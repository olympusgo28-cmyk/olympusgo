-- P4b-05: spending, returning, expiring and earning points. Stored as cents.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('b2000000-0000-0000-0000-000000000001');  -- host
select t.player('b2000000-0000-0000-0000-000000000002');
select t.player('b2000000-0000-0000-0000-000000000003');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;
create function t.pts(p_user uuid) returns bigint language sql as $$ select private.points_balance(p_user); $$;

-- Lots, oldest first.
select t.give_points('b2000000-0000-0000-0000-000000000002', 300, 1);
select t.give_points('b2000000-0000-0000-0000-000000000002', 500, 6);
select is(t.pts('b2000000-0000-0000-0000-000000000002'), 800::bigint, 'the balance is a sum of lots');
select private.points_spend('b2000000-0000-0000-0000-000000000002', 400, 'order', 'o1');
select is(t.pts('b2000000-0000-0000-0000-000000000002'), 400::bigint, 'spending lowers it');
select is((select count(*)::int from public.points_entries where source_id = 'o1' and kind = 'spend'), 2, 'taking the oldest lot first, then the next');
select is((select amount_minor from public.points_entries where source_id = 'o1' and kind = 'spend' order by id limit 1), -300::bigint, 'all of the oldest');
select throws_like($$select private.points_spend('b2000000-0000-0000-0000-000000000002', 401, 'order', 'o2')$$, '%that many points%', 'you can''t spend more than you have');
select is(private.points_return('order', 'o1', 'all'), 400::bigint, 'returning gives it all back');
select is(t.pts('b2000000-0000-0000-0000-000000000002'), 800::bigint, 'to the same lots');
select is(private.points_return('order', 'o1', 'again'), 0::bigint, 'and only once');

-- Partial returns.
select private.points_spend('b2000000-0000-0000-0000-000000000002', 200, 'order', 'o3');
select is(private.points_return('order', 'o3', 'p1', 50), 50::bigint, 'part can come back');
select is(private.points_return('order', 'o3', 'p2', 500), 150::bigint, 'and never more than was spent');

-- Expiry.
select t.give_points('b2000000-0000-0000-0000-000000000003', 100, -1);
select is(t.pts('b2000000-0000-0000-0000-000000000003'), 0::bigint, 'expired points are out of the balance with no timer');
select private.points_expire();
select private.points_expire();
select is((select count(*)::int from public.points_entries where user_id = 'b2000000-0000-0000-0000-000000000003' and kind = 'expire'), 1, 'the daily job writes it down once');

-- Append-only and closed.
select throws_like($$update public.points_entries set amount_minor = 1$$, '%append-only%', 'points can''t be changed');
select throws_like($$delete from public.points_entries$$, '%append-only%', 'or deleted');
select t.as_user('b2000000-0000-0000-0000-000000000002');
select throws_ok($$select 1 from public.points_entries$$, '42501', null, 'players read only points_my');
select throws_ok($$select private.points_spend(auth.uid(), 1, 'x', 'y')$$, '42501', null, 'and can''t call the ledger');
select is((public.points_my() ->> 'balance_minor')::int, 800, 'points_my gives the balance');
select is(public.points_my() ->> 'earning', 'false', 'and says earning is off');
select t.reset();

-- Earning stays off until the owner turns it on.
insert into ids values ('m1', t.paid_meet('b2000000-0000-0000-0000-000000000001'));
insert into ids values ('p1', t.paid('b2000000-0000-0000-0000-000000000003', t.id('m1')));
update public.activities set starts_at = now() + interval '5 minutes', ends_at = now() + interval '2 hours' where id = t.id('m1');
select t.as_user('b2000000-0000-0000-0000-000000000001');
select public.save_attendance(t.id('m1'), jsonb_build_object('b2000000-0000-0000-0000-000000000003', 'present'));
select t.reset();
select is(t.pts('b2000000-0000-0000-0000-000000000003'), 0::bigint, 'nothing is earned with the switch off');

-- Set everything, and it still needs 5 confirmed matches.
update public.feature_flags set enabled = true where key = 'points.earning';
insert into public.app_settings (key, value) values ('points.weekly_cap_minor', '2000'), ('points.redeem_min_account_days', '0');
insert into ids values ('m2', t.paid_meet('b2000000-0000-0000-0000-000000000001'));
insert into ids values ('p2', t.paid('b2000000-0000-0000-0000-000000000003', t.id('m2')));
update public.activity_participants set attendance = 'present' where activity_id = t.id('m2') and user_id = 'b2000000-0000-0000-0000-000000000003';
select is(t.pts('b2000000-0000-0000-0000-000000000003'), 0::bigint, 'no matches, no points (R-PTS-6)');

