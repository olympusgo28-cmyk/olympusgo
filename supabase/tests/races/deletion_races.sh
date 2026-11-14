#!/bin/bash
# Real parallel connections, which a single pgTAP transaction can't give. Many
# taps on "Delete my account" at once must refund a paid join exactly once and
# leave one request. The negative control runs the same calls without the
# request's lock and key, and must show the double refund they prevent.
set -euo pipefail

source "$(dirname "$0")/db.sh"
ROUNDS=${1:-25}
HOST=d9000000-0000-0000-0000-000000000001
PLAYER=d9000000-0000-0000-0000-000000000002
PARALLEL=8

"${PSQL[@]}" <<SQL
update public.feature_flags set enabled = true where key = 'payments.enabled';
insert into auth.users (id, instance_id, aud, role, email)
values ('$HOST', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '$HOST@test.local'),
       ('$PLAYER', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', '$PLAYER@test.local')
on conflict do nothing;
update public.account_private set birthday = '1990-01-01', country_code = 'SG',
  mobile = '+659' || right(replace(id::text, '-', ''), 7), mobile_verified_at = now()
where id in ('$HOST', '$PLAYER');
SQL

# A fresh paid join for the player on a Meet tomorrow. Prints the payment id.
paid_join() {
  "${PSQL[@]}" <<SQL
with a as (
  insert into public.activities (kind, host_id, title, sports, game_type, format, starts_at, ends_at,
    venue_id, capacity, fee_cents)
  select 'meet', '$HOST', 'Race', '{badminton}', 'doubles', 'open_play', now() + interval '1 day',
    now() + interval '1 day 2 hours', v.id, 4, 600 from public.venues v order by v.name limit 1
  returning id
), ap as (
  insert into public.activity_participants (activity_id, user_id, status)
  select a.id, '$PLAYER', 'joined' from a
), p as (
  insert into public.payments (user_id, activity_id, purpose, price_minor, fee_minor, amount_minor,
    organizer_id, rule_snapshot, idempotency_key, status, method, captured_at)
  select '$PLAYER', a.id, 'meet', 600, 200, 800, '$HOST', '{}', 'race-' || gen_random_uuid(), 'succeeded', 'card', now()
  from a returning id, activity_id
), up as (
  select private.ledger_post('capture', 'capture:' || p.id, 'SGD', jsonb_build_object('payment', p.id),
    jsonb_build_array(private.ledger_line('clearing', null, 800),
      private.ledger_line('held', p.activity_id, -600),
      private.ledger_line('platform_fees', null, -200))) from p
)
select p.id from p, up;
SQL
}

# Runs one statement as the player, in its own connection, PARALLEL times.
as_player_parallel() {
  local sql=$1
  local pids=()
  for ((k = 1; k <= PARALLEL; k++)); do
    "${PSQL[@]}" -c "select set_config('request.jwt.claims', '{\"sub\": \"$PLAYER\", \"role\": \"authenticated\"}', false); set role authenticated; $sql" >/dev/null 2>&1 &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do wait "$pid" || true; done
}

failed=0
for ((i = 1; i <= ROUNDS; i++)); do
  "${PSQL[@]}" -c "delete from public.account_deletions where user_id = '$PLAYER'; update public.profiles set hidden_at = null where id = '$PLAYER'" >/dev/null
  payment=$(paid_join)
  as_player_parallel "select public.account_delete_request('race');"
  refunds=$("${PSQL[@]}" -c "select count(*) from public.refunds where payment_id = '$payment'")
  amount=$("${PSQL[@]}" -c "select coalesce(sum(amount_minor), 0) from public.refunds where payment_id = '$payment'")
  requests=$("${PSQL[@]}" -c "select count(*) from public.account_deletions where user_id = '$PLAYER' and cancelled_at is null")
  if [[ "$refunds" != "1" || "$amount" != "800" || "$requests" != "1" ]]; then
    echo "round $i: $refunds refunds for $amount, $requests requests"
    failed=1
  fi
done

# Negative control: the same refund without the request's key must double up,
# or this script proves nothing.
"${PSQL[@]}" -c "delete from public.account_deletions where user_id = '$PLAYER'; update public.profiles set hidden_at = null where id = '$PLAYER'" >/dev/null
payment=$(paid_join)
pids=()
for ((k = 1; k <= PARALLEL; k++)); do
  "${PSQL[@]}" -c "select private.refund_issue('$payment', 'account_deleted', 'control-' || gen_random_uuid())" >/dev/null 2>&1 &
  pids+=($!)
done
for pid in "${pids[@]}"; do wait "$pid" || true; done
control=$("${PSQL[@]}" -c "select count(*) from public.refunds where payment_id = '$payment'")
"${PSQL[@]}" -c "update public.feature_flags set enabled = false where key = 'payments.enabled'" >/dev/null

if [[ "$control" == "1" ]]; then
  echo "control: the refund helper alone already stops a double refund, so this race is not what proves the key"
fi
if [[ $failed -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "ok: $ROUNDS rounds, one refund and one request each time (control saw $control refunds)"
