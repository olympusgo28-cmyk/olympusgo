#!/bin/bash
# Real parallel connections, which a single pgTAP transaction can't give.
#   Voucher: two carts spend one voucher at once. One gets it.
#   Cancel: on one order the buyer cancels twice while the sweep runs. It comes
#   back once.
#   Sweep: three organizer sweeps run at once on a game that counts. It gets
#   one number and one reward.
# Local stack only.
set -euo pipefail

PSQL=(docker exec -i supabase_db_olympusGO psql -U postgres -d postgres -Atq -v ON_ERROR_STOP=1)
ROUNDS=${1:-25}
OWNER=c6000000-0000-0000-0000-000000000081
BUYER=c6000000-0000-0000-0000-000000000082
ORG=c6000000-0000-0000-0000-000000000083
LOG=$(mktemp)
cleanup() {
  rm -f "$LOG"
  "${PSQL[@]}" >/dev/null <<SQL
update public.feature_flags set enabled = false where key in ('payments.enabled', 'shop.checkout', 'game.organizer_rewards');
update public.voucher_types set organizer_default = false where name = 'Race voucher';
SQL
}
trap cleanup EXIT

as_buyer() {
  "${PSQL[@]}" -c "begin; select set_config('request.jwt.claims', '{\"sub\":\"$BUYER\",\"role\":\"authenticated\"}', true); set local role authenticated; $1; commit;" >/dev/null 2>>"$LOG" || true
}

"${PSQL[@]}" <<SQL
update public.feature_flags set enabled = true where key in ('payments.enabled', 'shop.checkout', 'game.organizer_rewards');
insert into auth.users (id, instance_id, aud, role, email)
select x, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', x || '@test.local'
from unnest(array['$OWNER', '$BUYER', '$ORG']::uuid[] || array(
  select ('c6000000-0000-0000-0000-00000000009' || n)::uuid from generate_series(0, 5) n)) x
on conflict do nothing;
update public.account_private set birthday = '1990-01-01', country_code = 'SG',
  mobile = '+659' || right(replace(id::text, '-', ''), 7), mobile_verified_at = now()
where id in ('$OWNER', '$BUYER', '$ORG') or id::text like 'c6000000-0000-0000-0000-00000000009%';
insert into public.malls (owner_id, name, initials, collect_address, active)
values ('$OWNER', 'Game race shop', 'GR', '1 Test Road', true) on conflict do nothing;
SQL
MALL=$("${PSQL[@]}" -c "select id from public.malls where owner_id = '$OWNER'")
TYPE=$("${PSQL[@]}" <<SQL | head -1
insert into public.voucher_types (name, kind, mall_id, amount_minor, organizer_default)
values ('Race voucher', 'A', '$MALL', 800, true) returning id;
SQL
)

failed=0
for ((i = 1; i <= ROUNDS; i++)); do
  ITEM=$("${PSQL[@]}" -c "insert into public.products (mall_id, name, price_cents, stock, published) values ('$MALL', 'Race item', 10000, 10, true) returning id" | head -1)
  V=$("${PSQL[@]}" -c "insert into public.vouchers (type_id, owner_id, code, expires_at, source) values ('$TYPE', '$BUYER', 'R$i-' || gen_random_uuid(), now() + interval '9 days', 'race:' || gen_random_uuid()) returning id" | head -1)
  ONLY="jsonb_build_object('product', '$ITEM', 'qty', 1)"

  as_buyer "select public.shop_reserve('$MALL', 'race-a-$i-' || gen_random_uuid(), 9200, 0, $ONLY, null, '$V')" &
  a=$!
  as_buyer "select public.shop_reserve('$MALL', 'race-b-$i-' || gen_random_uuid(), 9200, 0, $ONLY, null, '$V')" &
  b=$!
  wait $a $b
  used=$("${PSQL[@]}" -c "select count(*) from public.voucher_redemptions where voucher_id = '$V' and kind = 'used'")
  if [[ "$used" != "1" ]]; then
    echo "round $i: a voucher was spent $used times"
    failed=1
  fi

  # Pay for it, then cancel twice while the sweep runs.
  ORDER=$("${PSQL[@]}" -c "select order_id from public.voucher_redemptions where voucher_id = '$V' limit 1")
  PAY=$("${PSQL[@]}" -c "select id from public.payments where order_id = '$ORDER'")
  "${PSQL[@]}" >/dev/null <<SQL
