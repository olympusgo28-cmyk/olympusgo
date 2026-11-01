-- P5-01, P5-02: clips, consent, the purge and jobs, for every role. Storage
-- policies are proven through the real API in test/supabase_clips_local_test.dart.
begin;
\ir helpers/setup.psql
select no_plan();

select t.player('e3000000-0000-0000-0000-000000000001');  -- adult owner
select t.player('e3000000-0000-0000-0000-000000000002');  -- stranger
select t.player('e3000000-0000-0000-0000-000000000003', 15);  -- linked teen
select t.player('e3000000-0000-0000-0000-000000000004', 40);  -- that teen's parent
select t.player('e3000000-0000-0000-0000-000000000005', 15);  -- restricted teen
select t.player('e3000000-0000-0000-0000-000000000006');  -- suspended adult
select t.player('e3000000-0000-0000-0000-000000000007');  -- staff
insert into public.guardian_links (parent_id, child_id, status)
values ('e3000000-0000-0000-0000-000000000004', 'e3000000-0000-0000-0000-000000000003', 'approved');
insert into public.staff (user_id, role) values ('e3000000-0000-0000-0000-000000000007', 'super');
insert into public.account_moderation (user_id, suspended_until)
values ('e3000000-0000-0000-0000-000000000006', now() + interval '1 day');
update public.feature_flags set enabled = true where key in ('video.analysis', 'video.analysis_minors');
-- Whatever a used database holds shouldn't reach the app-wide cap.
update public.app_settings set value = '100000000' where key = 'analysis.daily_seconds_total';
-- Older jobs on a used database would be claimed first.
update public.analysis_jobs set status = 'cancelled' where status = 'queued';

