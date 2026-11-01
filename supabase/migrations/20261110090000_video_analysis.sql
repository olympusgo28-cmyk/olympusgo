-- P5-01, P5-02: private clips, a consent row for every video of a child, the
-- 90-day purge, and analysis jobs. A worker claims a job with a token good for
-- that job only, and never holds the service-role key. Reports are numbers and
-- a grid: no image of a person is kept beyond the clip.

insert into public.feature_flags (key, enabled, description) values
  ('video.analysis', false, 'Clip analysis for adults'),
  ('video.analysis_minors', false, 'Clips of under-18s, added by a linked parent. Off until Gate F');

insert into public.app_settings (key, value, description) values
  ('video.max_seconds', '180', 'Longest clip (Q193)'),
  ('video.max_mb', '200', 'Largest clip (Q193)'),
  ('video.retention_days', '90', 'Days a clip is kept (Q197)'),
  ('video.extend_days', '90', 'Days one extension adds (Q196)'),
  ('video.max_extensions', '1', 'Extensions a clip can have (Q196)'),
  ('analysis.job_timeout_seconds', '900', 'How long a worker has for one job (Q194)'),
  ('analysis.daily_seconds_per_user', '600', 'Seconds of clip one player can analyse in 24 hours (Q195)'),
  ('analysis.daily_seconds_total', '36000', 'Seconds of clip across the app in 24 hours (Q195)'),
  ('analysis.daily_clips', '20', 'Clips one player can send in 24 hours (Q195)'),
  ('analysis.cost_cents_per_minute', '1', 'Estimated worker cost for the jobs monitor. Not billed to anyone'),
  ('video.consent_version', '"v1"', 'The wording a parent agrees to for a clip of their child');

-- The project's upload limit rises to 200 MB for clips, so these keep their own.
update storage.buckets set file_size_limit = 10485760 where id in ('avatars', 'chat-photos') and file_size_limit is null;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('analysis-clips', 'analysis-clips', false, 209715200, array['video/mp4', 'video/quicktime', 'image/jpeg']);

create table public.video_clips (
  id uuid primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  -- The person in the clip: the owner, or their linked child.
  subject_id uuid not null references auth.users (id) on delete cascade,
  sport text not null default 'badminton' check (sport in ('badminton')),
  ext text not null check (ext in ('mp4', 'mov')),
  status text not null default 'waiting'
    check (status in ('waiting', 'uploaded', 'court_ready', 'queued', 'done', 'failed', 'withdrawn')),
  error_code text,
  seconds int not null check (seconds between 1 and 3600),
  bytes bigint not null check (bytes > 0),
  -- Which half of the court the player is on. Only that side is measured.
  side text check (side in ('near', 'far')),
  -- Four [x, y] points from 0 to 1, in the frame.
  corners jsonb,
  frame boolean not null default false,
  extensions int not null default 0,
  purge_at timestamptz not null,
  -- The video and frame are gone. The row and report stay until deleted.
  file_gone_at timestamptz,
  created_at timestamptz not null default now()
);
create index video_clips_owner_idx on public.video_clips (owner_id, created_at desc);
create index video_clips_subject_idx on public.video_clips (subject_id);
create index video_clips_purge_idx on public.video_clips (purge_at) where file_gone_at is null;

create table public.video_consents (
  id uuid primary key default gen_random_uuid(),
  clip_id uuid unique references public.video_clips (id) on delete set null,
  child_id uuid not null references auth.users (id) on delete cascade,
  parent_id uuid not null references auth.users (id) on delete cascade,
  version text not null check (char_length(version) between 1 and 20),
  granted_at timestamptz not null default now(),
  withdrawn_at timestamptz
);
create index video_consents_child_idx on public.video_consents (child_id);
create index video_consents_parent_idx on public.video_consents (parent_id);

create table public.analysis_jobs (
  id uuid primary key default gen_random_uuid(),
  clip_id uuid not null references public.video_clips (id) on delete cascade,
  kind text not null check (kind in ('court', 'analyse')),
  status text not null default 'queued'
    check (status in ('queued', 'claimed', 'done', 'failed', 'cancelled')),
  -- Only a hash is kept, and it's cleared when the job ends.
  token_hash text,
  deadline timestamptz,
  attempts int not null default 0,
  worker_seconds int,
  error_code text,
  created_at timestamptz not null default now(),
  finished_at timestamptz,
  unique (clip_id, kind)
);
create index analysis_jobs_queue_idx on public.analysis_jobs (created_at) where status = 'queued';
create index analysis_jobs_deadline_idx on public.analysis_jobs (deadline) where status = 'claimed';

