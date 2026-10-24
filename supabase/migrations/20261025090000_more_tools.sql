-- Legal notices, video reports, team fixtures and results, club ratings,
-- private chat photos and the Passport's session history.

-- ─── Legal notices (no account needed) ─────────────────────────────────────

create table public.legal_notices (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique,
  sender_role text not null check (sender_role in (
    'The person affected', 'Parent or guardian', 'Lawyer or representative',
    'Police or regulator'
  )),
  name text not null check (char_length(trim(name)) between 2 and 120),
  email text not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  country text not null check (country in ('SG', 'MY', 'ID', 'TH')),
  location text not null check (char_length(trim(location)) between 2 and 300),
  reasons text[] not null check (cardinality(reasons) between 1 and 5),
  details text not null check (char_length(trim(details)) between 10 and 4000),
  sent_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.legal_notices enable row level security;

-- Returns a reference such as OLY-2610-0412 for the reply.
create function public.legal_notice_send(p jsonb) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_ref text := 'OLY-' || to_char(now(), 'YYMM') || '-' ||
    lpad((floor(random() * 10000))::int::text, 4, '0');
begin
  if (p ->> 'true')::boolean is not true then
    raise exception 'Confirm that what you have written is true.';
  end if;
  insert into public.legal_notices (
    reference, sender_role, name, email, country, location, reasons, details, sent_by
  ) values (
    v_ref,
    p ->> 'role',
    trim(p ->> 'name'),
    trim(p ->> 'email'),
    p ->> 'country',
    trim(p ->> 'location'),
    array(select jsonb_array_elements_text(coalesce(p -> 'reasons', '[]'::jsonb))),
    trim(p ->> 'details'),
    (select auth.uid())
  );
  return v_ref;
end;
$$;
revoke execute on function public.legal_notice_send(jsonb) from public;
grant execute on function public.legal_notice_send(jsonb) to anon, authenticated;

-- ─── Video and live reports ────────────────────────────────────────────────

alter table public.content_reports drop constraint content_reports_target_kind_check;
alter table public.content_reports add constraint content_reports_target_kind_check
  check (target_kind in ('message', 'club', 'team', 'activity', 'video', 'live'));

-- ─── Team fixtures and results ─────────────────────────────────────────────

create function public.team_fixture_create(
  p_team uuid, p_opponent text, p_starts_at timestamptz, p_competition text,
  p_venue text, p_locks_at timestamptz, p_notes text[]
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_id uuid;
  v_name text;
begin
  perform public.team_require_staff(p_team);
  insert into public.team_fixtures (
    team_id, opponent, starts_at, competition, venue, lineup_locks_at, notes
  ) values (
    p_team, trim(p_opponent), p_starts_at, coalesce(p_competition, ''),
    coalesce(p_venue, ''), p_locks_at, coalesce(p_notes, '{}')
  ) returning id into v_id;
  select t.name into v_name from public.teams t where t.id = p_team;
  insert into public.notifications (user_id, title, body, mark, link)
  select m.user_id, left(v_name || ' vs ' || trim(p_opponent), 120),
    'Say if you can play.', 'Tm', '/teams/' || p_team || '/fixtures/' || v_id
  from public.team_members m
  where m.team_id = p_team and m.user_id <> (select auth.uid()) and not m.staff;
  return v_id;
end;
$$;

create function public.team_fixture_result(p_fixture uuid, p_score text, p_won boolean)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_team uuid;
begin
  select f.team_id into v_team from public.team_fixtures f where f.id = p_fixture;
  if v_team is null then
    raise exception 'This fixture no longer exists.';
  end if;
  perform public.team_require_staff(v_team);
  update public.team_fixtures
    set score = nullif(trim(p_score), ''), won = p_won
    where id = p_fixture;
end;
$$;

-- ─── Club ratings ──────────────────────────────────────────────────────────

create table public.club_ratings (
  club_id uuid not null references public.clubs (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  stars int not null check (stars between 1 and 5),
  review text not null default '' check (char_length(review) <= 500),
  created_at timestamptz not null default now(),
  primary key (club_id, user_id)
);
alter table public.club_ratings enable row level security;

-- Members rate the club they play in, once; rating again replaces it.
create function public.club_rate(p_club uuid, p_stars int, p_review text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.club_require_member(p_club);
  if exists (
    select 1 from public.clubs c where c.id = p_club and c.owner_id = (select auth.uid())
  ) then
    raise exception 'You can''t rate your own club.';
  end if;
  insert into public.club_ratings (club_id, user_id, stars, review)
  values (p_club, (select auth.uid()), p_stars, coalesce(trim(p_review), ''))
  on conflict (club_id, user_id)
  do update set stars = excluded.stars, review = excluded.review, created_at = now();
end;
$$;

-- club_json with ratings added.
create or replace function public.club_json(p_club uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  c public.clubs;
  v_me uuid := (select auth.uid());
  v_perms text[] := public.club_my_perms(p_club);
  v_member boolean := public.club_is_member(p_club);
  v_standing text;
begin
  select * into c from public.clubs where id = p_club;
  if not found then
    return null;
  end if;
  v_standing := case
    when v_member then 'member'
    when exists (
      select 1 from public.club_bans b where b.club_id = p_club and b.user_id = v_me
    ) then 'banned'
    when exists (
      select 1 from public.club_join_requests r
      where r.club_id = p_club and r.user_id = v_me and r.status = 'pending'
    ) then 'requested'
    else 'outsider'
  end;
  return jsonb_build_object(
    'id', c.id,
    'name', c.name,
    'description', c.description,
    'rules', to_jsonb(c.rules),
    'area', c.area,
    'home_venue', c.home_venue_name,
    'sports', c.sports,
    'visibility', c.visibility,
    'join_mode', c.join_mode,
    'member_count', (select count(*) from public.club_members m where m.club_id = c.id),
    'logo_color', c.logo_color,
    'logo_ink', c.logo_ink,
    'cover_color', c.cover_color,
    'created_at', c.created_at,
    'meets_per_week', (
      select count(*) from public.activities a
      where a.club_id = c.id and a.starts_at >= now()
        and a.starts_at < now() + interval '7 days'
    ),
    'standing', v_standing,
    'is_owner', c.owner_id = v_me,
    'permissions', to_jsonb(case when v_member then v_perms else '{}'::text[] end),
    'role_name', (
      select r.name from public.club_member_roles mr
      join public.club_roles r on r.id = mr.role_id
      where mr.club_id = c.id and mr.user_id = v_me and r.level <> 'label'
      order by r.position limit 1
    ),
    'pending_requests', case when 'approve' = any (v_perms) then (
      select count(*) from public.club_join_requests r
      where r.club_id = c.id and r.status = 'pending'
    ) else 0 end,
    'unread_chat', case when v_member then (
      select count(*) from public.group_messages g
      where g.club_id = c.id and g.sender_id <> v_me and g.created_at > coalesce((
        select m.chat_read_at from public.club_members m
        where m.club_id = c.id and m.user_id = v_me
      ), '-infinity'::timestamptz)
    ) else 0 end,
    'role_count', (select count(*) from public.club_roles r where r.club_id = c.id),
    'ban_count', case when 'members' = any (v_perms) then (
      select count(*) from public.club_bans b where b.club_id = c.id
    ) else 0 end,
    'active_invites', (select count(*) from public.club_invites i where i.club_id = c.id),
    'play_rules', c.play_rules,
    'invite_code', case when v_member then c.invite_code end,
    'rating', (
      select round(avg(r.stars)::numeric, 1) from public.club_ratings r where r.club_id = c.id
    ),
    'rating_count', (select count(*) from public.club_ratings r where r.club_id = c.id),
    'rating_spread', (
      select jsonb_agg(coalesce((
        select count(*) from public.club_ratings r
        where r.club_id = c.id and r.stars = s.n
      ), 0) order by s.n desc)
      from generate_series(1, 5) as s(n)
    ),
    'my_stars', (
      select r.stars from public.club_ratings r where r.club_id = c.id and r.user_id = v_me
    )
  );
end;
$$;
revoke execute on function public.club_json(uuid) from public, anon, authenticated;

-- ─── Private chat photos ───────────────────────────────────────────────────
-- Paths are club/<club id>/<sender>/<file> or team/<team id>/<sender>/<file>,
-- readable by that club's or team's members through short-lived links.

update storage.buckets set public = false where id = 'chat-photos';

drop policy "Players upload chat photos to their folder" on storage.objects;

create function public.chat_photo_allowed(p_path text) returns boolean
language plpgsql stable security definer set search_path = '' as $$
declare
  v_parts text[] := string_to_array(p_path, '/');
  v_id uuid;
begin
  if cardinality(v_parts) < 4 or v_parts[2] !~ '^[0-9a-f-]{36}$' then
    return false;
  end if;
  v_id := v_parts[2]::uuid;
  return case v_parts[1]
    when 'club' then public.club_is_member(v_id)
    when 'team' then public.team_is_member(v_id) or public.team_is_staff(v_id)
    else false
  end;
end;
$$;
grant execute on function public.chat_photo_allowed(text) to authenticated;
revoke execute on function public.chat_photo_allowed(text) from public, anon;

create policy "Members upload photos to their club or team chat" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'chat-photos'
    and (storage.foldername(name))[3] = (select auth.uid())::text
    and public.chat_photo_allowed(name)
  );

create policy "Members see their club or team chat photos" on storage.objects
  for select to authenticated
  using (bucket_id = 'chat-photos' and public.chat_photo_allowed(name));

-- ─── Passport history ──────────────────────────────────────────────────────

-- Your past sessions in one sport, with game results from confirmed scores.
create function public.passport_history(p_sport text) returns jsonb
language sql stable security definer set search_path = '' as $$
  with mine as (
    select a.id, a.kind, a.title, a.starts_at, a.ranked
    from public.activity_participants ap
    join public.activities a on a.id = ap.activity_id
    where ap.user_id = (select auth.uid()) and ap.status = 'joined'
      and a.starts_at < now() and p_sport = any (a.sports)
      and coalesce(ap.attendance, 'present') = 'present'
  ),
  games as (
    select s.activity_id,
      ((select auth.uid()) = any (s.side_a)) as on_a,
      g.value as game
    from public.match_scores s
    cross join lateral jsonb_array_elements(s.games) as g(value)
    where s.status = 'confirmed'
      and (select auth.uid()) = any (s.side_a || s.side_b)
  ),
  results as (
    select activity_id,
      count(*) as played,
      count(*) filter (where
        (on_a and (game ->> 0)::int > (game ->> 1)::int)
        or (not on_a and (game ->> 1)::int > (game ->> 0)::int)
      ) as won
    from games group by activity_id
  )
  select jsonb_build_object(
    'sessions', (select count(*) from mine),
    'ranked_games', coalesce((
      select sum(r.played) from results r join mine m on m.id = r.activity_id where m.ranked
    ), 0),
    'games_played', coalesce((
      select sum(r.played) from results r join mine m on m.id = r.activity_id
    ), 0),
    'games_won', coalesce((
      select sum(r.won) from results r join mine m on m.id = r.activity_id
    ), 0),
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', m.id, 'kind', m.kind, 'title', m.title, 'starts_at', m.starts_at,
        'ranked', m.ranked, 'played', coalesce(r.played, 0), 'won', coalesce(r.won, 0)
      ) order by m.starts_at desc)
      from mine m left join results r on r.activity_id = m.id
    ), '[]'::jsonb)
  );
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'team_fixture_create(uuid,text,timestamptz,text,text,timestamptz,text[])',
    'team_fixture_result(uuid,text,boolean)', 'club_rate(uuid,integer,text)',
    'passport_history(text)'
  ] loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;

