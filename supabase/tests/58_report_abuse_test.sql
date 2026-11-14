-- Audit S3 (10 Nov 2026, Q269): three accounts must not be able to hide what
-- they can't see, a flood of reports is refused, only established accounts
-- count towards the automatic hide, and a staff "keep" sticks.
begin;
\ir helpers/setup.psql
select no_plan();

select t.player('e5800000-0000-0000-0000-000000000001');      -- owner of everything reported
select t.player('e5800000-0000-0000-0000-000000000002');      -- club member, in the DM
select t.player('e5800000-0000-0000-0000-000000000003');      -- outsider
select t.player('e5800000-0000-0000-0000-000000000004');      -- blocked by the owner
select t.player('e5800000-0000-0000-0000-000000000005', 15);  -- minor
select t.player(('e5800000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid)
  from generate_series(10, 19) i;                              -- reporters for the hide
select t.player('e5800000-0000-0000-0000-000000000020', 15);  -- a teen with a parent
insert into public.guardian_links (child_id, parent_id, status)
  values ('e5800000-0000-0000-0000-000000000020', 'e5800000-0000-0000-0000-000000000002', 'approved');
-- Established accounts, except 10 to 12, which are a day old.
update auth.users set created_at = now() - interval '30 days' where id::text like 'e5800000-%';
update auth.users set created_at = now() - interval '1 day'
  where id in ('e5800000-0000-0000-0000-000000000010', 'e5800000-0000-0000-0000-000000000011',
               'e5800000-0000-0000-0000-000000000012');
insert into public.blocks (blocker_id, blocked_id)
  values ('e5800000-0000-0000-0000-000000000001', 'e5800000-0000-0000-0000-000000000004');

-- A hidden club with a member, its chat, a club-only Meet, a DM, a public
-- Meet, and two shop items.
insert into public.clubs (id, owner_id, name, area, sports, visibility) values
  ('e5800000-0000-0000-0000-0000000000c1', 'e5800000-0000-0000-0000-000000000001', 'Quiet club', 'Bishan', '["badminton"]', 'hidden');
insert into public.club_members (club_id, user_id) values
  ('e5800000-0000-0000-0000-0000000000c1', 'e5800000-0000-0000-0000-000000000001'),
  ('e5800000-0000-0000-0000-0000000000c1', 'e5800000-0000-0000-0000-000000000002');
insert into public.teams (id, name, owner_id) values
  ('e5800000-0000-0000-0000-0000000000d1', 'Quiet team', 'e5800000-0000-0000-0000-000000000001');
insert into public.team_members (team_id, user_id) values
  ('e5800000-0000-0000-0000-0000000000d1', 'e5800000-0000-0000-0000-000000000002');
create temp table ids (name text primary key, id text) on commit drop;
grant select, insert on ids to authenticated, anon;
create function t.id(p_name text) returns text language sql stable as $$ select id from ids where name = p_name $$;
grant execute on function t.id(text) to authenticated, anon;

with g as (insert into public.group_messages (club_id, sender_id, kind, body)
  values ('e5800000-0000-0000-0000-0000000000c1', 'e5800000-0000-0000-0000-000000000001', 'text', 'See you at 8')
  returning id)
insert into ids select 'chat', id::text from g;

insert into ids values ('club_meet', t.meet('e5800000-0000-0000-0000-000000000001')::text);
alter table public.activities disable trigger activities_club_check;
update public.activities set club_id = 'e5800000-0000-0000-0000-0000000000c1' where id::text = t.id('club_meet');
alter table public.activities enable trigger activities_club_check;
insert into ids values ('meet', t.meet('e5800000-0000-0000-0000-000000000001')::text);
insert into ids values ('meet2', t.meet('e5800000-0000-0000-0000-000000000001')::text);

select t.as_user('e5800000-0000-0000-0000-000000000001');
insert into ids select 'conv', public.open_direct_conversation('e5800000-0000-0000-0000-000000000002')::text;
select t.reset();
with m as (insert into public.messages (conversation_id, sender_id, body)
  values (t.id('conv')::uuid, 'e5800000-0000-0000-0000-000000000001', 'Hello') returning id)
insert into ids select 'dm', id::text from m;

with s as (insert into public.malls (name, initials) values ('Test Mall', 'TM') returning id)
insert into ids select 'mall', id::text from s;
with p as (insert into public.products (mall_id, name, price_cents, published)
  values (t.id('mall')::uuid, 'Grip tape', 500, true) returning id)
insert into ids select 'listed', id::text from p;
with p as (insert into public.products (mall_id, name, price_cents, published)
  values (t.id('mall')::uuid, 'Draft item', 500, false) returning id)
insert into ids select 'draft', id::text from p;

create function t.report(p_kind text, p_id text) returns void language sql as $$
  insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values (auth.uid(), p_kind, p_id, 'spam');
$$;
grant execute on function t.report(text, text) to authenticated, anon;
-- Files a report as [p_who], for the counting checks below.
create function t.report_as(p_who uuid, p_id text, p_note text default '') returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_who, 'role', 'authenticated')::text, true);
  insert into public.content_reports (reporter_id, target_kind, target_id, reason, note)
  values (p_who, 'activity', p_id, 'spam', p_note);
  perform set_config('request.jwt.claims', '', true);
