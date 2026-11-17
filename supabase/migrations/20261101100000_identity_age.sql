-- Age paths (P1-03) and parent links (P1-08).
--
-- A player's age group is worked out from their birthday on every read and is
-- never stored, so nobody can write it and no job has to run on a birthday. A
-- player whose age is unknown counts as restricted: skipping the birthday step
-- must never be a way around the child protections.

create function private.age_years(p_birthday date, p_tz text) returns int
language sql stable set search_path = '' as $$
  select extract(year from age((now() at time zone p_tz)::date, p_birthday))::int;
$$;

create table public.guardian_links (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references auth.users (id) on delete cascade,
  parent_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'denied', 'revoked', 'ended')),
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  ended_at timestamptz,
  -- Set when the 30-day notice has gone out, so it only goes once.
  end_notice_at timestamptz,
  check (child_id <> parent_id)
);
create unique index guardian_links_live_idx on public.guardian_links (child_id, parent_id)
  where status in ('pending', 'approved');
create index guardian_links_parent_idx on public.guardian_links (parent_id, status);

-- Only the hash of a code is kept: a database reader cannot use one.
create table public.guardian_link_codes (
  id bigint generated always as identity primary key,
  child_id uuid not null references auth.users (id) on delete cascade,
  code_hash text not null unique,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);
create index guardian_link_codes_child_idx on public.guardian_link_codes (child_id);

-- Wrong-code counts per person trying a code.
create table public.guardian_code_attempts (
  user_id uuid primary key references auth.users (id) on delete cascade,
  wrong_count int not null default 0,
  locked_until timestamptz
);

alter table public.guardian_links enable row level security;
alter table public.guardian_link_codes enable row level security;
alter table public.guardian_code_attempts enable row level security;

create policy "Child and parent see their link" on public.guardian_links
  for select to authenticated
  using ((select auth.uid()) in (child_id, parent_id));
-- Codes and attempts have no policies or grants: only the functions below
-- touch them.
revoke all on public.guardian_link_codes from anon, authenticated;
revoke all on public.guardian_code_attempts from anon, authenticated;

create function private.audience_of(p_user uuid) returns text
language sql stable security definer set search_path = '' as $$
  -- Definer: birthdays are private to their owner, and every read path that
  -- protects a minor needs this answer for someone other than the caller.
  select coalesce((
    select case
      when ap.birthday is null or c.adult_age is null or c.child_age is null then 'unknown'
      when private.age_years(ap.birthday, c.timezone) >= c.adult_age then 'adult'
      when private.age_years(ap.birthday, c.timezone) >= c.child_age then 'teen'
      else 'child'
    end
    from public.account_private ap
    left join public.country_config c on c.country_code = ap.country_code
    where ap.id = p_user
  ), 'unknown');
$$;

create function private.is_minor(p_user uuid) returns boolean
language sql stable set search_path = '' as $$
  select private.audience_of(p_user) <> 'adult';
$$;

