-- P4a-04: reserve, webhook, hold, late money. The webhook is the only thing
-- that confirms a payment.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('c0000000-0000-0000-0000-000000000001');  -- host
select t.player('c0000000-0000-0000-0000-000000000002');  -- player
select t.player('c0000000-0000-0000-0000-000000000003');  -- second player
select t.player('c0000000-0000-0000-0000-000000000004');  -- third player
select t.player('c0000000-0000-0000-0000-000000000005', 12);  -- unlinked child

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;

insert into ids values ('m', t.paid_meet('c0000000-0000-0000-0000-000000000001', 600, 2));

-- Joining a paid Meet goes through a payment.
select t.as_user('c0000000-0000-0000-0000-000000000002');
select throws_ok($$select public.join_activity(t.id('m'))$$, 'P0001', 'payment_required', 'join alone refuses a paid Meet');
select t.reset();

create temp table r1 on commit drop as
  select t.reserve('c0000000-0000-0000-0000-000000000002', t.id('m'), 'double-tap-key') as v;
grant select on r1 to anon, authenticated;
select is((select v ->> 'result' from r1), 'reserved', 'reserve holds a spot');
select is((select (v ->> 'amount_minor')::int from r1), 800, 'S$6.00 charges S$8.00');
select is((select v ->> 'refund_rule' from r1), private.refund_rule_text('meet'), 'the rule shown is kept (R-REF-20)');
select is(t.status_of(t.id('m'), 'c0000000-0000-0000-0000-000000000002'), 'reserved', 'the player is reserved, not joined');
select is(public.activity_spots_taken(t.id('m')), 1, 'a hold counts as taken');
select is(private.spots_joined(t.id('m')), 0, 'a hold isn''t a player yet');
select ok((select abs(extract(epoch from (v ->> 'hold_until')::timestamptz - now() - interval '10 minutes')) < 5 from r1),
  'the hold is 10 minutes');

-- Double tap.
select is(t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000002', t.id('m'), 'double-tap-key')),
  (select t.payment_id(v) from r1), 'the same key returns the same payment');
select is(t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000002', t.id('m'), 'another-key-1')),
  (select t.payment_id(v) from r1), 'a new key returns the live payment');
select is((select count(*)::int from public.payments where activity_id = t.id('m')), 1, 'one payment');

-- A client can't confirm its own payment.
select t.as_user('c0000000-0000-0000-0000-000000000002');
select throws_ok(format($$update public.payments set status = 'succeeded' where id = %L$$, (select t.payment_id(v) from r1)),
  '42501', null, 'the app can''t confirm a payment');
select t.reset();
select is(t.status_of(t.id('m'), 'c0000000-0000-0000-0000-000000000002'), 'reserved', 'still only reserved');

-- payment_begin.
select t.as_user('c0000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.payment_begin(%L, 'card')$$, (select t.payment_id(v) from r1)),
  '%isn''t yours%', 'nobody else can start it');
select t.reset();
select t.as_user('c0000000-0000-0000-0000-000000000002');
select is(public.payment_begin((select t.payment_id(v) from r1), 'paynow') ->> 'method', 'paynow', 'PayNow chosen');
select throws_like(format($$select public.payment_begin(%L, 'card')$$, (select t.payment_id(v) from r1)),
  '%started%', 'the method can''t switch, so one payment can''t be paid twice');
select throws_like(format($$select public.payment_begin(%L, 'wallet')$$, (select t.payment_id(v) from r1)),
  '%how to pay%', 'there is no Wallet');
select t.reset();

-- Failure isn't final.
select t.event('payment_intent.payment_failed', jsonb_build_object('id', 'pi_x', 'failure_code', 'card_declined',
  'metadata', jsonb_build_object('payment_id', (select t.payment_id(v) from r1))));
select is(t.status_pay((select t.payment_id(v) from r1)), 'pending', 'a failed attempt keeps the payment open');
select is(t.status_of(t.id('m'), 'c0000000-0000-0000-0000-000000000002'), 'reserved', 'and the spot');

