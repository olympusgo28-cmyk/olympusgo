-- P4d: what the reviews found. Self check-ins, the paid rule before payments
-- open, late attendance, flagged accounts, and a voucher's limits.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
\ir helpers/academy.psql
select no_plan();

select t.player('d3000000-0000-0000-0000-000000000001');  -- organizer
select t.player('d3000000-0000-0000-0000-000000000002');  -- player
select t.player('d3000000-0000-0000-0000-000000000003');  -- flagged player
select t.player('d3000000-0000-0000-0000-000000000004');  -- shop owner
select t.player('d3000000-0000-0000-0000-000000000005');  -- content staff
select t.player('d3000000-0000-0000-0000-000000000006');  -- payments staff
select t.player('d3000000-0000-0000-0000-000000000007');  -- suspended organizer
insert into public.staff (user_id, role) values ('d3000000-0000-0000-0000-000000000005', 'content'),
  ('d3000000-0000-0000-0000-000000000006', 'payments');
select t.player(('d3000000-0000-0000-0000-00000000010' || n)::uuid) from generate_series(1, 6) n;
update public.voucher_types set organizer_default = false where organizer_default;
update public.feature_flags set enabled = true where key in ('game.campaigns', 'game.organizer_rewards', 'shop.checkout');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
create function t.q(n int) returns uuid language sql as $$ select ('d3000000-0000-0000-0000-00000000010' || n)::uuid; $$;
grant execute on all functions in schema t to anon, authenticated, service_role;

insert into ids select 'mall', t.shop('d3000000-0000-0000-0000-000000000004');
insert into ids select 'dear', t.product(t.id('mall'), 10000, 20);
insert into ids select 'cheap', t.product(t.id('mall'), 100, 20);
insert into ids select 'other', t.product(t.id('mall'), 3000, 20);

create function t.vtype(p_off bigint default 800, p_product uuid default null) returns uuid
language sql security definer as $$
  insert into public.voucher_types (name, kind, mall_id, amount_minor, product_id)
  values ('S$8 off', 'A', t.id('mall'), p_off, p_product) returning id;
$$;
insert into ids select 'type', t.vtype();
create function t.give(p_user uuid, p_type uuid default null) returns uuid language plpgsql security definer as $$
declare
  v uuid;
  v_source text := 'test:' || gen_random_uuid();
begin
  perform private.voucher_issue(coalesce(p_type, t.id('type')), p_user, v_source);
  select id into v from public.vouchers where source = v_source;
  return v;
end;
$$;
create function t.campaign(p_type text default 'attend_sessions', p_target int default 1) returns uuid
language plpgsql security definer as $$
declare
  c uuid;
begin
  insert into public.campaigns (title, starts_at, ends_at, status)
  values ('Review campaign', now() - interval '5 days', now() + interval '5 days', 'live') returning id into c;
  insert into public.quests (campaign_id, type, target, voucher_type_id) values (c, p_type, p_target, t.id('type'));
  return c;
end;
$$;
create function t.joined(p_user uuid, p_campaign uuid) returns void language sql security definer as $$
  insert into public.challenges (campaign_id, user_id, joined_at) values (p_campaign, p_user, now() - interval '4 days');
$$;
-- A session of 2 hours, played p_ago hours ago.
create function t.session(p_user uuid, p_method text, p_ago int default 48, p_status text default 'joined') returns uuid
language plpgsql security definer as $$
declare
  v uuid := t.meet('d3000000-0000-0000-0000-000000000004', 12, 48);
begin
  update public.activities set starts_at = now() - make_interval(hours => p_ago),
    ends_at = now() - make_interval(hours => p_ago - 2) where id = v;
  insert into public.activity_participants (activity_id, user_id, status) values (v, p_user, 'joined');
  update public.activity_participants set attendance = 'present', check_in_method = p_method, status = p_status
  where activity_id = v and user_id = p_user;
  return v;
end;
$$;
create function t.done(p_user uuid) returns bigint language sql security definer as $$
  select count(*) from public.challenge_progress where user_id = p_user and completed_at is not null;
$$;
grant execute on all functions in schema t to anon, authenticated, service_role;

-- ─── What counts as a session ────────────────────────────────

