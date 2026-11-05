-- P4d-03: a voucher at Shop checkout. It takes one unit of one item down at the
-- shop that funds it, so the buyer pays less and the shop gets less. Commission
-- is on the price after the voucher (decision 7), and voucher or points, per
-- item. A voucher is not money in the ledger.

insert into public.app_settings (key, value, description) values
  ('voucher.min_pay_minor', '50', 'What must be left to pay on an item: the smallest card charge');

alter table public.orders add column voucher_id uuid references public.vouchers (id);

-- May this person use this voucher at this shop? Raises anything that stops it.
create function private.voucher_usable(p_voucher uuid, p_mall uuid) returns public.voucher_types
language plpgsql stable security definer set search_path = '' as $$
-- Definer: vouchers have no client access.
declare
  v public.vouchers;
  t public.voucher_types;
begin
  select * into v from public.vouchers where id = p_voucher and owner_id = auth.uid();
  if v.id is null then raise exception 'This voucher isn''t yours.'; end if;
  if v.status = 'held' then raise exception 'This voucher opens with court booking.'; end if;
  if v.status <> 'issued' then raise exception 'This voucher has been used.'; end if;
  if v.expires_at <= now() then raise exception 'This voucher has expired.'; end if;
  select * into t from public.voucher_types where id = v.type_id;
  if t.mall_id is distinct from p_mall then raise exception 'This voucher is for another shop.'; end if;
  return t;
end;
$$;

-- Prices the cart, with a voucher on the first item it fits. One unit takes it,
-- so an item with more than one splits into two lines.
drop function public.shop_quote(uuid, jsonb, bigint);
drop function private.shop_price(uuid, jsonb, bigint);
create function private.shop_price(p_mall uuid, p_lines jsonb, p_points bigint default 0, p_voucher uuid default null)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: products have no client policies.
declare
  m public.malls;
  l record;
  u record;
  t public.voucher_types;
  v_left bigint := coalesce(p_points, 0);
  v_unit_points bigint;
  v_cap bigint := 0;
  v_total bigint := 0;
  v_out jsonb := '[]';
  v_priced int := 0;
  v_off bigint := 0;
  v_qty int;
  v_floor bigint := private.setting_int('voucher.min_pay_minor');
begin
  select * into m from public.malls where id = p_mall and active;
  if m.id is null then raise exception 'This shop isn''t open.'; end if;
  if p_voucher is not null then t := private.voucher_usable(p_voucher, p_mall); end if;
  for l in
    select x.product_id, x.variant, x.qty, p.name, p.price_cents, p.stock, p.service
    from jsonb_to_recordset(p_lines) as x(product_id uuid, variant text, qty int)
    join public.products p on p.id = x.product_id and p.mall_id = p_mall
    where private.product_on_sale(p.id)
    order by p.id, x.variant
  loop
    v_priced := v_priced + 1;
    v_qty := l.qty;
    if p_voucher is not null and v_off = 0 and l.price_cents > v_floor
       and (t.product_id is null or t.product_id = l.product_id) then
      v_off := least(t.amount_minor, l.price_cents - v_floor);
      select * into u from private.shop_unit(l.price_cents::bigint, m.commission_on_top, 'SGD', v_off);
      v_total := v_total + u.buyer;
      v_out := v_out || jsonb_build_object('product_id', l.product_id, 'variant', coalesce(l.variant, ''),
        'qty', 1, 'name', l.name, 'price_cents', l.price_cents, 'service', l.service,
        'on_top', m.commission_on_top, 'unit_commission', u.commission, 'unit_shop', u.shop,
        'unit_voucher', v_off, 'unit_points', 0, 'unit_paid', u.buyer);
      v_qty := v_qty - 1;
      continue when v_qty = 0;
    end if;
    select * into u from private.shop_unit(l.price_cents::bigint, m.commission_on_top);
    v_unit_points := least(u.points_cap, v_left / v_qty);
    v_left := v_left - v_unit_points * v_qty;
    v_cap := v_cap + u.points_cap * v_qty;
    v_total := v_total + (u.buyer - v_unit_points) * v_qty;
    v_out := v_out || jsonb_build_object('product_id', l.product_id, 'variant', coalesce(l.variant, ''),
      'qty', v_qty, 'name', l.name, 'price_cents', l.price_cents, 'service', l.service,
      'on_top', m.commission_on_top, 'unit_commission', u.commission, 'unit_shop', u.shop,
      'unit_voucher', 0, 'unit_points', v_unit_points, 'unit_paid', u.buyer - v_unit_points);
  end loop;
  if p_voucher is not null and v_off = 0 then
    raise exception 'This voucher doesn''t fit anything in your cart.';
  end if;
  return jsonb_build_object('lines', v_out, 'total_minor', v_total, 'points_cap_minor', v_cap,
    'points_left_minor', v_left, 'collect_address', m.collect_address, 'priced', v_priced,
    'voucher_minor', v_off, 'voucher_id', p_voucher);
