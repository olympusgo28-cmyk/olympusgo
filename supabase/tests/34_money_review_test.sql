-- What the independent reviews of 4a found, so it stays fixed.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('a5000000-0000-0000-0000-000000000001');  -- host
select t.player('a5000000-0000-0000-0000-000000000002');
select t.player('a5000000-0000-0000-0000-000000000003');
select t.player('a5000000-0000-0000-0000-000000000004');
select t.player('a5000000-0000-0000-0000-000000000005');  -- staff
insert into public.staff (user_id, role) values ('a5000000-0000-0000-0000-000000000005', 'payments');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;
create function t.started(p_payment uuid, p_intent text default null) returns void language sql as $$
  update public.payments set method = 'card', stripe_intent_id = coalesce(p_intent, 'pi_' || p_payment)
  where id = p_payment;
$$;
create function t.abandon(p_user uuid, p_payment uuid) returns void language plpgsql as $$
begin
  perform t.as_user(p_user);
  perform public.payment_abandon(p_payment);
  perform t.reset();
end;
$$;

-- Leaving an event ends the ticket.
insert into ids values ('e1', t.event_meet('a5000000-0000-0000-0000-000000000001', 3000, 4));
insert into ids values ('tk', t.paid('a5000000-0000-0000-0000-000000000002', t.id('e1')));
select t.as_user('a5000000-0000-0000-0000-000000000002');
select is(public.leave_activity(t.id('e1')), 3000, 'leaving an event refunds the price');
select t.reset();
select is((select status from public.event_tickets where activity_id = t.id('e1')), 'released', 'and the ticket stops working');
select is(t.refunded(t.id('tk')), 3000::bigint, 'refunded once');

-- A given-up payment is never seated.
insert into ids values ('m1', t.paid_meet('a5000000-0000-0000-0000-000000000001', 600, 2));
insert into ids values ('p1', t.payment_id(t.reserve('a5000000-0000-0000-0000-000000000002', t.id('m1'))));
select t.started(t.id('p1'));
select t.abandon('a5000000-0000-0000-0000-000000000002', t.id('p1'));
select is(t.succeed(t.id('p1')), 'refunded', 'money after giving up goes back');
select is(t.status_of(t.id('m1'), 'a5000000-0000-0000-0000-000000000002'), 'cancelled', 'with no seat');
select is(t.refunded(t.id('p1')), 800::bigint, 'in full');

-- Giving up, paying again, and the first money landing leaves one charge.
insert into ids values ('m2', t.paid_meet('a5000000-0000-0000-0000-000000000001', 600, 2));
insert into ids values ('p2', t.payment_id(t.reserve('a5000000-0000-0000-0000-000000000002', t.id('m2'))));
select t.started(t.id('p2'));
select t.abandon('a5000000-0000-0000-0000-000000000002', t.id('p2'));
insert into ids values ('p3', t.payment_id(t.reserve('a5000000-0000-0000-0000-000000000002', t.id('m2'))));
select is(t.succeed(t.id('p2')), 'refunded', 'the old payment goes back');
select is(t.status_of(t.id('m2'), 'a5000000-0000-0000-0000-000000000002'), 'reserved', 'and leaves the new hold alone');
select is(t.succeed(t.id('p3')), 'seated', 'the new payment takes the spot');
select is(t.bal('held', t.id('m2')), -600::bigint, 'one price held');

-- Too many tickets can't fail the webhook.
insert into ids values ('e2', t.event_meet('a5000000-0000-0000-0000-000000000001', 1000, 30));
insert into ids values ('t1', t.payment_id(t.reserve('a5000000-0000-0000-0000-000000000003', t.id('e2'), null, 6)));
select t.started(t.id('t1'));
select t.abandon('a5000000-0000-0000-0000-000000000003', t.id('t1'));
insert into ids values ('t2', t.payment_id(t.reserve('a5000000-0000-0000-0000-000000000003', t.id('e2'), null, 6)));
select t.succeed(t.id('t2'));
select lives_ok(format($$select t.succeed(%L)$$, t.id('t1')), 'a capture never raises on a business rule');
select is(t.refunded(t.id('t1')), 7200::bigint, 'the extra tickets go back');
select is((select qty from public.event_tickets where activity_id = t.id('e2')), 6, 'and the limit holds');

