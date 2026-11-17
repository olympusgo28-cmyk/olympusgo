begin;
\ir helpers/setup.psql
select plan(12);

select t.player('a1000000-0000-0000-0000-000000000001');
select t.player('a1000000-0000-0000-0000-000000000002');

-- Counted-game rule.

-- Ranking.
insert into public.clubs (id, owner_id, name, area, sports, visibility) values
  ('a1000000-0000-0000-0000-0000000000c1', 'a1000000-0000-0000-0000-000000000001', 'Busy club', 'Bishan', '["badminton"]', 'public');
create temp table g on commit drop as select t.meet('a1000000-0000-0000-0000-000000000001', p_capacity => 10) as id;
alter table public.activities disable trigger activities_club_check;
update public.activities set club_id = 'a1000000-0000-0000-0000-0000000000c1' where id = (select id from g);
insert into public.organizer_games (activity_id, host_id, counted, reason, present, game_no)
select id, 'a1000000-0000-0000-0000-000000000001', true, 'counted', 6, 1 from g;
select t.as_user('a1000000-0000-0000-0000-000000000002');
select is(public.group_activity_rank() -> 0 ->> 'name', 'Busy club', 'P2-04 a group with a counted game is ranked');
select is((public.group_activity_rank() -> 0 ->> 'games')::int, 1, 'with its count');
select ok(public.group_activity_rank()::text not like '%player%', 'P2-04 no player appears in a ranking');
select t.reset();

-- Chat.
select t.as_user('a1000000-0000-0000-0000-000000000001');
create temp table conv on commit drop as
  select public.open_direct_conversation('a1000000-0000-0000-0000-000000000002') as id;
grant select on conv to authenticated;
insert into public.messages (conversation_id, sender_id, body, client_id) values
  ((select id from conv), 'a1000000-0000-0000-0000-000000000001', 'Hello', 'a1000000-0000-0000-0000-0000000000aa');
select throws_ok(format($q$insert into public.messages (conversation_id, sender_id, body, client_id) values
  (%L, 'a1000000-0000-0000-0000-000000000001', 'Hello', 'a1000000-0000-0000-0000-0000000000aa')$q$, (select id from conv)),
  '23505', null, 'P2-05 a retry cannot post twice');
select t.reset();

select t.as_user('a1000000-0000-0000-0000-000000000002');
select throws_ok(format('select public.message_delete(%s)', (select id from public.messages limit 1)),
  'P0001', 'You can only delete your own messages.', 'nobody deletes someone else''s message');
select t.reset();

select t.as_user('a1000000-0000-0000-0000-000000000001');
select public.message_delete((select id from public.messages limit 1));
select is((select body from public.messages limit 1), 'Message deleted', 'P2-05 a deleted message is gone from the thread');
select t.reset();
select is((select body from public.message_archive limit 1), 'Hello', 'staff can still see it if it was reported');

-- Push.
select public.notify('a1000000-0000-0000-0000-000000000001', 'Your Meet moved', 'New time', '!', '/activities/x');
select ok((select not_before <= now() from public.push_queue where title = 'Your Meet moved'), 'P2-06 a session change goes at once');
update public.notification_settings set offers_and_news = false where user_id = 'a1000000-0000-0000-0000-000000000002';
insert into public.notification_settings (user_id, offers_and_news) values ('a1000000-0000-0000-0000-000000000002', false)
  on conflict (user_id) do update set offers_and_news = false;
select public.notify('a1000000-0000-0000-0000-000000000002', 'Offer', 'Sale');
select is_empty($$select 1 from public.push_queue where title = 'Offer'$$, 'P2-06 per-kind settings are honoured');

-- Quiet hours, by moving the window so it always covers now.
update public.app_settings set value = '0' where key = 'notify.quiet_from_hour';
update public.app_settings set value = '0' where key = 'notify.quiet_to_hour';
select public.notify('a1000000-0000-0000-0000-000000000001', 'Quiet test', 'Later');
select ok((select not_before > now() from public.push_queue where title = 'Quiet test'), 'P2-06 quiet hours hold everything else');
select public.notify('a1000000-0000-0000-0000-000000000001', 'Quiet session', 'Now', '!', '/activities/y');
select ok((select not_before <= now() from public.push_queue where title = 'Quiet session'), 'P2-06 session changes still get through');

select t.as_user('a1000000-0000-0000-0000-000000000001');
select throws_ok($$select * from public.push_queue$$, '42501', null, 'players cannot read the queue');
select t.reset();

select * from finish();
rollback;
