-- P1-14, Q228, Q139, Q208: a player deletes their account in the app. The
-- account closes at once, money comes back, the undo works, and the erase
-- leaves a "Former player" while a child's records survive.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
\ir helpers/academy.psql
select no_plan();
update public.feature_flags set enabled = true where key = 'lessons.checkout';

select t.player('d0000000-0000-0000-0000-000000001101');       -- host
select t.player('d0000000-0000-0000-0000-000000001102');       -- player who deletes
select t.player('d0000000-0000-0000-0000-000000001103');       -- host who deletes
select t.player('d0000000-0000-0000-0000-000000001104');       -- joined the deleting host
select t.player('d0000000-0000-0000-0000-000000001105');       -- parent who deletes
select t.player('d0000000-0000-0000-0000-000000001106', 12);   -- their only child
select t.player('d0000000-0000-0000-0000-000000001107');       -- second parent
select t.player('d0000000-0000-0000-0000-000000001108', 12);   -- child with two parents
select t.player('d0000000-0000-0000-0000-000000001109');       -- club owner
select t.player('d0000000-0000-0000-0000-000000001110');       -- staff
select t.player('d0000000-0000-0000-0000-000000001111');       -- shop owner
select t.player('d0000000-0000-0000-0000-000000001112');       -- buyer with an open order
select t.player('d0000000-0000-0000-0000-000000001113');       -- lesson payer
select t.player('d0000000-0000-0000-0000-000000001114');       -- academy owner
select t.player('c2000000-0000-0000-0000-000000000002');       -- the coach t.slot names
select t.player('d0000000-0000-0000-0000-000000001115');       -- hidden by moderation
select t.player('d0000000-0000-0000-0000-000000001116');       -- parent hard-deleted by hand
select t.player('d0000000-0000-0000-0000-000000001117');       -- a stranger
select t.player('d0000000-0000-0000-0000-000000001118');       -- host owed earnings
select t.player('d0000000-0000-0000-0000-000000001119');       -- paid that host
select t.player('d0000000-0000-0000-0000-000000001120');       -- host carrying a fee debt
select t.player('d0000000-0000-0000-0000-000000001121');       -- keeps the account at the last minute

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;

create function t.gate(p_path text, p_method text default 'GET') returns void language plpgsql as $$
begin
  perform set_config('request.path', p_path, true);
  perform set_config('request.method', p_method, true);
  perform private.gate_request();
  perform set_config('request.path', '', true);
end;
$$;
create function t.request(p_user uuid, p_reason text default null) returns jsonb language plpgsql as $$
declare
  v jsonb;
begin
  perform t.as_user(p_user);
  v := public.account_delete_request(p_reason);
  perform t.reset();
  return v;
end;
$$;
create function t.closing(p_user uuid) returns boolean language sql security definer as $$
  select private.is_closing(p_user);
$$;
-- From 42_lessons_test: a one-to-one slot and a booking as the payer.
create function t.slot(p_hours numeric default 72, p_price bigint default 5000) returns uuid
language sql security definer as $$
  update public.lesson_slots set status = 'withdrawn' where status = 'open';
  insert into public.lesson_slots (academy_id, coach_id, starts_at, ends_at, price_minor)
  values (t.id('academy'), 'c2000000-0000-0000-0000-000000000002',
    now() + make_interval(secs => p_hours * 3600), now() + make_interval(secs => p_hours * 3600 + 3600), p_price)
  returning id;
$$;
create function t.book(p_payer uuid, p_kind text, p_ref uuid, p_at timestamptz, p_student uuid, p_total bigint)
returns jsonb language plpgsql as $$
declare
  v jsonb;
begin
  perform t.as_user(p_payer);
  v := public.lesson_reserve(p_kind, p_ref, p_at, p_student, 'key-' || gen_random_uuid(), p_total);
  perform t.reset();
  return v;
end;
$$;
grant execute on all functions in schema t to anon, authenticated, service_role;