-- A cancelled Meet with a dispute pays the player, never the organizer.
insert into ids values ('m3', t.paid_meet('a5000000-0000-0000-0000-000000000001'));
insert into ids values ('p4', t.paid('a5000000-0000-0000-0000-000000000002', t.id('m3')));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_rev1', 'charge', 'ch_' || t.id('p4'), 'amount', 800));
select t.as_user('a5000000-0000-0000-0000-000000000001');
select public.cancel_activity(t.id('m3'), false, null);
select t.reset();
select is(t.refunded(t.id('p4')), 0::bigint, 'a dispute holds the refund');
select is((select refund_owed -> 0 ->> 'reason' from public.payments where id = t.id('p4')), 'organizer_cancelled', 'and remembers it');
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_rev1', 'status', 'won', 'amount', 800));
select is(t.refunded(t.id('p4')), 800::bigint, 'winning the dispute issues the refund');
update public.activities set starts_at = now() - interval '3 days', ends_at = now() - interval '2 days' where id = t.id('m3');
select private.money_sweep();
select is(private.release_activity(t.id('m3')), 0, 'a cancelled Meet never releases');
select is(t.bal('held', t.id('m3')), 0::bigint, 'and nothing stays held');

-- Lost disputes block a second give-back.
insert into ids values ('m4', t.paid_meet('a5000000-0000-0000-0000-000000000001'));
insert into ids values ('p5', t.paid('a5000000-0000-0000-0000-000000000002', t.id('m4')));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_rev2', 'charge', 'ch_' || t.id('p5'), 'amount', 800));
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_rev2', 'status', 'lost', 'amount', 800));
select t.as_user('a5000000-0000-0000-0000-000000000002');
select is(public.leave_activity(t.id('m4')), 0, 'a lost dispute already returned the money');
select t.reset();

-- Hosts can't touch their fee rows or the refund window.
insert into ids values ('m5', t.paid_meet('a5000000-0000-0000-0000-000000000001'));
insert into ids values ('p6', t.paid('a5000000-0000-0000-0000-000000000002', t.id('m5')));
update public.payments set captured_at = now() - interval '1 hour' where id = t.id('p6');
select t.as_user('a5000000-0000-0000-0000-000000000001');
update public.activities set starts_at = starts_at + interval '1 day', ends_at = ends_at + interval '1 day' where id = t.id('m5');
update public.activities set money_changed_at = null where id = t.id('m5');
select t.reset();
select ok((select money_changed_at is not null from public.activities where id = t.id('m5')), 'a host can''t close the refund window');

select t.as_user('a5000000-0000-0000-0000-000000000001');
select throws_like(format($$update public.activities set starts_at = now() + interval '100 days', ends_at = now() + interval '101 days' where id = %L$$, t.id('m5')),
  '%that far ahead%', 'a date can''t pass the hold limit');
select t.reset();

-- The window ends at the start, and new payers aren't covered.
insert into ids values ('p7', t.paid('a5000000-0000-0000-0000-000000000003', t.id('m5')));
select t.as_user('a5000000-0000-0000-0000-000000000003');
select is(public.leave_activity(t.id('m5')), 600, 'someone who paid after the change gets the normal refund');
select t.reset();
update public.activities set starts_at = now() - interval '1 minute' where id = t.id('m5');
select t.as_user('a5000000-0000-0000-0000-000000000002');
select is(public.leave_activity(t.id('m5')), 0, 'the change window ends at the start');
select t.reset();

