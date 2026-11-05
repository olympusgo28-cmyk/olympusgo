-- P4b-02: the Shop becomes partner shops with self-collect. Player-run shops,
-- delivery, addresses and returns are gone (owner, 1 Nov). Staff enter shops and
-- products, and each shop is linked to an owner's account.

insert into public.fee_rules (currency, applies_to, percent_bps, minimum_minor) values
  ('SGD', 'shop_commission', 1000, 0);  -- Q31, owner: flat 10%

insert into public.feature_flags (key, enabled, description) values
  ('shop.checkout', false, 'Paying in the Shop. Off until Gate D.');

insert into public.app_settings (key, value, description) values
  ('shop.hold_minutes', '10', 'How long stock is held while payment completes'),
  ('shop.collect_days', '7', 'Days after payment a product can be collected'),
  ('shop.release_hours', '48', 'Hours after collect-by that the payout releases (checklist 5, 16)');

-- A Shop payment belongs to one order, which owns its held money the way an
-- activity does.
alter table public.payments
  add column order_id uuid,
  add column held_owner uuid generated always as (coalesce(activity_id, order_id)) stored;
create unique index payments_one_order on public.payments (order_id) where order_id is not null;

-- Nothing was ever charged here, so old orders close without a refund.
update public.products set published = false where true;
delete from public.cart_lines where true;

drop function public.shop_open(jsonb);
drop function public.shop_address_save(jsonb);
drop function public.shop_checkout(jsonb, text, jsonb);
drop function public.shop_book_service(uuid, text, text);
drop function public.shop_mark_shipped(uuid, text, text);
drop function public.shop_return_request(uuid, text, text);
drop function public.shop_return_decide(uuid, boolean);
drop function public.shop_confirm_received(uuid);
drop function public.shop_cancel(uuid, text);
drop function public.shop_save_product(jsonb);
drop function public.shop_seller_orders();
drop function public.shop_seller_products();
drop function public.shop_seller_summary();
drop function public.shop_require_mine();
drop function public.shop_report(text, text, text);
drop table public.order_returns;
drop table public.addresses;

alter table public.malls
  alter column owner_id drop not null,
  alter column owner_id drop default,
  drop constraint malls_owner_id_fkey,
  add constraint malls_owner_id_fkey foreign key (owner_id) references auth.users (id) on delete set null,
  add column active boolean not null default false,
  add column commission_on_top boolean not null default false;
alter table public.malls rename column ships_from to collect_address;
alter table public.malls drop constraint if exists malls_ships_from_check;
alter table public.malls add constraint malls_collect_address_check check (char_length(collect_address) <= 200);

alter table public.products drop column max_points;

alter table public.orders
  drop constraint orders_buyer_id_fkey,
  drop constraint orders_mall_id_fkey,
  drop constraint orders_step_check,
  drop column delivery,
  drop column delivery_cents,
  drop column paid_with,
  drop column address,
  drop column arrives,
  drop column courier,
  drop column tracking,
  drop column shipped_at,
  drop column delivered_at,
  add column idempotency_key text,
  add column legacy boolean not null default false,
  add column slot_at timestamptz,
  add column hold_until timestamptz,
  add column paid_at timestamptz,
  add column collect_by timestamptz,
  add column release_at timestamptz,
  add column ready_at timestamptz,
  add column collected_at timestamptz,
  add column reported_at timestamptz,
  add column report_note text check (char_length(report_note) <= 500),
  add column released_at timestamptz,
  add column unreserved_at timestamptz;

update public.orders set legacy = true, step = 'cancelled' where step in ('packing', 'shipped');
update public.orders set legacy = true, step = 'collected' where step = 'delivered';

alter table public.orders
  alter column step set default 'pending',
  add constraint orders_step_check check (step in ('pending', 'paid', 'started', 'ready', 'collected',
    'reported', 'cancelled', 'expired', 'released', 'refunded')),
  add constraint orders_key unique (buyer_id, idempotency_key);

alter table public.orders add constraint orders_mall_id_fkey
  foreign key (mall_id) references public.malls (id) on delete restrict;

create unique index orders_one_pending on public.orders (buyer_id, mall_id) where step = 'pending';
create index orders_work_idx on public.orders (release_at) where step in ('paid', 'started', 'ready');
create index orders_hold_idx on public.orders (hold_until) where step = 'pending';

-- Unit amounts are fixed at checkout, so a refund by quantity never rounds.
alter table public.order_lines
  add column unit_voucher bigint not null default 0 check (unit_voucher >= 0),
  add column on_top boolean not null default false,
  add column unit_commission bigint not null default 0 check (unit_commission >= 0),
  add column unit_points bigint not null default 0 check (unit_points >= 0),
  add column unit_shop bigint not null default 0 check (unit_shop >= 0),
  add column unit_paid bigint not null default 0 check (unit_paid >= 0),
  add column refunded_qty integer not null default 0 check (refunded_qty >= 0),
  add constraint order_lines_units check (unit_paid = unit_shop + unit_commission - unit_points),
  add constraint order_lines_one_discount check (unit_voucher = 0 or unit_points = 0),
  add constraint order_lines_refunded check (refunded_qty <= qty);

