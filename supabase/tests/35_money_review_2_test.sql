-- The second pass: events out of order, disputes and partial refunds, and the
-- corners of a late capture.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('a6000000-0000-0000-0000-000000000001');  -- host
select t.player('a6000000-0000-0000-0000-000000000002');
select t.player('a6000000-0000-0000-0000-000000000003');
select t.player('a6000000-0000-0000-0000-000000000004');
select t.player('a6000000-0000-0000-0000-000000000005');  -- staff
insert into public.staff (user_id, role) values ('a6000000-0000-0000-0000-000000000005', 'payments');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;
create function t.rf(p_payment uuid) returns uuid language sql security definer as $$
  select id from public.refunds where payment_id = p_payment order by created_at limit 1;
$$;
grant execute on function t.rf(uuid) to anon, authenticated;
create function t.rstatus(p_refund uuid, p_status text, p_attempt int default null, p_id text default null)
returns text language sql as $$
  select t.event('refund.updated', jsonb_build_object('id', coalesce(p_id, 're_' || p_refund), 'status', p_status,
    'metadata', jsonb_build_object('refund_id', p_refund) ||
      case when p_attempt is null then '{}'::jsonb else jsonb_build_object('attempt', p_attempt::text) end));
$$;
create function t.leave(p_user uuid, p_activity uuid) returns int language plpgsql as $$
declare
  v int;
begin
  perform t.as_user(p_user);
  v := public.leave_activity(p_activity);
  perform t.reset();
  return v;
end;
$$;
create function t.pending_of(p_refund uuid) returns bigint language sql as $$
  select coalesce(sum(e.amount_minor), 0)::bigint from public.ledger_entries e
  join public.ledger_accounts a on a.id = e.account_id
  join public.ledger_transactions x on x.id = e.transaction_id
  where a.kind = 'refunds_pending' and x.reference ->> 'refund' = p_refund::text;
$$;

-- A late failure about an old attempt changes nothing.
insert into ids values ('m1', t.paid_meet('a6000000-0000-0000-0000-000000000001'));
insert into ids values ('p1', t.paid('a6000000-0000-0000-0000-000000000002', t.id('m1')));
select t.leave('a6000000-0000-0000-0000-000000000002', t.id('m1'));
select t.rstatus(t.rf(t.id('p1')), 'succeeded', 1);
select t.rstatus(t.rf(t.id('p1')), 'failed', 1);
select t.as_staff('a6000000-0000-0000-0000-000000000005');
select public.staff_refund_retry(t.rf(t.id('p1')), 'Card reissued');
select t.reset();
select t.rstatus(t.rf(t.id('p1')), 'succeeded', 2);
select is((select status from public.refunds where id = t.rf(t.id('p1'))), 'succeeded', 'attempt 2 settles');
select t.rstatus(t.rf(t.id('p1')), 'failed', 1);
select is((select status from public.refunds where id = t.rf(t.id('p1'))), 'succeeded', 'a late failure of attempt 1 changes nothing');
select is(t.pending_of(t.rf(t.id('p1'))), 0::bigint, 'and the ledger is square');

-- A late success of a bounced attempt doesn't stop the retry.
insert into ids values ('m2', t.paid_meet('a6000000-0000-0000-0000-000000000001'));
insert into ids values ('p2', t.paid('a6000000-0000-0000-0000-000000000002', t.id('m2')));
select t.leave('a6000000-0000-0000-0000-000000000002', t.id('m2'));
select t.rstatus(t.rf(t.id('p2')), 'succeeded', 1);
select t.rstatus(t.rf(t.id('p2')), 'failed', 1);
select t.as_staff('a6000000-0000-0000-0000-000000000005');
select public.staff_refund_retry(t.rf(t.id('p2')), 'Card reissued');
select t.reset();
select t.rstatus(t.rf(t.id('p2')), 'succeeded', 1, 're_second_copy');
select is((select status from public.refunds where id = t.rf(t.id('p2'))), 'pending', 'a stale success leaves the retry queued');
select ok(exists (select 1 from public.money_alerts where kind = 'refund_old_attempt' and detail ->> 'refund' = t.rf(t.id('p2'))::text), 'with an alert');

-- A stale success after a bounce with no retry.
insert into ids values ('m3', t.paid_meet('a6000000-0000-0000-0000-000000000001'));
insert into ids values ('p3', t.paid('a6000000-0000-0000-0000-000000000002', t.id('m3')));
select t.leave('a6000000-0000-0000-0000-000000000002', t.id('m3'));
select t.rstatus(t.rf(t.id('p3')), 'succeeded', 1);
select t.rstatus(t.rf(t.id('p3')), 'failed', 1);
select t.rstatus(t.rf(t.id('p3')), 'succeeded', 1, 're_third_copy');
select is((select status from public.refunds where id = t.rf(t.id('p3'))), 'failed', 'a bounce stays failed');

-- Bounced, then paid by hand: refunds_pending clears.
select t.as_staff('a6000000-0000-0000-0000-000000000005');
select public.staff_refund_manual(t.rf(t.id('p3')), 'BANK-1', 'Paid by transfer');
select t.reset();
select is(t.pending_of(t.rf(t.id('p3'))), 0::bigint, 'bounced then paid by hand clears');

