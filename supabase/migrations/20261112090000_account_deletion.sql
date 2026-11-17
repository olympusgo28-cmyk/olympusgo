-- P1-14, Q228, Q139, Q208, Q237: a player deletes their account in the app.
--
-- A request closes the account at once: the profile hides, the money owed
-- comes back, and every API call is refused except "keep my account" for
-- account.delete_undo_days. Then the daily job erases private data and leaves
-- a "Former player" tombstone. The auth.users row is never deleted, so no
-- cascade can take a child's records, a voucher's order or a match result.
-- The wrong cascades are corrected below anyway, as a second line.

-- ─── 1. Settings ───────────────────────────────────────────────────────────

insert into public.app_settings (key, value, description) values
  ('account.delete_undo_days', '30', 'Days to undo an account deletion before it is erased (R-ACC-11)'),
  ('account.erase_blocked_alert_days', '7', 'Days an erase may wait on open money before staff are told')
on conflict (key) do nothing;

-- ─── 2. The request ────────────────────────────────────────────────────────

create table public.account_deletions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  requested_at timestamptz not null default now(),
  erase_after timestamptz not null,
  cancelled_at timestamptz,
  erased_at timestamptz,
  -- Moderation hid them before the request, so cancelling must not unhide.
  hidden_before boolean not null default false,
  reason text check (char_length(reason) <= 200),
  blocked_reason text,
  blocked_at timestamptz
);
alter table public.account_deletions enable row level security;
create policy "Players see their own deletion" on public.account_deletions
  for select to authenticated using (user_id = auth.uid());
revoke all on public.account_deletions from anon, public;
revoke insert, update, delete, truncate, references, trigger on public.account_deletions from authenticated;
create index account_deletions_due_idx on public.account_deletions (erase_after)
  where cancelled_at is null and erased_at is null;

alter table public.profiles add column erased_at timestamptz;