-- ─── Report tracking ───────────────────────────────────────────────────────
-- Reviewers set the status and result; players see their own reports and can
-- ask once for a second look after a decision.

alter table public.content_reports
  add column status text not null default 'in_review'
    check (status in ('in_review', 'removed', 'no_action')),
  add column result text,
  add column decided_at timestamptz,
  add column second_look boolean not null default false;

alter table public.player_reports
  add column note text not null default '' check (char_length(note) <= 1000),
  add column status text not null default 'in_review'
    check (status in ('in_review', 'removed', 'no_action')),
  add column result text,
  add column decided_at timestamptz,
  add column second_look boolean not null default false;

create policy "Players read their own player reports" on public.player_reports
  for select to authenticated using (reporter_id = (select auth.uid()));

-- Your reports, newest first. Ids are "c:<uuid>" or "p:<number>".
create function public.my_reports() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(x.j order by x.at desc), '[]'::jsonb) from (
    select r.created_at as at, jsonb_build_object(
      'id', 'c:' || r.id,
      'kind', r.target_kind,
      'reason', r.reason,
      'at', r.created_at,
      'status', r.status,
      'result', r.result,
      'decided_at', r.decided_at,
      'second_look', r.second_look,
      'what', case r.target_kind
        when 'club' then (select c.name from public.clubs c where c.id::text = r.target_id)
        when 'activity' then (
          select a.title from public.activities a where a.id::text = r.target_id
        )
        when 'message' then (
          select coalesce(c.name, t.name) from public.group_messages g
          left join public.clubs c on c.id = g.club_id
          left join public.teams t on t.id = g.team_id
          where g.id::text = r.target_id
        )
        else null end,
      'who', case r.target_kind when 'message' then (
          select coalesce(p.full_name, p.username) from public.group_messages g
          join public.profiles p on p.id = g.sender_id
          where g.id::text = r.target_id
        ) else null end,
      'activity_kind', case r.target_kind when 'activity' then (
          select a.kind from public.activities a where a.id::text = r.target_id
        ) else null end
    ) as j
    from public.content_reports r where r.reporter_id = (select auth.uid())
    union all
    select r.created_at, jsonb_build_object(
      'id', 'p:' || r.id,
      'kind', 'player',
      'reason', r.reason,
      'at', r.created_at,
      'status', r.status,
      'result', r.result,
      'decided_at', r.decided_at,
      'second_look', r.second_look,
      'what', (select coalesce(p.full_name, p.username) from public.profiles p
        where p.id = r.reported_id),
      'who', null,
      'activity_kind', null
    )
    from public.player_reports r where r.reporter_id = (select auth.uid())
  ) x;
