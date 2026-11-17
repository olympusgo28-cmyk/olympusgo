-- P4a-06: refunds go back to the original method, in the amounts RULES.md
-- gives, and each one moves the ledger once.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('e0000000-0000-0000-0000-000000000001');  -- host
select t.player('e0000000-0000-0000-0000-000000000002');
select t.player('e0000000-0000-0000-0000-000000000003');
select t.player('e0000000-0000-0000-0000-000000000004');
select t.player('e0000000-0000-0000-0000-000000000005');
select t.player('e0000000-0000-0000-0000-000000000006');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;
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

-- Player leaves in time: the price, without the fee.
insert into ids values ('m1', t.paid_meet('e0000000-0000-0000-0000-000000000001'));
insert into ids values ('p1', t.paid('e0000000-0000-0000-0000-000000000002', t.id('m1')));
select is(t.leave('e0000000-0000-0000-0000-000000000002', t.id('m1')), 600, 'leaving in time returns S$6.00');
select is(t.status_of(t.id('m1'), 'e0000000-0000-0000-0000-000000000002'), 'cancelled', 'the spot is gone');
select is((select refund_cents from public.activity_participants where activity_id = t.id('m1')
  and user_id = 'e0000000-0000-0000-0000-000000000002'), 600, 'the amount is on the place');
select is((select refund_to from public.activity_participants where activity_id = t.id('m1')
  and user_id = 'e0000000-0000-0000-0000-000000000002'), 'original', 'it goes to the original method');
select is(t.bal('held', t.id('m1')), 0::bigint, 'nothing stays held for this spot');
select is(t.bal('refunds_pending') - t.bal('refunds_pending'), 0::bigint, 'pending is a number');
select is(t.leave('e0000000-0000-0000-0000-000000000002', t.id('m1')), 0, 'leaving twice refunds once');
select is(t.refunded(t.id('p1')), 600::bigint, 'one refund');

-- Worker and webhook.
select ok((public.money_svc_work() -> 'refunds') @> jsonb_build_array(jsonb_build_object('intent', 'pi_' || t.id('p1'))),
  'the worker picks up the refund');
select public.money_svc_result('refund', (select id from public.refunds where payment_id = t.id('p1')), true, 're_p1');
select is((select status from public.refunds where payment_id = t.id('p1')), 'processing', 'sent to Stripe');
select t.settle_refunds(t.id('p1'));
select is((select status from public.refunds where payment_id = t.id('p1')), 'succeeded', 'the webhook settles it');
select t.settle_refunds(t.id('p1'));
select is((select count(*)::int from public.ledger_transactions where kind = 'refund_paid'
  and reference ->> 'refund' = (select id::text from public.refunds where payment_id = t.id('p1'))), 1, 'settled once');

-- Late: nothing, and the price goes to the organizer in the end.
insert into ids values ('m2', t.paid_meet('e0000000-0000-0000-0000-000000000001'));
insert into ids values ('p2', t.paid('e0000000-0000-0000-0000-000000000002', t.id('m2')));
update public.activities set starts_at = now() - interval '1 minute' where id = t.id('m2');
select is(t.leave('e0000000-0000-0000-0000-000000000002', t.id('m2')), 0, 'leaving after the start returns nothing');
select is(t.bal('held', t.id('m2')), -600::bigint, 'the price stays held for the organizer');

-- Host's own spot.
insert into ids values ('m3', t.paid_meet('e0000000-0000-0000-0000-000000000001', 3000));
select t.as_user('e0000000-0000-0000-0000-000000000001');
select throws_ok(format($$select public.host_plays(%L, true)$$, t.id('m3')), 'P0001', 'payment_required', 'a host pays for their spot');
select t.reset();
insert into ids values ('h1', t.payment_id(t.reserve('e0000000-0000-0000-0000-000000000001', t.id('m3'))));
select is((select amount_minor from public.payments where id = t.id('h1')), 200::bigint, 'the host pays only S$2.00 (R-FEE-5)');
select is(t.succeed(t.id('h1')), 'seated', 'and plays');
select t.as_user('e0000000-0000-0000-0000-000000000001');
select public.host_plays(t.id('m3'), false);
select t.reset();
select is(t.refunded(t.id('h1')), 200::bigint, 'giving up the spot returns S$2.00 (owner, 31 Oct)');
select is((select organizer_pays_fee from public.refunds where payment_id = t.id('h1')), false, 'with no card fee on them');
select t.fee(t.id('h1'), 57);
select t.settle_refunds(t.id('h1'));
select is(t.bal('card_fee_recovery', 'e0000000-0000-0000-0000-000000000001'), 0::bigint, 'and none recovered');

-- Organizer cancels: five card payments, S$0.77 kept on each (R-REF-11).
insert into ids values ('m4', t.paid_meet('e0000000-0000-0000-0000-000000000001', 600, 8));
insert into ids values
  ('c1', t.paid('e0000000-0000-0000-0000-000000000002', t.id('m4'))),
  ('c2', t.paid('e0000000-0000-0000-0000-000000000003', t.id('m4'))),
  ('c3', t.paid('e0000000-0000-0000-0000-000000000004', t.id('m4'))),
  ('c4', t.paid('e0000000-0000-0000-0000-000000000005', t.id('m4'))),
  ('c5', t.paid('e0000000-0000-0000-0000-000000000006', t.id('m4')));
