-- Q41: Supabase Auth holds no real contact details, and codes stay server-side.
begin;
\ir helpers/setup.psql
select plan(13);

select t.player('b0000000-0000-0000-0000-000000000001');

select is_empty($$select 1 from auth.users where phone is not null$$, 'Supabase Auth holds no mobile numbers');
select is_empty($$select 1 from auth.users where email not like '%@users.olympusgo.invalid' and email not like '%@test.local'$$, 'Supabase Auth holds no real email addresses');

select is_empty($$select 1 from auth.users where email like '%' || id::text || '%@users.olympusgo.invalid'$$,
  'an internal address cannot be worked out from a user id');

select public.login_code_issue('target', 'first', 'login');
select public.login_code_issue('target', 'second', 'login');
select is(public.login_code_check('target', 'first'), null, 'R-ACC-2 a new code cancels the old one');
select is(public.login_code_check('target', 'second'), 'login', 'the newest code works');
select is(public.login_code_check('target', 'second'), null, 'R-ACC-2 a code works once');

select is(private.setting_int('auth.code_minutes'), 3, 'Q248 codes last 3 minutes');
select public.login_code_issue('target3', 'fresh', 'login');
select is((select expires_at from public.login_codes where target_hash = 'target3'), now() + interval '3 minutes',
  'R-ACC-2 a new code expires 3 minutes after it is sent');

select public.login_code_issue('target2', 'late', 'login');
update public.login_codes set expires_at = now() - interval '1 second' where target_hash = 'target2';
select is(public.login_code_check('target2', 'late'), null, 'R-ACC-2 an expired code is refused');

-- Q268: a contact only changes for a session that has just proved itself.
select public.login_step_up_grant('b0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-0000000000a1', 'mobile');
select is(public.login_contact_change('b0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-0000000000a1', 'email', 'Mei@Example.com') ->> 'status',
  'ok', 'a contact is saved for a session with a live proof');
select is((select email from public.account_private where id = 'b0000000-0000-0000-0000-000000000001'),
  'mei@example.com', 'in lower case');

select t.as_user('b0000000-0000-0000-0000-000000000001');
select throws_ok($$select * from public.login_codes$$, '42501', null, 'players cannot read codes');
select throws_ok($$select public.login_code_check('target', 'x')$$, '42501', null, 'players cannot check codes');
select t.reset();

select * from finish();
rollback;
