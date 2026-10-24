-- Clubs and teams: members, roles, join requests, bans, audit log,
-- announcements, invites, fixtures, and club and team chat.
--
-- Reads go through functions that return JSON shaped for the app, with the
-- viewer's standing and permissions worked out here. Every change goes
-- through a function that checks the viewer's club role first, so the tables
-- themselves only allow what the chat needs directly.

-- ─── Clubs ─────────────────────────────────────────────────────────────────

create table public.clubs (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 60),
  description text not null default '' check (char_length(description) <= 1000),
  rules text[] not null default '{}',
  area text not null default '' check (char_length(area) <= 80),
  home_venue_id uuid references public.venues (id) on delete set null,
  home_venue_name text check (char_length(home_venue_name) <= 120),
  -- [{"sport": "badminton", "min": 0, "max": 7}], min and max as band indexes.
  sports jsonb not null default '[]' check (jsonb_typeof(sports) = 'array'),
  visibility text not null default 'public'
    check (visibility in ('public', 'private', 'hidden')),
  join_mode text not null default 'request' check (join_mode in ('anyone', 'request')),
  -- ARGB colours, as the app stores them.
  logo_color bigint not null default 4280033059,
  logo_ink bigint not null default 4294099278,
  cover_color bigint not null default 4293417228,
  play_rules jsonb not null default '{}' check (jsonb_typeof(play_rules) = 'object'),
  invite_code text not null unique
    default upper(substr(md5(gen_random_uuid()::text), 1, 6)),
  owner_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger clubs_touch before update on public.clubs
  for each row execute function public.touch_updated_at();

create table public.club_roles (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 30),
  color bigint not null default 4286218376,
  level text not null default 'member'
    check (level in ('label', 'member', 'organizer', 'admin')),
  permissions text[] not null default '{}' check (permissions <@ array[
    'create_meet', 'public_meet', 'mark_attendance', 'tournament', 'events',
    'approve', 'members', 'roles', 'edit_page', 'audit', 'fees'
  ]),
  show_badge boolean not null default true,
  is_owner boolean not null default false,
  position int not null default 0,
  created_at timestamptz not null default now()
);
create index club_roles_club_idx on public.club_roles (club_id, position);
create unique index club_roles_one_owner on public.club_roles (club_id) where is_owner;

