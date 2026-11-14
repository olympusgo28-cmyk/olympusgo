begin;
\ir helpers/setup.psql
select no_plan();

select t.player('e1000000-0000-0000-0000-000000000001');
select t.player('e1000000-0000-0000-0000-000000000002');
select t.player('e1000000-0000-0000-0000-000000000003', 14);
select t.player('e1000000-0000-0000-0000-000000000004');
select t.player('e1000000-0000-0000-0000-000000000005', 30, 'MY');
update public.profiles set full_name = 'Adult One' where id = 'e1000000-0000-0000-0000-000000000001';
update public.profiles set full_name = 'Mei Lim' where id = 'e1000000-0000-0000-0000-000000000003';
update public.profiles set full_name = 'Kuala Player' where id = 'e1000000-0000-0000-0000-000000000005';
insert into public.ratings (user_id, sport, rating, matches) values
  ('e1000000-0000-0000-0000-000000000001', 'badminton', 1700, 3),
  ('e1000000-0000-0000-0000-000000000003', 'badminton', 1650, 3),
  ('e1000000-0000-0000-0000-000000000005', 'badminton', 1800, 3);
select private.leaderboards_build();

select t.as_user('e1000000-0000-0000-0000-000000000004');
select ok(public.leaderboard_rating('badminton', '{}')::text like '%Adult%', 'P3-07 an adult is listed from the snapshot');
select unalike(public.leaderboard_rating('badminton', '{}')::text, '%Mei%', 'P3-07 a minor is left out by default');
select unalike(public.leaderboard_rating('badminton', '{}')::text, '%Kuala%', 'P3-07 another country is left out');
select throws_ok($$select * from public.leaderboard_rows$$, '42501', null, 'snapshots have no client read');
select throws_ok(format('select public.guardian_leaderboard_set(%L, true)', 'e1000000-0000-0000-0000-000000000003'),
  'P0001', 'Only a linked parent can do this.', 'P3-07 a stranger cannot opt a child in');
select throws_ok($$insert into public.leaderboard_consents (child_id, guardian_id) values ('e1000000-0000-0000-0000-000000000003', auth.uid())$$,
  '42501', null, 'consent has no client write');
select t.reset();

-- A guardian opts in. The child's guardian link is direct, as P1 tests make it.
insert into public.guardian_links (parent_id, child_id, status)
  values ('e1000000-0000-0000-0000-000000000002', 'e1000000-0000-0000-0000-000000000003', 'approved');
select t.as_user('e1000000-0000-0000-0000-000000000002');
select lives_ok(format('select public.guardian_leaderboard_set(%L, true)', 'e1000000-0000-0000-0000-000000000003'), 'P3-07 a guardian opts in');
select t.reset();
select private.leaderboards_build();
select t.as_user('e1000000-0000-0000-0000-000000000004');
select ok(public.leaderboard_rating('badminton', '{}')::text like '%Mei L.%', 'P3-07 opted in, shown by first name and initial');
select unalike(public.leaderboard_rating('badminton', '{}')::text, '%Lim%', 'a child''s full name never shows');
select t.reset();

select t.as_user('e1000000-0000-0000-0000-000000000002');
select public.guardian_leaderboard_set('e1000000-0000-0000-0000-000000000003', false);
select unalike(public.leaderboard_rating('badminton', '{}')::text, '%Mei%', 'P3-07 opting out shows at once, before the next build');
select t.reset();

-- Blocks and suspensions apply at read time.
insert into public.blocks (blocker_id, blocked_id) values
  ('e1000000-0000-0000-0000-000000000004', 'e1000000-0000-0000-0000-000000000001');
select t.as_user('e1000000-0000-0000-0000-000000000004');
select unalike(public.leaderboard_rating('badminton', '{}')::text, '%Adult%', 'a blocked player is left out');
select t.reset();

select * from finish();
rollback;
