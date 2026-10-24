-- Tournaments: entries per event, partner invites, the draw (groups and a
-- knockout), the match schedule, scores and results.

create table public.tournament_entries (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities (id) on delete cascade,
  -- MS, WS, MD, WD, XD, or 'main' when the tournament has one event.
  division text not null check (char_length(division) between 1 and 12),
  user_id uuid not null references auth.users (id) on delete cascade,
  partner_id uuid references auth.users (id) on delete set null,
  -- The partner said yes.
  partner_ok boolean not null default false,
  status text not null default 'entered'
    check (status in ('entered', 'waitlist', 'withdrawn')),
  rating numeric(3, 1),
  seed int,
  group_name text,
  checked_in_at timestamptz,
  created_at timestamptz not null default now(),
  unique (activity_id, division, user_id)
);
create index tournament_entries_activity_idx on public.tournament_entries (activity_id, division);
create index tournament_entries_partner_idx on public.tournament_entries (partner_id)
  where partner_id is not null;

create table public.tournament_matches (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities (id) on delete cascade,
  division text not null,
  -- 'third' is the 3rd place match, played with the final.
  stage text not null check (stage in ('group', 'knockout', 'third')),
  group_name text,
  round int not null,
  slot int not null,
  entry_a uuid references public.tournament_entries (id) on delete set null,
  entry_b uuid references public.tournament_entries (id) on delete set null,
  -- Where a first-round knockout side comes from: 'A1' is the winner of
  -- Group A, 'B2' the runner-up of Group B; 'bye' means no opponent.
  src_a text,
  src_b text,
  scheduled_at timestamptz,
  court int,
  -- [[21, 15], [18, 21], [21, 17]], side A first.
  games jsonb,
  winner uuid references public.tournament_entries (id) on delete set null,
  walkover boolean not null default false,
  state text not null default 'waiting' check (state in ('waiting', 'called', 'done')),
  score_id uuid references public.match_scores (id) on delete set null,
  updated_at timestamptz not null default now()
);
create index tournament_matches_activity_idx on public.tournament_matches (activity_id, division);

alter table public.tournament_entries enable row level security;
alter table public.tournament_matches enable row level security;
-- Everything goes through the functions below.

-- ─── Helpers ───────────────────────────────────────────────────────────────

create function public.tournament_divisions(a public.activities) returns text[]
language sql immutable set search_path = '' as $$
  select case when cardinality(a.division_keys) = 0 then array['main']
              else a.division_keys end;
$$;

create function public.tournament_doubles(a public.activities, p_division text)
returns boolean
language sql immutable set search_path = '' as $$
  select case when p_division = 'main' then coalesce(a.game_type, 'doubles') <> 'singles'
              else p_division like '%D' end;
$$;

create function public.tournament_division_name(p_division text) returns text
language sql immutable set search_path = '' as $$
  select case p_division
    when 'MS' then 'Men''s singles' when 'WS' then 'Women''s singles'
    when 'MD' then 'Men''s doubles' when 'WD' then 'Women''s doubles'
    when 'XD' then 'Mixed doubles' when 'main' then 'The draw'
    else p_division end;
$$;

-- A player's level in the tournament's sport.
create function public.tournament_level(p_user uuid, p_sport text) returns numeric
language sql stable security definer set search_path = '' as $$
  select coalesce(
    (select level from public.player_sports where user_id = p_user and sport = p_sport),
    3.0);
$$;

-- The players in an entry: the entrant, and their partner once they said yes.
create function public.tournament_players(p_entry uuid) returns uuid[]
language sql stable security definer set search_path = '' as $$
  select case when e.partner_id is not null and e.partner_ok
              then array[e.user_id, e.partner_id] else array[e.user_id] end
  from public.tournament_entries e where e.id = p_entry;
$$;

-- "Ryan Teo" for singles, "Ryan and Priya" for a pair.
create function public.tournament_entry_name(p_entry uuid) returns text
language sql stable security definer set search_path = '' as $$
  select case
    when e.partner_id is null then coalesce(u.full_name, u.username::text, 'Player')
    else split_part(coalesce(u.full_name, u.username::text, 'Player'), ' ', 1) || ' and '
      || split_part(coalesce(p.full_name, p.username::text, 'Player'), ' ', 1)
    end
  from public.tournament_entries e
  join public.profiles u on u.id = e.user_id
  left join public.profiles p on p.id = e.partner_id
  where e.id = p_entry;
$$;

create function public.tournament_require_host(p_activity uuid) returns public.activities
language plpgsql stable security definer set search_path = '' as $$
declare
  a public.activities;
begin
  select * into a from public.activities where id = p_activity and kind = 'tournament';
  if not found then raise exception 'This tournament is no longer available.'; end if;
  if a.host_id <> (select auth.uid()) then
    raise exception 'Only the organizer can do this.';
  end if;
  return a;
end;
$$;

-- Games won by each side: {a, b}.
create function public.tournament_games_won(p_games jsonb) returns int[]
language sql immutable set search_path = '' as $$
  select array[
    coalesce(sum(((g->>0)::int > (g->>1)::int)::int), 0)::int,
    coalesce(sum(((g->>1)::int > (g->>0)::int)::int), 0)::int]
  from jsonb_array_elements(coalesce(p_games, '[]')) g;
$$;

