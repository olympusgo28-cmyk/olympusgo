-- Child protection and rate limits that hold wherever a request comes from.
--
-- Most reads in this app go through security definer functions, and those
-- skip row-level security. A policy alone would leave a restricted child able
-- to call shop_products or suggested_players. So there are three layers:
--
--   1. private.gate_request runs before every API call and refuses a
--      restricted player anything not on an allow list, so a new function
--      starts out refused.
--   2. Restrictive policies refuse the same tables, which also covers
--      Realtime and Storage, neither of which goes through the gate.
--   3. Functions that return people mask or drop minors.

-- ─── Rate limits ───────────────────────────────────────────────────────────

create table private.rate_rules (
  path text primary key,
  max_hits int not null check (max_hits > 0),
  window_seconds int not null check (window_seconds > 0)
);

create table private.rate_buckets (
  scope text not null,
  subject text not null,
  window_start timestamptz not null,
  hits int not null default 0,
  primary key (scope, subject, window_start)
);
create index rate_buckets_old_idx on private.rate_buckets (window_start);

insert into private.rate_rules (path, max_hits, window_seconds) values
  ('/rpc/legal_notice_send', 5, 3600),
  ('/rpc/account_recovery_request', 5, 3600),
  ('/rpc/shop_report', 20, 3600),
  ('/content_reports', 20, 3600),
  ('/player_reports', 20, 3600),
  ('/support_requests', 20, 3600),
  ('/rpc/guardian_code_create', 10, 3600),
  ('/rpc/guardian_code_redeem', 20, 3600),
  ('/rpc/resolve_qr', 120, 60),
  ('/rpc/host_check_in', 300, 60);

create function private.rate_hit(
  p_scope text, p_subject text, p_max int, p_window_seconds int
) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: rate_buckets is reachable by no client role.
declare
  v_window timestamptz := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds);
  v_hits int;
begin
  insert into private.rate_buckets (scope, subject, window_start, hits)
  values (p_scope, p_subject, v_window, 1)
  on conflict (scope, subject, window_start) do update
    set hits = private.rate_buckets.hits + 1
  returning hits into v_hits;
  return v_hits <= p_max;
end;
$$;
revoke execute on function private.rate_hit(text, text, int, int) from public;

-- The caller's address, as the API gateway passed it on.
create function private.request_ip() returns text
language plpgsql stable set search_path = '' as $$
declare
  v_headers json;
begin
  v_headers := nullif(current_setting('request.headers', true), '')::json;
  return coalesce(
    split_part(v_headers ->> 'x-forwarded-for', ',', 1),
    'unknown');
exception when others then
  return 'unknown';
end;
$$;
revoke execute on function private.request_ip() from public;

-- ─── What a restricted player may reach ────────────────────────────────────

-- Anything not listed here is refused for a restricted player.
create table private.restricted_allow (path text primary key);

insert into private.restricted_allow (path) values
  -- Their own account, onboarding and the way out of restricted mode.
  ('/profiles'), ('/account_private'), ('/player_sports'), ('/play_preferences'),
  ('/notification_settings'), ('/notifications'), ('/guardian_links'),
  ('/rpc/set_birthday'), ('/rpc/set_country'), ('/rpc/my_restrictions'),
  ('/rpc/username_available'), ('/rpc/guardian_code_create'), ('/rpc/guardian_parents'),
  -- Reference data.
  ('/sports'), ('/sport_formats'), ('/country_config'), ('/feature_flags'),
  ('/app_settings'), ('/fee_rules'),
  -- Getting help must always work.
  ('/blocks'), ('/player_reports'), ('/content_reports'), ('/support_requests'),
  ('/legal_notices'), ('/content_removals'),
  ('/rpc/legal_notice_send'), ('/rpc/my_reports'), ('/rpc/my_blocked_players'),
  ('/rpc/report_second_look'), ('/rpc/removal_ask_review'), ('/rpc/account_recovery_request');

create function private.gate_request() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: runs as whichever role is calling and reads private tables.
declare
  v_path text := current_setting('request.path', true);
  v_method text := current_setting('request.method', true);
  v_user uuid := auth.uid();
  v_rule private.rate_rules;
