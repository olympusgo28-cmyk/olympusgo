-- P3-07: the Arena leaderboards come from snapshots a job builds (R-LDR-4), by
-- sport and country. Children stay off unless a guardian opts them in.

create table public.leaderboard_consents (
  child_id uuid primary key references auth.users (id) on delete cascade,
  guardian_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.leaderboard_consents enable row level security;
revoke all on public.leaderboard_consents from anon, authenticated;
grant select on public.leaderboard_consents to authenticated;
create policy "Guardians see their consent" on public.leaderboard_consents
  for select to authenticated using (guardian_id = (select auth.uid()));

create table public.leaderboard_rows (
  board text not null check (board in ('rating', 'points')),
  sport text not null,
  country text not null,
  rank int not null,
  user_id uuid not null references auth.users (id) on delete cascade,
  level numeric(3, 1),
  games int,
  points int,
  best text,
  primary key (board, sport, country, user_id)
);
create index leaderboard_rows_rank_idx on public.leaderboard_rows (board, sport, country, rank);
alter table public.leaderboard_rows enable row level security;
revoke all on public.leaderboard_rows from anon, authenticated;

-- Checked when building and again when reading, so a consent withdrawn or a
-- suspension shows at once, not after the next build.
create function private.listable(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads consents across accounts.
  select not private.is_restricted(p_user) and (not private.is_minor(p_user) or exists (
    select 1 from public.leaderboard_consents c
    where c.child_id = p_user and private.is_guardian_of(c.guardian_id, p_user)));
$$;
revoke execute on function private.listable(uuid) from public;

create function private.leaderboards_build() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: runs from pg_cron, across every player.
begin
  delete from public.leaderboard_rows where true;

  insert into public.leaderboard_rows (board, sport, country, rank, user_id, level, games)
  select 'rating', x.sport, x.country_code, x.rank, x.user_id, private.level_of(x.rating), x.matches
  from (
    select r.sport, p.country_code, r.user_id, r.rating, r.matches,
      row_number() over (partition by r.sport, p.country_code
        order by r.rating desc, r.matches desc, r.user_id)::int as rank
    from public.ratings r
    join public.profiles p on p.id = r.user_id
    where r.matches > 0 and p.country_code is not null and private.listable(r.user_id)
  ) x
  where x.rank <= 500;

  insert into public.leaderboard_rows (board, sport, country, rank, user_id, points, best)
  with done as (
    select m.*, a.title, a.sports[1] as sport,
      (select count(*) from public.tournament_matches k
       where k.activity_id = m.activity_id and k.division = m.division
         and k.stage = 'knockout' and k.round = m.round) as size,
      exists (select 1 from public.tournament_matches t
              where t.activity_id = m.activity_id and t.division = m.division
                and t.stage = 'third') as has_third
    from public.tournament_matches m
    join public.activities a on a.id = m.activity_id
    where m.stage in ('knockout', 'third') and m.state = 'done' and m.winner is not null
      and not exists (select 1 from public.tournament_matches x
                      where x.activity_id = m.activity_id and x.division = m.division
                        and x.state <> 'done')
  ),
  finishes as (
    -- Winners of a final or 3rd place match.
    select sport, winner as entry, title, case when stage = 'third' then 50 else 100 end as pts,
      case when stage = 'third' then '3rd place' else 'Champion' end as label
    from done where stage = 'third' or size = 1
    union all
    -- Everyone who lost, at the round they went out.
    select sport, case when winner = entry_a then entry_b else entry_a end, title,
      case when stage = 'third' then 40 when size = 1 then 70
           when size = 2 and not has_third then 40 when size = 2 then null
           when size = 4 then 25 else 10 end,
      case when stage = 'third' then 'Semi-finalist' when size = 1 then 'Finalist'
           when size = 2 then 'Semi-finalist' when size = 4 then 'Quarter-finalist'
           else 'Round of ' || size * 2 end
    from done where not walkover
  ),
  per_player as (
    select f.sport, u as user_id, f.pts, f.label || ', ' || f.title as what
    from finishes f
    cross join lateral unnest(public.tournament_players(f.entry)) u
    where f.entry is not null and f.pts is not null and private.listable(u)
  ),
  totals as (
    select pp.sport, p.country_code, pp.user_id, sum(pp.pts)::int as points,
      (array_agg(pp.what order by pp.pts desc))[1] as best
    from per_player pp
    join public.profiles p on p.id = pp.user_id
    where p.country_code is not null
    group by pp.sport, p.country_code, pp.user_id
  ),
  ranked as (
    select t.*, row_number() over (partition by t.sport, t.country_code
      order by t.points desc, t.user_id)::int as rank
    from totals t
  )
  select 'points', r.sport, r.country_code, r.rank, r.user_id, r.points, r.best
  from ranked r where r.rank <= 500;
end;
$$;
revoke execute on function private.leaderboards_build() from public;
select cron.schedule('leaderboards-build', '15 * * * *', 'select private.leaderboards_build()');
select private.leaderboards_build();

-- For the operations team and local tests. No client role can call it.
create function public.leaderboards_refresh() returns void
language sql security definer set search_path = '' as $$
  -- Definer: runs the build, which reads every player.
  select private.leaderboards_build();
$$;
revoke execute on function public.leaderboards_refresh() from public, anon, authenticated;
grant execute on function public.leaderboards_refresh() to service_role;

create or replace function public.leaderboard_rating(p_sport text, p_areas text[])
returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads snapshots no client can read directly.
  with me as (
    select coalesce((select country_code from public.profiles where id = (select auth.uid())), 'SG') as country
  ),
  rows as (
    select r.user_id, r.level, r.games, r.rank
    from public.leaderboard_rows r
    where r.board = 'rating' and r.sport = p_sport and r.country = (select country from me)
      and private.listable(r.user_id)
      and not public.is_blocked_between((select auth.uid()), r.user_id)
      and (coalesce(cardinality(p_areas), 0) = 0 or exists (
        select 1 from public.club_members m join public.clubs c on c.id = m.club_id
        where m.user_id = r.user_id and c.area ilike any (p_areas)))
    order by r.rank
    limit 50
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'name', private.public_name(user_id), 'level', level, 'games', games,
    'mine', user_id = (select auth.uid())) order by rank), '[]')
  from rows;
