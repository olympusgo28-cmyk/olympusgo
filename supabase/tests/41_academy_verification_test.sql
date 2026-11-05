-- P4c-01: verification, coaches, students, make-up credits and closing.
begin;
\ir helpers/setup.psql
\ir helpers/academy.psql
select no_plan();

select t.player('c1000000-0000-0000-0000-000000000001');  -- owner
select t.player('c1000000-0000-0000-0000-000000000002');  -- verified coach
select t.player('c1000000-0000-0000-0000-000000000003');  -- no licence yet
select t.player('c1000000-0000-0000-0000-000000000004');  -- parent
select t.player('c1000000-0000-0000-0000-000000000005', 12);  -- child
select t.player('c1000000-0000-0000-0000-000000000006');  -- outsider
select t.player('c1000000-0000-0000-0000-000000000007', 15);  -- teen
select t.player('c1000000-0000-0000-0000-000000000008');  -- content staff
select t.player('c1000000-0000-0000-0000-000000000009');  -- moderator
select t.player('c1000000-0000-0000-0000-00000000000a');  -- adult student
select t.player('c1000000-0000-0000-0000-00000000000b', 10);  -- restricted child
insert into public.staff (user_id, role) values
  ('c1000000-0000-0000-0000-000000000008', 'content'),
  ('c1000000-0000-0000-0000-000000000009', 'moderator');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;

insert into ids select 'academy', t.academy('c1000000-0000-0000-0000-000000000001');
select t.coach(t.id('academy'), 'c1000000-0000-0000-0000-000000000002');
insert into ids select 'class', t.class(t.id('academy'), 'c1000000-0000-0000-0000-000000000002');
insert into ids select 'same_level', t.class(t.id('academy'), 'c1000000-0000-0000-0000-000000000002');
insert into ids select 'next_level', t.class(t.id('academy'), 'c1000000-0000-0000-0000-000000000002', 4, 2);
insert into ids select 'link', t.link('c1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000005');

-- ─── Nothing is reachable without a function ───────────────────────────────

select t.as_user('c1000000-0000-0000-0000-000000000006');
select is_empty($$ select 1 from public.academies $$, 'a player reads no academy rows directly');
select is_empty($$ select 1 from public.academy_students $$, 'or students');
select is_empty($$ select 1 from public.coach_licences $$, 'or licences');
select is_empty($$ select 1 from public.coach_profiles $$, 'or coach profiles');
select is_empty($$ select 1 from public.academy_makeup_credits $$, 'or credits');
select is_empty($$ select 1 from public.academy_cancellations $$, 'or cancellations');
select is_empty($$ update public.academies set verification = 'verified' returning 1 $$, 'nobody writes verification');
select throws_ok($$ insert into public.coach_licences (user_id, nroc_number, expires_on, status)
  values (auth.uid(), 'x12', current_date + 9, 'verified') $$, '42501', null, 'nobody grants themself a licence');
select t.reset();

select t.as_anon();
select throws_ok($$ select public.academy_list() $$, '42501', null, 'signed out can''t list academies');
select throws_ok($$ select public.coach_profile_get('c1000000-0000-0000-0000-000000000002') $$, '42501', null, 'or read a coach');
select throws_ok($$ select public.staff_verification_list() $$, '42501', null, 'or reach staff lists');
select t.reset();

-- ─── Only verified, open academies are listed ──────────────────────────────

with x as (insert into public.academies (owner_id, name, sport)
  values ('c1000000-0000-0000-0000-000000000003', 'Waiting Academy', 'badminton') returning id)
insert into ids select 'waiting', id from x;
insert into public.academy_coaches (academy_id, user_id, role, head, accepted_at)
values (t.id('waiting'), 'c1000000-0000-0000-0000-000000000003', 'Head coach', true, now());

select t.as_user('c1000000-0000-0000-0000-000000000006');
select is((select count(*) from jsonb_array_elements(public.academy_list()) x
  where (x ->> 'id')::uuid in (t.id('academy'), t.id('waiting'))), 1::bigint, 'a stranger sees only the verified academy');
