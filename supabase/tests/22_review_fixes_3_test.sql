begin;
\ir helpers/setup.psql
select no_plan();

select t.player(('ab000000-0000-0000-0000-00000000000' || i)::uuid) from generate_series(1, 7) i;
select t.player('ab000000-0000-0000-0000-000000000008', 14);
update public.profiles set full_name = 'Mei Lim' where id = 'ab000000-0000-0000-0000-000000000008';
insert into public.player_sports (user_id, sport, level, play_min, play_max)
select ('ab000000-0000-0000-0000-00000000000' || i)::uuid, 'badminton', 4, 3, 5 from generate_series(1, 8) i;

create function t.ranked_meet(p_host uuid) returns uuid language plpgsql as $$
declare v uuid := t.meet(p_host, p_capacity => 12, p_game => 'singles');
begin
  update public.activities set ranked = true, starts_at = now() - interval '1 hour' where id = v;
  insert into public.activity_participants (activity_id, user_id, status, attendance)
  select v, ('ab000000-0000-0000-0000-00000000000' || i)::uuid, 'joined', 'present' from generate_series(1, 8) i;
  return v;
end;
$$;
create function t.ids(p_a uuid, p_b uuid) returns uuid[] language sql as $$ select array[p_a, p_b]; $$;

create temp table m on commit drop as select t.ranked_meet('ab000000-0000-0000-0000-000000000001') as id;
grant select on m to authenticated;

-- 1. An organizer can't skip the other side.
select t.as_user('ab000000-0000-0000-0000-000000000001');
create temp table s1 on commit drop as
  select public.submit_score((select id from m), '{}', '{ab000000-0000-0000-0000-000000000002}', '[[21,0],[21,0]]') as id;
grant select on s1 to authenticated;
select throws_ok(format('select public.organiser_decide_score(%L)', (select id from s1)),
  'P0001', 'This score isn''t waiting for you.', 'an unanswered score can''t be decided early');
select t.reset();
update public.match_scores set status = 'disputed' where id = (select id from s1);
select t.as_user('ab000000-0000-0000-0000-000000000001');
select throws_ok(format('select public.organiser_decide_score(%L)', (select id from s1)),
  'P0001', 'You played in this match, so the OlympusGO team decides it.', 'an organizer can''t decide their own match');
select t.reset();

-- 2 and 19. Tournaments.
create function t.tournament(p_host uuid, p_a uuid, p_b uuid, p_started boolean) returns uuid language plpgsql as $$
declare
  v uuid := t.meet(p_host, p_game => 'singles');
  r uuid;
begin
  update public.activities set kind = 'tournament', format = 'knockout', ranked = false,
    starts_at = case when p_started then now() - interval '1 hour' else starts_at end where id = v;
  insert into public.tournament_entries (activity_id, division, user_id) values (v, 'main', p_a), (v, 'main', p_b);
  perform t.as_user(p_host);
  perform public.tournament_make_draw(v, 'main');
  perform t.reset();
  select id into r from public.tournament_matches where activity_id = v limit 1;
  perform t.as_user(p_host);
  perform public.tournament_score(r, '[[21,10],[21,12]]');
  perform t.reset();
  return v;
end;
$$;
create temp table own on commit drop as select t.tournament('ab000000-0000-0000-0000-000000000003',
  'ab000000-0000-0000-0000-000000000003', 'ab000000-0000-0000-0000-000000000004', true) as id;
create temp table early on commit drop as select t.tournament('ab000000-0000-0000-0000-000000000003',
  'ab000000-0000-0000-0000-000000000005', 'ab000000-0000-0000-0000-000000000006', false) as id;
create temp table fin on commit drop as select t.tournament('ab000000-0000-0000-0000-000000000003',
  'ab000000-0000-0000-0000-000000000005', 'ab000000-0000-0000-0000-000000000006', true) as id;
grant select on fin to authenticated;
select is((select ranked from public.match_results where activity_id = (select id from own)), false, 'a host''s own tournament match is not rated');
select is((select ranked from public.match_results where activity_id = (select id from early)), false, 'a tournament that has not started is not rated');
select is((select ranked from public.match_results where activity_id = (select id from fin)), true, 'a real tournament match is rated');
select private.leaderboards_build();
select ok(exists (select 1 from public.leaderboard_rows where board = 'points' and user_id = 'ab000000-0000-0000-0000-000000000005'), 'a finished tournament earns points');

