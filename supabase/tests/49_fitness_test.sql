-- P5-04: exercises, programs and the private workout log, for every role.
begin;
\ir helpers/setup.psql
select no_plan();

select t.player('e1000000-0000-0000-0000-000000000001');  -- adult
select t.player('e1000000-0000-0000-0000-000000000002');  -- another adult
select t.player('e1000000-0000-0000-0000-000000000003', 15);  -- linked teen
select t.player('e1000000-0000-0000-0000-000000000004', 40);  -- that teen's parent
select t.player('e1000000-0000-0000-0000-000000000005', 15);  -- teen with no parent, restricted
select t.player('e1000000-0000-0000-0000-000000000006');  -- suspended adult
select t.player('e1000000-0000-0000-0000-000000000007');  -- staff
insert into public.guardian_links (parent_id, child_id, status)
values ('e1000000-0000-0000-0000-000000000004', 'e1000000-0000-0000-0000-000000000003', 'approved');
insert into public.staff (user_id, role) values ('e1000000-0000-0000-0000-000000000007', 'super');
insert into public.blocks (blocker_id, blocked_id)
values ('e1000000-0000-0000-0000-000000000002', 'e1000000-0000-0000-0000-000000000001');
insert into public.account_moderation (user_id, suspended_until)
values ('e1000000-0000-0000-0000-000000000006', now() + interval '1 day');
update public.feature_flags set enabled = true where key = 'fitness.enabled';

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;

create function t.ex(p_slug text) returns uuid language sql security definer as $$
  select id from public.exercises where slug = p_slug;
$$;
grant execute on function t.ex(text) to authenticated;

