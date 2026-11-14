-- P4a-02: fee and refund quotes. Pure functions: every amount shown or charged
-- comes from here, so the app and the server can't disagree.

insert into public.fee_rules (currency, applies_to, percent_bps, minimum_minor) values
  ('SGD', 'court', 1000, 200),  -- R-FEE-7, assumed
  ('SGD', 'shop', 0, 0);        -- R-FEE-6: no buyer fee

-- Fee for one unit. A free spot where the payer covers the fee pays the minimum.
create function private.fee_per_unit(p_price bigint, p_currency text, p_applies_to text)
returns bigint
language sql stable security definer set search_path = '' as $$
  -- Definer: reads fee_rules for any caller.
  select case when p_price > 0 then private.fee_minor(p_price, p_currency, p_applies_to)
    else (select r.minimum_minor from public.fee_rules r
          where r.currency = p_currency and r.applies_to = p_applies_to and r.active) end;
$$;

-- R-FEE-1 to R-FEE-7. Per unit, so one seat can be refunded alone (Q69).
--   meet, ticket, tournament   price plus fee, each per unit
--   host_spot                  the minimum fee only (R-FEE-5)
--   organizer_fee              the minimum fee, charged to the organizer (R-FEE-3, R-FEE-4)
--   court                      price plus court fee
--   shop                       price, no buyer fee
create function public.money_quote(p_purpose text, p_price_minor bigint, p_qty integer default 1,
  p_currency text default 'SGD')
returns jsonb
language plpgsql stable set search_path = '' as $$
declare
  v_unit_price bigint := coalesce(p_price_minor, 0);
  v_unit_fee bigint;
begin
  if p_qty is null or p_qty < 1 or p_qty > 10 then raise exception 'Choose how many.'; end if;
  if v_unit_price < 0 then raise exception 'A price can''t be negative.'; end if;
  case p_purpose
    when 'meet', 'ticket', 'tournament' then
      v_unit_fee := private.fee_per_unit(v_unit_price, p_currency, 'session');
    when 'host_spot', 'organizer_fee' then
      v_unit_price := 0;
      v_unit_fee := private.fee_per_unit(0, p_currency, 'session');
    when 'court' then
      v_unit_fee := private.fee_per_unit(v_unit_price, p_currency, 'court');
    when 'shop' then
      v_unit_fee := 0;
    else
      raise exception 'Unknown purpose %', p_purpose;
  end case;
  return jsonb_build_object(
    'purpose', p_purpose, 'qty', p_qty, 'currency', p_currency,
    'unit_price_minor', v_unit_price, 'unit_fee_minor', v_unit_fee,
    'price_minor', v_unit_price * p_qty, 'fee_minor', v_unit_fee * p_qty,
    'total_minor', (v_unit_price + v_unit_fee) * p_qty);
end;
$$;

-- What a refund pays back, from the reason and what is left on the payment.
--   R-REF-1, 13 to 18: everything. R-REF-2: price without the fee. The host's
--   own spot is the fee (owner, 31 Oct), with no card fee charged to them.
create function public.money_refund_quote(p_reason text, p_price_minor bigint, p_fee_minor bigint,
  p_method text default 'card')
returns jsonb
language plpgsql immutable set search_path = '' as $$
declare
  v_price bigint := 0;
  v_fee bigint := 0;
  v_organizer boolean := false;
begin
  case p_reason
    when 'organizer_cancelled', 'change_by_organizer', 'removed_from_club', 'event_below_minimum' then
      v_price := p_price_minor;
      v_fee := p_fee_minor;
      -- R-REF-11 names card fees. PayNow's stays with Olympus (Q70 default).
      v_organizer := p_method = 'card';
    when 'account_deleted', 'partner_declined', 'medical', 'late_no_spot', 'blocked', 'staff' then
      v_price := p_price_minor;
      v_fee := p_fee_minor;
    when 'player_in_time' then
      v_price := p_price_minor;
    when 'host_spot', 'player_left' then
      v_fee := p_fee_minor;
    when 'late' then
      null;
    else
      raise exception 'Unknown refund reason %', p_reason;
  end case;
  return jsonb_build_object('reason', p_reason, 'price_minor', v_price, 'fee_minor', v_fee,
    'refund_minor', v_price + v_fee, 'organizer_pays_card_fee', v_organizer);
end;
$$;

-- R-REF-5 to R-REF-7. Court and shop rules arrive with their flows in 4b.
create function private.refund_in_time(p_purpose text, a public.activities) returns boolean
language sql stable set search_path = '' as $$
  select case p_purpose
    when 'ticket' then now() < a.starts_at - interval '24 hours'
    when 'tournament' then now() < coalesce(a.registration_closes_at, a.starts_at)
    else now() < a.starts_at end;
$$;

-- The words shown on the payment sheet and kept with the payment (R-REF-20).
create function private.refund_rule_text(p_purpose text) returns text
language sql immutable set search_path = '' as $$
  select case p_purpose
    when 'meet' then 'Give up your spot before the Meet starts and you get the price back, without the fee. After that, no refund. If the organizer cancels, you get everything back.'
    when 'ticket' then 'Release your tickets up to 24 hours before the start and you get the price back, without the fee. After that, no refund. If the organizer cancels, you get everything back.'
    when 'tournament' then 'Withdraw before registration closes and you get the price back, without the fee. After that, no refund. If the organizer cancels, you get everything back.'
    when 'host_spot' then 'Give up your spot before the Meet starts and you get the S$2.00 fee back.'
    else 'This fee isn''t refundable unless the player leaves in time.' end;
$$;

revoke execute on function public.money_quote(text, bigint, integer, text),
  public.money_refund_quote(text, bigint, bigint, text) from public, anon;
grant execute on function public.money_quote(text, bigint, integer, text),
  public.money_refund_quote(text, bigint, bigint, text) to authenticated, service_role;
revoke execute on function private.fee_per_unit(bigint, text, text),
  private.refund_in_time(text, public.activities) from public, anon;
grant execute on function private.fee_per_unit(bigint, text, text) to authenticated, service_role;
