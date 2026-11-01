-- P5-06: the video feed, for every role. Storage and the request gate are proven
-- through the real API in test/supabase_feed_local_test.dart.
begin;
\ir helpers/setup.psql
select no_plan();

select t.player('e4000000-0000-0000-0000-000000000001');  -- adult author
select t.player('e4000000-0000-0000-0000-000000000002');  -- follower
select t.player('e4000000-0000-0000-0000-000000000003');  -- stranger, same country
select t.player('e4000000-0000-0000-0000-000000000004');  -- follower who then blocks
select t.player('e4000000-0000-0000-0000-000000000005', 15);  -- linked teen, follows the author
select t.player('e4000000-0000-0000-0000-000000000006', 40);  -- that teen's parent
select t.player('e4000000-0000-0000-0000-000000000007', 15);  -- restricted teen
select t.player('e4000000-0000-0000-0000-000000000008');  -- suspended adult
select t.player('e4000000-0000-0000-0000-000000000009');  -- staff
select t.player('e4000000-0000-0000-0000-000000000010');  -- adult in another country
select t.player('e4000000-0000-0000-0000-000000000011');  -- a second author, on their first posts
update public.profiles set country_code = 'MY' where id = 'e4000000-0000-0000-0000-000000000010';
insert into public.guardian_links (parent_id, child_id, status)
values ('e4000000-0000-0000-0000-000000000006', 'e4000000-0000-0000-0000-000000000005', 'approved');
insert into public.staff (user_id, role) values ('e4000000-0000-0000-0000-000000000009', 'moderator');
insert into public.account_moderation (user_id, suspended_until)
values ('e4000000-0000-0000-0000-000000000008', now() + interval '1 day');
insert into public.follows (follower_id, followee_id) values
  ('e4000000-0000-0000-0000-000000000002', 'e4000000-0000-0000-0000-000000000001'),
  ('e4000000-0000-0000-0000-000000000004', 'e4000000-0000-0000-0000-000000000001'),
  ('e4000000-0000-0000-0000-000000000005', 'e4000000-0000-0000-0000-000000000001'),
  ('e4000000-0000-0000-0000-000000000007', 'e4000000-0000-0000-0000-000000000001');
update public.feature_flags set enabled = true where key in ('video.feed', 'feed.fake_checks');
update public.app_settings set value = '50' where key = 'feed.daily_posts';
-- Older jobs on a used database would be claimed first.
update public.post_jobs set status = 'done' where status = 'queued';

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

create function t.p(i int) returns uuid language sql immutable as $$
  select ('e4000000-0000-0000-0000-0000000010' || lpad(i::text, 2, '0'))::uuid;
$$;
grant execute on function t.p(int) to authenticated, service_role;