-- The viewer's live entries in this tournament.
create function public.tournament_my_entries(p_activity uuid) returns setof uuid
language sql stable security definer set search_path = '' as $$
  select e.id from public.tournament_entries e
  where e.activity_id = p_activity and e.status <> 'withdrawn'
    and (e.user_id = (select auth.uid())
         or (e.partner_id = (select auth.uid()) and e.partner_ok));
$$;

-- A group's table, best first: two points for a win, then games and
-- rally points.
create function public.tournament_group_table(
  p_activity uuid, p_division text, p_group text
) returns table (entry uuid, wins int, losses int, points int, seed int)
language sql stable security definer set search_path = '' as $$
  with m as (
    select * from public.tournament_matches
    where activity_id = p_activity and division = p_division
      and stage = 'group' and group_name = p_group and state = 'done'
  ), s as (
    select e.id, e.seed, e.status,
      count(*) filter (where m.winner = e.id)::int as wins,
      count(*) filter (where m.winner is not null and m.winner <> e.id)::int as losses,
      coalesce(sum(case when m.entry_a = e.id
        then (public.tournament_games_won(m.games))[1] - (public.tournament_games_won(m.games))[2]
        else (public.tournament_games_won(m.games))[2] - (public.tournament_games_won(m.games))[1] end), 0) as gdiff,
      coalesce(sum((select sum(case when m.entry_a = e.id
          then (g->>0)::int - (g->>1)::int else (g->>1)::int - (g->>0)::int end)
        from jsonb_array_elements(coalesce(m.games, '[]')) g)), 0) as pdiff
    from public.tournament_entries e
    left join m on e.id in (m.entry_a, m.entry_b)
    where e.activity_id = p_activity and e.division = p_division and e.group_name = p_group
    group by e.id, e.seed, e.status
  )
  -- Withdrawn players drop to the bottom, so they never go through.
  select id, wins, losses, wins * 2, seed from s
  order by status = 'withdrawn', wins * 2 desc, gdiff desc, pdiff desc, seed nulls last;
$$;

