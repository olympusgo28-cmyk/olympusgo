begin;
\ir helpers/setup.psql
select plan(14);

select t.player('60000000-0000-0000-0000-000000000001');      -- host
select t.player('60000000-0000-0000-0000-000000000002');      -- player
select t.player('60000000-0000-0000-0000-000000000003', 12);  -- child
select t.player('60000000-0000-0000-0000-000000000004');      -- parent
select t.player('60000000-0000-0000-0000-000000000005');      -- blocked

create temp table m on commit drop as
  select t.meet('60000000-0000-0000-0000-000000000001') as id;
grant select on m to authenticated;

select t.as_user('60000000-0000-0000-0000-000000000002');
select public.join_activity((select id from m));
create temp table tok on commit drop as select public.my_qr() as v;
grant select, update on tok to authenticated;
select t.reset();

select unalike((select v from tok), '%60000000%', 'the QR holds no user id');
select is(length((select v from tok)), 48, 'the QR holds an opaque token');

select t.as_user('60000000-0000-0000-0000-000000000002');
select is(public.my_qr(), (select v from tok), 'the token stays the same until rotated');
select throws_ok($$select * from public.player_qr_tokens$$, '42501', null, 'players cannot read the token table');
select t.reset();

select t.as_user('60000000-0000-0000-0000-000000000001');
select throws_ok(
  format('select public.host_check_in(%L, %L)', (select id from m), (select v from tok)),
  'P0001', 'Check-in opens 30 minutes before the start.', 'R-ATT-1 check-in waits for the window');
select t.reset();
select t.start_meet((select id from m));

select t.as_user('60000000-0000-0000-0000-000000000005');
select throws_ok(
  format('select public.host_check_in(%L, %L)', (select id from m), (select v from tok)),
  'P0001', 'Only the organizer can check players in.', 'only the host scans players in');
select t.reset();

select t.as_user('60000000-0000-0000-0000-000000000001');
select is((public.host_check_in((select id from m), (select v from tok)) ->> 'present')::int, 1, 'P1-10 a scan marks the player Present');
select is((public.host_check_in((select id from m), (select v from tok)) ->> 'present')::int, 1, 'a second scan changes nothing');
select t.reset();

select is((select check_in_method from public.activity_participants
  where activity_id = (select id from m) and user_id = '60000000-0000-0000-0000-000000000002'), 'qr', 'the scan is recorded as QR');

-- Rotation.
select t.as_user('60000000-0000-0000-0000-000000000002');
select public.rotate_my_qr();
select t.reset();
select t.as_user('60000000-0000-0000-0000-000000000001');
select throws_ok(
  format('select public.host_check_in(%L, %L)', (select id from m), (select v from tok)),
  'P0001', 'That code isn''t valid.', 'P1-10 a rotated token stops working');
select t.reset();

-- Under-13s do not scan.
select t.as_user('60000000-0000-0000-0000-000000000003');
select throws_ok(format('select public.resolve_qr(%L)', (select v from tok)),
  'P0001', 'Ask a parent to scan for you.', 'P1-10 an under-13 cannot scan a player');
select throws_ok(format('select public.check_in(%L)', (select id from m)),
  'P0001', 'Ask a parent to scan for you.', 'P1-10 an under-13 cannot scan a Meet');
select t.reset();

-- A parent scans for their child.
insert into public.guardian_links (child_id, parent_id, status) values
  ('60000000-0000-0000-0000-000000000003', '60000000-0000-0000-0000-000000000004', 'approved');
insert into public.activity_participants (activity_id, user_id, status)
  values ((select id from m), '60000000-0000-0000-0000-000000000003', 'joined');
select t.as_user('60000000-0000-0000-0000-000000000004');
select is(public.guardian_check_in((select id from m), '60000000-0000-0000-0000-000000000003'), 2, 'P1-10 a parent scans for a child');
select t.reset();
select t.as_user('60000000-0000-0000-0000-000000000005');
select throws_ok(
  format('select public.guardian_check_in(%L, %L)', (select id from m), '60000000-0000-0000-0000-000000000003'),
  'P0001', 'Only a linked parent can do this.', 'nobody else can scan for a child');
select t.reset();

select * from finish();
rollback;
