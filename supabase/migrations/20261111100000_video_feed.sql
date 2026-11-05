-- P5-06: adults post short videos. Nothing shows until it passes the checks, and
-- a person sees each user's first posts. Under-18s watch people they follow and
-- never post (Q180). Restricted children get nothing, and every read says so
-- here as well as at the request gate. Workers only send verdicts: the database
-- decides what happens to a post.

insert into public.feature_flags (key, enabled, description) values
  ('video.feed', false, 'Video feed. Off until providers are set and the lawyer answers Q213'),
  ('feed.fake_checks', false, 'Lets the local stand-in pass a post. Never on outside a local stack');

insert into public.app_settings (key, value, description) values
  ('feed.max_seconds', '60', 'Longest post (Q216)'),
  ('feed.max_mb', '100', 'Largest post (Q216)'),
  ('feed.daily_posts', '5', 'Posts one person can make in 24 hours (Q216)'),
  ('feed.list_length', '50', 'Posts in a list, which then ends (Q217)'),
  ('feed.url_seconds', '300', 'How long a link to a video lasts'),
  ('feed.first_posts_reviewed', '3', 'Approved posts before the automatic checks decide'),
  ('feed.frames_per_second', '1', 'Frames checked per second of video (Q218)'),
  ('feed.job_timeout_seconds', '300', 'How long a worker has to check one post'),
  ('feed.review_hours', '24', 'Hours to review a first post (Q219)'),
  ('feed.rejected_days', '30', 'Days a rejected or failed post stays in My posts');

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('feed-videos', 'feed-videos', false, 104857600, array['video/mp4', 'video/quicktime', 'image/jpeg']);

create table public.video_posts (
  id uuid primary key,
  author_id uuid not null references auth.users (id) on delete cascade,
  -- Named body so private.check_text reads it.
  body text not null default '' check (char_length(body) <= 300),
  sport text not null check (sport in (
    'badminton', 'pickleball', 'tennis', 'padel', 'table_tennis',
    'basketball', 'football', 'running', 'swimming', 'cycling'
  )),
  country_code text not null,
  audience text not null default 'followers' check (audience in ('public', 'followers')),
  ext text not null check (ext in ('mp4', 'mov')),
  seconds int not null check (seconds between 1 and 3600),
  bytes bigint not null check (bytes > 0),
  status text not null default 'waiting'
    check (status in ('waiting', 'checking', 'review', 'live', 'rejected', 'failed', 'blocked', 'deleted')),
  -- Where the file is. Stream later, with no change here.
  video_host text not null default 'storage' check (video_host in ('storage')),
  video_ref text not null,
  poster boolean not null default false,
  flagged boolean not null default false,
  hash_cleared_at timestamptz,
  approved_at timestamptz,
  approved_by uuid references auth.users (id) on delete set null,
  live_at timestamptz,
  hidden_at timestamptz,
  -- The author cleared a blocked post from My posts. The post itself stays.
  dismissed boolean not null default false,
  no_minors_at timestamptz not null,
  created_at timestamptz not null default now(),
  -- Nothing reaches a person without a passed hash match.
  constraint video_posts_hash_cleared check (status not in ('review', 'live') or hash_cleared_at is not null)
);
create index video_posts_author_idx on public.video_posts (author_id, created_at desc);
create index video_posts_live_idx on public.video_posts (live_at desc) where status = 'live' and hidden_at is null;
create index video_posts_review_idx on public.video_posts (created_at) where status = 'review';

