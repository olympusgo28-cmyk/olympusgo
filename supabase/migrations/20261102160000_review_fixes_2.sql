-- Fixes from the independent security review of Phase 2.

-- ─── 1. The internal sign-in address must not be derivable ─────────────────

-- It was built from the user id, which is public, so anyone could ask Supabase
-- Auth for a code for any account and guess at /verify with no lockout. Each
-- account now has a random address stored only here, so there is nothing to
-- ask for.
create function private.random_auth_email() returns text
language sql volatile set search_path = '' as $$
  select 'u-' || encode(extensions.gen_random_bytes(20), 'hex') || '@users.olympusgo.invalid';
$$;
revoke execute on function private.random_auth_email() from public;
grant execute on function private.random_auth_email() to service_role;

alter table public.account_private add column auth_email text;
create unique index account_private_auth_email_idx on public.account_private (auth_email);
-- Owners can read their row, so keep this column out of what they can select.
revoke select on public.account_private from authenticated;
grant select (id, birthday, country_code, parent_email, parent_approved_at, created_at, updated_at,
  identity_verified_at, mobile, mobile_verified_at, email, email_verified_at)
  on public.account_private to authenticated;

update auth.users u set email = private.random_auth_email()
where u.email like '%@users.olympusgo.invalid';
update public.account_private ap set auth_email = u.email
from auth.users u where u.id = ap.id and u.email like '%@users.olympusgo.invalid';
update auth.identities i
set identity_data = i.identity_data || jsonb_build_object('email', u.email)
from auth.users u
where u.id = i.user_id and i.provider = 'email' and u.email like '%@users.olympusgo.invalid';

drop function private.internal_email(uuid);

create or replace function public.login_lookup(p_kind text, p_value text) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads private contact details and the internal address.
  select jsonb_build_object('user_id', ap.id, 'mobile', ap.mobile,
    'email', case when ap.email_verified_at is not null then ap.email end,
    'internal_email', ap.auth_email)
  from public.account_private ap
  left join public.profiles p on p.id = ap.id
  where ap.auth_email is not null and case p_kind
    when 'mobile' then ap.mobile = p_value and ap.mobile_verified_at is not null
    when 'email' then ap.email = lower(p_value) and ap.email_verified_at is not null
    when 'username' then p.username = p_value::extensions.citext
    else false
  end
  limit 1;
$$;

-- A new account: its mobile and its internal address, together.
create function public.login_account_bind(p_user uuid, p_mobile text, p_auth_email text) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: these columns are closed to players.
begin
  update public.account_private
  set mobile = p_mobile, mobile_verified_at = now(), auth_email = p_auth_email
  where id = p_user;
  return true;
exception when unique_violation then
  return false;
end;
$$;
revoke execute on function public.login_account_bind(uuid, text, text) from public, anon, authenticated;
grant execute on function public.login_account_bind(uuid, text, text) to service_role;

-- ─── 2. Teams need a parent's approval too (R-TEM-1) ───────────────────────

create table public.guardian_team_approvals (
  child_id uuid not null references auth.users (id) on delete cascade,
  team_id uuid not null references public.teams (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'denied')),
  decided_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  primary key (child_id, team_id)
);
alter table public.guardian_team_approvals enable row level security;
revoke all on public.guardian_team_approvals from anon, authenticated;

