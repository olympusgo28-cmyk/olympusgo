-- P4d-03: vouchers at Shop checkout. Voucher or points, per item, with the shop
-- funding it and commission on the price after the voucher (decision 7).
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('d2000000-0000-0000-0000-000000000001');  -- shop owner
select t.player('d2000000-0000-0000-0000-000000000002');  -- buyer
select t.player('d2000000-0000-0000-0000-000000000003');  -- someone else
select t.player('d2000000-0000-0000-0000-000000000004');  -- payments staff
insert into public.staff (user_id, role) values ('d2000000-0000-0000-0000-000000000004', 'payments');
insert into public.app_settings (key, value) values ('points.redeem_min_account_days', '0');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;

insert into ids select 'mall', t.shop('d2000000-0000-0000-0000-000000000001');
insert into ids select 'other_mall', t.shop('d2000000-0000-0000-0000-000000000003');
insert into ids select 'top_mall', t.shop('d2000000-0000-0000-0000-000000000004', true);
insert into ids select 'item', t.product(t.id('mall'), 10000, 20);
insert into ids select 'cheap', t.product(t.id('mall'), 500, 20);
insert into ids select 'top_item', t.product(t.id('top_mall'), 10000, 20);

create function t.vtype(p_mall uuid, p_off bigint default 800, p_product uuid default null) returns uuid
language sql security definer as $$
  insert into public.voucher_types (name, kind, mall_id, amount_minor, product_id)
  values ('S$8 off', 'A', p_mall, p_off, p_product) returning id;
$$;
insert into ids select 'type', t.vtype(t.id('mall'));
create function t.give(p_user uuid, p_type uuid default null) returns uuid language plpgsql security definer as $$
declare
  v uuid;
  v_source text := 'test:' || gen_random_uuid();
begin
  perform private.voucher_issue(coalesce(p_type, t.id('type')), p_user, v_source);
  select id into v from public.vouchers where source = v_source;
  return v;
end;
$$;
create function t.vbuy(p_user uuid, p_mall uuid, p_product uuid, p_voucher uuid, p_qty int default 1, p_points bigint default 0,
  p_key text default null) returns jsonb language plpgsql as $$
declare
  v_only jsonb := jsonb_build_object('product', p_product, 'qty', p_qty);
  q jsonb;
  v jsonb;
begin
  perform t.as_user(p_user);
  q := public.shop_quote(p_mall, v_only, p_points, p_voucher);
  v := public.shop_reserve(p_mall, coalesce(p_key, 'key-' || gen_random_uuid()),
    (q ->> 'total_minor')::bigint, p_points, v_only, null, p_voucher);
  perform t.reset();
  return v;
end;
$$;
create function t.vstatus(p_voucher uuid) returns text language sql security definer as $$
  select status from public.vouchers where id = p_voucher;
$$;
create function t.oid(p jsonb) returns uuid language sql as $$ select (p ->> 'order_id')::uuid; $$;
grant execute on all functions in schema t to anon, authenticated, service_role;

-- ─── Prices ────────────────────────────────────────────────────────────────

insert into ids select 'v1', t.give('d2000000-0000-0000-0000-000000000002');
select t.as_user('d2000000-0000-0000-0000-000000000002');
create temp table q1 as select public.shop_quote(t.id('mall'), jsonb_build_object('product', t.id('item'), 'qty', 1), 0, t.id('v1')) as q;
select t.reset();
select is(((select q from q1) ->> 'total_minor')::bigint, 9200::bigint, 'S$100.00 less S$8.00 is S$92.00');
select is(((select q from q1) -> 'lines' -> 0 ->> 'unit_commission')::bigint, 920::bigint, 'commission is 10% of the price after the voucher');
select is(((select q from q1) -> 'lines' -> 0 ->> 'unit_shop')::bigint, 8280::bigint, 'and the shop funds it, at S$82.80');

insert into ids select 'top_type', t.vtype(t.id('top_mall'));
insert into ids select 'v_top', t.give('d2000000-0000-0000-0000-000000000002', t.id('top_type'));
select t.as_user('d2000000-0000-0000-0000-000000000002');
create temp table q2 as select public.shop_quote(t.id('top_mall'), jsonb_build_object('product', t.id('top_item'), 'qty', 1), 0, t.id('v_top')) as q;
select t.reset();
select is(((select q from q2) ->> 'total_minor')::bigint, 10120::bigint, 'on-top: S$92.00 plus 10%');
select is(((select q from q2) -> 'lines' -> 0 ->> 'unit_shop')::bigint, 9200::bigint, 'and the shop gets S$92.00');