create table private.order_transitions (
  from_step text not null,
  to_step text not null,
  primary key (from_step, to_step)
);
insert into private.order_transitions values
  ('pending', 'paid'), ('pending', 'cancelled'), ('pending', 'expired'),
  ('paid', 'started'), ('paid', 'ready'), ('paid', 'collected'), ('paid', 'reported'),
  ('paid', 'cancelled'), ('paid', 'released'), ('paid', 'refunded'),
  ('started', 'ready'), ('started', 'collected'), ('started', 'reported'),
  ('started', 'cancelled'), ('started', 'released'), ('started', 'refunded'),
  ('ready', 'collected'), ('ready', 'reported'), ('ready', 'cancelled'), ('ready', 'released'),
  ('ready', 'refunded'),
  ('reported', 'released'), ('reported', 'refunded'), ('reported', 'cancelled'),
  ('collected', 'refunded'), ('released', 'refunded'),
  ('refunded', 'released'), ('refunded', 'reported');

create function private.order_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    if old.step in ('cancelled', 'expired') or old.legacy then return old; end if;
    raise exception 'Orders are never deleted';
  end if;
  if new.step <> old.step and not exists (select 1 from private.order_transitions t
      where t.from_step = old.step and t.to_step = new.step) then
    raise exception 'An order can''t go from % to %', old.step, new.step;
  end if;
  if (new.buyer_id, new.mall_id, new.release_at is not null and old.release_at is not null)
     is distinct from (old.buyer_id, old.mall_id, old.release_at is not null) then
    raise exception 'An order''s buyer and shop can''t change';
  end if;
  if old.release_at is not null and new.release_at is distinct from old.release_at then
    raise exception 'An order''s release time can''t change';
  end if;
  return new;
end;
$$;
create trigger orders_guard before update or delete on public.orders
  for each row execute function private.order_guard();

-- What a line costs. Commission comes off the list price after any voucher, and
-- points never change it, so the shop's money is settled before they apply.
create function private.shop_unit(p_list bigint, p_on_top boolean, p_currency text default 'SGD',
  p_voucher bigint default 0)
returns table (commission bigint, shop bigint, buyer bigint, points_cap bigint)
language sql stable security definer set search_path = '' as $$
  -- Definer: reads fee_rules for any caller.
  with c as (select private.fee_minor(greatest(p_list - p_voucher, 0), p_currency, 'shop_commission') as commission)
  select c.commission,
    case when p_on_top then p_list - p_voucher else p_list - p_voucher - c.commission end,
    case when p_on_top then p_list - p_voucher + c.commission else p_list - p_voucher end,
    c.commission / 2
  from c;
$$;
revoke execute on function private.shop_unit(bigint, boolean, text, bigint) from public, anon;

create function private.product_on_sale(p_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: products have no client policies.
  select exists (select 1 from public.products p join public.malls m on m.id = p.mall_id
    where p.id = p_id and p.published and p.hidden_at is null and m.active and m.owner_id is not null
      and not private.is_suspended(m.owner_id));
$$;
revoke execute on function private.product_on_sale(uuid) from public, anon;

create or replace function public.shop_mall_json(p_mall uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', m.id, 'name', m.name, 'initials', m.initials, 'blurb', m.blurb,
    'about', m.about, 'collect_address', m.collect_address, 'color', m.color, 'ink', m.ink,
    'verified', m.verified, 'created_at', m.created_at,
    'owner_id', m.owner_id,
    'points_open', exists (select 1 from public.app_settings a where a.key = 'points.redeem_min_account_days'),
    'mine', m.owner_id = (select auth.uid()))
  from public.malls m where m.id = p_mall;
$$;

create or replace function public.shop_malls() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.shop_mall_json(m.id) order by m.created_at desc), '[]')
  from public.malls m
  where m.active and exists (select 1 from public.products p
    where p.mall_id = m.id and private.product_on_sale(p.id));
$$;

create or replace function public.shop_mall(p_mall uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'mall', public.shop_mall_json(m.id),
    'rating', coalesce((select round(avg(r.stars), 1) from public.product_reviews r
                        join public.products p on p.id = r.product_id
                        where p.mall_id = m.id), 0),
    'ratings', (select count(*) from public.product_reviews r
                join public.products p on p.id = r.product_id where p.mall_id = m.id),
    'followers', (select count(*) from public.mall_follows where mall_id = m.id),
    'following', exists (select 1 from public.mall_follows
                         where mall_id = m.id and user_id = (select auth.uid())),
    'products', (select coalesce(jsonb_agg(public.shop_product_json(p.id)
                   order by p.created_at desc), '[]')
                 from public.products p where p.mall_id = m.id and private.product_on_sale(p.id)))
  from public.malls m where m.id = p_mall and m.active;
