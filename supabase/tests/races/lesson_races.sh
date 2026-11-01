#!/bin/bash
# Real parallel connections, which a single pgTAP transaction can't give.
#   Slot: two people reserve the same one-to-one. One gets it.
#   Seat: three people reserve the last place in a class. One gets it.
#   Overlap: a coach opens the same time twice at once. One stands.
#   Money: on one booking the payer cancels twice, the academy cancels, the
#   coach marks attendance and the sweep runs, all at once. Odd rounds have the
#   lesson in the future, so the cancels race each other. Even rounds put it
#   just past its release time, so attendance and the sweep can win. Whichever
#   wins, the money moves once and nothing stays held. Local stack only.
set -euo pipefail

PSQL=(docker exec -i supabase_db_olympusGO psql -U postgres -d postgres -Atq -v ON_ERROR_STOP=1)
ROUNDS=${1:-25}
OWNER=c7000000-0000-0000-0000-000000000001
COACH=c7000000-0000-0000-0000-000000000002
A=c7000000-0000-0000-0000-000000000003
B=c7000000-0000-0000-0000-000000000004
C=c7000000-0000-0000-0000-000000000005
LOG=$(mktemp)
trap 'rm -f "$LOG"; "${PSQL[@]}" -c "update public.feature_flags set enabled = false where key in ('"'"'payments.enabled'"'"', '"'"'lessons.checkout'"'"')" >/dev/null' EXIT

# Refusals are expected. Anything else is a failed run, so it's kept and checked.
as_user() {
  "${PSQL[@]}" -c "begin; select set_config('request.jwt.claims', '{\"sub\":\"$1\",\"role\":\"authenticated\"}', true); set local role authenticated; $2; commit;" >/dev/null 2>>"$LOG" || true
}

"${PSQL[@]}" <<SQL
update public.feature_flags set enabled = true where key in ('payments.enabled', 'lessons.checkout');
insert into auth.users (id, instance_id, aud, role, email)
select x, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', x || '@test.local'
from unnest(array['$OWNER', '$COACH', '$A', '$B', '$C']::uuid[]) x
on conflict do nothing;
update public.account_private set birthday = '1990-01-01', country_code = 'SG',
  mobile = '+659' || right(replace(id::text, '-', ''), 7), mobile_verified_at = now()
where id in ('$OWNER', '$COACH', '$A', '$B', '$C');
insert into public.coach_licences (user_id, nroc_number, expires_on, status, verified_at)
values ('$OWNER', 'NROC-1', current_date + 300, 'verified', now()), ('$COACH', 'NROC-2', current_date + 300, 'verified', now())
on conflict (user_id) do nothing;
insert into public.vendors (owner_id, stripe_account_id, status) values ('$OWNER', 'acct_race', 'verified')
on conflict (owner_id) do nothing;
SQL
ACADEMY=$("${PSQL[@]}" -c "select id from public.academies where owner_id = '$OWNER' limit 1")
if [[ -z "$ACADEMY" ]]; then
  ACADEMY=$("${PSQL[@]}" <<SQL | head -1
insert into public.academies (owner_id, name, sport, verification, uen)
values ('$OWNER', 'Race Academy', 'badminton', 'verified', '201912345A') returning id;
SQL
  )
  "${PSQL[@]}" -c "insert into public.academy_coaches (academy_id, user_id, role, head, accepted_at) values ('$ACADEMY', '$OWNER', 'Head coach', true, now()), ('$ACADEMY', '$COACH', 'Coach', false, now())" >/dev/null
fi

reserve() { # user kind ref at
  as_user "$1" "select public.lesson_reserve('$2', '$3', $4, '$1', 'race-' || gen_random_uuid(), $5)"
}

clear_unpaid() {
  "${PSQL[@]}" >/dev/null <<SQL
update public.payments set status = 'cancelled' where lesson_booking_id in
  (select id from public.lesson_bookings where step = 'pending') and status = 'pending';
update public.lesson_bookings set step = 'cancelled' where step = 'pending';
SQL
}