select throws_ok($$ select public.academy_get(t.id('waiting')) $$, 'This academy is no longer listed.', 'and can''t open an unverified one');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000003');
select is((public.academy_get(t.id('waiting')) ->> 'name'), 'Waiting Academy', 'its owner can');
select t.reset();

-- ─── Submitting for review ─────────────────────────────────────────────────

insert into ids (name, id) values ('x', gen_random_uuid());
create temp table paths (name text primary key, path text) on commit drop;
grant all on paths to authenticated, anon;
insert into paths values
  ('mine', t.upload('c1000000-0000-0000-0000-000000000003')),
  ('theirs', t.upload('c1000000-0000-0000-0000-000000000006'));

select t.as_user('c1000000-0000-0000-0000-000000000003');
select throws_ok($$ select public.academy_submit_business(t.id('waiting'), 'nope', (select path from paths where name = 'mine')) $$,
  'Enter your UEN. It has 9 or 10 characters.', 'a bad UEN is refused');
select throws_ok($$ select public.academy_submit_business(t.id('waiting'), '201912345A', (select path from paths where name = 'theirs')) $$,
  'Add your business licence.', 'someone else''s file is refused');
select throws_ok($$ select public.coach_licence_submit('NROC-1', current_date - 1, (select path from paths where name = 'mine')) $$,
  'This licence has expired.', 'an expired licence is refused');
select lives_ok($$ select public.academy_submit_business(t.id('waiting'), '201912345a', (select path from paths where name = 'mine')) $$, 'the owner submits');
select lives_ok($$ select public.coach_licence_submit('NROC-1', current_date + 200, (select path from paths where name = 'mine')) $$, 'and their licence');
select is(public.coach_licence_my() ->> 'status', 'submitted', 'and sees it is in review');
select is(public.coach_licence_my() -> 'file_path', null, 'but no file path comes back');
select t.reset();