$$;

create or replace function public.shop_product_json(p_id uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', p.id, 'name', p.name, 'mall_id', p.mall_id, 'mall_name', m.name,
    'description', p.description, 'price_cents', u.buyer,
    'old_price_cents', (select b.buyer from private.shop_unit(p.old_price_cents::bigint, m.commission_on_top) b),
    -- Nothing to advertise until points can be spent.
    'points_cap_minor', case when exists (select 1 from public.app_settings a
        where a.key = 'points.redeem_min_account_days') then u.points_cap else 0 end,
    'art', p.art,
    'service', p.service, 'stock', p.stock, 'published', p.published,
    'options', p.options,
    'rating', coalesce((select round(avg(stars), 1) from public.product_reviews
                        where product_id = p.id), 0),
    'ratings', (select count(*) from public.product_reviews where product_id = p.id),
    'sold', coalesce((select sum(l.qty) from public.order_lines l
                      join public.orders o on o.id = l.order_id
                      where l.product_id = p.id and o.step not in ('pending', 'cancelled', 'expired')), 0))
  from public.products p join public.malls m on m.id = p.mall_id
  cross join lateral private.shop_unit(p.price_cents::bigint, m.commission_on_top) u
  where p.id = p_id;
$$;

create or replace function public.shop_products(p_kind text, p_mall uuid, p_query text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(x.j order by x.rank desc, x.created_at desc), '[]')
  from (
    select public.shop_product_json(p.id) as j, p.created_at,
      case when p_kind = 'popular'
           then (select coalesce(sum(l.qty), 0) from public.order_lines l where l.product_id = p.id)
           else 0 end as rank
    from public.products p
    join public.malls m on m.id = p.mall_id
    where private.product_on_sale(p.id)
      and (p_mall is null or p.mall_id = p_mall)
      and (coalesce(trim(p_query), '') = ''
           or p.name ilike '%' || trim(p_query) || '%'
           or m.name ilike '%' || trim(p_query) || '%')
      and (p_kind <> 'deals' or p.old_price_cents > p.price_cents)
      and (p_kind <> 'popular' or (not p.service and p.stock > 0))
    order by 3 desc, p.created_at desc
    limit case when p_kind = 'all' then 200 else 8 end
  ) x;
$$;

create or replace function public.shop_product(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not private.product_on_sale(p_id) then
    raise exception 'This item is no longer listed.';
  end if;
  return jsonb_build_object(
    'product', public.shop_product_json(p_id),
    'reviews', (select coalesce(jsonb_agg(jsonb_build_object(
        'name', private.public_name(r.user_id),
        'stars', r.stars, 'tags', r.tags, 'body', r.body, 'at', r.created_at,
        'level', case when r.show_level and not private.is_minor(r.user_id) then (
          select jsonb_build_object('sport', s.sport, 'level', s.level)
          from public.player_sports s where s.user_id = r.user_id
          order by s.level desc limit 1) end)
        order by r.created_at desc), '[]')
      from (select * from public.product_reviews x where x.product_id = p_id
              and not public.is_blocked_between((select auth.uid()), x.user_id)
            order by x.created_at desc limit 20) r),
    'related', (select coalesce(jsonb_agg(public.shop_product_json(x.id)), '[]')
      from (select o.id from public.products o
            where o.mall_id = (select mall_id from public.products where id = p_id)
              and o.id <> p_id and private.product_on_sale(o.id)
            order by o.created_at desc limit 4) x));
end;
$$;

create or replace function public.shop_cart() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', c.id, 'variant', c.variant, 'qty', c.qty,
    'product', public.shop_product_json(c.product_id)) order by c.created_at), '[]')
  from public.cart_lines c
  where c.user_id = (select auth.uid()) and private.product_on_sale(c.product_id);
$$;

-- Services are booked for a time, so they go straight to checkout.
create or replace function public.shop_cart_add(p_product uuid, p_variant text, p_qty integer)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  p public.products;
begin
  select * into p from public.products where id = p_product;
  if p.id is null or not private.product_on_sale(p_product) then
    raise exception 'This item is no longer listed.';
  end if;
  if p.service then raise exception 'Book this for a time instead.'; end if;
  if p.stock <= 0 then raise exception 'This is sold out.'; end if;
  if p.mall_id = public.shop_mine() then raise exception 'This is from your own shop.'; end if;
  insert into public.cart_lines (user_id, product_id, variant, qty)
  values ((select auth.uid()), p_product, coalesce(p_variant, ''), greatest(p_qty, 1))
  on conflict (user_id, product_id, variant)
    do update set qty = least(public.cart_lines.qty + excluded.qty, 99);
