-- P4d-01, P4d-02: campaigns, the counted-game rule and the milestone ladder.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
\ir helpers/academy.psql
select no_plan();

-- A used database may have defaults set; this file sets its own.
update public.voucher_types set organizer_default = false where organizer_default;

select t.player('d1000000-0000-0000-0000-000000000001');  -- organizer
select t.player('d1000000-0000-0000-0000-000000000099', 15);  -- teen organizer
select t.player('d1000000-0000-0000-0000-000000000098');  -- outsider
select t.player('d1000000-0000-0000-0000-000000000097');  -- content staff
select t.player('d1000000-0000-0000-0000-000000000096');  -- moderator
select t.player('d1000000-0000-0000-0000-000000000095');  -- payments staff
insert into public.staff (user_id, role) values ('d1000000-0000-0000-0000-000000000095', 'payments'),
  ('d1000000-0000-0000-0000-000000000097', 'content'),
  ('d1000000-0000-0000-0000-000000000096', 'moderator');
select t.player(('d1000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid) from generate_series(11, 19) i;
update public.feature_flags set enabled = true where key in ('game.campaigns', 'game.organizer_rewards');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;

create function t.p(i int) returns uuid language sql immutable as $$
  select ('d1000000-0000-0000-0000-0000000000' || lpad((10 + i)::text, 2, '0'))::uuid;
$$;

-- A Meet that has happened: p_paid players paid and p_scanned were scanned in,
-- with p_present Present, and its money released.
create function t.game(p_host uuid, p_present int default 6, p_paid int default null, p_scanned int default null,
  p_host_plays boolean default false) returns uuid
language plpgsql as $$
declare
  v uuid := t.paid_meet(p_host, 600, 12, 48);
  i int;
begin
  for i in 1 .. p_present loop
    if i <= coalesce(p_paid, p_present) then
      perform t.paid(t.p(i), v);
    else
      insert into public.activity_participants (activity_id, user_id, status) values (v, t.p(i), 'joined');
    end if;
  end loop;
  if p_host_plays then perform t.paid(p_host, v); end if;
  update public.activity_participants ap set attendance = 'present',
    check_in_method = case when ap.user_id = p_host then 'host'
      when (select count(*) from generate_series(1, coalesce(p_scanned, p_present)) x where t.p(x) = ap.user_id) > 0
      then 'qr' else 'host' end
  where ap.activity_id = v and ap.status = 'joined';
  update public.activities set starts_at = now() - interval '2 days', ends_at = now() - interval '47 hours' where id = v;
  insert into public.campaign_game_log (activity_id, host_id, present_count, players, starts_at, ends_at)
  values (v, p_host, p_present, '[]', now() - interval '2 days', now() - interval '47 hours');
  perform private.release_activity(v);
  return v;
end;
$$;
create function t.result(p_activity uuid) returns text language sql security definer as $$
  select reason from public.organizer_games where activity_id = p_activity;
$$;
grant execute on all functions in schema t to anon, authenticated, service_role;

-- ─── The ladder ────────────────────────────────────────────────────────────

create temp table want (n int, a int, b int);
insert into want values (1,0,0),(2,1,0),(3,0,0),(4,1,0),(5,0,0),(6,0,0),(7,0,0),(8,2,1),(9,0,0),(10,0,0),
  (11,0,0),(12,2,0),(13,0,0),(14,0,0),(15,0,0),(16,3,1),(17,0,0),(18,0,0),(19,0,0),(20,3,0),(21,0,0),(22,0,0),
  (23,0,0),(24,3,1),(25,0,0),(26,0,0),(27,0,0),(28,3,0),(29,0,0),(30,0,0),(31,0,0),(32,3,1),(33,0,0),(34,0,0),
  (35,0,0),(36,3,0),(37,0,0),(38,0,0),(39,0,0),(40,3,1);
select is_empty($$ select w.n from want w, lateral private.milestone_reward(w.n) m
  where (m.voucher_a, m.voucher_b) is distinct from (w.a, w.b) $$, 'the ladder matches games 1 to 40, the owner''s pattern after 24');
select is((private.milestone_reward(0)).voucher_a, 0, 'game 0 earns nothing');

-- ─── The counted rule, row by row ──────────────────────────────────────────

insert into ids values ('ok', t.game('d1000000-0000-0000-0000-000000000001'));
insert into ids values ('five', t.game('d1000000-0000-0000-0000-000000000001', 5));
insert into ids values ('unpaid', t.game('d1000000-0000-0000-0000-000000000001', 6, 5));
insert into ids values ('unscanned', t.game('d1000000-0000-0000-0000-000000000001', 6, 6, 5));
insert into ids values ('with_host', t.game('d1000000-0000-0000-0000-000000000001', 5, null, null, true));
select private.organizer_sweep();
select is(t.result(t.id('ok')), 'counted', '6 Present, paid and scanned counts, and the organizer needn''t play');
select is(t.result(t.id('five')), 'under_six', '5 Present doesn''t');
select is(t.result(t.id('unpaid')), 'unpaid', 'one participant who didn''t pay stops it');
select is(t.result(t.id('unscanned')), 'not_scanned', 'one not scanned stops it');
select is(t.result(t.id('with_host')), 'counted', 'an organizer who pays S$2.00 counts towards the 6, without scanning themself');
select is((select array_agg(game_no order by game_no) from public.organizer_games
  where host_id = 'd1000000-0000-0000-0000-000000000001' and counted), array[1, 2], 'counted games number from 1, and failed ones don''t use a number');
select is((select count(*) from public.reward_grants where user_id = 'd1000000-0000-0000-0000-000000000001'), 1::bigint, 'game 2 earns one Voucher A');

-- An organizer who didn't pay isn't one of the 6.
create function t.free_host() returns uuid language plpgsql as $$
declare
  v uuid := t.game('d1000000-0000-0000-0000-000000000098', 5);
begin
  insert into public.activity_participants (activity_id, user_id, status, attendance, check_in_method)
  values (v, 'd1000000-0000-0000-0000-000000000098', 'joined', 'present', 'host');
  return v;
end;
$$;
insert into ids values ('free_host', t.free_host());
select private.organizer_sweep();
select is(t.result(t.id('free_host')), 'under_six', 'an organizer who didn''t pay isn''t counted');

-- A fee refunded isn't a fee paid.
insert into ids select 'refunded', t.game('d1000000-0000-0000-0000-000000000098');
select private.refund_issue((select id from public.payments where activity_id = t.id('refunded') and user_id = t.p(1)), 'organizer_cancelled');
select private.organizer_sweep();
select is(t.result(t.id('refunded')), 'unpaid', 'a refunded fee doesn''t count as paid');

-- An organizer-pays Meet: the participants paid nothing.
create function t.organizer_pays() returns uuid language plpgsql security definer as $$
declare
  v uuid := t.meet('d1000000-0000-0000-0000-000000000098', 12, 48);
  i int;
begin
  for i in 1 .. 6 loop
    insert into public.activity_participants (activity_id, user_id, status, attendance, check_in_method)
    values (v, t.p(i), 'joined', 'present', 'qr');
  end loop;
  update public.activities set starts_at = now() - interval '2 days', ends_at = now() - interval '47 hours' where id = v;
  insert into public.campaign_game_log (activity_id, host_id, present_count, players, starts_at, ends_at)
  values (v, 'd1000000-0000-0000-0000-000000000098', 6, '[]', now() - interval '3 hours', now() - interval '1 hour');
  return v;
end;
$$;
insert into ids values ('org_pays', t.organizer_pays());
select private.organizer_sweep();
select is(t.result(t.id('org_pays')), 'unpaid', 'an organizer-pays Meet doesn''t count');

-- Only people 18 or over earn, and only once the money has settled.
select t.link('d1000000-0000-0000-0000-000000000098', 'd1000000-0000-0000-0000-000000000099');
insert into ids values ('teen', t.game('d1000000-0000-0000-0000-000000000099'));
select private.organizer_sweep();
select is(t.result(t.id('teen')), 'organizer_minor', 'a teen organizer earns nothing');

insert into ids select 'pending_money', t.paid_meet('d1000000-0000-0000-0000-000000000098', 600, 12, 48);
select t.paid(t.p(1), t.id('pending_money'));
update public.activities set starts_at = now() - interval '3 hours', ends_at = now() - interval '1 hour' where id = t.id('pending_money');
insert into public.campaign_game_log (activity_id, host_id, present_count, players, starts_at, ends_at)
values (t.id('pending_money'), 'd1000000-0000-0000-0000-000000000098', 6, '[]', now(), now());
select private.organizer_sweep();
select is(t.result(t.id('pending_money')), null, 'nothing is decided while money is unsettled');

-- A flagged account.
insert into public.points_blocks (user_id, reason) values ('d1000000-0000-0000-0000-000000000098', 'Farming');
insert into ids values ('flagged', t.game('d1000000-0000-0000-0000-000000000098'));
select private.organizer_sweep();
select is(t.result(t.id('flagged')), 'organizer_flagged', 'a flagged organizer earns nothing');
delete from public.points_blocks where user_id = 'd1000000-0000-0000-0000-000000000098';

-- ─── Idempotency ───────────────────────────────────────────────────────────

select private.organizer_sweep();
select private.organizer_sweep();
select is((select count(*) from public.reward_grants where user_id = 'd1000000-0000-0000-0000-000000000001'), 1::bigint, 'running the sweep again grants nothing more');

-- Rewards wait for a type, and arrive once it exists.
select is((select status from public.reward_grants where user_id = 'd1000000-0000-0000-0000-000000000001'), 'pending', 'a reward waits for its voucher type');
select t.as_user('d1000000-0000-0000-0000-000000000001');
select is((public.organizer_rewards_my() ->> 'counted')::int, 2, 'the organizer sees their count');
select is(public.organizer_rewards_my() -> 'next' ->> 'game', '4', 'and the next milestone');
select is((public.organizer_rewards_my() ->> 'waiting')::int, 1, 'and what''s waiting');
select t.reset();

insert into ids select 'shop', t.shop('d1000000-0000-0000-0000-000000000097');
insert into ids select 'venue', id from public.venues order by name limit 1;
select t.as_staff('d1000000-0000-0000-0000-000000000095');
insert into ids select 'type_a', public.staff_voucher_type_save(jsonb_build_object('name', 'Shuttle voucher', 'kind', 'A',
  'mall_id', t.id('shop'), 'amount_minor', 800, 'organizer_default', true), 'Agreed with the shop');
insert into ids select 'type_b', public.staff_voucher_type_save(jsonb_build_object('name', 'Hall voucher', 'kind', 'B',
  'venue_id', t.id('venue'), 'amount_minor', 600, 'organizer_default', true), 'Agreed with the hall');
select t.reset();
select private.organizer_sweep();
select is((select status from public.reward_grants where user_id = 'd1000000-0000-0000-0000-000000000001'), 'issued', 'it''s issued once the type exists');
select private.organizer_sweep();
select is((select count(*) from public.vouchers where owner_id = 'd1000000-0000-0000-0000-000000000001'), 1::bigint, 'once');
select ok((select expires_at from public.vouchers where owner_id = 'd1000000-0000-0000-0000-000000000001')
  between now() + interval '89 days' and now() + interval '91 days', 'for 90 days');

-- Game 8 brings a Voucher B, held with no expiry.
create function t.jump(p_user uuid, p_to int) returns void language plpgsql security definer as $$
declare
  i int;
begin
  for i in (select coalesce(max(game_no), 0) + 1 from public.organizer_games where host_id = p_user) .. p_to - 1 loop
    insert into public.organizer_games (activity_id, host_id, counted, reason, present, game_no)
    values (gen_random_uuid(), p_user, true, 'counted', 6, i);
  end loop;
end;
$$;
select t.jump('d1000000-0000-0000-0000-000000000001', 8);
insert into ids values ('eighth', t.game('d1000000-0000-0000-0000-000000000001'));
select private.organizer_sweep();
select is((select count(*) from public.vouchers v join public.voucher_types x on x.id = v.type_id
  where v.owner_id = 'd1000000-0000-0000-0000-000000000001' and x.kind = 'A'), 3::bigint, 'game 8 adds 2 Voucher A');
select is((select v.status from public.vouchers v join public.voucher_types x on x.id = v.type_id
  where v.owner_id = 'd1000000-0000-0000-0000-000000000001' and x.kind = 'B'), 'held', 'and a Voucher B, held');
select is((select v.expires_at from public.vouchers v join public.voucher_types x on x.id = v.type_id
  where v.owner_id = 'd1000000-0000-0000-0000-000000000001' and x.kind = 'B'), null, 'with no expiry running');

-- ─── Campaigns ─────────────────────────────────────────────────────────────

select t.as_staff('d1000000-0000-0000-0000-000000000097');
insert into ids select 'campaign', public.staff_campaign_save(jsonb_build_object('title', 'Play 2 in November',
  'starts_at', now() - interval '1 day', 'ends_at', now() + interval '10 days',
  'quests', jsonb_build_array(jsonb_build_object('type', 'play_sessions', 'target', 2, 'voucher_type_id', t.id('type_a')))), 'New campaign');
select t.reset();

select t.as_user(t.p(5));
select is((select count(*) from jsonb_array_elements(public.campaign_list()) e where e ->> 'id' = t.id('campaign')::text), 0::bigint, 'a draft isn''t listed');
select throws_ok($$ select public.campaign_join(t.id('campaign')) $$, 'This campaign has ended.', 'or joined');
select t.reset();
select t.as_staff('d1000000-0000-0000-0000-000000000097');
select public.staff_campaign_status(t.id('campaign'), 'live', 'Starting');
select throws_ok($$ select public.staff_campaign_status(t.id('campaign'), 'draft', 'Back') $$, 'A campaign can''t go from live to draft.', 'no way back to draft');
select public.staff_campaign_save(jsonb_build_object('id', t.id('campaign'), 'title', 'Play in November',
  'starts_at', now() - interval '1 day', 'ends_at', now() + interval '12 days',
  'quests', jsonb_build_array(jsonb_build_object('type', 'play_sessions', 'target', 1))), 'Renaming');
select t.reset();
select is((select target from public.quests where campaign_id = t.id('campaign')), 2, 'a live campaign''s target stays what people signed up to');
select is((select title from public.campaigns where id = t.id('campaign')), 'Play in November', 'though its words can change');

select t.as_user(t.p(5));
select lives_ok($$ select public.campaign_join(t.id('campaign')) $$, 'an adult joins');
select lives_ok($$ select public.campaign_join(t.id('campaign')) $$, 'twice is harmless');
select t.reset();
select t.as_user('d1000000-0000-0000-0000-000000000099');
select throws_ok($$ select public.campaign_join(t.id('campaign')) $$, 'Campaigns are for adults for now.', 'a teen can''t join');
select is((select count(*) from jsonb_array_elements(public.campaign_list()) e where e ->> 'id' = t.id('campaign')::text), 1::bigint, 'but can see it');
select t.reset();
select t.as_anon();
select throws_ok($$ select public.campaign_list() $$, '42501', null, 'signed out sees nothing');
select t.reset();

-- Two sessions complete the quest, once, and a rating doesn't move.
create function t.rating_total() returns numeric language sql security definer as $$
  select coalesce(sum(rating), 0) from public.ratings;
$$;
create temp table before_rating as select t.rating_total() as v;
create function t.attend(p_user uuid) returns void language plpgsql security definer as $$
declare
  v uuid := t.meet('d1000000-0000-0000-0000-000000000098', 12, 48);
begin
  update public.activities set starts_at = now() - interval '30 hours', ends_at = now() - interval '29 hours' where id = v;
  insert into public.activity_participants (activity_id, user_id, status) values (v, p_user, 'joined');
  update public.activity_participants set attendance = 'present', check_in_method = 'qr' where activity_id = v and user_id = p_user;
end;
$$;
update public.challenges set joined_at = now() - interval '31 hours' where user_id = t.p(5);
update public.campaigns set starts_at = now() - interval '5 days' where id = t.id('campaign');
select t.attend(t.p(5));
select is((select count from public.challenge_progress where user_id = t.p(5)), 1, 'one session is one step');
select t.attend(t.p(5));
select ok((select completed_at is not null from public.challenge_progress where user_id = t.p(5)), 'two finish the quest');
select is((select count(*) from public.vouchers where owner_id = t.p(5)), 1::bigint, 'and issue its voucher');
select t.attend(t.p(5));
select private.quest_sync(t.p(5));
select is((select count(*) from public.vouchers where owner_id = t.p(5)), 1::bigint, 'only once');
select is(t.rating_total(), (select v from before_rating), 'and no rating moved');
select is_empty($$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname in ('public', 'private') and (p.proname like 'quest%' or p.proname like 'campaign%' or p.proname like 'organizer%')
    and p.prosrc ~* 'public\.(ratings|rating_events)' $$, 'no quest code touches ratings');

-- A quest failing never stops attendance.
select ok(exists (select 1 from pg_trigger where tgname = 'activity_participants_quests'), 'attendance feeds quests');

-- ─── Who can reach what ────────────────────────────────────────────────────

select t.as_user(t.p(5));
select throws_ok($$ select * from public.vouchers $$, '42501', null, 'no client reads vouchers directly');
select throws_ok($$ select * from public.voucher_redemptions $$, '42501', null, 'or redemptions');
select throws_ok($$ select * from public.reward_grants $$, '42501', null, 'or grants');
select throws_ok($$ select * from public.organizer_games $$, '42501', null, 'or the game record');
select throws_ok($$ update public.campaigns set status = 'live' $$, '42501', null, 'nobody writes a campaign');
select throws_ok($$ select public.staff_campaign_list() $$, 'Not found.', 'a player can''t reach staff lists');
select t.reset();
select t.as_staff('d1000000-0000-0000-0000-000000000096');
select throws_ok($$ select public.staff_redemptions() $$, 'Not found.', 'nor can a moderator');
select t.reset();
select t.as_staff('d1000000-0000-0000-0000-000000000097', false);
select throws_ok($$ select public.staff_campaign_list() $$, 'Not found.', 'nor content staff without MFA');
select t.reset();
select t.as_staff('d1000000-0000-0000-0000-000000000097');
select ok(public.staff_organizer_games()::text like '%under_six%', 'staff see why a game didn''t count');
select t.reset();

select * from finish();
rollback;
