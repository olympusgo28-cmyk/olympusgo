-- The Shop, with payments switched off: players open a shop, list
-- products, and buyers order and pay the shop directly on delivery or
-- pickup. Reviews and return requests follow delivery.

create table public.malls (
  id uuid primary key default gen_random_uuid(),
  -- One shop per player.
  owner_id uuid not null unique default auth.uid() references auth.users (id) on delete cascade,
  name text not null unique check (char_length(trim(name)) between 2 and 40),
  initials text not null check (char_length(initials) between 1 and 3),
  blurb text not null default '' check (char_length(blurb) <= 80),
  about text not null default '' check (char_length(about) <= 1000),
  ships_from text not null default '' check (char_length(ships_from) <= 80),
  color bigint not null default 4294698928,
  ink bigint not null default 4284104448,
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.mall_follows (
  mall_id uuid not null references public.malls (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (mall_id, user_id)
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  mall_id uuid not null references public.malls (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 3 and 80),
  description text not null default '' check (char_length(description) <= 2000),
  price_cents int not null check (price_cents between 1 and 10000000),
  old_price_cents int check (old_price_cents between 1 and 10000000),
  max_points int not null default 0 check (max_points >= 0),
  art text not null default 'bag' check (art in ('racquet', 'bag')),
  service boolean not null default false,
  stock int not null default 0 check (stock between 0 and 100000),
  published boolean not null default false,
  -- [{"title": "Weight", "values": ["3U", "4U"]}]
  options jsonb not null default '[]' check (jsonb_typeof(options) = 'array'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index products_mall_idx on public.products (mall_id, created_at);
create trigger products_touch before update on public.products
  for each row execute function public.touch_updated_at();

create table public.cart_lines (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  variant text not null default '' check (char_length(variant) <= 120),
  qty int not null check (qty between 1 and 99),
  created_at timestamptz not null default now(),
  unique (user_id, product_id, variant)
);

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  label text not null check (char_length(trim(label)) between 1 and 40),
  name text not null check (char_length(trim(name)) between 1 and 80),
  line text not null check (char_length(trim(line)) between 3 and 200),
  phone text not null default '' check (char_length(phone) <= 30),
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references auth.users (id) on delete cascade,
  mall_id uuid not null references public.malls (id) on delete cascade,
  step text not null default 'packing'
    check (step in ('packing', 'shipped', 'delivered', 'cancelled')),
  delivery text not null default 'Standard',
  delivery_cents int not null default 0,
  paid_with text not null default 'Pay the shop',
  -- {"label", "name", "line", "phone", "pickup"}, as it was when ordered.
  address jsonb,
  arrives date,
  courier text check (char_length(courier) <= 40),
  tracking text check (char_length(tracking) <= 60),
  service boolean not null default false,
  booking text check (char_length(booking) <= 120),
  cancel_reason text check (char_length(cancel_reason) <= 120),
  reviewed boolean not null default false,
  placed_at timestamptz not null default now(),
  shipped_at timestamptz,
  delivered_at timestamptz,
  cancelled_at timestamptz
);
create index orders_buyer_idx on public.orders (buyer_id, placed_at desc);
create index orders_mall_idx on public.orders (mall_id, placed_at desc);

create table public.order_lines (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid references public.products (id) on delete set null,
  name text not null,
  variant text not null default '',
  qty int not null check (qty between 1 and 99),
  price_cents int not null
);
create index order_lines_order_idx on public.order_lines (order_id);
create index order_lines_product_idx on public.order_lines (product_id);

create table public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  stars int not null check (stars between 1 and 5),
  tags text[] not null default '{}' check (cardinality(tags) <= 6),
  body text not null default '' check (char_length(body) <= 1000),
  show_level boolean not null default true,
  created_at timestamptz not null default now(),
  unique (order_id, product_id)
);
create index product_reviews_product_idx on public.product_reviews (product_id, created_at desc);

create table public.order_returns (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders (id) on delete cascade,
  reason text not null check (char_length(reason) between 1 and 60),
  want text not null check (char_length(want) between 1 and 60),
  status text not null default 'requested' check (status in ('requested', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  decided_at timestamptz
);

alter table public.malls enable row level security;
alter table public.mall_follows enable row level security;
alter table public.products enable row level security;
alter table public.cart_lines enable row level security;
alter table public.addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_lines enable row level security;
alter table public.product_reviews enable row level security;
alter table public.order_returns enable row level security;

create policy "Players manage their own addresses" on public.addresses
  for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
-- Everything else goes through the functions below.

alter table public.content_reports drop constraint content_reports_target_kind_check;
alter table public.content_reports add constraint content_reports_target_kind_check
  check (target_kind in ('message', 'club', 'team', 'activity', 'video', 'live', 'listing'));

-- ─── Helpers ───────────────────────────────────────────────────────────────

create function public.shop_mine() returns uuid
language sql stable security definer set search_path = '' as $$
  select id from public.malls where owner_id = (select auth.uid());
$$;

create function public.shop_require_mine() returns uuid
language plpgsql stable security definer set search_path = '' as $$
declare
  v uuid := public.shop_mine();
begin
  if v is null then raise exception 'Open your shop first.'; end if;
  return v;
end;
$$;

create function public.shop_product_json(p_id uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', p.id, 'name', p.name, 'mall_id', p.mall_id, 'mall_name', m.name,
    'description', p.description, 'price_cents', p.price_cents,
    'old_price_cents', p.old_price_cents, 'max_points', p.max_points, 'art', p.art,
    'service', p.service, 'stock', p.stock, 'published', p.published,
    'options', p.options,
    'rating', coalesce((select round(avg(stars), 1) from public.product_reviews
                        where product_id = p.id), 0),
    'ratings', (select count(*) from public.product_reviews where product_id = p.id),
    'sold', coalesce((select sum(l.qty) from public.order_lines l
                      join public.orders o on o.id = l.order_id
                      where l.product_id = p.id and o.step <> 'cancelled'), 0))
  from public.products p join public.malls m on m.id = p.mall_id
  where p.id = p_id;
$$;

create function public.shop_mall_json(p_mall uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', m.id, 'name', m.name, 'initials', m.initials, 'blurb', m.blurb,
    'about', m.about, 'ships_from', m.ships_from, 'color', m.color, 'ink', m.ink,
    'verified', m.verified, 'created_at', m.created_at,
    'mine', m.owner_id = (select auth.uid()))
  from public.malls m where m.id = p_mall;
$$;

create function public.shop_order_json(p_order uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', o.id, 'mall_id', o.mall_id, 'mall_name', m.name, 'step', o.step,
    'delivery', o.delivery, 'delivery_cents', o.delivery_cents,
    'paid_with', o.paid_with, 'address', o.address, 'arrives', o.arrives,
    'courier', o.courier, 'tracking', o.tracking, 'service', o.service,
    'booking', o.booking, 'reviewed', o.reviewed, 'placed_at', o.placed_at,
    'delivered_at', o.delivered_at,
    'buyer', (select coalesce(full_name, username::text, 'Player')
              from public.profiles where id = o.buyer_id),
    'return', (select jsonb_build_object('reason', r.reason, 'want', r.want,
                 'status', r.status) from public.order_returns r where r.order_id = o.id),
    'lines', (select coalesce(jsonb_agg(jsonb_build_object(
                 'product_id', l.product_id, 'name', l.name, 'variant', l.variant,
                 'qty', l.qty, 'price_cents', l.price_cents) order by l.name), '[]')
              from public.order_lines l where l.order_id = o.id))
  from public.orders o join public.malls m on m.id = o.mall_id
  where o.id = p_order;
$$;

create function public.shop_can_see_order(p_order uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.orders o join public.malls m on m.id = o.mall_id
                 where o.id = p_order
                   and (o.buyer_id = (select auth.uid()) or m.owner_id = (select auth.uid())));
$$;

revoke execute on function public.shop_require_mine(), public.shop_product_json(uuid),
  public.shop_mall_json(uuid), public.shop_order_json(uuid), public.shop_can_see_order(uuid)
  from public, anon, authenticated;

-- ─── Browsing ──────────────────────────────────────────────────────────────

-- Shops with something listed, newest first.
create function public.shop_malls() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.shop_mall_json(m.id) order by m.created_at desc), '[]')
  from public.malls m
  where exists (select 1 from public.products p where p.mall_id = m.id and p.published);
$$;

-- Listed products: 'all' (optionally one shop or a search), 'popular' or
-- 'deals'.
create function public.shop_products(p_kind text, p_mall uuid, p_query text)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(x.j order by x.rank desc, x.created_at desc), '[]')
  from (
    select public.shop_product_json(p.id) as j, p.created_at,
      case when p_kind = 'popular'
           then (select coalesce(sum(l.qty), 0) from public.order_lines l where l.product_id = p.id)
           else 0 end as rank
    from public.products p
    join public.malls m on m.id = p.mall_id
    where p.published
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

create function public.shop_product(p_id uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  p public.products;
begin
  select * into p from public.products where id = p_id;
  if not found or (not p.published and p.mall_id is distinct from public.shop_mine()) then
    raise exception 'This item is no longer listed.';
  end if;
  return jsonb_build_object(
    'product', public.shop_product_json(p.id),
    'reviews', (select coalesce(jsonb_agg(jsonb_build_object(
        'name', coalesce(u.full_name, u.username::text, 'Player'),
        'stars', r.stars, 'tags', r.tags, 'body', r.body, 'at', r.created_at,
        'level', case when r.show_level then (
          select jsonb_build_object('sport', s.sport, 'level', s.level)
          from public.player_sports s where s.user_id = r.user_id
          order by s.level desc limit 1) end)
        order by r.created_at desc), '[]')
      from (select * from public.product_reviews where product_id = p.id
            order by created_at desc limit 20) r
      join public.profiles u on u.id = r.user_id),
    'related', (select coalesce(jsonb_agg(public.shop_product_json(x.id)), '[]')
      from (select id from public.products where mall_id = p.mall_id and id <> p.id
              and published order by created_at desc limit 4) x));
end;
$$;

create function public.shop_mall(p_mall uuid) returns jsonb
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
                 from public.products p where p.mall_id = m.id and p.published))
  from public.malls m where m.id = p_mall;
$$;

create function public.shop_follow(p_mall uuid, p_on boolean) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_on then
    insert into public.mall_follows (mall_id, user_id) values (p_mall, (select auth.uid()))
    on conflict do nothing;
  else
    delete from public.mall_follows where mall_id = p_mall and user_id = (select auth.uid());
  end if;
end;
$$;

-- ─── Cart and checkout ─────────────────────────────────────────────────────

create function public.shop_cart() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', c.id, 'variant', c.variant, 'qty', c.qty,
    'product', public.shop_product_json(c.product_id)) order by c.created_at), '[]')
  from public.cart_lines c
  join public.products p on p.id = c.product_id
  where c.user_id = (select auth.uid()) and p.published;