create table public.club_members (
  club_id uuid not null references public.clubs (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  chat_read_at timestamptz,
  primary key (club_id, user_id)
);
create index club_members_user_idx on public.club_members (user_id);

create table public.club_member_roles (
  club_id uuid not null,
  user_id uuid not null,
  role_id uuid not null references public.club_roles (id) on delete cascade,
  primary key (user_id, role_id),
  foreign key (club_id, user_id)
    references public.club_members (club_id, user_id) on delete cascade
);
create index club_member_roles_club_idx on public.club_member_roles (club_id, user_id);

create table public.club_join_requests (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  message text not null default '' check (char_length(message) <= 300),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'declined', 'cancelled')),
  decided_by uuid references auth.users (id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
create unique index club_join_requests_one_pending
  on public.club_join_requests (club_id, user_id) where status = 'pending';

create table public.club_bans (
  club_id uuid not null references public.clubs (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  banned_by uuid references auth.users (id) on delete set null,
  reason text not null default '' check (char_length(reason) <= 300),
  created_at timestamptz not null default now(),
  primary key (club_id, user_id)
);

create table public.club_audit (
  id bigint generated always as identity primary key,
  club_id uuid not null references public.clubs (id) on delete cascade,
  actor_id uuid references auth.users (id) on delete set null,
  category text not null check (category in ('members', 'roles', 'meets', 'club')),
  action text not null,
  detail text not null default '',
  created_at timestamptz not null default now()
);
create index club_audit_club_idx on public.club_audit (club_id, created_at desc);

create table public.club_announcements (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs (id) on delete cascade,
  author_id uuid references auth.users (id) on delete set null,
  title text not null check (char_length(trim(title)) between 1 and 80),
  body text not null default '' check (char_length(body) <= 2000),
  audience text not null default 'everyone' check (char_length(audience) <= 60),
  pinned boolean not null default false,
  created_at timestamptz not null default now()
);
create index club_announcements_club_idx
  on public.club_announcements (club_id, created_at desc);

-- Invited players, and players who opened an invite code, can see a private
-- or hidden club and join it without a request.
create table public.club_invites (
  club_id uuid not null references public.clubs (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  invited_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (club_id, user_id)
);

-- A club hosts Meets, tournaments and events.
alter table public.activities
  add constraint activities_club_fk foreign key (club_id)
  references public.clubs (id) on delete set null not valid;

-- ─── Teams ─────────────────────────────────────────────────────────────────

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 60),
  represents text not null default '' check (char_length(represents) <= 80),
  sport text not null default 'badminton' check (sport in (
    'badminton', 'tennis', 'pickleball', 'table_tennis', 'squash', 'padel',
    'running', 'hyrox'
  )),
  season text not null default '' check (char_length(season) <= 40),
  logo_color bigint not null default 4293417228,
  logo_ink bigint not null default 4294967295,
  -- [{"name": "Under 15", "rule": "Born 2012 or later", "enabled": true}]
  sub_teams jsonb not null default '[]' check (jsonb_typeof(sub_teams) = 'array'),
  owner_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.team_clubs (
  team_id uuid not null references public.teams (id) on delete cascade,
  club_id uuid not null references public.clubs (id) on delete cascade,
  primary key (team_id, club_id)
);

create table public.team_members (
  team_id uuid not null references public.teams (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  staff boolean not null default false,
  staff_title text not null default '' check (char_length(staff_title) <= 60),
  reserve boolean not null default false,
  captain text check (captain in ('Captain', 'Vice-captain')),
  sub_team text,
  joined_at timestamptz not null default now(),
  chat_read_at timestamptz,
  primary key (team_id, user_id)
);
create index team_members_user_idx on public.team_members (user_id);

create table public.team_fixtures (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams (id) on delete cascade,
  opponent text not null check (char_length(trim(opponent)) between 1 and 80),
  starts_at timestamptz not null,
  competition text not null default '',
  venue text not null default '',
  lineup_locks_at timestamptz,
  notes text[] not null default '{}',
  -- {"S1": ["<user id>"], "D1": ["<id>", null]}
  lineup jsonb not null default '{}' check (jsonb_typeof(lineup) = 'object'),
  published boolean not null default false,
  set_by uuid references auth.users (id) on delete set null,
  score text,
  won boolean,
  created_at timestamptz not null default now()
);
create index team_fixtures_team_idx on public.team_fixtures (team_id, starts_at);

create table public.fixture_availability (
  fixture_id uuid not null references public.team_fixtures (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  availability text not null check (availability in ('available', 'unavailable', 'maybe')),
  updated_at timestamptz not null default now(),
  primary key (fixture_id, user_id)
);

-- ─── Chat and reports ──────────────────────────────────────────────────────

create table public.group_messages (
  id uuid primary key default gen_random_uuid(),
  club_id uuid references public.clubs (id) on delete cascade,
  team_id uuid references public.teams (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  kind text not null default 'text'
    check (kind in ('text', 'meet', 'lineup', 'photo', 'system')),
  body text not null default '' check (char_length(body) <= 2000),
  activity_id uuid references public.activities (id) on delete set null,
  photo_url text,
  removed boolean not null default false,
  removed_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  check ((club_id is null) <> (team_id is null))
);
create index group_messages_club_idx on public.group_messages (club_id, created_at)
  where club_id is not null;
create index group_messages_team_idx on public.group_messages (team_id, created_at)
  where team_id is not null;

-- Reports about messages, clubs, teams and activities.
create table public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  target_kind text not null check (target_kind in ('message', 'club', 'team', 'activity')),
  target_id text not null,
  reason text not null check (char_length(reason) between 1 and 40),
  note text not null default '' check (char_length(note) <= 1000),
  created_at timestamptz not null default now()
);

-- ─── Helpers ───────────────────────────────────────────────────────────────

create function public.club_is_member(p_club uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.club_members m
    where m.club_id = p_club and m.user_id = (select auth.uid())
  );
$$;

-- The viewer's permissions in a club: everything for the owner, otherwise
-- what their roles grant.
create function public.club_my_perms(p_club uuid) returns text[]
language sql stable security definer set search_path = '' as $$
  select case
    when exists (
      select 1 from public.clubs c
      where c.id = p_club and c.owner_id = (select auth.uid())
    ) then array[
      'create_meet', 'public_meet', 'mark_attendance', 'tournament', 'events',
      'approve', 'members', 'roles', 'edit_page', 'audit', 'fees'
    ]
    else coalesce((
      select array_agg(distinct p order by p)
      from public.club_member_roles mr
      join public.club_roles r on r.id = mr.role_id
      cross join lateral unnest(r.permissions) as p
      where mr.club_id = p_club and mr.user_id = (select auth.uid())
    ), '{}')
  end;
$$;

create function public.club_can(p_club uuid, p_perm text) returns boolean
language sql stable security definer set search_path = '' as $$
  select p_perm = any (public.club_my_perms(p_club));
$$;

create function public.club_require(p_club uuid, p_perm text) returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.club_can(p_club, p_perm) then
    raise exception 'You don''t have permission to do that in this club.';
  end if;
end;
$$;

create function public.club_require_member(p_club uuid) returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.club_is_member(p_club) then
    raise exception 'Join the club to see this.';
  end if;
end;
$$;

create function public.club_log(
  p_club uuid, p_category text, p_action text, p_detail text default ''
) returns void
language sql security definer set search_path = '' as $$
  insert into public.club_audit (club_id, actor_id, category, action, detail)
  values (p_club, (select auth.uid()), p_category, p_action, coalesce(p_detail, ''));
$$;

create function public.club_notify(
  p_user uuid, p_title text, p_body text, p_link text
) returns void
language sql security definer set search_path = '' as $$
  insert into public.notifications (user_id, title, body, mark, link)
  values (p_user, left(p_title, 120), left(coalesce(p_body, ''), 300), 'Cl', p_link);
$$;

-- What each role level grants, as on the create-role slider.
create function public.club_level_perms(p_level text) returns text[]
language sql immutable set search_path = '' as $$
  select case p_level
    when 'organizer' then array['create_meet', 'public_meet', 'mark_attendance']
    when 'admin' then array[
      'create_meet', 'public_meet', 'mark_attendance', 'tournament',
      'approve', 'members', 'roles', 'edit_page'
    ]
    else '{}'::text[]
  end;
$$;

create function public.player_json(p_user uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', p.id, 'username', p.username, 'full_name', p.full_name,
    'avatar_url', p.avatar_url
  )
  from public.profiles p where p.id = p_user;
$$;

-- One club as the app shows it, from the viewer's side.
create function public.club_json(p_club uuid) returns jsonb
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
    'invite_code', case when v_member then c.invite_code end
  );
end;
$$;

create function public.club_visible(p_club uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.clubs c
    where c.id = p_club and (
      c.visibility <> 'hidden'
      or public.club_is_member(c.id)
      or exists (
        select 1 from public.club_invites i
        where i.club_id = c.id and i.user_id = (select auth.uid())
      )
    )
  );
$$;

create function public.team_is_member(p_team uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.team_members m
    where m.team_id = p_team and m.user_id = (select auth.uid())
  );
$$;

create function public.team_is_staff(p_team uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.teams t where t.id = p_team and t.owner_id = (select auth.uid())
  ) or exists (
    select 1 from public.team_members m
    where m.team_id = p_team and m.user_id = (select auth.uid()) and m.staff
  );
$$;

-- ─── Club reads ────────────────────────────────────────────────────────────

create function public.club_get(p_club uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.club_visible(p_club) then
    raise exception 'This club no longer exists.';
  end if;
  return public.club_json(p_club);
end;
$$;

-- "mine", "recommended" (public clubs to join) or "fresh" (new this month).
create function public.club_list(p_tab text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.club_json(x.id) order by x.ord), '[]'::jsonb)
  from (
    select y.id, y.ord from (
      select m.club_id as id, -extract(epoch from m.joined_at)::double precision as ord
      from public.club_members m
      where p_tab = 'mine' and m.user_id = (select auth.uid())
      union all
      select c.id, -(
        select count(*) from public.club_members m where m.club_id = c.id
      )::double precision
      from public.clubs c
      where p_tab = 'recommended' and c.visibility = 'public'
        and not public.club_is_member(c.id)
        and not exists (
          select 1 from public.club_bans b
          where b.club_id = c.id and b.user_id = (select auth.uid())
        )
      union all
      select c.id, -extract(epoch from c.created_at)::double precision
      from public.clubs c
      where p_tab = 'fresh' and c.visibility = 'public'
        and c.created_at > now() - interval '30 days'
        and not public.club_is_member(c.id)
    ) y
    order by y.ord
    limit 50
  ) x;
$$;

-- The club an invite code opens. Opening it lets the player see and join.
create function public.club_for_code(p_code text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_club uuid;
begin
  select c.id into v_club from public.clubs c where c.invite_code = upper(trim(p_code));
  if v_club is null then
    return null;
  end if;
  if not public.club_is_member(v_club) then
    insert into public.club_invites (club_id, user_id)
    values (v_club, (select auth.uid()))
    on conflict do nothing;
  end if;
  return v_club;
end;
$$;

create function public.club_member_list(p_club uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.club_require_member(p_club);
  return (
    select coalesce(jsonb_agg(public.player_json(m.user_id) || jsonb_build_object(
      'rating', (
        select ps.level from public.player_sports ps
        where ps.user_id = m.user_id and ps.sport = c.sports -> 0 ->> 'sport'
      ),
      'role_ids', coalesce((
        select jsonb_agg(mr.role_id) from public.club_member_roles mr
        where mr.club_id = m.club_id and mr.user_id = m.user_id
      ), '[]'::jsonb),
      'joined_at', m.joined_at,
      'meets_played', (
        select count(*) from public.activity_participants ap
        join public.activities a on a.id = ap.activity_id
        where a.club_id = m.club_id and ap.user_id = m.user_id
          and ap.status = 'joined' and a.starts_at < now()
      ),
      'no_shows', (
        select count(*) from public.activity_participants ap
        join public.activities a on a.id = ap.activity_id
        where a.club_id = m.club_id and ap.user_id = m.user_id
          and ap.attendance = 'absent'
      )
    ) order by m.joined_at), '[]'::jsonb)
    from public.club_members m
    join public.clubs c on c.id = m.club_id
    where m.club_id = p_club
  );
end;
$$;

create function public.club_role_list(p_club uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.club_require_member(p_club);
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', r.id, 'name', r.name, 'color', r.color, 'level', r.level,
      'permissions', to_jsonb(r.permissions), 'show_badge', r.show_badge,
      'is_owner', r.is_owner, 'position', r.position,
      'member_count', (
        select count(*) from public.club_member_roles mr where mr.role_id = r.id
      )
    ) order by r.position, r.created_at), '[]'::jsonb)
    from public.club_roles r where r.club_id = p_club
  );
end;
$$;

create function public.club_request_list(p_club uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.club_require(p_club, 'approve');
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', r.id,
      'player', public.player_json(r.user_id),
      'created_at', r.created_at,
      'message', r.message,
      'status', r.status,
      'rating', (
        select ps.level from public.player_sports ps
        where ps.user_id = r.user_id and ps.sport = c.sports -> 0 ->> 'sport'
      ),
      'sessions', (
        select count(*) from public.activity_participants ap
        join public.activities a on a.id = ap.activity_id
        where ap.user_id = r.user_id and ap.status = 'joined' and a.starts_at < now()
      ),
      'mutual', (
        select count(*) from public.club_members m2
        where m2.user_id = r.user_id and m2.club_id <> r.club_id
          and public.club_is_member(m2.club_id)
      )
    ) order by r.status <> 'pending', r.created_at desc), '[]'::jsonb)
    from public.club_join_requests r
    join public.clubs c on c.id = r.club_id
    where r.club_id = p_club and r.status <> 'cancelled'
      and (r.status = 'pending' or r.decided_at > now() - interval '30 days')
  );