-- Webhook, including a replay.
select is(t.succeed((select t.payment_id(v) from r1), 'paynow', 'evt_once_1'), 'seated', 'payment_intent.succeeded seats them');
select is(t.status_of(t.id('m'), 'c0000000-0000-0000-0000-000000000002'), 'joined', 'the player is in');
select is(t.status_pay((select t.payment_id(v) from r1)), 'succeeded', 'the payment succeeded');
select is(t.bal('held', t.id('m')), -600::bigint, 'the price is held');
select is((select count(*)::int from public.ledger_transactions
  where idempotency_key = 'capture:' || (select t.payment_id(v) from r1)), 1, 'one capture entry');
select is(t.succeed((select t.payment_id(v) from r1), 'paynow', 'evt_once_1'), 'duplicate', 'the same event replayed does nothing');
select is(t.succeed((select t.payment_id(v) from r1), 'paynow'), 'duplicate', 'a new event for the same payment does nothing');
select is(t.bal('held', t.id('m')), -600::bigint, 'the price is held once');
select is((select count(*)::int from public.ledger_transactions
  where idempotency_key = 'capture:' || (select t.payment_id(v) from r1)), 1, 'still one capture entry');
select is((select count(*)::int from public.ledger_transactions
  where reference ->> 'payment' = (select t.payment_id(v) from r1)::text), 1, 'nothing else was posted');
select is(t.event('payment_intent.payment_failed', jsonb_build_object('id', 'pi_x', 'failure_code', 'late',
  'metadata', jsonb_build_object('payment_id', (select t.payment_id(v) from r1)))), 'failed', 'a failure after success arrives');
select is(t.status_pay((select t.payment_id(v) from r1)), 'succeeded', 'and changes nothing');