begin
  -- Not an API call, for example a direct database session.
  if v_path is null or v_path = '' then
    return;
  end if;

  if v_user is not null and private.is_restricted(v_user) and not exists (
      select 1 from private.restricted_allow a where a.path = v_path) then
    raise exception 'Ask a parent to link your account first.' using errcode = 'P0001';
  end if;

  if v_method = 'POST' then
    select * into v_rule from private.rate_rules r where r.path = v_path;
    if v_rule.path is not null and not private.rate_hit(
        v_path, coalesce(v_user::text, private.request_ip()),
        v_rule.max_hits, v_rule.window_seconds) then
      raise exception 'Too many tries. Wait a while, then try again.' using errcode = 'P0001';
    end if;
  end if;
end;
$$;
revoke execute on function private.gate_request() from public;
grant execute on function private.gate_request() to anon, authenticated, service_role;
-- The gate reaches these through its own definer rights, not the caller's.

alter role authenticator set pgrst.db_pre_request = 'private.gate_request';
notify pgrst, 'reload config';

-- ─── Restrictive policies ──────────────────────────────────────────────────

-- ANDed with every other policy, so no existing "players can read" rule can
-- open these for a restricted player. This is what covers Realtime.
do $$
declare
  t text;
begin
  foreach t in array array[
    -- Open chat.
    'messages', 'conversations', 'conversation_members', 'group_messages',
    -- Discovery.
    'follows',
    -- Shop.
    'products', 'orders', 'order_lines', 'order_returns', 'cart_lines',
    'malls', 'mall_follows', 'product_reviews', 'addresses'
  ] loop
    execute format(
      'create policy "Not for restricted players" on public.%I as restrictive
         for all to authenticated
         using (not private.is_restricted((select auth.uid())))
         with check (not private.is_restricted((select auth.uid())))', t);
  end loop;
end;
$$;

create policy "Chat photos are not for restricted players" on storage.objects
  as restrictive for select to authenticated
  using (bucket_id <> 'chat-photos' or not private.is_restricted((select auth.uid())));

-- ─── Who can see a person ──────────────────────────────────────────────────

drop policy "Signed-in players can see profiles they are not blocked from" on public.profiles;
create policy "Players see who they are allowed to" on public.profiles
  for select to authenticated
  using (private.can_view_profile(id, (select auth.uid())));

drop policy "Signed-in players can see Passports" on public.player_sports;
create policy "Players see the Passports they are allowed to" on public.player_sports
  for select to authenticated
  using (private.can_view_profile(user_id, (select auth.uid())));

drop policy "Follows are visible to signed-in players" on public.follows;
create policy "Follows of visible players" on public.follows
  for select to authenticated
  using (private.can_view_profile(follower_id, (select auth.uid()))
    and private.can_view_profile(followee_id, (select auth.uid())));

-- Rosters go through meet_players, which masks minors. This table was open to
-- every signed-in player, which listed anyone's whereabouts.
drop policy "Players see who is going" on public.activity_participants;
create policy "Players see their own place" on public.activity_participants
  for select to authenticated
  using (user_id = (select auth.uid())
    or public.is_host(activity_id)
    or private.is_guardian_of((select auth.uid()), user_id));

-- A player's first name and photo come through here for every club, team and
-- academy list, so masking it here covers all of them.
create or replace function public.player_json(p_user uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: called from functions that show players the caller may not read.
  select case
    when private.is_minor(p.id) and p.id <> auth.uid()
      and not private.is_guardian_of(auth.uid(), p.id)
    then jsonb_build_object('id', p.id, 'username', null,
      'full_name', private.masked_name(p.full_name), 'avatar_url', null)
    else jsonb_build_object('id', p.id, 'username', p.username,
      'full_name', p.full_name, 'avatar_url', p.avatar_url)
  end
  from public.profiles p where p.id = p_user;
$$;

-- R-AGE-3: under 18, a profile is never open to everyone.
create function private.profile_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.visibility = 'everyone' and private.is_minor(new.id) then
    new.visibility := 'followers';
  end if;
  return new;
end;
$$;

create trigger profiles_guard before insert or update on public.profiles
  for each row execute function private.profile_guard();

-- ─── Discovery and rankings leave minors out ───────────────────────────────

create or replace function public.suggested_players()
returns table (id uuid, username text, full_name text, avatar_url text, level numeric, sessions int)
language sql stable security definer set search_path = '' as $$
  -- Definer: ranks players across the whole player_sports table.
  with mine as (
    select sport, play_min, play_max from public.player_sports
    where user_id = auth.uid()
  ),
  matches as (
    select ps.user_id, max(ps.level) as level
    from public.player_sports ps
    join mine m on m.sport = ps.sport
      and ps.level between m.play_min and m.play_max
    where ps.user_id <> auth.uid()
    group by ps.user_id
  )
  select p.id, p.username::text, p.full_name, p.avatar_url, m.level,
    (select count(*) from public.activity_participants ap
      join public.activities a on a.id = ap.activity_id
      where ap.user_id = p.id and ap.status = 'joined'
        and a.starts_at < now())::int as sessions
  from matches m
  join public.profiles p on p.id = m.user_id
  where p.onboarding_completed
    and not private.is_minor(p.id)
    and not exists (select 1 from public.follows f
      where f.follower_id = auth.uid() and f.followee_id = p.id)
    and not public.is_blocked_between(auth.uid(), p.id)
  order by sessions desc, p.created_at desc
  limit 10;
$$;

create or replace function public.leaderboard_rating(p_sport text, p_areas text[])
returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: ranks players across tables the caller cannot read.
  with me as (
    select coalesce((select country_code from public.profiles where id = (select auth.uid())), 'SG') as country
  ),
  games as (
    select u as user_id, count(*)::int as n
    from public.match_scores s
    join public.activities a on a.id = s.activity_id
    cross join lateral unnest(s.side_a || s.side_b) u
    where s.status = 'confirmed' and p_sport = any (a.sports)
    group by u
  ),
  rows as (
    select p.id, coalesce(p.full_name, p.username::text, 'Player') as name,
      ps.level, g.n
    from public.player_sports ps
    join public.profiles p on p.id = ps.user_id
    join games g on g.user_id = ps.user_id
    where ps.sport = p_sport
      and p.country_code = (select country from me)
      and not private.is_minor(p.id)
      and not public.is_blocked_between((select auth.uid()), p.id)
      and (coalesce(cardinality(p_areas), 0) = 0 or exists (
        select 1 from public.club_members m join public.clubs c on c.id = m.club_id
        where m.user_id = p.id and c.area ilike any (p_areas)))
    order by ps.level desc, g.n desc, name
    limit 50
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'name', name, 'level', level, 'games', n,
    'mine', id = (select auth.uid())) order by level desc, n desc, name), '[]')
  from rows;