select t.fee(t.id(n), 77) from unnest(array['c1', 'c2', 'c3', 'c4', 'c5']) n;
select t.as_user('e0000000-0000-0000-0000-000000000001');
select is((public.cancel_preview(t.id('m4')) ->> 'card_fee_cents')::int, 385, 'the preview uses Stripe''s real fees');
select is((public.cancel_preview(t.id('m4')) ->> 'each_cents')::int, 800, 'each player gets S$8.00');
select public.cancel_activity(t.id('m4'), false, null);
select t.reset();
select is(t.refunded(t.id('c1')), 800::bigint, 'an organizer cancellation returns everything');
select is(t.bal('held', t.id('m4')), 0::bigint, 'nothing stays held');
select is(t.bal('card_fee_recovery', 'e0000000-0000-0000-0000-000000000001'), 0::bigint, 'no card fee before the refunds land');
select t.settle_refunds(t.id(n)) from unnest(array['c1', 'c2', 'c3', 'c4', 'c5']) n;
select is(t.bal('card_fee_recovery', 'e0000000-0000-0000-0000-000000000001'), 385::bigint, 'S$3.85 taken from the organizer');
select t.settle_refunds(t.id('c1'));
select is(t.bal('card_fee_recovery', 'e0000000-0000-0000-0000-000000000001'), 385::bigint, 'and only once');
select ok(exists (select 1 from public.notifications where user_id = 'e0000000-0000-0000-0000-000000000002'
  and body = 'The organizer cancelled it. You get everything you paid back.'), 'the player is told');

-- The fee can arrive after the refund.
insert into ids values ('m5', t.paid_meet('e0000000-0000-0000-0000-000000000001'));
insert into ids values ('c6', t.paid('e0000000-0000-0000-0000-000000000002', t.id('m5')));
select t.as_user('e0000000-0000-0000-0000-000000000001');
select public.cancel_activity(t.id('m5'), false, null);
select t.reset();
select t.settle_refunds(t.id('c6'));
select is(t.bal('card_fee_recovery', 'e0000000-0000-0000-0000-000000000001'), 385::bigint, 'no fee known yet, nothing recovered');
select t.fee(t.id('c6'), 77);
select is(t.bal('card_fee_recovery', 'e0000000-0000-0000-0000-000000000001'), 462::bigint, 'recovered when Stripe reports it');

-- PayNow: no card fee on the organizer (Q70 default).
insert into ids values ('m6', t.paid_meet('e0000000-0000-0000-0000-000000000001'));
insert into ids values ('c7', t.paid('e0000000-0000-0000-0000-000000000002', t.id('m6'), 'paynow'));
select t.fee(t.id('c7'), 10);
select t.as_user('e0000000-0000-0000-0000-000000000001');
select public.cancel_activity(t.id('m6'), false, null);
select t.reset();
select t.settle_refunds(t.id('c7'));
select is(t.bal('card_fee_recovery', 'e0000000-0000-0000-0000-000000000001'), 462::bigint, 'PayNow adds no card fee');

-- A failed refund charges nothing, and stays with staff.
insert into ids values ('m7', t.paid_meet('e0000000-0000-0000-0000-000000000001'));
insert into ids values ('c8', t.paid('e0000000-0000-0000-0000-000000000002', t.id('m7')));
select t.fee(t.id('c8'), 77);
select t.as_user('e0000000-0000-0000-0000-000000000001');
select public.cancel_activity(t.id('m7'), false, null);
select t.reset();
select t.settle_refunds(t.id('c8'), 'failed');
select is((select status from public.refunds where payment_id = t.id('c8')), 'failed', 'a failed refund is marked');
select ok(exists (select 1 from public.money_alerts where kind = 'refund_failed'
  and detail ->> 'payment' = t.id('c8')::text), 'and raises an alert');
select is(t.bal('card_fee_recovery', 'e0000000-0000-0000-0000-000000000001'), 462::bigint, 'and no card fee is taken');

-- Moved later: a full refund inside the window (R-REF-17 default).
insert into ids values ('m8', t.paid_meet('e0000000-0000-0000-0000-000000000001'));
insert into ids values ('c9', t.paid('e0000000-0000-0000-0000-000000000002', t.id('m8')));
update public.payments set captured_at = now() - interval '1 hour' where id = t.id('c9');
select t.as_user('e0000000-0000-0000-0000-000000000001');
update public.activities set starts_at = starts_at + interval '1 day', ends_at = ends_at + interval '1 day' where id = t.id('m8');
select t.reset();
select is(t.leave('e0000000-0000-0000-0000-000000000002', t.id('m8')), 800, 'after a date change a player gets everything');
select is((select reason from public.refunds where payment_id = t.id('c9')), 'change_by_organizer', 'for the right reason');