insert into ids select 'c1', t.campaign();
select t.joined('d3000000-0000-0000-0000-000000000002', t.id('c1'));
select t.session('d3000000-0000-0000-0000-000000000002', 'self');
select private.quest_sync('d3000000-0000-0000-0000-000000000002');
select is(t.done('d3000000-0000-0000-0000-000000000002'), 0::bigint, 'checking yourself in isn''t proof');
select t.session('d3000000-0000-0000-0000-000000000002', 'qr', 48, 'cancelled');
select private.quest_sync('d3000000-0000-0000-0000-000000000002');
select is(t.done('d3000000-0000-0000-0000-000000000002'), 0::bigint, 'nor is a spot you gave up');
insert into ids select 'future', t.meet('d3000000-0000-0000-0000-000000000004', 12, 48);
insert into public.activity_participants (activity_id, user_id, status, attendance, check_in_method)
values (t.id('future'), 'd3000000-0000-0000-0000-000000000002', 'joined', 'present', 'qr');
select private.quest_sync('d3000000-0000-0000-0000-000000000002');
select is(t.done('d3000000-0000-0000-0000-000000000002'), 0::bigint, 'nor a session that hasn''t happened');
-- The organizer's scan or list confirms a check-in the player made themself.
insert into ids select 'confirm', t.meet('d3000000-0000-0000-0000-000000000001', 12, 48);
insert into public.activity_participants (activity_id, user_id, status) values
  (t.id('confirm'), t.q(5), 'joined'), (t.id('confirm'), t.q(6), 'joined');
update public.activity_participants set attendance = 'present', check_in_method = 'self' where activity_id = t.id('confirm');
create function t.open_now(p_activity uuid) returns void language sql security definer as $$
  update public.activities set starts_at = now(), ends_at = now() + interval '2 hours' where id = p_activity;
$$;
select t.open_now(t.id('confirm'));
insert into public.player_qr_tokens (user_id, token) values (t.q(5), 'confirm-token-5')
on conflict (user_id) do update set token = excluded.token;
select t.as_user('d3000000-0000-0000-0000-000000000001');
select public.host_check_in(t.id('confirm'), 'confirm-token-5');
select public.save_attendance(t.id('confirm'), jsonb_build_object(t.q(6), 'present'));
select t.reset();
select results_eq($$ select check_in_method from public.activity_participants where activity_id = t.id('confirm') order by user_id $$,
  $$ values ('qr'::text), ('host'::text) $$, 'a scan or the list confirms a player''s own check-in');

-- A session is judged when its attendance has closed, by the sweep, once.
create function t.scanned_early(p_user uuid) returns uuid language plpgsql security definer as $$
declare
  v uuid := t.meet('d3000000-0000-0000-0000-000000000004', 12, 48);
begin
  insert into public.activity_participants (activity_id, user_id, status) values (v, p_user, 'joined');
  update public.activity_participants set attendance = 'present', check_in_method = 'qr' where activity_id = v and user_id = p_user;
  return v;
end;
$$;
create function t.back(p_activity uuid, p_ago interval) returns void language sql security definer as $$
  update public.activities set starts_at = now() - p_ago, ends_at = now() - p_ago + interval '1 hour' where id = p_activity;
$$;
grant execute on all functions in schema t to anon, authenticated, service_role;
insert into ids select 's1', t.scanned_early('d3000000-0000-0000-0000-000000000002');
select is(t.done('d3000000-0000-0000-0000-000000000002'), 0::bigint, 'a scan alone finishes nothing');
select t.back(t.id('s1'), '30 hours'::interval);
select private.organizer_sweep();
select is(t.done('d3000000-0000-0000-0000-000000000002'), 1::bigint, 'the sweep finishes it once attendance has closed');
select is((select count(*) from private.quest_sessions_done where activity_id = t.id('s1')), 1::bigint, 'and marks the session');
select lives_ok($$ select private.organizer_sweep() $$, 'running again changes nothing');

-- A switched-off voucher waits, and isn't lost.
insert into ids select 'type_off', t.vtype();
create function t.switch(p_type uuid, p_on boolean) returns void language sql security definer as $$
  update public.voucher_types set active = p_on where id = p_type;
$$;
insert into ids select 'c2', public_c from (select t.campaign() as public_c) x;
update public.quests set voucher_type_id = t.id('type_off') where campaign_id = t.id('c2');
select t.joined(t.q(1), t.id('c2'));
select t.switch(t.id('type_off'), false);
select t.session(t.q(1), 'qr');
select private.quest_sync(t.q(1));
select is(t.done(t.q(1)), 0::bigint, 'a quest waits for its voucher to be switched back on');
select t.switch(t.id('type_off'), true);
select private.organizer_sweep();
select is((select count(*) from public.vouchers where owner_id = t.q(1)), 1::bigint, 'and the sweep pays out when it is');

