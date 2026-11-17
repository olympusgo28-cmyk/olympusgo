begin;
\ir helpers/setup.psql
select no_plan();

select t.player('ad000000-0000-0000-0000-000000000001');
select t.player('ad000000-0000-0000-0000-000000000002');
select t.player('ad000000-0000-0000-0000-000000000003', 14);
update public.profiles set full_name = 'Mei Lim' where id = 'ad000000-0000-0000-0000-000000000003';

create temp table mine on commit drop as select t.meet('ad000000-0000-0000-0000-000000000001') as id;
create temp table theirs on commit drop as select t.meet('ad000000-0000-0000-0000-000000000002', p_hours => 72) as id;
grant select on mine, theirs to authenticated;
update public.activities set series_id = 'ad000000-0000-0000-0000-0000000000aa' where id = (select id from theirs);

-- Series belong to their host.
select t.as_user('ad000000-0000-0000-0000-000000000001');
update public.activities set series_id = 'ad000000-0000-0000-0000-0000000000aa' where id = (select id from mine);
select t.reset();
select is((select series_id from public.activities where id = (select id from mine)), null, 'a series id can''t be copied on');

update public.activities set series_id = 'ad000000-0000-0000-0000-0000000000aa' where id = (select id from mine);
select t.as_user('ad000000-0000-0000-0000-000000000001');
select public.cancel_activity((select id from mine), true, null);
select t.reset();
select is((select status from public.activities where id = (select id from theirs)), 'published', 'a series cancel stays on the host''s own Meets');

-- Once scores are in, the Meet holds still.
create temp table r on commit drop as select t.meet('ad000000-0000-0000-0000-000000000001', p_game => 'singles') as id;
grant select on r to authenticated;
update public.activities set ranked = true, starts_at = now() - interval '1 hour', ends_at = now() + interval '1 hour' where id = (select id from r);
insert into public.match_scores (activity_id, entered_by, side_a, side_b, games) values ((select id from r),
  'ad000000-0000-0000-0000-000000000001', '{ad000000-0000-0000-0000-000000000001}', '{ad000000-0000-0000-0000-000000000002}', '[[21,10],[21,12]]');
select t.as_user('ad000000-0000-0000-0000-000000000001');
update public.activities set sports = '{pickleball}', game_type = 'doubles', ends_at = now() + interval '3 days' where id = (select id from r);
select throws_ok(format('select public.cancel_activity(%L, false, null)', (select id from r)),
  'P0001', 'This has scores, so it can''t be cancelled. Ask the OlympusGO team.', 'a started Meet with scores can''t be cancelled');
select t.reset();
select is((select sports from public.activities where id = (select id from r)), '{badminton}'::text[], 'the sport stays once scores are in');
select is((select game_type from public.activities where id = (select id from r)), 'singles', 'and the game');
select cmp_ok((select ends_at from public.activities where id = (select id from r)), '<', now() + interval '2 days', 'a started Meet keeps its end');

-- player_json hides a minor's id. Clients only reach it through other functions.
create function t.pj(p uuid) returns text language sql security definer as $$ select public.player_json(p)::text; $$;
grant execute on function t.pj(uuid) to authenticated;
select t.as_user('ad000000-0000-0000-0000-000000000001');
select ok(t.pj('ad000000-0000-0000-0000-000000000003') not like '%ad000000-0000-0000-0000-000000000003%', 'player_json hides a minor''s real id');
select ok(t.pj('ad000000-0000-0000-0000-000000000002') like '%ad000000-0000-0000-0000-000000000002%', 'and shows an adult''s');
select t.reset();

select * from finish();
rollback;