create function t.who(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end;
$$;
grant execute on function t.who(uuid) to authenticated, service_role;

create function t.back() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end;
$$;
grant execute on function t.back() to authenticated, service_role;

create function t.c(i int) returns uuid language sql immutable as $$
  select ('e3000000-0000-0000-0000-0000000010' || lpad(i::text, 2, '0'))::uuid;
$$;
grant execute on function t.c(int) to authenticated, service_role;

-- Pretends the upload landed.
create function t.file(p_clip uuid) returns void language sql security definer as $$
  insert into storage.objects (bucket_id, name, metadata)
  select 'analysis-clips', c.owner_id || '/' || c.id || '.' || c.ext, '{"size": 1000}'
  from public.video_clips c where c.id = p_clip;
$$;

create function t.corners() returns jsonb language sql immutable as $$
  select '[[0.1, 0.1], [0.9, 0.1], [0.9, 0.9], [0.1, 0.9]]'::jsonb;
$$;
grant execute on function t.corners() to authenticated, service_role;

create function t.report() returns jsonb language sql immutable as $$
  select jsonb_build_object('distance_m', 812.5, 'avg_speed_ms', 1.8, 'top_speed_ms', 4.2, 'moving_seconds', 95,
    'heatmap', (select jsonb_agg((select jsonb_agg(5) from generate_series(1, 6))) from generate_series(1, 13)));
$$;
grant execute on function t.report() to service_role;

create temp table claims (name text primary key, v jsonb) on commit drop;
grant all on claims to authenticated, service_role;

create function t.claim(p_name text) returns jsonb language plpgsql as $$
declare
  v jsonb := public.analysis_svc_claim();
begin
  insert into claims values (p_name, v) on conflict (name) do update set v = excluded.v;
  return v;
end;
$$;
grant execute on function t.claim(text) to service_role;

create function t.got(p_name text) returns jsonb language sql as $$ select v from claims where name = p_name; $$;
grant execute on function t.got(text) to service_role;

-- A clip of the owner's, all the way to court_ready.
create function t.ready(p_i int, p_owner uuid default 'e3000000-0000-0000-0000-000000000001', p_seconds int default 60)
returns void language plpgsql as $$
begin
  perform t.who(p_owner);
  perform public.clip_create(t.c(p_i), null, 'mp4', p_seconds, 1000, true);
  perform t.back();
  perform t.file(t.c(p_i));
  perform t.who(p_owner);
  perform public.clip_uploaded(t.c(p_i));
  perform t.back();
  set local role service_role;
  perform t.claim('c' || p_i);
  perform public.analysis_svc_result((t.got('c' || p_i) ->> 'job_id')::uuid, t.got('c' || p_i) ->> 'token', true,
    jsonb_build_object('seconds', p_seconds, 'corners', t.corners()), null, 5);
  reset role;
end;
$$;

-- ─── Signed out, and no client access ──────────────────────────────────────

set local role anon;
select throws_ok($$ select public.clip_list() $$, '42501', null, 'signed out: no clips');
select throws_ok($$ select public.clip_create(gen_random_uuid(), null, 'mp4', 60, 1000, true) $$, '42501', null, 'can''t add one');
select throws_ok($$ select public.clip_get(gen_random_uuid()) $$, '42501', null, 'can''t open one');
select throws_ok($$ select public.clip_delete(gen_random_uuid()) $$, '42501', null, 'can''t delete one');
select throws_ok($$ select public.analysis_status() $$, '42501', null, 'can''t check');
select throws_ok($$ select * from public.video_clips $$, '42501', null, 'no table access');
reset role;

select t.who('e3000000-0000-0000-0000-000000000001');
select throws_ok($$ select * from public.video_clips $$, '42501', null, 'a player can''t read clips directly');
select throws_ok($$ select * from public.video_consents $$, '42501', null, 'or consents');
select throws_ok($$ select * from public.analysis_jobs $$, '42501', null, 'or jobs');
select throws_ok($$ select * from public.analysis_reports $$, '42501', null, 'or reports');
select throws_ok($$ select * from public.storage_deletions $$, '42501', null, 'or the delete queue');
select throws_ok($$ select public.analysis_svc_claim() $$, '42501', null, 'or claim a job');
select throws_ok($$ select public.analysis_svc_result(gen_random_uuid(), 'x', true, '{}', null, 1) $$, '42501', null,
  'or report one');
select throws_ok($$ select public.analysis_svc_sweep() $$, '42501', null, 'or sweep');
select throws_ok($$ select public.analysis_svc_orphans() $$, '42501', null, 'or look for strays');
select throws_ok($$ select public.analysis_svc_frame_path(gen_random_uuid(), 'x') $$, '42501', null, 'or ask for a path');
select throws_ok($$ select public.analysis_svc_removed('{}') $$, '42501', null, 'or clear the queue');
select throws_ok($$ select public.staff_analysis_overview() $$, 'P0001', 'Not found.', 'or see the monitor');
select t.back();

select is_empty($$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname like 'analysis\_svc\_%'
    and (has_function_privilege('anon', p.oid, 'execute') or has_function_privilege('authenticated', p.oid, 'execute')) $$,
  'the service functions are for Edge Functions only');
select is_empty($$ select b.id from storage.buckets b where b.id = 'analysis-clips' and b.public $$, 'the bucket is private');
select is_empty($$ select policyname from pg_policies where schemaname = 'storage' and tablename = 'objects'
  and qual || coalesce(with_check, '') like '%analysis-clips%' and cmd in ('UPDATE', 'DELETE') $$,
  'no client can change or delete a file');
select is_empty($$ select policyname from pg_policies where schemaname = 'storage' and tablename = 'objects'
  and coalesce(qual, '') || coalesce(with_check, '') like '%analysis-clips%' and coalesce(qual, '') || coalesce(with_check, '') like '%is_staff%' $$,
  'staff have no policy on it');

-- ─── Flags and who can add ─────────────────────────────────────────────────

select t.back();
update public.feature_flags set enabled = false where key = 'video.analysis';
select t.who('e3000000-0000-0000-0000-000000000001');
select is((public.analysis_status() ->> 'open')::boolean, false, 'flag off: closed');
select throws_ok(format($$ select public.clip_create(%L, null, 'mp4', 60, 1000, true) $$, t.c(1)), 'P0001',
  'Analysis is not open yet.', 'flag off: can''t add');
select t.back();
update public.feature_flags set enabled = true where key = 'video.analysis';

select t.who('e3000000-0000-0000-0000-000000000001');
select is((public.analysis_status() ->> 'open')::boolean, true, 'an adult can use it');
select throws_ok(format($$ select public.clip_create(%L, null, 'mp4', 60, 1000, false) $$, t.c(1)), 'P0001',
  'Check that everyone in the clip has agreed.', 'everyone in the clip must have agreed');
select throws_ok(format($$ select public.clip_create(%L, null, 'avi', 60, 1000, true) $$, t.c(1)), 'P0001',
  'Choose an MP4 or MOV clip.', 'only mp4 or mov');
select throws_ok(format($$ select public.clip_create(%L, null, 'mp4', 181, 1000, true) $$, t.c(1)), 'P0001',
  'That clip is too long.', 'over 3 minutes is refused');
select throws_ok(format($$ select public.clip_create(%L, null, 'mp4', 60, 300000000, true) $$, t.c(1)), 'P0001',
  'That clip is too big.', 'over 200 MB is refused');

select t.who('e3000000-0000-0000-0000-000000000003');
select is((public.analysis_status() ->> 'open')::boolean, false, 'a teen sees it closed');
select throws_ok(format($$ select public.clip_create(%L, null, 'mp4', 60, 1000, true) $$, t.c(2)), 'P0001',
  'Ask a parent to add this clip.', 'a teen can''t upload');
select t.who('e3000000-0000-0000-0000-000000000005');
select throws_ok(format($$ select public.clip_create(%L, null, 'mp4', 60, 1000, true) $$, t.c(2)), 'P0001',
  'Ask a parent to link your account first.', 'a restricted child can''t');
select t.who('e3000000-0000-0000-0000-000000000006');
select throws_ok(format($$ select public.clip_create(%L, null, 'mp4', 60, 1000, true) $$, t.c(2)), 'P0001',
  'Your account is suspended.', 'a suspended player can''t');
select t.who('e3000000-0000-0000-0000-000000000002');
select throws_ok(format($$ select public.clip_create(%L, 'e3000000-0000-0000-0000-000000000003', 'mp4', 60, 1000, true, 'v1') $$, t.c(2)),
  'P0001', 'This clip can''t be added.', 'a stranger can''t add a clip of someone''s child');
select t.back();

-- ─── An adult's clip, start to finish ──────────────────────────────────────

select t.who('e3000000-0000-0000-0000-000000000001');
select is(public.clip_create(t.c(1), null, 'mp4', 60, 1000, true) ->> 'path',
  'e3000000-0000-0000-0000-000000000001/' || t.c(1) || '.mp4', 'an adult starts a clip');
select is(public.clip_create(t.c(1), null, 'mp4', 60, 1000, true) ->> 'status', 'waiting', 'a retry reaches the same one');
select is(public.clip_list() -> 0 ->> 'status', 'waiting', 'it shows as waiting until the file is in');
select throws_ok(format($$ select public.clip_uploaded(%L) $$, t.c(1)), 'P0001', 'The upload didn''t finish. Try again.',
  'a clip with no file can''t go on');
select t.back();
select t.file(t.c(1));
select t.who('e3000000-0000-0000-0000-000000000002');
select throws_ok(format($$ select public.clip_create(%L, null, 'mp4', 60, 1000, true) $$, t.c(1)), 'P0001',
  'This clip can''t be added.', 'someone else can''t take that id');
select throws_ok(format($$ select public.clip_uploaded(%L) $$, t.c(1)), 'P0001', 'Clip not found.', 'or finish it');
select t.who('e3000000-0000-0000-0000-000000000001');
select lives_ok(format($$ select public.clip_uploaded(%L) $$, t.c(1)), 'the owner finishes the upload');
select lives_ok(format($$ select public.clip_uploaded(%L) $$, t.c(1)), 'twice is fine');
select t.back();
select is((select count(*)::int from public.analysis_jobs where clip_id = t.c(1)), 1, 'one job is queued');

set local role service_role;
select t.claim('one') is not null;
select is(t.got('one') ->> 'kind', 'court', 'a worker claims the court job');
select is(t.got('one') ->> 'path', 'e3000000-0000-0000-0000-000000000001/' || t.c(1) || '.mp4', 'with the file''s path');
select ok(char_length(t.got('one') ->> 'token') = 64, 'and a token');
select is(public.analysis_svc_claim(), null, 'nobody else gets it');
select is(public.analysis_svc_frame_path((t.got('one') ->> 'job_id')::uuid, t.got('one') ->> 'token'),
  'e3000000-0000-0000-0000-000000000001/' || t.c(1) || '.frame.jpg', 'the database says where its frame goes');
select is(public.analysis_svc_frame_path((t.got('one') ->> 'job_id')::uuid, 'wrong'), null, 'and tells a wrong token nothing');
reset role;
select is_empty($$ select 1 from public.analysis_jobs j, claims c
  where j.token_hash = c.v ->> 'token' $$, 'only a hash of the token is kept');

set local role service_role;
select throws_ok(format($$ select public.analysis_svc_result(%L, 'wrong', true, '{"seconds": 60}', null, 5) $$,
  t.got('one') ->> 'job_id'), 'P0001', 'Bad token.', 'a wrong token is refused');
select throws_ok(format($$ select public.analysis_svc_result(%L, %L, true, '{"seconds": 60, "corners": [[9, 9]]}', null, 5) $$,
  t.got('one') ->> 'job_id', t.got('one') ->> 'token'), 'P0001', 'Bad result.', 'bad corners are refused');
select throws_ok(format($$ select public.analysis_svc_result(%L, %L, true, '{}', null, 5) $$,
  t.got('one') ->> 'job_id', t.got('one') ->> 'token'), 'P0001', 'Bad result.', 'a result with no length is refused');
select is(public.analysis_svc_result((t.got('one') ->> 'job_id')::uuid, t.got('one') ->> 'token', true,
  jsonb_build_object('seconds', 58, 'corners', t.corners()), null, 5), 'done', 'the court job finishes');
select is(public.analysis_svc_result((t.got('one') ->> 'job_id')::uuid, t.got('one') ->> 'token', true,
  jsonb_build_object('seconds', 58, 'corners', t.corners()), null, 5), 'done', 'a replay changes nothing');
reset role;
select is((select seconds from public.video_clips where id = t.c(1)), 58, 'the worker''s length replaces the phone''s');

select t.who('e3000000-0000-0000-0000-000000000001');
select is(public.clip_get(t.c(1)) ->> 'status', 'court_ready', 'the owner sees the court');
select is(public.clip_get(t.c(1)) ->> 'frame', 'e3000000-0000-0000-0000-000000000001/' || t.c(1) || '.frame.jpg', 'and its frame');
select throws_ok(format($$ select public.clip_confirm_court(%L, '[[1, 2]]', 'near') $$, t.c(1)), 'P0001',
  'Mark the four corners.', 'corners are checked');
select throws_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'both') $$, t.c(1)), 'P0001',
  'Choose your side.', 'one side only');