select t.as_user('c1000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.academy_submit_business(t.id('waiting'), '201912345A', 'x') $$, 'Only the owner can do this.', 'a stranger can''t submit');
select throws_ok($$ select public.academy_verification(t.id('waiting')) $$, 'Only the head coach can do this.', 'or read the checklist');
select t.reset();

select t.as_user('c1000000-0000-0000-0000-000000000007');
select throws_ok($$ select public.coach_licence_submit('NROC-1', current_date + 9, 'x') $$, 'Coaches must be 18 or over.', 'a teen can''t be a coach');
select throws_ok($$ select public.academy_create('{"name": "Teen Academy"}') $$, 'Academies are run by adults.', 'or run an academy');
select t.reset();

-- ─── Staff review ──────────────────────────────────────────────────────────

select t.as_user('c1000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.staff_verification_list() $$, 'Not found.', 'a player can''t review');
select t.reset();
select t.as_staff('c1000000-0000-0000-0000-000000000009');
select throws_ok($$ select public.staff_licence_decide('c1000000-0000-0000-0000-000000000003', true, 'ok') $$, 'Not found.', 'nor can a moderator');
select t.reset();
select t.as_staff('c1000000-0000-0000-0000-000000000008', false);
select throws_ok($$ select public.staff_verification_list() $$, 'Not found.', 'nor content staff without MFA');
select t.reset();

select t.as_staff('c1000000-0000-0000-0000-000000000008');
select throws_ok($$ select public.staff_academy_decide(t.id('waiting'), true, 'ok') $$, 'The head coach''s licence isn''t verified yet.', 'the licence comes first');
select throws_ok($$ select public.staff_licence_decide('c1000000-0000-0000-0000-000000000003', true, ' ') $$, 'Give a reason.', 'every decision has a reason');
select lives_ok($$ select public.staff_licence_decide('c1000000-0000-0000-0000-000000000003', true, 'Checked the register') $$, 'staff verify the licence');
select throws_ok($$ select public.staff_academy_decide(t.id('waiting'), true, 'ok') $$, 'The owner''s payout account isn''t verified yet.', 'then the payout account');
select t.reset();
insert into public.vendors (owner_id, stripe_account_id, status) values ('c1000000-0000-0000-0000-000000000003', 'acct_w', 'verified');
select t.as_staff('c1000000-0000-0000-0000-000000000008');
select ok(public.staff_verification_list() -> 'academies' -> 0 ->> 'file_path' is not null, 'staff see the file path to review');
select lives_ok($$ select public.staff_academy_decide(t.id('waiting'), true, 'All three checked') $$, 'and verify the academy');
select lives_ok($$ select public.staff_doc_removed('academy', t.id('waiting'), 'Check done') $$, 'then clear the file');
select t.reset();
select is((select verification from public.academies where id = t.id('waiting')), 'verified', 'the academy is verified');
select is((select licence_path from public.academies where id = t.id('waiting')), null, 'and its file is gone');
select ok(exists (select 1 from public.admin_audit a where a.action = 'academy_verification'), 'the decision is audited');

-- A verified academy can't quietly change its details.
select t.as_user('c1000000-0000-0000-0000-000000000003');
select throws_ok($$ select public.academy_submit_business(t.id('waiting'), '201912345B', (select path from paths where name = 'mine')) $$,
  'This academy is verified. Contact us to change it.', 'a verified UEN stays put');
select t.reset();

-- ─── Coaches say yes first ─────────────────────────────────────────────────

select t.as_user('c1000000-0000-0000-0000-000000000001');
select lives_ok($$ select public.academy_set_coach(t.id('academy'),
  (select username::text from public.profiles where id = 'c1000000-0000-0000-0000-000000000006'), true) $$, 'the head invites someone');
select throws_ok($$ select public.academy_set_coach(t.id('academy'), 'c1000000-0000-0000-0000-000000000007', true) $$,
  'No player has that username.', 'never a minor, who reads as nobody');
select t.reset();

select t.as_user('c1000000-0000-0000-0000-000000000006');
select ok(not public.academy_is_coach(t.id('academy')), 'an invitation alone makes nobody a coach');
select is((public.academy_my_coach_invites() -> 0 ->> 'name'), 'Test Academy', 'they see the invitation');
select throws_ok($$ select public.academy_roster(t.id('class')) $$, 'Only the academy''s coaches can do this.', 'and no roster');
select lives_ok($$ select public.academy_coach_answer(t.id('academy'), true) $$, 'they say yes');
select ok(public.academy_is_coach(t.id('academy')), 'and are a coach');
select throws_ok($$ select public.academy_roster(t.id('class')) $$, 'We need to verify your coaching licence first.', 'but a coach with no licence sees no children');
select throws_ok($$ select public.academy_coach_answer(t.id('academy'), true) $$, 'This invitation has ended.', 'an answer counts once');
select t.reset();

select t.as_user('c1000000-0000-0000-0000-000000000001');
select throws_ok($$ select public.academy_save_class(t.id('academy'), jsonb_build_object('name', 'New', 'weekdays', '[1]'::jsonb,
  'hour', 10, 'capacity', 4, 'coach_id', 'c1000000-0000-0000-0000-000000000006')) $$,
  'We need to verify that coach''s licence first. Save the class without a coach for now.', 'no classes before the licence (R-ACD-1)');
select lives_ok($$ select public.academy_save_class(t.id('academy'), jsonb_build_object('name', 'New', 'weekdays', '[1]'::jsonb, 'hour', 10, 'capacity', 4)) $$,
  'a class can wait for its coach');
select t.reset();

-- An expired licence stops new classes, and existing ones stay.
update public.coach_licences set expires_on = current_date - 1 where user_id = 'c1000000-0000-0000-0000-000000000002';
select t.as_user('c1000000-0000-0000-0000-000000000001');
select lives_ok($$ select public.academy_save_class(t.id('academy'), jsonb_build_object('id', t.id('class'), 'name', 'Kept', 'weekdays', '[1,2,3,4,5,6,7]'::jsonb,
  'hour', 10, 'capacity', 4, 'coach_id', 'c1000000-0000-0000-0000-000000000002')) $$, 'an expired coach keeps their class');
select throws_ok($$ select public.academy_save_class(t.id('academy'), jsonb_build_object('name', 'Other', 'weekdays', '[1]'::jsonb,
  'hour', 10, 'capacity', 4, 'coach_id', 'c1000000-0000-0000-0000-000000000002')) $$,
  'We need to verify that coach''s licence first. Save the class without a coach for now.', 'and gets no new one');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000002');
select lives_ok($$ select public.academy_roster(t.id('class')) $$, 'and still sees their roster');
select t.reset();
update public.coach_licences set expires_on = current_date + 300 where user_id = 'c1000000-0000-0000-0000-000000000002';

-- ─── Coach pages ───────────────────────────────────────────────────────────

select t.as_user('c1000000-0000-0000-0000-000000000002');
select lives_ok($$ select public.coach_profile_save('Junior specialist', 'Ten years with beginners.', 10) $$, 'a coach writes their page');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000006');
select is(public.coach_profile_get('c1000000-0000-0000-0000-000000000002') ->> 'headline', 'Junior specialist', 'anyone signed in reads it');
select throws_ok($$ select public.coach_profile_get('c1000000-0000-0000-0000-000000000006') $$, 'This coach isn''t listed.', 'not an unlicensed coach');
select throws_ok($$ select public.coach_profile_get('c1000000-0000-0000-0000-000000000007') $$, 'This coach isn''t listed.', 'nor a minor');
select t.reset();
insert into public.blocks (blocker_id, blocked_id) values ('c1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-00000000000b');
select t.as_user('c1000000-0000-0000-0000-00000000000b');
select throws_ok($$ select public.coach_profile_get('c1000000-0000-0000-0000-000000000002') $$, 'This coach isn''t listed.', 'nor to someone they blocked');
select t.reset();
delete from public.blocks where blocker_id = 'c1000000-0000-0000-0000-000000000002';

-- ─── Students are real accounts ────────────────────────────────────────────

select t.as_user('c1000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.academy_request(t.id('class'), 'c1000000-0000-0000-0000-000000000005', '', null) $$,
  'You can enrol yourself or a child linked to your account.', 'nobody enrols a stranger''s child');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000005');
select throws_ok($$ select public.academy_request(t.id('class'), 'c1000000-0000-0000-0000-000000000005', '', null) $$,
  'A parent needs to do this for you.', 'a child can''t enrol themself');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000004');
select is((select count(*) from jsonb_array_elements(public.academy_my_players())), 2::bigint, 'a parent can enrol themself or their child');
select lives_ok($$ select public.academy_request(t.id('class'), 'c1000000-0000-0000-0000-000000000005', 'Hello', null) $$, 'a parent asks for a linked child');
select throws_ok($$ select public.academy_request(t.id('class'), 'c1000000-0000-0000-0000-000000000005', '', null) $$,
  'You''ve already asked for this class.', 'once');
select t.reset();
select is((select age from public.academy_requests where player_id = 'c1000000-0000-0000-0000-000000000005'), 12, 'the age comes from the server');
select t.as_user('c1000000-0000-0000-0000-00000000000a');
select lives_ok($$ select public.academy_request(t.id('class'), auth.uid(), '', null) $$, 'an adult enrols themself');
select t.reset();

insert into public.blocks (blocker_id, blocked_id) values ('c1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000006');
select t.as_user('c1000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.academy_request(t.id('class'), auth.uid(), '', null) $$, 'This class isn''t available.', 'a block keeps them apart');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.academy_request((select id from public.academy_classes where academy_id = t.id('waiting') limit 1), auth.uid(), '', null) $$,
  'This class no longer runs.', 'a missing class is refused');
select t.reset();

insert into ids select 'request', id from public.academy_requests where player_id = 'c1000000-0000-0000-0000-000000000005';
select t.as_user('c1000000-0000-0000-0000-000000000002');
select lives_ok($$ select public.academy_decide(t.id('request'), 'accepted') $$, 'a coach accepts');
select t.reset();
insert into ids select 'child_student', id from public.academy_students where player_id = 'c1000000-0000-0000-0000-000000000005';

select t.as_user('c1000000-0000-0000-0000-000000000005');
select is(public.academy_student(t.id('child_student')) ->> 'can_act', 'false', 'the child reads their own page and can''t act on it');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000004');
select is(public.academy_student(t.id('child_student')) ->> 'can_act', 'true', 'their parent can');
select is(public.academy_get(t.id('academy')) ->> 'my_role', 'parent', 'and is a parent there');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.academy_student(t.id('child_student')) $$, 'This student has left.', 'a stranger reads nothing');
select t.reset();

-- ─── Make-up credits (R-ACD-3) ─────────────────────────────────────────────

create function t.credits(p_student uuid) returns int language sql security definer as $$
  select (public.academy_student_json(p_student) ->> 'makeup_credits')::int;
$$;

select is(t.credits(t.id('child_student')), 0, 'no credits to start');
select t.as_user('c1000000-0000-0000-0000-000000000002');
select is(public.academy_change_class(t.id('class'), 'cancel', 'Rain stopped play', null), 1, 'a cancelled class tells the parent');
select public.academy_change_class(t.id('class'), 'cancel', 'Still cancelled', null);
select t.reset();
select is(t.credits(t.id('child_student')), 1, 'and gives one credit, once');

select t.as_user('c1000000-0000-0000-0000-000000000004');
select lives_ok($$ select public.academy_answer_notice(t.id('child_student'), false) $$, 'Can''t make it');
select lives_ok($$ select public.academy_answer_notice(t.id('child_student'), false) $$, 'tapped twice');
select t.reset();
select is(t.credits(t.id('child_student')), 2, 'gives one more, once');

select t.as_user('c1000000-0000-0000-0000-000000000004');
select throws_ok($$ select public.academy_book_makeup(t.id('child_student'), t.id('next_level'), t.class_at(3)) $$,
  'Make-ups are for classes at the same level.', 'same level only');
select throws_ok($$ select public.academy_book_makeup(t.id('child_student'), t.id('same_level'), t.class_at(3) + interval '1 hour') $$,
  'This class doesn''t run then.', 'only when the class runs');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.academy_book_makeup(t.id('child_student'), t.id('same_level'), t.class_at(3)) $$,
  'This student has left.', 'only for your own child');