create function t.u(i int) returns uuid language sql immutable as $$
  select ('e4000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid;
$$;
grant execute on function t.u(int) to authenticated, service_role;

create temp table claims (name text primary key, v jsonb) on commit drop;
grant all on claims to service_role;
create function t.got(p_name text) returns jsonb language sql as $$ select v from claims where name = p_name; $$;
grant execute on function t.got(text) to service_role;

create function t.case_of(p_post uuid) returns uuid language sql security definer as $$
  select id from public.moderation_cases where target_kind = 'video' and target_id = p_post::text;
$$;
grant execute on function t.case_of(uuid) to authenticated;

-- Posts as the author, up to the point the file has landed.
create function t.upload(p_post uuid, p_author uuid, p_audience text default 'public') returns void language plpgsql as $$
begin
  perform t.who(p_author);
  perform public.post_create(p_post, 'mp4', 20, 1000, 'Smash practice', 'badminton', p_audience, true);
  perform t.back();
  insert into storage.objects (bucket_id, name, metadata)
  values ('feed-videos', p_author::text || '/' || p_post::text || '.mp4', '{"size": 1000}');
  perform t.who(p_author);
  perform public.post_uploaded(p_post);
  perform t.back();
end;
$$;

create function t.verdict(p_hash text default 'clear', p_frames text default 'clear') returns text language plpgsql as $$
declare
  j jsonb;
  r text;
begin
  execute 'set local role service_role';
  j := public.feed_svc_claim();
  r := public.feed_svc_result((j ->> 'job_id')::uuid, j ->> 'token', true, p_hash, p_frames, 'local-fake', null, true, null, 2);
  execute 'reset role';
  return r;
end;
$$;

-- This author is past their first posts.
create function t.trusted(p_author uuid) returns void language sql as $$
  insert into public.video_posts (id, author_id, sport, country_code, ext, seconds, bytes, status, video_ref,
    hash_cleared_at, approved_at, live_at, no_minors_at)
  select gen_random_uuid(), p_author, 'badminton', 'SG', 'mp4', 5, 10, 'live', 'old/' || n, now(), now(), now() - interval '1 day', now()
  from generate_series(1, 3) n;
$$;

-- ─── No direct access ──────────────────────────────────────────────────────

select t.who(t.u(1));
select throws_ok($$ select * from public.video_posts $$, '42501', null, 'a player can''t read posts directly');
select throws_ok($$ select * from public.post_likes $$, '42501', null, 'or likes');
select throws_ok($$ select * from public.post_jobs $$, '42501', null, 'or jobs');
select throws_ok($$ select * from public.abuse_matches $$, '42501', null, 'or matches');
select throws_ok($$ insert into public.post_likes (post_id, user_id) values (gen_random_uuid(), auth.uid()) $$, '42501', null, 'or like directly');
select throws_ok($$ select public.feed_svc_claim() $$, '42501', null, 'or claim a job');
select throws_ok($$ select public.feed_svc_sweep() $$, '42501', null, 'or sweep');
select throws_ok($$ select public.feed_svc_result(gen_random_uuid(), 'x', true, 'clear', 'clear', 'c', null, false, null, 1) $$,
  '42501', null, 'or send a verdict');
select throws_ok($$ select public.staff_post_queue() $$, 'P0001', null, 'or see the staff queue');
select throws_ok($$ select public.staff_post_decide(gen_random_uuid(), 'live', 'x') $$, 'P0001', null, 'or decide a post');
select throws_ok($$ select public.staff_post_play(gen_random_uuid()) $$, 'P0001', null, 'or use the staff player');
select t.back();

select t.as_anon();
select throws_ok($$ select public.feed_status() $$, '42501', null, 'someone signed out can''t ask');
select throws_ok($$ select public.feed_following() $$, '42501', null, 'or read a list');
select throws_ok($$ select public.feed_discover() $$, '42501', null, 'or Discover');
select throws_ok($$ select public.post_play(gen_random_uuid()) $$, '42501', null, 'or play');
select t.back();

select is_empty($$ select b.id from storage.buckets b where b.id = 'feed-videos' and b.public $$, 'the bucket is private');
select is_empty($$ select 1 from pg_policies where tablename = 'objects' and schemaname = 'storage'
  and coalesce(qual, '') || coalesce(with_check, '') like '%feed-videos%' $$, 'and no policy lets a client near it');
select is_empty($$ select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relname in ('video_posts', 'post_likes', 'post_jobs', 'abuse_matches') and not c.relrowsecurity $$,
  'every feed table has RLS on');

-- ─── Who can post ──────────────────────────────────────────────────────────

select t.who(t.u(5));
select throws_like($$ select public.post_create(t.p(90), 'mp4', 20, 1000, '', 'badminton', 'public', true) $$,
  'Posting is for adults%', 'a teen can''t post');
select is(public.feed_status() ->> 'can_post', 'false', 'and isn''t offered it');
select is(public.feed_status() ->> 'can_discover', 'false', 'or Discover');
select is(public.feed_status() ->> 'open', 'true', 'but does get the feed');
select t.back();

select t.who(t.u(7));
select throws_like($$ select public.post_create(t.p(90), 'mp4', 20, 1000, '', 'badminton', 'public', true) $$,
  'Ask a parent%', 'a restricted child can''t post');
select is(public.feed_status() ->> 'open', 'false', 'and has no feed');
select t.back();

select t.who(t.u(8));
select throws_like($$ select public.post_create(t.p(90), 'mp4', 20, 1000, '', 'badminton', 'public', true) $$,
  '%suspended%', 'a suspended adult can''t post');
select t.back();

select t.who(t.u(1));
select throws_like($$ select public.post_create(t.p(90), 'mp4', 20, 1000, '', 'badminton', 'public', false) $$,
  'Check that no one under 18%', 'posting needs the tick');
select throws_like($$ select public.post_create(t.p(90), 'mp4', 20, 1000, '', 'badminton', 'public', null) $$,
  'Check that no one under 18%', 'and a missing tick isn''t a tick');
select throws_like($$ select public.post_create(t.p(90), 'mp4', 61, 1000, '', 'badminton', 'public', true) $$,
  'That video is too long%', 'over the length limit is refused');
select throws_like($$ select public.post_create(t.p(90), 'mp4', 20, 104857601, '', 'badminton', 'public', true) $$,
  'That video is too big%', 'and over the size limit');
select throws_like($$ select public.post_create(t.p(90), 'avi', 20, 1000, '', 'badminton', 'public', true) $$,
  'Choose an MP4%', 'and another format');
select throws_like($$ select public.post_create(t.p(90), 'mp4', 20, 1000, '', 'badminton', 'everyone', true) $$,
  'Choose who%', 'and an unknown audience');
select throws_like($$ select public.post_create(t.p(90), 'mp4', 20, 1000, 'call me on 91234567', 'badminton', 'public', true) $$,
  'Keep phone numbers%', 'a caption goes through the text check');
select t.back();

update public.feature_flags set enabled = false where key = 'video.feed';
select t.who(t.u(1));
select throws_like($$ select public.post_create(t.p(90), 'mp4', 20, 1000, '', 'badminton', 'public', true) $$,
  'Videos are not open%', 'with the flag off nobody posts');
select throws_like($$ select public.feed_following() $$, 'Videos are not open%', 'or reads');
select t.back();
set local role service_role;
select is(public.feed_svc_claim(), null, 'and no job runs');
reset role;
update public.feature_flags set enabled = true where key = 'video.feed';

-- A retry reaches the same post, and someone else's id gets nowhere.
select t.who(t.u(1));
select is(public.post_create(t.p(1), 'mp4', 20, 1000, 'One', 'badminton', 'public', true) ->> 'status', 'waiting', 'a post starts waiting');
select is(public.post_create(t.p(1), 'mp4', 20, 1000, 'One', 'badminton', 'public', true) ->> 'status', 'waiting', 'a retry is the same post');
select is(public.post_upload_target(t.p(1)) ->> 'ref', t.u(1)::text || '/' || t.p(1) || '.mp4', 'the file''s path comes from the server');
select throws_like($$ select public.post_uploaded(t.p(1)) $$, 'The upload didn''t finish%', 'no file, no checks');
select t.back();
select t.who(t.u(2));
select throws_like($$ select public.post_create(t.p(1), 'mp4', 20, 1000, 'Mine', 'badminton', 'public', true) $$,
  'This post can''t be added%', 'someone else''s id gets nowhere');
select throws_like($$ select public.post_upload_target(t.p(1)) $$, 'This post can''t be uploaded%', 'or a place to upload');
select throws_like($$ select public.post_uploaded(t.p(1)) $$, 'Post not found%', 'or finishes it');
select t.back();
select is((select country_code from public.video_posts where id = t.p(1)), 'SG', 'the server sets the country');

-- ─── States ────────────────────────────────────────────────────────────────

select throws_like($$ update public.video_posts set status = 'live', hash_cleared_at = now() where id = t.p(1) $$,
  'A post can''t go from waiting to live%', 'a post can''t skip its checks');
select throws_ok($$ insert into public.video_posts (id, author_id, sport, country_code, ext, seconds, bytes, status, video_ref, no_minors_at)
  values (t.p(91), t.u(1), 'badminton', 'SG', 'mp4', 1, 1, 'live', 'x', now()) $$, '23514', null, 'nothing is live without a hash pass');
select throws_ok($$ insert into public.video_posts (id, author_id, sport, country_code, ext, seconds, bytes, status, video_ref, no_minors_at)
  values (t.p(91), t.u(1), 'badminton', 'SG', 'mp4', 1, 1, 'review', 'x', now()) $$, '23514', null, 'or in review');
select throws_like($$ update public.video_posts set video_ref = 'x' where id = t.p(1) $$, 'A post''s identity%', 'a post''s file can''t change');

-- The first posts go to a person, whatever the frames said.
select t.upload(t.p(2), t.u(11));
select is((select status from public.video_posts where id = t.p(2)), 'checking', 'an uploaded post is being checked');
select is(t.verdict(), 'review', 'a clean first post goes to a person');
select t.who(t.u(2));
select throws_like($$ select public.post_play(t.p(2)) $$, 'This video isn''t available%', 'and nobody else can play it yet');
select t.back();
select t.who(t.u(11));
select is(public.post_play(t.p(2)) ->> 'ref', t.u(11)::text || '/' || t.p(2) || '.mp4', 'but its author can');
select is((public.post_mine() -> 0 ->> 'status'), 'review', 'and sees where it stands');
select t.back();

select t.trusted(t.u(1));
select t.upload(t.p(3), t.u(1));
select is(t.verdict(), 'live', 'past the first posts, a clean post goes live');
select t.upload(t.p(4), t.u(1));
select is(t.verdict('clear', 'flag'), 'review', 'a flag goes to a person');
select is((select flagged from public.video_posts where id = t.p(4)), true, 'marked as flagged');
select t.upload(t.p(5), t.u(1));
select is(t.verdict('clear', 'reject'), 'rejected', 'failed frames reject it');
select is((select poster from public.video_posts where id = t.p(5)), false, 'with no poster');

-- A bad result changes nothing, and the fake can't pass a post when it's off.
select t.upload(t.p(6), t.u(1));
set local role service_role;
insert into claims values ('one', public.feed_svc_claim());
select ok(t.got('one') ->> 'ref' is not null, 'a worker gets the file''s ref');
select ok(not t.got('one') ? 'author_id' and not t.got('one') ? 'caption', 'and nothing about the person');
select throws_like($$ select public.feed_svc_result((t.got('one') ->> 'job_id')::uuid, 'wrong', true, 'clear', 'clear', 'real', null, false, null, 1) $$,
  'Bad token%', 'a wrong token is refused');
select throws_like($$ select public.feed_svc_result((t.got('one') ->> 'job_id')::uuid, t.got('one') ->> 'token', true, 'maybe', 'clear', 'real', null, false, null, 1) $$,
  'Bad result%', 'an unknown verdict is refused');
select throws_like($$ select public.feed_svc_result((t.got('one') ->> 'job_id')::uuid, t.got('one') ->> 'token', true, 'clear', 'clear', '', null, false, null, 1) $$,
  'Bad result%', 'a verdict from nobody is refused');
reset role;
update public.feature_flags set enabled = false where key = 'feed.fake_checks';
set local role service_role;
select throws_like($$ select public.feed_svc_result((t.got('one') ->> 'job_id')::uuid, t.got('one') ->> 'token', true, 'clear', 'clear', 'local-fake', null, false, null, 1) $$,
  'Bad result%', 'the fake checker is refused unless it''s switched on');
select is(public.feed_svc_job((t.got('one') ->> 'job_id')::uuid, 'wrong'), null, 'a wrong token gets no poster path');
select ok(public.feed_svc_job((t.got('one') ->> 'job_id')::uuid, t.got('one') ->> 'token') is not null, 'the right one does');

-- Checks that couldn't finish never let a post through.
select is(public.feed_svc_result((t.got('one') ->> 'job_id')::uuid, t.got('one') ->> 'token', false, null, null, null, null, false, 'no_provider', 1),
  'retry', 'a failed check tries again');
reset role;
select is((select status from public.video_posts where id = t.p(6)), 'checking', 'and the post still waits');
set local role service_role;
insert into claims values ('two', public.feed_svc_claim());
select is(public.feed_svc_result((t.got('two') ->> 'job_id')::uuid, t.got('two') ->> 'token', false, null, null, null, null, false, 'no_provider', 1), 'retry', 'twice');
insert into claims values ('three', public.feed_svc_claim());
select is(public.feed_svc_result((t.got('three') ->> 'job_id')::uuid, t.got('three') ->> 'token', false, null, null, null, null, false, 'no_provider', 1), 'failed', 'then fails');
select is(public.feed_svc_result((t.got('three') ->> 'job_id')::uuid, t.got('three') ->> 'token', true, 'clear', 'clear', 'real', null, false, null, 1), 'failed', 'and a replay changes nothing');
reset role;
select is((select status from public.video_posts where id = t.p(6)), 'failed', 'failed, not live and not in review');
select t.who(t.u(2));
select throws_like($$ select public.post_retry(t.p(6)) $$, 'Post not found%', 'only the author can retry');
select t.back();
select t.who(t.u(1));
select lives_ok($$ select public.post_retry(t.p(6)) $$, 'the author can');
select t.back();
update public.feature_flags set enabled = true where key = 'feed.fake_checks';
select is(t.verdict(), 'live', 'and it still has to pass');

-- A timeout goes round again, then fails.
select t.upload(t.p(7), t.u(1));
set local role service_role;
insert into claims values ('slow', public.feed_svc_claim());
reset role;
update public.post_jobs set deadline = now() - interval '1 minute' where post_id = t.p(7);
set local role service_role;
select throws_like($$ select public.feed_svc_result((t.got('slow') ->> 'job_id')::uuid, t.got('slow') ->> 'token', true, 'clear', 'clear', 'real', null, false, null, 1) $$,
  'Bad token%', 'an expired token is refused');
select ok(public.feed_svc_sweep() is not null, 'the sweep runs');
reset role;
select is((select status from public.post_jobs where post_id = t.p(7)), 'queued', 'a timed-out job goes back in the queue');
update public.post_jobs set attempts = 3, status = 'claimed', deadline = now() - interval '1 minute' where post_id = t.p(7);
set local role service_role;
select ok(public.feed_svc_sweep() is not null, 'the sweep runs again');
reset role;
select is((select status from public.video_posts where id = t.p(7)), 'failed', 'and after the last try the post fails');

-- ─── Who sees what ─────────────────────────────────────────────────────────

select t.upload(t.p(10), t.u(1), 'public');
select t.verdict();
select t.upload(t.p(11), t.u(1), 'followers');
select t.verdict();

create function t.ids(p jsonb) returns uuid[] language sql as $$
  select coalesce(array_agg((x ->> 'id')::uuid), '{}') from jsonb_array_elements(p) x;
$$;
grant execute on function t.ids(jsonb) to authenticated;

select t.who(t.u(2));
select ok(t.p(10) = any (t.ids(public.feed_following())) and t.p(11) = any (t.ids(public.feed_following())), 'a follower sees public and followers-only posts');
select ok(t.p(10) = any (t.ids(public.feed_discover())), 'a public post is in Discover');
select ok(not t.p(11) = any (t.ids(public.feed_discover())), 'a followers-only post isn''t');
select lives_ok($$ select public.post_like(t.p(11)) $$, 'a follower can like');
select lives_ok($$ select public.post_like(t.p(11)) $$, 'twice');
select is((select (x ->> 'likes')::int from jsonb_array_elements(public.feed_following()) x where (x ->> 'id')::uuid = t.p(11)), 1, 'and it counts once');
select is(public.post_play(t.p(11)) ->> 'host', 'storage', 'a follower can play');
select t.back();

select t.who(t.u(3));
select is_empty($$ select 1 from jsonb_array_elements(public.feed_following()) $$, 'a stranger''s Following is empty');
select ok(t.p(10) = any (t.ids(public.feed_discover())), 'but they find public posts');
select ok(not t.p(11) = any (t.ids(public.feed_discover())), 'not followers-only ones');
select throws_like($$ select public.post_play(t.p(11)) $$, 'This video isn''t available%', 'or play one');
select throws_like($$ select public.post_like(t.p(11)) $$, 'This video isn''t available%', 'or like one');
select lives_ok($$ select public.post_like(t.p(10)) $$, 'but can like a public one');
select t.back();

select t.who(t.u(10));
select ok(not t.p(10) = any (t.ids(public.feed_discover())), 'Discover stays in your country');
select t.back();

insert into public.player_sports (user_id, sport, level, play_min, play_max) values (t.u(3), 'tennis', 3, 2, 4);
select t.who(t.u(3));
select ok(not t.p(10) = any (t.ids(public.feed_discover())), 'and your sports');
select t.back();
delete from public.player_sports where user_id = t.u(3);

-- Teens: following only.
select t.who(t.u(5));
select ok(t.p(11) = any (t.ids(public.feed_following())), 'a teen sees who they follow');
select throws_like($$ select public.feed_discover() $$, 'Discover is for adults%', 'a teen can''t reach Discover');
select t.back();
select t.upload(t.p(12), t.u(3), 'public');
select t.verdict();
update public.video_posts set status = 'live', approved_at = now(), live_at = now() where id = t.p(12);
select t.who(t.u(5));
select throws_like($$ select public.post_play(t.p(12)) $$, 'This video isn''t available%', 'or play a public post from someone they don''t follow');
select throws_like($$ select public.post_like(t.p(12)) $$, 'This video isn''t available%', 'or like one');
select is(public.post_posters(array[t.p(12)]), '{}'::jsonb, 'or get its poster');
select t.back();

-- Restricted children: nothing, though they follow the author.
select t.who(t.u(7));
select throws_like($$ select public.feed_following() $$, 'Ask a parent%', 'a restricted child can''t read Following');
select throws_like($$ select public.feed_discover() $$, 'Ask a parent%', 'or Discover');
select throws_like($$ select public.post_play(t.p(10)) $$, 'Ask a parent%', 'or play');
select throws_like($$ select public.post_like(t.p(10)) $$, 'Ask a parent%', 'or like');
select throws_like($$ select public.post_posters(array[t.p(10)]) $$, 'Ask a parent%', 'or see a poster');
select is(public.post_mine(), '[]'::jsonb, 'but own posts still answer');
select t.back();

select t.who(t.u(8));
select throws_like($$ select public.feed_following() $$, '%suspended%', 'a suspended adult can''t read');
select t.back();

-- Blocks work both ways.
insert into public.blocks (blocker_id, blocked_id) values (t.u(4), t.u(1));
select t.who(t.u(4));
select ok(not t.p(11) = any (t.ids(public.feed_following())), 'a blocker no longer sees the author');
select throws_like($$ select public.post_play(t.p(11)) $$, 'This video isn''t available%', 'or plays them');
select t.back();
insert into public.follows (follower_id, followee_id) values (t.u(3), t.u(1)) on conflict do nothing;
insert into public.blocks (blocker_id, blocked_id) values (t.u(1), t.u(3));
select t.who(t.u(3));
select ok(not t.p(10) = any (t.ids(public.feed_discover())), 'and someone the author blocked sees nothing either');
select t.back();
delete from public.blocks where blocked_id = t.u(3);
delete from public.follows where follower_id = t.u(3) and followee_id = t.u(1);

-- Authors who've gone quiet disappear with their posts.
update public.profiles set visibility = 'only_me' where id = t.u(1);
select t.who(t.u(2));
select ok(not t.p(10) = any (t.ids(public.feed_following())), 'an only-me author leaves the feed');
select t.back();
update public.profiles set visibility = 'followers' where id = t.u(1);
insert into public.account_moderation (user_id, suspended_until) values (t.u(1), now() + interval '1 day');
select t.who(t.u(2));
select ok(not t.p(10) = any (t.ids(public.feed_following())), 'and a suspended author');
select t.back();
delete from public.account_moderation where user_id = t.u(1);

-- A person only ever sees a file that passed the hash match.
select t.upload(t.p(16), t.u(11));
select t.who(t.u(11));
select throws_ok(format($$ insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values (auth.uid(), 'video', %L, 'Harmful') $$, t.p(16)), '42501', null, 'an unchecked post can''t be reported into a person''s view');
select t.back();
insert into public.moderation_cases (target_kind, target_id, deadline_at) values ('video', t.p(16)::text, now() + interval '1 day');
select t.as_staff(t.u(9));
select throws_like($$ select public.staff_post_play(t.p(16)) $$, 'This video can''t be played%', 'and staff can''t play one, case or no case');
select t.back();
delete from public.moderation_cases where target_id = t.p(16)::text;
select t.verdict();

-- The file that passed is the file that plays.
update storage.objects set version = 'first' where bucket_id = 'feed-videos' and name like '%' || t.p(11) || '%';
update public.video_posts set file_version = 'first' where id = t.p(11);
update storage.objects set version = 'swapped' where bucket_id = 'feed-videos' and name like '%' || t.p(11) || '%';
select t.who(t.u(2));
select throws_like($$ select public.post_play(t.p(11)) $$, 'This video isn''t available%', 'a swapped file doesn''t play');
select t.back();
update storage.objects set version = 'first' where bucket_id = 'feed-videos' and name like '%' || t.p(11) || '%';

-- Lists end, with no cursor to carry on.
update public.app_settings set value = '1' where key = 'feed.list_length';
select t.who(t.u(2));
select is(jsonb_array_length(public.feed_following()), 1, 'a list stops at its length');
select t.back();
update public.app_settings set value = '50' where key = 'feed.list_length';
select is((select pronargs::int from pg_proc where proname = 'feed_following'), 0, 'and takes no cursor');
select is((select pronargs::int from pg_proc where proname = 'feed_discover'), 0, 'in either tab');

-- ─── Reports ───────────────────────────────────────────────────────────────

select t.who(t.u(2));
select throws_ok($$ insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values (auth.uid(), 'video', gen_random_uuid()::text, 'Harmful') $$, '42501', null, 'a report needs a real post');
select lives_ok(format($$ insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values (auth.uid(), 'video', %L, 'Harmful') $$, t.p(10)), 'a real post can be reported');
select t.back();
select is((select owner_id from public.moderation_cases where target_kind = 'video' and target_id = t.p(10)::text), t.u(1), 'the case knows the author');
select t.who(t.u(10));
select lives_ok(format($$ insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values (auth.uid(), 'video', %L, 'Harmful') $$, t.p(10)), 'a second report');
select t.back();
select is((select hidden_at from public.video_posts where id = t.p(10)), null, 'two reports don''t hide a post');
select t.who(t.u(5));
select lives_ok(format($$ insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values (auth.uid(), 'video', %L, 'Harmful') $$, t.p(10)), 'a third report, from a teen');
select t.back();
select ok((select hidden_at from public.video_posts where id = t.p(10)) is not null, 'three reporters hide it');
select is((select involves_child from public.moderation_cases where target_id = t.p(10)::text), true, 'and a child''s report marks the case');
select t.who(t.u(2));
select ok(not t.p(10) = any (t.ids(public.feed_following())), 'a hidden post leaves the feed');
select throws_like($$ select public.post_play(t.p(10)) $$, 'This video isn''t available%', 'and can''t be played');
select t.back();
select t.who(t.u(1));
select is((select x ->> 'status' from jsonb_array_elements(public.post_mine()) x where (x ->> 'id')::uuid = t.p(10)), 'removed', 'its author sees it''s down');
select t.back();

-- ─── Staff ─────────────────────────────────────────────────────────────────

select t.as_staff(t.u(9));
select ok(t.p(2) = any (t.ids(public.staff_post_queue())), 'a moderator sees first posts');
select is((select x ->> 'caption' from jsonb_array_elements(public.staff_post_queue()) x where (x ->> 'id')::uuid = t.p(2)), 'Smash practice', 'with the caption');
select ok(not (public.staff_post_queue() -> 0 ? 'author_id'), 'not the person');
select is(public.staff_post_play(t.p(2)) ->> 'ref', t.u(11)::text || '/' || t.p(2) || '.mp4', 'and can play one');
select throws_like($$ select public.staff_post_play(t.p(3)) $$, 'This video can''t be played%', 'but not a live post nobody reported');
select throws_like($$ select public.staff_post_decide(t.p(2), 'live', '') $$, 'Give a reason%', 'a decision needs a reason');
select lives_ok($$ select public.staff_post_decide(t.p(2), 'live', 'Fine') $$, 'approving works');
select throws_like($$ select public.staff_post_decide(t.p(2), 'rejected', 'Late') $$, 'This post has already%', 'and it''s decided once');
select t.back();
select is((select count(*)::int from public.admin_audit where target_id = t.p(2)::text and action = 'post_viewed'), 1, 'every look is audited');
select is((select count(*)::int from public.admin_audit where target_id = t.p(2)::text and action = 'post_live'), 1, 'and every decision');
select ok((select approved_at from public.video_posts where id = t.p(2)) is not null, 'the approval counts towards the first posts');

select t.upload(t.p(13), t.u(11));
select t.verdict();
select t.as_staff(t.u(9));
select lives_ok($$ select public.staff_post_decide(t.p(13), 'rejected', 'Not sport') $$, 'rejecting works');
select t.back();
select is((select count(*)::int from public.content_removals where user_id = t.u(11) and why = 'Not sport'), 1, 'and tells the author');

-- Staff don't decide their own.
select t.upload(t.p(14), t.u(9));
select t.verdict();
select t.as_staff(t.u(9));
select ok(not t.p(14) = any (t.ids(public.staff_post_queue())), 'a moderator''s own post isn''t in their queue');
select throws_like($$ select public.staff_post_decide(t.p(14), 'live', 'Mine') $$, 'Someone else has to%', 'and they can''t pass it');
select t.back();

-- Or their own case.
insert into public.moderation_cases (target_kind, target_id, owner_id, deadline_at)
values ('video', t.p(14)::text, t.u(9), now() + interval '1 day');
select t.as_staff(t.u(9));
select throws_like($$ select public.staff_case_decide(t.case_of(t.p(14)), 'kept', 'Mine') $$, 'Someone else has to decide your own case%', 'or keep a case on their own post');
select t.back();

-- Three approvals, then the checks decide.
update public.video_posts set approved_at = now() where id in (t.p(2));
insert into public.video_posts (id, author_id, sport, country_code, ext, seconds, bytes, status, video_ref, hash_cleared_at, approved_at, live_at, no_minors_at)
select gen_random_uuid(), t.u(11), 'badminton', 'SG', 'mp4', 5, 10, 'live', 'older/' || n, now(), now(), now(), now() from generate_series(1, 2) n;
select t.upload(t.p(15), t.u(11));
select is(t.verdict(), 'live', 'after three approvals a clean post goes live');

-- A case on a video, kept and removed.
select t.as_staff(t.u(9));
select is(public.staff_post_play(t.p(10)) ->> 'host', 'storage', 'a moderator can play a reported post');
select is((public.staff_case_get(t.case_of(t.p(10))) ->> 'text'), 'Smash practice', 'the case shows the caption');
select lives_ok($$ select public.staff_case_decide(t.case_of(t.p(10)), 'kept', 'Fine') $$, 'keeping a case');
select t.back();
select is((select hidden_at from public.video_posts where id = t.p(10)), null, 'puts the post back');

-- ─── Abuse matches ─────────────────────────────────────────────────────────

select t.upload(t.p(20), t.u(1));
select is(t.verdict('match'), 'blocked', 'a match blocks the post');
select is((select count(*)::int from public.abuse_matches where post_id = t.p(20)), 1, 'and records it');
select is((select owner_id from public.moderation_cases where target_id = t.p(20)::text), null, 'the case names nobody');
select is((select involves_child from public.moderation_cases where target_id = t.p(20)::text), true, 'and is a child-safety case');
select is((select count(*)::int from public.content_removals where user_id = t.u(1)), 0, 'nothing tells the author');
select t.who(t.u(1));
select is((select x ->> 'status' from jsonb_array_elements(public.post_mine()) x where (x ->> 'id')::uuid = t.p(20)), 'rejected', 'and it reads as a plain rejection');
select throws_like($$ select public.post_play(t.p(20)) $$, 'This video isn''t available%', 'the author can''t play it');
select lives_ok($$ select public.post_delete(t.p(20)) $$, 'deleting clears it from their list');
select is((select count(*)::int from jsonb_array_elements(public.post_mine()) x where (x ->> 'id')::uuid = t.p(20)), 0, 'and it''s gone from there');
select t.back();
select is((select status from public.video_posts where id = t.p(20)), 'blocked', 'but stays blocked');
select t.as_staff(t.u(9));
select throws_like($$ select public.staff_post_play(t.p(20)) $$, 'This video can''t be played%', 'staff can''t play a match');
select lives_ok($$ select public.staff_case_decide(t.case_of(t.p(20)), 'kept', 'Mistake') $$, 'keeping the case');
select t.back();
select is((select status from public.video_posts where id = t.p(20)), 'blocked', 'doesn''t bring the post back');
select ok((select hidden_at from public.video_posts where id = t.p(20)) is not null, 'it stays hidden');
select throws_like($$ update public.abuse_matches set matcher = 'x' where post_id = t.p(20) $$, 'A match can''t change%', 'a match can''t be edited');
select throws_like($$ delete from public.abuse_matches where post_id = t.p(20) $$, 'A match can''t change%', 'or removed');

-- Nothing about a match reaches its author by another door.
select t.upload(t.p(24), t.u(3));
select is(t.verdict('match'), 'blocked', 'another match');
select t.who(t.u(3));
select is((public.post_create(t.p(24), 'mp4', 20, 1000, '', 'badminton', 'public', true) ->> 'status'), 'rejected', 'a retry says rejected, not blocked');
select t.back();
select t.as_staff(t.u(9));
select is(public.staff_case_get(t.case_of(t.p(24))) ->> 'text', 'Blocked video', 'staff see no caption on a match');
select t.back();
update public.video_posts set created_at = now() - interval '31 days' where id = t.p(24);
select t.who(t.u(3));
select is((select count(*)::int from jsonb_array_elements(public.post_mine()) x where (x ->> 'id')::uuid = t.p(24)), 0, 'and it leaves My posts when a rejection would');
select t.back();

-- After a match, that author's posts go to a person.
select t.upload(t.p(21), t.u(1));
select is(t.verdict(), 'review', 'an author with a match goes back to review');

-- A video deleted during its check still gets the verdict.
select t.upload(t.p(22), t.u(3));
select t.who(t.u(3));
select lives_ok($$ select public.post_delete(t.p(22)) $$, 'deleting mid-check is allowed');
select is((public.post_create(t.p(22), 'mp4', 20, 1000, '', 'badminton', 'public', true) ->> 'status'), 'deleted', 'a retry says deleted');
select t.back();
set local role service_role;
select ok(public.feed_svc_sweep() is not null, 'the sweep runs');
reset role;
select is((select count(*)::int from public.video_posts where id = t.p(22)), 1, 'and the post stays while its check is open');
select is(t.verdict('match'), 'blocked', 'a late match still lands');
select is((select status from public.video_posts where id = t.p(22)), 'blocked', 'on a deleted post');
select t.who(t.u(3));
select is((select count(*)::int from jsonb_array_elements(public.post_mine()) x where (x ->> 'id')::uuid = t.p(22)), 0, 'and it stays out of My posts');
select is((public.post_create(t.p(22), 'mp4', 20, 1000, '', 'badminton', 'public', true) ->> 'status'), 'deleted', 'and a retry still says deleted');
select t.back();
select t.upload(t.p(23), t.u(3));
select t.who(t.u(3));
select lives_ok($$ select public.post_delete(t.p(23)) $$, 'deleting another');
select t.back();
select is(t.verdict(), 'deleted', 'a clean verdict leaves it deleted');
select throws_like($$ update public.video_posts set status = 'live' where id = t.p(23) $$, 'A post can''t go from deleted to live%', 'and it can''t come back');

-- ─── Deleting ──────────────────────────────────────────────────────────────

delete from public.storage_deletions where bucket = 'feed-videos';
set local role service_role;
select ok(public.feed_svc_sweep() is not null, 'the sweep runs');
reset role;
select is((select count(*)::int from public.video_posts where id = t.p(23)), 0, 'a finished deleted post goes');
select is((select count(*)::int from public.storage_deletions where bucket = 'feed-videos' and path like '%' || t.p(23) || '%'), 2, 'and queues its video and poster');
select is((select count(*)::int from public.video_posts where id = t.p(22)), 1, 'a blocked post stays');

select t.who(t.u(2));
select throws_like($$ select public.post_delete(t.p(3)) $$, 'Post not found%', 'someone else can''t delete a post');
select t.back();

-- A reported post waits for its case.
select t.who(t.u(1));
select lives_ok($$ select public.post_delete(t.p(3)) $$, 'an author deletes a live post');
select t.back();
insert into public.moderation_cases (target_kind, target_id, owner_id, deadline_at)
values ('video', t.p(3)::text, t.u(1), now() + interval '1 day') on conflict (target_kind, target_id) do update set status = 'open';
set local role service_role;
select ok(public.feed_svc_sweep() is not null, 'the sweep runs');
reset role;
select is((select count(*)::int from public.video_posts where id = t.p(3)), 1, 'an open case keeps it');
select t.who(t.u(2));
select throws_like($$ select public.post_play(t.p(3)) $$, 'This video isn''t available%', 'though nobody can play it');
select t.back();

-- Unfinished uploads and old rejections clear themselves.
select t.who(t.u(3));
select ok(public.post_create(t.p(30), 'mp4', 20, 1000, '', 'badminton', 'public', true) is not null, 'a post that never uploads');
select t.back();
update public.video_posts set created_at = now() - interval '2 days' where id = t.p(30);
update public.video_posts set created_at = now() - interval '31 days' where id = t.p(5);
set local role service_role;
select ok(public.feed_svc_sweep() is not null, 'the sweep runs');
reset role;
select is((select count(*)::int from public.video_posts where id in (t.p(30), t.p(5))), 0, 'goes, with a rejected post past its time');

-- A used id stays spent.
select t.who(t.u(1));
select t.back();
delete from public.video_posts where id = t.p(3);
select t.who(t.u(1));
select throws_like($$ select public.post_create(t.p(3), 'mp4', 20, 1000, '', 'badminton', 'public', true) $$,
  'This post can''t be added%', 'an id with a case can''t come back');
select t.back();

-- A deleted post whose checks failed tries again rather than going unchecked.
select t.upload(t.p(33), t.u(3));
select t.who(t.u(3));
select lives_ok($$ select public.post_delete(t.p(33)) $$, 'deleted before its check');
select t.back();
update public.post_jobs set status = 'failed', finished_at = now() where post_id = t.p(33);
set local role service_role;
select ok(public.feed_svc_sweep() is not null, 'the sweep runs');
reset role;
select is((select status from public.post_jobs where post_id = t.p(33)), 'queued', 'and its check goes round again');
select is((select count(*)::int from public.video_posts where id = t.p(33)), 1, 'with the post still there');
update public.video_posts set created_at = now() - interval '31 days' where id = t.p(33);
set local role service_role;
select ok(public.feed_svc_sweep() is not null, 'the sweep runs');
reset role;
select is((select count(*)::int from public.video_posts where id = t.p(33)), 0, 'until its time runs out');

-- A file with no post goes. One tied to a match doesn't.
insert into storage.objects (bucket_id, name, metadata, created_at) values
  ('feed-videos', 'stray/' || gen_random_uuid() || '.mp4', '{"size": 1}', now() - interval '2 hours');
delete from public.storage_deletions where bucket = 'feed-videos';
delete from public.video_posts where id = t.p(20);
insert into storage.objects (bucket_id, name, metadata, created_at)
values ('feed-videos', t.u(1) || '/' || t.p(20) || '.poster.jpg', '{"size": 1}', now() - interval '2 hours');
update storage.objects set created_at = now() - interval '2 hours' where bucket_id = 'feed-videos';
set local role service_role;
select ok(public.feed_svc_sweep() >= 1, 'the safety net finds a stray file');
reset role;
select ok(exists (select 1 from public.storage_deletions where bucket = 'feed-videos' and path like 'stray/%'), 'and queues it');
select is((select count(*)::int from public.storage_deletions where path like '%' || t.p(20) || '%'), 0, 'a matched file stays, even with its post gone');
select is((select count(*)::int from public.abuse_matches where post_id = t.p(20)), 1, 'and the match outlives it');

-- Deleting an account takes its posts and likes.
select is((select count(*)::int from public.post_likes where user_id = t.u(2)), 1, 'a like is there');
select t.upload(t.p(31), t.u(10));
delete from public.storage_deletions where bucket = 'feed-videos';
delete from auth.users where id = t.u(10);
select is((select count(*)::int from public.video_posts where id = t.p(31)), 0, 'deleting an account deletes its posts');
select is((select count(*)::int from public.storage_deletions where path like '%' || t.p(31) || '%'), 2, 'and queues the files');
delete from auth.users where id = t.u(2);
select is((select count(*)::int from public.post_likes where user_id = t.u(2)), 0, 'and its likes');

-- The daily limit counts.
update public.app_settings set value = '0' where key = 'feed.daily_posts';
select t.who(t.u(3));
select throws_like($$ select public.post_create(t.p(32), 'mp4', 20, 1000, '', 'badminton', 'public', true) $$,
  'That''s all your posts%', 'a daily limit holds');
select t.back();

-- Every feed function keeps out those it should.
select is_empty($$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and (p.proname like 'post\_%' or p.proname like 'feed\_%' or p.proname like 'staff\_post\_%')
    and has_function_privilege('anon', p.oid, 'execute') $$, 'no feed function is open to anon');
select is_empty($$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname like 'feed\_svc\_%' and has_function_privilege('authenticated', p.oid, 'execute') $$,
  'and no worker function to players');

select * from finish();
rollback;