$$;

create or replace function public.leaderboard_points(p_sport text) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: ranks players across tables the caller cannot read.
  with done as (
    select m.*, a.title,
      (select count(*) from public.tournament_matches k
       where k.activity_id = m.activity_id and k.division = m.division
         and k.stage = 'knockout' and k.round = m.round) as size,
      exists (select 1 from public.tournament_matches t
              where t.activity_id = m.activity_id and t.division = m.division
                and t.stage = 'third') as has_third
    from public.tournament_matches m
    join public.activities a on a.id = m.activity_id
    where p_sport = any (a.sports) and m.stage in ('knockout', 'third')
      and m.state = 'done' and m.winner is not null
      and not exists (select 1 from public.tournament_matches x
                      where x.activity_id = m.activity_id and x.division = m.division
                        and x.state <> 'done')
  ),
  finishes as (
    -- Winners of a final or 3rd place match.
    select winner as entry, title, case when stage = 'third' then 50 else 100 end as pts,
      case when stage = 'third' then '3rd place' else 'Champion' end as label
    from done where stage = 'third' or size = 1
    union all
    -- Everyone who lost, at the round they went out.
    select case when winner = entry_a then entry_b else entry_a end, title,
      case when stage = 'third' then 40 when size = 1 then 70
           when size = 2 and not has_third then 40 when size = 2 then null
           when size = 4 then 25 else 10 end,
      case when stage = 'third' then 'Semi-finalist' when size = 1 then 'Finalist'
           when size = 2 then 'Semi-finalist' when size = 4 then 'Quarter-finalist'
           else 'Round of ' || size * 2 end
    from done where not walkover
  ),
  per_player as (
    select u as user_id, f.pts, f.label || ', ' || f.title as what
    from finishes f
    cross join lateral unnest(public.tournament_players(f.entry)) u
    where f.entry is not null and f.pts is not null
      and not private.is_minor(u)
  ),
  totals as (
    select user_id, sum(pts)::int as points,
      (array_agg(what order by pts desc))[1] as best
    from per_player group by user_id
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'name', coalesce(p.full_name, p.username::text, 'Player'),
    'points', t.points, 'best', t.best,
    'mine', t.user_id = (select auth.uid())) order by t.points desc, p.full_name), '[]')
  from (select * from totals order by points desc limit 50) t
  join public.profiles p on p.id = t.user_id;