end;
$$;

create function public.club_ban_list(p_club uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.club_require(p_club, 'members');
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'player', public.player_json(b.user_id),
      'banned_by', coalesce((
        select coalesce(p.full_name, p.username) from public.profiles p
        where p.id = b.banned_by
      ), 'An organizer'),
      'reason', b.reason,
      'at', b.created_at
    ) order by b.created_at desc), '[]'::jsonb)
    from public.club_bans b where b.club_id = p_club
  );
end;
$$;

create function public.club_audit_list(p_club uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.club_require(p_club, 'audit');
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', x.id, 'category', x.category, 'action', x.action,
      'detail', x.detail, 'at', x.created_at,
      'actor', coalesce((
        select coalesce(p.full_name, p.username) from public.profiles p
        where p.id = x.actor_id
      ), 'Someone')
    ) order by x.created_at desc), '[]'::jsonb)
    from (
      select * from public.club_audit a where a.club_id = p_club
      order by a.created_at desc limit 200
    ) x
  );
end;
$$;

create function public.club_announcement_list(p_club uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.club_require_member(p_club);
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', a.id, 'title', a.title, 'body', a.body, 'pinned', a.pinned,
      'at', a.created_at,
      'author', coalesce((
        select coalesce(p.full_name, p.username) from public.profiles p
        where p.id = a.author_id
      ), 'An organizer'),
      'author_role', coalesce((
        select r.name from public.club_member_roles mr
        join public.club_roles r on r.id = mr.role_id
        where mr.club_id = a.club_id and mr.user_id = a.author_id and r.level <> 'label'
        order by r.position limit 1
      ), 'Member')
    ) order by a.pinned desc, a.created_at desc), '[]'::jsonb)
    from public.club_announcements a where a.club_id = p_club
  );
end;
$$;

-- Members ranked by their rating in one sport.
create function public.club_leaderboard(p_club uuid, p_sport text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.club_require_member(p_club);
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'player', public.player_json(x.user_id),
      'level', x.level,
      'meets', x.meets
    ) order by x.level desc, x.meets desc), '[]'::jsonb)
    from (
      select m.user_id, ps.level, (
        select count(*) from public.activity_participants ap
        join public.activities a on a.id = ap.activity_id
        where a.club_id = m.club_id and ap.user_id = m.user_id
          and ap.status = 'joined' and a.starts_at < now()
      ) as meets
      from public.club_members m
      join public.player_sports ps on ps.user_id = m.user_id and ps.sport = p_sport
      where m.club_id = p_club
    ) x
  );
end;
$$;

-- People to invite: those you follow and those you have played with.
create function public.club_invite_candidates() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.player_json(x.id) || jsonb_build_object(
    'rating', (
      select ps.level from public.player_sports ps
      where ps.user_id = x.id order by ps.created_at limit 1
    ),
    'meets_together', x.together
  ) order by x.together desc), '[]'::jsonb)
  from (
    select u.id, max(u.together) as together from (
      select f.followee_id as id, 0 as together
      from public.follows f where f.follower_id = (select auth.uid())
      union all
      select o.user_id, count(*)::int
      from public.activity_participants mine
      join public.activity_participants o
        on o.activity_id = mine.activity_id and o.user_id <> mine.user_id
      where mine.user_id = (select auth.uid())
        and mine.status = 'joined' and o.status = 'joined'
      group by o.user_id
    ) u
    group by u.id
    limit 50
  ) x
  where exists (select 1 from public.profiles p where p.id = x.id);
$$;

-- ─── Club changes ──────────────────────────────────────────────────────────

