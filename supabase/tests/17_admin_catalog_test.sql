begin;
\ir helpers/setup.psql
select plan(13);

select t.player('b1000000-0000-0000-0000-000000000001');      -- content staff
select t.player('b1000000-0000-0000-0000-000000000002');      -- moderator
select t.player('b1000000-0000-0000-0000-000000000003');      -- player
select t.player('b1000000-0000-0000-0000-000000000004', 12);  -- child
insert into public.staff (user_id, role) values
  ('b1000000-0000-0000-0000-000000000001', 'content'),
  ('b1000000-0000-0000-0000-000000000002', 'moderator');

select t.as_staff('b1000000-0000-0000-0000-000000000001');
select public.staff_sport_save('sepak_takraw', 'Sepak takraw', 'draft', 'New sport for testing');
select throws_ok($$select public.staff_sport_save('sepak_takraw', 'Sepak takraw', 'live', 'Too soon')$$,
  'P0001', 'Add a live format before making this sport live.', 'A-02 a sport needs a live format first');
select public.staff_format_save('sepak_takraw', 'doubles', 'Doubles', 'live', 4, '{"points_to_win": 21}', 'First format');
select public.staff_sport_save('sepak_takraw', 'Sepak takraw', 'live', 'Ready');
select t.reset();

select t.as_user('b1000000-0000-0000-0000-000000000003');
select isnt_empty($$select 1 from public.sports where key = 'sepak_takraw'$$, 'A-02 a new sport pushed live appears in the app');
select t.reset();
select lives_ok($$select t.meet('b1000000-0000-0000-0000-000000000003', p_sport => 'sepak_takraw')$$, 'a Meet can use it');
select lives_ok($$insert into public.player_sports (user_id, sport, level, play_min, play_max)
  values ('b1000000-0000-0000-0000-000000000003', 'sepak_takraw', 4, 3, 5)$$, 'so can a Passport');
select is((select count(*)::int from public.admin_audit where target_kind in ('sport', 'format')), 3, 'A-02 each change is in the audit log');
select ok((select count(*) > 0 from public.catalog_audit where row_key = 'sepak_takraw'), 'and in catalog_audit');

select t.as_staff('b1000000-0000-0000-0000-000000000002');
select throws_ok($$select public.staff_catalog()$$, 'P0001', 'Not found.', 'a moderator cannot edit sports');
select ok((public.staff_user_search('Test Pl')::text like '%Test Player%'), 'A-04 a moderator finds a user');
select is(public.staff_user_get('b1000000-0000-0000-0000-000000000004') ->> 'audience', 'child', 'A-04 the age group is shown');
select ok((public.staff_user_get('b1000000-0000-0000-0000-000000000004')::text not like '%birthday%'), 'the birthday is not');
select t.reset();

select public.account_recovery_request('lost@example.com');
select t.as_staff('b1000000-0000-0000-0000-000000000002');
select is(jsonb_array_length(public.staff_recovery_list()), 1, 'A-04 a P1-06 request can be reviewed');
select public.staff_recovery_decide((public.staff_recovery_list() -> 0 ->> 'id')::bigint, true, 'Identity confirmed');
select is(jsonb_array_length(public.staff_recovery_list()), 0, 'and closed');
select t.reset();

select t.as_user('b1000000-0000-0000-0000-000000000003');
select throws_ok($$select public.staff_user_search('Test')$$, 'P0001', 'Not found.', 'a player cannot search users');
select t.reset();

select * from finish();
rollback;
