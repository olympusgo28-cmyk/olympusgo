-- R-ACC-11, Q264 (owner, 9 Nov 2026): an erased account's audit stays
-- account.audit_keep_years (10), then goes. A cancelled request stays for
-- ever. Money and points decisions, other players' lines in a roster change,
-- and other people's own audit are untouched.
begin;
\ir helpers/setup.psql
select no_plan();

select t.player('e5000000-0000-0000-0000-000000000001');  -- erased 10 years and a day ago
select t.player('e5000000-0000-0000-0000-000000000002');  -- erased a day short of 10 years, due long before
select t.player('e5000000-0000-0000-0000-000000000003');  -- cancelled 11 years ago
select t.player('e5000000-0000-0000-0000-000000000004');  -- bystander, also the staff member and host
select t.player('e5000000-0000-0000-0000-000000000005');  -- erased 6 years ago
select t.player('e5000000-0000-0000-0000-000000000006');  -- cancelled and erased (never happens; proves the filter)

insert into public.clubs (id, owner_id, name, area, sports) values
  ('e5000000-0000-0000-0000-0000000000c1', 'e5000000-0000-0000-0000-000000000004',
   'Audit club', 'Bishan', '["badminton"]');

insert into public.account_deletions (user_id, requested_at, erase_after, erased_at, cancelled_at) values
  ('e5000000-0000-0000-0000-000000000001', now() - interval '10 years 31 days',
   now() - interval '10 years 1 day', now() - interval '10 years 1 day', null),
  -- Its erase waited on money for three weeks, so erase_after is older than
  -- 10 years while erased_at is not: the clock runs from the erase.
  ('e5000000-0000-0000-0000-000000000002', now() - interval '10 years 50 days',
   now() - interval '10 years 20 days', now() - interval '10 years' + interval '1 day', null),
  ('e5000000-0000-0000-0000-000000000003', now() - interval '11 years',
   now() - interval '11 years' + interval '30 days', null, now() - interval '11 years' + interval '1 day'),
  ('e5000000-0000-0000-0000-000000000005', now() - interval '6 years 30 days',
   now() - interval '6 years', now() - interval '6 years', null),
  ('e5000000-0000-0000-0000-000000000006', now() - interval '12 years',
   now() - interval '11 years', now() - interval '11 years', now() - interval '11 years 10 days');
update public.profiles p set erased_at = d.erased_at, full_name = 'Former player'
from public.account_deletions d where d.user_id = p.id and d.erased_at is not null;

-- For each account: as the one who acted and as the subject in every audit
-- table (7 rows the job removes), plus three staff decisions about money and
-- points (which stay). Money rows have reason 'money'.
create function t.seed_audit(p_user uuid) returns void language plpgsql as $$
declare
  v_staff uuid := 'e5000000-0000-0000-0000-000000000004';
begin
  insert into public.admin_audit (actor, action, target_kind, target_id, reason) values
    (p_user, 'result_correct', 'score', gen_random_uuid()::text, 'acted'),
    (v_staff, 'warn', 'user', p_user::text, 'about them'),
    (v_staff, 'verification_file_viewed', 'licence', p_user::text, 'their licence'),
    (p_user, 'refund_void', 'refund', gen_random_uuid()::text, 'money'),
    (v_staff, 'points_blocked', 'user', p_user::text, 'money'),
    (p_user, 'hold_decided', 'activity', gen_random_uuid()::text, 'money');
  insert into public.attendance_audit (activity_id, actor, before, after) values
    (gen_random_uuid(), p_user, '{}'::jsonb, '{}'::jsonb),
    (gen_random_uuid(), v_staff, jsonb_build_object(p_user, 'joined'),
      jsonb_build_object(p_user, 'present'));
  insert into public.club_audit (club_id, actor_id, category, action) values
    ('e5000000-0000-0000-0000-0000000000c1', p_user, 'members', 'acted');
  insert into public.catalog_audit (table_name, row_key, action, actor) values
    ('sports', 'badminton', 'update', p_user);
end;
$$;
select t.seed_audit(u) from unnest(array[
  'e5000000-0000-0000-0000-000000000001', 'e5000000-0000-0000-0000-000000000002',
  'e5000000-0000-0000-0000-000000000003', 'e5000000-0000-0000-0000-000000000005',
  'e5000000-0000-0000-0000-000000000006']::uuid[]) u;

