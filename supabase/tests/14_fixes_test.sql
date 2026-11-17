begin;
\ir helpers/setup.psql
select plan(15);

select t.player('e0000000-0000-0000-0000-000000000001');      -- adult
select t.player('e0000000-0000-0000-0000-000000000002');      -- blocker
select t.player('e0000000-0000-0000-0000-000000000003', 12);  -- linked child
select t.player('e0000000-0000-0000-0000-000000000004');      -- parent
select t.player('e0000000-0000-0000-0000-000000000005');      -- outsider
insert into public.guardian_links (child_id, parent_id, status) values
  ('e0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000004', 'approved');
update public.profiles set full_name = 'Mei Ling Tan' where id = 'e0000000-0000-0000-0000-000000000003';

-- Blocked senders.
select t.as_user('e0000000-0000-0000-0000-000000000001');
create temp table conv on commit drop as
  select public.open_direct_conversation('e0000000-0000-0000-0000-000000000002') as id;
grant select on conv to authenticated;
insert into public.messages (conversation_id, sender_id, body)
  values ((select id from conv), 'e0000000-0000-0000-0000-000000000001', 'Hello');
select t.reset();
insert into public.blocks (blocker_id, blocked_id)
  values ('e0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001');
select t.as_user('e0000000-0000-0000-0000-000000000001');
select throws_ok(format($q$insert into public.messages (conversation_id, sender_id, body)
  values (%L, %L, 'Still here')$q$, (select id from conv), 'e0000000-0000-0000-0000-000000000001'),
  '42501', null, 'R-PRV-4 a blocked player cannot keep sending');
select t.reset();

-- Group approval.
insert into public.clubs (id, owner_id, name, area, sports, visibility, join_mode)
  values ('e0000000-0000-0000-0000-0000000000c1', 'e0000000-0000-0000-0000-000000000001', 'Open club', 'Bishan', '["badminton"]', 'public', 'anyone');

select t.as_user('e0000000-0000-0000-0000-000000000003');
select is(public.club_visible('e0000000-0000-0000-0000-0000000000c1'), false, 'P2-03 a child cannot see an unapproved group');
select is(public.club_join('e0000000-0000-0000-0000-0000000000c1'), 'requested', 'asking goes to the parent');
select t.reset();

select is((select count(*)::int from public.club_members where user_id = 'e0000000-0000-0000-0000-000000000003'), 0, 'the child is not in yet');
select throws_ok($$insert into public.club_members (club_id, user_id)
  values ('e0000000-0000-0000-0000-0000000000c1', 'e0000000-0000-0000-0000-000000000003')$$,
  'P0001', 'A parent needs to approve this group first.', 'no path into a club skips the parent');

select t.as_user('e0000000-0000-0000-0000-000000000005');
select throws_ok($$select public.guardian_group_requests('e0000000-0000-0000-0000-000000000003')$$,
  'P0001', 'Only a linked parent can see this.', 'a stranger cannot see the request');
select t.reset();

select t.as_user('e0000000-0000-0000-0000-000000000004');
select is(jsonb_array_length(public.guardian_group_requests('e0000000-0000-0000-0000-000000000003')), 1, 'the parent sees it');
select public.guardian_group_decide('e0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-0000000000c1', true);
select t.reset();

select t.as_user('e0000000-0000-0000-0000-000000000003');
select is(public.club_visible('e0000000-0000-0000-0000-0000000000c1'), true, 'approval opens the group');
select is(public.club_join('e0000000-0000-0000-0000-0000000000c1'), 'member', 'the child can now join');
select t.reset();

-- Club Meets.
create temp table cm on commit drop as select t.meet('e0000000-0000-0000-0000-000000000001') as id;
grant select on cm to authenticated;
alter table public.activities disable trigger activities_club_check;
update public.activities set club_id = 'e0000000-0000-0000-0000-0000000000c1' where id = (select id from cm);

select t.as_user('e0000000-0000-0000-0000-000000000005');
select is_empty(format('select 1 from public.activities where id = %L', (select id from cm)), 'R-MET-2 a club Meet stays with the club');
select t.reset();
update public.activities set public_listing = true where id = (select id from cm);
select t.as_user('e0000000-0000-0000-0000-000000000005');
select isnt_empty(format('select 1 from public.activities where id = %L', (select id from cm)), 'R-MET-2 until it is made public');
select t.reset();

-- Names.
insert into public.club_bans (club_id, user_id, banned_by)
  values ('e0000000-0000-0000-0000-0000000000c1', 'e0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001');
select t.as_user('e0000000-0000-0000-0000-000000000001');
select set_config('role', 'postgres', true);
select is(private.public_name('e0000000-0000-0000-0000-000000000003'), 'Mei L.', 'public_name masks a minor');
select t.reset();
select t.as_user('e0000000-0000-0000-0000-000000000004');
select set_config('role', 'postgres', true);
select is(private.public_name('e0000000-0000-0000-0000-000000000003'), 'Mei Ling Tan', 'not for their parent');
select t.reset();

select ok(position('public_name' in pg_get_functiondef('public.club_ban_list(uuid)'::regprocedure)) > 0, 'club lists use it');
select ok(position('public_name' in pg_get_functiondef('public.shop_order_json(uuid)'::regprocedure)) > 0, 'shop orders use it');

select * from finish();
rollback;
