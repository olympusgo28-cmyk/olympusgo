begin;
\ir helpers/setup.psql
select plan(12);

select t.player('70000000-0000-0000-0000-000000000001');
select t.player('70000000-0000-0000-0000-000000000002');
select t.player('70000000-0000-0000-0000-000000000003');

create temp table m on commit drop as
  select t.meet('70000000-0000-0000-0000-000000000001') as id;
grant select on m to authenticated;

select t.as_user('70000000-0000-0000-0000-000000000002');
select public.join_activity((select id from m));
select t.reset();
select t.as_user('70000000-0000-0000-0000-000000000003');
select public.join_activity((select id from m));
select t.reset();

select t.as_user('70000000-0000-0000-0000-000000000001');
select throws_ok(
  format($q$select public.save_attendance(%L, '{}')$q$, (select id from m)),
  'P0001', 'Attendance opens 30 minutes before the start.', 'R-ATT-1 attendance waits for the window');
select t.reset();
select t.start_meet((select id from m));

select t.as_user('70000000-0000-0000-0000-000000000002');
select throws_ok(
  format($q$select public.save_attendance(%L, '{}')$q$, (select id from m)),
  'P0001', 'Only the organizer can mark attendance.', 'only the host saves attendance');
select t.reset();

select t.as_user('70000000-0000-0000-0000-000000000001');
select is(public.save_attendance((select id from m),
  '{"70000000-0000-0000-0000-000000000002": "present", "70000000-0000-0000-0000-000000000003": "absent"}'),
  1, 'P1-11 the host saves attendance');
select t.reset();

select is((select count(*)::int from public.campaign_game_log where activity_id = (select id from m)), 1, 'P1-11 one log row is written');
select is((select present_count from public.campaign_game_log where activity_id = (select id from m)), 1, 'the log counts who was Present');
select is((select jsonb_array_length(players) from public.campaign_game_log where activity_id = (select id from m)), 2, 'the log lists each player');
select is((select players -> 0 ->> 'paid' from public.campaign_game_log where activity_id = (select id from m)), 'false', 'the log records who paid');

select is((select players -> 0 ->> 'qr' from public.campaign_game_log where activity_id = (select id from m)), 'false', 'a host''s tick is not a QR scan');

-- Saving the same again: no second row and nothing to audit.
select t.as_user('70000000-0000-0000-0000-000000000001');
select public.save_attendance((select id from m),
  '{"70000000-0000-0000-0000-000000000002": "present", "70000000-0000-0000-0000-000000000003": "absent"}');
select t.reset();
select is((select count(*)::int from public.campaign_game_log where activity_id = (select id from m)), 1, 'P1-11 saving twice does not duplicate');
select is((select count(*)::int from public.attendance_audit where activity_id = (select id from m)), 0, 'an unchanged save is not an edit');

-- A late edit goes to the audit log, and the log itself stands.
select t.as_user('70000000-0000-0000-0000-000000000001');
select public.save_attendance((select id from m), '{"70000000-0000-0000-0000-000000000003": "present"}');
select t.reset();
select is((select count(*)::int from public.attendance_audit where activity_id = (select id from m)), 1, 'P1-11 a late edit goes to the audit log');
select throws_ok($$delete from public.campaign_game_log$$, 'P0001', 'campaign_game_log is append-only', 'the log is append-only');

select * from finish();
rollback;