-- A refund that bounces, and one that lands after we gave up on it.
insert into ids values ('m6', t.paid_meet('a5000000-0000-0000-0000-000000000001'));
insert into ids values ('p8', t.paid('a5000000-0000-0000-0000-000000000002', t.id('m6')));
select t.as_user('a5000000-0000-0000-0000-000000000002');
select public.leave_activity(t.id('m6'));
select t.reset();
create temp table r1 on commit drop as select id from public.refunds where payment_id = t.id('p8');
grant select on r1 to anon, authenticated;
select public.money_svc_result('refund_done', (select id from r1), true, 're_bounce');
select is((select status from public.refunds where id = (select id from r1)), 'succeeded', 'a refund can succeed at once');
select t.event('refund.failed', jsonb_build_object('id', 're_bounce', 'status', 'failed', 'failure_reason', 'bank',
  'metadata', jsonb_build_object('refund_id', (select id from r1))));
select is((select status from public.refunds where id = (select id from r1)), 'failed', 'a bounce after success is failed again');
select ok(exists (select 1 from public.money_alerts where kind = 'refund_failed' and detail ->> 'refund' = (select id::text from r1)), 'with an alert');
select t.as_staff('a5000000-0000-0000-0000-000000000005');
select public.staff_refund_retry((select id from r1), 'Try once more');
select t.reset();
select is((select attempt from public.refunds where id = (select id from r1)), 2, 'a retry gets a new Stripe key');
select t.event('refund.updated', jsonb_build_object('id', 're_second', 'status', 'succeeded',
  'metadata', jsonb_build_object('refund_id', (select id from r1))));
select is((select count(*)::int from public.ledger_transactions where kind = 'refund_paid'
  and reference ->> 'refund' = (select id::text from r1)), 2, 'each attempt settles in the ledger');

-- A pending refund can't be voided: the worker may have sent it.
insert into ids values ('m7', t.paid_meet('a5000000-0000-0000-0000-000000000001'));
insert into ids values ('p9', t.paid('a5000000-0000-0000-0000-000000000002', t.id('m7')));
select t.as_user('a5000000-0000-0000-0000-000000000002');
select public.leave_activity(t.id('m7'));
select t.reset();
create temp table r2 on commit drop as select id from public.refunds where payment_id = t.id('p9');
grant select on r2 to anon, authenticated;
select t.as_staff('a5000000-0000-0000-0000-000000000005');
select throws_like(format($$select public.staff_refund_void(%L, 'Sent to the wrong one')$$, (select id from r2)), '%can be voided%',
  'a pending refund can''t be voided');
select t.reset();

-- Tickets after a voided refund.
insert into ids values ('e3', t.event_meet('a5000000-0000-0000-0000-000000000001', 1000, 10));
insert into ids values ('t3', t.payment_id(t.reserve('a5000000-0000-0000-0000-000000000004', t.id('e3'), null, 3)));
select t.succeed(t.id('t3'));
select t.as_user('a5000000-0000-0000-0000-000000000004');
select public.event_ticket_release(t.id('e3'), 1);
select t.reset();
update public.refunds set status = 'failed' where payment_id = t.id('t3');
create temp table r3 on commit drop as select id from public.refunds where payment_id = t.id('t3');
grant select on r3 to anon, authenticated;
select t.as_staff('a5000000-0000-0000-0000-000000000005');
select public.staff_refund_void((select id from r3), 'Wrong amount');
select t.reset();
select t.as_user('a5000000-0000-0000-0000-000000000004');
select is(public.event_ticket_release(t.id('e3'), 1), 1000, 'a voided refund doesn''t block the next one');
select t.reset();

-- Partial free tickets return the organizer's fee per ticket.
insert into ids values ('e4', t.event_meet('a5000000-0000-0000-0000-000000000001', 0, 10));
select t.as_user('a5000000-0000-0000-0000-000000000002');
select public.event_ticket_buy(t.id('e4'), 3);
select t.reset();
insert into ids values ('o1', (select id from public.payments where activity_id = t.id('e4') and purpose = 'organizer_fee'));
select public.money_svc_result('organizer_fee', t.id('o1'), true, 'pi_o1');
select t.succeed(t.id('o1'));
select t.as_user('a5000000-0000-0000-0000-000000000002');
select public.event_ticket_release(t.id('e4'), 2);
select t.reset();
select is(t.refunded(t.id('o1')), 400::bigint, 'two of three free tickets return S$4.00');