-- Club removal (R-REF-13).
insert into public.clubs (id, name, owner_id) values
  ('e1000000-0000-0000-0000-000000000001', 'Refund club', 'e0000000-0000-0000-0000-000000000001');
insert into public.club_members (club_id, user_id) values
  ('e1000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001'),
  ('e1000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000003'),
  ('e1000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000004')
on conflict do nothing;
insert into ids values ('m9', t.paid_meet('e0000000-0000-0000-0000-000000000001'));
alter table public.activities disable trigger activities_club_check;
update public.activities set club_id = 'e1000000-0000-0000-0000-000000000001' where id = t.id('m9');
alter table public.activities enable trigger activities_club_check;
insert into ids values ('c10', t.paid('e0000000-0000-0000-0000-000000000003', t.id('m9')));
insert into ids values ('c11', t.paid('e0000000-0000-0000-0000-000000000004', t.id('m9')));
select t.as_user('e0000000-0000-0000-0000-000000000001');
select public.club_remove_member('e1000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000003');
select public.club_ban('e1000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000004', 'test');
select t.reset();
select is(t.refunded(t.id('c10')), 800::bigint, 'a removed member gets everything');
select is(t.status_of(t.id('m9'), 'e0000000-0000-0000-0000-000000000003'), 'cancelled', 'and loses the spot');
select is(t.refunded(t.id('c11')), 800::bigint, 'a banned member gets everything');

-- Tickets, one at a time.
insert into ids values ('e1', t.event_meet('e0000000-0000-0000-0000-000000000001', 1000, 10, 72));
insert into ids values ('t1', t.payment_id(t.reserve('e0000000-0000-0000-0000-000000000002', t.id('e1'), null, 3)));
select t.succeed(t.id('t1'));
select t.as_user('e0000000-0000-0000-0000-000000000002');
select is(public.event_ticket_release(t.id('e1'), 1), 1000, 'releasing one ticket returns its price');
select is(public.event_ticket_release(t.id('e1'), 1), 1000, 'and another');
select t.reset();
select is((select qty from public.event_tickets where activity_id = t.id('e1')
  and user_id = 'e0000000-0000-0000-0000-000000000002'), 1, 'one ticket left');
select is(t.refunded(t.id('t1')), 2000::bigint, 'S$20.00 back, without fees');
select t.as_user('e0000000-0000-0000-0000-000000000002');
select is(public.event_ticket_release(t.id('e1'), 5), 1000, 'asking for too many releases what''s left');
select t.reset();
select is(t.bal('held', t.id('e1')), 0::bigint, 'nothing stays held');

-- Tickets inside 24 hours: nothing back (R-REF-6).
insert into ids values ('e2', t.event_meet('e0000000-0000-0000-0000-000000000001', 1000, 10, 6));
insert into ids values ('t2', t.paid('e0000000-0000-0000-0000-000000000003', t.id('e2')));
select t.as_user('e0000000-0000-0000-0000-000000000003');
select is(public.event_ticket_release(t.id('e2'), 1), 0, 'a ticket 6 hours before returns nothing');
select t.reset();

-- Tickets on a cancelled event.
insert into ids values ('e3', t.event_meet('e0000000-0000-0000-0000-000000000001', 1000, 10));
insert into ids values ('t3', t.paid('e0000000-0000-0000-0000-000000000004', t.id('e3')));
select t.as_user('e0000000-0000-0000-0000-000000000001');
select public.cancel_activity(t.id('e3'), false, null);
select t.reset();
select is(t.refunded(t.id('t3')), 1200::bigint, 'a cancelled event returns everything');
select is((select status from public.event_tickets where activity_id = t.id('e3')), 'released', 'and ends the tickets');

-- Disputes stop refunds.
insert into ids values ('m10', t.paid_meet('e0000000-0000-0000-0000-000000000001'));
insert into ids values ('d1', t.paid('e0000000-0000-0000-0000-000000000002', t.id('m10')));
select is(t.event('charge.dispute.created', jsonb_build_object('id', 'dp_1', 'charge', 'ch_' || t.id('d1'), 'amount', 800)),
  'dispute', 'a chargeback opens a dispute');
select is(t.leave('e0000000-0000-0000-0000-000000000002', t.id('m10')), 0, 'and blocks a refund');
select ok(exists (select 1 from public.money_alerts where key = 'dispute-refund:' || t.id('d1')), 'with an alert');
select is(t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_1', 'status', 'won', 'amount', 800)),
  'dispute_closed', 'a closed dispute is recorded');
select is((select status from public.payment_disputes where stripe_dispute_id = 'dp_1'), 'won', 'as won');

-- A refund for nobody's refund id raises an alert, not an error.
select t.event('refund.updated', jsonb_build_object('id', 're_stray', 'status', 'succeeded',
  'metadata', jsonb_build_object('refund_id', gen_random_uuid())));
select ok(exists (select 1 from public.money_alerts where key = 'refund-unknown:re_stray'), 'a stray refund raises an alert');

select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