select t.who('e3000000-0000-0000-0000-000000000002');
select throws_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'near') $$, t.c(1)), 'P0001',
  'Clip not found.', 'a stranger can''t');
select throws_ok(format($$ select public.clip_get(%L) $$, t.c(1)), 'P0001', 'Clip not found.', 'or open it');
select lives_ok(format($$ select public.clip_delete(%L) $$, t.c(1)), 'deleting someone else''s does nothing');
select is(jsonb_array_length(public.clip_list()), 0, 'and they list none of it');
select t.who('e3000000-0000-0000-0000-000000000001');
select lives_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'near') $$, t.c(1)), 'the owner confirms');
select lives_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'near') $$, t.c(1)), 'twice is fine');
select t.back();
select is((select count(*)::int from public.analysis_jobs where clip_id = t.c(1) and kind = 'analyse'), 1, 'one analysis job');

set local role service_role;
select t.claim('two') is not null;
select is(t.got('two') ->> 'side', 'near', 'the worker is told which side');
select is(t.got('two') -> 'corners', t.corners(), 'and the corners');
select throws_ok(format($$ select public.analysis_svc_result(%L, %L, true, %L, null, 5) $$,
  t.got('two') ->> 'job_id', t.got('one') ->> 'token', t.report()), 'P0001', 'Bad token.',
  'another job''s token is refused');
