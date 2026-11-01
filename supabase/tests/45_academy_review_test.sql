-- One test for each problem the 4c reviews found.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
\ir helpers/academy.psql
select no_plan();

update public.feature_flags set enabled = true where key = 'lessons.checkout';

select t.player('c5000000-0000-0000-0000-000000000001');  -- owner
select t.player('c5000000-0000-0000-0000-000000000002');  -- coach
select t.player('c5000000-0000-0000-0000-000000000003');  -- parent
select t.player('c5000000-0000-0000-0000-000000000004', 12);  -- child
select t.player('c5000000-0000-0000-0000-000000000005');  -- adult student
select t.player('c5000000-0000-0000-0000-000000000006');  -- second parent
select t.player('c5000000-0000-0000-0000-000000000007');  -- content staff
select t.player('c5000000-0000-0000-0000-000000000008');  -- payments staff
select t.player('c5000000-0000-0000-0000-000000000009', 15);  -- teen
select t.player('c5000000-0000-0000-0000-00000000000a');  -- outsider
insert into public.staff (user_id, role) values
  ('c5000000-0000-0000-0000-000000000007', 'content'), ('c5000000-0000-0000-0000-000000000008', 'payments');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;

insert into ids select 'academy', t.academy('c5000000-0000-0000-0000-000000000001');
select t.coach(t.id('academy'), 'c5000000-0000-0000-0000-000000000002');
insert into ids select 'class', t.class(t.id('academy'), 'c5000000-0000-0000-0000-000000000002');
update public.academy_classes set trial_price_cents = 1500, dropin_price_cents = 3000 where id = t.id('class');
insert into ids select 'link', t.link('c5000000-0000-0000-0000-000000000003', 'c5000000-0000-0000-0000-000000000004');
select t.link('c5000000-0000-0000-0000-000000000006', 'c5000000-0000-0000-0000-000000000004');
insert into ids select 'child', t.student(t.id('class'), 'c5000000-0000-0000-0000-000000000003', 'c5000000-0000-0000-0000-000000000004');

create function t.slot(p_hours numeric default 72) returns uuid language sql security definer as $$
  update public.lesson_slots set status = 'withdrawn' where status = 'open';
  insert into public.lesson_slots (academy_id, coach_id, starts_at, ends_at, price_minor)
  values (t.id('academy'), 'c5000000-0000-0000-0000-000000000002', now() + make_interval(secs => p_hours * 3600),
    now() + make_interval(secs => p_hours * 3600 + 3600), 5000)
  returning id;
$$;
create function t.booked(p_hours numeric default 72, p_pay boolean default true) returns uuid language plpgsql as $$
declare
  v jsonb;
  s uuid := t.slot(p_hours);
begin
  perform t.as_user('c5000000-0000-0000-0000-000000000005');
  v := public.lesson_reserve('one_to_one', s, null, auth.uid(), 'key-' || gen_random_uuid(), 5500);
  perform t.reset();
  if p_pay then perform t.succeed((v ->> 'payment_id')::uuid); end if;
  return (v ->> 'booking_id')::uuid;
end;
$$;
create function t.lpay(p_booking uuid) returns uuid language sql security definer as $$
  select id from public.payments where lesson_booking_id = p_booking;
$$;
create function t.lstep(p_booking uuid) returns text language sql security definer as $$
  select step from public.lesson_bookings where id = p_booking;
$$;
create function t.gone(p_booking uuid) returns void language plpgsql as $$
begin
  alter table public.lesson_bookings disable trigger lesson_bookings_guard;
  update public.lesson_bookings set starts_at = now() - interval '2 hours', ends_at = now() - interval '1 hour',
    release_at = now() + interval '23 hours' where id = p_booking;
  alter table public.lesson_bookings enable trigger lesson_bookings_guard;
end;
$$;
grant execute on all functions in schema t to anon, authenticated, service_role;