end;
$$;
revoke execute on function private.shop_price(uuid, jsonb, bigint, uuid) from public, anon;

create function public.shop_quote(p_mall uuid, p_only jsonb default null, p_points bigint default 0,
  p_voucher uuid default null)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads products, vouchers and the points ledger.
declare
  me uuid := auth.uid();
  q jsonb := private.shop_price(p_mall, private.shop_lines_for(me, p_mall, p_only), p_points, p_voucher);
begin
  return q || jsonb_build_object(
    'points_balance_minor', private.points_balance(me),
    'can_redeem', private.points_can_redeem(me),
    'refund_rule', private.refund_rule_text('shop'),
    'can_pay', private.flag('payments.enabled') and private.flag('shop.checkout'),
    'vouchers', (select coalesce(jsonb_agg(jsonb_build_object('id', v.id, 'name', t.name,
        'amount_minor', t.amount_minor, 'expires_at', v.expires_at) order by v.expires_at), '[]')
      from public.vouchers v join public.voucher_types t on t.id = v.type_id
      where v.owner_id = me and v.status = 'issued' and v.expires_at > now() and t.mall_id = p_mall));
end;
$$;
revoke execute on function public.shop_quote(uuid, jsonb, bigint, uuid) from public, anon;
grant execute on function public.shop_quote(uuid, jsonb, bigint, uuid) to authenticated;

do $$
declare
  d text;
  fixed text;