select throws_ok(format($$ select public.analysis_svc_result(%L, %L, true, '{"distance_m": 1}', null, 5) $$,
  t.got('two') ->> 'job_id', t.got('two') ->> 'token'), 'P0001', 'Bad result.', 'a malformed report is refused');
select throws_ok(format($$ select public.analysis_svc_result(%L, %L, true, %L, null, 5) $$,
  t.got('two') ->> 'job_id', t.got('two') ->> 'token', t.report() || '{"top_speed_ms": 99}'), 'P0001', 'Bad result.',
  'an impossible speed is refused');
select is(public.analysis_svc_result((t.got('two') ->> 'job_id')::uuid, t.got('two') ->> 'token', true, t.report(), null, 30),
  'done', 'the report is saved');
reset role;

select t.who('e3000000-0000-0000-0000-000000000001');
select is(public.clip_get(t.c(1)) #>> '{report,distance_m}', '812.5', 'the owner reads the report');
select is(jsonb_array_length(public.clip_get(t.c(1)) #> '{report,heatmap}'), 13, 'with its heatmap');
select is_empty(format($$ select 1 where (public.clip_get(%L) -> 'report') ?| array['clip_id', 'subject_id'] $$, t.c(1)),
  'and no ids');
select t.back();
select is_empty($$ select column_name from information_schema.columns
  where table_schema = 'public' and table_name = 'analysis_reports' and column_name ~* 'opponent|other|image|frame|video' $$,
  'a report holds no image and nothing about an opponent');

-- ─── Failures ──────────────────────────────────────────────────────────────

select t.who('e3000000-0000-0000-0000-000000000001');
select public.clip_create(t.c(3), null, 'mp4', 60, 1000, true) is not null;
select t.back();
select t.file(t.c(3));
select t.who('e3000000-0000-0000-0000-000000000001');
select public.clip_uploaded(t.c(3));
select t.back();
set local role service_role;
select t.claim('f1') is not null;
select is(public.analysis_svc_result((t.got('f1') ->> 'job_id')::uuid, t.got('f1') ->> 'token', false, null, 'internal', 2),
  'queued', 'an internal failure gets one retry');
select t.claim('f2') is not null;
select is(t.got('f2') ->> 'job_id', t.got('f1') ->> 'job_id', 'the same job');
select is(public.analysis_svc_result((t.got('f2') ->> 'job_id')::uuid, t.got('f2') ->> 'token', false, null, 'internal', 2),
  'failed', 'then it fails');
reset role;
select is((select status from public.video_clips where id = t.c(3)), 'failed', 'and so does the clip');

select t.who('e3000000-0000-0000-0000-000000000001');
select public.clip_create(t.c(4), null, 'mp4', 60, 1000, true) is not null;
select t.back();
select t.file(t.c(4));
select t.who('e3000000-0000-0000-0000-000000000001');
select public.clip_uploaded(t.c(4));
select t.back();
set local role service_role;
select t.claim('f3') is not null;
select is(public.analysis_svc_result((t.got('f3') ->> 'job_id')::uuid, t.got('f3') ->> 'token', false, null, 'doubles', 2),
  'failed', 'a doubles clip fails at once');
reset role;
select is((select error_code from public.video_clips where id = t.c(4)), 'doubles', 'and says why');

select t.who('e3000000-0000-0000-0000-000000000001');
select public.clip_create(t.c(5), null, 'mp4', 60, 1000, true) is not null;
select t.back();
select t.file(t.c(5));
select t.who('e3000000-0000-0000-0000-000000000001');
select public.clip_uploaded(t.c(5));
select t.back();
set local role service_role;
select t.claim('f4') is not null;
select is(public.analysis_svc_result((t.got('f4') ->> 'job_id')::uuid, t.got('f4') ->> 'token', true,
  jsonb_build_object('seconds', 500), null, 2), 'failed', 'a clip longer than the phone said is stopped');
reset role;
select is((select error_code from public.video_clips where id = t.c(5)), 'too_long', 'by its real length');

-- An expired token.
select t.who('e3000000-0000-0000-0000-000000000001');
select public.clip_create(t.c(6), null, 'mp4', 60, 1000, true) is not null;
select t.back();
select t.file(t.c(6));
select t.who('e3000000-0000-0000-0000-000000000001');
select public.clip_uploaded(t.c(6));
select t.back();
set local role service_role;
select t.claim('x1') is not null;
reset role;
update public.analysis_jobs set deadline = now() - interval '1 minute' where id = (t.got('x1') ->> 'job_id')::uuid;
set local role service_role;
select throws_ok(format($$ select public.analysis_svc_result(%L, %L, true, '{"seconds": 60}', null, 5) $$,
  t.got('x1') ->> 'job_id', t.got('x1') ->> 'token'), 'P0001', 'Bad token.', 'an expired token is refused');
select ok(public.analysis_svc_sweep() is not null, 'the sweep runs');
reset role;
select is((select status from public.analysis_jobs where id = (t.got('x1') ->> 'job_id')::uuid), 'queued', 'a timed-out job gets one retry');
set local role service_role;
select t.claim('x2') is not null;
reset role;
update public.analysis_jobs set deadline = now() - interval '1 minute' where id = (t.got('x2') ->> 'job_id')::uuid;
set local role service_role;
select ok(public.analysis_svc_sweep() is not null, 'the sweep runs again');
reset role;
select is((select status from public.video_clips where id = t.c(6)), 'failed', 'then the clip fails');
select is((select error_code from public.video_clips where id = t.c(6)), 'timeout', 'as a timeout');

-- ─── The daily cap ─────────────────────────────────────────────────────────

select t.ready(7, 'e3000000-0000-0000-0000-000000000002', 180);
select t.ready(8, 'e3000000-0000-0000-0000-000000000002', 180);
select t.ready(9, 'e3000000-0000-0000-0000-000000000002', 180);
select t.ready(10, 'e3000000-0000-0000-0000-000000000002', 180);
select t.who('e3000000-0000-0000-0000-000000000002');
select lives_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'far') $$, t.c(7)), '3 minutes');
select lives_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'far') $$, t.c(8)), '6 minutes');
select lives_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'far') $$, t.c(9)), '9 minutes');
select throws_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'far') $$, t.c(10)), 'P0001',
  'You''ve reached today''s limit. Try again tomorrow.', '12 minutes is over the daily cap');