-- Stripe's canceled counts as failed, and staff can settle a silent refund.
insert into ids values ('m4', t.paid_meet('a6000000-0000-0000-0000-000000000001'));
insert into ids values ('p4', t.paid('a6000000-0000-0000-0000-000000000002', t.id('m4')));
select t.leave('a6000000-0000-0000-0000-000000000002', t.id('m4'));
select public.money_svc_result('refund', t.rf(t.id('p4')), true, 're_silent');
select t.as_user('a6000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.staff_refund_settle(%L, 'failed', 'Checked it')$$, t.rf(t.id('p4'))), 'Not found%', 'a player can''t settle a refund');
select t.reset();
select t.as_staff('a6000000-0000-0000-0000-000000000005');
select public.staff_refund_settle(t.rf(t.id('p4')), 'failed', 'Stripe shows it failed');
select public.staff_refund_retry(t.rf(t.id('p4')), 'Trying again');
select t.reset();
select public.money_svc_result('refund', t.rf(t.id('p4')), true, 're_silent2');
select t.event('refund.updated', jsonb_build_object('id', 're_silent2', 'status', 'canceled',
  'metadata', jsonb_build_object('refund_id', t.rf(t.id('p4')), 'attempt', '2')));
select is((select status from public.refunds where id = t.rf(t.id('p4'))), 'failed', 'canceled counts as failed');

-- A partial release during a dispute pays exactly that part when it's won.
insert into ids values ('e1', t.event_meet('a6000000-0000-0000-0000-000000000001', 1000, 10));
insert into ids values ('t1', t.payment_id(t.reserve('a6000000-0000-0000-0000-000000000003', t.id('e1'), null, 3)));
select t.succeed(t.id('t1'));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_r2', 'charge', 'ch_' || t.id('t1'), 'amount', 3600));
select t.as_user('a6000000-0000-0000-0000-000000000003');
select public.event_ticket_release(t.id('e1'), 1);
select t.reset();
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_r2', 'status', 'won', 'amount', 3600));
select is(t.refunded(t.id('t1')), 1000::bigint, 'winning refunds the one ticket released');
select is((select qty from public.event_tickets where activity_id = t.id('e1')), 2, 'and the other two stand');

-- A lost dispute on a cancelled Meet leaves nothing held.
insert into ids values ('m5', t.paid_meet('a6000000-0000-0000-0000-000000000001'));
insert into ids values ('p5', t.paid('a6000000-0000-0000-0000-000000000002', t.id('m5')));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_r3', 'charge', 'ch_' || t.id('p5'), 'amount', 800));
select t.as_user('a6000000-0000-0000-0000-000000000001');
select public.cancel_activity(t.id('m5'), false, null);
select t.reset();
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_r3', 'status', 'lost', 'amount', 800));
select is(t.bal('held', t.id('m5')), 0::bigint, 'a lost dispute on a cancelled Meet leaves nothing held');

-- A stale guest doesn't overfill.
insert into ids values ('m6', t.paid_meet('a6000000-0000-0000-0000-000000000001', 600, 2));
insert into ids values ('g1', t.payment_id(t.reserve('a6000000-0000-0000-0000-000000000002', t.id('m6'), null, 1, 'Guest')));
update public.payments set method = 'card', stripe_intent_id = 'pi_g1' where id = t.id('g1');
select t.as_user('a6000000-0000-0000-0000-000000000002');
select public.payment_abandon(t.id('g1'));
select t.reset();
insert into ids values ('g2', t.payment_id(t.reserve('a6000000-0000-0000-0000-000000000002', t.id('m6'))));
update public.activity_participants set hold_until = now() - interval '1 second'
where activity_id = t.id('m6') and user_id = 'a6000000-0000-0000-0000-000000000002';
update public.payments set hold_until = now() - interval '1 second' where id = t.id('g2');
select t.succeed(t.id('g2'));
select is(public.activity_spots_taken(t.id('m6')), 1, 'a guest from an abandoned try isn''t seated');

-- Money landing after the hold but before the sweep takes a free seat.
insert into ids values ('m7', t.paid_meet('a6000000-0000-0000-0000-000000000001', 600, 2));
insert into ids values ('h1', t.payment_id(t.reserve('a6000000-0000-0000-0000-000000000003', t.id('m7'))));
update public.activity_participants set hold_until = now() - interval '1 second'
where activity_id = t.id('m7') and user_id = 'a6000000-0000-0000-0000-000000000003';
update public.payments set hold_until = now() - interval '1 second' where id = t.id('h1');
select is(t.succeed(t.id('h1')), 'seated', 'money just after the hold takes the free seat');

-- Given-up money doesn't touch a live offer.
insert into ids values ('m8', t.paid_meet('a6000000-0000-0000-0000-000000000001', 600, 2));
insert into ids values ('o1', t.payment_id(t.reserve('a6000000-0000-0000-0000-000000000002', t.id('m8'))));
update public.payments set method = 'card', stripe_intent_id = 'pi_o1' where id = t.id('o1');
select t.as_user('a6000000-0000-0000-0000-000000000002');
select public.payment_abandon(t.id('o1'));
select t.reset();
update public.activity_participants set status = 'offered', hold_until = now() + interval '20 minutes'
where activity_id = t.id('m8') and user_id = 'a6000000-0000-0000-0000-000000000002';
select t.succeed(t.id('o1'));
select is(t.status_of(t.id('m8'), 'a6000000-0000-0000-0000-000000000002'), 'offered', 'money for a given-up payment leaves an offer alone');

-- Leaving twice collects once, even in the change window.
insert into ids values ('m9', t.paid_meet('a6000000-0000-0000-0000-000000000001'));
insert into ids values ('p9', t.paid('a6000000-0000-0000-0000-000000000002', t.id('m9')));
update public.payments set captured_at = now() - interval '1 hour' where id = t.id('p9');
select is(t.leave('a6000000-0000-0000-0000-000000000002', t.id('m9')), 600, 'leaving returns the price');
update public.activities set money_changed_at = now() where id = t.id('m9');
select is(t.leave('a6000000-0000-0000-0000-000000000002', t.id('m9')), 0, 'someone who left can''t collect the fee');

select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
