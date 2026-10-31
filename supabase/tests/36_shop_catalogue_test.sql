-- P4b-02: partner shops, what's on sale, and moderation that actually hides.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('b1000000-0000-0000-0000-000000000001');  -- owner
select t.player('b1000000-0000-0000-0000-000000000002');  -- buyer
select t.player('b1000000-0000-0000-0000-000000000003', 12);  -- unlinked child
select t.player('b1000000-0000-0000-0000-000000000004');  -- content staff
select t.player('b1000000-0000-0000-0000-000000000005');  -- payments staff
select t.player('b1000000-0000-0000-0000-000000000006', 15);
insert into public.staff (user_id, role) values
  ('b1000000-0000-0000-0000-000000000004', 'content'),
  ('b1000000-0000-0000-0000-000000000005', 'payments');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;
insert into ids values ('s', t.shop('b1000000-0000-0000-0000-000000000001'));
insert into ids values ('p', t.product(t.id('s'), 10000, 5));
insert into ids values ('top', t.shop('b1000000-0000-0000-0000-000000000005', true));
insert into ids values ('tp', t.product(t.id('top'), 10000, 5));

-- Gone for good.
select hasnt_table('public', 'addresses', 'no addresses');
select hasnt_table('public', 'order_returns', 'no returns');
select hasnt_function('public', 'shop_open', 'players can''t open a shop');
select hasnt_function('public', 'shop_checkout', 'the unpaid checkout is gone');
select hasnt_function('public', 'shop_mark_shipped', 'nothing ships');

-- Prices.
select t.as_user('b1000000-0000-0000-0000-000000000002');
select is((public.shop_product(t.id('p')) #>> '{product,price_cents}')::int, 10000, 'the default price is the shop''s price');
select is((public.shop_product(t.id('tp')) #>> '{product,price_cents}')::int, 11000, 'on-top shows the buyer the S$110.00 they pay');
select is((public.shop_product(t.id('p')) #>> '{product,points_cap_minor}')::int, 0, 'nothing is advertised until points can be spent');
select t.reset();
insert into public.app_settings (key, value) values ('points.redeem_min_account_days', '0');
select t.as_user('b1000000-0000-0000-0000-000000000002');
select is((public.shop_product(t.id('p')) #>> '{product,points_cap_minor}')::int, 500, 'points can take half the S$10.00 commission');
select t.reset();

-- What's on sale.
select ok(private.product_on_sale(t.id('p')), 'a published product of an open shop is on sale');
update public.products set hidden_at = now() where id = t.id('p');
select ok(not private.product_on_sale(t.id('p')), 'a hidden product isn''t');
select t.as_user('b1000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.shop_product(%L)$$, t.id('p')), '%no longer listed%', 'and doesn''t open');
select ok(not public.shop_products('all', t.id('s'), '') @> jsonb_build_array(jsonb_build_object('id', t.id('p'))), 'and isn''t listed');
select throws_like(format($$select public.shop_cart_add(%L, '', 1)$$, t.id('p')), '%no longer listed%', 'and can''t go in a cart');
select t.reset();
update public.products set hidden_at = null where id = t.id('p');
update public.malls set active = false where id = t.id('s');
select ok(not private.product_on_sale(t.id('p')), 'a closed shop sells nothing');
update public.malls set active = true where id = t.id('s');

-- Reports reach the listing they're about.
select t.as_user('b1000000-0000-0000-0000-000000000002');
select public.shop_report(t.id('p'), 'fake', '');
select t.reset();
select is((select target_id from public.moderation_cases where target_kind = 'listing' and target_id = t.id('p')::text), t.id('p')::text,
  'a report is filed against the product');

-- Who can reach what.
select t.as_anon();
select throws_ok($$select 1 from public.points_entries$$, '42501', null, 'signed out: no points');
select t.reset();
select t.as_user('b1000000-0000-0000-0000-000000000002');
select is_empty($$select 1 from public.orders$$, 'a player reads no orders directly');
select is_empty($$select 1 from public.products$$, 'nor products');
update public.products set price_cents = 1 where id = t.id('p');
select t.reset();
select is((select price_cents from public.products where id = t.id('p')), 10000, 'a player can''t change a price');

-- A shop opens only with an owner and an address.
select t.as_staff('b1000000-0000-0000-0000-000000000004');
select throws_like($$select public.staff_shop_save('{"name":"No owner shop","active":true}', 'Opening it')$$, '%needs an owner%', 'no owner, no opening');
create temp table made on commit drop as select public.staff_shop_save('{"name":"RSL Sports","collect_address":"2 Test Road"}', 'Adding RSL') as id;
select t.reset();
grant select on made to anon, authenticated;
select ok((select not active from public.malls where id = (select id from made)), 'a new shop starts closed');
create temp table names on commit drop as select id, username::text as username from public.profiles;
grant select on names to anon, authenticated;
select t.as_staff('b1000000-0000-0000-0000-000000000005');
select throws_like(format($$select public.staff_shop_link_owner(%L, 'nobody_here', 'Linking')$$, (select id from made)), '%No player%', 'an owner has to exist');
select public.staff_shop_link_owner((select id from made), (select username from names where id = 'b1000000-0000-0000-0000-000000000002'), 'Linking the owner');
select throws_like(format($$select public.staff_shop_link_owner(%L, %L, 'A teen')$$, (select id from made),
  (select username from names where id = 'b1000000-0000-0000-0000-000000000006')), '%adult%', 'a minor can''t own a shop');
select t.reset();
select is((select owner_id from public.malls where id = (select id from made)), 'b1000000-0000-0000-0000-000000000002'::uuid, 'the owner is linked');

-- Roles.
select t.as_user('b1000000-0000-0000-0000-000000000002');
select throws_like($$select public.staff_shop_list()$$, 'Not found%', 'a player can''t list shops as staff');
select throws_like($$select public.staff_order_list()$$, 'Not found%', 'or orders');
select t.reset();
select t.as_staff('b1000000-0000-0000-0000-000000000004');
select throws_like($$select public.staff_order_list()$$, 'Not found%', 'content staff don''t see orders');
select throws_like(format($$select public.staff_shop_commission_set(%L, true, 'Trying it')$$, t.id('s')), 'Not found%', 'or set commission');
select t.reset();
select t.as_staff('b1000000-0000-0000-0000-000000000005');
select lives_ok($$select public.staff_shop_list()$$, 'payments staff see shops, for the commission and owner');
select throws_like($$select public.staff_product_list(gen_random_uuid())$$, 'Not found%', 'but don''t edit the catalogue');
select t.reset();
select t.as_staff('b1000000-0000-0000-0000-000000000004', false);
select throws_like($$select public.staff_shop_list()$$, 'Not found%', 'staff need MFA');
select t.reset();

-- Stock moves by amount.
select t.as_staff('b1000000-0000-0000-0000-000000000004');
select is(public.staff_product_stock(t.id('p'), 3, 'Delivery came'), 8, 'stock goes up by the amount');
select throws_like(format($$select public.staff_product_stock(%L, -99, 'Oops please')$$, t.id('p')), '%below zero%', 'never below zero');
select t.reset();

select * from finish();
rollback;