end;
$$;

-- ─── 1. Only what you can see ──────────────────────────────────────────────

select t.as_user('e5800000-0000-0000-0000-000000000003');
select throws_ok($$ select t.report('message', t.id('chat')) $$, 'P0001', 'This can''t be reported.',
  'S3 an outsider can''t report a chat message in a club they aren''t in');
select throws_ok($$ select t.report('club', 'e5800000-0000-0000-0000-0000000000c1') $$, 'P0001', 'This can''t be reported.',
  'nor a hidden club');
select throws_ok($$ select t.report('club', gen_random_uuid()::text) $$, 'P0001', 'This can''t be reported.',
  'and a club that doesn''t exist gets the same answer');
select throws_ok($$ select t.report('activity', t.id('club_meet')) $$, 'P0001', 'This can''t be reported.',
  'nor a club-only Meet');
select throws_ok($$ select t.report('dm', t.id('dm')) $$, 'P0001', 'This can''t be reported.',
  'nor someone else''s direct message');
select throws_ok($$ select t.report('dm', (t.id('dm')::bigint + 1)::text) $$, 'P0001', 'This can''t be reported.',
  'nor a guessed message number');
select throws_ok($$ select t.report('live', gen_random_uuid()::text) $$, 'P0001', 'This can''t be reported.',
  'nor a kind with nothing behind it');
select throws_ok($$ select t.report('club', 'not-an-id') $$, 'P0001', 'This can''t be reported.',
  'a bad id is refused, not an error');
select throws_ok($$ select public.shop_report(t.id('draft')::uuid, 'spam', '') $$, 'P0001', 'This can''t be reported.',
  'nor an unpublished shop item');
select throws_ok($$ select public.shop_report(gen_random_uuid(), 'spam', '') $$, 'P0001', 'This can''t be reported.',
  'and a missing one gets the same answer, so a draft''s id stays secret');
select throws_ok($$ select t.report('team', 'e5800000-0000-0000-0000-0000000000d1') $$, 'P0001', 'This can''t be reported.',
  'nor a team they aren''t in');
select throws_ok($$ insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  values ('e5800000-0000-0000-0000-000000000002', 'activity', t.id('meet'), 'spam') $$, 'P0001', 'This can''t be reported.',
  'nobody reports in another player''s name');
select lives_ok($$ select t.report('activity', t.id('meet')) $$, 'an outsider can report a public Meet');
select lives_ok($$ select public.shop_report(t.id('listed')::uuid, 'spam', '') $$, 'and a listed shop item');
select t.reset();

select t.as_user('e5800000-0000-0000-0000-000000000002');
select lives_ok($$ select t.report('message', t.id('chat')) $$, 'a member can report a chat message');
select lives_ok($$ select t.report('club', 'e5800000-0000-0000-0000-0000000000c1') $$, 'and their hidden club');
select lives_ok($$ select t.report('activity', t.id('club_meet')) $$, 'and its club-only Meet');
select lives_ok($$ select t.report('dm', t.id('dm')) $$, 'and a direct message sent to them');
select lives_ok($$ select t.report('team', 'e5800000-0000-0000-0000-0000000000d1') $$, 'and their team');
select lives_ok($$ select t.report('dm', '000' || t.id('dm')) $$, 'a padded message number is the same message');
select t.reset();

select t.as_anon();
select throws_ok($$ select t.report('activity', t.id('meet')) $$, '42501', null, 'a signed-out caller can''t report');
select t.reset();

