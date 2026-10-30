-- P3-01, P3-03, P3-04. Every confirmed score, from any path, passes through
-- match_scores, so the triggers here are the one place a score is validated, a
-- permanent result is written and a rating moves. Nothing can skip them.

insert into public.app_settings (key, value, description) values
  ('rating.k_new', '32', 'K for a player''s first matches (owner, 31 Oct)'),
  ('rating.k_settled', '20', 'K once settled (owner, 31 Oct)'),
  ('rating.settled_after', '30', 'Matches before a player is settled'),
  ('rating.start', '1500', 'Rating of level 4.0'),
  ('rating.points_per_level', '100', 'Rating points in one level (Q52)'),
  ('rating.repeat_window_days', '30', 'Days a repeat opponent counts less (R-RAT-5)'),
  ('rating.repeat_factor_pct', '75', 'Each repeat counts this percent of the last (Q52)'),
  ('rating.provisional_matches', '5', 'Matches before a level stops being provisional (R-RAT-4)'),
  ('score.confirm_hours', '24', 'Hours to confirm before it goes to the organiser (R-SCO-2)'),
  ('score.correction_hours', '24', 'Hours an organiser can correct a result (R-SCO-3)');

-- ─── Presets (P3-01) ───────────────────────────────────────────────────────

create table public.scoring_presets (
  key text primary key,
  sport_key text not null references public.sports (key) on update cascade,
  name text not null,
  rules jsonb not null,
  active boolean not null default true
);
alter table public.scoring_presets enable row level security;
create policy "Scoring presets are visible" on public.scoring_presets
  for select to anon, authenticated using (true);
create trigger scoring_presets_audit after insert or update or delete on public.scoring_presets
  for each row execute function private.audit_catalog();
insert into private.restricted_allow (path) values ('/scoring_presets');

-- Open decision 20: the owner chose 15 points, cap 21, on 31 Oct.
insert into public.scoring_presets (key, sport_key, name, rules, active) values
  ('badminton_standard', 'badminton', 'Badminton', '{"points_to_win": 21, "win_by": 2, "cap": 30, "best_of": 3}', true),
  ('badminton_junior_15', 'badminton', 'Junior, 15 points', '{"points_to_win": 15, "win_by": 2, "cap": 21, "best_of": 3}', true),
  ('badminton_junior_11', 'badminton', 'Junior, 11 points', '{"points_to_win": 11, "win_by": 2, "cap": 15, "best_of": 3}', false),
  ('pickleball_standard', 'pickleball', 'Pickleball', '{"points_to_win": 11, "win_by": 2, "best_of": 3}', true);

-- ─── Generated rounds and permanent results ────────────────────────────────

create table public.matches (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities (id) on delete cascade,
  round int not null check (round >= 1),
  court int not null check (court >= 1),
  side_a uuid[] not null,
  side_b uuid[] not null,
  byes uuid[] not null default '{}',
  created_at timestamptz not null default now(),
  unique (activity_id, round, court)
);
alter table public.matches enable row level security;
revoke all on public.matches from anon, authenticated;

-- R-SCO-3: a result is never changed. A correction is a new row.
create table public.match_results (
  id uuid primary key default gen_random_uuid(),
  score_id uuid not null unique,
  activity_id uuid not null,
  sport text not null,
  side_a uuid[] not null,
  side_b uuid[] not null,
  games jsonb not null,
  winner smallint not null check (winner in (1, 2)),
  ranked boolean not null,
  supersedes uuid references public.match_results (id),
  retired_side smallint,
  reason text,
  confirmed_at timestamptz not null default now()
);
create index match_results_players_idx on public.match_results using gin ((side_a || side_b));
create trigger match_results_append_only before update or delete on public.match_results
  for each row execute function private.forbid_change();
create trigger match_results_no_truncate before truncate on public.match_results
  for each statement execute function private.forbid_change();
alter table public.match_results enable row level security;
revoke all on public.match_results from anon, authenticated;
grant select on public.match_results to authenticated;
create policy "Players see their own results" on public.match_results
  for select to authenticated
  using ((select auth.uid()) = any (side_a || side_b) or public.is_host(activity_id));

alter table public.match_scores drop constraint match_scores_games_check;
alter table public.match_scores add constraint match_scores_games_check
  check (jsonb_typeof(games) = 'array' and jsonb_array_length(games) between 1 and 5);
alter table public.match_scores drop constraint match_scores_status_check;
alter table public.match_scores add constraint match_scores_status_check
  check (status in ('waiting', 'confirmed', 'disputed', 'superseded'));
alter table public.match_scores
  add column client_key uuid,
  add column supersedes uuid references public.match_scores (id),
  add column retired_side smallint check (retired_side in (1, 2));
create unique index match_scores_client_idx on public.match_scores (entered_by, client_key);

-- ─── Ratings (P3-04) ───────────────────────────────────────────────────────

create table public.ratings (
  user_id uuid not null references auth.users (id) on delete cascade,
  sport text not null references public.sports (key) on update cascade,
  rating numeric(8, 2) not null,
  matches int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, sport)
);