-- A host's roster change with the erased player and the bystander in it.
insert into public.attendance_audit (activity_id, actor, before, after) values
  ('e5000000-0000-0000-0000-0000000000a1', 'e5000000-0000-0000-0000-000000000004',
   '{"e5000000-0000-0000-0000-000000000001": "joined", "e5000000-0000-0000-0000-000000000004": "joined"}',
   '{"e5000000-0000-0000-0000-000000000001": "present", "e5000000-0000-0000-0000-000000000004": "present"}');

-- The bystander's own rows, about nobody else.
insert into public.admin_audit (actor, action, target_kind, target_id, reason) values
  ('e5000000-0000-0000-0000-000000000004', 'own', 'score', 'own-score', 'own');
insert into public.attendance_audit (activity_id, actor, before, after) values
  (gen_random_uuid(), 'e5000000-0000-0000-0000-000000000004',
   '{"e5000000-0000-0000-0000-000000000004": "joined"}', '{"e5000000-0000-0000-0000-000000000004": "present"}');
insert into public.club_audit (club_id, actor_id, category, action) values
  ('e5000000-0000-0000-0000-0000000000c1', 'e5000000-0000-0000-0000-000000000004', 'club', 'own');
insert into public.catalog_audit (table_name, row_key, action, actor) values
  ('sports', 'own', 'update', 'e5000000-0000-0000-0000-000000000004');

create function t.audit_rows(p_user uuid) returns int language sql as $$
  select (
    (select count(*) from public.admin_audit a
      where (a.actor = p_user or a.target_id = p_user::text) and a.reason <> 'money')
    + (select count(*) from public.attendance_audit a
      where a.actor = p_user or a.before ? p_user::text or a.after ? p_user::text)
    + (select count(*) from public.club_audit a where a.actor_id = p_user)
    + (select count(*) from public.catalog_audit a where a.actor = p_user))::int;
$$;
create function t.money_rows(p_user uuid) returns int language sql as $$
  select count(*)::int from public.admin_audit a
  where a.reason = 'money' and (a.actor = p_user or a.target_id = p_user::text);
$$;
-- The bystander's own rows, including their line in the roster change.
create function t.own_rows() returns int language sql as $$
  select (
    (select count(*) from public.admin_audit where action = 'own')
    + (select count(*) from public.attendance_audit
        where before ? 'e5000000-0000-0000-0000-000000000004')
    + (select count(*) from public.club_audit where action = 'own')
    + (select count(*) from public.catalog_audit where row_key = 'own'))::int;
$$;
create function t.deletion(p_user uuid) returns boolean language sql as $$
  select exists (select 1 from public.account_deletions where user_id = p_user);
$$;

select is(private.setting_int('account.audit_keep_years'), 10, 'the audit is kept 10 years');
select is(t.audit_rows('e5000000-0000-0000-0000-000000000002'), 7, 'set-up: seven audit rows each');
select is(t.money_rows('e5000000-0000-0000-0000-000000000002'), 3, 'set-up: three money rows each');
select is(t.own_rows(), 5, 'set-up: five rows of the bystander''s own');

-- ─── The job ───────────────────────────────────────────────────────────────

select is(private.account_audit_purge_due(), 1, 'only the account erased over 10 years ago is purged');
select is(t.audit_rows('e5000000-0000-0000-0000-000000000001'), 0,
  'its audit goes: what it did, what staff did to it and its licence, its attendance');
select ok(not t.deletion('e5000000-0000-0000-0000-000000000001'), 'so does its deletion record');
select is(t.money_rows('e5000000-0000-0000-0000-000000000001'), 3,
  'staff decisions on its refunds, points and held money stay (Q14)');
select ok((select erased_at is not null from public.profiles
           where id = 'e5000000-0000-0000-0000-000000000001'), 'the "Former player" tombstone stays');
select is(
  (select jsonb_build_array(before, after) from public.attendance_audit
   where activity_id = 'e5000000-0000-0000-0000-0000000000a1'),
  '[{"e5000000-0000-0000-0000-000000000004": "joined"}, {"e5000000-0000-0000-0000-000000000004": "present"}]'::jsonb,
  'a roster change keeps the other players'' lines and loses only theirs');
select is(t.audit_rows('e5000000-0000-0000-0000-000000000002'), 7,
  'a day short of 10 years from the erase, everything stays, though the erase was due earlier');
