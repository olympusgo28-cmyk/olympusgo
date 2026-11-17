-- Checklist section 4: the database refuses a restricted child, not just the
-- screens. These set request.path the way the API does.
begin;
\ir helpers/setup.psql
select plan(19);

select t.player('80000000-0000-0000-0000-000000000001');      -- adult
select t.player('80000000-0000-0000-0000-000000000002', 12);  -- restricted child
select t.player('80000000-0000-0000-0000-000000000003', 12);  -- linked child
select t.player('80000000-0000-0000-0000-000000000004');      -- their parent
select t.player('80000000-0000-0000-0000-000000000005', 16);  -- approved teen
select t.player('80000000-0000-0000-0000-000000000006');      -- teen's parent

insert into public.guardian_links (child_id, parent_id, status) values
  ('80000000-0000-0000-0000-000000000003', '80000000-0000-0000-0000-000000000004', 'approved'),
  ('80000000-0000-0000-0000-000000000005', '80000000-0000-0000-0000-000000000006', 'approved');

create function t.gate(p_path text, p_method text default 'GET') returns void language plpgsql as $$
begin
  perform set_config('request.path', p_path, true);
  perform set_config('request.method', p_method, true);
  perform private.gate_request();
end;
$$;
grant execute on function t.gate(text, text) to authenticated, anon;

select t.as_user('80000000-0000-0000-0000-000000000002');
select throws_ok($$select t.gate('/rpc/shop_products')$$, 'P0001', 'Ask a parent to link your account first.', 'a restricted child is refused the Shop');
select throws_ok($$select t.gate('/rpc/suggested_players')$$, 'P0001', null, 'a restricted child is refused discovery');
select throws_ok($$select t.gate('/rpc/open_direct_conversation')$$, 'P0001', null, 'a restricted child is refused chat');
select throws_ok($$select t.gate('/rpc/resolve_qr')$$, 'P0001', null, 'a restricted child is refused Scan');
select throws_ok($$select t.gate('/rpc/a_function_added_next_year')$$, 'P0001', null, 'a new function starts out refused');
select lives_ok($$select t.gate('/rpc/my_restrictions')$$, 'a restricted child reaches their own status');
select lives_ok($$select t.gate('/rpc/guardian_code_create')$$, 'a restricted child can ask for a parent code');
select lives_ok($$select t.gate('/rpc/legal_notice_send')$$, 'getting help always works');

-- The tables refuse too, which is what covers Realtime.
select is_empty($$select 1 from public.products$$, 'a restricted child reads no products');
select is_empty($$select 1 from public.messages$$, 'a restricted child reads no messages');
select is_empty($$select 1 from public.group_messages$$, 'a restricted child reads no group chat');
select t.reset();

select t.as_user('80000000-0000-0000-0000-000000000003');
select lives_ok($$select t.gate('/rpc/shop_products')$$, 'linking lifts the gate');
select t.reset();

select t.as_user('80000000-0000-0000-0000-000000000001');
select lives_ok($$select t.gate('/rpc/shop_products')$$, 'an adult is not gated');

-- Who sees whom.
select is_empty($$select 1 from public.profiles where id = '80000000-0000-0000-0000-000000000003'$$, 'an adult cannot read a minor''s profile');
select is_empty($$select 1 from public.player_sports where user_id = '80000000-0000-0000-0000-000000000003'$$, 'an adult cannot read a minor''s Passport');
select t.reset();

select t.as_user('80000000-0000-0000-0000-000000000004');
select isnt_empty($$select 1 from public.profiles where id = '80000000-0000-0000-0000-000000000003'$$, 'a parent reads their own child''s profile');
select t.reset();

-- Direct messages, R-MSG-1.
select t.as_user('80000000-0000-0000-0000-000000000001');
select throws_ok(
  $$select public.open_direct_conversation('80000000-0000-0000-0000-000000000005')$$,
  '42501', 'You can''t message this player.', 'R-MSG-1 an adult cannot message an under-18');
select t.reset();

select t.as_user('80000000-0000-0000-0000-000000000006');
select lives_ok(
  $$select public.open_direct_conversation('80000000-0000-0000-0000-000000000005')$$,
  'a linked parent can message their child');
select t.reset();

-- Rate limits.
select t.as_anon();
select throws_ok($$select t.gate('/rpc/legal_notice_send', 'POST') from generate_series(1, 6)$$,
  'P0001', 'Too many tries. Wait a while, then try again.', 'a public function is rate limited');
select t.reset();

select * from finish();
rollback;
