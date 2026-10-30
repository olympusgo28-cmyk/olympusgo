begin;
\ir helpers/setup.psql
select plan(15);

select t.player('f0000000-0000-0000-0000-000000000001');      -- viewer
select t.player('f0000000-0000-0000-0000-000000000002');      -- host
select t.player('f0000000-0000-0000-0000-000000000003', 15);  -- teen
select t.player('f0000000-0000-0000-0000-000000000004');      -- blocked
select t.player('f0000000-0000-0000-0000-000000000005');      -- only me
insert into public.guardian_links (child_id, parent_id, status) values
  ('f0000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000002', 'approved');
update public.profiles set visibility = 'only_me' where id = 'f0000000-0000-0000-0000-000000000005';
insert into public.blocks (blocker_id, blocked_id)
  values ('f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000004');
insert into public.player_sports (user_id, sport, level, play_min, play_max)
select ('f0000000-0000-0000-0000-00000000000' || i)::uuid, 'badminton', 4, 3, 5 from generate_series(1, 5) i;

create temp table m on commit drop as select t.meet('f0000000-0000-0000-0000-000000000002') as id;
create temp table b on commit drop as select t.meet('f0000000-0000-0000-0000-000000000004') as id;
grant select on m, b to authenticated;

select t.as_user('f0000000-0000-0000-0000-000000000001');

-- Location.
select is(public.discover_sessions() -> 0 ->> 'km', null, 'with no area shared, no distance is shown');
select throws_ok($$select public.location_set('w21z7abcd')$$, 'P0001', 'Turn on location first.', 'no location without consent');
select public.consent_set('location', true);
select public.location_set('w21z7abcd');
select t.reset();
select is((select geohash from public.private_locations where user_id = 'f0000000-0000-0000-0000-000000000001'), 'w21z7', 'P2-01 only a coarse geohash is kept');
select t.as_user('f0000000-0000-0000-0000-000000000001');
select throws_ok($$select * from public.private_locations$$, '42501', null, 'nobody can read stored locations');

-- Sessions.
select ok(public.discover_sessions()::text like '%' || (select id from m)::text || '%', 'P2-01 a Meet is found');
select ok(public.discover_sessions()::text not like '%' || (select id from b)::text || '%', 'P2-01 a blocked host''s Meet is left out');
select ok((public.discover_sessions() -> 0 ->> 'km') is not null, 'distance is shown from your own area');
select is(jsonb_array_length(public.discover_sessions(p_sport => 'pickleball')), 0, 'the sport filter works');
select is(jsonb_array_length(public.discover_sessions(p_max_km => 0.001)), 0, 'the distance filter works');
select is(jsonb_array_length(public.discover_sessions(p_from => now() + interval '30 days')), 0, 'the date filter works');

-- Players.
select ok(public.discover_players()::text like '%f0000000-0000-0000-0000-000000000002%', 'P2-01 an adult is found');
select ok(public.discover_players()::text not like '%f0000000-0000-0000-0000-000000000003%', 'P2-01 minors are left out');
select ok(public.discover_players()::text not like '%f0000000-0000-0000-0000-000000000004%', 'P2-01 blocked players are left out');
select ok(public.discover_players()::text not like '%f0000000-0000-0000-0000-000000000005%', 'only-me players are left out');

-- Withdrawing.
select public.consent_set('location', false);
select t.reset();
select is_empty($$select 1 from public.private_locations where user_id = 'f0000000-0000-0000-0000-000000000001'$$, 'withdrawing consent deletes the location');

select * from finish();
rollback;
