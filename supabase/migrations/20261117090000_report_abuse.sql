-- Audit of 10 Nov 2026, finding S3 (Q269): three accounts could hide any
-- content. The checklist rule (P2-07) is "Three distinct reporters auto-hide
-- an item", but a report was checked only for being filed as yourself. So:
--   1. a player could report what they cannot see (DM ids are sequential);
--   2. there was no limit, and one bulk insert filed any number of reports;
--   3. three accounts made a minute ago counted;
--   4. after staff kept an item, the same three could hide it again.
-- The independent review of the first version (14 Nov) found more, also fixed
-- here: a report's time and review fields were the client's to set, so the
-- limit could be dodged by backdating; an id in capitals made a fresh case,
-- undoing a keep; a repeat report after a keep never reached staff; and
-- unverified accounts, empty chats and people the owner blocked counted.
-- The rule stays. Reports must be of something the reporter can see, are
-- limited per hour, count towards the hide only from established accounts,
-- and a reporter counts once per staff decision.

-- ─── 1. Settings ───────────────────────────────────────────────────────────

insert into public.app_settings (key, value, description) values
  ('moderation.reports_per_hour', '10',
   'Reports one account may file in an hour, over every kind (S3, Q269)'),
  ('moderation.reporter_min_days', '7',
   'Days an account must be old before its reports count towards the automatic hide; 0 counts every account (S3, Q269)')
on conflict (key) do nothing;

create index if not exists content_reports_reporter_idx on public.content_reports (reporter_id, created_at);
create index if not exists player_reports_reporter_idx on public.player_reports (reporter_id, created_at);

-- One spelling of each id, so a case can't be split by retyping it (an
-- upper-case uuid, a zero-padded message number). Null when it doesn't parse.
create function private.report_target_id(p_kind text, p_id text) returns text
language sql immutable set search_path = '' as $$
  select case
    when p_kind in ('message', 'activity', 'club', 'team', 'video', 'listing')
      and p_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      then p_id::uuid::text
    when p_kind = 'dm' and p_id ~ '^[0-9]{1,18}$' then p_id::bigint::text
  end;
$$;
revoke execute on function private.report_target_id(text, text) from public, anon, authenticated;

-- Whether this report counts towards the automatic hide. Every report still
-- reaches staff.
alter table public.case_reports add column counts boolean not null default true;

-- ─── 2. What a player can see, per kind ────────────────────────────────────

-- Whether the signed-in player can see the thing they are reporting, using
-- the same rules the app reads it by. Unknown kinds, bad ids and anything
-- missing are all simply false.
create function private.report_target_visible(p_kind text, p_id text) returns boolean
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads clubs, teams, products and posts, which have no client
-- read policies, for the caller only (every helper here uses auth.uid()).
declare
  v_me uuid := (select auth.uid());
  v_uuid uuid := case when p_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then p_id::uuid end;
  v_num bigint := case when p_id ~ '^[0-9]{1,18}$' then p_id::bigint end;
begin
  if v_me is null or p_id is null then
    return false;
  end if;
  return case p_kind
    when 'message' then exists (select 1 from public.group_messages g
      where g.id = v_uuid and not g.removed
        and ((g.club_id is not null and public.club_is_member(g.club_id))
          or (g.team_id is not null and (public.team_is_member(g.team_id) or public.team_is_staff(g.team_id)))))
    when 'dm' then exists (select 1 from public.messages m
      where m.id = v_num and m.hidden_at is null
        and public.is_conversation_member(m.conversation_id))
    when 'activity' then exists (select 1 from public.activities a
      where a.id = v_uuid and a.status = 'published' and a.hidden_at is null
        and (a.kind <> 'meet' or a.club_id is null or a.public_listing
          or public.club_is_member(a.club_id) or private.on_activity(a.id)))
    when 'club' then v_uuid is not null and public.club_visible(v_uuid)
    when 'team' then exists (select 1 from public.teams t
      where t.id = v_uuid and t.hidden_at is null
        and (t.owner_id = v_me or public.team_is_member(t.id) or public.team_is_staff(t.id)))
    when 'video' then exists (select 1 from public.video_posts p
      where p.id = v_uuid and private.post_visible(p, v_me))
    when 'listing' then not private.is_restricted(v_me) and exists (select 1 from public.products p
      where p.id = v_uuid and p.published and p.hidden_at is null)
    else false
  end;
end;
$$;
revoke execute on function private.report_target_visible(text, text) from public, anon, authenticated;

-- Whether a report from [p_reporter] counts towards the automatic hide: the
-- account is old enough and not restricted, and whoever owns the thing hasn't
-- blocked the reporter. For a player, the reporter must also see their profile
-- or have had a message from them. A report that doesn't count still reaches
-- staff.
create function private.report_counts(p_reporter uuid, p_kind text, p_id text) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads auth.users and the block and chat graph.
  select p_reporter is not null
    and not private.is_restricted(p_reporter)
    and exists (select 1 from auth.users u where u.id = p_reporter
      and u.created_at <= now() - make_interval(days => private.setting_int('moderation.reporter_min_days')))
    and not exists (select 1 from public.blocks b where b.blocked_id = p_reporter
      and b.blocker_id = case when p_kind = 'player' then p_id::uuid else private.case_owner(p_kind, p_id) end)
    and case when p_kind = 'player' then
      private.can_view_profile(p_id::uuid, p_reporter)
      -- An empty chat anyone can open doesn't count; a message from them does.
      or exists (select 1 from public.messages m
        join public.conversation_members a on a.conversation_id = m.conversation_id
        where a.user_id = p_reporter and m.sender_id = p_id::uuid)
    else true end;