-- Puts a finished match's winner into the next round, and the losing
-- semi-finalists into the 3rd place match.
create function public.tournament_advance(p_match uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  m public.tournament_matches;
  v_last int;
  v_loser uuid;
begin
  select * into m from public.tournament_matches where id = p_match;
  if m.stage <> 'knockout' or m.winner is null then return; end if;
  select max(round) into v_last from public.tournament_matches
  where activity_id = m.activity_id and division = m.division and stage = 'knockout';
  if m.round < v_last then
    if m.slot % 2 = 0 then
      update public.tournament_matches set entry_a = m.winner, updated_at = now()
      where activity_id = m.activity_id and division = m.division and stage = 'knockout'
        and round = m.round + 1 and slot = m.slot / 2;
    else
      update public.tournament_matches set entry_b = m.winner, updated_at = now()
      where activity_id = m.activity_id and division = m.division and stage = 'knockout'
        and round = m.round + 1 and slot = m.slot / 2;
    end if;
  end if;
  if m.round = v_last - 1 then
    v_loser := case when m.walkover then null
                    when m.winner = m.entry_a then m.entry_b else m.entry_a end;
    if m.slot % 2 = 0 then
      update public.tournament_matches set entry_a = v_loser, updated_at = now()
      where activity_id = m.activity_id and division = m.division and stage = 'third';
    else
      update public.tournament_matches set entry_b = v_loser, updated_at = now()
      where activity_id = m.activity_id and division = m.division and stage = 'third';
    end if;
    -- A semi-final walkover leaves the 3rd place match a side short.
    if not exists (select 1 from public.tournament_matches
                   where activity_id = m.activity_id and division = m.division
                     and stage = 'knockout' and round = v_last - 1 and state <> 'done') then
      update public.tournament_matches
      set winner = coalesce(entry_a, entry_b), state = 'done', walkover = true, updated_at = now()
      where activity_id = m.activity_id and division = m.division and stage = 'third'
        and state <> 'done' and (entry_a is null or entry_b is null);
    end if;
  end if;
end;
$$;

-- First-round byes go straight through.
create function public.tournament_settle_byes(p_activity uuid, p_division text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  m record;
begin
  for m in
    select id from public.tournament_matches
    where activity_id = p_activity and division = p_division and stage = 'knockout'
      and round = 1 and src_b = 'bye' and entry_a is not null and state <> 'done'
  loop
    update public.tournament_matches
    set winner = entry_a, state = 'done', walkover = true, updated_at = now()
    where id = m.id;
    perform public.tournament_advance(m.id);
  end loop;
end;
$$;

-- Once every match in a group is played, its top two go into the knockout.
create function public.tournament_fill_from_group(
  p_activity uuid, p_division text, p_group text
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_letter text := right(p_group, 1);
  r record;
  v_pos int := 0;
begin
  if exists (select 1 from public.tournament_matches
             where activity_id = p_activity and division = p_division
               and stage = 'group' and group_name = p_group and state <> 'done') then
    return;
  end if;
  for r in select * from public.tournament_group_table(p_activity, p_division, p_group) loop
    v_pos := v_pos + 1;
    exit when v_pos > 2;
    if exists (select 1 from public.tournament_matches
               where activity_id = p_activity and division = p_division
                 and stage = 'knockout' and round = 1 and state = 'done' and not walkover
                 and (src_a = v_letter || v_pos or src_b = v_letter || v_pos)) then
      raise exception 'The knockout has started, so this group''s result can''t change.';
    end if;
    update public.tournament_matches set entry_a = r.entry, updated_at = now()
    where activity_id = p_activity and division = p_division and stage = 'knockout'
      and round = 1 and src_a = v_letter || v_pos;
    update public.tournament_matches set entry_b = r.entry, updated_at = now()
    where activity_id = p_activity and division = p_division and stage = 'knockout'
      and round = 1 and src_b = v_letter || v_pos;
  end loop;
  perform public.tournament_settle_byes(p_activity, p_division);
end;
$$;

-- Gives every match in the division a time and court: 20-minute slots from
-- the start, as many at once as there are courts, never two at once for the
-- same player, and each knockout round after the one before.
create function public.tournament_schedule(p_activity uuid, p_division text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  a public.activities;
  v_courts int;
  m record;
  v_slot int;
  v_floor int := 0;
  v_prev_round int := -1;
  v_prev_stage text := '';
  v_court int;
  v_at timestamptz;
  v_slot_len interval := interval '20 minutes';
begin
  select * into a from public.activities where id = p_activity;
  v_courts := coalesce(a.courts, 4);
  update public.tournament_matches set scheduled_at = null, court = null
  where activity_id = p_activity and division = p_division;
  -- Start after the matches other events already hold.
  for m in
    select * from public.tournament_matches
    where activity_id = p_activity and division = p_division
      and src_b is distinct from 'bye'
    order by case stage when 'group' then 0 else 1 end, round,
             case stage when 'third' then 1 else 0 end, group_name nulls last, slot
  loop
    if m.stage <> 'group' and (v_prev_stage = 'group' or m.round <> v_prev_round)
       and not (m.stage = 'third' and v_prev_stage = 'knockout' and m.round = v_prev_round) then
      -- A new knockout round starts after everything before it.
      select coalesce(max(floor(extract(epoch from (scheduled_at - a.starts_at)) / 1200)::int) + 1, 0)
      into v_floor
      from public.tournament_matches
      where activity_id = p_activity and division = p_division and scheduled_at is not null;
    end if;
    v_prev_round := m.round;
    v_prev_stage := m.stage;
    v_slot := v_floor;
    loop
      v_at := a.starts_at + v_slot * v_slot_len;
      if (select count(*) from public.tournament_matches
          where activity_id = p_activity and scheduled_at = v_at) < v_courts
         and not exists (
           select 1 from public.tournament_matches o
           where o.activity_id = p_activity and o.scheduled_at = v_at
             and (select array_agg(x) from unnest(
                    coalesce(public.tournament_players(o.entry_a), '{}')
                    || coalesce(public.tournament_players(o.entry_b), '{}')) x)
                 && (coalesce(public.tournament_players(m.entry_a), '{}')
                     || coalesce(public.tournament_players(m.entry_b), '{}')))
      then
        exit;
      end if;
      v_slot := v_slot + 1;
    end loop;
    select min(c) into v_court from generate_series(1, v_courts) c
    where c not in (select court from public.tournament_matches
                    where activity_id = p_activity and scheduled_at = v_at and court is not null);
    update public.tournament_matches set scheduled_at = v_at, court = v_court
    where id = m.id;
  end loop;
end;
$$;

-- Bracket order for a draw of [p_size]: 1, 8, 4, 5, 2, 7, 3, 6 for eight,
-- so the top seeds meet last.
create function public.tournament_bracket(p_size int) returns int[]
language plpgsql immutable set search_path = '' as $$
declare
  arr int[] := array[1];
  nxt int[];
  n int;
  s int;
begin
  while cardinality(arr) < p_size loop
    n := cardinality(arr) * 2;
    nxt := '{}';
    foreach s in array arr loop
      nxt := nxt || array[s, n + 1 - s];
    end loop;
    arr := nxt;
  end loop;
  return arr;
end;
$$;

revoke execute on function
  public.tournament_level(uuid, text),
  public.tournament_players(uuid),
  public.tournament_entry_name(uuid),
  public.tournament_require_host(uuid),
  public.tournament_my_entries(uuid),
  public.tournament_group_table(uuid, text, text),
  public.tournament_advance(uuid),
  public.tournament_settle_byes(uuid, text),
  public.tournament_fill_from_group(uuid, text, text),
  public.tournament_schedule(uuid, text)
from public, anon, authenticated;

-- ─── Reading ───────────────────────────────────────────────────────────────

-- Counts per event, the viewer's entry, a partner invite waiting for them,
-- and whether it's over.
create function public.tournament_info(p_activity uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  a public.activities;
  v_me uuid := (select auth.uid());
  e public.tournament_entries;
  v_mine jsonb;
  v_invite jsonb;
  v_first public.tournament_matches;
begin
  select * into a from public.activities where id = p_activity and kind = 'tournament';
  if not found then raise exception 'This tournament is no longer available.'; end if;

  select * into e from public.tournament_entries
  where id in (select public.tournament_my_entries(p_activity))
  order by created_at limit 1;
  if found then
    select * into v_first from public.tournament_matches
    where state <> 'done' and e.id in (entry_a, entry_b) and scheduled_at is not null
    order by scheduled_at limit 1;
    v_mine := jsonb_build_object(
      'entry', e.id,
      'division', e.division,
      'status', e.status,
      'partner', public.player_json(case when e.user_id = v_me then e.partner_id else e.user_id end),
      'partner_ok', e.partner_ok,
      'group', e.group_name,
      'seed', e.seed,
      'first_match_at', v_first.scheduled_at,
      'first_court', v_first.court);
  end if;

  select jsonb_build_object('entry', i.id, 'division', i.division,
    'from', public.player_json(i.user_id))
  into v_invite
  from public.tournament_entries i
  where i.activity_id = p_activity and i.partner_id = v_me and not i.partner_ok
    and i.status <> 'withdrawn'
  order by i.created_at limit 1;

  return jsonb_build_object(
    'divisions', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'key', k,
        'entries', (select count(*) from public.tournament_entries
                    where activity_id = p_activity and division = k and status = 'entered'),
        'waiting', (select count(*) from public.tournament_entries
                    where activity_id = p_activity and division = k and status = 'waitlist'),
        'drawn', exists (select 1 from public.tournament_matches
                         where activity_id = p_activity and division = k))
        order by o), '[]')
      from unnest(public.tournament_divisions(a)) with ordinality as d(k, o)),
    'mine', v_mine,
    'invite', v_invite,
    'checked_in', (select count(*) from public.tournament_entries
                   where activity_id = p_activity and status = 'entered'
                     and checked_in_at is not null),
    'finished', exists (select 1 from public.tournament_matches where activity_id = p_activity)
      and not exists (select 1 from public.tournament_matches
                      where activity_id = p_activity and state <> 'done'),
    'level', public.tournament_level(v_me, a.sports[1]),
    'host', v_me = a.host_id);
end;
$$;

create function public.tournament_entry_list(p_activity uuid, p_division text)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', e.id,
    'names', public.tournament_entry_name(e.id),
    'rating', e.rating,
    'seed', e.seed,
    'status', e.status,
    'partner_pending', e.partner_id is not null and not e.partner_ok,
    'needs_partner', e.partner_id is null and public.tournament_doubles(a, e.division),
    'mine', e.id in (select public.tournament_my_entries(p_activity)),
    'checked_in', e.checked_in_at is not null,
    'group', e.group_name,
    'first_match_at', (select min(scheduled_at) from public.tournament_matches m
                       where e.id in (m.entry_a, m.entry_b)))
    order by e.status = 'waitlist', e.seed nulls last, e.rating desc nulls last, e.created_at), '[]')
  from public.tournament_entries e
  join public.activities a on a.id = e.activity_id
  where e.activity_id = p_activity and e.division = p_division and e.status <> 'withdrawn';