create table public.analysis_reports (
  clip_id uuid primary key references public.video_clips (id) on delete cascade,
  subject_id uuid not null references auth.users (id) on delete cascade,
  distance_m numeric(8, 1) not null check (distance_m between 0 and 100000),
  avg_speed_ms numeric(4, 2) not null check (avg_speed_ms between 0 and 15),
  top_speed_ms numeric(4, 2) not null check (top_speed_ms between 0 and 15),
  moving_seconds int not null check (moving_seconds between 0 and 3600),
  -- Share of time in each cell, 0 to 100. Rows run along the court.
  heatmap jsonb not null,
  created_at timestamptz not null default now()
);
create index analysis_reports_subject_idx on public.analysis_reports (subject_id);

-- What each player has used. Not tied to a clip, so deleting a clip gives none
-- of it back.
create table public.analysis_usage (
  id bigint generated always as identity primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('court', 'analyse')),
  seconds int not null default 0,
  at timestamptz not null default now()
);
create index analysis_usage_owner_idx on public.analysis_usage (owner_id, at desc);
create index analysis_usage_at_idx on public.analysis_usage (at);

-- Files still to remove. Filled in the same transaction that loses the row, so
-- deleting an account can't leave a video behind.
create table public.storage_deletions (
  id bigint generated always as identity primary key,
  path text not null,
  created_at timestamptz not null default now()
);
create index storage_deletions_path_idx on public.storage_deletions (path);

do $$
declare
  t text;
begin
  foreach t in array array['video_clips', 'video_consents', 'analysis_jobs', 'analysis_reports', 'analysis_usage',
    'storage_deletions']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
  end loop;
end;
$$;

-- ─── Files ─────────────────────────────────────────────────────────────────

create function private.clip_video_path(c public.video_clips) returns text
language sql immutable set search_path = '' as $$
  select c.owner_id::text || '/' || c.id::text || '.' || c.ext;
$$;

create function private.clip_frame_path(c public.video_clips) returns text
language sql immutable set search_path = '' as $$
  select c.owner_id::text || '/' || c.id::text || '.frame.jpg';
$$;
revoke execute on function private.clip_video_path(public.video_clips) from public, anon, authenticated;
revoke execute on function private.clip_frame_path(public.video_clips) from public, anon, authenticated;

-- Only the court frame, only to the owner or a linked parent. Never a video.
create function private.clip_frame_ok(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: Storage runs this as the caller, and clips have no client access.
  select not private.is_restricted(auth.uid()) and exists (
    select 1 from public.video_clips c
    where c.frame and c.file_gone_at is null and private.clip_frame_path(c) = p_name
      and ((c.owner_id = auth.uid() and c.subject_id = c.owner_id)
        or private.is_guardian_of(auth.uid(), c.subject_id)));
$$;
revoke execute on function private.clip_frame_ok(text) from public, anon;
grant execute on function private.clip_frame_ok(text) to authenticated;

create policy "Players read their own court frame" on storage.objects
  for select to authenticated
  using (bucket_id = 'analysis-clips' and private.clip_frame_ok(name));

create function private.clip_queue_files() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: fires for whoever deleted the row, including an account deletion.
begin
  -- Even if they were marked gone: removing a file twice does no harm.
  insert into public.storage_deletions (path)
  values (private.clip_video_path(old)), (private.clip_frame_path(old));
  return old;
end;
$$;
create trigger video_clips_queue_files before delete on public.video_clips
  for each row execute function private.clip_queue_files();

-- ─── Rules ─────────────────────────────────────────────────────────────────

-- May this clip be sent to a worker right now?
create function private.clip_may_run(c public.video_clips) returns boolean
language sql stable set search_path = '' as $$
  select private.flag('video.analysis') and c.file_gone_at is null and not private.is_restricted(c.owner_id)
    and case when c.subject_id = c.owner_id then not private.is_minor(c.owner_id)
      else private.flag('video.analysis_minors') and private.is_guardian_of(c.owner_id, c.subject_id)
        and exists (select 1 from public.video_consents v
          where v.clip_id = c.id and v.child_id = c.subject_id and v.parent_id = c.owner_id
            and v.withdrawn_at is null)
      end;
$$;
revoke execute on function private.clip_may_run(public.video_clips) from public, anon, authenticated;

create function private.clip_upload_ok(p_name text) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: Storage runs this as the caller, and clips have no client access.
  select exists (
    select 1 from public.video_clips c
    where c.owner_id = auth.uid() and c.status = 'waiting' and private.clip_video_path(c) = p_name
      and private.clip_may_run(c));
$$;
revoke execute on function private.clip_upload_ok(text) from public, anon;
grant execute on function private.clip_upload_ok(text) to authenticated;

create policy "Players upload the clip they started" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'analysis-clips' and private.clip_upload_ok(name));