$$;

create or replace function public.leaderboard_points(p_sport text) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads snapshots no client can read directly.
  with me as (
    select coalesce((select country_code from public.profiles where id = (select auth.uid())), 'SG') as country
  ),
  rows as (
    select r.user_id, r.points, r.best, r.rank
    from public.leaderboard_rows r
    where r.board = 'points' and r.sport = p_sport and r.country = (select country from me)
      and private.listable(r.user_id)
      and not public.is_blocked_between((select auth.uid()), r.user_id)
    order by r.rank
    limit 50
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'name', private.public_name(user_id), 'points', points, 'best', best,
    'mine', user_id = (select auth.uid())) order by rank), '[]')
  from rows;
$$;

create function public.guardian_leaderboard_set(p_child uuid, p_on boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: leaderboard_consents has no client write path.
begin
  if not private.is_guardian_of(auth.uid(), p_child) then
    raise exception 'Only a linked parent can do this.';
  end if;
  if p_on then
    insert into public.leaderboard_consents (child_id, guardian_id) values (p_child, auth.uid())
    on conflict (child_id) do update set guardian_id = excluded.guardian_id, created_at = now();
  else
    delete from public.leaderboard_consents where child_id = p_child;
  end if;
end;
$$;
revoke execute on function public.guardian_leaderboard_set(uuid, boolean) from public, anon;
grant execute on function public.guardian_leaderboard_set(uuid, boolean) to authenticated;
