-- Checklist section 4: minors never appear in player discovery, public
-- leaderboards or rankings by name.
begin;
\ir helpers/setup.psql
select plan(15);

select t.player('90000000-0000-0000-0000-000000000001');      -- viewer
select t.player('90000000-0000-0000-0000-000000000002', 15);  -- teen
select t.player('90000000-0000-0000-0000-000000000003');      -- teen's parent
select t.player('90000000-0000-0000-0000-000000000004');      -- another adult
select t.player('90000000-0000-0000-0000-000000000005');      -- blocked adult

update public.profiles set full_name = 'Mei Ling Tan' where id = '90000000-0000-0000-0000-000000000002';
insert into public.guardian_links (child_id, parent_id, status) values
  ('90000000-0000-0000-0000-000000000002', '90000000-0000-0000-0000-000000000003', 'approved');

insert into public.player_sports (user_id, sport, level, play_min, play_max)
select id, 'badminton', 4, 1, 8 from (values
  ('90000000-0000-0000-0000-000000000001'::uuid),
  ('90000000-0000-0000-0000-000000000002'),
  ('90000000-0000-0000-0000-000000000004'),
  ('90000000-0000-0000-0000-000000000005')) v(id);
insert into public.blocks (blocker_id, blocked_id)
  values ('90000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000005');

create temp table m on commit drop as
  select t.meet('90000000-0000-0000-0000-000000000004') as id;
grant select on m to authenticated;

insert into public.activity_participants (activity_id, user_id, status) values
  ((select id from m), '90000000-0000-0000-0000-000000000001', 'joined'),
  ((select id from m), '90000000-0000-0000-0000-000000000002', 'joined'),
  ((select id from m), '90000000-0000-0000-0000-000000000005', 'joined');

insert into public.match_scores (activity_id, entered_by, side_a, side_b, games, status)
values ((select id from m), '90000000-0000-0000-0000-000000000001',
  '{90000000-0000-0000-0000-000000000001,90000000-0000-0000-0000-000000000002}',
  '{90000000-0000-0000-0000-000000000004}', '[[21,10],[21,10]]', 'confirmed');
update public.activities set sports = '{badminton}' where id = (select id from m);

select t.player('90000000-0000-0000-0000-000000000006');      -- stranger

select t.as_user('90000000-0000-0000-0000-000000000006');
select is_empty(
  format('select 1 from public.meet_players(%L) p where p.full_name like %L', (select id from m), 'Mei%'),
  'someone not on the Meet does not see a minor at all');
select t.reset();

select t.as_user('90000000-0000-0000-0000-000000000001');
select is_empty(
  format('select 1 from public.meet_players(%L) p where p.user_id = %L', (select id from m), '90000000-0000-0000-0000-000000000002'),
  'a masked minor''s real id is not shown');
select throws_ok(
  $$insert into public.follows (follower_id, followee_id) values
    ('90000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000002')$$,
  '42501', null, 'a minor cannot be followed');
select t.reset();

select t.as_user('90000000-0000-0000-0000-000000000004');
select throws_ok(
  format('select public.add_walk_in(%L, %L, true)',
    t.meet('90000000-0000-0000-0000-000000000004'), '90000000-0000-0000-0000-000000000002'),
  'P0001', 'You can''t add this player.', 'a host cannot pull a minor onto their Meet');
select t.reset();

create temp table e on commit drop as
  with i as (insert into public.tournament_entries (activity_id, division, user_id)
    values ((select id from m), 'main', '90000000-0000-0000-0000-000000000002') returning id)
  select id from i;
select is(public.tournament_entry_name((select id from e)), 'Mei L.', 'tournament lists show a minor by first name and initial');

select t.as_user('90000000-0000-0000-0000-000000000001');
select ok(not exists (select 1 from public.suggested_players() s where s.id = '90000000-0000-0000-0000-000000000002'),
  'minors are left out of player suggestions');
-- Any adult: the list is short, and a used local stack fills it with others.
select ok(exists (select 1 from public.suggested_players()), 'adults are still suggested');
select unalike(public.leaderboard_rating('badminton', '{}')::text, '%Mei%', 'minors are left out of the rating leaderboard');
select is((select count(*)::int from public.meet_players((select id from m)) p where p.full_name = 'Mei L.'),
  1, 'a minor shows as first name and initial on a roster');
select is((select username from public.meet_players((select id from m)) p where p.full_name = 'Mei L.'),
  null, 'a minor''s username is not shown');
select set_config('role', 'postgres', true);
select is((public.player_json('90000000-0000-0000-0000-000000000002') ->> 'full_name'), 'Mei L.', 'player_json masks minors for every list');
select set_config('role', 'authenticated', true);
select is_empty(
  format('select 1 from public.meet_players(%L) p where p.user_id = %L', (select id from m), '90000000-0000-0000-0000-000000000005'),
  'R-PRV-4 blocked players are left out of rosters');
select t.reset();

select t.as_user('90000000-0000-0000-0000-000000000004');
select is((select full_name from public.meet_players((select id from m)) p where p.user_id = '90000000-0000-0000-0000-000000000002'),
  'Mei Ling Tan', 'the host sees the name they need for check-in');
select t.reset();

select t.as_user('90000000-0000-0000-0000-000000000003');
select set_config('role', 'postgres', true);
select is((public.player_json('90000000-0000-0000-0000-000000000002') ->> 'full_name'), 'Mei Ling Tan', 'a parent sees their child''s name');
select t.reset();

select t.as_user('90000000-0000-0000-0000-000000000002');
update public.profiles set visibility = 'everyone' where id = '90000000-0000-0000-0000-000000000002';
select isnt((select visibility from public.profiles where id = '90000000-0000-0000-0000-000000000002'), 'everyone', 'R-AGE-3 a minor cannot go public');
select t.reset();

select * from finish();
rollback;
