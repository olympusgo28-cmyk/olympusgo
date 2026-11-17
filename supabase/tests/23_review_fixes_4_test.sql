begin;
\ir helpers/setup.psql
select no_plan();

select t.player(('ac000000-0000-0000-0000-00000000000' || i)::uuid) from generate_series(1, 7) i;
select t.player('ac000000-0000-0000-0000-000000000008', 14);
update public.profiles set full_name = 'Mei Lim' where id = 'ac000000-0000-0000-0000-000000000008';
update public.profiles set full_name = 'Ana Tan' where id = 'ac000000-0000-0000-0000-000000000002';
insert into public.player_sports (user_id, sport, level, play_min, play_max)
select ('ac000000-0000-0000-0000-00000000000' || i)::uuid, 'badminton', 4, 3, 5 from generate_series(1, 8) i;

create function t.ranked_meet(p_host uuid) returns uuid language plpgsql as $$
declare v uuid := t.meet(p_host, p_capacity => 12, p_game => 'singles');
begin
  update public.activities set ranked = true, starts_at = now() - interval '1 hour' where id = v;
  insert into public.activity_participants (activity_id, user_id, status, attendance)
  select v, ('ac000000-0000-0000-0000-00000000000' || i)::uuid, 'joined', 'present' from generate_series(1, 8) i;
  return v;
end;
$$;
create function t.result(p_meet uuid, p_a uuid, p_b uuid, p_games jsonb) returns uuid language plpgsql as $$
declare v uuid;
begin
  perform t.as_user(p_a);
  select public.submit_score(p_meet, '{}', array[p_b], p_games) into v;
  perform t.reset();
  perform t.as_user(p_b);
  perform public.answer_score(v, true);
  perform t.reset();
  return v;
end;
$$;
create function t.rating(p_user uuid) returns numeric language sql as $$
  select rating from public.ratings where user_id = p_user and sport = 'badminton';
$$;

create temp table m on commit drop as select t.ranked_meet('ac000000-0000-0000-0000-000000000001') as id;
grant select on m to authenticated;

-- A host can't erase their own loss.
select t.result((select id from m), 'ac000000-0000-0000-0000-000000000002', 'ac000000-0000-0000-0000-000000000001', '[[21,10],[21,12]]');
select is(t.rating('ac000000-0000-0000-0000-000000000001'), 1484.00, 'the host lost');
update public.activity_participants set attendance = 'absent'
  where activity_id = (select id from m) and user_id = 'ac000000-0000-0000-0000-000000000001';
select is(t.rating('ac000000-0000-0000-0000-000000000001'), 1484.00, 'marking themself absent changes nothing');
update public.activity_participants set attendance = 'absent'
  where activity_id = (select id from m) and user_id = 'ac000000-0000-0000-0000-000000000002';
select is(t.rating('ac000000-0000-0000-0000-000000000001'), 1484.00, 'nor marking the winner absent');
update public.activity_participants set attendance = 'present'
  where activity_id = (select id from m) and user_id in ('ac000000-0000-0000-0000-000000000001', 'ac000000-0000-0000-0000-000000000002');

-- A dispute blocks a second entry of the match.
select t.as_user('ac000000-0000-0000-0000-000000000003');
create temp table s on commit drop as
  select public.submit_score((select id from m), '{}', '{ac000000-0000-0000-0000-000000000004}', '[[21,10],[21,12]]') as id;
grant select on s to authenticated;
select t.reset();
select t.as_user('ac000000-0000-0000-0000-000000000004');
select public.answer_score((select id from s), false, 'Wrong score');
select throws_ok(format($q$select public.submit_score(%L, '{}', '{ac000000-0000-0000-0000-000000000003}', '[[21,19],[21,19]]')$q$, (select id from m)),
  'P0001', 'This match has a score already. Check your Inbox.', 'a disputed match can''t be entered again');
select t.reset();

-- A host can't reshape the Meet once it counts.
select t.as_user('ac000000-0000-0000-0000-000000000001');
update public.activities set ranked = false where id = (select id from m);
select is((select ranked from public.activity_cards where id = (select id from m)), true, 'ranked is fixed once scores are in');
select throws_ok($$insert into public.activities (kind, host_id, title, sports, game_type, format, starts_at, ends_at, venue_id, capacity)
  select 'tournament', auth.uid(), 'Backdated', '{badminton}', 'singles', 'knockout', now() - interval '1 day', now(), v.id, 8 from public.venues v limit 1$$,
  'P0001', 'Pick a time that hasn''t passed.', 'a new activity can''t start in the past');
select t.reset();
create temp table f on commit drop as select t.meet('ac000000-0000-0000-0000-000000000001', p_game => 'singles') as id;
grant select on f to authenticated;
select t.as_user('ac000000-0000-0000-0000-000000000001');
update public.activities set starts_at = now() - interval '1 hour' where id = (select id from f);
select t.reset();
select cmp_ok((select starts_at from public.activities where id = (select id from f)), '>', now(), 'a start can''t move into the past');

-- Minors stay stand-ins on scores.
select t.as_user('ac000000-0000-0000-0000-000000000005');
create temp table k on commit drop as
  select public.submit_score((select id from m), '{}',
    array[(select p.user_id from public.meet_players((select id from m)) p where p.full_name = 'Mei L.')], '[[21,10],[21,12]]') as id;
grant select on k to authenticated;
select ok(public.score_view((select id from k))::text not like '%ac000000-0000-0000-0000-000000000008%', 'a score hides a minor''s real id');
select ok(public.score_view((select id from k))::text like '%Mei L.%', 'and shows first name and initial');
select unalike(public.score_view((select id from k))::text, '%Lim%', 'never the full name');
select t.reset();
select t.as_user('ac000000-0000-0000-0000-000000000006');
select is(public.score_view((select id from k)), null, 'an outsider sees no score');
select t.reset();