$$;

create function public.tournament_groups(p_activity uuid, p_division text)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'name', g.group_name,
    'rows', (select jsonb_agg(jsonb_build_object(
        'names', public.tournament_entry_name(t.entry),
        'seed', t.seed,
        'rating', (select rating from public.tournament_entries where id = t.entry),
        'wins', t.wins, 'losses', t.losses, 'points', t.points,
        'mine', t.entry in (select public.tournament_my_entries(p_activity))))
      from public.tournament_group_table(p_activity, p_division, g.group_name) t))
    order by g.group_name), '[]')
  from (select distinct group_name from public.tournament_entries
        where activity_id = p_activity and division = p_division
          and group_name is not null) g;
$$;

-- Every match in an event, or in all of them when [p_division] is null.
create function public.tournament_match_list(p_activity uuid, p_division text)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', m.id,
    'division', m.division,
    'stage', m.stage,
    'group', m.group_name,
    'round', m.round,
    'slot', m.slot,
    'a', m.entry_a, 'b', m.entry_b,
    'a_name', case when m.entry_a is not null then public.tournament_entry_name(m.entry_a) end,
    'b_name', case when m.entry_b is not null then public.tournament_entry_name(m.entry_b) end,
    'src_a', m.src_a, 'src_b', m.src_b,
    'at', m.scheduled_at,
    'court', m.court,
    'games', m.games,
    'winner', case when m.winner is null then null
                   when m.winner = m.entry_a then 'a' else 'b' end,
    'walkover', m.walkover,
    'state', m.state,
    'mine', case when m.entry_a in (select public.tournament_my_entries(p_activity)) then 'a'
                 when m.entry_b in (select public.tournament_my_entries(p_activity)) then 'b' end)
    order by m.scheduled_at nulls last, m.court), '[]')
  from public.tournament_matches m
  where m.activity_id = p_activity and (p_division is null or m.division = p_division);
$$;

-- Players to invite as a doubles partner: people the viewer follows or has
-- played Meets with, most games together first.
create function public.tournament_partner_picks(p_activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
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
      'name', pr.full_name,
      'level', public.tournament_level(p.id, (select sports[1] from a)),
      'together', coalesce(t.n, 0)) as x
    from pool p
    join public.profiles pr on pr.id = p.id
    left join together t on t.id = p.id
    where p.id <> (select id from me)
      and not public.is_blocked_between((select id from me), p.id)
    order by coalesce(t.n, 0) desc
    limit 20
  ) s;
$$;

-- ─── Entering ──────────────────────────────────────────────────────────────

