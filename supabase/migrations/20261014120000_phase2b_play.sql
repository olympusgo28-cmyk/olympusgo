-- Phase 2b: Meets, tournaments and events; joining, waitlists, guests,
-- payments and check-in.

create table public.venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null,
  latitude double precision,
  longitude double precision,
  country_code text not null default 'SG'
);

insert into public.venues (name, address, latitude, longitude) values
  ('Kallang Badminton Hall', '52 Stadium Rd', 1.3036, 103.8752),
  ('Bishan Sports Hall', '5 Bishan St 14', 1.3550, 103.8510),
  ('Toa Payoh Courts', 'Lorong 6', 1.3329, 103.8478),
  ('Singapore Sports Hub', '1 Stadium Dr', 1.3040, 103.8746);

-- One table for every kind of play; columns that only one kind uses are null
-- for the others.
create table public.activities (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('meet', 'tournament', 'event')),
  host_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(title) between 3 and 80),
  description text check (char_length(description) <= 1000),
  sports text[] not null check (cardinality(sports) between 1 and 10),
  game_type text check (game_type in ('singles', 'doubles', 'mixed')),
  -- Meet: open_play, round_robin, king_of_the_court, ladder.
  -- Tournament: knockout, round_robin, groups_knockout.
  -- Event: festival, clinic, social, fundraiser.
  format text not null,
  level_min numeric(2, 1) check (level_min between 1 and 8),
  level_max numeric(2, 1) check (level_max between 1 and 8),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  venue_id uuid not null references public.venues (id),
  -- Players for a Meet, teams for a tournament, tickets for an event.
  capacity int not null check (capacity between 2 and 1000),
  courts int check (courts between 1 and 20),
  fee_cents int not null default 0 check (fee_cents between 0 and 100000),
  currency text not null default 'SGD',
  approval_required boolean not null default false,
  allow_guests boolean not null default true,
  scoring text,
  seed_by_level boolean,
  umpire_scores boolean,
  allow_refunds boolean not null default true,
  registration_closes_at timestamptz,
  status text not null default 'published' check (status in ('published', 'cancelled')),
  created_at timestamptz not null default now(),
  check (ends_at > starts_at),
  check (level_min is null or level_max is null or level_min <= level_max)
);
create index activities_upcoming_idx on public.activities (kind, starts_at) where status = 'published';
create index activities_host_idx on public.activities (host_id, starts_at);

create table public.activity_participants (
  id bigint generated always as identity primary key,
  activity_id uuid not null references public.activities (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null check (status in ('joined', 'waitlist', 'requested', 'cancelled')),
  guest_name text check (char_length(guest_name) between 1 and 60),
  guest_level numeric(2, 1),
  notify_on_opening boolean not null default true,
  checked_in_at timestamptz,
  created_at timestamptz not null default now(),
  unique (activity_id, user_id)
);
create index activity_participants_user_idx on public.activity_participants (user_id, status);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  activity_id uuid references public.activities (id) on delete set null,
  amount_cents int not null,
  platform_fee_cents int not null,
  currency text not null default 'SGD',
  method text not null check (method in ('card', 'wallet')),
  provider_reference text,
  status text not null check (status in ('pending', 'succeeded', 'refunded', 'failed')),
  receipt_no text not null unique,
  created_at timestamptz not null default now()
);

-- Which sports show as chips in Play, and their filters.
create table public.play_preferences (
  user_id uuid not null references auth.users (id) on delete cascade,
  sport text not null,
  game_type text check (game_type in ('singles', 'doubles', 'mixed')),
  level_min numeric(2, 1) not null default 1,
  level_max numeric(2, 1) not null default 8,
  position int not null default 0,
  primary key (user_id, sport)
);

-- Spots taken: joined players plus their guests.
create function public.activity_spots_taken(a uuid) returns int
language sql stable security definer set search_path = '' as $$
  select coalesce(sum(1 + (guest_name is not null)::int), 0)::int
  from public.activity_participants
  where activity_id = a and status = 'joined';
$$;

-- Cards for lists: one row per activity with counts the viewer needs.
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

-- Join a free activity (paid ones go through record_payment_and_join).
create function public.join_activity(
  activity uuid,
  guest text default null,
  guest_lvl numeric default null
) returns text
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  a public.activities;
  needed int := case when guest is null then 1 else 2 end;
  result text;