-- ─── A refused coach can't restore their own access ────────────────────────

insert into storage.objects (bucket_id, name) values ('verification-docs', 'c5000000-0000-0000-0000-000000000002/licence.jpg');
select t.as_staff('c5000000-0000-0000-0000-000000000007');
select public.staff_licence_decide('c5000000-0000-0000-0000-000000000002', false, 'Fake licence');
select t.reset();
select t.as_user('c5000000-0000-0000-0000-000000000002');
select lives_ok($$ select public.coach_licence_submit('NROC-9', current_date + 90, 'c5000000-0000-0000-0000-000000000002/licence.jpg') $$, 'a refused coach can send a new licence');
select throws_ok($$ select public.academy_roster(t.id('class')) $$, 'We need to verify your coaching licence first.', 'but sees no children until staff verify it');
select throws_ok($$ select public.academy_student(t.id('child')) $$, 'This student has left.', 'or any one child');
select t.reset();
select t.as_staff('c5000000-0000-0000-0000-000000000007');
select public.staff_licence_decide('c5000000-0000-0000-0000-000000000002', true, 'Real this time');
select t.reset();
select t.as_user('c5000000-0000-0000-0000-000000000002');
select lives_ok($$ select public.academy_roster(t.id('class')) $$, 'and is back once they do');
select t.reset();

-- ─── Nobody learns who has an account or who is a minor ────────────────────

update public.account_private set email = 'known@test.local', email_verified_at = now() where id = 'c5000000-0000-0000-0000-00000000000a';
update public.account_private set email = 'teen@test.local', email_verified_at = now() where id = 'c5000000-0000-0000-0000-000000000009';
select t.as_user('c5000000-0000-0000-0000-000000000005');
insert into ids select 'new', public.academy_create('{"name": "Probe", "coaches": ["known@test.local", "teen@test.local", "nobody@test.local"]}');
select is((select array_agg(x order by x) from jsonb_array_elements_text(public.academy_get(t.id('new')) -> 'invited') x),
  array['known@test.local', 'nobody@test.local', 'teen@test.local'],
  'every email reads the same, account or not, adult or not');
select is((select count(*) from jsonb_array_elements(public.academy_verification(t.id('new')) -> 'coaches')), 1::bigint, 'and nobody unanswered shows on the checklist');
select throws_ok($$ select public.academy_create('{"name": "Too many", "coaches": ["a@b.c","a@b.d","a@b.e","a@b.f","a@b.g","a@b.h","a@b.i","a@b.j","a@b.k","a@b.l","a@b.m","a@b.n","a@b.o","a@b.p","a@b.q","a@b.r","a@b.s","a@b.t","a@b.u","a@b.v","a@b.w"]}') $$,
  'Invite up to 20 coaches at a time.', 'a list has a limit');
select throws_ok($$ select public.academy_set_coach(t.id('new'), 'c5000000-0000-0000-0000-000000000009', true) $$, 'No player has that username.', 'a minor reads as nobody');
select t.reset();
select is((select count(*) from public.notifications where user_id in ('c5000000-0000-0000-0000-00000000000a', 'c5000000-0000-0000-0000-000000000009')), 0::bigint, 'and a stranger gets nothing from a list of emails');

select t.as_user('c5000000-0000-0000-0000-00000000000a');
select public.academy_claim_invites();
select is(public.academy_my_coach_invites() -> 0 ->> 'name', 'Probe', 'an adult sees it when they next look');
select t.reset();
select t.as_user('c5000000-0000-0000-0000-000000000009');
select public.academy_claim_invites();
select is(public.academy_my_coach_invites(), '[]'::jsonb, 'a minor doesn''t');
select t.reset();
select t.as_user('c5000000-0000-0000-0000-000000000005');
select is((select count(*) from jsonb_array_elements_text(public.academy_get(t.id('new')) -> 'invited')), 3::bigint, 'after they look, all three emails still read the same');
select is(public.academy_get(t.id('new')) -> 'pending_coaches', '[]'::jsonb, 'with no username against any');
select t.reset();
select t.as_user('c5000000-0000-0000-0000-00000000000a');
select public.academy_coach_answer(t.id('new'), false);
select t.reset();
select t.as_user('c5000000-0000-0000-0000-000000000005');
select is((select count(*) from jsonb_array_elements_text(public.academy_get(t.id('new')) -> 'invited')), 2::bigint, 'an answer ends the invitation');
select t.reset();

