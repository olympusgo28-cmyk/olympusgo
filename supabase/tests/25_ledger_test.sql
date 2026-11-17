-- P4a-01: the ledger balances, can't be changed, and clients can't reach it.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('b0000000-0000-0000-0000-000000000001');
select t.player('b0000000-0000-0000-0000-000000000002');
select t.player('b0000000-0000-0000-0000-000000000003', 12);

select ok(private.ledger_post('test', 'lk-1', 'SGD', '{}', jsonb_build_array(
  private.ledger_line('clearing', null, 800), private.ledger_line('platform_fees', null, -800))) is not null,
  'a balanced transaction posts');
select is(private.ledger_post('test', 'lk-1', 'SGD', '{}', jsonb_build_array(
  private.ledger_line('clearing', null, 800), private.ledger_line('platform_fees', null, -800))),
  null, 'a repeated key posts nothing');
select is((select count(*)::int from public.ledger_transactions where idempotency_key = 'lk-1'), 1,
  'a repeated key leaves one transaction');
select throws_ok($$select private.ledger_post('test', 'lk-2', 'SGD', '{}', jsonb_build_array(
  private.ledger_line('clearing', null, 800), private.ledger_line('platform_fees', null, -700)))$$,
  'P0001', null, 'lines that don''t sum to zero are refused');
select is(private.ledger_post('test', 'lk-3', 'SGD', '{}', jsonb_build_array(
  private.ledger_line('clearing', null, 0))), null, 'a zero transaction posts nothing');
select ok(t.all_balanced(), 'posted transactions balance at commit');

-- Writing past ledger_post is caught at commit.
savepoint before_bad;
insert into public.ledger_transactions (id, kind, idempotency_key, currency)
values ('b1000000-0000-0000-0000-000000000001', 'test', 'lk-4', 'SGD');
insert into public.ledger_entries (transaction_id, account_id, currency, amount_minor)
select 'b1000000-0000-0000-0000-000000000001', id, 'SGD', 500 from public.ledger_accounts
where kind = 'clearing' and currency = 'SGD';
select throws_like($$set constraints all immediate$$, '%does not balance%',
  'one-sided entries fail the deferred check');
rollback to before_bad;
set constraints all deferred;

select throws_like($$update public.ledger_entries set amount_minor = 1$$, '%append-only%',
  'entries can''t be changed');
select throws_like($$delete from public.ledger_entries$$, '%append-only%', 'entries can''t be deleted');
select throws_like($$truncate public.ledger_entries cascade$$, '%append-only%', 'entries can''t be truncated');
select throws_like($$update public.ledger_transactions set kind = 'x'$$, '%append-only%',
  'transactions can''t be changed');

-- A paid player, for the guards.
create temp table m on commit drop as
  select t.paid_meet('b0000000-0000-0000-0000-000000000001') as meet;
grant select on m to anon, authenticated;
create temp table pay on commit drop as
  select t.paid('b0000000-0000-0000-0000-000000000002', (select meet from m)) as id;
grant select on pay to anon, authenticated;

select throws_like($$update public.payments set price_minor = 1 where id = (select id from pay)$$,
  '%amounts can%', 'a payment''s amounts can''t change');
select throws_like($$update public.payments set status = 'pending' where id = (select id from pay)$$,
  '%can''t go from succeeded to pending%', 'a payment can''t go back');
select throws_like($$delete from public.payments where id = (select id from pay)$$, '%never deleted%',
  'payments can''t be deleted');

-- The cap.
select throws_like($$insert into public.refunds (payment_id, reason, price_minor, idempotency_key)
  values ((select id from pay), 'staff', 601, 'cap-1')$$, '%can''t exceed%', 'one refund can''t pass the price');
select throws_like($$insert into public.refunds (payment_id, reason, fee_minor, idempotency_key)
  values ((select id from pay), 'staff', 201, 'cap-2')$$, '%can''t exceed%', 'one refund can''t pass the fee');
