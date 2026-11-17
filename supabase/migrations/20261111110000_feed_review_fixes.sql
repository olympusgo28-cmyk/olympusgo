-- P5-06: fixes from the independent review of the feed database.

-- Rate rules write, and PostgREST runs a stable function read-only, so these
-- failed through the API. A GET also skipped the rate limit.
alter function public.feed_status() volatile;
alter function public.feed_following() volatile;
alter function public.feed_discover() volatile;
alter function public.post_upload_target(uuid) volatile;
alter function public.post_mine() volatile;
alter function public.post_play(uuid) volatile;
alter function public.post_posters(uuid[]) volatile;

-- The file that passed is the file that plays. Nothing can overwrite it now,
-- and this catches anything that ever does.
alter table public.video_posts add column file_version text;

create function private.post_file_ok(p public.video_posts) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads Storage's own table.
  select p.file_version is not distinct from (select o.version from storage.objects o
    where o.bucket_id = 'feed-videos' and o.name = p.video_ref);
$$;
revoke execute on function private.post_file_ok(public.video_posts) from public, anon, authenticated;

do $$
declare
  n text;
  d text;
  fixed text;
  pairs text[][] := array[
    -- A retry says what My posts says, so neither tells anyone about a match.
    ['public.post_create(uuid, text, integer, bigint, text, text, text, boolean)',
     $a$    return jsonb_build_object('id', p.id, 'status', p.status);
  end if;

  perform pg_advisory_xact_lock$a$,
     $a$    return jsonb_build_object('id', p.id, 'status', case when p.status <> 'blocked' then p.status
      when p.dismissed then 'deleted' else 'rejected' end);
  end if;

  -- An id with a history stays spent: a new post can't inherit a closed case,
  -- and a match on it must still land.
  if exists (select 1 from public.moderation_cases c where c.target_kind = 'video' and c.target_id = p_post::text)
      or exists (select 1 from public.abuse_matches m where m.post_id = p_post) then
    raise exception 'This post can''t be added.';
  end if;

  perform pg_advisory_xact_lock$a$],
    ['public.post_uploaded(uuid)',
     $a$  v_size bigint;
begin$a$,
     $a$  v_size bigint;
  v_version text;
begin$a$],
    ['public.post_uploaded(uuid)',
     $a$  select (o.metadata ->> 'size')::bigint into v_size from storage.objects o
  where o.bucket_id = 'feed-videos' and o.name = p.video_ref;$a$,
     $a$  select (o.metadata ->> 'size')::bigint, o.version into v_size, v_version from storage.objects o
  where o.bucket_id = 'feed-videos' and o.name = p.video_ref;$a$],
    ['public.post_uploaded(uuid)',
     $a$  update public.video_posts v set status = 'checking' where v.id = p.id;$a$,
     $a$  update public.video_posts v set status = 'checking', file_version = v_version where v.id = p.id;$a$],
    ['public.post_play(uuid)',
     $a$  if p.id is null or not (private.post_visible(p, v_user)
      or (p.author_id = v_user and p.status in ('checking', 'review', 'live', 'failed'))) then$a$,
     $a$  if p.id is null or not private.post_file_ok(p) or not (private.post_visible(p, v_user)
      or (p.author_id = v_user and p.status in ('checking', 'review', 'live', 'failed'))) then$a$],
    -- Only a file that passed the hash match reaches a person.
    ['public.staff_post_play(uuid)',
     $a$  if p.id is null or p.status = 'blocked' or not (p.status = 'review' or exists ($a$,
     $a$  if p.id is null or p.status = 'blocked' or p.hash_cleared_at is null or not private.post_file_ok(p)
      or not (p.status = 'review' or exists ($a$],
    -- Rejected posts leave My posts after a while, so a blocked one has to as well.
    ['public.post_mine()',
     $a$    where p.author_id = v_user and p.status <> 'deleted' and not p.dismissed);$a$,
     $a$    where p.author_id = v_user and p.status <> 'deleted' and not p.dismissed
      and not (p.status = 'blocked'
        and p.created_at < now() - make_interval(days => private.setting_int('feed.rejected_days'))));$a$],
    -- Deleted before a match landed stays out of My posts, as any deleted post does.
    ['public.feed_svc_result(uuid, text, boolean, text, text, text, text, boolean, text, integer)',
     $a$    update public.video_posts v set status = 'blocked', hidden_at = now(), poster = false where v.id = p.id;$a$,
     $a$    update public.video_posts v set status = 'blocked', hidden_at = now(), poster = false,
      dismissed = v.dismissed or p.status = 'deleted' where v.id = p.id;$a$],
    -- A post deleted before its checks finished still gets them, for a while.
    ['public.feed_svc_sweep()',
     $a$  -- An upload that never finished.$a$,
     $a$  update public.post_jobs j set status = 'queued', attempts = 0, error_code = null, finished_at = null
  from public.video_posts v
  where v.id = j.post_id and v.status = 'deleted' and j.status = 'failed'
    and v.created_at >= now() - make_interval(days => private.setting_int('feed.rejected_days'));

  -- An upload that never finished.$a$],
    -- A moderator doesn't decide about their own post, here or in the feed queue.
    ['public.staff_case_decide(uuid, text, text)',
     $a$  if c.id is null or c.status <> 'open' then raise exception 'This case is closed.'; end if;$a$,
     $a$  if c.id is null or c.status <> 'open' then raise exception 'This case is closed.'; end if;
  if c.owner_id = auth.uid() then raise exception 'Someone else has to decide your own case.'; end if;$a$]
  ];
  i int;
begin
  for i in 1 .. array_length(pairs, 1) loop
    n := pairs[i][1];
    d := pg_get_functiondef(n::regprocedure);
    fixed := replace(d, pairs[i][2], pairs[i][3]);
    if fixed = d then raise exception '% did not change at step %', n, i; end if;
    execute fixed;
  end loop;
end;
$$;

-- Once a post was seen clean it can be reported. Before that, a report would be
-- a way to get a person to look at something unchecked.
create or replace function private.post_exists(p_id text) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reporters can't read posts directly.
  select exists (select 1 from public.video_posts v where v.id::text = p_id and v.hash_cleared_at is not null);
$$;

create or replace function private.case_text(p_kind text, p_id text) returns text
language sql stable security definer set search_path = '' as $$
  -- Definer: staff see the reported item, whoever posted it.
  select case p_kind
    when 'dm' then (select body from public.messages where id::text = p_id)
    when 'message' then (select body from public.group_messages where id::text = p_id)
    when 'activity' then (select title from public.activities where id::text = p_id)
    when 'club' then (select name from public.clubs where id::text = p_id)
    when 'team' then (select name from public.teams where id::text = p_id)
    when 'player' then (select coalesce(full_name, username::text) from public.profiles where id::text = p_id)
    when 'listing' then (select name from public.products where id::text = p_id)
    when 'video' then (select case when status = 'blocked' then 'Blocked video'
      else coalesce(nullif(body, ''), 'Video with no caption') end from public.video_posts where id::text = p_id)
  end;
$$;

-- A failed check on a deleted post waits for its retries to run out.
do $$
declare
  n text := 'public.feed_svc_sweep()';
  d text := pg_get_functiondef(n::regprocedure);
  fixed text := replace(d,
    $a$    and not exists (select 1 from public.post_jobs j where j.post_id = v.id and j.status in ('queued', 'claimed'))$a$,
    $a$    and (v.created_at < now() - make_interval(days => private.setting_int('feed.rejected_days'))
      or not exists (select 1 from public.post_jobs j where j.post_id = v.id and j.status in ('queued', 'claimed')))$a$);
begin
  if fixed = d then raise exception 'sweep did not change'; end if;
  execute fixed;
end;
$$;

-- The rule holds whoever writes, and a service write hears it, not a grant error.
alter function private.post_guard() security definer;