create function public.tournament_register(
  p_activity uuid, p_divisions text[], p_partner uuid default null
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  a public.activities;
  v_me uuid := (select auth.uid());
  k text;
  v_doubles boolean;
  v_status text;
  v_rating numeric;
  v_name text;
begin
  select * into a from public.activities
  where id = p_activity and kind = 'tournament' and status = 'published';
  if not found then raise exception 'This tournament is no longer available.'; end if;
  if a.starts_at < now() then raise exception 'This has already started.'; end if;
  if a.registration_closes_at is not null and a.registration_closes_at < now() then
    raise exception 'Registration has closed.';
  end if;
  if a.fee_cents > 0 then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;
  if coalesce(cardinality(p_divisions), 0) = 0 then raise exception 'Choose at least one event.'; end if;
  if cardinality(p_divisions) > 2 then raise exception 'You can enter up to 2 events.'; end if;
  if public.is_blocked_between(v_me, a.host_id) then
    raise exception 'You can''t enter this tournament.';
  end if;
  if p_partner = v_me then raise exception 'Pick someone else as your partner.'; end if;
  if p_partner is not null and public.is_blocked_between(v_me, p_partner) then
    raise exception 'You can''t invite this player.';
  end if;
  select coalesce(full_name, username::text, 'A player') into v_name
  from public.profiles where id = v_me;

  foreach k in array p_divisions loop
    if not k = any (public.tournament_divisions(a)) then
      raise exception 'That event isn''t part of this tournament.';
    end if;
    v_doubles := public.tournament_doubles(a, k);
    if v_doubles and p_partner is null then raise exception 'Pick a doubles partner.'; end if;
    if exists (select 1 from public.tournament_entries
               where activity_id = p_activity and division = k and status <> 'withdrawn'
                 and (user_id = v_me or (partner_id = v_me and partner_ok))) then
      raise exception 'You''re already in %.', public.tournament_division_name(k);
    end if;
    if v_doubles and exists (
      select 1 from public.tournament_entries
      where activity_id = p_activity and division = k and status <> 'withdrawn'
        and (user_id = p_partner or (partner_id = p_partner and partner_ok))) then
      raise exception 'Your partner is already in %.', public.tournament_division_name(k);
    end if;
    if exists (select 1 from public.tournament_matches
               where activity_id = p_activity and division = k) then
      raise exception 'The draw for % is out, so it''s closed to new entries.',
        public.tournament_division_name(k);
    end if;
    v_status := case when (select count(*) from public.tournament_entries
                           where activity_id = p_activity and division = k
                             and status = 'entered') >= a.capacity
                     then 'waitlist' else 'entered' end;
    v_rating := public.tournament_level(v_me, a.sports[1]);
    insert into public.tournament_entries
      (activity_id, division, user_id, partner_id, partner_ok, status, rating)
    values (p_activity, k, v_me, case when v_doubles then p_partner end, false, v_status, v_rating)
    on conflict (activity_id, division, user_id) do update
      set partner_id = excluded.partner_id, partner_ok = false, status = excluded.status,
          rating = excluded.rating, seed = null, group_name = null, checked_in_at = null,
          created_at = now();
    if v_doubles then
      perform public.notify(
        p_partner,
        v_name || ' asked you to partner them',
        public.tournament_division_name(k) || ' · ' || a.title || '. Open it to say yes or no.',
        upper(left(v_name, 1)),
        '/activities/' || a.id,
        '#FFE8CC', '#7A3B00');
    end if;
  end loop;

  insert into public.activity_participants (activity_id, user_id, status)
  values (p_activity, v_me, 'joined')
  on conflict (activity_id, user_id) do update set status = 'joined', created_at = now();
end;
$$;

-- The invited partner says yes or no.
create function public.tournament_partner_answer(p_entry uuid, p_accept boolean)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  e public.tournament_entries;
  a public.activities;
  v_me uuid := (select auth.uid());
  v_name text;
begin
  select * into e from public.tournament_entries
  where id = p_entry and partner_id = v_me and not partner_ok and status <> 'withdrawn';
  if not found then raise exception 'This invite is no longer open.'; end if;
  select * into a from public.activities where id = e.activity_id;
  select coalesce(full_name, username::text, 'Your partner') into v_name
  from public.profiles where id = v_me;
  if p_accept then
    if exists (select 1 from public.tournament_entries
               where activity_id = e.activity_id and division = e.division
                 and status <> 'withdrawn' and id <> e.id
                 and (user_id = v_me or (partner_id = v_me and partner_ok))) then
      raise exception 'You''re already in %.', public.tournament_division_name(e.division);
    end if;
    update public.tournament_entries
    set partner_ok = true,
        rating = round((public.tournament_level(user_id, a.sports[1])
                        + public.tournament_level(v_me, a.sports[1])) / 2, 1)
    where id = e.id;
    insert into public.activity_participants (activity_id, user_id, status)
    values (e.activity_id, v_me, 'joined')
    on conflict (activity_id, user_id) do update set status = 'joined';
    perform public.notify(e.user_id, v_name || ' is your partner',
      public.tournament_division_name(e.division) || ' · ' || a.title,
      upper(left(v_name, 1)), '/activities/' || a.id, '#E3F7C8', '#2E5A00');
  else
    update public.tournament_entries set status = 'withdrawn' where id = e.id;
    if not exists (select 1 from public.tournament_entries
                   where activity_id = e.activity_id and user_id = e.user_id
                     and status <> 'withdrawn') then
      update public.activity_participants set status = 'cancelled'
      where activity_id = e.activity_id and user_id = e.user_id;
    end if;
    perform public.notify(e.user_id, v_name || ' can''t partner you',
      public.tournament_division_name(e.division) || ' · ' || a.title
        || '. Register again with someone else.',
      '!', '/activities/' || a.id);
  end if;
end;
$$;

-- Withdraws the viewer from every event. Matches they haven't played go to
-- their opponents, and the first pair waiting gets their spot if the draw
-- isn't out yet.
create function public.tournament_withdraw(p_activity uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := (select auth.uid());
  e public.tournament_entries;
  m public.tournament_matches;
  a public.activities;
  v_other uuid;
  v_next public.tournament_entries;
  v_name text;
begin
  select * into a from public.activities where id = p_activity;
  select coalesce(full_name, username::text, 'Your partner') into v_name
  from public.profiles where id = v_me;
  for e in
    select * from public.tournament_entries
    where activity_id = p_activity and status <> 'withdrawn'
      and (user_id = v_me or partner_id = v_me)
  loop
    if e.partner_id = v_me and not e.partner_ok then
      -- Only invited: turn the invite down instead.
      perform public.tournament_partner_answer(e.id, false);
      continue;
    end if;
    update public.tournament_entries set status = 'withdrawn' where id = e.id;
    for m in
      select * from public.tournament_matches
      where state <> 'done' and e.id in (entry_a, entry_b)
    loop
      v_other := case when m.entry_a = e.id then m.entry_b else m.entry_a end;
      if v_other is not null then
        update public.tournament_matches
        set winner = v_other, state = 'done', walkover = true, updated_at = now()
        where id = m.id;
        perform public.tournament_advance(m.id);
        if m.stage = 'group' then
          perform public.tournament_fill_from_group(p_activity, m.division, m.group_name);
        end if;
      end if;
    end loop;
    -- Tell the other player in the pair.
    v_other := case when e.user_id = v_me then e.partner_id else e.user_id end;
    if v_other is not null and e.partner_ok then
      perform public.notify(v_other, v_name || ' withdrew',
        public.tournament_division_name(e.division) || ' · ' || a.title,
        '!', '/activities/' || a.id);
      if not exists (select 1 from public.tournament_entries
                     where activity_id = p_activity and status <> 'withdrawn'
                       and (user_id = v_other or (partner_id = v_other and partner_ok))) then
        update public.activity_participants set status = 'cancelled'
        where activity_id = p_activity and user_id = v_other;
      end if;
    end if;
    if e.status = 'entered' and not exists (
      select 1 from public.tournament_matches
      where activity_id = p_activity and division = e.division) then
      select * into v_next from public.tournament_entries
      where activity_id = p_activity and division = e.division and status = 'waitlist'
      order by created_at limit 1;
      if found then
        update public.tournament_entries set status = 'entered' where id = v_next.id;
        perform public.notify(v_next.user_id, 'You''re in',
          'A spot opened in ' || public.tournament_division_name(e.division)
            || ' · ' || a.title, '✓', '/activities/' || a.id, '#E3F7C8', '#2E5A00');
      end if;
    end if;
  end loop;
end;
$$;

-- ─── Organizer ─────────────────────────────────────────────────────────────

create function public.tournament_check_in(p_entry uuid, p_here boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare
  e public.tournament_entries;
begin
  select * into e from public.tournament_entries where id = p_entry;
  if not found then raise exception 'This entry is no longer here.'; end if;
  perform public.tournament_require_host(e.activity_id);
  update public.tournament_entries
  set checked_in_at = case when p_here then coalesce(checked_in_at, now()) end
  where id = p_entry;
end;
$$;

-- Sends a notice to entrants: 'all', 'unchecked', or one event's key.
-- Returns how many players it reached.
create function public.tournament_message(p_activity uuid, p_to text, p_text text)
returns int
language plpgsql security definer set search_path = '' as $$
declare
  a public.activities := public.tournament_require_host(p_activity);
  v_ids uuid[];
  v_id uuid;
begin
  if char_length(trim(coalesce(p_text, ''))) not between 1 and 500 then
    raise exception 'Write a message of up to 500 characters.';
  end if;
  select array_agg(distinct x) into v_ids
  from public.tournament_entries e,
       unnest(public.tournament_players(e.id)) x
  where e.activity_id = p_activity and e.status = 'entered'
    and (p_to = 'all' or (p_to = 'unchecked' and e.checked_in_at is null)
         or e.division = p_to);
  foreach v_id in array coalesce(v_ids, '{}') loop
    perform public.notify(v_id, a.title, trim(p_text), '!', '/activities/' || a.id);
  end loop;
  return coalesce(cardinality(v_ids), 0);
end;
$$;

-- Makes (or remakes, before any score is in) one event's draw: seeds by
-- rating, then groups of about four with the top two into a knockout, a
-- straight knockout, or one round robin, as the tournament's format says.
create function public.tournament_make_draw(p_activity uuid, p_division text)
returns int
language plpgsql security definer set search_path = '' as $$
declare
  a public.activities := public.tournament_require_host(p_activity);
  v_ids uuid[];
  n int;
  g int;
  i int;
  r int;
  v_group text;
  v_members uuid[];
  v_arr uuid[];
  v_rounds int;
  v_half int;
  v_src text[] := '{}';
  v_ent uuid[] := '{}';
  q int;
  v_size int;
  v_order int[];
  v_total int;
  v_count int;
  sa int;
  sb int;
  v_player uuid;
  v_first public.tournament_matches;
  e record;
begin
  if not p_division = any (public.tournament_divisions(a)) then
    raise exception 'That event isn''t part of this tournament.';
  end if;
  if exists (select 1 from public.tournament_matches
             where activity_id = p_activity and division = p_division
               and state = 'done' and not walkover) then
    raise exception 'Scores are in already, so the draw can''t be made again.';
  end if;
  delete from public.tournament_matches where activity_id = p_activity and division = p_division;
  update public.tournament_entries set seed = null, group_name = null
  where activity_id = p_activity and division = p_division;

  -- Pairs still waiting on their partner don't make the draw.
  select array_agg(id order by rating desc nulls last, created_at) into v_ids
  from public.tournament_entries
  where activity_id = p_activity and division = p_division and status = 'entered'
    and (partner_id is null or partner_ok)
    and (not public.tournament_doubles(a, p_division) or partner_ok);
  n := coalesce(cardinality(v_ids), 0);
  if n < 2 or (a.format = 'groups_knockout' and n < 3) then
    raise exception 'There aren''t enough entries for a draw yet.';
  end if;
  for i in 1..n loop
    update public.tournament_entries set seed = i where id = v_ids[i];
  end loop;

  if a.format in ('round_robin', 'groups_knockout') then
    g := case when a.format = 'round_robin' then 1 else greatest(1, n / 4) end;
    -- Snake the seeds into groups: A B C D D C B A …
    for i in 1..n loop
      r := (i - 1) / g;
      v_group := 'Group ' || chr(65 + case when r % 2 = 0 then (i - 1) % g
                                           else g - 1 - (i - 1) % g end);
      update public.tournament_entries set group_name = v_group where id = v_ids[i];
    end loop;
    -- Everyone in a group plays everyone else (the circle method).
    for v_group in select distinct group_name from public.tournament_entries
                   where activity_id = p_activity and division = p_division
                     and group_name is not null
    loop
      select array_agg(id order by seed) into v_members from public.tournament_entries
      where activity_id = p_activity and division = p_division and group_name = v_group;
      v_arr := v_members;
      if cardinality(v_arr) % 2 = 1 then v_arr := v_arr || array[null::uuid]; end if;
      v_half := cardinality(v_arr) / 2;
      v_rounds := cardinality(v_arr) - 1;
      for r in 1..v_rounds loop
        for i in 1..v_half loop
          if v_arr[i] is not null and v_arr[cardinality(v_arr) + 1 - i] is not null then
            insert into public.tournament_matches
              (activity_id, division, stage, group_name, round, slot, entry_a, entry_b)
            values (p_activity, p_division, 'group', v_group, r, i - 1,
                    v_arr[i], v_arr[cardinality(v_arr) + 1 - i]);
          end if;
        end loop;
        v_arr := array[v_arr[1], v_arr[cardinality(v_arr)]] || v_arr[2:cardinality(v_arr) - 1];
      end loop;
    end loop;
    if a.format = 'groups_knockout' then
      -- Group winners are the top seeds; each one meets a runner-up from
      -- another group first.
      for i in 1..g loop
        v_src := v_src || (chr(64 + i) || '1');
      end loop;
      for i in reverse g..1 loop
        v_src := v_src || (chr(64 + (i % g) + 1) || '2');
      end loop;
      q := 2 * g;
    end if;
  else
    v_ent := v_ids;
    q := n;
  end if;

  if q is not null and q >= 2 then
    v_size := 2;
    while v_size < q loop v_size := v_size * 2; end loop;
    v_order := public.tournament_bracket(v_size);
    v_total := 0;
    v_count := v_size;
    while v_count > 1 loop v_total := v_total + 1; v_count := v_count / 2; end loop;
    for i in 0..(v_size / 2 - 1) loop
      sa := v_order[2 * i + 1];
      sb := v_order[2 * i + 2];
      insert into public.tournament_matches
        (activity_id, division, stage, round, slot, entry_a, entry_b, src_a, src_b)
      values (p_activity, p_division, 'knockout', 1, i,
              case when cardinality(v_ent) > 0 then v_ent[sa] end,
              case when cardinality(v_ent) > 0 and sb <= q then v_ent[sb] end,
              case when cardinality(v_src) > 0 then v_src[sa] end,
              case when sb > q then 'bye' when cardinality(v_src) > 0 then v_src[sb] end);
    end loop;
    for r in 2..v_total loop
      for i in 0..(v_size / (2 ^ r)::int - 1) loop
        insert into public.tournament_matches (activity_id, division, stage, round, slot)
        values (p_activity, p_division, 'knockout', r, i);
      end loop;
    end loop;
    -- No 3rd place match when a semi-finalist has a bye.
    if v_total >= 2 and (v_size > 4 or q = 4) then
      insert into public.tournament_matches (activity_id, division, stage, round, slot)
      values (p_activity, p_division, 'third', v_total, 0);
    end if;
  end if;

  perform public.tournament_schedule(p_activity, p_division);
  perform public.tournament_settle_byes(p_activity, p_division);

  -- Tell everyone in the draw their group and first match.
  for e in select id, group_name from public.tournament_entries
           where activity_id = p_activity and division = p_division and seed is not null
  loop
    select * into v_first from public.tournament_matches
    where e.id in (entry_a, entry_b) and state <> 'done' order by scheduled_at limit 1;
    foreach v_player in array public.tournament_players(e.id) loop
      perform public.notify(v_player,
        'The draw is out · ' || a.title,
        concat_ws(' · ', public.tournament_division_name(p_division), e.group_name,
          case when v_first.id is not null then
            'first match ' || to_char(v_first.scheduled_at at time zone 'Asia/Singapore',
                                     'Dy FMHH12:MI AM') || ', Court ' || v_first.court end),
        '★', '/activities/' || a.id, '#16181B', '#C6FF00');
    end loop;
  end loop;
  return n;
end;
$$;

-- Calls a match to its court.
create function public.tournament_call(p_match uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  m public.tournament_matches;
  a public.activities;
  v_player uuid;
begin
  select * into m from public.tournament_matches where id = p_match;
  if not found then raise exception 'This match is no longer in the draw.'; end if;
  a := public.tournament_require_host(m.activity_id);
  if m.entry_a is null or m.entry_b is null then
    raise exception 'Both sides need to be known first.';
  end if;
  if m.state = 'done' then raise exception 'This match is finished.'; end if;
  update public.tournament_matches set state = 'called', updated_at = now() where id = p_match;
  foreach v_player in array public.tournament_players(m.entry_a)
                            || public.tournament_players(m.entry_b) loop
    perform public.notify(v_player, 'You''re on Court ' || coalesce(m.court::text, '?'),
      public.tournament_entry_name(m.entry_a) || ' vs ' || public.tournament_entry_name(m.entry_b)
        || ' · ' || public.tournament_division_name(m.division),
      coalesce(m.court::text, '!'), '/activities/' || a.id, '#16181B', '#C6FF00');
  end loop;
end;
$$;

-- The umpire's score: games side A first, such as [[21, 15], [21, 18]].
-- Moves the winner on, and fills the knockout once a group is done.
create function public.tournament_score(p_match uuid, p_games jsonb) returns void
language plpgsql security definer set search_path = '' as $$
declare
  m public.tournament_matches;
  a public.activities;
  g jsonb;
  v_won int[];
  v_winner uuid;
  v_last int;
  v_score uuid;
begin
  select * into m from public.tournament_matches where id = p_match;
  if not found then raise exception 'This match is no longer in the draw.'; end if;
  a := public.tournament_require_host(m.activity_id);
  if m.entry_a is null or m.entry_b is null then
    raise exception 'Both sides need to be known first.';
  end if;
  if jsonb_typeof(p_games) <> 'array' or jsonb_array_length(p_games) not between 1 and 5 then
    raise exception 'Enter between 1 and 5 games.';
  end if;
  for g in select * from jsonb_array_elements(p_games) loop
    if jsonb_typeof(g) <> 'array' or jsonb_array_length(g) <> 2
       or jsonb_typeof(g->0) <> 'number' or jsonb_typeof(g->1) <> 'number'
       or (g->>0)::int not between 0 and 99 or (g->>1)::int not between 0 and 99 then
      raise exception 'Each game needs two scores.';
    end if;
    if (g->>0)::int = (g->>1)::int then raise exception 'A game can''t end level.'; end if;
  end loop;
  v_won := public.tournament_games_won(p_games);
  if v_won[1] = v_won[2] then raise exception 'Enter the deciding game.'; end if;
  v_winner := case when v_won[1] > v_won[2] then m.entry_a else m.entry_b end;

  if m.state = 'done' then
    -- A correction: only while the next match isn't played.
    select max(round) into v_last from public.tournament_matches
    where activity_id = m.activity_id and division = m.division and stage = 'knockout';
    if m.stage = 'knockout' and exists (
      select 1 from public.tournament_matches
      where activity_id = m.activity_id and division = m.division and state = 'done'
        and ((stage = 'knockout' and round = m.round + 1 and slot = m.slot / 2)
             or (stage = 'third' and m.round = v_last - 1))) then
      raise exception 'The next round has been played, so this score can''t change.';
    end if;
    if m.score_id is not null then
      delete from public.match_scores where id = m.score_id;
    end if;
  end if;

  if jsonb_array_length(p_games) between 2 and 3 and m.stage <> 'third' then
    insert into public.match_scores
      (activity_id, entered_by, side_a, side_b, games, status, answered_by, answered_at)
    values (m.activity_id, (select auth.uid()), public.tournament_players(m.entry_a),
            public.tournament_players(m.entry_b), p_games, 'confirmed',
            (select auth.uid()), now())
    returning id into v_score;
  end if;

  update public.tournament_matches
  set games = p_games, winner = v_winner, state = 'done', walkover = false,
      score_id = v_score, updated_at = now()
  where id = p_match;
  perform public.tournament_advance(p_match);
  if m.stage = 'group' then
    perform public.tournament_fill_from_group(m.activity_id, m.division, m.group_name);
  end if;
end;
$$;

revoke execute on function
  public.tournament_info(uuid),
  public.tournament_entry_list(uuid, text),
  public.tournament_groups(uuid, text),
  public.tournament_match_list(uuid, text),
  public.tournament_partner_picks(uuid),
  public.tournament_register(uuid, text[], uuid),
  public.tournament_partner_answer(uuid, boolean),
  public.tournament_withdraw(uuid),
  public.tournament_check_in(uuid, boolean),
  public.tournament_message(uuid, text, text),
  public.tournament_make_draw(uuid, text),
  public.tournament_call(uuid),
  public.tournament_score(uuid, jsonb)
from public, anon;
grant execute on function
  public.tournament_info(uuid),
  public.tournament_entry_list(uuid, text),
  public.tournament_groups(uuid, text),
  public.tournament_match_list(uuid, text),
  public.tournament_partner_picks(uuid),
  public.tournament_register(uuid, text[], uuid),
  public.tournament_partner_answer(uuid, boolean),
  public.tournament_withdraw(uuid),
  public.tournament_check_in(uuid, boolean),
  public.tournament_message(uuid, text, text),
  public.tournament_make_draw(uuid, text),
  public.tournament_call(uuid),
  public.tournament_score(uuid, jsonb)
to authenticated;
