#!/bin/bash
# Real parallel connections, which a single pgTAP transaction can't give.
#   One key: six calls with the same key at once make one request.
#   One player: six keys at once stop at the daily limit.
#   App-wide: six players at once stop at the app-wide limit.
# Local stack only. The model is never called.
set -euo pipefail

PSQL=(docker exec -i supabase_db_olympusGO psql -U postgres -d postgres -Atq -v ON_ERROR_STOP=1)
ROUNDS=${1:-25}
PREFIX=c7000000-0000-0000-0000-0000000000
cleanup() {
  "${PSQL[@]}" >/dev/null <<SQL
delete from public.ai_plan_requests where user_id::text like '$PREFIX%';
update public.feature_flags set enabled = false where key in ('fitness.enabled', 'fitness.ai_plans');
update public.app_settings set value = '200' where key = 'ai_plans.daily_total';
SQL
}
trap cleanup EXIT

ask() { # user, key
  "${PSQL[@]}" -c "begin; select set_config('request.jwt.claims', '{\"sub\":\"$1\",\"role\":\"authenticated\"}', true); set local role authenticated; select public.ai_plan_begin('$2', 'speed', 2) ->> 'status'; commit;" 2>/dev/null || true
}

"${PSQL[@]}" <<SQL
update public.feature_flags set enabled = true where key in ('fitness.enabled', 'fitness.ai_plans');
insert into auth.users (id, instance_id, aud, role, email)
select ('$PREFIX' || lpad(n::text, 2, '0'))::uuid, '00000000-0000-0000-0000-000000000000', 'authenticated',
  'authenticated', 'race' || n || '@test.local'
from generate_series(10, 16) n on conflict do nothing;
update public.account_private set birthday = '1990-01-01', country_code = 'SG',
  mobile = '+659' || right(replace(id::text, '-', ''), 7), mobile_verified_at = now()
where id::text like '$PREFIX%' and birthday is null;
update public.profiles set onboarding_completed = true, username = 'race' || right(id::text, 4)
where id::text like '$PREFIX%';
insert into public.consents (user_id, kind)
select id, 'ai_plans' from auth.users where id::text like '$PREFIX%' on conflict do nothing;
SQL

ONE=${PREFIX}10
for round in $(seq 1 "$ROUNDS"); do
  "${PSQL[@]}" -c "delete from public.ai_plan_requests where user_id::text like '$PREFIX%'; update public.app_settings set value = '100000' where key = 'ai_plans.daily_total';"

  for _ in 1 2 3 4 5 6; do ask "$ONE" "same-key-$round" >/dev/null & done
  wait
  n=$("${PSQL[@]}" -c "select count(*) from public.ai_plan_requests where user_id = '$ONE'")
  [ "$n" = 1 ] || { echo "round $round: one key made $n requests"; exit 1; }

  "${PSQL[@]}" -c "delete from public.ai_plan_requests where user_id = '$ONE'"
  for i in 1 2 3 4 5 6; do ask "$ONE" "many-key-$round-$i" >/dev/null & done
  wait
  n=$("${PSQL[@]}" -c "select count(*) from public.ai_plan_requests where user_id = '$ONE'")
  [ "$n" = 3 ] || { echo "round $round: the daily limit let through $n"; exit 1; }

  # Whatever else is on this stack counts towards the limit too.
  "${PSQL[@]}" -c "update public.app_settings set value = (select to_jsonb(count(*) + 2) from public.ai_plan_requests where user_id::text not like '$PREFIX%' and created_at > now() - interval '1 day') where key = 'ai_plans.daily_total'; delete from public.ai_plan_requests where user_id::text like '$PREFIX%';"
  for u in 11 12 13 14 15 16; do ask "$PREFIX$u" "total-key-$round" >/dev/null & done
  wait
  n=$("${PSQL[@]}" -c "select count(*) from public.ai_plan_requests where user_id::text like '$PREFIX%'")
  [ "$n" = 2 ] || { echo "round $round: the app-wide limit let through $n"; exit 1; }
done
echo "ok: $ROUNDS rounds, one key made one request, and both limits held"
