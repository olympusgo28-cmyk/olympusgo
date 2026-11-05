-- P5-05: AI plans. An adult who has agreed gets a draft program from a summary
-- of their workouts. Nothing a player typed reaches the model, and neither the
-- prompt nor the answer is stored. Only the Edge Function calls the model.

insert into public.feature_flags (key, enabled, description) values
  ('fitness.ai_plans', false, 'AI-written draft programs, for adults who have agreed');

insert into public.app_settings (key, value, description) values
  ('ai_plans.daily_per_player', '3', 'AI plans one player can ask for in 24 hours (Q184)'),
  ('ai_plans.daily_total', '200', 'AI plans across the app in 24 hours, to cap cost (Q185)'),
  ('ai_plans.model', '"claude-opus-5-5"', 'The model that writes AI plans');

alter table public.consents drop constraint consents_kind_check;
alter table public.consents add constraint consents_kind_check check (kind in ('location', 'ai_plans'));

-- A minor's agreement can't count later, so it is never recorded.
do $$
declare
  d text := pg_get_functiondef('public.consent_set(text, boolean)'::regprocedure);
  fixed text := replace(d, $x$begin
  insert into public.consents as c$x$, $x$begin
  if p_kind = 'ai_plans' and p_granted and private.is_minor(auth.uid()) then
    raise exception 'AI plans are for adults.';
  end if;
  insert into public.consents as c$x$);
begin
  if fixed = d then raise exception 'consent_set did not change'; end if;
  execute fixed;
end;
$$;

alter table public.programs add column source text not null default 'player' check (source in ('player', 'ai'));

create table public.ai_plan_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  -- Made on the phone, so a retry can't pay for a second plan.
  client_key text not null check (char_length(client_key) between 8 and 64),
  goal text not null check (goal in ('speed', 'strength', 'mobility', 'general')),
  days int not null check (days between 2 and 5),
  status text not null default 'pending' check (status in ('pending', 'done', 'failed')),
  model text,
  input_tokens int,
  output_tokens int,
  program_id uuid references public.programs (id) on delete set null,
  created_at timestamptz not null default now(),
  finished_at timestamptz,
  unique (user_id, client_key)
);
create index ai_plan_requests_recent_idx on public.ai_plan_requests (created_at);
create index ai_plan_requests_program_idx on public.ai_plan_requests (program_id);
alter table public.ai_plan_requests enable row level security;
revoke all on public.ai_plan_requests from anon, authenticated;

-- ─── Shared saving ─────────────────────────────────────────────────────────

-- Saves a program for p_user. Its callers have already checked who that is.
create function private.program_write(p_user uuid, p_minor boolean, p_program jsonb, p_source text)
returns uuid language plpgsql set search_path = '' as $$
declare
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
  perform pg_advisory_xact_lock(hashtextextended('program:' || p_user::text, 0));
  if (select count(*) from public.programs p where p.owner_id = p_user and p.id <> v_id) >= 50 then
    raise exception 'You have 50 programs. Delete one first.';
  end if;

  insert into public.programs (id, owner_id, name, source) values (v_id, p_user, v_name, p_source)
  on conflict (id) do update set name = excluded.name, updated_at = now()
    where public.programs.owner_id = p_user
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
      if v_ex.id is null or v_ex.status <> 'live' or (p_minor and not v_ex.minors_ok) then
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
revoke execute on function private.program_write(uuid, boolean, jsonb, text) from public, anon, authenticated;

