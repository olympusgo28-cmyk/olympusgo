-- P4a-05: held money goes to the organizer once, at the right moment, and a
-- report keeps it held.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('f0000000-0000-0000-0000-000000000001');  -- host
select t.player('f0000000-0000-0000-0000-000000000002');
select t.player('f0000000-0000-0000-0000-000000000003');
select t.player('f0000000-0000-0000-0000-000000000004');  -- outsider

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;
create function t.report(p_user uuid, p_activity uuid) returns void language plpgsql as $$
begin
  insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values (p_user, 'activity', p_activity::text, 'scam');
end;
$$;

-- Saving attendance after the start releases, absent players included.
insert into ids values ('m1', t.paid_meet('f0000000-0000-0000-0000-000000000001'));
insert into ids values ('p1', t.paid('f0000000-0000-0000-0000-000000000002', t.id('m1')));
insert into ids values ('p2', t.paid('f0000000-0000-0000-0000-000000000003', t.id('m1')));
select is(t.bal('held', t.id('m1')), -1200::bigint, 'two prices held');
update public.activities set starts_at = now() - interval '5 minutes', ends_at = now() + interval '2 hours' where id = t.id('m1');
select t.as_user('f0000000-0000-0000-0000-000000000001');
select public.save_attendance(t.id('m1'), jsonb_build_object(
  'f0000000-0000-0000-0000-000000000002', 'present', 'f0000000-0000-0000-0000-000000000003', 'absent'));
select t.reset();
select is(t.bal('held', t.id('m1')), 0::bigint, 'saving attendance releases the money');
select is(t.bal('organizer', 'f0000000-0000-0000-0000-000000000001'), -1200::bigint, 'absent players'' prices are released too');

-- Correcting attendance later moves nothing.
select t.as_user('f0000000-0000-0000-0000-000000000001');
select public.save_attendance(t.id('m1'), jsonb_build_object('f0000000-0000-0000-0000-000000000003', 'present'));
select t.reset();
select is((select count(*)::int from public.ledger_transactions where kind = 'release'
  and reference ->> 'activity' = t.id('m1')::text), 2, 'each payment released once');
select is(t.bal('organizer', 'f0000000-0000-0000-0000-000000000001'), -1200::bigint, 'a correction moves no money');

-- Cancelling after release is refused.
select t.as_user('f0000000-0000-0000-0000-000000000001');
select throws_like(format($$select public.cancel_activity(%L, false, null)$$, t.id('m1')), '%been released%',
  'a host can''t cancel once money is released');
select t.reset();

-- Saving early does nothing until the start.
insert into ids values ('m2', t.paid_meet('f0000000-0000-0000-0000-000000000001'));
insert into ids values ('p3', t.paid('f0000000-0000-0000-0000-000000000002', t.id('m2')));
update public.activities set starts_at = now() + interval '20 minutes', ends_at = now() + interval '2 hours' where id = t.id('m2');
select t.as_user('f0000000-0000-0000-0000-000000000001');
select public.save_attendance(t.id('m2'), jsonb_build_object('f0000000-0000-0000-0000-000000000002', 'present'));
select t.reset();
select is(t.bal('held', t.id('m2')), -600::bigint, 'attendance saved before the start releases nothing');
select private.money_sweep();
select is(t.bal('held', t.id('m2')), -600::bigint, 'nor does the sweep');
select t.as_user('f0000000-0000-0000-0000-000000000001');
select public.cancel_activity(t.id('m2'), false, null);
select t.reset();
select is(t.refunded(t.id('p3')), 800::bigint, 'so saving early then cancelling refunds everyone');

-- The sweep picks up a saved Meet at the start.
insert into ids values ('m3', t.paid_meet('f0000000-0000-0000-0000-000000000001'));
insert into ids values ('p4', t.paid('f0000000-0000-0000-0000-000000000002', t.id('m3')));
update public.activities set starts_at = now() + interval '20 minutes', ends_at = now() + interval '2 hours' where id = t.id('m3');
select t.as_user('f0000000-0000-0000-0000-000000000001');
select public.save_attendance(t.id('m3'), jsonb_build_object('f0000000-0000-0000-0000-000000000002', 'present'));
select t.reset();
update public.activities set starts_at = now() - interval '1 minute' where id = t.id('m3');
select private.money_sweep();
select is(t.bal('held', t.id('m3')), 0::bigint, 'the sweep releases once it has started');

-- 24 hours after the end, with no attendance.
insert into ids values ('m4', t.paid_meet('f0000000-0000-0000-0000-000000000001'));
insert into ids values ('p5', t.paid('f0000000-0000-0000-0000-000000000002', t.id('m4')));
update public.activities set starts_at = now() - interval '26 hours', ends_at = now() - interval '23 hours' where id = t.id('m4');
select private.money_sweep();
select is(t.bal('held', t.id('m4')), -600::bigint, '23 hours after the end, still held');
update public.activities set ends_at = now() - interval '25 hours' where id = t.id('m4');
select private.money_sweep();
select is(t.bal('held', t.id('m4')), 0::bigint, '24 hours after the end, released');

