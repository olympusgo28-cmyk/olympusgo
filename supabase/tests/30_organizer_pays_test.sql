-- Free Meets where the organizer pays (owner, 31 Oct): a saved card first, S$2.00
-- per join, and a failed charge becomes a debt the player never feels.
begin;
\ir helpers/setup.psql
\ir helpers/money.psql
select no_plan();

select t.player('a1000000-0000-0000-0000-000000000001');  -- organizer
select t.player('a1000000-0000-0000-0000-000000000002');
select t.player('a1000000-0000-0000-0000-000000000003');
select t.player('a1000000-0000-0000-0000-000000000004', 15);  -- teen

insert into public.guardian_links (child_id, parent_id, status)
values ('a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000003', 'approved');

create temp table ids (name text primary key, id uuid) on commit drop;
grant all on ids to anon, authenticated;
create function t.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name; $$;
grant execute on function t.id(text) to anon, authenticated;
create function t.publish_free(p_host uuid) returns uuid language plpgsql as $$
declare
  v_id uuid;
begin
  perform t.as_user(p_host);
  insert into public.activities (kind, host_id, title, sports, game_type, format, starts_at, ends_at, venue_id, capacity)
  select 'meet', p_host, 'Free Meet', '{badminton}', 'doubles', 'open_play', now() + interval '2 days',
    now() + interval '2 days 2 hours', v.id, 8 from public.venues v order by v.name limit 1
  returning id into v_id;
  perform t.reset();
  return v_id;
end;
$$;
create function t.save_card(p_user uuid, p_method text default 'pm_local_card') returns text language sql as $$
  select t.event('setup_intent.succeeded', jsonb_build_object('id', 'seti_' || p_user, 'customer', 'cus_' || p_user,
    'payment_method', p_method, 'card_brand', 'visa', 'card_last4', '4242',
    'metadata', jsonb_build_object('user_id', p_user)));
$$;
create function t.join(p_user uuid, p_activity uuid) returns text language plpgsql as $$
declare
  v text;
begin
  perform t.as_user(p_user);
  v := public.join_activity(p_activity);
  perform t.reset();
  return v;
end;
$$;
create function t.fee_payment(p_activity uuid, p_player uuid) returns uuid language sql as $$
  select id from public.payments where activity_id = p_activity and beneficiary_id = p_player
  order by created_at desc limit 1;
$$;

select throws_ok($$select t.publish_free('a1000000-0000-0000-0000-000000000001')$$, 'P0001', 'card_required',
  'no saved card, no organizer-pays Meet');
select t.reset();
select is(t.save_card('a1000000-0000-0000-0000-000000000001'), 'card_saved', 'Stripe confirms the saved card');
select t.as_user('a1000000-0000-0000-0000-000000000001');
select is(public.money_my_card() ->> 'last4', '4242', 'the organizer sees the last four digits');
select t.reset();
select throws_like($$select t.publish_free('a1000000-0000-0000-0000-000000000004')$$, '%under 18%',
  'a teen can''t publish an organizer-pays Meet');
select t.reset();
insert into ids values ('m1', t.publish_free('a1000000-0000-0000-0000-000000000001'));
select ok(t.id('m1') is not null, 'with a card it publishes');

-- A join queues the fee, and the worker charges it.
select is(t.join('a1000000-0000-0000-0000-000000000002', t.id('m1')), 'joined', 'the player just joins');
insert into ids values ('f1', t.fee_payment(t.id('m1'), 'a1000000-0000-0000-0000-000000000002'));
select is((select user_id from public.payments where id = t.id('f1')), 'a1000000-0000-0000-0000-000000000001'::uuid, 'the organizer is charged');
select is((select amount_minor from public.payments where id = t.id('f1')), 200::bigint, 'S$2.00');
select ok((public.money_svc_work() -> 'organizer_fees') @> jsonb_build_array(jsonb_build_object('payment_id', t.id('f1'))),
  'the worker picks it up');
select public.money_svc_result('organizer_fee', t.id('f1'), true, 'pi_f1');
select ok(not ((public.money_svc_work() -> 'organizer_fees') @> jsonb_build_array(jsonb_build_object('payment_id', t.id('f1')))),
  'and doesn''t charge it twice');
select is(t.succeed(t.id('f1')), 'captured', 'the webhook confirms it');

-- Leaving in time gives the fee back, with no card fee on the organizer.
select t.as_user('a1000000-0000-0000-0000-000000000002');
select public.leave_activity(t.id('m1'));
select t.reset();
select is(t.refunded(t.id('f1')), 200::bigint, 'a player leaving returns the S$2.00 (R-FEE-3)');
select is((select reason from public.refunds where payment_id = t.id('f1')), 'player_left', 'as a player leaving');
select is((select organizer_pays_fee from public.refunds where payment_id = t.id('f1')), false, 'with no card fee on them');