end;
$$;

-- Reports carry the product's id, which is what a moderator's hide matches.
create function public.shop_report(p_product uuid, p_reason text, p_note text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.products p where p.id = p_product) then
    raise exception 'This item is no longer listed.';
  end if;
  insert into public.content_reports (reporter_id, target_kind, target_id, reason, note)
  values ((select auth.uid()), 'listing', p_product::text, left(p_reason, 40),
          left(coalesce(p_note, ''), 1000));
end;
$$;
revoke execute on function public.shop_report(uuid, text, text) from public, anon;
grant execute on function public.shop_report(uuid, text, text) to authenticated;

create or replace function public.shop_can_see_order(p_order uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.orders o join public.malls m on m.id = o.mall_id
    where o.id = p_order and ((select auth.uid()) = o.buyer_id
      or ((select auth.uid()) = m.owner_id and o.paid_at is not null)));
$$;

-- Each side sees its own numbers: the buyer what they paid, the shop what it
-- gets. Staff see both. The cancel reason stays with staff.
create or replace function public.shop_order_json(p_order uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', o.id, 'mall_id', o.mall_id, 'mall_name', m.name, 'step', o.step,
    'collect_address', m.collect_address, 'service', o.service, 'booking', o.booking,
    'slot_at', o.slot_at, 'reviewed', o.reviewed, 'placed_at', o.placed_at,
    'hold_until', o.hold_until, 'collect_by', o.collect_by,
    -- Marking it ready late gives the buyer the same time as anyone else.
    'release_at', greatest(o.release_at,
      o.ready_at + make_interval(hours => private.setting_int('shop.release_hours'))),
    'ready_at', o.ready_at, 'collected_at', o.collected_at,
    'buyer_id', o.buyer_id, 'owner_id', m.owner_id,
    'buyer', (select coalesce(private.public_name(id), username::text, 'Player')
              from public.profiles where id = o.buyer_id),
    'server_now', now(),
    'payment', case when v.is_owner then null else (select jsonb_build_object('id', p.id, 'status', p.status,
        'method', p.method, 'amount_minor', p.amount_minor, 'receipt_no', p.receipt_no,
        'refunded_minor', coalesce((select sum(r.amount_minor) from public.refunds r
          where r.payment_id = p.id and r.status <> 'voided'), 0),
        'refund_status', (select case when bool_or(r.status = 'failed') then 'failed'
            when bool_or(r.status in ('pending', 'processing')) then 'pending'
            when count(*) > 0 then 'done' end
          from public.refunds r where r.payment_id = p.id and r.status <> 'voided'),
        'dispute_status', (select d.status from public.payment_disputes d where d.payment_id = p.id
          order by d.created_at desc limit 1))
      from public.payments p where p.order_id = o.id) end,
    'lines', (select coalesce(jsonb_agg(jsonb_build_object(
                 'id', l.id, 'product_id', l.product_id, 'name', l.name, 'variant', l.variant,
                 'qty', l.qty, 'price_cents', l.price_cents,
                 'unit_paid', case when v.is_owner then 0 else l.unit_paid end,
                 'unit_points', case when v.is_owner then 0 else l.unit_points end,
                 'unit_shop', case when v.is_buyer then 0 else l.unit_shop end,
                 'refunded_qty', l.refunded_qty,
                 'art', (select art from public.products where id = l.product_id))
                 order by l.name), '[]')
              from public.order_lines l where l.order_id = o.id))
  from public.orders o join public.malls m on m.id = o.mall_id
  cross join lateral (select (select auth.uid()) = o.buyer_id as is_buyer,
    (select auth.uid()) = m.owner_id and (select auth.uid()) is distinct from o.buyer_id as is_owner) v
  where o.id = p_order;
$$;

create or replace function public.shop_review(p_order uuid, p_stars integer, p_tags text[],
  p_body text, p_show_level boolean)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order and buyer_id = (select auth.uid());
  if not found then raise exception 'This order isn''t yours.'; end if;
  if o.collected_at is null then raise exception 'You can review once you''ve collected it.'; end if;
  if o.reviewed then raise exception 'You''ve reviewed this order.'; end if;
  if p_stars not between 1 and 5 then raise exception 'Tap a star to rate.'; end if;
  insert into public.product_reviews (order_id, product_id, user_id, stars, tags, body, show_level)
  select p_order, l.product_id, o.buyer_id, p_stars, coalesce(p_tags, '{}'),
         left(coalesce(trim(p_body), ''), 1000), coalesce(p_show_level, true)
  from (select distinct product_id from public.order_lines
        where order_id = p_order and product_id is not null) l
  on conflict do nothing;
  update public.orders set reviewed = true where id = p_order;
end;
$$;
