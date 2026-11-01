-- P5-04: Fitness. Exercises, programs and a private workout log. Nothing here
-- earns points, vouchers, badges or rating. Clients reach these tables through
-- the functions below only.

insert into public.feature_flags (key, enabled, description) values
  ('fitness.enabled', false, 'Workouts: exercises, programs and the log');

insert into public.app_settings (key, value, description) values
  ('fitness.daily_workouts', '20', 'Workouts one player can save in 24 hours (Q183)');

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null check (char_length(trim(name)) between 2 and 60),
  -- The two letters on the exercise's tile.
  mark text not null check (char_length(mark) = 2),
  muscle_group text not null check (muscle_group in ('legs', 'core', 'upper')),
  muscles text[] not null default '{}',
  equipment text not null check (char_length(trim(equipment)) between 2 and 40),
  steps text[] not null default '{}',
  tip text not null default '' check (char_length(tip) <= 200),
  safety text not null default '' check (char_length(safety) <= 200),
  -- Timed exercises, such as a plank, log seconds instead of reps.
  unit text not null default 'reps' check (unit in ('reps', 'seconds')),
  weighted boolean not null default false,
  minors_ok boolean not null default false,
  status text not null default 'live' check (status in ('draft', 'live')),
  sort int not null default 0
);
create index exercises_live_idx on public.exercises (sort) where status = 'live';

-- A template is a program with no owner.
create table public.programs (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 60),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index programs_owner_idx on public.programs (owner_id);

create table public.program_days (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs (id) on delete cascade,
  position int not null check (position between 1 and 7),
  name text not null default '' check (char_length(name) <= 60),
  unique (program_id, position)
);

create table public.program_items (
  id uuid primary key default gen_random_uuid(),
  day_id uuid not null references public.program_days (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id),
  position int not null check (position between 1 and 30),
  sets int not null check (sets between 1 and 20),
  reps int check (reps between 1 and 200),
  seconds int check (seconds between 1 and 3600),
  weight_g int check (weight_g between 0 and 500000),
  rest_seconds int not null default 60 check (rest_seconds between 0 and 900),
  unique (day_id, position),
  check (num_nonnulls(reps, seconds) = 1)
);
create index program_items_exercise_idx on public.program_items (exercise_id);

create table public.workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- Made on the phone, so a retry can't save the same workout twice.
  client_key text not null check (char_length(client_key) between 8 and 64),
  program_id uuid references public.programs (id) on delete set null,
  name text not null check (char_length(trim(name)) between 2 and 60),
  started_at timestamptz not null,
  ended_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (user_id, client_key),
  check (ended_at >= started_at and ended_at <= started_at + interval '12 hours')
);
create index workouts_user_idx on public.workouts (user_id, started_at desc);
create index workouts_program_idx on public.workouts (program_id);

create table public.workout_sets (
  id bigint generated always as identity primary key,
  workout_id uuid not null references public.workouts (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id),
  position int not null check (position between 1 and 300),
  reps int check (reps between 1 and 200),
  seconds int check (seconds between 1 and 3600),
  weight_g int check (weight_g between 0 and 500000),
  unique (workout_id, position),
  check (num_nonnulls(reps, seconds) = 1)
);
create index workout_sets_exercise_idx on public.workout_sets (exercise_id);

do $$
declare
  t text;
begin
  foreach t in array array['exercises', 'programs', 'program_days', 'program_items', 'workouts', 'workout_sets']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
  end loop;
end;
$$;

-- ─── Helpers ───────────────────────────────────────────────────────────────

-- Refuses anyone who can't use Fitness, and says whether the caller is a minor.
create function private.fitness_gate() returns boolean
language plpgsql stable set search_path = '' as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Log in first.'; end if;
  if private.is_suspended(v_user) then raise exception 'Your account is suspended.'; end if;
  if private.is_restricted(v_user) then raise exception 'Ask a parent to link your account first.'; end if;
  if not private.flag('fitness.enabled') then raise exception 'Workouts are not open yet.'; end if;
  return private.is_minor(v_user);
end;
$$;
revoke execute on function private.fitness_gate() from public, anon, authenticated;

