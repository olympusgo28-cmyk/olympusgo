-- P4c-02: who can read and write an assessment, and that a level is not a rating.
begin;
\ir helpers/setup.psql
\ir helpers/academy.psql
select no_plan();

select t.player('c3000000-0000-0000-0000-000000000001');  -- head coach
select t.player('c3000000-0000-0000-0000-000000000002');  -- assigning coach
select t.player('c3000000-0000-0000-0000-000000000003');  -- another coach
select t.player('c3000000-0000-0000-0000-000000000004');  -- parent
select t.player('c3000000-0000-0000-0000-000000000005', 12);  -- child
select t.player('c3000000-0000-0000-0000-000000000006');  -- outsider
select t.player('c3000000-0000-0000-0000-000000000007');  -- adult student
select t.player('c3000000-0000-0000-0000-000000000008');  -- adult student's relative
select t.player('c3000000-0000-0000-0000-000000000009');  -- invited, no licence

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;

insert into ids select 'academy', t.academy('c3000000-0000-0000-0000-000000000001');
select t.coach(t.id('academy'), 'c3000000-0000-0000-0000-000000000002');
select t.coach(t.id('academy'), 'c3000000-0000-0000-0000-000000000003');
insert into public.academy_coaches (academy_id, user_id, accepted_at)
values (t.id('academy'), 'c3000000-0000-0000-0000-000000000009', now());
insert into ids select 'class', t.class(t.id('academy'), 'c3000000-0000-0000-0000-000000000002');
insert into ids select 'link', t.link('c3000000-0000-0000-0000-000000000004', 'c3000000-0000-0000-0000-000000000005');
insert into ids select 'child', t.student(t.id('class'), 'c3000000-0000-0000-0000-000000000004', 'c3000000-0000-0000-0000-000000000005');
insert into ids select 'adult', t.student(t.id('class'), 'c3000000-0000-0000-0000-000000000007', 'c3000000-0000-0000-0000-000000000007');
insert into ids select 'typed', t.student(t.id('class'), 'c3000000-0000-0000-0000-000000000004', null);

-- ─── Templates ─────────────────────────────────────────────────────────────

select t.as_user('c3000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.assessment_template_save(t.id('academy'), '{"name": "Skills", "criteria": ["Footwork"]}') $$,
  'Only the head coach can do this.', 'only the head coach makes templates');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000001');
select throws_ok($$ select public.assessment_template_save(t.id('academy'), '{"name": "Skills", "criteria": []}') $$, 'Add 1 to 20 things to assess.', 'a template needs lines');
select throws_ok($$ select public.assessment_template_save(t.id('academy'), '{"name": "Skills", "criteria": ["Serve", "serve"]}') $$, 'Each thing you assess needs its own name.', 'each its own');
select throws_ok($$ select public.assessment_template_save(t.id('academy'), '{"name": "Skills", "scale_max": 11, "criteria": ["Serve"]}') $$, 'Score out of 2 to 10.', 'scores stay in range');
insert into ids select 'template', public.assessment_template_save(t.id('academy'), '{"name": "Term skills", "scale_max": 5, "criteria": ["Footwork", "Serve"]}');
select t.reset();

create function t.crit(p_label text) returns uuid language sql security definer as $$
  select id from public.assessment_criteria where label = p_label and template_id = t.id('template');
$$;
create function t.scores(a int, b int) returns jsonb language sql as $$
  select jsonb_build_object(t.crit('Footwork'), a, t.crit('Serve'), b);
$$;
create function t.assess(p_student uuid, a int, b int, p_on date default null) returns jsonb language sql as $$
  select jsonb_build_object('student_id', p_student, 'template_id', t.id('template'), 'level', 2, 'note', 'Good week',
    'assessed_on', p_on, 'scores', t.scores(a, b));
$$;
grant execute on all functions in schema t to anon, authenticated, service_role;

-- ─── Writing ───────────────────────────────────────────────────────────────