-- Set-up: a paid join, a hosted Meet with a paid player, a paid lesson, an
-- open Shop order, points, a voucher, two families.
insert into ids values ('m1', t.paid_meet('d0000000-0000-0000-0000-000000001101', 600, 4));
insert into ids values ('p1', t.paid('d0000000-0000-0000-0000-000000001102', t.id('m1')));
insert into ids values ('m2', t.paid_meet('d0000000-0000-0000-0000-000000001103', 600, 4));
insert into ids values ('p2', t.paid('d0000000-0000-0000-0000-000000001104', t.id('m2')));
insert into ids values ('academy', t.academy('d0000000-0000-0000-0000-000000001114'));
select t.coach(t.id('academy'), 'c2000000-0000-0000-0000-000000000002');
create temp table lb on commit drop as
  select t.book('d0000000-0000-0000-0000-000000001113', 'one_to_one', t.slot(72), null,
    'd0000000-0000-0000-0000-000000001113', 5500) as v;
select t.succeed((select (v ->> 'payment_id')::uuid from lb));
insert into ids values ('shop', t.shop('d0000000-0000-0000-0000-000000001111'));
insert into ids values ('item', t.product(t.id('shop'), 2000, 5));
create temp table ob on commit drop as
  select t.buy('d0000000-0000-0000-0000-000000001112', t.id('shop'), t.id('item')) as v;
select t.succeed((select (v ->> 'payment_id')::uuid from ob));
select t.give_points('d0000000-0000-0000-0000-000000001102', 500);
insert into public.voucher_types (name, kind, mall_id, amount_minor) values ('Test voucher', 'A', t.id('shop'), 500);
insert into public.vouchers (type_id, owner_id, code, status, expires_at, source)
select id, 'd0000000-0000-0000-0000-000000001102', 'DEL-TEST-1', 'issued', now() + interval '10 days', 'test:' || gen_random_uuid()
from public.voucher_types limit 1;
select t.link('d0000000-0000-0000-0000-000000001105', 'd0000000-0000-0000-0000-000000001106');
select t.link('d0000000-0000-0000-0000-000000001105', 'd0000000-0000-0000-0000-000000001108');
select t.link('d0000000-0000-0000-0000-000000001107', 'd0000000-0000-0000-0000-000000001108');
insert into public.clubs (owner_id, name, area, sports) values ('d0000000-0000-0000-0000-000000001109', 'Owners Club', 'Bishan', '["badminton"]');
insert into public.staff (user_id, role) values ('d0000000-0000-0000-0000-000000001110', 'moderator');
update public.profiles set hidden_at = now() - interval '1 day' where id = 'd0000000-0000-0000-0000-000000001115';
insert into public.notifications (user_id, title) values ('d0000000-0000-0000-0000-000000001102', 'Old note');
-- Money owed: a Meet that has been paid for and released, as the payout run would pay it.
insert into ids values ('m3', t.paid_meet('d0000000-0000-0000-0000-000000001118', 600, 4));
insert into ids values ('p3', t.paid('d0000000-0000-0000-0000-000000001119', t.id('m3')));
select private.release_activity(t.id('m3'));
-- An unpaid organizer fee: a debit on the organizer side of the ledger (a
-- card-fee recovery under R-REF-11 has the same sign and is treated the same).
select private.ledger_post('test', 'del-debt-' || gen_random_uuid(), 'SGD', '{}', jsonb_build_array(
  private.ledger_line('organizer_fee_debt', 'd0000000-0000-0000-0000-000000001120', 77),
  private.ledger_line('platform_fees', null, -77)));

-- ─── Who may not delete yet ────────────────────────────────────────────────

select throws_like($$select t.request('d0000000-0000-0000-0000-000000001109')$$, '%Hand your club%',
  'a club owner hands the club over first');
select throws_like($$select t.request('d0000000-0000-0000-0000-000000001110')$$, '%staff role%',
  'a staff member is removed from staff first');
select throws_like($$select t.request('d0000000-0000-0000-0000-000000001111')$$, '%your shop%',
  'a shop owner asks the team first');
select throws_like($$select t.request('d0000000-0000-0000-0000-000000001114')$$, '%Close your academy%',
  'an academy owner closes it first');
select is(private.organizer_net('d0000000-0000-0000-0000-000000001118', 'SGD'), 600::bigint, 'set-up: the host is owed S$6.00');
select throws_like($$select t.request('d0000000-0000-0000-0000-000000001118')$$, '%earnings to be paid out%',
  'a host who is owed money is paid first (R-ACC-15)');