create table public.post_likes (
  post_id uuid not null references public.video_posts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
create index post_likes_user_idx on public.post_likes (user_id);

create table public.post_jobs (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null unique references public.video_posts (id) on delete cascade,
  status text not null default 'queued' check (status in ('queued', 'claimed', 'done', 'failed')),
  -- Only a hash is kept, and it's cleared when the job ends.
  token_hash text,
  deadline timestamptz,
  attempts int not null default 0,
  worker_seconds int,
  error_code text,
  created_at timestamptz not null default now(),
  finished_at timestamptz
);
create index post_jobs_queue_idx on public.post_jobs (created_at) where status = 'queued';
create index post_jobs_deadline_idx on public.post_jobs (deadline) where status = 'claimed';

-- No foreign keys, so a match outlives the post and the account. What the law
-- wants done with it is Q213.
create table public.abuse_matches (
  id bigint generated always as identity primary key,
  post_id uuid not null unique,
  author_id uuid not null,
  video_host text not null,
  video_ref text not null,
  matcher text not null,
  match_ref text,
  created_at timestamptz not null default now()
);
create index abuse_matches_author_idx on public.abuse_matches (author_id);

do $$
declare
  t text;
begin
  foreach t in array array['video_posts', 'post_likes', 'post_jobs', 'abuse_matches']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
  end loop;
end;
$$;

-- ─── States ────────────────────────────────────────────────────────────────

create table private.post_transitions (
  from_status text not null,
  to_status text not null,
  primary key (from_status, to_status)
);
insert into private.post_transitions values
  ('waiting', 'checking'), ('waiting', 'deleted'),
  ('checking', 'live'), ('checking', 'review'), ('checking', 'rejected'), ('checking', 'blocked'),
  ('checking', 'failed'), ('checking', 'deleted'),
  ('review', 'live'), ('review', 'rejected'), ('review', 'deleted'),
  ('failed', 'checking'), ('failed', 'deleted'),
  ('live', 'deleted'), ('rejected', 'deleted'),
  -- A post deleted during its check still gets the verdict.
  ('deleted', 'blocked');

create function private.post_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if (new.id, new.author_id, new.video_ref, new.video_host, new.no_minors_at)
      is distinct from (old.id, old.author_id, old.video_ref, old.video_host, old.no_minors_at) then
    raise exception 'A post''s identity can''t change';
  end if;
  if new.status <> old.status and not exists (
      select 1 from private.post_transitions t
      where t.from_status = old.status and t.to_status = new.status) then
    raise exception 'A post can''t go from % to %', old.status, new.status;
  end if;
  return new;
end;
$$;
create trigger video_posts_guard before update on public.video_posts
  for each row execute function private.post_guard();

create trigger video_posts_check_text before insert or update of body on public.video_posts
  for each row execute function private.check_text();

create function private.abuse_keep() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception 'A match can''t change';
end;
$$;
create trigger abuse_matches_keep before update or delete on public.abuse_matches
  for each row execute function private.abuse_keep();

-- ─── Files ─────────────────────────────────────────────────────────────────

create function private.post_poster_ref(p public.video_posts) returns text
language sql immutable set search_path = '' as $$
  select p.author_id::text || '/' || p.id::text || '.poster.jpg';
$$;
revoke execute on function private.post_poster_ref(public.video_posts) from public, anon, authenticated;

-- Blocked files stay where they are until the lawyer says what happens to them.
create function private.post_queue_files() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: fires for whoever deleted the row, including an account deletion.
begin
  if old.status <> 'blocked' and old.video_host = 'storage' then
    insert into public.storage_deletions (bucket, path)
    values ('feed-videos', old.video_ref), ('feed-videos', private.post_poster_ref(old));
  end if;
  return old;
end;
$$;
create trigger video_posts_queue_files before delete on public.video_posts
  for each row execute function private.post_queue_files();

-- ─── Who sees what ─────────────────────────────────────────────────────────

-- Every read, like and play comes through here.
create function private.post_visible(p public.video_posts, p_viewer uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads the follow and block graph for any viewer.
  select p_viewer is not null
    and p.status = 'live' and p.hidden_at is null
    and not private.is_restricted(p_viewer)
    and not public.is_blocked_between(p.author_id, p_viewer)
    and not private.is_minor(p.author_id)
    and not private.is_suspended(p.author_id)
    and exists (select 1 from public.profiles a
      where a.id = p.author_id and a.hidden_at is null and a.visibility <> 'only_me')
    and (exists (select 1 from public.follows f where f.follower_id = p_viewer and f.followee_id = p.author_id)
      or (p.audience = 'public' and not private.is_minor(p_viewer)));
$$;
revoke execute on function private.post_visible(public.video_posts, uuid) from public, anon, authenticated;

create function private.post_json(p public.video_posts, p_viewer uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: likes have no client access.
  select jsonb_build_object('id', p.id, 'author_id', p.author_id, 'author', private.public_name(p.author_id),
    'caption', p.body, 'sport', p.sport, 'seconds', p.seconds, 'poster', p.poster, 'audience', p.audience,
    'likes', (select count(*) from public.post_likes l where l.post_id = p.id),
    'liked', exists (select 1 from public.post_likes l where l.post_id = p.id and l.user_id = p_viewer),
    'mine', p.author_id = p_viewer, 'live_at', p.live_at);
$$;
revoke execute on function private.post_json(public.video_posts, uuid) from public, anon, authenticated;

-- The same refusals for every read, so none depends on the gate alone.
create function private.feed_gate(p_user uuid) returns void
language plpgsql stable set search_path = '' as $$
begin
  if p_user is null then raise exception 'Log in first.'; end if;
  if private.is_suspended(p_user) then raise exception 'Your account is suspended.'; end if;
  if private.is_restricted(p_user) then raise exception 'Ask a parent to link your account first.'; end if;
  if not private.flag('video.feed') then raise exception 'Videos are not open yet.'; end if;
end;
$$;
revoke execute on function private.feed_gate(uuid) from public, anon, authenticated;

create function public.feed_status() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads flags and age for the caller.
declare
  v_user uuid := auth.uid();
  v_open boolean;
  v_adult boolean;
begin
  if v_user is null then raise exception 'Log in first.'; end if;
  v_open := private.flag('video.feed') and not private.is_restricted(v_user);
  v_adult := not private.is_minor(v_user);
  return jsonb_build_object('open', v_open, 'can_post', v_open and v_adult, 'can_discover', v_open and v_adult,
    'max_seconds', private.setting_int('feed.max_seconds'), 'max_mb', private.setting_int('feed.max_mb'));
end;
$$;

-- People you follow, newest first. It ends.
create function public.feed_following() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: posts have no client access. post_visible decides each one.
declare
  v_user uuid := auth.uid();
begin
  perform private.feed_gate(v_user);
  return (select coalesce(jsonb_agg(private.post_json(x, v_user) order by x.live_at desc), '[]'::jsonb)
    from (select p.* from public.video_posts p
      join public.follows f on f.followee_id = p.author_id and f.follower_id = v_user
      where p.status = 'live' and private.post_visible(p, v_user)
      order by p.live_at desc limit private.setting_int('feed.list_length')) x);
end;
$$;

-- Newest public posts from your country and sports. Adults only. It ends too.
create function public.feed_discover() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: posts have no client access. post_visible decides each one.
declare
  v_user uuid := auth.uid();
  v_country text;
begin
  perform private.feed_gate(v_user);
  if private.is_minor(v_user) then raise exception 'Discover is for adults.'; end if;
  select p.country_code into v_country from public.profiles p where p.id = v_user;
  return (select coalesce(jsonb_agg(private.post_json(x, v_user) order by x.live_at desc), '[]'::jsonb)
    from (select p.* from public.video_posts p
      where p.status = 'live' and p.audience = 'public' and p.country_code = v_country
        and p.author_id <> v_user
        and (exists (select 1 from public.player_sports s where s.user_id = v_user and s.sport = p.sport)
          or not exists (select 1 from public.player_sports s where s.user_id = v_user))
        and private.post_visible(p, v_user)
      order by p.live_at desc limit private.setting_int('feed.list_length')) x);
end;
$$;

-- ─── Posting ───────────────────────────────────────────────────────────────

-- The phone makes the id, so a retry reaches the same post.
create function public.post_create(p_post uuid, p_ext text, p_seconds int, p_bytes bigint, p_caption text,
  p_sport text, p_audience text, p_no_minors boolean) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: the tables have no client access.
declare
  v_user uuid := auth.uid();
  p public.video_posts;
begin
  perform private.feed_gate(v_user);
  if private.is_minor(v_user) then raise exception 'Posting is for adults for now.'; end if;
  if p_no_minors is distinct from true then
    raise exception 'Check that no one under 18 is in the video.';
  end if;
  if p_ext is null or p_ext not in ('mp4', 'mov') then raise exception 'Choose an MP4 or MOV video.'; end if;
  if p_seconds is null or p_seconds < 1 or p_seconds > private.setting_int('feed.max_seconds') then
    raise exception 'That video is too long.';
  end if;
  if p_bytes is null or p_bytes < 1 or p_bytes > private.setting_int('feed.max_mb')::bigint * 1048576 then
    raise exception 'That video is too big.';
  end if;
  if p_post is null then raise exception 'This post can''t be added.'; end if;
  if p_audience is null or p_audience not in ('public', 'followers') then raise exception 'Choose who can see this.'; end if;

  select * into p from public.video_posts v where v.id = p_post;
  if p.id is not null then
    if p.author_id <> v_user then raise exception 'This post can''t be added.'; end if;
    return jsonb_build_object('id', p.id, 'status', p.status);
  end if;

  perform pg_advisory_xact_lock(hashtextextended('feed:' || v_user::text, 0));
  if (select count(*) from public.video_posts v
      where v.author_id = v_user and v.created_at > now() - interval '24 hours')
      >= private.setting_int('feed.daily_posts') then
    raise exception 'That''s all your posts for today. Try again tomorrow.';
  end if;
  insert into public.video_posts (id, author_id, body, sport, country_code, audience, ext, seconds, bytes,
    video_ref, no_minors_at)
  select p_post, v_user, coalesce(btrim(p_caption), ''), p_sport, a.country_code, p_audience, p_ext, p_seconds,
    p_bytes, v_user::text || '/' || p_post::text || '.' || p_ext, now()
  from public.profiles a where a.id = v_user
  on conflict (id) do nothing
  returning * into p;
  if p.id is null then raise exception 'This post can''t be added.'; end if;
  return jsonb_build_object('id', p.id, 'status', p.status);
end;
$$;

-- Where the phone sends the file. The function signs it for this post alone.
create function public.post_upload_target(p_post uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: posts have no client access.
declare
  v_user uuid := auth.uid();
  p public.video_posts;
begin
  perform private.feed_gate(v_user);
  select * into p from public.video_posts v where v.id = p_post and v.author_id = v_user;
  if p.id is null or p.status <> 'waiting' then raise exception 'This post can''t be uploaded.'; end if;
  return jsonb_build_object('host', p.video_host, 'ref', p.video_ref);
end;
$$;

-- The file is in. Queues its checks.
create function public.post_uploaded(p_post uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: reads Storage's own table and writes jobs.
declare
  v_user uuid := auth.uid();
  p public.video_posts;
  v_size bigint;
begin
  perform private.feed_gate(v_user);
  select * into p from public.video_posts v where v.id = p_post and v.author_id = v_user for update;
  if p.id is null then raise exception 'Post not found.'; end if;
  if p.status <> 'waiting' then return; end if;
  select (o.metadata ->> 'size')::bigint into v_size from storage.objects o
  where o.bucket_id = 'feed-videos' and o.name = p.video_ref;
  if not found then raise exception 'The upload didn''t finish. Try again.'; end if;
  if v_size > private.setting_int('feed.max_mb')::bigint * 1048576 then
    raise exception 'That video is too big.';
  end if;
  update public.video_posts v set status = 'checking' where v.id = p.id;
  insert into public.post_jobs (post_id) values (p.id);
end;
$$;

-- Checks that couldn't finish can run again. The post still has to pass.
create function public.post_retry(p_post uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes jobs.
declare
  v_user uuid := auth.uid();
  p public.video_posts;
begin
  perform private.feed_gate(v_user);
  select * into p from public.video_posts v where v.id = p_post and v.author_id = v_user for update;
  if p.id is null then raise exception 'Post not found.'; end if;
  if p.status <> 'failed' then return; end if;
  update public.post_jobs j set status = 'queued', attempts = 0, error_code = null, finished_at = null
  where j.post_id = p.id;
  update public.video_posts v set status = 'checking' where v.id = p.id;
end;
$$;

-- Marks it. The sweep takes the row and file once no check or case needs them,
-- so a video deleted mid-check still gets its verdict.
create function public.post_delete(p_post uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: stays open to accounts that can do nothing else.
declare
  v_user uuid := auth.uid();
  p public.video_posts;
begin
  if v_user is null then raise exception 'Log in first.'; end if;
  select * into p from public.video_posts v where v.id = p_post and v.author_id = v_user for update;
  if p.id is null then raise exception 'Post not found.'; end if;
  if p.status = 'deleted' then return; end if;
  if p.status = 'blocked' then
    update public.video_posts v set dismissed = true where v.id = p.id;
    return;
  end if;
  update public.video_posts v set status = 'deleted' where v.id = p.id;
end;
$$;

-- A blocked post reads as rejected, with the same reason, so the list tells
-- nobody a match was made.
create function public.post_mine() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: posts have no client access.
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Log in first.'; end if;
  return (select coalesce(jsonb_agg(private.post_json(p, v_user) || jsonb_build_object(
      'status', case when p.status = 'blocked' then 'rejected'
        when p.status = 'live' and p.hidden_at is not null then 'removed'
        else p.status end,
      'created_at', p.created_at) order by p.created_at desc), '[]'::jsonb)
    from public.video_posts p
    where p.author_id = v_user and p.status <> 'deleted' and not p.dismissed);
end;
$$;

create function public.post_like(p_post uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: likes have no client access.
declare
  v_user uuid := auth.uid();
  p public.video_posts;
begin
  perform private.feed_gate(v_user);
  select * into p from public.video_posts v where v.id = p_post;
  if p.id is null or not private.post_visible(p, v_user) then raise exception 'This video isn''t available.'; end if;
  insert into public.post_likes (post_id, user_id) values (p.id, v_user) on conflict do nothing;
end;
$$;

create function public.post_unlike(p_post uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: likes have no client access.
declare
  v_user uuid := auth.uid();
begin
  perform private.feed_gate(v_user);
  delete from public.post_likes l where l.post_id = p_post and l.user_id = v_user;
end;
$$;

-- What the function signs for a viewer who asked to play one video.
create function public.post_play(p_post uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: posts have no client access. post_visible decides.
declare
  v_user uuid := auth.uid();
  p public.video_posts;
begin
  perform private.feed_gate(v_user);
  select * into p from public.video_posts v where v.id = p_post;
  if p.id is null or not (private.post_visible(p, v_user)
      or (p.author_id = v_user and p.status in ('checking', 'review', 'live', 'failed'))) then
    raise exception 'This video isn''t available.';
  end if;
  return jsonb_build_object('host', p.video_host, 'ref', p.video_ref);
end;
$$;

-- Posters for a list, only for posts this viewer may see.
create function public.post_posters(p_posts uuid[]) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: posts have no client access.
declare
  v_user uuid := auth.uid();
begin
  perform private.feed_gate(v_user);
  if coalesce(array_length(p_posts, 1), 0) > private.setting_int('feed.list_length') then
    raise exception 'Too many posts.';
  end if;
  return (select coalesce(jsonb_object_agg(p.id, private.post_poster_ref(p)), '{}'::jsonb)
    from public.video_posts p
    where p.id = any (p_posts) and p.poster and private.post_visible(p, v_user));
end;
$$;

-- ─── Workers ───────────────────────────────────────────────────────────────

-- The oldest job, with a token for that job alone. The author's name stays here.
create function public.feed_svc_claim() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only.
declare
  j public.post_jobs;
  p public.video_posts;
  v_token text;
  v_timeout int := private.setting_int('feed.job_timeout_seconds');
begin
  if not private.flag('video.feed') then return null; end if;
  -- The post first, then the job, the same order everything else locks in.
  select v.* into p from public.video_posts v
  join public.post_jobs x on x.post_id = v.id
  where x.status = 'queued' order by x.created_at for update of v skip locked limit 1;
  if p.id is null then return null; end if;
  select * into j from public.post_jobs x where x.post_id = p.id and x.status = 'queued' for update;
  if j.id is null then return null; end if;
  v_token := encode(extensions.gen_random_bytes(32), 'hex');
  update public.post_jobs x set status = 'claimed', attempts = x.attempts + 1,
    deadline = now() + make_interval(secs => v_timeout),
    token_hash = encode(extensions.digest(v_token, 'sha256'), 'hex')
  where x.id = j.id;
  return jsonb_build_object('job_id', j.id, 'token', v_token, 'timeout_seconds', v_timeout,
    'host', p.video_host, 'ref', p.video_ref, 'frames_per_second', private.setting_int('feed.frames_per_second'),
    'max_seconds', private.setting_int('feed.max_seconds'));
end;
$$;

-- Proves a token before anything is spent on it, and says where a poster goes.
create function public.feed_svc_job(p_job uuid, p_token text) returns text
language sql stable security definer set search_path = '' as $$
  -- Definer: service role only.
  select private.post_poster_ref(p)
  from public.post_jobs j join public.video_posts p on p.id = j.post_id
  where j.id = p_job and j.status = 'claimed' and j.deadline >= now()
    and p_token is not null and j.token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex');
$$;

-- p_hash: clear or match. p_frames: clear, flag or reject. Without p_ok the
-- checks couldn't finish, so the post waits or fails. It never goes through.
create function public.feed_svc_result(p_job uuid, p_token text, p_ok boolean, p_hash text, p_frames text,
  p_checker text, p_match_ref text, p_poster boolean, p_code text, p_worker_seconds int) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only. The token is what proves which job this is.
declare
  j public.post_jobs;
  p public.video_posts;
  v_author uuid;
  v_status text;
begin
  select v.author_id into v_author from public.video_posts v
  where v.id = (select x.post_id from public.post_jobs x where x.id = p_job);
  if v_author is null then raise exception 'Unknown job.'; end if;
  perform pg_advisory_xact_lock(hashtextextended('feed:' || v_author::text, 0));

  select * into p from public.video_posts v
  where v.id = (select x.post_id from public.post_jobs x where x.id = p_job) for update;
  select * into j from public.post_jobs x where x.id = p_job for update;
  if j.status in ('done', 'failed') then return p.status; end if;
  if j.status <> 'claimed' or j.token_hash is null or p_token is null
      or j.token_hash <> encode(extensions.digest(p_token, 'sha256'), 'hex') or j.deadline < now() then
    raise exception 'Bad token.';
  end if;

  if p_ok is distinct from true then
    if j.attempts < 3 then
      update public.post_jobs x set status = 'queued', token_hash = null, deadline = null where x.id = j.id;
      return 'retry';
    end if;
    update public.post_jobs x set status = 'failed', token_hash = null, deadline = null,
      error_code = left(coalesce(p_code, 'internal'), 40), finished_at = now()
    where x.id = j.id;
    if p.status = 'checking' then
      update public.video_posts v set status = 'failed' where v.id = p.id;
      return 'failed';
    end if;
    return p.status;
  end if;

  if p_hash is null or p_hash not in ('clear', 'match') or p_frames is null
      or p_frames not in ('clear', 'flag', 'reject') or p_checker is null or p_checker = '' then
    raise exception 'Bad result.';
  end if;
  if p_checker = 'local-fake' and not private.flag('feed.fake_checks') then raise exception 'Bad result.'; end if;

  update public.post_jobs x set status = 'done', token_hash = null, deadline = null, finished_at = now(),
    worker_seconds = p_worker_seconds
  where x.id = j.id;

  if p_hash = 'match' then
    insert into public.abuse_matches (post_id, author_id, video_host, video_ref, matcher, match_ref)
    values (p.id, p.author_id, p.video_host, p.video_ref, p_checker, p_match_ref);
    update public.video_posts v set status = 'blocked', hidden_at = now(), poster = false where v.id = p.id;
    -- No owner on the case, so nothing tells the author a match was made.
    insert into public.moderation_cases as m (target_kind, target_id, owner_id, involves_child, deadline_at, hidden_at)
    values ('video', p.id::text, null, true,
      now() + make_interval(hours => private.setting_int('moderation.child_deadline_hours')), now())
    on conflict (target_kind, target_id) do update
      set owner_id = null, involves_child = true, status = 'open', hidden_at = now(),
        deadline_at = least(m.deadline_at, excluded.deadline_at);
    return 'blocked';
  end if;

  -- Deleted during the check: nothing goes up, whatever the frames said.
  if p.status = 'deleted' then return 'deleted'; end if;

  v_status := case
    when p_frames = 'reject' then 'rejected'
    when p_frames = 'flag'
      or (select count(*) from public.video_posts v where v.author_id = p.author_id and v.approved_at is not null)
        < private.setting_int('feed.first_posts_reviewed')
      or exists (select 1 from public.abuse_matches m where m.author_id = p.author_id) then 'review'
    else 'live' end;
  update public.video_posts v set status = v_status, hash_cleared_at = now(), flagged = p_frames = 'flag',
    poster = coalesce(p_poster, false) and v_status <> 'rejected',
    live_at = case when v_status = 'live' then now() end
  where v.id = p.id;
  return v_status;
end;
$$;

-- Times out stuck checks and clears what's finished with. The files themselves
-- go through the shared delete queue.
create function public.feed_svc_sweep() returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only.
declare
  v_count int;
begin
  perform 1 from public.video_posts v
  where v.id in (select j.post_id from public.post_jobs j where j.status = 'claimed' and j.deadline < now())
  order by v.id for update of v;

  update public.post_jobs j set status = case when j.attempts < 3 then 'queued' else 'failed' end,
    token_hash = null, deadline = null, error_code = case when j.attempts < 3 then null else 'timeout' end,
    finished_at = case when j.attempts < 3 then null else now() end
  where j.status = 'claimed' and j.deadline < now();
  update public.video_posts v set status = 'failed'
  from public.post_jobs j
  where j.post_id = v.id and j.status = 'failed' and v.status = 'checking';

  -- An upload that never finished.
  delete from public.video_posts v where v.status = 'waiting' and v.created_at < now() - interval '1 day';

  delete from public.video_posts v
  where (v.status = 'deleted' or (v.status in ('rejected', 'failed')
      and v.created_at < now() - make_interval(days => private.setting_int('feed.rejected_days'))))
    and not exists (select 1 from public.post_jobs j where j.post_id = v.id and j.status in ('queued', 'claimed'))
    and not exists (select 1 from public.moderation_cases c
      where c.target_kind = 'video' and c.target_id = v.id::text and c.status = 'open');

  -- The safety net. A matched file stays, even with its post gone.
  insert into public.storage_deletions (bucket, path)
  select 'feed-videos', o.name from storage.objects o
  where o.bucket_id = 'feed-videos' and o.created_at < now() - interval '1 hour'
    and not exists (select 1 from public.video_posts p
      where p.id::text = substring(o.name from '/([0-9a-f-]{36})\.'))
    and not exists (select 1 from public.abuse_matches m
      where m.post_id::text = substring(o.name from '/([0-9a-f-]{36})\.'))
    and not exists (select 1 from public.storage_deletions d where d.bucket = 'feed-videos' and d.path = o.name)
  limit 500;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- ─── Moderation ────────────────────────────────────────────────────────────

create or replace function private.case_set_hidden(p_kind text, p_id text, p_hidden boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: hides rows the caller does not own.
declare
  v_at timestamptz := case when p_hidden then now() end;
begin
  case p_kind
    when 'player' then update public.profiles set hidden_at = v_at where id = p_id::uuid;
    when 'dm' then update public.messages set hidden_at = v_at where id::text = p_id;
    when 'message' then update public.group_messages set removed = p_hidden where id::text = p_id;
    when 'activity' then update public.activities set hidden_at = v_at where id = p_id::uuid;
    when 'club' then update public.clubs set hidden_at = v_at where id = p_id::uuid;
    when 'team' then update public.teams set hidden_at = v_at where id = p_id::uuid;
    when 'listing' then update public.products set hidden_at = v_at where id::text = p_id;
    -- Status stays, so keeping a case can't bring back a blocked post.
    when 'video' then update public.video_posts set hidden_at = v_at where id::text = p_id and status <> 'blocked';
    else null;
  end case;
end;
$$;

create or replace function private.case_owner(p_kind text, p_id text) returns uuid
language sql stable security definer set search_path = '' as $$
  -- Definer: reads who posted something the caller cannot see.
  select case p_kind
    when 'player' then p_id::uuid
    when 'dm' then (select sender_id from public.messages where id::text = p_id)
    when 'message' then (select sender_id from public.group_messages where id::text = p_id)
    when 'activity' then (select host_id from public.activities where id::text = p_id)
    when 'club' then (select owner_id from public.clubs where id::text = p_id)
    when 'video' then (select author_id from public.video_posts where id::text = p_id and status <> 'blocked')
  end;
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
    when 'video' then (select coalesce(nullif(body, ''), 'Video with no caption') from public.video_posts where id::text = p_id)
  end;
$$;

create function private.post_exists(p_id text) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reporters can't read posts directly.
  select exists (select 1 from public.video_posts v where v.id::text = p_id);
$$;
revoke execute on function private.post_exists(text) from public, anon;
grant execute on function private.post_exists(text) to authenticated;

create policy "Video reports name a real post" on public.content_reports
  as restrictive for insert to authenticated
  with check (target_kind <> 'video' or private.post_exists(target_id));

-- ─── Staff ─────────────────────────────────────────────────────────────────

-- Oldest first, because each one has a deadline.
create function public.staff_post_queue() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: posts have no client access. The role is checked here.
begin
  perform private.staff_require('moderator');
  return (select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'caption', p.body, 'sport', p.sport,
      'seconds', p.seconds, 'flagged', p.flagged, 'created_at', p.created_at,
      'deadline_at', p.created_at + make_interval(hours => private.setting_int('feed.review_hours')))
    order by p.created_at), '[]'::jsonb)
    from public.video_posts p where p.status = 'review' and p.author_id <> auth.uid());
end;
$$;

create function public.staff_post_decide(p_post uuid, p_outcome text, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes posts, notices and the audit log.
declare
  v_author uuid;
  p public.video_posts;
begin
  perform private.staff_require('moderator');
  if p_outcome is null or p_outcome not in ('live', 'rejected') then raise exception 'Choose an outcome.'; end if;
  if p_reason is null or btrim(p_reason) = '' then raise exception 'Give a reason.'; end if;
  select v.author_id into v_author from public.video_posts v where v.id = p_post;
  if v_author is null then raise exception 'Not found.'; end if;
  perform pg_advisory_xact_lock(hashtextextended('feed:' || v_author::text, 0));
  select * into p from public.video_posts v where v.id = p_post for update;
  if p.status <> 'review' then raise exception 'This post has already been decided.'; end if;
  if p.author_id = auth.uid() then raise exception 'Someone else has to decide your own post.'; end if;
  if p_outcome = 'live' then
    update public.video_posts v set status = 'live', approved_at = now(), approved_by = auth.uid(), live_at = now()
    where v.id = p.id;
  else
    update public.video_posts v set status = 'rejected', poster = false where v.id = p.id;
    insert into public.content_removals (user_id, what, where_text, rule, decided_by, why, next)
    values (p.author_id, 'video', 'video', 'Community rules', 'Olympus safety team', p_reason, '{}');
  end if;
  perform private.staff_audit('post_' || p_outcome, 'post', p.id::text, p_reason);
end;
$$;

-- A person looks at a post only to decide on it, and every look is recorded. A
-- matched file is never played.
create function public.staff_post_play(p_post uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: posts have no client access.
declare
  p public.video_posts;
begin
  perform private.staff_require('moderator');
  select * into p from public.video_posts v where v.id = p_post;
  if p.id is null or p.status = 'blocked' or not (p.status = 'review' or exists (
      select 1 from public.moderation_cases c
      where c.target_kind = 'video' and c.target_id = p.id::text and c.status = 'open')) then
    raise exception 'This video can''t be played.';
  end if;
  perform private.staff_audit('post_viewed', 'post', p.id::text, 'Reviewing');
  return jsonb_build_object('host', p.video_host, 'ref', p.video_ref);
end;
$$;

-- ─── Grants ────────────────────────────────────────────────────────────────

do $$
declare
  f text;
begin
  foreach f in array array[
    'feed_status()', 'feed_following()', 'feed_discover()',
    'post_create(uuid, text, integer, bigint, text, text, text, boolean)', 'post_upload_target(uuid)',
    'post_uploaded(uuid)', 'post_retry(uuid)', 'post_delete(uuid)', 'post_mine()', 'post_like(uuid)',
    'post_unlike(uuid)', 'post_play(uuid)', 'post_posters(uuid[])', 'staff_post_queue()',
    'staff_post_decide(uuid, text, text)', 'staff_post_play(uuid)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
  foreach f in array array[
    'feed_svc_claim()', 'feed_svc_job(uuid, text)',
    'feed_svc_result(uuid, text, boolean, text, text, text, text, boolean, text, integer)', 'feed_svc_sweep()']
  loop
    execute format('revoke execute on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to service_role', f);
  end loop;
end;
$$;

-- Seeing your own posts and removing them stay open, whatever your state.
insert into private.restricted_allow (path) values
  ('/rpc/feed_status'), ('/rpc/post_mine'), ('/rpc/post_delete');
insert into private.suspended_allow (path) values
  ('/rpc/feed_status'), ('/rpc/post_mine'), ('/rpc/post_delete');

insert into private.rate_rules (path, max_hits, window_seconds) values
  ('/rpc/post_create', 30, 3600),
  ('/rpc/post_upload_target', 60, 3600),
  ('/rpc/post_uploaded', 60, 3600),
  ('/rpc/post_retry', 10, 3600),
  ('/rpc/post_delete', 60, 3600),
  ('/rpc/post_like', 600, 3600),
  ('/rpc/post_unlike', 600, 3600),
  ('/rpc/post_play', 600, 3600),
  ('/rpc/post_posters', 300, 3600),
  ('/rpc/post_mine', 300, 3600),
  ('/rpc/feed_status', 300, 3600),
  ('/rpc/feed_following', 300, 3600),
  ('/rpc/feed_discover', 300, 3600);