$$;

create function public.report_second_look(p_id text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_kind text := split_part(p_id, ':', 1);
  v_key text := split_part(p_id, ':', 2);
begin
  if v_kind = 'c' then
    update public.content_reports set second_look = true
      where id::text = v_key and reporter_id = (select auth.uid())
        and status <> 'in_review' and not second_look;
  elsif v_kind = 'p' then
    update public.player_reports set second_look = true
      where id::text = v_key and reporter_id = (select auth.uid())
        and status <> 'in_review' and not second_look;
  end if;
  if not found then
    raise exception 'You can ask once, after a decision.';
  end if;
end;
$$;

-- Something of yours a reviewer removed, and your one request for a review.
create table public.content_removals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  what text not null,
  where_text text not null default '',
  rule text not null,
  decided_by text not null default 'Olympus review team',
  why text not null default '',
  next text[] not null default '{}',
  review_asked boolean not null default false,
  review_note text not null default '' check (char_length(review_note) <= 1000),
  created_at timestamptz not null default now()
);
alter table public.content_removals enable row level security;
create policy "Players read their own removal notices" on public.content_removals
  for select to authenticated using (user_id = (select auth.uid()));

create function public.removal_ask_review(p_id uuid, p_note text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.content_removals
    set review_asked = true, review_note = coalesce(trim(p_note), '')
    where id = p_id and user_id = (select auth.uid()) and not review_asked;
  if not found then
    raise exception 'You can ask once for a review.';
  end if;
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'my_reports()', 'report_second_look(text)', 'removal_ask_review(uuid,text)'
  ] loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;

-- ─── Identity check status ─────────────────────────────────────────────────
-- Set by the review team; players can read it but never change it.

alter table public.account_private add column identity_verified_at timestamptz;

create function public.lock_identity() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.identity_verified_at is distinct from old.identity_verified_at
    and (select auth.role()) in ('authenticated', 'anon') then
    raise exception 'Identity checks are done by the review team.';
  end if;
  return new;
end;
$$;

create trigger account_private_lock_identity before update on public.account_private
  for each row execute function public.lock_identity();