-- A refund before release leaves only the rest.
insert into ids values ('m5', t.event_meet('f0000000-0000-0000-0000-000000000001', 1000, 10, 72));
insert into ids values ('t1', t.payment_id(t.reserve('f0000000-0000-0000-0000-000000000002', t.id('m5'), null, 3)));
select t.succeed(t.id('t1'));
select t.as_user('f0000000-0000-0000-0000-000000000002');
select public.event_ticket_release(t.id('m5'), 1);
select t.reset();
select private.release_activity(t.id('m5'));
select is((select sum(amount_minor)::bigint from public.ledger_entries e join public.ledger_transactions x on x.id = e.transaction_id
  where x.idempotency_key = 'release:' || t.id('t1') and e.amount_minor > 0), 2000::bigint, 'only what wasn''t refunded is released');
select is(t.bal('held', t.id('m5')), 0::bigint, 'and nothing is stuck');

-- A refund after release comes from earnings.
select t.as_user('f0000000-0000-0000-0000-000000000002');
select is(public.event_ticket_release(t.id('m5'), 1), 1000, 'a refund after release still works');
select t.reset();
select is(t.bal('held', t.id('m5')), 0::bigint, 'and doesn''t touch held money');

-- R-HOLD-4: a participant's report holds the money.
insert into ids values ('m6', t.paid_meet('f0000000-0000-0000-0000-000000000001'));
insert into ids values ('p6', t.paid('f0000000-0000-0000-0000-000000000002', t.id('m6')));
select t.report('f0000000-0000-0000-0000-000000000004', t.id('m6'));
select is((select count(*)::int from public.activity_money_holds where activity_id = t.id('m6')), 0, 'an outsider''s report holds nothing');
select t.report('f0000000-0000-0000-0000-000000000002', t.id('m6'));
select is((select count(*)::int from public.activity_money_holds where activity_id = t.id('m6') and closed_at is null), 1,
  'a participant''s report holds the money');
update public.activities set starts_at = now() - interval '30 hours', ends_at = now() - interval '26 hours' where id = t.id('m6');
select private.money_sweep();
select is(t.bal('held', t.id('m6')), -600::bigint, 'the sweep leaves held money alone');
select is(private.release_activity(t.id('m6')), 0, 'and so does a direct release');

-- Deciding the case doesn't move money. Only the hold decision does.
insert into public.staff (user_id, role) values ('f0000000-0000-0000-0000-000000000004', 'payments');
select t.as_staff('f0000000-0000-0000-0000-000000000004');
select public.staff_hold_decide(t.id('m6'), false, 'Looked at the report');
select throws_like(format($$select public.staff_hold_decide(%L, false, 'again')$$, t.id('m6')), '%no hold%', 'a hold closes once');
select t.reset();
select private.money_sweep();
select is(t.bal('held', t.id('m6')), 0::bigint, 'once staff close it, the money is released');

-- After release a report holds nothing.
select t.report('f0000000-0000-0000-0000-000000000003', t.id('m6'));
select is((select count(*)::int from public.activity_money_holds where activity_id = t.id('m6') and closed_at is null), 0, 'a report after release holds nothing');

-- Staff can refund everything instead.
insert into ids values ('m7', t.paid_meet('f0000000-0000-0000-0000-000000000001'));
insert into ids values ('p7', t.paid('f0000000-0000-0000-0000-000000000002', t.id('m7')));
select t.report('f0000000-0000-0000-0000-000000000002', t.id('m7'));
select t.as_staff('f0000000-0000-0000-0000-000000000004');
select public.staff_hold_decide(t.id('m7'), true, 'Upheld');
select t.reset();
select is(t.refunded(t.id('p7')), 800::bigint, 'a decided hold can refund everyone');

-- Old money raises an alert. Nothing is decided automatically.
insert into ids values ('m8', t.paid_meet('f0000000-0000-0000-0000-000000000001'));
insert into ids values ('p8', t.paid('f0000000-0000-0000-0000-000000000002', t.id('m8')));
update public.payments set captured_at = now() - interval '76 days' where id = t.id('p8');
select private.money_sweep();
select ok(exists (select 1 from public.money_alerts where key = 'hold-aging:' || t.id('m8')), 'money held 75 days raises an alert');
select is(t.bal('held', t.id('m8')), -600::bigint, 'and stays held');

-- Activities holding money can't vanish.
select throws_like(format($$delete from public.activities where id = %L$$, t.id('m8')), '%holds money%', 'an activity holding money can''t be deleted');

select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