create function t.who(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end;
$$;
grant execute on function t.who(uuid) to authenticated, service_role;

create function t.back() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end;
$$;
grant execute on function t.back() to authenticated;

create function t.program(p_exercise text default 'back-squat', p_id uuid default null) returns jsonb
language sql as $$
  select jsonb_build_object('id', p_id, 'name', 'My legs', 'days', jsonb_build_array(jsonb_build_object(
    'name', 'Day 1', 'items', jsonb_build_array(jsonb_build_object('exercise_id', t.ex(p_exercise), 'sets', 4,
      'reps', 5, 'seconds', 20, 'weight_g', 70000, 'rest_seconds', 120)))));
$$;
grant execute on function t.program(text, uuid) to authenticated;

create function t.workout(p_exercise text default 'back-squat', p_when timestamptz default now() - interval '1 hour')
returns jsonb language sql as $$
  select jsonb_build_object('name', 'Legs', 'started_at', p_when, 'ended_at', p_when + interval '45 minutes',
    'sets', jsonb_build_array(
      jsonb_build_object('exercise_id', t.ex(p_exercise), 'reps', 5, 'weight_g', 70000),
      jsonb_build_object('exercise_id', t.ex(p_exercise), 'reps', 5, 'weight_g', 72500)));
$$;
grant execute on function t.workout(text, timestamptz) to authenticated;

-- ─── The catalogue ─────────────────────────────────────────────────────────

select ok((select count(*) from public.exercises where status = 'live') >= 40, 'the starter list has about 40 exercises');
select is((select count(*)::int from public.programs where owner_id is null and name in
  ('Court speed', 'Mobility and balance', 'Off-season strength')), 3, 'three templates exist');
select is_empty($$ select name from public.programs where owner_id is null and name ilike '%injury%' $$,
  'no template promises injury prevention');
select is_empty($$ select slug from public.exercises where minors_ok
  and equipment not in ('Bodyweight', 'Band', 'Bench or box') $$,
  'only bodyweight and band work is cleared for under-18s');
select is_empty($$ select slug from public.exercises where
  (name || tip || safety || array_to_string(steps, ' ')) ~* 'calorie|injur|rehab|cure|heal|medical|\mburn|\mfat\M|prevent|therap' $$,
  'no calorie or medical claims in the catalogue');
select is_empty($$ select p.name from public.programs p left join public.program_days d on d.program_id = p.id
  where p.owner_id is null and (p.name || coalesce(d.name, '')) ~* 'calorie|injur|rehab|cure|heal|medical|\mburn|\mfat\M|prevent|therap' $$,
  'or in the templates');
select is_empty($$ select e.slug from public.exercises e where e.minors_ok and e.weighted $$,
  'nothing with a load is cleared for under-18s');

-- ─── Signed out ────────────────────────────────────────────────────────────

set local role anon;
select throws_ok($$ select public.exercise_list() $$, '42501', null, 'signed out: no exercises');
select throws_ok($$ select public.workout_summary(30) $$, '42501', null, 'signed out: no log');
select throws_ok($$ select public.program_list() $$, '42501', null, 'signed out: no programs');
select throws_ok($$ select public.program_save('{}') $$, '42501', null, 'signed out: can''t save a program');
select throws_ok($$ select public.program_delete(gen_random_uuid()) $$, '42501', null, 'or delete one');
select throws_ok($$ select public.workout_save('anon-key', '{}') $$, '42501', null, 'signed out: can''t log');
select throws_ok($$ select public.workout_delete(gen_random_uuid()) $$, '42501', null, 'or delete');
select throws_ok($$ select public.exercise_history(gen_random_uuid()) $$, '42501', null, 'signed out: no history');
select throws_ok($$ select * from public.exercises $$, '42501', null, 'signed out: no table access');
reset role;

-- ─── Tables have no client access ──────────────────────────────────────────

select t.who('e1000000-0000-0000-0000-000000000001');
select throws_ok($$ select * from public.workouts $$, '42501', null, 'a player can''t read workouts directly');
select throws_ok($$ select * from public.workout_sets $$, '42501', null, 'or workout sets');
select throws_ok($$ select * from public.programs $$, '42501', null, 'or programs');
select throws_ok($$ select * from public.exercises $$, '42501', null, 'or exercises');
select throws_ok($$ insert into public.workouts (user_id, client_key, name, started_at, ended_at)
  values (auth.uid(), 'k1234567', 'x', now(), now()) $$, '42501', null, 'or write them');
select throws_ok($$ select * from public.program_items $$, '42501', null, 'or program items');
select throws_ok($$ select * from public.program_days $$, '42501', null, 'or program days');
select throws_ok($$ select private.fitness_gate() $$, '42501', null, 'or call the helpers');
select throws_ok($$ select private.fitness_tz(auth.uid()) $$, '42501', null, 'any of them');

-- ─── Flag off ──────────────────────────────────────────────────────────────

select t.back();
update public.feature_flags set enabled = false where key = 'fitness.enabled';
select t.who('e1000000-0000-0000-0000-000000000001');
select throws_ok($$ select public.exercise_list() $$, 'P0001', 'Workouts are not open yet.', 'flag off: closed');
select throws_ok($$ select public.workout_save('flagoff-1', t.workout()) $$, 'P0001',
  'Workouts are not open yet.', 'flag off: can''t save');
select t.back();
update public.feature_flags set enabled = true where key = 'fitness.enabled';

-- ─── Adult ─────────────────────────────────────────────────────────────────

select t.who('e1000000-0000-0000-0000-000000000001');
select ok(jsonb_array_length(public.exercise_list()) >= 40, 'an adult sees the whole list');
select ok((select bool_or(x ->> 'name' = 'Off-season strength') from jsonb_array_elements(public.program_list()) x),
  'an adult sees the strength template');
select t.back();
insert into ids values ('p1', gen_random_uuid());
select t.who('e1000000-0000-0000-0000-000000000001');
select is(public.program_save(t.program('back-squat', t.id('p1'))), t.id('p1'), 'an adult saves a program');
select is(public.program_save(t.program('back-squat', t.id('p1'))), t.id('p1'), 'a retry saves the same one');
select is((select count(*)::int from jsonb_array_elements(public.program_list()) x
  where x ->> 'id' = t.id('p1')::text), 1, 'once');
select is((select x #>> '{days,0,items,0,weight_g}' from jsonb_array_elements(public.program_list()) x
  where x ->> 'id' = t.id('p1')::text), '70000', 'weight comes back in whole grams');
select is((select x #>> '{days,0,items,0,seconds}' from jsonb_array_elements(public.program_list()) x
  where x ->> 'id' = t.id('p1')::text), null, 'a reps exercise stores no seconds');

select lives_ok($$ select public.workout_save('adult-key-1', t.workout()) $$, 'an adult logs a workout');
select is(public.workout_save('adult-key-1', t.workout()), public.workout_save('adult-key-1', t.workout()),
  'a retry returns the same workout');
select is((public.workout_summary(30) ->> 'workouts')::int, 1, 'and logs once');
select is((public.workout_summary(30) ->> 'lifted_g')::bigint, 712500::bigint, 'weight × reps is summed');
select is((public.exercise_history(t.ex('back-squat')) ->> 'times')::int, 1, 'history counts the workout once');
select is(public.exercise_history(t.ex('back-squat')) #>> '{best,weight_g}', '72500', 'best set is the heaviest');
select is((public.workout_summary(null) -> 'bests' -> 0 ->> 'exercise'), 'Back squat', 'personal bests list it');

select throws_ok($$ select public.program_save(jsonb_build_object('name', 'x', 'days', '[]'::jsonb)) $$, 'P0001',
  'Give the program a name.', 'a program needs a name');
select throws_ok($$ select public.program_save(jsonb_build_object('name', 'Empty', 'days',
  '[{"name": "D", "items": []}]'::jsonb)) $$, 'P0001', 'Add an exercise first.', 'and an exercise');
select throws_ok($$ select public.program_save(jsonb_set(t.program(), '{days,0,items,0,sets}', '99')) $$, 'P0001',
  'Check the sets, reps, weight and rest.', 'silly sets are refused');
select throws_ok($$ select public.program_save(jsonb_set(t.program(), '{days,0,items,0,weight_g}', '1.5')) $$, 'P0001',
  'Check the sets, reps, weight and rest.', 'grams are whole numbers');
select throws_ok($$ select public.program_save(jsonb_set(t.program(), '{days,0,items,0,exercise_id}',
  '"not-a-uuid"')) $$, 'P0001', 'That exercise is not available.', 'a bad exercise id is refused');
select throws_ok($$ select public.workout_save('adult-key-2', t.workout() || '{"sets": []}') $$, 'P0001',
  'Finish a set first.', 'an empty workout is refused');
select throws_ok($$ select public.workout_save('adult-key-3', jsonb_set(t.workout(), '{sets,0,reps}', '9999')) $$,
  'P0001', 'Check the reps, time and weight.', 'silly reps are refused');
select throws_ok($$ select public.workout_save('adult-key-4',
  t.workout('back-squat', now() + interval '1 day')) $$, 'P0001', 'Check the workout''s start and finish.',
  'a workout can''t finish in the future');
select throws_ok($$ select public.workout_save('adult-key-6', jsonb_set(t.workout(), '{sets,0,weight_g}', '1.5')) $$,
  'P0001', 'Check the reps, time and weight.', 'grams are whole numbers in a workout too');
select throws_ok($$ select public.workout_save('adult-key-7', t.workout() || jsonb_build_object(
  'started_at', '-infinity', 'ended_at', '-infinity')) $$, 'P0001', 'Check the workout''s start and finish.',
  'endless dates are refused');
select throws_ok($$ select public.workout_save('adult-key-8', t.workout() || jsonb_build_object(
  'ended_at', now() - interval '1 hour', 'started_at', now() - interval '14 hours')) $$, 'P0001',
  'Check the workout''s start and finish.', 'a workout over 12 hours is refused');
select is((public.workout_summary(30) ->> 'workouts')::int, 1, 'a refused workout leaves nothing behind');
select lives_ok($$ select public.workout_summary(2147483647) $$, 'a huge range is held to ten years');

-- A timed exercise.
select lives_ok($$ select public.workout_save('adult-key-5', jsonb_build_object('name', 'Core',
  'started_at', now() - interval '2 hours', 'ended_at', now() - interval '1 hour',
  'sets', jsonb_build_array(jsonb_build_object('exercise_id', t.ex('plank'), 'seconds', 45, 'reps', 3)))) $$,
  'a timed set logs seconds');
select is(public.exercise_history(t.ex('plank')) #>> '{best,seconds}', '45', 'and shows them');
select is(public.exercise_history(t.ex('plank')) #>> '{best,reps}', null, 'with no reps');

-- ─── Streak ────────────────────────────────────────────────────────────────

select t.who('e1000000-0000-0000-0000-000000000002');
select is((public.workout_summary(30) ->> 'week_streak')::int, 0, 'no workouts, no streak');
select public.workout_save('streak-1', t.workout('push-up', now() - interval '1 hour')) is not null;
select is((public.workout_summary(30) ->> 'week_streak')::int, 1, 'one this week is a streak of 1');

-- Two players can use the same key.
select t.who('e1000000-0000-0000-0000-000000000001');
select is((public.workout_summary(null) ->> 'workouts')::int, 2, 'the first adult has their two workouts');
select t.who('e1000000-0000-0000-0000-000000000002');
select ok(public.workout_save('adult-key-1', t.workout('push-up')) is not null, 'the same key works for someone else');
select is((public.workout_summary(null) ->> 'workouts')::int, 2, 'as their own workout');
select t.back();

-- ─── The streak over several weeks ─────────────────────────────────────────

select t.player('e1000000-0000-0000-0000-000000000009');
create function t.weeks_ago(p_user uuid, p_weeks int) returns void language sql as $$
  insert into public.workouts (user_id, client_key, name, started_at, ended_at)
  values (p_user, 'weeks-ago-' || p_weeks, 'Old', now() - make_interval(weeks => p_weeks),
    now() - make_interval(weeks => p_weeks) + interval '1 hour');
$$;
select t.weeks_ago('e1000000-0000-0000-0000-000000000009', 1);
select t.who('e1000000-0000-0000-0000-000000000009');
select is((public.workout_summary(30) ->> 'week_streak')::int, 1, 'last week still counts until this week ends');
select t.back();
select t.weeks_ago('e1000000-0000-0000-0000-000000000009', 2);
select t.weeks_ago('e1000000-0000-0000-0000-000000000009', 4);
select t.who('e1000000-0000-0000-0000-000000000009');
select is((public.workout_summary(30) ->> 'week_streak')::int, 2, 'a missed week ends the streak');
select t.back();
delete from public.workouts where user_id = 'e1000000-0000-0000-0000-000000000009'
  and client_key in ('weeks-ago-1', 'weeks-ago-2');
select t.who('e1000000-0000-0000-0000-000000000009');
select is((public.workout_summary(30) ->> 'week_streak')::int, 0, 'an old week alone is no streak');
select t.back();

-- ─── The daily limit ───────────────────────────────────────────────────────

delete from public.workouts where user_id = 'e1000000-0000-0000-0000-000000000009';
update public.app_settings set value = '2' where key = 'fitness.daily_workouts';
select t.who('e1000000-0000-0000-0000-000000000009');
select lives_ok($$ select public.workout_save('daily-key-1', t.workout('push-up')) $$, 'one today');
select lives_ok($$ select public.workout_save('daily-key-2', t.workout('push-up')) $$, 'two today');
select throws_ok($$ select public.workout_save('daily-key-3', t.workout('push-up')) $$, 'P0001',
  'That''s a lot of workouts for one day. Try again tomorrow.', 'the daily limit holds');
select lives_ok($$ select public.workout_save('daily-key-2', t.workout('push-up')) $$, 'a retry of a saved one still works');
select t.back();
update public.workouts set created_at = now() - interval '23 hours'
where user_id = 'e1000000-0000-0000-0000-000000000009' and client_key = 'daily-key-1';
select t.who('e1000000-0000-0000-0000-000000000009');
select throws_ok($$ select public.workout_save('daily-key-5', t.workout('push-up')) $$, 'P0001',
  'That''s a lot of workouts for one day. Try again tomorrow.', 'a workout 23 hours ago still counts');
select t.back();
update public.workouts set created_at = now() - interval '25 hours'
where user_id = 'e1000000-0000-0000-0000-000000000009' and client_key = 'daily-key-1';
select t.who('e1000000-0000-0000-0000-000000000009');
select lives_ok($$ select public.workout_save('daily-key-4', t.workout('push-up')) $$, 'the limit covers the last 24 hours');
select t.back();
update public.app_settings set value = '20' where key = 'fitness.daily_workouts';

-- ─── An exercise taken off the list ────────────────────────────────────────

update public.exercises set status = 'draft' where slug in ('plank', 'bird-dog');
select t.who('e1000000-0000-0000-0000-000000000009');
select ok((select not bool_or(x ->> 'name' = 'Plank') from jsonb_array_elements(public.exercise_list()) x),
  'a draft exercise isn''t listed');
select throws_ok($$ select public.program_save(t.program('plank')) $$, 'P0001', 'That exercise is not available.',
  'or saved into a program');
select ok((select not bool_or(i ->> 'exercise' = 'Plank') from jsonb_array_elements(public.program_list()) x,
    jsonb_array_elements(x -> 'days') d, jsonb_array_elements(d -> 'items') i), 'or shown in a template');
select lives_ok($$ select public.workout_save('draft-key-1', jsonb_build_object('name', 'Core',
  'started_at', now() - interval '2 hours', 'ended_at', now() - interval '1 hour',
  'sets', jsonb_build_array(jsonb_build_object('exercise_id', t.ex('plank'), 'seconds', 45)))) $$,
  'but a workout already under way can still save');
select t.back();
update public.exercises set status = 'live' where slug in ('plank', 'bird-dog');

-- ─── Another player, parent, staff, blocked ────────────────────────────────

-- The second adult has blocked the first. Neither sees the other's log either way.
select t.who('e1000000-0000-0000-0000-000000000002');
select ok(not (public.workout_summary(null)::text like '%Back squat%'), 'another adult sees none of the first adult''s log');
select is(public.exercise_history(t.ex('back-squat')) ->> 'times', '0', 'or their history');
select ok((select not bool_or(x ->> 'id' = t.id('p1')::text) from jsonb_array_elements(public.program_list()) x),
  'or their programs');
select throws_ok(format($$ select public.program_save(t.program('plank', %L)) $$, t.id('p1')), 'P0001',
  'Program not found.', 'and can''t overwrite one');
select lives_ok(format($$ select public.program_delete(%L) $$, t.id('p1')), 'deleting someone else''s does nothing');
select t.who('e1000000-0000-0000-0000-000000000001');
select ok((select bool_or(x ->> 'id' = t.id('p1')::text) from jsonb_array_elements(public.program_list()) x),
  'the program is still there');
select t.back();

insert into ids select 'template', id from public.programs where owner_id is null and name = 'Court speed';
select t.who('e1000000-0000-0000-0000-000000000001');
select throws_ok(format($$ select public.program_save(t.program('plank', %L)) $$, t.id('template')), 'P0001',
  'Program not found.', 'a player can''t change a template');
select lives_ok(format($$ select public.program_delete(%L) $$, t.id('template')), 'or delete one');
select t.back();
select is((select count(*)::int from public.programs where id = t.id('template') and owner_id is null), 1, 'it stays');

select t.who('e1000000-0000-0000-0000-000000000004');
select ok(not (public.workout_summary(null)::text like '%Back squat%'), 'a parent sees no one else''s log');
select t.who('e1000000-0000-0000-0000-000000000007');
select ok(not (public.workout_summary(null)::text like '%Back squat%'), 'staff see no one else''s log');
select throws_ok($$ select * from public.workouts $$, '42501', null, 'and no table access');
select t.back();

-- ─── Minors ────────────────────────────────────────────────────────────────

select t.who('e1000000-0000-0000-0000-000000000003');
select ok((select bool_and((x ->> 'equipment') in ('Bodyweight', 'Band', 'Bench or box'))
  from jsonb_array_elements(public.exercise_list()) x), 'a teen sees bodyweight and band work only');
select ok(jsonb_array_length(public.exercise_list()) < 40, 'a shorter list');
select ok((select bool_or(x ->> 'name' = 'Court speed') from jsonb_array_elements(public.program_list()) x),
  'a teen sees the templates that suit them');
select ok((select not bool_or(x ->> 'name' = 'Off-season strength') from jsonb_array_elements(public.program_list()) x),
  'but not the strength template');
select throws_ok($$ select public.program_save(t.program('back-squat')) $$, 'P0001',
  'That exercise is not available.', 'a teen can''t save an adults-only exercise');
select throws_ok($$ select public.workout_save('teen-key-1', t.workout('back-squat')) $$, 'P0001',
  'That exercise is not available.', 'or log one');
select lives_ok($$ select public.program_save(t.program('push-up')) $$, 'a teen can save a suitable program');
select lives_ok($$ select public.workout_save('teen-key-2', t.workout('push-up')) $$, 'and log it');

-- Teen logs stay private from their parent.
select t.who('e1000000-0000-0000-0000-000000000004');
select is((public.workout_summary(null) ->> 'workouts')::int, 0, 'a parent can''t see their child''s log');
select t.back();

-- A program made as an adult shows only what a minor can do, and the log stays.
insert into public.workouts (user_id, client_key, name, started_at, ended_at)
values ('e1000000-0000-0000-0000-000000000003', 'older-key', 'Older', now() - interval '3 days',
  now() - interval '3 days' + interval '30 minutes');
insert into public.workout_sets (workout_id, exercise_id, position, reps, weight_g)
select id, t.ex('back-squat'), 1, 5, 40000 from public.workouts where client_key = 'older-key';
insert into public.programs (id, owner_id, name) values
  ('e1000000-0000-0000-0000-00000000aaaa', 'e1000000-0000-0000-0000-000000000003', 'Older');
with d as (insert into public.program_days (program_id, position, name)
  values ('e1000000-0000-0000-0000-00000000aaaa', 1, 'One') returning id)
insert into public.program_items (day_id, exercise_id, position, sets, reps)
select d.id, t.ex('back-squat'), 1, 3, 5 from d union all select d.id, t.ex('push-up'), 2, 3, 5 from d;
select t.who('e1000000-0000-0000-0000-000000000003');
select is((select jsonb_array_length(x #> '{days,0,items}') from jsonb_array_elements(public.program_list()) x
  where x ->> 'name' = 'Older'), 1, 'an item a minor can''t do is left out of their program');
select is(public.exercise_history(t.ex('back-squat')) ->> 'times', '1', 'what they logged is kept');
select t.back();

-- ─── Restricted and suspended ──────────────────────────────────────────────

select t.who('e1000000-0000-0000-0000-000000000005');
select throws_ok($$ select public.exercise_list() $$, 'P0001', 'Ask a parent to link your account first.',
  'a restricted child is refused');
select throws_ok($$ select public.workout_save('rest-key-1', t.workout('push-up')) $$, 'P0001',
  'Ask a parent to link your account first.', 'and can''t save');
select t.back();

-- The same through the API gate.
select set_config('request.path', '/rpc/exercise_list', true);
select set_config('request.method', 'POST', true);
select set_config('request.jwt.claims', '{"sub": "e1000000-0000-0000-0000-000000000005"}', true);
select throws_ok($$ select private.gate_request() $$, 'P0001', 'Ask a parent to link your account first.',
  'the API gate refuses them too');
select set_config('request.jwt.claims', '{"sub": "e1000000-0000-0000-0000-000000000006"}', true);
select throws_ok($$ select private.gate_request() $$, 'P0001', 'Your account is suspended.',
  'and a suspended player');
select set_config('request.path', '', true);
select set_config('request.jwt.claims', '', true);

select t.who('e1000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.exercise_list() $$, 'P0001', 'Your account is suspended.',
  'a suspended player is refused');
select throws_ok($$ select public.workout_save('susp-key-1', t.workout()) $$, 'P0001',
  'Your account is suspended.', 'and can''t save');
select t.back();

-- ─── Deleting ──────────────────────────────────────────────────────────────

select t.who('e1000000-0000-0000-0000-000000000002');
select is((public.workout_summary(null) ->> 'workouts')::int, 2, 'the second adult has two workouts');
select t.back();
insert into ids select 'w2', id from public.workouts
where user_id = 'e1000000-0000-0000-0000-000000000002' and client_key = 'streak-1';
select t.who('e1000000-0000-0000-0000-000000000001');
select lives_ok(format($$ select public.workout_delete(%L) $$, t.id('w2')), 'deleting someone else''s does nothing');
select t.who('e1000000-0000-0000-0000-000000000002');
select is((public.workout_summary(null) ->> 'workouts')::int, 2, 'it stays');
select lives_ok(format($$ select public.workout_delete(%L) $$, t.id('w2')), 'the owner deletes it');
select is((public.workout_summary(null) ->> 'workouts')::int, 1, 'and it''s gone');
select t.back();
select is((select count(*)::int from public.workout_sets where workout_id = t.id('w2')), 0, 'with its sets');

insert into ids select 'p1w', w.id from public.workouts w
where w.user_id = 'e1000000-0000-0000-0000-000000000001' and w.client_key = 'adult-key-1';
update public.workouts set program_id = t.id('p1') where id = t.id('p1w');
select t.who('e1000000-0000-0000-0000-000000000001');
select lives_ok(format($$ select public.program_delete(%L) $$, t.id('p1')), 'a player deletes their program');
select t.back();
select is((select program_id from public.workouts where id = t.id('p1w')), null, 'the log stays, unlinked');

delete from auth.users where id = 'e1000000-0000-0000-0000-000000000001';
select is((select count(*)::int from public.workouts where user_id = 'e1000000-0000-0000-0000-000000000001'), 0,
  'deleting an account deletes the log');
select is((select count(*)::int from public.programs where owner_id = 'e1000000-0000-0000-0000-000000000001'), 0,
  'and the programs');

-- ─── Nothing here earns anything ───────────────────────────────────────────

create function t.earned() returns bigint language plpgsql as $$
declare
  v_table text;
  v_n bigint;
  v_total bigint := 0;
begin
  for v_table in select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
      and c.relname ~ '(point|rating|ledger|badge|voucher|reward|challenge|quest|campaign|organizer)'
  loop
    execute format('select count(*) from public.%I', v_table) into v_n;
    v_total := v_total + v_n;
  end loop;
  return v_total;
end;
$$;

select t.player('e1000000-0000-0000-0000-000000000008');
create temp table earned_before on commit drop as select t.earned() as n;
select t.who('e1000000-0000-0000-0000-000000000008');
select lives_ok($$ select public.workout_save('earn-key-1', t.workout()) $$, 'a workout saves');
select lives_ok($$ select public.program_save(t.program()) $$, 'and a program');
select t.back();
select is(t.earned(), (select n from earned_before), 'saving a workout moves no points, voucher, badge or rating');
select is_empty($$ select t.tgname from pg_trigger t join pg_class c on c.oid = t.tgrelid
  where c.relname in ('workouts', 'workout_sets') and not t.tgisinternal $$,
  'nothing fires when a workout is saved');

select * from finish();
rollback;