select t.reset();

-- Exactly 24 hours is enough; a minute less isn't.
update public.academy_classes set weekdays = '{1,2,3,4,5,6,7}',
  hour = extract(hour from (now() + interval '24 hours') at time zone 'Asia/Singapore')::int,
  minute = extract(minute from (now() + interval '24 hours') at time zone 'Asia/Singapore')::int
where id = t.id('same_level');
select t.as_user('c1000000-0000-0000-0000-000000000004');
select throws_ok($$ select public.academy_book_makeup(t.id('child_student'), t.id('same_level'),
  date_trunc('minute', now() + interval '23 hours 59 minutes') ) $$, null, null, 'inside 24 hours is refused');
select t.reset();
update public.academy_classes set hour = 10, minute = 0 where id = t.id('same_level');

select t.as_user('c1000000-0000-0000-0000-000000000004');
select ok((select count(*) from jsonb_array_elements(public.academy_makeup_slots(t.id('child_student')))) > 0, 'slots are offered');
select is_empty($$ select 1 from jsonb_array_elements(public.academy_makeup_slots(t.id('child_student'))) x
  where (x ->> 'at')::timestamptz < now() + interval '24 hours' $$, 'none inside 24 hours');
select is_empty($$ select 1 from jsonb_array_elements(public.academy_makeup_slots(t.id('child_student'))) x
  where (x ->> 'class_id')::uuid = t.id('next_level') $$, 'none at another level');
