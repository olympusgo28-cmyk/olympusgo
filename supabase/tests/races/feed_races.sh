#!/bin/bash
# Real parallel connections, which a single pgTAP transaction can't give.
#   Claim: six workers claim at once with one job queued. One gets it.
#   Replay: six replays of one match make one match row.
#   Limit: six posts at once with room for two. Two get through.
#   First posts: four verdicts at once on a new author. None goes live.
#   Likes: six likes at once count once.
# NEGATIVE=1 takes the lock out of post_create for the run, and passes only if
# the limit race then catches the overrun, so a pass here means something.
# Local stack only.
set -euo pipefail

PSQL=(docker exec -i supabase_db_olympusGO psql -U postgres -d postgres -Atq -v ON_ERROR_STOP=1)
ROUNDS=${1:-25}
AUTHOR=c9000000-0000-0000-0000-000000000010
FAN=c9000000-0000-0000-0000-000000000011
LOCK="perform pg_advisory_xact_lock(hashtextextended('feed:' || v_user::text, 0));"
restore_lock() {
  "${PSQL[@]}" >/dev/null <<SQL
do \$\$
begin
  execute replace(pg_get_functiondef('public.post_create(uuid, text, integer, bigint, text, text, text, boolean)'::regprocedure),
    '-- no lock', \$l\$$LOCK\$l\$);
end;
\$\$;
SQL
}
cleanup() {
  [ "${NEGATIVE:-0}" = 1 ] && restore_lock
  "${PSQL[@]}" >/dev/null <<SQL
delete from public.video_posts where author_id = '$AUTHOR';
delete from public.moderation_cases where target_kind = 'video' and owner_id is null and target_id in
  (select post_id::text from public.abuse_matches where author_id = '$AUTHOR');
delete from public.storage_deletions where path like '$AUTHOR/%';
update public.feature_flags set enabled = false where key in ('video.feed', 'feed.fake_checks');
update public.app_settings set value = '5' where key = 'feed.daily_posts';
SQL
}
trap cleanup EXIT

"${PSQL[@]}" <<SQL
update public.feature_flags set enabled = true where key in ('video.feed', 'feed.fake_checks');
insert into auth.users (id, instance_id, aud, role, email) values
  ('$AUTHOR', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'feed-race-a@test.local'),
  ('$FAN', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'feed-race-b@test.local')
on conflict do nothing;
update public.account_private set birthday = '1990-01-01', country_code = 'SG',
  mobile = '+6597' || right(replace(id::text, '-', ''), 6), mobile_verified_at = now()
where id in ('$AUTHOR', '$FAN') and birthday is null;
update public.profiles set onboarding_completed = true, username = 'feed_race_' || right(id::text, 2)
where id in ('$AUTHOR', '$FAN');
insert into public.follows (follower_id, followee_id) values ('$FAN', '$AUTHOR') on conflict do nothing;
SQL

as_user() {
  "${PSQL[@]}" -c "begin; select set_config('request.jwt.claims', '{\"sub\":\"$1\",\"role\":\"authenticated\"}', true); set local role authenticated; $2; commit;" 2>/dev/null || true
}

# A post with its file in place, as far as the checks.
checking() {
  "${PSQL[@]}" >/dev/null <<SQL
insert into public.video_posts (id, author_id, sport, country_code, ext, seconds, bytes, status, video_ref, no_minors_at)
values ('$1', '$AUTHOR', 'badminton', 'SG', 'mp4', 20, 1000, 'waiting', '$AUTHOR/$1.mp4', now());
update public.video_posts set status = 'checking' where id = '$1';
insert into public.post_jobs (post_id) values ('$1');
SQL
}

reset_round() {
  "${PSQL[@]}" >/dev/null <<SQL
delete from public.video_posts where author_id = '$AUTHOR';
update public.post_jobs set status = 'done' where status = 'queued';
update public.app_settings set value = '50' where key = 'feed.daily_posts';
SQL
}

limit_race() {
  reset_round
  "${PSQL[@]}" -c "update public.app_settings set value = '2' where key = 'feed.daily_posts'" >/dev/null
  # The ids first, so the six start together.
  IDS=($("${PSQL[@]}" -c "select gen_random_uuid() from generate_series(1, 6)"))
  for p in "${IDS[@]}"; do
    as_user "$AUTHOR" "select public.post_create('$p', 'mp4', 20, 1000, '', 'badminton', 'public', true)" >/dev/null &
  done
  wait
  "${PSQL[@]}" -c "select count(*) from public.video_posts where author_id = '$AUTHOR'"
}

