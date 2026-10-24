-- Fixes from UAT: orders and shops carry who to message, and order lines
-- carry the product's picture type.

create or replace function public.shop_order_json(p_order uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', o.id, 'mall_id', o.mall_id, 'mall_name', m.name, 'step', o.step,
    'delivery', o.delivery, 'delivery_cents', o.delivery_cents,
    'paid_with', o.paid_with, 'address', o.address, 'arrives', o.arrives,
    'courier', o.courier, 'tracking', o.tracking, 'service', o.service,
    'booking', o.booking, 'reviewed', o.reviewed, 'placed_at', o.placed_at,
    'delivered_at', o.delivered_at,
    'buyer_id', o.buyer_id,
    'owner_id', m.owner_id,
    'buyer', (select coalesce(full_name, username::text, 'Player')
              from public.profiles where id = o.buyer_id),
    'return', (select jsonb_build_object('reason', r.reason, 'want', r.want,
                 'status', r.status) from public.order_returns r where r.order_id = o.id),
    'lines', (select coalesce(jsonb_agg(jsonb_build_object(
                 'product_id', l.product_id, 'name', l.name, 'variant', l.variant,
                 'qty', l.qty, 'price_cents', l.price_cents,
                 'art', (select art from public.products where id = l.product_id))
                 order by l.name), '[]')
              from public.order_lines l where l.order_id = o.id))
  from public.orders o join public.malls m on m.id = o.mall_id
  where o.id = p_order;
$$;

create or replace function public.shop_mall_json(p_mall uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', m.id, 'name', m.name, 'initials', m.initials, 'blurb', m.blurb,
    'about', m.about, 'ships_from', m.ships_from, 'color', m.color, 'ink', m.ink,
    'verified', m.verified, 'created_at', m.created_at,
    'owner_id', m.owner_id,
    'mine', m.owner_id = (select auth.uid()))
  from public.malls m where m.id = p_mall;
$$;
