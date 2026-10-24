-- My gear, and the Game leaderboards: ratings from ranked play, and points
-- from finished tournaments.

create table public.player_gear (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  type text not null check (type in (
    'badmintonRacquet', 'tennisRacquet', 'tableTennisBat', 'pickleballPaddle', 'shoes')),
  brand text not null check (char_length(trim(brand)) between 1 and 40),
  model text not null check (char_length(trim(model)) between 1 and 60),
  -- [["Weight", "4U (83 g)"], ["String", "BG65"]]
  specs jsonb not null default '[]'
    check (jsonb_typeof(specs) = 'array' and jsonb_array_length(specs) <= 20),
  price_cents int check (price_cents between 0 and 10000000),
  created_at timestamptz not null default now()
);
create index player_gear_user_idx on public.player_gear (user_id, created_at);

alter table public.player_gear enable row level security;
create policy "Players see their own gear" on public.player_gear
  for select to authenticated using (user_id = (select auth.uid()));
create policy "Players add their own gear" on public.player_gear
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy "Players edit their own gear" on public.player_gear
  for update to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "Players remove their own gear" on public.player_gear
  for delete to authenticated using (user_id = (select auth.uid()));

-- Ratings in the viewer's country: players with at least one confirmed
-- ranked game in [p_sport], best level first. [p_areas] narrows it to
-- members of clubs in those areas; empty means the whole country.
create function public.leaderboard_rating(p_sport text, p_areas text[])
returns jsonb
language sql stable security definer set search_path = '' as $$
  with me as (
    select coalesce((select country_code from public.profiles where id = (select auth.uid())), 'SG') as country
  ),
  games as (
    select u as user_id, count(*)::int as n
    from public.match_scores s
    join public.activities a on a.id = s.activity_id
    cross join lateral unnest(s.side_a || s.side_b) u
    where s.status = 'confirmed' and p_sport = any (a.sports)
    group by u
  ),
  rows as (
    select p.id, coalesce(p.full_name, p.username::text, 'Player') as name,
      ps.level, g.n
    from public.player_sports ps
    join public.profiles p on p.id = ps.user_id
    join games g on g.user_id = ps.user_id
    where ps.sport = p_sport
      and p.country_code = (select country from me)
      and not public.is_blocked_between((select auth.uid()), p.id)
      and (coalesce(cardinality(p_areas), 0) = 0 or exists (
        select 1 from public.club_members m join public.clubs c on c.id = m.club_id
        where m.user_id = p.id and c.area ilike any (p_areas)))
    order by ps.level desc, g.n desc, name
    limit 50
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'name', name, 'level', level, 'games', n,
    'mine', id = (select auth.uid())) order by level desc, n desc, name), '[]')
  from rows;
$$;

-- Points from finished tournaments in [p_sport]: 100 for a title, 70 for
-- the final, 50 for 3rd, 40 for a semi-final, 25 for a quarter-final and 10
-- for an earlier knockout round. Each player's best finish is shown.
create function public.leaderboard_points(p_sport text) returns jsonb
language sql stable security definer set search_path = '' as $$
  with done as (
    select m.*, a.title,
      (select count(*) from public.tournament_matches k
       where k.activity_id = m.activity_id and k.division = m.division
         and k.stage = 'knockout' and k.round = m.round) as size,
      exists (select 1 from public.tournament_matches t
              where t.activity_id = m.activity_id and t.division = m.division
                and t.stage = 'third') as has_third
    from public.tournament_matches m
    join public.activities a on a.id = m.activity_id
    where p_sport = any (a.sports) and m.stage in ('knockout', 'third')
      and m.state = 'done' and m.winner is not null
      and not exists (select 1 from public.tournament_matches x
                      where x.activity_id = m.activity_id and x.division = m.division
                        and x.state <> 'done')
  ),
  finishes as (
    -- Winners of a final or 3rd place match.
    select winner as entry, title, case when stage = 'third' then 50 else 100 end as pts,
      case when stage = 'third' then '3rd place' else 'Champion' end as label
    from done where stage = 'third' or size = 1
    union all
    -- Everyone who lost, at the round they went out.
    select case when winner = entry_a then entry_b else entry_a end, title,
      case when stage = 'third' then 40 when size = 1 then 70
           when size = 2 and not has_third then 40 when size = 2 then null
           when size = 4 then 25 else 10 end,
      case when stage = 'third' then 'Semi-finalist' when size = 1 then 'Finalist'
           when size = 2 then 'Semi-finalist' when size = 4 then 'Quarter-finalist'
           else 'Round of ' || size * 2 end
    from done where not walkover
  ),
  per_player as (
    select u as user_id, f.pts, f.label || ', ' || f.title as what
    from finishes f
    cross join lateral unnest(public.tournament_players(f.entry)) u
    where f.entry is not null and f.pts is not null
  ),
  totals as (
    select user_id, sum(pts)::int as points,
      (array_agg(what order by pts desc))[1] as best
    from per_player group by user_id
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'name', coalesce(p.full_name, p.username::text, 'Player'),
    'points', t.points, 'best', t.best,
    'mine', t.user_id = (select auth.uid())) order by t.points desc, p.full_name), '[]')
  from (select * from totals order by points desc limit 50) t
  join public.profiles p on p.id = t.user_id;
$$;

revoke execute on function public.leaderboard_rating(text, text[]),
  public.leaderboard_points(text) from public, anon;
grant execute on function public.leaderboard_rating(text, text[]),
  public.leaderboard_points(text) to authenticated;