failed=0
cancelled=0
late=0
released=0
day=0
for ((i = 1; i <= ROUNDS; i++)); do
  day=$((day + 1))

  # Two people, one slot.
  SLOT=$("${PSQL[@]}" <<SQL | head -1
insert into public.lesson_slots (academy_id, coach_id, starts_at, ends_at, price_minor)
values ('$ACADEMY', '$COACH', now() + make_interval(hours => 48 + $i * 2), now() + make_interval(hours => 49 + $i * 2), 5000) returning id;
SQL
  )
  reserve "$A" one_to_one "$SLOT" null 5500 &
  x=$!
  reserve "$B" one_to_one "$SLOT" null 5500 &
  y=$!
  wait $x $y
  sold=$("${PSQL[@]}" -c "select count(*) from public.lesson_bookings where slot_id = '$SLOT' and step = 'pending'")
  if [[ "$sold" != "1" ]]; then
    echo "round $i: a slot was sold $sold times"
    failed=1
  fi
  clear_unpaid

  # Three people, the last seat.
  CLASS=$("${PSQL[@]}" <<SQL | head -1
insert into public.academy_classes (academy_id, name, weekdays, hour, capacity, coach_id, dropin_price_cents)
values ('$ACADEMY', 'Race class', '{1,2,3,4,5,6,7}', 10, 1, '$COACH', 3000) returning id;
SQL
  )
  AT="(((now() at time zone 'Asia/Singapore')::date + 5)::timestamp + time '10:00') at time zone 'Asia/Singapore'"
  reserve "$A" class "$CLASS" "$AT" 3300 &
  x=$!
  reserve "$B" class "$CLASS" "$AT" 3300 &
  y=$!
  reserve "$C" class "$CLASS" "$AT" 3300 &
  z=$!
  wait $x $y $z
  sold=$("${PSQL[@]}" -c "select count(*) from public.lesson_bookings where class_id = '$CLASS' and step = 'pending'")
  if [[ "$sold" != "1" ]]; then
    echo "round $i: the last seat was sold $sold times"
    failed=1
  fi
  clear_unpaid

  # A coach opens the same time twice.
  WHEN="now() + make_interval(hours => 500 + $i * 3)"
  as_user "$COACH" "select public.lesson_slot_add('$ACADEMY', $WHEN, 60, 5000, '')" &
  x=$!
  as_user "$COACH" "select public.lesson_slot_add('$ACADEMY', $WHEN + interval '10 minutes', 60, 5000, '')" &
  y=$!
  wait $x $y
  open=$("${PSQL[@]}" -c "select count(*) from public.lesson_slots where coach_id = '$COACH' and status = 'open' and starts_at > now() + make_interval(hours => 499 + $i * 3) and starts_at < now() + make_interval(hours => 501 + $i * 3)")
  if [[ "$open" != "1" ]]; then
    echo "round $i: $open slots overlap"
    failed=1
  fi

  # Everything at once on one paid booking.
  SLOT2=$("${PSQL[@]}" <<SQL | head -1
insert into public.lesson_slots (academy_id, coach_id, starts_at, ends_at, price_minor)
values ('$ACADEMY', '$COACH', now() + make_interval(hours => 1000 + $i * 2), now() + make_interval(hours => 1001 + $i * 2), 5000) returning id;
SQL
  )
  ids=$("${PSQL[@]}" <<SQL
begin;
select set_config('request.jwt.claims', '{"sub":"$A","role":"authenticated"}', true);
set local role authenticated;
select public.lesson_reserve('one_to_one',
  '$SLOT2', null, '$A', 'money-' || gen_random_uuid(), 5500);
commit;
SQL
  )
  booking=$(echo "$ids" | grep -o '"booking_id": "[^"]*"' | cut -d'"' -f4)
  payment=$(echo "$ids" | grep -o '"payment_id": "[^"]*"' | cut -d'"' -f4)
  "${PSQL[@]}" >/dev/null <<SQL