select is(private.organizer_net('d0000000-0000-0000-0000-000000001120', 'SGD'), -77::bigint, 'set-up: the other host owes S$0.77 in fees');
select lives_ok($$select t.request('d0000000-0000-0000-0000-000000001120')$$,
  'a fee debt is not earnings: the request goes through');
select is(t.closing('d0000000-0000-0000-0000-000000001120'), true, 'and the account is closing');
select is(t.closing('d0000000-0000-0000-0000-000000001109'), false, 'a refused request changes nothing');
select throws_ok($$select public.account_delete_request()$$, 'P0001', 'Sign in first.', 'signed out: refused');

-- ─── The request ───────────────────────────────────────────────────────────

select is(private.can_view_profile('d0000000-0000-0000-0000-000000001102', 'd0000000-0000-0000-0000-000000001117'), true,
  'before: a stranger can see the player');

create temp table r1 on commit drop as select t.request('d0000000-0000-0000-0000-000000001102', 'Privacy worries') as v;
grant select on r1 to anon, authenticated;
select ok((select abs(extract(epoch from (v ->> 'erase_after')::timestamptz - now() - interval '30 days')) < 5 from r1),
  'the erase is 30 days out (R-ACC-11)');
select is(t.closing('d0000000-0000-0000-0000-000000001102'), true, 'the account is closing');
select is(private.can_view_profile('d0000000-0000-0000-0000-000000001102', 'd0000000-0000-0000-0000-000000001117'), false,
  'the profile is hidden at once');
select is((select hidden_before from public.account_deletions where user_id = 'd0000000-0000-0000-0000-000000001102'), false,
  'and the request remembers it was not hidden before');
select is((select reason from public.account_deletions where user_id = 'd0000000-0000-0000-0000-000000001102'), 'Privacy worries',
  'the reason is kept');

-- Money: the joined Meet is left and everything comes back, fee included (R-REF-18).
select is(t.refunded(t.id('p1')), 800::bigint, 'the paid join comes back in full, S$6.00 plus the S$2.00 fee');
select is((select reason from public.refunds where payment_id = t.id('p1')), 'account_deleted', 'under its own reason');
select is((select idempotency_key from public.refunds where payment_id = t.id('p1')), 'account_deleted:' || t.id('p1'),
  'with a key that stops a second refund');
select is(t.status_of(t.id('m1'), 'd0000000-0000-0000-0000-000000001102'), 'cancelled', 'the spot is given up');
select is(t.bal('held', t.id('m1')), 0::bigint, 'nothing stays held for that spot');
select is((select count(*)::int from public.notifications where user_id = 'd0000000-0000-0000-0000-000000001102'
  and title = 'Your account is closing' and body like 'Log in before % to keep it.'), 1, 'the player is told how to undo');

-- Idempotent: asking again changes nothing and refunds nothing twice.
select is((select t.request('d0000000-0000-0000-0000-000000001102') ->> 'erase_after'), (select v ->> 'erase_after' from r1),
  'a second request returns the same date');
select is((select count(*)::int from public.refunds where payment_id = t.id('p1')), 1, 'and refunds once');

-- A host who deletes cancels their Meets, and their players are paid back.
select t.request('d0000000-0000-0000-0000-000000001103');
select is((select status from public.activities where id = t.id('m2')), 'cancelled', 'the hosted Meet is cancelled');
select is(t.refunded(t.id('p2')), 800::bigint, 'the player who joined it gets everything back');
select is((select reason from public.refunds where payment_id = t.id('p2')), 'organizer_cancelled', 'as an organizer cancellation');

-- A paid lesson still to come is cancelled and refunded in full.
select t.request('d0000000-0000-0000-0000-000000001113');
select is((select step from public.lesson_bookings where id = (select (v ->> 'booking_id')::uuid from lb)), 'cancelled',
  'the lesson is cancelled');
select is((select cancelled_by from public.lesson_bookings where id = (select (v ->> 'booking_id')::uuid from lb)), 'payer',
  'by the payer');
select is(t.refunded((select (v ->> 'payment_id')::uuid from lb)), 5500::bigint, 'S$50.00 plus S$5.00 comes back');

