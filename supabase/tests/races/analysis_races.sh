#!/bin/bash
# Real parallel connections, which a single pgTAP transaction can't give.
#   Claim: six workers claim at once with one job queued. One gets it.
#   Cap: six confirms at once, with room for two clips. Two get through.
#   Result: six replays of one result at once make one report.
# Local stack only.
set -euo pipefail

source "$(dirname "$0")/db.sh"
ROUNDS=${1:-25}
OWNER=c8000000-0000-0000-0000-000000000010
cleanup() {
  "${PSQL[@]}" >/dev/null <<SQL
delete from public.video_clips where owner_id = '$OWNER';
delete from public.analysis_usage where owner_id = '$OWNER';
delete from public.storage_deletions where path like '$OWNER/%';
update public.feature_flags set enabled = false where key = 'video.analysis';
update public.app_settings set value = '600' where key = 'analysis.daily_seconds_per_user';
SQL
}
trap cleanup EXIT

"${PSQL[@]}" <<SQL
update public.feature_flags set enabled = true where key = 'video.analysis';
update public.app_settings set value = '120' where key = 'analysis.daily_seconds_per_user';
insert into auth.users (id, instance_id, aud, role, email)
values ('$OWNER', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'analysis-race@test.local')
on conflict do nothing;
update public.account_private set birthday = '1990-01-01', country_code = 'SG',
  mobile = '+6598' || right(replace(id::text, '-', ''), 6), mobile_verified_at = now()
where id = '$OWNER' and birthday is null;
update public.profiles set onboarding_completed = true, username = 'analysis_race' where id = '$OWNER';
SQL

as_owner() {
  "${PSQL[@]}" -c "begin; select set_config('request.jwt.claims', '{\"sub\":\"$OWNER\",\"role\":\"authenticated\"}', true); set local role authenticated; $1; commit;" 2>/dev/null || true
}

# A clip of 60 seconds, ready for the player to confirm.
ready() {
  "${PSQL[@]}" >/dev/null <<SQL
insert into public.video_clips (id, owner_id, subject_id, ext, status, seconds, bytes, purge_at, frame)
values ('$1', '$OWNER', '$OWNER', 'mp4', 'court_ready', 60, 1000, now() + interval '1 day', true);
SQL
}

for round in $(seq 1 "$ROUNDS"); do
  "${PSQL[@]}" -c "delete from public.video_clips where owner_id = '$OWNER'; update public.analysis_jobs set status = 'cancelled' where status = 'queued';" >/dev/null

  # Six claims on one job.
  CLIP=$("${PSQL[@]}" -c "select gen_random_uuid()")
  "${PSQL[@]}" >/dev/null <<SQL
insert into public.video_clips (id, owner_id, subject_id, ext, status, seconds, bytes, purge_at)
values ('$CLIP', '$OWNER', '$OWNER', 'mp4', 'uploaded', 60, 1000, now() + interval '1 day');
insert into public.analysis_jobs (clip_id, kind) values ('$CLIP', 'court');
SQL
  TMP=$(mktemp -d)
  for i in 1 2 3 4 5 6; do
    "${PSQL[@]}" -c "select public.analysis_svc_claim()" > "$TMP/$i" 2>/dev/null &
  done
  wait
  n=$(cat "$TMP"/* | grep -c job_id || true)
  [ "$n" = 1 ] || { echo "round $round: one job claimed $n times"; exit 1; }

  # Six replays of one good result.
  TOKEN=$(cat "$TMP"/* | grep job_id | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["token"])')
  JOB=$(cat "$TMP"/* | grep job_id | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["job_id"])')
  rm -rf "$TMP"
  for _ in 1 2 3 4 5 6; do
    "${PSQL[@]}" -c "select public.analysis_svc_result('$JOB', '$TOKEN', true, '{\"seconds\": 60}', null, 1)" >/dev/null 2>&1 &
  done
  wait
  s=$("${PSQL[@]}" -c "select status from public.analysis_jobs where id = '$JOB'")
  [ "$s" = done ] || { echo "round $round: the job ended $s"; exit 1; }

  # Three clips of 60 seconds and a cap of 120.
  "${PSQL[@]}" -c "delete from public.video_clips where owner_id = '$OWNER'; delete from public.analysis_usage where owner_id = '$OWNER'" >/dev/null
  CLIPS=()
  for i in 1 2 3; do
    c=$("${PSQL[@]}" -c "select gen_random_uuid()")
    CLIPS+=("$c")
    ready "$c"
  done
  for c in "${CLIPS[@]}"; do
    as_owner "select public.clip_confirm_court('$c', '[[0,0],[1,0],[1,1],[0,1]]', 'near')" >/dev/null &
  done
  wait
  n=$("${PSQL[@]}" -c "select count(*) from public.analysis_jobs j join public.video_clips c on c.id = j.clip_id where c.owner_id = '$OWNER' and j.kind = 'analyse'")
  [ "$n" = 2 ] || { echo "round $round: the daily cap let through $n"; exit 1; }
done
echo "ok: $ROUNDS rounds, each job claimed once, one result counted, and the cap held"
