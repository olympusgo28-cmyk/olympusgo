-- Joining a Meet (P1-09), QR check-in (P1-10) and the attendance log (P1-11).
--
-- Capacity is decided inside the join function with a row lock on the
-- activity (R-MET-4). Before this, two people could pass the capacity check
-- at the same moment and both get in.

alter table public.activity_participants
  -- Order in the waitlist. Taken under the activity's row lock, so ties
  -- cannot happen, and given again on rejoining, so leaving loses your place.
  add column queue_seq bigint,
  add column checked_in_by uuid references auth.users (id) on delete set null,
  add column check_in_method text
    -- Only 'qr' is proof of a scan: the host held a live token. The others are
  -- a player's or parent's word, so they do not count as QR in the game log.
    check (check_in_method in ('qr', 'self', 'parent', 'host'));

create sequence public.activity_queue_seq;
revoke all on sequence public.activity_queue_seq from public, anon, authenticated;

update public.activity_participants
set queue_seq = nextval('public.activity_queue_seq')
where status = 'waitlist';

create index activity_participants_queue_idx
  on public.activity_participants (activity_id, queue_seq) where status = 'waitlist';

-- Seats open to joiners. Reserved slots are the host's to give out.
create function private.open_capacity(a public.activities) returns int
language sql stable set search_path = '' as $$
  select a.capacity - a.reserved_slots;
$$;
revoke execute on function private.open_capacity(public.activities) from public;

