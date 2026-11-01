-- P4c-01: paid lessons, from booking through refund, release, report and dispute.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
\ir helpers/academy.psql
select no_plan();

update public.feature_flags set enabled = true where key = 'lessons.checkout';

select t.player('c2000000-0000-0000-0000-000000000001');  -- owner
select t.player('c2000000-0000-0000-0000-000000000002');  -- coach
select t.player('c2000000-0000-0000-0000-000000000003');  -- parent
select t.player('c2000000-0000-0000-0000-000000000004', 12);  -- child
select t.player('c2000000-0000-0000-0000-000000000005');  -- adult student
select t.player('c2000000-0000-0000-0000-000000000006');  -- outsider
select t.player('c2000000-0000-0000-0000-000000000007', 15);  -- teen
select t.player('c2000000-0000-0000-0000-000000000008');  -- payments staff
select t.player('c2000000-0000-0000-0000-000000000009');  -- second adult
select t.link('c2000000-0000-0000-0000-000000000003', 'c2000000-0000-0000-0000-000000000004');
insert into public.staff (user_id, role) values ('c2000000-0000-0000-0000-000000000008', 'payments');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;

insert into ids select 'academy', t.academy('c2000000-0000-0000-0000-000000000001');
select t.coach(t.id('academy'), 'c2000000-0000-0000-0000-000000000002');
insert into ids select 'class', t.class(t.id('academy'), 'c2000000-0000-0000-0000-000000000002');
update public.academy_classes set trial_price_cents = 1500, dropin_price_cents = 3000 where id = t.id('class');

-- A slot p_hours from now, added straight in.
create function t.slot(p_hours numeric default 72, p_price bigint default 5000) returns uuid
language sql security definer as $$
  -- Earlier slots step aside, so tests can reuse a time.
  update public.lesson_slots set status = 'withdrawn' where status = 'open';
  insert into public.lesson_slots (academy_id, coach_id, starts_at, ends_at, price_minor)
  values (t.id('academy'), 'c2000000-0000-0000-0000-000000000002',
    now() + make_interval(secs => p_hours * 3600), now() + make_interval(secs => p_hours * 3600 + 3600), p_price)
  returning id;
$$;

-- Books as p_payer, and leaves the session as it was.
create function t.book(p_payer uuid, p_kind text, p_ref uuid, p_at timestamptz, p_student uuid, p_total bigint)
returns jsonb language plpgsql as $$
declare
  v jsonb;
begin
  perform t.as_user(p_payer);
  v := public.lesson_reserve(p_kind, p_ref, p_at, p_student, 'key-' || gen_random_uuid(), p_total);
  perform t.reset();
  return v;
end;
$$;

-- Booked and paid: a one-to-one S$50.00 plus S$5.00, for the adult student.
create function t.paid_slot(p_hours numeric default 72) returns uuid language plpgsql as $$
declare
  v jsonb := t.book('c2000000-0000-0000-0000-000000000005', 'one_to_one', t.slot(p_hours), null,
    'c2000000-0000-0000-0000-000000000005', 5500);
begin
  perform t.succeed((v ->> 'payment_id')::uuid);
  return (v ->> 'booking_id')::uuid;
end;
$$;

create function t.lpay(p_booking uuid) returns uuid language sql security definer as $$
  select id from public.payments where lesson_booking_id = p_booking;
$$;
create function t.lstep(p_booking uuid) returns text language sql as $$
  select step from public.lesson_bookings where id = p_booking;
$$;
-- Puts a lesson in the past. The guard keeps times fixed, so it steps aside.
create function t.past(p_booking uuid, p_hours int default 1) returns void language plpgsql as $$
begin
  alter table public.lesson_bookings disable trigger lesson_bookings_guard;
  update public.lesson_bookings
  set starts_at = now() - make_interval(hours => p_hours + 1), ends_at = now() - make_interval(hours => p_hours),
      release_at = case when release_at is not null then now() - make_interval(hours => p_hours) + interval '24 hours' end
  where id = p_booking;
  alter table public.lesson_bookings enable trigger lesson_bookings_guard;