$$;

create or replace function public.club_leaderboard(p_club uuid, p_sport text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: ranks club members for another member.
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
      where m.club_id = p_club and not private.is_minor(m.user_id)
    ) x
  );
end;
$$;

-- Picking a person to invite is discovery too.
create or replace function public.club_invite_candidates() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads who the caller has played with.
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
    where not private.is_minor(u.id)
      and not public.is_blocked_between((select auth.uid()), u.id)
    group by u.id
    limit 50
  ) x
  where exists (select 1 from public.profiles p where p.id = x.id);
$$;

create or replace function public.team_candidates(p_team uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads club rosters for a team's staff.
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
      where not private.is_minor(u.id)
        and not public.is_blocked_between((select auth.uid()), u.id)
        and not exists (
        select 1 from public.team_members m where m.team_id = p_team and m.user_id = u.id
      ) and exists (select 1 from public.profiles p where p.id = u.id)
      limit 100
    ) x
  );
end;
$$;

create or replace function public.profile_social(target uuid)
returns table (followers bigint, following bigint, i_follow boolean, follows_me boolean)
language sql stable security definer set search_path = '' as $$
  -- Definer: counts follows the caller may not be able to read one by one.
  select
    (select count(*) from public.follows where followee_id = target),
    (select count(*) from public.follows where follower_id = target),
    exists (select 1 from public.follows where follower_id = auth.uid() and followee_id = target),
    exists (select 1 from public.follows where follower_id = target and followee_id = auth.uid())
  where private.can_view_profile(target, auth.uid());
$$;

