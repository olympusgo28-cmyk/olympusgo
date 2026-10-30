begin;
\ir helpers/setup.psql
select no_plan();

select t.player('d1000000-0000-0000-0000-000000000001');
select t.player('d1000000-0000-0000-0000-000000000002');
select t.player('d1000000-0000-0000-0000-000000000003');
select t.player('d1000000-0000-0000-0000-000000000004');
insert into public.player_sports (user_id, sport, level, play_min, play_max) values
  ('d1000000-0000-0000-0000-000000000001', 'badminton', 4, 3, 5),
  ('d1000000-0000-0000-0000-000000000002', 'badminton', 4, 3, 5),
  ('d1000000-0000-0000-0000-000000000003', 'badminton', 5, 3, 6);

-- Validation.
select is(private.game_winner(30, 29, '{"points_to_win":21,"win_by":2,"cap":30}'), 1, 'P3-03 30-29 is valid');
select is(private.game_winner(22, 20, '{"points_to_win":21,"win_by":2,"cap":30}'), 1, 'P3-03 22-20 is valid in a game to 21');
select is(private.game_winner(22, 21, '{"points_to_win":21,"win_by":2,"cap":30}'), -1, 'P3-03 22-21 is invalid');
select is(private.game_winner(11, 5, '{"points_to_win":11,"win_by":2}'), 1, 'P3-01 pickleball 11-5 is valid');
select is(private.game_winner(21, 5, '{"points_to_win":11,"win_by":2}'), -1, 'pickleball 21-5 is not');
select is(private.match_winner('[[21,10],[21,10]]', '{"points_to_win":21,"win_by":2,"cap":30,"best_of":3}'), 1, 'two games win a match');
select is(private.match_winner('[[21,10],[21,10],[21,10]]', '{"points_to_win":21,"win_by":2,"cap":30,"best_of":3}'), 0, 'no game after it is won');
select is(private.match_winner('[[21,10],[10,21]]', '{"points_to_win":21,"win_by":2,"cap":30,"best_of":3}'), 0, 'a split needs a decider');

create temp table m on commit drop as select t.meet('d1000000-0000-0000-0000-000000000004') as id;
grant select on m to authenticated;
update public.activities set ranked = true where id = (select id from m);
insert into public.activity_participants (activity_id, user_id, status, attendance)
select (select id from m), ('d1000000-0000-0000-0000-00000000000' || i)::uuid, 'joined', 'present' from generate_series(1, 3) i;
select t.start_meet((select id from m));
update public.activities set starts_at = now() - interval '1 hour' where id = (select id from m);

select t.as_user('d1000000-0000-0000-0000-000000000001');
select throws_ok(format($q$select public.submit_score(%L, '{}', '{d1000000-0000-0000-0000-000000000002}', '[[22,21],[21,10]]')$q$, (select id from m)),
  'P0001', 'That score can''t stand. Check each game.', 'P3-03 the database refuses an impossible score');
select throws_ok(format($q$select public.submit_score(%L, '{d1000000-0000-0000-0000-000000000003}', '{d1000000-0000-0000-0000-000000000002}', '[[21,10],[21,10]]')$q$, (select id from m)),
  'P0001', 'Both sides need the same number of players.', 'sides must match');
create temp table s on commit drop as
  select public.submit_score((select id from m), '{}', '{d1000000-0000-0000-0000-000000000002}', '[[21,10],[21,12]]', 'd1000000-0000-0000-0000-0000000000aa') as id;
grant select on s to authenticated;
select is(public.submit_score((select id from m), '{}', '{d1000000-0000-0000-0000-000000000002}', '[[21,10],[21,12]]', 'd1000000-0000-0000-0000-0000000000aa'),
  (select id from s), 'a retry finds the same score');
select t.reset();

select is_empty($$select 1 from public.rating_events where user_id::text like 'd1000000%'$$, 'P3-04 nothing moves until the other side confirms');

select t.as_user('d1000000-0000-0000-0000-000000000002');
select public.answer_score((select id from s), true);
select t.reset();

-- Equal players: 1500 each, K 32, delta 16.
select is((select rating from public.ratings where user_id = 'd1000000-0000-0000-0000-000000000001' and sport = 'badminton'), 1516.00, 'P3-04 the winner gains');
select is((select rating from public.ratings where user_id = 'd1000000-0000-0000-0000-000000000002' and sport = 'badminton'), 1484.00, 'P3-04 the loser loses the same');
select is((select sum(delta) from public.rating_events where user_id::text like 'd1000000%'), 0.00, 'P3-04 deltas sum to zero for equal K');
select is((select level from public.player_sports where user_id = 'd1000000-0000-0000-0000-000000000001' and sport = 'badminton'), 4.2, 'level follows the rating');

