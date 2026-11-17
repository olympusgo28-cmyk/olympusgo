#!/bin/bash
# Real parallel connections, which a single pgTAP transaction can't give. On one
# order the buyer cancels twice, collects and the sweep runs, all at once. Odd
# rounds have the clock far off, so cancel and collect truly race. Even rounds
# put it a moment away, so the sweep can win. Whichever wins, the money moves
# once, stock comes back only on a cancel, and nothing stays held. Local stack only.
set -euo pipefail

source "$(dirname "$0")/db.sh"
ROUNDS=${1:-25}
OWNER=c9000000-0000-0000-0000-000000000003
BUYER=c9000000-0000-0000-0000-000000000004
LOG=$(mktemp)
trap 'rm -f "$LOG"; "${PSQL[@]}" -c "update public.feature_flags set enabled = false where key in ('"'"'payments.enabled'"'"', '"'"'shop.checkout'"'"')" >/dev/null || true' EXIT

# Refusals are expected. Anything else is a failed run, so it's kept and checked.
as_buyer() {
  "${PSQL[@]}" -c "begin; select set_config('request.jwt.claims', '{\"sub\":\"$BUYER\",\"role\":\"authenticated\"}', true); set local role authenticated; $1; commit;" >/dev/null 2>>"$LOG" || true
}

"${PSQL[@]}" <<SQL
update public.feature_flags set enabled = true where key in ('payments.enabled', 'shop.checkout');
insert into auth.users (id, instance_id, aud, role, email)
values ('$OWNER', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '$OWNER@test.local'),
       ('$BUYER', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '$BUYER@test.local')
on conflict do nothing;
update public.account_private set birthday = '1990-01-01', country_code = 'SG',
  mobile = '+659' || right(replace(id::text, '-', ''), 7), mobile_verified_at = now()
where id in ('$OWNER', '$BUYER');
insert into public.malls (owner_id, name, initials, collect_address, active)
values ('$OWNER', 'Race shop', 'RS', '1 Test Road', true) on conflict do nothing;
SQL
MALL=$("${PSQL[@]}" -c "select id from public.malls where owner_id = '$OWNER'")

failed=0
cancelled=0
collected=0
released=0
for ((i = 1; i <= ROUNDS; i++)); do
  ITEM=$("${PSQL[@]}" -c "insert into public.products (mall_id, name, price_cents, stock, published) values ('$MALL', 'Race item', 10000, 3, true) returning id" | head -1)
  ids=$("${PSQL[@]}" <<SQL
begin;
select set_config('request.jwt.claims', '{"sub":"$BUYER","role":"authenticated"}', true);
set local role authenticated;
select public.shop_reserve('$MALL', 'race-' || gen_random_uuid(), 10000, 0,
  '{"product":"$ITEM","qty":1}'::jsonb);
commit;
SQL
  )
  order=$(echo "$ids" | grep -o '"order_id": "[^"]*"' | cut -d'"' -f4)
  payment=$(echo "$ids" | grep -o '"payment_id": "[^"]*"' | cut -d'"' -f4)
  soon="now() + interval '9 days'"
  ((i % 2 == 0)) && soon="now() + interval '30 milliseconds'"
  "${PSQL[@]}" >/dev/null <<SQL
select public.money_svc_event(jsonb_build_object('id', 'evt_' || gen_random_uuid(),
  'type', 'payment_intent.succeeded', 'object', jsonb_build_object('id', 'pi_$payment',
  'amount', 10000, 'currency', 'sgd', 'latest_charge', 'ch_$payment', 'payment_method_type', 'card',
  'metadata', jsonb_build_object('payment_id', '$payment'))));
-- The guard keeps this time fixed, so only this script may move it.
set session_replication_role = replica;
update public.orders set step = 'ready', ready_at = now() - interval '9 days', release_at = $soon where id = '$order';
set session_replication_role = origin;
SQL

  as_buyer "select public.shop_order_cancel('$order', 'race')" &
  a=$!
  as_buyer "select public.shop_collected('$order')" &
  b=$!
  as_buyer "select public.shop_order_cancel('$order', 'race')" &
  c=$!
  (for _ in 1 2 3 4 5; do "${PSQL[@]}" -c "select private.orders_sweep()" >/dev/null; done) &
  d=$!
  wait $a $b $c $d

  read -r step held refunds refunded stock releases <<<"$("${PSQL[@]}" -F ' ' <<SQL
select o.step, private.ledger_balance('held', o.id, 'SGD'),
  (select count(*) from public.refunds r where r.payment_id = '$payment'),
  (select coalesce(sum(r.amount_minor), 0) from public.refunds r where r.payment_id = '$payment'),
  (select stock from public.products where id = '$ITEM'),
  (select count(*) from public.ledger_transactions t where t.idempotency_key = 'release:$payment')
from public.orders o where o.id = '$order';
SQL
  )"
  case "$step" in
    cancelled)
      cancelled=$((cancelled + 1))
      if [[ "$held" != "0" || "$refunds" != "1" || "$refunded" != "10000" || "$stock" != "3" || "$releases" != "0" ]]; then
        echo "round $i: cancelled, held $held, refunds $refunds of $refunded, stock $stock, releases $releases"
        failed=1
      fi
      ;;
    collected | released)
      [[ "$step" == "collected" ]] && collected=$((collected + 1)) || released=$((released + 1))
      if [[ "$held" != "0" || "$refunds" != "0" || "$stock" != "2" || "$releases" != "1" ]]; then
        echo "round $i: $step, held $held, refunds $refunds of $refunded, stock $stock, releases $releases"
        failed=1
      fi
      ;;
    *)
      echo "round $i: ended as $step"
      failed=1
      ;;
  esac
done

# Refused is fine. Broken isn't.
if grep ERROR "$LOG" | grep -vE "can't be cancelled|too late|order is closed"; then
  echo "A racer failed for a reason nobody expected"
  failed=1
fi
swept=$("${PSQL[@]}" -c "select count(*) from public.money_alerts where kind = 'order_sweep_failed'")
if [[ "$swept" != "0" ]]; then
  echo "The sweep failed $swept times while racing"
  failed=1
fi
if ((cancelled == 0 || collected + released == 0)); then
  echo "Nothing raced: $cancelled cancelled, $collected collected, $released released"
  failed=1
fi
if [[ $failed -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "ok: $ROUNDS rounds ($cancelled cancelled, $collected collected, $released released), the money moved once"
