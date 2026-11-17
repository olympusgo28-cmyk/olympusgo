-- R-ACC-11 (owner, 9 Nov 2026): once an account is erased, the audit of what
-- it did and what was done to it is kept account.audit_keep_years (10), then
-- removed. A cancelled deletion request is kept forever. Money records,
-- results, reports, cases and consents are not touched here (Q14, Q264).

-- ─── 1. Setting ────────────────────────────────────────────────────────────

insert into public.app_settings (key, value, description) values
  ('account.audit_keep_years', '10', 'Years an erased account''s audit is kept, then removed (R-ACC-11)')
on conflict (key) do nothing;

-- ─── 2. The audit guard lets only the retention job delete ─────────────────

-- private.forbid_change also guards the money ledger, points and results, so
-- it stays as it is. The three audit tables get their own guard: a delete is
-- allowed only while og.audit_purge is on, which only
-- private.account_audit_purge_due sets, for its own transaction. Updates
-- and truncates are never allowed. 20261114100000 tightens this to the job's
-- own role and revokes the clients' write grants.
create function private.forbid_audit_change() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' and current_setting('og.audit_purge', true) = 'on' then
    return old;
  end if;
  raise exception '% is append-only', tg_table_name;
end;
$$;
revoke execute on function private.forbid_audit_change() from public;

drop trigger admin_audit_append_only on public.admin_audit;
create trigger admin_audit_append_only before update or delete on public.admin_audit
  for each row execute function private.forbid_audit_change();
drop trigger attendance_audit_append_only on public.attendance_audit;
create trigger attendance_audit_append_only before update or delete on public.attendance_audit
  for each row execute function private.forbid_audit_change();
drop trigger catalog_audit_append_only on public.catalog_audit;
create trigger catalog_audit_append_only before update or delete on public.catalog_audit
  for each row execute function private.forbid_audit_change();

-- The job finds an account's rows by who acted.
create index admin_audit_actor_idx on public.admin_audit (actor);
create index attendance_audit_actor_idx on public.attendance_audit (actor);
create index club_audit_actor_idx on public.club_audit (actor_id);
create index catalog_audit_actor_idx on public.catalog_audit (actor);

-- ─── 3. The job ────────────────────────────────────────────────────────────

create function private.account_audit_purge_due() returns int
language plpgsql security definer set search_path = '' as $$
-- Definer: the retention job, from pg_cron. Deletes from append-only audit
-- tables, which no client may do.
declare
  v_cutoff timestamptz :=
    now() - make_interval(years => private.setting_int('account.audit_keep_years'));
  v_users uuid[];
  v_ids text[];
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

  -- What they did as staff, and what staff did to their account. Rows about
  -- money movements stay with the money records (Q14).
  delete from public.admin_audit a
  where (a.actor = any (v_users) or (a.target_kind = 'user' and a.target_id = any (v_ids)))
    and a.target_kind not in
      ('refund', 'payout', 'payment', 'order', 'stripe_intent', 'money_alert', 'lesson');
  -- Attendance they changed, and changes to their own attendance (keyed by
  -- player id in before and after).
  delete from public.attendance_audit a
  where a.actor = any (v_users) or a.before ?| v_ids or a.after ?| v_ids;
  delete from public.club_audit a where a.actor_id = any (v_users);
  delete from public.catalog_audit a where a.actor = any (v_users);
  delete from public.account_deletions d where d.user_id = any (v_users);

  perform set_config('og.audit_purge', '', true);
  return cardinality(v_users);
end;
$$;
revoke execute on function private.account_audit_purge_due() from public;

-- 02:30 Singapore, after retention-delete.
select cron.schedule('retention-audit', '30 18 * * *', $$select private.account_audit_purge_due()$$);