end;
$$;
create function t.due(p_booking uuid) returns void language plpgsql as $$
begin
  alter table public.lesson_bookings disable trigger lesson_bookings_guard;
  update public.lesson_bookings set starts_at = now() - interval '26 hours', ends_at = now() - interval '25 hours',
    release_at = now() - interval '1 hour' where id = p_booking;
  alter table public.lesson_bookings enable trigger lesson_bookings_guard;
end;
$$;
grant execute on all functions in schema t to anon, authenticated, service_role;

-- ─── Nothing is reachable directly ─────────────────────────────────────────

select t.as_user('c2000000-0000-0000-0000-000000000006');
select is_empty($$ select 1 from public.lesson_bookings $$, 'a player reads no bookings directly');
select is_empty($$ select 1 from public.lesson_slots $$, 'or slots');
select throws_ok($$ insert into public.lesson_slots (academy_id, coach_id, starts_at, ends_at, price_minor)
  values (t.id('academy'), auth.uid(), now(), now() + interval '1 hour', 1) $$, '42501', null, 'and writes none');
select t.reset();
select t.as_anon();
select throws_ok($$ select public.lesson_my() $$, '42501', null, 'signed out reaches nothing');
select throws_ok($$ select public.lesson_slots_open(t.id('academy')) $$, '42501', null, 'not even open slots');
select t.reset();

-- ─── Quotes ────────────────────────────────────────────────────────────────

select t.as_user('c2000000-0000-0000-0000-000000000003');
select is((public.lesson_quote('trial', t.id('class'), t.class_at(3)) ->> 'fee_minor')::bigint, 200::bigint, 'a S$15.00 trial pays the S$2.00 minimum (R-ACD-4)');
select is((public.lesson_quote('trial', t.id('class'), t.class_at(3)) ->> 'total_minor')::bigint, 1700::bigint, 'S$17.00 in all');
select is((public.lesson_quote('class', t.id('class'), t.class_at(3)) ->> 'fee_minor')::bigint, 300::bigint, 'a S$30.00 class pays 10%');
select ok(public.lesson_quote('class', t.id('class'), t.class_at(3)) -> 'payee_id' is null, 'no account id leaves in a quote');
select throws_ok($$ select public.lesson_quote('trial', t.id('class'), t.class_at(3) + interval '1 hour') $$, 'This class doesn''t run then.', 'only when the class runs');
select t.reset();
update public.academy_classes set trial_price_cents = null where id = t.id('class');
select t.as_user('c2000000-0000-0000-0000-000000000003');
select throws_ok($$ select public.lesson_quote('trial', t.id('class'), t.class_at(3)) $$, 'This class doesn''t offer that.', 'no price, no trial');
select t.reset();
update public.academy_classes set trial_price_cents = 1500 where id = t.id('class');

-- ─── Who can book ──────────────────────────────────────────────────────────

create function t.try(p_payer uuid, p_student uuid) returns jsonb language plpgsql as $$
declare
  v jsonb;
begin
  v := t.book(p_payer, 'trial', t.id('class'), t.class_at(3), p_student, 1700);
  return v;
end;
$$;

select throws_ok($$ select t.try('c2000000-0000-0000-0000-000000000006', 'c2000000-0000-0000-0000-000000000004') $$,
  'You can enrol yourself or a child linked to your account.', 'nobody books a stranger''s child');
select t.reset();
select throws_ok($$ select t.try('c2000000-0000-0000-0000-000000000007', 'c2000000-0000-0000-0000-000000000007') $$,
  'A parent needs to do this for you.', 'a teen can''t book themself');
select t.reset();
select throws_ok($$ select t.book('c2000000-0000-0000-0000-000000000005', 'trial', t.id('class'), t.class_at(3), 'c2000000-0000-0000-0000-000000000005', 1600) $$,
  'price_changed', 'a wrong total is refused, not charged');
select t.reset();

update public.feature_flags set enabled = false where key = 'lessons.checkout';
select throws_ok($$ select t.try('c2000000-0000-0000-0000-000000000005', 'c2000000-0000-0000-0000-000000000005') $$,
  'Paying for lessons isn''t open yet.', 'the flag is off by default');