select is((select count(*)::int from public.moderation_cases where target_id = t.id('chat')), 1,
  'a refused report leaves no case behind, and an accepted one makes one');
select is((select count(*)::int from public.moderation_cases where target_kind = 'dm'
  and target_id in (t.id('dm'), '000' || t.id('dm'))), 1, 'and a padded number joins the same case');

-- A minor without a parent can still ask for help, but it doesn't count.
select t.as_user('e5800000-0000-0000-0000-000000000005');
select lives_ok($$ select t.report('activity', t.id('meet')) $$, 'a child can report a public Meet');
select t.reset();
select is((select counts from public.case_reports r join public.moderation_cases c on c.id = r.case_id
  where c.target_id = t.id('meet') and r.reporter_id = 'e5800000-0000-0000-0000-000000000005'), false,
  'S3 a restricted account''s report doesn''t count towards the hide');
select t.as_user('e5800000-0000-0000-0000-000000000004');
select lives_ok($$ select t.report('activity', t.id('meet')) $$, 'someone the host blocked can report the host''s Meet');
select t.reset();
select is((select counts from public.case_reports r join public.moderation_cases c on c.id = r.case_id
  where c.target_id = t.id('meet') and r.reporter_id = 'e5800000-0000-0000-0000-000000000004'), false,
  'but it doesn''t count towards hiding it');

-- ─── 2. A limit per hour ───────────────────────────────────────────────────

select t.as_user('e5800000-0000-0000-0000-000000000013');
select lives_ok($$ select t.report('activity', t.id('meet')) from generate_series(1, 10) $$, 'ten reports in an hour are fine');
select throws_ok($$ select t.report('activity', t.id('meet')) $$, 'P0001', 'You''ve sent a lot of reports. Try again in an hour.',
  'S3 the eleventh is refused');
select throws_ok($$ insert into public.player_reports (reporter_id, reported_id, reason)
  values (auth.uid(), 'e5800000-0000-0000-0000-000000000001', 'spam') $$, 'P0001', null,
  'and the limit covers player reports too');
select t.reset();

select t.as_user('e5800000-0000-0000-0000-000000000014');
select throws_ok($$ insert into public.content_reports (reporter_id, target_kind, target_id, reason)
  select auth.uid(), 'activity', t.id('meet'), 'spam' from generate_series(1, 50) $$, 'P0001',
  'You''ve sent a lot of reports. Try again in an hour.', 'a bulk insert can''t get round it');
select t.reset();
select is((select count(*)::int from public.content_reports where reporter_id = 'e5800000-0000-0000-0000-000000000014'), 0,
  'and none of the bulk insert is kept');
select t.as_user('e5800000-0000-0000-0000-000000000014');
select throws_ok($$ insert into public.content_reports (reporter_id, target_kind, target_id, reason, created_at)
  select auth.uid(), 'activity', t.id('meet'), 'spam', '2000-01-01' from generate_series(1, 50) $$, 'P0001',
  'You''ve sent a lot of reports. Try again in an hour.', 'S3 backdating them doesn''t either');
select lives_ok($$ insert into public.content_reports (reporter_id, target_kind, target_id, reason, created_at, status, decided_at)
  values (auth.uid(), 'activity', t.id('meet'), 'spam', '2000-01-01', 'removed', '2000-01-02') $$,
  'one report with its own time and status is accepted');
select t.reset();
select ok((select created_at = now() and status = 'in_review' and decided_at is null from public.content_reports
  where reporter_id = 'e5800000-0000-0000-0000-000000000014'), 'but the server sets its time and review fields');

-- ─── 3. Only established accounts hide ─────────────────────────────────────

select t.report_as(('e5800000-0000-0000-0000-0000000000' || i)::uuid, t.id('meet2')) from generate_series(10, 12) i;
select is((select hidden_at from public.activities where id::text = t.id('meet2')), null,
  'S3 three day-old accounts don''t hide a Meet');
select is((select count(*)::int from public.case_reports r join public.moderation_cases c on c.id = r.case_id
  where c.target_id = t.id('meet2')), 3, 'but staff see all three reports');
select t.report_as(('e5800000-0000-0000-0000-0000000000' || i)::uuid, t.id('meet2')) from generate_series(15, 16) i;
select is((select hidden_at from public.activities where id::text = t.id('meet2')), null, 'two established accounts don''t');
select t.report_as('e5800000-0000-0000-0000-000000000017', t.id('meet2'));
select isnt((select hidden_at from public.activities where id::text = t.id('meet2')), null,
  'P2-07 three established accounts do');