-- The person in the clip, if it's theirs, or a parent still linked to them. An
-- owner whose link has ended has no claim on a child's clip.
create function private.clip_mine(c public.video_clips) returns boolean
language sql stable set search_path = '' as $$
  select (c.owner_id = auth.uid() and c.subject_id = c.owner_id)
    or private.is_guardian_of(auth.uid(), c.subject_id);
$$;
revoke execute on function private.clip_mine(public.video_clips) from public, anon, authenticated;

create function private.clip_seconds_today(p_owner uuid) returns bigint
language sql stable set search_path = '' as $$
  select coalesce(sum(u.seconds), 0) from public.analysis_usage u
  where u.kind = 'analyse' and u.at > now() - interval '1 day' and (p_owner is null or u.owner_id = p_owner);
$$;
revoke execute on function private.clip_seconds_today(uuid) from public, anon, authenticated;

create function private.clip_json(c public.video_clips) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object('id', c.id, 'status', c.status, 'error_code', c.error_code, 'sport', c.sport,
    'seconds', c.seconds, 'side', c.side, 'corners', c.corners, 'created_at', c.created_at,
    'purge_at', c.purge_at, 'file_gone', c.file_gone_at is not null,
    'can_extend', c.file_gone_at is null and c.status <> 'withdrawn'
      and c.extensions < private.setting_int('video.max_extensions'),
    'for_child', c.subject_id <> c.owner_id,
    'child', case when c.subject_id <> c.owner_id then
      (select p.full_name from public.profiles p where p.id = c.subject_id) end,
    'frame', case when c.frame and c.file_gone_at is null then private.clip_frame_path(c) end);
$$;
revoke execute on function private.clip_json(public.video_clips) from public, anon, authenticated;

create function private.clip_corners_ok(p jsonb) returns boolean
language sql immutable set search_path = '' as $$
  select case when jsonb_typeof(p) = 'array' and jsonb_array_length(p) = 4 then not exists (
    select 1 from jsonb_array_elements(p) e
    where case when jsonb_typeof(e) = 'array' and jsonb_array_length(e) = 2
        and jsonb_typeof(e -> 0) = 'number' and jsonb_typeof(e -> 1) = 'number'
      then (e ->> 0)::numeric not between 0 and 1 or (e ->> 1)::numeric not between 0 and 1
      else true end)
    else false end;
$$;
revoke execute on function private.clip_corners_ok(jsonb) from public, anon, authenticated;

-- ─── Player functions ──────────────────────────────────────────────────────

create function public.analysis_status() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: reads settings for any caller.
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Log in first.'; end if;
  return jsonb_build_object(
    'open', private.flag('video.analysis') and not private.is_minor(v_user) and not private.is_restricted(v_user),
    'children_open', private.flag('video.analysis') and private.flag('video.analysis_minors')
      and not private.is_minor(v_user) and not private.is_restricted(v_user),
    'max_seconds', private.setting_int('video.max_seconds'),
    'max_mb', private.setting_int('video.max_mb'));
end;
$$;