select t.reset();
select t.as_user('c2000000-0000-0000-0000-000000000005');
select lives_ok($$ select public.academy_request(t.id('class'), auth.uid(), '', t.class_at(3)) $$, 'with it off a free trial request still works');
select t.reset();
update public.feature_flags set enabled = true where key = 'lessons.checkout';
select t.as_user('c2000000-0000-0000-0000-000000000009');
select throws_ok($$ select public.academy_request(t.id('class'), auth.uid(), '', t.class_at(3)) $$,
  'Trials are booked and paid in the app.', 'with it on, trials are paid');
select t.reset();

update public.vendors set status = 'pending' where owner_id = 'c2000000-0000-0000-0000-000000000001';
select throws_ok($$ select t.try('c2000000-0000-0000-0000-000000000005', 'c2000000-0000-0000-0000-000000000005') $$,
  'This academy can''t take payments yet.', 'an unverified payee takes nothing (R-PAY-4)');
select t.reset();
update public.vendors set status = 'verified' where owner_id = 'c2000000-0000-0000-0000-000000000001';

select throws_ok($$ select t.book('c2000000-0000-0000-0000-000000000002', 'class', t.id('class'), t.class_at(3), 'c2000000-0000-0000-0000-000000000002', 3300) $$,
  'You can''t book your own lesson.', 'a coach doesn''t book their own lesson');
select t.reset();

insert into public.blocks (blocker_id, blocked_id) values ('c2000000-0000-0000-0000-000000000002', 'c2000000-0000-0000-0000-000000000006');
select throws_ok($$ select t.try('c2000000-0000-0000-0000-000000000006', 'c2000000-0000-0000-0000-000000000006') $$,
  'This class isn''t available.', 'a block stops a booking');
select t.reset();
delete from public.blocks where blocker_id = 'c2000000-0000-0000-0000-000000000002';

-- ─── A parent books a trial for their child ────────────────────────────────

insert into ids select 'trial', (x ->> 'booking_id')::uuid
from t.try('c2000000-0000-0000-0000-000000000003', 'c2000000-0000-0000-0000-000000000004') x;
select is(t.lstep(t.id('trial')), 'pending', 'a booking waits for payment');
select is((select amount_minor from public.payments where id = t.lpay(t.id('trial'))), 1700::bigint, 'the server worked out the amount');
select is((select organizer_id from public.payments where id = t.lpay(t.id('trial'))),
  'c2000000-0000-0000-0000-000000000001'::uuid, 'the owner is paid, never the coach (R-PAY-3)');
select is((select beneficiary_id from public.payments where id = t.lpay(t.id('trial'))),
  'c2000000-0000-0000-0000-000000000004'::uuid, 'and the child is who it''s for');
select ok((select hold_until from public.lesson_bookings where id = t.id('trial')) <= now() + interval '10 minutes', 'the hold is 10 minutes');
select is(private.class_taken(t.id('class'), t.class_at(3)), 1, 'and takes a place');
select throws_ok($$ select t.try('c2000000-0000-0000-0000-000000000003', 'c2000000-0000-0000-0000-000000000004') $$,
  'Finish or cancel your unpaid lesson first.', 'one unpaid lesson at a time');
select t.reset();

-- Same key, same booking.
select t.as_user('c2000000-0000-0000-0000-000000000005');
select is(public.lesson_reserve('class', t.id('class'), t.class_at(4), auth.uid(), 'same-key-1', 3300) ->> 'payment_id',
  public.lesson_reserve('class', t.id('class'), t.class_at(4), auth.uid(), 'same-key-1', 3300) ->> 'payment_id', 'a retry is the same booking');
select t.reset();
select is((select count(*) from public.lesson_bookings where payer_id = 'c2000000-0000-0000-0000-000000000005'), 1::bigint, 'only one row');
select is(t.succeed(t.lpay((select id from public.lesson_bookings where payer_id = 'c2000000-0000-0000-0000-000000000005'))), 'seated', 'capture confirms it');
select is(t.succeed(t.lpay((select id from public.lesson_bookings where payer_id = 'c2000000-0000-0000-0000-000000000005'))), 'duplicate', 'and again changes nothing');

