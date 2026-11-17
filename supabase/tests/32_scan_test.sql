-- P4a-09: Scan resolves players, groups, venues and vendors, within the
-- visibility rules. No minor can look anyone up.
begin;
\ir helpers/setup.psql
select no_plan();

select t.player('a3000000-0000-0000-0000-000000000001');
select t.player('a3000000-0000-0000-0000-000000000002');
select t.player('a3000000-0000-0000-0000-000000000003', 15);
select t.player('a3000000-0000-0000-0000-000000000004', 12);
select t.player('a3000000-0000-0000-0000-000000000005');  -- vendor

insert into public.guardian_links (child_id, parent_id, status) values
  ('a3000000-0000-0000-0000-000000000003', 'a3000000-0000-0000-0000-000000000001', 'approved'),
  ('a3000000-0000-0000-0000-000000000004', 'a3000000-0000-0000-0000-000000000001', 'approved');

insert into public.clubs (id, name, owner_id, visibility) values
  ('a3100000-0000-0000-0000-000000000001', 'Open club', 'a3000000-0000-0000-0000-000000000001', 'public'),
  ('a3100000-0000-0000-0000-000000000002', 'Private club', 'a3000000-0000-0000-0000-000000000001', 'private');
insert into public.club_members (club_id, user_id) values
  ('a3100000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001'),
  ('a3100000-0000-0000-0000-000000000002', 'a3000000-0000-0000-0000-000000000001')
on conflict do nothing;

create temp table tokens (name text primary key, token text) on commit drop;
grant all on tokens to anon, authenticated;
create function t.tk(p_name text) returns text language sql as $$ select token from tokens where name = p_name; $$;
grant execute on function t.tk(text) to anon, authenticated;

select t.as_user('a3000000-0000-0000-0000-000000000001');
insert into tokens values ('player', public.my_qr()),
  ('open', public.club_qr('a3100000-0000-0000-0000-000000000001')),
  ('private', public.club_qr('a3100000-0000-0000-0000-000000000002'));
select t.reset();

select t.as_user('a3000000-0000-0000-0000-000000000002');
select is(public.resolve_qr(t.tk('player')) ->> 'kind', 'player', 'a player''s code opens the player');
select is(public.resolve_qr(t.tk('open')), jsonb_build_object('kind', 'group', 'id', 'a3100000-0000-0000-0000-000000000001'), 'a group''s code opens the group');
select throws_like(format($$select public.resolve_qr(%L)$$, t.tk('private')), '%isn''t valid%', 'a private group stays private');
select throws_like($$select public.resolve_qr('nonsense')$$, '%isn''t valid%', 'a made-up code fails');
select throws_like($$select public.club_qr('a3100000-0000-0000-0000-000000000001')$$, '%', 'only people who manage members get the group''s code');
select t.reset();

-- Rotating.
select t.as_user('a3000000-0000-0000-0000-000000000001');
insert into tokens values ('open2', public.club_qr('a3100000-0000-0000-0000-000000000001', true));
select is(public.club_qr('a3100000-0000-0000-0000-000000000001'), t.tk('open2'), 'without rotating, the code stays the same');
select t.reset();
select t.as_user('a3000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.resolve_qr(%L)$$, t.tk('open')), '%isn''t valid%', 'a rotated group code stops working');
select is(public.resolve_qr(t.tk('open2')) ->> 'kind', 'group', 'the new one works');
select t.reset();

select t.as_user('a3000000-0000-0000-0000-000000000001');
insert into tokens values ('player2', public.rotate_my_qr());
select t.reset();
select t.as_user('a3000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.resolve_qr(%L)$$, t.tk('player')), '%isn''t valid%', 'a rotated player code stops working');
select t.reset();

-- Blocks.
insert into public.blocks (blocker_id, blocked_id) values
  ('a3000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002');
select t.as_user('a3000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.resolve_qr(%L)$$, t.tk('player2')), '%isn''t valid%', 'a blocked player can''t resolve');
select throws_like(format($$select public.resolve_qr(%L)$$, t.tk('open2')), '%isn''t valid%', 'nor the blocker''s group');
select t.reset();
delete from public.blocks where blocker_id = 'a3000000-0000-0000-0000-000000000001';

-- Minors.
select t.as_user('a3000000-0000-0000-0000-000000000003');
select throws_like(format($$select public.resolve_qr(%L)$$, t.tk('player2')), '%parent%', 'a linked teen can''t resolve a code');
select t.reset();
select t.as_user('a3000000-0000-0000-0000-000000000004');
select throws_like(format($$select public.resolve_qr(%L)$$, t.tk('player2')), '%parent%', 'a child can''t resolve a code');
select t.reset();
select t.as_anon();
select throws_ok(format($$select public.resolve_qr(%L)$$, t.tk('player2')), '42501', null, 'signed out can''t resolve');
select throws_ok($$select 1 from public.place_qr_tokens$$, '42501', null, 'signed out can''t read codes');
select t.reset();
select t.as_user('a3000000-0000-0000-0000-000000000002');
select throws_ok($$select 1 from public.place_qr_tokens$$, '42501', null, 'players can''t read codes');
select t.reset();

-- Vendors and venues.
insert into public.vendors (owner_id, stripe_account_id, status) values ('a3000000-0000-0000-0000-000000000005', 'acct_scan', 'pending');
select t.as_user('a3000000-0000-0000-0000-000000000005');
select throws_like($$select public.vendor_qr()$$, '%payout set-up%', 'an unverified vendor has no code');
select t.reset();
update public.vendors set status = 'verified' where owner_id = 'a3000000-0000-0000-0000-000000000005';
select t.as_user('a3000000-0000-0000-0000-000000000005');
insert into tokens values ('vendor', public.vendor_qr());
select t.reset();
select t.as_user('a3000000-0000-0000-0000-000000000002');
select is(public.resolve_qr(t.tk('vendor')) ->> 'kind', 'vendor', 'a vendor''s code opens the vendor');
select t.reset();
update public.vendors set status = 'rejected' where owner_id = 'a3000000-0000-0000-0000-000000000005';
select t.as_user('a3000000-0000-0000-0000-000000000002');
select throws_like(format($$select public.resolve_qr(%L)$$, t.tk('vendor')), '%isn''t valid%', 'a rejected vendor''s code stops working');
select t.reset();

insert into public.staff (user_id, role) values ('a3000000-0000-0000-0000-000000000001', 'content');
select t.as_staff('a3000000-0000-0000-0000-000000000001');
insert into tokens select 'venue', public.staff_venue_qr(id) from public.venues order by name limit 1;
select t.reset();
select t.as_user('a3000000-0000-0000-0000-000000000002');
select is(public.resolve_qr(t.tk('venue')) ->> 'kind', 'venue', 'a venue''s code opens the venue');
select throws_like($$select public.staff_venue_qr((select id from public.venues limit 1))$$, 'Not found%', 'players can''t make venue codes');
select t.reset();

select * from finish();
rollback;