select t.back();
update public.analysis_usage set at = now() - interval '25 hours'
where owner_id = 'e3000000-0000-0000-0000-000000000002' and kind = 'analyse';
select t.who('e3000000-0000-0000-0000-000000000002');
select lives_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'far') $$, t.c(10)), 'it''s the last 24 hours');
select t.back();
update public.analysis_jobs set status = 'cancelled' where status = 'queued';
update public.app_settings set value = '0' where key = 'analysis.daily_seconds_total';
select t.ready(12, 'e3000000-0000-0000-0000-000000000001', 10);
select t.who('e3000000-0000-0000-0000-000000000001');
select throws_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'far') $$, t.c(12)), 'P0001',
  'Analysis is busy today. Try again tomorrow.', 'the app-wide cap holds');
select t.back();
update public.app_settings set value = '100000000' where key = 'analysis.daily_seconds_total';

-- ─── A child's clip ────────────────────────────────────────────────────────

update public.feature_flags set enabled = false where key = 'video.analysis_minors';
select t.who('e3000000-0000-0000-0000-000000000004');
select is((public.analysis_status() ->> 'children_open')::boolean, false, 'clips of children stay off until Gate F');
select throws_ok(format($$ select public.clip_create(%L, 'e3000000-0000-0000-0000-000000000003', 'mp4', 60, 1000, true, 'v1') $$, t.c(20)),
  'P0001', 'Clips of children are not open yet.', 'and a parent can''t add one');
select t.back();
update public.feature_flags set enabled = true where key = 'video.analysis_minors';

select t.who('e3000000-0000-0000-0000-000000000004');
select throws_ok(format($$ select public.clip_create(%L, 'e3000000-0000-0000-0000-000000000003', 'mp4', 60, 1000, true) $$, t.c(20)),
  'P0001', 'Give your consent first.', 'no consent, no clip');
select lives_ok(format($$ select public.clip_create(%L, 'e3000000-0000-0000-0000-000000000003', 'mp4', 60, 1000, true, 'v1') $$, t.c(20)),
  'a parent adds a clip of their child');
select t.back();
select is((select count(*)::int from public.video_consents where clip_id = t.c(20) and version = 'v1'
  and parent_id = 'e3000000-0000-0000-0000-000000000004'), 1, 'with one consent row');

select t.file(t.c(20));
select t.who('e3000000-0000-0000-0000-000000000004');
select public.clip_uploaded(t.c(20));
select is(jsonb_array_length(public.child_clip_list('e3000000-0000-0000-0000-000000000003')), 1, 'a parent lists it');
select is(public.child_clip_list('e3000000-0000-0000-0000-000000000003') -> 0 ->> 'for_child', 'true', 'as their child''s');
select t.who('e3000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.child_clip_list('e3000000-0000-0000-0000-000000000003') $$, 'P0001', 'Not found.',
  'a stranger can''t list a child''s clips');
select throws_ok(format($$ select public.clip_get(%L) $$, t.c(20)), 'P0001', 'Clip not found.', 'or read one');
select throws_ok(format($$ select public.consent_withdraw(%L) $$, t.c(20)), 'P0001', 'Clip not found.', 'or withdraw');
select throws_ok(format($$ select public.clip_extend(%L) $$, t.c(20)), 'P0001', 'Clip not found.', 'or extend');
select t.who('e3000000-0000-0000-0000-000000000007');
select throws_ok(format($$ select public.clip_get(%L) $$, t.c(20)), 'P0001', 'Clip not found.', 'and staff can''t either');
select t.who('e3000000-0000-0000-0000-000000000003');
select throws_ok(format($$ select public.clip_get(%L) $$, t.c(20)), 'P0001', 'Clip not found.', 'the child sees nothing for now');
select t.back();

-- Extending.
select t.who('e3000000-0000-0000-0000-000000000004');
select ok(public.clip_extend(t.c(20)) > now() + interval '170 days', 'a parent extends by 90 days');
select throws_ok(format($$ select public.clip_extend(%L) $$, t.c(20)), 'P0001', 'This clip has already been extended.',
  'once');
select t.back();