create or replace function public.program_save(p_program jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: the tables have no client access. Only the caller's own row changes.
declare
  v_minor boolean := private.fitness_gate();
begin
  return private.program_write(auth.uid(), v_minor, p_program, 'player');
end;
$$;

do $$
declare
  d text := pg_get_functiondef('private.program_json(public.programs, boolean)'::regprocedure);
  fixed text := replace(d, $x$'template', p.owner_id is null,$x$, $x$'template', p.owner_id is null, 'source', p.source,$x$);
begin
  if fixed = d then raise exception 'program_json did not change'; end if;
  execute fixed;
end;
$$;

-- ─── Requests ──────────────────────────────────────────────────────────────

create function private.ai_consent(p_user uuid) returns boolean
language sql stable set search_path = '' as $$
  select exists (select 1 from public.consents c
    where c.user_id = p_user and c.kind = 'ai_plans' and c.withdrawn_at is null);
$$;
revoke execute on function private.ai_consent(uuid) from public, anon, authenticated;

-- Says no rather than raising when a flag is off, so Settings can still offer
-- withdrawing.
create function public.ai_plan_status() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: reads settings and the caller's own requests, which have no client access.
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Log in first.'; end if;
  return jsonb_build_object(
    'open', private.flag('fitness.enabled') and private.flag('fitness.ai_plans') and not private.is_minor(v_user)
      and not private.is_restricted(v_user),
    'agreed', private.ai_consent(v_user),
    'left', greatest(0, private.setting_int('ai_plans.daily_per_player') - (select count(*)
      from public.ai_plan_requests r where r.user_id = v_user and r.created_at > now() - interval '1 day')));
end;
$$;

-- Withdrawing works for anyone, suspended and restricted players included, so
-- it has its own function that can only ever say no.
create function public.ai_plan_withdraw() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the caller's own consent row.
begin
  perform public.consent_set('ai_plans', false);
end;
$$;

insert into private.restricted_allow (path) values ('/rpc/ai_plan_status'), ('/rpc/ai_plan_withdraw');
insert into private.suspended_allow (path) values ('/rpc/ai_plan_status'), ('/rpc/ai_plan_withdraw');

-- Only what the plan needs: our own exercise names and the player's numbers.
create function private.ai_plan_summary(p_user uuid) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'workouts_28_days', (select count(*) from public.workouts w
      where w.user_id = p_user and w.started_at > now() - interval '28 days'),
    'exercises', (select coalesce(jsonb_agg(to_jsonb(x) order by x.exercise), '[]') from (
      select e.name as exercise, count(*) as sets, max(s.reps) as best_reps, max(s.seconds) as best_seconds,
        max(s.weight_g) as best_weight_g
      from public.workouts w
      join public.workout_sets s on s.workout_id = w.id
      join public.exercises e on e.id = s.exercise_id
      where w.user_id = p_user and w.started_at > now() - interval '28 days'
      group by e.name) x));
$$;
revoke execute on function private.ai_plan_summary(uuid) from public, anon, authenticated;

-- Called as the player by the ai-plan function, so the API gate runs too. A
-- key that has run before gives its result and spends nothing.
create function public.ai_plan_begin(p_client_key text, p_goal text, p_days int) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: writes requests and reads the log, which have no client access.
declare
  v_minor boolean := private.fitness_gate();
  v_user uuid := auth.uid();
  v_old public.ai_plan_requests;
  v_id uuid;
