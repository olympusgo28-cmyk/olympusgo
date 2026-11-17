-- P4b-03: prices, reservations, capture and late money.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('b3000000-0000-0000-0000-000000000001');  -- owner
select t.player('b3000000-0000-0000-0000-000000000002');  -- buyer
select t.player('b3000000-0000-0000-0000-000000000003');  -- buyer
select t.player('b3000000-0000-0000-0000-000000000004', 12);  -- unlinked child
select t.player('b3000000-0000-0000-0000-000000000005');  -- owner of the on-top shop
select t.player('b3000000-0000-0000-0000-000000000006', 11);  -- linked child
select t.player('b3000000-0000-0000-0000-000000000007');  -- owner
select t.player('b3000000-0000-0000-0000-000000000008');  -- owner
select t.player('b3000000-0000-0000-0000-000000000009');  -- owner
insert into public.guardian_links (child_id, parent_id, status)
values ('b3000000-0000-0000-0000-000000000006', 'b3000000-0000-0000-0000-000000000003', 'approved');

insert into public.app_settings (key, value) values ('points.redeem_min_account_days', '0');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;
create function t.line(p_order uuid) returns public.order_lines language sql security definer as $$
  select * from public.order_lines where order_id = p_order limit 1;
$$;
create function t.pay_of(p_order uuid) returns uuid language sql security definer as $$
  select id from public.payments where order_id = p_order;
$$;
grant execute on function t.pay_of(uuid) to anon, authenticated;

insert into ids values ('s', t.shop('b3000000-0000-0000-0000-000000000001'));
insert into ids values ('p', t.product(t.id('s'), 10000, 5));
insert into ids values ('top', t.shop('b3000000-0000-0000-0000-000000000005', true));
insert into ids values ('tp', t.product(t.id('top'), 10000, 5));

-- The checklist's examples.
create temp table b1 on commit drop as select t.buy('b3000000-0000-0000-0000-000000000002', t.id('s'), t.id('p')) as v;
insert into ids values ('o1', t.order_of((select v from b1)));
select is((select (v ->> 'amount_minor')::int from b1), 10000, 'S$100.00 by default');
select is((t.line(t.id('o1'))).unit_shop, 9000::bigint, 'the shop gets S$90.00');
select is((t.line(t.id('o1'))).unit_commission, 1000::bigint, 'OlympusGO gets S$10.00');
select is(t.stock(t.id('p')), 4, 'stock is taken');
select is(t.step(t.id('o1')), 'pending', 'and the order waits for the webhook');

create temp table b2 on commit drop as select t.buy('b3000000-0000-0000-0000-000000000002', t.id('top'), t.id('tp')) as v;
select is((select (v ->> 'amount_minor')::int from b2), 11000, 'S$110.00 with the switch on');
select is((t.line(t.order_of((select v from b2)))).unit_shop, 10000::bigint, 'and the shop gets S$100.00');

-- Rounding per unit.
insert into ids values ('r', t.product(t.id('s'), 1005, 9));
select is((private.shop_price(t.id('s'), jsonb_build_array(jsonb_build_object('product_id', t.id('r'), 'variant', '', 'qty', 3)), 0)
  -> 'lines' -> 0 ->> 'unit_commission')::int, 101, 'commission rounds half up per unit');
select is((private.shop_price(t.id('s'), jsonb_build_array(jsonb_build_object('product_id', t.id('r'), 'variant', '', 'qty', 3)), 150)
  -> 'lines' -> 0 ->> 'unit_points')::int, 50, 'the cap is half, rounded down');
select is((private.shop_price(t.id('s'), jsonb_build_array(jsonb_build_object('product_id', t.id('r'), 'variant', '', 'qty', 3)), 149)
  -> 'lines' -> 0 ->> 'unit_points')::int, 49, 'points spread per unit');

-- Double tap and a second key.
insert into ids values ('s2', t.shop('b3000000-0000-0000-0000-000000000007'));
select is(t.order_of(t.buy('b3000000-0000-0000-0000-000000000002', t.id('s'), t.id('p'), 1, 0, null, 'other-key-1')), t.id('o1'), 'a live order is reused, not doubled');
select is(t.stock(t.id('p')), 4, 'so stock is taken once');
select is((select count(*)::int from public.orders where mall_id = t.id('s')), 1, 'and there''s one order');