-- Withdrawing.
set local role service_role;
select t.claim('child') is not null;
select is(t.got('child') ->> 'path', 'e3000000-0000-0000-0000-000000000004/' || t.c(20) || '.mp4', 'a worker claims it');
reset role;
select t.who('e3000000-0000-0000-0000-000000000004');
select lives_ok(format($$ select public.consent_withdraw(%L) $$, t.c(20)), 'the parent withdraws');
select t.back();
select is((select status from public.analysis_jobs where id = (t.got('child') ->> 'job_id')::uuid), 'cancelled',
  'the job stops at once');
select ok((select withdrawn_at is not null from public.video_consents where clip_id = t.c(20)), 'the withdrawal is recorded');
set local role service_role;
select is(public.analysis_svc_result((t.got('child') ->> 'job_id')::uuid, t.got('child') ->> 'token', true,
  '{"seconds": 60}', null, 5), 'cancelled', 'a late result does nothing');
reset role;
select is((select status from public.video_clips where id = t.c(20)), 'withdrawn', 'the clip stays withdrawn');

set local role service_role;
select ok(public.analysis_svc_sweep() @> jsonb_build_array(jsonb_build_object('path',
  'e3000000-0000-0000-0000-000000000004/' || t.c(20) || '.mp4')) is not null, 'the sweep runs');
select ok(exists (select 1 from jsonb_array_elements(public.analysis_svc_sweep()) x
  where x ->> 'path' = 'e3000000-0000-0000-0000-000000000004/' || t.c(20) || '.mp4'), 'and says to remove the file');
reset role;
select ok((select file_gone_at is not null from public.video_clips where id = t.c(20)), 'the clip is marked gone');

-- A child's clip with no live consent never runs.
select t.who('e3000000-0000-0000-0000-000000000004');
select public.clip_create(t.c(21), 'e3000000-0000-0000-0000-000000000003', 'mp4', 60, 1000, true, 'v1') is not null;
select t.back();
select t.file(t.c(21));
select t.who('e3000000-0000-0000-0000-000000000004');
select public.clip_uploaded(t.c(21));
select t.back();
update public.video_consents set withdrawn_at = now() where clip_id = t.c(21);
update public.analysis_jobs set status = 'cancelled' where status = 'queued' and clip_id <> t.c(21);
set local role service_role;
select is(public.analysis_svc_claim(), null, 'no consent, no job');
reset role;
select is((select status from public.analysis_jobs where clip_id = t.c(21)), 'failed', 'it fails instead');
select is((select error_code from public.analysis_jobs where clip_id = t.c(21)), 'not_allowed', 'where staff can see it');

-- A consent for wording we don't use isn't consent.
select t.who('e3000000-0000-0000-0000-000000000004');
select throws_ok(format($$ select public.clip_create(%L, 'e3000000-0000-0000-0000-000000000003', 'mp4', 60, 1000, true, 'whatever') $$, t.c(23)),
  'P0001', 'Give your consent first.', 'consent must be to the current wording');
select t.back();

-- A link ending.
select t.who('e3000000-0000-0000-0000-000000000004');
select public.clip_create(t.c(22), 'e3000000-0000-0000-0000-000000000003', 'mp4', 60, 1000, true, 'v1') is not null;
select t.back();
select t.file(t.c(22));
select t.who('e3000000-0000-0000-0000-000000000004');
select public.clip_uploaded(t.c(22));
select t.back();
update public.guardian_links set status = 'revoked' where child_id = 'e3000000-0000-0000-0000-000000000003';
set local role service_role;
select is(public.analysis_svc_claim(), null, 'a clip whose parent link ended doesn''t run');
select ok(public.analysis_svc_sweep() is not null, 'the sweep runs');
reset role;
select is((select count(*)::int from public.video_clips where id = t.c(22)), 0, 'and it goes at once');
select is((select count(*)::int from public.storage_deletions where path like '%' || t.c(22) || '%'), 2,
  'with its files queued');
select t.who('e3000000-0000-0000-0000-000000000004');
select ok(not (public.clip_list()::text like '%Test Player%'), 'the former parent keeps no name or report');
select t.back();
update public.guardian_links set status = 'approved' where child_id = 'e3000000-0000-0000-0000-000000000003';

-- A former parent who still owns a clip has no claim on it, before the sweep runs.
select t.who('e3000000-0000-0000-0000-000000000004');
select public.clip_create(t.c(24), 'e3000000-0000-0000-0000-000000000003', 'mp4', 60, 1000, true, 'v1') is not null;
select t.back();
update public.guardian_links set status = 'revoked' where child_id = 'e3000000-0000-0000-0000-000000000003';
select t.who('e3000000-0000-0000-0000-000000000004');
select throws_ok(format($$ select public.clip_get(%L) $$, t.c(24)), 'P0001', 'Clip not found.', 'a former parent can''t open it');
select is(jsonb_array_length(public.clip_list()), 0, 'or list it');
select throws_ok(format($$ select public.clip_extend(%L) $$, t.c(24)), 'P0001', 'Clip not found.', 'or extend it');
select t.back();
update public.guardian_links set status = 'approved' where child_id = 'e3000000-0000-0000-0000-000000000003';

-- A second linked parent can act on a clip the first added, and stops it for both.
select t.player('e3000000-0000-0000-0000-000000000008', 41);
insert into public.guardian_links (parent_id, child_id, status)
values ('e3000000-0000-0000-0000-000000000008', 'e3000000-0000-0000-0000-000000000003', 'approved');
select t.who('e3000000-0000-0000-0000-000000000008');
select is(public.clip_get(t.c(24)) ->> 'for_child', 'true', 'the other parent can open it');
select lives_ok(format($$ select public.consent_withdraw(%L) $$, t.c(24)), 'and withdraw');
select t.back();
select is((select status from public.video_clips where id = t.c(24)), 'withdrawn', 'which holds for both');

