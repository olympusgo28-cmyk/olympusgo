begin;
\ir helpers/setup.psql
select plan(19);

select t.player('20000000-0000-0000-0000-000000000012', 12);
select t.player('20000000-0000-0000-0000-000000000013', 13);
select t.player('20000000-0000-0000-0000-000000000017', 17);
select t.player('20000000-0000-0000-0000-000000000018', 18);
select t.player('20000000-0000-0000-0000-000000000099', null);

select is(private.audience_of('20000000-0000-0000-0000-000000000012'), 'child', 'P1-03 age 12 is a child');
select is(private.audience_of('20000000-0000-0000-0000-000000000013'), 'teen', 'P1-03 age 13 is a teen');
select is(private.audience_of('20000000-0000-0000-0000-000000000017'), 'teen', 'P1-03 age 17 is a teen');
select is(private.audience_of('20000000-0000-0000-0000-000000000018'), 'adult', 'P1-03 age 18 is an adult');
select is(private.audience_of('20000000-0000-0000-0000-000000000099'), 'unknown', 'no birthday means unknown');

select ok(private.is_restricted('20000000-0000-0000-0000-000000000012'), 'an unlinked child is restricted');
select ok(private.is_restricted('20000000-0000-0000-0000-000000000017'), 'an unapproved teen is restricted');
select ok(private.is_restricted('20000000-0000-0000-0000-000000000099'), 'unknown age is restricted, never open');
select ok(not private.is_restricted('20000000-0000-0000-0000-000000000018'), 'an adult is not restricted');

-- The limits come from configuration.
update public.country_config set child_age = 14 where country_code = 'SG';
select is(private.audience_of('20000000-0000-0000-0000-000000000013'), 'child', 'R-AGE-2 limits are read from country_config');
update public.country_config set child_age = 13 where country_code = 'SG';

-- A birthday cannot be written directly any more.
select t.as_user('20000000-0000-0000-0000-000000000012');
select throws_ok(
  $$update public.account_private set birthday = '1990-01-01'$$,
  '42501', null, 'a child cannot rewrite their birthday');
select throws_ok(
  $$update public.account_private set country_code = 'MY'$$,
  '42501', null, 'a player cannot move country directly');
select throws_ok(
  $$select public.set_birthday('1990-01-01', 'SG')$$,
  'P0001', 'Your birthday can''t be changed once it is set.', 'set_birthday refuses a second date');
select t.reset();

select t.as_user('20000000-0000-0000-0000-000000000099');
select throws_ok(
  $$select public.set_birthday('2000-01-01', 'MY')$$,
  'P0001', 'OlympusGO isn''t open in that country yet.', 'closed countries are refused');
select throws_ok(
  $$select public.set_birthday('2999-01-01', 'SG')$$,
  'P0001', 'Check your birthday and try again.', 'a future birthday is refused');
select is(public.set_birthday('2000-01-01', 'SG'), 'adult', 'set_birthday returns the age group');
select is((public.my_restrictions() ->> 'restricted')::boolean, false, 'my_restrictions agrees');
select t.reset();

select t.as_user('20000000-0000-0000-0000-000000000012');
select is((public.my_restrictions() ->> 'can_scan')::boolean, false, 'an under-13 cannot scan');
select is(public.my_restrictions() ->> 'audience', 'child', 'my_restrictions names the age group');
select t.reset();

select * from finish();
rollback;