-- The floor.
select t.as_user('d2000000-0000-0000-0000-000000000002');
select is((public.shop_quote(t.id('mall'), jsonb_build_object('product', t.id('cheap'), 'qty', 1), 0, t.id('v1')) ->> 'total_minor')::bigint,
  50::bigint, 'a voucher bigger than the price leaves S$0.50 to pay');
select t.reset();

-- ─── More than one, and points beside it ───────────────────────────────────

select t.as_user('d2000000-0000-0000-0000-000000000002');
create temp table q3 as select public.shop_quote(t.id('mall'), jsonb_build_object('product', t.id('item'), 'qty', 3), 0, t.id('v1')) as q;
select t.reset();
select is(jsonb_array_length((select q from q3) -> 'lines'), 2, 'two of three stay apart from the discounted one');
select is(((select q from q3) ->> 'total_minor')::bigint, 29200::bigint, 'one unit takes the voucher');

insert into public.points_entries (id, user_id, kind, amount_minor, lot_id, expires_at, source_kind, source_id, idempotency_key)
values (990001, 'd2000000-0000-0000-0000-000000000002', 'earn', 5000, 990001, now() + interval '300 days', 'test', '990001', 'test:990001');
select t.as_user('d2000000-0000-0000-0000-000000000002');
create temp table q4 as select public.shop_quote(t.id('mall'), jsonb_build_object('product', t.id('item'), 'qty', 2), 500, t.id('v1')) as q;
select t.reset();
select is(((select q from q4) -> 'lines' -> 0 ->> 'unit_points')::bigint, 0::bigint, 'the voucher unit takes no points');
select is(((select q from q4) -> 'lines' -> 1 ->> 'unit_points')::bigint, 500::bigint, 'the other unit can');
select is(((select q from q4) -> 'lines' -> 1 ->> 'unit_voucher')::bigint, 0::bigint, 'and takes no voucher');

-- ─── Who can use it ────────────────────────────────────────────────────────

select t.as_user('d2000000-0000-0000-0000-000000000003');
select throws_ok($$ select public.shop_quote(t.id('mall'), jsonb_build_object('product', t.id('item'), 'qty', 1), 0, t.id('v1')) $$,
  'This voucher isn''t yours.', 'someone else''s voucher is refused');
select t.reset();
select t.as_user('d2000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.shop_quote(t.id('other_mall'), '{"product": "00000000-0000-0000-0000-000000000000", "qty": 1}', 0, t.id('v1')) $$,
  'This voucher is for another shop.', 'at another shop too');
select t.reset();

insert into ids select 'only_item', t.vtype(t.id('mall'), 300, t.id('item'));
insert into ids select 'v_item', t.give('d2000000-0000-0000-0000-000000000002', t.id('only_item'));
select t.as_user('d2000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.shop_quote(t.id('mall'), jsonb_build_object('product', t.id('cheap'), 'qty', 1), 0, t.id('v_item')) $$,
  'This voucher doesn''t fit anything in your cart.', 'a voucher for one product fits only that');
select t.reset();

insert into ids select 'v_old', t.give('d2000000-0000-0000-0000-000000000002');
update public.vouchers set expires_at = now() - interval '1 minute' where id = t.id('v_old');
select t.as_user('d2000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.shop_quote(t.id('mall'), jsonb_build_object('product', t.id('item'), 'qty', 1), 0, t.id('v_old')) $$,
  'This voucher has expired.', 'an expired voucher is refused');
select t.reset();

insert into ids select 'venue', id from public.venues order by name limit 1;
create function t.btype() returns uuid language sql security definer as $$
  insert into public.voucher_types (name, kind, venue_id, amount_minor) values ('Hall', 'B', t.id('venue'), 600) returning id;
$$;
insert into ids select 'b', t.btype();
insert into ids select 'v_b', t.give('d2000000-0000-0000-0000-000000000002', t.id('b'));
select is(t.vstatus(t.id('v_b')), 'held', 'Voucher B is held');
select t.as_user('d2000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.shop_quote(t.id('mall'), jsonb_build_object('product', t.id('item'), 'qty', 1), 0, t.id('v_b')) $$,
  'This voucher opens with court booking.', 'and can''t be spent yet');
