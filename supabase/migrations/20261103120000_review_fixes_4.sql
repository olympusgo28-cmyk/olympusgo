-- Fixes from the second review of Phase 3.

insert into public.app_settings (key, value, description) values
  ('score.staff_after_hours', '72', 'Hours a dispute waits for its organizer before staff see it (Q61)');

-- Self-chosen levels from before the half-step rule came back.
update public.player_sports ps set level = ps.level
where (ps.level > 7 or ps.level * 2 <> round(ps.level * 2))
  and not exists (select 1 from public.ratings r where r.user_id = ps.user_id and r.sport = ps.sport);

-- ─── A host can't rewrite the facts a rating rests on ──────────────────────

create function private.activity_has_scores(p_activity uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called from a trigger running as the client.
  select exists (select 1 from public.match_scores s where s.activity_id = p_activity);
$$;
revoke execute on function private.activity_has_scores(uuid) from public;
grant execute on function private.activity_has_scores(uuid) to authenticated;

create or replace function private.activity_lock_columns() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user = 'authenticated' then
    new.status := old.status;
    new.host_id := old.host_id;
    new.kind := old.kind;
    new.scoring_snapshot := old.scoring_snapshot;
    new.game_on_at := old.game_on_at;
    new.hidden_at := old.hidden_at;
    if private.is_minor(old.host_id) then
      new.public_listing := false;
    end if;
    if private.attendance_saved(old.id) then
      new.starts_at := old.starts_at;
      new.ends_at := old.ends_at;
    end if;
    -- A start can move later, not into the past, and not once it has passed.
    if old.starts_at <= now() or new.starts_at < now() then
      new.starts_at := old.starts_at;
    end if;
    if private.activity_has_scores(old.id) then
      new.ranked := old.ranked;
    end if;
  end if;
  return new;
end;
$$;

create function private.activity_start_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user = 'authenticated' and new.starts_at < now() then
    raise exception 'Pick a time that hasn''t passed.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
create trigger activities_start_guard before insert on public.activities
  for each row execute function private.activity_start_guard();

-- Attendance only touches Meets, and a host can't use it on their own match.
-- Once a rated result is taken back it stays back (Q60).
create or replace function private.attendance_rate() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: match_results and ratings have no client write path.
declare
  a public.activities;
  res public.match_results;
begin
  if new.attendance is not distinct from old.attendance then return new; end if;
  select * into a from public.activities where id = new.activity_id for no key update;
  if a.kind <> 'meet' then return new; end if;
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
    elsif private.result_rated(res.id) and not a.host_id = any (res.side_a || res.side_b) then
      perform private.rating_reverse(res.id);
    end if;
  end loop;
  return new;
end;
$$;

-- ─── A deleted account stops nothing ───────────────────────────────────────

do $$
declare
  d text;
  fixed text;
begin
  d := pg_get_functiondef('private.rating_apply(public.match_results)'::regprocedure);
  fixed := replace(d, $old$  if not p_result.ranked then return; end if;$old$,
    $new$  if not p_result.ranked then return; end if;
  -- A deleted account has no rating to move, so the result stands unrated.
  if exists (select 1 from unnest(v_everyone) x
      where not exists (select 1 from auth.users u where u.id = x)) then
    return;
  end if;$new$);
  if fixed = d then raise exception 'rating_apply did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('private.rating_reverse(uuid)'::regprocedure);
  fixed := replace(d, $old$      order by x.user_id loop$old$,
    $new$      and exists (select 1 from auth.users u where u.id = x.user_id)
      order by x.user_id loop$new$);
  if fixed = d then raise exception 'rating_reverse did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.organiser_decide_score(uuid, jsonb, text)'::regprocedure);
  fixed := replace(d, $old$  foreach u in array s.side_a || s.side_b loop$old$,
    $new$  for u in select x from unnest(s.side_a || s.side_b) x
      where exists (select 1 from auth.users v where v.id = x) loop$new$);
  if fixed = d then raise exception 'organiser_decide_score did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.staff_result_correct(uuid, jsonb, text)'::regprocedure);
  fixed := replace(d, $old$  v_new uuid := p_score;
begin$old$, $new$  v_new uuid := p_score;
  v_activity uuid;
begin$new$);
  fixed := replace(fixed, $old$  select * into s from public.match_scores where id = p_score for update;$old$,
    $new$  select activity_id into v_activity from public.match_scores where id = p_score;
  perform 1 from public.activities where id = v_activity for no key update;
  select * into s from public.match_scores where id = p_score for update;$new$);
  fixed := replace(fixed, $old$  v_rules := coalesce(s.rules,$old$,
    $new$  if auth.uid() = any (s.side_a || s.side_b) then
    raise exception 'You played in this match, so someone else corrects it.';
  end if;
  v_rules := coalesce(s.rules,$new$);
  fixed := replace(fixed, $old$  from unnest(s.side_a || s.side_b) u;$old$,
    $new$  from unnest(s.side_a || s.side_b) u
  where exists (select 1 from auth.users x where x.id = u);$new$);
  if position('v_activity uuid' in fixed) = 0 or position('someone else corrects' in fixed) = 0
    or position('x.id = u' in fixed) = 0 then
    raise exception 'staff_result_correct did not change';
  end if;
  execute fixed;

  -- One open score per match. The sides must fit the game, and nobody scores
  -- against someone blocked: they can't see each other on the roster.
  d := pg_get_functiondef('public.submit_score(uuid, uuid[], uuid[], jsonb, uuid)'::regprocedure);
  fixed := replace(d, $old$(s.status = 'waiting' or s.games = submit_score.games)$old$,
    $new$(s.status <> 'confirmed' or s.games = submit_score.games)$new$);
  fixed := replace(fixed, $old$(s.status = 'waiting' or s.games = v_flip)$old$,
    $new$(s.status <> 'confirmed' or s.games = v_flip)$new$);
  fixed := replace(fixed, $old$  if (select count(distinct u) from unnest(everyone) u) <> cardinality(everyone) then$old$,
    $new$  if cardinality(v_a) <> coalesce(case a.game_type when 'singles' then 1
      when 'doubles' then 2 when 'mixed' then 2 end, cardinality(v_a)) then
    raise exception 'That''s the wrong number of players for this game.';
  end if;
  if (select count(distinct u) from unnest(everyone) u) <> cardinality(everyone) then$new$);
  fixed := replace(fixed, $old$        and ap.attendance is distinct from 'absent')) then$old$,
    $new$        and ap.attendance is distinct from 'absent')
      or public.is_blocked_between(me, u)) then$new$);
  if position($s$status <> 'confirmed' or s.games = v_flip$s$ in fixed) = 0
    or position('wrong number of players' in fixed) = 0
    or position('is_blocked_between(me, u)' in fixed) = 0 then
    raise exception 'submit_score did not change';
  end if;
  execute fixed;

  -- A host earns no points from a draw they ran the scoring for.
  d := pg_get_functiondef('private.leaderboards_build()'::regprocedure);
  fixed := replace(d, $old$select sport, winner as entry, title,$old$, $new$select activity_id, sport, winner as entry, title,$new$);
  fixed := replace(fixed, $old$select sport, case when winner = entry_a$old$, $new$select activity_id, sport, case when winner = entry_a$new$);
  fixed := replace(fixed, $old$where f.entry is not null and f.pts is not null and private.listable(u)$old$,
    $new$where f.entry is not null and f.pts is not null and private.listable(u)
      and u <> (select a.host_id from public.activities a where a.id = f.activity_id)$new$);
  if position('a.id = f.activity_id' in fixed) = 0 or position('select activity_id, sport, case' in fixed) = 0 then
    raise exception 'leaderboards_build did not change';
  end if;
  execute fixed;
