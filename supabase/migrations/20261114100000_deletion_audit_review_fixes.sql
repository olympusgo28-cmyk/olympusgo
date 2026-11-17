-- Review of 20261114090000 (Q264). The audit purge took other players'
-- attendance with a roster row, removed points and refund decisions, missed
-- a coach's licence rows, let any session that set og.audit_purge delete,
-- and a purged account could open a fresh deletion request.

-- ─── 1. Only the job's own role may use the allowance ──────────────────────

-- A session as service_role (which bypasses RLS) could set og.audit_purge
-- itself. The guard now also needs the role that owns the job, which is the
-- role the job runs as.
create or replace function private.forbid_audit_change() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_setting('og.audit_purge', true) = 'on'
      and current_user = (select r.rolname from pg_catalog.pg_proc p
        join pg_catalog.pg_roles r on r.oid = p.proowner
        where p.oid = 'private.account_audit_purge_due()'::pg_catalog.regprocedure)
      and (tg_op = 'DELETE' or (tg_op = 'UPDATE' and tg_table_name = 'attendance_audit')) then
    return case when tg_op = 'DELETE' then old else new end;
  end if;
  raise exception '% is append-only', tg_table_name;
end;
$$;

-- Clients only ever read these; RLS already had no write policy.
revoke update, delete, truncate on public.admin_audit, public.attendance_audit,
  public.catalog_audit from anon, authenticated;

-- ─── 2. The job ────────────────────────────────────────────────────────────

create or replace function private.account_audit_purge_due() returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: the retention job, from pg_cron. Deletes from append-only audit
-- tables, which no client may do.
declare
  v_cutoff timestamptz :=
    now() - make_interval(years => private.setting_int('account.audit_keep_years'));
  -- Staff decisions that moved money or points stay with the money records
  -- (Q14), whoever made them and whoever they were about.
  v_money_actions constant text[] := array['alert_closed', 'hold_decided', 'lesson_decided',
    'order_decided', 'payout_approved', 'payout_first_approval', 'refund', 'refund_manual',
    'refund_retry', 'refund_settle', 'refund_void', 'suspense_clear', 'points_blocked',
    'points_unblocked', 'shop_commission'];
  v_money_kinds constant text[] := array['refund', 'payout', 'payment', 'order',
    'stripe_intent', 'money_alert', 'lesson'];
  v_users uuid[];
  v_ids text[];
  v_empty bigint[];
begin
  select array_agg(d.user_id order by d.erased_at) into v_users
  from (
    select x.user_id, x.erased_at from public.account_deletions x
    where x.erased_at is not null and x.cancelled_at is null and x.erased_at < v_cutoff
    order by x.erased_at
    limit 200
  ) d;
  if v_users is null then return 0; end if;
  v_ids := array(select u::text from unnest(v_users) u);

  perform set_config('og.audit_purge', 'on', true);

  -- What they did as staff, and what staff did to their account or their
  -- coaching licence.
  delete from public.admin_audit a
  where (a.actor = any (v_users)
      or (a.target_kind in ('user', 'licence') and a.target_id = any (v_ids)))
    and not (a.action = any (v_money_actions) or a.target_kind = any (v_money_kinds));

  -- Attendance they changed goes. A roster change by someone else keeps every
  -- other player's line: only theirs is taken out, and the row goes once
  -- nothing is left in it.
  delete from public.attendance_audit a where a.actor = any (v_users);
  with s as (
    update public.attendance_audit a
    set before = a.before - v_ids, after = a.after - v_ids
    where a.before ?| v_ids or a.after ?| v_ids
    returning a.id, a.before, a.after
  )
  select coalesce(array_agg(s.id) filter (where s.before = '{}'::jsonb and s.after = '{}'::jsonb),
    '{}') into v_empty from s;
  delete from public.attendance_audit a where a.id = any (v_empty);

  delete from public.club_audit a where a.actor_id = any (v_users);
  delete from public.catalog_audit a where a.actor = any (v_users);
  delete from public.account_deletions d where d.user_id = any (v_users);

  perform set_config('og.audit_purge', '', true);
  return cardinality(v_users);
end;
$$;
revoke execute on function private.account_audit_purge_due() from public;

-- ─── 3. An erased account can't ask again ──────────────────────────────────

-- account_delete_request refuses on the deletion row's erased_at, and that row
-- goes after 10 years. profiles.erased_at stays, so the table checks it.
create function private.deletion_not_erased() returns trigger
language plpgsql set search_path = '' as $$
begin
  if private.is_erased(new.user_id) then
    raise exception 'This account was deleted.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
revoke execute on function private.deletion_not_erased() from public;
create trigger account_deletions_not_erased before insert on public.account_deletions
  for each row execute function private.deletion_not_erased();
