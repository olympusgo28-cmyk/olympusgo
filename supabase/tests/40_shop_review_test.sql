-- What three independent reviews of Phase 4b found. Each block is a bug that existed.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('b5000000-0000-0000-0000-000000000001');  -- owner
select t.player('b5000000-0000-0000-0000-000000000002');  -- buyer
select t.player('b5000000-0000-0000-0000-000000000003');  -- someone else
select t.player('b5000000-0000-0000-0000-000000000004');  -- payments staff
select t.player('b5000000-0000-0000-0000-000000000005');  -- a teen's parent
select t.player('b5000000-0000-0000-0000-000000000006', 15);  -- a teen
select t.player('b5000000-0000-0000-0000-000000000007');  -- plays and earns
insert into public.guardian_links (child_id, parent_id, status)
values ('b5000000-0000-0000-0000-000000000006', 'b5000000-0000-0000-0000-000000000005', 'approved');
insert into public.staff (user_id, role) values ('b5000000-0000-0000-0000-000000000004', 'payments');
insert into public.app_settings (key, value) values ('points.redeem_min_account_days', '0');
update public.feature_flags set enabled = true where key = 'points.earning';
insert into public.app_settings (key, value) values ('points.weekly_cap_minor', '500');
update public.app_settings set value = '0' where key = 'points.min_confirmed_matches';

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
create function t.lines(p_order uuid, p_qty int) returns jsonb language sql as $$
  select jsonb_build_array(jsonb_build_object('line', t.line_id(p_order), 'qty', p_qty));
$$;
grant execute on function t.pay_of(uuid), t.line_id(uuid), t.lines(uuid, int) to anon, authenticated;
create function t.paid_order(p_qty int default 1, p_points bigint default 0) returns uuid language plpgsql as $$
declare
  v uuid := t.order_of(t.buy('b5000000-0000-0000-0000-000000000002', t.id('s'), t.id('p'), p_qty, p_points));
begin
  perform t.succeed(t.pay_of(v));
  return v;
end;
$$;
create function t.owner(p_sql text) returns void language plpgsql as $$
begin
  perform t.as_user('b5000000-0000-0000-0000-000000000001');
  execute p_sql;
  perform t.reset();
end;
$$;
create function t.buyer(p_sql text) returns void language plpgsql as $$
begin
  perform t.as_user('b5000000-0000-0000-0000-000000000002');
  execute p_sql;
  perform t.reset();
end;
$$;
create function t.ready(p_order uuid) returns void language sql as $$
  select t.owner(format('select public.shop_mark_ready(%L)', p_order));
$$;
create function t.staff_decide(p_order uuid, p_lines jsonb, p_key text) returns bigint language plpgsql as $$
declare
  v bigint;
begin
  perform t.as_staff('b5000000-0000-0000-0000-000000000004');
  v := public.staff_order_decide(p_order, p_lines, false, 'Checked it', p_key);
  perform t.reset();
  return v;
end;
$$;
create function t.overdue(p_order uuid) returns void language plpgsql as $$
begin
  alter table public.orders disable trigger orders_guard;
  update public.orders set release_at = now() - interval '1 minute', ready_at = ready_at - interval '9 days' where id = p_order;
  alter table public.orders enable trigger orders_guard;
end;
$$;
create function t.dispute(p_order uuid, p_id text) returns text language sql as $$
  select t.event('charge.dispute.created', jsonb_build_object('id', p_id, 'charge', 'ch_' || t.pay_of(p_order), 'amount', 10000));
$$;
create function t.dispute_end(p_id text, p_status text) returns text language sql as $$
  select t.event('charge.dispute.closed', jsonb_build_object('id', p_id, 'status', p_status, 'amount', 10000));
$$;

insert into ids values ('s', t.shop('b5000000-0000-0000-0000-000000000001'));
insert into ids values ('p', t.product(t.id('s'), 10000, 50));

-- Refunding a Shop payment outside Orders paid the same money twice.
insert into ids values ('o1', t.paid_order());
select t.as_staff('b5000000-0000-0000-0000-000000000004');
select throws_like(format($$select public.staff_refund_issue(%L, 'Whole thing')$$, t.pay_of(t.id('o1'))), '%by item%',
  'Shop payments are refunded by item, in Orders');
select t.reset();