update public.app_settings set value = '0' where key = 'points.min_confirmed_matches';
update public.activity_participants set attendance = 'absent' where activity_id = t.id('m2') and user_id = 'b2000000-0000-0000-0000-000000000003';
update public.activity_participants set attendance = 'present' where activity_id = t.id('m2') and user_id = 'b2000000-0000-0000-0000-000000000003';
select is(t.pts('b2000000-0000-0000-0000-000000000003'), 400::bigint, 'a S$2.00 fee earns S$4.00, which is 40 points');
update public.activity_participants set attendance = 'absent' where activity_id = t.id('m2') and user_id = 'b2000000-0000-0000-0000-000000000003';
select is(t.pts('b2000000-0000-0000-0000-000000000003'), 0::bigint, 'correcting to Absent takes them back');
update public.feature_flags set enabled = false where key = 'points.earning';
update public.activity_participants set attendance = 'present' where activity_id = t.id('m2') and user_id = 'b2000000-0000-0000-0000-000000000003';
select is(t.pts('b2000000-0000-0000-0000-000000000003'), 0::bigint, 'switching earning off stops new points');
update public.feature_flags set enabled = true where key = 'points.earning';
update public.activity_participants set attendance = null where activity_id = t.id('m2') and user_id = 'b2000000-0000-0000-0000-000000000003';
update public.activity_participants set attendance = 'present' where activity_id = t.id('m2') and user_id = 'b2000000-0000-0000-0000-000000000003';
select is(t.pts('b2000000-0000-0000-0000-000000000003'), 400::bigint, 'and on again they come back');

-- Taking back works with earning off, and a spent lot can go below zero.
select private.points_spend('b2000000-0000-0000-0000-000000000003', 400, 'order', 'spent');
update public.feature_flags set enabled = false where key = 'points.earning';
update public.activity_participants set attendance = 'absent' where activity_id = t.id('m2') and user_id = 'b2000000-0000-0000-0000-000000000003';
select is(t.pts('b2000000-0000-0000-0000-000000000003'), 0::bigint, 'a balance shows no less than zero');
select is((select sum(amount_minor)::bigint from public.points_entries where user_id = 'b2000000-0000-0000-0000-000000000003' and expires_at > now()), -400::bigint,
  'the shortfall stays on the lot');
update public.feature_flags set enabled = true where key = 'points.earning';

-- A refund of the fee takes points with it.
insert into ids values ('m3', t.paid_meet('b2000000-0000-0000-0000-000000000001'));
insert into ids values ('p3', t.paid('b2000000-0000-0000-0000-000000000002', t.id('m3')));
update public.activity_participants set attendance = 'present' where activity_id = t.id('m3') and user_id = 'b2000000-0000-0000-0000-000000000002';
create temp table b0 on commit drop as select t.pts('b2000000-0000-0000-0000-000000000002') as v;
select private.refund_issue(t.id('p3'), 'staff');
select is(t.pts('b2000000-0000-0000-0000-000000000002'), (select v from b0) - 400, 'a refunded fee earns nothing');

-- The weekly cap.
update public.app_settings set value = '100' where key = 'points.weekly_cap_minor';
insert into ids values ('m4', t.paid_meet('b2000000-0000-0000-0000-000000000001'));
insert into ids values ('p4', t.paid('b2000000-0000-0000-0000-000000000003', t.id('m4')));
select is((select count(*)::int from public.points_entries where source_id = t.id('p4')::text), 0, 'before Present, nothing');
update public.activity_participants set attendance = 'present' where activity_id = t.id('m4') and user_id = 'b2000000-0000-0000-0000-000000000003';
select is((select count(*)::int from public.points_entries where source_id = t.id('p4')::text), 0, 'a player over the weekly cap gets nothing more');

-- Blocked accounts lose them.
insert into public.staff (user_id, role) values ('b2000000-0000-0000-0000-000000000001', 'payments');
select t.as_staff('b2000000-0000-0000-0000-000000000001');
select public.staff_points_block('b2000000-0000-0000-0000-000000000002', true, 'Farming points');
select t.reset();
select is(t.pts('b2000000-0000-0000-0000-000000000002'), 0::bigint, 'a blocked account forfeits its points');
select ok(not private.points_can_redeem('b2000000-0000-0000-0000-000000000002'), 'and can''t redeem');

-- Redeeming needs the owner's minimum age.
delete from public.app_settings where key = 'points.redeem_min_account_days';
select ok(not private.points_can_redeem('b2000000-0000-0000-0000-000000000003'), 'with no minimum set, nobody redeems');

-- A failure in points never stops attendance.
select ok(exists (select 1 from pg_trigger where tgname = 'activity_participants_points'), 'attendance is hooked');

select * from finish();
rollback;
