begin;
\ir helpers/setup.psql
select plan(12);

select t.player('c0000000-0000-0000-0000-000000000001');  -- super
select t.player('c0000000-0000-0000-0000-000000000002');  -- moderator
select t.player('c0000000-0000-0000-0000-000000000003');  -- player
insert into public.staff (user_id, role) values
  ('c0000000-0000-0000-0000-000000000001', 'super'),
  ('c0000000-0000-0000-0000-000000000002', 'moderator');

select t.as_staff('c0000000-0000-0000-0000-000000000001', false);
select is(private.is_staff(), false, 'A-01 staff without MFA are not staff');
select throws_ok($$select public.staff_audit_list()$$, 'P0001', 'Not found.', 'A-01 staff without MFA get no data');
select is((public.staff_whoami() ->> 'mfa')::boolean, false, 'the app can see MFA is missing');
select t.reset();

select t.as_staff('c0000000-0000-0000-0000-000000000001');
select is(private.is_staff('payments'), true, 'a super passes every role');
select lives_ok($$select public.staff_audit_list()$$, 'a super reads the audit log');
select t.reset();

select t.as_staff('c0000000-0000-0000-0000-000000000002');
select is(private.is_staff('payments'), false, 'a moderator is not payments staff');
select throws_ok($$select public.staff_audit_list()$$, 'P0001', 'Not found.', 'role separation is in the database');
select throws_ok($$select * from public.staff$$, '42501', null, 'staff cannot read the staff table directly');
select t.reset();

select t.as_user('c0000000-0000-0000-0000-000000000003');
select throws_ok($$select * from public.admin_audit$$, '42501', null, 'players cannot read the audit log');
select is(public.staff_whoami() -> 'roles', '[]'::jsonb, 'a player has no roles');
select t.reset();

insert into public.admin_audit (actor, action, target_kind, target_id, reason)
  values ('c0000000-0000-0000-0000-000000000001', 'test', 'user', 'x', 'testing');
select throws_ok($$delete from public.admin_audit$$, 'P0001', 'admin_audit is append-only', 'the audit log cannot be deleted');
select throws_ok($$update public.admin_audit set reason = 'other'$$, 'P0001', 'admin_audit is append-only', 'the audit log cannot be edited');

select * from finish();
rollback;
