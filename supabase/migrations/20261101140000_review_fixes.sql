-- Fixes from the independent security review of the Phase 1 work.

-- ─── Every account needs a verified mobile ─────────────────────────────────

-- Email sign-up skipped the mobile step, so a child could make a second
-- account with an adult birthday and approve their own parent link. Without a
-- verified mobile an account is restricted, whatever the sign-up settings are.
-- This also holds R-ACC-5: one account per verified mobile.
create function private.has_verified_mobile(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads auth.users, which no client role can.
  select exists (select 1 from auth.users u
    where u.id = p_user and u.phone_confirmed_at is not null);
$$;
revoke execute on function private.has_verified_mobile(uuid) from public;
grant execute on function private.has_verified_mobile(uuid) to authenticated, service_role;

create or replace function private.is_restricted(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called from RLS policies and the request gate for any caller.
  select not private.has_verified_mobile(p_user)
    or (private.is_minor(p_user) and not exists (
      select 1 from public.guardian_links l
      where l.child_id = p_user and l.status = 'approved'));
$$;

-- Wrong codes are counted before the code is looked at, in one statement, so
-- parallel tries cannot all pass, and a late wrong try cannot clear a lock.
-- Returned, not raised: raising would undo the count.
create function private.code_attempt_blocked(p_user uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: guardian_code_attempts has no client access.
declare
  v_row public.guardian_code_attempts;
begin
  insert into public.guardian_code_attempts as g (user_id, wrong_count) values (p_user, 1)
  on conflict (user_id) do update set
    wrong_count = case when g.locked_until <= now() then 1 else g.wrong_count + 1 end,
    locked_until = case when g.locked_until > now() then g.locked_until end
  returning * into v_row;
  if v_row.locked_until > now() then return true; end if;
  if v_row.wrong_count > private.setting_int('auth.code_lock_attempts') then
    update public.guardian_code_attempts
    set locked_until = now() + make_interval(mins => private.setting_int('auth.code_lock_minutes')),
        wrong_count = 0
    where user_id = p_user;
    return true;
  end if;
  return false;
end;
$$;
revoke execute on function private.code_attempt_blocked(uuid) from public;

create or replace function public.guardian_code_redeem(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: reads guardian_link_codes and the child's profile for the parent.
declare
  me uuid := auth.uid();
  v_row public.guardian_link_codes;
  v_link uuid;
  v_name text;
begin
  -- These come first, so a refused parent cannot learn that a code is real.
  if private.audience_of(me) <> 'adult' then
    raise exception 'A parent or guardian must be 18 or over.';
  end if;
  if not private.has_verified_mobile(me) then
    raise exception 'A parent or guardian needs a verified mobile number.';
  end if;
  if private.code_attempt_blocked(me) then
    return jsonb_build_object('error', 'Too many tries. Wait a while, then try again.');
  end if;

  select * into v_row from public.guardian_link_codes
  where code_hash = private.code_hash(coalesce(p_code, ''))
    and used_at is null and expires_at > now() and child_id <> me
  for update;
  if v_row.id is null then
    return jsonb_build_object('error', 'That code didn''t work. Check it and try again.');
  end if;

  update public.guardian_link_codes set used_at = now() where id = v_row.id;
  delete from public.guardian_code_attempts where user_id = me;

  insert into public.guardian_links (child_id, parent_id)
  values (v_row.child_id, me)
  on conflict (child_id, parent_id) where status in ('pending', 'approved')
    do update set created_at = public.guardian_links.created_at
  returning id into v_link;

  select coalesce(p.full_name, 'Your child') into v_name
  from public.profiles p where p.id = v_row.child_id;
  return jsonb_build_object('link_id', v_link, 'child_name', v_name);
end;
$$;

create or replace function public.guardian_link_decide(p_link uuid, p_approve boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: guardian_links has no write policy; the parent acts through here.
declare
  v_link public.guardian_links;
begin
  select * into v_link from public.guardian_links
  where id = p_link and parent_id = auth.uid() for update;
  if v_link.id is null or v_link.status <> 'pending' then
    raise exception 'This request is no longer waiting for you.';
  end if;
  if private.audience_of(auth.uid()) <> 'adult' or not private.has_verified_mobile(auth.uid()) then
    raise exception 'A parent or guardian must be 18 or over.';
  end if;
  update public.guardian_links
  set status = case when p_approve then 'approved' else 'denied' end, decided_at = now()
  where id = p_link;
  perform public.notify(v_link.child_id,
    case when p_approve then 'Your parent linked your account' else 'Your parent said no to the link' end,
    case when p_approve then 'You can use OlympusGO now.' else 'Ask them to try again when they are ready.' end,
    '!', '/parent-link');
end;
$$;

-- ─── Sign-in lockout: same idea ────────────────────────────────────────────

drop function public.login_gate_locked(text);
drop function public.login_gate_result(text, boolean);

-- Counts this try before the code is checked. False means locked.
create function public.login_gate_attempt(p_target_hash text) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: login_attempts has no client access.
declare
  v_row public.login_attempts;
begin
  insert into public.login_attempts as l (target_hash, wrong_count) values (p_target_hash, 1)
  on conflict (target_hash) do update set
    wrong_count = case when l.locked_until <= now() then 1 else l.wrong_count + 1 end,
    locked_until = case when l.locked_until > now() then l.locked_until end,
    updated_at = now()
  returning * into v_row;
  if v_row.locked_until > now() then return false; end if;
  if v_row.wrong_count > private.setting_int('auth.code_lock_attempts') then
    update public.login_attempts
    set locked_until = now() + make_interval(mins => private.setting_int('auth.code_lock_minutes')),
        wrong_count = 0
    where target_hash = p_target_hash;
    return false;
  end if;
  return true;
end;
$$;

create function public.login_gate_clear(p_target_hash text) returns void
language sql security definer set search_path = '' as $$
  -- Definer: login_attempts has no client access.
  delete from public.login_attempts where target_hash = p_target_hash;
$$;

revoke execute on function public.login_gate_attempt(text) from public, anon, authenticated;
revoke execute on function public.login_gate_clear(text) from public, anon, authenticated;
grant execute on function public.login_gate_attempt(text) to service_role;
grant execute on function public.login_gate_clear(text) to service_role;

-- The left of x-forwarded-for is whatever the caller sent. Cloudflare sets
-- cf-connecting-ip itself; otherwise the last hop is the one our gateway added.
create or replace function private.request_ip() returns text
language plpgsql stable set search_path = '' as $$
declare
  v_headers json;
  v_hops text[];
begin
  v_headers := nullif(current_setting('request.headers', true), '')::json;
  v_hops := string_to_array(v_headers ->> 'x-forwarded-for', ',');
  return coalesce(v_headers ->> 'cf-connecting-ip',
    trim(v_hops[array_upper(v_hops, 1)]), 'unknown');
exception when others then
  return 'unknown';
end;
$$;

-- ─── Rosters ───────────────────────────────────────────────────────────────

-- A masked minor keeps a stand-in id that only means something on this Meet,
-- so nobody can follow them from Meet to Meet or feed their id to a function.
-- People who are not on the Meet do not see minors at all (R-AGE-6).
create or replace function public.meet_players(activity uuid) returns table (
  user_id uuid, username text, full_name text, avatar_url text,
  status text, guest_name text, level numeric, sessions int,
  attendance text, walk_in boolean, paid_cash boolean,
  checked_in_at timestamptz, is_host boolean, joined_at timestamptz,
  check_in_method text
)
language sql stable security definer set search_path = '' as $$
  -- Definer: shows the Meet's roster without opening activity_participants.
  with viewer as (select auth.uid() as id)
  select case when masked
      then md5(activity::text || ap.user_id::text)::uuid else ap.user_id end,
    case when masked then null else p.username::text end,
    case when masked then private.masked_name(p.full_name) else p.full_name end,
    case when masked then null else p.avatar_url end,
    ap.status, ap.guest_name,
    case when masked then null else (select ps.level from public.player_sports ps
      where ps.user_id = ap.user_id and ps.sport = a.sports[1]) end,
    case when masked then 0 else (select count(*) from public.activity_participants x
      join public.activities y on y.id = x.activity_id
      where x.user_id = ap.user_id and x.status = 'joined'
        and y.starts_at < now())::int end,
    ap.attendance, ap.walk_in, ap.paid_cash, ap.checked_in_at,
    ap.user_id = a.host_id, ap.created_at, ap.check_in_method
  from public.activity_participants ap
  join public.activities a on a.id = ap.activity_id
  join public.profiles p on p.id = ap.user_id
  cross join viewer
  cross join lateral (
    select private.is_minor(ap.user_id)
      and ap.user_id <> viewer.id
      and a.host_id <> viewer.id
      and not private.is_guardian_of(viewer.id, ap.user_id) as masked
  ) m
  where ap.activity_id = activity and ap.status in ('joined', 'waitlist')
    and not public.is_blocked_between(viewer.id, ap.user_id)
    and (not masked or exists (select 1 from public.activity_participants me
      where me.activity_id = activity and me.user_id = viewer.id
        and me.status in ('joined', 'waitlist')))
  order by ap.user_id = a.host_id desc, ap.status, ap.queue_seq, ap.created_at;
$$;

-- A host could add any player to their own Meet and so see them unmasked.
create or replace function public.add_walk_in(activity uuid, player uuid, cash boolean)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: adds another player's row, with the checks below.
declare
  a public.activities;
begin
  select * into a from public.activities where id = activity and host_id = auth.uid() for update;
  if a.id is null then raise exception 'Only the organizer can add walk-ins.'; end if;
  if public.is_blocked_between(a.host_id, player) or private.is_restricted(player)
    or (private.is_minor(player) and not exists (select 1 from public.activity_participants ap
      where ap.activity_id = activity and ap.user_id = player)) then
    raise exception 'You can''t add this player.';
  end if;
  insert into public.activity_participants
    (activity_id, user_id, status, walk_in, paid_cash, attendance, check_in_method, checked_in_by, checked_in_at)
  values (activity, player, 'joined', true, cash, 'present', 'host', auth.uid(), now())
  on conflict (activity_id, user_id) do update
    set status = 'joined', walk_in = true, paid_cash = cash, attendance = 'present', queue_seq = null;
  perform private.refresh_game_on(activity);
  if not cash then
    insert into public.notifications (user_id, title, body, mark, link)
    select player, 'Pay for ' || a.title,
      'You were added as a walk-in. Pay in the app to get your points.',
      'S$', '/activities/' || a.id
    where a.fee_cents > 0;
  end if;
end;
$$;

create or replace function public.walk_in_candidates(activity uuid) returns table (
  user_id uuid, username text, full_name text, avatar_url text,
  level numeric, sessions int
)
language sql stable security definer set search_path = '' as $$
  -- Definer: reads who has played with this host before.
  with a as (select * from public.activities where id = activity),
  past as (
    select distinct x.user_id from public.activity_participants x
    join public.activities y on y.id = x.activity_id, a
    where x.status = 'joined'
      and (y.host_id = a.host_id or (a.club_id is not null and y.club_id = a.club_id))
  )
  select p.id, p.username::text, p.full_name, p.avatar_url,
    (select ps.level from public.player_sports ps, a
      where ps.user_id = p.id and ps.sport = a.sports[1]),
    (select count(*) from public.activity_participants x
      where x.user_id = p.id and x.status = 'joined')::int
  from past join public.profiles p on p.id = past.user_id
  where public.is_host(activity)
    and not private.is_minor(p.id)
    and not public.is_blocked_between(auth.uid(), p.id)
    and not exists (select 1 from public.activity_participants z
      where z.activity_id = activity and z.user_id = p.id and z.status = 'joined')
  order by p.full_name;
$$;

-- ─── Older functions that named minors ─────────────────────────────────────

create function private.public_name(p_user uuid) returns text
language sql stable security definer set search_path = '' as $$
  -- Definer: the one way to show a person's name to someone else.
  select case
    when private.is_minor(p.id) and p.id is distinct from auth.uid()
      and not private.is_guardian_of(auth.uid(), p.id)
    then private.masked_name(p.full_name)
    else coalesce(p.full_name, p.username::text, 'Player')
  end
  from public.profiles p where p.id = p_user;
$$;
revoke execute on function private.public_name(uuid) from public;
grant execute on function private.public_name(uuid) to authenticated, service_role;

create or replace function public.tournament_entry_name(p_entry uuid) returns text
language sql stable security definer set search_path = '' as $$
  -- Definer: called while listing entries for anyone viewing a tournament.
  select case
    when e.partner_id is null then private.public_name(e.user_id)
    else split_part(private.public_name(e.user_id), ' ', 1) || ' and '
      || split_part(private.public_name(e.partner_id), ' ', 1)
    end
  from public.tournament_entries e
  where e.id = p_entry;
$$;

create or replace function public.tournament_partner_picks(p_activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads who the caller has played with.
  with a as (select * from public.activities where id = p_activity),
  me as (select (select auth.uid()) as id),
  together as (
    select o.user_id as id, count(*)::int as n
    from public.activity_participants mine
    join public.activity_participants o
      on o.activity_id = mine.activity_id and o.user_id <> mine.user_id and o.status = 'joined'
    join public.activities x on x.id = mine.activity_id
    where mine.user_id = (select id from me) and mine.status = 'joined'
      and x.kind = 'meet' and x.sports && (select sports from a)
    group by o.user_id
  ),
  pool as (
    select id from together
    union
    select followee_id from public.follows where follower_id = (select id from me)
  )
  select coalesce(jsonb_agg(x order by (x->>'together')::int desc, x->>'name'), '[]')
  from (
    select jsonb_build_object(
      'player', public.player_json(p.id),
      'name', private.public_name(p.id),
      'level', public.tournament_level(p.id, (select sports[1] from a)),
      'together', coalesce(t.n, 0)) as x
    from pool p
    join public.profiles pr on pr.id = p.id
    left join together t on t.id = p.id
    where p.id <> (select id from me)
      and not private.is_minor(p.id)
      and not public.is_blocked_between((select id from me), p.id)
    order by coalesce(t.n, 0) desc
    limit 20
  ) s;
$$;

create or replace function public.notify_follow() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: writes a notification to the person being followed.
declare
  v_name text := private.public_name(new.follower_id);
begin
  perform public.notify(
    new.followee_id,
    v_name || ' followed you',
    'See their Passport, or follow back',
    upper(left(v_name, 1)),
    '/players/' || new.follower_id,
    '#FFE8CC',
    '#7A3B00'
  );
  return new;
end;
$$;

-- Following was the way to get a minor into a pick list. Parents still can.
create policy "Minors are not followed" on public.follows
  as restrictive for insert to authenticated
  with check (not private.is_minor(followee_id)
    or private.is_guardian_of((select auth.uid()), followee_id));

-- ─── Photos ────────────────────────────────────────────────────────────────

-- The bucket was public, so a photo loaded for anyone with its address. Now
-- each read is checked against who may see that player.
update storage.buckets set public = false where id = 'avatars';

create policy "Photos of players you can see" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and private.can_view_profile(
    ((storage.foldername(name))[1])::uuid, (select auth.uid())));

-- ─── Smaller findings ──────────────────────────────────────────────────────

-- Promotion goes through the host's approval too, and a scan after the first
-- save is an edit, so it goes in the audit log.
create or replace function private.promote_waitlist(p_activity uuid) returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: changes other players' rows and writes their notifications.
declare
  a public.activities;
  r record;
  v_left int;
  v_party int;
  v_moved int := 0;
begin
  select * into a from public.activities where id = p_activity;
  if a.id is null or a.status <> 'published' or a.starts_at < now() then
    return 0;
  end if;
  v_left := private.open_capacity(a) - public.activity_spots_taken(p_activity);
  for r in
    select * from public.activity_participants ap
    where ap.activity_id = p_activity and ap.status = 'waitlist'
    order by ap.queue_seq
  loop
    exit when v_left <= 0;
    v_party := case when r.guest_name is null then 1 else 2 end;
    continue when v_party > v_left;
    continue when public.is_blocked_between(r.user_id, a.host_id);
    continue when private.is_restricted(r.user_id);
    update public.activity_participants
    set status = case when a.approval_required then 'requested' else 'joined' end,
        queue_seq = null
    where id = r.id;
    perform public.notify(r.user_id,
      case when a.approval_required then 'Your request is with the host' else 'You''re in' end,
      'A spot opened at ' || a.title || '.', '!', '/activities/' || a.id);
    v_left := v_left - v_party;
    v_moved := v_moved + 1;
  end loop;
  perform private.refresh_game_on(p_activity);
  return v_moved;
end;
$$;

create or replace function private.mark_present(
  p_activity uuid, p_player uuid, p_actor uuid, p_method text
) returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: writes another player's row and reads the roster count.
declare
  v_before text;
  v_present int;
begin
  select attendance into v_before from public.activity_participants
  where activity_id = p_activity and user_id = p_player and status = 'joined';
  update public.activity_participants
  set attendance = 'present',
      checked_in_at = coalesce(checked_in_at, now()),
      checked_in_by = coalesce(checked_in_by, p_actor),
      check_in_method = coalesce(check_in_method, p_method)
  where activity_id = p_activity and user_id = p_player and status = 'joined';
  if not found then
    raise exception 'That player isn''t on this Meet.';
  end if;
  if v_before is distinct from 'present' and exists (
      select 1 from public.campaign_game_log l where l.activity_id = p_activity) then
    insert into public.attendance_audit (activity_id, actor, before, after)
    values (p_activity, p_actor, jsonb_build_object(p_player, v_before),
      jsonb_build_object(p_player, 'present'));
  end if;
  select count(*)::int into v_present from public.activity_participants
  where activity_id = p_activity and status = 'joined' and attendance = 'present';
  return v_present;
end;
$$;

-- Once attendance is saved, moving the Meet's date must not reopen it.
create or replace function private.activity_lock_columns() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user = 'authenticated' then
    new.status := old.status;
    new.host_id := old.host_id;
    new.kind := old.kind;
    new.scoring_snapshot := old.scoring_snapshot;
    new.game_on_at := old.game_on_at;
    if private.is_minor(old.host_id) then
      new.public_listing := false;
    end if;
    if private.attendance_saved(old.id) then
      new.starts_at := old.starts_at;
      new.ends_at := old.ends_at;
    end if;
  end if;
  return new;
end;
$$;

create function private.attendance_saved(p_activity uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: the trigger runs as the host, who may not read every log row.
  select exists (select 1 from public.campaign_game_log l where l.activity_id = p_activity);
$$;
revoke execute on function private.attendance_saved(uuid) from public;
grant execute on function private.attendance_saved(uuid) to authenticated, service_role;