-- Turning 18 ends a parent's claim.
select t.player('e3000000-0000-0000-0000-000000000009', 15);
insert into public.guardian_links (parent_id, child_id, status)
values ('e3000000-0000-0000-0000-000000000004', 'e3000000-0000-0000-0000-000000000009', 'approved');
select t.who('e3000000-0000-0000-0000-000000000004');
select public.clip_create(t.c(25), 'e3000000-0000-0000-0000-000000000009', 'mp4', 60, 1000, true, 'v1') is not null;
select t.back();
alter table public.account_private disable trigger user;
update public.account_private set birthday = current_date - interval '19 years'
where id = 'e3000000-0000-0000-0000-000000000009';
alter table public.account_private enable trigger user;
set local role service_role;
select ok(public.analysis_svc_sweep() is not null, 'the sweep runs');
reset role;
select is((select count(*)::int from public.video_clips where id = t.c(25)), 0, 'a clip of someone now 18 is removed');

-- Deleting a clip gives none of the cap back.
select t.player('e3000000-0000-0000-0000-000000000010');
select t.ready(26, 'e3000000-0000-0000-0000-000000000010', 180);
select t.who('e3000000-0000-0000-0000-000000000010');
select public.clip_confirm_court(t.c(26), t.corners(), 'near');
select lives_ok(format($$ select public.clip_delete(%L) $$, t.c(26)), 'a player deletes a clip');
select t.back();
select is((select sum(seconds)::int from public.analysis_usage where owner_id = 'e3000000-0000-0000-0000-000000000010'), 180,
  'and what they used still counts');
update public.app_settings set value = '180' where key = 'analysis.daily_seconds_per_user';
select t.ready(27, 'e3000000-0000-0000-0000-000000000010', 60);
select t.who('e3000000-0000-0000-0000-000000000010');
select throws_ok(format($$ select public.clip_confirm_court(%L, t.corners(), 'near') $$, t.c(27)), 'P0001',
  'You''ve reached today''s limit. Try again tomorrow.', 'so the cap can''t be reset by deleting');
select t.back();
update public.app_settings set value = '600' where key = 'analysis.daily_seconds_per_user';

-- Finding the court is capped too.
update public.app_settings set value = '1' where key = 'analysis.daily_clips';
select t.who('e3000000-0000-0000-0000-000000000010');
select public.clip_create(t.c(28), null, 'mp4', 60, 1000, true) is not null;
select t.back();
select t.file(t.c(28));
select t.who('e3000000-0000-0000-0000-000000000010');
select throws_ok(format($$ select public.clip_uploaded(%L) $$, t.c(28)), 'P0001',
  'You''ve reached today''s limit. Try again tomorrow.', 'sending clips is capped');
select t.back();
update public.app_settings set value = '20' where key = 'analysis.daily_clips';

-- A worker asks whether to carry on.
update public.analysis_jobs set status = 'cancelled' where status = 'queued';
select t.ready(29, 'e3000000-0000-0000-0000-000000000002', 10);
select t.who('e3000000-0000-0000-0000-000000000002');
select public.clip_confirm_court(t.c(29), t.corners(), 'near');
select t.back();
set local role service_role;
select t.claim('go') is not null;
select is(public.analysis_svc_may_continue((t.got('go') ->> 'job_id')::uuid, t.got('go') ->> 'token'), true, 'a live job carries on');
select is(public.analysis_svc_may_continue((t.got('go') ->> 'job_id')::uuid, 'wrong'), false, 'a wrong token doesn''t');
select is(public.analysis_svc_frame_path((t.got('go') ->> 'job_id')::uuid, t.got('go') ->> 'token'), null,
  'an analysis job has no frame to write');
reset role;
update public.feature_flags set enabled = false where key = 'video.analysis';
set local role service_role;
select is(public.analysis_svc_may_continue((t.got('go') ->> 'job_id')::uuid, t.got('go') ->> 'token'), false, 'and neither does a switched-off feature');
select is(public.analysis_svc_claim(), null, 'and nothing new starts');
reset role;
update public.feature_flags set enabled = true where key = 'video.analysis';

-- A file with no live clip goes, however it got there.
insert into storage.objects (bucket_id, name, metadata, created_at)
values ('analysis-clips', 'orphan/orphan.mp4', '{"size": 1}', now() - interval '2 hours');
set local role service_role;
select ok(public.analysis_svc_orphans() >= 1, 'the sweep finds a file with no clip');
select ok(exists (select 1 from jsonb_array_elements(public.analysis_svc_sweep()) x where x ->> 'path' = 'orphan/orphan.mp4'),
  'and queues it');
reset role;

-- ─── Keeping and purging ───────────────────────────────────────────────────

select ok((select purge_at between now() + interval '89 days' and now() + interval '91 days'
  from public.video_clips where id = t.c(12)), 'a clip is kept 90 days');
