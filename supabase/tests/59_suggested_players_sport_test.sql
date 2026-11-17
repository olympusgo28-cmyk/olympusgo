-- Q272: suggested_players() says which sport a suggestion matched on, and
-- keeps every exclusion it already had.
begin;
\ir helpers/setup.psql
select no_plan();

select t.player('e5900000-0000-0000-0000-000000000001');      -- viewer: squash and padel
select t.player('e5900000-0000-0000-0000-000000000002');      -- matches on squash
select t.player('e5900000-0000-0000-0000-000000000003');      -- cycling only: no match
select t.player('e5900000-0000-0000-0000-000000000004');      -- squash and padel
select t.player('e5900000-0000-0000-0000-000000000005', 15);  -- minor, squash
select t.player('e5900000-0000-0000-0000-000000000006');      -- blocked, squash

-- Squash and padel, which no one else plays on a used local stack, so the
-- list's limit of ten cannot crowd these players out.
update public.profiles set onboarding_completed = true
where id::text like 'e5900000-0000-0000-0000-00000000000%';

insert into public.player_sports (user_id, sport, level, play_min, play_max) values
  ('e5900000-0000-0000-0000-000000000001', 'squash', 7.0, 6.5, 8),
  ('e5900000-0000-0000-0000-000000000001', 'padel', 7.0, 6.5, 8),
  ('e5900000-0000-0000-0000-000000000002', 'squash', 7.0, 6.5, 8),
  ('e5900000-0000-0000-0000-000000000003', 'cycling', 7.0, 6.5, 8),
  -- Two matching sports: the higher level is the one shown.
  ('e5900000-0000-0000-0000-000000000004', 'squash', 6.5, 6.5, 8),
  ('e5900000-0000-0000-0000-000000000004', 'padel', 7.0, 6.5, 8),
  ('e5900000-0000-0000-0000-000000000005', 'squash', 7.0, 6.5, 8),
  ('e5900000-0000-0000-0000-000000000006', 'squash', 7.0, 6.5, 8);
insert into public.blocks (blocker_id, blocked_id)
  values ('e5900000-0000-0000-0000-000000000001', 'e5900000-0000-0000-0000-000000000006');

select t.as_user('e5900000-0000-0000-0000-000000000001');

select is(
  (select s.sport from public.suggested_players() s where s.id = 'e5900000-0000-0000-0000-000000000002'),
  'squash', 'a suggestion carries the sport it matched on');
select is(
  (select s.sport from public.suggested_players() s where s.id = 'e5900000-0000-0000-0000-000000000004'),
  'padel', 'with two matching sports, the one with the higher level shows');
select is(
  (select s.level from public.suggested_players() s where s.id = 'e5900000-0000-0000-0000-000000000004'),
  7.0::numeric, 'and its level is that sport''s level');
select ok(not exists (select 1 from public.suggested_players() s where s.id = 'e5900000-0000-0000-0000-000000000003'),
  'a player with no matching sport is not suggested');
select ok(not exists (select 1 from public.suggested_players() s where s.id = 'e5900000-0000-0000-0000-000000000005'),
  'a minor is still left out');
select ok(not exists (select 1 from public.suggested_players() s where s.id = 'e5900000-0000-0000-0000-000000000006'),
  'a player the viewer blocked is still left out');
select ok(not exists (select 1 from public.suggested_players() s where s.id = 'e5900000-0000-0000-0000-000000000001'),
  'the viewer is not suggested to themselves');
select t.reset();

-- Grants: signed-in players only.
select ok(has_function_privilege('authenticated', 'public.suggested_players()', 'execute'),
  'signed-in players can call it');
select ok(not has_function_privilege('anon', 'public.suggested_players()', 'execute'),
  'anonymous callers cannot');
select ok(not has_function_privilege('public', 'public.suggested_players()', 'execute'),
  'PUBLIC cannot');

select * from finish();
rollback;