begin
  d := pg_get_functiondef('public.shop_reserve(uuid, text, bigint, bigint, jsonb, timestamptz)'::regprocedure);
  execute 'drop function public.shop_reserve(uuid, text, bigint, bigint, jsonb, timestamptz)';
  fixed := replace(d, 'p_slot timestamp with time zone DEFAULT NULL::timestamp with time zone)',
    'p_slot timestamp with time zone DEFAULT NULL::timestamp with time zone, p_voucher uuid DEFAULT NULL::uuid)');
  fixed := replace(fixed,
    $old$  if jsonb_array_length(q -> 'lines') <> jsonb_array_length(v_lines) then$old$,
    $new$  if (q ->> 'priced')::int <> jsonb_array_length(v_lines) then$new$);
  -- The voucher's row is locked before anything is taken, so two carts can't spend it.
  fixed := replace(fixed,
    $old$  q := private.shop_price(p_mall, v_lines, v_points);$old$,
    $new$  if p_voucher is not null then
    perform 1 from public.vouchers where id = p_voucher for update;
  end if;
  q := private.shop_price(p_mall, v_lines, v_points, p_voucher);$new$);
  fixed := replace(fixed,
    $old$  insert into public.orders (buyer_id, mall_id, idempotency_key, service, slot_at, hold_until)
  values (me, p_mall, p_key, v_service, p_slot, v_hold)$old$,
    $new$  insert into public.orders (buyer_id, mall_id, idempotency_key, service, slot_at, hold_until, voucher_id)
  values (me, p_mall, p_key, v_service, p_slot, v_hold, p_voucher)$new$);
  fixed := replace(fixed,
    $old$    insert into public.order_lines (order_id, product_id, name, variant, qty, price_cents, on_top,
      unit_commission, unit_points, unit_shop, unit_paid)$old$,
    $new$    insert into public.order_lines (order_id, product_id, name, variant, qty, price_cents, on_top,
      unit_commission, unit_points, unit_shop, unit_paid, unit_voucher)$new$);
  fixed := replace(fixed,
    $old$      (l ->> 'unit_points')::bigint, (l ->> 'unit_shop')::bigint, (l ->> 'unit_paid')::bigint);$old$,
    $new$      (l ->> 'unit_points')::bigint, (l ->> 'unit_shop')::bigint, (l ->> 'unit_paid')::bigint,
      (l ->> 'unit_voucher')::bigint);$new$);
  fixed := replace(fixed,
    $old$  perform private.points_spend(me, v_points, 'order', o.id::text);$old$,
    $new$  perform private.points_spend(me, v_points, 'order', o.id::text);

  if p_voucher is not null then
    update public.vouchers set status = 'used', used_at = now() where id = p_voucher;
    insert into public.voucher_redemptions (voucher_id, user_id, mall_id, order_id, kind, amount_minor)
    values (p_voucher, me, p_mall, o.id, 'used', (q ->> 'voucher_minor')::bigint);
  end if;$new$);
  if position('p_voucher' in fixed) = 0 or position('''priced''' in fixed) = 0
     or position('unit_voucher' in fixed) = 0 or position('voucher_redemptions' in fixed) = 0 then
    raise exception 'shop_reserve did not change';
  end if;
  execute fixed;
  execute 'revoke execute on function public.shop_reserve(uuid, text, bigint, bigint, jsonb, timestamptz, uuid) from public, anon';
  execute 'grant execute on function public.shop_reserve(uuid, text, bigint, bigint, jsonb, timestamptz, uuid) to authenticated';

  -- A cancelled order hands the voucher back, once, in the same stamped step as
  -- stock and points. It keeps its own expiry.
  d := pg_get_functiondef('private.order_unreserve(uuid)'::regprocedure);
  fixed := replace(d, $old$  perform private.points_return('order', p_order::text, 'all');$old$,
    $new$  perform private.points_return('order', p_order::text, 'all');
  perform private.voucher_return(p_order);$new$);
  if fixed = d then raise exception 'order_unreserve did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.shop_order_json(uuid)'::regprocedure);
  fixed := replace(d, $old$'unit_points', case when v.is_owner then 0 else l.unit_points end,$old$,
    $new$'unit_points', case when v.is_owner then 0 else l.unit_points end,
                 'unit_voucher', l.unit_voucher,$new$);
  if fixed = d then raise exception 'shop_order_json did not change'; end if;
  execute fixed;
end;
$$;

create function private.voucher_return(p_order uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the voucher. The caller holds the unreserve stamp, so this runs once.
declare
  o public.orders;
  r public.voucher_redemptions;
begin
  select * into o from public.orders where id = p_order;
  if o.voucher_id is null then return; end if;
  select * into r from public.voucher_redemptions
  where voucher_id = o.voucher_id and order_id = p_order and kind = 'used';
  if r.id is null then return; end if;
  update public.vouchers
  set status = case when expires_at <= now() then 'expired' else 'issued' end, used_at = null
  where id = o.voucher_id and status = 'used';
  insert into public.voucher_redemptions (voucher_id, user_id, mall_id, order_id, kind, amount_minor)
  values (o.voucher_id, r.user_id, r.mall_id, p_order, 'returned', r.amount_minor)
  on conflict do nothing;
end;
$$;