-- Part of an order still waiting stays waiting, and pays out only once it's collected.
insert into ids values ('o2', t.paid_order(2));
select t.ready(t.id('o2'));
select is(t.staff_decide(t.id('o2'), t.lines(t.id('o2'), 1), 'decide-o2-1'), 10000::bigint, 'one of two refunded');
select is(t.step(t.id('o2')), 'ready', 'the rest waits for the buyer');
select is(t.bal('organizer', 'b5000000-0000-0000-0000-000000000001'), 0::bigint, 'and the shop isn''t paid early');
select is(t.staff_decide(t.id('o2'), t.lines(t.id('o2'), 1), 'decide-o2-1'), 10000::bigint, 'a repeat answers the same');
select is(t.refunded(t.pay_of(t.id('o2'))), 10000::bigint, 'and refunds nothing more');
select t.buyer(format('select public.shop_collected(%L)', t.id('o2')));
select is(t.bal('organizer', 'b5000000-0000-0000-0000-000000000001'), -9000::bigint, 'collecting pays what''s left');
select is(t.bal('held', t.id('o2')), 0::bigint, 'and nothing stays held');

-- A key that names nothing.
select throws_like(format($$select t.staff_decide(%L, %L, 'decide-o1-1')$$, t.id('o1'),
    jsonb_build_array(jsonb_build_object('line', gen_random_uuid(), 'qty', 1))), '%already been refunded%',
  'unknown lines don''t release the order');
select throws_like(format($$select t.staff_decide(%L, '[]', 'decide-o1-2')$$, t.id('o1')), '%isn''t due%',
  'an order that isn''t due can''t be released');

-- Staff can refund a ready order in full.
select t.ready(t.id('o1'));
select is(t.staff_decide(t.id('o1'), t.lines(t.id('o1'), 1), 'decide-o1-3'), 10000::bigint, 'a whole ready order');
select is(t.step(t.id('o1')), 'refunded', 'moves to refunded');

-- A late Mark ready used to start an automatic release the buyer couldn't stop.
insert into ids values ('o3', t.paid_order());
select t.overdue(t.id('o3'));
select throws_like(format($$select t.ready(%L)$$, t.id('o3')), '%past its date%', 'a stale order can''t be marked ready');
select t.buyer(format($$select public.shop_report_problem(%L, 'They never had it ready')$$, t.id('o3')));
select is(t.step(t.id('o3')), 'reported', 'the buyer can still report it');
insert into ids values ('o4', t.paid_order());
select t.overdue(t.id('o4'));
select t.buyer(format($$select public.shop_order_cancel(%L, 'Gave up')$$, t.id('o4')));
select is(t.step(t.id('o4')), 'cancelled', 'or cancel it');
select lives_ok(format($$select t.staff_decide(%L, '[]', 'decide-o3-1')$$, t.id('o3')), 'and staff can decide a stale one');

-- A finished service can't be cancelled.
insert into ids values ('sv', t.product(t.id('s'), 2500, 0, true));
insert into ids values ('o5', t.order_of(t.buy('b5000000-0000-0000-0000-000000000002', t.id('s'), t.id('sv'), 1, 0, now() + interval '3 days')));
select t.succeed(t.pay_of(t.id('o5')));
select t.ready(t.id('o5'));
select t.as_user('b5000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.shop_order_cancel(%L, 'Free work')$$, t.id('o5')), '%work is done%',
  'a ready service can''t be cancelled for a refund');
select t.reset();

-- Collected during a dispute used to stay held for good.
insert into ids values ('o6', t.paid_order());
select t.dispute(t.id('o6'), 'dp_o6');
select t.buyer(format('select public.shop_collected(%L)', t.id('o6')));
select is(t.bal('held', t.id('o6')), -10000::bigint, 'collected during a dispute stays held');
select t.dispute_end('dp_o6', 'won');
select private.orders_sweep();
select is(t.bal('held', t.id('o6')), 0::bigint, 'and the sweep pays the shop once it''s won');