create function public.club_create(p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := (select auth.uid());
  v_club uuid;
  v_owner uuid;
  v_visibility text := coalesce(p ->> 'visibility', 'public');
  v_palette bigint[] := array[4279135054, 4281285215, 4291319101, 4282280842];
begin
  if v_me is null then
    raise exception 'Log in again to continue.';
  end if;
  insert into public.clubs (
    name, description, area, home_venue_id, home_venue_name, sports,
    visibility, join_mode, logo_color, owner_id
  ) values (
    trim(p ->> 'name'),
    coalesce(p ->> 'description', ''),
    coalesce(p ->> 'area', ''),
    nullif(p ->> 'venue_id', '')::uuid,
    p ->> 'venue_name',
    coalesce(p -> 'sports', '[]'::jsonb),
    v_visibility,
    case when v_visibility = 'public' then coalesce(p ->> 'join_mode', 'request')
      else 'request' end,
    v_palette[1 + floor(random() * 4)::int],
    v_me
  ) returning id into v_club;

  insert into public.club_roles (club_id, name, color, level, permissions, is_owner, position)
  values (
    v_club, 'Owner', 4280033059, 'admin', array[
      'create_meet', 'public_meet', 'mark_attendance', 'tournament', 'events',
      'approve', 'members', 'roles', 'edit_page', 'audit', 'fees'
    ], true, 0
  ) returning id into v_owner;
  insert into public.club_roles (club_id, name, color, level, permissions, position)
  values (v_club, 'Admin', 4291319101, 'admin', public.club_level_perms('admin'), 1);

  insert into public.club_members (club_id, user_id) values (v_club, v_me);
  insert into public.club_member_roles (club_id, user_id, role_id) values (v_club, v_me, v_owner);
  perform public.club_log(v_club, 'club', 'created the club');
  return v_club;
end;
$$;

create function public.club_update(p_club uuid, p jsonb) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.club_require(p_club, 'edit_page');
  update public.clubs c set
    name = coalesce(trim(p ->> 'name'), c.name),
    description = coalesce(p ->> 'description', c.description),
    rules = case when p ? 'rules'
      then array(select jsonb_array_elements_text(p -> 'rules')) else c.rules end,
    area = coalesce(p ->> 'area', c.area),
    home_venue_name = case when p ? 'home_venue' then p ->> 'home_venue'
      else c.home_venue_name end,
    sports = coalesce(p -> 'sports', c.sports),
    visibility = coalesce(p ->> 'visibility', c.visibility),
    join_mode = case
      when coalesce(p ->> 'visibility', c.visibility) <> 'public' then 'request'
      else coalesce(p ->> 'join_mode', c.join_mode) end,
    play_rules = coalesce(p -> 'play_rules', c.play_rules),
    logo_color = coalesce((p ->> 'logo_color')::bigint, c.logo_color),
    logo_ink = coalesce((p ->> 'logo_ink')::bigint, c.logo_ink),
    cover_color = coalesce((p ->> 'cover_color')::bigint, c.cover_color)
  where c.id = p_club;
  perform public.club_log(p_club, 'club', 'edited the club info');
end;
$$;

-- Joins straight away for an open club or an invited player; otherwise asks.
create function public.club_join(p_club uuid, p_message text default '') returns text
language plpgsql security definer set search_path = '' as $$
declare
  c public.clubs;
  v_me uuid := (select auth.uid());
begin
  select * into c from public.clubs where id = p_club;
  if not found or not public.club_visible(p_club) then
    raise exception 'This club no longer exists.';
  end if;
  if exists (select 1 from public.club_bans b where b.club_id = p_club and b.user_id = v_me) then
    raise exception 'You can''t join this club.';
  end if;
  if public.club_is_member(p_club) then
    return 'member';
  end if;
  if (c.visibility = 'public' and c.join_mode = 'anyone') or exists (
    select 1 from public.club_invites i where i.club_id = p_club and i.user_id = v_me
  ) then
    insert into public.club_members (club_id, user_id) values (p_club, v_me);
    delete from public.club_invites where club_id = p_club and user_id = v_me;
    update public.club_join_requests set status = 'cancelled'
      where club_id = p_club and user_id = v_me and status = 'pending';
    perform public.club_log(p_club, 'members', 'joined the club');
    return 'member';
  end if;
  insert into public.club_join_requests (club_id, user_id, message)
  values (p_club, v_me, coalesce(p_message, ''))
  on conflict (club_id, user_id) where status = 'pending'
  do update set message = excluded.message;
  perform public.club_notify(
    c.owner_id, 'New request to join ' || c.name,
    'Approve or decline it in Join requests.', '/clubs/' || p_club || '/requests'
  );
  return 'requested';
end;
$$;

create function public.club_cancel_request(p_club uuid) returns void
language sql security definer set search_path = '' as $$
  update public.club_join_requests set status = 'cancelled'
  where club_id = p_club and user_id = (select auth.uid()) and status = 'pending';
$$;

create function public.club_leave(p_club uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if exists (
    select 1 from public.clubs c where c.id = p_club and c.owner_id = (select auth.uid())
  ) then
    raise exception 'You own this club. Transfer it to another member before you leave.';
  end if;
  delete from public.club_members where club_id = p_club and user_id = (select auth.uid());
  perform public.club_log(p_club, 'members', 'left the club');
end;
$$;

create function public.club_decide_request(p_request uuid, p_status text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  r public.club_join_requests;
  v_name text;
begin
  select * into r from public.club_join_requests where id = p_request;
  if not found then
    raise exception 'This request no longer exists.';
  end if;
  perform public.club_require(r.club_id, 'approve');
  if r.status <> 'pending' then
    raise exception 'This request was already answered.';
  end if;
  if p_status not in ('approved', 'declined') then
    raise exception 'Choose approve or decline.';
  end if;
  update public.club_join_requests
    set status = p_status, decided_by = (select auth.uid()), decided_at = now()
    where id = p_request;
  select c.name into v_name from public.clubs c where c.id = r.club_id;
  if p_status = 'approved' then
    insert into public.club_members (club_id, user_id) values (r.club_id, r.user_id)
    on conflict do nothing;
    perform public.club_notify(
      r.user_id, 'You''re in ' || v_name, 'Your request to join was approved.',
      '/clubs/' || r.club_id
    );
  else
    perform public.club_notify(
      r.user_id, 'Request to join ' || v_name,
      'This club can''t take you right now.', '/clubs/' || r.club_id
    );
  end if;
  perform public.club_log(
    r.club_id, 'members',
    case when p_status = 'approved' then 'approved a join request'
      else 'declined a join request' end,
    coalesce((select coalesce(p.full_name, p.username) from public.profiles p
      where p.id = r.user_id), '')
  );
end;
$$;

-- Gives a member one permission role, or none (Everyone). Labels stay.
create function public.club_set_member_role(p_club uuid, p_user uuid, p_role uuid)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.club_require(p_club, 'members');
  if exists (select 1 from public.clubs c where c.id = p_club and c.owner_id = p_user) then
    raise exception 'The owner''s role can''t be changed.';
  end if;
  if not exists (
    select 1 from public.club_members m where m.club_id = p_club and m.user_id = p_user
  ) then
    raise exception 'This player isn''t a member.';
  end if;
  delete from public.club_member_roles mr
    using public.club_roles r
    where mr.role_id = r.id and mr.club_id = p_club and mr.user_id = p_user
      and r.level <> 'label' and not r.is_owner;
  if p_role is not null then
    if not exists (
      select 1 from public.club_roles r
      where r.id = p_role and r.club_id = p_club and not r.is_owner
    ) then
      raise exception 'That role isn''t in this club.';
    end if;
    insert into public.club_member_roles (club_id, user_id, role_id)
    values (p_club, p_user, p_role) on conflict do nothing;
  end if;
  perform public.club_log(p_club, 'roles', 'changed a member''s role');
end;
$$;

create function public.club_remove_member(p_club uuid, p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.club_require(p_club, 'members');
  if exists (select 1 from public.clubs c where c.id = p_club and c.owner_id = p_user) then
    raise exception 'The owner can''t be removed.';
  end if;
  delete from public.club_members where club_id = p_club and user_id = p_user;
  perform public.club_log(p_club, 'members', 'removed a member');
end;
$$;

create function public.club_ban(p_club uuid, p_user uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.club_require(p_club, 'members');
  if exists (select 1 from public.clubs c where c.id = p_club and c.owner_id = p_user) then
    raise exception 'The owner can''t be banned.';
  end if;
  delete from public.club_members where club_id = p_club and user_id = p_user;
  delete from public.club_invites where club_id = p_club and user_id = p_user;
  update public.club_join_requests set status = 'declined',
    decided_by = (select auth.uid()), decided_at = now()
    where club_id = p_club and user_id = p_user and status = 'pending';
  insert into public.club_bans (club_id, user_id, banned_by, reason)
  values (p_club, p_user, (select auth.uid()), coalesce(p_reason, ''))
  on conflict (club_id, user_id) do update set reason = excluded.reason;
  perform public.club_log(p_club, 'members', 'banned a player', coalesce(p_reason, ''));
end;
$$;

create function public.club_unban(p_club uuid, p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.club_require(p_club, 'members');
  delete from public.club_bans where club_id = p_club and user_id = p_user;
  perform public.club_log(p_club, 'members', 'lifted a ban');
end;
$$;

create function public.club_role_create(
  p_club uuid, p_name text, p_color bigint, p_level text, p_members uuid[]
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_role uuid;
begin
  perform public.club_require(p_club, 'roles');
  insert into public.club_roles (club_id, name, color, level, permissions, position)
  values (
    p_club, trim(p_name), p_color, p_level, public.club_level_perms(p_level),
    coalesce((select max(r.position) + 1 from public.club_roles r where r.club_id = p_club), 1)
  ) returning id into v_role;
  insert into public.club_member_roles (club_id, user_id, role_id)
  select p_club, m.user_id, v_role from public.club_members m
  where m.club_id = p_club and m.user_id = any (coalesce(p_members, '{}'))
  on conflict do nothing;
  perform public.club_log(p_club, 'roles', 'created a role', trim(p_name));
  return v_role;
end;
$$;

create function public.club_role_update(
  p_role uuid, p_name text, p_color bigint, p_level text,
  p_permissions text[], p_show_badge boolean
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  r public.club_roles;
begin
  select * into r from public.club_roles where id = p_role;
  if not found then
    raise exception 'This role no longer exists.';
  end if;
  perform public.club_require(r.club_id, 'roles');
  if r.is_owner then
    raise exception 'The owner role can''t be changed.';
  end if;
  if 'fees' = any (p_permissions) and not exists (
    select 1 from public.clubs c where c.id = r.club_id and c.owner_id = (select auth.uid())
  ) then
    raise exception 'Only the owner can give fee and payout access.';
  end if;
  update public.club_roles set
    name = trim(p_name), color = p_color, level = p_level,
    permissions = case when p_level = 'label' then '{}'::text[]
      else coalesce(p_permissions, '{}') end,
    show_badge = p_show_badge
  where id = p_role;
  perform public.club_log(r.club_id, 'roles', 'edited a role', trim(p_name));
end;
$$;

create function public.club_role_delete(p_role uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  r public.club_roles;
begin
  select * into r from public.club_roles where id = p_role;
  if not found then
    return;
  end if;
  perform public.club_require(r.club_id, 'roles');
  if r.is_owner then
    raise exception 'The owner role can''t be deleted.';
  end if;
  delete from public.club_roles where id = p_role;
  perform public.club_log(r.club_id, 'roles', 'deleted a role', r.name);
end;
$$;

create function public.club_role_reorder(p_club uuid, p_ids uuid[]) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.club_require(p_club, 'roles');
  update public.club_roles r set position = x.ord
  from unnest(p_ids) with ordinality as x(id, ord)
  where r.id = x.id and r.club_id = p_club and not r.is_owner;
  perform public.club_log(p_club, 'roles', 'reordered roles');
end;
$$;

create function public.club_role_set_members(p_role uuid, p_ids uuid[]) returns void
language plpgsql security definer set search_path = '' as $$
declare
  r public.club_roles;
begin
  select * into r from public.club_roles where id = p_role;
  if not found then
    raise exception 'This role no longer exists.';
  end if;
  perform public.club_require(r.club_id, 'roles');
  if r.is_owner then
    raise exception 'Transfer the club to change its owner.';
  end if;
  delete from public.club_member_roles where role_id = p_role;
  insert into public.club_member_roles (club_id, user_id, role_id)
  select r.club_id, m.user_id, p_role from public.club_members m
  where m.club_id = r.club_id and m.user_id = any (coalesce(p_ids, '{}'))
  on conflict do nothing;
  perform public.club_log(r.club_id, 'roles', 'changed who has a role', r.name);
end;
$$;

create function public.club_announce(
  p_club uuid, p_title text, p_body text, p_audience text, p_pinned boolean
) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_name text;
begin
  perform public.club_require(p_club, 'edit_page');
  insert into public.club_announcements (club_id, author_id, title, body, audience, pinned)
  values (p_club, (select auth.uid()), trim(p_title), coalesce(p_body, ''),
    coalesce(p_audience, 'everyone'), coalesce(p_pinned, false));
  select c.name into v_name from public.clubs c where c.id = p_club;
  insert into public.notifications (user_id, title, body, mark, link)
  select m.user_id, left(v_name || ': ' || trim(p_title), 120), left(coalesce(p_body, ''), 300),
    'Cl', '/clubs/' || p_club || '/announcements'
  from public.club_members m
  where m.club_id = p_club and m.user_id <> (select auth.uid());
  perform public.club_log(p_club, 'club', 'posted an announcement', trim(p_title));
end;
$$;

create function public.club_transfer(p_club uuid, p_to uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := (select auth.uid());
  v_owner_role uuid;
  v_admin_role uuid;
begin
  if not exists (select 1 from public.clubs c where c.id = p_club and c.owner_id = v_me) then
    raise exception 'Only the owner can transfer the club.';
  end if;
  if not exists (
    select 1 from public.club_members m where m.club_id = p_club and m.user_id = p_to
  ) then
    raise exception 'The new owner must be a member.';
  end if;
  select r.id into v_owner_role from public.club_roles r where r.club_id = p_club and r.is_owner;
  select r.id into v_admin_role from public.club_roles r
    where r.club_id = p_club and r.level = 'admin' and not r.is_owner
    order by r.position limit 1;
  update public.clubs set owner_id = p_to where id = p_club;
  delete from public.club_member_roles where role_id = v_owner_role;
  insert into public.club_member_roles (club_id, user_id, role_id)
  values (p_club, p_to, v_owner_role) on conflict do nothing;
  if v_admin_role is not null then
    insert into public.club_member_roles (club_id, user_id, role_id)
    values (p_club, v_me, v_admin_role) on conflict do nothing;
  end if;
  perform public.club_notify(
    p_to, 'You now own a club', 'The previous owner handed it to you.',
    '/clubs/' || p_club
  );
  perform public.club_log(p_club, 'club', 'transferred ownership');
end;
$$;

create function public.club_delete(p_club uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.clubs c where c.id = p_club and c.owner_id = (select auth.uid())
  ) then
    raise exception 'Only the owner can delete the club.';
  end if;
  delete from public.clubs where id = p_club;
end;
$$;

create function public.club_invite(p_club uuid, p_ids uuid[]) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_name text;
  v_from text;
begin
  perform public.club_require_member(p_club);
  select c.name into v_name from public.clubs c where c.id = p_club;
  select coalesce(p.full_name, p.username, 'A player') into v_from
    from public.profiles p where p.id = (select auth.uid());
  with added as (
    insert into public.club_invites (club_id, user_id, invited_by)
    select p_club, u, (select auth.uid()) from unnest(coalesce(p_ids, '{}')) as u
    where not exists (
      select 1 from public.club_members m where m.club_id = p_club and m.user_id = u
    ) and exists (select 1 from public.profiles p where p.id = u)
    on conflict do nothing
    returning user_id
  )
  insert into public.notifications (user_id, title, body, mark, link)
  select a.user_id, left(v_from || ' invited you to ' || v_name, 120),
    'Open the club to join.', 'Cl', '/clubs/' || p_club
  from added a;
  perform public.club_log(p_club, 'members', 'invited players');
end;
$$;

create function public.club_chat_read(p_club uuid) returns void
language sql security definer set search_path = '' as $$
  update public.club_members set chat_read_at = now()
  where club_id = p_club and user_id = (select auth.uid());
$$;

-- Hosting for a club needs the matching permission.
create function public.check_activity_club() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.club_id is not null and not public.club_can(new.club_id, case new.kind
    when 'tournament' then 'tournament'
    when 'event' then 'events'
    else 'create_meet' end
  ) then
    raise exception 'You can''t host this for that club.';
  end if;
  return new;
end;
$$;

create trigger activities_club_check before insert or update of club_id
  on public.activities for each row execute function public.check_activity_club();

-- ─── Teams ─────────────────────────────────────────────────────────────────

create function public.team_json(p_team uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', t.id, 'name', t.name, 'represents', t.represents, 'sport', t.sport,
    'season', t.season, 'logo_color', t.logo_color, 'logo_ink', t.logo_ink,
    'sub_teams', (
      select coalesce(jsonb_agg(s || jsonb_build_object('players', (
        select count(*) from public.team_members m
        where m.team_id = t.id and m.sub_team = s ->> 'name' and not m.staff
      ))), '[]'::jsonb)
      from jsonb_array_elements(t.sub_teams) s
    ),
    'linked_clubs', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', c.id, 'name', c.name, 'logo_color', c.logo_color, 'logo_ink', c.logo_ink
      )), '[]'::jsonb)
      from public.team_clubs tc join public.clubs c on c.id = tc.club_id
      where tc.team_id = t.id
    ),
    'player_count', (
      select count(*) from public.team_members m
      where m.team_id = t.id and not m.staff and not m.reserve
    ),
    'reserve_count', (
      select count(*) from public.team_members m
      where m.team_id = t.id and not m.staff and m.reserve
    ),
    'staff_count', (
      select count(*) from public.team_members m where m.team_id = t.id and m.staff
    ),
    'my_role', case
      when t.owner_id = (select auth.uid()) then 'owner'
      when public.team_is_staff(t.id) then 'staff'
      else 'player' end,
    'unread_chat', (
      select count(*) from public.group_messages g
      where g.team_id = t.id and g.sender_id <> (select auth.uid())
        and g.created_at > coalesce((
          select m.chat_read_at from public.team_members m
          where m.team_id = t.id and m.user_id = (select auth.uid())
        ), '-infinity'::timestamptz)
    )
  )
  from public.teams t where t.id = p_team;
$$;

-- Teams are private: only their players and staff see them.
create function public.team_list(p_tab text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.team_json(m.team_id) order by m.joined_at desc), '[]'::jsonb)
  from public.team_members m
  where p_tab = 'mine' and m.user_id = (select auth.uid());
$$;

create function public.team_require_member(p_team uuid) returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.team_is_member(p_team) and not public.team_is_staff(p_team) then
    raise exception 'Only the team''s players and staff can see this.';
  end if;
end;
$$;

create function public.team_require_staff(p_team uuid) returns void
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.team_is_staff(p_team) then
    raise exception 'Only team staff can do that.';
  end if;
end;
$$;

create function public.team_get(p_team uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.team_require_member(p_team);
  return public.team_json(p_team);
end;
$$;

create function public.team_member_list(p_team uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_sport text;
  v_next uuid;
begin
  perform public.team_require_member(p_team);
  select t.sport into v_sport from public.teams t where t.id = p_team;
  select f.id into v_next from public.team_fixtures f
    where f.team_id = p_team and f.starts_at >= now() order by f.starts_at limit 1;
  return (
    select coalesce(jsonb_agg(public.player_json(m.user_id) || jsonb_build_object(
      'rating', (
        select ps.level from public.player_sports ps
        where ps.user_id = m.user_id and ps.sport = v_sport
      ),
      'club', coalesce((
        select c.name from public.team_clubs tc
        join public.club_members cm on cm.club_id = tc.club_id and cm.user_id = m.user_id
        join public.clubs c on c.id = tc.club_id
        where tc.team_id = p_team limit 1
      ), ''),
      'captain', m.captain,
      'availability', coalesce((
        select a.availability from public.fixture_availability a
        where a.fixture_id = v_next and a.user_id = m.user_id
      ), 'no_reply'),
      'reserve', m.reserve,
      'staff', m.staff,
      'staff_title', m.staff_title
    ) order by m.staff desc, m.joined_at), '[]'::jsonb)
    from public.team_members m where m.team_id = p_team
  );
end;
$$;

create function public.team_fixture_list(p_team uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.team_require_member(p_team);
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', f.id, 'opponent', f.opponent, 'starts_at', f.starts_at,
      'competition', f.competition, 'venue', f.venue, 'score', f.score,
      'won', f.won,
      'attending', (
        select count(*) from public.fixture_availability a
        where a.fixture_id = f.id and a.availability = 'available'
      ),
      'squad', (
        select count(*) from public.team_members m
        where m.team_id = p_team and not m.staff
      )
    ) order by f.starts_at), '[]'::jsonb)
    from public.team_fixtures f where f.team_id = p_team
  );
end;
$$;

create function public.team_fixture_get(p_fixture uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  f public.team_fixtures;
begin
  select * into f from public.team_fixtures where id = p_fixture;
  if not found then
    raise exception 'This fixture no longer exists.';
  end if;
  perform public.team_require_member(f.team_id);
  return jsonb_build_object(
    'id', f.id, 'team_id', f.team_id,
    'team_name', (select t.name from public.teams t where t.id = f.team_id),
    'sport', (select t.sport from public.teams t where t.id = f.team_id),
    'opponent', f.opponent, 'starts_at', f.starts_at,
    'competition', f.competition, 'venue', f.venue,
    'lineup_locks_at', f.lineup_locks_at, 'notes', to_jsonb(f.notes),
    'set_by', coalesce((
      select coalesce(p.full_name, p.username) from public.profiles p where p.id = f.set_by
    ), ''),
    'my_availability', coalesce((
      select a.availability from public.fixture_availability a
      where a.fixture_id = f.id and a.user_id = (select auth.uid())
    ), 'no_reply'),
    'lineup', f.lineup,
    'published', f.published
  );
end;
$$;

create function public.team_set_availability(p_fixture uuid, p_value text) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v_team uuid;
begin
  select f.team_id into v_team from public.team_fixtures f where f.id = p_fixture;
  if v_team is null then
    raise exception 'This fixture no longer exists.';
  end if;
  perform public.team_require_member(v_team);
  if p_value = 'no_reply' then
    delete from public.fixture_availability
      where fixture_id = p_fixture and user_id = (select auth.uid());
  else
    insert into public.fixture_availability (fixture_id, user_id, availability)
    values (p_fixture, (select auth.uid()), p_value)
    on conflict (fixture_id, user_id)
    do update set availability = excluded.availability, updated_at = now();
  end if;
end;
$$;

create function public.team_save_lineup(p_fixture uuid, p_lineup jsonb, p_publish boolean)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  f public.team_fixtures;
begin
  select * into f from public.team_fixtures where id = p_fixture;
  if not found then
    raise exception 'This fixture no longer exists.';
  end if;
  perform public.team_require_staff(f.team_id);
  update public.team_fixtures set
    lineup = coalesce(p_lineup, '{}'::jsonb),
    published = f.published or p_publish,
    set_by = (select auth.uid())
  where id = p_fixture;
  if p_publish and not f.published then
    insert into public.group_messages (team_id, sender_id, kind, body)
    values (f.team_id, (select auth.uid()), 'lineup', 'Lineup for ' || f.opponent || ' is out');
  end if;
end;
$$;

-- Players to add: members of the team's clubs and people you follow.
create function public.team_candidates(p_team uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_sport text;
begin
  perform public.team_require_staff(p_team);
  select t.sport into v_sport from public.teams t where t.id = p_team;
  return (
    select coalesce(jsonb_agg(public.player_json(x.id) || jsonb_build_object(
      'rating', (
        select ps.level from public.player_sports ps
        where ps.user_id = x.id and ps.sport = v_sport
      ),
      'club', x.club
    )), '[]'::jsonb)
    from (
      select distinct on (u.id) u.id, u.club from (
        select cm.user_id as id, c.name as club
        from public.team_clubs tc
        join public.club_members cm on cm.club_id = tc.club_id
        join public.clubs c on c.id = tc.club_id
        where tc.team_id = p_team
        union all
        select f.followee_id, '' from public.follows f
        where f.follower_id = (select auth.uid())
      ) u
      where not exists (
        select 1 from public.team_members m where m.team_id = p_team and m.user_id = u.id
      ) and exists (select 1 from public.profiles p where p.id = u.id)
      limit 100
    ) x
  );
end;
$$;

create function public.team_add_players(p_team uuid, p_ids uuid[]) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.team_require_staff(p_team);
  insert into public.team_members (team_id, user_id)
  select p_team, u from unnest(coalesce(p_ids, '{}')) as u
  where exists (select 1 from public.profiles p where p.id = u)
  on conflict do nothing;
end;
$$;

create function public.team_create(p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := (select auth.uid());
  v_team uuid;
begin
  if v_me is null then
    raise exception 'Log in again to continue.';
  end if;
  insert into public.teams (name, represents, sport, season, sub_teams, owner_id)
  values (
    trim(p ->> 'name'),
    coalesce(p ->> 'represents', ''),
    coalesce(p ->> 'sport', 'badminton'),
    coalesce(p ->> 'season', ''),
    coalesce(p -> 'sub_teams', '[]'::jsonb),
    v_me
  ) returning id into v_team;
  insert into public.team_members (team_id, user_id, staff, staff_title)
  values (v_team, v_me, true, 'Team owner');
  insert into public.team_members (team_id, user_id)
  select v_team, e.u::uuid from jsonb_array_elements_text(
    coalesce(p -> 'players', '[]'::jsonb)
  ) as e(u)
  where e.u ~ '^[0-9a-f-]{36}$'
    and exists (select 1 from public.profiles pr where pr.id = e.u::uuid)
  on conflict do nothing;
  return v_team;
end;
$$;

create function public.team_update(p_team uuid, p jsonb) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.team_require_staff(p_team);
  update public.teams t set
    name = coalesce(trim(p ->> 'name'), t.name),
    represents = coalesce(p ->> 'represents', t.represents),
    season = coalesce(p ->> 'season', t.season),
    sub_teams = coalesce(p -> 'sub_teams', t.sub_teams),
    logo_color = coalesce((p ->> 'logo_color')::bigint, t.logo_color),
    logo_ink = coalesce((p ->> 'logo_ink')::bigint, t.logo_ink)
  where t.id = p_team;
end;
$$;

create function public.team_leave(p_team uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if exists (
    select 1 from public.teams t where t.id = p_team and t.owner_id = (select auth.uid())
  ) then
    raise exception 'You own this team. Delete it, or hand it to another coach first.';
  end if;
  delete from public.team_members where team_id = p_team and user_id = (select auth.uid());
end;
$$;

create function public.team_delete(p_team uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.teams t where t.id = p_team and t.owner_id = (select auth.uid())
  ) then
    raise exception 'Only the team owner can delete the team.';
  end if;
  delete from public.teams where id = p_team;
end;
$$;

create function public.team_chat_read(p_team uuid) returns void
language sql security definer set search_path = '' as $$
  update public.team_members set chat_read_at = now()
  where team_id = p_team and user_id = (select auth.uid());
$$;

-- Removes (or restores) a chat message: its sender, a club member manager,
-- or team staff.
create function public.group_message_set_removed(p_id uuid, p_removed boolean)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  g public.group_messages;
begin
  select * into g from public.group_messages where id = p_id;
  if not found then
    raise exception 'This message no longer exists.';
  end if;
  if not (
    g.sender_id = (select auth.uid())
    or (g.club_id is not null and public.club_can(g.club_id, 'members'))
    or (g.team_id is not null and public.team_is_staff(g.team_id))
  ) then
    raise exception 'You can''t remove this message.';
  end if;
  update public.group_messages set
    removed = p_removed,
    removed_by = case when p_removed then (select auth.uid()) end
  where id = p_id;
  if g.club_id is not null and g.sender_id <> (select auth.uid()) then
    perform public.club_log(
      g.club_id, 'members',
      case when p_removed then 'removed a chat message' else 'restored a chat message' end
    );
  end if;
end;
$$;

-- ─── Row level security ────────────────────────────────────────────────────
-- Everything but chat and reports goes through the functions above.

alter table public.clubs enable row level security;
alter table public.club_roles enable row level security;
alter table public.club_members enable row level security;
alter table public.club_member_roles enable row level security;
alter table public.club_join_requests enable row level security;
alter table public.club_bans enable row level security;
alter table public.club_audit enable row level security;
alter table public.club_announcements enable row level security;
alter table public.club_invites enable row level security;
alter table public.teams enable row level security;
alter table public.team_clubs enable row level security;
alter table public.team_members enable row level security;
alter table public.team_fixtures enable row level security;
alter table public.fixture_availability enable row level security;
alter table public.group_messages enable row level security;
alter table public.content_reports enable row level security;

create policy "Members read their club or team chat" on public.group_messages
  for select to authenticated using (
    (club_id is not null and public.club_is_member(club_id))
    or (team_id is not null and (public.team_is_member(team_id) or public.team_is_staff(team_id)))
  );

create policy "Members post in their club or team chat" on public.group_messages
  for insert to authenticated with check (
    sender_id = (select auth.uid())
    and kind in ('text', 'meet', 'photo')
    and not removed
    and (
      (club_id is not null and public.club_is_member(club_id))
      or (team_id is not null and (public.team_is_member(team_id) or public.team_is_staff(team_id)))
    )
  );

create policy "Players file reports as themselves" on public.content_reports
  for insert to authenticated with check (reporter_id = (select auth.uid()));

create policy "Players read their own reports" on public.content_reports
  for select to authenticated using (reporter_id = (select auth.uid()));

alter publication supabase_realtime add table public.group_messages;

-- Chat photos: public links with unguessable names, uploaded into your own
-- folder.
insert into storage.buckets (id, name, public) values ('chat-photos', 'chat-photos', true)
on conflict (id) do nothing;

create policy "Players upload chat photos to their folder" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'chat-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- ─── Who can call what ─────────────────────────────────────────────────────

do $$
declare
  f text;
begin
  -- Internal helpers: only other functions use these.
  foreach f in array array[
    'club_log(uuid,text,text,text)', 'club_notify(uuid,text,text,text)',
    'club_json(uuid)', 'team_json(uuid)', 'player_json(uuid)'
  ] loop
    execute format('revoke execute on function public.%s from public, anon, authenticated', f);
  end loop;
  -- Signed-in players only.
  foreach f in array array[
    'club_is_member(uuid)', 'club_my_perms(uuid)', 'club_can(uuid,text)',
    'club_require(uuid,text)', 'club_require_member(uuid)', 'club_level_perms(text)',
    'club_visible(uuid)', 'team_is_member(uuid)', 'team_is_staff(uuid)',
    'team_require_member(uuid)', 'team_require_staff(uuid)',
    'club_get(uuid)', 'club_list(text)', 'club_for_code(text)',
    'club_member_list(uuid)', 'club_role_list(uuid)', 'club_request_list(uuid)',
    'club_ban_list(uuid)', 'club_audit_list(uuid)', 'club_announcement_list(uuid)',
    'club_leaderboard(uuid,text)', 'club_invite_candidates()',
    'club_create(jsonb)', 'club_update(uuid,jsonb)', 'club_join(uuid,text)',
    'club_cancel_request(uuid)', 'club_leave(uuid)', 'club_decide_request(uuid,text)',
    'club_set_member_role(uuid,uuid,uuid)', 'club_remove_member(uuid,uuid)',
    'club_ban(uuid,uuid,text)', 'club_unban(uuid,uuid)',
    'club_role_create(uuid,text,bigint,text,uuid[])',
    'club_role_update(uuid,text,bigint,text,text[],boolean)',
    'club_role_delete(uuid)', 'club_role_reorder(uuid,uuid[])',
    'club_role_set_members(uuid,uuid[])',
    'club_announce(uuid,text,text,text,boolean)', 'club_transfer(uuid,uuid)',
    'club_delete(uuid)', 'club_invite(uuid,uuid[])', 'club_chat_read(uuid)',
    'team_list(text)', 'team_get(uuid)', 'team_member_list(uuid)',
    'team_fixture_list(uuid)', 'team_fixture_get(uuid)',
    'team_set_availability(uuid,text)', 'team_save_lineup(uuid,jsonb,boolean)',
    'team_candidates(uuid)', 'team_add_players(uuid,uuid[])', 'team_create(jsonb)',
    'team_update(uuid,jsonb)', 'team_leave(uuid)', 'team_delete(uuid)',
    'team_chat_read(uuid)', 'group_message_set_removed(uuid,boolean)'
  ] loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;