update public.video_clips set purge_at = now() - interval '1 minute' where id = t.c(1);
set local role service_role;
select ok(public.analysis_svc_sweep() is not null, 'the sweep runs');
reset role;
select ok((select file_gone_at is not null from public.video_clips where id = t.c(1)), 'a clip past 90 days goes');
select ok((select frame = false from public.video_clips where id = t.c(1)), 'with its frame');
select is((select count(*)::int from public.analysis_reports where clip_id = t.c(1)), 1, 'the report stays');
select t.who('e3000000-0000-0000-0000-000000000001');
select is(public.clip_get(t.c(1)) ->> 'frame', null, 'and the frame is no longer offered');
select throws_ok(format($$ select public.clip_extend(%L) $$, t.c(1)), 'P0001', 'This clip has gone.', 'a gone clip can''t be extended');
select lives_ok(format($$ select public.clip_delete(%L) $$, t.c(1)), 'the owner deletes it');
select t.back();
select is((select count(*)::int from public.analysis_reports where clip_id = t.c(1)), 0, 'and the report goes too');

-- The file queue, and removing from it.
select is((select count(*)::int from public.storage_deletions where path like '%' || t.c(12) || '%'), 0, 'a held clip isn''t queued');
delete from auth.users where id = 'e3000000-0000-0000-0000-000000000001';
select is((select count(*)::int from public.video_clips where owner_id = 'e3000000-0000-0000-0000-000000000001'), 0,
  'deleting an account deletes its clips');
select is((select count(*)::int from public.storage_deletions where path like '%' || t.c(12) || '%'), 2,
  'and queues the video and frame, so nothing is left behind');
set local role service_role;
create temp table q on commit drop as select array_agg((x ->> 'id')::bigint) as ids
  from jsonb_array_elements(public.analysis_svc_sweep()) x;
reset role;
grant select on q to service_role;
set local role service_role;
select lives_ok($$ select public.analysis_svc_removed((select ids from q)) $$, 'removed files come off the queue');
reset role;
select t.player('e3000000-0000-0000-0000-000000000001');

-- ─── Staying able to leave ─────────────────────────────────────────────────

select set_config('request.method', 'POST', true);
select set_config('request.jwt.claims', '{"sub": "e3000000-0000-0000-0000-000000000006"}', true);
select set_config('request.path', '/rpc/clip_delete', true);
select lives_ok($$ select private.gate_request() $$, 'a suspended player can delete a clip');
select set_config('request.path', '/rpc/consent_withdraw', true);
select lives_ok($$ select private.gate_request() $$, 'and withdraw');
select set_config('request.path', '/rpc/clip_create', true);
select throws_ok($$ select private.gate_request() $$, 'P0001', 'Your account is suspended.', 'but not add one');
select set_config('request.jwt.claims', '{"sub": "e3000000-0000-0000-0000-000000000005"}', true);
select throws_ok($$ select private.gate_request() $$, 'P0001', 'Ask a parent to link your account first.',
  'and neither can a restricted child');
select set_config('request.path', '/rpc/clip_list', true);
select lives_ok($$ select private.gate_request() $$, 'who can still list');
select set_config('request.path', '', true);
select set_config('request.jwt.claims', '', true);

select is_empty($$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  join private.rate_rules r on r.path = '/rpc/' || p.proname
  where n.nspname = 'public' and (p.proname like 'clip\_%' or p.proname like 'analysis\_%') and p.provolatile <> 'v' $$,
  'no rate-limited function runs read-only');

-- ─── Staff ─────────────────────────────────────────────────────────────────

select t.who('e3000000-0000-0000-0000-000000000007');
select throws_ok($$ select public.staff_analysis_overview() $$, 'P0001', 'Not found.', 'staff need MFA for the monitor');
select t.back();

-- With MFA.
create function t.staff() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', 'e3000000-0000-0000-0000-000000000007',
    'role', 'authenticated', 'aal', 'aal2')::text, true);
  execute 'set local role authenticated';
end;
$$;
grant execute on function t.staff() to authenticated;
select t.staff();
select ok((public.staff_analysis_overview() ->> 'queued') is not null, 'content staff see the monitor');
select is_empty($$ select 1 where public.staff_analysis_overview()::text ~ 'e3000000|\.mp4|\.jpg|Test Player' $$,
  'with no player, path or clip in it');
select throws_ok($$ select public.staff_analysis_retry(gen_random_uuid(), 'too') $$, 'P0001',
  'Only a failed job can be retried.', 'only a failed job can be retried');
select throws_ok($$ select public.staff_analysis_retry(gen_random_uuid(), '') $$, 'P0001', 'Give a reason.', 'with a reason');
select t.back();

-- A withdrawn or gone clip can't be brought back.
insert into public.analysis_jobs (clip_id, kind, status)
values (t.c(24), 'analyse', 'failed') on conflict (clip_id, kind) do update set status = 'failed';
insert into claims select 'retry', jsonb_build_object('id', j.id) from public.analysis_jobs j
where j.clip_id = t.c(24) and j.kind = 'analyse';
select t.staff();
select throws_ok(format($$ select public.staff_analysis_retry(%L, 'try again') $$, t.got('retry') ->> 'id'), 'P0001',
  'This clip can''t be run again.', 'a withdrawn clip can''t be retried');
select t.back();

-- ─── Nothing here touches a rating ─────────────────────────────────────────

select is_empty($$ select t.tgname from pg_trigger t join pg_class c on c.oid = t.tgrelid
  where c.relname in ('analysis_reports', 'analysis_jobs') and not t.tgisinternal $$,
  'nothing fires when a report is saved');
select is_empty($$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname like 'analysis\_svc\_%' and p.prosrc ~* 'ratings|rating_events|passport|points' $$,
  'and the worker''s functions never reach a rating, Passport or points');

select * from finish();
rollback;
