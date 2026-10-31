#!/bin/bash
# Real parallel connections, which a single pgTAP transaction can't give. A
# refund and a release race on one payment: whichever wins, the held account
# must end at zero and the price must be paid out exactly once. Local stack only.
set -euo pipefail

PSQL=(docker exec -i supabase_db_olympusGO psql -U postgres -d postgres -Atq -v ON_ERROR_STOP=1)
ROUNDS=${1:-25}
HOST=c9000000-0000-0000-0000-000000000001
PLAYER=c9000000-0000-0000-0000-000000000002

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

failed=0
start=$("${PSQL[@]}" -c "select private.ledger_balance('organizer', '$HOST', 'SGD')")
for ((i = 1; i <= ROUNDS; i++)); do
  ids=$("${PSQL[@]}" <<SQL
with a as (
  insert into public.activities (kind, host_id, title, sports, game_type, format, starts_at, ends_at,
    venue_id, capacity, fee_cents)
  select 'meet', '$HOST', 'Race', '{badminton}', 'doubles', 'open_play', now() + interval '1 day',
    now() + interval '2 days', v.id, 4, 600 from public.venues v order by v.name limit 1
  returning id
), p as (
  insert into public.payments (user_id, activity_id, purpose, price_minor, fee_minor, amount_minor,
    organizer_id, rule_snapshot, idempotency_key, status, method, captured_at)
  select '$PLAYER', a.id, 'meet', 600, 200, 800, '$HOST', '{}', 'race-' || gen_random_uuid(), 'pending', 'card', now()
  from a returning id, activity_id
), up as (
  select private.ledger_post('capture', 'capture:' || p.id, 'SGD', jsonb_build_object('payment', p.id),
    jsonb_build_array(private.ledger_line('clearing', null, 800),
      private.ledger_line('held', p.activity_id, -600),
      private.ledger_line('platform_fees', null, -200))) from p
)
select p.activity_id || ' ' || p.id from p, up;
SQL
  )
  read -r activity payment <<<"$ids"
  "${PSQL[@]}" -c "update public.payments set status = 'succeeded' where id = '$payment'" >/dev/null

  "${PSQL[@]}" -c "select private.release_activity('$activity')" >/dev/null &
  a=$!
  "${PSQL[@]}" -c "begin; select 1 from public.activities where id = '$activity' for update; select private.refund_issue('$payment', 'player_in_time'); commit;" >/dev/null &
  b=$!
  wait $a
  wait $b

  result=$("${PSQL[@]}" <<SQL
select private.ledger_balance('held', '$activity', 'SGD');
SQL
  )
  refunded=$("${PSQL[@]}" -c "select coalesce(sum(price_minor), 0) from public.refunds where payment_id = '$payment'")
  organizer=$("${PSQL[@]}" -c "select private.ledger_balance('organizer', '$HOST', 'SGD')")
  # Whichever won, the player gets the price back once, and the organizer ends
  # where they started: a late refund comes out of what was just released.
  if [[ "$result" != "0" || "$refunded" != "600" || "$organizer" != "$start" ]]; then
    echo "round $i: held $result, refunded $refunded, organizer $organizer, was $start"
    failed=1
  fi
done

"${PSQL[@]}" -c "update public.feature_flags set enabled = false where key = 'payments.enabled'" >/dev/null
if [[ $failed -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "ok: $ROUNDS rounds, held money always ended at zero"