create table public.rating_events (
  id bigint generated always as identity primary key,
  result_id uuid not null references public.match_results (id),
  user_id uuid not null,
  sport text not null,
  before numeric(8, 2) not null,
  delta numeric(8, 2) not null,
  after numeric(8, 2) not null,
  reversal boolean not null default false,
  at timestamptz not null default now(),
  unique (result_id, user_id, reversal)
);
create index rating_events_user_idx on public.rating_events (user_id, sport, at);
create trigger rating_events_append_only before update or delete on public.rating_events
  for each row execute function private.forbid_change();
create trigger rating_events_no_truncate before truncate on public.rating_events
  for each statement execute function private.forbid_change();

alter table public.ratings enable row level security;
alter table public.rating_events enable row level security;
revoke all on public.ratings, public.rating_events from anon, authenticated;
grant select on public.ratings, public.rating_events to authenticated;
create policy "Ratings of visible players" on public.ratings
  for select to authenticated using (private.can_view_profile(user_id, (select auth.uid())));
create policy "Own rating history" on public.rating_events
  for select to authenticated
  using (user_id = (select auth.uid()) or private.is_guardian_of((select auth.uid()), user_id));

create function private.level_of(p_rating numeric) returns numeric
language sql stable security definer set search_path = '' as $$
  -- Definer: reads settings for any caller.
  select greatest(1.0, least(8.0, round(4.0 + (p_rating - private.setting_int('rating.start'))
    / private.setting_int('rating.points_per_level')::numeric, 1)));
$$;
revoke execute on function private.level_of(numeric) from public;
grant execute on function private.level_of(numeric) to authenticated, service_role;

-- The self-declared level only seeds the rating. Once a rating exists, level
-- follows it, whatever a client sends. Leaderboards and seeding read level, so
-- they now rest on results and cannot be set by hand.
alter table public.player_sports drop constraint player_sports_level_check;
alter table public.player_sports add constraint player_sports_level_check check (level between 1 and 8);

create function private.player_sport_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: ratings cannot be read for every player by the caller.
declare
  v numeric;
begin
  select rating into v from public.ratings where user_id = new.user_id and sport = new.sport;
  if v is not null then new.level := private.level_of(v); end if;
  return new;
end;
$$;
create trigger player_sports_guard before insert or update on public.player_sports
  for each row execute function private.player_sport_guard();

-- A player's row, made from their declared level the first time.
create function private.rating_row(p_user uuid, p_sport text) returns public.ratings
language plpgsql security definer set search_path = '' as $$
-- Definer: ratings has no client write path.
declare
  r public.ratings;
  v_level numeric;
begin
  select * into r from public.ratings where user_id = p_user and sport = p_sport for update;
  if r.user_id is not null then return r; end if;
  select level into v_level from public.player_sports where user_id = p_user and sport = p_sport;
  insert into public.ratings (user_id, sport, rating)
  values (p_user, p_sport, private.setting_int('rating.start')
    -- R-RAT-3: nobody can place themselves above AD.
    + (least(coalesce(v_level, 4.0), 7.0) - 4.0) * private.setting_int('rating.points_per_level'))
  on conflict (user_id, sport) do nothing;
  select * into r from public.ratings where user_id = p_user and sport = p_sport for update;
  return r;
end;
$$;

create function private.rating_write(
  p_result uuid, p_user uuid, p_sport text, p_delta numeric, p_reversal boolean
) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: ratings has no client write path.
declare
  r public.ratings := private.rating_row(p_user, p_sport);
  v_after numeric := r.rating + p_delta;
begin
  update public.ratings
  set rating = v_after, matches = greatest(0, matches + case when p_reversal then -1 else 1 end),
      updated_at = now()
  where user_id = p_user and sport = p_sport;
  insert into public.rating_events (result_id, user_id, sport, before, delta, after, reversal)
  values (p_result, p_user, p_sport, r.rating, p_delta, v_after, p_reversal);
  update public.player_sports set level = private.level_of(v_after)
  where user_id = p_user and sport = p_sport;
end;
$$;

create function private.rating_apply(p_result public.match_results) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: ratings has no client write path. Runs once per result: the unique
-- key on rating_events refuses a second go.
declare
  v_everyone uuid[] := p_result.side_a || p_result.side_b;
  v_kind text;
  v_avg_a numeric;
  v_avg_b numeric;
  v_expected_a double precision;
  v_factor double precision;
  v_repeats int;
  v_score double precision;
  v_expected double precision;
  u uuid;
  r public.ratings;
  v_k int;