-- 5. A correction gets a full rating, not a repeat's.
create temp table fm on commit drop as select id from public.tournament_matches where activity_id = (select id from fin) limit 1;
grant select on fm to authenticated;
select t.as_user('ab000000-0000-0000-0000-000000000003');
select public.tournament_score((select id from fm), '[[10,21],[12,21]]', 'Scores swapped');
select t.reset();
select is((select delta from public.rating_events where user_id = 'ab000000-0000-0000-0000-000000000005' order by id desc limit 1), -16.00,
  'a correction is not a repeat of the result it replaces');

update public.activities set status = 'cancelled' where id = (select id from fin);
select private.leaderboards_build();
select ok(not exists (select 1 from public.leaderboard_rows where board = 'points' and user_id = 'ab000000-0000-0000-0000-000000000005'), 'a cancelled tournament earns none');

-- 3 and 11. Only ranked, live Meets.
create temp table ev on commit drop as select t.ranked_meet('ab000000-0000-0000-0000-000000000001') as id;
grant select on ev to authenticated;
update public.activities set kind = 'event' where id = (select id from ev);
select t.as_user('ab000000-0000-0000-0000-000000000002');
select throws_ok(format($q$select public.submit_score(%L, '{}', '{ab000000-0000-0000-0000-000000000003}', '[[21,10],[21,12]]')$q$, (select id from ev)),
  'P0001', 'Scores are for ranked games.', 'an event can''t take a ranked score');
select throws_ok(format($q$select public.submit_score(%L, '{}', '{ab000000-0000-0000-0000-000000000003}', '[[21,-7],[21,-200]]')$q$, (select id from m)),
  'P0001', 'That score can''t stand. Check each game.', 'negative points are refused');
select t.reset();
update public.activities set status = 'cancelled' where id = (select id from ev);
update public.activities set kind = 'meet' where id = (select id from ev);
select t.as_user('ab000000-0000-0000-0000-000000000002');
select throws_ok(format($q$select public.submit_score(%L, '{}', '{ab000000-0000-0000-0000-000000000003}', '[[21,10],[21,12]]')$q$, (select id from ev)),
  'P0001', 'This Meet was cancelled.', 'a cancelled Meet takes no scores');

-- 4 and 14. One match, one score; a key means one score.
create temp table s4 on commit drop as
  select public.submit_score((select id from m), '{}', '{ab000000-0000-0000-0000-000000000003}', '[[21,10],[21,12]]', 'ab000000-0000-0000-0000-0000000000aa') as id;
grant select on s4 to authenticated;
select throws_ok(format($q$select public.submit_score(%L, '{}', '{ab000000-0000-0000-0000-000000000003}', '[[21,5],[21,5]]', 'ab000000-0000-0000-0000-0000000000aa')$q$, (select id from m)),
  'P0001', 'This score was sent already.', 'a key can''t stand for a different score');
select t.reset();
select t.as_user('ab000000-0000-0000-0000-000000000003');
select throws_ok(format($q$select public.submit_score(%L, '{}', '{ab000000-0000-0000-0000-000000000002}', '[[10,21],[12,21]]')$q$, (select id from m)),
  'P0001', 'This match has a score already. Check your Inbox.', 'the other side can''t enter the same match');
select public.answer_score((select id from s4), true);
select throws_ok(format($q$select public.submit_score(%L, '{}', '{ab000000-0000-0000-0000-000000000002}', '[[10,21],[12,21]]')$q$, (select id from m)),
  'P0001', 'This match has a score already. Check your Inbox.', 'nor after it is confirmed');
select t.reset();

-- 9. Taking attendance away takes the rating back.
select is((select rating from public.ratings where user_id = 'ab000000-0000-0000-0000-000000000002' and sport = 'badminton'), 1516.00, 'the winner moved');
update public.activity_participants set attendance = 'absent'
  where activity_id = (select id from m) and user_id = 'ab000000-0000-0000-0000-000000000003';
select is((select rating from public.ratings where user_id = 'ab000000-0000-0000-0000-000000000002' and sport = 'badminton'), 1500.00, 'absent takes it back');
select is((select matches from public.ratings where user_id = 'ab000000-0000-0000-0000-000000000002' and sport = 'badminton'), 0, 'and the match stops counting');
select t.as_user('ab000000-0000-0000-0000-000000000002');
select is(public.my_rating_change((select id from m), (select id from s4)), null, 'my_rating_change hides a reversed result');
select t.reset();
update public.activity_participants set attendance = 'present'
  where activity_id = (select id from m) and user_id = 'ab000000-0000-0000-0000-000000000003';