if [ "${NEGATIVE:-0}" = 1 ]; then
  "${PSQL[@]}" >/dev/null <<SQL
do \$\$
declare
  d text := pg_get_functiondef('public.post_create(uuid, text, integer, bigint, text, text, text, boolean)'::regprocedure);
  fixed text := replace(d, \$l\$$LOCK\$l\$, '-- no lock');
begin
  if fixed = d then raise exception 'the lock was not found'; end if;
  execute fixed;
end;
\$\$;
SQL
  for round in $(seq 1 "$ROUNDS"); do
    n=$(limit_race)
    if [ "$n" -gt 2 ]; then
      echo "ok: without the lock the race caught $n posts past a limit of 2, in round $round"
      exit 0
    fi
  done
  echo "negative control: no overrun in $ROUNDS rounds, so this script proves nothing"
  exit 1
fi

for round in $(seq 1 "$ROUNDS"); do
  reset_round

  # Six claims on one job.
  POST=$("${PSQL[@]}" -c "select gen_random_uuid()")
  checking "$POST"
  TMP=$(mktemp -d)
  for i in 1 2 3 4 5 6; do
    "${PSQL[@]}" -c "select public.feed_svc_claim()" > "$TMP/$i" 2>/dev/null &
  done
  wait
  n=$(cat "$TMP"/* | grep -c job_id || true)
  [ "$n" = 1 ] || { echo "round $round: one job claimed $n times"; exit 1; }

  # Six replays of one match.
  TOKEN=$(cat "$TMP"/* | grep job_id | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["token"])')
  JOB=$(cat "$TMP"/* | grep job_id | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["job_id"])')
  rm -rf "$TMP"
  for _ in 1 2 3 4 5 6; do
    "${PSQL[@]}" -c "select public.feed_svc_result('$JOB', '$TOKEN', true, 'match', 'clear', 'local-fake', null, false, null, 1)" >/dev/null 2>&1 &
  done
  wait
  n=$("${PSQL[@]}" -c "select count(*) from public.abuse_matches where post_id = '$POST'")
  [ "$n" = 1 ] || { echo "round $round: one match made $n rows"; exit 1; }
  # A match outlives its post, and a clean round needs a clean author.
  "${PSQL[@]}" >/dev/null <<SQL
alter table public.abuse_matches disable trigger abuse_matches_keep;
delete from public.abuse_matches where author_id = '$AUTHOR';
alter table public.abuse_matches enable trigger abuse_matches_keep;
delete from public.moderation_cases where target_kind = 'video' and target_id = '$POST';
SQL

  # Six posts at once, with room for two.
  n=$(limit_race)
  [ "$n" = 2 ] || { echo "round $round: the daily limit let through $n"; exit 1; }

  # Four verdicts at once on an author with no approvals.
  reset_round
  JOBS=()
  for i in 1 2 3 4; do
    p=$("${PSQL[@]}" -c "select gen_random_uuid()")
    checking "$p"
    JOBS+=("$("${PSQL[@]}" -c "select public.feed_svc_claim()")")
  done
  for j in "${JOBS[@]}"; do
    job=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["job_id"])' "$j")
    token=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["token"])' "$j")
    "${PSQL[@]}" -c "select public.feed_svc_result('$job', '$token', true, 'clear', 'clear', 'local-fake', null, false, null, 1)" >/dev/null &
  done
  wait
  n=$("${PSQL[@]}" -c "select count(*) from public.video_posts where author_id = '$AUTHOR' and status = 'review'")
  [ "$n" = 4 ] || { echo "round $round: only $n of 4 new posts went to a person"; exit 1; }

  # Six likes at once.
  "${PSQL[@]}" >/dev/null <<SQL
update public.video_posts set status = 'live', live_at = now(), audience = 'public'
where id = (select id from public.video_posts where author_id = '$AUTHOR' limit 1);
SQL
  LIVE=$("${PSQL[@]}" -c "select id from public.video_posts where author_id = '$AUTHOR' and status = 'live'")
  for _ in 1 2 3 4 5 6; do
    as_user "$FAN" "select public.post_like('$LIVE')" >/dev/null &
  done
  wait
  n=$("${PSQL[@]}" -c "select count(*) from public.post_likes where post_id = '$LIVE'")
  [ "$n" = 1 ] || { echo "round $round: one person liked $n times"; exit 1; }
done
echo "ok: $ROUNDS rounds, each job claimed once, one match per replay, the limit held, new posts reached a person, one like each"