-- The price shown is the price charged.
select t.as_user('b3000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.shop_reserve(%L, 'wrong-price-key', 1, 0, %L)$$, t.id('s'), jsonb_build_object('product', t.id('p'))),
  'price_changed', 'a changed price stops the charge');
select t.reset();
select is(t.stock(t.id('p')), 4, 'and takes no stock');

-- Who can't buy.
select t.as_user('b3000000-0000-0000-0000-000000000004');
select throws_like(format($$select public.shop_reserve(%L, 'child-key-1', 10000, 0, %L)$$, t.id('s'), jsonb_build_object('product', t.id('p'))), '%parent%', 'a restricted child can''t');
select t.reset();
select t.as_user('b3000000-0000-0000-0000-000000000006');
select throws_like(format($$select public.shop_reserve(%L, 'child-key-2', 10000, 0, %L)$$, t.id('s'), jsonb_build_object('product', t.id('p'))), '%parent%', 'a linked under-13 can''t (Q88 default)');
select t.reset();
select t.as_user('b3000000-0000-0000-0000-000000000001');
select throws_like(format($$select public.shop_reserve(%L, 'own-shop-key', 10000, 0, %L)$$, t.id('s'), jsonb_build_object('product', t.id('p'))), '%own shop%', 'an owner can''t buy from themselves');
select t.reset();
select t.as_anon();
select throws_ok(format($$select public.shop_reserve(%L, 'anon-key-01', 10000)$$, t.id('s')), '42501', null, 'signed out can''t');
select t.reset();
update public.feature_flags set enabled = false where key = 'shop.checkout';
select t.as_user('b3000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.shop_reserve(%L, 'flag-off-key', 10000, 0, %L)$$, t.id('s'), jsonb_build_object('product', t.id('p'))), '%isn''t open yet%', 'the flag stops checkout');
select t.reset();
update public.feature_flags set enabled = true where key = 'shop.checkout';

-- Stock can't oversell.
insert into ids values ('last', t.product(t.id('s2'), 1000, 1));
select t.buy('b3000000-0000-0000-0000-000000000002', t.id('s2'), t.id('last'));
select t.as_user('b3000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.shop_reserve(%L, 'too-late-key', 1000, 0, %L)$$, t.id('s2'), jsonb_build_object('product', t.id('last'))), 'Not enough%', 'the last unit sells once');
select t.reset();

-- Webhook.
insert into ids values ('p1', t.pay_of(t.id('o1')));
select is(t.succeed(t.id('p1'), 'paynow', 'evt_shop_1'), 'seated', 'the webhook confirms an order');
select is(t.step(t.id('o1')), 'paid', 'paid');
select is(t.bal('held', t.id('o1')), -10000::bigint, 'and all of it is held');
select is(t.succeed(t.id('p1'), 'paynow', 'evt_shop_1'), 'duplicate', 'a replay does nothing');
select is(t.bal('held', t.id('o1')), -10000::bigint, 'held once');
select ok((select release_at = collect_by + interval '48 hours' from public.orders where id = t.id('o1')), 'release is 48 hours after collect-by');
select ok((select abs(extract(epoch from collect_by - now() - interval '7 days')) < 5 from public.orders where id = t.id('o1')), 'collect-by is 7 days out');

-- Points at checkout.
insert into ids values ('s3', t.shop('b3000000-0000-0000-0000-000000000008'));
insert into ids values ('p3', t.product(t.id('s3'), 10000, 5));
select t.give_points('b3000000-0000-0000-0000-000000000003', 500);
create temp table b3 on commit drop as select t.buy('b3000000-0000-0000-0000-000000000003', t.id('s3'), t.id('p3'), 1, 500) as v;
insert into ids values ('o3', t.order_of((select v from b3)));
select is((select (v ->> 'amount_minor')::int from b3), 9500, 'S$5.00 of points takes S$5.00 off');
select is((t.line(t.id('o3'))).unit_shop, 9000::bigint, 'and the shop still gets S$90.00');
select is(private.points_balance('b3000000-0000-0000-0000-000000000003'), 0::bigint, 'the points are spent');
select t.as_user('b3000000-0000-0000-0000-000000000003');
select public.payment_abandon(t.pay_of(t.id('o3')));
select t.reset();
select is(t.step(t.id('o3')), 'cancelled', 'giving up cancels the order');
select is(t.stock(t.id('p3')), 5, 'stock comes back');
select is(private.points_balance('b3000000-0000-0000-0000-000000000003'), 500::bigint, 'and the points');

-- Points past the cap are refused.
select t.give_points('b3000000-0000-0000-0000-000000000003', 5000);
select t.as_user('b3000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.shop_reserve(%L, 'over-cap-key', 9000, 1000, %L)$$, t.id('s3'), jsonb_build_object('product', t.id('p3'))), '%up to 50 points%', 'points stop at half the commission');
select t.reset();

-- Late money.
insert into ids values ('o4', t.order_of(t.buy('b3000000-0000-0000-0000-000000000003', t.id('s3'), t.id('p3'))));
update public.payments set method = 'card', stripe_intent_id = 'pi_o4' where id = t.pay_of(t.id('o4'));
update public.orders set hold_until = now() - interval '1 second' where id = t.id('o4');
update public.payments set hold_until = now() - interval '1 second' where id = t.pay_of(t.id('o4'));
select private.holds_sweep();
select is(t.step(t.id('o4')), 'expired', 'an unpaid hold expires');
select is(t.stock(t.id('p3')), 5, 'and stock comes back');
select is(t.status_pay(t.pay_of(t.id('o4'))), 'cancel_requested', 'Stripe is told to stop');
select private.holds_sweep();
select is(t.stock(t.id('p3')), 5, 'stock returns once');
select is(t.succeed(t.pay_of(t.id('o4'))), 'refunded', 'money after expiry goes back');
select is(t.refunded(t.pay_of(t.id('o4'))), 10000::bigint, 'in full');
select is(t.step(t.id('o4')), 'expired', 'and never takes the item');
select is(t.stock(t.id('p3')), 5, 'nor stock');

-- A webhook just past the hold, ahead of the sweep, still counts.
insert into ids values ('o5', t.order_of(t.buy('b3000000-0000-0000-0000-000000000003', t.id('s3'), t.id('p3'))));
update public.orders set hold_until = now() - interval '1 second' where id = t.id('o5');
update public.payments set hold_until = now() - interval '1 second' where id = t.pay_of(t.id('o5'));
select is(t.succeed(t.pay_of(t.id('o5'))), 'seated', 'while the order is pending the money is in time');

-- Blocked while paying.
insert into ids values ('o6', t.order_of(t.buy('b3000000-0000-0000-0000-000000000002', t.id('s3'), t.id('p3'))));
insert into public.blocks (blocker_id, blocked_id) values ('b3000000-0000-0000-0000-000000000008', 'b3000000-0000-0000-0000-000000000002');
select is(t.succeed(t.pay_of(t.id('o6'))), 'refunded', 'a buyer blocked while paying is refunded');
select is(t.step(t.id('o6')), 'cancelled', 'and the order ends');
delete from public.blocks where blocker_id = 'b3000000-0000-0000-0000-000000000008';

-- Services.
insert into ids values ('sv', t.product(t.id('s3'), 3000, 0, true));
select t.as_user('b3000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.shop_cart_add(%L, '', 1)$$, t.id('sv')), '%Book this%', 'a service doesn''t go in a cart');
select throws_like(format($$select public.shop_reserve(%L, 'no-slot-key-1', 3000, 0, %L)$$, t.id('s3'), jsonb_build_object('product', t.id('sv'))), '%Pick a time%', 'a service needs a time');
select t.reset();
insert into ids values ('o7', t.order_of(t.buy('b3000000-0000-0000-0000-000000000002', t.id('s3'), t.id('sv'), 1, 0, now() + interval '3 days')));
select t.succeed(t.pay_of(t.id('o7')));
select ok((select collect_by = slot_at from public.orders where id = t.id('o7')), 'a service''s collect-by is its slot');

-- A second try at a shop while one is unpaid can't charge a different price.
insert into ids values ('s9m', t.shop('b3000000-0000-0000-0000-000000000009'));
insert into ids values ('p9m', t.product(t.id('s9m'), 10000, 5));
select t.buy('b3000000-0000-0000-0000-000000000002', t.id('s9m'), t.id('p9m'));
select t.as_user('b3000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.shop_reserve(%L, 'another-try-1', 20000, 0,
    jsonb_build_object('product', %L, 'qty', 2))$$, t.id('s9m'), t.id('p9m')),
  '%unpaid order%', 'an unpaid order at another price stops the charge');
select lives_ok(format($$select public.shop_reserve(%L, 'another-try-2', 10000, 0,
    jsonb_build_object('product', %L, 'qty', 1))$$, t.id('s9m'), t.id('p9m')),
  'the same price picks that order up');
select t.reset();

-- One order per payment.
select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
