-- Audit of 10 Nov 2026, finding S2 (Q268): a session alone could change the
-- login mobile or email, and could set a password on its own Auth user and
-- log in with it. So a stolen session, or a phone left unlocked, became a
-- permanent takeover.
--
-- R-ACC-9: changing email or mobile needs a code to the other one, and the old
-- contact is alerted. A session now needs a fresh proof (a "step-up") before a
-- contact changes, and a player's Auth email, password and phone never change
-- after the account is made. Supabase Auth also never sends mail of its own,
-- so its own email codes cannot be used to get back in.

-- ─── 1. Settings ───────────────────────────────────────────────────────────

insert into public.app_settings (key, value, description) values
  ('auth.step_up_minutes', '5',
   'Minutes a code proves "it is you" for changing a login contact (R-ACC-9, Q268)')
on conflict (key) do nothing;

alter table public.login_codes drop constraint login_codes_purpose_check;
alter table public.login_codes add constraint login_codes_purpose_check
  check (purpose in ('login', 'signup', 'contact', 'step_up'));

-- ─── 2. The proof ──────────────────────────────────────────────────────────

-- One row per session that has just proved itself with a code, and which
-- contact the code went to. Tied to the session, not the player, so proof
-- given on one phone unlocks nothing on another. No client reads or writes
-- this table.
create table public.step_ups (
  session_id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  proved_kind text not null check (proved_kind in ('mobile', 'email')),
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index step_ups_user_idx on public.step_ups (user_id);
alter table public.step_ups enable row level security;
revoke all on public.step_ups from public, anon, authenticated;

-- Which contact must prove it is them (R-ACC-9, "the other one"): the email
-- when the mobile is changing, the mobile when the email is. A player with
-- only one contact proves with that one. Null when they have none.
create function public.login_proof_contact(p_user uuid, p_changing text) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads private contact details, for resolve-login only.
  select case
    when p_changing = 'mobile' and ap.email is not null and ap.email_verified_at is not null
      then jsonb_build_object('kind', 'email', 'value', ap.email)
    when p_changing = 'email' and ap.mobile is not null and ap.mobile_verified_at is not null
      then jsonb_build_object('kind', 'mobile', 'value', ap.mobile)
    when ap.mobile is not null and ap.mobile_verified_at is not null
      then jsonb_build_object('kind', 'mobile', 'value', ap.mobile)
    when ap.email is not null and ap.email_verified_at is not null
      then jsonb_build_object('kind', 'email', 'value', ap.email)
  end
  from public.account_private ap
  where ap.id = p_user and p_changing in ('mobile', 'email');
$$;

-- Records that a code sent to [p_kind] was just entered in this session.
create function public.login_step_up_grant(p_user uuid, p_session uuid, p_kind text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: step_ups has no client access. Called by resolve-login after it has
-- checked a code for this player in this session.
begin
  delete from public.step_ups where expires_at < now() - interval '1 day';
  insert into public.step_ups (session_id, user_id, proved_kind, expires_at)
  values (p_session, p_user, p_kind,
    now() + make_interval(mins => private.setting_int('auth.step_up_minutes')))
  on conflict (session_id) do update
    set expires_at = excluded.expires_at, proved_kind = excluded.proved_kind
    where public.step_ups.user_id = excluded.user_id;
end;
$$;

-- Whether this session may change [p_changing] now: it holds a live proof,
-- and the proof came from the contact that change needs.
create function public.login_step_up_live(p_user uuid, p_session uuid, p_changing text)
returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: step_ups has no client access.
  select exists (select 1 from public.step_ups s
    where s.session_id = p_session and s.user_id = p_user and s.expires_at > now()
      and s.proved_kind = public.login_proof_contact(p_user, p_changing) ->> 'kind');
$$;

-- Sets a login contact, only for a session holding the right live proof. The
-- proof is used up, the player is told in the app, and the contact to alert
-- is returned so resolve-login can message it: the old one, or, when this is
-- their first contact of that kind, the other one. So no change is silent.
create function public.login_contact_change(
  p_user uuid, p_session uuid, p_kind text, p_value text
) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: contact columns and step_ups are closed to players.
declare
  ap public.account_private;
  v_old text;
  v_alert text;
  v_new text := case when p_kind = 'email' then lower(p_value) else p_value end;
begin
  if p_kind not in ('mobile', 'email') then
    return jsonb_build_object('status', 'refused');
  end if;
  perform 1 from public.step_ups s
  where s.session_id = p_session and s.user_id = p_user and s.expires_at > now()
    and s.proved_kind = public.login_proof_contact(p_user, p_kind) ->> 'kind'
  for update;
  if not found then
    return jsonb_build_object('status', 'step_up');
  end if;

  select * into ap from public.account_private x where x.id = p_user for update;
  v_old := case p_kind
    when 'mobile' then case when ap.mobile_verified_at is not null then ap.mobile end
    else case when ap.email_verified_at is not null then ap.email end
  end;
  if v_old is not distinct from v_new then
    -- Nothing changes, so nothing is used up and nobody is alerted.
    return jsonb_build_object('status', 'ok', 'alert', null);
  end if;
  v_alert := coalesce(v_old, case p_kind
    when 'mobile' then case when ap.email_verified_at is not null then ap.email end
    else case when ap.mobile_verified_at is not null then ap.mobile end
  end);

  begin
    if p_kind = 'mobile' then
      update public.account_private set mobile = v_new, mobile_verified_at = now() where id = p_user;
    else
      update public.account_private set email = v_new, email_verified_at = now() where id = p_user;
    end if;
  exception when unique_violation then
    -- Another account holds it. The proof stays, so they can try another.
    return jsonb_build_object('status', 'taken');
  end;

  delete from public.step_ups where session_id = p_session;
  insert into public.notifications (user_id, title, body, mark, link)
  values (p_user,
    case when p_kind = 'mobile' and v_old is not null then 'Your login mobile was changed'
      when p_kind = 'mobile' then 'A mobile was added to your login'
      when v_old is not null then 'Your login email was changed'
      else 'An email was added to your login' end,
    'If this wasn''t you, get help now.', '!', '/settings/help');
  return jsonb_build_object('status', 'ok', 'alert', v_alert, 'first', v_old is null);
end;
$$;

-- The old way in: it changed a contact with no proof.
drop function public.login_contact_set(uuid, text, text);

revoke execute on function public.login_step_up_grant(uuid, uuid, text) from public, anon, authenticated;
revoke execute on function public.login_step_up_live(uuid, uuid, text) from public, anon, authenticated;
revoke execute on function public.login_proof_contact(uuid, text) from public, anon, authenticated;
revoke execute on function public.login_contact_change(uuid, uuid, text, text) from public, anon, authenticated;
grant execute on function public.login_step_up_grant(uuid, uuid, text) to service_role;
grant execute on function public.login_step_up_live(uuid, uuid, text) to service_role;
grant execute on function public.login_proof_contact(uuid, text) to service_role;
grant execute on function public.login_contact_change(uuid, uuid, text, text) to service_role;

-- ─── 3. A player's Auth sign-in details never change ───────────────────────

-- Proven on 11 Nov 2026: with only a player's session, a direct call to
-- Supabase Auth set a password and then logged in with it, and changed the
-- Auth email. Players have no password and resolve-login never changes these
-- after it makes the account, so any later change is refused. Active staff log
-- in to the admin app with a password, so they are exempt.
create function private.auth_login_fixed() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: Supabase Auth's own role cannot read public.staff.
begin
  -- The pending columns too: Auth stores a requested change there.
  if new.email is distinct from old.email
      or new.encrypted_password is distinct from old.encrypted_password
      or new.phone is distinct from old.phone
      or coalesce(new.email_change, '') is distinct from coalesce(old.email_change, '')
      or coalesce(new.phone_change, '') is distinct from coalesce(old.phone_change, '') then
    if not exists (select 1 from public.staff s where s.user_id = old.id and s.active) then
      raise exception 'Sign-in details for this account cannot be changed here.'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;
revoke execute on function private.auth_login_fixed() from public;

create trigger auth_users_login_fixed before update on auth.users
  for each row execute function private.auth_login_fixed();

-- ─── 4. Supabase Auth never sends mail of its own ──────────────────────────

-- Proven on 11 Nov 2026: a session can read its account's internal Auth
-- address, ask Supabase Auth to email a 6-digit code to it, and then guess
-- that code against Auth directly, with no lock. Every real code is sent and
-- checked by resolve-login, which makes sessions without any Auth email. So
-- Auth's send-email hook (supabase/config.toml) refuses every send: no code or
-- link is ever issued, and Auth cannot be used to mail anyone in our name.
create function private.auth_email_refused(event jsonb) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object('error', jsonb_build_object(
    'http_code', 403, 'message', 'Use the OlympusGO app to sign in.'));
$$;
revoke execute on function private.auth_email_refused(jsonb) from public, anon, authenticated;
grant usage on schema private to supabase_auth_admin;
grant execute on function private.auth_email_refused(jsonb) to supabase_auth_admin;