-- Clients cannot move it.
select t.as_user('d1000000-0000-0000-0000-000000000001');
select throws_ok($$update public.ratings set rating = 9000$$, '42501', null, 'P3-04 a player cannot write a rating');
update public.player_sports set level = 8 where user_id = 'd1000000-0000-0000-0000-000000000001';
select t.reset();
select is((select level from public.player_sports where user_id = 'd1000000-0000-0000-0000-000000000001' and sport = 'badminton'), 4.2, 'a level with a rating cannot be set by hand');

-- Immutable.
select throws_ok($$delete from public.match_results$$, 'P0001', 'match_results is append-only', 'R-SCO-3 a result cannot be deleted');
select throws_ok($$update public.match_results set winner = 2$$, 'P0001', 'match_results is append-only', 'R-SCO-3 a result cannot be changed');

-- Repeat match counts less.
select t.as_user('d1000000-0000-0000-0000-000000000001');
create temp table s2 on commit drop as
  select public.submit_score((select id from m), '{}', '{d1000000-0000-0000-0000-000000000002}', '[[21,10],[21,12]]') as id;
grant select on s2 to authenticated;
select t.reset();
select t.as_user('d1000000-0000-0000-0000-000000000002');
select public.answer_score((select id from s2), true);
select t.reset();
select cmp_ok((select abs(delta) from public.rating_events order by id desc limit 1), '<', 16.00, 'R-RAT-5 a repeat match counts less');

-- Absent players do not move.
create temp table a on commit drop as select t.meet('d1000000-0000-0000-0000-000000000004') as id;
grant select on a to authenticated;
update public.activities set ranked = true, starts_at = now() - interval '1 hour' where id = (select id from a);
insert into public.activity_participants (activity_id, user_id, status, attendance) values
  ((select id from a), 'd1000000-0000-0000-0000-000000000001', 'joined', 'present'),
  ((select id from a), 'd1000000-0000-0000-0000-000000000003', 'joined', null);
select t.as_user('d1000000-0000-0000-0000-000000000001');
create temp table s3 on commit drop as
  select public.submit_score((select id from a), '{}', '{d1000000-0000-0000-0000-000000000003}', '[[21,10],[21,12]]') as id;
grant select on s3 to authenticated;
select t.reset();
select t.as_user('d1000000-0000-0000-0000-000000000003');
select public.answer_score((select id from s3), true);
select t.reset();
select is((select count(*)::int from public.match_results where score_id = (select id from s3)), 1, 'the result still stands');
select is((select count(*)::int from public.rating_events where result_id = (select id from public.match_results where score_id = (select id from s3))), 0, 'P3-04 only attended players are rated');

-- Expiry and the organiser.
insert into public.match_scores (activity_id, entered_by, side_a, side_b, games, created_at)
  values ((select id from a), 'd1000000-0000-0000-0000-000000000001', '{d1000000-0000-0000-0000-000000000001}', '{d1000000-0000-0000-0000-000000000003}', '[[21,10],[21,12]]', now() - interval '25 hours');
select private.scores_expire();
create temp table late on commit drop as
  select id from public.match_scores where status = 'disputed' and activity_id = (select id from a);
grant select on late to authenticated;
select is((select count(*)::int from public.match_scores where status = 'disputed' and activity_id = (select id from a)), 1, 'R-SCO-2 unconfirmed after 24 hours goes to the organiser');
select t.as_user('d1000000-0000-0000-0000-000000000002');
select throws_ok(format('select public.organiser_decide_score(%L)', (select id from late)),
  'P0001', 'Only the organizer can decide this.', 'only the organiser decides');
select t.reset();
select t.as_user('d1000000-0000-0000-0000-000000000004');
select lives_ok(format('select public.organiser_decide_score(%L)', (select id from late)), 'the organiser decides');
select t.reset();



-- Attendance saved after the score still rates it.
update public.activity_participants set attendance = 'present'
  where activity_id = (select id from a) and user_id = 'd1000000-0000-0000-0000-000000000003';
select is((select count(*)::int from public.rating_events where result_id = (select id from public.match_results where score_id = (select id from s3))), 2,
  'P3-04 a result is rated once attendance arrives');

-- R-RAT-3: a self-placed level never seeds above AD.
select t.player('d1000000-0000-0000-0000-000000000005');
insert into public.player_sports (user_id, sport, level, play_min, play_max)
  values ('d1000000-0000-0000-0000-000000000005', 'badminton', 8, 3, 8);
select is((private.rating_row('d1000000-0000-0000-0000-000000000005', 'badminton')).rating, 1800.00, 'R-RAT-3 PRO cannot be self-chosen');

-- Clients are refused.
select t.as_anon();
select throws_ok($$select * from public.ratings$$, '42501', null, 'signed out: no ratings');
select throws_ok($$select * from public.rating_events$$, '42501', null, 'signed out: no rating history');
select throws_ok($$select * from public.match_results$$, '42501', null, 'signed out: no results');
select t.reset();

