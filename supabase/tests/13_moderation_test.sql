begin;
\ir helpers/setup.psql
select plan(25);

select t.player('d0000000-0000-0000-0000-000000000001');      -- poster
select t.player(('d0000000-0000-0000-0000-00000000000' || i)::uuid) from generate_series(2, 5) i;  -- reporters
select t.player('d0000000-0000-0000-0000-000000000006', 15);  -- teen
select t.player('d0000000-0000-0000-0000-000000000007');      -- moderator 1
select t.player('d0000000-0000-0000-0000-000000000008');      -- moderator 2
insert into public.guardian_links (child_id, parent_id, status) values
  ('d0000000-0000-0000-0000-000000000006', 'd0000000-0000-0000-0000-000000000005', 'approved');
insert into public.staff (user_id, role) values
  ('d0000000-0000-0000-0000-000000000007', 'moderator'),
  ('d0000000-0000-0000-0000-000000000008', 'moderator');

create temp table m on commit drop as select t.meet('d0000000-0000-0000-0000-000000000001') as id;
grant select on m to authenticated;

create function t.report(p_who uuid) returns void language plpgsql security definer as $$
begin
  insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values (p_who, 'activity', (select id from m)::text, 'spam');
end;
$$;
grant execute on function t.report(uuid) to authenticated;

-- P2-07 auto-hide.
select t.report('d0000000-0000-0000-0000-000000000002');
select t.report('d0000000-0000-0000-0000-000000000002');
select t.report('d0000000-0000-0000-0000-000000000003');
select is((select hidden_at from public.activities where id = (select id from m)), null, 'two people do not hide an item');
select is((select count(*)::int from public.case_reports r join public.moderation_cases c on c.id = r.case_id
  where c.target_id = (select id from m)::text), 2, 'the same person counts once');
select t.report('d0000000-0000-0000-0000-000000000004');
select isnt((select hidden_at from public.activities where id = (select id from m)), null, 'P2-07 three distinct reporters hide the item');
select is((select count(*)::int from public.moderation_cases where target_id = (select id from m)::text), 1, 'one case per item');

select t.as_user('d0000000-0000-0000-0000-000000000002');
select is_empty(format('select 1 from public.activities where id = %L', (select id from m)), 'a hidden Meet is gone for other players');
select t.reset();
select t.as_user('d0000000-0000-0000-0000-000000000001');
select isnt_empty(format('select 1 from public.activities where id = %L', (select id from m)), 'its host still sees it');
select t.reset();

-- Reporters learn nothing.
select t.as_user('d0000000-0000-0000-0000-000000000002');
select is(public.my_reports() -> 0 ->> 'status', 'in_review', 'P2-07 a reporter sees a neutral status');
select is(public.my_reports() -> 0 ->> 'result', null, 'a reporter never sees the result');
select t.reset();

-- Child reports.
create temp table k on commit drop as select t.meet('d0000000-0000-0000-0000-000000000001') as id;
grant select on k to authenticated;
insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values ('d0000000-0000-0000-0000-000000000006', 'activity', (select id from k)::text, 'unsafe');
select ok((select involves_child and deadline_at <= now() + interval '24 hours'
  from public.moderation_cases where target_id = (select id from k)::text), 'P2-07 a child report has a 24-hour deadline');

-- Staff decide.
select t.as_user('d0000000-0000-0000-0000-000000000002');
select throws_ok($$select public.staff_case_list()$$, 'P0001', null, 'a player cannot see the queue');
select throws_ok($$select * from public.moderation_cases$$, '42501', null, 'a player cannot read cases');
select t.reset();

select t.as_staff('d0000000-0000-0000-0000-000000000007');
select ok(jsonb_array_length(public.staff_case_list()) >= 2, 'A-03 a moderator sees the queue');
select public.staff_case_decide((select (c ->> 'id')::uuid from jsonb_array_elements(public.staff_case_list()) c where c ->> 'target_id' = (select id from m)::text), 'kept', 'Not against the rules');
select t.reset();
select is((select hidden_at from public.activities where id = (select id from m)), null, 'A-03 restoring brings an item back');
select ok((select count(*) >= 1 from public.admin_audit where action = 'case_kept'), 'A-03 every action writes the audit log');

select t.as_staff('d0000000-0000-0000-0000-000000000007');
select public.staff_case_decide((select (c ->> 'id')::uuid from jsonb_array_elements(public.staff_case_list()) c where c ->> 'target_id' = (select id from k)::text), 'removed', 'Breaks the rules');
select t.reset();
select is((select count(*)::int from public.content_removals where user_id = 'd0000000-0000-0000-0000-000000000001'), 1, 'the poster gets a removal notice');

-- Suspend at once; bans need two people.
select t.as_staff('d0000000-0000-0000-0000-000000000007');
select public.staff_suspend('d0000000-0000-0000-0000-000000000003', 7, 'Repeat spam');
select t.reset();
select ok(private.is_restricted('d0000000-0000-0000-0000-000000000003'), 'R-MOD-5 a suspension takes effect at once');

select t.as_staff('d0000000-0000-0000-0000-000000000007');
select public.staff_ban_request('d0000000-0000-0000-0000-000000000004', 'Harassment');
select throws_ok(format('select public.staff_ban_decide(%L, true, %L)', (select public.staff_ban_list() -> 0 ->> 'id'), 'Agreed'),
  'P0001', 'A second staff member has to decide this.', 'R-MOD-4 nobody approves their own ban');
select t.reset();
select ok(not private.is_suspended('d0000000-0000-0000-0000-000000000004'), 'a ban does nothing until approved');

select t.as_staff('d0000000-0000-0000-0000-000000000008');
select public.staff_ban_decide((public.staff_ban_list() -> 0 ->> 'id')::uuid, true, 'Agreed');
select t.reset();
select ok(private.is_suspended('d0000000-0000-0000-0000-000000000004'), 'R-MOD-4 a second person applies the ban');

-- Text checks.
select is(private.text_problem('Call me on 9123 4567'), 'phone', 'phone numbers are caught');
select is(private.text_problem('join at https://wa.me/123'), 'link', 'outside links are caught');
select is(private.text_problem('dasar babi'), 'word', 'Malay is caught');
select is(private.text_problem('Good game, see you Saturday at 8pm'), null, 'normal chat passes');
select is(private.text_problem('Scored 21 to 19, court 3'), null, 'scores are not phone numbers');
select is(private.text_problem('assistant coach'), null, 'a word inside a longer word passes');

select * from finish();
rollback;
