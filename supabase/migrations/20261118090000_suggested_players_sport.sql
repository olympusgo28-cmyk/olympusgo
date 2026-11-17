-- The Player card shows the sport a suggestion was matched on (owner, 15 Nov
-- 2026, Q272). suggested_players() now returns it as a sport key.
--
-- The match rule, the exclusions (minors, suspended, blocked, already
-- followed, not onboarded), the order and the limit are the ones it had
-- before; only the sport is new. A player who matches on more than one sport
-- is shown with the one where their level is highest, the level the card
-- already used.
--
-- A new return type needs a new function, so this drops and recreates it and
-- sets its grants again: no execute for PUBLIC or anon.

drop function public.suggested_players();

create function public.suggested_players()
returns table (
  id uuid, username text, full_name text, avatar_url text,
  level numeric, sessions int, sport text
)
language sql stable security definer set search_path = '' as $$
  -- Definer: ranks players across the whole player_sports table.
  with mine as (
    select sport, play_min, play_max from public.player_sports
    where user_id = auth.uid()
  ),
  matches as (
    select distinct on (ps.user_id) ps.user_id, ps.level, ps.sport
    from public.player_sports ps
    join mine m on m.sport = ps.sport
      and ps.level between m.play_min and m.play_max
    where ps.user_id <> auth.uid()
    order by ps.user_id, ps.level desc, ps.sport
  )
  select p.id, p.username::text, p.full_name, p.avatar_url, m.level,
    (select count(*) from public.activity_participants ap
      join public.activities a on a.id = ap.activity_id
      where ap.user_id = p.id and ap.status = 'joined'
        and a.starts_at < now())::int as sessions,
    m.sport::text
  from matches m
  join public.profiles p on p.id = m.user_id
  where p.onboarding_completed
    and not private.is_minor(p.id) and not private.is_suspended(p.id)
    and not exists (select 1 from public.follows f
      where f.follower_id = auth.uid() and f.followee_id = p.id)
    and not public.is_blocked_between(auth.uid(), p.id)
  order by sessions desc, p.created_at desc
  limit 10;
$$;

revoke all on function public.suggested_players() from public, anon;
grant execute on function public.suggested_players() to authenticated, service_role;
