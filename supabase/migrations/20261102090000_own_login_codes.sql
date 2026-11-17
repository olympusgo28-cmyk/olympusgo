-- Q41. Supabase Auth's public /otp and /verify could be called directly, which
-- showed whether a mobile was registered and skipped our lockout. So Supabase
-- Auth no longer holds anyone's real contact details: mobiles and emails live
-- here, resolve-login issues and checks every code, and each auth.users row
-- has only an internal address used to create a session. Any direct lookup
-- now sees an unknown account, whoever it is asking about.

alter table public.account_private
  add column mobile text check (mobile ~ '^\+[1-9][0-9]{6,14}$'),
  add column mobile_verified_at timestamptz,
  add column email text check (email = lower(email) and email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  add column email_verified_at timestamptz;

-- R-ACC-5: one account per verified mobile.
create unique index account_private_mobile_idx on public.account_private (mobile);
create unique index account_private_email_idx on public.account_private (email);

create function private.internal_email(p_user uuid) returns text
language sql immutable set search_path = '' as $$
  select 'u-' || p_user::text || '@users.olympusgo.invalid';
$$;
revoke execute on function private.internal_email(uuid) from public;

update public.account_private ap
set mobile = '+' || u.phone,
    mobile_verified_at = u.phone_confirmed_at,
    email = lower(u.email),
    email_verified_at = u.email_confirmed_at
from auth.users u
where u.id = ap.id;

update auth.users
set email = private.internal_email(id),
    email_confirmed_at = coalesce(email_confirmed_at, now()),
    phone = null,
    phone_confirmed_at = null;

delete from auth.identities where provider = 'phone';
update auth.identities
set identity_data = identity_data || jsonb_build_object('email', private.internal_email(user_id))
where provider = 'email';

create or replace function private.has_verified_mobile(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called for other players, whose private row is closed.
  select exists (select 1 from public.account_private ap
    where ap.id = p_user and ap.mobile is not null and ap.mobile_verified_at is not null);
$$;

-- ─── Codes ─────────────────────────────────────────────────────────────────

create table public.login_codes (
  id bigint generated always as identity primary key,
  -- Hashes only: nobody reading this table can use a code.
  target_hash text not null,
  code_hash text not null,
  purpose text not null check (purpose in ('login', 'signup', 'contact')),
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);
create index login_codes_target_idx on public.login_codes (target_hash) where used_at is null;
alter table public.login_codes enable row level security;
revoke all on public.login_codes from anon, authenticated;

insert into public.app_settings (key, value, description) values
  ('auth.code_minutes', '10', 'How long a sign-in code lasts (R-ACC-2)');

-- A new code cancels the old one (R-ACC-2).
create function public.login_code_issue(p_target_hash text, p_code_hash text, p_purpose text)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: login_codes has no client access.
begin
  update public.login_codes set used_at = now()
  where target_hash = p_target_hash and used_at is null;
  insert into public.login_codes (target_hash, code_hash, purpose, expires_at)
  values (p_target_hash, p_code_hash, p_purpose,
    now() + make_interval(mins => private.setting_int('auth.code_minutes')));
end;
$$;

-- Uses the code up in one statement, so it works once. Returns its purpose.
create function public.login_code_check(p_target_hash text, p_code_hash text) returns text
language sql security definer set search_path = '' as $$
  -- Definer: login_codes has no client access.
  update public.login_codes set used_at = now()
  where id = (select id from public.login_codes
    where target_hash = p_target_hash and code_hash = p_code_hash
      and used_at is null and expires_at > now()
    order by id desc limit 1 for update)
  returning purpose;
$$;

drop function public.login_lookup(text);

-- Finds an account by what was typed. For the Edge Function only.
create function public.login_lookup(p_kind text, p_value text) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads private contact details and the internal address.
  select jsonb_build_object('user_id', ap.id, 'mobile', ap.mobile,
    'email', case when ap.email_verified_at is not null then ap.email end,
    'internal_email', private.internal_email(ap.id))
  from public.account_private ap
  left join public.profiles p on p.id = ap.id
  where case p_kind
    when 'mobile' then ap.mobile = p_value and ap.mobile_verified_at is not null
    when 'email' then ap.email = lower(p_value) and ap.email_verified_at is not null
    when 'username' then p.username = p_value::extensions.citext
    else false
  end
  limit 1;
$$;

-- False when another account already holds this contact.
create function public.login_contact_set(p_user uuid, p_kind text, p_value text) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: contact columns are closed to players.
begin
  if p_kind = 'mobile' then
    update public.account_private set mobile = p_value, mobile_verified_at = now() where id = p_user;
  else
    update public.account_private set email = lower(p_value), email_verified_at = now() where id = p_user;
  end if;
  return true;
exception when unique_violation then
  return false;
end;
$$;

revoke execute on function public.login_code_issue(text, text, text) from public, anon, authenticated;
revoke execute on function public.login_code_check(text, text) from public, anon, authenticated;
revoke execute on function public.login_lookup(text, text) from public, anon, authenticated;
revoke execute on function public.login_contact_set(uuid, text, text) from public, anon, authenticated;
grant execute on function public.login_code_issue(text, text, text) to service_role;
grant execute on function public.login_code_check(text, text) to service_role;
grant execute on function public.login_lookup(text, text) to service_role;
grant execute on function public.login_contact_set(uuid, text, text) to service_role;

-- ─── Older functions that found people through auth.users ─────────────────

do $$
declare
  d text;
  fixed text;
begin
  d := pg_get_functiondef('public.academy_invite(uuid, text)'::regprocedure);
  fixed := replace(d, $old$select id into v_user from auth.users
  where right(regexp_replace(coalesce(phone, ''), '[^0-9]', '', 'g'), 8) = right(v_digits, 8)$old$,
    $new$select id into v_user from public.account_private
  where mobile_verified_at is not null
    and right(regexp_replace(coalesce(mobile, ''), '[^0-9]', '', 'g'), 8) = right(v_digits, 8)$new$);
  if fixed = d then raise exception 'academy_invite did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.academy_create(jsonb)'::regprocedure);
  fixed := replace(d, 'select id into v_user from auth.users where lower(email) = e;',
    'select id into v_user from public.account_private where email = e and email_verified_at is not null;');
  if fixed = d then raise exception 'academy_create did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.academy_claim_invites()'::regprocedure);
  fixed := replace(d, 'select lower(email) from auth.users where id = (select auth.uid())',
    'select email from public.account_private where id = (select auth.uid()) and email_verified_at is not null');
  if fixed = d then raise exception 'academy_claim_invites did not change'; end if;
  execute fixed;
end;
$$;
