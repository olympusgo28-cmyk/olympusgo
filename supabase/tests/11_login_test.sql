-- Q41: Supabase Auth holds no real contact details, and codes stay server-side.
begin;
\ir helpers/setup.psql
select plan(10);

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

select public.login_code_issue('target2', 'late', 'login');
update public.login_codes set expires_at = now() - interval '1 second' where target_hash = 'target2';
select is(public.login_code_check('target2', 'late'), null, 'R-ACC-2 an expired code is refused');

select is(public.login_contact_set('b0000000-0000-0000-0000-000000000001', 'email', 'Mei@Example.com'), true, 'a contact is saved in lower case');

select t.as_user('b0000000-0000-0000-0000-000000000001');
select throws_ok($$select * from public.login_codes$$, '42501', null, 'players cannot read codes');
select throws_ok($$select public.login_code_check('target', 'x')$$, '42501', null, 'players cannot check codes');
select t.reset();

select * from finish();
rollback;