-- ─── What a coach writes is checked ────────────────────────────────────────

select t.as_user('c5000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.academy_parent_note(t.id('child'), '{}', 'text me on 91234567') $$, 'Please change the wording.', 'a note to a family');
select throws_ok($$ select public.academy_save_session(t.id('class'), '{}', '{}', 'text me on 91234567') $$, 'Please change the wording.', 'a session note');
select throws_ok($$ select public.academy_change_class(t.id('class'), 'time', 'text me on 91234567', null) $$, 'Please change the wording.', 'a class notice');
select t.reset();

-- ─── Notices go to today's guardians ───────────────────────────────────────

update public.guardian_links set status = 'revoked' where id = t.id('link');
select t.as_user('c5000000-0000-0000-0000-000000000002');
select public.academy_parent_note(t.id('child'), '{}', 'A good week');
select t.reset();
select is((select count(*) from public.notifications where user_id = 'c5000000-0000-0000-0000-000000000003' and title like 'A note about%'), 0::bigint, 'a revoked parent hears nothing');
select is((select count(*) from public.notifications where user_id = 'c5000000-0000-0000-0000-000000000006' and title like 'A note about%'), 1::bigint, 'the other parent does');
update public.guardian_links set status = 'approved' where id = t.id('link');

-- ─── Invitations ───────────────────────────────────────────────────────────

update public.account_private set mobile = '+6591112222' where id = 'c5000000-0000-0000-0000-000000000009';
update public.account_private set mobile = '+6591113333' where id = 'c5000000-0000-0000-0000-00000000000a';
update public.account_private set mobile = '+6491113333' where id = 'c5000000-0000-0000-0000-000000000006';
select t.as_user('c5000000-0000-0000-0000-000000000002');
select public.academy_invite(t.id('class'), '9111 2222');
select public.academy_invite(t.id('class'), '9111 3333');
select t.reset();
select is((select count(*) from public.notifications where user_id = 'c5000000-0000-0000-0000-000000000009' and title like 'You''re invited%'), 0::bigint, 'a child is never messaged by a coach');
select is((select count(*) from public.notifications where user_id = 'c5000000-0000-0000-0000-00000000000a' and title like 'You''re invited%'), 1::bigint, 'an adult with that exact number is');
select is((select count(*) from public.notifications where user_id = 'c5000000-0000-0000-0000-000000000006' and title like 'You''re invited%'), 0::bigint, 'not someone sharing its last 8 digits');

-- ─── Files ─────────────────────────────────────────────────────────────────

select ok(exists (select 1 from pg_policies where schemaname = 'storage' and policyname = 'Owners upload their own verification files'
  and with_check like '%is_restricted%' and with_check like '%is_suspended%'), 'restricted and suspended accounts can''t upload');
select t.as_staff('c5000000-0000-0000-0000-000000000007');
select lives_ok($$ select public.staff_doc_viewed('licence', 'c5000000-0000-0000-0000-000000000002', 'Reviewing') $$, 'opening a file');
select t.reset();
select ok(exists (select 1 from public.admin_audit a where a.action = 'verification_file_viewed'), 'is audited');

select ok(private.doc_in_use('c5000000-0000-0000-0000-000000000002/licence.jpg'), 'a file under review or verified is locked');
select ok(not private.doc_in_use('c5000000-0000-0000-0000-000000000005/licence.jpg'), 'one that isn''t can be replaced');

-- ─── Rejecting a verified academy ends its lessons ─────────────────────────

insert into ids values ('upcoming', t.booked());
insert into ids values ('unpaid', t.booked(80, false));
select t.as_staff('c5000000-0000-0000-0000-000000000007');
select public.staff_academy_decide(t.id('academy'), false, 'Licence withdrawn');
select t.reset();
select is(t.lstep(t.id('upcoming')), 'cancelled', 'a paid lesson is cancelled');
select is(t.refunded(t.lpay(t.id('upcoming'))), 5500::bigint, 'in full');
select is(t.succeed(t.lpay(t.id('unpaid'))), 'refunded', 'and money on its way goes back');
update public.academies set verification = 'verified' where id = t.id('academy');

-- ─── Expired, then a failed late refund ────────────────────────────────────

insert into ids values ('lapsed', t.booked(90, false));
update public.lesson_bookings set hold_until = now() - interval '1 minute' where id = t.id('lapsed');
update public.payments set method = 'paynow', hold_until = now() - interval '1 minute' where id = t.lpay(t.id('lapsed'));
select private.lessons_sweep();
select t.succeed(t.lpay(t.id('lapsed')));
select t.settle_refunds(t.lpay(t.id('lapsed')), 'failed');
insert into ids select 'lapsed_refund', id from public.refunds where payment_id = t.lpay(t.id('lapsed'));
select t.as_staff('c5000000-0000-0000-0000-000000000008');
select public.staff_refund_void(t.id('lapsed_refund'), 'Card closed');
select t.reset();
select is(t.lstep(t.id('lapsed')), 'reported', 'a voided refund on an expired booking comes back to staff');
select t.as_staff('c5000000-0000-0000-0000-000000000008');
select throws_ok($$ select public.staff_lesson_decide(t.id('lapsed'), false, 'Pay them') $$,
  'This lesson wasn''t taught, so the money goes back.', 'and can''t be paid to the academy');
select lives_ok($$ select public.staff_lesson_decide(t.id('lapsed'), true, 'Send it back') $$, 'staff send it back');
select t.reset();
select is(t.refunded(t.lpay(t.id('lapsed'))), 5500::bigint, 'all of it, as the late refund was');
select is(t.bal('held', t.id('lapsed')), 0::bigint, 'with nothing held');

-- ─── A void after the place was sold again ─────────────────────────────────

insert into ids values ('first', t.booked());
select t.as_user('c5000000-0000-0000-0000-000000000005');
select public.lesson_cancel(t.id('first'));
select t.reset();
insert into ids select 'resold', id from public.lesson_slots where id = (select slot_id from public.lesson_bookings where id = t.id('first'));
select t.as_user('c5000000-0000-0000-0000-00000000000a');
insert into ids select 'second', (public.lesson_reserve('one_to_one', t.id('resold'), null, auth.uid(), 'key-resold-1', 5500) ->> 'booking_id')::uuid;
select t.reset();
select t.settle_refunds(t.lpay(t.id('first')), 'failed');
insert into ids select 'first_refund', id from public.refunds where payment_id = t.lpay(t.id('first'));
select t.as_staff('c5000000-0000-0000-0000-000000000008');
select lives_ok($$ select public.staff_refund_void(t.id('first_refund'), 'Card closed') $$, 'a void works after the place is sold again');
select lives_ok($$ select public.staff_lesson_decide(t.id('first'), true, 'Send it back') $$, 'and staff can finish it');
select t.reset();
select is(t.refunded(t.lpay(t.id('first'))), 5000::bigint, 'without adding the fee the payer''s cancel kept');

-- ─── Disputes and staff refunds ────────────────────────────────────────────

-- Staff refund queued against a dispute, then lost: the academy gives it back.
insert into ids values ('queued', t.booked());
alter table public.lesson_bookings disable trigger lesson_bookings_guard;
update public.lesson_bookings set starts_at = now() - interval '2 hours', ends_at = now() - interval '1 hour' where id = t.id('queued');
alter table public.lesson_bookings enable trigger lesson_bookings_guard;
select t.as_user('c5000000-0000-0000-0000-000000000002');
select public.lesson_mark_attendance(t.id('queued'), true);
select t.reset();
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_q', 'charge', 'ch_' || t.lpay(t.id('queued')), 'amount', 5500));
select t.as_staff('c5000000-0000-0000-0000-000000000008');
select public.staff_lesson_decide(t.id('queued'), true, 'Not delivered');
select t.reset();
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_q', 'status', 'lost', 'amount', 5500));
select ok(exists (select 1 from public.ledger_transactions x where x.kind = 'dispute_owed' and x.reference ->> 'payment' = t.lpay(t.id('queued'))::text),
  'a refund queued on a lost dispute comes back from the academy');

-- Lost first, then staff try to refund.
insert into ids values ('lost_first', t.booked());
select t.gone(t.id('lost_first'));
select t.as_user('c5000000-0000-0000-0000-000000000002');
select public.lesson_mark_attendance(t.id('lost_first'), true);
select t.reset();
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_r', 'charge', 'ch_' || t.lpay(t.id('lost_first')), 'amount', 5500));
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_r', 'status', 'lost', 'amount', 5500));
select t.as_staff('c5000000-0000-0000-0000-000000000008');
select throws_ok($$ select public.staff_lesson_decide(t.id('lost_first'), true, 'Too late') $$,
  'The bank has returned money on this payment. Work it out in Payments.', 'staff can''t promise a refund the bank has already made');
select t.reset();
select is(t.lstep(t.id('lost_first')), 'released', 'and the lesson stays as it was');

-- Part of a payment lost, then the academy cancels.
insert into ids values ('part', t.booked());
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_p', 'charge', 'ch_' || t.lpay(t.id('part')), 'amount', 2000));
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_p', 'status', 'lost', 'amount', 2000));
select t.as_user('c5000000-0000-0000-0000-000000000002');
select public.lesson_academy_cancel(t.id('part'), 'Coach unwell');
select t.reset();
select is(t.lstep(t.id('part')), 'reported', 'a part-lost payment goes to staff');
select is(t.refunded(t.lpay(t.id('part'))), 0::bigint, 'rather than refunding more than was left');
select t.as_staff('c5000000-0000-0000-0000-000000000008');
select throws_ok($$ select public.staff_lesson_decide(t.id('part'), false, 'Pay') $$,
  'This lesson wasn''t taught, so the money goes back.', 'a cancelled lesson can''t be paid out');
select lives_ok($$ select public.staff_lesson_decide(t.id('part'), true, 'What''s left') $$, 'staff send back what''s left');
select t.reset();
select is(t.refunded(t.lpay(t.id('part'))), 3500::bigint, 'S$55.00 less the S$20.00 the bank returned');
select is(t.bal('held', t.id('part')), 0::bigint, 'with nothing held');

-- A refund queued while a dispute is open, then only part of it lost.
insert into ids values ('part_open', t.booked());
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_o', 'charge', 'ch_' || t.lpay(t.id('part_open')), 'amount', 2000));
select t.as_user('c5000000-0000-0000-0000-000000000002');
select public.lesson_academy_cancel(t.id('part_open'), 'Coach unwell');
select t.reset();
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_o', 'status', 'lost', 'amount', 2000));
select is(t.refunded(t.lpay(t.id('part_open'))), 0::bigint, 'the queued full refund isn''t sent');
select is(t.lstep(t.id('part_open')), 'reported', 'it goes to staff');

-- ─── The screen's promise holds ────────────────────────────────────────────

insert into ids values ('promise', t.booked(23.5));
select t.as_user('c5000000-0000-0000-0000-000000000005');
select throws_ok($$ select public.lesson_cancel(t.id('promise'), null, 5000) $$,
  'The time to cancel for a refund has passed. Check and try again.', 'a refund promised then lost refuses the cancel');
select t.reset();
select is(t.lstep(t.id('promise')), 'paid', 'and nothing happens');

-- ─── Lessons that can't be taught aren't sold ──────────────────────────────

update public.coach_licences set expires_on = current_date - 1 where user_id = 'c5000000-0000-0000-0000-000000000002';
select t.as_user('c5000000-0000-0000-0000-000000000005');
select throws_ok($$ select public.lesson_quote('class', t.id('class'), t.class_at(3)) $$, 'This class has no coach yet.', 'an expired class coach sells nothing');
select t.reset();
update public.coach_licences set expires_on = current_date + 300 where user_id = 'c5000000-0000-0000-0000-000000000002';
insert into public.account_moderation (user_id, suspended_until) values ('c5000000-0000-0000-0000-000000000002', now() + interval '1 day');
select t.as_user('c5000000-0000-0000-0000-000000000005');
select throws_ok($$ select public.lesson_quote('class', t.id('class'), t.class_at(3)) $$, 'This lesson isn''t available.', 'nor a suspended coach');
select t.reset();
delete from public.account_moderation where user_id = 'c5000000-0000-0000-0000-000000000002';

-- A licence refused ends class lessons too.
select t.as_user('c5000000-0000-0000-0000-000000000005');
select public.lesson_reserve('class', t.id('class'), t.class_at(6), auth.uid(), 'key-class-1', 3300);
select t.reset();
select t.as_staff('c5000000-0000-0000-0000-000000000007');
select public.staff_licence_decide('c5000000-0000-0000-0000-000000000002', false, 'Struck off');
select t.reset();
select is((select step from public.lesson_bookings where idempotency_key = 'key-class-1'), 'cancelled', 'a refused licence ends class bookings');
select t.licence('c5000000-0000-0000-0000-000000000002');

-- A cancelled one-to-one isn't sold again.
insert into ids values ('coach_off', t.booked());
select t.as_user('c5000000-0000-0000-0000-000000000002');
select public.lesson_academy_cancel(t.id('coach_off'), 'Coach unwell');
select t.reset();
select is((select status from public.lesson_slots where id = (select slot_id from public.lesson_bookings where id = t.id('coach_off'))), 'withdrawn', 'the time comes off sale');

-- ─── Slots in Singapore time ───────────────────────────────────────────────

select t.as_user('c5000000-0000-0000-0000-000000000005');
select is(((public.academy_class_slots(t.id('academy'), 'class') -> 0 ->> 'at')::timestamptz at time zone 'Asia/Singapore')::time, time '10:00', 'class times are Singapore''s');
select t.reset();
update public.academy_classes set trial_price_cents = null where id = t.id('class');
select t.as_user('c5000000-0000-0000-0000-000000000005');
select is(public.academy_class_slots(t.id('academy'), 'trial'), '[]'::jsonb, 'with lessons paid, an unpriced trial isn''t offered');
select t.reset();
update public.feature_flags set enabled = false where key = 'lessons.checkout';
select t.as_user('c5000000-0000-0000-0000-000000000005');
select ok(jsonb_array_length(public.academy_class_slots(t.id('academy'), 'trial')) > 0, 'with them off, it is, for free');
select is(public.academy_class_slots(t.id('new'), 'trial'), '[]'::jsonb, 'an unverified academy offers nothing, even to its owner');
select t.reset();

-- ─── Earnings ──────────────────────────────────────────────────────────────

select is(private.payment_earned((select p from public.payments p where id = t.lpay(t.id('queued')))), 0::bigint, 'nothing is earned on refunded money');
select ok(t.all_balanced(), 'the ledger balances');

select * from finish();
rollback;