begin
  if v_minor then raise exception 'AI plans are for adults.'; end if;
  if not private.flag('fitness.ai_plans') then raise exception 'AI plans are not open yet.'; end if;
  if not private.ai_consent(v_user) then raise exception 'Agree to AI plans first.'; end if;
  if p_client_key is null or char_length(p_client_key) not between 8 and 64 then
    raise exception 'Couldn''t make a plan. Try again.';
  end if;
  if p_goal is null or p_goal not in ('speed', 'strength', 'mobility', 'general')
      or p_days is null or p_days not between 2 and 5 then
    raise exception 'Choose a goal and days a week.';
  end if;

  -- One at a time per player, so the limit holds.
  perform pg_advisory_xact_lock(hashtextextended('ai-plan:' || v_user::text, 0));
  select * into v_old from public.ai_plan_requests r where r.user_id = v_user and r.client_key = p_client_key;
  if v_old.id is not null then
    if v_old.status = 'done' and v_old.program_id is not null then
      return jsonb_build_object('status', 'done', 'program_id', v_old.program_id);
    end if;
    if v_old.status = 'pending' and v_old.created_at > now() - interval '3 minutes' then
      return jsonb_build_object('status', 'pending');
    end if;
    -- A retry of a failed plan would spend money with no limit.
    raise exception 'That plan didn''t work. Start a new one.';
  end if;

  if (select count(*) from public.ai_plan_requests r where r.user_id = v_user
      and r.created_at > now() - interval '1 day') >= private.setting_int('ai_plans.daily_per_player') then
    raise exception 'You''ve made today''s plans. Try again tomorrow.';
  end if;
  -- A plan that couldn't be saved would be paid for and lost.
  if (select count(*) from public.programs p where p.owner_id = v_user) >= 50 then
    raise exception 'You have 50 programs. Delete one first.';
  end if;
  -- Across all players, so this one is held until the request is written.
  perform pg_advisory_xact_lock(hashtextextended('ai-plan-total', 0));
  if (select count(*) from public.ai_plan_requests r where r.created_at > now() - interval '1 day')
      >= private.setting_int('ai_plans.daily_total') then
    raise exception 'AI plans are busy today. Try again tomorrow.';
  end if;

  insert into public.ai_plan_requests (user_id, client_key, goal, days)
  values (v_user, p_client_key, p_goal, p_days) returning id into v_id;

  return jsonb_build_object('status', 'ready', 'request_id', v_id, 'goal', p_goal, 'days', p_days,
    'model', (select s.value #>> '{}' from public.app_settings s where s.key = 'ai_plans.model'),
    'summary', private.ai_plan_summary(v_user),
    'catalogue', (select coalesce(jsonb_agg(jsonb_build_object('slug', e.slug, 'name', e.name,
        'group', e.muscle_group, 'equipment', e.equipment, 'unit', e.unit, 'weighted', e.weighted)
        order by e.sort), '[]')
      from public.exercises e where e.status = 'live'));
end;
$$;

-- Words a plan must never carry (R-FIT-3), and no weight in a name. The prompt
-- asks for this, and this doesn't rely on it. planner.ts holds the same list.
create function private.ai_plan_clean(p_text text) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(p_text, '') !~* '\m(calories?|kcal|injur\w*|rehab\w*|cures?|heal|heals|healing|medical|doctors?|diets?|dieting|weight.?loss|burn\w*|fat|prevent\w*|therap\w*|diagnos\w*|pain\w*|recover\w*)\M|\d\s*(kg|kgs|lb|lbs)\M';
$$;
revoke execute on function private.ai_plan_clean(text) from public, anon, authenticated;

-- May the function still send this player's data? Asked before a second try,
-- so withdrawing or a suspension takes effect at once.
create function private.ai_plan_allowed(r public.ai_plan_requests) returns boolean
language sql stable set search_path = '' as $$
  select r.status = 'pending' and not private.is_minor(r.user_id) and not private.is_restricted(r.user_id)
    and private.ai_consent(r.user_id) and private.flag('fitness.enabled') and private.flag('fitness.ai_plans');
$$;
revoke execute on function private.ai_plan_allowed(public.ai_plan_requests) from public, anon, authenticated;

create function public.ai_plan_svc_allowed(p_request uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: service role only. Reads the request, which has no client access.
  select coalesce((select private.ai_plan_allowed(r) from public.ai_plan_requests r where r.id = p_request), false);
$$;

-- The service side. Everything is checked again here, whatever the function
-- already did. A plan that fails saves nothing.
create function public.ai_plan_svc_finish(p_request uuid, p_plan jsonb, p_model text,
  p_input_tokens int, p_output_tokens int) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only. Saves a program for the player who asked.
declare
  r public.ai_plan_requests;
  v_day jsonb;
  v_item jsonb;
  v_days jsonb := '[]';
  v_items jsonb;
  v_ex public.exercises;
  v_program uuid;
begin
  select * into r from public.ai_plan_requests x where x.id = p_request for update;
  if r.id is null then raise exception 'Unknown request.'; end if;
  if r.status = 'done' then return r.program_id; end if;
  if r.status <> 'pending' then raise exception 'That plan didn''t work. Start a new one.'; end if;
  if not private.ai_plan_allowed(r) then raise exception 'This plan can''t be saved.'; end if;

  if jsonb_typeof(p_plan -> 'days') is distinct from 'array' or jsonb_array_length(p_plan -> 'days') <> r.days then
    raise exception 'The plan has the wrong number of days.';
  end if;
  if char_length(trim(coalesce(p_plan ->> 'name', ''))) not between 2 and 60
      or not private.ai_plan_clean(p_plan ->> 'name') then
    raise exception 'The plan''s name isn''t usable.';
  end if;

  for v_day in select * from jsonb_array_elements(p_plan -> 'days') loop
    if char_length(coalesce(v_day ->> 'name', '')) > 60 or not private.ai_plan_clean(v_day ->> 'name') then
      raise exception 'A day''s name isn''t usable.';
    end if;
    if jsonb_typeof(v_day -> 'items') is distinct from 'array'
        or jsonb_array_length(v_day -> 'items') not between 1 and 12 then
      raise exception 'A day needs 1 to 12 exercises.';
    end if;
    v_items := '[]';
    for v_item in select * from jsonb_array_elements(v_day -> 'items') loop
      if v_item ? 'weight_g' then raise exception 'A plan can''t set a weight.'; end if;
      select * into v_ex from public.exercises e where e.slug = v_item ->> 'exercise' and e.status = 'live';
      if v_ex.id is null then raise exception 'The plan names an exercise that isn''t available.'; end if;
      v_items := v_items || jsonb_build_object('exercise_id', v_ex.id, 'sets', v_item -> 'sets', 'reps', v_item -> 'reps',
        'seconds', v_item -> 'seconds', 'rest_seconds', v_item -> 'rest_seconds');
    end loop;
    v_days := v_days || jsonb_build_object('name', coalesce(v_day ->> 'name', ''), 'items', v_items);
  end loop;

  v_program := private.program_write(r.user_id, false,
    jsonb_build_object('name', trim(p_plan ->> 'name'), 'days', v_days), 'ai');
  update public.ai_plan_requests x set status = 'done', program_id = v_program, model = p_model,
    input_tokens = p_input_tokens, output_tokens = p_output_tokens, finished_at = now()
  where x.id = p_request;
  return v_program;
end;
$$;

create function public.ai_plan_svc_fail(p_request uuid, p_model text, p_input_tokens int, p_output_tokens int)
returns void language plpgsql security definer set search_path = '' as $$
-- Definer: service role only. A failed plan still counts, because it still cost money.
begin
  update public.ai_plan_requests x set status = 'failed', model = p_model, input_tokens = p_input_tokens,
    output_tokens = p_output_tokens, finished_at = now()
  where x.id = p_request and x.status = 'pending';
end;
$$;

revoke execute on function public.ai_plan_status() from public, anon;
grant execute on function public.ai_plan_status() to authenticated;
revoke execute on function public.ai_plan_withdraw() from public, anon;
grant execute on function public.ai_plan_withdraw() to authenticated;
revoke execute on function public.ai_plan_begin(text, text, int) from public, anon;
grant execute on function public.ai_plan_begin(text, text, int) to authenticated;
revoke execute on function public.ai_plan_svc_finish(uuid, jsonb, text, int, int) from public, anon, authenticated;
grant execute on function public.ai_plan_svc_finish(uuid, jsonb, text, int, int) to service_role;
revoke execute on function public.ai_plan_svc_allowed(uuid) from public, anon, authenticated;
grant execute on function public.ai_plan_svc_allowed(uuid) to service_role;
revoke execute on function public.ai_plan_svc_fail(uuid, text, int, int) from public, anon, authenticated;
grant execute on function public.ai_plan_svc_fail(uuid, text, int, int) to service_role;

insert into private.rate_rules (path, max_hits, window_seconds) values
  ('/rpc/ai_plan_begin', 20, 3600),
  ('/rpc/ai_plan_status', 300, 3600);
