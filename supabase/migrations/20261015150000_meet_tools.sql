-- The Play loop: refunds on leaving, the organizer's tools (players,
-- walk-ins, attendance, cancelling) and ranked scores that the other side
-- confirms.

-- ─── Columns ───────────────────────────────────────────────────────────────

alter table public.activities
  -- Recurring Meets share a series, so a cancel can cover the later ones.
  add column series_id uuid,
  add column cancel_message text check (char_length(cancel_message) <= 300);

create index activities_series_idx on public.activities (series_id, starts_at)
  where series_id is not null;

-- Meet options from the create form.
alter table public.activities
  -- Below this many sign-ups a day before, the organizer decides.
  add column min_players int check (min_players between 0 and 64),
  -- On a free Meet, players pay the S$2 platform fee (otherwise the
  -- organizer pays it for each player).
  add column players_pay_fee boolean not null default false,
  -- Show the level as numbers ("3.0–5.9") instead of bands ("LI–HI").
  add column level_numbers boolean not null default false,
  add column host_invites_only boolean not null default false,
  add column public_listing boolean not null default false;

-- Tournament and event options from the create forms.
alter table public.activities
  -- A tournament's events: MS, WS, MD, WD, XD.
  add column division_keys text[] not null default '{}',
  add column age_divisions text[] not null default '{Open}',
  add column team_entry boolean not null default false,
  add column verified_only boolean not null default false,
  add column match_check_in boolean not null default true,
  add column waitlist_when_full boolean not null default true,
  -- The event showing a tournament, or the tournament an event shows.
  add column linked_id uuid references public.activities (id) on delete set null;

-- The view expanded a.* when it was made, so rebuild it for the new columns.
drop view public.activity_cards;
create view public.activity_cards with (security_invoker = true) as
select
  a.*,
  v.name as venue_name,
  v.address as venue_address,
  p.full_name as host_name,
  public.activity_spots_taken(a.id) as spots_taken,
  (select count(*) from public.activity_participants w
    where w.activity_id = a.id and w.status = 'waitlist')::int as waitlist_count,
  (select me.status from public.activity_participants me
    where me.activity_id = a.id and me.user_id = auth.uid()) as my_status,
  (select count(*) from public.activity_participants w2
    where w2.activity_id = a.id and w2.status = 'waitlist'
      and w2.created_at <= (select me2.created_at from public.activity_participants me2
                            where me2.activity_id = a.id and me2.user_id = auth.uid()
                              and me2.status = 'waitlist'))::int as my_waitlist_position,
  (select count(*) from public.activities h
    where h.host_id = a.host_id and h.kind = 'meet')::int as host_meet_count
from public.activities a
join public.venues v on v.id = a.venue_id
join public.profiles p on p.id = a.host_id;

alter table public.activity_participants
  add column attendance text check (attendance in ('present', 'absent')),
  add column walk_in boolean not null default false,
  -- Walk-ins who paid the organizer in cash.
  add column paid_cash boolean not null default false,
  add column refund_to text check (refund_to in ('wallet', 'card')),
  add column refund_cents int check (refund_cents >= 0);

-- ─── Leaving ───────────────────────────────────────────────────────────────

-- Gives up a spot. Before the Meet starts: everything back to the Wallet,
-- or the session fee to the card (card refunds keep the platform fee).
-- Returns the refund in cents.
drop function public.leave_activity(uuid);
create function public.leave_activity(activity uuid, to_wallet boolean default true)
returns int
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  a public.activities;
  pay public.payments;
  refund int := 0;
begin
  select * into a from public.activities where id = activity;
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
  set status = 'cancelled',
      refund_to = case when refund > 0 then (case when to_wallet then 'wallet' else 'card' end) end,
      refund_cents = refund
  where activity_id = activity and user_id = me;
  return refund;
end;
$$;

-- ─── Organizer tools ───────────────────────────────────────────────────────

create function public.is_host(activity uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.activities
    where id = activity and host_id = auth.uid());
$$;