end;
$$;

-- ─── Scores are read through functions ─────────────────────────────────────

-- The tables hold real ids. A roster can show a minor by a stand-in, and a
-- score must not undo that, so clients read these instead.
revoke all on public.match_scores, public.match_results from anon, authenticated;

create function private.score_person(p_activity uuid, p_host uuid, p_user uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads profiles the caller may not see.
  select case
    when r.id = p_user then jsonb_build_object('id', r.id, 'username', p.username,
      'full_name', p.full_name, 'avatar_url', p.avatar_url)
    when public.is_blocked_between(auth.uid(), p_user) then jsonb_build_object('id', r.id)
    else jsonb_build_object('id', r.id, 'full_name', private.masked_name(p.full_name)) end
  from (select private.roster_id(p_activity, p_host, p_user) as id) r
  left join public.profiles p on p.id = p_user;
$$;
revoke execute on function private.score_person(uuid, uuid, uuid) from public;

create function public.score_view(p_score uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: match_scores has no client read path. Players in the match and
  -- its organizer only.
  select jsonb_build_object('id', s.id, 'activity_id', s.activity_id, 'title', a.title,
    'status', s.status, 'reason', s.reason, 'games', s.games, 'created_at', s.created_at,
    'side_a', (select jsonb_agg(private.score_person(a.id, a.host_id, u)) from unnest(s.side_a) u),
    'side_b', (select jsonb_agg(private.score_person(a.id, a.host_id, u)) from unnest(s.side_b) u),
    'entered_by', private.score_person(a.id, a.host_id, s.entered_by),
    'organizer', private.score_person(a.id, a.host_id, a.host_id))
  from public.match_scores s join public.activities a on a.id = s.activity_id
  where s.id = p_score and (auth.uid() = any (s.side_a || s.side_b) or a.host_id = auth.uid());
$$;

create function public.my_meet_results(p_activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: match_results has no client read path. The caller's own results,
  -- without any a correction replaced.
  select coalesce(jsonb_agg(jsonb_build_object('on_a', auth.uid() = any (m.side_a),
    'games', m.games, 'won', m.winner = case when auth.uid() = any (m.side_a) then 1 else 2 end)
    order by m.confirmed_at), '[]'::jsonb)
  from public.match_results m
  where m.activity_id = p_activity and auth.uid() = any (m.side_a || m.side_b)
    and not exists (select 1 from public.match_results n where n.supersedes = m.id);
$$;

create function public.meet_disputes(p_activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: match_scores has no client read path. What this organizer can
  -- decide, so not their own matches.
  select coalesce(jsonb_agg(s.id order by s.created_at), '[]'::jsonb)
  from public.match_scores s join public.activities a on a.id = s.activity_id
  where s.activity_id = p_activity and a.host_id = auth.uid() and s.status = 'disputed'
    and not auth.uid() = any (s.side_a || s.side_b);
$$;

create or replace function public.staff_scores(p_score uuid default null) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads scores across activities.
begin
  perform private.staff_require('moderator');
  return (select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'title', a.title, 'status', s.status,
      'games', s.games, 'reason', s.reason, 'at', s.created_at,
      'side_a', (select jsonb_agg(private.public_name(u)) from unnest(s.side_a) u),
      'side_b', (select jsonb_agg(private.public_name(u)) from unnest(s.side_b) u))
      order by s.created_at), '[]'::jsonb)
    from public.match_scores s join public.activities a on a.id = s.activity_id
    where case when p_score is not null then s.id = p_score
      else s.status = 'disputed' and (a.host_id = any (s.side_a || s.side_b)
        or s.created_at < now() - make_interval(hours => private.setting_int('score.staff_after_hours'))) end);
end;
$$;

revoke execute on function public.score_view(uuid) from public, anon;
revoke execute on function public.my_meet_results(uuid) from public, anon;
revoke execute on function public.meet_disputes(uuid) from public, anon;
grant execute on function public.score_view(uuid) to authenticated;
grant execute on function public.my_meet_results(uuid) to authenticated;
grant execute on function public.meet_disputes(uuid) to authenticated;
