-- The parallel race (20 joins on 10 spots) needs real connections, so it
-- lives in test/supabase_play_local_test.dart. This file covers the rules.
begin;
\ir helpers/setup.psql
select plan(25);

select t.player('50000000-0000-0000-0000-000000000001');  -- host
select t.player(('50000000-0000-0000-0000-00000000000' || i)::uuid) from generate_series(2, 9) i;
select t.player('50000000-0000-0000-0000-000000000012', 12);

create temp table m on commit drop as
  select t.meet('50000000-0000-0000-0000-000000000001', p_capacity => 3, p_min => 2) as id;
grant select on m to authenticated;

-- Fill it.
select t.as_user('50000000-0000-0000-0000-000000000002');
select is(public.join_activity((select id from m)), 'joined', 'P1-09 a player joins');
select is(public.join_activity((select id from m)), 'joined', 'joining twice changes nothing');
select is((select game_is_on from public.activity_cards where id = (select id from m)), false, 'not on below the minimum');
select t.reset();

select t.as_user('50000000-0000-0000-0000-000000000003');
select is(public.join_activity((select id from m)), 'joined', 'a second player joins');
select is((select game_is_on from public.activity_cards where id = (select id from m)), true, 'P1-09 the minimum shows Game is on');
select t.reset();

select is((select count(*)::int from public.notifications
  where title = 'Game is on' and link = '/activities/' || (select id from m)), 2, 'players are told once');

select t.as_user('50000000-0000-0000-0000-000000000004');
select is(public.join_activity((select id from m)), 'joined', 'the last spot goes');
select t.reset();

-- Full: the same function puts you on the waitlist, in order.
select t.as_user('50000000-0000-0000-0000-000000000005');
select is(public.join_activity((select id from m)), 'waitlist', 'R-MET-4 a full Meet waitlists');
select is((select my_waitlist_position from public.activity_cards where id = (select id from m)), 1, 'first in the queue');
select t.reset();

select t.as_user('50000000-0000-0000-0000-000000000006');
select is(public.join_waitlist((select id from m)), 2, 'second in the queue');
select is(public.join_waitlist((select id from m)), 2, 'pressing again keeps your place');
select t.reset();

select t.as_user('50000000-0000-0000-0000-000000000007');
select is(public.join_activity((select id from m)), 'waitlist', 'third in the queue');
select is((select waitlist_count from public.activity_cards where id = (select id from m)), 3, 'the count is right for everyone');
select t.reset();

-- A pair can't take one seat, so the next person who fits moves up.
select t.as_user('50000000-0000-0000-0000-000000000005');
select public.leave_activity((select id from m));
select public.join_activity((select id from m), 'My guest', 3.0);
select t.reset();

select t.as_user('50000000-0000-0000-0000-000000000002');
select public.leave_activity((select id from m));
select t.reset();
select is(t.status_of((select id from m), '50000000-0000-0000-0000-000000000006'), 'joined', 'leaving promotes the next in line');
select is(t.status_of((select id from m), '50000000-0000-0000-0000-000000000007'), 'waitlist', 'the one behind keeps waiting');
select is(t.status_of((select id from m), '50000000-0000-0000-0000-000000000002'), 'cancelled', 'the leaver is out');

-- Blocked by the host: skipped.
insert into public.blocks (blocker_id, blocked_id)
  values ('50000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000007');
select t.as_user('50000000-0000-0000-0000-000000000003');
select public.leave_activity((select id from m));
select t.reset();
select is(t.status_of((select id from m), '50000000-0000-0000-0000-000000000007'), 'waitlist', 'someone blocked by the host is skipped');

-- Reserved slots are held back from joiners.
create temp table r on commit drop as
  select t.meet('50000000-0000-0000-0000-000000000001', p_capacity => 2) as id;
grant select on r to authenticated;
update public.activities set reserved_slots = 1 where id = (select id from r);
select t.as_user('50000000-0000-0000-0000-000000000008');
select is(public.join_activity((select id from r)), 'joined', 'one open seat is taken');
select t.reset();
select t.as_user('50000000-0000-0000-0000-000000000009');
select is(public.join_activity((select id from r)), 'waitlist', 'reserved slots are not open to joiners');
select t.reset();

-- A host raising capacity lets the queue in.
update public.activities set reserved_slots = 0 where id = (select id from r);
select is(t.status_of((select id from r), '50000000-0000-0000-0000-000000000009'), 'joined', 'freeing a reserved slot promotes');

-- Restricted players stay out.
select t.as_user('50000000-0000-0000-0000-000000000012');
select throws_ok(
  format('select public.join_activity(%L)', (select id from r)),
  'P0001', 'Ask a parent to link your account first.', 'a restricted child cannot join');
select throws_ok(
  $$insert into public.activities (kind, host_id, title, sports, format, starts_at, ends_at, venue_id, capacity)
    select 'meet', '50000000-0000-0000-0000-000000000012', 'Mine', '{badminton}', 'open_play',
      now() + interval '1 day', now() + interval '2 days', v.id, 4 from public.venues v limit 1$$,
  'P0001', 'Ask a parent to link your account first.', 'a restricted child cannot host');
select t.reset();

-- Price is shown but no money moves until Phase 4a.
update public.activities set fee_cents = 800 where id = (select id from r);
select t.as_user('50000000-0000-0000-0000-000000000003');
select is(public.join_activity((select id from r)), 'waitlist', 'a paid Meet joins with no payment while payments are off');
select is_empty(format('select 1 from public.payments where activity_id = %L', (select id from r)), 'no payment row is written');
select t.reset();

-- Hosts cannot write what the server owns.
select t.as_user('50000000-0000-0000-0000-000000000001');
update public.activities set status = 'cancelled', scoring_snapshot = '{}' where id = (select id from m);
select t.reset();
select is((select status from public.activities where id = (select id from m)), 'published', 'hosts cannot set status directly');

select * from finish();
rollback;