select t.reset();

-- ─── The code stays with its owner ─────────────────────────────────────────

select t.as_user('d2000000-0000-0000-0000-000000000002');
select ok((public.voucher_my() -> 0 ->> 'code') is not null, 'the owner sees the code');
select t.reset();
select t.as_user('d2000000-0000-0000-0000-000000000003');
select is(public.voucher_my(), '[]'::jsonb, 'nobody else sees their vouchers');
select t.reset();
select is((select count(*) from public.notifications n join public.vouchers v on n.body like '%' || v.code || '%'), 0::bigint, 'no notification carries a code');

-- ─── Spending and getting it back ──────────────────────────────────────────

insert into ids select 'o1', t.oid(t.vbuy('d2000000-0000-0000-0000-000000000002', t.id('mall'), t.id('item'), t.id('v1')));
select is(t.vstatus(t.id('v1')), 'used', 'reserving spends the voucher');
select is((select amount_minor from public.payments where order_id = t.id('o1')), 9200::bigint, 'the payment is what''s left');
select is((select count(*) from public.voucher_redemptions where voucher_id = t.id('v1') and kind = 'used'), 1::bigint, 'and it''s logged');
select throws_ok($$ select t.vbuy('d2000000-0000-0000-0000-000000000002', t.id('mall'), t.id('item'), t.id('v1')) $$,
  'This voucher has been used.', 'it can''t be spent twice');
select t.reset();

select t.succeed((select id from public.payments where order_id = t.id('o1')));
select t.as_user('d2000000-0000-0000-0000-000000000002');
select public.shop_order_cancel(t.id('o1'), 'Changed my mind');
select public.shop_order_cancel(t.id('o1'), 'Again') where false;
select t.reset();
select is(t.vstatus(t.id('v1')), 'issued', 'cancelling gives it back');
select is((select count(*) from public.voucher_redemptions where voucher_id = t.id('v1') and kind = 'returned'), 1::bigint, 'once');
select is((select stock from public.products where id = t.id('item')), 20, 'with the stock');

-- A voucher past its date when it comes back is simply over.
insert into ids select 'v2', t.give('d2000000-0000-0000-0000-000000000002');
insert into ids select 'o2', t.oid(t.vbuy('d2000000-0000-0000-0000-000000000002', t.id('mall'), t.id('item'), t.id('v2')));
select t.succeed((select id from public.payments where order_id = t.id('o2')));
update public.vouchers set expires_at = now() - interval '1 day' where id = t.id('v2');
select t.as_user('d2000000-0000-0000-0000-000000000002');
select public.shop_order_cancel(t.id('o2'), 'Changed my mind');
select t.reset();
select is(t.vstatus(t.id('v2')), 'expired', 'it keeps its own expiry');

-- Abandoning an unpaid order and an expired hold give it back too.
insert into ids select 'v3', t.give('d2000000-0000-0000-0000-000000000002');
insert into ids select 'o3', t.oid(t.vbuy('d2000000-0000-0000-0000-000000000002', t.id('mall'), t.id('item'), t.id('v3')));
update public.orders set hold_until = now() - interval '1 minute' where id = t.id('o3');
select private.orders_sweep();
select is(t.vstatus(t.id('v3')), 'issued', 'a lapsed hold returns it');

-- The money still adds up through to the shop.
insert into ids select 'v4', t.give('d2000000-0000-0000-0000-000000000002');
insert into ids select 'o4', t.oid(t.vbuy('d2000000-0000-0000-0000-000000000002', t.id('mall'), t.id('item'), t.id('v4')));
select t.succeed((select id from public.payments where order_id = t.id('o4')));
select t.as_user('d2000000-0000-0000-0000-000000000002');
select public.shop_collected(t.id('o4'));
select t.reset();
select is(t.vstatus(t.id('v4')), 'used', 'a collected order keeps the voucher used');
select is(t.bal('held', t.id('o4')), 0::bigint, 'nothing stays held');
select is((select sum(unit_shop * qty)::bigint from public.order_lines where order_id = t.id('o4')), 8280::bigint, 'the shop gets its share of the lower price');
select ok(t.all_balanced(), 'the ledger balances');

