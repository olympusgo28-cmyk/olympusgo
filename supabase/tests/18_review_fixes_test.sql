begin;
\ir helpers/setup.psql
select plan(14);

select t.player('c1000000-0000-0000-0000-000000000001');      -- adult
select t.player('c1000000-0000-0000-0000-000000000002', 15);  -- linked teen
select t.player('c1000000-0000-0000-0000-000000000003');      -- parent
select t.player(('c1000000-0000-0000-0000-00000000000' || i)::uuid) from generate_series(4, 8) i;
-- Only established accounts count towards the automatic hide (S3, Q269).
update auth.users set created_at = now() - interval '30 days' where id::text like 'c1000000-%';
insert into public.guardian_links (child_id, parent_id, status) values
  ('c1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000003', 'approved');
update public.profiles set full_name = 'Real Child Name' where id = 'c1000000-0000-0000-0000-000000000002';

-- A stranger cannot put a child on a team.
insert into public.teams (id, name, sport, owner_id) values
  ('c1000000-0000-0000-0000-0000000000f1', 'Stranger team', 'badminton', 'c1000000-0000-0000-0000-000000000001');
insert into public.team_members (team_id, user_id)
  values ('c1000000-0000-0000-0000-0000000000f1', 'c1000000-0000-0000-0000-000000000002');
select is((select count(*)::int from public.team_members where user_id = 'c1000000-0000-0000-0000-000000000002'), 0, 'R-TEM-1 a child is not added to a team without a parent');
select is((select count(*)::int from public.guardian_team_approvals), 1, 'the request waits for the parent');

select t.as_user('c1000000-0000-0000-0000-000000000002');
select throws_ok($$insert into public.group_messages (team_id, sender_id, kind, body)
  values ('c1000000-0000-0000-0000-0000000000f1', 'c1000000-0000-0000-0000-000000000002', 'text', 'Hi')$$,
  '42501', null, 'a child cannot chat in an unapproved team');
select t.reset();

select t.as_user('c1000000-0000-0000-0000-000000000003');
select public.guardian_team_decide('c1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-0000000000f1', true);
select t.reset();
select is((select count(*)::int from public.team_members where user_id = 'c1000000-0000-0000-0000-000000000002'), 1, 'a parent''s approval adds them');

-- Owners cannot un-hide.
create temp table m on commit drop as select t.meet('c1000000-0000-0000-0000-000000000001') as id;
grant select on m to authenticated;
update public.activities set hidden_at = now() where id = (select id from m);
update public.profiles set hidden_at = now() where id = 'c1000000-0000-0000-0000-000000000001';
select t.as_user('c1000000-0000-0000-0000-000000000001');
update public.activities set hidden_at = null where id = (select id from m);
update public.profiles set hidden_at = null where id = 'c1000000-0000-0000-0000-000000000001';
select t.reset();
select isnt((select hidden_at from public.activities where id = (select id from m)), null, 'a host cannot un-hide their Meet');
select isnt((select hidden_at from public.profiles where id = 'c1000000-0000-0000-0000-000000000001'), null, 'a player cannot un-hide their profile');

-- Kept stays kept.
create temp table k on commit drop as select t.meet('c1000000-0000-0000-0000-000000000001') as id;
create function t.report(p_who uuid) returns void language plpgsql security definer as $$
begin
  insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values (p_who, 'activity', (select id from k)::text, 'spam');
end;
$$;
select t.report(('c1000000-0000-0000-0000-00000000000' || i)::uuid) from generate_series(4, 6) i;
select isnt((select hidden_at from public.activities where id = (select id from k)), null, 'three reporters hide it');
-- A test runs in one transaction, so every now() is the same. Move the past back.
update public.case_reports set created_at = now() - interval '1 hour';
update public.moderation_cases set status = 'kept', hidden_at = null, decided_at = now() - interval '1 minute' where target_id = (select id from k)::text;
update public.activities set hidden_at = null where id = (select id from k);
select t.report('c1000000-0000-0000-0000-000000000007');
select is((select hidden_at from public.activities where id = (select id from k)), null, 'one new report does not re-hide a cleared item');
select is((select status from public.moderation_cases where target_id = (select id from k)::text), 'open', 'but it goes back in the queue');

-- Real names.
insert into public.player_reports (reporter_id, reported_id, reason)
  values ('c1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000002', 'other');
insert into public.blocks (blocker_id, blocked_id)
  values ('c1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000002');
select t.as_user('c1000000-0000-0000-0000-000000000001');
select ok(public.my_reports()::text not like '%Real Child Name%', 'my_reports does not reveal a minor''s name');
select is((select full_name from public.my_blocked_players() limit 1), 'Real C.', 'nor does the blocked list');
select t.reset();

-- Suspended.
insert into public.account_moderation (user_id, suspended_until)
  values ('c1000000-0000-0000-0000-000000000008', now() + interval '7 days');
create function t.gate(p_path text, p_method text) returns void language plpgsql as $$
begin
  perform set_config('request.path', p_path, true);
  perform set_config('request.method', p_method, true);
  perform private.gate_request();
end;
$$;
grant execute on function t.gate(text, text) to authenticated;
select t.as_user('c1000000-0000-0000-0000-000000000008');
select throws_ok($$select t.gate('/profiles', 'PATCH')$$, 'P0001', 'Your account is suspended.', 'a suspended player cannot edit their profile');
select lives_ok($$select t.gate('/profiles', 'GET')$$, 'but can still read it');
select t.reset();

-- Names.
select t.as_user('c1000000-0000-0000-0000-000000000001');
select throws_ok($$update public.profiles set full_name = 'call 81234567' where id = 'c1000000-0000-0000-0000-000000000001'$$,
  'P0001', 'Keep phone numbers out of this, so everyone stays safe.', 'text checks cover names');
select t.reset();

select * from finish();
rollback;