update public.app_settings set value = '0' where key = 'moderation.reporter_min_days';
select is(private.report_counts('e5800000-0000-0000-0000-000000000010', 'activity', t.id('meet2')), true,
  'with the setting at 0 every account counts');
update public.app_settings set value = '7' where key = 'moderation.reporter_min_days';

-- ─── 4. A staff "keep" sticks ──────────────────────────────────────────────

-- A test is one transaction, so every now() is the same. Move the past back.
update public.case_reports set created_at = now() - interval '1 hour'
  where case_id = (select id from public.moderation_cases where target_id = t.id('meet2'));
update public.moderation_cases set status = 'kept', hidden_at = null, decided_at = now() - interval '30 minutes',
  deadline_at = now() - interval '2 days'
  where target_id = t.id('meet2');
update public.activities set hidden_at = null where id::text = t.id('meet2');

select t.report_as(('e5800000-0000-0000-0000-0000000000' || i)::uuid, t.id('meet2')) from generate_series(15, 17) i;
select is((select hidden_at from public.activities where id::text = t.id('meet2')), null,
  'S3 the same three can''t hide it again after staff kept it');
select is((select status from public.moderation_cases where target_id = t.id('meet2')), 'open',
  'but their new reports put it back in front of staff');
select is((select deadline_at from public.moderation_cases where target_id = t.id('meet2')), now() + interval '24 hours',
  'with a new deadline, so an old case can''t jump the queue');
select t.report_as('e5800000-0000-0000-0000-000000000015', t.id('meet2'), 'It happened again on Saturday');
select is((select note from public.case_reports r join public.moderation_cases c on c.id = r.case_id
  where c.target_id = t.id('meet2') and r.reporter_id = 'e5800000-0000-0000-0000-000000000015'),
  'It happened again on Saturday', 'staff see the latest note');
select t.report_as(('e5800000-0000-0000-0000-0000000000' || i)::uuid, upper(t.id('meet2'))) from generate_series(15, 17) i;
select is((select count(*)::int from public.moderation_cases where lower(target_id) = t.id('meet2')), 1,
  'S3 an id in capitals is the same case');
select is((select hidden_at from public.activities where id::text = t.id('meet2')), null,
  'so retyping it doesn''t undo the keep');
select t.report_as('e5800000-0000-0000-0000-000000000018', t.id('meet2'));
select is((select hidden_at from public.activities where id::text = t.id('meet2')), null, 'one new reporter alone doesn''t hide it');

-- ─── 5. Players ────────────────────────────────────────────────────────────

select t.as_user('e5800000-0000-0000-0000-000000000004');
select lives_ok($$ insert into public.player_reports (reporter_id, reported_id, reason)
  values (auth.uid(), 'e5800000-0000-0000-0000-000000000001', 'harassment') $$,
  'a blocked player can still report the person who blocked them');
select t.reset();
select is((select counts from public.case_reports r join public.moderation_cases c on c.id = r.case_id
  where c.target_kind = 'player' and r.reporter_id = 'e5800000-0000-0000-0000-000000000004'), false,
  'but it doesn''t count towards hiding them');
select t.as_user('e5800000-0000-0000-0000-000000000003');
select lives_ok($$ insert into public.player_reports (reporter_id, reported_id, reason)
  values (auth.uid(), 'e5800000-0000-0000-0000-000000000005', 'other') $$, 'anyone can report a child they met');
select t.reset();
select is((select counts from public.case_reports r join public.moderation_cases c on c.id = r.case_id
  where c.target_id = 'e5800000-0000-0000-0000-000000000005' and r.reporter_id = 'e5800000-0000-0000-0000-000000000003'),
  false, 'and a stranger''s report of a child doesn''t count');
select is(private.report_counts('e5800000-0000-0000-0000-000000000002', 'player', 'e5800000-0000-0000-0000-000000000001'), true,
  'a player who can see them counts');
with c as (insert into public.conversations default values returning id)
insert into ids select 'teen_chat', c.id::text from c;
insert into public.conversation_members (conversation_id, user_id)
select t.id('teen_chat')::uuid, u
from unnest(array['e5800000-0000-0000-0000-000000000020', 'e5800000-0000-0000-0000-000000000005']::uuid[]) u;
select is(private.report_counts('e5800000-0000-0000-0000-000000000020', 'player', 'e5800000-0000-0000-0000-000000000005'), false,
  'S3 an empty chat, which anyone can open, doesn''t count');