select ok(t.deletion('e5000000-0000-0000-0000-000000000002'), 'with its deletion record');
select is(t.audit_rows('e5000000-0000-0000-0000-000000000003'), 7, 'a cancelled request''s account keeps its audit');
select ok(t.deletion('e5000000-0000-0000-0000-000000000003'), 'and the cancelled request stays');
select ok(t.deletion('e5000000-0000-0000-0000-000000000006'), 'a cancelled request is never purged, whatever its dates');
select is(t.own_rows(), 5, 'the bystander''s own rows stay');
select is(current_setting('og.audit_purge', true), '', 'the job switches the allowance off again');
select is(private.account_audit_purge_due(), 0, 'a second run finds nothing');

-- A purged account can't start again.
select throws_ok($$insert into public.account_deletions (user_id, erase_after)
  values ('e5000000-0000-0000-0000-000000000001', now())$$,
  'P0001', 'This account was deleted.', 'a purged account can''t get a new deletion row');
select t.as_user('e5000000-0000-0000-0000-000000000001');
select throws_ok($$select public.account_delete_request(null)$$,
  'P0001', 'This account was deleted.', 'nor ask for one');
select t.reset();

-- The window comes from the setting.
update public.app_settings set value = '5' where key = 'account.audit_keep_years';
select is(private.account_audit_purge_due(), 2, 'with 5 years, the 6- and 10-year-old erasures go');
select is(t.audit_rows('e5000000-0000-0000-0000-000000000005'), 0, 'the 6-year-old one''s audit is gone');
select ok(t.deletion('e5000000-0000-0000-0000-000000000003'), 'a cancelled request is kept for ever');
select is(t.audit_rows('e5000000-0000-0000-0000-000000000003'), 7, 'and so is that account''s audit');
update public.app_settings set value = '10' where key = 'account.audit_keep_years';

-- ─── The guards ────────────────────────────────────────────────────────────

select throws_ok($$delete from public.admin_audit where action = 'own'$$,
  'P0001', 'admin_audit is append-only', 'outside the job, admin_audit refuses a delete');
select throws_ok($$delete from public.attendance_audit$$,
  'P0001', 'attendance_audit is append-only', 'so does attendance_audit');
select throws_ok($$delete from public.catalog_audit where row_key = 'own'$$,
  'P0001', 'catalog_audit is append-only', 'and catalog_audit');
select set_config('og.audit_purge', 'on', true);
select throws_ok($$update public.admin_audit set reason = 'changed' where action = 'own'$$,
  'P0001', 'admin_audit is append-only', 'admin_audit refuses an update even with the allowance on');
select throws_ok($$truncate public.admin_audit$$,
  'P0001', 'admin_audit is append-only', 'and a truncate');
select set_config('role', 'service_role', true);
select throws_ok($$delete from public.admin_audit where action = 'own'$$,
  'P0001', 'admin_audit is append-only', 'service_role can''t use the allowance, though it skips RLS');
select throws_ok($$update public.attendance_audit set after = '{}'$$,
  'P0001', 'attendance_audit is append-only', 'nor change attendance rows');
select t.reset();
select set_config('og.audit_purge', '', true);

select ok(not has_table_privilege('authenticated', 'public.attendance_audit', 'delete')
  and not has_table_privilege('authenticated', 'public.catalog_audit', 'delete')
  and not has_table_privilege('authenticated', 'public.admin_audit', 'delete')
  and not has_table_privilege('anon', 'public.attendance_audit', 'update'),
  'players hold no write grant on the audit tables');
select is(
  array(select tgrelid::regclass::text from pg_trigger
        where tgfoid = 'private.forbid_audit_change'::regproc order by 1),
  array['admin_audit', 'attendance_audit', 'catalog_audit'],
  'only the three audit tables use the purge-aware guard; money and results keep the strict one');
select ok(not has_function_privilege('authenticated', 'private.account_audit_purge_due()', 'execute'),
  'a player cannot run the job');
select ok(not has_function_privilege('anon', 'private.account_audit_purge_due()', 'execute'),
  'nor can anyone signed out');
select is((select schedule from cron.job where jobname = 'retention-audit'), '30 18 * * *',
  'the job runs daily at 02:30 Singapore');

select * from finish();
rollback;