select is(t.succeed(t.lpay(t.id('trial'))), 'seated', 'the parent''s payment confirms the trial');
select is(t.lstep(t.id('trial')), 'paid', 'it''s paid');
select is(t.bal('held', t.id('trial')), -1500::bigint, 'the price is held');
select ok(t.all_balanced(), 'the ledger balances');
select is((select count(*) from public.points_entries where user_id in
  ('c2000000-0000-0000-0000-000000000003', 'c2000000-0000-0000-0000-000000000004')), 0::bigint, 'no lesson earns points');

-- Who can read it.
select t.as_user('c2000000-0000-0000-0000-000000000004');
select is((select count(*) from jsonb_array_elements(public.lesson_my())), 1::bigint, 'the child sees their lesson');
select throws_ok($$ select public.lesson_cancel(t.id('trial')) $$, 'This lesson isn''t yours.', 'but can''t cancel it');
select t.reset();
select t.as_user('c2000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.lesson_get(t.id('trial')) $$, 'This lesson isn''t yours.', 'a stranger reads nothing');
select is(public.lesson_my(), '[]'::jsonb, 'and lists nothing');
select throws_ok($$ select public.lesson_cancel(t.id('trial')) $$, 'This lesson isn''t yours.', 'or cancels');
select throws_ok($$ select public.lesson_mark_attendance(t.id('trial'), true) $$, 'This lesson isn''t yours.', 'or marks');
select throws_ok($$ select public.lesson_academy_cancel(t.id('trial'), 'x') $$, 'This lesson isn''t yours.', 'as the academy');
select t.reset();
select t.as_user('c2000000-0000-0000-0000-000000000002');
select is((select count(*) from jsonb_array_elements(public.lesson_academy_list(t.id('academy'))) x where (x ->> 'id')::uuid = t.id('trial')), 1::bigint, 'the coach sees it');
select t.reset();

-- ─── Cancelling: exactly 24 hours is in time ───────────────────────────────

insert into ids values ('in_time', t.paid_slot(72));
select t.settle_refunds(t.lpay(t.id('in_time')));
select t.as_user('c2000000-0000-0000-0000-000000000005');
select is(public.lesson_cancel(t.id('in_time')), 5000::bigint, 'in time: the price back');
select t.reset();
select is(t.lstep(t.id('in_time')), 'cancelled', 'cancelled');
select is(t.refunded(t.lpay(t.id('in_time'))), 5000::bigint, 'and the S$5.00 fee is kept (R-REF-2)');
select is(t.bal('held', t.id('in_time')), 0::bigint, 'nothing stays held');

-- The clock is fixed inside a transaction, so 24 hours from now() is exact.
insert into ids values ('edge', t.paid_slot(24));
select t.as_user('c2000000-0000-0000-0000-000000000005');
select is(public.lesson_cancel(t.id('edge')), 5000::bigint, 'exactly 24 hours before is still in time');
select t.reset();
insert into ids values ('late', t.paid_slot(23.99));
select t.as_user('c2000000-0000-0000-0000-000000000005');
select is(public.lesson_cancel(t.id('late')), 0::bigint, 'inside 24 hours: nothing back (R-REF-3)');
select t.reset();
select is(t.lstep(t.id('late')), 'late_cancelled', 'and it stays booked for the money');
select is(t.bal('held', t.id('late')), -5000::bigint, 'still held');
select t.as_user('c2000000-0000-0000-0000-000000000005');
select throws_ok($$ select public.lesson_cancel(t.id('late')) $$, 'This lesson can''t be cancelled now.', 'once');
select t.reset();

-- Abandoning an unpaid booking frees the place.
insert into ids select 'dropped', (x ->> 'booking_id')::uuid
from t.book('c2000000-0000-0000-0000-000000000009', 'class', t.id('class'), t.class_at(5), 'c2000000-0000-0000-0000-000000000009', 3300) x;
select t.as_user('c2000000-0000-0000-0000-000000000009');
select lives_ok($$ select public.lesson_cancel(t.id('dropped')) $$, 'an unpaid booking can be dropped');
select t.reset();
select is(t.lstep(t.id('dropped')), 'cancelled', 'it ends');
select is(private.class_taken(t.id('class'), t.class_at(5)), 0, 'and gives the place back');

-- ─── The academy cancels: everything back, card fee from the owner ─────────

insert into ids values ('academy_off', t.paid_slot(72));
select t.fee(t.lpay(t.id('academy_off')), 190);
select t.as_user('c2000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.lesson_academy_cancel(t.id('academy_off'), ' ') $$, 'Say why, for the parent.', 'a reason is needed');
select lives_ok($$ select public.lesson_academy_cancel(t.id('academy_off'), 'Coach unwell') $$, 'the coach cancels');
select t.reset();
select is(t.refunded(t.lpay(t.id('academy_off'))), 5500::bigint, 'everything comes back, fee included (R-REF-1)');
select t.settle_refunds(t.lpay(t.id('academy_off')));
select ok(exists (select 1 from public.ledger_transactions x where x.reference ->> 'payment' = t.lpay(t.id('academy_off'))::text and x.kind = 'card_fee'),
  'and the card fee falls on the owner (R-REF-11)');

-- A late cancel the academy then calls off still comes back in full.
insert into ids values ('late_off', t.paid_slot(23.99));
select t.as_user('c2000000-0000-0000-0000-000000000005');
select public.lesson_cancel(t.id('late_off'));
select t.reset();
select t.as_user('c2000000-0000-0000-0000-000000000001');
select lives_ok($$ select public.lesson_academy_cancel(t.id('late_off'), 'Hall flooded') $$, 'the head cancels a late-cancelled lesson');
select t.reset();
select is(t.refunded(t.lpay(t.id('late_off'))), 5500::bigint, 'and it all goes back');

-- ─── Attendance and release ────────────────────────────────────────────────

insert into ids values ('taught', t.paid_slot(72));
select t.as_user('c2000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.lesson_mark_attendance(t.id('taught'), true) $$, 'Mark attendance once the lesson starts.', 'not before the start');
select t.reset();
select t.past(t.id('taught'));
select t.as_user('c2000000-0000-0000-0000-000000000002');
select lives_ok($$ select public.lesson_mark_attendance(t.id('taught'), true) $$, 'the coach marks attendance');
select throws_ok($$ select public.lesson_mark_attendance(t.id('taught'), false) $$, 'This lesson has been settled.', 'once');
select t.reset();
select is(t.lstep(t.id('taught')), 'released', 'attendance releases it');
select is(t.bal('held', t.id('taught')), 0::bigint, 'nothing held');
select is((select sum(e.amount_minor)::bigint from public.ledger_entries e join public.ledger_transactions x on x.id = e.transaction_id
  join public.ledger_accounts a on a.id = e.account_id
  where x.reference ->> 'payment' = t.lpay(t.id('taught'))::text and a.kind = 'organizer'), -5000::bigint, 'the owner gets the price');

insert into ids values ('absent', t.paid_slot(72));
select t.past(t.id('absent'));
select t.as_user('c2000000-0000-0000-0000-000000000001');
select lives_ok($$ select public.lesson_mark_attendance(t.id('absent'), false) $$, 'the head marks someone absent');
select t.reset();
select is(t.lstep(t.id('absent')), 'released', 'an absent student is not refunded (R-HOLD-3)');

insert into ids values ('never_marked', t.paid_slot(72));
select t.past(t.id('never_marked'));
select private.lessons_sweep();
select is(t.lstep(t.id('never_marked')), 'paid', 'not released before the wait is over');
select t.due(t.id('never_marked'));
select private.lessons_sweep();
select is(t.lstep(t.id('never_marked')), 'released', 'released 24 hours after the end (R-HOLD-2)');

select t.due(t.id('late'));
select private.lessons_sweep();
select is(t.lstep(t.id('late')), 'released', 'a late cancel still pays the academy');

-- ─── Reports hold the money ────────────────────────────────────────────────

insert into ids values ('reported', t.paid_slot(72));
select t.as_user('c2000000-0000-0000-0000-000000000005');
select throws_ok($$ select public.lesson_report(t.id('reported'), 'No coach') $$, 'You can report a problem once the lesson starts.', 'not before it starts');
select t.reset();
select t.past(t.id('reported'));
select t.as_user('c2000000-0000-0000-0000-000000000005');
select lives_ok($$ select public.lesson_report(t.id('reported'), 'No coach came') $$, 'the payer reports');
select t.reset();
select t.due(t.id('reported'));
select private.lessons_sweep();
select is(t.lstep(t.id('reported')), 'reported', 'the sweep leaves it held (R-HOLD-5)');
select t.as_user('c2000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.lesson_mark_attendance(t.id('reported'), true) $$, 'This lesson has been settled.', 'the coach can''t mark past it');
select t.reset();

select t.as_user('c2000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.staff_lesson_decide(t.id('reported'), true, 'x') $$, 'Not found.', 'a player can''t decide');
select throws_ok($$ select public.staff_lesson_list() $$, 'Not found.', 'or list');
select t.reset();
select t.as_staff('c2000000-0000-0000-0000-000000000008');
select throws_ok($$ select public.staff_refund_issue(t.lpay(t.id('reported')), 'x') $$, 'Refund lessons in Lessons.', 'lessons aren''t refunded the other way');
select is(public.staff_lesson_list() -> 0 ->> 'step', 'reported', 'reports come first');
select ok(exists (select 1 from jsonb_array_elements(public.staff_held_list()) x where (x ->> 'lesson_booking_id')::uuid = t.id('reported')), 'and it''s on the held list');
select lives_ok($$ select public.staff_lesson_decide(t.id('reported'), true, 'Coach didn''t attend') $$, 'staff refund it');
select throws_ok($$ select public.staff_lesson_decide(t.id('reported'), true, 'again') $$, 'This lesson can''t be refunded now.', 'once');
select throws_ok($$ select public.staff_lesson_decide(t.id('reported'), false, 'again') $$, 'There''s no report on this lesson.', 'and it can''t then be released');
select t.reset();
select is(t.refunded(t.lpay(t.id('reported'))), 5500::bigint, 'everything comes back');
select private.lessons_sweep();
select is((select count(*) from public.ledger_transactions x where x.kind = 'release'
  and x.reference ->> 'payment' = t.lpay(t.id('reported'))::text), 0::bigint, 'and the sweep releases nothing afterwards');
select is(t.lstep(t.id('reported')), 'refunded', 'it stays refunded');
select is((select released_at from public.payments where id = t.lpay(t.id('reported'))), null, 'and was never released');

insert into ids values ('kept', t.paid_slot(72));
select t.past(t.id('kept'));
select t.as_user('c2000000-0000-0000-0000-000000000005');
select public.lesson_report(t.id('kept'), 'Short lesson');
select t.reset();
select t.as_staff('c2000000-0000-0000-0000-000000000008');
select lives_ok($$ select public.staff_lesson_decide(t.id('kept'), false, 'Coach confirmed') $$, 'staff release instead');
select t.reset();
select is(t.lstep(t.id('kept')), 'released', 'the academy is paid');
select t.as_staff('c2000000-0000-0000-0000-000000000008');
select lives_ok($$ select public.staff_lesson_decide(t.id('kept'), true, 'Later found not delivered') $$, 'staff can still refund after release (Q93)');
select t.reset();
select is(t.refunded(t.lpay(t.id('kept'))), 5500::bigint, 'in full');
select ok(t.all_balanced(), 'the ledger balances after a refund from released money');

-- A voided refund goes back to staff, and never strands the money.
insert into ids values ('void_me', t.paid_slot(72));
select t.as_user('c2000000-0000-0000-0000-000000000005');
select public.lesson_cancel(t.id('void_me'));
select t.reset();
select t.settle_refunds(t.lpay(t.id('void_me')), 'failed');
insert into ids select 'void_refund', id from public.refunds where payment_id = t.lpay(t.id('void_me'));
select t.as_staff('c2000000-0000-0000-0000-000000000008');
select lives_ok($$ select public.staff_refund_void(t.id('void_refund'), 'Card closed') $$, 'staff void a failed refund');
select t.reset();
select is(t.lstep(t.id('void_me')), 'reported', 'it comes back for a decision');
select is(t.bal('held', t.id('void_me')), -5000::bigint, 'with the money held again');

-- ─── Late money ────────────────────────────────────────────────────────────

create temp table late_pay (booking uuid, payment uuid) on commit drop;
insert into late_pay select (x ->> 'booking_id')::uuid, (x ->> 'payment_id')::uuid
from t.book('c2000000-0000-0000-0000-000000000005', 'one_to_one', t.slot(72), null, 'c2000000-0000-0000-0000-000000000005', 5500) x;
update public.lesson_bookings set hold_until = now() - interval '1 minute' where id = (select booking from late_pay);
update public.payments set method = 'paynow', hold_until = now() - interval '1 minute' where id = (select payment from late_pay);
select private.lessons_sweep();
select is(t.lstep((select booking from late_pay)), 'expired', 'the sweep ends a lapsed hold');
select is(t.succeed((select payment from late_pay)), 'refunded', 'money after that comes back');
select is(t.refunded((select payment from late_pay)), 5500::bigint, 'in full (Q85)');
select is(t.bal('held', (select booking from late_pay)), 0::bigint, 'with nothing held');

-- ─── Disputes ──────────────────────────────────────────────────────────────

insert into ids values ('disputed', t.paid_slot(72));
select t.past(t.id('disputed'));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_l1', 'charge', 'ch_' || t.lpay(t.id('disputed')), 'amount', 5500));
select t.as_user('c2000000-0000-0000-0000-000000000002');
select lives_ok($$ select public.lesson_mark_attendance(t.id('disputed'), true) $$, 'attendance can be saved during a dispute');
select t.reset();
select is(t.lstep(t.id('disputed')), 'marked', 'but the money waits');
select is(t.bal('held', t.id('disputed')), -5000::bigint, 'held');
select private.lessons_sweep();
select is(t.lstep(t.id('disputed')), 'marked', 'and the sweep waits too');
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_l1', 'status', 'won', 'amount', 5500));
select private.lessons_sweep();
select is(t.lstep(t.id('disputed')), 'released', 'a won dispute lets it go');

insert into ids values ('lost', t.paid_slot(72));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_l2', 'charge', 'ch_' || t.lpay(t.id('lost')), 'amount', 5500));
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_l2', 'status', 'lost', 'amount', 5500));
select is(t.lstep(t.id('lost')), 'cancelled', 'a dispute lost on a lesson not delivered ends it');
select is(t.bal('held', t.id('lost')), 0::bigint, 'with nothing held');
select ok(t.all_balanced(), 'the ledger balances');

insert into ids values ('owed', t.paid_slot(72));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_l3', 'charge', 'ch_' || t.lpay(t.id('owed')), 'amount', 5500));
select t.as_user('c2000000-0000-0000-0000-000000000002');
select public.lesson_academy_cancel(t.id('owed'), 'Coach unwell');
select t.reset();
select is(t.refunded(t.lpay(t.id('owed'))), 0::bigint, 'an open dispute keeps the refund waiting');
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_l3', 'status', 'won', 'amount', 5500));
select is(t.refunded(t.lpay(t.id('owed'))), 5500::bigint, 'then it goes');

-- ─── Slots ─────────────────────────────────────────────────────────────────

select t.as_user('c2000000-0000-0000-0000-000000000002');
insert into ids select 's1', public.lesson_slot_add(t.id('academy'), now() + interval '30 days', 60, 5000, 'Court 1');
select throws_ok($$ select public.lesson_slot_add(t.id('academy'), now() + interval '30 days' + interval '30 minutes', 60, 5000, 'Court 2') $$,
  'You already have a lesson then.', 'a coach can''t be booked twice at once');
select lives_ok($$ select public.lesson_slot_add(t.id('academy'), now() + interval '30 days' + interval '1 hour', 60, 5000, 'Court 2') $$, 'back to back is fine');
select throws_ok($$ select public.lesson_slot_add(t.id('academy'), now() + interval '74 days 23 hours', 120, 5000, '') $$, 'That''s too far ahead.', 'no further than 75 days (R-HOLD-7)');
select t.reset();
select t.as_user('c2000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.lesson_slot_add(t.id('academy'), now() + interval '1 day', 60, 5000, '') $$,
  'Only the academy''s coaches can do this.', 'only a coach publishes');
select ok((select count(*) from jsonb_array_elements(public.lesson_slots_open(t.id('academy')))) >= 1, 'anyone sees open lessons');
select t.reset();

-- An expired licence takes slots off sale.
update public.coach_licences set expires_on = current_date - 1 where user_id = 'c2000000-0000-0000-0000-000000000002';
select t.as_user('c2000000-0000-0000-0000-000000000006');
select is(public.lesson_slots_open(t.id('academy')), '[]'::jsonb, 'an expired coach''s lessons aren''t offered');
select throws_ok($$ select public.lesson_quote('one_to_one', t.id('s1')) $$, 'This lesson is no longer open.', 'or bookable');
select t.reset();
update public.coach_licences set expires_on = current_date + 300 where user_id = 'c2000000-0000-0000-0000-000000000002';

-- A booked slot can't be sold again or withdrawn.
insert into ids select 'b1', (x ->> 'booking_id')::uuid
from t.book('c2000000-0000-0000-0000-000000000005', 'one_to_one', t.id('s1'), null, 'c2000000-0000-0000-0000-000000000005', 5500) x;
select throws_ok($$ select t.book('c2000000-0000-0000-0000-000000000009', 'one_to_one', t.id('s1'), null, 'c2000000-0000-0000-0000-000000000009', 5500) $$,
  'Someone has just booked this lesson.', 'one person per slot');
select t.reset();
select t.as_user('c2000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.lesson_slot_withdraw(t.id('s1')) $$, 'Someone has booked this. Cancel the lesson first.', 'and it can''t be pulled away');
select t.reset();

-- ─── A coach who goes, a class called off, an academy that closes ──────────

select t.succeed(t.lpay(t.id('b1')));
select t.as_user('c2000000-0000-0000-0000-000000000001');
select public.academy_change_class(t.id('class'), 'cancel', 'Hall closed', null);
select t.reset();
insert into ids select 'next_class', id from public.lesson_bookings
where class_id = t.id('class') and (starts_at at time zone 'Asia/Singapore')::date = private.class_next_date((select c from public.academy_classes c where id = t.id('class')));

select t.as_user('c2000000-0000-0000-0000-000000000001');
select lives_ok($$ select public.academy_set_coach(t.id('academy'), 'c2000000-0000-0000-0000-000000000002', false) $$, 'a coach is removed');
select t.reset();
select is(t.lstep(t.id('b1')), 'cancelled', 'their one-to-one is cancelled');
select is(t.refunded(t.lpay(t.id('b1'))), 5500::bigint, 'in full');
select is((select count(*) from public.lesson_slots where coach_id = 'c2000000-0000-0000-0000-000000000002'
  and status = 'open' and starts_at > now()), 0::bigint, 'and their slots are withdrawn');

-- Closing refunds what's to come, and what's been taught still pays.
select t.coach(t.id('academy'), 'c2000000-0000-0000-0000-000000000002')
where not exists (select 1 from public.academy_coaches where user_id = 'c2000000-0000-0000-0000-000000000002');
insert into ids values ('to_come', t.paid_slot(100));
insert into ids values ('done', t.paid_slot(101));
select t.past(t.id('done'));
select t.as_user('c2000000-0000-0000-0000-000000000001');
select lives_ok($$ select public.academy_close(t.id('academy')) $$, 'the academy closes');
select t.reset();
select is(t.lstep(t.id('to_come')), 'cancelled', 'an upcoming lesson is cancelled');
select is(t.refunded(t.lpay(t.id('to_come'))), 5500::bigint, 'in full');
select is(t.lstep(t.id('done')), 'paid', 'a past one stands');
select t.due(t.id('done'));
select private.lessons_sweep();
select is(t.lstep(t.id('done')), 'released', 'and still pays the owner');

-- The sweep carries on past a row that fails.
select ok(t.all_balanced(), 'the ledger balances at the end');

select * from finish();
rollback;