insert into public.messages (conversation_id, sender_id, body)
  values (t.id('teen_chat')::uuid, 'e5800000-0000-0000-0000-000000000005', 'hi');
select is(private.report_counts('e5800000-0000-0000-0000-000000000020', 'player', 'e5800000-0000-0000-0000-000000000005'), true,
  'a message from them does, even from a child they can''t look up');
insert into public.blocks (blocker_id, blocked_id)
  values ('e5800000-0000-0000-0000-000000000005', 'e5800000-0000-0000-0000-000000000020');
select is(private.report_counts('e5800000-0000-0000-0000-000000000020', 'player', 'e5800000-0000-0000-0000-000000000005'), false,
  'but not once they''ve blocked the reporter');

select is(private.case_owner('team', 'e5800000-0000-0000-0000-0000000000d1'), 'e5800000-0000-0000-0000-000000000001'::uuid,
  'a team has an owner, so their blocks count');

-- ─── 7. Rechecked when counted, with real staff decisions ─────────────────
-- Reviews of 14 Nov (Q269). Two reports racing a decision in separate sessions
-- can't be shown in one pgTAP transaction; QA checks that by hand.

select t.player(('e5800000-0000-0000-0000-0000000000' || i)::uuid) from generate_series(21, 60) i;
update auth.users set created_at = now() - interval '30 days'
  where id::text between 'e5800000-0000-0000-0000-000000000021' and 'e5800000-0000-0000-0000-000000000060';
insert into public.staff (user_id, role) values ('e5800000-0000-0000-0000-000000000050', 'moderator');
update public.app_settings set value = '6' where key = 'moderation.child_deadline_hours';
insert into ids select 'meet' || i, t.meet('e5800000-0000-0000-0000-000000000001')::text from generate_series(3, 8) i;

-- Takes a decision through the staff function, as the moderator.
create function t.decide(p_name text, p_outcome text) returns void language plpgsql as $$
declare
  v_case uuid := (select id from public.moderation_cases where target_id = t.id(p_name));
begin
  perform set_config('request.jwt.claims', json_build_object('sub', 'e5800000-0000-0000-0000-000000000050',
    'role', 'authenticated', 'aal', 'aal2')::text, true);
  perform public.staff_case_decide(v_case, p_outcome, 'Checked');
  perform set_config('request.jwt.claims', '', true);
end;
$$;
create function t.case_of(p_name text) returns public.moderation_cases language sql as $$
  select * from public.moderation_cases where target_id = t.id(p_name)
$$;
create function t.hidden(p_name text) returns boolean language sql as $$
  select hidden_at is not null from public.activities where id::text = t.id(p_name)
$$;
create function t.report_player(p_who uuid, p_target uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_who, 'role', 'authenticated')::text, true);
  insert into public.player_reports (reporter_id, reported_id, reason) values (p_who, p_target, 'harassment');
  perform set_config('request.jwt.claims', '', true);
end;
$$;

-- (a) After a real keep, earlier reporters don't count again and three new
-- ones hide it again, timed after the decision even inside one transaction.
select t.report_as(('e5800000-0000-0000-0000-0000000000' || i)::uuid, t.id('meet3')) from generate_series(21, 23) i;
select ok(t.hidden('meet3'), 'three reports hide it');
select t.decide('meet3', 'kept');
select ok(not t.hidden('meet3') and (t.case_of('meet3')).status = 'kept', 'staff keep it, and it shows again');
select ok((t.case_of('meet3')).decided_at > now(), 'S3 the decision is timed by the clock, after the lock');
update public.moderation_cases set deadline_at = now() - interval '2 days' where target_id = t.id('meet3');
select t.report_as('e5800000-0000-0000-0000-000000000021', t.id('meet3'));
select is((t.case_of('meet3')).status, 'open', 'a new report puts it back in front of staff');
select is((t.case_of('meet3')).deadline_at, now() + interval '24 hours', 'with a fresh 24-hour deadline');
select t.report_as(('e5800000-0000-0000-0000-0000000000' || i)::uuid, t.id('meet3')) from generate_series(24, 25) i;
select ok(not t.hidden('meet3'), 'S3 an earlier reporter and two new ones aren''t three');
select t.report_as('e5800000-0000-0000-0000-000000000026', t.id('meet3'));
select ok(t.hidden('meet3'), 'S3 three new reporters after the keep hide it again');
select ok((select bool_and(r.created_at > c.decided_at) from public.case_reports r
  join public.moderation_cases c on c.id = r.case_id
  where c.target_id = t.id('meet3') and r.reporter_id::text >= 'e5800000-0000-0000-0000-000000000024'),
  'S3 a report filed after a decision is timed after it');