-- Fee rows are the system's.
insert into ids values ('e5', t.event_meet('a5000000-0000-0000-0000-000000000001', 0, 10));
select t.as_user('a5000000-0000-0000-0000-000000000002');
select public.event_ticket_buy(t.id('e5'), 1);
select t.reset();
insert into ids values ('o2', (select id from public.payments where activity_id = t.id('e5') and purpose = 'organizer_fee'));
select t.as_user('a5000000-0000-0000-0000-000000000001');
select throws_like(format($$select public.payment_abandon(%L)$$, t.id('o2')), '%isn''t yours%', 'a host can''t cancel their own fee');
select t.reset();

-- A failed charge that worked after all clears the debt.
select public.money_svc_result('organizer_fee', t.id('o2'), false, null, 'card_declined');
select is(t.status_pay(t.id('o2')), 'debt', 'written off as a debt');
select is(t.succeed(t.id('o2')), 'captured', 'the money landing is recorded');
select is((select count(*)::int from public.ledger_transactions where idempotency_key = 'debt_reverse:' || t.id('o2')), 1, 'and the debt is reversed');

-- Late organizer fee after the player left.
insert into ids values ('e6', t.event_meet('a5000000-0000-0000-0000-000000000001', 0, 10));
select t.as_user('a5000000-0000-0000-0000-000000000002');
select public.event_ticket_buy(t.id('e6'), 1);
select t.reset();
insert into ids values ('o3', (select id from public.payments where activity_id = t.id('e6') and purpose = 'organizer_fee'));
select public.money_svc_result('organizer_fee', t.id('o3'), true, 'pi_o3');
select t.as_user('a5000000-0000-0000-0000-000000000002');
select public.event_ticket_release(t.id('e6'), 1);
select t.reset();
select is(t.status_pay(t.id('o3')), 'cancel_requested', 'the charge is being stopped');
select is(t.succeed(t.id('o3')), 'refunded', 'if it lands anyway it goes back');

-- Debts have one live payment.
select private.ledger_post('test', 'rev-debt-' || gen_random_uuid(), 'SGD', '{}', jsonb_build_array(
  private.ledger_line('organizer_fee_debt', 'a5000000-0000-0000-0000-000000000003', 200),
  private.ledger_line('platform_fees', null, -200)));
select t.as_user('a5000000-0000-0000-0000-000000000003');
select is(public.organizer_debt_reserve('debt-key-one') ->> 'payment_id', public.organizer_debt_reserve('debt-key-two') ->> 'payment_id',
  'a second tap reuses the payment');
select t.reset();

-- A host pays even on a free Meet.
insert into ids values ('m8', t.meet('a5000000-0000-0000-0000-000000000001'));
select t.as_user('a5000000-0000-0000-0000-000000000001');
select throws_ok(format($$select public.join_activity(%L)$$, t.id('m8')), 'P0001', 'payment_required', 'a host can''t skip the S$2.00');
select t.reset();

-- A hold on one activity doesn't freeze the rest.
insert into public.vendors (owner_id, stripe_account_id, status) values ('a5000000-0000-0000-0000-000000000001', 'acct_rev', 'verified');
insert into ids values ('m9', t.paid_meet('a5000000-0000-0000-0000-000000000001'));
select t.paid('a5000000-0000-0000-0000-000000000002', t.id('m9'));
select private.release_activity(t.id('m9'));
insert into ids values ('m10', t.paid_meet('a5000000-0000-0000-0000-000000000001'));
select t.paid('a5000000-0000-0000-0000-000000000002', t.id('m10'));
insert into public.activity_money_holds (activity_id) values (t.id('m10'));
insert into ids values ('run', private.payouts_prepare('SGD', '2099-03-02'));
select ok(exists (select 1 from public.payout_items where payout_id = t.id('run')
  and owner_id = 'a5000000-0000-0000-0000-000000000001'), 'an open hold leaves other earnings payable');

