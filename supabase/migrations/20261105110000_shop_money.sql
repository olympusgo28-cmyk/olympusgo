-- P4b-03, P4b-04: paying in the Shop and handing over. One order is one shop is
-- one payment, so refunds, disputes, reconciliation and payouts are 4a's own.
-- The whole payment sits in `held` until handover. Commission is recognised at
-- release, so a cancel has nothing to reverse.

alter table public.payments drop constraint payments_purpose_check;
alter table public.payments add constraint payments_purpose_check
  check (purpose in ('meet', 'ticket', 'tournament', 'host_spot', 'organizer_fee', 'debt', 'shop'));

-- How much of this refund was the shop's, and which lines it covered, so a void
-- can put back exactly that.
alter table public.refunds add column shop_minor bigint check (shop_minor >= 0);
alter table public.refunds add column order_lines jsonb;

do $$
declare
  d text := pg_get_functiondef('private.payment_guard()'::regprocedure);
  fixed text := replace(replace(d,
    'new.rule_snapshot, new.idempotency_key)', 'new.rule_snapshot, new.idempotency_key, new.order_id)'),
    'old.rule_snapshot, old.idempotency_key)', 'old.rule_snapshot, old.idempotency_key, old.order_id)');
begin
  if fixed = d then raise exception 'payment_guard did not change'; end if;
  execute fixed;
end;
$$;

create or replace function private.refund_rule_text(p_purpose text) returns text
language sql immutable set search_path = '' as $$
  select case p_purpose
    when 'meet' then 'Give up your spot before the Meet starts and you get the price back, without the fee. After that, no refund. If the organizer cancels, you get everything back.'
    when 'ticket' then 'Release your tickets up to 24 hours before the start and you get the price back, without the fee. After that, no refund. If the organizer cancels, you get everything back.'
    when 'tournament' then 'Withdraw before registration closes and you get the price back, without the fee. After that, no refund. If the organizer cancels, you get everything back.'
    when 'host_spot' then 'Give up your spot before the Meet starts and you get the S$2.00 fee back.'
    when 'shop' then 'Cancel any time before you collect and you get everything back, unless a service has started. Sports equipment is final once collected.'
    else 'This fee isn''t refundable unless the player leaves in time.' end;
$$;

create or replace function private.refund_issue(p_payment uuid, p_reason text, p_key text default null,
  p_price_limit bigint default null, p_actor uuid default null, p_fee_limit bigint default null)
returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: refunds and the ledger have no client write path.
declare
  pay public.payments;
  v_price bigint;
  v_fee bigint;
  v_shop bigint;
  v_lines jsonb := nullif(current_setting('og.order_refund_lines', true), '')::jsonb;
  q jsonb;
  v_id uuid;
begin
  select * into pay from public.payments where id = p_payment for update;
  if pay.status <> 'succeeded' then return 0; end if;
  -- A lost dispute already gave the money back.
  if exists (select 1 from public.payment_disputes d
      where d.payment_id = pay.id and d.status = 'lost' and d.amount_minor >= pay.amount_minor) then
    return 0;
  end if;
  select pay.price_minor - coalesce(sum(price_minor), 0), pay.fee_minor - coalesce(sum(fee_minor), 0)
  into v_price, v_fee
  from public.refunds where payment_id = pay.id and status <> 'voided';

  q := public.money_refund_quote(p_reason, v_price, v_fee, pay.method);
  v_price := (q ->> 'price_minor')::bigint;
  v_fee := (q ->> 'fee_minor')::bigint;
  if p_price_limit is not null then v_price := least(v_price, p_price_limit); end if;
  if p_fee_limit is not null then v_fee := least(v_fee, p_fee_limit); end if;
  if v_price + v_fee = 0 then return 0; end if;

  -- A Shop price sits in two places once released: the shop's earnings, and the
  -- commission. Each line says how much of it was the shop's.
  if pay.purpose = 'shop' then
    v_shop := least(v_price, private.order_refund_shop_part(pay.order_id));
  end if;

  -- An open dispute may yet take this money back, so the refund waits for it,
  -- for exactly this amount.
  if exists (select 1 from public.payment_disputes d
      where d.payment_id = pay.id and d.status = 'open') then
    update public.payments
    set refund_owed = coalesce(refund_owed, '[]'::jsonb) || jsonb_build_array(jsonb_build_object(
      'reason', p_reason, 'price', v_price, 'fee', v_fee, 'shop', v_shop, 'lines', v_lines))
    where id = pay.id;
    perform private.money_alert('refund_blocked_by_dispute', 'dispute-refund:' || pay.id,
      jsonb_build_object('payment', pay.id));
    return 0;
  end if;

  insert into public.refunds (payment_id, reason, price_minor, fee_minor, organizer_pays_fee,
    idempotency_key, actor, shop_minor, order_lines)
  values (pay.id, p_reason, v_price, v_fee, (q ->> 'organizer_pays_card_fee')::boolean,
    coalesce(p_key, p_reason || ':' || pay.id), p_actor, v_shop, v_lines)
  on conflict (idempotency_key) do nothing
  returning id into v_id;
  if v_id is null then return 0; end if;

  perform private.ledger_post('refund', 'refund:' || v_id, pay.currency,
    jsonb_build_object('refund', v_id, 'payment', pay.id),
    jsonb_build_array(
      case when pay.released_at is null
        then private.ledger_line('held', pay.held_owner, v_price)
        else private.ledger_line('organizer', pay.organizer_id, coalesce(v_shop, v_price)) end,
      private.ledger_line('platform_fees', null,
        case when pay.released_at is null then 0 else v_price - coalesce(v_shop, v_price) end),
      private.ledger_line(case when pay.purpose = 'debt' then 'organizer_fee_debt' else 'platform_fees' end,
        case when pay.purpose = 'debt' then pay.user_id end, v_fee),
      private.ledger_line('refunds_pending', null, -(v_price + v_fee))));
  return v_price + v_fee;
end;
$$;
revoke execute on function private.refund_issue(uuid, text, text, bigint, uuid, bigint)
  from public, anon, authenticated;