$$;

create function public.shop_cart_add(p_product uuid, p_variant text, p_qty int)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  p public.products;
begin
  select * into p from public.products where id = p_product and published;
  if not found then raise exception 'This item is no longer listed.'; end if;
  if not p.service and p.stock <= 0 then raise exception 'This is sold out.'; end if;
  if p.mall_id = public.shop_mine() then raise exception 'This is from your own shop.'; end if;
  insert into public.cart_lines (user_id, product_id, variant, qty)
  values ((select auth.uid()), p_product, coalesce(p_variant, ''), greatest(p_qty, 1))
  on conflict (user_id, product_id, variant)
    do update set qty = least(public.cart_lines.qty + excluded.qty, 99);
end;
$$;

create function public.shop_cart_set(p_line uuid, p_qty int) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_qty <= 0 then
    delete from public.cart_lines where id = p_line and user_id = (select auth.uid());
  else
    update public.cart_lines set qty = least(p_qty, 99)
    where id = p_line and user_id = (select auth.uid());
  end if;
end;
$$;

-- Saves an address; the default one goes first.
create function public.shop_address_save(p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_id uuid;
begin
  if coalesce((p->>'is_default')::boolean, false) then
    update public.addresses set is_default = false where user_id = (select auth.uid());
  end if;
  insert into public.addresses (user_id, label, name, line, phone, is_default)
  values ((select auth.uid()), trim(p->>'label'), trim(p->>'name'), trim(p->>'line'),
          coalesce(trim(p->>'phone'), ''), coalesce((p->>'is_default')::boolean, false))
  returning id into v_id;
  return v_id;
end;
$$;

-- Places one order per shop for the cart, or just [p_only] for Buy now
-- ({"product", "variant", "qty"}). Buyers pay the shop directly, so nothing
-- is charged here. Returns the order ids.
create function public.shop_checkout(p_address jsonb, p_delivery text, p_only jsonb)
returns uuid[]
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := (select auth.uid());
  v_cents int;
  v_ids uuid[] := '{}';
  v_order uuid;
  v_mall uuid;
  v_first boolean := true;
  l record;
  v_owner uuid;
begin
  v_cents := case p_delivery when 'Standard' then 199 when 'Express' then 499
                             when 'Pick up' then 0 end;
  if v_cents is null then raise exception 'Pick a delivery option.'; end if;
  if p_delivery <> 'Pick up' and coalesce(trim(p_address->>'line'), '') = '' then
    raise exception 'Add a delivery address.';
  end if;

  create temp table if not exists pg_temp.checkout_lines (
    product_id uuid, variant text, qty int) on commit drop;
  delete from pg_temp.checkout_lines where true;
  if p_only is not null then
    insert into pg_temp.checkout_lines
    values ((p_only->>'product')::uuid, coalesce(p_only->>'variant', ''),
            greatest(coalesce((p_only->>'qty')::int, 1), 1));
  else
    insert into pg_temp.checkout_lines
    select product_id, variant, qty from public.cart_lines where user_id = v_me;
  end if;
  if not exists (select 1 from pg_temp.checkout_lines) then
    raise exception 'Your cart is empty.';
  end if;

  for v_mall in
    select distinct p.mall_id from pg_temp.checkout_lines c
    join public.products p on p.id = c.product_id
  loop
    insert into public.orders (buyer_id, mall_id, delivery, delivery_cents, address, arrives)
    values (v_me, v_mall, p_delivery, case when v_first then v_cents else 0 end,
            p_address,
            current_date + case p_delivery when 'Express' then 1 else 4 end)
    returning id into v_order;
    v_first := false;
    for l in
      select c.*, p.name, p.price_cents, p.stock, p.service, p.published
      from pg_temp.checkout_lines c join public.products p on p.id = c.product_id
      where p.mall_id = v_mall
      for update of p
    loop
      if not l.published then raise exception '% is no longer listed.', l.name; end if;
      if not l.service and l.stock < l.qty then
        raise exception 'Only % of % left.', l.stock, l.name;
      end if;
      insert into public.order_lines (order_id, product_id, name, variant, qty, price_cents)
      values (v_order, l.product_id, l.name, l.variant, l.qty, l.price_cents);
      if not l.service then
        update public.products set stock = stock - l.qty where id = l.product_id;
      end if;
    end loop;
    select owner_id into v_owner from public.malls where id = v_mall;
    if v_owner = v_me then raise exception 'You can''t order from your own shop.'; end if;
    perform public.notify(v_owner, 'New order to pack',
      (select coalesce(full_name, username::text, 'A player') from public.profiles where id = v_me)
        || ' ordered. They pay you on delivery or pickup.',
      '★', '/shop/seller/orders/' || v_order, '#16181B', '#C6FF00');
    v_ids := v_ids || v_order;
  end loop;
  if p_only is null then
    delete from public.cart_lines where user_id = v_me;
  end if;
  return v_ids;
end;
$$;

-- A service such as restringing, booked for a slot.
create function public.shop_book_service(p_product uuid, p_slot text, p_tension text)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  p public.products;
  v_order uuid;
  v_owner uuid;
begin
  select * into p from public.products where id = p_product and published and service;
  if not found then raise exception 'This service is no longer offered.'; end if;
  select owner_id into v_owner from public.malls where id = p.mall_id;
  if v_owner = (select auth.uid()) then raise exception 'This is from your own shop.'; end if;
  insert into public.orders (buyer_id, mall_id, delivery, service, booking)
  values ((select auth.uid()), p.mall_id, 'Drop-off', true, left(p_slot, 120))
  returning id into v_order;
  insert into public.order_lines (order_id, product_id, name, variant, qty, price_cents)
  values (v_order, p.id, p.name, left(concat_ws(' · ', nullif(p_tension, ''), p_slot), 120),
          1, p.price_cents);
  perform public.notify(v_owner, 'New booking', p.name || ' · ' || p_slot, '★',
    '/shop/seller/orders/' || v_order, '#16181B', '#C6FF00');
  return v_order;
end;
$$;

-- ─── Orders ────────────────────────────────────────────────────────────────

create function public.shop_orders() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.shop_order_json(id) order by placed_at desc), '[]')
  from public.orders where buyer_id = (select auth.uid());