create function private.fitness_tz(p_user uuid) returns text
language sql stable set search_path = '' as $$
  select coalesce((select c.timezone from public.account_private a
    join public.country_config c on c.country_code = a.country_code where a.id = p_user), 'Asia/Singapore');
$$;
revoke execute on function private.fitness_tz(uuid) from public, anon, authenticated;

create function private.exercise_json(e public.exercises) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object('id', e.id, 'name', e.name, 'mark', e.mark, 'muscle_group', e.muscle_group,
    'muscles', to_jsonb(e.muscles), 'equipment', e.equipment, 'steps', to_jsonb(e.steps), 'tip', e.tip,
    'safety', e.safety, 'unit', e.unit, 'weighted', e.weighted);
$$;
revoke execute on function private.exercise_json(public.exercises) from public, anon, authenticated;

-- Leaves out anything the player can't do now: an exercise taken off the list,
-- or one not cleared for under-18s. The next save drops it.
create function private.program_json(p public.programs, p_minor boolean) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object('id', p.id, 'name', p.name, 'template', p.owner_id is null,
    'days', coalesce((select jsonb_agg(jsonb_build_object('name', d.name,
      'items', coalesce((select jsonb_agg(jsonb_build_object('exercise_id', i.exercise_id, 'exercise', e.name,
          'mark', e.mark, 'unit', e.unit, 'weighted', e.weighted, 'sets', i.sets, 'reps', i.reps,
          'seconds', i.seconds, 'weight_g', i.weight_g, 'rest_seconds', i.rest_seconds) order by i.position)
        from public.program_items i join public.exercises e on e.id = i.exercise_id
        where i.day_id = d.id and e.status = 'live' and (e.minors_ok or not p_minor)), '[]')) order by d.position)
      from public.program_days d where d.program_id = p.id), '[]'));
$$;
revoke execute on function private.program_json(public.programs, boolean) from public, anon, authenticated;

-- ─── Exercises and programs ────────────────────────────────────────────────

create function public.exercise_list() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: the tables have no client access, and this applies the age rule.
declare
  v_minor boolean := private.fitness_gate();
begin
  return (select coalesce(jsonb_agg(private.exercise_json(e) order by e.sort, e.name), '[]')
    from public.exercises e where e.status = 'live' and (e.minors_ok or not v_minor));
end;
$$;

create function public.program_list() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: a player sees their own programs and the templates that suit them.
declare
  v_minor boolean := private.fitness_gate();
begin
  return (select coalesce(jsonb_agg(private.program_json(p, v_minor)
      order by p.owner_id is null, p.updated_at desc), '[]')
    from public.programs p
    where p.owner_id = auth.uid()
      or (p.owner_id is null and (not v_minor or not exists (
        select 1 from public.program_days d
        join public.program_items i on i.day_id = d.id
        join public.exercises e on e.id = i.exercise_id
        where d.program_id = p.id and not e.minors_ok))));
end;
$$;

