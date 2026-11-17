-- Fixes from the independent review of Phase 3. Each one closes a way a rating
-- could move without a real match, or a way a player's data could show.

-- ─── Scores keep the rules they were entered under ─────────────────────────

alter table public.match_scores add column rules jsonb;

-- An account can be deleted after someone corrected its score.
alter table public.match_scores drop constraint match_scores_supersedes_fkey;
alter table public.match_scores add constraint match_scores_supersedes_fkey
  foreign key (supersedes) references public.match_scores (id) on delete set null;

create or replace function private.match_winner(p_games jsonb, r jsonb, p_retired smallint default null)
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
    if jsonb_typeof(g) <> 'array' or jsonb_array_length(g) <> 2
      or jsonb_typeof(g -> 0) <> 'number' or jsonb_typeof(g -> 1) <> 'number'
      or (g ->> 0)::numeric not between 0 and 99 or (g ->> 1)::numeric not between 0 and 99
      or (g ->> 0)::numeric <> trunc((g ->> 0)::numeric)
      or (g ->> 1)::numeric <> trunc((g ->> 1)::numeric) then
      return 0;
    end if;
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

create or replace function private.score_check() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: reads the activity's rules for any caller.
begin
  new.rules := coalesce(new.rules, private.activity_rules(new.activity_id));
  if new.status <> 'superseded'
    and private.match_winner(new.games, new.rules, new.retired_side) = 0 then
    raise exception 'That score can''t stand. Check each game.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

-- R-RAT-1: a rating moves only for a real ranked match. Tournaments count once
-- they have started, unless the person entering the score played in it.
create or replace function private.score_confirmed() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: match_results and ratings have no client write path.
declare
  a public.activities;
  v_old uuid;
  v_rules jsonb := coalesce(new.rules, private.activity_rules(new.activity_id));
  v_ranked boolean;
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
  v_ranked := a.status = 'published' and now() >= a.starts_at and v_rules ? 'points_to_win'
    and case a.kind
      when 'tournament' then not new.entered_by = any (new.side_a || new.side_b)
      when 'meet' then coalesce(a.ranked, false)
      else false end
    and (new.retired_side is null or private.games_finished(new.games, v_rules) >= 1);
  insert into public.match_results
    (score_id, activity_id, sport, side_a, side_b, games, winner, ranked, supersedes, retired_side, reason)
  values (new.id, new.activity_id, a.sports[1], new.side_a, new.side_b, new.games,
    private.match_winner(new.games, v_rules, new.retired_side), v_ranked,
    v_old, new.retired_side, new.reason)
  returning * into res;
  perform private.rating_apply(res);
  return new;
end;
$$;

-- ─── Ratings ───────────────────────────────────────────────────────────────

