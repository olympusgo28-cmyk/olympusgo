-- P4a-07, P4a-08: payout runs and reconciliation.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('a2000000-0000-0000-0000-000000000001');  -- organizer
select t.player('a2000000-0000-0000-0000-000000000002');
select t.player('a2000000-0000-0000-0000-000000000003');  -- staff
select t.player('a2000000-0000-0000-0000-000000000004');  -- staff
select t.player('a2000000-0000-0000-0000-000000000005');  -- unverified organizer
select t.player('a2000000-0000-0000-0000-000000000006', 15);

insert into public.staff (user_id, role) values
  ('a2000000-0000-0000-0000-000000000003', 'payments'),
  ('a2000000-0000-0000-0000-000000000004', 'payments');
insert into public.vendors (owner_id, stripe_account_id, status) values
  ('a2000000-0000-0000-0000-000000000001', 'acct_1', 'verified'),
  ('a2000000-0000-0000-0000-000000000005', 'acct_5', 'pending');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;
create function t.earn(p_host uuid, p_player uuid, p_price int default 600) returns uuid language plpgsql as $$
declare
  v_meet uuid := t.paid_meet(p_host, p_price);
begin
  perform t.paid(p_player, v_meet);
  perform private.release_activity(v_meet);
  return v_meet;
end;
$$;
create function t.item(p_run uuid, p_owner uuid) returns uuid language sql as $$
  select id from public.payout_items where payout_id = p_run and owner_id = p_owner;
$$;

select t.earn('a2000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000002');
select t.earn('a2000000-0000-0000-0000-000000000005', 'a2000000-0000-0000-0000-000000000002');
-- A week of its own, clear of any run on a dirty database.
insert into ids values ('r1', private.payouts_prepare('SGD', '2099-01-05'));
select ok(t.id('r1') is not null, 'a run is prepared');
select is(private.payouts_prepare('SGD', '2099-01-05'), null, 'one run a week');
select is((select amount_minor from public.payout_items where id = t.item(t.id('r1'), 'a2000000-0000-0000-0000-000000000001')),
  600::bigint, 'the organizer''s earnings are in it');
select is(t.item(t.id('r1'), 'a2000000-0000-0000-0000-000000000005'), null, 'an unverified vendor is left out (R-PAY-4)');
select is(t.bal('organizer', 'a2000000-0000-0000-0000-000000000001'), -600::bigint, 'preparing moves nothing');