begin
  if not p_result.ranked then return; end if;
  select kind into v_kind from public.activities where id = p_result.activity_id;
  -- Only attended players: everyone must be marked Present on a Meet.
  if v_kind = 'meet' and exists (select 1 from unnest(v_everyone) x
      where not exists (select 1 from public.activity_participants ap
        where ap.activity_id = p_result.activity_id and ap.user_id = x and ap.attendance = 'present')) then
    return;
  end if;

  -- Lock in one order, so two confirmations can't deadlock.
  perform private.rating_row(x, p_result.sport) from unnest(v_everyone) x order by x;

  select avg(rating) into v_avg_a from unnest(p_result.side_a) x
    cross join lateral private.rating_row(x, p_result.sport);
  select avg(rating) into v_avg_b from unnest(p_result.side_b) x
    cross join lateral private.rating_row(x, p_result.sport);
  v_expected_a := 1 / (1 + power(10::double precision, (v_avg_b - v_avg_a)::double precision / 400));

  -- R-RAT-5: the same two sides again count less each time.
  select count(*) into v_repeats from public.match_results m
  where m.id <> p_result.id and m.sport = p_result.sport and m.ranked
    and m.confirmed_at > now() - make_interval(days => private.setting_int('rating.repeat_window_days'))
    and ((m.side_a @> p_result.side_a and m.side_a <@ p_result.side_a
          and m.side_b @> p_result.side_b and m.side_b <@ p_result.side_b)
      or (m.side_a @> p_result.side_b and m.side_a <@ p_result.side_b
          and m.side_b @> p_result.side_a and m.side_b <@ p_result.side_a));
  v_factor := power(private.setting_int('rating.repeat_factor_pct') / 100.0, v_repeats);

  foreach u in array v_everyone loop
    r := private.rating_row(u, p_result.sport);
    v_k := case when r.matches < private.setting_int('rating.settled_after')
      then private.setting_int('rating.k_new') else private.setting_int('rating.k_settled') end;
    if u = any (p_result.side_a) then
      v_expected := v_expected_a;
      v_score := case when p_result.winner = 1 then 1 else 0 end;
    else
      v_expected := 1 - v_expected_a;
      v_score := case when p_result.winner = 2 then 1 else 0 end;
    end if;
    perform private.rating_write(p_result.id, u, p_result.sport,
      round((v_k * v_factor * (v_score - v_expected))::numeric, 2), false);
  end loop;
end;
$$;