-- (b) An open case's deadline doesn't move.
select t.report_as('e5800000-0000-0000-0000-000000000027', t.id('meet4'));
update public.moderation_cases set deadline_at = now() + interval '5 hours' where target_id = t.id('meet4');
select t.report_as('e5800000-0000-0000-0000-000000000028', t.id('meet4'));
select is((t.case_of('meet4')).deadline_at, now() + interval '5 hours', 'more reports don''t push an open deadline back');
select t.report_as('e5800000-0000-0000-0000-000000000029', t.id('meet4'));
select ok(t.hidden('meet4'), 'three reports hide it');
select is((t.case_of('meet4')).deadline_at, now() + interval '5 hours', 'and hiding it doesn''t move the deadline either');

-- (c) A case with a child in it uses the child deadline when it comes back.
select t.report_as('e5800000-0000-0000-0000-000000000020', t.id('meet8'));
select is((t.case_of('meet8')).deadline_at, now() + interval '6 hours', 'a teen''s report sets the child deadline');
select t.decide('meet8', 'kept');
update public.moderation_cases set deadline_at = now() - interval '2 days' where target_id = t.id('meet8');
select t.report_as('e5800000-0000-0000-0000-000000000030', t.id('meet8'));
select is((t.case_of('meet8')).deadline_at, now() + interval '6 hours', 'and it comes back with a fresh child deadline');

-- (d) A removed item stays removed.
select t.report_as(('e5800000-0000-0000-0000-0000000000' || i)::uuid, t.id('meet5')) from generate_series(31, 33) i;
select t.decide('meet5', 'removed');
select throws_ok($$select t.report_as('e5800000-0000-0000-0000-000000000034', t.id('meet5'))$$,
  'P0001', 'This can''t be reported.', 'a removed Meet can''t be reported again');
select ok(t.hidden('meet5'), 'and it stays hidden');
-- A player can always be reported, so their removed case meets new reports.
select t.report_player('e5800000-0000-0000-0000-000000000046', 'e5800000-0000-0000-0000-000000000049');
insert into ids values ('p49', 'e5800000-0000-0000-0000-000000000049');
select t.decide('p49', 'removed');
select t.report_player('e5800000-0000-0000-0000-000000000047', 'e5800000-0000-0000-0000-000000000049');
select is((t.case_of('p49')).status, 'removed', 'a report after removal doesn''t reopen it');

-- (e) A suspension after reporting stops the report counting; a block after
-- reporting doesn't, or an owner could silence everyone who reported them.
select t.report_as('e5800000-0000-0000-0000-000000000039', t.id('meet7'));
insert into public.account_moderation (user_id, suspended_until)
  values ('e5800000-0000-0000-0000-000000000039', now() + interval '7 days');
select t.report_as(('e5800000-0000-0000-0000-0000000000' || i)::uuid, t.id('meet7')) from generate_series(40, 41) i;
select ok(not t.hidden('meet7'), 'S3 a reporter suspended afterwards no longer counts');

select t.report_as('e5800000-0000-0000-0000-000000000035', t.id('meet6'));
insert into public.blocks (blocker_id, blocked_id)
  values ('e5800000-0000-0000-0000-000000000001', 'e5800000-0000-0000-0000-000000000035');
select t.report_as(('e5800000-0000-0000-0000-0000000000' || i)::uuid, t.id('meet6')) from generate_series(36, 37) i;
select ok(t.hidden('meet6'), 'S3 the host blocking a reporter afterwards doesn''t silence them');

-- A victim who reports a player and then blocks them still counts.
select t.report_player(('e5800000-0000-0000-0000-0000000000' || i)::uuid, 'e5800000-0000-0000-0000-000000000052')
  from generate_series(53, 54) i;
insert into public.blocks (blocker_id, blocked_id) values
  ('e5800000-0000-0000-0000-000000000053', 'e5800000-0000-0000-0000-000000000052'),
  ('e5800000-0000-0000-0000-000000000054', 'e5800000-0000-0000-0000-000000000052');
