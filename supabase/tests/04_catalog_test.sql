begin;
\ir helpers/setup.psql
select plan(12);

select t.player('40000000-0000-0000-0000-000000000001');

select is((select status from public.sports where key = 'badminton'), 'live', 'badminton is live');
select is((select status from public.sports where key = 'pickleball'), 'live', 'pickleball is live');
select is((select status from public.sports where key = 'tennis'), 'draft', 'tennis is a draft');

select lives_ok($$select t.meet('40000000-0000-0000-0000-000000000001')$$, 'a Meet in a live sport is allowed');
select throws_ok(
  $$select t.meet('40000000-0000-0000-0000-000000000001', p_sport => 'tennis')$$,
  'P0001', 'That sport isn''t open for new Meets.', 'a Meet in a draft sport is refused');

update public.sport_formats set status = 'maintenance' where sport_key = 'badminton' and key = 'mixed';
select throws_ok(
  $$select t.meet('40000000-0000-0000-0000-000000000001', p_game => 'mixed')$$,
  'P0001', 'That format isn''t open for new Meets.', 'a format in maintenance takes no new Meets');
update public.sport_formats set status = 'live' where sport_key = 'badminton' and key = 'mixed';

-- Each Meet keeps its own copy of the rules.
create temp table m on commit drop as
  select t.meet('40000000-0000-0000-0000-000000000001') as id;
select is((select (scoring_snapshot ->> 'points_to_win')::int from public.activities, m where activities.id = m.id),
  21, 'the Meet copies its scoring rules');
update public.sport_formats set scoring = scoring || '{"points_to_win": 15}'
  where sport_key = 'badminton' and key = 'doubles';
select is((select (scoring_snapshot ->> 'points_to_win')::int from public.activities, m where activities.id = m.id),
  21, 'changing a format leaves existing Meets alone');

select ok((select count(*) > 0 from public.catalog_audit where table_name = 'sport_formats' and action = 'update'),
  'catalogue changes are in catalog_audit');
select throws_ok($$delete from public.catalog_audit$$, 'P0001', 'catalog_audit is append-only', 'the audit cannot be deleted');
select throws_ok($$update public.catalog_audit set action = 'x'$$, 'P0001', 'catalog_audit is append-only', 'the audit cannot be edited');

select t.as_user('40000000-0000-0000-0000-000000000001');
select is_empty($$select 1 from public.sports where status = 'draft'$$, 'players do not see drafts');
select t.reset();

select * from finish();
rollback;
