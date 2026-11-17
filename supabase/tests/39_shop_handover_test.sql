-- P4b-04: collecting, reporting, cancelling, the release clock and staff.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('b4000000-0000-0000-0000-000000000001');  -- owner
select t.player('b4000000-0000-0000-0000-000000000002');  -- buyer
select t.player('b4000000-0000-0000-0000-000000000003');  -- someone else
select t.player('b4000000-0000-0000-0000-000000000004');  -- payments staff
insert into public.staff (user_id, role) values ('b4000000-0000-0000-0000-000000000004', 'payments');
insert into public.app_settings (key, value) values ('points.redeem_min_account_days', '0');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;
create function t.pay_of(p_order uuid) returns uuid language sql security definer as $$
  select id from public.payments where order_id = p_order;
$$;
create function t.line_id(p_order uuid) returns uuid language sql security definer as $$
  select id from public.order_lines where order_id = p_order limit 1;
$$;
grant execute on function t.pay_of(uuid), t.line_id(uuid) to anon, authenticated;
create function t.paid_order(p_qty int default 1, p_points bigint default 0) returns uuid language plpgsql as $$
declare
  v uuid := t.order_of(t.buy('b4000000-0000-0000-0000-000000000002', t.id('s'), t.id('p'), p_qty, p_points));
begin
  perform t.succeed(t.pay_of(v));
  return v;
end;
$$;
create function t.owner_ready(p_order uuid) returns void language plpgsql as $$
begin
  perform t.as_user('b4000000-0000-0000-0000-000000000001');
  perform public.shop_mark_ready(p_order);
  perform t.reset();
end;
$$;
create function t.as_buyer(p_sql text) returns void language plpgsql as $$
begin
  perform t.as_user('b4000000-0000-0000-0000-000000000002');
  execute p_sql;
  perform t.reset();
end;
$$;
grant execute on function t.as_buyer(text) to anon, authenticated;

insert into ids values ('s', t.shop('b4000000-0000-0000-0000-000000000001'));
insert into ids values ('p', t.product(t.id('s'), 10000, 20));

