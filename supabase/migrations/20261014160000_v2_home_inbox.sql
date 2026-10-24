-- Design v2: richer activity cards, suggested players for Home, and
-- notifications for the Inbox's Updates.

-- ─── Activity cards ────────────────────────────────────────────────────────

alter table public.activities
  -- Clubs arrive with Phase 3a, which adds the foreign key.
  add column club_id uuid,
  add column ranked boolean not null default false,
  -- "Every Tue and Fri".
  add column recurrence text check (char_length(recurrence) <= 60),
  -- A line under the date, such as "Men's doubles final on Court 1 now".
  add column subtitle text check (char_length(subtitle) <= 80),
  -- Tournaments and events can carry a cover with a short title.
  add column cover_title text check (char_length(cover_title) <= 40),
  add column cover_color text check (cover_color ~ '^#[0-9A-Fa-f]{6}$'),
  add column cover_ink text check (cover_ink ~ '^#[0-9A-Fa-f]{6}$'),
  -- Tournament tier: "Regional", "National".
  add column tier text check (char_length(tier) <= 20),
  add column live boolean not null default false,
  add column online boolean not null default false,
  add column watching int not null default 0 check (watching >= 0),
  -- Event audience: "All ages", "18 and over".
  add column audience text check (char_length(audience) <= 40);

create index activities_club_idx on public.activities (club_id, starts_at)
  where club_id is not null;

-- The view expanded a.* when it was made, so rebuild it to pick up the new
-- columns.
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

-- ─── Suggested players ─────────────────────────────────────────────────────

-- Players who share a sport with me at a level inside my play range, most
-- active first. Skips people I follow, have blocked or am blocked by.
create function public.suggested_players() returns table (
  id uuid, username text, full_name text, avatar_url text,
  level numeric, sessions int
)
language sql stable security definer set search_path = '' as $$
  with mine as (
    select sport, play_min, play_max from public.player_sports
    where user_id = auth.uid()
  ),
  matches as (
    select ps.user_id, max(ps.level) as level
    from public.player_sports ps
    join mine m on m.sport = ps.sport
      and ps.level between m.play_min and m.play_max
    where ps.user_id <> auth.uid()
    group by ps.user_id
  )
  select p.id, p.username::text, p.full_name, p.avatar_url, m.level,
    (select count(*) from public.activity_participants ap
      join public.activities a on a.id = ap.activity_id
      where ap.user_id = p.id and ap.status = 'joined'
        and a.starts_at < now())::int as sessions
  from matches m
  join public.profiles p on p.id = m.user_id
  where p.onboarding_completed
    and not exists (select 1 from public.follows f
      where f.follower_id = auth.uid() and f.followee_id = p.id)
    and not public.is_blocked_between(auth.uid(), p.id)
  order by sessions desc, p.created_at desc
  limit 10;
$$;

revoke execute on function public.suggested_players() from public, anon;
grant execute on function public.suggested_players() to authenticated;

-- ─── Notifications ─────────────────────────────────────────────────────────

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  body text not null default '' check (char_length(body) <= 300),
  -- Two letters (or "!") on the row's tile, and its colours.
  mark text not null default '•' check (char_length(mark) between 1 and 3),
  color text check (color ~ '^#[0-9A-Fa-f]{6}$'),
  ink text check (ink ~ '^#[0-9A-Fa-f]{6}$'),
  square boolean not null default false,
  -- App path the row opens, such as /players/<id>.
  link text check (link like '/%' and char_length(link) <= 200),
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

create policy "Own notifications" on public.notifications
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Mark own notifications read" on public.notifications
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- Players may only mark rows read; everything else is written by the server.
revoke insert, update, delete on public.notifications from anon, authenticated;
grant update (read_at) on public.notifications to authenticated;

-- Server-side helper for triggers and functions.
create function public.notify(
  target uuid, title text, body text default '', mark text default '•',
  link text default null, color text default '#16181B', ink text default '#C6FF00'
) returns void
language sql security definer set search_path = '' as $$
  insert into public.notifications (user_id, title, body, mark, link, color, ink)
  values (target, title, body, mark, link, color, ink);
$$;
revoke execute on function public.notify(uuid, text, text, text, text, text, text)
  from public, anon, authenticated;

-- A new follower.
create function public.notify_follow() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  who public.profiles;
begin
  select * into who from public.profiles where id = new.follower_id;
  perform public.notify(
    new.followee_id,
    coalesce(who.full_name, who.username::text, 'Someone') || ' followed you',
    'See their Passport, or follow back',
    upper(left(coalesce(who.full_name, who.username::text, '?'), 1)),
    '/players/' || new.follower_id,
    '#FFE8CC',
    '#7A3B00'
  );
  return new;
end;
$$;

create trigger follows_notify after insert on public.follows
  for each row execute function public.notify_follow();

-- ─── Social games ──────────────────────────────────────────────────────────

-- Meets can be "Social": rotating partners in any format.
alter table public.activities drop constraint activities_game_type_check;
alter table public.activities add constraint activities_game_type_check
  check (game_type in ('singles', 'doubles', 'mixed', 'social'));
alter table public.play_preferences drop constraint play_preferences_game_type_check;
alter table public.play_preferences add constraint play_preferences_game_type_check
  check (game_type in ('singles', 'doubles', 'mixed', 'social'));