create or replace function public.staff_refund_void(p_refund uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds, the ledger and the audit log.
declare
  r public.refunds;
  pay public.payments;
  v_gone boolean;
begin
  perform private.staff_require('payments');
  select * into r from public.refunds where id = p_refund for update;
  if r.id is null or r.status <> 'failed' then
    raise exception 'Only a failed refund can be voided.';
  end if;
  select * into pay from public.payments where id = r.payment_id for update;
  update public.refunds set status = 'voided', settled_at = now() where id = r.id;
  -- The items weren't refunded after all, so what went back on the shelf comes off.
  -- Points returned stay returned.
  update public.products p set stock = greatest(p.stock - x.qty, 0)
  from (select l.product_id, sum(y.qty)::int as qty
        from jsonb_to_recordset(coalesce(r.order_lines, '[]')) as y(line uuid, qty int, restock boolean)
        join public.order_lines l on l.id = y.line
        where y.restock group by l.product_id) x
  where p.id = x.product_id and not exists (select 1 from public.orders o
    -- A closed order's units are all back on the shelf, and stay there.
    where o.id = pay.order_id and o.step in ('cancelled', 'expired'));
  update public.order_lines l set refunded_qty = l.refunded_qty - x.qty
  from jsonb_to_recordset(coalesce(r.order_lines, '[]')) as x(line uuid, qty int)
  where l.id = x.line;
  -- A lost dispute booked this refund as OlympusGO's loss, so that's what it undoes.
  v_gone := exists (select 1 from public.ledger_transactions t
    where t.kind = 'dispute_lost' and t.reference ->> 'payment' = pay.id::text);
  -- An order that was refunded in full is live again: a sale if it was paid out,
  -- and staff's to decide if not.
  if not v_gone then
    update public.orders set step = case when pay.released_at is null then 'reported' else 'released' end
    where id = pay.order_id and step = 'refunded';
  end if;
  perform private.ledger_post('refund_void', 'refund_void:' || r.id, pay.currency,
    jsonb_build_object('refund', r.id, 'payment', pay.id),
    jsonb_build_array(private.ledger_line('refunds_pending', null, r.amount_minor),
      case when pay.released_at is null
        then private.ledger_line('held', pay.held_owner, -r.price_minor)
        when v_gone then private.ledger_line('platform_fees', null, -r.price_minor)
        else private.ledger_line('organizer', pay.organizer_id, -coalesce(r.shop_minor, r.price_minor)) end,
      private.ledger_line('platform_fees', null,
        case when pay.released_at is null or v_gone then 0
          else -(r.price_minor - coalesce(r.shop_minor, r.price_minor)) end),
      private.ledger_line(case when pay.purpose = 'debt' then 'organizer_fee_debt' else 'platform_fees' end,
        case when pay.purpose = 'debt' then pay.user_id end, -r.fee_minor)));
  perform private.staff_audit('refund_void', 'refund', r.id::text, p_reason);
end;
$$;

-- Everything goes back once: stock and points. The stamp is what makes it once.
create function private.order_unreserve(p_order uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: changes stock and the points ledger.
begin
  update public.orders set unreserved_at = now() where id = p_order and unreserved_at is null;
  if not found then return false; end if;
  -- By product, since an order can hold two variants of one, and in product
  -- order, like every other lock on stock.
  perform 1 from public.products p
  where p.id in (select l.product_id from public.order_lines l where l.order_id = p_order)
  order by p.id for update;
  update public.products p set stock = p.stock + x.back
  from (select l.product_id, sum(l.qty - l.refunded_qty)::int as back
        from public.order_lines l join public.orders o on o.id = l.order_id
        where l.order_id = p_order and not o.service
        group by l.product_id) x
  where p.id = x.product_id;
  perform private.points_return('order', p_order::text, 'all');
  return true;
end;
$$;

-- A shop's share of a refund. Staff name the lines, so they say how much. Anything
-- else refunds all that's left of the order.
create function private.order_refund_shop_part(p_order uuid) returns bigint
language plpgsql stable security definer set search_path = '' as $$
-- Definer: order lines have no client access.
declare
  v_shop bigint := nullif(current_setting('og.order_refund_shop', true), '')::bigint;
begin
  if v_shop is not null then return v_shop; end if;
  return (select coalesce(sum(l.unit_shop * (l.qty - l.refunded_qty)), 0)::bigint
    from public.order_lines l where l.order_id = p_order);
end;
$$;

-- When an order's money goes to the shop. A shop can't shorten the buyer's time
-- by marking it ready at the last minute.
create function private.order_due(o public.orders) returns timestamptz
language sql stable set search_path = '' as $$
  select greatest(o.release_at, o.ready_at + make_interval(hours => private.setting_int('shop.release_hours')));
$$;

-- Pays the shop what's left of an order, once, and takes the commission.
create function private.release_order(p_order uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the ledger.
declare
  pay public.payments;
  v_net bigint;
  v_shop bigint;
begin
  select * into pay from public.payments where order_id = p_order for update;
  if pay.id is null or pay.status <> 'succeeded' or pay.released_at is not null then
    return false;
  end if;
  if pay.refund_owed is not null or exists (select 1 from public.payment_disputes d
      where d.payment_id = pay.id and d.status = 'open') then
    return false;
  end if;
  select pay.price_minor - coalesce(sum(r.price_minor), 0) into v_net
  from public.refunds r where r.payment_id = pay.id and r.status <> 'voided';
  select coalesce(sum(l.unit_shop * (l.qty - l.refunded_qty)), 0) into v_shop
  from public.order_lines l where l.order_id = p_order;
  -- Never pay a shop out of OlympusGO's money.
  if v_net < v_shop then
    perform private.money_alert('release_short', 'release-short:' || p_order, jsonb_build_object('order', p_order));
    return false;
  end if;
  perform private.ledger_post('release', 'release:' || pay.id, pay.currency,
    jsonb_build_object('payment', pay.id, 'order', p_order),
    jsonb_build_array(private.ledger_line('held', p_order, v_net),
      private.ledger_line('organizer', pay.organizer_id, -v_shop),
      private.ledger_line('platform_fees', null, -(v_net - v_shop))));
  update public.payments set released_at = now() where id = pay.id;
  update public.orders set released_at = now() where id = p_order;
  return true;
end;
$$;

-- Prices a list of {product, variant, qty} for a shop, and spreads the points.
create function private.shop_price(p_mall uuid, p_lines jsonb, p_points bigint default 0) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: products have no client policies.
declare
  m public.malls;
  l record;
  u record;
  v_left bigint := coalesce(p_points, 0);
  v_unit_points bigint;
  v_cap bigint := 0;
  v_total bigint := 0;
  v_out jsonb := '[]';
begin
  select * into m from public.malls where id = p_mall and active;
  if m.id is null then raise exception 'This shop isn''t open.'; end if;
  for l in
    select x.product_id, x.variant, x.qty, p.name, p.price_cents, p.stock, p.service
    from jsonb_to_recordset(p_lines) as x(product_id uuid, variant text, qty int)
    join public.products p on p.id = x.product_id and p.mall_id = p_mall
    where private.product_on_sale(p.id)
    order by p.id, x.variant
  loop
    select * into u from private.shop_unit(l.price_cents::bigint, m.commission_on_top);
    v_unit_points := least(u.points_cap, v_left / l.qty);
    v_left := v_left - v_unit_points * l.qty;
    v_cap := v_cap + u.points_cap * l.qty;
    v_total := v_total + (u.buyer - v_unit_points) * l.qty;
    v_out := v_out || jsonb_build_object('product_id', l.product_id, 'variant', coalesce(l.variant, ''),
      'qty', l.qty, 'name', l.name, 'price_cents', l.price_cents, 'service', l.service,
      'on_top', m.commission_on_top, 'unit_commission', u.commission, 'unit_shop', u.shop,
      'unit_points', v_unit_points, 'unit_paid', u.buyer - v_unit_points);
  end loop;
  return jsonb_build_object('lines', v_out, 'total_minor', v_total, 'points_cap_minor', v_cap,
    'points_left_minor', v_left, 'collect_address', m.collect_address);
end;
$$;

create function private.shop_lines_for(p_user uuid, p_mall uuid, p_only jsonb) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: cart_lines has no client policies.
  select case when p_only is not null then jsonb_build_array(jsonb_build_object(
      'product_id', p_only ->> 'product', 'variant', left(coalesce(p_only ->> 'variant', ''), 120),
      'qty', greatest(coalesce((p_only ->> 'qty')::int, 1), 1)))
    else coalesce((select jsonb_agg(jsonb_build_object('product_id', c.product_id, 'variant', c.variant,
        'qty', c.qty))
      from public.cart_lines c join public.products p on p.id = c.product_id
      where c.user_id = p_user and p.mall_id = p_mall and private.product_on_sale(p.id)), '[]') end;
$$;

-- The final price before paying, from the same arithmetic as the charge.
create function public.shop_quote(p_mall uuid, p_only jsonb default null, p_points bigint default 0)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads products and the points ledger.
declare
  me uuid := auth.uid();
  q jsonb := private.shop_price(p_mall, private.shop_lines_for(me, p_mall, p_only), p_points);
begin
  return q || jsonb_build_object(
    'points_balance_minor', private.points_balance(me),
    'can_redeem', private.points_can_redeem(me),
    'refund_rule', private.refund_rule_text('shop'),
    'can_pay', private.flag('payments.enabled') and private.flag('shop.checkout'));
end;
$$;

create function public.shop_reserve(p_mall uuid, p_key text, p_expected_minor bigint,
  p_points bigint default 0, p_only jsonb default null, p_slot timestamptz default null)
returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: takes stock and points in one transaction.
declare
  me uuid := auth.uid();
  o public.orders;
  m public.malls;
  pay public.payments;
  q jsonb;
  l jsonb;
  v_lines jsonb;
  v_service boolean;
  v_hold timestamptz;
  v_points bigint := coalesce(p_points, 0);
begin
  if me is null then raise exception 'Sign in first.'; end if;
  if p_key is null or length(p_key) < 8 then raise exception 'Try that again.'; end if;
  if private.is_restricted(me) or private.audience_of(me) = 'child' then
    raise exception 'Ask a parent to buy this for you.';
  end if;
  if v_points < 0 then raise exception 'Try that again.'; end if;

  -- Points are spent one order at a time, so two carts can't share a balance.
  perform pg_advisory_xact_lock(hashtext('points:' || me));

  select * into o from public.orders where buyer_id = me and idempotency_key = p_key;
  if o.id is not null then
    if o.mall_id <> p_mall then raise exception 'Try that again.'; end if;
    select * into pay from public.payments where order_id = o.id;
    return private.payment_json(pay) || jsonb_build_object('result', 'reserved', 'order_id', o.id);
  end if;

  if not (private.flag('payments.enabled') and private.flag('shop.checkout')) then
    raise exception 'Paying in the Shop isn''t open yet.';
  end if;
  select * into m from public.malls where id = p_mall and active;
  if m.id is null or m.owner_id is null then raise exception 'This shop isn''t open.'; end if;
  if m.owner_id = me then raise exception 'This is from your own shop.'; end if;
  if public.is_blocked_between(me, m.owner_id) then raise exception 'You can''t buy from this shop.'; end if;

  v_lines := private.shop_lines_for(me, p_mall, p_only);
  if jsonb_array_length(v_lines) = 0 then raise exception 'Your cart is empty.'; end if;

  -- A live order for this shop: finish that one rather than take stock twice,
  -- but only if it's exactly what they're paying for now.
  select * into o from public.orders where buyer_id = me and mall_id = p_mall and step = 'pending';
  if o.id is not null then
    select * into pay from public.payments where order_id = o.id;
    if pay.amount_minor is distinct from p_expected_minor or o.slot_at is distinct from p_slot
       or exists (
         (select (x ->> 'product_id')::uuid, x ->> 'variant', (x ->> 'qty')::int
          from jsonb_array_elements(v_lines) x
          except select l.product_id, l.variant, l.qty from public.order_lines l where l.order_id = o.id)
         union all
         (select l.product_id, l.variant, l.qty from public.order_lines l where l.order_id = o.id
          except select (x ->> 'product_id')::uuid, x ->> 'variant', (x ->> 'qty')::int
          from jsonb_array_elements(v_lines) x)) then
      raise exception 'Finish or cancel your unpaid order at this shop first.';
    end if;
    return private.payment_json(pay) || jsonb_build_object('result', 'reserved', 'order_id', o.id);
  end if;

  -- Sorted, so two buyers of the same items can't deadlock.
  perform 1 from public.products p
  where p.id in (select (x ->> 'product_id')::uuid from jsonb_array_elements(v_lines) x)
  order by p.id for update;

  if v_points > 0 and not private.points_can_redeem(me) then
    raise exception 'Points can''t be used yet.';
  end if;
  q := private.shop_price(p_mall, v_lines, v_points);
  if jsonb_array_length(q -> 'lines') <> jsonb_array_length(v_lines) then
    raise exception 'Something in your cart is no longer listed.';
  end if;
  if (q ->> 'points_left_minor')::bigint > 0 then
    raise exception 'You can use up to % points here.', (q ->> 'points_cap_minor')::bigint / 10;
  end if;
  -- The price shown is the price charged, or nothing is.
  if (q ->> 'total_minor')::bigint is distinct from p_expected_minor then
    raise exception 'price_changed' using errcode = 'P0001';
  end if;

  v_service := exists (select 1 from jsonb_array_elements(q -> 'lines') x where (x ->> 'service')::boolean);
  if v_service then
    if jsonb_array_length(v_lines) > 1 then raise exception 'Book a service on its own.'; end if;
    if p_slot is null or p_slot <= now()
       or p_slot > now() + make_interval(days => private.setting_int('money.max_advance_days')) then
      raise exception 'Pick a time for this.';
    end if;
  elsif p_slot is not null then
    raise exception 'Try that again.';
  end if;

  v_hold := now() + make_interval(mins => private.setting_int('shop.hold_minutes'));
  insert into public.orders (buyer_id, mall_id, idempotency_key, service, slot_at, hold_until)
  values (me, p_mall, p_key, v_service, p_slot, v_hold)
  returning * into o;

  for l in select x from jsonb_array_elements(q -> 'lines') x loop
    if not private.product_on_sale((l ->> 'product_id')::uuid) then
      raise exception '% is no longer listed.', l ->> 'name';
    end if;
    if not (l ->> 'service')::boolean then
      update public.products set stock = stock - (l ->> 'qty')::int
      where id = (l ->> 'product_id')::uuid and stock >= (l ->> 'qty')::int;
      if not found then raise exception 'Not enough of % left.', l ->> 'name'; end if;
    end if;
    insert into public.order_lines (order_id, product_id, name, variant, qty, price_cents, on_top,
      unit_commission, unit_points, unit_shop, unit_paid)
    values (o.id, (l ->> 'product_id')::uuid, l ->> 'name', l ->> 'variant', (l ->> 'qty')::int,
      (l ->> 'price_cents')::int, (l ->> 'on_top')::boolean, (l ->> 'unit_commission')::bigint,
      (l ->> 'unit_points')::bigint, (l ->> 'unit_shop')::bigint, (l ->> 'unit_paid')::bigint);
  end loop;

  perform private.points_spend(me, v_points, 'order', o.id::text);

  insert into public.payments (user_id, order_id, purpose, price_minor, fee_minor, amount_minor,
    currency, organizer_id, rule_snapshot, idempotency_key, hold_until)
  values (me, o.id, 'shop', (q ->> 'total_minor')::bigint, 0, (q ->> 'total_minor')::bigint, 'SGD',
    m.owner_id, jsonb_build_object('refund_rule', private.refund_rule_text('shop')), p_key, v_hold)
  returning * into pay;
  return private.payment_json(pay) || jsonb_build_object('result', 'reserved', 'order_id', o.id);
end;
$$;

-- What capture does for an order, with the order and payment locked. The
-- order's step decides, not the clock: while it's pending, the money is in time.
create function private.order_captured(pay public.payments, was public.payments) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: runs for the webhook.
declare
  o public.orders;
  m public.malls;
  v_collect timestamptz;
begin
  select * into o from public.orders where id = pay.order_id;
  select * into m from public.malls where id = o.mall_id;
  if o.step = 'pending' and was.status = 'pending'
     and not private.is_restricted(pay.user_id) and not private.is_suspended(pay.user_id)
     and not public.is_blocked_between(pay.user_id, m.owner_id) then
    v_collect := coalesce(o.slot_at, now() + make_interval(days => private.setting_int('shop.collect_days')));
    update public.orders
    set step = 'paid', paid_at = now(), hold_until = null, collect_by = v_collect,
        release_at = v_collect + make_interval(hours => private.setting_int('shop.release_hours'))
    where id = o.id;
    delete from public.cart_lines c
    where c.user_id = pay.user_id
      and (c.product_id, c.variant) in (select l.product_id, l.variant from public.order_lines l
        where l.order_id = o.id);
    begin
      perform public.notify(m.owner_id, 'New order to prepare', 'Open it to see what they bought.', '★',
        '/shop/owner/orders/' || o.id, '#16181B', '#C6FF00');
      perform public.notify(pay.user_id, 'You''ve paid', 'We''ll tell you when it''s ready to collect.',
        '✓', '/shop/orders/' || o.id, '#E3F7C8', '#2E5A00');
    exception when others then
      null;  -- An account has gone. The order stands.
    end;
    return 'seated';
  end if;

  -- Late money never takes the item (Q85): stock or points may be gone.
  if o.step = 'pending' then
    update public.orders set step = 'cancelled', hold_until = null,
      cancel_reason = 'Couldn''t be paid for', cancelled_at = now() where id = o.id;
    perform private.order_unreserve(o.id);
  end if;
  perform private.refund_issue(pay.id, 'late_no_spot');
  begin
    perform public.notify(pay.user_id, 'Your payment is coming back',
      'We couldn''t keep your order, so everything you paid is being refunded.', '!',
      '/shop/orders/' || o.id);
  exception when others then
    null;
  end;
  return 'refunded';
end;
$$;

do $$
declare
  d text := pg_get_functiondef('private.capture_succeeded(uuid, text, text, bigint, text, text)'::regprocedure);
  fixed text := d;
begin
  fixed := replace(fixed,
$old$  select * into was from public.payments where id = p_payment for update;$old$,
$new$  if pay.order_id is not null then
    perform 1 from public.orders where id = pay.order_id for update;
  end if;
  select * into was from public.payments where id = p_payment for update;$new$);
  fixed := replace(fixed, $old$private.ledger_line('held', pay.activity_id, -pay.price_minor)$old$,
    $new$private.ledger_line('held', pay.held_owner, -pay.price_minor)$new$);
  fixed := replace(fixed,
$old$  if pay.purpose = 'debt' then
    return 'captured';
  end if;$old$,
$new$  if pay.purpose = 'debt' then
    return 'captured';
  end if;
  if pay.purpose = 'shop' then
    return private.order_captured(pay, was);
  end if;$new$);
  if position('order_captured' in fixed) = 0 or position('pay.held_owner' in fixed) = 0
     or position('from public.orders where id = pay.order_id' in fixed) = 0 then
    raise exception 'capture_succeeded did not change';
  end if;
  execute fixed;
end;
$$;

-- A lost dispute gave the buyer their money, so it closes any order that hasn't
-- been paid out or collected: the chargeback takes what's still held, and whatever
-- was also refunded is OlympusGO's loss, not the shop's. A shop that handed the
-- goods over is paid as usual, and OlympusGO carries the chargeback (Q83). A
-- closed inquiry took no money, so it counts as won.
do $$
declare
  d text := pg_get_functiondef('public.money_svc_event(jsonb)'::regprocedure);
  fixed text := d;
begin
  fixed := replace(fixed, $old$      -- Won returns the money. Lost stays open for staff (Q72).
$old$, $new$      -- Won returns the money. Lost stays open for staff (Q72).
      -- Orders lock in the same order as everything else that touches them.
      select p.* into v_row from public.payments p
      join public.payment_disputes x on x.payment_id = p.id where x.stripe_dispute_id = o ->> 'id';
      if v_row.order_id is not null then
        perform pg_advisory_xact_lock(hashtext('points:' || v_row.user_id));
        perform 1 from public.orders where id = v_row.order_id for update;
      end if;
$new$);
  fixed := replace(fixed, $old$o ->> 'status' = 'won'$old$, $new$o ->> 'status' in ('won', 'warning_closed')$new$);
  -- A refund staff owed still goes out if the bank took back only part. If it
  -- took it all, the buyer has the money, so the shop gives back what it was paid
  -- for goods that went back on the shelf.
  fixed := replace(fixed, $old$          if o ->> 'status' in ('won', 'warning_closed') then
            for v_owed, v_index in$old$,
    $new$          if o ->> 'status' not in ('won', 'warning_closed') and (o ->> 'amount')::bigint = v_row.amount_minor
             and v_row.released_at is not null then
            select coalesce(sum((x ->> 'shop')::bigint), 0) into v_also
            from jsonb_array_elements(v_row.refund_owed) x;
            if v_also > 0 then
              perform private.ledger_post('dispute_owed', 'dispute_owed:' || (o ->> 'id'), v_row.currency,
                jsonb_build_object('payment', v_payment, 'dispute', o ->> 'id'),
                jsonb_build_array(private.ledger_line('organizer', v_row.organizer_id, v_also),
                  private.ledger_line('platform_fees', null, -v_also)));
            end if;
          end if;
          if o ->> 'status' in ('won', 'warning_closed') or (o ->> 'amount')::bigint <> v_row.amount_minor then
            for v_owed, v_index in$new$);
  fixed := replace(fixed, $old$        -- The chargeback returned what a cancelled Meet still owed, so there's
        -- nothing left to hold.
        if o ->> 'status' <> 'won' and v_row.released_at is null and (select a.status = 'cancelled'
            from public.activities a where a.id = v_row.activity_id) then$old$,
$new$        -- Part of a payment is for a person to work out.
        if o ->> 'status' not in ('won', 'warning_closed') and (o ->> 'amount')::bigint <> v_row.amount_minor then
          perform private.money_alert('dispute_partial', 'dispute-partial:' || (o ->> 'id'),
            jsonb_build_object('payment', v_payment));
        end if;
        -- The chargeback returned what a cancelled Meet still owed, so there's
        -- nothing left to hold.
        if o ->> 'status' not in ('won', 'warning_closed') and v_row.released_at is null
           and (o ->> 'amount')::bigint = v_row.amount_minor
           and (exists (select 1 from public.activities a where a.id = v_row.activity_id and a.status = 'cancelled')
             or exists (select 1 from public.orders x where x.id = v_row.order_id and x.step <> 'collected')) then$new$);
  fixed := replace(fixed, $old$private.ledger_line('held', v_row.activity_id, v_row.price_minor),
              private.ledger_line('platform_fees', null, v_row.fee_minor),$old$,
    $new$private.ledger_line('held', v_row.held_owner, v_row.price_minor - v_also),
              private.ledger_line('platform_fees', null, v_row.fee_minor + v_also),$new$);
  fixed := replace(fixed, $old$          perform private.ledger_post('dispute_lost', 'dispute_lost:' || (o ->> 'id'), v_row.currency,$old$,
    $new$          select coalesce(sum(r.price_minor), 0) into v_also from public.refunds r
          where r.payment_id = v_payment and r.status <> 'voided';
          perform private.ledger_post('dispute_lost', 'dispute_lost:' || (o ->> 'id'), v_row.currency,$new$);
  fixed := replace(fixed, $old$          update public.payments set released_at = now() where id = v_payment;
        end if;$old$,
    $new$          update public.payments set released_at = now() where id = v_payment;
          if v_row.order_id is not null then
            update public.orders set step = 'cancelled', cancelled_at = now(), cancel_reason = 'Card dispute lost'
            where id = v_row.order_id and step in ('paid', 'started', 'ready', 'reported');
            if found then
              perform private.order_unreserve(v_row.order_id);
              begin
                perform public.notify(v_row.user_id, 'Your order was cancelled', 'Your bank returned your payment.',
                  '!', '/shop/orders/' || v_row.order_id);
                perform public.notify(v_row.organizer_id, 'Order cancelled', 'The buyer''s bank returned the payment.',
                  '!', '/shop/owner/orders/' || v_row.order_id);
              exception when others then
                null;  -- An account has gone. The order stands.
              end;
            end if;
          end if;
        end if;$new$);
  -- A refund that waited on a dispute goes out for exactly what was recorded.
  fixed := replace(fixed, $old$              perform private.refund_issue(v_payment, v_owed ->> 'reason',$old$,
    $new$              perform set_config('og.order_refund_shop', coalesce(v_owed ->> 'shop', ''), true);
              perform set_config('og.order_refund_lines', coalesce(v_owed ->> 'lines', ''), true);
              perform private.refund_issue(v_payment, v_owed ->> 'reason',$new$);
  fixed := replace(fixed, E'\ndeclare\n', E'\ndeclare\n  v_also bigint;\n');
  if position('v_also bigint' in fixed) = 0 or position('og.order_refund_lines' in fixed) = 0
     or position('Card dispute lost' in fixed) = 0 or position('dispute_partial' in fixed) = 0
     or position('x.step <> ' in fixed) = 0 or position('v_row.price_minor - v_also' in fixed) = 0
     or position('Orders lock in the same order' in fixed) = 0 or position('dispute_owed' in fixed) = 0 then
    raise exception 'money_svc_event did not change';
  end if;
  execute fixed;
end;
$$;

-- Shop refunds go through Orders, by item, so stock, points and the split stay right.
do $$
declare
  d text := pg_get_functiondef('public.staff_refund_issue(uuid, text)'::regprocedure);
  fixed text := replace(d, $old$  perform 1 from public.activities where id = pay.activity_id for update;$old$,
    $new$  if pay.purpose = 'shop' then raise exception 'Refund Shop orders by item, in Orders.'; end if;
  perform 1 from public.activities where id = pay.activity_id for update;$new$);
begin
  if fixed = d then raise exception 'staff_refund_issue did not change'; end if;
  execute fixed;
end;
$$;

create or replace function public.payment_abandon(p_payment uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: changes the spot under the same lock as joining.
declare
  pay public.payments;
begin
  select * into pay from public.payments
  where id = p_payment and user_id = auth.uid() and purpose <> 'organizer_fee';
  if pay.id is null then raise exception 'That payment isn''t yours.'; end if;
  if pay.activity_id is not null then
    perform 1 from public.activities where id = pay.activity_id for update;
  elsif pay.order_id is not null then
    perform pg_advisory_xact_lock(hashtext('points:' || pay.user_id));
    perform 1 from public.orders where id = pay.order_id for update;
  end if;
  select * into pay from public.payments where id = p_payment for update;
  if pay.status <> 'pending' then return; end if;
  update public.payments
  set status = case when method is null then 'cancelled' else 'cancel_requested' end
  where id = pay.id;
  if pay.order_id is not null then
    update public.orders set step = 'cancelled', hold_until = null, cancelled_at = now(),
      cancel_reason = 'Buyer stopped paying' where id = pay.order_id and step = 'pending';
    perform private.order_unreserve(pay.order_id);
  elsif pay.activity_id is not null then
    update public.activity_participants set status = 'cancelled', hold_until = null
    where activity_id = pay.activity_id and user_id = pay.user_id and status = 'reserved';
    perform private.promote_waitlist(pay.activity_id);
  end if;
end;
$$;

-- Handover ----------------------------------------------------------------------

create function private.order_lock(p_order uuid, p_user uuid) returns public.orders
language plpgsql security definer set search_path = '' as $$
-- Definer: orders have no client policies. Buyer's points lock first, always.
declare
  o public.orders;
begin
  select * into o from public.orders where id = p_order;
  if o.id is null then raise exception 'This order isn''t yours.'; end if;
  perform pg_advisory_xact_lock(hashtext('points:' || o.buyer_id));
  select * into o from public.orders where id = p_order for update;
  return o;
end;
$$;

create function private.owner_of(p_mall uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select owner_id from public.malls where id = p_mall;
$$;

create function public.shop_mark_started(p_order uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: orders have no client policies.
declare
  o public.orders := private.order_lock(p_order, auth.uid());
begin
  if private.owner_of(o.mall_id) is distinct from auth.uid() then raise exception 'This order isn''t yours.'; end if;
  if not o.service or o.step <> 'paid' then raise exception 'This can''t be started.'; end if;
  update public.orders set step = 'started' where id = o.id;
end;
$$;

create function public.shop_mark_ready(p_order uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: orders have no client policies.
declare
  o public.orders := private.order_lock(p_order, auth.uid());
begin
  if private.owner_of(o.mall_id) is distinct from auth.uid() then raise exception 'This order isn''t yours.'; end if;
  if o.step not in ('paid', 'started') then raise exception 'This can''t be marked ready.'; end if;
  -- Ready starts the clock on paying the shop, so a late one goes to staff (Q90).
  if now() >= o.release_at then raise exception 'This order is past its date. OlympusGO will contact you.'; end if;
  update public.orders set step = 'ready', ready_at = now() where id = o.id;
  begin
    perform public.notify(o.buyer_id, 'Ready to collect', 'Your order is waiting at the shop.', '✓',
      '/shop/orders/' || o.id, '#E3F7C8', '#2E5A00');
  exception when others then
    null;  -- An account has gone. The order stands.
  end;
end;
$$;

-- "Yes, I got it all." This is what the shop waits to see before handing over.
create function public.shop_collected(p_order uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: orders have no client policies.
declare
  o public.orders := private.order_lock(p_order, auth.uid());
begin
  if o.buyer_id is distinct from auth.uid() then raise exception 'This order isn''t yours.'; end if;
  -- A double tap, or a retry after a lost answer.
  if o.step = 'collected' then return; end if;
  if o.step not in ('paid', 'started', 'ready') then raise exception 'This order is closed.'; end if;
  update public.orders set step = 'collected', collected_at = now() where id = o.id;
  perform private.release_order(o.id);
  begin
    perform public.notify(private.owner_of(o.mall_id), 'Collected', 'The buyer confirmed they have it all.', '✓',
      '/shop/owner/orders/' || o.id, '#E3F7C8', '#2E5A00');
  exception when others then
    null;
  end;
end;
$$;

create function public.shop_report_problem(p_order uuid, p_note text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: orders have no client policies.
declare
  o public.orders := private.order_lock(p_order, auth.uid());
begin
  if o.buyer_id is distinct from auth.uid() then raise exception 'This order isn''t yours.'; end if;
  if o.step not in ('paid', 'started', 'ready') then raise exception 'This order is closed.'; end if;
  -- Only a ready order's clock runs out. One the shop never readied stays open.
  if o.step = 'ready' and now() >= private.order_due(o) then raise exception 'It''s too late to report this here.'; end if;
  update public.orders set step = 'reported', reported_at = now(), report_note = left(trim(coalesce(p_note, '')), 500)
  where id = o.id;
  perform private.money_alert('order_reported', 'order-reported:' || o.id, jsonb_build_object('order', o.id));
end;
$$;

-- The buyer cancels before collecting, and a started service can't be (checklist 15).
create function public.shop_order_cancel(p_order uuid, p_reason text) returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds, stock and points.
declare
  o public.orders := private.order_lock(p_order, auth.uid());
  pay public.payments;
  v_refund bigint;
begin
  if o.buyer_id is distinct from auth.uid() then raise exception 'This order isn''t yours.'; end if;
  if o.step = 'pending' then
    select * into pay from public.payments where order_id = o.id;
    perform public.payment_abandon(pay.id);
    return 0;
  end if;
  if o.step not in ('paid', 'ready') then raise exception 'This order can''t be cancelled now.'; end if;
  -- The bank has taken back part of this, so what's owed is for a person to work out.
  if exists (select 1 from public.payment_disputes d join public.payments p on p.id = d.payment_id
      where p.order_id = o.id and d.status = 'lost') then
    raise exception 'Your bank has this payment. Contact us about this order.';
  end if;
  if o.step = 'ready' and o.service then raise exception 'The work is done, so this can''t be cancelled.'; end if;
  if o.step = 'ready' and now() >= private.order_due(o) then raise exception 'It''s too late to cancel this.'; end if;
  select * into pay from public.payments where order_id = o.id for update;
  update public.orders set step = 'cancelled', cancelled_at = now(),
    cancel_reason = left(coalesce(p_reason, ''), 120) where id = o.id;
  perform private.order_unreserve(o.id);
  v_refund := private.refund_issue(pay.id, 'player_in_time', 'order:' || o.id);
  begin
    perform public.notify(private.owner_of(o.mall_id), 'Order cancelled', 'The buyer cancelled before collecting.', '!',
      '/shop/owner/orders/' || o.id);
  exception when others then
    null;
  end;
  return v_refund;
end;
$$;

create function public.shop_owner_cancel(p_order uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds, stock and points.
declare
  o public.orders := private.order_lock(p_order, auth.uid());
  pay public.payments;
begin
  if private.owner_of(o.mall_id) is distinct from auth.uid() then raise exception 'This order isn''t yours.'; end if;
  if o.step not in ('paid', 'started', 'ready') then raise exception 'This order can''t be cancelled now.'; end if;
  select * into pay from public.payments where order_id = o.id for update;
  update public.orders set step = 'cancelled', cancelled_at = now(),
    cancel_reason = left(coalesce(p_reason, 'The shop cancelled'), 120) where id = o.id;
  perform private.order_unreserve(o.id);
  perform private.refund_issue(pay.id, 'organizer_cancelled', 'order:' || o.id);
  begin
    perform public.notify(o.buyer_id, 'The shop cancelled your order', 'Everything you paid is coming back.', '!',
      '/shop/orders/' || o.id);
  exception when others then
    null;  -- An account has gone. The refund stands.
  end;
end;
$$;

-- Whether or not it's open, so an owner can always reach their orders.
create function public.shop_my_mall() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: only the caller's own shop.
  select public.shop_mall_json(m.id) from public.malls m where m.owner_id = (select auth.uid());
$$;

create function public.shop_owner_orders() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: only the caller's own shop.
  select coalesce(jsonb_agg(public.shop_order_json(o.id) order by o.placed_at desc), '[]')
  from public.orders o join public.malls m on m.id = o.mall_id
  where m.owner_id = (select auth.uid()) and o.paid_at is not null;
$$;

-- Sweeps ---------------------------------------------------------------------

create function private.orders_sweep() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: cron.
declare
  r record;
  o public.orders;
begin
  for r in select id from public.orders where step = 'pending' and hold_until <= now() order by id loop
    begin
      o := private.order_lock(r.id, null);
      if o.step = 'pending' and o.hold_until <= now() then
        update public.orders set step = 'expired', hold_until = null where id = o.id;
        update public.payments
        set status = case when method is null then 'cancelled' else 'cancel_requested' end,
            cancel_reason = 'expired'
        where order_id = o.id and status = 'pending';
        perform private.order_unreserve(o.id);
      end if;
    exception when others then
      perform private.money_alert('order_sweep_failed', 'order-sweep:' || r.id || ':' || now()::date,
        jsonb_build_object('order', r.id));
    end;
  end loop;

  for r in select x.id, x.step from public.orders x
    where x.step in ('ready', 'paid', 'started') and private.order_due(x) <= now()
    order by x.id
  loop
    begin
      if r.step = 'ready' then
        o := private.order_lock(r.id, null);
        if o.step = 'ready' and private.order_due(o) <= now() and private.release_order(o.id) then
          update public.orders set step = 'released' where id = o.id;
        end if;
      else
        -- The shop never said it was ready, so a person decides (Q90).
        perform private.money_alert('order_stale', 'order-stale:' || r.id, jsonb_build_object('order', r.id));
      end if;
    exception when others then
      perform private.money_alert('order_sweep_failed', 'order-sweep:' || r.id || ':' || now()::date,
        jsonb_build_object('order', r.id));
    end;
  end loop;

  -- Collected while a dispute was open: pay the shop now it's over.
  for r in
    select x.id from public.orders x join public.payments p on p.order_id = x.id
    where x.step = 'collected' and p.released_at is null order by x.id
  loop
    begin
      o := private.order_lock(r.id, null);
      perform private.release_order(o.id);
    exception when others then
      perform private.money_alert('order_sweep_failed', 'order-sweep:' || r.id || ':' || now()::date,
        jsonb_build_object('order', r.id));
    end;
  end loop;
end;
$$;

-- Orders aren't activities: their holds run here, and their money stays put.
do $$
declare
  d text := pg_get_functiondef('private.holds_sweep()'::regprocedure);
  fixed text := d;
begin
  fixed := replace(fixed, $old$where status = 'pending' and activity_id is null and hold_until <= now() and method is null;$old$,
    $new$where status = 'pending' and purpose = 'debt' and hold_until <= now() and method is null;$new$);
  fixed := replace(fixed, $old$where status = 'pending' and activity_id is null and hold_until <= now();$old$,
    $new$where status = 'pending' and purpose = 'debt' and hold_until <= now();$new$);
  fixed := replace(fixed, E'\nend;\n$function$', E'\n  perform private.orders_sweep();\nend;\n$function$');
  if position('orders_sweep' in fixed) = 0 or position('purpose = ''debt''' in fixed) = 0 then
    raise exception 'holds_sweep did not change';
  end if;
  execute fixed;
end;
$$;

do $$
declare
  d text := pg_get_functiondef('private.money_sweep()'::regprocedure);
  fixed text := d;
begin
  fixed := replace(fixed, $old$select distinct p.activity_id from public.payments p
    where p.status = 'succeeded' and p.released_at is null and p.price_minor > 0$old$,
    $new$select distinct p.held_owner as activity_id from public.payments p
    where p.status = 'succeeded' and p.released_at is null and p.price_minor > 0
      and p.held_owner is not null and private.ledger_balance('held', p.held_owner, p.currency) <> 0$new$);
  if position('held_owner' in fixed) = 0 then raise exception 'money_sweep did not change'; end if;
  execute fixed;
end;
$$;

-- Earnings show the shop's share, not the commission.
create function private.payment_earned(p public.payments) returns bigint
language sql stable security definer set search_path = '' as $$
  select case when p.purpose = 'shop'
    then (select coalesce(sum(l.unit_shop * (l.qty - l.refunded_qty)), 0)::bigint
          from public.order_lines l join public.orders o on o.id = l.order_id
          where l.order_id = p.order_id and o.step not in ('cancelled', 'expired', 'refunded'))
    else p.price_minor end;
$$;

create or replace function public.money_my_earnings() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: no client role touches ledger tables.
declare
  me uuid := auth.uid();
  v_currency text := 'SGD';
begin
  return jsonb_build_object(
    'currency', v_currency,
    'available_minor', greatest(private.organizer_net(me, v_currency), 0),
    'owed_minor', greatest(-private.organizer_net(me, v_currency), 0),
    'fee_debt_minor', greatest(private.ledger_balance('organizer_fee_debt', me, v_currency), 0),
    'held_minor', coalesce((select sum(case when p.purpose = 'shop' then private.payment_earned(p)
        else p.price_minor - coalesce((select sum(r.price_minor)
          from public.refunds r where r.payment_id = p.id and r.status <> 'voided'), 0) end)
      from public.payments p
      where p.organizer_id = me and p.status = 'succeeded' and p.released_at is null), 0),
    'month_minor', coalesce((select sum(private.payment_earned(p)) from public.payments p
      where p.organizer_id = me and p.status = 'succeeded'
        and p.released_at >= date_trunc('month', now())), 0),
    'year_minor', coalesce((select sum(private.payment_earned(p)) from public.payments p
      where p.organizer_id = me and p.status = 'succeeded'
        and p.released_at >= date_trunc('year', now())), 0),
    'vendor', (select jsonb_build_object('status', v.status, 'schedule', v.schedule)
      from public.vendors v where v.owner_id = me),
    'payouts', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', i.id, 'amount_minor', i.amount_minor, 'status', i.status, 'week_start', p.week_start)
        order by p.week_start desc), '[]')
      from public.payout_items i join public.payouts p on p.id = i.payout_id
      where i.owner_id = me and i.status in ('pending', 'sent', 'failed')),
    'activities', (select coalesce(jsonb_agg(x order by x ->> 'starts_at' desc), '[]') from (
      select jsonb_build_object('activity_id', a.id, 'title', a.title, 'starts_at', a.starts_at,
        'price_minor', sum(p.price_minor),
        'released', bool_and(p.released_at is not null)) as x
      from public.payments p join public.activities a on a.id = p.activity_id
      where p.organizer_id = me and p.status = 'succeeded' and p.price_minor > 0
      group by a.id order by a.starts_at desc limit 50) y));
end;
$$;

create or replace function public.money_my_payments(p_limit integer default 50) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: joins refunds and titles for the caller's own rows.
  select coalesce(jsonb_agg(x order by x ->> 'created_at' desc), '[]')
  from (
    select private.payment_json(p) || jsonb_build_object(
      'created_at', p.created_at, 'captured_at', p.captured_at,
      'title', coalesce((select a.title from public.activities a where a.id = p.activity_id),
        (select m.name from public.orders o join public.malls m on m.id = o.mall_id where o.id = p.order_id)),
      'activity_id', p.activity_id, 'order_id', p.order_id,
      'refunded_minor', coalesce((select sum(r.amount_minor) from public.refunds r
        where r.payment_id = p.id and r.status <> 'voided'), 0)) as x
    from public.payments p
    where p.user_id = auth.uid() and p.status in ('succeeded', 'debt')
    order by p.created_at desc limit least(coalesce(p_limit, 50), 200)
  ) y;
$$;

insert into private.rate_rules (path, max_hits, window_seconds) values ('/rpc/shop_reserve', 20, 3600);

revoke execute on function public.shop_quote(uuid, jsonb, bigint),
  public.shop_reserve(uuid, text, bigint, bigint, jsonb, timestamptz),
  public.shop_mark_started(uuid), public.shop_mark_ready(uuid), public.shop_collected(uuid),
  public.shop_report_problem(uuid, text), public.shop_order_cancel(uuid, text),
  public.shop_owner_cancel(uuid, text), public.shop_owner_orders(), public.shop_my_mall()
  from public, anon;
grant execute on function public.shop_quote(uuid, jsonb, bigint),
  public.shop_reserve(uuid, text, bigint, bigint, jsonb, timestamptz),
  public.shop_mark_started(uuid), public.shop_mark_ready(uuid), public.shop_collected(uuid),
  public.shop_report_problem(uuid, text), public.shop_order_cancel(uuid, text),
  public.shop_owner_cancel(uuid, text), public.shop_owner_orders(), public.shop_my_mall()
  to authenticated;

revoke execute on function private.order_unreserve(uuid), private.release_order(uuid),
  private.shop_price(uuid, jsonb, bigint), private.shop_lines_for(uuid, uuid, jsonb),
  private.order_captured(public.payments, public.payments), private.order_lock(uuid, uuid),
  private.orders_sweep(), private.payment_earned(public.payments),
  private.order_refund_shop_part(uuid), private.owner_of(uuid)
  from public, anon, authenticated;

-- Staff ---------------------------------------------------------------------------

create function public.staff_shop_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff see every shop, open or not. Content runs them, payments set
-- the commission and the owner.
begin
  if not (private.is_staff('content') or private.is_staff('payments')) then
    raise exception 'Not found.' using errcode = 'P0001';
  end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'name', m.name, 'active', m.active,
      'collect_address', m.collect_address, 'blurb', m.blurb, 'initials', m.initials,
      'commission_on_top', m.commission_on_top, 'owner_id', m.owner_id,
      'owner', (select username::text from public.profiles p where p.id = m.owner_id),
      'products', (select count(*) from public.products x where x.mall_id = m.id))
      order by m.name), '[]') from public.malls m);
end;
$$;

create function public.staff_shop_save(p jsonb, p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: malls have no client write path.
declare
  v_id uuid := nullif(p ->> 'id', '')::uuid;
begin
  perform private.staff_require('content');
  if v_id is null then
    insert into public.malls (name, initials, blurb, about, collect_address, active)
    values (p ->> 'name', upper(left(coalesce(nullif(p ->> 'initials', ''), p ->> 'name'), 3)),
      coalesce(p ->> 'blurb', ''), coalesce(p ->> 'about', ''), coalesce(p ->> 'collect_address', ''),
      coalesce((p ->> 'active')::boolean, false))
    returning id into v_id;
  else
    update public.malls set name = p ->> 'name', blurb = coalesce(p ->> 'blurb', blurb),
      about = coalesce(p ->> 'about', about), collect_address = coalesce(p ->> 'collect_address', collect_address),
      active = coalesce((p ->> 'active')::boolean, active)
    where id = v_id;
    if not found then raise exception 'Not found.' using errcode = 'P0001'; end if;
  end if;
  if (select active and (owner_id is null or trim(collect_address) = '') from public.malls where id = v_id) then
    raise exception 'A shop needs an owner and a collection address before it opens.';
  end if;
  perform private.staff_audit('shop_saved', 'mall', v_id::text, p_reason, p);
  return v_id;
end;
$$;

-- New orders use the switch. Lines already sold keep their amounts.
create function public.staff_shop_commission_set(p_mall uuid, p_on_top boolean, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: money settings.
begin
  perform private.staff_require('payments');
  update public.malls set commission_on_top = p_on_top where id = p_mall;
  if not found then raise exception 'Not found.' using errcode = 'P0001'; end if;
  perform private.staff_audit('shop_commission', 'mall', p_mall::text, p_reason,
    jsonb_build_object('on_top', p_on_top));
end;
$$;

-- Payments stamp their organizer, so an owner can't change under open orders.
create function public.staff_shop_link_owner(p_mall uuid, p_username text, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: decides who gets paid.
declare
  v_owner uuid;
begin
  perform private.staff_require('payments');
  select id into v_owner from public.profiles where username::text = lower(trim(p_username));
  if v_owner is null then raise exception 'No player has that username.'; end if;
  if exists (select 1 from public.malls m where m.owner_id = v_owner and m.id <> p_mall) then
    raise exception 'That player already runs a shop.';
  end if;
  if private.is_minor(v_owner) or private.is_restricted(v_owner) then
    raise exception 'A shop owner has to be an adult with a working account.';
  end if;
  if exists (select 1 from public.orders o join public.payments p on p.order_id = o.id
      where o.mall_id = p_mall and p.released_at is null
        and o.step in ('pending', 'paid', 'started', 'ready', 'reported')) then
    raise exception 'This shop has open orders, so its owner can''t change yet.';
  end if;
  update public.malls set owner_id = v_owner where id = p_mall;
  if not found then raise exception 'Not found.' using errcode = 'P0001'; end if;
  perform private.staff_audit('shop_owner', 'mall', p_mall::text, p_reason,
    jsonb_build_object('owner', v_owner));
end;
$$;

create function public.staff_product_list(p_mall uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: includes unpublished products.
begin
  perform private.staff_require('content');
  return (select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'name', p.name, 'description', p.description,
      'price_cents', p.price_cents, 'service', p.service, 'stock', p.stock, 'published', p.published,
      'hidden', p.hidden_at is not null, 'art', p.art) order by p.name), '[]')
    from public.products p where p.mall_id = p_mall);
end;
$$;

create function public.staff_product_save(p jsonb, p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: products have no client write path. Stock moves only by staff_product_stock.
declare
  v_id uuid := nullif(p ->> 'id', '')::uuid;
begin
  perform private.staff_require('content');
  if v_id is null then
    insert into public.products (mall_id, name, description, price_cents, service, art, published, options)
    values ((p ->> 'mall_id')::uuid, p ->> 'name', coalesce(p ->> 'description', ''),
      (p ->> 'price_cents')::int, coalesce((p ->> 'service')::boolean, false), coalesce(p ->> 'art', 'bag'),
      coalesce((p ->> 'published')::boolean, false), coalesce(p -> 'options', '[]'))
    returning id into v_id;
  else
    update public.products set name = p ->> 'name', description = coalesce(p ->> 'description', description),
      price_cents = (p ->> 'price_cents')::int, published = coalesce((p ->> 'published')::boolean, published),
      options = coalesce(p -> 'options', options)
    where id = v_id;
    if not found then raise exception 'Not found.' using errcode = 'P0001'; end if;
  end if;
  perform private.staff_audit('product_saved', 'product', v_id::text, p_reason, p);
  return v_id;
end;
$$;

-- By amount, so an edit can't wipe stock held for someone paying.
create function public.staff_product_stock(p_product uuid, p_change integer, p_reason text) returns integer
language plpgsql security definer set search_path = '' as $$
-- Definer: products have no client write path.
declare
  v_stock int;
begin
  perform private.staff_require('content');
  update public.products set stock = stock + p_change where id = p_product and stock + p_change >= 0
  returning stock into v_stock;
  if v_stock is null then raise exception 'That would take stock below zero.'; end if;
  perform private.staff_audit('product_stock', 'product', p_product::text, p_reason,
    jsonb_build_object('change', p_change));
  return v_stock;
end;
$$;

create function public.staff_order_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff read every order. Opaque ids and the shop's name only.
begin
  perform private.staff_require('payments');
  return (select coalesce(jsonb_agg(x), '[]') from (
    select jsonb_build_object('id', o.id, 'step', o.step, 'mall', m.name, 'placed_at', o.placed_at,
      'release_at', private.order_due(o), 'report_note', o.report_note,
      'amount_minor', (select p.amount_minor from public.payments p where p.order_id = o.id)) as x
    from public.orders o join public.malls m on m.id = o.mall_id
    where not o.legacy
    order by (o.step = 'reported') desc, o.placed_at desc limit 200) y);
end;
$$;

create function public.staff_order_get(p_order uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff read every order.
begin
  perform private.staff_require('payments');
  return public.shop_order_json(p_order) || jsonb_build_object('report_note',
    (select report_note from public.orders where id = p_order));
end;
$$;

-- Decides a reported order, or refunds after release (Q93). `lines` is
-- [{line, qty}], and an empty list releases everything to the shop.
create table private.order_decisions (
  key text primary key,
  order_id uuid not null,
  lines jsonb not null,
  refund_minor bigint,
  created_at timestamptz not null default now()
);
revoke all on private.order_decisions from public, anon, authenticated;

create function public.staff_order_decide(p_order uuid, p_lines jsonb, p_restock boolean, p_reason text,
  p_key text)
returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds, stock, points and the ledger.
declare
  o public.orders;
  pay public.payments;
  l record;
  v_price bigint := 0;
  v_shop bigint := 0;
  v_points bigint := 0;
  v_refund bigint := 0;
  v_left bigint;
  v_due boolean;
  v_done jsonb := '[]';
begin
  perform private.staff_require('payments');
  if p_key is null or length(p_key) < 8 then raise exception 'Try that again.'; end if;
  o := private.order_lock(p_order, null);
  -- Quantities are relative, so a repeat must not refund another unit.
  insert into private.order_decisions (key, order_id, lines)
  values (p_key, p_order, coalesce(p_lines, '[]')) on conflict do nothing;
  if not found then
    if not exists (select 1 from private.order_decisions d where d.key = p_key and d.order_id = p_order
        and d.lines = coalesce(p_lines, '[]')) then
      raise exception 'That decision has already been made. Open the order again.';
    end if;
    return (select d.refund_minor from private.order_decisions d where d.key = p_key);
  end if;
  if o.step not in ('reported', 'paid', 'started', 'ready', 'collected', 'released') then
    raise exception 'This order is closed.';
  end if;
  if exists (select 1 from public.payment_disputes d join public.payments p on p.id = d.payment_id
      where p.order_id = o.id and d.status = 'lost' and d.amount_minor >= p.amount_minor) then
    raise exception 'The bank already returned this payment.';
  end if;
  v_due := o.step in ('reported', 'collected') or now() >= private.order_due(o);
  select * into pay from public.payments where order_id = o.id for update;

  for l in
    select ol.*, least(x.qty, ol.qty - ol.refunded_qty) as take
    from (select y.line, sum(coalesce(y.qty, 0))::int as qty
          from jsonb_to_recordset(coalesce(p_lines, '[]')) as y(line uuid, qty int) group by y.line) x
    join public.order_lines ol on ol.id = x.line and ol.order_id = o.id
    order by ol.product_id
  loop
    continue when l.take <= 0;
    v_done := v_done || jsonb_build_object('line', l.id, 'qty', l.take,
      'restock', coalesce(p_restock, false) and not o.service);
    v_price := v_price + l.unit_paid * l.take;
    v_shop := v_shop + l.unit_shop * l.take;
    v_points := v_points + l.unit_points * l.take;
    update public.order_lines set refunded_qty = refunded_qty + l.take where id = l.id;
    if coalesce(p_restock, false) and not o.service then
      update public.products set stock = stock + l.take where id = l.product_id;
    end if;
  end loop;

  if jsonb_array_length(coalesce(p_lines, '[]')) > 0 and v_price = 0 then
    raise exception 'Those items have already been refunded.';
  end if;
  if v_price = 0 and not v_due then
    raise exception 'This order isn''t due yet, so it can''t be released.';
  end if;

  if v_price > 0 then
    perform set_config('og.order_refund_shop', v_shop::text, true);
    perform set_config('og.order_refund_lines', v_done::text, true);
    v_refund := private.refund_issue(pay.id, 'staff', 'staff-order:' || p_key, v_price, auth.uid());
    perform set_config('og.order_refund_shop', '', true);
    perform set_config('og.order_refund_lines', '', true);
    if v_points > 0 then
      perform private.points_return('order', o.id::text, 'staff:' || p_key, v_points);
    end if;
  end if;

  select coalesce(sum(qty - refunded_qty), 0) into v_left from public.order_lines where order_id = o.id;
  if v_left = 0 then
    update public.orders set step = 'refunded' where id = o.id;
  elsif v_due and pay.released_at is null then
    -- Part of an order still waiting to be collected stays waiting.
    if private.release_order(o.id) then
      if o.step <> 'collected' then update public.orders set step = 'released' where id = o.id; end if;
    elsif o.step <> 'collected' then
      raise exception 'A dispute is open or the money doesn''t add up, so this can''t be released yet. See the alerts.';
    end if;
  end if;
  update private.order_decisions set refund_minor = v_refund where key = p_key;
  perform private.staff_audit('order_decided', 'order', o.id::text, p_reason,
    jsonb_build_object('lines', p_lines, 'restock', p_restock, 'refund_minor', v_refund));
  return v_refund;
end;
$$;

create function public.staff_points_block(p_user uuid, p_block boolean, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the points ledger. Blocking forfeits what's left (R-PTS-6).
declare
  l record;
begin
  perform private.staff_require('payments');
  perform pg_advisory_xact_lock(hashtext('points:' || p_user));
  if not p_block then
    delete from public.points_blocks where user_id = p_user;
  else
    insert into public.points_blocks (user_id, blocked_by, reason) values (p_user, auth.uid(), p_reason)
    on conflict (user_id) do nothing;
    for l in select * from private.points_lots(p_user) x where x.left_minor > 0 loop
      insert into public.points_entries (user_id, kind, amount_minor, lot_id, expires_at, source_kind,
        source_id, idempotency_key)
      values (p_user, 'forfeit', -l.left_minor, l.lot_id, l.expires_at, 'block', p_user::text,
        'forfeit:' || l.lot_id || ':' || gen_random_uuid());
    end loop;
  end if;
  perform private.staff_audit(case when p_block then 'points_blocked' else 'points_unblocked' end,
    'user', p_user::text, p_reason);
end;
$$;

revoke execute on function public.staff_shop_list(), public.staff_shop_save(jsonb, text),
  public.staff_shop_commission_set(uuid, boolean, text), public.staff_shop_link_owner(uuid, text, text),
  public.staff_product_list(uuid), public.staff_product_save(jsonb, text),
  public.staff_product_stock(uuid, integer, text), public.staff_order_list(), public.staff_order_get(uuid),
  public.staff_order_decide(uuid, jsonb, boolean, text, text), public.staff_points_block(uuid, boolean, text)
  from public, anon;
grant execute on function public.staff_shop_list(), public.staff_shop_save(jsonb, text),
  public.staff_shop_commission_set(uuid, boolean, text), public.staff_shop_link_owner(uuid, text, text),
  public.staff_product_list(uuid), public.staff_product_save(jsonb, text),
  public.staff_product_stock(uuid, integer, text), public.staff_order_list(), public.staff_order_get(uuid),
  public.staff_order_decide(uuid, jsonb, boolean, text, text), public.staff_points_block(uuid, boolean, text)
  to authenticated;

-- Held money includes orders.
create or replace function public.staff_held_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: held money by activity or order, with what's keeping it.
begin
  perform private.staff_require('payments');
  return (select coalesce(jsonb_agg(x order by x ->> 'oldest'), '[]') from (
    select jsonb_build_object('activity_id', a.id, 'title', a.title, 'ends_at', a.ends_at,
      'held_minor', -private.ledger_balance('held', a.id, a.currency),
      'oldest', min(p.captured_at),
      'hold_id', (select h.id from public.activity_money_holds h
        where h.activity_id = a.id and h.closed_at is null)) as x
    from public.payments p join public.activities a on a.id = p.activity_id
    where p.status = 'succeeded' and p.released_at is null and p.price_minor > 0
    group by a.id
    union all
    select jsonb_build_object('order_id', o.id, 'title', m.name, 'ends_at', private.order_due(o),
      'held_minor', -private.ledger_balance('held', o.id, p.currency),
      'oldest', p.captured_at, 'hold_id', null)
    from public.payments p join public.orders o on o.id = p.order_id join public.malls m on m.id = o.mall_id
    where p.status = 'succeeded' and p.released_at is null
      and private.ledger_balance('held', o.id, p.currency) <> 0) y);
end;
$$;