select t.report_player('e5800000-0000-0000-0000-000000000055', 'e5800000-0000-0000-0000-000000000052');
select isnt((select hidden_at from public.moderation_cases where target_id = 'e5800000-0000-0000-0000-000000000052'), null,
  'S3 victims who report and then block still hide the player');

-- A club handed to someone else: the case keeps its owner, and a moderator
-- who owns the club now still can't decide it.
insert into public.clubs (id, owner_id, name, area, sports, visibility) values
  ('e5800000-0000-0000-0000-0000000000c2', 'e5800000-0000-0000-0000-000000000002', 'Open club', 'Bishan', '["badminton"]', 'public');
insert into ids values ('c2', 'e5800000-0000-0000-0000-0000000000c2');
select t.as_user('e5800000-0000-0000-0000-000000000042');
select t.report('club', 'e5800000-0000-0000-0000-0000000000c2');
select t.reset();
update public.clubs set owner_id = 'e5800000-0000-0000-0000-000000000050' where id = 'e5800000-0000-0000-0000-0000000000c2';
select t.as_user('e5800000-0000-0000-0000-000000000043');
select t.report('club', 'e5800000-0000-0000-0000-0000000000c2');
select t.reset();
select is((select owner_id from public.moderation_cases where target_id = 'e5800000-0000-0000-0000-0000000000c2'),
  'e5800000-0000-0000-0000-000000000002'::uuid, 'S3 handing a club over doesn''t move the case onto someone else');
select throws_ok($$select t.decide('c2', 'kept')$$, 'P0001', 'Someone else has to decide your own case.',
  'S3 a moderator who owns it now can''t decide it');
-- Nor can a moderator who owned it when it was reported and has since handed it on.
insert into public.clubs (id, owner_id, name, area, sports, visibility) values
  ('e5800000-0000-0000-0000-0000000000c3', 'e5800000-0000-0000-0000-000000000050', 'Mod club', 'Bishan', '["badminton"]', 'public');
insert into ids values ('c3', 'e5800000-0000-0000-0000-0000000000c3');
select t.as_user('e5800000-0000-0000-0000-000000000056');
select t.report('club', 'e5800000-0000-0000-0000-0000000000c3');
select t.reset();
update public.clubs set owner_id = 'e5800000-0000-0000-0000-000000000002' where id = 'e5800000-0000-0000-0000-0000000000c3';
select throws_ok($$select t.decide('c3', 'kept')$$, 'P0001', 'Someone else has to decide your own case.',
  'S3 nor one who owned it when it was reported');
-- A case with no owner gets one on the next report.
insert into ids values ('meet9', t.meet('e5800000-0000-0000-0000-000000000001')::text);
insert into public.moderation_cases (target_kind, target_id, owner_id, involves_child, deadline_at)
  values ('activity', t.id('meet9'), null, false, now() + interval '24 hours');
select t.report_as('e5800000-0000-0000-0000-000000000057', t.id('meet9'));
select is((t.case_of('meet9')).owner_id, 'e5800000-0000-0000-0000-000000000001'::uuid,
  'a case missing its owner gets one on the next report');

-- (f) A team owner's block, end to end.
insert into public.blocks (blocker_id, blocked_id)
  values ('e5800000-0000-0000-0000-000000000001', 'e5800000-0000-0000-0000-000000000051');
insert into public.team_members (team_id, user_id)
  values ('e5800000-0000-0000-0000-0000000000d1', 'e5800000-0000-0000-0000-000000000051');
select t.as_user('e5800000-0000-0000-0000-000000000051');
select t.report('team', 'e5800000-0000-0000-0000-0000000000d1');
select t.reset();
select is((select r.counts from public.case_reports r join public.moderation_cases c on c.id = r.case_id
  where c.target_id = 'e5800000-0000-0000-0000-0000000000d1' and r.reporter_id = 'e5800000-0000-0000-0000-000000000051'),
  false, 'S3 a team member the team owner blocked doesn''t count');

-- ─── 6. Nobody calls the helpers ───────────────────────────────────────────

select ok(not has_function_privilege(r, f, 'execute'), format('%s can''t run %s', r, f))
from unnest(array['anon', 'authenticated']) r,
     unnest(array['private.report_target_visible(text,text)', 'private.report_counts(uuid,text,text)',
                  'private.report_target_id(text,text)',
                  'private.report_check()']) f;

select * from finish();
rollback;