-- 6 and 7. Rounds and scores with a minor.
select t.as_user('ab000000-0000-0000-0000-000000000001');
select public.meet_rounds_save((select id from m), 1, jsonb_build_array(jsonb_build_object('number', 1, 'byes', '[]'::jsonb, 'matches',
  jsonb_build_array(jsonb_build_object('court', 1, 'side_a', '["ab000000-0000-0000-0000-000000000008"]'::jsonb, 'side_b', '["ab000000-0000-0000-0000-000000000004"]'::jsonb)))));
select ok(public.meet_rounds((select id from m))::text like '%ab000000-0000-0000-0000-000000000008%', 'the organizer sees the real id');
select throws_ok(format($q$select public.meet_rounds_save(%L, 1, '[{"number":1,"byes":[],"matches":[{"court":1,"side_a":["ab000000-0000-0000-0000-000000000009"],"side_b":["ab000000-0000-0000-0000-000000000004"]}]}]')$q$, (select id from m)),
  'P0001', 'Everyone in a round has to be on the Meet.', 'rounds only hold players on the Meet');
select t.reset();

select t.as_user('ab000000-0000-0000-0000-000000000004');
select ok(public.meet_rounds((select id from m))::text not like '%ab000000-0000-0000-0000-000000000008%', 'a minor''s real id stays hidden in rounds');
select is(public.meet_rounds((select id from m)) -> 0 -> 'side_a' ->> 0,
  (select p.user_id::text from public.meet_players((select id from m)) p where p.full_name = 'Mei L.'), 'rounds use the roster''s stand-in');
create temp table s7 on commit drop as
  select public.submit_score((select id from m), '{}', array[(select p.user_id from public.meet_players((select id from m)) p where p.full_name = 'Mei L.')], '[[21,10],[21,12]]') as id;
select t.reset();
select is((select side_b[1] from public.match_scores where id = (select id from s7)), 'ab000000-0000-0000-0000-000000000008'::uuid, 'a score against a minor saves the real player');

select t.player('ab000000-0000-0000-0000-000000000009');
insert into public.activity_participants (activity_id, user_id, status)
  values ((select id from m), 'ab000000-0000-0000-0000-000000000009', 'requested');
select t.as_user('ab000000-0000-0000-0000-000000000009');
select is(public.meet_rounds((select id from m)), '[]'::jsonb, 'a player only requesting a spot sees no rounds');
select is(public.meet_rounds((select id from fin)), '[]'::jsonb, 'an outsider sees no rounds');
select t.reset();

-- 13. A new partner doesn't reset the repeat count.
create temp table d on commit drop as select t.ranked_meet('ab000000-0000-0000-0000-000000000001') as id;
grant select on d to authenticated;
update public.activities set game_type = 'doubles' where id = (select id from d);
create function t.play(p_mate uuid, p_score jsonb) returns void language plpgsql as $$
declare v uuid;
begin
  perform t.as_user('ab000000-0000-0000-0000-000000000005');
  select public.submit_score((select id from d), array[p_mate], array[
    'ab000000-0000-0000-0000-000000000006', 'ab000000-0000-0000-0000-000000000007']::uuid[], p_score) into v;
  perform t.reset();
  perform t.as_user('ab000000-0000-0000-0000-000000000006');
  perform public.answer_score(v, true);
  perform t.reset();
end;
$$;
select t.play('ab000000-0000-0000-0000-000000000002', '[[21,10],[21,12]]');
create temp table d1 on commit drop as
  select abs(delta) as x from public.rating_events where user_id = 'ab000000-0000-0000-0000-000000000006' order by id desc limit 1;
select t.play('ab000000-0000-0000-0000-000000000003', '[[21,11],[21,12]]');
select cmp_ok((select abs(delta) from public.rating_events where user_id = 'ab000000-0000-0000-0000-000000000006' order by id desc limit 1),
  '<', (select x from d1), 'R-RAT-5 the same opponent counts less with a new partner');

