-- P5-06: fixes from the second independent review of the feed.

-- Staff can add sports, so the catalogue decides, not a list here.
alter table public.video_posts drop constraint video_posts_sport_check;

do $$
declare
  n text;
  d text;
  fixed text;
  pairs text[][] := array[
    ['public.post_create(uuid, text, integer, bigint, text, text, text, boolean)',
     $a$  if p_audience is null or p_audience not in ('public', 'followers') then raise exception 'Choose who can see this.'; end if;$a$,
     $a$  if p_audience is null or p_audience not in ('public', 'followers') then raise exception 'Choose who can see this.'; end if;
  if p_sport is null or not exists (select 1 from public.sports s where s.key = p_sport and s.status = 'live') then
    raise exception 'Choose a sport.';
  end if;
  if char_length(coalesce(btrim(p_caption), '')) > 300 then raise exception 'Keep your caption to 300 characters.'; end if;$a$],
    -- Until the file is in, a retry can change what the person chose.
    ['public.post_create(uuid, text, integer, bigint, text, text, text, boolean)',
     $a$    if p.author_id <> v_user then raise exception 'This post can''t be added.'; end if;
$a$,
     $a$    if p.author_id <> v_user then raise exception 'This post can''t be added.'; end if;
    if p.status = 'waiting' then
      update public.video_posts v set body = coalesce(btrim(p_caption), ''), sport = p_sport, audience = p_audience
      where v.id = p.id;
    end if;
$a$],
    ['public.post_mine()',
     $a$      'created_at', p.created_at) order by p.created_at desc), '[]'::jsonb)$a$,
     $a$      'reason', case when p.status = 'failed' then
        (select j.error_code from public.post_jobs j where j.post_id = p.id) end,
      'created_at', p.created_at) order by p.created_at desc), '[]'::jsonb)$a$],
    -- Some failures are about the file, and no number of tries changes them.
    ['public.feed_svc_result(uuid, text, boolean, text, text, text, text, boolean, text, integer)',
     $a$    if j.attempts < 3 then
      update public.post_jobs x set status = 'queued', token_hash = null, deadline = null where x.id = j.id;$a$,
     $a$    if j.attempts < 3 and coalesce(p_code, '') not in ('too_long', 'bad_video') then
      update public.post_jobs x set status = 'queued', token_hash = null, deadline = null where x.id = j.id;$a$],
    ['public.post_retry(uuid)',
     $a$  if p.status <> 'failed' then return; end if;
$a$,
     $a$  if p.status <> 'failed' then return; end if;
  if exists (select 1 from public.post_jobs j where j.post_id = p.id and j.error_code in ('too_long', 'bad_video')) then
    raise exception 'This video can''t be checked. Post a different one.';
  end if;
$a$],
    -- Hourly, and never for a file that can't be read at all.
    ['public.feed_svc_sweep()',
     $a$  where v.id = j.post_id and v.status = 'deleted' and j.status = 'failed'
$a$,
     $a$  where v.id = j.post_id and v.status = 'deleted' and j.status = 'failed'
    and coalesce(j.error_code, '') not in ('too_long', 'bad_video')
    and j.finished_at < now() - interval '1 hour'
$a$],
    -- And the post stays while that can still happen.
    ['public.feed_svc_sweep()',
     $a$      or not exists (select 1 from public.post_jobs j where j.post_id = v.id and j.status in ('queued', 'claimed')))$a$,
     $a$      or not exists (select 1 from public.post_jobs j where j.post_id = v.id and (j.status in ('queued', 'claimed')
        or (v.status = 'deleted' and j.status = 'failed' and coalesce(j.error_code, '') not in ('too_long', 'bad_video')))))$a$]
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