-- A refund after release that waited on a dispute keeps its own split.
insert into ids values ('o7', t.paid_order(2));
select t.buyer(format('select public.shop_collected(%L)', t.id('o7')));
select t.dispute(t.id('o7'), 'dp_o7');
create temp table before (minor bigint);
insert into before select t.bal('organizer', 'b5000000-0000-0000-0000-000000000001');
grant all on before to anon, authenticated;
select t.staff_decide(t.id('o7'), t.lines(t.id('o7'), 1), 'decide-o7-1');
select t.dispute_end('dp_o7', 'won');
select is(t.bal('organizer', 'b5000000-0000-0000-0000-000000000001') - (select minor from before), 9000::bigint,
  'the shop gives back its S$90.00, not the buyer''s S$100.00');
select is((select r.shop_minor from public.refunds r where r.payment_id = t.pay_of(t.id('o7'))), 9000::bigint, 'and that''s recorded');

-- Voiding a refund staff made before release puts the split back, and the line.
insert into ids values ('o8', t.paid_order(2));
select t.buyer(format($$select public.shop_report_problem(%L, 'One was broken')$$, t.id('o8')));
truncate before;
insert into before select t.bal('organizer', 'b5000000-0000-0000-0000-000000000001');
select t.staff_decide(t.id('o8'), t.lines(t.id('o8'), 1), 'decide-o8-1');
select is(t.bal('organizer', 'b5000000-0000-0000-0000-000000000001') - (select minor from before), -9000::bigint, 'the rest went to the shop');
select t.settle_refunds(t.pay_of(t.id('o8')), 'failed');
insert into ids select 'r8', r.id from public.refunds r where r.payment_id = t.pay_of(t.id('o8'));
select t.as_staff('b5000000-0000-0000-0000-000000000004');
select public.staff_refund_void(t.id('r8'), 'Bank refused it');
select t.reset();
select is(t.bal('organizer', 'b5000000-0000-0000-0000-000000000001') - (select minor from before), -18000::bigint,
  'voiding credits the shop S$90.00, not the whole S$100.00');
select is((select refunded_qty from public.order_lines where id = t.line_id(t.id('o8'))), 0, 'and the line counts as sold again');

-- A refund and a chargeback on the same order.
insert into ids values ('o9', t.paid_order());
select t.dispute(t.id('o9'), 'dp_o9');
select t.buyer(format($$select public.shop_order_cancel(%L, 'Changed my mind')$$, t.id('o9')));
select t.dispute_end('dp_o9', 'lost');
select is(t.bal('held', t.id('o9')), 0::bigint, 'a cancelled order that lost its dispute ends at zero');

insert into ids values ('o10', t.paid_order());
select t.buyer(format($$select public.shop_order_cancel(%L, 'Changed my mind')$$, t.id('o10')));
select t.settle_refunds(t.pay_of(t.id('o10')));
select t.dispute(t.id('o10'), 'dp_o10');
select t.dispute_end('dp_o10', 'lost');
select is(t.bal('held', t.id('o10')), 0::bigint, 'refunded and charged back still ends at zero');
select is(t.bal('disputes_open'), 0::bigint, 'with nothing left open');

insert into ids values ('o11', t.paid_order(2));
select t.ready(t.id('o11'));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_o11', 'charge', 'ch_' || t.pay_of(t.id('o11')), 'amount', 20000));
create temp table stock_now (n int);
insert into stock_now select t.stock(t.id('p'));
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_o11', 'status', 'lost', 'amount', 20000));
select is(t.step(t.id('o11')), 'cancelled', 'a lost dispute closes an uncollected order');
select is(t.stock(t.id('p')), (select n + 2 from stock_now), 'and the stock comes back');
select is(t.bal('held', t.id('o11')), 0::bigint, 'with nothing held');

insert into ids values ('o12', t.paid_order());
select t.dispute(t.id('o12'), 'dp_o12');
select t.staff_decide(t.id('o12'), t.lines(t.id('o12'), 1), 'decide-o12-1');
select t.dispute_end('dp_o12', 'lost');
select is(t.bal('held', t.id('o12')), 0::bigint, 'a staff refund waiting on a lost dispute clears');

-- Two variants of one product both go back.
insert into public.cart_lines (user_id, product_id, variant, qty) values
  ('b5000000-0000-0000-0000-000000000002', t.id('p'), '3U', 2),
  ('b5000000-0000-0000-0000-000000000002', t.id('p'), '4U', 1);
truncate stock_now;
insert into stock_now select t.stock(t.id('p'));
select t.as_user('b5000000-0000-0000-0000-000000000002');
create function pg_temp.reserve_cart() returns uuid language plpgsql as $$
declare
  q jsonb := public.shop_quote(t.id('s'));