-- A dispute lost before collecting ends the order and hands the voucher back.
insert into ids select 'v5', t.give('d2000000-0000-0000-0000-000000000002');
insert into ids select 'o5', t.oid(t.vbuy('d2000000-0000-0000-0000-000000000002', t.id('mall'), t.id('item'), t.id('v5')));
select t.succeed((select id from public.payments where order_id = t.id('o5')));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_v', 'charge', 'ch_' || (select id from public.payments where order_id = t.id('o5')), 'amount', 9200));
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_v', 'status', 'lost', 'amount', 9200));
select is(t.vstatus(t.id('v5')), 'issued', 'a lost dispute hands it back');
select ok(t.all_balanced(), 'and the ledger balances');

-- A staff refund by line leaves it spent.
insert into ids select 'v6', t.give('d2000000-0000-0000-0000-000000000002');
insert into ids select 'o6', t.oid(t.vbuy('d2000000-0000-0000-0000-000000000002', t.id('mall'), t.id('item'), t.id('v6')));
select t.succeed((select id from public.payments where order_id = t.id('o6')));
select t.as_user('d2000000-0000-0000-0000-000000000002');
select public.shop_collected(t.id('o6'));
select t.reset();
select is(t.vstatus(t.id('v6')), 'used', 'and an order that was collected doesn''t');

-- Staff refunding the unit the voucher paid towards: the card gets what it paid,
-- the rest stays sold, and the voucher stays spent.
insert into ids select 'v7', t.give('d2000000-0000-0000-0000-000000000002');
insert into ids select 'o7', t.oid(t.vbuy('d2000000-0000-0000-0000-000000000002', t.id('mall'), t.id('item'), t.id('v7'), 2));
select t.succeed((select id from public.payments where order_id = t.id('o7')));
insert into ids select 'l7', id from public.order_lines where order_id = t.id('o7') and unit_voucher > 0;
select t.as_user('d2000000-0000-0000-0000-000000000002');
select public.shop_report_problem(t.id('o7'), 'One was broken');
select t.as_staff('d2000000-0000-0000-0000-000000000004');
select is(public.staff_order_decide(t.id('o7'), jsonb_build_array(jsonb_build_object('line', t.id('l7'), 'qty', 1)),
    false, 'One unit damaged', 'voucher-decide-1'), 9200::bigint, 'staff refund what was paid on that unit');
select t.reset();
select is(t.vstatus(t.id('v7')), 'used', 'and the voucher stays spent');
select is(t.bal('held', t.id('o7')), 0::bigint, 'nothing stays held');
select ok(t.all_balanced(), 'and the ledger balances');

-- A refund that failed and was voided leaves a cancelled order's voucher where
-- it was: returned, once.
insert into ids select 'v8', t.give('d2000000-0000-0000-0000-000000000002');
insert into ids select 'o8', t.oid(t.vbuy('d2000000-0000-0000-0000-000000000002', t.id('mall'), t.id('item'), t.id('v8')));
select t.succeed((select id from public.payments where order_id = t.id('o8')));
select t.as_user('d2000000-0000-0000-0000-000000000002');
select public.shop_order_cancel(t.id('o8'), 'Changed my mind');
select t.reset();
select t.settle_refunds((select id from public.payments where order_id = t.id('o8')), 'failed');
insert into ids select 'r8', r.id from public.refunds r join public.payments p on p.id = r.payment_id
  where p.order_id = t.id('o8');
select t.as_staff('d2000000-0000-0000-0000-000000000004');
select public.staff_refund_void(t.id('r8'), 'Card closed');
select t.reset();
select is(t.vstatus(t.id('v8')), 'issued', 'a voided refund leaves the voucher returned');
select is((select count(*) from public.voucher_redemptions where voucher_id = t.id('v8') and kind = 'returned'), 1::bigint, 'once');
select ok(t.all_balanced(), 'and the ledger balances');

-- ─── Nobody writes these ───────────────────────────────────────────────────

select t.as_user('d2000000-0000-0000-0000-000000000002');
select throws_ok($$ update public.vouchers set status = 'issued' $$, '42501', null, 'a client can''t revive a voucher');
select throws_ok($$ insert into public.voucher_redemptions (voucher_id, user_id, mall_id, order_id, kind, amount_minor)
  values (t.id('v1'), auth.uid(), t.id('mall'), t.id('o1'), 'returned', 1) $$, '42501', null, 'or write the log');
select t.reset();
select throws_ok($$ delete from public.voucher_redemptions $$, 'P0001', null, 'the log is append-only');

select * from finish();
rollback;