-- ─── Organizer games ─────────────────────────────────────

create function t.game(p_host uuid, p_ago interval default '2 days', p_present int default 6) returns uuid
language plpgsql as $$
declare
  v uuid := t.paid_meet(p_host, 600, 12, 48);
  i int;
begin
  for i in 1 .. p_present loop
    perform t.paid(t.q(i), v);
  end loop;
  update public.activity_participants ap set attendance = 'present', check_in_method = 'qr'
  where ap.activity_id = v and ap.status = 'joined';
  update public.activities set starts_at = now() - p_ago, ends_at = now() - p_ago + interval '1 hour' where id = v;
  perform private.release_activity(v);
  return v;
end;
$$;
grant execute on function t.game(uuid, interval, int) to anon, authenticated;

-- A game with no save still gets looked at.
insert into ids select 'unsaved', t.game('d3000000-0000-0000-0000-000000000001');
select private.organizer_sweep();
select is((select reason from public.organizer_games where activity_id = t.id('unsaved')), 'counted', 'a game nobody pressed save on is judged');

-- Attendance stays open till the end of the day, so a game isn't judged before that.
insert into ids select 'today', t.game('d3000000-0000-0000-0000-000000000001', '2 minutes'::interval);
update public.activities set starts_at = date_trunc('day', now() at time zone 'Asia/Singapore') at time zone 'Asia/Singapore' + interval '1 minute',
  ends_at = date_trunc('day', now() at time zone 'Asia/Singapore') at time zone 'Asia/Singapore' + interval '2 minutes' where id = t.id('today');
select private.organizer_sweep();
select is((select count(*) from public.organizer_games where activity_id = t.id('today')), 0::bigint, 'a game isn''t judged while attendance is open');

-- A cancelled Meet's money never releases, and it's still recorded.
insert into ids select 'cancelled', t.game('d3000000-0000-0000-0000-000000000001', '3 days'::interval);
create function t.cancelled(p_activity uuid) returns void language plpgsql security definer as $$
begin
  update public.payments set released_at = null where activity_id = p_activity;
  update public.activities set status = 'cancelled' where id = p_activity;
end;
$$;
select t.cancelled(t.id('cancelled'));

-- Before payments open a game ranks, and earns nothing.
update public.feature_flags set enabled = false where key in ('payments.enabled', 'campaign.require_paid');
insert into ids select 'before', t.meet('d3000000-0000-0000-0000-000000000001', 12, 48);
update public.activities set starts_at = now() - interval '2 days', ends_at = now() - interval '47 hours' where id = t.id('before');
insert into public.activity_participants (activity_id, user_id, status, attendance, check_in_method)
select t.id('before'), t.q(n), 'joined', 'present', 'qr' from generate_series(1, 6) n;
select private.organizer_sweep();
select is((select reason from public.organizer_games where activity_id = t.id('cancelled')), 'cancelled', 'a paid Meet that was cancelled is recorded as that');
select results_eq($$ select counted, reason, game_no from public.organizer_games where activity_id = t.id('before') $$,
  $$ values (false, 'before_payments'::text, null::int) $$, 'a game before payments gets no number');
update public.feature_flags set enabled = true where key = 'payments.enabled';

-- A flagged or suspended organizer's grant waits.
insert into public.points_blocks (user_id, reason) values ('d3000000-0000-0000-0000-000000000003', 'Farming');
insert into public.reward_grants (key, user_id, kind) values
  ('test-flagged', 'd3000000-0000-0000-0000-000000000003', 'A'),
  ('test-suspended', 'd3000000-0000-0000-0000-000000000007', 'A');
insert into public.account_moderation (user_id, suspended_until) values ('d3000000-0000-0000-0000-000000000007', now() + interval '7 days')
on conflict (user_id) do update set suspended_until = excluded.suspended_until;
update public.voucher_types set organizer_default = true where id = t.id('type');
select private.organizer_sweep();
select is((select count(*) from public.vouchers where source in ('test-flagged', 'test-suspended')), 0::bigint,
  'a flagged or suspended account''s rewards wait');

-- ─── Vouchers at checkout ─────────────────────────────────

create function t.quote(p_user uuid, p_lines jsonb, p_voucher uuid default null) returns jsonb language plpgsql as $$
declare
  v jsonb;
