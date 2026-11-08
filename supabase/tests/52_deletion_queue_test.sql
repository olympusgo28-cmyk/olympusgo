-- P5-06: the delete queue across two buckets. A backlog in one can't hold up the
-- other, and the same path in another bucket is a different file.
begin;
\ir helpers/setup.psql
select no_plan();

reset role;
delete from public.storage_deletions;
insert into public.storage_deletions (path)
select 'clip/' || n || '.mp4' from generate_series(1, 250) n;
insert into public.storage_deletions (bucket, path) values ('feed-videos', 'post/a.mp4'), ('feed-videos', 'post/b.mp4');

select throws_ok($$ insert into public.storage_deletions (bucket, path) values ('documents', 'x') $$,
  '23514', null, 'the queue only names buckets the sweep knows');

set local role service_role;
create temp table due on commit drop as select x from jsonb_array_elements(public.analysis_svc_sweep()) x;
reset role;
select is((select count(*)::int from due where x ->> 'bucket' = 'analysis-clips'), 200, 'one bucket gets its share of a run');
select is((select count(*)::int from due where x ->> 'bucket' = 'feed-videos'), 2, 'and a backlog there leaves room for the other');

-- A file queued in the feed bucket says nothing about a clip with the same name.
delete from public.storage_deletions;
insert into storage.objects (bucket_id, name, metadata, created_at)
values ('analysis-clips', 'same/name.mp4', '{"size": 1}', now() - interval '2 hours');
insert into public.storage_deletions (bucket, path) values ('feed-videos', 'same/name.mp4');
set local role service_role;
select ok(public.analysis_svc_orphans() >= 1, 'a stray clip is found though a feed file shares its name');
reset role;
select is((select count(*)::int from public.storage_deletions where path = 'same/name.mp4' and bucket = 'analysis-clips'), 1,
  'and it''s queued in its own bucket');

select * from finish();
rollback;