-- Last spot, then waitlist.
insert into ids values ('p3', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000003', t.id('m'))));
select is(public.activity_spots_taken(t.id('m')), 2, 'the Meet is full with a hold');
select is(t.reserve('c0000000-0000-0000-0000-000000000004', t.id('m')) ->> 'result', 'waitlist', 'the next player goes on the waitlist');
select is(t.status_of(t.id('m'), 'c0000000-0000-0000-0000-000000000004'), 'waitlist', 'with no charge');
select is((select count(*)::int from public.payments where activity_id = t.id('m')
  and user_id = 'c0000000-0000-0000-0000-000000000004'), 0, 'and no payment');

-- Expired hold frees the spot and makes an offer. Nobody is charged.
update public.activity_participants set hold_until = now() - interval '1 second'
where activity_id = t.id('m') and user_id = 'c0000000-0000-0000-0000-000000000003';
update public.payments set hold_until = now() - interval '1 second' where id = t.id('p3');
select public.activity_spots_taken(t.id('m'));
select is(public.activity_spots_taken(t.id('m')), 1, 'an expired hold stops counting');
select private.holds_sweep();
select is(t.status_of(t.id('m'), 'c0000000-0000-0000-0000-000000000003'), 'cancelled', 'the sweep frees the spot');
select is(t.status_pay(t.id('p3')), 'cancelled', 'and ends a payment nobody started');
select is(t.status_of(t.id('m'), 'c0000000-0000-0000-0000-000000000004'), 'offered', 'the next player gets an offer');
select ok(exists (select 1 from public.notifications where user_id = 'c0000000-0000-0000-0000-000000000004'
  and title = 'A spot opened'), 'and is told');
select is(public.activity_spots_taken(t.id('m')), 2, 'an offer holds the seat');

-- The offer can be taken.
insert into ids values ('p4', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000004', t.id('m'))));
select is(t.status_of(t.id('m'), 'c0000000-0000-0000-0000-000000000004'), 'reserved', 'taking the offer reserves');
select is(t.succeed(t.id('p4')), 'seated', 'paying takes the seat');
select is(public.activity_spots_taken(t.id('m')), 2, 'the Meet is full');

-- Late money with a seat free.
insert into ids values ('m2', t.paid_meet('c0000000-0000-0000-0000-000000000001', 600, 2));
insert into ids values ('late1', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000002', t.id('m2'))));
update public.payments set method = 'paynow', stripe_intent_id = 'pi_late1' where id = t.id('late1');
update public.activity_participants set hold_until = now() - interval '1 second'
where activity_id = t.id('m2') and user_id = 'c0000000-0000-0000-0000-000000000002';
update public.payments set hold_until = now() - interval '1 second' where id = t.id('late1');
select private.holds_sweep();
select is(t.status_pay(t.id('late1')), 'cancel_requested', 'an intent in flight has to be cancelled');
select is(t.succeed(t.id('late1'), 'paynow'), 'seated', 'money after the hold takes a free seat');
select is(t.status_of(t.id('m2'), 'c0000000-0000-0000-0000-000000000002'), 'joined', 'the player is in');
select is(t.refunded(t.id('late1')), 0::bigint, 'nothing refunded');

-- Late money with no seat: a full refund, fee included.
insert into ids values ('late2', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000003', t.id('m2'))));
update public.payments set method = 'paynow', stripe_intent_id = 'pi_late2', hold_until = now() - interval '1 second' where id = t.id('late2');
update public.activity_participants set hold_until = now() - interval '1 second'
where activity_id = t.id('m2') and user_id = 'c0000000-0000-0000-0000-000000000003';
select private.holds_sweep();
insert into ids values ('p5', t.paid('c0000000-0000-0000-0000-000000000004', t.id('m2')));
select is(t.succeed(t.id('late2'), 'paynow'), 'refunded', 'late money with the seat gone is refunded');
select is(t.refunded(t.id('late2')), 800::bigint, 'in full');
select is((select reason from public.refunds where payment_id = t.id('late2')), 'late_no_spot', 'for the right reason');
select is((select organizer_pays_fee from public.refunds where payment_id = t.id('late2')), false, 'the organizer pays no card fee');
select is(t.status_of(t.id('m2'), 'c0000000-0000-0000-0000-000000000003'), 'cancelled', 'no seat');
select ok(exists (select 1 from public.notifications where user_id = 'c0000000-0000-0000-0000-000000000003'
  and title = 'Your payment is coming back'), 'and they''re told');

-- Late money doesn't jump the queue.
insert into ids values ('m3', t.paid_meet('c0000000-0000-0000-0000-000000000001', 600, 2));
insert into ids values ('late3', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000002', t.id('m3'))));
update public.payments set method = 'card', stripe_intent_id = 'pi_late3', hold_until = now() - interval '1 second' where id = t.id('late3');
update public.activity_participants set hold_until = now() - interval '1 second'
where activity_id = t.id('m3') and user_id = 'c0000000-0000-0000-0000-000000000002';
select t.reserve('c0000000-0000-0000-0000-000000000003', t.id('m3'));
update public.activity_participants set status = 'waitlist', hold_until = null, queue_seq = 1
where activity_id = t.id('m3') and user_id = 'c0000000-0000-0000-0000-000000000003';
update public.payments set status = 'cancelled' where activity_id = t.id('m3') and user_id = 'c0000000-0000-0000-0000-000000000003';
select is(t.succeed(t.id('late3'), 'card'), 'refunded', 'late money waits behind the queue, so it''s refunded');

-- Cancelled while paying: full refund, and the organizer bears the card fee.
insert into ids values ('m4', t.paid_meet('c0000000-0000-0000-0000-000000000001'));
insert into ids values ('p6', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000002', t.id('m4'))));
update public.payments set method = 'card', stripe_intent_id = 'pi_p6' where id = t.id('p6');
select t.as_user('c0000000-0000-0000-0000-000000000001');
select public.cancel_activity(t.id('m4'), false, null);
select t.reset();
select is(t.status_pay(t.id('p6')), 'cancel_requested', 'cancelling asks Stripe to stop the payment');
select is(t.succeed(t.id('p6'), 'card'), 'refunded', 'money that lands anyway goes back');
select is(t.refunded(t.id('p6')), 800::bigint, 'in full');
select is((select reason from public.refunds where payment_id = t.id('p6')), 'organizer_cancelled', 'as an organizer cancellation');

-- Blocked mid-payment.
insert into ids values ('m5', t.paid_meet('c0000000-0000-0000-0000-000000000001'));
insert into ids values ('p7', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000002', t.id('m5'))));
insert into public.blocks (blocker_id, blocked_id)
values ('c0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002');
select is(t.succeed(t.id('p7')), 'refunded', 'a player blocked while paying is refunded');
select is(t.refunded(t.id('p7')), 800::bigint, 'in full');
delete from public.blocks where blocker_id = 'c0000000-0000-0000-0000-000000000001';

-- Suspended mid-payment.
insert into ids values ('m6', t.paid_meet('c0000000-0000-0000-0000-000000000001'));
insert into ids values ('p8', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000003', t.id('m6'))));
insert into public.account_moderation (user_id, suspended_until)
values ('c0000000-0000-0000-0000-000000000003', now() + interval '1 day');
select is(t.succeed(t.id('p8')), 'refunded', 'a player suspended while paying is refunded');
delete from public.account_moderation where user_id = 'c0000000-0000-0000-0000-000000000003';

-- Money that doesn't match goes to suspense, not nowhere.
insert into ids values ('m7', t.paid_meet('c0000000-0000-0000-0000-000000000001'));
insert into ids values ('p9', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000004', t.id('m7'))));
select is(t.event('payment_intent.succeeded', jsonb_build_object('id', 'pi_short_9', 'amount', 100, 'currency', 'sgd',
  'latest_charge', 'ch_short', 'metadata', jsonb_build_object('payment_id', t.id('p9')))), 'suspense', 'a wrong amount goes to suspense');
select is(t.status_pay(t.id('p9')), 'pending', 'and confirms nothing');
select ok(exists (select 1 from public.money_alerts where key = 'suspense:pi_short_9'), 'and raises an alert');
select is(t.event('payment_intent.succeeded', jsonb_build_object('id', 'pi_stray_1', 'amount', 500, 'currency', 'sgd',
  'latest_charge', 'ch_stray', 'metadata', jsonb_build_object('payment_id', gen_random_uuid()))), 'suspense', 'money for no payment goes to suspense');
select ok(exists (select 1 from public.money_alerts where key = 'suspense:pi_stray_1'), 'and raises an alert');
update public.payments set stripe_intent_id = 'pi_first' where id = t.id('p9');
select is(t.event('payment_intent.succeeded', jsonb_build_object('id', 'pi_second', 'amount', 800, 'currency', 'sgd',
  'latest_charge', 'ch_second', 'metadata', jsonb_build_object('payment_id', t.id('p9')))), 'suspense', 'a second intent paying twice goes to suspense');

-- Webhook first: create-payment-intent attaches afterwards.
insert into ids values ('m8', t.paid_meet('c0000000-0000-0000-0000-000000000001'));
insert into ids values ('p10', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000002', t.id('m8'))));
select is(t.succeed(t.id('p10')), 'seated', 'the webhook can arrive first');
select public.money_svc_attach_intent(t.id('p10'), 'pi_later');
select is((select stripe_intent_id from public.payments where id = t.id('p10')), 'pi_' || t.id('p10'), 'the late attach changes nothing');

-- Abandoning.
insert into ids values ('p11', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000003', t.id('m8'))));
select t.as_user('c0000000-0000-0000-0000-000000000003');
select public.payment_abandon(t.id('p11'));
select t.reset();
select is(t.status_of(t.id('m8'), 'c0000000-0000-0000-0000-000000000003'), 'cancelled', 'giving up frees the spot');
select is(t.status_pay(t.id('p11')), 'cancelled', 'and ends the payment');

-- The price is fixed once money exists.
select t.as_user('c0000000-0000-0000-0000-000000000001');
select throws_like(format($$update public.activities set fee_cents = 100 where id = %L$$, t.id('m8')), '%already paid%',
  'the host can''t change the price after people pay');
select throws_like(format($$update public.activities set players_pay_fee = true where id = %L$$, t.id('m8')), '%already paid%',
  'or who pays the fee');
select throws_like(format($$update public.activities set starts_at = starts_at - interval '1 hour' where id = %L$$, t.id('m8')),
  '%only move later%', 'or move it earlier');
select lives_ok(format($$update public.activities set starts_at = starts_at + interval '1 day', ends_at = ends_at + interval '1 day' where id = %L$$, t.id('m8')),
  'it can move later');
select t.reset();
select ok((select money_changed_at is not null from public.activities where id = t.id('m8')), 'and that opens the refund window');

-- Who can't reserve.
select t.as_user('c0000000-0000-0000-0000-000000000005');
select throws_like(format($$select public.activity_reserve(%L, 'child-key-1')$$, t.id('m8')), '%parent%', 'a restricted child can''t');
select t.reset();
select t.as_anon();
select throws_ok(format($$select public.activity_reserve(%L, 'anon-key-01')$$, t.id('m8')), '42501', null, 'signed out can''t');
select t.reset();
select t.as_user('c0000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.activity_reserve(%L, 'x')$$, t.id('m8')), '%Try that again%', 'a key is required');
select t.reset();

insert into ids values ('m9', t.paid_meet('c0000000-0000-0000-0000-000000000001'));
update public.activities set approval_required = true where id = t.id('m9');
select t.as_user('c0000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.activity_reserve(%L, 'approval-key')$$, t.id('m9')), '%need approval%', 'paid plus approval is refused for now');
select t.reset();

insert into ids values ('m10', t.paid_meet('c0000000-0000-0000-0000-000000000001', 600, 4, 24 * 80));
select t.as_user('c0000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.activity_reserve(%L, 'far-away-key')$$, t.id('m10')), '%closer to the date%',
  'a booking past the hold limit is refused');
select t.reset();

update public.feature_flags set enabled = false where key = 'payments.enabled';
insert into ids values ('m11', t.paid_meet('c0000000-0000-0000-0000-000000000001'));
select t.as_user('c0000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.activity_reserve(%L, 'flag-off-key')$$, t.id('m11')), '%switched on%', 'the flag off stops reservations');
select is(public.join_activity(t.id('m11')), 'joined', 'and a paid Meet settles with the host, as before');
select t.reset();
update public.feature_flags set enabled = true where key = 'payments.enabled';

-- Tickets.
insert into ids values ('e1', t.event_meet('c0000000-0000-0000-0000-000000000001', 1000, 3));
insert into ids values ('tk1', t.payment_id(t.reserve('c0000000-0000-0000-0000-000000000002', t.id('e1'), null, 2)));
select is((select amount_minor from public.payments where id = t.id('tk1')), 2400::bigint, 'two S$10 tickets charge S$24.00, the fee per ticket');
select t.as_user('c0000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.activity_reserve(%L, 'tickets-key-2', 2)$$, t.id('e1')), '%Only 1 left%',
  'held tickets count against the seats');
select t.reset();
select is(t.succeed(t.id('tk1')), 'seated', 'paying issues the tickets');
select is((select qty from public.event_tickets where activity_id = t.id('e1')
  and user_id = 'c0000000-0000-0000-0000-000000000002'), 2, 'two tickets');
select is((select count(*)::int from public.stripe_events where id like 'evt_once_%'), 1, 'one event row for the replay');

select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