-- Vendors can lose their checks.
select t.event('account.updated', jsonb_build_object('id', 'acct_rev', 'payouts_enabled', false));
select is((select status from public.vendors where owner_id = 'a5000000-0000-0000-0000-000000000001'), 'pending', 'losing payouts stops a vendor being verified');

-- Suspense has a way out, and disputes don't hide in it.
select t.event('payment_intent.succeeded', jsonb_build_object('id', 'pi_rev_stray', 'amount', 500, 'currency', 'sgd',
  'latest_charge', 'ch_rev_stray', 'metadata', jsonb_build_object('payment_id', gen_random_uuid())));
select t.as_staff('a5000000-0000-0000-0000-000000000005');
select public.staff_suspense_clear('pi_rev_stray', 'Refunded in Stripe by hand');
select throws_like($$select public.staff_suspense_clear('pi_rev_stray', 'Again please')$$, '%already been cleared%', 'it clears once');
select t.reset();
select ok((select closed_at is not null from public.money_alerts where key = 'suspense:pi_rev_stray'), 'and closes the alert');

-- The same key on another activity is refused.
insert into ids values ('m11', t.paid_meet('a5000000-0000-0000-0000-000000000001'));
insert into ids values ('m12', t.paid_meet('a5000000-0000-0000-0000-000000000001'));
select t.reserve('a5000000-0000-0000-0000-000000000004', t.id('m11'), 'shared-key-1');
select t.as_user('a5000000-0000-0000-0000-000000000004');
select throws_like(format($$select public.activity_reserve(%L, 'shared-key-1')$$, t.id('m12')), '%Try that again%', 'a key belongs to one activity');
select t.reset();

-- charge.updated can't be lost.
insert into ids values ('m13', t.paid_meet('a5000000-0000-0000-0000-000000000001'));
insert into ids values ('p10', t.payment_id(t.reserve('a5000000-0000-0000-0000-000000000003', t.id('m13'))));
select t.started(t.id('p10'), 'pi_rev_early');
select throws_like($$select public.money_svc_event('{"id":"evt_early","type":"charge.updated","object":{"id":"ch_early","payment_intent":"pi_rev_early","fee_minor":77}}')$$,
  '%before capture%', 'a fee ahead of its capture is refused, so Stripe sends it again');
select is((select count(*)::int from public.stripe_events where id = 'evt_early'), 0, 'and isn''t recorded as seen');

-- Lease.
update private.worker_lease set until = '-infinity' where id;
update private.worker_lease set token = null;
create temp table lease on commit drop as select public.money_svc_lease(300) as token;
select ok((select token from lease) is not null, 'the first worker gets the lease');
select is(public.money_svc_lease(300), null, 'the second doesn''t');
select public.money_svc_lease(0, gen_random_uuid());
select is(public.money_svc_lease(300), null, 'someone else''s token can''t give it back');
select public.money_svc_lease(0, (select token from lease));
select ok(public.money_svc_lease(300) is not null, 'its own can');

-- Card details stay out of the event log.
select t.event('setup_intent.succeeded', jsonb_build_object('id', 'seti_rev', 'customer', 'cus_rev', 'payment_method', 'pm_rev',
  'card_brand', 'visa', 'card_last4', '4242', 'metadata', jsonb_build_object('user_id', 'a5000000-0000-0000-0000-000000000002')), 'evt_rev_card');
select ok((select payload -> 'object' ->> 'card_last4' from public.stripe_events where id = 'evt_rev_card') is null, 'the last four digits aren''t logged');

-- A stopped worker raises an alert. The local daily reconcile job may have
-- run in the last day, so age its runs here (rolled back with the test).
update public.reconciliation_runs set ran_at = ran_at - interval '3 days';
select private.money_sweep();
select ok(exists (select 1 from public.money_alerts where kind = 'reconcile_missing'), 'no reconciliation in a day raises an alert');

select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
