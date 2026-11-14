-- P5-06: the delete queue serves two buckets, so feed videos can use the same
-- sweep as clips. Each bucket gets its own share of a run, so a failure or a
-- backlog in one can't starve the other.

alter table public.storage_deletions
  add column bucket text not null default 'analysis-clips'
    check (bucket in ('analysis-clips', 'feed-videos'));
create index storage_deletions_bucket_idx on public.storage_deletions (bucket, id);

create or replace function public.analysis_svc_sweep() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only.
begin
  -- Clips first, then jobs, the same order everything else locks in.
  perform 1 from public.video_clips c
  where c.id in (select j.clip_id from public.analysis_jobs j where j.status = 'claimed' and j.deadline < now())
     or (c.purge_at <= now() and c.file_gone_at is null)
  order by c.id for update of c;

  update public.analysis_jobs j set status = case when j.attempts < 2 then 'queued' else 'failed' end,
    token_hash = null, deadline = null, error_code = case when j.attempts < 2 then null else 'timeout' end,
    finished_at = case when j.attempts < 2 then null else now() end
  where j.status = 'claimed' and j.deadline < now();
  update public.video_clips c set status = 'failed', error_code = 'timeout'
  from public.analysis_jobs j
  where j.clip_id = c.id and j.status = 'failed' and j.error_code = 'timeout'
    and c.status not in ('failed', 'withdrawn');

  -- An upload that never finished.
  delete from public.video_clips c where c.status = 'waiting' and c.created_at < now() - interval '1 day';

  -- A clip of a child whose parent link has ended goes now, report included:
  -- nobody who added it has a claim on it any more (Q206).
  delete from public.video_clips c
  where c.subject_id <> c.owner_id and not private.is_guardian_of(c.owner_id, c.subject_id);

  update public.analysis_jobs j set status = 'cancelled', token_hash = null, finished_at = now()
  from public.video_clips c
  where j.clip_id = c.id and j.status in ('queued', 'claimed') and c.purge_at <= now();
  update public.video_clips c set status = 'failed', error_code = 'not_allowed'
  where c.purge_at <= now() and c.file_gone_at is null and c.status in ('waiting', 'uploaded', 'queued', 'court_ready');

  with due as (
    update public.video_clips c set file_gone_at = now(), frame = false
    where c.purge_at <= now() and c.file_gone_at is null
    returning c.*
  )
  insert into public.storage_deletions (path)
  select private.clip_video_path(d::public.video_clips) from due d
  union all select private.clip_frame_path(d::public.video_clips) from due d;

  return (select coalesce(jsonb_agg(jsonb_build_object('id', x.id, 'bucket', x.bucket, 'path', x.path)), '[]')
    from (
      select d.*, row_number() over (partition by d.bucket order by d.id) as place
      from public.storage_deletions d
    ) x
    where x.place <= 200);
end;
$$;

create or replace function public.analysis_svc_orphans() returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only. Reads Storage's own table.
declare
  v_count int;
begin
  insert into public.storage_deletions (path)
  select o.name from storage.objects o
  where o.bucket_id = 'analysis-clips' and o.created_at < now() - interval '1 hour'
    and not exists (select 1 from public.video_clips c
      where c.file_gone_at is null
        and c.id::text = substring(o.name from '/([0-9a-f-]{36})\.'))
    and not exists (select 1 from public.storage_deletions d
      where d.bucket = 'analysis-clips' and d.path = o.name)
  limit 500;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