begin
  insert into public.cart_lines (user_id, product_id, qty)
  select p_user, (x ->> 'product')::uuid, (x ->> 'qty')::int from jsonb_array_elements(p_lines) x;
  perform t.as_user(p_user);
  v := public.shop_quote(t.id('mall'), null, 0, p_voucher);
  perform t.reset();
  delete from public.cart_lines where user_id = p_user;
  return v;
end;
$$;
create function t.only(p_user uuid, p_product uuid, p_qty int default 1, p_voucher uuid default null) returns jsonb
language plpgsql as $$
declare
  v jsonb;
begin
  perform t.as_user(p_user);
  v := public.shop_quote(t.id('mall'), jsonb_build_object('product', p_product, 'qty', p_qty), 0, p_voucher);
  perform t.reset();
  return v;
end;
$$;
grant execute on all functions in schema t to anon, authenticated, service_role;

insert into ids select 'v1', t.give('d3000000-0000-0000-0000-000000000002');
-- It goes on the dearest item, whichever way the ids fall.
select is((select (l ->> 'unit_voucher')::bigint from jsonb_array_elements(t.quote('d3000000-0000-0000-0000-000000000002',
  jsonb_build_array(jsonb_build_object('product', t.id('cheap'), 'qty', 1), jsonb_build_object('product', t.id('dear'), 'qty', 1)),
  t.id('v1')) -> 'lines') l where (l ->> 'product_id')::uuid = t.id('dear')), 800::bigint, 'a voucher goes on the dearest item');

-- The offer says what it'll really take off, and leaves out what doesn't fit.
select is(t.only('d3000000-0000-0000-0000-000000000002', t.id('cheap')) -> 'vouchers' -> 0 ->> 'amount_minor', '50',
  'the offer says what it will really take off');
insert into ids select 'for_other', t.vtype(800, t.id('other'));
insert into ids select 'v2', t.give('d3000000-0000-0000-0000-000000000002', t.id('for_other'));
select is((select count(*) from jsonb_array_elements(t.only('d3000000-0000-0000-0000-000000000002', t.id('dear')) -> 'vouchers') v
  where v ->> 'id' = t.id('v2')::text), 0::bigint, 'a voucher for another item isn''t offered');

-- Switched off, it can't be used or offered.
insert into ids select 'type2', t.vtype();
insert into ids select 'v3', t.give('d3000000-0000-0000-0000-000000000002', t.id('type2'));
select t.switch(t.id('type2'), false);
select throws_ok($$ select t.only('d3000000-0000-0000-0000-000000000002', t.id('dear'), 1, t.id('v3')) $$,
  'This voucher can''t be used right now.', 'a switched-off voucher can''t be used');
select t.reset();
select is((select count(*) from jsonb_array_elements(t.only('d3000000-0000-0000-0000-000000000002', t.id('dear')) -> 'vouchers') v
  where v ->> 'id' = t.id('v3')::text), 0::bigint, 'or offered');

-- An expired voucher says so.
insert into ids select 'v4', t.give('d3000000-0000-0000-0000-000000000002');
update public.vouchers set expires_at = now() - interval '1 day', status = 'expired' where id = t.id('v4');
select throws_ok($$ select t.only('d3000000-0000-0000-0000-000000000002', t.id('dear'), 1, t.id('v4')) $$,
  'This voucher has expired.', 'a swept voucher says it expired');
select t.reset();

-- A flagged account can't spend what it holds.
insert into ids select 'v5', t.give('d3000000-0000-0000-0000-000000000003');
select throws_ok($$ select t.only('d3000000-0000-0000-0000-000000000003', t.id('dear'), 1, t.id('v5')) $$,
  'This voucher can''t be used right now.', 'a flagged account can''t spend a voucher');
select t.reset();
select t.as_user('d3000000-0000-0000-0000-000000000003');
select throws_ok(format($$ select public.campaign_join(%L) $$, t.id('c1')), 'You can''t join campaigns right now.', 'or join a campaign');
select t.reset();

-- A retry finds a split order, and only with the voucher it holds.
create function t.reserve_v(p_key text, p_voucher uuid, p_expected bigint) returns jsonb language plpgsql as $$
declare
  v jsonb;
begin
  perform t.as_user('d3000000-0000-0000-0000-000000000002');
  v := public.shop_reserve(t.id('mall'), p_key, p_expected, 0, jsonb_build_object('product', t.id('dear'), 'qty', 3), null, p_voucher);
  perform t.reset();
  return v;