-- Parent approved, and the link has not ended.
create function private.is_guardian_of(p_parent uuid, p_child uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called from RLS policies on tables the caller cannot read.
  select exists (
    select 1 from public.guardian_links l
    where l.parent_id = p_parent and l.child_id = p_child and l.status = 'approved'
  ) and private.is_minor(p_child);
$$;

-- Restricted: under 18 or age unknown, with no approved parent.
create function private.is_restricted(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called from RLS policies and the request gate for any caller.
  select private.is_minor(p_user) and not exists (
    select 1 from public.guardian_links l
    where l.child_id = p_user and l.status = 'approved'
  );
$$;

-- "Mei T." Minors are never shown in full to people outside their family.
create function private.masked_name(p_full_name text) returns text
language sql immutable set search_path = '' as $$
  select case
    when p_full_name is null or trim(p_full_name) = '' then 'Player'
    when array_length(regexp_split_to_array(trim(p_full_name), '\s+'), 1) = 1 then trim(p_full_name)
    else (regexp_split_to_array(trim(p_full_name), '\s+'))[1] || ' '
      || left((regexp_split_to_array(trim(p_full_name), '\s+'))[2], 1) || '.'
  end;
$$;

create function private.can_view_profile(p_target uuid, p_viewer uuid) returns boolean
language sql stable set search_path = '' as $$
  select p_target = p_viewer
    or private.is_guardian_of(p_viewer, p_target)
    or (not private.is_minor(p_target)
        and not private.is_restricted(p_viewer)
        and not public.is_blocked_between(p_viewer, p_target));
$$;

revoke execute on function private.age_years(date, text) from public;
revoke execute on function private.audience_of(uuid) from public;
revoke execute on function private.is_minor(uuid) from public;
revoke execute on function private.is_guardian_of(uuid, uuid) from public;
revoke execute on function private.is_restricted(uuid) from public;
revoke execute on function private.masked_name(text) from public;
revoke execute on function private.can_view_profile(uuid, uuid) from public;
grant execute on function private.age_years(date, text) to authenticated, service_role;
grant execute on function private.audience_of(uuid) to authenticated, service_role;
grant execute on function private.is_minor(uuid) to authenticated, service_role;
grant execute on function private.is_guardian_of(uuid, uuid) to authenticated, service_role;
grant execute on function private.is_restricted(uuid) to anon, authenticated, service_role;
grant execute on function private.masked_name(text) to authenticated, service_role;
grant execute on function private.can_view_profile(uuid, uuid) to authenticated, service_role;

-- ─── Age is written once, by the server ────────────────────────────────────

-- Players could write their birthday and country straight to this table,
-- which made the age group theirs to choose.
revoke update on public.account_private from authenticated;
grant update (parent_email) on public.account_private to authenticated;

create function public.set_birthday(p_birthday date, p_country text) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: birthday and country are closed to players (above); this is the
-- one path that sets them, and it refuses a second attempt.
declare
  me uuid := auth.uid();
  v_private public.account_private;
begin
  if me is null then raise exception 'Sign in first.'; end if;
  if not exists (select 1 from public.country_config c
      where c.country_code = p_country and c.signup_open) then
    raise exception 'OlympusGO isn''t open in that country yet.';
  end if;
  if p_birthday is null or p_birthday > current_date or p_birthday < date '1900-01-02' then
    raise exception 'Check your birthday and try again.';
  end if;
  select * into v_private from public.account_private where id = me for update;
  if v_private.birthday is not null and v_private.birthday <> p_birthday then
    raise exception 'Your birthday can''t be changed once it is set.';
  end if;
  update public.account_private
  set birthday = p_birthday, country_code = p_country
  where id = me;
  return private.audience_of(me);
end;
$$;

-- Moving country later, which also moves the age limits, is for open
-- countries only.
create function public.set_country(p_country text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: country_code is closed to players (above).
begin
  if not exists (select 1 from public.country_config c
      where c.country_code = p_country and c.signup_open) then
    raise exception 'OlympusGO isn''t open in that country yet.';
  end if;
  update public.account_private set country_code = p_country where id = auth.uid();
end;
$$;

-- Everything the app needs to decide what to show. The app reads this for
-- its screens; the database enforces the same answers separately.
create function public.my_restrictions() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads the caller's own link and age through private helpers.
declare
  me uuid := auth.uid();
  v_audience text := private.audience_of(me);
  v_restricted boolean := private.is_restricted(me);
begin
  return jsonb_build_object(
    'audience', v_audience,
    'restricted', v_restricted,
    'pending_parent', exists (select 1 from public.guardian_links l
      where l.child_id = me and l.status = 'pending'),
    -- Under-13s never scan: a parent scans for them.
    'can_scan', not v_restricted and v_audience <> 'child',
    'can_chat', not v_restricted,
    'can_discover', not v_restricted,
    'can_shop', not v_restricted,
    'can_host', not v_restricted
  );
end;
$$;

revoke execute on function public.set_birthday(date, text) from public, anon;
revoke execute on function public.set_country(text) from public, anon;
revoke execute on function public.my_restrictions() from public, anon;
grant execute on function public.set_birthday(date, text) to authenticated;
grant execute on function public.set_country(text) to authenticated;
grant execute on function public.my_restrictions() to authenticated;

-- ─── Parent link ───────────────────────────────────────────────────────────

-- Eight characters from an alphabet with no 0, O, 1 or I, so a code read off
-- one phone and typed into another does not get misread.
create function private.new_link_code() returns text
language plpgsql volatile set search_path = '' as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  bytes bytea := extensions.gen_random_bytes(8);
  code text := '';
begin
  for i in 0..7 loop
    code := code || substr(alphabet, (get_byte(bytes, i) % 32) + 1, 1);
  end loop;
  return code;
end;
$$;
revoke execute on function private.new_link_code() from public;

create function private.code_hash(p_code text) returns text
language sql immutable set search_path = '' as $$
  select encode(extensions.digest(upper(trim(p_code)), 'sha256'), 'hex');
$$;
revoke execute on function private.code_hash(text) from public;

-- The child asks for a code. A new code cancels any earlier one.
create function public.guardian_code_create() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: writes guardian_link_codes, which has no client policies.
declare
  me uuid := auth.uid();
  v_code text := private.new_link_code();
  v_expires timestamptz := now() + make_interval(hours => private.setting_int('guardian.code_hours'));
begin
  if private.audience_of(me) not in ('child', 'teen') then
    raise exception 'Parent links are for players under 18.';
  end if;
  update public.guardian_link_codes set used_at = now()
  where child_id = me and used_at is null;
  insert into public.guardian_link_codes (child_id, code_hash, expires_at)
  values (me, private.code_hash(v_code), v_expires);
  return jsonb_build_object('code', v_code, 'expires_at', v_expires);
end;
$$;

-- The parent types the code. This starts a pending link and shows who it is
-- for; nothing changes for the child until the parent approves.
create function public.guardian_code_redeem(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: reads guardian_link_codes and the child's profile for the parent.
declare
  me uuid := auth.uid();
  v_attempt public.guardian_code_attempts;
  v_row public.guardian_link_codes;
  v_link uuid;
  v_name text;
begin
  -- Same wording for every failure, so a code cannot be probed.
  select * into v_attempt from public.guardian_code_attempts where user_id = me for update;
  if v_attempt.locked_until > now() then
    raise exception 'Too many tries. Wait a while, then try again.';
  end if;
  -- The age check comes first, so a parent under 18 cannot learn that a code
  -- is real and cannot use up its attempts.
  if private.audience_of(me) <> 'adult' then
    raise exception 'A parent or guardian must be 18 or over.';
  end if;

  select * into v_row from public.guardian_link_codes
  where code_hash = private.code_hash(coalesce(p_code, ''))
    and used_at is null and expires_at > now() and child_id <> me
  for update;

  if v_row.id is null then
    insert into public.guardian_code_attempts (user_id, wrong_count) values (me, 1)
    on conflict (user_id) do update set
      wrong_count = case when public.guardian_code_attempts.locked_until <= now()
        then 1 else public.guardian_code_attempts.wrong_count + 1 end,
      locked_until = null
    returning * into v_attempt;
    if v_attempt.wrong_count >= private.setting_int('auth.code_lock_attempts') then
      update public.guardian_code_attempts
      set locked_until = now() + make_interval(mins => private.setting_int('auth.code_lock_minutes')),
          wrong_count = 0
      where user_id = me;
    end if;
    -- Returned, not raised: raising would roll back the count written above.
    return jsonb_build_object('error', 'That code didn''t work. Check it and try again.');
  end if;

  update public.guardian_link_codes set used_at = now() where id = v_row.id;
  delete from public.guardian_code_attempts where user_id = me;

  insert into public.guardian_links (child_id, parent_id)
  values (v_row.child_id, me)
  on conflict (child_id, parent_id) where status in ('pending', 'approved')
    do update set created_at = public.guardian_links.created_at
  returning id into v_link;

  select coalesce(p.full_name, 'Your child') into v_name
  from public.profiles p where p.id = v_row.child_id;

  return jsonb_build_object('link_id', v_link, 'child_name', v_name);
end;
$$;

create function public.guardian_link_decide(p_link uuid, p_approve boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: guardian_links has no write policy; the parent acts through here.
declare
  v_link public.guardian_links;
begin
  select * into v_link from public.guardian_links
  where id = p_link and parent_id = auth.uid() for update;
  if v_link.id is null or v_link.status <> 'pending' then
    raise exception 'This request is no longer waiting for you.';
  end if;
  if private.audience_of(auth.uid()) <> 'adult' then
    raise exception 'A parent or guardian must be 18 or over.';
  end if;
  update public.guardian_links
  set status = case when p_approve then 'approved' else 'denied' end, decided_at = now()
  where id = p_link;
  perform public.notify(v_link.child_id,
    case when p_approve then 'Your parent linked your account' else 'Your parent said no to the link' end,
    case when p_approve then 'You can use OlympusGO now.' else 'Ask them to try again when they are ready.' end,
    '!', '/parent-link');
end;
$$;

-- The parent ends the link. The child goes back to restricted at once.
create function public.guardian_link_revoke(p_link uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: guardian_links has no write policy; the parent acts through here.
declare
  v_link public.guardian_links;
begin
  select * into v_link from public.guardian_links
  where id = p_link and parent_id = auth.uid() for update;
  if v_link.id is null or v_link.status <> 'approved' then
    raise exception 'This link is no longer active.';
  end if;
  update public.guardian_links set status = 'revoked', ended_at = now() where id = p_link;
  perform public.notify(v_link.child_id, 'Your parent ended the link',
    'Ask a parent to link your account to keep playing.', '!', '/parent-link');
end;
$$;

create function public.guardian_children() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads the child's profile for their linked parent.
  select coalesce(jsonb_agg(jsonb_build_object(
    'link_id', l.id, 'child_id', l.child_id, 'status', l.status,
    'name', coalesce(p.full_name, 'Your child'), 'avatar_url', p.avatar_url,
    'created_at', l.created_at
  ) order by l.created_at desc), '[]'::jsonb)
  from public.guardian_links l
  join public.profiles p on p.id = l.child_id
  where l.parent_id = (select auth.uid()) and l.status in ('pending', 'approved');
$$;

create function public.guardian_parents() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads the parent's name for the child who linked to them.
  select coalesce(jsonb_agg(jsonb_build_object(
    'link_id', l.id, 'status', l.status,
    'name', coalesce(p.full_name, 'Your parent')
  ) order by l.created_at desc), '[]'::jsonb)
  from public.guardian_links l
  join public.profiles p on p.id = l.parent_id
  where l.child_id = (select auth.uid()) and l.status in ('pending', 'approved');
$$;

-- What a child has posted, for their parent to see and delete.
create function public.guardian_child_posts(p_child uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: gathers the child's posts across tables the parent cannot read.
declare
  v_posts jsonb;
begin
  if not private.is_guardian_of(auth.uid(), p_child) then
    raise exception 'Only a linked parent can see this.';
  end if;
  select coalesce(jsonb_agg(x order by x.created_at desc), '[]'::jsonb) into v_posts from (
    select 'chat' as kind, m.id::text as id, m.body as body, m.created_at
    from public.group_messages m
    where m.sender_id = p_child and not m.removed and m.body is not null
    union all
    select 'club_review', r.club_id::text, r.review, r.created_at
    from public.club_ratings r
    where r.user_id = p_child and r.review is not null
    union all
    select 'product_review', r.id::text, r.body, r.created_at
    from public.product_reviews r
    where r.user_id = p_child
  ) x;
  return v_posts;
end;
$$;

create function public.guardian_delete_post(p_child uuid, p_kind text, p_id text)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: removes a child's post from tables the parent cannot write.
begin
  if not private.is_guardian_of(auth.uid(), p_child) then
    raise exception 'Only a linked parent can do this.';
  end if;
  case p_kind
    when 'chat' then
      update public.group_messages set removed = true, removed_by = auth.uid()
      where id = p_id::uuid and sender_id = p_child;
    when 'club_review' then
      delete from public.club_ratings where club_id = p_id::uuid and user_id = p_child;
    when 'product_review' then
      delete from public.product_reviews where id = p_id::uuid and user_id = p_child;
    else
      raise exception 'Unknown post.';
  end case;
end;
$$;

revoke execute on function public.guardian_code_create() from public, anon;
revoke execute on function public.guardian_code_redeem(text) from public, anon;
revoke execute on function public.guardian_link_decide(uuid, boolean) from public, anon;
revoke execute on function public.guardian_link_revoke(uuid) from public, anon;
revoke execute on function public.guardian_children() from public, anon;
revoke execute on function public.guardian_parents() from public, anon;
revoke execute on function public.guardian_child_posts(uuid) from public, anon;
revoke execute on function public.guardian_delete_post(uuid, text, text) from public, anon;
grant execute on function public.guardian_code_create() to authenticated;
grant execute on function public.guardian_code_redeem(text) to authenticated;
grant execute on function public.guardian_link_decide(uuid, boolean) to authenticated;
grant execute on function public.guardian_link_revoke(uuid) to authenticated;
grant execute on function public.guardian_children() to authenticated;
grant execute on function public.guardian_parents() to authenticated;
grant execute on function public.guardian_child_posts(uuid) to authenticated;
grant execute on function public.guardian_delete_post(uuid, text, text) to authenticated;

-- ─── Links end at adulthood (R-AGE-4) ──────────────────────────────────────

-- Run daily. Safe to run twice: each link is told once and ended once.
create function private.guardian_links_daily() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: runs from pg_cron with no user, across every link.
declare
  v_notice int := private.setting_int('guardian.end_notice_days');
  r record;
begin
  for r in
    select l.id, l.child_id, l.parent_id
    from public.guardian_links l
    join public.account_private ap on ap.id = l.child_id
    join public.country_config c on c.country_code = ap.country_code
    where l.status = 'approved' and l.end_notice_at is null
      and ap.birthday is not null and c.adult_age is not null
      and private.age_years(ap.birthday, c.timezone) < c.adult_age
      and private.age_years((ap.birthday - make_interval(days => v_notice))::date, c.timezone) >= c.adult_age
  loop
    update public.guardian_links set end_notice_at = now() where id = r.id;
    perform public.notify(r.child_id, 'Your parent link is ending soon',
      'It ends when you turn 18.', '!', '/parent-link');
    perform public.notify(r.parent_id, 'A parent link is ending soon',
      'It ends when your child turns 18.', '!', '/parent-link');
  end loop;

  update public.guardian_links l set status = 'ended', ended_at = now()
  where l.status = 'approved' and private.audience_of(l.child_id) = 'adult';
end;
$$;
revoke execute on function private.guardian_links_daily() from public;

create extension if not exists pg_cron;
select cron.schedule('guardian-links-daily', '10 16 * * *', 'select private.guardian_links_daily()');
