begin;
\ir helpers/setup.psql
select plan(23);

select t.player('30000000-0000-0000-0000-000000000001', 12);  -- child
select t.player('30000000-0000-0000-0000-000000000002', 40);  -- parent
select t.player('30000000-0000-0000-0000-000000000003', 16);  -- too young to be a parent
select t.player('30000000-0000-0000-0000-000000000004', 40);  -- stranger

select t.as_user('30000000-0000-0000-0000-000000000001');
create temp table code on commit drop as select public.guardian_code_create() as v;
grant select on code to authenticated;
select matches((select v ->> 'code' from code), '^[A-HJ-NP-Z2-9]{8}$', 'P1-08 the code is 8 clear characters');
select cmp_ok(((select v ->> 'expires_at' from code)::timestamptz - now()), '<=', interval '24 hours', 'P1-08 the code lasts 24 hours');
select t.reset();

select is((select count(*)::int from public.guardian_link_codes c, code
  where c.code_hash = (code.v ->> 'code')), 0, 'the plain code is not stored');

select t.as_user('30000000-0000-0000-0000-000000000003');
select throws_ok(
  format('select public.guardian_code_redeem(%L)', (select v ->> 'code' from code)),
  'P0001', 'A parent or guardian must be 18 or over.', 'P1-08 a parent under 18 is refused');
select t.reset();

-- A child with a second, email-only account and an adult birthday.
select t.player('30000000-0000-0000-0000-000000000006', 30);
update auth.users set phone = null, phone_confirmed_at = null where id = '30000000-0000-0000-0000-000000000006';
select ok(private.is_restricted('30000000-0000-0000-0000-000000000006'), 'R-ACC-5 an account with no verified mobile is restricted');
select t.as_user('30000000-0000-0000-0000-000000000006');
select throws_ok(
  format('select public.guardian_code_redeem(%L)', (select v ->> 'code' from code)),
  'P0001', 'A parent or guardian needs a verified mobile number.', 'an email-only adult cannot be a parent');
select t.reset();

select t.as_user('30000000-0000-0000-0000-000000000002');
create temp table link on commit drop as
  select public.guardian_code_redeem((select v ->> 'code' from code)) as v;
grant select on link to authenticated;
select ok((select v ? 'link_id' from link), 'the parent enters the code');
select ok(private.is_restricted('30000000-0000-0000-0000-000000000001'), 'the child stays restricted until approved');
select is(public.guardian_code_redeem((select v ->> 'code' from code)) ->> 'error',
  'That code didn''t work. Check it and try again.', 'a code works once');
select t.reset();

select t.as_user('30000000-0000-0000-0000-000000000004');
select throws_ok(
  format('select public.guardian_link_decide(%L, true)', (select v ->> 'link_id' from link)),
  'P0001', 'This request is no longer waiting for you.', 'a stranger cannot approve');
select t.reset();

select t.as_user('30000000-0000-0000-0000-000000000002');
select lives_ok(
  format('select public.guardian_link_decide(%L, true)', (select v ->> 'link_id' from link)),
  'the parent approves');
select ok(not private.is_restricted('30000000-0000-0000-0000-000000000001'), 'approval lifts restricted mode');
select ok(private.is_guardian_of('30000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001'), 'the parent is linked');
select t.reset();

-- The parent sees and deletes what the child posted.
insert into public.clubs (id, owner_id, name, area, sports)
  values ('30000000-0000-0000-0000-0000000000c1', '30000000-0000-0000-0000-000000000002', 'Test club', 'Bishan', '["badminton"]');
insert into public.club_ratings (club_id, user_id, stars, review)
  values ('30000000-0000-0000-0000-0000000000c1', '30000000-0000-0000-0000-000000000001', 5, 'Great');

select t.as_user('30000000-0000-0000-0000-000000000004');
select throws_ok(
  $$select public.guardian_child_posts('30000000-0000-0000-0000-000000000001')$$,
  'P0001', 'Only a linked parent can see this.', 'a stranger cannot see a child''s posts');
select t.reset();

select t.as_user('30000000-0000-0000-0000-000000000002');
select is(jsonb_array_length(public.guardian_child_posts('30000000-0000-0000-0000-000000000001')), 1, 'the parent sees the post');
select lives_ok(
  $$select public.guardian_delete_post('30000000-0000-0000-0000-000000000001', 'club_review', '30000000-0000-0000-0000-0000000000c1')$$,
  'the parent deletes the post');
select is(jsonb_array_length(public.guardian_child_posts('30000000-0000-0000-0000-000000000001')), 0, 'the post is gone');

select lives_ok(
  format('select public.guardian_link_revoke(%L)', (select v ->> 'link_id' from link)),
  'the parent revokes');
select ok(private.is_restricted('30000000-0000-0000-0000-000000000001'), 'revoking restores restricted mode');
select t.reset();

-- 5 wrong codes lock the target for 15 minutes.
select t.as_user('30000000-0000-0000-0000-000000000004');
select public.guardian_code_redeem('AAAAAAAA') from generate_series(1, 5);
select is(public.guardian_code_redeem('AAAAAAAA') ->> 'error',
  'Too many tries. Wait a while, then try again.', 'R-ACC-3 five wrong codes lock the target');
select t.reset();

-- An expired code does nothing.
select t.as_user('30000000-0000-0000-0000-000000000001');
create temp table code2 on commit drop as select public.guardian_code_create() as v;
grant select on code2 to authenticated;
select t.reset();
update public.guardian_link_codes set expires_at = now() - interval '1 minute';
select t.as_user('30000000-0000-0000-0000-000000000002');
select is(public.guardian_code_redeem((select v ->> 'code' from code2)) ->> 'error',
  'That code didn''t work. Check it and try again.', 'P1-08 an expired code is refused');
select t.reset();

-- A link ends at 18, with a notice 30 days before.
select t.as_user('30000000-0000-0000-0000-000000000001');
create temp table code3 on commit drop as select public.guardian_code_create() as v;
grant select on code3 to authenticated;
select t.reset();
select t.as_user('30000000-0000-0000-0000-000000000002');
select public.guardian_link_decide(((public.guardian_code_redeem((select v ->> 'code' from code3))) ->> 'link_id')::uuid, true);
select t.reset();
alter table public.account_private disable trigger account_private_lock_birthday;
update public.account_private set birthday = (now() at time zone 'Asia/Singapore')::date - interval '18 years' + interval '20 days'
  where id = '30000000-0000-0000-0000-000000000001';
select private.guardian_links_daily();
select private.guardian_links_daily();
select is((select count(*)::int from public.notifications
  where user_id = '30000000-0000-0000-0000-000000000001' and title = 'Your parent link is ending soon'),
  1, 'R-AGE-4 the notice goes once, 30 days before');
update public.account_private set birthday = (now() at time zone 'Asia/Singapore')::date - interval '19 years'
  where id = '30000000-0000-0000-0000-000000000001';
select private.guardian_links_daily();
select is((select count(*)::int from public.guardian_links
  where child_id = '30000000-0000-0000-0000-000000000001' and status = 'ended'), 1, 'R-AGE-4 the link ends at 18');

select * from finish();
rollback;
