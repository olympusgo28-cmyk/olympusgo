-- P4a-02: one test per row of the fee and refund tables in RULES.md, rewritten
-- for No Wallet (Q45).
begin;
\ir helpers/setup.psql
select no_plan();

create function t.q(p_purpose text, p_price bigint, p_qty int default 1) returns text language sql as $$
  select (x ->> 'price_minor') || '+' || (x ->> 'fee_minor') || '=' || (x ->> 'total_minor')
  from public.money_quote(p_purpose, p_price, p_qty) x;
$$;
create function t.r(p_reason text, p_price bigint, p_fee bigint, p_method text default 'card') returns text
language sql as $$
  select (x ->> 'refund_minor') || ':' || (x ->> 'organizer_pays_card_fee')
  from public.money_refund_quote(p_reason, p_price, p_fee, p_method) x;
$$;

-- Fee examples.
select is(t.q('meet', 600), '600+200=800', 'Paid Meet: S$6.00 gives S$2.00 and S$8.00');
select is(t.q('tournament', 1500), '1500+200=1700', 'Tournament singles: S$15.00 gives S$17.00');
select is(t.q('tournament', 3000), '3000+300=3300', 'Mixed doubles pair: S$30.00 gives S$3.00 and S$33.00');
select is(t.q('tournament', 6000), '6000+600=6600', 'Team entry: S$60.00 gives S$66.00');
select is(t.q('ticket', 3000), '3000+300=3300', 'Paid ticket: S$30.00 gives S$33.00');
select is(t.q('court', 4400), '4400+440=4840', 'Court, 2 hours: S$44.00 gives S$48.40');
select is(t.q('organizer_fee', 0), '0+200=200', 'Free Meet: S$2.00 charged to the organizer');
select is(t.q('host_spot', 0), '0+200=200', 'Host''s spot on a free Meet: S$2.00');
select is(t.q('host_spot', 3000), '0+200=200', 'Host''s spot on a paid Meet is still S$2.00 (R-FEE-5)');
select is(t.q('meet', 0), '0+200=200', 'Free Meet where players pay: S$2.00 (R-FEE-3b)');
select is(t.q('shop', 4250), '4250+0=4250', 'Shop: no buyer fee');
select is(t.q('meet', 2000), '2000+200=2200', '10% that meets the minimum exactly');
select is(t.q('meet', 2005), '2005+201=2206', '10% rounds half up (R-MON-4)');
select is(t.q('meet', 600, 2), '1200+400=1600', 'A guest pays per seat');
select is(t.q('ticket', 1000, 3), '3000+600=3600', 'Fee is per unit (Q69 default)');
select throws_like($$select public.money_quote('meet', -1)$$, '%negative%', 'A price can''t be negative');
select throws_like($$select public.money_quote('meet', 600, 11)$$, '%how many%', 'Eleven is too many');
select throws_like($$select public.money_quote('wallet', 600)$$, '%Unknown purpose%', 'No such purpose');

-- Refund examples.
select is(t.r('player_in_time', 600, 200), '600:false', 'Player gives up a Meet spot in time: S$6.00');
select is(t.r('host_spot', 0, 200), '200:false', 'Host gives up their spot: S$2.00, no card fee (owner, 31 Oct)');
select is(t.r('organizer_cancelled', 600, 200, 'card'), '800:true', 'Organizer cancels, card: S$8.00, card fee on them');
select is(t.r('organizer_cancelled', 600, 200, 'paynow'), '800:false', 'Organizer cancels, PayNow: S$8.00, no card fee');
select is(t.r('player_in_time', 3000, 300), '3000:false', 'Withdraw before registration closes: S$30.00');
select is(t.r('medical', 3000, 300), '3300:false', 'Withdraw with a medical note: S$33.00');
select is(t.r('player_in_time', 4400, 440), '4400:false', 'Court more than 24 hours before: S$44.00');
select is(t.r('late', 4400, 440), '0:false', 'Court inside 24 hours: S$0.00');
select is(t.r('organizer_cancelled', 4250, 0, 'card'), '4250:true', 'Shop order cancelled by the shop: S$42.50');
select is(t.r('player_in_time', 4250, 0), '4250:false', 'Shop order cancelled in time: S$42.50');
select is(t.r('late', 1000, 200), '0:false', 'Ticket refund asked 6 hours before: S$0.00');
select is(t.r('player_in_time', 0, 200), '0:false', 'Players-pay-fee Meet, in time: S$0.00 (Q68 default)');
select is(t.r('removed_from_club', 600, 200), '800:true', 'Removed from a club: everything (R-REF-13)');
select is(t.r('partner_declined', 3000, 300), '3300:false', 'Partner declines: everything (R-REF-14)');
select is(t.r('event_below_minimum', 3000, 300), '3300:true', 'Below minimum entries: everything (R-REF-16)');
select is(t.r('change_by_organizer', 3000, 300), '3300:true', 'Organizer changes it: everything (R-REF-17)');
select is(t.r('account_deleted', 600, 200), '800:false', 'Account deleted: everything (R-REF-18)');
select is(t.r('late_no_spot', 600, 200), '800:false', 'Paid too late for a spot: everything (Q64 default)');
select throws_like($$select public.money_refund_quote('wallet', 1, 1)$$, '%Unknown refund reason%', 'No such reason');

-- The in-time cut-offs (R-REF-5 to R-REF-7).
select t.player('d0000000-0000-0000-0000-000000000001');
create temp table a on commit drop as select t.meet('d0000000-0000-0000-0000-000000000001') as id;
create function t.in_time(p_purpose text) returns boolean language sql as $$
  select private.refund_in_time(p_purpose, x) from public.activities x where x.id = (select id from a);
$$;
update public.activities set starts_at = now() + interval '2 hours', ends_at = now() + interval '3 hours',
  registration_closes_at = now() - interval '1 hour' where id = (select id from a);
select ok(t.in_time('meet'), 'Meet: in time before the start');
select ok(not t.in_time('ticket'), 'Ticket: late inside 24 hours');
select ok(not t.in_time('tournament'), 'Tournament: late after registration closes');
update public.activities set starts_at = now() + interval '25 hours', ends_at = now() + interval '26 hours',
  registration_closes_at = now() + interval '1 hour' where id = (select id from a);
select ok(t.in_time('ticket'), 'Ticket: in time more than 24 hours before');
select ok(t.in_time('tournament'), 'Tournament: in time until registration closes');
update public.activities set starts_at = now() - interval '1 minute' where id = (select id from a);
select ok(not t.in_time('meet'), 'Meet: late once started');

select * from finish();
rollback;