$$;

create function public.shop_order(p_order uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.shop_can_see_order(p_order) then
    raise exception 'This order isn''t yours.';
  end if;
  return public.shop_order_json(p_order);
end;
$$;

create function public.shop_confirm_received(p_order uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.orders set step = 'delivered', delivered_at = now()
  where id = p_order and buyer_id = (select auth.uid()) and step in ('packing', 'shipped');
  if not found then raise exception 'This order can''t be marked received.'; end if;
end;
$$;

-- Cancels before it ships and puts the stock back. Nothing was charged, so
-- the refund is 0.
create function public.shop_cancel(p_order uuid, p_reason text) returns int
language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order and buyer_id = (select auth.uid());
  if not found then raise exception 'This order isn''t yours.'; end if;
  if o.step <> 'packing' then raise exception 'It has shipped, so ask for a return instead.'; end if;
  update public.orders set step = 'cancelled', cancelled_at = now(),
    cancel_reason = left(p_reason, 120) where id = p_order;
  update public.products p set stock = p.stock + l.qty
  from public.order_lines l
  where l.order_id = p_order and l.product_id = p.id and not p.service;
  perform public.notify((select owner_id from public.malls where id = o.mall_id),
    'Order cancelled', coalesce(p_reason, 'The buyer cancelled before it shipped.'), '!',
    '/shop/seller/orders/' || p_order);
  return 0;
end;
$$;

-- A review of everything in a delivered order.
create function public.shop_review(
  p_order uuid, p_stars int, p_tags text[], p_body text, p_show_level boolean
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order and buyer_id = (select auth.uid());
  if not found then raise exception 'This order isn''t yours.'; end if;
  if o.step <> 'delivered' then raise exception 'You can review once it arrives.'; end if;
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

-- Asks the shop to take it back, within 7 days of delivery.
create function public.shop_return_request(p_order uuid, p_reason text, p_want text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order and buyer_id = (select auth.uid());
  if not found then raise exception 'This order isn''t yours.'; end if;
  if o.step <> 'delivered' or o.service then
    raise exception 'Returns open once a delivered item arrives.';
  end if;
  if o.delivered_at < now() - interval '7 days' then
    raise exception 'Returns close 7 days after delivery.';
  end if;
  insert into public.order_returns (order_id, reason, want) values (p_order, p_reason, p_want);
  perform public.notify((select owner_id from public.malls where id = o.mall_id),
    'Return request', p_reason || ' · ' || p_want || '. Answer within 2 working days.', '!',
    '/shop/seller/orders/' || p_order);
exception when unique_violation then
  raise exception 'You''ve already asked to return this.';
end;
$$;

-- ─── Seller ────────────────────────────────────────────────────────────────

create function public.shop_open(p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_id uuid;
  v_name text := trim(coalesce(p->>'name', ''));
begin
  if public.shop_mine() is not null then raise exception 'You already have a shop.'; end if;
  if char_length(v_name) < 2 then raise exception 'Give your shop a name.'; end if;
  insert into public.malls (owner_id, name, initials, blurb, about, ships_from)
  values ((select auth.uid()), v_name,
          upper(left(regexp_replace(initcap(v_name), '[^A-Z0-9]', '', 'g') || v_name, 2)),
          left(coalesce(trim(p->>'blurb'), ''), 80),
          left(coalesce(trim(p->>'about'), ''), 1000),
          left(coalesce(trim(p->>'ships_from'), ''), 80))
  returning id into v_id;
  return v_id;
exception when unique_violation then
  raise exception 'Another shop has that name.';
end;
$$;

create function public.shop_seller_summary() returns jsonb
language sql stable security definer set search_path = '' as $$
  select case when m.id is null then null else jsonb_build_object(
    'mall', public.shop_mall_json(m.id),
    'sales_today_cents', (select coalesce(sum(l.qty * l.price_cents), 0)
      from public.orders o join public.order_lines l on l.order_id = o.id
      where o.mall_id = m.id and o.step <> 'cancelled'
        and o.placed_at >= date_trunc('day', now() at time zone 'Asia/Singapore') at time zone 'Asia/Singapore'),
    'to_ship', (select count(*) from public.orders where mall_id = m.id and step = 'packing'),
    'on_the_way', (select count(*) from public.orders where mall_id = m.id and step = 'shipped'),
    'returns', (select count(*) from public.order_returns r join public.orders o on o.id = r.order_id
                where o.mall_id = m.id and r.status = 'requested'),
    'listed', (select count(*) from public.products where mall_id = m.id and published),
    'low_stock', (select count(*) from public.products
                  where mall_id = m.id and not service and stock <= 3)) end
  from (select public.shop_mine() as id) m;
$$;

create function public.shop_seller_orders() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.shop_order_json(id) order by placed_at desc), '[]')
  from public.orders where mall_id = public.shop_mine();
$$;

create function public.shop_seller_products() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.shop_product_json(id) order by created_at desc), '[]')
  from public.products where mall_id = public.shop_mine();
$$;

create function public.shop_save_product(p jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_mall uuid := public.shop_require_mine();
  v_id uuid := nullif(p->>'id', '')::uuid;
begin
  if v_id is null then
    insert into public.products (mall_id, name, description, price_cents, old_price_cents,
      max_points, art, service, stock, published, options)
    values (v_mall, trim(p->>'name'), coalesce(p->>'description', ''),
      (p->>'price_cents')::int, nullif(p->>'old_price_cents', '')::int,
      coalesce((p->>'max_points')::int, 0), coalesce(p->>'art', 'bag'),
      coalesce((p->>'service')::boolean, false), coalesce((p->>'stock')::int, 0),
      coalesce((p->>'published')::boolean, false), coalesce(p->'options', '[]'))
    returning id into v_id;
  else
    update public.products set name = trim(p->>'name'),
      description = coalesce(p->>'description', description),
      price_cents = (p->>'price_cents')::int,
      old_price_cents = nullif(p->>'old_price_cents', '')::int,
      max_points = coalesce((p->>'max_points')::int, max_points),
      service = coalesce((p->>'service')::boolean, service),
      stock = coalesce((p->>'stock')::int, stock),
      published = coalesce((p->>'published')::boolean, published)
    where id = v_id and mall_id = v_mall;
    if not found then raise exception 'This product isn''t in your shop.'; end if;
  end if;
  return public.shop_product_json(v_id);
end;
$$;

create function public.shop_mark_shipped(p_order uuid, p_courier text, p_tracking text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order and mall_id = public.shop_mine();
  if not found then raise exception 'This order isn''t for your shop.'; end if;
  if o.step <> 'packing' then raise exception 'This order has already moved on.'; end if;
  update public.orders set step = 'shipped', shipped_at = now(),
    courier = nullif(left(trim(p_courier), 40), ''),
    tracking = nullif(left(trim(p_tracking), 60), '')
  where id = p_order;
  perform public.notify(o.buyer_id,
    case when o.service then 'Your booking is ready'
         when o.delivery = 'Pick up' then 'Ready to collect'
         else 'Your order is on the way' end,
    (select name from public.malls where id = o.mall_id)
      || coalesce(' · ' || nullif(trim(p_courier), '') || ' ' || coalesce(trim(p_tracking), ''), ''),
    '★', '/shop/orders/' || p_order, '#16181B', '#C6FF00');
end;
$$;

-- The shop accepts or declines a return. Accepted items go back in stock.
create function public.shop_return_decide(p_order uuid, p_accept boolean) returns void
language plpgsql security definer set search_path = '' as $$
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order and mall_id = public.shop_mine();
  if not found then raise exception 'This order isn''t for your shop.'; end if;
  update public.order_returns
  set status = case when p_accept then 'accepted' else 'declined' end, decided_at = now()
  where order_id = p_order and status = 'requested';
  if not found then raise exception 'There''s no return waiting on this order.'; end if;
  if p_accept then
    update public.products p set stock = p.stock + l.qty
    from public.order_lines l
    where l.order_id = p_order and l.product_id = p.id and not p.service;
  end if;
  perform public.notify(o.buyer_id,
    case when p_accept then 'Return accepted' else 'Return declined' end,
    (select name from public.malls where id = o.mall_id)
      || case when p_accept then ' will contact you to collect it.'
              else '. Chat with support if you think this is wrong.' end,
    case when p_accept then '✓' else '!' end, '/shop/orders/' || p_order);
end;
$$;

-- A report about a listing, shop or order, for the safety team.
create function public.shop_report(p_what text, p_reason text, p_note text) returns void
language sql security definer set search_path = '' as $$
  insert into public.content_reports (reporter_id, target_kind, target_id, reason, note)
  values ((select auth.uid()), 'listing', left(p_what, 200), left(p_reason, 40),
          left(coalesce(p_note, ''), 1000));
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'shop_mine()', 'shop_malls()', 'shop_products(text, uuid, text)', 'shop_product(uuid)',
    'shop_mall(uuid)', 'shop_follow(uuid, boolean)', 'shop_cart()',
    'shop_cart_add(uuid, text, int)', 'shop_cart_set(uuid, int)', 'shop_address_save(jsonb)',
    'shop_checkout(jsonb, text, jsonb)', 'shop_book_service(uuid, text, text)',
    'shop_orders()', 'shop_order(uuid)', 'shop_confirm_received(uuid)',
    'shop_cancel(uuid, text)', 'shop_review(uuid, int, text[], text, boolean)',
    'shop_return_request(uuid, text, text)', 'shop_open(jsonb)', 'shop_seller_summary()',
    'shop_seller_orders()', 'shop_seller_products()', 'shop_save_product(jsonb)',
    'shop_mark_shipped(uuid, text, text)', 'shop_return_decide(uuid, boolean)',
    'shop_report(text, text, text)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;
