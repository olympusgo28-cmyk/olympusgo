-- Audit S3 follow-up (review of 14 Nov 2026, Q269, R-MOD-6).
--
-- A report counts towards the automatic hide only if it qualified at a filing
-- (a repeat report can't switch it off) and its reporter isn't restricted
-- when the reports are counted, so
-- staff suspending a reporter stops their report counting. A block made after
-- the report doesn't: that would let an owner silence everyone who reported
-- them, and a victim who reports and then blocks would lose their own report.
-- A case keeps the owner it had when first reported, and a moderator can't
-- decide a case about something they own now either. Reports and staff
-- decisions are timed by the clock, not the start of their transaction, so a
-- report filed while staff decide is placed on the right side of the
-- decision. Old rows are cleaned up.

-- ─── 1. The automatic hide rechecks each reporter's restriction ───────────

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

  -- The owner is the one when first reported (filled in if it was missing):
  -- handing a club to someone else mustn't move the case onto them. A video
  -- that matched known abuse material never gets one, so nothing tells the
  -- uploader.
  insert into public.moderation_cases as m
    (target_kind, target_id, owner_id, involves_child, deadline_at)
  values (v_kind, v_id, v_owner, v_child, now() + make_interval(hours =>
    private.setting_int(case when v_child then 'moderation.child_deadline_hours' else 'moderation.deadline_hours' end)))
  on conflict (target_kind, target_id) do update
    set owner_id = case when m.target_kind = 'video'
          and exists (select 1 from public.abuse_matches a where a.post_id::text = m.target_id)
          then null else coalesce(m.owner_id, excluded.owner_id) end,
        involves_child = m.involves_child or excluded.involves_child,
        deadline_at = case when excluded.involves_child and not m.involves_child
          then least(m.deadline_at, excluded.deadline_at) else m.deadline_at end
  returning * into v_case;

  -- Each reporter counts once per item: their first report's time stays, so
  -- reporting again after staff kept the item doesn't count again (S3). Staff
  -- see the latest reason and note. The clock, not the transaction start,
  -- places a report before or after a decision.
  insert into public.case_reports (case_id, reporter_id, reason, note, counts, created_at)
  values (v_case.id, new.reporter_id, new.reason, new.note,
    private.report_counts(new.reporter_id, v_kind, v_id), clock_timestamp())
  on conflict (case_id, reporter_id) do update
    set counts = public.case_reports.counts or excluded.counts,
        reason = excluded.reason, note = excluded.note;

  -- A report counts only while its reporter isn't restricted (suspended,
  -- banned, no verified mobile). Nothing to count once it's hidden or removed,
  -- and no need to count past the threshold.
  v_reporters := 0;
  if v_case.status <> 'removed' and v_case.hidden_at is null then
    select count(*) into v_reporters from (
      select 1 from public.case_reports r
      where r.case_id = v_case.id and r.counts
        and r.created_at > coalesce(v_case.decided_at, '-infinity')
        and not private.is_restricted(r.reporter_id)
      limit private.setting_int('moderation.auto_hide_reports')) x;
  end if;

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
revoke execute on function private.report_to_case() from public, anon, authenticated;

-- ─── 2. Staff decisions ────────────────────────────────────────────────────

-- Timed once the case is locked, and not by whoever owns the thing now.
do $$
declare
  n text := 'public.staff_case_decide(uuid, text, text)';
  d text := pg_get_functiondef(n::regprocedure);
  fixed text := d;
  pairs text[][] := array[
    ['decided_by = auth.uid(), decided_at = now(),',
     'decided_by = auth.uid(), decided_at = clock_timestamp(),'],
    ['if c.owner_id = auth.uid() then',
     'if auth.uid() in (c.owner_id, private.case_owner(c.target_kind, c.target_id)) then']];
  i int;
begin
  for i in 1 .. array_length(pairs, 1) loop
    if position(pairs[i][1] in fixed) = 0 then raise exception '% did not change at step %', n, i; end if;
    fixed := replace(fixed, pairs[i][1], pairs[i][2]);
  end loop;
  execute fixed;
end;
$$;

-- ─── 3. Old rows ────────────────────────────────────────────────────────────

-- One spelling of each id first, so the owner lookups below find the row. Two
-- cases for the same thing would stop this migration rather than be merged
-- without a person looking. Before applying to a shared project, check:
--   select target_kind, private.report_target_id(target_kind, target_id), count(*)
--   from public.moderation_cases group by 1, 2 having count(*) > 1;
update public.moderation_cases
set target_id = private.report_target_id(target_kind, target_id)
where private.report_target_id(target_kind, target_id) <> target_id;
update public.content_reports
set target_id = private.report_target_id(target_kind, target_id)
where private.report_target_id(target_kind, target_id) <> target_id;

-- Cases made before teams had an owner, but never an abuse match's.
update public.moderation_cases c
set owner_id = private.case_owner(c.target_kind, c.target_id)
where c.owner_id is null and private.case_owner(c.target_kind, c.target_id) is not null
  and not exists (select 1 from public.abuse_matches a where a.post_id::text = c.target_id);

-- Reports filed before 14 Nov all counted. This uses today's account ages and
-- blocks, as there is no record of them at the time. A reporter restricted
-- today is left alone: the count already leaves them out while it lasts.
update public.case_reports r
set counts = private.report_counts(r.reporter_id, c.target_kind, c.target_id)
from public.moderation_cases c
where c.id = r.case_id and not private.is_restricted(r.reporter_id);