select public.money_svc_event(jsonb_build_object('id', 'evt_' || gen_random_uuid(),
  'type', 'payment_intent.succeeded', 'object', jsonb_build_object('id', 'pi_$PAY',
  'amount', 9200, 'currency', 'sgd', 'latest_charge', 'ch_$PAY', 'payment_method_type', 'card',
  'metadata', jsonb_build_object('payment_id', '$PAY'))));
SQL
  as_buyer "select public.shop_order_cancel('$ORDER', 'race')" &
  a=$!
  as_buyer "select public.shop_order_cancel('$ORDER', 'race')" &
  b=$!
  (for _ in 1 2 3; do "${PSQL[@]}" -c "select private.orders_sweep()" >/dev/null; done) &
  c=$!
  wait $a $b $c
  read -r back status <<<"$("${PSQL[@]}" -F ' ' -c "select (select count(*) from public.voucher_redemptions where voucher_id = '$V' and kind = 'returned'), (select status from public.vouchers where id = '$V')")"
  if [[ "$back" != "1" || "$status" != "issued" ]]; then
    echo "round $i: returned $back times, status $status"
    failed=1
  fi

  # Three sweeps at once on one counted game.
  ACT=$("${PSQL[@]}" <<SQL | head -1
set session_replication_role = replica;
insert into public.activities (kind, host_id, title, sports, game_type, format, starts_at, ends_at, venue_id, capacity)
select 'meet', '$ORG', 'Race Meet', array['badminton'], 'doubles', 'open_play', now() - interval '3 hours', now() - interval '1 hour', v.id, 12
from public.venues v order by v.name limit 1 returning id;
SQL
  )
  "${PSQL[@]}" >/dev/null <<SQL
update public.feature_flags set enabled = false where key = 'payments.enabled';
set session_replication_role = replica;
insert into public.activity_participants (activity_id, user_id, status, attendance, check_in_method)
select '$ACT', u.id, 'joined', 'present', 'qr' from auth.users u
where u.id::text like 'c6000000-0000-0000-0000-00000000009%';
set session_replication_role = origin;
insert into public.campaign_game_log (activity_id, host_id, present_count, players, starts_at, ends_at)
values ('$ACT', '$ORG', 6, '[]', now(), now());
SQL
  (for _ in 1 2; do "${PSQL[@]}" -c "select private.organizer_sweep()" >/dev/null; done) &
  a=$!
  "${PSQL[@]}" -c "select private.organizer_sweep()" >/dev/null &
  b=$!
  "${PSQL[@]}" -c "select private.organizer_sweep()" >/dev/null &
  c=$!
  wait $a $b $c
  "${PSQL[@]}" -c "update public.feature_flags set enabled = true where key = 'payments.enabled'" >/dev/null
  rows=$("${PSQL[@]}" -c "select count(*) from public.organizer_games where activity_id = '$ACT'")
  if [[ "$rows" != "1" ]]; then
    echo "round $i: the game was recorded $rows times"
    failed=1
  fi
done

games=$("${PSQL[@]}" -c "select count(*) from public.organizer_games where host_id = '$ORG' and counted")
last=$("${PSQL[@]}" -c "select max(game_no) from public.organizer_games where host_id = '$ORG'")
if [[ "$games" != "$ROUNDS" || "$last" != "$ROUNDS" ]]; then
  echo "$games counted, last number $last, wanted $ROUNDS of each"
  failed=1
fi
grants=$("${PSQL[@]}" -c "select count(*) from public.reward_grants where user_id = '$ORG'")
vouchers=$("${PSQL[@]}" -c "select count(*) from public.vouchers where owner_id = '$ORG'")
if [[ "$vouchers" -gt "$grants" ]]; then
  echo "$vouchers vouchers from $grants grants"
  failed=1
fi

if grep ERROR "$LOG" | grep -viE "been used|can't be cancelled|order is closed"; then
  echo "A racer failed for a reason nobody expected"
  failed=1
fi
swept=$("${PSQL[@]}" -c "select count(*) from public.money_alerts where kind in ('order_sweep_failed', 'organizer_sweep_failed')")
if [[ "$swept" != "0" ]]; then
  echo "A sweep failed $swept times while racing"
  failed=1
fi
if [[ $failed -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "ok: $ROUNDS rounds, each voucher spent once and returned once, each game numbered once, $grants grants, $vouchers vouchers"