begin
  return (public.shop_reserve(t.id('s'), 'two-variants-1', (q ->> 'total_minor')::bigint) ->> 'order_id')::uuid;
end;
$$;
insert into ids select 'o13', pg_temp.reserve_cart();
select t.reset();
select is(t.stock(t.id('p')), (select n - 3 from stock_now), 'three taken across two variants');
select t.buyer(format($$select public.shop_order_cancel(%L, 'Oops')$$, t.id('o13')));
select is(t.stock(t.id('p')), (select n from stock_now), 'and all three come back');
delete from public.cart_lines where user_id = 'b5000000-0000-0000-0000-000000000002';

-- An unpaid order at the same price isn't the same order.
insert into ids values ('q', t.product(t.id('s'), 10000, 5));
select t.buy('b5000000-0000-0000-0000-000000000002', t.id('s'), t.id('p'));
select t.as_user('b5000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.shop_reserve(%L, 'same-price-1', 10000, 0, jsonb_build_object('product', %L, 'qty', 1))$$,
  t.id('s'), t.id('q')), '%unpaid order%', 'another item at the same price stops the charge');
select throws_like(format($$select public.shop_reserve(%L, 'no-price-1', null, 0, jsonb_build_object('product', %L, 'qty', 1))$$,
  t.id('s'), t.id('p')), '%unpaid order%', 'and a missing price is no way round it');
select t.reset();

-- Earnings show what the shop will really get.
insert into ids values ('s2', t.shop('b5000000-0000-0000-0000-000000000003'));
insert into ids values ('p2', t.product(t.id('s2'), 10000, 5));
insert into ids values ('o14', t.order_of(t.buy('b5000000-0000-0000-0000-000000000002', t.id('s2'), t.id('p2'))));
select t.succeed(t.pay_of(t.id('o14')));
select t.buyer(format($$select public.shop_order_cancel(%L, 'Oops')$$, t.id('o14')));
select t.as_user('b5000000-0000-0000-0000-000000000003');
select is((public.money_my_earnings() ->> 'held_minor')::bigint, 0::bigint, 'a cancelled order isn''t held for the shop');
select t.reset();

-- A client can write profiles.created_at, so it can't be what the gate reads.
update public.app_settings set value = '30' where key = 'points.redeem_min_account_days';
update auth.users set created_at = now() where id = 'b5000000-0000-0000-0000-000000000003';
update public.profiles set created_at = '2000-01-01' where id = 'b5000000-0000-0000-0000-000000000003';
select ok(not private.points_can_redeem('b5000000-0000-0000-0000-000000000003'), 'a backdated profile doesn''t pass the age gate');
update public.app_settings set value = '0' where key = 'points.redeem_min_account_days';