-- A corrected result takes back exactly what the old one gave.
create function private.rating_reverse(p_result uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: ratings has no client write path.
declare
  e public.rating_events;
begin
  for e in select * from public.rating_events where result_id = p_result and not reversal loop
    perform private.rating_write(p_result, e.user_id, e.sport, -e.delta, true);
  end loop;
end;
$$;

revoke execute on function private.rating_row(uuid, text) from public;
revoke execute on function private.rating_write(uuid, uuid, text, numeric, boolean) from public;
revoke execute on function private.rating_apply(public.match_results) from public;
revoke execute on function private.rating_reverse(uuid) from public;

-- ─── Validation (P3-03) ────────────────────────────────────────────────────

create function private.game_winner(p_a int, p_b int, r jsonb) returns int
language plpgsql immutable set search_path = '' as $$
declare
  hi int := greatest(p_a, p_b);
  lo int := least(p_a, p_b);
  v_to int := (r ->> 'points_to_win')::int;
  v_by int := coalesce((r ->> 'win_by')::int, 2);
  v_cap int := (r ->> 'cap')::int;
begin
  if p_a is null or p_b is null or hi = lo then return -1; end if;
  if v_to is null then return case when p_a > p_b then 1 else 2 end; end if;
  if (hi = v_to and hi - lo >= v_by)
    or (hi > v_to and (v_cap is null or hi < v_cap) and hi - lo = v_by)
    or (v_cap is not null and hi = v_cap and lo >= v_cap - v_by) then
    return case when p_a > p_b then 1 else 2 end;
  end if;
  return -1;
end;
$$;

-- 1 or 2 for a finished match, 0 if the score cannot stand.
create function private.match_winner(p_games jsonb, r jsonb, p_retired smallint default null)
returns int
language plpgsql immutable set search_path = '' as $$
declare
  g jsonb;
  w int;
  a int := 0;
  b int := 0;
  v_best int := (r ->> 'best_of')::int;
  v_need int := case when v_best is null then null else v_best / 2 + 1 end;
  i int := 0;
begin
  for g in select * from jsonb_array_elements(p_games) loop
    i := i + 1;
    if jsonb_typeof(g) <> 'array' or jsonb_array_length(g) <> 2 then return 0; end if;
    -- R-STA-3: on a retirement the last game stops where it stopped.
    if p_retired is not null then
      if i < jsonb_array_length(p_games)
        and private.game_winner((g ->> 0)::int, (g ->> 1)::int, r) < 0 then return 0; end if;
      continue;
    end if;
    if v_need is not null and (a = v_need or b = v_need) then return 0; end if;
    w := private.game_winner((g ->> 0)::int, (g ->> 1)::int, r);
    if w < 0 then return 0; end if;
    if w = 1 then a := a + 1; else b := b + 1; end if;
  end loop;
  if p_retired is not null then return 3 - p_retired; end if;
  if a = b then return 0; end if;
  if v_need is not null and greatest(a, b) <> v_need then return 0; end if;
  return case when a > b then 1 else 2 end;
end;
$$;

-- Games won and finished, which a retirement needs to be rated (R-STA-3).
create function private.games_finished(p_games jsonb, r jsonb) returns int
language sql immutable set search_path = '' as $$
  select count(*)::int from jsonb_array_elements(p_games) g
  where private.game_winner((g ->> 0)::int, (g ->> 1)::int, r) > 0;
$$;

-- An organiser's choice of preset, such as junior points. No client write path.
create table public.activity_presets (
  activity_id uuid primary key references public.activities (id) on delete cascade,
  preset text not null references public.scoring_presets (key) on update cascade
);
alter table public.activity_presets enable row level security;
revoke all on public.activity_presets from anon, authenticated;

-- The organiser's preset, else the Meet's own copy of the rules. A tournament
-- is checked game by game: its organiser sets how many games each stage plays.
create function private.activity_rules(p_activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads the catalogue, including rows a client cannot see.
  select case when a.kind = 'tournament' then r.rules - 'best_of' else r.rules end
  from public.activities a
  cross join lateral (select coalesce(
    (select p.rules from public.activity_presets ap
      join public.scoring_presets p on p.key = ap.preset where ap.activity_id = a.id),
    a.scoring_snapshot,
    (select f.scoring from public.sport_formats f where f.sport_key = a.sports[1]
      order by f.position limit 1), '{}'::jsonb) as rules) r
  where a.id = p_activity;
$$;

revoke execute on function private.game_winner(int, int, jsonb) from public;
revoke execute on function private.match_winner(jsonb, jsonb, smallint) from public;
revoke execute on function private.games_finished(jsonb, jsonb) from public;
revoke execute on function private.activity_rules(uuid) from public;
grant execute on function private.game_winner(int, int, jsonb) to authenticated, service_role;
grant execute on function private.match_winner(jsonb, jsonb, smallint) to authenticated, service_role;
grant execute on function private.games_finished(jsonb, jsonb) to authenticated, service_role;

create function private.score_check() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: reads the activity's rules for any caller.
begin
  if new.status <> 'superseded'
    and private.match_winner(new.games, private.activity_rules(new.activity_id), new.retired_side) = 0 then
    raise exception 'That score can''t stand. Check each game.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
create trigger match_scores_check before insert or update of games on public.match_scores
  for each row execute function private.score_check();

-- A score becoming confirmed, by any path, makes the permanent result.
create function private.score_confirmed() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: match_results and ratings have no client write path.
declare
  a public.activities;
  v_old uuid;
  v_rules jsonb := private.activity_rules(new.activity_id);
  res public.match_results;
begin
  if new.status <> 'confirmed' or (tg_op = 'UPDATE' and old.status = 'confirmed') then
    return new;
  end if;
  select * into a from public.activities where id = new.activity_id;
  if new.supersedes is not null then
    select id into v_old from public.match_results where score_id = new.supersedes;
    if v_old is not null then perform private.rating_reverse(v_old); end if;
  end if;
  insert into public.match_results
    (score_id, activity_id, sport, side_a, side_b, games, winner, ranked, supersedes, retired_side, reason)
  values (new.id, new.activity_id, a.sports[1], new.side_a, new.side_b, new.games,
    private.match_winner(new.games, v_rules, new.retired_side),
    (a.kind = 'tournament' or coalesce(a.ranked, false))
      and (new.retired_side is null or private.games_finished(new.games, v_rules) >= 1),
    v_old, new.retired_side, new.reason)
  returning * into res;
  perform private.rating_apply(res);
  return new;
end;
$$;
create trigger match_scores_confirmed after insert or update of status on public.match_scores
  for each row execute function private.score_confirmed();

-- Attendance is often saved after the scores. When the last player is marked
-- Present, results held back for that reason get rated.
create function private.attendance_rate() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: match_results and ratings have no client write path.
declare
  res public.match_results;
begin
  if new.attendance is distinct from 'present' then return new; end if;
  for res in
    select * from public.match_results m
    where m.activity_id = new.activity_id and m.ranked and new.user_id = any (m.side_a || m.side_b)
      and not exists (select 1 from public.rating_events e where e.result_id = m.id)
      and not exists (select 1 from public.match_results n where n.supersedes = m.id)
    order by m.confirmed_at
  loop
    perform private.rating_apply(res);
  end loop;
  return new;
end;
$$;
create trigger activity_participants_rate after update of attendance on public.activity_participants
  for each row execute function private.attendance_rate();

-- Results from before this table existed. No rating moved on them.
insert into public.match_results
  (score_id, activity_id, sport, side_a, side_b, games, winner, ranked, confirmed_at)
select s.id, s.activity_id, a.sports[1], s.side_a, s.side_b, s.games,
  private.match_winner(s.games, private.activity_rules(s.activity_id)), false,
  coalesce(s.answered_at, s.created_at)
from public.match_scores s join public.activities a on a.id = s.activity_id
where s.status = 'confirmed' and private.match_winner(s.games, private.activity_rules(s.activity_id)) > 0;

-- ─── Entering and answering ────────────────────────────────────────────────

drop function public.submit_score(uuid, uuid[], uuid[], jsonb);
create function public.submit_score(
  activity uuid, partners uuid[], opponents uuid[], games jsonb, client_key uuid default null
) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: match_scores has no client write path.
declare
  me uuid := auth.uid();
  a public.activities;
  score uuid;
  v_a uuid[] := array[me] || partners;
  everyone uuid[] := v_a || opponents;
begin
  select * into a from public.activities where id = activity for update;
  if a.id is null or not a.ranked then raise exception 'Scores are for ranked games.'; end if;
  if now() < a.starts_at then raise exception 'Scores open when the Meet starts.'; end if;
  if cardinality(v_a) <> cardinality(opponents) then raise exception 'Both sides need the same number of players.'; end if;
  if (select count(distinct u) from unnest(everyone) u) <> cardinality(everyone) then
    raise exception 'A player can only be on one side.';
  end if;
  if client_key is not null then
    select id into score from public.match_scores s where s.entered_by = me and s.client_key = submit_score.client_key;
    if score is not null then return score; end if;
  end if;
  if exists (select 1 from unnest(everyone) u where not exists (
      select 1 from public.activity_participants ap
      where ap.activity_id = activity and ap.user_id = u and ap.status = 'joined'
        and ap.attendance is distinct from 'absent')) then
    raise exception 'Everyone in the match has to have played in the Meet.';
  end if;
  insert into public.match_scores (activity_id, entered_by, side_a, side_b, games, client_key)
  values (activity, me, v_a, opponents, games, submit_score.client_key)
  returning id into score;
  insert into public.notifications (user_id, title, body, mark, link)
  select o, 'Confirm your score', a.title || ': is this score right?', '21', '/scores/' || score
  from unnest(opponents) o;
  return score;
end;
$$;

create or replace function public.answer_score(score uuid, ok boolean, why text default null)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: match_scores has no client write path.
declare
  s public.match_scores;
begin
  select * into s from public.match_scores where id = score for update;
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

-- R-SCO-2: disputed or left unconfirmed, the organiser decides.
create function public.organiser_decide_score(p_score uuid, p_games jsonb default null, p_reason text default null)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: match_scores has no client write path.
declare
  s public.match_scores;
begin
  select * into s from public.match_scores where id = p_score for update;
  if s.id is null or not public.is_host(s.activity_id) then
    raise exception 'Only the organizer can decide this.';
  end if;
  if s.status not in ('waiting', 'disputed') then raise exception 'This score has been decided.'; end if;
  update public.match_scores
  set games = coalesce(p_games, games), status = 'confirmed', reason = p_reason,
      answered_by = auth.uid(), answered_at = now()
  where id = p_score;
end;
$$;

create function private.scores_expire() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: runs from pg_cron, across every Meet.
declare
  s record;
begin
  for s in
    update public.match_scores m set status = 'disputed', reason = 'Not confirmed in time'
    where m.status = 'waiting'
      and m.created_at < now() - make_interval(hours => private.setting_int('score.confirm_hours'))
    returning m.activity_id
  loop
    insert into public.notifications (user_id, title, body, mark, link)
    select a.host_id, 'A score needs you', 'It wasn''t confirmed in time.', '!', '/activities/' || a.id
    from public.activities a where a.id = s.activity_id;
  end loop;
end;
$$;
revoke execute on function private.scores_expire() from public;
select cron.schedule('scores-expire', '5 * * * *', 'select private.scores_expire()');

-- R-SCO-3: past the organiser's window, staff correct a result. A draw that has
-- moved on stays as it is: changing who won would rewrite later matches.
create function public.staff_result_correct(p_score uuid, p_games jsonb, p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: writes match_scores and the audit log.
declare
  s public.match_scores;
  m public.tournament_matches;
  v_new uuid;
begin
  perform private.staff_require('moderator');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Say why this result is changing.'; end if;
  select * into s from public.match_scores where id = p_score for update;
  if s.id is null or s.status <> 'confirmed' then raise exception 'That result can''t be corrected.'; end if;
  select * into m from public.tournament_matches where score_id = p_score for update;
  if m.id is not null and private.match_winner(p_games, private.activity_rules(s.activity_id))
      <> private.match_winner(s.games, private.activity_rules(s.activity_id)) then
    raise exception 'The winner can''t change here because the draw has moved on.';
  end if;
  update public.match_scores set status = 'superseded' where id = p_score;
  insert into public.match_scores
    (activity_id, entered_by, side_a, side_b, games, status, answered_by, answered_at, supersedes, reason)
  values (s.activity_id, auth.uid(), s.side_a, s.side_b, p_games, 'confirmed', auth.uid(), now(), p_score, p_reason)
  returning id into v_new;
  if m.id is not null then
    update public.tournament_matches set score_id = v_new, games = p_games where id = m.id;
  end if;
  perform public.notify(u, 'A result was corrected', 'OlympusGO corrected one of your results.', '!', '/passport')
  from unnest(s.side_a || s.side_b) u;
  perform private.staff_audit('result_correct', 'score', p_score::text, p_reason,
    jsonb_build_object('new_score', v_new, 'games', p_games));
  return v_new;
end;
$$;

-- Rounds from the match generator. Host only; rounds with a score stand.
create function public.meet_rounds_save(p_activity uuid, p_from int, p_rounds jsonb) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: matches has no client write path.
declare
  r jsonb;
  m jsonb;
begin
  if not public.is_host(p_activity) then raise exception 'Only the organizer can do this.'; end if;
  perform 1 from public.activities where id = p_activity for update;
  delete from public.matches where activity_id = p_activity and round >= p_from;
  for r in select * from jsonb_array_elements(p_rounds) loop
    for m in select * from jsonb_array_elements(r -> 'matches') loop
      insert into public.matches (activity_id, round, court, side_a, side_b, byes)
      values (p_activity, (r ->> 'number')::int, (m ->> 'court')::int,
        array(select jsonb_array_elements_text(m -> 'side_a'))::uuid[],
        array(select jsonb_array_elements_text(m -> 'side_b'))::uuid[],
        array(select jsonb_array_elements_text(r -> 'byes'))::uuid[]);
    end loop;
  end loop;
end;
$$;

create function public.meet_rounds(p_activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: matches has no client read path. Rounds show ids; names come
  -- from meet_players, which masks minors.
  select coalesce(jsonb_agg(jsonb_build_object('round', m.round, 'court', m.court,
    'side_a', m.side_a, 'side_b', m.side_b, 'byes', m.byes) order by m.round, m.court), '[]'::jsonb)
  from public.matches m
  where m.activity_id = p_activity
    and (public.is_host(p_activity) or private.on_activity(p_activity));
$$;

-- Open decision 20: the organiser picks junior points before any score is in.
create function public.activity_preset_set(p_activity uuid, p_preset text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: activity_presets has no client write path.
declare
  a public.activities;
begin
  select * into a from public.activities where id = p_activity for update;
  if a.id is null or not public.is_host(p_activity) then
    raise exception 'Only the organizer can do this.';
  end if;
  if exists (select 1 from public.match_scores s where s.activity_id = p_activity) then
    raise exception 'Scores are in already, so the scoring can''t change.';
  end if;
  if not exists (select 1 from public.scoring_presets p
      where p.key = p_preset and p.active and p.sport_key = a.sports[1]) then
    raise exception 'That scoring isn''t available for this sport.';
  end if;
  insert into public.activity_presets (activity_id, preset) values (p_activity, p_preset)
  on conflict (activity_id) do update set preset = excluded.preset;
end;
$$;

-- The limit came before the ranking, so the best fits could be cut for no
-- reason. Rank first, then limit.
create or replace function public.discover_players(
  p_sport text default null,
  p_level numeric default null,
  p_limit int default 30
) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: ranks across player_sports. Minors, blocked players, hidden
  -- profiles and players who chose "only me" are left out.
  select coalesce(jsonb_agg(public.player_json(x.id) || jsonb_build_object('level', x.level)
    order by x.fits desc, x.level desc, x.id), '[]'::jsonb)
  from (
    select y.* from (
      select distinct on (p.id) p.id, ps.level,
        exists (select 1 from public.player_sports m where m.user_id = auth.uid()
          and m.sport = ps.sport and ps.level between m.play_min and m.play_max) as fits
      from public.player_sports ps
      join public.profiles p on p.id = ps.user_id
      where p.onboarding_completed and p.id <> auth.uid()
        and p.visibility <> 'only_me' and p.hidden_at is null
        and not private.is_minor(p.id)
        and not public.is_blocked_between(auth.uid(), p.id)
        and (p_sport is null or ps.sport = p_sport)
        and (p_level is null or ps.level = p_level)
      order by p.id, 3 desc, ps.level desc
    ) y
    order by y.fits desc, y.level desc, y.id
    limit least(p_limit, 100)
  ) x;
$$;

-- Level scales are keyed by band, which the audit trigger didn't know.
create or replace function private.audit_catalog() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: catalog_audit is closed to every client role.
declare
  v_row jsonb := to_jsonb(coalesce(new, old));
begin
  insert into public.catalog_audit (table_name, row_key, action, actor, before, after)
  values (tg_table_name, coalesce(v_row ->> 'key', v_row ->> 'id', v_row ->> 'band'), lower(tg_op), auth.uid(),
    case when tg_op = 'INSERT' then null else to_jsonb(old) end,
    case when tg_op = 'DELETE' then null else to_jsonb(new) end);
  return coalesce(new, old);
end;
$$;

-- A-05: presets and level scales without a deploy.
create function public.staff_preset_save(
  p_key text, p_sport text, p_name text, p_rules jsonb, p_active boolean, p_reason text
) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: scoring_presets has no client write path.
declare
  v_to int := (p_rules ->> 'points_to_win')::int;
  v_by int := (p_rules ->> 'win_by')::int;
  v_cap int := (p_rules ->> 'cap')::int;
  v_best int := (p_rules ->> 'best_of')::int;
begin
  perform private.staff_require('content');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Say why this is changing.'; end if;
  if coalesce(v_to, 0) < 1 or coalesce(v_by, 0) < 1 or coalesce(v_best, 0) < 1 or v_best % 2 = 0
    or (v_cap is not null and v_cap <= v_to) then
    raise exception 'Those rules can''t work. Check the numbers.';
  end if;
  insert into public.scoring_presets as s (key, sport_key, name, rules, active)
  values (p_key, p_sport, p_name, p_rules, p_active)
  on conflict (key) do update set name = excluded.name, rules = excluded.rules, active = excluded.active;
  perform private.staff_audit('preset_save', 'preset', p_key, p_reason,
    jsonb_build_object('rules', p_rules, 'active', p_active));
end;
$$;

create function public.staff_level_save(p_band text, p_name text, p_from numeric, p_reason text)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: level_scales has no client write path.
begin
  perform private.staff_require('content');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Say why this is changing.'; end if;
  if p_from not between 1 and 8 then raise exception 'A level is between 1.0 and 8.0.'; end if;
  update public.level_scales set name = p_name, from_level = p_from where band = p_band;
  if not found then raise exception 'That level isn''t on the scale.'; end if;
  perform private.staff_audit('level_save', 'level', p_band, p_reason,
    jsonb_build_object('from_level', p_from));
end;
$$;

do $$
declare
  d text := pg_get_functiondef('public.staff_catalog()'::regprocedure);
  fixed text := replace(d, $old$'level_scales', (select$old$,
    $new$'presets', (select coalesce(jsonb_agg(to_jsonb(p) order by p.sport_key, p.key), '[]'::jsonb) from public.scoring_presets p),
    'level_scales', (select$new$);
begin
  if fixed = d then raise exception 'staff_catalog did not change'; end if;
  execute fixed;
end;
$$;

-- The rules a screen checks a score with, the same ones the trigger uses.
create function public.activity_scoring(p_activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: the catalogue row may be hidden from the caller.
  select private.activity_rules(p_activity);
$$;

-- How my level moved over a Meet, or over one score.
create function public.my_rating_change(p_activity uuid, p_score uuid default null) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads the caller's own events only.
  with mine as (
    select e.before, e.after, e.at, e.id from public.rating_events e
    join public.match_results m on m.id = e.result_id
    where e.user_id = auth.uid() and not e.reversal and m.activity_id = p_activity
      and (p_score is null or m.score_id = p_score)
      and not exists (select 1 from public.match_results n where n.supersedes = m.id)
  )
  select case when count(*) = 0 then null else jsonb_build_object(
    'before', private.level_of((array_agg(before order by id))[1]),
    'after', private.level_of((array_agg(after order by id desc))[1])) end
  from mine;
$$;

-- My rating, for the profile.
create function public.my_rating(p_sport text) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads the caller's own rows only.
  select jsonb_build_object('rating', r.rating, 'level', private.level_of(r.rating), 'matches', r.matches,
    'provisional', r.matches < private.setting_int('rating.provisional_matches'),
    'history', (select coalesce(jsonb_agg(jsonb_build_object('at', e.at, 'rating', e.after) order by e.at), '[]'::jsonb)
      from public.rating_events e where e.user_id = r.user_id and e.sport = r.sport))
  from public.ratings r where r.user_id = auth.uid() and r.sport = p_sport;
$$;

revoke execute on function public.submit_score(uuid, uuid[], uuid[], jsonb, uuid) from public, anon;
revoke execute on function public.organiser_decide_score(uuid, jsonb, text) from public, anon;
revoke execute on function public.staff_result_correct(uuid, jsonb, text) from public, anon;
revoke execute on function public.meet_rounds_save(uuid, int, jsonb) from public, anon;
revoke execute on function public.meet_rounds(uuid) from public, anon;
revoke execute on function public.activity_preset_set(uuid, text) from public, anon;
revoke execute on function public.staff_preset_save(text, text, text, jsonb, boolean, text) from public, anon;
revoke execute on function public.staff_level_save(text, text, numeric, text) from public, anon;
revoke execute on function public.my_rating(text) from public, anon;
revoke execute on function public.activity_scoring(uuid) from public, anon;
revoke execute on function public.my_rating_change(uuid, uuid) from public, anon;
grant execute on function public.submit_score(uuid, uuid[], uuid[], jsonb, uuid) to authenticated;
grant execute on function public.organiser_decide_score(uuid, jsonb, text) to authenticated;
grant execute on function public.staff_result_correct(uuid, jsonb, text) to authenticated;
grant execute on function public.meet_rounds_save(uuid, int, jsonb) to authenticated;
grant execute on function public.meet_rounds(uuid) to authenticated;
grant execute on function public.activity_preset_set(uuid, text) to authenticated;
grant execute on function public.staff_preset_save(text, text, text, jsonb, boolean, text) to authenticated;
grant execute on function public.staff_level_save(text, text, numeric, text) to authenticated;
grant execute on function public.my_rating(text) to authenticated;
grant execute on function public.activity_scoring(uuid) to authenticated;
grant execute on function public.my_rating_change(uuid, uuid) to authenticated;

-- ─── Tournaments ───────────────────────────────────────────────────────────

alter table public.tournament_matches add column decided_at timestamptz;

do $$
declare
  d text := pg_get_functiondef('public.tournament_score(uuid, jsonb)'::regprocedure);
  fixed text := d;
begin
  fixed := replace(fixed, 'tournament_score(p_match uuid, p_games jsonb)',
    'tournament_score(p_match uuid, p_games jsonb, p_reason text DEFAULT NULL::text, p_retired smallint DEFAULT NULL::smallint)');
  fixed := replace(fixed, 'select * into m from public.tournament_matches where id = p_match;',
    'select * into m from public.tournament_matches where id = p_match for update;');
  fixed := replace(fixed, $old$    if (g->>0)::int = (g->>1)::int then raise exception$old$,
    $new$    if p_retired is null and (g->>0)::int = (g->>1)::int then raise exception$new$);
  fixed := replace(fixed, $old$  if v_won[1] = v_won[2] then raise exception 'Enter the deciding game.'; end if;
  v_winner := case when v_won[1] > v_won[2] then m.entry_a else m.entry_b end;$old$,
    $new$  if p_retired is null and v_won[1] = v_won[2] then raise exception 'Enter the deciding game.'; end if;
  v_winner := case when p_retired = 1 then m.entry_b when p_retired = 2 then m.entry_a
    when v_won[1] > v_won[2] then m.entry_a else m.entry_b end;$new$);
  fixed := replace(fixed, $old$  set games = p_games, winner = v_winner, state = 'done', walkover = false,$old$,
    $new$  set games = p_games, winner = v_winner, state = 'done', walkover = false,
      decided_at = coalesce(decided_at, now()),$new$);
  fixed := replace(fixed, E'  v_score uuid;\nbegin', E'  v_score uuid;\n  v_old uuid;\nbegin');
  fixed := replace(fixed, $old$    -- A correction: only while the next match isn't played.$old$,
    $new$    -- R-SCO-3: a correction needs a reason and a recent result. Later ones
    -- go through staff.
    if coalesce(trim(p_reason), '') = '' then
      raise exception 'Say why this result is changing.';
    end if;
    if coalesce(m.decided_at, m.updated_at) < now() - make_interval(hours => private.setting_int('score.correction_hours')) then
      raise exception 'This result is too old to change here. Ask the OlympusGO team.';
    end if;
    -- A correction: only while the next match isn't played.$new$);
  -- R-SCO-3: the old score stays on record.
  fixed := replace(fixed, $old$    if m.score_id is not null then
      delete from public.match_scores where id = m.score_id;
    end if;$old$, $new$    v_old := m.score_id;
    if v_old is not null then
      update public.match_scores set status = 'superseded' where id = v_old;
    end if;$new$);
  -- R-RAT-1: every tournament match is ranked, third place included.
  fixed := replace(fixed, $old$  if jsonb_array_length(p_games) between 2 and 3 and m.stage <> 'third' then
    insert into public.match_scores
      (activity_id, entered_by, side_a, side_b, games, status, answered_by, answered_at)
    values (m.activity_id, (select auth.uid()), public.tournament_players(m.entry_a),
            public.tournament_players(m.entry_b), p_games, 'confirmed',
            (select auth.uid()), now())
    returning id into v_score;
  end if;$old$, $new$  insert into public.match_scores
    (activity_id, entered_by, side_a, side_b, games, status, answered_by, answered_at, supersedes, reason, retired_side)
  values (m.activity_id, (select auth.uid()), public.tournament_players(m.entry_a),
          public.tournament_players(m.entry_b), p_games, 'confirmed',
          (select auth.uid()), now(), v_old, p_reason, p_retired)
  returning id into v_score;$new$);
  if position('supersedes' in fixed) = 0 or position('v_old uuid' in fixed) = 0
    or position('Say why' in fixed) = 0 or position('delete from public.match_scores' in fixed) > 0
    or position('p_retired = 1' in fixed) = 0 or position('decided_at = coalesce' in fixed) = 0
    or position('p_match for update' in fixed) = 0 then
    raise exception 'tournament_score did not change as expected';
  end if;
  drop function public.tournament_score(uuid, jsonb);
  execute fixed;
end;
$$;
revoke execute on function public.tournament_score(uuid, jsonb, text, smallint) from public, anon;
grant execute on function public.tournament_score(uuid, jsonb, text, smallint) to authenticated;

-- R-MET-4 for tournaments: the capacity check needs the same row lock.
do $$
declare
  n record;
  d text;
  fixed text;
begin
  select p.oid::regprocedure as sig into n from pg_proc p
  where p.proname = 'tournament_register' and p.pronamespace = 'public'::regnamespace;
  d := pg_get_functiondef(n.sig);
  fixed := regexp_replace(d, 'select \* into a from public\.activities\s+where id = p_activity', 'select * into a from public.activities where id = p_activity', 'g');
  fixed := regexp_replace(fixed, '(select \* into a from public\.activities where id = p_activity[^;]*);', E'\\1 for update;');
  if fixed = d then raise exception 'tournament_register did not change'; end if;
  execute fixed;
end;
$$;