select t.as_user('d1000000-0000-0000-0000-000000000005');
select is_empty($$select 1 from public.match_results$$, 'an outsider sees no results');
select is_empty($$select 1 from public.rating_events$$, 'an outsider sees no rating history');
select throws_ok($$select private.rating_write(gen_random_uuid(), auth.uid(), 'badminton', 500, false)$$, '42501', null, 'rating helpers cannot be called');
select t.reset();

-- Tournament rules.
create temp table k on commit drop as select t.meet('d1000000-0000-0000-0000-000000000004', p_game => 'singles') as id;
grant select on k to authenticated;
update public.activities set kind = 'tournament', format = 'knockout', ranked = false where id = (select id from k);
insert into public.tournament_entries (activity_id, division, user_id) values
  ((select id from k), 'main', 'd1000000-0000-0000-0000-000000000001'),
  ((select id from k), 'main', 'd1000000-0000-0000-0000-000000000002');
select t.as_user('d1000000-0000-0000-0000-000000000004');
select public.tournament_make_draw((select id from k), 'main');
select t.reset();
create temp table g on commit drop as
  select id from public.tournament_matches where activity_id = (select id from k) limit 1;
grant select on g to authenticated;
select t.as_user('d1000000-0000-0000-0000-000000000004');
select throws_ok(format($q$select public.tournament_score(%L, '[[22,21],[21,10]]')$q$, (select id from g)),
  'P0001', 'That score can''t stand. Check each game.', 'P3-03 a tournament score is checked too');
select lives_ok(format($q$select public.tournament_score(%L, '[[21,10],[21,12]]')$q$, (select id from g)), 'a good score stands');
select t.reset();
create temp table before on commit drop as
  select user_id, rating from public.ratings where user_id in ('d1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000002');
create temp table first_score on commit drop as
  select score_id as id from public.tournament_matches where id = (select id from g);
select cmp_ok((select count(*)::int from public.rating_events where result_id = (select id from public.match_results where score_id = (select id from first_score))), '=', 2, 'R-RAT-1 every tournament match is ranked');

select t.as_user('d1000000-0000-0000-0000-000000000004');
select throws_ok(format($q$select public.tournament_score(%L, '[[10,21],[12,21]]')$q$, (select id from g)),
  'P0001', 'Say why this result is changing.', 'R-SCO-3 a correction needs a reason');
select lives_ok(format($q$select public.tournament_score(%L, '[[10,21],[12,21]]', 'Scores swapped')$q$, (select id from g)), 'R-SCO-3 the organiser corrects within 24 hours');
select t.reset();
select is((select status from public.match_scores where id = (select id from first_score)), 'superseded', 'R-SCO-3 the old score stays');
select is((select count(*)::int from public.match_results where score_id = (select id from first_score)), 1, 'R-SCO-3 the old result stays');
select isnt_empty($$select 1 from public.match_results where supersedes = (select id from public.match_results where score_id = (select id from first_score))$$, 'R-SCO-3 the new result points at the old one');
select is((select count(*)::int from public.rating_events where result_id = (select id from public.match_results where score_id = (select id from first_score)) and reversal), 2, 'a correction reverses the old rating');

-- The window runs from the first decision, however many corrections follow.
update public.tournament_matches set decided_at = now() - interval '25 hours' where id = (select id from g);
select t.as_user('d1000000-0000-0000-0000-000000000004');
select throws_ok(format($q$select public.tournament_score(%L, '[[21,10],[21,12]]', 'Late')$q$, (select id from g)),
  'P0001', 'This result is too old to change here. Ask the OlympusGO team.', 'R-SCO-3 later corrections go through staff');
select t.reset();

-- Staff correct a result.
select t.player('d1000000-0000-0000-0000-000000000006');
create temp table conf on commit drop as
  select score_id as id from public.tournament_matches where id = (select id from g);
grant select on conf to authenticated;
select t.as_user('d1000000-0000-0000-0000-000000000006');
select throws_ok(format($q$select public.staff_result_correct(%L, '[[21,10],[21,12]]', 'x')$q$, (select id from conf)),
  'P0001', 'Not found.', 'a player cannot use the staff correction');
select t.reset();
insert into public.staff (user_id, role) values ('d1000000-0000-0000-0000-000000000006', 'moderator');
select t.as_staff('d1000000-0000-0000-0000-000000000006');
select throws_ok(format($q$select public.staff_result_correct(%L, '[[21,10],[21,12]]', 'Wrong way round')$q$, (select id from conf)),
  'P0001', 'The winner can''t change here because the draw has moved on.', 'staff cannot rewrite a draw');