create function private.team_allowed(p_user uuid, p_team uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called from policies for any caller.
  select not private.is_minor(p_user)
    or exists (select 1 from public.guardian_team_approvals a
      where a.child_id = p_user and a.team_id = p_team and a.status = 'approved')
    or exists (select 1 from public.teams t where t.id = p_team and t.owner_id = p_user);
$$;
revoke execute on function private.team_allowed(uuid, uuid) from public;
grant execute on function private.team_allowed(uuid, uuid) to authenticated, service_role;

-- Every way onto a team passes through this table. A child is not added: the
-- request waits for their parent instead.
create function private.team_member_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the approval request and tells the parents.
begin
  if private.team_allowed(new.user_id, new.team_id) then
    return new;
  end if;
  insert into public.guardian_team_approvals (child_id, team_id) values (new.user_id, new.team_id)
  on conflict (child_id, team_id) do nothing;
  perform public.notify(l.parent_id, 'A team is waiting for you',
    'Your child was invited to a team.', '!', '/parent-link/children/' || new.user_id)
  from public.guardian_links l where l.child_id = new.user_id and l.status = 'approved';
  return null;
end;
$$;
create trigger team_members_guard before insert on public.team_members
  for each row execute function private.team_member_guard();

drop policy "Children chat only in approved groups" on public.group_messages;
create policy "Children chat only in approved groups" on public.group_messages
  as restrictive for all to authenticated
  using ((club_id is null or private.group_allowed((select auth.uid()), club_id))
    and (team_id is null or private.team_allowed((select auth.uid()), team_id)))
  with check ((club_id is null or private.group_allowed((select auth.uid()), club_id))
    and (team_id is null or private.team_allowed((select auth.uid()), team_id)));

drop function public.guardian_group_requests(uuid);
create function public.guardian_group_requests(p_child uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads a child's requests and the group's name for their parent.
begin
  if not private.is_guardian_of(auth.uid(), p_child) then
    raise exception 'Only a linked parent can see this.';
  end if;
  return (select coalesce(jsonb_agg(x), '[]'::jsonb) from (
    select 'club' as kind, c.id as club_id, c.name, c.area
    from public.guardian_group_approvals a join public.clubs c on c.id = a.club_id
    where a.child_id = p_child and a.status = 'pending'
    union all
    select 'team', t.id, t.name, ''
    from public.guardian_team_approvals a join public.teams t on t.id = a.team_id
    where a.child_id = p_child and a.status = 'pending') x);
end;
$$;
revoke execute on function public.guardian_group_requests(uuid) from public, anon;
grant execute on function public.guardian_group_requests(uuid) to authenticated;

create function public.guardian_team_decide(p_child uuid, p_team uuid, p_approve boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the approval and adds the child to the team.
begin
  if not private.is_guardian_of(auth.uid(), p_child) then
    raise exception 'Only a linked parent can do this.';
  end if;
  update public.guardian_team_approvals
  set status = case when p_approve then 'approved' else 'denied' end,
      decided_by = auth.uid(), decided_at = now()
  where child_id = p_child and team_id = p_team and status = 'pending';
  if not found then raise exception 'This request is no longer waiting for you.'; end if;
  if p_approve then
    insert into public.team_members (team_id, user_id) values (p_team, p_child) on conflict do nothing;
  end if;
end;
$$;
revoke execute on function public.guardian_team_decide(uuid, uuid, boolean) from public, anon;
grant execute on function public.guardian_team_decide(uuid, uuid, boolean) to authenticated;

-- ─── 3. Owners cannot un-hide their own content ────────────────────────────

create or replace function private.activity_lock_columns() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user = 'authenticated' then
    new.status := old.status;
    new.host_id := old.host_id;
    new.kind := old.kind;
    new.scoring_snapshot := old.scoring_snapshot;
    new.game_on_at := old.game_on_at;
    new.hidden_at := old.hidden_at;
    if private.is_minor(old.host_id) then
      new.public_listing := false;
    end if;
    if private.attendance_saved(old.id) then
      new.starts_at := old.starts_at;
      new.ends_at := old.ends_at;
    end if;
  end if;
  return new;
end;
$$;

create or replace function private.profile_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.visibility = 'everyone' and private.is_minor(new.id) then
    new.visibility := 'followers';
  end if;
  if tg_op = 'UPDATE' and current_user = 'authenticated' then
    new.hidden_at := old.hidden_at;
  end if;
  return new;
end;
$$;

create function private.message_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user = 'authenticated' then
    new.hidden_at := null;
    new.deleted_at := null;
  end if;
  return new;
end;
$$;
create trigger messages_guard before insert on public.messages
  for each row execute function private.message_guard();

-- ─── 4. A cleared item stays cleared ───────────────────────────────────────

-- Only reports made since the last decision count, so one new report cannot
-- re-hide something staff already kept.
create or replace function private.report_to_case() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: moderation_cases and case_reports have no client access.
declare
  v_kind text;
  v_id text;
  v_owner uuid;
  v_child boolean;
  v_case public.moderation_cases;
  v_reporters int;
begin
  if tg_table_name = 'player_reports' then
    v_kind := 'player';
    v_id := new.reported_id::text;
  else
    v_kind := new.target_kind;
    v_id := new.target_id;
  end if;
  v_owner := private.case_owner(v_kind, v_id);
  v_child := private.is_minor(new.reporter_id) or (v_owner is not null and private.is_minor(v_owner));

  insert into public.moderation_cases as m
    (target_kind, target_id, owner_id, involves_child, deadline_at)
  values (v_kind, v_id, v_owner, v_child, now() + make_interval(hours =>
    private.setting_int(case when v_child then 'moderation.child_deadline_hours' else 'moderation.deadline_hours' end)))
  on conflict (target_kind, target_id) do update
    set involves_child = m.involves_child or excluded.involves_child,
        deadline_at = case when excluded.involves_child and not m.involves_child
          then least(m.deadline_at, excluded.deadline_at) else m.deadline_at end
  returning * into v_case;

  insert into public.case_reports (case_id, reporter_id, reason, note)
  values (v_case.id, new.reporter_id, new.reason, new.note)
  on conflict (case_id, reporter_id) do update
    set created_at = case when public.case_reports.created_at < v_case.decided_at
      then now() else public.case_reports.created_at end;

  select count(*) into v_reporters from public.case_reports r
  where r.case_id = v_case.id and r.created_at > coalesce(v_case.decided_at, '-infinity');

  if v_reporters >= private.setting_int('moderation.auto_hide_reports')
    and v_case.status <> 'removed' and v_case.hidden_at is null then
    update public.moderation_cases set hidden_at = now(), status = 'open' where id = v_case.id;
    perform private.case_set_hidden(v_kind, v_id, true);
  elsif v_case.status = 'kept' and v_reporters > 0 then
    -- Back in the queue for a person to look at, but left visible.
    update public.moderation_cases set status = 'open' where id = v_case.id;
  end if;
  return new;
end;
$$;

-- ─── 5. Two more functions that returned real names ────────────────────────

do $$
declare
  d text := pg_get_functiondef('public.my_reports()'::regprocedure);
  fixed text := replace(d, 'coalesce(p.full_name, p.username)', 'coalesce(private.public_name(p.id), p.username)');
begin
  if fixed = d then raise exception 'my_reports did not change'; end if;
  execute fixed;
end;
$$;

create or replace function public.my_blocked_players()
returns table (id uuid, username text, full_name text, avatar_url text)
language sql stable security definer set search_path = '' as $$
  -- Definer: blocked players cannot be read directly by the blocker.
  select p.id,
    case when private.is_minor(p.id) then null else p.username::text end,
    private.public_name(p.id),
    case when private.is_minor(p.id) then null else p.avatar_url end
  from public.blocks b join public.profiles p on p.id = b.blocked_id
  where b.blocker_id = auth.uid()
  order by b.created_at desc;
$$;

-- ─── 6. Suspended players can read and get help, and nothing else ──────────

create table private.suspended_allow (path text primary key);
insert into private.suspended_allow (path) values
  ('/rpc/my_restrictions'), ('/rpc/staff_whoami'), ('/rpc/legal_notice_send'),
  ('/rpc/my_reports'), ('/rpc/removal_ask_review'), ('/rpc/guardian_parents');

create or replace function private.gate_request() returns void
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

  if v_user is not null and private.is_restricted(v_user) and not private.is_staff() then
    if private.is_suspended(v_user) then
      if not ((v_method in ('GET', 'HEAD')
            and exists (select 1 from private.restricted_allow a where a.path = v_path))
          or exists (select 1 from private.suspended_allow a where a.path = v_path)) then
        raise exception 'Your account is suspended.' using errcode = 'P0001';
      end if;
    elsif not exists (select 1 from private.restricted_allow a where a.path = v_path) then
      raise exception 'Ask a parent to link your account first.' using errcode = 'P0001';
    end if;
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

do $$
declare
  n text;
  d text;
  fixed text;
begin
  foreach n in array array['public.discover_players(text, numeric, int)', 'public.suggested_players()'] loop
    d := pg_get_functiondef(n::regprocedure);
    fixed := replace(d, 'not private.is_minor(p.id)', 'not private.is_minor(p.id) and not private.is_suspended(p.id)');
    if fixed = d then raise exception '% did not change', n; end if;
    execute fixed;
  end loop;
end;
$$;

-- ─── 7. Text checks cover names too ────────────────────────────────────────

create or replace function private.check_text() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_problem text;
begin
  -- Read through jsonb: each table this runs on has different columns.
  v_problem := private.text_problem(case tg_table_name
    when 'profiles' then concat_ws(' ', to_jsonb(new) ->> 'bio', to_jsonb(new) ->> 'full_name', to_jsonb(new) ->> 'username')
    when 'activities' then concat_ws(' ', to_jsonb(new) ->> 'title', to_jsonb(new) ->> 'description')
    else to_jsonb(new) ->> 'body' end);
  if v_problem = 'phone' then
    raise exception 'Keep phone numbers out of this, so everyone stays safe.' using errcode = 'P0001';
  elsif v_problem = 'link' then
    raise exception 'Links to other apps can''t be posted here.' using errcode = 'P0001';
  elsif v_problem = 'word' then
    raise exception 'That wording isn''t allowed. Try saying it another way.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger profiles_check_text on public.profiles;
create trigger profiles_check_text before update of bio, full_name, username on public.profiles
  for each row execute function private.check_text();