-- Roles.
select t.as_user('a2000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.staff_payout_approve(%L, 'mine')$$, t.id('r1')), 'Not found%', 'a player can''t approve');
select t.reset();
select t.as_staff('a2000000-0000-0000-0000-000000000003', false);
select throws_like(format($$select public.staff_payout_approve(%L, 'no mfa')$$, t.id('r1')), 'Not found%', 'staff need MFA');
select t.reset();

-- Fees owed net against the payout.
select private.ledger_post('test', 'net-1-' || gen_random_uuid(), 'SGD', '{}', jsonb_build_array(
  private.ledger_line('card_fee_recovery', 'a2000000-0000-0000-0000-000000000001', 77),
  private.ledger_line('processor_fees', null, -77)));
select private.ledger_post('test', 'net-2-' || gen_random_uuid(), 'SGD', '{}', jsonb_build_array(
  private.ledger_line('organizer_fee_debt', 'a2000000-0000-0000-0000-000000000001', 200),
  private.ledger_line('platform_fees', null, -200)));

select t.as_staff('a2000000-0000-0000-0000-000000000003');
select is(public.staff_payout_approve(t.id('r1'), 'Weekly run'), 'approved', 'one approver is enough below the threshold');
select t.reset();
select is((select amount_minor from public.payout_items where id = t.item(t.id('r1'), 'a2000000-0000-0000-0000-000000000001')),
  323::bigint, 'S$6.00 less S$2.00 and S$0.77 owed');
select is(t.bal('organizer', 'a2000000-0000-0000-0000-000000000001'), 0::bigint, 'earnings are paid down');
select is(t.bal('organizer_fee_debt', 'a2000000-0000-0000-0000-000000000001'), 0::bigint, 'the debt clears');
select is(t.bal('card_fee_recovery', 'a2000000-0000-0000-0000-000000000001'), 0::bigint, 'and the card fee');
select t.as_staff('a2000000-0000-0000-0000-000000000004');
select throws_like(format($$select public.staff_payout_approve(%L, 'again')$$, t.id('r1')), '%closed%', 'a run approves once');
select t.reset();

-- The worker transfers.
select ok((public.money_svc_work() -> 'transfers') @> jsonb_build_array(jsonb_build_object('account', 'acct_1')), 'the worker picks up the transfer');
select public.money_svc_result('transfer', t.item(t.id('r1'), 'a2000000-0000-0000-0000-000000000001'), false, null, 'balance_insufficient');
select is((select status from public.payout_items where id = t.item(t.id('r1'), 'a2000000-0000-0000-0000-000000000001')), 'pending',
  'funds still arriving means try again');
select public.money_svc_result('transfer', t.item(t.id('r1'), 'a2000000-0000-0000-0000-000000000001'), true, 'tr_1');
select is((select status from public.payout_items where id = t.item(t.id('r1'), 'a2000000-0000-0000-0000-000000000001')), 'sent', 'then it''s sent');
select public.money_svc_result('transfer', t.item(t.id('r1'), 'a2000000-0000-0000-0000-000000000001'), true, 'tr_1');
select is((select count(*)::int from public.ledger_transactions
  where idempotency_key = 'transfer:' || t.item(t.id('r1'), 'a2000000-0000-0000-0000-000000000001')), 1, 'posted once');

-- A failed transfer returns the money.
select t.earn('a2000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000002');
insert into ids values ('r2', private.payouts_prepare('SGD', '2099-01-12'));
select t.as_staff('a2000000-0000-0000-0000-000000000003');
select public.staff_payout_approve(t.id('r2'), 'Weekly run');
select t.reset();
select public.money_svc_result('transfer', t.item(t.id('r2'), 'a2000000-0000-0000-0000-000000000001'), false, null, 'account_closed');
select is(t.bal('organizer', 'a2000000-0000-0000-0000-000000000001'), -600::bigint, 'a failed transfer returns the money');
select ok(exists (select 1 from public.money_alerts where key = 'payout-failed:' || t.item(t.id('r2'), 'a2000000-0000-0000-0000-000000000001')), 'with an alert');

-- Above the threshold: two different people.
update public.app_settings set value = '100' where key = 'payout.second_approver_minor';
insert into ids values ('r3', private.payouts_prepare('SGD', '2099-01-19'));
select t.as_staff('a2000000-0000-0000-0000-000000000003');
select is(public.staff_payout_approve(t.id('r3'), 'First look'), 'needs_second', 'a large run needs a second approver');
select throws_like(format($$select public.staff_payout_approve(%L, 'me again')$$, t.id('r3')), '%second staff%', 'and not the same person');
select t.reset();
select is(t.bal('organizer', 'a2000000-0000-0000-0000-000000000001'), -600::bigint, 'nothing moves after one approval');
select t.as_staff('a2000000-0000-0000-0000-000000000004');
select is(public.staff_payout_approve(t.id('r3'), 'Second look'), 'approved', 'a second person approves it');
select t.reset();
select is(t.bal('organizer', 'a2000000-0000-0000-0000-000000000001'), 0::bigint, 'and the money moves');
update public.app_settings set value = '500000' where key = 'payout.second_approver_minor';

-- Earnings can fall between prepare and approve.
select t.earn('a2000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000002');
insert into ids values ('r4', private.payouts_prepare('SGD', '2099-01-26'));
select private.ledger_post('test', 'net-3-' || gen_random_uuid(), 'SGD', '{}', jsonb_build_array(
  private.ledger_line('organizer', 'a2000000-0000-0000-0000-000000000001', 600),
  private.ledger_line('refunds_pending', null, -600)));
select t.as_staff('a2000000-0000-0000-0000-000000000003');
select public.staff_payout_approve(t.id('r4'), 'Weekly run');
select t.reset();
select is((select status from public.payout_items where id = t.item(t.id('r4'), 'a2000000-0000-0000-0000-000000000001')), 'dropped',
  'approval rechecks the balance');

-- An unapproved run gives way to the next.
insert into ids values ('r5', private.payouts_prepare('SGD', '2099-02-02'));
insert into ids values ('r6', private.payouts_prepare('SGD', '2099-02-09'));
select is((select status from public.payouts where id = t.id('r5')), 'superseded', 'an old draft is replaced');
select t.as_staff('a2000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.staff_payout_approve(%L, 'old')$$, t.id('r5')), '%closed%', 'and can''t be approved');
select t.reset();

-- A suspended owner waits.
select t.earn('a2000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000002');
insert into public.account_moderation (user_id, suspended_until)
values ('a2000000-0000-0000-0000-000000000001', now() + interval '1 day');
insert into ids values ('r7', private.payouts_prepare('SGD', '2099-02-16'));
select is(t.item(t.id('r7'), 'a2000000-0000-0000-0000-000000000001'), null, 'a suspended owner is left out');
delete from public.account_moderation where user_id = 'a2000000-0000-0000-0000-000000000001';

-- Vendors.
select t.as_user('a2000000-0000-0000-0000-000000000006');
select throws_like($$select public.vendor_start()$$, '%adults only%', 'a minor can''t be a vendor');
select t.reset();
select t.as_user('a2000000-0000-0000-0000-000000000002');
select is(public.vendor_start() ->> 'status', 'pending', 'an adult can start');
select is_empty($$select 1 from public.vendors where owner_id = 'a2000000-0000-0000-0000-000000000001'$$, 'and sees only their own');
select public.vendor_set_schedule('monthly');
select throws_ok($$select public.vendor_set_schedule('hourly')$$, '23514', null, 'schedules are a fixed list');
select t.reset();
select t.event('account.updated', jsonb_build_object('id', 'acct_5', 'payouts_enabled', true));
select is((select status from public.vendors where owner_id = 'a2000000-0000-0000-0000-000000000005'), 'verified', 'Stripe verifies the vendor');

-- Reconciliation.
select is((public.money_svc_reconcile_save(3, 1, jsonb_build_array(jsonb_build_object('source', 'ch_recon_test', 'kind', 'fee'))) is not null), true, 'a run is saved');
select ok(exists (select 1 from public.money_alerts where key = 'recon:ch_recon_test:fee' and kind = 'reconciliation'), 'a mismatch raises an alert');
select public.money_svc_reconcile_save(3, 1, jsonb_build_array(jsonb_build_object('source', 'ch_recon_test', 'kind', 'fee')));
select is((select count(*)::int from public.money_alerts where key = 'recon:ch_recon_test:fee'), 1, 'the same mismatch alerts once');
select ok(jsonb_array_length(public.money_svc_ledger_rows(now() - interval '1 hour')) > 0, 'the ledger gives Stripe''s ids');

select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