select lives_ok(format($q$select public.staff_result_correct(%L, '[[10,21],[10,21]]', 'Wrong points')$q$, (select id from conf)), 'R-SCO-3 staff correct a later result');
select t.reset();
select is((select count(*)::int from public.admin_audit where action = 'result_correct'), 1, 'the correction is audited');

-- Retirement (R-STA-3).
create temp table r on commit drop as select t.meet('d1000000-0000-0000-0000-000000000004', p_game => 'singles') as id;
grant select on r to authenticated;
update public.activities set kind = 'tournament', format = 'knockout', ranked = false where id = (select id from r);
insert into public.tournament_entries (activity_id, division, user_id) values
  ((select id from r), 'main', 'd1000000-0000-0000-0000-000000000001'),
  ((select id from r), 'main', 'd1000000-0000-0000-0000-000000000002');
select t.as_user('d1000000-0000-0000-0000-000000000004');
select public.tournament_make_draw((select id from r), 'main');
select t.reset();
create temp table rm on commit drop as
  select id from public.tournament_matches where activity_id = (select id from r) limit 1;
grant select on rm to authenticated;
select t.as_user('d1000000-0000-0000-0000-000000000004');
select lives_ok(format($q$select public.tournament_score(%L, '[[5,5]]', null, 1::smallint)$q$, (select id from rm)),
  'R-STA-3 a retirement keeps the score so far');
select t.reset();
select is((select ranked from public.match_results where activity_id = (select id from r)), false, 'R-STA-3 no game finished, no rating');
select is((select winner::int from public.match_results where activity_id = (select id from r)), 2, 'the other side wins a retirement');

-- Organisers pick a preset before any score is in.
create temp table j on commit drop as select t.meet('d1000000-0000-0000-0000-000000000004', p_game => 'singles') as id;
grant select on j to authenticated;
select t.as_user('d1000000-0000-0000-0000-000000000001');
select throws_ok(format($q$select public.activity_preset_set(%L, 'badminton_junior_15')$q$, (select id from j)),
  'P0001', 'Only the organizer can do this.', 'only the organiser picks a preset');
select t.reset();
select t.as_user('d1000000-0000-0000-0000-000000000004');
select throws_ok(format($q$select public.activity_preset_set(%L, 'badminton_junior_11')$q$, (select id from j)),
  'P0001', 'That scoring isn''t available for this sport.', 'owner: the 11-point variant is off');
select throws_ok(format($q$select public.activity_preset_set(%L, 'pickleball_standard')$q$, (select id from j)),
  'P0001', 'That scoring isn''t available for this sport.', 'a preset must be for the sport');
select lives_ok(format($q$select public.activity_preset_set(%L, 'badminton_junior_15')$q$, (select id from j)), 'an organiser picks junior points');
select is(public.activity_scoring((select id from j)) ->> 'points_to_win', '15', 'the preset replaces the sport''s rules');
select t.reset();
insert into public.match_scores (activity_id, entered_by, side_a, side_b, games) values ((select id from j),
  'd1000000-0000-0000-0000-000000000001', '{d1000000-0000-0000-0000-000000000001}', '{d1000000-0000-0000-0000-000000000002}', '[[15,9],[15,9]]');
select t.as_user('d1000000-0000-0000-0000-000000000004');
select throws_ok(format($q$select public.activity_preset_set(%L, 'badminton_standard')$q$, (select id from j)),
  'P0001', 'Scores are in already, so the scoring can''t change.', 'scoring is fixed once scores are in');
select t.reset();

-- A-05.
select t.as_user('d1000000-0000-0000-0000-000000000001');
select throws_ok($$select public.staff_preset_save('badminton_standard', 'badminton', 'x', '{"points_to_win":5,"win_by":1,"best_of":1}', true, 'x')$$,
  'P0001', 'Not found.', 'A-05 a player cannot change a preset');
select t.reset();
insert into public.staff (user_id, role) values ('d1000000-0000-0000-0000-000000000004', 'content');
select t.as_staff('d1000000-0000-0000-0000-000000000004');
select throws_ok($$select public.staff_preset_save('badminton_standard', 'badminton', 'x', '{"points_to_win":21,"win_by":2,"cap":10,"best_of":3}', true, 'test')$$,
  'P0001', 'Those rules can''t work. Check the numbers.', 'A-05 impossible rules are refused');
select lives_ok($$select public.staff_preset_save('badminton_junior_11', 'badminton', 'Junior, 11 points', '{"points_to_win":11,"win_by":2,"cap":15,"best_of":3}', true, 'Trial')$$, 'A-05 staff turn a preset on');
select lives_ok($$select public.staff_level_save('LB', 'Low Beginner', 1.5, 'Trial')$$, 'A-05 staff change a level scale');
select t.reset();
select is((select count(*)::int from public.admin_audit where action in ('preset_save', 'level_save')), 2, 'A-05 changes are audited');

select * from finish();
rollback;
