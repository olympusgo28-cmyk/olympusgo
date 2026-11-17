begin;
\ir helpers/setup.psql
select plan(9);

-- Fee examples from RULES.md, section 2.
select is(public.platform_fee_cents(600), 200, 'R-FEE-1 S$6.00 pays the S$2.00 minimum');
select is(public.platform_fee_cents(1500), 200, 'R-FEE-1 S$15.00 pays the S$2.00 minimum');
select is(public.platform_fee_cents(3000), 300, 'R-FEE-1 S$30.00 pays S$3.00');
select is(public.platform_fee_cents(6000), 600, 'R-FEE-1 S$60.00 pays S$6.00');
select is(public.platform_fee_cents(4400), 440, 'R-FEE-7 S$44.00 pays S$4.40');
select is(public.platform_fee_cents(0), 0, 'nothing is charged on nothing');
select is(public.platform_fee_cents(2005), 201, 'R-MON-4 a half cent rounds up');

update public.fee_rules set percent_bps = 1500 where currency = 'SGD' and applies_to = 'session';
select is(public.platform_fee_cents(3000), 450, 'the percentage comes from fee_rules');

select t.as_user(t.player('10000000-0000-0000-0000-000000000001'));
update public.fee_rules set percent_bps = 0;
select t.reset();
select is((select percent_bps from public.fee_rules where applies_to = 'session'), 1500, 'players cannot change the fee');

select * from finish();
rollback;