-- An open Shop order is left to finish.
select t.request('d0000000-0000-0000-0000-000000001112');
select is(t.step(t.order_of((select v from ob))), 'paid', 'the Shop order stays as it was');

-- ─── The gate: a closing account can only keep itself ──────────────────────

select t.as_user('d0000000-0000-0000-0000-000000001102');
select throws_ok($$select t.gate('/rpc/shop_products')$$, 'P0001', 'This account is closing.', 'closing: refused the Shop');
select throws_ok($$select t.gate('/rpc/join_activity', 'POST')$$, 'P0001', 'This account is closing.', 'closing: refused joining');
select throws_ok($$select t.gate('/notifications')$$, 'P0001', 'This account is closing.', 'closing: refused the inbox');
select lives_ok($$select t.gate('/rpc/my_restrictions', 'POST')$$, 'closing: can read their own status');
select lives_ok($$select t.gate('/rpc/account_delete_cancel', 'POST')$$, 'closing: can keep the account');
select lives_ok($$select t.gate('/rpc/legal_notice_send', 'POST')$$, 'closing: getting help still works');
select is((public.my_restrictions() ->> 'closing_until')::timestamptz, (select (v ->> 'erase_after')::timestamptz from r1),
  'my_restrictions says when the erase is');
select is((select count(*)::int from public.account_deletions), 1, 'RLS: the player reads their own request');
select t.reset();
select t.as_user('d0000000-0000-0000-0000-000000001117');
select is((select count(*)::int from public.account_deletions), 0, 'RLS: nobody else reads it');
select is((public.my_restrictions() ->> 'closing_until'), null, 'and their own status says nothing');
select throws_ok($$insert into public.account_deletions (user_id, erase_after) values ('d0000000-0000-0000-0000-000000001117', now())$$,
  '42501', null, 'RLS: a request is not written by hand');
select t.reset();
select t.as_anon();
select throws_ok($$select 1 from public.account_deletions$$, '42501', null, 'signed out: nothing');
select t.reset();

-- ─── Keeping the account ───────────────────────────────────────────────────

select t.as_user('d0000000-0000-0000-0000-000000001102');
select lives_ok($$select public.account_delete_cancel()$$, 'the player keeps the account');
select t.reset();
select is(t.closing('d0000000-0000-0000-0000-000000001102'), false, 'it is no longer closing');
select is(private.can_view_profile('d0000000-0000-0000-0000-000000001102', 'd0000000-0000-0000-0000-000000001117'), true,
  'and is visible again');
select is((select cancelled_at is not null from public.account_deletions where user_id = 'd0000000-0000-0000-0000-000000001102'), true,
  'the request records the undo');
select is((select count(*)::int from public.refunds where payment_id = t.id('p1')), 1, 'the refund stands (choice is final)');

-- A moderation hide survives a request and its undo.
select t.request('d0000000-0000-0000-0000-000000001115');
select t.as_user('d0000000-0000-0000-0000-000000001115');
select public.account_delete_cancel();
select t.reset();
select isnt((select hidden_at from public.profiles where id = 'd0000000-0000-0000-0000-000000001115'), null,
  'undo does not unhide what moderation hid');

-- Asking again after an undo works, and the erase can then run.
select t.request('d0000000-0000-0000-0000-000000001102');
select is(t.closing('d0000000-0000-0000-0000-000000001102'), true, 'a new request after an undo closes again');

-- ─── The erase ─────────────────────────────────────────────────────────────

select t.request('d0000000-0000-0000-0000-000000001105');
select is(private.is_restricted('d0000000-0000-0000-0000-000000001106'), false, 'while the parent is only closing, the child is fine');

-- Not due yet: nothing happens.
select is(private.account_erase_due(), 0, 'nothing is erased before its day');

-- The refund has reached the player's card, as the worker and webhook would have done long ago.
select t.settle_refunds(t.id('p1'));
update public.account_deletions set erase_after = now() - interval '1 day'
where user_id in ('d0000000-0000-0000-0000-000000001102', 'd0000000-0000-0000-0000-000000001105',
  'd0000000-0000-0000-0000-000000001112');
select is(private.account_erase_due(), 2, 'two due accounts are erased; the one with an open order waits');