select ok(exists (select 1 from jsonb_array_elements(public.academy_makeup_slots(t.id('child_student'))) x
  where (x ->> 'class_id')::uuid = t.id('same_level') and (x ->> 'at')::timestamptz = t.class_at(3)), 'slots are at the class''s real time');
select lives_ok($$ select public.academy_book_makeup(t.id('child_student'), t.id('same_level'), t.class_at(3)) $$, 'a make-up books');
select throws_ok($$ select public.academy_book_makeup(t.id('child_student'), t.id('same_level'), t.class_at(3)) $$,
  'This make-up is already booked.', 'once');
select t.reset();
select is(t.credits(t.id('child_student')), 1, 'and spends one credit');
select is(private.class_taken(t.id('same_level'), t.class_at(3)), 1, 'and takes a place');

-- A full class has no room for a make-up.
insert into ids select 'other_student', t.student(t.id('same_level'), 'c1000000-0000-0000-0000-00000000000a', 'c1000000-0000-0000-0000-00000000000a');
update public.academy_classes set capacity = 1 where id = t.id('same_level');
select t.as_user('c1000000-0000-0000-0000-000000000004');
select throws_ok($$ select public.academy_book_makeup(t.id('child_student'), t.id('same_level'), t.class_at(4)) $$,
  'This class is full.', 'a full class says no');