-- Blocked players can't be named on a score.
insert into public.blocks (blocker_id, blocked_id) values ('ac000000-0000-0000-0000-000000000006', 'ac000000-0000-0000-0000-000000000007');
select t.as_user('ac000000-0000-0000-0000-000000000007');
select throws_ok(format($q$select public.submit_score(%L, '{}', '{ac000000-0000-0000-0000-000000000006}', '[[21,10],[21,12]]')$q$, (select id from m)),
  'P0001', 'Everyone in the match has to have played in the Meet.', 'a blocked player can''t be scored against');
select t.reset();

-- my_meet_results and meet_disputes.
select t.as_user('ac000000-0000-0000-0000-000000000002');
select is(jsonb_array_length(public.my_meet_results((select id from m))), 1, 'a player sees their own results');
select is(public.my_meet_results((select id from m)) -> 0 ->> 'won', 'true', 'and who won');
select t.reset();
select t.as_user('ac000000-0000-0000-0000-000000000001');
select is(jsonb_array_length(public.meet_disputes((select id from m))), 1, 'an organizer sees disputes to decide');
select t.reset();
select t.as_user('ac000000-0000-0000-0000-000000000002');
select is(public.meet_disputes((select id from m)), '[]'::jsonb, 'a player does not');
select t.reset();

-- Staff.
update public.match_scores set created_at = now() - interval '4 days' where id = (select id from s);
insert into public.staff (user_id, role) values ('ac000000-0000-0000-0000-000000000003', 'moderator'), ('ac000000-0000-0000-0000-000000000006', 'moderator');
select t.as_staff('ac000000-0000-0000-0000-000000000006');
select ok(public.staff_scores()::text like format('%%%s%%', (select id from s)), 'a dispute left too long reaches staff');
select t.reset();
select t.as_staff('ac000000-0000-0000-0000-000000000003');
select throws_ok(format($q$select public.staff_result_correct(%L, '[[21,1],[21,1]]', 'Mine')$q$, (select id from s)),
  'P0001', 'You played in this match, so someone else corrects it.', 'staff can''t correct their own match');
select t.reset();

-- Deleted accounts.
delete from auth.users where id = 'ac000000-0000-0000-0000-000000000004';
select t.as_user('ac000000-0000-0000-0000-000000000001');
select lives_ok(format('select public.organiser_decide_score(%L)', (select id from s)), 'a dispute can be decided after an account is deleted');
select t.reset();
select lives_ok($$update public.activity_participants set attendance = 'absent'
  where activity_id = (select id from m) and user_id = 'ac000000-0000-0000-0000-000000000003'$$, 'attendance saves after an account is deleted');

-- Tournaments: attendance doesn't apply, and a host earns no points.
create temp table g on commit drop as select t.meet('ac000000-0000-0000-0000-000000000005', p_game => 'singles') as id;
grant select on g to authenticated;
update public.activities set kind = 'tournament', format = 'knockout', ranked = false, starts_at = now() - interval '1 hour' where id = (select id from g);
insert into public.tournament_entries (activity_id, division, user_id) values
  ((select id from g), 'main', 'ac000000-0000-0000-0000-000000000005'),
  ((select id from g), 'main', 'ac000000-0000-0000-0000-000000000002');
select t.as_user('ac000000-0000-0000-0000-000000000005');
select public.tournament_make_draw((select id from g), 'main');
select t.reset();
create temp table gm on commit drop as select id from public.tournament_matches where activity_id = (select id from g) limit 1;
grant select on gm to authenticated;
select t.as_user('ac000000-0000-0000-0000-000000000005');
select public.tournament_score((select id from gm), '[[21,10],[21,12]]');
select t.reset();
select private.leaderboards_build();
select ok(not exists (select 1 from public.leaderboard_rows where board = 'points' and user_id = 'ac000000-0000-0000-0000-000000000005'), 'a host earns no points from their own draw');

create temp table h on commit drop as select t.meet('ac000000-0000-0000-0000-000000000005', p_game => 'singles') as id;
grant select on h to authenticated;
update public.activities set kind = 'tournament', format = 'knockout', ranked = false, starts_at = now() - interval '1 hour' where id = (select id from h);
insert into public.tournament_entries (activity_id, division, user_id) values
  ((select id from h), 'main', 'ac000000-0000-0000-0000-000000000006'),
  ((select id from h), 'main', 'ac000000-0000-0000-0000-000000000007');
select t.as_user('ac000000-0000-0000-0000-000000000005');
select public.tournament_make_draw((select id from h), 'main');
select t.reset();
create temp table hm on commit drop as select id from public.tournament_matches where activity_id = (select id from h) limit 1;
grant select on hm to authenticated;
select t.as_user('ac000000-0000-0000-0000-000000000005');
select public.tournament_score((select id from hm), '[[21,10],[21,12]]');
select t.reset();
select is(t.rating('ac000000-0000-0000-0000-000000000007'), 1484.00, 'a tournament match is rated');
insert into public.activity_participants (activity_id, user_id, status, attendance)
  values ((select id from h), 'ac000000-0000-0000-0000-000000000007', 'joined', 'present');
update public.activity_participants set attendance = 'absent'
  where activity_id = (select id from h) and user_id = 'ac000000-0000-0000-0000-000000000007';
select is(t.rating('ac000000-0000-0000-0000-000000000007'), 1484.00, 'attendance doesn''t touch a tournament result');

select * from finish();
rollback;