-- The buyer waits for their order, and staff hear about it after a week.
select is((select blocked_reason from public.account_deletions where user_id = 'd0000000-0000-0000-0000-000000001112'), 'shop_order',
  'the open Shop order holds the erase');
select is((select erased_at from public.account_deletions where user_id = 'd0000000-0000-0000-0000-000000001112'), null,
  'so nothing is erased yet');
select is((select count(*)::int from public.money_alerts where key = 'erase-blocked:d0000000-0000-0000-0000-000000001112'), 0,
  'no alert on day one');
update public.account_deletions set blocked_at = now() - interval '8 days' where user_id = 'd0000000-0000-0000-0000-000000001112';
select private.account_erase_due();
select is((select count(*)::int from public.money_alerts where key = 'erase-blocked:d0000000-0000-0000-0000-000000001112'), 1,
  'after a week staff are told');

-- The tombstone.
select is((select full_name from public.profiles where id = 'd0000000-0000-0000-0000-000000001102'), 'Former player', 'the name is gone');
select is((select username from public.profiles where id = 'd0000000-0000-0000-0000-000000001102'), null, 'the username is gone');
select isnt((select erased_at from public.profiles where id = 'd0000000-0000-0000-0000-000000001102'), null, 'the profile says erased');
select is((select mobile from public.account_private where id = 'd0000000-0000-0000-0000-000000001102'), null, 'the mobile is gone');
select is((select birthday from public.account_private where id = 'd0000000-0000-0000-0000-000000001102'), null, 'the birthday is gone');
select is((select count(*)::int from public.player_sports where user_id = 'd0000000-0000-0000-0000-000000001102'), 0, 'sports are gone');
select is((select count(*)::int from public.notifications where user_id = 'd0000000-0000-0000-0000-000000001102'), 0, 'the inbox is gone');
select is((select count(*)::int from auth.users where id = 'd0000000-0000-0000-0000-000000001102'), 1, 'the auth row stays');
select is((select banned_until > now() from auth.users where id = 'd0000000-0000-0000-0000-000000001102'), true, 'and is banned');
select is((select count(*)::int from public.payments where user_id = 'd0000000-0000-0000-0000-000000001102'), 1, 'payments stay (receipts)');
select is((select count(*)::int from public.refunds where payment_id = t.id('p1')), 1, 'refunds stay');
select is(private.points_balance('d0000000-0000-0000-0000-000000001102'), 0::bigint, 'points are forfeited');
select is((select kind from public.points_entries where user_id = 'd0000000-0000-0000-0000-000000001102' order by id desc limit 1),
  'forfeit', 'as a forfeit entry, never a deleted row');
select is((select status from public.vouchers where code = 'DEL-TEST-1'), 'expired', 'the voucher lapses');
select is(private.is_minor('d0000000-0000-0000-0000-000000001102'), false, 'no birthday does not make a Former player a minor');

-- Readers see "Former player".
select t.as_user('d0000000-0000-0000-0000-000000001117');
select is(private.public_name('d0000000-0000-0000-0000-000000001102'), 'Former player', 'the name helper says Former player');
select is(private.masked_name('Former player'), 'Former player', 'the mask leaves it whole');
select lives_ok($$select t.gate('/rpc/shop_products')$$, 'a stranger is not affected by the gate change');
select t.reset();
select t.as_user('d0000000-0000-0000-0000-000000001102');
select throws_ok($$select t.gate('/rpc/my_restrictions', 'POST')$$, 'P0001', 'This account was deleted.',
  'an erased account gets nothing, not even its status');
select t.reset();

-- The family: the only child is back in the shell with records intact; the
-- child with another parent is untouched.
select is((select status from public.guardian_links where parent_id = 'd0000000-0000-0000-0000-000000001105'
  and child_id = 'd0000000-0000-0000-0000-000000001106'), 'ended', 'the link to the erased parent ends');
select is(private.is_restricted('d0000000-0000-0000-0000-000000001106'), true, 'the only child is frozen in the shell');
select is((select full_name from public.profiles where id = 'd0000000-0000-0000-0000-000000001106'), 'Test Player',
  'the child''s own record is intact');
select is((select birthday is not null from public.account_private where id = 'd0000000-0000-0000-0000-000000001106'), true,
  'and so is the child''s birthday');