end;
$$;
create function t.as_buyer_report(p_order uuid) returns void language plpgsql as $$
begin
  perform t.as_user('d3000000-0000-0000-0000-000000000002');
  perform public.shop_report_problem(p_order, 'Nothing came');
  perform t.reset();
end;
$$;
grant execute on all functions in schema t to anon, authenticated, service_role;
insert into ids select 'o1', (t.reserve_v('retry-key-1', t.id('v1'), 29200) ->> 'order_id')::uuid;
select is((select count(*) from public.order_lines where order_id = t.id('o1')), 2::bigint, 'three of an item split around the voucher');
insert into ids select 'v6', t.give('d3000000-0000-0000-0000-000000000002');
select is((t.reserve_v('retry-key-2', t.id('v1'), 29200) ->> 'order_id')::uuid, t.id('o1'), 'a retry with a new key finds that order');
select throws_ok($$ select t.reserve_v('retry-key-3', t.id('v6'), 29200) $$,
  'Finish or cancel your unpaid order at this shop first.', 'but not with another voucher');
select t.reset();

-- A full staff refund leaves the voucher spent until the owner decides (Q161).
select t.succeed((select id from public.payments where order_id = t.id('o1')));
create temp table o1_lines on commit drop as select jsonb_agg(jsonb_build_object('line', id, 'qty', qty)) as v
  from public.order_lines where order_id = t.id('o1');
grant select on o1_lines to authenticated;
select t.as_buyer_report(t.id('o1'));
select t.as_staff('d3000000-0000-0000-0000-000000000006');
select public.staff_order_decide(t.id('o1'), (select v from o1_lines), false, 'Shop went quiet', 'voucher-decide-all');
select t.reset();
select is((select status from public.vouchers where id = t.id('v1')), 'used', 'a full staff refund leaves it spent');
select ok(t.all_balanced(), 'the ledger balances');

-- ─── Staff ──────────────────────────────────────────

select t.as_staff('d3000000-0000-0000-0000-000000000005');
select throws_ok($$ select public.staff_voucher_type_save(jsonb_build_object('name', 'Too generous', 'kind', 'A',
  'mall_id', t.id('mall'), 'amount_minor', 5000), 'Why not') $$, 'Not found.', 'content staff can''t set a voucher''s amount');
select lives_ok($$ select public.staff_redemptions() $$, 'they can see redemptions');
select t.reset();
select t.as_staff('d3000000-0000-0000-0000-000000000006');
select lives_ok($$ select public.staff_organizer_games() $$, 'and payments staff can see the games');
select throws_ok(format($$ select public.staff_voucher_type_save(jsonb_build_object('name', 'Wrong one', 'kind', 'A',
  'mall_id', %L, 'amount_minor', 500, 'product_id', %L), 'Mistake') $$, t.id('mall'), gen_random_uuid()),
  'That product isn''t from this shop.', 'a voucher''s product must be the shop''s');
select lives_ok(format($$ select public.staff_voucher_type_save(jsonb_build_object('id', %L, 'kind', 'B', 'name', 'Renamed'), 'New name') $$, t.id('type2')),
  'an edit keeps its kind');
select t.reset();
select is((select kind from public.voucher_types where id = t.id('type2')), 'A', 'whatever the edit says');

select t.as_staff('d3000000-0000-0000-0000-000000000005');
select throws_ok(format($$ select public.staff_campaign_save(jsonb_build_object('id', %L, 'title', 'Shorter',
  'starts_at', now() - interval '5 days', 'ends_at', now() + interval '1 day',
  'quests', jsonb_build_array(jsonb_build_object('type', 'play_sessions', 'target', 1))), 'Too long') $$, t.id('c1')),
  'A live campaign can''t end sooner. End it instead.', 'a live campaign can''t be cut short');
select t.reset();

-- ─── Grants ─────────────────────────────────────────

select is_empty($$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'private' and p.proname in ('voucher_issue', 'badge_grant', 'quest_sync', 'quest_count', 'quest_attendance',
    'milestone_reward', 'game_counted', 'organizer_game_check', 'organizer_sweep', 'campaign_json', 'next_milestone',
    'voucher_usable', 'voucher_return', 'shop_price', 'staff_require_game')
    and (has_function_privilege('anon', p.oid, 'execute') or has_function_privilege('authenticated', p.oid, 'execute')) $$,
  'no client can call what issues a voucher');

select * from finish();
rollback;