-- 16. Deleting an account after a correction.
insert into public.staff (user_id, role) values ('ab000000-0000-0000-0000-000000000004', 'moderator');
create temp table c on commit drop as select id from public.match_scores where activity_id = (select id from d) and status = 'confirmed' limit 1;
grant select on c to authenticated;
select t.as_staff('ab000000-0000-0000-0000-000000000004');
select lives_ok(format($q$select public.staff_result_correct(%L, '[[21,1],[21,1]]', 'Typed wrong')$q$, (select id from c)), 'staff correct a Meet result');
select isnt_empty($$select public.staff_scores()$$, 'staff can list what needs them');
select t.reset();
select ok(exists (select 1 from public.match_scores where status = 'disputed' and id = (select id from s1)), 'an organizer''s own dispute waits for staff');

-- 17. A score keeps its rules if a preset changes.
create temp table j on commit drop as select t.ranked_meet('ab000000-0000-0000-0000-000000000001') as id;
grant select on j to authenticated;
insert into public.activity_presets (activity_id, preset) values ((select id from j), 'badminton_junior_15');
select t.as_user('ab000000-0000-0000-0000-000000000002');
create temp table s17 on commit drop as
  select public.submit_score((select id from j), '{}', '{ab000000-0000-0000-0000-000000000004}', '[[15,9],[15,9]]') as id;
grant select on s17 to authenticated;
select t.reset();
update public.scoring_presets set rules = rules || '{"points_to_win": 11, "cap": 15}' where key = 'badminton_junior_15';
select t.as_user('ab000000-0000-0000-0000-000000000004');
select lives_ok(format('select public.answer_score(%L, true)', (select id from s17)), 'a preset change can''t strand a waiting score');
select t.reset();
select throws_ok($$select public.staff_preset_save('badminton_standard', 'badminton', 'x', '{"points_to_win":21,"win_by":2,"best_of":5}', true, 'test')$$,
  'P0001', 'Not found.', 'staff only');

-- 10. Hidden players stay off the board.
insert into public.ratings (user_id, sport, rating, matches) values
  ('ab000000-0000-0000-0000-000000000009', 'pickleball', 2100, 3),
  ('ab000000-0000-0000-0000-000000000006', 'pickleball', 2000, 3);
select private.leaderboards_build();
select ok(exists (select 1 from public.leaderboard_rows where board = 'rating' and sport = 'pickleball' and user_id = 'ab000000-0000-0000-0000-000000000009'), 'a visible player is listed');
update public.profiles set visibility = 'only_me' where id = 'ab000000-0000-0000-0000-000000000009';
update public.profiles set hidden_at = now() where id = 'ab000000-0000-0000-0000-000000000006';
select private.leaderboards_build();
select is_empty($$select 1 from public.leaderboard_rows where board = 'rating' and sport = 'pickleball' and user_id::text like 'ab000000%'$$, 'only-me and hidden players are not');

-- 12. Levels.
select is(private.level_of(9000), 7.9, 'R-RAT-3 a rating alone never reaches PRO');
select t.as_user('ab000000-0000-0000-0000-000000000009');
insert into public.player_sports (user_id, sport, level, play_min, play_max) values (auth.uid(), 'badminton', 7.3, 1, 8);
select is((select level from public.player_sports where user_id = auth.uid() and sport = 'badminton'), 7.0, 'a chosen level stops at AD, in half steps');
select t.reset();

-- 18. Consent ends with the link.
insert into public.guardian_links (parent_id, child_id, status) values
  ('ab000000-0000-0000-0000-000000000002', 'ab000000-0000-0000-0000-000000000008', 'approved');
select t.as_user('ab000000-0000-0000-0000-000000000002');
select public.guardian_leaderboard_set('ab000000-0000-0000-0000-000000000008', true);
select t.reset();
update public.guardian_links set status = 'ended' where child_id = 'ab000000-0000-0000-0000-000000000008';
select is_empty($$select 1 from public.leaderboard_consents where child_id = 'ab000000-0000-0000-0000-000000000008'$$, 'a consent ends with the link');

-- Suspensions show at read time.
select ok(private.listable('ab000000-0000-0000-0000-000000000002'), 'a player is listable');
insert into public.account_moderation (user_id, suspended_until) values ('ab000000-0000-0000-0000-000000000002', now() + interval '1 day');
select ok(not private.listable('ab000000-0000-0000-0000-000000000002'), 'a suspended player is not');

select lives_ok($$delete from auth.users where id = 'ab000000-0000-0000-0000-000000000005'$$, 'an account can be deleted after a correction');

select * from finish();
rollback;