-- R-MSG-1: adults cannot open a private chat with an under-18. Same wording as
-- a block, so this does not reveal anyone's age. A linked parent still can.
create or replace function public.open_direct_conversation(other uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: creates the conversation and both memberships together.
declare
  me uuid := auth.uid();
  conv uuid;
begin
  if me is null or other is null or me = other then
    raise exception 'Invalid conversation';
  end if;
  if public.is_blocked_between(me, other)
    or ((private.is_minor(me) or private.is_minor(other))
        and not private.is_guardian_of(me, other)
        and not private.is_guardian_of(other, me)
        and not (private.audience_of(me) = 'teen' and private.audience_of(other) = 'teen')) then
    raise exception 'You can''t message this player.' using errcode = 'insufficient_privilege';
  end if;
  select a.conversation_id into conv
  from public.conversation_members a
  join public.conversation_members b on b.conversation_id = a.conversation_id
  where a.user_id = me and b.user_id = other
    and (select count(*) from public.conversation_members c
         where c.conversation_id = a.conversation_id) = 2
  limit 1;
  if conv is null then
    insert into public.conversations default values returning id into conv;
    insert into public.conversation_members (conversation_id, user_id)
    values (conv, me), (conv, other);
  end if;
  return conv;
end;
$$;

-- ─── Recovery ──────────────────────────────────────────────────────────────

-- Was an open insert. Now a function, so the gate can rate-limit it and a
-- failed attempt looks the same as a good one.
drop policy "Anyone can ask for account recovery" on public.account_recovery_requests;

alter table public.account_recovery_requests
  add column status text not null default 'open'
    check (status in ('open', 'approved', 'refused')),
  add column reviewed_by uuid references auth.users (id) on delete set null,
  add column reviewed_at timestamptz;

create function public.account_recovery_request(p_email text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: account_recovery_requests has no client policies; staff read it.
begin
  if p_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    insert into public.account_recovery_requests (contact_email) values (lower(trim(p_email)));
  end if;
end;
$$;
revoke execute on function public.account_recovery_request(text) from public;
grant execute on function public.account_recovery_request(text) to anon, authenticated;

-- ─── Sign-in limits, used only by the resolve-login Edge Function ──────────

create table public.login_attempts (
  target_hash text primary key,
  wrong_count int not null default 0,
  locked_until timestamptz,
  updated_at timestamptz not null default now()
);
alter table public.login_attempts enable row level security;
revoke all on public.login_attempts from anon, authenticated;
-- No policies or grants. Holds a hash of the identifier, never the identifier.

create function public.login_gate_send(p_target_hash text, p_ip_hash text) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: writes rate_buckets on behalf of the Edge Function.
declare
  v_window int := private.setting_int('auth.send_window_minutes') * 60;
begin
  return private.rate_hit('login_send_target', p_target_hash,
      private.setting_int('auth.send_limit_target'), v_window)
    and private.rate_hit('login_send_ip', p_ip_hash,
      private.setting_int('auth.send_limit_ip'), v_window);
end;
$$;

create function public.login_gate_locked(p_target_hash text) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: login_attempts has no client policies.
  select coalesce((select locked_until > now() from public.login_attempts
    where target_hash = p_target_hash), false);
$$;

create function public.login_gate_result(p_target_hash text, p_ok boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: login_attempts has no client policies.
declare
  v_row public.login_attempts;
begin
  if p_ok then
    delete from public.login_attempts where target_hash = p_target_hash;
    return;
  end if;
  insert into public.login_attempts (target_hash, wrong_count) values (p_target_hash, 1)
  on conflict (target_hash) do update set
    wrong_count = case when public.login_attempts.locked_until <= now()
      then 1 else public.login_attempts.wrong_count + 1 end,
    locked_until = null,
    updated_at = now()
  returning * into v_row;
  if v_row.wrong_count >= private.setting_int('auth.code_lock_attempts') then
    update public.login_attempts
    set locked_until = now() + make_interval(mins => private.setting_int('auth.code_lock_minutes')),
        wrong_count = 0
    where target_hash = p_target_hash;
  end if;
end;
$$;

revoke execute on function public.login_gate_send(text, text) from public, anon, authenticated;
revoke execute on function public.login_gate_locked(text) from public, anon, authenticated;
revoke execute on function public.login_gate_result(text, boolean) from public, anon, authenticated;
grant execute on function public.login_gate_send(text, text) to service_role;
grant execute on function public.login_gate_locked(text) to service_role;
grant execute on function public.login_gate_result(text, boolean) to service_role;

-- Old buckets have no further use.
select cron.schedule('rate-buckets-prune', '20 * * * *',
  $$delete from private.rate_buckets where window_start < now() - interval '1 day'$$);

-- A username's sign-in details, for the Edge Function only. Email first when
-- it is verified, otherwise the mobile.
create function public.login_lookup(p_username text) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads auth.users, which only the Edge Function may ask about.
  select jsonb_build_object(
    'email', case when u.email_confirmed_at is not null then u.email end,
    'phone', case when u.email_confirmed_at is null and u.phone_confirmed_at is not null
      then '+' || u.phone end
  )
  from public.profiles p
  join auth.users u on u.id = p.id
  where p.username = p_username::extensions.citext;
$$;
revoke execute on function public.login_lookup(text) from public, anon, authenticated;
grant execute on function public.login_lookup(text) to service_role;

-- A player's session count, for their profile. Rows are no longer open to
-- every signed-in player, so the count needs its own door.
create function public.player_session_count(p_user uuid) returns int
language sql stable security definer set search_path = '' as $$
  -- Definer: counts rows the caller cannot read, and returns only the total.
  select case when private.can_view_profile(p_user, auth.uid()) then (
    select count(*)::int from public.activity_participants ap
    join public.activities a on a.id = ap.activity_id
    where ap.user_id = p_user and ap.status = 'joined' and a.starts_at < now()
  ) else 0 end;
$$;
revoke execute on function public.player_session_count(uuid) from public, anon;
grant execute on function public.player_session_count(uuid) to authenticated;