-- The phone makes the id, so a retry reaches the same clip. A clip of a child
-- writes its consent row in the same step.
create function public.clip_create(p_clip uuid, p_subject uuid, p_ext text, p_seconds int, p_bytes bigint,
  p_everyone_agreed boolean, p_consent_version text default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: the tables have no client access.
declare
  v_user uuid := auth.uid();
  v_subject uuid := coalesce(p_subject, auth.uid());
  c public.video_clips;
begin
  if v_user is null then raise exception 'Log in first.'; end if;
  if private.is_suspended(v_user) then raise exception 'Your account is suspended.'; end if;
  if private.is_restricted(v_user) then raise exception 'Ask a parent to link your account first.'; end if;
  if not private.flag('video.analysis') then raise exception 'Analysis is not open yet.'; end if;
  if private.is_minor(v_user) then raise exception 'Ask a parent to add this clip.'; end if;
  if v_subject <> v_user then
    if not private.flag('video.analysis_minors') then raise exception 'Clips of children are not open yet.'; end if;
    if not private.is_guardian_of(v_user, v_subject) then raise exception 'This clip can''t be added.'; end if;
    if p_consent_version is distinct from
        (select x.value #>> '{}' from public.app_settings x where x.key = 'video.consent_version') then
      raise exception 'Give your consent first.';
    end if;
  end if;
  if p_everyone_agreed is distinct from true then
    raise exception 'Check that everyone in the clip has agreed.';
  end if;
  if p_ext is null or p_ext not in ('mp4', 'mov') then raise exception 'Choose an MP4 or MOV clip.'; end if;
  if p_seconds is null or p_seconds < 1 or p_seconds > private.setting_int('video.max_seconds') then
    raise exception 'That clip is too long.';
  end if;
  if p_bytes is null or p_bytes < 1 or p_bytes > private.setting_int('video.max_mb')::bigint * 1048576 then
    raise exception 'That clip is too big.';
  end if;
  if p_clip is null then raise exception 'This clip can''t be added.'; end if;

  select * into c from public.video_clips v where v.id = p_clip;
  if c.id is not null then
    -- The same id from someone else says nothing about whose it is.
    if c.owner_id <> v_user then raise exception 'This clip can''t be added.'; end if;
  else
    insert into public.video_clips (id, owner_id, subject_id, ext, seconds, bytes, purge_at)
    values (p_clip, v_user, v_subject, p_ext, p_seconds, p_bytes,
      now() + make_interval(days => private.setting_int('video.retention_days')))
    on conflict (id) do nothing
    returning * into c;
    if c.id is null then raise exception 'This clip can''t be added.'; end if;
    if v_subject <> v_user then
      insert into public.video_consents (clip_id, child_id, parent_id, version)
      values (p_clip, v_subject, v_user, p_consent_version);
    end if;
  end if;
  return jsonb_build_object('id', c.id, 'path', private.clip_video_path(c), 'status', c.status);
end;
$$;

-- The file is in. Queues the job that finds the court.
create function public.clip_uploaded(p_clip uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: reads Storage's own table and writes jobs.
declare
  c public.video_clips;
  v_size bigint;
begin
  select * into c from public.video_clips v where v.id = p_clip and v.owner_id = auth.uid() for update;
  if c.id is null then raise exception 'Clip not found.'; end if;
  if c.status <> 'waiting' then return; end if;
  if not private.clip_may_run(c) then raise exception 'This clip can''t be analysed.'; end if;
  select (o.metadata ->> 'size')::bigint into v_size from storage.objects o
  where o.bucket_id = 'analysis-clips' and o.name = private.clip_video_path(c);
  if not found then raise exception 'The upload didn''t finish. Try again.'; end if;
  if v_size > private.setting_int('video.max_mb')::bigint * 1048576 then
    raise exception 'That clip is too big.';
  end if;
  -- Finding the court costs money too, so sending clips is capped.
  perform pg_advisory_xact_lock(hashtextextended('analysis:' || auth.uid()::text, 0));
  if (select count(*) from public.analysis_usage u where u.owner_id = auth.uid() and u.kind = 'court'
      and u.at > now() - interval '1 day') >= private.setting_int('analysis.daily_clips') then
    raise exception 'You''ve reached today''s limit. Try again tomorrow.';
  end if;
  insert into public.analysis_usage (owner_id, kind) values (auth.uid(), 'court');
  update public.video_clips v set status = 'uploaded', bytes = coalesce(v_size, v.bytes) where v.id = p_clip;
  insert into public.analysis_jobs (clip_id, kind) values (p_clip, 'court');
end;
$$;

-- The player has checked the court and picked a side. The daily caps are
-- reserved here, under a lock.
create function public.clip_confirm_court(p_clip uuid, p_corners jsonb, p_side text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes jobs, which have no client access.
declare
  v_user uuid := auth.uid();
  c public.video_clips;
begin
  select * into c from public.video_clips v where v.id = p_clip and v.owner_id = v_user for update;
  if c.id is null then raise exception 'Clip not found.'; end if;
  if c.status in ('queued', 'done') then return; end if;
  if c.status <> 'court_ready' then raise exception 'This clip isn''t ready for that.'; end if;
  if not private.clip_may_run(c) then raise exception 'This clip can''t be analysed.'; end if;
  if p_corners is null or not private.clip_corners_ok(p_corners) then raise exception 'Mark the four corners.'; end if;
  if p_side is null or p_side not in ('near', 'far') then raise exception 'Choose your side.'; end if;

  perform pg_advisory_xact_lock(hashtextextended('analysis:' || v_user::text, 0));
  if private.clip_seconds_today(v_user) + c.seconds > private.setting_int('analysis.daily_seconds_per_user') then
    raise exception 'You''ve reached today''s limit. Try again tomorrow.';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('analysis-total', 0));
  if private.clip_seconds_today(null) + c.seconds > private.setting_int('analysis.daily_seconds_total') then
    raise exception 'Analysis is busy today. Try again tomorrow.';
  end if;

  insert into public.analysis_usage (owner_id, kind, seconds) values (v_user, 'analyse', c.seconds);
  update public.video_clips v set corners = p_corners, side = p_side, status = 'queued' where v.id = p_clip;
  insert into public.analysis_jobs (clip_id, kind) values (p_clip, 'analyse');
end;
$$;

create function public.clip_list() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: returns the caller's own clips, to nobody else.
begin
  if auth.uid() is null then raise exception 'Log in first.'; end if;
  return (select coalesce(jsonb_agg(private.clip_json(c) order by c.created_at desc), '[]')
    from public.video_clips c where c.owner_id = auth.uid() and private.clip_mine(c));
end;
$$;

create function public.child_clip_list(p_child uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: a parent lists their child's clips, and the check is here.
begin
  if not private.is_guardian_of(auth.uid(), p_child) then raise exception 'Not found.'; end if;
  return (select coalesce(jsonb_agg(private.clip_json(c) order by c.created_at desc), '[]')
    from public.video_clips c where c.subject_id = p_child);
end;
$$;

create function public.clip_get(p_clip uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: the owner or a linked parent, and nobody else.
declare
  c public.video_clips;
begin
  select * into c from public.video_clips v where v.id = p_clip;
  if c.id is null or not private.clip_mine(c) then raise exception 'Clip not found.'; end if;
  return private.clip_json(c) || jsonb_build_object('report', (select to_jsonb(r) - 'clip_id' - 'subject_id'
    from public.analysis_reports r where r.clip_id = p_clip));
end;
$$;

-- Deleting takes the report too. The file goes at the next sweep.
create function public.clip_delete(p_clip uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: the tables have no client access.
declare
  c public.video_clips;
begin
  select * into c from public.video_clips v where v.id = p_clip for update;
  if c.id is null or not private.clip_mine(c) then return; end if;
  delete from public.video_clips v where v.id = p_clip;
end;
$$;

create function public.clip_extend(p_clip uuid) returns timestamptz
language plpgsql security definer set search_path = '' as $$
-- Definer: the tables have no client access.
declare
  c public.video_clips;
  v_purge timestamptz;
begin
  select * into c from public.video_clips v where v.id = p_clip for update;
  if c.id is null or not private.clip_mine(c) then raise exception 'Clip not found.'; end if;
  if c.file_gone_at is not null or c.status = 'withdrawn' then raise exception 'This clip has gone.'; end if;
  if c.extensions >= private.setting_int('video.max_extensions') then
    raise exception 'This clip has already been extended.';
  end if;
  update public.video_clips v set extensions = v.extensions + 1,
    purge_at = v.purge_at + make_interval(days => private.setting_int('video.extend_days'))
  where v.id = p_clip returning purge_at into v_purge;
  return v_purge;
end;
$$;

-- Stops everything at once. The file goes at the next sweep, inside 7 days (ACD-13).
create function public.consent_withdraw(p_clip uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: the tables have no client access.
declare
  c public.video_clips;
begin
  select * into c from public.video_clips v where v.id = p_clip for update;
  if c.id is null or c.subject_id = c.owner_id or not private.clip_mine(c) then
    raise exception 'Clip not found.';
  end if;
  update public.video_consents v set withdrawn_at = coalesce(v.withdrawn_at, now()) where v.clip_id = p_clip;
  update public.analysis_jobs j set status = 'cancelled', token_hash = null, finished_at = now()
  where j.clip_id = p_clip and j.status in ('queued', 'claimed');
  update public.video_clips v set status = 'withdrawn', purge_at = least(v.purge_at, now()) where v.id = p_clip;
end;
$$;

-- ─── Service functions ─────────────────────────────────────────────────────

-- Gives a worker the oldest job it may run, with a token for that job alone.
create function public.analysis_svc_claim() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only.
declare
  j public.analysis_jobs;
  c public.video_clips;
  v_token text;
  v_timeout int := private.setting_int('analysis.job_timeout_seconds');
begin
  -- Switched off, the queue simply waits.
  if not private.flag('video.analysis') then return null; end if;
  loop
    -- The clip first, then the job, the same order everything else locks in.
    select v.* into c from public.video_clips v
    join public.analysis_jobs x on x.clip_id = v.id
    where x.status = 'queued' order by x.created_at for update of v skip locked limit 1;
    if c.id is null then return null; end if;
    select * into j from public.analysis_jobs x where x.clip_id = c.id and x.status = 'queued' for update;
    if j.id is null then continue; end if;
    if not private.clip_may_run(c) then
      -- Failed, not cancelled, so the monitor shows it and staff can retry.
      update public.analysis_jobs x set status = case when c.status = 'withdrawn' then 'cancelled' else 'failed' end,
        error_code = case when c.status = 'withdrawn' then null else 'not_allowed' end, finished_at = now()
      where x.id = j.id;
      update public.video_clips v set status = 'failed', error_code = 'not_allowed'
      where v.id = c.id and v.status <> 'withdrawn';
      continue;
    end if;
    v_token := encode(extensions.gen_random_bytes(32), 'hex');
    update public.analysis_jobs x set status = 'claimed', attempts = x.attempts + 1,
      deadline = now() + make_interval(secs => v_timeout),
      token_hash = encode(extensions.digest(v_token, 'sha256'), 'hex')
    where x.id = j.id;
    return jsonb_build_object('job_id', j.id, 'kind', j.kind, 'token', v_token, 'timeout_seconds', v_timeout,
      'path', private.clip_video_path(c), 'frame_path', private.clip_frame_path(c),
      'sport', c.sport, 'side', c.side, 'corners', c.corners, 'max_seconds', private.setting_int('video.max_seconds'));
  end loop;
end;
$$;

-- A report's numbers, checked whatever the function already did.
create function private.analysis_report_ok(p jsonb) returns boolean
language sql immutable set search_path = '' as $$
  select coalesce(jsonb_typeof(p -> 'distance_m') = 'number' and jsonb_typeof(p -> 'avg_speed_ms') = 'number'
    and jsonb_typeof(p -> 'top_speed_ms') = 'number' and jsonb_typeof(p -> 'moving_seconds') = 'number', false)
    and case when jsonb_typeof(p -> 'heatmap') = 'array' and jsonb_array_length(p -> 'heatmap') = 13 then
      not exists (select 1 from jsonb_array_elements(p -> 'heatmap') r
        where case when jsonb_typeof(r) = 'array' and jsonb_array_length(r) = 6 then exists (
          select 1 from jsonb_array_elements(r) x
          where case when jsonb_typeof(x) = 'number' then (x #>> '{}')::numeric not between 0 and 100 else true end)
        else true end)
    else false end;
$$;
revoke execute on function private.analysis_report_ok(jsonb) from public, anon, authenticated;

create function public.analysis_svc_result(p_job uuid, p_token text, p_ok boolean, p_result jsonb,
  p_code text, p_worker_seconds int) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only. The token is what proves which job this is.
declare
  j public.analysis_jobs;
  c public.video_clips;
  v_code text := coalesce(p_code, 'internal');
begin
  -- The clip first, then the job, the same order everything else locks in.
  select * into c from public.video_clips v
  where v.id = (select x.clip_id from public.analysis_jobs x where x.id = p_job) for update;
  select * into j from public.analysis_jobs x where x.id = p_job for update;
  if j.id is null then raise exception 'Unknown job.'; end if;
  if j.status in ('done', 'failed', 'cancelled') then return j.status; end if;
  if j.status <> 'claimed' or j.token_hash is null or p_token is null
      or j.token_hash <> encode(extensions.digest(p_token, 'sha256'), 'hex') then
    raise exception 'Bad token.';
  end if;
  if j.deadline < now() then raise exception 'Bad token.'; end if;

  if not private.clip_may_run(c) then
    update public.analysis_jobs x set status = case when c.status = 'withdrawn' then 'cancelled' else 'failed' end,
      error_code = case when c.status = 'withdrawn' then null else 'not_allowed' end,
      token_hash = null, finished_at = now()
    where x.id = p_job;
    update public.video_clips v set status = 'failed', error_code = 'not_allowed'
    where v.id = c.id and v.status <> 'withdrawn';
    return 'cancelled';
  end if;

  if not p_ok then
    -- A problem with the clip itself won't change on a second try.
    if v_code = 'internal' and j.attempts < 2 then
      update public.analysis_jobs x set status = 'queued', token_hash = null, deadline = null where x.id = p_job;
      return 'queued';
    end if;
    if v_code not in ('internal', 'bad_video', 'too_long', 'no_court', 'no_player', 'doubles') then
      v_code := 'internal';
    end if;
    update public.analysis_jobs x set status = 'failed', token_hash = null, error_code = v_code,
      worker_seconds = p_worker_seconds, finished_at = now() where x.id = p_job;
    update public.video_clips v set status = 'failed', error_code = v_code where v.id = c.id;
    return 'failed';
  end if;

  if j.kind = 'court' then
    if p_result -> 'corners' is not null and jsonb_typeof(p_result -> 'corners') <> 'null'
        and not private.clip_corners_ok(p_result -> 'corners') then
      raise exception 'Bad result.';
    end if;
    if jsonb_typeof(p_result -> 'seconds') is distinct from 'number'
        or (p_result ->> 'seconds')::numeric < 1 then
      raise exception 'Bad result.';
    end if;
    -- The phone's word for the length isn't trusted: the caps use this one.
    if (p_result ->> 'seconds')::numeric > private.setting_int('video.max_seconds') then
      update public.analysis_jobs x set status = 'failed', token_hash = null, error_code = 'too_long',
        worker_seconds = p_worker_seconds, finished_at = now() where x.id = p_job;
      update public.video_clips v set status = 'failed', error_code = 'too_long' where v.id = c.id;
      return 'failed';
    end if;
    update public.video_clips v set status = 'court_ready', frame = true,
      seconds = ceil((p_result ->> 'seconds')::numeric)::int,
      corners = case when jsonb_typeof(p_result -> 'corners') = 'array' then p_result -> 'corners' end
    where v.id = c.id;
  else
    if not private.analysis_report_ok(p_result) then raise exception 'Bad result.'; end if;
    begin
      insert into public.analysis_reports (clip_id, subject_id, distance_m, avg_speed_ms, top_speed_ms,
        moving_seconds, heatmap)
      values (c.id, c.subject_id, (p_result ->> 'distance_m')::numeric, (p_result ->> 'avg_speed_ms')::numeric,
        (p_result ->> 'top_speed_ms')::numeric, (p_result ->> 'moving_seconds')::numeric::int, p_result -> 'heatmap');
    exception when check_violation or numeric_value_out_of_range then
      raise exception 'Bad result.';
    end;
    update public.video_clips v set status = 'done' where v.id = c.id;
  end if;
  update public.analysis_jobs x set status = 'done', token_hash = null, worker_seconds = p_worker_seconds,
    finished_at = now() where x.id = p_job;
  return 'done';
end;
$$;

-- Should a worker carry on? It asks between stages, so a withdrawal stops the
-- work, not just the result. A wrong or old token says no.
create function public.analysis_svc_may_continue(p_job uuid, p_token text) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: service role only.
  select coalesce((select private.clip_may_run(c)
    from public.analysis_jobs j join public.video_clips c on c.id = j.clip_id
    where j.id = p_job and j.status = 'claimed' and j.deadline >= now() and p_token is not null
      and j.token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')), false);
$$;

-- Where this job's frame goes. It comes from here, never from the worker, and
-- only a live token on a court job gets an answer.
create function public.analysis_svc_frame_path(p_job uuid, p_token text) returns text
language sql stable security definer set search_path = '' as $$
  -- Definer: service role only.
  select private.clip_frame_path(c)
  from public.analysis_jobs j join public.video_clips c on c.id = j.clip_id
  where j.id = p_job and j.kind = 'court' and j.status = 'claimed' and j.deadline >= now()
    and p_token is not null and j.token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')
    and private.clip_may_run(c);
$$;

-- Times out stuck jobs, marks what's due, and says what files to remove.
create function public.analysis_svc_sweep() returns jsonb
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

  return (select coalesce(jsonb_agg(jsonb_build_object('id', x.id, 'path', x.path)), '[]')
    from (select * from public.storage_deletions order by id limit 200) x);
end;
$$;

-- The safety net: any file with no live clip goes, however it got there. On its
-- own, so that a problem here can't hold up a purge.
create function public.analysis_svc_orphans() returns int
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
    and not exists (select 1 from public.storage_deletions d where d.path = o.name)
  limit 500;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

create function public.analysis_svc_removed(p_ids bigint[]) returns void
language sql security definer set search_path = '' as $$
  -- Definer: service role only. Called once Storage has confirmed.
  delete from public.storage_deletions d where d.id = any (p_ids);
$$;

-- ─── Staff ─────────────────────────────────────────────────────────────────

-- Counts and error codes only: no clip, frame, player or path.
create function public.staff_analysis_overview() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: jobs have no client access. The role is checked here.
begin
  perform private.staff_require('content');
  return jsonb_build_object(
    'queued', (select count(*) from public.analysis_jobs j where j.status = 'queued'),
    'running', (select count(*) from public.analysis_jobs j where j.status = 'claimed'),
    'done_24h', (select count(*) from public.analysis_jobs j
      where j.status = 'done' and j.finished_at > now() - interval '1 day'),
    'failed_24h', (select count(*) from public.analysis_jobs j
      where j.status = 'failed' and j.finished_at > now() - interval '1 day'),
    'files_waiting', (select count(*) from public.storage_deletions),
    -- If the sweep has stopped, this shows it.
    'files_overdue', (select count(*) from public.video_clips c
      where c.file_gone_at is null and c.purge_at < now() - interval '1 hour'),
    'storage_bytes', (select coalesce(sum(c.bytes), 0) from public.video_clips c where c.file_gone_at is null),
    'clips_held', (select count(*) from public.video_clips c where c.file_gone_at is null),
    'cost_cents_30d', (select coalesce(sum(j.worker_seconds), 0) * private.setting_int('analysis.cost_cents_per_minute') / 60
      from public.analysis_jobs j where j.finished_at > now() - interval '30 days'),
    'failures', (select coalesce(jsonb_agg(jsonb_build_object('id', x.id, 'kind', x.kind, 'error_code', x.error_code,
        'attempts', x.attempts, 'at', x.finished_at) order by x.finished_at desc), '[]')
      from (select * from public.analysis_jobs j where j.status = 'failed'
        order by j.finished_at desc limit 50) x));
end;
$$;

create function public.staff_analysis_retry(p_job uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: jobs have no client access. The role is checked here.
declare
  c public.video_clips;
  j public.analysis_jobs;
begin
  perform private.staff_require('content');
  if char_length(trim(coalesce(p_reason, ''))) < 3 then raise exception 'Give a reason.'; end if;
  select * into c from public.video_clips v
  where v.id = (select x.clip_id from public.analysis_jobs x where x.id = p_job) for update;
  select * into j from public.analysis_jobs x where x.id = p_job and x.status = 'failed' for update;
  if j.id is null then raise exception 'Only a failed job can be retried.'; end if;
  if c.status <> 'failed' or not private.clip_may_run(c) then
    raise exception 'This clip can''t be run again.';
  end if;
  update public.analysis_jobs x set status = 'queued', attempts = 0, error_code = null, finished_at = null
  where x.id = p_job;
  update public.video_clips v set status = case j.kind when 'court' then 'uploaded' else 'queued' end, error_code = null
  where v.id = c.id;
  perform private.staff_audit('analysis_retried', 'analysis_job', p_job::text, p_reason);
end;
$$;

-- ─── Access ────────────────────────────────────────────────────────────────

do $$
declare
  f text;
begin
  foreach f in array array[
    'analysis_status()', 'clip_create(uuid, uuid, text, integer, bigint, boolean, text)', 'clip_uploaded(uuid)',
    'clip_confirm_court(uuid, jsonb, text)', 'clip_list()', 'child_clip_list(uuid)', 'clip_get(uuid)',
    'clip_delete(uuid)', 'clip_extend(uuid)', 'consent_withdraw(uuid)', 'staff_analysis_overview()',
    'staff_analysis_retry(uuid, text)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  foreach f in array array[
    'analysis_svc_claim()', 'analysis_svc_result(uuid, text, boolean, jsonb, text, integer)',
    'analysis_svc_may_continue(uuid, text)', 'analysis_svc_frame_path(uuid, text)', 'analysis_svc_orphans()',
    'analysis_svc_sweep()', 'analysis_svc_removed(bigint[])']
  loop
    execute format('revoke execute on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to service_role', f);
  end loop;
end;
$$;

-- Seeing, deleting and withdrawing stay open to anyone, whatever their state.
insert into private.restricted_allow (path) values
  ('/rpc/analysis_status'), ('/rpc/clip_list'), ('/rpc/child_clip_list'), ('/rpc/clip_get'), ('/rpc/clip_delete'),
  ('/rpc/consent_withdraw');
insert into private.suspended_allow (path) values
  ('/rpc/analysis_status'), ('/rpc/clip_list'), ('/rpc/child_clip_list'), ('/rpc/clip_get'), ('/rpc/clip_delete'),
  ('/rpc/consent_withdraw');

insert into private.rate_rules (path, max_hits, window_seconds) values
  ('/rpc/clip_create', 30, 3600),
  ('/rpc/clip_uploaded', 60, 3600),
  ('/rpc/clip_confirm_court', 30, 3600),
  ('/rpc/clip_delete', 60, 3600),
  ('/rpc/clip_extend', 30, 3600),
  ('/rpc/consent_withdraw', 30, 3600),
  ('/rpc/clip_list', 600, 3600),
  ('/rpc/clip_get', 600, 3600),
  ('/rpc/child_clip_list', 300, 3600),
  ('/rpc/analysis_status', 300, 3600);

-- The sweep runs through the same worker tick as money.
select cron.schedule('analysis-sweep', '*/5 * * * *', $$select private.worker_tick('clips')$$);