-- The phone makes the id, so a retry updates the same program.
create function public.program_save(p_program jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: the tables have no client access. Only the caller's own row changes.
declare
  v_minor boolean := private.fitness_gate();
  v_user uuid := auth.uid();
  v_id uuid;
  v_name text := trim(coalesce(p_program ->> 'name', ''));
  v_days jsonb := p_program -> 'days';
  v_day jsonb;
  v_item jsonb;
  v_day_id uuid;
  v_ex public.exercises;
  v_found uuid;
  v_d int := 0;
  v_i int;
  v_count int := 0;
begin
  if char_length(v_name) not between 2 and 60 then raise exception 'Give the program a name.'; end if;
  if v_days is null or jsonb_typeof(v_days) <> 'array' or jsonb_array_length(v_days) not between 1 and 7 then
    raise exception 'A program has 1 to 7 days.';
  end if;
  begin
    v_id := coalesce((p_program ->> 'id')::uuid, gen_random_uuid());
  exception when invalid_text_representation then
    raise exception 'Program not found.';
  end;

  -- One at a time per player, so the limit below holds.
  perform pg_advisory_xact_lock(hashtextextended('program:' || v_user::text, 0));
  if (select count(*) from public.programs p where p.owner_id = v_user and p.id <> v_id) >= 50 then
    raise exception 'You have 50 programs. Delete one first.';
  end if;

  insert into public.programs (id, owner_id, name) values (v_id, v_user, v_name)
  on conflict (id) do update set name = excluded.name, updated_at = now()
    where public.programs.owner_id = v_user
  returning id into v_found;
  if v_found is null then raise exception 'Program not found.'; end if;

  delete from public.program_days d where d.program_id = v_id;
  for v_day in select * from jsonb_array_elements(v_days) loop
    v_d := v_d + 1;
    if char_length(coalesce(v_day ->> 'name', '')) > 60 then raise exception 'That day name is too long.'; end if;
    if jsonb_typeof(v_day -> 'items') is distinct from 'array' or jsonb_array_length(v_day -> 'items') > 30 then
      raise exception 'A day has up to 30 exercises.';
    end if;
    insert into public.program_days (program_id, position, name)
    values (v_id, v_d, coalesce(v_day ->> 'name', '')) returning id into v_day_id;
    v_i := 0;
    for v_item in select * from jsonb_array_elements(v_day -> 'items') loop
      v_i := v_i + 1;
      begin
        select * into v_ex from public.exercises e where e.id = (v_item ->> 'exercise_id')::uuid;
      exception when invalid_text_representation then
        v_ex := null;
      end;
      if v_ex.id is null or v_ex.status <> 'live' or (v_minor and not v_ex.minors_ok) then
        raise exception 'That exercise is not available.';
      end if;
      begin
        insert into public.program_items (day_id, exercise_id, position, sets, reps, seconds, weight_g, rest_seconds)
        values (v_day_id, v_ex.id, v_i, (v_item ->> 'sets')::int,
          case when v_ex.unit = 'reps' then (v_item ->> 'reps')::int end,
          case when v_ex.unit = 'seconds' then (v_item ->> 'seconds')::int end,
          case when v_ex.weighted then (v_item ->> 'weight_g')::int end,
          coalesce((v_item ->> 'rest_seconds')::int, 60));
      exception when check_violation or not_null_violation or invalid_text_representation
        or numeric_value_out_of_range then
        raise exception 'Check the sets, reps, weight and rest.';
      end;
      v_count := v_count + 1;
    end loop;
  end loop;
  if v_count = 0 then raise exception 'Add an exercise first.'; end if;
  return v_id;
end;
$$;

create function public.program_delete(p_program uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: only the caller's own row goes. Past workouts stay in the log.
begin
  perform private.fitness_gate();
  delete from public.programs p where p.id = p_program and p.owner_id = auth.uid();
end;
$$;

-- ─── The log ───────────────────────────────────────────────────────────────

create function public.workout_save(p_client_key text, p_workout jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: the tables have no client access. The row always belongs to the caller.
declare
  v_minor boolean := private.fitness_gate();
  v_user uuid := auth.uid();
  v_id uuid;
  v_program uuid;
  v_sets jsonb := p_workout -> 'sets';
  v_set jsonb;
  v_ex public.exercises;
  v_name text := trim(coalesce(p_workout ->> 'name', ''));
  v_started timestamptz;
  v_ended timestamptz;
  v_i int := 0;
begin
  if p_client_key is null or char_length(p_client_key) not between 8 and 64 then
    raise exception 'This workout can''t be saved.';
  end if;
  select w.id into v_id from public.workouts w where w.user_id = v_user and w.client_key = p_client_key;
  if v_id is not null then return v_id; end if;

  if char_length(v_name) not between 2 and 60 then raise exception 'Give the workout a name.'; end if;
  if v_sets is null or jsonb_typeof(v_sets) <> 'array' or jsonb_array_length(v_sets) not between 1 and 300 then
    raise exception 'Finish a set first.';
  end if;
  begin
    v_started := (p_workout ->> 'started_at')::timestamptz;
    v_ended := (p_workout ->> 'ended_at')::timestamptz;
    v_program := (p_workout ->> 'program_id')::uuid;
  exception when others then
    raise exception 'This workout can''t be saved.';
  end;
  if v_started is null or v_ended is null or not isfinite(v_started) or not isfinite(v_ended)
      or v_ended < v_started or v_ended > now() + interval '5 minutes'
      or v_ended > v_started + interval '12 hours' then
    raise exception 'Check the workout''s start and finish.';
  end if;
  -- One at a time per player, so the limit holds.
  perform pg_advisory_xact_lock(hashtextextended('workout:' || v_user::text, 0));
  -- A retry may have waited on the lock while the first attempt saved.
  select w.id into v_id from public.workouts w where w.user_id = v_user and w.client_key = p_client_key;
  if v_id is not null then return v_id; end if;
  if (select count(*) from public.workouts w where w.user_id = v_user
      and w.created_at > now() - interval '1 day') >= private.setting_int('fitness.daily_workouts') then
    raise exception 'That''s a lot of workouts for one day. Try again tomorrow.';
  end if;
  if v_program is not null and not exists (select 1 from public.programs p
      where p.id = v_program and (p.owner_id = v_user or p.owner_id is null)) then
    v_program := null;
  end if;

  insert into public.workouts (user_id, client_key, program_id, name, started_at, ended_at)
  values (v_user, p_client_key, v_program, v_name, v_started, v_ended)
  on conflict (user_id, client_key) do nothing
  returning id into v_id;
  if v_id is null then
    select w.id into v_id from public.workouts w where w.user_id = v_user and w.client_key = p_client_key;
    return v_id;
  end if;

  for v_set in select * from jsonb_array_elements(v_sets) loop
    v_i := v_i + 1;
    begin
      select * into v_ex from public.exercises e where e.id = (v_set ->> 'exercise_id')::uuid;
    exception when invalid_text_representation then
      v_ex := null;
    end;
    -- A workout can finish after an exercise left the list, so status isn't checked.
    if v_ex.id is null or (v_minor and not v_ex.minors_ok) then
      raise exception 'That exercise is not available.';
    end if;
    begin
      insert into public.workout_sets (workout_id, exercise_id, position, reps, seconds, weight_g)
      values (v_id, v_ex.id, v_i,
        case when v_ex.unit = 'reps' then (v_set ->> 'reps')::int end,
        case when v_ex.unit = 'seconds' then (v_set ->> 'seconds')::int end,
        case when v_ex.weighted then (v_set ->> 'weight_g')::int end);
    exception when check_violation or not_null_violation or invalid_text_representation
      or numeric_value_out_of_range then
      raise exception 'Check the reps, time and weight.';
    end;
  end loop;
  return v_id;
end;
$$;

create function public.workout_delete(p_workout uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: only the caller's own workout goes.
begin
  perform private.fitness_gate();
  delete from public.workouts w where w.id = p_workout and w.user_id = auth.uid();
end;
$$;

-- p_days null means all time. The streak and 30-day count ignore the range.
create function public.workout_summary(p_days int default 30) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: returns the caller's own log, to nobody else.
declare
  v_user uuid := auth.uid();
  v_tz text;
  v_from timestamptz;
  v_this date;
  v_anchor date;
  v_streak int;
begin
  perform private.fitness_gate();
  v_tz := private.fitness_tz(v_user);
  v_from := case when p_days is null then '-infinity'::timestamptz
    else now() - make_interval(days => least(greatest(p_days, 1), 3650)) end;
  v_this := date_trunc('week', now() at time zone v_tz)::date;
  v_anchor := case when exists (select 1 from public.workouts w where w.user_id = v_user
      and date_trunc('week', w.started_at at time zone v_tz)::date = v_this) then v_this else v_this - 7 end;
  with weeks as (
    select distinct date_trunc('week', w.started_at at time zone v_tz)::date as d
    from public.workouts w where w.user_id = v_user
  ), numbered as (select d, row_number() over (order by d desc) as r from weeks)
  select count(*) into v_streak from numbered where d = v_anchor - ((r - 1) * 7)::int;

  return (with mine as (
      select w.id, w.name, w.started_at, w.ended_at,
        (select coalesce(sum(coalesce(s.weight_g, 0)::bigint * coalesce(s.reps, 0)), 0)
          from public.workout_sets s where s.workout_id = w.id) as lifted_g,
        (select count(distinct s.exercise_id) from public.workout_sets s where s.workout_id = w.id) as exercises
      from public.workouts w where w.user_id = v_user
    ), best as (
      select distinct on (s.exercise_id) s.exercise_id, s.reps, s.seconds, s.weight_g, w.started_at
      from public.workout_sets s join public.workouts w on w.id = s.workout_id
      where w.user_id = v_user
      order by s.exercise_id, s.weight_g desc nulls last, s.reps desc nulls last, s.seconds desc nulls last,
        w.started_at
    )
    select jsonb_build_object(
      'minor', private.is_minor(v_user),
      'workouts', (select count(*) from mine m where m.started_at >= v_from),
      'seconds', (select coalesce(sum(extract(epoch from m.ended_at - m.started_at))::bigint, 0)
        from mine m where m.started_at >= v_from),
      'lifted_g', (select coalesce(sum(m.lifted_g), 0) from mine m where m.started_at >= v_from),
      'workouts_30d', (select count(*) from mine m where m.started_at >= now() - interval '30 days'),
      'week_streak', v_streak,
      'lifted_week_g', (select coalesce(sum(m.lifted_g), 0) from mine m
        where date_trunc('week', m.started_at at time zone v_tz)::date = v_this),
      'recent', (select coalesce(jsonb_agg(jsonb_build_object('id', x.id, 'name', x.name, 'started_at', x.started_at,
          'seconds', extract(epoch from x.ended_at - x.started_at)::bigint, 'exercises', x.exercises,
          'lifted_g', x.lifted_g) order by x.started_at desc), '[]')
        from (select * from mine m where m.started_at >= v_from order by m.started_at desc limit 100) x),
      'bests', (select coalesce(jsonb_agg(jsonb_build_object('exercise_id', b.exercise_id, 'exercise', e.name,
          'reps', b.reps, 'seconds', b.seconds, 'weight_g', b.weight_g, 'at', b.started_at)
          order by b.started_at desc), '[]')
        from (select * from best order by started_at desc limit 5) b
        join public.exercises e on e.id = b.exercise_id)));
end;
$$;

create function public.exercise_history(p_exercise uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: returns the caller's own sets, to nobody else.
declare
  v_user uuid := auth.uid();
begin
  perform private.fitness_gate();
  return (with mine as (
      select s.reps, s.seconds, s.weight_g, w.started_at, w.id as workout_id, s.position
      from public.workout_sets s join public.workouts w on w.id = s.workout_id
      where w.user_id = v_user and s.exercise_id = p_exercise
    )
    select jsonb_build_object(
      'times', (select count(distinct m.workout_id) from mine m),
      'best', (select to_jsonb(b) from (select m.reps, m.seconds, m.weight_g, m.started_at as at from mine m
        order by m.weight_g desc nulls last, m.reps desc nulls last, m.seconds desc nulls last, m.started_at
        limit 1) b),
      'recent', (select coalesce(jsonb_agg(jsonb_build_object('reps', r.reps, 'seconds', r.seconds,
          'weight_g', r.weight_g, 'at', r.started_at) order by r.started_at desc, r.position desc), '[]')
        from (select * from mine m order by m.started_at desc, m.position desc limit 30) r)));
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'exercise_list()', 'program_list()', 'program_save(jsonb)', 'program_delete(uuid)',
    'workout_save(text, jsonb)', 'workout_delete(uuid)', 'workout_summary(integer)', 'exercise_history(uuid)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;

-- supabase_flutter calls every function with POST, so reads count here too.
-- That is why the reads above aren't stable: the API runs a stable function in
-- a read-only transaction, where the request gate can't record the hit.
insert into private.rate_rules (path, max_hits, window_seconds) values
  ('/rpc/exercise_list', 300, 3600),
  ('/rpc/program_list', 300, 3600),
  ('/rpc/program_save', 60, 3600),
  ('/rpc/program_delete', 60, 3600),
  ('/rpc/workout_save', 60, 3600),
  ('/rpc/workout_delete', 60, 3600),
  ('/rpc/workout_summary', 300, 3600),
  ('/rpc/exercise_history', 300, 3600);