select t.as_user('c3000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.assessment_save(t.assess(t.id('child'), 3, 3)) $$, 'Only the academy''s coaches can do this.', 'an outsider can''t assess');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000004');
select throws_ok($$ select public.assessment_save(t.assess(t.id('child'), 5, 5)) $$, 'Only the academy''s coaches can do this.', 'nor a parent');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000005');
select throws_ok($$ select public.assessment_save(t.assess(t.id('child'), 5, 5)) $$, 'Only the academy''s coaches can do this.', 'nor the player');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000009');
select throws_ok($$ select public.assessment_save(t.assess(t.id('child'), 3, 3)) $$, 'We need to verify your coaching licence first.', 'nor an unlicensed coach');
select t.reset();

select t.as_user('c3000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.assessment_save(t.assess(t.id('typed'), 3, 3)) $$, 'Ask them to enrol from their own account first.', 'a typed name can''t be assessed');
select throws_ok($$ select public.assessment_save(jsonb_build_object('student_id', t.id('child'), 'template_id', t.id('template'),
  'scores', jsonb_build_object(t.crit('Serve'), 3))) $$, 'Score every line.', 'every line is scored');
select throws_ok($$ select public.assessment_save(t.assess(t.id('child'), 6, 3)) $$, 'Scores run from 0 to 5.', 'within the scale');
select throws_ok($$ select public.assessment_save(t.assess(t.id('child'), 3, 3, current_date + 2)) $$, 'Pick today or an earlier day.', 'and never in the future');
insert into ids select 'first', public.assessment_save(t.assess(t.id('child'), 2, 3, current_date - 30));
insert into ids select 'second', public.assessment_save(t.assess(t.id('child'), 4, 4, current_date - 1));
insert into ids select 'adult_one', public.assessment_save(t.assess(t.id('adult'), 3, 3, current_date - 1));
select throws_ok($$ select public.assessment_save(t.assess(t.id('child'), 1, 1, current_date - 1)) $$, 'This student already has that assessment for this day.', 'one a day per template');
select t.reset();

select is((select count(*) from public.notifications where user_id = 'c3000000-0000-0000-0000-000000000004'), 2::bigint, 'the parent hears about each one');
select ok(not exists (select 1 from public.notifications where user_id = 'c3000000-0000-0000-0000-000000000004'
  and (title like '%4%' or body like '%Good week%')), 'and no score or note is in the notification');

-- ─── Nobody else writes, even directly ─────────────────────────────────────

select t.as_user('c3000000-0000-0000-0000-000000000002');
select throws_ok($$ update public.assessments set note = 'x' where id = t.id('first') $$, '42501', null, 'not even its coach writes the table');
select throws_ok($$ insert into public.assessment_scores (assessment_id, criterion_id, label, position, score, max_score)
  values (t.id('first'), gen_random_uuid(), 'x', 9, 1, 5) $$, '42501', null, 'or adds a score');
select throws_ok($$ delete from public.assessments where id = t.id('first') $$, '42501', null, 'or deletes one');
select t.reset();
select t.as_anon();
select throws_ok($$ select * from public.assessments $$, '42501', null, 'signed out reads nothing');
select throws_ok($$ select public.assessment_list('c3000000-0000-0000-0000-000000000005') $$, '42501', null, 'nor through a function');
select t.reset();

-- ─── Reading ───────────────────────────────────────────────────────────────

create function t.seen() returns bigint language sql as $$
  select count(*) from public.assessments where player_id = 'c3000000-0000-0000-0000-000000000005';
$$;
create function t.listed() returns bigint language sql as $$
  select count(*) from jsonb_array_elements(public.assessment_list('c3000000-0000-0000-0000-000000000005'));
$$;
create function t.scores_seen() returns bigint language sql as $$
  select count(*) from public.assessment_scores where assessment_id in (t.id('first'), t.id('second'));
$$;
grant execute on all functions in schema t to anon, authenticated, service_role;

select t.as_user('c3000000-0000-0000-0000-000000000005');
select is(t.seen(), 2::bigint, 'the player reads their own');
select is(t.listed(), 2::bigint, 'through the function too');
select is(t.scores_seen(), 4::bigint, 'with the scores');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000004');
select is(t.seen(), 2::bigint, 'a minor''s parent reads them');
select is(t.listed(), 2::bigint, 'through the function too');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000002');
select is(t.seen(), 2::bigint, 'the assigning coach reads them');
select is(t.listed(), 2::bigint, 'through the function too');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000003');
select is(t.seen(), 0::bigint, 'another coach reads nothing');
select is(t.listed(), 0::bigint, 'through the function either');
select is(t.scores_seen(), 0::bigint, 'and no scores');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000001');
select is(t.seen(), 0::bigint, 'nor the head coach who didn''t assign them');
select is(t.listed(), 0::bigint, 'through the function either');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000006');
select is(t.seen(), 0::bigint, 'nor an outsider');
select is(t.listed(), 0::bigint, 'through the function either');
select t.reset();

-- An adult's assessments are theirs alone.
select t.as_user('c3000000-0000-0000-0000-000000000008');
select is((select count(*) from public.assessments where id = t.id('adult_one')), 0::bigint, 'nobody else reads an adult''s');
select t.reset();

-- Older parents and leavers lose access.
update public.guardian_links set status = 'revoked' where id = t.id('link');
select t.as_user('c3000000-0000-0000-0000-000000000004');
select is(t.seen(), 0::bigint, 'a revoked link ends a parent''s access');
select t.reset();
update public.guardian_links set status = 'approved' where id = t.id('link');

-- ─── Correcting ────────────────────────────────────────────────────────────

select t.as_user('c3000000-0000-0000-0000-000000000003');
select throws_ok($$ select public.assessment_save(t.assess(null, 5, 5) || jsonb_build_object('id', t.id('first'))) $$,
  'Only the coach who wrote this can change it.', 'another coach can''t correct it');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000002');
select lives_ok($$ select public.assessment_save(t.assess(null, 3, 3, current_date - 30) || jsonb_build_object('id', t.id('first'))) $$, 'its coach can');
select is((select edited_at is not null from public.assessments where id = t.id('first')), true, 'and it shows as edited');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000005');
select is(public.assessment_list('c3000000-0000-0000-0000-000000000005') -> 0 ->> 'edited', 'true', 'the player sees that');
select is((public.assessment_list('c3000000-0000-0000-0000-000000000005') -> 0 -> 'scores' -> 0 ->> 'score')::int, 3, 'and the corrected score');
select is(public.assessment_list('c3000000-0000-0000-0000-000000000005') -> 0 ->> 'assessed_on', (current_date - 30)::text, 'oldest first, for the chart');
select t.reset();

-- Frozen once used, so a chart compares like with like.
select t.as_user('c3000000-0000-0000-0000-000000000001');
select throws_ok($$ select public.assessment_template_save(t.id('academy'), jsonb_build_object('id', t.id('template'), 'name', 'Term skills', 'scale_max', 5, 'criteria', '["Footwork", "Smash"]'::jsonb)) $$,
  'This template has been used. Make a new one to change what it scores.', 'a used template keeps its lines');
select lives_ok($$ select public.assessment_template_save(t.id('academy'), jsonb_build_object('id', t.id('template'), 'name', 'Renamed', 'scale_max', 5, 'criteria', '["Footwork", "Serve"]'::jsonb)) $$, 'and can be renamed');
select t.reset();

-- ─── A level is not a rating (R-RAT-6) ─────────────────────────────────────

select is_empty($$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname in ('public', 'private') and p.proname like 'assessment%'
    and (p.prosrc ilike '%rating%' or p.prosrc ilike '%leaderboard%' or p.prosrc ilike '%passport%') $$,
  'no assessment function touches a rating, leaderboard or Passport');
select is_empty($$ select tgname from pg_trigger t join pg_class c on c.oid = t.tgrelid
  where c.relname in ('assessments', 'assessment_scores') and not t.tgisinternal $$, 'and no trigger hangs off an assessment');

-- ─── Leaving ───────────────────────────────────────────────────────────────

delete from public.academy_coaches where user_id = 'c3000000-0000-0000-0000-000000000002';
select t.as_user('c3000000-0000-0000-0000-000000000002');
select is(t.seen(), 0::bigint, 'a coach who leaves loses access');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000001');
select public.academy_close(t.id('academy'));
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000004');
select is(t.seen(), 2::bigint, 'a closed academy''s assessments stay with the parent');
select t.reset();
select t.as_user('c3000000-0000-0000-0000-000000000005');
select is(t.listed(), 2::bigint, 'and the player');
select t.reset();
delete from public.academies where id = t.id('academy');
select t.as_user('c3000000-0000-0000-0000-000000000005');
select is(t.listed(), 2::bigint, 'even if the academy row goes');
select t.reset();

select * from finish();
rollback;