select t.reset();
update public.academy_classes set capacity = 4 where id = t.id('same_level');

-- The monthly limit the academy set.
update public.academies set makeups_per_month = 0 where id = t.id('academy');
select t.as_user('c1000000-0000-0000-0000-000000000004');
select throws_ok($$ select public.academy_book_makeup(t.id('child_student'), t.id('same_level'), t.class_at(4)) $$,
  'This academy allows 0 make-ups a month.', 'the academy''s monthly limit holds');
select t.reset();
update public.academies set makeups_per_month = 8 where id = t.id('academy');

-- An expired credit doesn't count.
update public.academy_makeup_credits set expires_on = current_date - 1 where student_id = t.id('child_student');
select is(t.credits(t.id('child_student')), 0, 'expired credits don''t show');
select t.as_user('c1000000-0000-0000-0000-000000000004');
select throws_ok($$ select public.academy_book_makeup(t.id('child_student'), t.id('same_level'), t.class_at(5)) $$,
  'No make-up credits left.', 'and can''t be spent');
select t.reset();

-- ─── A revoked link ends a parent's access ─────────────────────────────────

update public.guardian_links set status = 'revoked' where id = t.id('link');
select t.as_user('c1000000-0000-0000-0000-000000000004');
select throws_ok($$ select public.academy_student(t.id('child_student')) $$, 'This student has left.', 'the parent can no longer read them');
select throws_ok($$ select public.academy_filming(t.id('child_student'), true) $$, 'Only the parent can change this.', 'or act for them');
select t.reset();
update public.guardian_links set status = 'approved' where id = t.id('link');

-- ─── Restricted and suspended accounts ─────────────────────────────────────

create function t.gate(p_user uuid, p_path text) returns void language plpgsql as $$
begin
  perform t.as_user(p_user);
  perform set_config('request.path', p_path, true);
  perform set_config('request.method', 'POST', true);
  perform private.gate_request();
end;
$$;

select throws_ok($$ select t.gate('c1000000-0000-0000-0000-00000000000b', '/rpc/academy_list') $$, null, null, 'an unlinked under-13 can''t reach academies');
select t.reset();
insert into public.account_moderation (user_id, suspended_until) values ('c1000000-0000-0000-0000-000000000006', now() + interval '1 day');
select throws_ok($$ select t.gate('c1000000-0000-0000-0000-000000000006', '/rpc/academy_request') $$, null, null, 'a suspended player can''t ask to enrol');
select t.reset();

-- ─── Closing keeps the records ─────────────────────────────────────────────

select t.as_user('c1000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.academy_close(t.id('academy')) $$, 'Only the head coach can do this.', 'only the head coach closes');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000001');
select lives_ok($$ select public.academy_close(t.id('academy')) $$, 'the head coach closes it');
select t.reset();
select is((select count(*) from public.academy_students where id = t.id('child_student')), 1::bigint, 'the student''s record stays');
select t.as_user('c1000000-0000-0000-0000-000000000002');
select ok(not public.academy_is_coach(t.id('academy')), 'nobody coaches at a closed academy');
select t.reset();
select t.as_user('c1000000-0000-0000-0000-000000000006');
select throws_ok($$ select public.academy_get(t.id('academy')) $$, 'This academy is no longer listed.', 'it isn''t listed');
select t.reset();

select * from finish();
rollback;