-- A failed charge: the player stays, the organizer owes it.
select is(t.join('a1000000-0000-0000-0000-000000000003', t.id('m1')), 'joined', 'another player joins');
insert into ids values ('f2', t.fee_payment(t.id('m1'), 'a1000000-0000-0000-0000-000000000003'));
select public.money_svc_result('organizer_fee', t.id('f2'), false, null, 'card_declined');
select is(t.status_pay(t.id('f2')), 'debt', 'a failed charge becomes a debt');
select is(t.status_of(t.id('m1'), 'a1000000-0000-0000-0000-000000000003'), 'joined', 'the player keeps the spot');
select is(t.bal('organizer_fee_debt', 'a1000000-0000-0000-0000-000000000001'), 200::bigint, 'S$2.00 owed');
select ok(exists (select 1 from public.notifications where user_id = 'a1000000-0000-0000-0000-000000000001'
  and title = 'We couldn''t charge your card'), 'the organizer is told');
select throws_ok($$select t.publish_free('a1000000-0000-0000-0000-000000000001')$$, 'P0001', 'fee_debt',
  'a debt blocks the next organizer-pays Meet');
select t.reset();

-- Paying it clears the block.
select t.as_user('a1000000-0000-0000-0000-000000000001');
select is(public.money_my_earnings() ->> 'fee_debt_minor', '200', 'the organizer sees what they owe');
insert into ids values ('d1', (public.organizer_debt_reserve('clear-debt-key') ->> 'payment_id')::uuid);
select t.reset();
select is((select amount_minor from public.payments where id = t.id('d1')), 200::bigint, 'the amount owed');
select is(t.succeed(t.id('d1')), 'captured', 'paying it is confirmed by the webhook');
select is(t.bal('organizer_fee_debt', 'a1000000-0000-0000-0000-000000000001'), 0::bigint, 'nothing owed');
select ok(t.publish_free('a1000000-0000-0000-0000-000000000001') is not null, 'and the block is gone');

-- A debt reverses if the player leaves in time.
insert into ids values ('m2', t.publish_free('a1000000-0000-0000-0000-000000000001'));
select t.join('a1000000-0000-0000-0000-000000000002', t.id('m2'));
insert into ids values ('f3', t.fee_payment(t.id('m2'), 'a1000000-0000-0000-0000-000000000002'));
select public.money_svc_result('organizer_fee', t.id('f3'), false, null, 'card_declined');
select is(t.bal('organizer_fee_debt', 'a1000000-0000-0000-0000-000000000001'), 200::bigint, 'owed again');
select t.as_user('a1000000-0000-0000-0000-000000000002');
select public.leave_activity(t.id('m2'));
select t.reset();
select is(t.bal('organizer_fee_debt', 'a1000000-0000-0000-0000-000000000001'), 0::bigint, 'the player leaving cancels the debt');
select is(t.status_pay(t.id('f3')), 'cancelled', 'and closes it');

-- Cancelling returns the organizer's own fees (Q71 default).
insert into ids values ('m3', t.publish_free('a1000000-0000-0000-0000-000000000001'));
select t.join('a1000000-0000-0000-0000-000000000002', t.id('m3'));
insert into ids values ('f4', t.fee_payment(t.id('m3'), 'a1000000-0000-0000-0000-000000000002'));
select public.money_svc_result('organizer_fee', t.id('f4'), true, 'pi_f4');
select t.succeed(t.id('f4'));
select t.as_user('a1000000-0000-0000-0000-000000000001');
select public.cancel_activity(t.id('m3'), false, null);
select t.reset();
select is(t.refunded(t.id('f4')), 200::bigint, 'cancelling returns the organizer''s fees');

-- No card by the time the worker runs.
insert into ids values ('m4', t.publish_free('a1000000-0000-0000-0000-000000000001'));
delete from public.payment_customers where user_id = 'a1000000-0000-0000-0000-000000000001';
select t.join('a1000000-0000-0000-0000-000000000003', t.id('m4'));
insert into ids values ('f5', t.fee_payment(t.id('m4'), 'a1000000-0000-0000-0000-000000000003'));
select public.money_svc_result('organizer_fee', t.id('f5'), false, null, 'no_card');
select is(t.status_pay(t.id('f5')), 'debt', 'a removed card also becomes a debt');

-- Players-pay-fee: each player pays the S$2.00.
insert into ids values ('m5', t.meet('a1000000-0000-0000-0000-000000000001'));
update public.activities set players_pay_fee = true where id = t.id('m5');
select t.as_user('a1000000-0000-0000-0000-000000000002');
select throws_ok(format($$select public.join_activity(%L)$$, t.id('m5')), 'P0001', 'payment_required', 'a players-pay Meet needs a payment');
select t.reset();
insert into ids values ('pf', t.paid('a1000000-0000-0000-0000-000000000002', t.id('m5')));
select is((select amount_minor from public.payments where id = t.id('pf')), 200::bigint, 'S$2.00');
select t.as_user('a1000000-0000-0000-0000-000000000001');
select is((public.cancel_preview(t.id('m5')) ->> 'each_cents')::int, 200, 'the preview shows the S$2.00');
select t.reset();

-- Free tickets.
insert into ids values ('e1', t.event_meet('a1000000-0000-0000-0000-000000000001', 0, 10));
select t.as_user('a1000000-0000-0000-0000-000000000002');
select public.event_ticket_buy(t.id('e1'), 2);
select t.reset();
select is((select amount_minor from public.payments where activity_id = t.id('e1') and purpose = 'organizer_fee'), 400::bigint,
  'two free tickets cost the organizer S$4.00 (R-FEE-4)');

select ok(t.all_balanced(), 'every transaction here balances');
select * from finish();
rollback;