select lives_ok($$insert into public.refunds (payment_id, reason, price_minor, idempotency_key)
  values ((select id from pay), 'staff', 400, 'cap-3')$$, 'a partial refund is fine');
select throws_like($$insert into public.refunds (payment_id, reason, price_minor, idempotency_key)
  values ((select id from pay), 'staff', 201, 'cap-4')$$, '%can''t exceed%', 'refunds add up against the cap');
select lives_ok($$insert into public.refunds (payment_id, reason, price_minor, idempotency_key)
  values ((select id from pay), 'staff', 200, 'cap-5')$$, 'the rest of the price is fine');
select lives_ok($$update public.refunds set status = 'failed' where idempotency_key = 'cap-5'$$,
  'a refund can fail');
select throws_like($$insert into public.refunds (payment_id, reason, price_minor, idempotency_key)
  values ((select id from pay), 'staff', 1, 'cap-6')$$, '%can''t exceed%', 'a failed refund still counts');
select throws_like($$delete from public.refunds where idempotency_key = 'cap-5'$$, '%never deleted%',
  'refunds can''t be deleted');
select throws_like($$update public.refunds set price_minor = 1 where idempotency_key = 'cap-5'$$,
  '%amounts can%', 'a refund''s amounts can''t change');

-- Who can read what.
select t.as_anon();
select throws_ok($$select 1 from public.payments$$, '42501', null, 'signed out: no payments');
select throws_ok($$select 1 from public.ledger_entries$$, '42501', null, 'signed out: no ledger');
select throws_ok($$select 1 from public.refunds$$, '42501', null, 'signed out: no refunds');
select t.reset();

select t.as_user('b0000000-0000-0000-0000-000000000002');
select is((select count(*)::int from public.payments where id = (select id from pay)), 1, 'owner: reads their payment');
select is((select count(*)::int from public.refunds where payment_id = (select id from pay)), 2, 'owner: reads their refunds');
select throws_ok($$select 1 from public.ledger_entries$$, '42501', null, 'owner: no ledger');
select throws_ok($$select 1 from public.ledger_accounts$$, '42501', null, 'owner: no accounts');
select throws_ok($$select 1 from public.stripe_events$$, '42501', null, 'owner: no event log');
select throws_ok($$select 1 from public.money_alerts$$, '42501', null, 'owner: no alerts');
select throws_ok($$select 1 from public.payouts$$, '42501', null, 'owner: no payouts');
select throws_ok($$select 1 from public.payment_customers$$, '42501', null, 'owner: no customers table');
select throws_ok($$update public.payments set status = 'cancelled' where id = (select id from pay)$$,
  '42501', null, 'owner: can''t write a payment');
select throws_ok($$insert into public.refunds (payment_id, reason, price_minor, idempotency_key)
  values ((select id from pay), 'staff', 1, 'hack')$$, '42501', null, 'owner: can''t write a refund');
select throws_ok($$select private.ledger_post('x', 'x', 'SGD', '{}', '[]')$$, '42501', null,
  'owner: can''t post to the ledger');
select throws_ok($$select public.money_svc_event('{}')$$, '42501', null, 'owner: can''t send an event');
select throws_ok($$select public.money_svc_result('refund', gen_random_uuid(), true)$$, '42501', null,
  'owner: can''t report a result');
select throws_ok($$select public.money_svc_work()$$, '42501', null, 'owner: can''t read the worker''s list');
select t.reset();

select t.as_user('b0000000-0000-0000-0000-000000000001');
select is_empty($$select 1 from public.payments where id = (select id from pay)$$,
  'organizer: payment rows are the player''s own');
select t.reset();

select t.as_user('b0000000-0000-0000-0000-000000000003');
select is_empty($$select 1 from public.payments where id = (select id from pay)$$, 'minor: no one else''s payment');
select t.reset();

select ok(t.all_balanced(), 'everything above balances');
select * from finish();
rollback;