select is(private.is_restricted('d0000000-0000-0000-0000-000000001108'), false, 'a child with a second parent carries on');

-- ─── An undo that lands while the job runs wins ────────────────────────────

select t.request('d0000000-0000-0000-0000-000000001121');
update public.account_deletions set erase_after = now() - interval '1 day' where user_id = 'd0000000-0000-0000-0000-000000001121';
select t.as_user('d0000000-0000-0000-0000-000000001121');
select public.account_delete_cancel();
select t.reset();
select is(private.account_erase_due(), 0, 'the job skips a kept account');
select lives_ok($$select private.account_erase('d0000000-0000-0000-0000-000000001121')$$,
  'erasing a kept account by its id is harmless');
select is((select full_name from public.profiles where id = 'd0000000-0000-0000-0000-000000001121'), 'Test Player',
  'the kept account keeps its name');
select is((select erased_at from public.profiles where id = 'd0000000-0000-0000-0000-000000001121'), null, 'and is not marked erased');
select is((select erased_at from public.account_deletions where user_id = 'd0000000-0000-0000-0000-000000001121'), null,
  'the cancelled request is never marked erased');
select is((select mobile is not null from public.account_private where id = 'd0000000-0000-0000-0000-000000001121'), true,
  'the mobile stays');
select lives_ok($$select private.account_erase('d0000000-0000-0000-0000-000000001117')$$,
  'erasing an account that never asked is harmless');
select is((select full_name from public.profiles where id = 'd0000000-0000-0000-0000-000000001117'), 'Test Player',
  'a stranger who never asked is untouched');
update public.account_deletions set erased_at = now() - interval '1 hour' where user_id = 'd0000000-0000-0000-0000-000000001102';
select lives_ok($$select private.account_erase('d0000000-0000-0000-0000-000000001102')$$, 'erasing twice is harmless');
select is((select erased_at from public.account_deletions where user_id = 'd0000000-0000-0000-0000-000000001102'),
  now() - interval '1 hour', 'and keeps the first erase time');

-- ─── Cascades corrected (Q139): a hard delete by hand ──────────────────────

insert into ids values ('class', t.class(t.id('academy')));
insert into ids values ('student', t.student(t.id('class'), 'd0000000-0000-0000-0000-000000001116',
  'd0000000-0000-0000-0000-000000001106'));
insert into public.support_requests (user_id, message) values ('d0000000-0000-0000-0000-000000001116', 'Please delete my account.');
insert into public.vouchers (type_id, owner_id, code, status, expires_at, source)
select id, 'd0000000-0000-0000-0000-000000001116', 'DEL-TEST-2', 'used', now() + interval '10 days', 'test:' || gen_random_uuid()
from public.voucher_types limit 1;
insert into ids values ('v2', (select id from public.vouchers where code = 'DEL-TEST-2'));
update public.orders set voucher_id = t.id('v2') where id = t.order_of((select v from ob));

delete from auth.users where id = 'd0000000-0000-0000-0000-000000001116';
select is((select count(*)::int from public.academy_students where id = t.id('student')), 1, 'the child''s enrolment survives the parent');
select is((select parent_id from public.academy_students where id = t.id('student')), null, 'with no parent on it');
select is((select count(*)::int from public.support_requests where message = 'Please delete my account.'), 1,
  'the support request survives');
select is((select count(*)::int from public.orders where id = t.order_of((select v from ob))), 1,
  'an order that used the voucher survives');
select is((select owner_id from public.vouchers where id = t.id('v2')), null, 'the voucher has no owner any more');
delete from public.vouchers where id = t.id('v2');
select is((select count(*)::int from public.orders where id = t.order_of((select v from ob))), 1,
  'removing the voucher itself leaves the order');
select is((select voucher_id from public.orders where id = t.order_of((select v from ob))), null, 'which just loses the link');
select throws_ok($$delete from auth.users where id = 'd0000000-0000-0000-0000-000000001114'$$, '23503', null,
  'an academy owner cannot be hard-deleted under their academy');
select throws_ok($$delete from auth.users where id = 'd0000000-0000-0000-0000-000000001101'$$, '23503', null,
  'a host cannot be hard-deleted under their Meet');

select * from finish();
rollback;