select public.money_svc_event(jsonb_build_object('id', 'evt_' || gen_random_uuid(),
  'type', 'payment_intent.succeeded', 'object', jsonb_build_object('id', 'pi_$payment',
  'amount', 5500, 'currency', 'sgd', 'latest_charge', 'ch_$payment', 'payment_method_type', 'card',
  'metadata', jsonb_build_object('payment_id', '$payment'))));
SQL
  if ((i % 2 == 0)); then
    # The guard keeps these times fixed, so only this script may move them.
    "${PSQL[@]}" >/dev/null <<SQL
set session_replication_role = replica;
update public.lesson_bookings set starts_at = now() - interval '2 hours', ends_at = now() - interval '1 hour',
  release_at = now() + interval '30 milliseconds' where id = '$booking';
set session_replication_role = origin;
SQL
  fi
  as_user "$A" "select public.lesson_cancel('$booking', 'race')" &
  p=$!
  as_user "$A" "select public.lesson_cancel('$booking', 'race')" &
  q=$!
  as_user "$COACH" "select public.lesson_academy_cancel('$booking', 'race')" &
  r=$!
  as_user "$COACH" "select public.lesson_mark_attendance('$booking', true)" &
  s=$!
  (for _ in 1 2 3 4 5; do "${PSQL[@]}" -c "select private.lessons_sweep()" >/dev/null; done) &
  t=$!
  wait $p $q $r $s $t
  # Whatever's left when they've finished, the sweep settles if it's due.
  "${PSQL[@]}" -c "select private.lessons_sweep()" >/dev/null

  read -r step held refunds refunded releases <<<"$("${PSQL[@]}" -F ' ' <<SQL
select b.step, private.ledger_balance('held', b.id, 'SGD'),
  (select count(*) from public.refunds r where r.payment_id = '$payment'),
  (select coalesce(sum(r.amount_minor), 0) from public.refunds r where r.payment_id = '$payment'),
  (select count(*) from public.ledger_transactions t where t.idempotency_key = 'release:$payment')
from public.lesson_bookings b where b.id = '$booking';
SQL
  )"
  case "$step" in
    cancelled)
      cancelled=$((cancelled + 1))
      if [[ "$held" != "0" || "$refunds" != "1" || "$releases" != "0" || ("$refunded" != "5000" && "$refunded" != "5500") ]]; then
        echo "round $i: cancelled, held $held, refunds $refunds of $refunded, releases $releases"
        failed=1
      fi
      ;;
    late_cancelled)
      late=$((late + 1))
      if [[ "$refunds" != "0" || "$releases" != "0" ]]; then
        echo "round $i: late, refunds $refunds, releases $releases"
        failed=1
      fi
      ;;
    released)
      released=$((released + 1))
      if [[ "$held" != "0" || "$refunds" != "0" || "$releases" != "1" ]]; then
        echo "round $i: released, held $held, refunds $refunds of $refunded, releases $releases"
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
if grep ERROR "$LOG" | grep -viE "can't be cancelled|has started|has been settled|Finish or cancel|just booked|is full|already have a lesson|already booked|mark attendance once|isn't yours"; then
  echo "A racer failed for a reason nobody expected"
  failed=1
fi
swept=$("${PSQL[@]}" -c "select count(*) from public.money_alerts where kind = 'lesson_sweep_failed'")
if [[ "$swept" != "0" ]]; then
  echo "The sweep failed $swept times while racing"
  failed=1
fi
if ((cancelled == 0 || released == 0)); then
  echo "Nothing raced: $cancelled cancelled, $late late, $released released"
  failed=1
fi
if [[ $failed -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "ok: $ROUNDS rounds ($cancelled cancelled, $late late, $released released), every place sold once, the money moved once"
