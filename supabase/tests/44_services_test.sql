-- P4c-03: referrals record that one was made, and nothing about why.
begin;
\ir helpers/setup.psql
select no_plan();

select t.player('c4000000-0000-0000-0000-000000000001');  -- adult
select t.player('c4000000-0000-0000-0000-000000000002', 15);  -- teen
select t.player('c4000000-0000-0000-0000-000000000003');  -- content staff
select t.player('c4000000-0000-0000-0000-000000000004');  -- payments staff
select t.player('c4000000-0000-0000-0000-000000000005', 10);  -- restricted child
insert into public.staff (user_id, role) values
  ('c4000000-0000-0000-0000-000000000003', 'content'), ('c4000000-0000-0000-0000-000000000004', 'payments');

insert into public.service_partners (id, name, booking_url, ref_code, active) values
  ('c4a00000-0000-0000-0000-000000000001', 'Live Physio', 'https://physio.example/book', 'OLYMPUS', true),
  ('c4a00000-0000-0000-0000-000000000002', 'Query Physio', 'https://physio.example/book?clinic=2', 'OG-2', true),
  ('c4a00000-0000-0000-0000-000000000003', 'Off Physio', 'https://physio.example/off', 'OFF', false);

select is(array_agg(column_name::text order by ordinal_position), array['id', 'user_id', 'partner_id', 'ref_code', 'created_at'],
  'a referral holds only these columns, so a condition has nowhere to go')
from information_schema.columns where table_schema = 'public' and table_name = 'service_referrals';

select t.as_user('c4000000-0000-0000-0000-000000000001');
select is((select count(*) from jsonb_array_elements(public.service_partner_list())), 2::bigint, 'only live partners are listed');
select ok(public.service_partner_list() -> 0 -> 'ref_code' is null, 'without their reference code');
select is(public.service_referral_make('c4a00000-0000-0000-0000-000000000001'), 'https://physio.example/book?ref=OLYMPUS', 'the link carries the partner code');
select is(public.service_referral_make('c4a00000-0000-0000-0000-000000000002'), 'https://physio.example/book?clinic=2&ref=OG-2', 'added to a link with a query');
select unalike(public.service_referral_make('c4a00000-0000-0000-0000-000000000001'), '%c4000000%', 'and never who it is');
select throws_ok($$ select public.service_referral_make('c4a00000-0000-0000-0000-000000000003') $$, 'This partner is no longer listed.', 'an inactive partner can''t be used');
select is_empty($$ select 1 from public.service_referrals $$, 'referrals aren''t readable, even by their owner');
select is_empty($$ select 1 from public.service_partners $$, 'partners only come through the list');
select throws_ok($$ insert into public.service_referrals (user_id, partner_id, ref_code)
  values (auth.uid(), 'c4a00000-0000-0000-0000-000000000001', 'x') $$, '42501', null, 'nobody writes one directly');
select t.reset();
select is((select count(*) from public.service_referrals where user_id = 'c4000000-0000-0000-0000-000000000001'), 3::bigint, 'each referral is recorded');

select t.as_user('c4000000-0000-0000-0000-000000000002');
select throws_ok($$ select public.service_referral_make('c4a00000-0000-0000-0000-000000000001') $$, 'Ask a parent to book this for you.', 'a minor can''t leave for a clinic alone');
select t.reset();

select t.as_anon();
select throws_ok($$ select public.service_partner_list() $$, '42501', null, 'signed out sees no list');
select t.reset();

create function t.gate(p_user uuid, p_path text) returns void language plpgsql as $$
begin
  perform t.as_user(p_user);
  perform set_config('request.path', p_path, true);
  perform set_config('request.method', 'POST', true);
  perform private.gate_request();
end;
$$;
select throws_ok($$ select t.gate('c4000000-0000-0000-0000-000000000005', '/rpc/service_partner_list') $$, null, null, 'nor does a restricted child');
select t.reset();

select t.as_user('c4000000-0000-0000-0000-000000000001');
select throws_ok($$ select public.staff_service_list() $$, 'Not found.', 'a player can''t reach staff lists');
select t.reset();
select t.as_staff('c4000000-0000-0000-0000-000000000004');
select throws_ok($$ select public.staff_service_list() $$, 'Not found.', 'nor can payments staff');
select t.reset();
select t.as_staff('c4000000-0000-0000-0000-000000000003', false);
select throws_ok($$ select public.staff_service_list() $$, 'Not found.', 'nor content staff without MFA');
select t.reset();

select t.as_staff('c4000000-0000-0000-0000-000000000003');
select is((select (x ->> 'referrals')::int from jsonb_array_elements(public.staff_service_list()) x where x ->> 'name' = 'Live Physio'), 2, 'staff see a count per partner');
select ok(public.staff_service_list()::text not like '%c4000000%', 'and never who');
select throws_ok($$ select public.staff_service_save('{"name": "New", "booking_url": "http://x.example", "ref_code": "ABC"}', 'Added') $$,
  'The booking link must start with https://', 'partner links are https only');
select throws_ok($$ select public.staff_service_save('{"name": "New", "booking_url": "javascript:alert(1)", "ref_code": "ABC"}', 'Added') $$,
  'The booking link must start with https://', 'so a script link can''t get in');
select throws_ok($$ select public.staff_service_save('{"name": "New", "booking_url": "https://x.example", "ref_code": "a b"}', 'Added') $$,
  'The reference code is 3 to 32 letters, numbers, - or _.', 'and codes stay plain');
select throws_ok($$ select public.staff_service_save('{"name": "New", "booking_url": "https://x.example", "ref_code": "ABC"}', ' ') $$,
  'Give a reason.', 'with a reason');
select lives_ok($$ select public.staff_service_save('{"name": "New Physio", "booking_url": "https://x.example", "ref_code": "ABC", "active": true}', 'Partnered') $$, 'staff add a partner');
select t.reset();
select ok(exists (select 1 from public.admin_audit a where a.action = 'service_partner_saved'), 'and it''s audited');

select * from finish();
rollback;
