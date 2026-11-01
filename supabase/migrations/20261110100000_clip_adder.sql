-- P5-03: says whether the caller added the clip. Any linked parent can read one,
-- but only the one who added it marks the court, so the app shouldn't offer it
-- to the other.
create or replace function private.clip_json(c public.video_clips) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object('id', c.id, 'status', c.status, 'error_code', c.error_code, 'sport', c.sport,
    'seconds', c.seconds, 'side', c.side, 'corners', c.corners, 'created_at', c.created_at,
    'purge_at', c.purge_at, 'file_gone', c.file_gone_at is not null,
    'can_extend', c.file_gone_at is null and c.status <> 'withdrawn'
      and c.extensions < private.setting_int('video.max_extensions'),
    'for_child', c.subject_id <> c.owner_id,
    'child', case when c.subject_id <> c.owner_id then
      (select p.full_name from public.profiles p where p.id = c.subject_id) end,
    'frame', case when c.frame and c.file_gone_at is null then private.clip_frame_path(c) end,
    'added_by_me', c.owner_id = auth.uid());
$$;
revoke execute on function private.clip_json(public.video_clips) from public, anon, authenticated;