create function private.is_closing(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: read from the request gate for any caller.
  select exists (select 1 from public.account_deletions d
    where d.user_id = p_user and d.cancelled_at is null and d.erased_at is null);
$$;
revoke execute on function private.is_closing(uuid) from public;

create function private.is_erased(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: read from the request gate and the name helpers for any caller.
  select exists (select 1 from public.profiles p where p.id = p_user and p.erased_at is not null);
$$;
revoke execute on function private.is_erased(uuid) from public;

-- An erased account has no birthday, which would otherwise count as a minor
-- and mask the tombstone's name.
create or replace function private.is_minor(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads profiles for any caller; returns only yes or no.
  select private.audience_of(p_user) <> 'adult' and not private.is_erased(p_user);
$$;

-- "Former player" is shown whole, never as "Former p.".
create or replace function private.masked_name(p_full_name text) returns text
language sql immutable set search_path = '' as $$
  select case
    when p_full_name is null or trim(p_full_name) = '' then 'Player'
    when p_full_name = 'Former player' then p_full_name
    when array_length(regexp_split_to_array(trim(p_full_name), '\s+'), 1) = 1 then trim(p_full_name)
    else (regexp_split_to_array(trim(p_full_name), '\s+'))[1] || ' '
      || left((regexp_split_to_array(trim(p_full_name), '\s+'))[2], 1) || '.'
  end;
$$;

-- Clients never write erased_at.
create or replace function private.profile_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.visibility = 'everyone' and private.is_minor(new.id) then
    new.visibility := 'followers';
  end if;
  if tg_op = 'UPDATE' and current_user = 'authenticated' then
    new.hidden_at := old.hidden_at;
    new.erased_at := old.erased_at;
  end if;
  return new;
end;
$$;

-- The birthday is write-once, except when the erase job clears it.
create or replace function public.lock_birthday() returns trigger
language plpgsql set search_path = '' as $$
begin
  if old.birthday is not null and new.birthday is distinct from old.birthday
     and current_setting('og.account_erase', true) is distinct from new.id::text then
    raise exception 'Your birthday can''t be changed once it is set.'
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

-- Everything a leaving player paid for an activity still to come, back in
-- full with the fee (R-REF-18). Like leave_activity without the time window.
create function private.account_leave(a public.activities, p_user uuid) returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds, tickets and the waitlist.
declare
  pay public.payments;
  v_refund bigint := 0;
begin
  perform 1 from public.activities where id = a.id for update;
  for pay in
    select * from public.payments p
    where p.activity_id = a.id and p.user_id = p_user
      and p.purpose in ('meet', 'host_spot', 'ticket', 'tournament')
      and p.status in ('pending', 'succeeded')
    order by p.created_at
  loop
    if pay.status = 'pending' then
      update public.payments
      set status = case when method is null then 'cancelled' else 'cancel_requested' end
      where id = pay.id;
    else
      v_refund := v_refund + private.refund_issue(pay.id, 'account_deleted', 'account_deleted:' || pay.id);
    end if;
  end loop;
  if now() < a.starts_at then
    perform private.organizer_fee_reverse(a, p_user);
  end if;
  update public.event_tickets set status = 'released'
  where activity_id = a.id and user_id = p_user and status = 'active';
  update public.activity_participants
  set status = 'cancelled', queue_seq = null, hold_until = null,
      refund_to = case when v_refund > 0 then 'original' end,
      refund_cents = v_refund
  where activity_id = a.id and user_id = p_user;
  perform private.promote_waitlist(a.id);
  return v_refund;
end;
$$;
revoke execute on function private.account_leave(public.activities, uuid) from public;

create function public.account_delete_request(p_reason text default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: writes account_deletions and hides the profile; refunds go through
-- the money helpers. auth.uid() is still the caller inside a definer, so
-- cancel_activity's host check holds.
declare
  me uuid := auth.uid();
  d public.account_deletions;
  a public.activities;
  b public.lesson_bookings;
  v_until timestamptz;
  v_hidden boolean;
begin
  if me is null then raise exception 'Sign in first.'; end if;
  perform pg_advisory_xact_lock(hashtext('account_delete:' || me));

  select * into d from public.account_deletions where user_id = me;
  if d.erased_at is not null then raise exception 'This account was deleted.'; end if;
  if d.user_id is not null and d.cancelled_at is null then
    return jsonb_build_object('erase_after', d.erase_after);
  end if;

  -- Hand over what other people depend on first (R-ACC-15).
  if exists (select 1 from public.staff s where s.user_id = me and s.active) then
    raise exception 'Staff accounts are closed by the OlympusGO team. Ask them to remove your staff role first.';
  end if;
  if exists (select 1 from public.clubs c where c.owner_id = me) then
    raise exception 'Hand your club to another member, or delete it, first.';
  end if;
  if exists (select 1 from public.teams t where t.owner_id = me) then
    raise exception 'Hand your team to another coach, or delete it, first.';
  end if;
  if exists (select 1 from public.academies x where x.owner_id = me and x.closed_at is null) then
    raise exception 'Close your academy first.';
  end if;
  if exists (select 1 from public.malls m where m.owner_id = me and m.active) then
    raise exception 'Ask the OlympusGO team to close or hand over your shop first.';
  end if;
  -- Owed money is what the payout run would pay: the same net, per currency.
  -- (The ledger is positive debit, negative credit, so the raw sum is owed when
  -- negative; organizer_net already turns it round.) A fee debt is not refused.
  if exists (select 1 from public.ledger_accounts la where la.owner_id = me
      and la.kind in ('organizer', 'organizer_fee_debt', 'card_fee_recovery')
      group by la.currency having private.organizer_net(me, la.currency) > 0) then
    raise exception 'You still have earnings to be paid out. Ask the OlympusGO team to send them first.';
  end if;

  v_until := now() + make_interval(days => private.setting_int('account.delete_undo_days'));
  select p.hidden_at is not null into v_hidden from public.profiles p where p.id = me;
  insert into public.account_deletions (user_id, erase_after, hidden_before, reason)
  values (me, v_until, coalesce(v_hidden, false), left(nullif(trim(p_reason), ''), 200))
  on conflict (user_id) do update
    set requested_at = now(), erase_after = excluded.erase_after, cancelled_at = null,
        hidden_before = excluded.hidden_before, reason = excluded.reason,
        blocked_reason = null, blocked_at = null;
  update public.profiles set hidden_at = coalesce(hidden_at, now()) where id = me;

  -- Meets they host that haven't happened: cancelled, everyone paid back.
  for a in
    select * from public.activities s
    where s.host_id = me and s.status = 'published' and s.starts_at > now()
    order by s.id
  loop
    perform public.cancel_activity(a.id, false, 'The organizer closed their OlympusGO account.');
  end loop;

  -- Meets, tournaments and events they joined: everything paid comes back.
  for a in
    select s.* from public.activities s
    where s.host_id <> me and s.status = 'published' and s.starts_at > now()
      and (exists (select 1 from public.activity_participants ap
             where ap.activity_id = s.id and ap.user_id = me
               and ap.status in ('joined', 'reserved', 'offered', 'waitlist', 'requested'))
        or exists (select 1 from public.payments p
             where p.activity_id = s.id and p.user_id = me and p.status in ('pending', 'succeeded')))
    order by s.id
  loop
    perform private.account_leave(a, me);
  end loop;

  -- Lessons they paid for that haven't happened.
  for b in
    select * from public.lesson_bookings x
    where x.payer_id = me and x.step in ('pending', 'paid') and x.starts_at > now()
    order by x.id
  loop
    perform private.lesson_cancel_full(b, 'account_deleted');
    update public.lesson_bookings set cancelled_by = 'payer', cancel_reason = 'account_deleted'
    where id = b.id and step = 'cancelled';
  end loop;

  -- Shop orders finish on their own; the erase waits for them.

  perform public.notify(me, 'Your account is closing',
    'Log in before ' || to_char(v_until at time zone 'Asia/Singapore', 'DD Mon YYYY') || ' to keep it.',
    '!', '/closing');
  return jsonb_build_object('erase_after', v_until);
end;
$$;
revoke execute on function public.account_delete_request(text) from public, anon;
grant execute on function public.account_delete_request(text) to authenticated;

create function public.account_delete_cancel() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes account_deletions and unhides the profile.
declare
  me uuid := auth.uid();
  d public.account_deletions;
begin
  if me is null then raise exception 'Sign in first.'; end if;
  perform pg_advisory_xact_lock(hashtext('account_delete:' || me));
  select * into d from public.account_deletions where user_id = me for update;
  if d.erased_at is not null then raise exception 'This account was deleted.'; end if;
  if d.user_id is null or d.cancelled_at is not null then return; end if;
  update public.account_deletions set cancelled_at = now(), blocked_reason = null, blocked_at = null
  where user_id = me;
  if not d.hidden_before then
    update public.profiles set hidden_at = null where id = me;
  end if;
end;
$$;
revoke execute on function public.account_delete_cancel() from public, anon;
grant execute on function public.account_delete_cancel() to authenticated;

-- The app learns the state from my_restrictions.
do $$
declare
  d text := pg_get_functiondef('public.my_restrictions()'::regprocedure);
  fixed text := replace(d, $old$'suspended', private.is_suspended(me),$old$,
    $new$'suspended', private.is_suspended(me),
    'closing_until', (select x.erase_after from public.account_deletions x
      where x.user_id = me and x.cancelled_at is null and x.erased_at is null),$new$);
begin
  if fixed = d then raise exception 'my_restrictions did not change'; end if;
  execute fixed;
end;
$$;

-- ─── 3. The gate: a closing account can only keep itself ───────────────────

create table private.closing_allow (path text primary key);
insert into private.closing_allow (path) values
  ('/rpc/my_restrictions'), ('/rpc/account_delete_cancel'), ('/rpc/account_delete_request'),
  ('/account_deletions'), ('/profiles'), ('/account_private'),
  -- Getting help must always work.
  ('/rpc/legal_notice_send'), ('/support_requests'), ('/legal_notices');

create or replace function private.gate_request() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: runs as whichever role is calling and reads private tables.
declare
  v_path text := current_setting('request.path', true);
  v_method text := current_setting('request.method', true);
  v_user uuid := auth.uid();
  v_rule private.rate_rules;
begin
  -- Not an API call, for example a direct database session.
  if v_path is null or v_path = '' then
    return;
  end if;

  if v_user is not null and not private.is_staff() then
    if private.is_erased(v_user) then
      raise exception 'This account was deleted.' using errcode = 'P0001';
    end if;
    if private.is_closing(v_user)
       and not exists (select 1 from private.closing_allow a where a.path = v_path) then
      raise exception 'This account is closing.' using errcode = 'P0001';
    end if;
  end if;

  if v_user is not null and private.is_restricted(v_user) and not private.is_staff() then
    if private.is_suspended(v_user) then
      if not ((v_method in ('GET', 'HEAD')
            and exists (select 1 from private.restricted_allow a where a.path = v_path))
          or exists (select 1 from private.suspended_allow a where a.path = v_path)) then
        raise exception 'Your account is suspended.' using errcode = 'P0001';
      end if;
    elsif not exists (select 1 from private.restricted_allow a where a.path = v_path) then
      raise exception 'Ask a parent to link your account first.' using errcode = 'P0001';
    end if;
  end if;

  if v_method = 'POST' then
    select * into v_rule from private.rate_rules r where r.path = v_path;
    if v_rule.path is not null and not private.rate_hit(
        v_path, coalesce(v_user::text, private.request_ip()),
        v_rule.max_hits, v_rule.window_seconds) then
      raise exception 'Too many tries. Wait a while, then try again.' using errcode = 'P0001';
    end if;
  end if;
end;
$$;

-- ─── 4. The erase ──────────────────────────────────────────────────────────

alter table public.storage_deletions drop constraint if exists storage_deletions_bucket_check;
alter table public.storage_deletions add constraint storage_deletions_bucket_check
  check (bucket in ('analysis-clips', 'feed-videos', 'avatars', 'chat-photos', 'verification-docs'));

-- Money still moving for this person, which the erase must wait for.
create function private.account_money_open(p_user uuid) returns text
language sql stable security definer set search_path = '' as $$
  -- Definer: reads money tables.
  select case
    when exists (select 1 from public.orders o where o.buyer_id = p_user
      and o.step in ('pending', 'paid', 'started', 'ready', 'reported')) then 'shop_order'
    when exists (select 1 from public.lesson_bookings b where b.payer_id = p_user
      and b.step in ('pending', 'paid', 'marked', 'late_cancelled', 'reported')) then 'lesson'
    when exists (select 1 from public.payments p join public.payment_disputes x on x.payment_id = p.id
      where p.user_id = p_user and x.status = 'open') then 'dispute'
    when exists (select 1 from public.payments p where p.user_id = p_user
      and p.status in ('succeeded', 'cancel_requested') and p.released_at is null and p.price_minor > 0
      and not exists (select 1 from public.refunds r where r.payment_id = p.id)) then 'held'
    when exists (select 1 from public.refunds r join public.payments p on p.id = r.payment_id
      where p.user_id = p_user and r.status in ('pending', 'processing', 'failed', 'manual')) then 'refund'
  end;
$$;
revoke execute on function private.account_money_open(uuid) from public;

create function private.account_erase(p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: the retention job. Deletes private rows, queues files, and leaves
-- a "Former player" tombstone. Money, results, reports and audit stay.
declare
  l record;
  d public.account_deletions;
begin
  perform pg_advisory_xact_lock(hashtext('account_delete:' || p_user));
  -- Under the same lock the request and the undo take, so a "Keep my account"
  -- that landed after the job chose this row is seen here and wins.
  select * into d from public.account_deletions where user_id = p_user;
  if d.user_id is null or d.cancelled_at is not null or d.erased_at is not null then
    return;
  end if;
  perform pg_advisory_xact_lock(hashtext('points:' || p_user));
  perform set_config('og.account_erase', p_user::text, true);

  -- Files first, while the rows that name them still exist.
  insert into public.storage_deletions (bucket, path)
  select 'avatars', o.name from storage.objects o
  where o.bucket_id = 'avatars' and o.name like p_user::text || '/%';
  insert into public.storage_deletions (bucket, path)
  select 'chat-photos', o.name from storage.objects o
  where o.bucket_id = 'chat-photos' and o.name like '%/' || p_user::text || '/%';
  insert into public.storage_deletions (bucket, path)
  select 'verification-docs', c.file_path from public.coach_licences c
  where c.user_id = p_user and c.file_path is not null;

  -- Who they are.
  update public.account_private
  set mobile = null, mobile_verified_at = null, email = null, email_verified_at = null,
      birthday = null, parent_email = null, parent_approved_at = null, identity_verified_at = null
  where id = p_user;
  update public.profiles
  set full_name = 'Former player', username = null, bio = null, avatar_url = null,
      gender = 'prefer_not_to_say', visibility = 'only_me', show_level = false,
      findable_by_phone = false, share_location_at_meets = false,
      hidden_at = coalesce(hidden_at, now()), erased_at = now()
  where id = p_user;

  -- Family: links end, so a child with no other parent is back in the shell.
  update public.guardian_links set status = 'ended', ended_at = now()
  where (parent_id = p_user or child_id = p_user) and status in ('pending', 'approved');
  update public.academy_students set parent_id = null where parent_id = p_user;

  -- What they did and saw. Video rows go, and their triggers queue the files.
  delete from public.video_posts where author_id = p_user;
  delete from public.video_clips where owner_id = p_user or subject_id = p_user;
  delete from public.analysis_reports where subject_id = p_user;
  delete from public.analysis_usage where owner_id = p_user;
  delete from public.ai_plan_requests where user_id = p_user;
  delete from public.workouts where user_id = p_user;
  delete from public.programs where owner_id = p_user;
  delete from public.messages where sender_id = p_user;
  delete from public.group_messages where sender_id = p_user;
  delete from public.conversation_members where user_id = p_user;
  delete from public.follows where follower_id = p_user or followee_id = p_user;
  delete from public.blocks where blocker_id = p_user or blocked_id = p_user;
  delete from public.saved_items where user_id = p_user;
  delete from public.notifications where user_id = p_user;
  delete from public.notification_settings where user_id = p_user;
  delete from public.device_tokens where user_id = p_user;
  delete from public.push_queue where user_id = p_user;
  delete from public.private_locations where user_id = p_user;
  delete from public.play_preferences where user_id = p_user;
  delete from public.player_sports where user_id = p_user;
  delete from public.player_gear where user_id = p_user;
  delete from public.ratings where user_id = p_user;
  delete from public.leaderboard_rows where user_id = p_user;
  delete from public.club_members where user_id = p_user;
  delete from public.club_join_requests where user_id = p_user;
  delete from public.club_invites where user_id = p_user;
  delete from public.club_ratings where user_id = p_user;
  delete from public.team_members where user_id = p_user;
  delete from public.fixture_availability where user_id = p_user;
  delete from public.event_reminders where user_id = p_user;
  delete from public.mall_follows where user_id = p_user;
  delete from public.cart_lines where user_id = p_user;
  delete from public.product_reviews where user_id = p_user;
  delete from public.academy_coaches where user_id = p_user;
  delete from public.academy_requests where parent_id = p_user or player_id = p_user;
  delete from public.coach_licences where user_id = p_user;
  delete from public.coach_profiles where user_id = p_user;
  delete from public.player_qr_tokens where user_id = p_user;
  delete from public.guardian_link_codes where child_id = p_user;
  delete from public.guardian_code_attempts where user_id = p_user;
  delete from public.service_referrals where user_id = p_user;
  delete from public.challenge_progress where user_id = p_user;
  delete from public.challenges where user_id = p_user;
  delete from public.player_badges where user_id = p_user;
  delete from public.reward_grants where user_id = p_user;

  -- Points are forfeited (R-PTS-6 shape); vouchers lapse.
  for l in select * from private.points_lots(p_user) x where x.left_minor > 0 loop
    insert into public.points_entries (user_id, kind, amount_minor, lot_id, expires_at, source_kind,
      source_id, idempotency_key)
    values (p_user, 'forfeit', -l.left_minor, l.lot_id, l.expires_at, 'account_deleted', p_user::text,
      'forfeit:' || l.lot_id || ':deleted');
  end loop;
  update public.vouchers set status = 'expired', expires_at = coalesce(expires_at, now())
  where owner_id = p_user and status in ('issued', 'held');

  -- Nobody signs in as them again. Hosted projects may not let this role
  -- touch auth.users; the gate and the empty contacts refuse them anyway.
  begin
    update auth.users set banned_until = 'infinity' where id = p_user;
    delete from auth.sessions where user_id = p_user;
    delete from auth.refresh_tokens where user_id = p_user::text;
    delete from auth.identities where user_id = p_user;
  exception when insufficient_privilege then
    null;
  end;

  update public.account_deletions set erased_at = now(), blocked_reason = null, blocked_at = null
  where user_id = p_user and cancelled_at is null and erased_at is null;
end;
$$;
revoke execute on function private.account_erase(uuid) from public;

-- Daily: erase what is due and safe; say so when something holds one up.
create function private.account_erase_due() returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: the retention job, from pg_cron.
declare
  d public.account_deletions;
  v_open text;
  v_done int := 0;
begin
  for d in
    select * from public.account_deletions x
    where x.cancelled_at is null and x.erased_at is null and x.erase_after < now()
    order by x.erase_after
    limit 200
  loop
    v_open := private.account_money_open(d.user_id);
    if v_open is null then
      perform private.account_erase(d.user_id);
      v_done := v_done + 1;
    else
      update public.account_deletions
      set blocked_reason = v_open, blocked_at = coalesce(blocked_at, now())
      where user_id = d.user_id;
      if coalesce(d.blocked_at, now()) < now()
          - make_interval(days => private.setting_int('account.erase_blocked_alert_days')) then
        perform private.money_alert('erase_blocked', 'erase-blocked:' || d.user_id,
          jsonb_build_object('user_id', d.user_id, 'reason', v_open));
      end if;
    end if;
  end loop;
  return v_done;
end;
$$;
revoke execute on function private.account_erase_due() from public;

select cron.schedule('retention-delete', '0 18 * * *', $$select private.account_erase_due()$$);

-- ─── 5. Cascades that were wrong (Q139), as a second line of defence ───────

alter table public.academies drop constraint academies_owner_id_fkey,
  add constraint academies_owner_id_fkey foreign key (owner_id) references auth.users (id);
alter table public.academy_students alter column parent_id drop not null,
  drop constraint academy_students_parent_id_fkey,
  add constraint academy_students_parent_id_fkey foreign key (parent_id) references auth.users (id) on delete set null;
alter table public.support_requests alter column user_id drop not null,
  drop constraint support_requests_user_id_fkey,
  add constraint support_requests_user_id_fkey foreign key (user_id) references auth.users (id) on delete set null;
alter table public.vouchers alter column owner_id drop not null,
  drop constraint vouchers_owner_id_fkey,
  add constraint vouchers_owner_id_fkey foreign key (owner_id) references auth.users (id) on delete set null;
alter table public.orders drop constraint orders_voucher_id_fkey,
  add constraint orders_voucher_id_fkey foreign key (voucher_id) references public.vouchers (id) on delete set null;
alter table public.voucher_redemptions alter column voucher_id drop not null,
  drop constraint voucher_redemptions_voucher_id_fkey,
  add constraint voucher_redemptions_voucher_id_fkey foreign key (voucher_id) references public.vouchers (id) on delete set null;
alter table public.activities drop constraint activities_host_id_fkey,
  add constraint activities_host_id_fkey foreign key (host_id) references auth.users (id);
alter table public.match_scores alter column entered_by drop not null,
  drop constraint match_scores_entered_by_fkey,
  add constraint match_scores_entered_by_fkey foreign key (entered_by) references auth.users (id) on delete set null;
alter table public.player_reports alter column reporter_id drop not null,
  drop constraint player_reports_reporter_id_fkey,
  add constraint player_reports_reporter_id_fkey foreign key (reporter_id) references auth.users (id) on delete set null;
alter table public.content_reports alter column reporter_id drop not null,
  drop constraint content_reports_reporter_id_fkey,
  add constraint content_reports_reporter_id_fkey foreign key (reporter_id) references auth.users (id) on delete set null;
-- The reporter is part of this key, so the row can neither lose them nor go
-- with them: like abuse_matches, it keeps the id with no foreign key, so the
-- evidence outlives the account.
alter table public.case_reports drop constraint case_reports_reporter_id_fkey;