$$;
revoke execute on function private.report_counts(uuid, text, text) from public, anon, authenticated;

-- Who owns a reported thing, for blocks and removal notices. Adds teams,
-- which had no owner here.
create or replace function private.case_owner(p_kind text, p_id text) returns uuid
language sql stable security definer set search_path = '' as $$
  -- Definer: reads who posted something the caller cannot see.
  select case p_kind
    when 'player' then p_id::uuid
    when 'dm' then (select sender_id from public.messages where id::text = p_id)
    when 'message' then (select sender_id from public.group_messages where id::text = p_id)
    when 'activity' then (select host_id from public.activities where id::text = p_id)
    when 'club' then (select owner_id from public.clubs where id::text = p_id)
    when 'team' then (select owner_id from public.teams where id::text = p_id)
    when 'video' then (select author_id from public.video_posts where id::text = p_id and status <> 'blocked')
  end;
$$;

-- ─── 3. Every report a player files is checked ─────────────────────────────

create function private.report_check() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: counts the reporter's reports over both tables.
declare
  v_me uuid := (select auth.uid());
  v_recent int;
  v_id text;
begin
  -- The time and the review fields are the server's, whoever inserts: a
  -- backdated report would slip past the hourly count.
  new.created_at := now();
  new.status := 'in_review';
  new.result := null;
  new.decided_at := null;
  new.second_look := false;
  if tg_table_name = 'content_reports' then
    v_id := private.report_target_id(new.target_kind, new.target_id);
    if v_id is null then
      raise exception 'This can''t be reported.' using errcode = 'P0001';
    end if;
    new.target_id := v_id;
  end if;

  -- Server jobs and tests file reports with no session. A player's report,
  -- directly or through a function like shop_report, always has one.
  if v_me is null then
    return new;
  end if;
  if new.reporter_id is distinct from v_me then
    raise exception 'This can''t be reported.' using errcode = 'P0001';
  end if;

  -- One at a time per reporter, so parallel requests can't slip past the count.
  perform pg_advisory_xact_lock(hashtext('report:' || v_me::text));
  select (select count(*) from public.content_reports c
            where c.reporter_id = v_me and c.created_at > now() - interval '1 hour')
       + (select count(*) from public.player_reports p
            where p.reporter_id = v_me and p.created_at > now() - interval '1 hour')
    into v_recent;
  if v_recent >= private.setting_int('moderation.reports_per_hour') then
    raise exception 'You''ve sent a lot of reports. Try again in an hour.' using errcode = 'P0001';
  end if;

  -- The same answer whether it is missing or hidden from them, so a guessed
  -- id tells them nothing.
  if tg_table_name = 'content_reports' then
    -- Nested: player_reports rows have no target_kind to read.
    if not private.report_target_visible(new.target_kind, new.target_id) then
      raise exception 'This can''t be reported.' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;
revoke execute on function private.report_check() from public, anon, authenticated;

create trigger content_reports_check before insert on public.content_reports
  for each row execute function private.report_check();
create trigger player_reports_check before insert on public.player_reports
  for each row execute function private.report_check();

-- ─── 4. The automatic hide counts the right reports ────────────────────────

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
  v_fresh timestamptz;
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

  -- A reporter counts once per staff decision: their first report's time
  -- stays, so reporting again after staff kept the item doesn't count again
  -- (S3). Staff see the latest reason and note.
  insert into public.case_reports (case_id, reporter_id, reason, note, counts)
  values (v_case.id, new.reporter_id, new.reason, new.note,
    private.report_counts(new.reporter_id, v_kind, v_id))
  on conflict (case_id, reporter_id) do update
    set counts = public.case_reports.counts or excluded.counts,
        reason = excluded.reason, note = excluded.note;

  select count(*) into v_reporters from public.case_reports r
  where r.case_id = v_case.id and r.counts
    and r.created_at > coalesce(v_case.decided_at, '-infinity');

  -- A case coming back after a decision gets a new deadline from now, so a
  -- re-report can't push an old, overdue case above fresh ones.
  v_fresh := now() + make_interval(hours => private.setting_int(case when v_case.involves_child
    then 'moderation.child_deadline_hours' else 'moderation.deadline_hours' end));

  if v_reporters >= private.setting_int('moderation.auto_hide_reports')
    and v_case.status <> 'removed' and v_case.hidden_at is null then
    update public.moderation_cases set hidden_at = now(), status = 'open',
      deadline_at = case when v_case.status = 'open' then deadline_at else v_fresh end
    where id = v_case.id;
    perform private.case_set_hidden(v_kind, v_id, true);
  elsif v_case.status = 'kept' then
    -- Reported again since staff kept it, by anyone: back in the queue for a
    -- person to look at, but left visible.
    update public.moderation_cases set status = 'open', deadline_at = v_fresh where id = v_case.id;
  end if;
  return new;
end;
$$;

-- ─── 5. Shop reports give the same answer as every other report ────────────

-- Its own "no longer listed" check told a caller a draft id existed. The
-- trigger above now gives the one answer.
create or replace function public.shop_report(p_product uuid, p_reason text, p_note text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.content_reports (reporter_id, target_kind, target_id, reason, note)
  values ((select auth.uid()), 'listing', p_product::text, left(p_reason, 40),
          left(coalesce(p_note, ''), 1000));
end;
$$;