-- Who is going and who is waiting, with their level and how often they
-- play. Visible to everyone, like the faces on the Meet page.
create function public.meet_players(activity uuid) returns table (
  user_id uuid, username text, full_name text, avatar_url text,
  status text, guest_name text, level numeric, sessions int,
  attendance text, walk_in boolean, paid_cash boolean,
  checked_in_at timestamptz, is_host boolean, joined_at timestamptz
)
language sql stable security definer set search_path = '' as $$
  select ap.user_id, p.username::text, p.full_name, p.avatar_url,
    ap.status, ap.guest_name,
    (select ps.level from public.player_sports ps
      where ps.user_id = ap.user_id and ps.sport = a.sports[1]),
    (select count(*) from public.activity_participants x
      join public.activities y on y.id = x.activity_id
      where x.user_id = ap.user_id and x.status = 'joined'
        and y.starts_at < now())::int,
    ap.attendance, ap.walk_in, ap.paid_cash, ap.checked_in_at,
    ap.user_id = a.host_id, ap.created_at
  from public.activity_participants ap
  join public.activities a on a.id = ap.activity_id
  join public.profiles p on p.id = ap.user_id
  where ap.activity_id = activity and ap.status in ('joined', 'waitlist')
  order by ap.user_id = a.host_id desc, ap.status, ap.created_at;
$$;