-- Reviews.
update auth.users set created_at = now() where created_at is null;
update public.profiles set full_name = 'Teen Fullname' where id = 'b5000000-0000-0000-0000-000000000006';
insert into public.product_reviews (order_id, product_id, user_id, stars, tags, body, show_level)
values (t.id('o2'), t.id('p'), 'b5000000-0000-0000-0000-000000000006', 5, '{}', 'Nice', true);
insert into public.player_sports (user_id, sport, level, play_min, play_max)
values ('b5000000-0000-0000-0000-000000000006', 'badminton', 4, 1, 8) on conflict do nothing;
select t.as_user('b5000000-0000-0000-0000-000000000003');
select ok(position('Teen Fullname' in public.shop_product(t.id('p'))::text) = 0, 'a minor''s full name isn''t shown on a review');
select is(public.shop_product(t.id('p')) #> '{reviews,0,level}', 'null'::jsonb, 'nor their level');
select t.reset();
insert into public.blocks (blocker_id, blocked_id) values ('b5000000-0000-0000-0000-000000000003', 'b5000000-0000-0000-0000-000000000006');
select t.as_user('b5000000-0000-0000-0000-000000000003');
select is(jsonb_array_length(public.shop_product(t.id('p')) -> 'reviews'), 0, 'and blocked people''s reviews are left out');
select t.reset();

-- Each side sees its own numbers.
select t.as_user('b5000000-0000-0000-0000-000000000002');
select is((public.shop_order(t.id('o2')) #>> '{lines,0,unit_shop}')::int, 0, 'the buyer doesn''t see the shop''s share');
select ok(public.shop_order(t.id('o2')) ? 'cancel_reason' = false, 'or the cancel reason');
select t.reset();
select t.as_user('b5000000-0000-0000-0000-000000000001');
select is(public.shop_order(t.id('o2')) -> 'payment', 'null'::jsonb, 'the shop doesn''t see how the buyer paid');
select is((public.shop_order(t.id('o2')) #>> '{lines,0,unit_points}')::int, 0, 'or whether they used points');
select throws_like(format($$select public.shop_order(%L)$$,
    (select o.id from public.orders o where o.mall_id = t.id('s') and o.step = 'pending' limit 1)), '%',
  'and can''t open an unpaid order');
select t.reset();

-- A hidden item leaves a cart's checkout instead of blocking it.
insert into ids values ('h', t.product(t.id('s2'), 5000, 5));
insert into ids values ('v', t.product(t.id('s2'), 3000, 5));
insert into public.cart_lines (user_id, product_id, variant, qty) values
  ('b5000000-0000-0000-0000-000000000002', t.id('h'), '', 1),
  ('b5000000-0000-0000-0000-000000000002', t.id('v'), '', 1);
update public.products set hidden_at = now() where id = t.id('h');
select t.as_user('b5000000-0000-0000-0000-000000000002');
select is((public.shop_quote(t.id('s2')) ->> 'total_minor')::bigint, 3000::bigint, 'the quote leaves out a hidden item');
select is(jsonb_array_length(public.shop_quote(t.id('s2'), jsonb_build_object('product', t.id('h'), 'qty', 1)) -> 'lines'), 0, 'and shows nothing of it');
select t.reset();

-- A suspended owner's shop stops selling.
insert into public.account_moderation (user_id, suspended_until) values ('b5000000-0000-0000-0000-000000000003', now() + interval '1 day');
select ok(not private.product_on_sale(t.id('v')), 'a suspended owner''s products are off sale');
delete from public.account_moderation where user_id = 'b5000000-0000-0000-0000-000000000003';

-- A block forfeits points, including any on their way back.
insert into ids values ('o15', t.order_of((select t.buy('b5000000-0000-0000-0000-000000000005', t.id('s'), t.id('p'), 1, 100)
  from (select t.give_points('b5000000-0000-0000-0000-000000000005', 1000)) g)));
select t.as_staff('b5000000-0000-0000-0000-000000000004');
select public.staff_points_block('b5000000-0000-0000-0000-000000000005', true, 'Gaming points');
select t.reset();
select t.as_user('b5000000-0000-0000-0000-000000000005');
select public.shop_order_cancel(t.id('o15'), 'Oops');
select t.reset();
select is(private.points_balance('b5000000-0000-0000-0000-000000000005'), 0::bigint, 'returned points don''t reach a blocked player');

-- A lost chargeback takes the fee's points back, and the week counts what's left.
select t.meet('b5000000-0000-0000-0000-000000000001') as m \gset
update public.activities set fee_cents = 600 where id = :'m';
insert into ids values ('m', :'m');
insert into ids select 'mp', t.payment_id(t.reserve('b5000000-0000-0000-0000-000000000007', t.id('m')));
select t.succeed(t.id('mp'));
update public.activity_participants set attendance = 'present' where activity_id = t.id('m') and user_id = 'b5000000-0000-0000-0000-000000000007';
select is(private.points_balance('b5000000-0000-0000-0000-000000000007'), 400::bigint, 'a S$2.00 fee earns 40 points');
update public.activity_participants set attendance = 'absent' where activity_id = t.id('m') and user_id = 'b5000000-0000-0000-0000-000000000007';
select is(private.points_balance('b5000000-0000-0000-0000-000000000007'), 0::bigint, 'a mis-tap takes them back');
update public.activity_participants set attendance = 'present' where activity_id = t.id('m') and user_id = 'b5000000-0000-0000-0000-000000000007';
select is(private.points_balance('b5000000-0000-0000-0000-000000000007'), 400::bigint, 'and the weekly cap doesn''t count them twice');
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_pts', 'charge', 'ch_' || t.id('mp'), 'amount', 800));
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_pts', 'status', 'lost', 'amount', 800));
select is(private.points_balance('b5000000-0000-0000-0000-000000000007'), 0::bigint, 'a lost chargeback takes the points back');

-- The second review, of the fixes above.

-- A voided refund on a paid-out order gives the shop its sale back.
insert into ids values ('o20', t.paid_order());
select t.buyer(format('select public.shop_collected(%L)', t.id('o20')));
truncate before;
insert into before select t.bal('organizer', 'b5000000-0000-0000-0000-000000000001');
select t.staff_decide(t.id('o20'), t.lines(t.id('o20'), 1), 'decide-o20-1');
select t.settle_refunds(t.pay_of(t.id('o20')), 'failed');
insert into ids select 'r20', r.id from public.refunds r where r.payment_id = t.pay_of(t.id('o20'));
select t.as_staff('b5000000-0000-0000-0000-000000000004');
select public.staff_refund_void(t.id('r20'), 'Bank refused it');
select t.reset();
select is(t.bal('organizer', 'b5000000-0000-0000-0000-000000000001') - (select minor from before), 0::bigint, 'the shop keeps its S$90.00');
select is(t.step(t.id('o20')), 'released', 'and the sale stands');

-- One voided before anything was paid out goes back to staff.
insert into ids values ('o21', t.paid_order());
select t.staff_decide(t.id('o21'), t.lines(t.id('o21'), 1), 'decide-o21-1');
select t.settle_refunds(t.pay_of(t.id('o21')), 'failed');
insert into ids select 'r21', r.id from public.refunds r where r.payment_id = t.pay_of(t.id('o21'));
select t.as_staff('b5000000-0000-0000-0000-000000000004');
select public.staff_refund_void(t.id('r21'), 'Bank refused it');
select t.reset();
select is(t.step(t.id('o21')), 'reported', 'a voided full refund is staff''s to decide');
select is(t.bal('held', t.id('o21')), -10000::bigint, 'with the money still held');

-- A shop that handed the goods over is still paid if the dispute is lost.
insert into ids values ('o22', t.paid_order());
select t.dispute(t.id('o22'), 'dp_o22');
select t.buyer(format('select public.shop_collected(%L)', t.id('o22')));
truncate before;
insert into before select t.bal('organizer', 'b5000000-0000-0000-0000-000000000001');
select t.dispute_end('dp_o22', 'lost');
select private.orders_sweep();
select is(t.bal('organizer', 'b5000000-0000-0000-0000-000000000001') - (select minor from before), -9000::bigint, 'collected and disputed still pays the shop');
select is(t.step(t.id('o22')), 'collected', 'and the order stands');

-- A closed inquiry took no money.
insert into ids values ('o23', t.paid_order());
select t.ready(t.id('o23'));
select t.dispute(t.id('o23'), 'dp_o23');
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_o23', 'status', 'warning_closed', 'amount', 10000));
select is(t.step(t.id('o23')), 'ready', 'a closed inquiry doesn''t cancel the order');
select is((select status from public.payment_disputes where stripe_dispute_id = 'dp_o23'), 'won', 'and counts as won');

-- A partial dispute is for a person.
insert into ids values ('o24', t.paid_order());
select t.ready(t.id('o24'));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_o24', 'charge', 'ch_' || t.pay_of(t.id('o24')), 'amount', 4000));
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_o24', 'status', 'lost', 'amount', 4000));
select is(t.step(t.id('o24')), 'ready', 'a dispute for part of a payment closes nothing');
select ok(exists (select 1 from public.money_alerts where key = 'dispute-partial:dp_o24'), 'and tells staff');

-- A product can't pick its own dates.
select t.as_user('b5000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.shop_reserve(%L, 'slot-on-goods-1', 10000, 0, jsonb_build_object('product', %L, 'qty', 1), '2099-01-01')$$,
  t.id('s'), t.id('q')), '%Try that again%', 'a slot on a product is refused');
select t.reset();

-- Marked ready at the last minute, the buyer still gets their time.
insert into ids values ('o25', t.paid_order());
alter table public.orders disable trigger orders_guard;
update public.orders set release_at = now() + interval '1 minute' where id = t.id('o25');
alter table public.orders enable trigger orders_guard;
select t.ready(t.id('o25'));
alter table public.orders disable trigger orders_guard;
update public.orders set release_at = now() - interval '1 minute' where id = t.id('o25');
alter table public.orders enable trigger orders_guard;
select private.orders_sweep();
select is(t.step(t.id('o25')), 'ready', 'a last-minute Mark ready isn''t released straight away');
select t.buyer(format($$select public.shop_order_cancel(%L, 'Too late for me')$$, t.id('o25')));
select is(t.step(t.id('o25')), 'cancelled', 'and the buyer can still cancel');

-- Staff decisions.
insert into ids values ('o26', t.paid_order(2));
select t.buyer(format($$select public.shop_report_problem(%L, 'Hmm')$$, t.id('o26')));
select throws_like(format($$select t.staff_decide(%L, %L, 'decide-o2-1')$$, t.id('o26'), t.lines(t.id('o26'), 1)), '%already been made%',
  'a key can''t be reused for another order');
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_o26', 'charge', 'ch_' || t.pay_of(t.id('o26')), 'amount', 20000));
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_o26', 'status', 'lost', 'amount', 20000));
select throws_like(format($$select t.staff_decide(%L, %L, 'decide-o26-1')$$, t.id('o26'), t.lines(t.id('o26'), 1)), '%closed%',
  'a lost dispute leaves staff nothing to refund');

-- The final review.

-- After a partial chargeback staff can still act, and the buyer can't cancel.
insert into ids values ('o28', t.paid_order(2));
select t.ready(t.id('o28'));
select t.event('charge.dispute.created', jsonb_build_object('id', 'dp_o28', 'charge', 'ch_' || t.pay_of(t.id('o28')), 'amount', 1000));
select t.event('charge.dispute.closed', jsonb_build_object('id', 'dp_o28', 'status', 'lost', 'amount', 1000));
select t.as_user('b5000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.shop_order_cancel(%L, 'Oops')$$, t.id('o28')), '%Contact us%',
  'a buyer can''t cancel for a full refund after a partial chargeback');
select t.reset();
select is(t.staff_decide(t.id('o28'), t.lines(t.id('o28'), 1), 'decide-o28-1'), 10000::bigint, 'staff can still refund a line');

-- A refund waiting on a dispute that was lost after release: the goods went back.
insert into ids values ('o29', t.paid_order());
select t.buyer(format('select public.shop_collected(%L)', t.id('o29')));
select t.dispute(t.id('o29'), 'dp_o29');
select t.staff_decide(t.id('o29'), t.lines(t.id('o29'), 1), 'decide-o29-1');
truncate before;
insert into before select t.bal('organizer', 'b5000000-0000-0000-0000-000000000001');
select t.dispute_end('dp_o29', 'lost');
select is(t.bal('organizer', 'b5000000-0000-0000-0000-000000000001') - (select minor from before), 9000::bigint,
  'the shop gives back what it was paid');
select is(t.refunded(t.pay_of(t.id('o29'))), 0::bigint, 'and the buyer isn''t refunded on top of the bank');

-- A void doesn't take stock off a closed order's shelf.
insert into ids values ('o30', t.paid_order(2));
truncate stock_now;
insert into stock_now select t.stock(t.id('p'));
select t.as_staff('b5000000-0000-0000-0000-000000000004');
select public.staff_order_decide(t.id('o30'), t.lines(t.id('o30'), 1), true, 'One was broken', 'decide-o30-1');
select t.reset();
select t.settle_refunds(t.pay_of(t.id('o30')), 'failed');
select t.buyer(format($$select public.shop_order_cancel(%L, 'Forget it')$$, t.id('o30')));
insert into ids select 'r30', r.id from public.refunds r where r.payment_id = t.pay_of(t.id('o30')) and r.status = 'failed';
select t.as_staff('b5000000-0000-0000-0000-000000000004');
select public.staff_refund_void(t.id('r30'), 'Bank refused it');
select t.reset();
select is(t.stock(t.id('p')), (select n + 2 from stock_now), 'both units stay on the shelf');

-- An abandoned order was never the shop's.
insert into ids values ('o27', t.order_of(t.buy('b5000000-0000-0000-0000-000000000002', t.id('s2'), t.id('v'))));
select t.buyer(format($$select public.shop_order_cancel(%L, 'Oops')$$, t.id('o27')));
select t.as_user('b5000000-0000-0000-0000-000000000003');
select is(jsonb_array_length(public.shop_owner_orders()) , 1, 'the shop doesn''t see orders that were never paid');
select t.reset();

select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