begin
  select * into a from public.activities where id = activity and status = 'published';
  if a.id is null then raise exception 'This activity is no longer available.'; end if;
  if a.starts_at < now() then raise exception 'This has already started.'; end if;
  if a.registration_closes_at is not null and a.registration_closes_at < now() then
    raise exception 'Registration has closed.';
  end if;
  if a.fee_cents > 0 then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;
  if guest is not null and not a.allow_guests then
    raise exception 'The host has turned off guests.';
  end if;
  if public.is_blocked_between(me, a.host_id) then
    raise exception 'You can''t join this activity.';
  end if;
  if public.activity_spots_taken(activity) + needed > a.capacity then
    raise exception 'It just filled up. Join the waitlist instead.';
  end if;
  result := case when a.approval_required then 'requested' else 'joined' end;
  insert into public.activity_participants (activity_id, user_id, status, guest_name, guest_level)
  values (activity, me, result, guest, guest_lvl)
  on conflict (activity_id, user_id) do update
    set status = excluded.status, guest_name = excluded.guest_name,
        guest_level = excluded.guest_level, created_at = now();
  return result;
end;
$$;

create function public.join_waitlist(activity uuid, notify boolean default true) returns int
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  pos int;
begin
  insert into public.activity_participants (activity_id, user_id, status, notify_on_opening)
  values (activity, me, 'waitlist', notify)
  on conflict (activity_id, user_id) do update
    set status = 'waitlist', notify_on_opening = notify, created_at = now()
    where public.activity_participants.status <> 'joined';
  select count(*) into pos from public.activity_participants
  where activity_id = activity and status = 'waitlist'
    and created_at <= (select created_at from public.activity_participants
                       where activity_id = activity and user_id = me);
  return pos;
end;
$$;

-- Give up a spot. Returns true when the player gets a refund (more than 24
-- hours before the start).
create function public.leave_activity(activity uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  a public.activities;
  refund boolean;
begin
  select * into a from public.activities where id = activity;
  refund := a.starts_at - now() > interval '24 hours';
  update public.activity_participants set status = 'cancelled'
  where activity_id = activity and user_id = me;
  if refund then
    update public.payments set status = 'refunded'
    where activity_id = activity and user_id = me and status = 'succeeded';
  end if;
  return refund;
end;
$$;

-- Check in at the venue by scanning the Meet's code.
create function public.check_in(activity uuid) returns int
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  here int;
begin
  update public.activity_participants set checked_in_at = coalesce(checked_in_at, now())
  where activity_id = activity and user_id = me and status = 'joined';
  if not found then raise exception 'You are not on the list for this Meet.'; end if;
  select count(*) into here from public.activity_participants
  where activity_id = activity and checked_in_at is not null;
  return here;
end;
$$;

revoke execute on function public.join_activity(uuid, text, numeric) from public, anon;
revoke execute on function public.join_waitlist(uuid, boolean) from public, anon;
revoke execute on function public.leave_activity(uuid) from public, anon;
revoke execute on function public.check_in(uuid) from public, anon;
grant execute on function public.join_activity(uuid, text, numeric) to authenticated;
grant execute on function public.join_waitlist(uuid, boolean) to authenticated;
grant execute on function public.leave_activity(uuid) to authenticated;
grant execute on function public.check_in(uuid) to authenticated;

-- Row level security.
alter table public.venues enable row level security;
alter table public.activities enable row level security;
alter table public.activity_participants enable row level security;
alter table public.payments enable row level security;
alter table public.play_preferences enable row level security;

create policy "Venues are public to players" on public.venues
  for select to authenticated using (true);

create policy "Published activities are visible" on public.activities
  for select to authenticated
  using (status = 'published' or host_id = (select auth.uid()));
create policy "Players host as themselves" on public.activities
  for insert to authenticated with check (host_id = (select auth.uid()));
create policy "Hosts edit their activities" on public.activities
  for update to authenticated
  using (host_id = (select auth.uid())) with check (host_id = (select auth.uid()));

create policy "Players see who is going" on public.activity_participants
  for select to authenticated using (true);
-- Joining and leaving only through the functions above.

create policy "Players see their own payments" on public.payments
  for select to authenticated using (user_id = (select auth.uid()));

create policy "Own play preferences" on public.play_preferences
  for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