-- The host takes a spot, or gives it up and keeps organizing. A paid spot
-- for the host costs the platform fee only, so it goes through payments.
create function public.host_plays(activity uuid, playing boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare
  a public.activities;
begin
  select * into a from public.activities where id = activity and host_id = auth.uid();
  if a.id is null then raise exception 'Only the organizer can do this.'; end if;
  if not playing then
    update public.activity_participants set status = 'cancelled'
    where activity_id = activity and user_id = a.host_id;
    return;
  end if;
  if a.fee_cents > 0 then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;
  if public.activity_spots_taken(activity) >= a.capacity then
    raise exception 'The Meet is full.';
  end if;
  insert into public.activity_participants (activity_id, user_id, status)
  values (activity, a.host_id, 'joined')
  on conflict (activity_id, user_id) do update set status = 'joined';
end;
$$;

-- Players who have played with this host or club before and are not on
-- the list yet.
create function public.walk_in_candidates(activity uuid) returns table (
  user_id uuid, username text, full_name text, avatar_url text,
  level numeric, sessions int
)
language sql stable security definer set search_path = '' as $$
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
    and not exists (select 1 from public.activity_participants z
      where z.activity_id = activity and z.user_id = p.id and z.status = 'joined')
  order by p.full_name;
$$;

-- Adds a member who turned up without joining, marked Present.
create function public.add_walk_in(activity uuid, player uuid, cash boolean)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_host(activity) then
    raise exception 'Only the organizer can add walk-ins.';
  end if;
  insert into public.activity_participants
    (activity_id, user_id, status, walk_in, paid_cash, attendance)
  values (activity, player, 'joined', true, cash, 'present')
  on conflict (activity_id, user_id) do update
    set status = 'joined', walk_in = true, paid_cash = cash, attendance = 'present';
  if not cash then
    insert into public.notifications (user_id, title, body, mark, link)
    select player, 'Pay for ' || a.title,
      'You were added as a walk-in. Pay in the app to get your points.',
      'S$', '/activities/' || a.id
    from public.activities a where a.id = activity and a.fee_cents > 0;
  end if;
end;
$$;

-- Marks who came. [marks] maps user ids to 'present', 'absent' or ''.
-- Open from the start until 11:59 PM that day.
create function public.save_attendance(activity uuid, marks jsonb) returns int
language plpgsql security definer set search_path = '' as $$
declare
  a public.activities;
  present int;
begin
  select * into a from public.activities where id = activity and host_id = auth.uid();
  if a.id is null then raise exception 'Only the organizer can mark attendance.'; end if;
  if now() < a.starts_at - interval '30 minutes' then
    raise exception 'Attendance opens 30 minutes before the start.';
  end if;
  if now() > date_trunc('day', a.starts_at) + interval '1 day' then
    raise exception 'Attendance closed at 11:59 PM on the day.';
  end if;
  update public.activity_participants ap
  set attendance = nullif(marks ->> ap.user_id::text, '')
  where ap.activity_id = activity and ap.status = 'joined'
    and marks ? ap.user_id::text;
  select count(*) into present from public.activity_participants
  where activity_id = activity and status = 'joined' and attendance = 'present';
  return present;
end;
$$;

-- The platform fee on anything paid: 10%, minimum S$2.
create function public.platform_fee_cents(amount int) returns int
language sql immutable set search_path = '' as $$
  select case when amount <= 0 then 0 else greatest(200, round(amount * 0.1)::int) end;
$$;

-- Card companies keep about 3.4% + S$0.50 of a refunded card payment.
create function public.card_fee_cents(amount int) returns int
language sql immutable set search_path = '' as $$
  select round(amount * 0.034 + 50)::int;
$$;

-- What cancelling would refund, before the organizer confirms.
create function public.cancel_preview(activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  with a as (select * from public.activities where id = activity),
  paid as (
    select pay.* from public.payments pay
    where pay.activity_id = activity and pay.status = 'succeeded'
  )
  select jsonb_build_object(
    'players', (select count(*) from public.activity_participants
      where activity_id = activity and status = 'joined' and user_id <> a.host_id),
    'each_cents', a.fee_cents + public.platform_fee_cents(a.fee_cents),
    'card_payments', (select count(*) from paid where method = 'card'),
    'card_fee_cents', coalesce((select sum(public.card_fee_cents(amount_cents))
      from paid where method = 'card'), 0),
    'later_meets', case when a.series_id is null then 1 else
      (select count(*) from public.activities s where s.series_id = a.series_id
        and s.starts_at >= a.starts_at and s.status = 'published') end,
    'last_meet', (select max(s.starts_at) from public.activities s
      where s.series_id = a.series_id and s.status = 'published')
  )
  from a where public.is_host(activity);
$$;

-- Cancels the Meet (or the rest of its series), refunds every payment in
-- full and tells the players.
create function public.cancel_activity(activity uuid, series boolean, message text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  a public.activities;
begin
  select * into a from public.activities where id = activity and host_id = auth.uid();
  if a.id is null then raise exception 'Only the organizer can cancel.'; end if;
  with gone as (
    update public.activities set status = 'cancelled', cancel_message = nullif(trim(message), '')
    where id = activity
       or (series and a.series_id is not null and series_id = a.series_id
           and starts_at >= a.starts_at and status = 'published')
    returning id, title
  ), refunded as (
    update public.payments pay set status = 'refunded'
    from gone where pay.activity_id = gone.id and pay.status = 'succeeded'
    returning pay.id
  )
  insert into public.notifications (user_id, title, body, mark, link)
  select ap.user_id, gone.title || ' is cancelled',
    coalesce(nullif(trim(message), ''), 'The organizer cancelled it. You get a full refund.'),
    '!', '/activities/' || gone.id
  from gone join public.activity_participants ap on ap.activity_id = gone.id
  where ap.status in ('joined', 'waitlist') and ap.user_id <> a.host_id;
end;
$$;

-- ─── Ranked scores ─────────────────────────────────────────────────────────

create table public.match_scores (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities (id) on delete cascade,
  entered_by uuid not null references auth.users (id) on delete cascade,
  side_a uuid[] not null check (cardinality(side_a) between 1 and 2),
  side_b uuid[] not null check (cardinality(side_b) between 1 and 2),
  -- [[21, 15], [18, 21], [21, 17]], side A first.
  games jsonb not null check (jsonb_typeof(games) = 'array' and jsonb_array_length(games) between 2 and 3),
  status text not null default 'waiting' check (status in ('waiting', 'confirmed', 'disputed')),
  reason text check (char_length(reason) <= 120),
  answered_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  answered_at timestamptz
);
create index match_scores_activity_idx on public.match_scores (activity_id);

alter table public.match_scores enable row level security;
create policy "Players in the match see its score" on public.match_scores
  for select to authenticated
  using ((select auth.uid()) = any (side_a || side_b) or public.is_host(activity_id));

-- One side enters the score; the other side is asked to confirm it.
create function public.submit_score(
  activity uuid, partners uuid[], opponents uuid[], games jsonb
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  a public.activities;
  score uuid;
  everyone uuid[] := array[me] || partners || opponents;
begin
  select * into a from public.activities where id = activity;
  if a.id is null or not a.ranked then raise exception 'Scores are for ranked games.'; end if;
  if now() < a.starts_at then raise exception 'Scores open when the Meet starts.'; end if;
  if exists (select 1 from unnest(everyone) u where not exists (
      select 1 from public.activity_participants ap
      where ap.activity_id = activity and ap.user_id = u and ap.status = 'joined')) then
    raise exception 'Everyone in the match has to be on the Meet.';
  end if;
  insert into public.match_scores (activity_id, entered_by, side_a, side_b, games)
  values (activity, me, array[me] || partners, opponents, games)
  returning id into score;
  insert into public.notifications (user_id, title, body, mark, link)
  select o, 'Confirm your score', a.title || ': is this score right?', '21',
    '/scores/' || score
  from unnest(opponents) o;
  return score;
end;
$$;

-- The other side confirms, or says why it is wrong (the organizer then
-- sets the final score).
create function public.answer_score(score uuid, ok boolean, why text default null)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  s public.match_scores;
begin
  select * into s from public.match_scores where id = score;
  if s.id is null or not auth.uid() = any (s.side_b) then
    raise exception 'Only the other side can answer this score.';
  end if;
  if s.status <> 'waiting' then raise exception 'This score has been answered.'; end if;
  update public.match_scores
  set status = case when ok then 'confirmed' else 'disputed' end,
      reason = case when ok then null else why end,
      answered_by = auth.uid(), answered_at = now()
  where id = score;
  if not ok then
    insert into public.notifications (user_id, title, body, mark, link)
    select a.host_id, 'A score needs you', coalesce(why, 'A player says a score is wrong.'),
      '!', '/activities/' || a.id
    from public.activities a where a.id = s.activity_id;
  end if;
end;
$$;

-- ─── Grants ────────────────────────────────────────────────────────────────

revoke execute on function public.leave_activity(uuid, boolean) from public, anon;
revoke execute on function public.is_host(uuid) from public, anon;
revoke execute on function public.meet_players(uuid) from public, anon;
revoke execute on function public.host_plays(uuid, boolean) from public, anon;
revoke execute on function public.walk_in_candidates(uuid) from public, anon;
revoke execute on function public.add_walk_in(uuid, uuid, boolean) from public, anon;
revoke execute on function public.save_attendance(uuid, jsonb) from public, anon;
revoke execute on function public.cancel_preview(uuid) from public, anon;
revoke execute on function public.cancel_activity(uuid, boolean, text) from public, anon;
revoke execute on function public.submit_score(uuid, uuid[], uuid[], jsonb) from public, anon;
revoke execute on function public.answer_score(uuid, boolean, text) from public, anon;
grant execute on function public.leave_activity(uuid, boolean) to authenticated;
grant execute on function public.is_host(uuid) to authenticated;
grant execute on function public.meet_players(uuid) to authenticated;
grant execute on function public.host_plays(uuid, boolean) to authenticated;
grant execute on function public.walk_in_candidates(uuid) to authenticated;
grant execute on function public.add_walk_in(uuid, uuid, boolean) to authenticated;
grant execute on function public.save_attendance(uuid, jsonb) to authenticated;
grant execute on function public.cancel_preview(uuid) to authenticated;
grant execute on function public.cancel_activity(uuid, boolean, text) to authenticated;
grant execute on function public.submit_score(uuid, uuid[], uuid[], jsonb) to authenticated;
grant execute on function public.answer_score(uuid, boolean, text) to authenticated;