-- Announces "Game is on" once, and takes it back if the Meet drops below.
-- Call with the activity's row locked.
create function private.refresh_game_on(p_activity uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: game_on_at is closed to clients; notifications go to other players.
declare
  a public.activities;
  v_on boolean;
begin
  select * into a from public.activities where id = p_activity;
  v_on := coalesce(a.min_players, 0) > 0
    and public.activity_spots_taken(p_activity) >= a.min_players;
  if v_on and a.game_on_at is null then
    update public.activities set game_on_at = now() where id = p_activity;
    insert into public.notifications (user_id, title, body, mark, link)
    select ap.user_id, 'Game is on', a.title || ' has enough players.', '!', '/activities/' || a.id
    from public.activity_participants ap
    where ap.activity_id = p_activity and ap.status = 'joined';
  elsif not v_on and a.game_on_at is not null then
    update public.activities set game_on_at = null where id = p_activity;
  end if;
end;
$$;
revoke execute on function private.refresh_game_on(uuid) from public;

-- Moves the next eligible people in. Call with the activity's row locked.
-- Skips anyone who cannot be seated rather than holding up the queue: a pair
-- when one seat is free, someone blocked with the host, or someone restricted.
create function private.promote_waitlist(p_activity uuid) returns int
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
    update public.activity_participants set status = 'joined', queue_seq = null where id = r.id;
    perform public.notify(r.user_id, 'You''re in', 'A spot opened at ' || a.title || '.',
      '!', '/activities/' || a.id);
    v_left := v_left - v_party;
    v_moved := v_moved + 1;
  end loop;
  perform private.refresh_game_on(p_activity);
  return v_moved;
end;
$$;
revoke execute on function private.promote_waitlist(uuid) from public;

-- One function joins. Returns 'joined', 'requested' or 'waitlist'; calling it
-- again changes nothing, so a retry cannot lose a place in the queue.
create or replace function public.join_activity(
  activity uuid,
  guest text default null,
  guest_lvl numeric default null
) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: joins go only through here, so capacity cannot be sidestepped.
declare
  me uuid := auth.uid();
  a public.activities;
  v_party int := case when guest is null then 1 else 2 end;
  v_existing text;
  v_result text;
begin
  -- The lock is what makes the count below safe. Every path that changes who
  -- holds a spot takes the same lock.
  select * into a from public.activities
  where id = activity and status = 'published' for update;
  if a.id is null then raise exception 'This activity is no longer available.'; end if;
  if a.starts_at < now() then raise exception 'This has already started.'; end if;
  if a.registration_closes_at is not null and a.registration_closes_at < now() then
    raise exception 'Registration has closed.';
  end if;
  if private.is_restricted(me) then
    raise exception 'Ask a parent to link your account first.';
  end if;
  if public.is_blocked_between(me, a.host_id) then
    raise exception 'You can''t join this activity.';
  end if;
  -- Money moves from Phase 4a. Until then a Meet shows its price and players
  -- settle with the host; other kinds stay closed.
  if a.fee_cents > 0 and (a.kind <> 'meet' or private.flag('payments.enabled')) then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;
  if guest is not null and not a.allow_guests then
    raise exception 'The host has turned off guests.';
  end if;

  select ap.status into v_existing from public.activity_participants ap
  where ap.activity_id = activity and ap.user_id = me;
  if v_existing in ('joined', 'waitlist', 'requested') then
    return v_existing;
  end if;

  if public.activity_spots_taken(activity) + v_party > private.open_capacity(a) then
    if not a.waitlist_when_full then
      raise exception 'This one is full.';
    end if;
    v_result := 'waitlist';
  elsif a.approval_required then
    v_result := 'requested';
  else
    v_result := 'joined';
  end if;

  insert into public.activity_participants
    (activity_id, user_id, status, guest_name, guest_level, queue_seq)
  values (activity, me, v_result, guest, guest_lvl,
    case when v_result = 'waitlist' then nextval('public.activity_queue_seq') end)
  on conflict (activity_id, user_id) do update
    set status = excluded.status, guest_name = excluded.guest_name,
        guest_level = excluded.guest_level, queue_seq = excluded.queue_seq,
        created_at = now();

  perform private.refresh_game_on(activity);
  return v_result;
end;
$$;

-- The waitlist button. Returns your place, or 0 if you got straight in.
create or replace function public.join_waitlist(activity uuid, notify boolean default true)
returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: goes through the same lock and queue as join_activity.
declare
  me uuid := auth.uid();
  v_status text;
  v_seq bigint;
begin
  v_status := public.join_activity(activity);
  update public.activity_participants set notify_on_opening = notify
  where activity_id = activity and user_id = me;
  if v_status <> 'waitlist' then return 0; end if;
  select queue_seq into v_seq from public.activity_participants
  where activity_id = activity and user_id = me;
  return (select count(*)::int from public.activity_participants
    where activity_id = activity and status = 'waitlist' and queue_seq <= v_seq);
end;
$$;

create or replace function public.leave_activity(activity uuid, to_wallet boolean default true)
returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: leaving promotes other players, which the caller may not do.
declare
  me uuid := auth.uid();
  a public.activities;
  pay public.payments;
  refund int := 0;
begin
  select * into a from public.activities where id = activity for update;
  if a.id is null then raise exception 'This activity is no longer available.'; end if;
  select * into pay from public.payments
  where activity_id = activity and user_id = me and status = 'succeeded'
  order by created_at desc limit 1;
  if pay.id is not null and a.starts_at > now() then
    refund := case when to_wallet then pay.amount_cents
                   else pay.amount_cents - pay.platform_fee_cents end;
    update public.payments set status = 'refunded' where id = pay.id;
  end if;
  update public.activity_participants
  set status = 'cancelled', queue_seq = null,
      refund_to = case when refund > 0 then (case when to_wallet then 'wallet' else 'card' end) end,
      refund_cents = refund
  where activity_id = activity and user_id = me;
  perform private.promote_waitlist(activity);
  return refund;
end;
$$;

create or replace function public.host_plays(activity uuid, playing boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: takes or frees a spot under the same lock as joining.
declare
  a public.activities;
begin
  select * into a from public.activities where id = activity and host_id = auth.uid() for update;
  if a.id is null then raise exception 'Only the organizer can do this.'; end if;
  if not playing then
    update public.activity_participants set status = 'cancelled', queue_seq = null
    where activity_id = activity and user_id = a.host_id;
    perform private.promote_waitlist(activity);
    return;
  end if;
  if a.fee_cents > 0 and private.flag('payments.enabled') then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;
  if public.activity_spots_taken(activity) >= a.capacity then
    raise exception 'The Meet is full.';
  end if;
  insert into public.activity_participants (activity_id, user_id, status)
  values (activity, a.host_id, 'joined')
  on conflict (activity_id, user_id) do update set status = 'joined', queue_seq = null;
  perform private.refresh_game_on(activity);
end;
$$;

-- Raising capacity or freeing reserved slots opens seats too.
create function private.activity_seats_changed() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: promotes players the host does not own.
begin
  if new.capacity > old.capacity or new.reserved_slots < old.reserved_slots then
    perform private.promote_waitlist(new.id);
  end if;
  return new;
end;
$$;

create trigger activities_seats_changed after update of capacity, reserved_slots
  on public.activities
  for each row execute function private.activity_seats_changed();

-- ─── What the roster shows ─────────────────────────────────────────────────

-- Reads the waitlist for the cards below. A view running as the caller cannot
-- count rows the caller is not allowed to see.
create function public.activity_waitlist_count(a uuid) returns int
language sql stable security definer set search_path = '' as $$
  select count(*)::int from public.activity_participants
  where activity_id = a and status = 'waitlist';
$$;

create function public.activity_my_position(a uuid) returns int
language sql stable security definer set search_path = '' as $$
  -- Definer: counts the other waitlisted players ahead of the caller.
  select (select count(*)::int from public.activity_participants w
    where w.activity_id = a and w.status = 'waitlist' and w.queue_seq <= me.queue_seq)
  from public.activity_participants me
  where me.activity_id = a and me.user_id = auth.uid() and me.status = 'waitlist';
$$;

revoke execute on function public.activity_waitlist_count(uuid) from public, anon;
revoke execute on function public.activity_my_position(uuid) from public, anon;
grant execute on function public.activity_waitlist_count(uuid) to authenticated;
grant execute on function public.activity_my_position(uuid) to authenticated;

drop view public.activity_cards;
create view public.activity_cards with (security_invoker = true) as
select
  a.*,
  v.name as venue_name,
  v.address as venue_address,
  p.full_name as host_name,
  public.activity_spots_taken(a.id) as spots_taken,
  public.activity_waitlist_count(a.id) as waitlist_count,
  (select me.status from public.activity_participants me
    where me.activity_id = a.id and me.user_id = auth.uid()) as my_status,
  public.activity_my_position(a.id) as my_waitlist_position,
  (select count(*) from public.activities h
    where h.host_id = a.host_id and h.kind = 'meet')::int as host_meet_count,
  coalesce(a.min_players, 0) > 0
    and public.activity_spots_taken(a.id) >= a.min_players as game_is_on
from public.activities a
join public.venues v on v.id = a.venue_id
join public.profiles p on p.id = a.host_id;

-- Who is going. Minors show as "Mei T." with no photo or username, except to
-- the host, who has to recognise them, and to their own parent. Blocked
-- players are left out both ways.
drop function public.meet_players(uuid);
create function public.meet_players(activity uuid) returns table (
  user_id uuid, username text, full_name text, avatar_url text,
  status text, guest_name text, level numeric, sessions int,
  attendance text, walk_in boolean, paid_cash boolean,
  checked_in_at timestamptz, is_host boolean, joined_at timestamptz,
  check_in_method text
)
language sql stable security definer set search_path = '' as $$
  -- Definer: shows the Meet's roster without opening activity_participants.
  with viewer as (select auth.uid() as id)
  select ap.user_id,
    case when masked then null else p.username::text end,
    case when masked then private.masked_name(p.full_name) else p.full_name end,
    case when masked then null else p.avatar_url end,
    ap.status, ap.guest_name,
    (select ps.level from public.player_sports ps
      where ps.user_id = ap.user_id and ps.sport = a.sports[1]),
    (select count(*) from public.activity_participants x
      join public.activities y on y.id = x.activity_id
      where x.user_id = ap.user_id and x.status = 'joined'
        and y.starts_at < now())::int,
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
  order by ap.user_id = a.host_id desc, ap.status, ap.queue_seq, ap.created_at;
$$;
revoke execute on function public.meet_players(uuid) from public, anon;
grant execute on function public.meet_players(uuid) to authenticated;

-- ─── Player QR ─────────────────────────────────────────────────────────────

-- The QR shows this token, never a user id or username. Rotating it makes
-- every old screenshot worthless.
create table public.player_qr_tokens (
  user_id uuid primary key references auth.users (id) on delete cascade,
  token text not null unique,
  rotated_at timestamptz not null default now()
);
alter table public.player_qr_tokens enable row level security;
revoke all on public.player_qr_tokens from anon, authenticated;
-- No policies and no grants: only the functions below touch tokens.

create function private.new_qr_token() returns text
language sql volatile set search_path = '' as $$
  select encode(extensions.gen_random_bytes(24), 'hex');
$$;
revoke execute on function private.new_qr_token() from public;

create function public.my_qr() returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: player_qr_tokens has no client policies.
declare
  me uuid := auth.uid();
  v_token text;
begin
  if private.is_restricted(me) then
    raise exception 'Ask a parent to link your account first.';
  end if;
  insert into public.player_qr_tokens (user_id, token)
  values (me, private.new_qr_token())
  on conflict (user_id) do nothing;
  select token into v_token from public.player_qr_tokens where user_id = me;
  return v_token;
end;
$$;

create function public.rotate_my_qr() returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: player_qr_tokens has no client policies.
declare
  me uuid := auth.uid();
  v_token text := private.new_qr_token();
begin
  if private.is_restricted(me) then
    raise exception 'Ask a parent to link your account first.';
  end if;
  insert into public.player_qr_tokens (user_id, token) values (me, v_token)
  on conflict (user_id) do update set token = excluded.token, rotated_at = now();
  return v_token;
end;
$$;

-- What a scan opens. Under-13s cannot scan; nobody learns anything about a
-- minor or a blocked player from a scan. Not marked stable: the gate writes a
-- rate-limit row for it, which a read-only transaction would refuse.
create function public.resolve_qr(p_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: maps a token to a player without exposing the token table.
declare
  me uuid := auth.uid();
  v_target uuid;
  v_username text;
begin
  if private.is_restricted(me) or private.audience_of(me) = 'child' then
    raise exception 'Ask a parent to scan for you.';
  end if;
  select user_id into v_target from public.player_qr_tokens where token = p_token;
  if v_target is null or not private.can_view_profile(v_target, me) then
    raise exception 'That code isn''t valid.';
  end if;
  select username::text into v_username from public.profiles where id = v_target;
  return jsonb_build_object('kind', 'player', 'username', v_username);
end;
$$;

revoke execute on function public.my_qr() from public, anon;
revoke execute on function public.rotate_my_qr() from public, anon;
revoke execute on function public.resolve_qr(text) from public, anon;
grant execute on function public.my_qr() to authenticated;
grant execute on function public.rotate_my_qr() to authenticated;
grant execute on function public.resolve_qr(text) to authenticated;

-- R-ATT-1: opens 30 minutes before the start, closes at 23:59 at the venue.
create function private.attendance_open(a public.activities) returns boolean
language plpgsql stable set search_path = '' as $$
declare
  v_tz text := private.activity_tz(a.id);
  v_closes timestamptz :=
    (date_trunc('day', a.starts_at at time zone v_tz) + interval '1 day') at time zone v_tz;
begin
  return now() >= a.starts_at - make_interval(mins => private.setting_int('meet.attendance_opens_minutes'))
    and now() < v_closes;
end;
$$;
revoke execute on function private.attendance_open(public.activities) from public;
grant execute on function private.attendance_open(public.activities) to authenticated;

-- Writes one player as Present. The first check-in stands; a second scan
-- reports the same result and changes nothing.
create function private.mark_present(
  p_activity uuid, p_player uuid, p_actor uuid, p_method text
) returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: writes another player's row and reads the roster count.
declare
  v_present int;
begin
  update public.activity_participants
  set attendance = 'present',
      checked_in_at = coalesce(checked_in_at, now()),
      checked_in_by = coalesce(checked_in_by, p_actor),
      check_in_method = coalesce(check_in_method, p_method)
  where activity_id = p_activity and user_id = p_player and status = 'joined';
  if not found then
    raise exception 'That player isn''t on this Meet.';
  end if;
  select count(*)::int into v_present from public.activity_participants
  where activity_id = p_activity and status = 'joined' and attendance = 'present';
  return v_present;
end;
$$;
revoke execute on function private.mark_present(uuid, uuid, uuid, text) from public;

-- The host scans a player's QR.
create function public.host_check_in(p_activity uuid, p_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: resolves a token the host cannot read and writes the player's row.
declare
  me uuid := auth.uid();
  a public.activities;
  v_player uuid;
  v_present int;
  v_name text;
begin
  select * into a from public.activities where id = p_activity for update;
  if a.id is null or a.host_id <> me then
    raise exception 'Only the organizer can check players in.';
  end if;
  if not private.attendance_open(a) then
    raise exception 'Check-in opens 30 minutes before the start.';
  end if;
  select user_id into v_player from public.player_qr_tokens where token = p_token;
  if v_player is null then raise exception 'That code isn''t valid.'; end if;
  v_present := private.mark_present(p_activity, v_player, me, 'qr');
  select coalesce(p.full_name, 'Player') into v_name from public.profiles p where p.id = v_player;
  return jsonb_build_object('name', v_name, 'present', v_present);
end;
$$;

-- A parent scans the Meet's code for a child who cannot scan.
create function public.guardian_check_in(p_activity uuid, p_child uuid) returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the child's row on behalf of their linked parent.
declare
  me uuid := auth.uid();
  a public.activities;
begin
  if not private.is_guardian_of(me, p_child) then
    raise exception 'Only a linked parent can do this.';
  end if;
  select * into a from public.activities where id = p_activity for update;
  if a.id is null then raise exception 'This activity is no longer available.'; end if;
  if not private.attendance_open(a) then
    raise exception 'Check-in opens 30 minutes before the start.';
  end if;
  return private.mark_present(p_activity, p_child, me, 'parent');
end;
$$;

-- A player scans the Meet's code themselves. Under-13s cannot scan.
create or replace function public.check_in(activity uuid) returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: writes attendance, which players cannot set directly.
declare
  me uuid := auth.uid();
  a public.activities;
begin
  if private.is_restricted(me) or private.audience_of(me) = 'child' then
    raise exception 'Ask a parent to scan for you.';
  end if;
  select * into a from public.activities where id = activity for update;
  if a.id is null then raise exception 'This activity is no longer available.'; end if;
  if not private.attendance_open(a) then
    raise exception 'Check-in opens 30 minutes before the start.';
  end if;
  return private.mark_present(activity, me, me, 'self');
end;
$$;

revoke execute on function public.host_check_in(uuid, text) from public, anon;
revoke execute on function public.guardian_check_in(uuid, uuid) from public, anon;
grant execute on function public.host_check_in(uuid, text) to authenticated;
grant execute on function public.guardian_check_in(uuid, uuid) to authenticated;

-- ─── Attendance and the counted-game log ───────────────────────────────────

-- One row per saved session, from day one, even before vouchers exist.
-- Vouchers read this later to work out which games counted. Holds opaque ids
-- only, with no link to auth.users, so it outlives a deleted account.
create table public.campaign_game_log (
  id bigint generated always as identity primary key,
  activity_id uuid not null unique,
  host_id uuid not null,
  present_count int not null,
  -- [{"player": id, "present": true, "paid": false, "qr": true}]
  players jsonb not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  saved_at timestamptz not null default now()
);

-- Every change after the first save.
create table public.attendance_audit (
  id bigint generated always as identity primary key,
  activity_id uuid not null,
  actor uuid not null,
  before jsonb not null,
  after jsonb not null,
  at timestamptz not null default now()
);

create trigger campaign_game_log_append_only before update or delete on public.campaign_game_log
  for each row execute function private.forbid_change();
create trigger campaign_game_log_no_truncate before truncate on public.campaign_game_log
  for each statement execute function private.forbid_change();
create trigger attendance_audit_append_only before update or delete on public.attendance_audit
  for each row execute function private.forbid_change();
create trigger attendance_audit_no_truncate before truncate on public.attendance_audit
  for each statement execute function private.forbid_change();

alter table public.campaign_game_log enable row level security;
alter table public.attendance_audit enable row level security;

create policy "Hosts read their own game log" on public.campaign_game_log
  for select to authenticated using (host_id = (select auth.uid()));
create policy "Hosts read their own attendance changes" on public.attendance_audit
  for select to authenticated using (actor = (select auth.uid()));

create or replace function public.save_attendance(activity uuid, marks jsonb) returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: writes other players' rows and the append-only tables.
declare
  a public.activities;
  v_before jsonb;
  v_after jsonb;
  v_present int;
  v_players jsonb;
begin
  select * into a from public.activities
  where id = activity and host_id = auth.uid() for update;
  if a.id is null then raise exception 'Only the organizer can mark attendance.'; end if;
  if not private.attendance_open(a) then
    if now() < a.starts_at then
      raise exception 'Attendance opens 30 minutes before the start.';
    end if;
    raise exception 'Attendance closed at 11:59 PM on the day.';
  end if;

  select coalesce(jsonb_object_agg(user_id, attendance), '{}'::jsonb) into v_before
  from public.activity_participants where activity_id = activity and status = 'joined';

  update public.activity_participants ap
  set attendance = nullif(marks ->> ap.user_id::text, ''),
      checked_in_at = case when marks ->> ap.user_id::text = 'present'
        then coalesce(ap.checked_in_at, now()) else ap.checked_in_at end,
      checked_in_by = case when marks ->> ap.user_id::text = 'present'
        then coalesce(ap.checked_in_by, auth.uid()) else ap.checked_in_by end,
      check_in_method = case when marks ->> ap.user_id::text = 'present'
        then coalesce(ap.check_in_method, 'host') else ap.check_in_method end
  where ap.activity_id = activity and ap.status = 'joined'
    and marks ? ap.user_id::text;

  select coalesce(jsonb_object_agg(user_id, attendance), '{}'::jsonb) into v_after
  from public.activity_participants where activity_id = activity and status = 'joined';

  select count(*)::int into v_present from public.activity_participants
  where activity_id = activity and status = 'joined' and attendance = 'present';

  select coalesce(jsonb_agg(jsonb_build_object(
    'player', ap.user_id,
    'present', ap.attendance = 'present',
    'paid', exists (select 1 from public.payments pay
      where pay.activity_id = activity and pay.user_id = ap.user_id and pay.status = 'succeeded'),
    'qr', coalesce(ap.check_in_method = 'qr', false)
  ) order by ap.user_id), '[]'::jsonb) into v_players
  from public.activity_participants ap
  where ap.activity_id = activity and ap.status = 'joined';

  insert into public.campaign_game_log
    (activity_id, host_id, present_count, players, starts_at, ends_at)
  values (activity, a.host_id, v_present, v_players, a.starts_at, a.ends_at)
  on conflict (activity_id) do nothing;

  -- found is false when a log row was already there: this is a late edit.
  if not found and v_before is distinct from v_after then
    insert into public.attendance_audit (activity_id, actor, before, after)
    values (activity, auth.uid(), v_before, v_after);
  end if;
  return v_present;
end;
$$;
