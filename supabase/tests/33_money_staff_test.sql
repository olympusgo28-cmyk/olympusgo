-- A-06: only payments staff reach money, and every write is audited.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('a4000000-0000-0000-0000-000000000001');  -- host
select t.player('a4000000-0000-0000-0000-000000000002');  -- player
select t.player('a4000000-0000-0000-0000-000000000003');  -- payments staff
select t.player('a4000000-0000-0000-0000-000000000004');  -- moderator
select t.player('a4000000-0000-0000-0000-000000000005', 12);

insert into public.staff (user_id, role) values
  ('a4000000-0000-0000-0000-000000000003', 'payments'),
  ('a4000000-0000-0000-0000-000000000004', 'moderator');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;

insert into ids values ('m1', t.paid_meet('a4000000-0000-0000-0000-000000000001'));
insert into ids values ('p1', t.paid('a4000000-0000-0000-0000-000000000002', t.id('m1')));

create temp table calls (sql text) on commit drop;
grant select on calls to anon, authenticated;
insert into calls values
  ('select public.staff_money_overview()'), ('select public.staff_payment_list()'),
  ('select public.staff_refund_list()'), ('select public.staff_held_list()'),
  ('select public.staff_payout_list()'), ('select public.staff_dispute_list()'),
  ('select public.staff_alert_list()');

create function t.refused_all() returns int language plpgsql as $$
declare
  c record;
  n int := 0;
begin
  for c in select sql from calls loop
    begin
      execute c.sql;
    exception when others then
      n := n + 1;
    end;
  end loop;
  return n;
end;
$$;
grant execute on function t.refused_all() to anon, authenticated;

select t.as_user('a4000000-0000-0000-0000-000000000002');
select is(t.refused_all(), 7, 'a player reads none of it');
select t.reset();
select t.as_user('a4000000-0000-0000-0000-000000000005');
select is(t.refused_all(), 7, 'a minor reads none of it');
select t.reset();
select t.as_staff('a4000000-0000-0000-0000-000000000004');
select is(t.refused_all(), 7, 'a moderator reads none of it');
select t.reset();
select t.as_staff('a4000000-0000-0000-0000-000000000003', false);
select is(t.refused_all(), 7, 'payments staff without MFA read none of it');
select t.reset();
select t.as_anon();
select is(t.refused_all(), 7, 'signed out reads none of it');
select t.reset();
select t.as_staff('a4000000-0000-0000-0000-000000000003');
select is(t.refused_all(), 0, 'payments staff read all of it');

select is((public.staff_payment_get(t.id('p1')) ->> 'amount_minor')::int, 800, 'a payment opens');
select ok(jsonb_array_length(public.staff_payment_get(t.id('p1')) -> 'ledger') >= 3, 'with its ledger lines');
select ok(public.staff_held_list() @> jsonb_build_array(jsonb_build_object('activity_id', t.id('m1'), 'held_minor', 600)), 'held money is listed');

-- Staff refund.
select throws_like(format($$select public.staff_refund_issue(%L, 'x')$$, t.id('p1')), '%', 'a reason is required');
select is(public.staff_refund_issue(t.id('p1'), 'Player was overcharged'), 800::bigint, 'staff can refund what''s left');
select throws_like(format($$select public.staff_refund_issue(%L, 'again please')$$, t.id('p1')), '%nothing left%', 'and not twice');
select t.reset();
select ok(exists (select 1 from public.admin_audit where action = 'refund' and target_id = t.id('p1')::text), 'it''s audited');

-- Failed: retry, void, or record a bank transfer.
create temp table rid on commit drop as select id from public.refunds where payment_id = t.id('p1');
grant select on rid to anon, authenticated;
update public.refunds set status = 'failed' where id = (select id from rid);
select t.as_staff('a4000000-0000-0000-0000-000000000003');
select public.staff_refund_retry((select id from rid), 'Card reissued');
select t.reset();
select is((select status from public.refunds where id = (select id from rid)), 'pending', 'a failed refund can be retried');

update public.refunds set status = 'failed' where id = (select id from rid);
select t.as_staff('a4000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.staff_refund_manual(%L, '', 'Paid by bank')$$, (select id from rid)), '%reference%', 'a manual refund needs a reference');
select public.staff_refund_void((select id from rid), 'Sent to the wrong payment');
select throws_like(format($$select public.staff_refund_void(%L, 'again please')$$, (select id from rid)), '%can be voided%', 'a refund voids once');
select t.reset();
select is(t.refunded(t.id('p1')), 0::bigint, 'a voided refund no longer counts');
select is(t.bal('held', t.id('m1')), -600::bigint, 'and the price is held again');

-- Refund again after voiding, then record a bank transfer.
select t.as_staff('a4000000-0000-0000-0000-000000000003');
select is(public.staff_refund_issue(t.id('p1'), 'Trying again'), 800::bigint, 'the money can be refunded after a void');
select t.reset();
create temp table rid2 on commit drop as select id from public.refunds where payment_id = t.id('p1') and status = 'pending';
grant select on rid2 to anon, authenticated;
update public.refunds set status = 'failed' where id = (select id from rid2);
select t.as_staff('a4000000-0000-0000-0000-000000000003');
select public.staff_refund_manual((select id from rid2), 'BANK-123', 'PayNow refund failed');
select t.reset();
select is((select status from public.refunds where id = (select id from rid2)), 'manual', 'recorded as paid by hand');

-- Alerts.
select private.money_alert('test', 'test-alert-1');
create temp table aid on commit drop as select id from public.money_alerts where key = 'test-alert-1';
grant select on aid to anon, authenticated;
select t.as_user('a4000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.staff_alert_close(%L, 'mine now')$$, (select id from aid)), 'Not found%', 'a player can''t close an alert');
select t.reset();
select t.as_staff('a4000000-0000-0000-0000-000000000003');
select public.staff_alert_close((select id from aid), 'Checked with finance');
select throws_like(format($$select public.staff_alert_close(%L, 'again please')$$, (select id from aid)), '%closed%', 'an alert closes once');
select t.reset();

-- Every staff write goes through the Edge Function's list, and none is open to anon.
select is_empty($$select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname like 'staff\_%' and has_function_privilege('anon', p.oid, 'execute')$$,
  'no staff function is open to signed-out callers');

select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