-- A rating still counts: it moved, and hasn't been taken back.
create function private.result_rated(p_result uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: rating_events is read across players.
  select exists (select 1 from public.rating_events e where e.result_id = p_result and not e.reversal)
    and not exists (select 1 from public.rating_events e where e.result_id = p_result and e.reversal);
$$;
revoke execute on function private.result_rated(uuid) from public;

create or replace function private.rating_apply(p_result public.match_results) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: ratings has no client write path. Runs once per result: the unique
-- key on rating_events refuses a second go.
declare
  v_everyone uuid[] := p_result.side_a || p_result.side_b;
  v_kind text;
  v_avg_a numeric;
  v_avg_b numeric;
  v_expected_a double precision;
  v_repeats int;
  v_score double precision;
  v_expected double precision;
  v_opponents uuid[];
  u uuid;
  r public.ratings;
  v_k int;
begin
  if not p_result.ranked then return; end if;
  select kind into v_kind from public.activities where id = p_result.activity_id;
  if v_kind <> 'tournament' and exists (select 1 from unnest(v_everyone) x
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

  foreach u in array v_everyone loop
    r := private.rating_row(u, p_result.sport);
    v_k := case when r.matches < private.setting_int('rating.settled_after')
      then private.setting_int('rating.k_new') else private.setting_int('rating.k_settled') end;
    if u = any (p_result.side_a) then
      v_expected := v_expected_a;
      v_score := case when p_result.winner = 1 then 1 else 0 end;
      v_opponents := p_result.side_b;
    else
      v_expected := 1 - v_expected_a;
      v_score := case when p_result.winner = 2 then 1 else 0 end;
      v_opponents := p_result.side_a;
    end if;
    -- R-RAT-5: the same opponent counts less each time, whoever the partner
    -- was. Results taken back or never rated don't count as repeats.
    select count(*) into v_repeats from public.match_results m
    where m.id <> p_result.id and m.id is distinct from p_result.supersedes
      and m.sport = p_result.sport and m.ranked
      and m.confirmed_at > now() - make_interval(days => private.setting_int('rating.repeat_window_days'))
      and ((u = any (m.side_a) and m.side_b && v_opponents)
        or (u = any (m.side_b) and m.side_a && v_opponents))
      and private.result_rated(m.id);
    perform private.rating_write(p_result.id, u, p_result.sport,
      round((v_k * power(private.setting_int('rating.repeat_factor_pct') / 100.0, v_repeats)
        * (v_score - v_expected))::numeric, 2), false);
  end loop;
end;
$$;

create or replace function private.rating_reverse(p_result uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: ratings has no client write path.
declare
  e public.rating_events;
begin
  for e in select * from public.rating_events x where x.result_id = p_result and not x.reversal
      and not exists (select 1 from public.rating_events y
        where y.result_id = x.result_id and y.user_id = x.user_id and y.reversal)
      order by x.user_id loop
    perform private.rating_write(p_result, e.user_id, e.sport, -e.delta, true);
  end loop;
end;
$$;

-- R-RAT-3: PRO needs verification, which doesn't exist yet, so a rating stops
-- at the top of AD. A level nobody earned stops at AD, in half steps.
create or replace function private.level_of(p_rating numeric) returns numeric
language sql stable security definer set search_path = '' as $$
  -- Definer: reads settings for any caller.
  select greatest(1.0, least(7.9, round(4.0 + (p_rating - private.setting_int('rating.start'))
    / private.setting_int('rating.points_per_level')::numeric, 1)));
$$;

create or replace function private.player_sport_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: ratings cannot be read for every player by the caller.
declare
  v numeric;
begin
  select rating into v from public.ratings where user_id = new.user_id and sport = new.sport;
  if v is not null then
    new.level := private.level_of(v);
  else
    new.level := least(round(new.level * 2) / 2, 7.0);
  end if;
  return new;
end;
$$;

-- Attendance can change until it closes. Present gives a held result its
-- rating; taking it away takes the rating back.
create or replace function private.attendance_rate() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: match_results and ratings have no client write path.
declare
  res public.match_results;
begin
  if new.attendance is not distinct from old.attendance then return new; end if;
  perform 1 from public.activities where id = new.activity_id for no key update;
  for res in
    select * from public.match_results m
    where m.activity_id = new.activity_id and m.ranked and new.user_id = any (m.side_a || m.side_b)
      and not exists (select 1 from public.match_results n where n.supersedes = m.id)
    order by m.confirmed_at
  loop
    if new.attendance = 'present' then
      if not exists (select 1 from public.rating_events e where e.result_id = res.id) then
        perform private.rating_apply(res);
      end if;
    elsif private.result_rated(res.id) then
      perform private.rating_reverse(res.id);
    end if;
  end loop;
  return new;
end;
$$;

-- ─── Entering, answering and deciding ──────────────────────────────────────

-- A roster shows some players by a stand-in id. Scores name the real player.
create function private.roster_real(p_activity uuid, p_id uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  -- Definer: reads the roster for any caller on it.
  select ap.user_id from public.activity_participants ap
  where ap.activity_id = p_activity
    and (ap.user_id = p_id or md5(p_activity::text || ap.user_id::text)::uuid = p_id);
$$;

-- What this viewer may see of a player on a roster, as meet_players shows it.
create function private.roster_id(p_activity uuid, p_host uuid, p_user uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  -- Definer: minor status and blocks are read across accounts.
  select case when p_user = auth.uid() or (not public.is_blocked_between(auth.uid(), p_user)
      and (p_host = auth.uid() or not private.is_minor(p_user)
        or private.is_guardian_of(auth.uid(), p_user)))
    then p_user else md5(p_activity::text || p_user::text)::uuid end;
$$;
revoke execute on function private.roster_real(uuid, uuid) from public;
revoke execute on function private.roster_id(uuid, uuid, uuid) from public;

create or replace function public.submit_score(
  activity uuid, partners uuid[], opponents uuid[], games jsonb, client_key uuid default null
) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: match_scores has no client write path.
declare
  me uuid := auth.uid();
  a public.activities;
  score uuid;
  v_old public.match_scores;
  v_mates uuid[] := array(select private.roster_real(activity, u) from unnest(partners) u);
  v_b uuid[] := array(select private.roster_real(activity, u) from unnest(opponents) u);
  v_a uuid[] := array[me] || v_mates;
  everyone uuid[] := v_a || v_b;
  v_flip jsonb := (select jsonb_agg(jsonb_build_array(g -> 1, g -> 0) order by n)
    from jsonb_array_elements(games) with ordinality x (g, n));
begin
  select * into a from public.activities where id = activity for update;
  if a.id is null or a.kind <> 'meet' or not coalesce(a.ranked, false) then
    raise exception 'Scores are for ranked games.';
  end if;
  if a.status <> 'published' then raise exception 'This Meet was cancelled.'; end if;
  if now() < a.starts_at then raise exception 'Scores open when the Meet starts.'; end if;
  if cardinality(v_a) <> cardinality(v_b) then raise exception 'Both sides need the same number of players.'; end if;
  if (select count(distinct u) from unnest(everyone) u) <> cardinality(everyone) then
    raise exception 'A player can only be on one side.';
  end if;
  if client_key is not null then
    select * into v_old from public.match_scores s where s.entered_by = me and s.client_key = submit_score.client_key;
    if v_old.id is not null then
      if v_old.activity_id = activity and v_old.games = submit_score.games then return v_old.id; end if;
      raise exception 'This score was sent already.';
    end if;
  end if;
  if exists (select 1 from unnest(everyone) u where not exists (
      select 1 from public.activity_participants ap
      where ap.activity_id = activity and ap.user_id = u and ap.status = 'joined'
        and ap.attendance is distinct from 'absent')) then
    raise exception 'Everyone in the match has to have played in the Meet.';
  end if;
  -- One match, one score: both sides entering it must not count twice.
  if exists (select 1 from public.match_scores s
      where s.activity_id = activity and s.status in ('waiting', 'disputed', 'confirmed')
        and ((s.side_a @> v_a and s.side_a <@ v_a and s.side_b @> v_b and s.side_b <@ v_b
              and (s.status = 'waiting' or s.games = submit_score.games))
          or (s.side_a @> v_b and s.side_a <@ v_b and s.side_b @> v_a and s.side_b <@ v_a
              and (s.status = 'waiting' or s.games = v_flip)))) then
    raise exception 'This match has a score already. Check your Inbox.';
  end if;
  insert into public.match_scores (activity_id, entered_by, side_a, side_b, games, client_key)
  values (activity, me, v_a, v_b, games, submit_score.client_key)
  returning id into score;
  insert into public.notifications (user_id, title, body, mark, link)
  select o, 'Confirm your score', a.title || ': is this score right?', '21', '/scores/' || score
  from unnest(v_b) o;
  return score;
end;
$$;

create or replace function public.answer_score(score uuid, ok boolean, why text default null)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: match_scores has no client write path.
declare
  s public.match_scores;
  v_activity uuid;
begin
  -- The activity first, so attendance can't save between this check and the
  -- rating and leave the result unrated.
  select activity_id into v_activity from public.match_scores where id = score;
  perform 1 from public.activities where id = v_activity for no key update;
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

-- R-SCO-2: an organizer decides a disputed score, or one left unanswered for
-- 24 hours, which the hourly job marks disputed. Not one they played in (Q55).
create or replace function public.organiser_decide_score(p_score uuid, p_games jsonb default null, p_reason text default null)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: match_scores has no client write path.
declare
  s public.match_scores;
  v_activity uuid;
  u uuid;
begin
  select activity_id into v_activity from public.match_scores where id = p_score;
  perform 1 from public.activities where id = v_activity for no key update;
  select * into s from public.match_scores where id = p_score for update;
  if s.id is null or not public.is_host(s.activity_id) then
    raise exception 'Only the organizer can decide this.';
  end if;
  if s.status <> 'disputed' then raise exception 'This score isn''t waiting for you.'; end if;
  if auth.uid() = any (s.side_a || s.side_b) then
    raise exception 'You played in this match, so the OlympusGO team decides it.';
  end if;
  update public.match_scores
  set games = coalesce(p_games, games), status = 'confirmed', reason = p_reason,
      answered_by = auth.uid(), answered_at = now()
  where id = p_score;
  foreach u in array s.side_a || s.side_b loop
    perform public.notify(u, 'Your score is final', 'The organizer set the final score.', '21', '/scores/' || s.id);
  end loop;
end;
$$;

-- Staff decide what an organizer can't: their own match, or a later correction.
create or replace function public.staff_result_correct(p_score uuid, p_games jsonb, p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: writes match_scores and the audit log.
declare
  s public.match_scores;
  m public.tournament_matches;
  v_rules jsonb;
  v_new uuid := p_score;
begin
  perform private.staff_require('moderator');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Say why this result is changing.'; end if;
  select * into s from public.match_scores where id = p_score for update;
  if s.id is null or s.status not in ('confirmed', 'disputed') then
    raise exception 'That result can''t be corrected.';
  end if;
  v_rules := coalesce(s.rules, private.activity_rules(s.activity_id));
  if s.status = 'disputed' then
    update public.match_scores
    set games = coalesce(p_games, games), status = 'confirmed', reason = p_reason,
        answered_by = auth.uid(), answered_at = now()
    where id = p_score;
  else
    select * into m from public.tournament_matches where score_id = p_score for update;
    if m.id is not null and private.match_winner(p_games, v_rules, s.retired_side)
        <> private.match_winner(s.games, v_rules, s.retired_side) then
      raise exception 'The winner can''t change here because the draw has moved on.';
    end if;
    update public.match_scores set status = 'superseded' where id = p_score;
    insert into public.match_scores (activity_id, entered_by, side_a, side_b, games, status,
      answered_by, answered_at, supersedes, reason, rules, retired_side)
    values (s.activity_id, auth.uid(), s.side_a, s.side_b, p_games, 'confirmed',
      auth.uid(), now(), p_score, p_reason, v_rules, s.retired_side)
    returning id into v_new;
    if m.id is not null then
      update public.tournament_matches set score_id = v_new, games = p_games where id = m.id;
    end if;
  end if;
  perform public.notify(u, 'A result was corrected', 'OlympusGO corrected one of your results.', '!', '/scores/' || v_new)
  from unnest(s.side_a || s.side_b) u;
  perform private.staff_audit('result_correct', 'score', p_score::text, p_reason,
    jsonb_build_object('new_score', v_new, 'games', p_games));
  return v_new;
end;
$$;

-- What staff need to act on: disputes an organizer can't decide, or one result
-- looked up by id.
create function public.staff_scores(p_score uuid default null) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads scores across activities.
begin
  perform private.staff_require('moderator');
  return (select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'title', a.title, 'status', s.status,
      'games', s.games, 'reason', s.reason, 'at', s.created_at) order by s.created_at), '[]'::jsonb)
    from public.match_scores s join public.activities a on a.id = s.activity_id
    where case when p_score is not null then s.id = p_score
      else s.status = 'disputed' and a.host_id = any (s.side_a || s.side_b) end);
end;
$$;
revoke execute on function public.staff_scores(uuid) from public, anon;
grant execute on function public.staff_scores(uuid) to authenticated;

-- A-05: the score screens have three games.
do $$
declare
  d text := pg_get_functiondef('public.staff_preset_save(text, text, text, jsonb, boolean, text)'::regprocedure);
  fixed text := replace(d, 'or coalesce(v_best, 0) < 1 or v_best % 2 = 0', 'or coalesce(v_best, 0) not in (1, 3)');
begin
  if fixed = d then raise exception 'staff_preset_save did not change'; end if;
  execute fixed;
end;
$$;

-- ─── Rounds ────────────────────────────────────────────────────────────────

-- Host only. Rounds from p_from on are replaced; the screen starts after the
-- last round unless the organizer picks an earlier one.
create or replace function public.meet_rounds_save(p_activity uuid, p_from int, p_rounds jsonb) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: matches has no client write path.
declare
  r jsonb;
  m jsonb;
  v_a uuid[];
  v_b uuid[];
  v_byes uuid[];
begin
  if not public.is_host(p_activity) then raise exception 'Only the organizer can do this.'; end if;
  perform 1 from public.activities where id = p_activity for update;
  delete from public.matches where activity_id = p_activity and round >= p_from;
  for r in select * from jsonb_array_elements(p_rounds) loop
    for m in select * from jsonb_array_elements(r -> 'matches') loop
      v_a := array(select jsonb_array_elements_text(m -> 'side_a'))::uuid[];
      v_b := array(select jsonb_array_elements_text(m -> 'side_b'))::uuid[];
      v_byes := array(select jsonb_array_elements_text(r -> 'byes'))::uuid[];
      if exists (select 1 from unnest(v_a || v_b || v_byes) u where not exists (
          select 1 from public.activity_participants ap
          where ap.activity_id = p_activity and ap.user_id = u and ap.status = 'joined')) then
        raise exception 'Everyone in a round has to be on the Meet.';
      end if;
      insert into public.matches (activity_id, round, court, side_a, side_b, byes)
      values (p_activity, (r ->> 'number')::int, (m ->> 'court')::int, v_a, v_b, v_byes);
    end loop;
  end loop;
end;
$$;

create or replace function public.meet_rounds(p_activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: matches has no client read path. Ids match what meet_players
  -- shows this viewer, so minors and blocked players stay stand-ins.
  select coalesce(jsonb_agg(jsonb_build_object('round', m.round, 'court', m.court,
    'side_a', (select jsonb_agg(private.roster_id(p_activity, a.host_id, u)) from unnest(m.side_a) u),
    'side_b', (select jsonb_agg(private.roster_id(p_activity, a.host_id, u)) from unnest(m.side_b) u),
    'byes', (select coalesce(jsonb_agg(private.roster_id(p_activity, a.host_id, u)), '[]'::jsonb) from unnest(m.byes) u))
    order by m.round, m.court), '[]'::jsonb)
  from public.matches m
  join public.activities a on a.id = m.activity_id
  where m.activity_id = p_activity
    and (a.host_id = auth.uid() or exists (select 1 from public.activity_participants me
      where me.activity_id = p_activity and me.user_id = auth.uid()
        and me.status in ('joined', 'waitlist')));
$$;

create or replace function public.my_rating_change(p_activity uuid, p_score uuid default null) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads the caller's own events only.
  with mine as (
    select e.before, e.after, e.at, e.id from public.rating_events e
    join public.match_results m on m.id = e.result_id
    where e.user_id = auth.uid() and not e.reversal and m.activity_id = p_activity
      and (p_score is null or m.score_id = p_score)
      and not exists (select 1 from public.rating_events x where x.result_id = e.result_id and x.reversal)
  )
  select case when count(*) = 0 then null else jsonb_build_object(
    'before', private.level_of((array_agg(before order by id))[1]),
    'after', private.level_of((array_agg(after order by id desc))[1])) end
  from mine;
$$;

-- ─── Leaderboards ──────────────────────────────────────────────────────────

create or replace function private.listable(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads consents and profiles across accounts.
  select not private.is_restricted(p_user)
    and exists (select 1 from public.profiles p where p.id = p_user
      and p.hidden_at is null and p.visibility <> 'only_me')
    and (not private.is_minor(p_user) or exists (
      select 1 from public.leaderboard_consents c
      where c.child_id = p_user and private.is_guardian_of(c.guardian_id, p_user)));
$$;

-- A consent ends with the link. A new link starts with it off.
create function private.link_ended() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: leaderboard_consents has no client write path.
begin
  if old.status = 'approved' and new.status <> 'approved' then
    delete from public.leaderboard_consents c
    where c.child_id = new.child_id and c.guardian_id = new.parent_id;
  end if;
  return new;
end;
$$;
create trigger guardian_links_consent after update of status on public.guardian_links
  for each row execute function private.link_ended();

do $$
declare
  d text := pg_get_functiondef('private.leaderboards_build()'::regprocedure);
  fixed text := replace(d, $old$where m.stage in ('knockout', 'third') and m.state = 'done'$old$,
    $new$where a.status = 'published' and a.starts_at <= now()
      and m.stage in ('knockout', 'third') and m.state = 'done'$new$);
begin
  if fixed = d then raise exception 'leaderboards_build did not change'; end if;
  execute fixed;
end;
$$;
