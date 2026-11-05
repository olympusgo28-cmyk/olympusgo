-- P2-07 and A-03. Every report feeds one case per reported item. Three distinct
-- reporters hide the item until staff decide. Reports keep arriving the way
-- they always have, through content_reports and player_reports, so every
-- existing report path is covered by the trigger below.

alter table public.content_reports drop constraint if exists content_reports_target_kind_check;
alter table public.content_reports add constraint content_reports_target_kind_check
  check (target_kind in ('message', 'dm', 'club', 'team', 'activity', 'video', 'live', 'listing'));

alter table public.messages add column hidden_at timestamptz;
alter table public.activities add column hidden_at timestamptz;
alter table public.profiles add column hidden_at timestamptz;
alter table public.clubs add column hidden_at timestamptz;
alter table public.teams add column hidden_at timestamptz;
alter table public.products add column hidden_at timestamptz;

insert into public.app_settings (key, value, description) values
  ('moderation.auto_hide_reports', '3', 'Distinct reporters before an item hides itself'),
  ('moderation.deadline_hours', '24', 'Hours to answer a report (R-MOD-1)'),
  ('moderation.child_deadline_hours', '24', 'Hours to answer a report involving a child');

create table public.moderation_cases (
  id uuid primary key default gen_random_uuid(),
  target_kind text not null,
  target_id text not null,
  -- Who posted it, for the removal notice.
  owner_id uuid references auth.users (id) on delete set null,
  status text not null default 'open' check (status in ('open', 'removed', 'kept')),
  involves_child boolean not null default false,
  deadline_at timestamptz not null,
  hidden_at timestamptz,
  decided_by uuid references auth.users (id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  unique (target_kind, target_id)
);
create index moderation_cases_queue_idx on public.moderation_cases (deadline_at) where status = 'open';

create table public.case_reports (
  case_id uuid not null references public.moderation_cases (id) on delete cascade,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reason text not null,
  note text,
  created_at timestamptz not null default now(),
  primary key (case_id, reporter_id)
);

create table public.account_moderation (
  user_id uuid primary key references auth.users (id) on delete cascade,
  warnings int not null default 0,
  suspended_until timestamptz,
  banned_at timestamptz
);

-- R-MOD-4: a ban needs a second staff member.
create table public.ban_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  requested_by uuid not null references auth.users (id),
  reason text not null,
  approved_by uuid references auth.users (id),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
create unique index ban_requests_open_idx on public.ban_requests (user_id) where decided_at is null;

create table public.moderation_words (
  word text primary key,
  language text not null,
  category text not null check (category in ('profanity', 'suggestive')),
  active boolean not null default true
);

alter table public.moderation_cases enable row level security;
alter table public.case_reports enable row level security;
alter table public.account_moderation enable row level security;
alter table public.ban_requests enable row level security;
alter table public.moderation_words enable row level security;
revoke all on public.moderation_cases, public.case_reports, public.account_moderation,
  public.ban_requests, public.moderation_words from anon, authenticated;

-- A starter list only. It needs review by native speakers of each language.
insert into public.moderation_words (word, language, category) values
  ('fuck', 'en', 'profanity'), ('shit', 'en', 'profanity'), ('bitch', 'en', 'profanity'),
  ('cunt', 'en', 'profanity'), ('asshole', 'en', 'profanity'),
  ('nudes', 'en', 'suggestive'), ('sexy', 'en', 'suggestive'), ('horny', 'en', 'suggestive'),
  ('babi', 'ms', 'profanity'), ('puki', 'ms', 'profanity'), ('sial', 'ms', 'profanity'),
  ('kanina', 'zh', 'profanity'), ('lanjiao', 'zh', 'profanity'), ('cao ni ma', 'zh', 'profanity'),
  ('punda', 'ta', 'profanity'), ('thevidiya', 'ta', 'profanity');

-- ─── Suspensions (R-MOD-5: at once, not when the token expires) ────────────

create function private.is_suspended(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: account_moderation has no client access.
  select exists (select 1 from public.account_moderation m
    where m.user_id = p_user and (m.banned_at is not null or m.suspended_until > now()));
$$;
revoke execute on function private.is_suspended(uuid) from public;
grant execute on function private.is_suspended(uuid) to anon, authenticated, service_role;

create or replace function private.is_restricted(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called from RLS policies and the request gate for any caller.
  select not private.has_verified_mobile(p_user)
    or private.is_suspended(p_user)
    or (private.is_minor(p_user) and not exists (
      select 1 from public.guardian_links l
      where l.child_id = p_user and l.status = 'approved'));
$$;

create function private.profile_hidden(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called while the caller may not be able to read the row.
  select coalesce((select hidden_at is not null from public.profiles where id = p_user), false);
$$;
revoke execute on function private.profile_hidden(uuid) from public;
grant execute on function private.profile_hidden(uuid) to authenticated, service_role;

create or replace function private.can_view_profile(p_target uuid, p_viewer uuid) returns boolean
language sql stable set search_path = '' as $$
  select p_target = p_viewer
    or private.is_guardian_of(p_viewer, p_target)
    or (not private.is_minor(p_target)
        and not private.is_restricted(p_viewer)
        and not public.is_blocked_between(p_viewer, p_target)
        and not private.profile_hidden(p_target));
$$;

-- my_restrictions is read to choose what to show, so it says why.
do $$
declare
  d text := pg_get_functiondef('public.my_restrictions()'::regprocedure);
  fixed text := replace(d, $old$'restricted', v_restricted,$old$,
    $new$'restricted', v_restricted,
    'suspended', private.is_suspended(me),$new$);
begin
  if fixed = d then raise exception 'my_restrictions did not change'; end if;
  execute fixed;
end;
$$;

-- ─── Hidden items ──────────────────────────────────────────────────────────

create policy "Hidden messages stay with their sender" on public.messages
  as restrictive for select to authenticated
  using (hidden_at is null or sender_id = (select auth.uid()));

create policy "Hidden activities stay with their host" on public.activities
  as restrictive for select to authenticated
  using (hidden_at is null or host_id = (select auth.uid()));

create or replace function public.club_visible(p_club uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: clubs has no client policies.
  select exists (
    select 1 from public.clubs c
    where c.id = p_club
      and (c.hidden_at is null or public.club_is_member(c.id))
      and (
      c.visibility <> 'hidden'
      or public.club_is_member(c.id)
      or exists (
        select 1 from public.club_invites i
        where i.club_id = c.id and i.user_id = (select auth.uid())
      )
    )
  );
$$;

do $$
declare
  d text := pg_get_functiondef('public.club_list(text)'::regprocedure);
  fixed text := replace(d, $old$c.visibility = 'public'$old$, $new$c.visibility = 'public' and c.hidden_at is null$new$);
begin
  if fixed = d then raise exception 'club_list did not change'; end if;
  execute fixed;
end;
$$;

create function private.case_set_hidden(p_kind text, p_id text, p_hidden boolean) returns void
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
    else null;
  end case;
end;
$$;
revoke execute on function private.case_set_hidden(text, text, boolean) from public;

create function private.case_owner(p_kind text, p_id text) returns uuid
language sql stable security definer set search_path = '' as $$
  -- Definer: reads who posted something the caller cannot see.
  select case p_kind
    when 'player' then p_id::uuid
    when 'dm' then (select sender_id from public.messages where id::text = p_id)
    when 'message' then (select sender_id from public.group_messages where id::text = p_id)
    when 'activity' then (select host_id from public.activities where id::text = p_id)
    when 'club' then (select owner_id from public.clubs where id::text = p_id)
  end;
$$;
revoke execute on function private.case_owner(text, text) from public;

-- Called once per new report row.
create function private.report_to_case() returns trigger
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
          then least(m.deadline_at, excluded.deadline_at) else m.deadline_at end,
        status = case when m.status = 'kept' then 'open' else m.status end
  returning * into v_case;

  insert into public.case_reports (case_id, reporter_id, reason, note)
  values (v_case.id, new.reporter_id, new.reason, new.note)
  on conflict do nothing;

  select count(*) into v_reporters from public.case_reports where case_id = v_case.id;
  if v_case.status = 'open' and v_case.hidden_at is null
    and v_reporters >= private.setting_int('moderation.auto_hide_reports') then
    update public.moderation_cases set hidden_at = now() where id = v_case.id;
    perform private.case_set_hidden(v_kind, v_id, true);
  end if;
  return new;
end;
$$;

create trigger content_reports_case after insert on public.content_reports
  for each row execute function private.report_to_case();
create trigger player_reports_case after insert on public.player_reports
  for each row execute function private.report_to_case();

-- Reporters get a neutral acknowledgement only (checklist P2-07), so nobody
-- learns how a report ended.
do $$
declare
  d text := pg_get_functiondef('public.my_reports()'::regprocedure);
  fixed text;
begin
  fixed := replace(d, $old$'status', r.status$old$, $new$'status', 'in_review'$new$);
  fixed := replace(fixed, $old$'result', r.result$old$, $new$'result', null$new$);
  fixed := replace(fixed, $old$'decided_at', r.decided_at$old$, $new$'decided_at', null$new$);
  fixed := replace(fixed, $old$'second_look', r.second_look$old$, $new$'second_look', false$new$);
  if fixed = d then raise exception 'my_reports did not change'; end if;
  execute fixed;
end;
$$;

-- ─── Text checks ───────────────────────────────────────────────────────────

-- Names the problem, or null. Run in the database so no client can skip it.
create function private.text_problem(p_text text) returns text
language plpgsql stable security definer set search_path = '' as $$
-- Definer: moderation_words has no client access.
declare
  v text := lower(coalesce(p_text, ''));
begin
  if v ~ '(^|[^0-9])(\+?65[ -]?)?[689][0-9]{3}[ -]?[0-9]{4}([^0-9]|$)' then return 'phone'; end if;
  if v ~ '(https?://|www\.|wa\.me|t\.me|telegram\.me|discord\.gg|instagram\.com|facebook\.com)' then
    return 'link';
  end if;
  if exists (select 1 from public.moderation_words w
      where w.active and v ~ ('(^|[^a-z])' || w.word || '([^a-z]|$)')) then
    return 'word';
  end if;
  return null;
end;
$$;
revoke execute on function private.text_problem(text) from public;
grant execute on function private.text_problem(text) to authenticated, service_role;

create function private.check_text() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_problem text;
begin
  -- Read through jsonb: each table this runs on has different columns.
  v_problem := private.text_problem(case tg_table_name
    when 'profiles' then to_jsonb(new) ->> 'bio'
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

create trigger messages_check_text before insert on public.messages
  for each row execute function private.check_text();
create trigger group_messages_check_text before insert on public.group_messages
  for each row execute function private.check_text();
create trigger profiles_check_text before update of bio on public.profiles
  for each row execute function private.check_text();
create trigger activities_check_text before insert or update of title, description on public.activities
  for each row execute function private.check_text();

-- ─── Staff queue (A-03) ────────────────────────────────────────────────────

create function public.staff_case_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: cases have no client access. Moderators only, and no payment data.
begin
  perform private.staff_require('moderator');
  return (select coalesce(jsonb_agg(x order by (x ->> 'deadline_at'), (x ->> 'reports')::int desc), '[]'::jsonb)
    from (select jsonb_build_object('id', c.id, 'kind', c.target_kind, 'target_id', c.target_id,
        'owner', c.owner_id, 'child', c.involves_child, 'deadline_at', c.deadline_at,
        'hidden', c.hidden_at is not null,
        'reports', (select count(*) from public.case_reports r where r.case_id = c.id),
        'reasons', (select jsonb_agg(distinct r.reason) from public.case_reports r where r.case_id = c.id)) as x
      from public.moderation_cases c where c.status = 'open') y);
end;
$$;

create function private.case_text(p_kind text, p_id text) returns text
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
  end;
$$;
revoke execute on function private.case_text(text, text) from public;

create function public.staff_case_get(p_case uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: cases have no client access.
declare
  c public.moderation_cases;
begin
  perform private.staff_require('moderator');
  select * into c from public.moderation_cases where id = p_case;
  if c.id is null then raise exception 'Not found.'; end if;
  return to_jsonb(c) || jsonb_build_object(
    'text', private.case_text(c.target_kind, c.target_id),
    'reports', (select coalesce(jsonb_agg(jsonb_build_object('reason', r.reason, 'note', r.note, 'at', r.created_at)
      order by r.created_at), '[]'::jsonb) from public.case_reports r where r.case_id = p_case),
    'owner_warnings', coalesce((select warnings from public.account_moderation where user_id = c.owner_id), 0));
end;
$$;

-- 'removed' stays hidden and tells the poster. 'kept' puts it back.
create function public.staff_case_decide(p_case uuid, p_outcome text, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes cases, notices and the audit log.
declare
  c public.moderation_cases;
begin
  perform private.staff_require('moderator');
  if p_outcome not in ('removed', 'kept') then raise exception 'Choose an outcome.'; end if;
  select * into c from public.moderation_cases where id = p_case for update;
  if c.id is null or c.status <> 'open' then raise exception 'This case is closed.'; end if;
  update public.moderation_cases
  set status = p_outcome, decided_by = auth.uid(), decided_at = now(),
      hidden_at = case when p_outcome = 'removed' then coalesce(hidden_at, now()) end
  where id = p_case;
  perform private.case_set_hidden(c.target_kind, c.target_id, p_outcome = 'removed');
  if p_outcome = 'removed' and c.owner_id is not null then
    insert into public.content_removals (user_id, what, where_text, rule, decided_by, why, next)
    values (c.owner_id, c.target_kind, c.target_kind, 'Community rules', 'Olympus safety team', p_reason, '{}');
  end if;
  perform private.staff_audit('case_' || p_outcome, 'case', p_case::text, p_reason);
end;
$$;

create function public.staff_warn(p_user uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes account_moderation and the audit log.
begin
  perform private.staff_require('moderator');
  insert into public.account_moderation as m (user_id, warnings) values (p_user, 1)
  on conflict (user_id) do update set warnings = m.warnings + 1;
  perform public.notify(p_user, 'A warning from OlympusGO', 'Please read the community rules.', '!', '/settings/help/rules');
  perform private.staff_audit('warn', 'user', p_user::text, p_reason);
end;
$$;

create function public.staff_suspend(p_user uuid, p_days int, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes account_moderation and the audit log.
begin
  perform private.staff_require('moderator');
  if p_days not between 1 and 365 then raise exception 'Choose 1 to 365 days.'; end if;
  insert into public.account_moderation as m (user_id, suspended_until)
  values (p_user, now() + make_interval(days => p_days))
  on conflict (user_id) do update set suspended_until = excluded.suspended_until;
  perform private.staff_audit('suspend', 'user', p_user::text, p_reason, jsonb_build_object('days', p_days));
end;
$$;

create function public.staff_ban_request(p_user uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes ban_requests and the audit log.
begin
  perform private.staff_require('moderator');
  insert into public.ban_requests (user_id, requested_by, reason) values (p_user, auth.uid(), p_reason);
  perform private.staff_audit('ban_request', 'user', p_user::text, p_reason);
exception when unique_violation then
  raise exception 'A ban is already waiting for a second person.';
end;
$$;

create function public.staff_ban_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: ban_requests has no client access.
begin
  perform private.staff_require('moderator');
  return (select coalesce(jsonb_agg(jsonb_build_object('id', b.id, 'user_id', b.user_id,
      'reason', b.reason, 'created_at', b.created_at,
      'mine', b.requested_by = auth.uid()) order by b.created_at), '[]'::jsonb)
    from public.ban_requests b where b.decided_at is null);
end;
$$;

-- R-MOD-4: the person who asked cannot be the person who approves.
create function public.staff_ban_decide(p_request uuid, p_approve boolean, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: applies the ban and writes the audit log.
declare
  b public.ban_requests;
begin
  perform private.staff_require('moderator');
  select * into b from public.ban_requests where id = p_request and decided_at is null for update;
  if b.id is null then raise exception 'This request is closed.'; end if;
  if b.requested_by = auth.uid() then
    raise exception 'A second staff member has to decide this.';
  end if;
  update public.ban_requests set approved_by = auth.uid(), decided_at = now() where id = p_request;
  if p_approve then
    insert into public.account_moderation as m (user_id, banned_at) values (b.user_id, now())
    on conflict (user_id) do update set banned_at = now();
  end if;
  perform private.staff_audit(case when p_approve then 'ban' else 'ban_refused' end,
    'user', b.user_id::text, p_reason);
end;
$$;

revoke execute on function public.staff_case_list() from public, anon;
revoke execute on function public.staff_case_get(uuid) from public, anon;
revoke execute on function public.staff_case_decide(uuid, text, text) from public, anon;
revoke execute on function public.staff_warn(uuid, text) from public, anon;
revoke execute on function public.staff_suspend(uuid, int, text) from public, anon;
revoke execute on function public.staff_ban_request(uuid, text) from public, anon;
revoke execute on function public.staff_ban_list() from public, anon;
revoke execute on function public.staff_ban_decide(uuid, boolean, text) from public, anon;
grant execute on function public.staff_case_list() to authenticated;
grant execute on function public.staff_case_get(uuid) to authenticated;
grant execute on function public.staff_case_decide(uuid, text, text) to authenticated;
grant execute on function public.staff_warn(uuid, text) to authenticated;
grant execute on function public.staff_suspend(uuid, int, text) to authenticated;
grant execute on function public.staff_ban_request(uuid, text) to authenticated;
grant execute on function public.staff_ban_list() to authenticated;
grant execute on function public.staff_ban_decide(uuid, boolean, text) to authenticated;