-- Yes, I got it all.
insert into ids values ('o1', t.paid_order());
select t.as_user('b4000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.shop_mark_ready(%L)$$, t.id('o1')), '%isn''t yours%', 'a stranger can''t mark it ready');
select throws_like(format($$select public.shop_collected(%L)$$, t.id('o1')), '%isn''t yours%', 'or confirm it');
select throws_like(format($$select public.shop_order(%L)$$, t.id('o1')), '%isn''t yours%', 'or read it');
select t.reset();
select t.as_user('b4000000-0000-0000-0000-000000000001');
select throws_like(format($$select public.shop_collected(%L)$$, t.id('o1')), '%isn''t yours%', 'the shop can''t confirm for the buyer');
select t.reset();
select t.owner_ready(t.id('o1'));
select is(t.step(t.id('o1')), 'ready', 'the owner marks it ready');
select ok(exists (select 1 from public.notifications where user_id = 'b4000000-0000-0000-0000-000000000002' and title = 'Ready to collect'), 'and the buyer is told');
select t.as_buyer(format($$select public.shop_collected(%L)$$, t.id('o1')));
select is(t.step(t.id('o1')), 'collected', 'yes, I got it all');
select is(t.bal('held', t.id('o1')), 0::bigint, 'releases the money');
select is(t.bal('organizer', 'b4000000-0000-0000-0000-000000000001'), -9000::bigint, 'S$90.00 to the shop');
select is((select sum(e.amount_minor)::bigint from public.ledger_entries e join public.ledger_transactions x on x.id = e.transaction_id
  join public.ledger_accounts a on a.id = e.account_id
  where x.idempotency_key = 'release:' || t.pay_of(t.id('o1')) and a.kind = 'platform_fees'), -1000::bigint, 'and S$10.00 commission');
select t.as_user('b4000000-0000-0000-0000-000000000002');
select lives_ok(format($$select public.shop_collected(%L)$$, t.id('o1')), 'a double tap does nothing');
select throws_like(format($$select public.shop_report_problem(%L, 'Late')$$, t.id('o1')), '%closed%', 'no report after it''s collected');
select throws_like(format($$select public.shop_order_cancel(%L, 'Late')$$, t.id('o1')), '%can''t be cancelled%', 'and no cancel');
select t.reset();

-- Report a problem.
insert into ids values ('o2', t.paid_order());
select t.owner_ready(t.id('o2'));
select t.as_buyer(format($$select public.shop_report_problem(%L, 'One item is missing')$$, t.id('o2')));
select is(t.step(t.id('o2')), 'reported', 'a report holds it');
select is(t.bal('held', t.id('o2')), -10000::bigint, 'the money stays');
select ok(exists (select 1 from public.money_alerts where key = 'order-reported:' || t.id('o2')), 'and staff are alerted');
update public.orders set step = step where id = t.id('o2');
select private.holds_sweep();
select is(t.step(t.id('o2')), 'reported', 'a report stops the timer');

-- Staff release it.
select t.as_staff('b4000000-0000-0000-0000-000000000004');
select public.staff_order_decide(t.id('o2'), '[]', false, 'Nothing was missing', 'decide-key-1');
select t.reset();
select is(t.step(t.id('o2')), 'released', 'staff can release a report');
select is(t.bal('held', t.id('o2')), 0::bigint, 'and the money moves');

-- Staff refund part.
insert into ids values ('o3', t.paid_order(2));
select t.as_buyer(format($$select public.shop_report_problem(%L, 'One was broken')$$, t.id('o3')));
select t.as_staff('b4000000-0000-0000-0000-000000000004');
select is(public.staff_order_decide(t.id('o3'), jsonb_build_array(jsonb_build_object('line', t.line_id(t.id('o3')), 'qty', 1)), true, 'One unit damaged', 'decide-key-2'), 10000::bigint, 'one of two comes back');
select t.reset();
select is(t.step(t.id('o3')), 'released', 'and the rest goes to the shop');
select is(t.bal('held', t.id('o3')), 0::bigint, 'nothing stays held');
select is((select sum(e.amount_minor)::bigint from public.ledger_entries e join public.ledger_transactions x on x.id = e.transaction_id
  join public.ledger_accounts a on a.id = e.account_id
  where x.idempotency_key = 'release:' || t.pay_of(t.id('o3')) and a.kind = 'organizer'), -9000::bigint, 'the shop gets the share of what stayed sold');

-- Staff refund everything, with points.
select t.give_points('b4000000-0000-0000-0000-000000000002', 500);
insert into ids values ('o4', t.paid_order(1, 500));
select t.as_buyer(format($$select public.shop_report_problem(%L, 'Wrong item')$$, t.id('o4')));
select t.as_staff('b4000000-0000-0000-0000-000000000004');
select public.staff_order_decide(t.id('o4'), jsonb_build_array(jsonb_build_object('line', t.line_id(t.id('o4')), 'qty', 1)), false, 'Wrong item given', 'decide-key-3');
select t.reset();
select is(t.step(t.id('o4')), 'refunded', 'refunding it all closes the order');
select is(t.refunded(t.pay_of(t.id('o4'))), 9500::bigint, 'the card gets what it paid');
select is(private.points_balance('b4000000-0000-0000-0000-000000000002'), 500::bigint, 'and the points come back');

-- After release, staff only, split between the shop and the commission.
create temp table before_org on commit drop as select t.bal('organizer', 'b4000000-0000-0000-0000-000000000001') as v;
select t.as_staff('b4000000-0000-0000-0000-000000000004');
select public.staff_order_decide(t.id('o1'), jsonb_build_array(jsonb_build_object('line', t.line_id(t.id('o1')), 'qty', 1)), false, 'Goodwill refund', 'decide-key-4');
select t.reset();
select is(t.step(t.id('o1')), 'refunded', 'staff can refund after release (Q93 default)');
select is(t.bal('organizer', 'b4000000-0000-0000-0000-000000000001') - (select v from before_org), 9000::bigint, 'the shop gives back its S$90.00, not the commission');

-- Buyer cancels before collecting.
create temp table s0 on commit drop as select t.stock(t.id('p')) as v;
insert into ids values ('o5', t.paid_order());
select t.as_user('b4000000-0000-0000-0000-000000000002');
select is(public.shop_order_cancel(t.id('o5'), 'Changed my mind'), 10000::bigint, 'cancelling before collecting refunds everything');
select t.reset();
select is(t.step(t.id('o5')), 'cancelled', 'and closes the order');
select is(t.stock(t.id('p')), (select v from s0), 'stock is back');
select is(t.bal('held', t.id('o5')), 0::bigint, 'nothing held');

-- Shop cancels.
insert into ids values ('o6', t.paid_order());
select t.fee(t.pay_of(t.id('o6')), 390);
select t.as_user('b4000000-0000-0000-0000-000000000001');
select public.shop_owner_cancel(t.id('o6'), 'Out of stock');
select t.reset();
select t.settle_refunds(t.pay_of(t.id('o6')));
select is(t.refunded(t.pay_of(t.id('o6'))), 10000::bigint, 'the shop cancelling refunds everything');
select is(t.bal('card_fee_recovery', 'b4000000-0000-0000-0000-000000000001'), 390::bigint, 'and the card fee is on the shop');

-- Started services can't be cancelled by the buyer.
insert into ids values ('sv', t.product(t.id('s'), 3000, 0, true));
insert into ids values ('o7', t.order_of(t.buy('b4000000-0000-0000-0000-000000000002', t.id('s'), t.id('sv'), 1, 0, now() + interval '2 days')));
select t.succeed(t.pay_of(t.id('o7')));
select t.as_user('b4000000-0000-0000-0000-000000000001');
select public.shop_mark_started(t.id('o7'));
select t.reset();
select t.as_user('b4000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.shop_order_cancel(%L, 'Too late')$$, t.id('o7')), '%can''t be cancelled%', 'a started service can''t be cancelled');
select t.reset();

-- The clock.
insert into ids values ('o8', t.paid_order());
select t.owner_ready(t.id('o8'));
alter table public.orders disable trigger orders_guard;
update public.orders set release_at = now() - interval '1 minute', ready_at = ready_at - interval '9 days' where id = t.id('o8');
alter table public.orders enable trigger orders_guard;
select t.as_user('b4000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.shop_report_problem(%L, 'Late')$$, t.id('o8')), '%too late%', 'a report after the clock is refused, sweep or no sweep');
select throws_like(format($$select public.shop_order_cancel(%L, 'Late')$$, t.id('o8')), '%too late%', 'and so is a cancel');
select t.reset();
select private.orders_sweep();
select is(t.step(t.id('o8')), 'released', 'the timer releases a ready order');
select is(t.bal('held', t.id('o8')), 0::bigint, 'and the money');
select private.orders_sweep();
select is((select count(*)::int from public.ledger_transactions where idempotency_key = 'release:' || t.pay_of(t.id('o8'))), 1, 'once');

-- A shop that never marks it ready waits for a person.
insert into ids values ('o9', t.paid_order());
alter table public.orders disable trigger orders_guard;
update public.orders set release_at = now() - interval '1 minute', ready_at = ready_at - interval '9 days' where id = t.id('o9');
alter table public.orders enable trigger orders_guard;
select private.orders_sweep();
select is(t.step(t.id('o9')), 'paid', 'not ready means no release');
select ok(exists (select 1 from public.money_alerts where key = 'order-stale:' || t.id('o9')), 'and an alert');

-- A dispute holds it.
insert into ids values ('o10', t.paid_order());
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_shop', 'charge', 'ch_' || t.pay_of(t.id('o10')), 'amount', 10000));
select t.as_buyer(format($$select public.shop_collected(%L)$$, t.id('o10')));
select is(t.bal('held', t.id('o10')), -10000::bigint, 'an open dispute holds the release');
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_shop', 'status', 'won', 'amount', 10000));

-- Transition table.
select throws_like(format($$update public.orders set step = 'pending' where id = %L$$, t.id('o1')), '%can''t go from%', 'orders only move forward');
select throws_like(format($$update public.orders set release_at = now() where id = %L$$, t.id('o9')), '%release time%', 'the clock can''t be moved');

-- Owner's view, and their money.
select t.as_user('b4000000-0000-0000-0000-000000000001');
select ok(jsonb_array_length(public.shop_owner_orders()) > 0, 'the owner sees their orders');
select t.reset();
select t.as_user('b4000000-0000-0000-0000-000000000003');
select is(jsonb_array_length(public.shop_owner_orders()), 0, 'a stranger sees none');
select t.reset();

-- Reviews need collecting.
select t.as_buyer(format($$select public.shop_review(%L, 5, '{}', 'Good', false)$$, t.id('o10')));
select is((select reviewed from public.orders where id = t.id('o10')), true, 'a collected order can be reviewed');
select t.as_user('b4000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.shop_review(%L, 5, '{}', 'Never had it', false)$$, t.id('o8')), '%collected it%',
  'one the timer released can''t');
select t.reset();

select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
