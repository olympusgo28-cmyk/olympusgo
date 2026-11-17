-- Q268 (audit S2), R-ACC-9: a login contact changes only for a session that
-- has just proved itself with a code to the right contact, the proof is used
-- once, no change is silent, a player's Auth email, password and phone never
-- change, and Supabase Auth sends no mail of its own.
begin;
\ir helpers/setup.psql
select no_plan();

select t.player('e7000000-0000-0000-0000-000000000001');  -- mobile and email
select t.player('e7000000-0000-0000-0000-000000000002');  -- mobile only
select t.player('e7000000-0000-0000-0000-000000000003');  -- holds a taken email
select t.player('e7000000-0000-0000-0000-000000000004');  -- active staff
select t.player('e7000000-0000-0000-0000-000000000005');  -- staff no longer active
update public.account_private set email = 'one@test.local', email_verified_at = now()
  where id = 'e7000000-0000-0000-0000-000000000001';
update public.account_private set email = 'taken@test.local', email_verified_at = now()
  where id = 'e7000000-0000-0000-0000-000000000003';
update public.account_private set email = 'unverified@test.local', email_verified_at = null
  where id = 'e7000000-0000-0000-0000-000000000002';
insert into public.staff (user_id, role, active) values
  ('e7000000-0000-0000-0000-000000000004', 'content', true),
  ('e7000000-0000-0000-0000-000000000005', 'content', false);

create function t.sid(p_session text) returns uuid language sql as $$
  select ('e7000000-0000-0000-0000-0000000000' || p_session)::uuid;
$$;
create function t.change(p_session text, p_kind text, p_value text,
    p_user uuid default 'e7000000-0000-0000-0000-000000000001') returns text language sql as $$
  select public.login_contact_change(p_user, t.sid(p_session), p_kind, p_value) ->> 'status';
$$;
create function t.prove(p_session text, p_kind text,
    p_user uuid default 'e7000000-0000-0000-0000-000000000001') returns void language sql as $$
  select public.login_step_up_grant(p_user, t.sid(p_session), p_kind);
$$;
create function t.email_of(p_user uuid) returns text language sql as $$
  select email from public.account_private where id = p_user;
$$;
create function t.notices(p_user uuid) returns text[] language sql as $$
  select coalesce(array_agg(title order by title), '{}') from public.notifications where user_id = p_user;
$$;

select is(private.setting_int('auth.step_up_minutes'), 5, 'a proof lasts 5 minutes');

-- ─── No proof, no change ───────────────────────────────────────────────────

select is(t.change('a1', 'email', 'attacker@test.local'), 'step_up',
  'a session with no proof cannot change the email');
select is(t.change('a1', 'mobile', '+6590000001'), 'step_up', 'nor the mobile');
select is(t.email_of('e7000000-0000-0000-0000-000000000001'), 'one@test.local', 'nothing changed');

-- ─── Which contact proves it (R-ACC-9, "the other one") ────────────────────

select is(public.login_proof_contact('e7000000-0000-0000-0000-000000000001', 'mobile') ->> 'kind',
  'email', 'changing the mobile is proved by the email');
select is(public.login_proof_contact('e7000000-0000-0000-0000-000000000001', 'email') ->> 'kind',
  'mobile', 'changing the email is proved by the mobile');
select is(public.login_proof_contact('e7000000-0000-0000-0000-000000000002', 'mobile') ->> 'kind',
  'mobile', 'with only a mobile (the email was never verified), the mobile proves its own change');
select is(public.login_proof_contact('e7000000-0000-0000-0000-000000000002', 'mobile') ->> 'value',
  (select mobile from public.account_private where id = 'e7000000-0000-0000-0000-000000000002'),
  'and it is the mobile on file, not one the caller names');
select is(public.login_proof_contact('e7000000-0000-0000-0000-000000000001', 'username'), null,
  'nothing else can be changed this way');

-- A proof from the wrong contact proves nothing for this change.
select t.prove('a1', 'mobile');
select is(public.login_step_up_live('e7000000-0000-0000-0000-000000000001', t.sid('a1'), 'email'),
  true, 'a code to the mobile lets this session change the email');
select is(public.login_step_up_live('e7000000-0000-0000-0000-000000000001', t.sid('a1'), 'mobile'),
  false, 'but not the mobile itself, while there is an email to prove it');
select is(t.change('a1', 'mobile', '+6590000001'), 'step_up',
  'so a thief who also holds the SIM cannot move the mobile without the email');

-- ─── A proof belongs to one session and one player ─────────────────────────

select is(t.change('a2', 'email', 'attacker@test.local'), 'step_up',
  'another session of the same player is still refused');
select is(t.change('a1', 'email', 'attacker@test.local', 'e7000000-0000-0000-0000-000000000002'),
  'step_up', 'the proof cannot be used on another player''s account');
select t.prove('a1', 'mobile', 'e7000000-0000-0000-0000-000000000002');
select is((select user_id from public.step_ups where session_id = t.sid('a1')),
  'e7000000-0000-0000-0000-000000000001', 'a second player cannot take over a session''s proof');

-- ─── Taken, then used once, and never silent ───────────────────────────────

select is(t.change('a1', 'email', 'TAKEN@test.local'), 'taken',
  'an email another account holds is refused');
select is(public.login_step_up_live('e7000000-0000-0000-0000-000000000001', t.sid('a1'), 'email'),
  true, 'and the proof is kept, so they can try another');
select is(t.notices('e7000000-0000-0000-0000-000000000001'), '{}', 'a refused change tells nobody anything');

select is(public.login_contact_change('e7000000-0000-0000-0000-000000000001',
    t.sid('a1'), 'email', 'New@Test.Local'),
  '{"status": "ok", "alert": "one@test.local", "first": false}'::jsonb,
  'with the right proof the email changes, and the old address is the one to alert');
select is(t.email_of('e7000000-0000-0000-0000-000000000001'), 'new@test.local', 'saved in lower case');
select is(t.notices('e7000000-0000-0000-0000-000000000001'), array['Your login email was changed'],
  'the player is told in the app');
select is(t.change('a1', 'email', 'again@test.local'), 'step_up', 'the proof is used up: once only');

-- A first contact of a kind: the other contact is alerted, and the app says so.
select t.prove('b1', 'mobile', 'e7000000-0000-0000-0000-000000000002');
select is(public.login_contact_change('e7000000-0000-0000-0000-000000000002',
    t.sid('b1'), 'email', 'first@test.local'),
  jsonb_build_object('status', 'ok', 'first', true, 'alert',
    (select mobile from public.account_private where id = 'e7000000-0000-0000-0000-000000000002')),
  'a first email alerts the mobile, so adding one is never silent');
select is(t.notices('e7000000-0000-0000-0000-000000000002'), array['An email was added to your login'],
  'and the player is told in the app');

-- Setting a contact to what it already is changes nothing and uses nothing.
select t.prove('b2', 'mobile', 'e7000000-0000-0000-0000-000000000002');
select is(public.login_contact_change('e7000000-0000-0000-0000-000000000002',
    t.sid('b2'), 'email', 'first@test.local'),
  '{"status": "ok", "alert": null}'::jsonb, 'the same email again alerts nobody');
select is(public.login_step_up_live('e7000000-0000-0000-0000-000000000002', t.sid('b2'), 'email'),
  true, 'and keeps the proof');

-- ─── Expiry ────────────────────────────────────────────────────────────────

select t.prove('a3', 'mobile');
update public.step_ups set expires_at = now() - interval '1 second' where session_id = t.sid('a3');
select is(t.change('a3', 'email', 'late@test.local'), 'step_up', 'an expired proof is refused');
select is(t.change('a3', 'username', 'x'), 'refused', 'only a mobile or an email can be changed here');

-- ─── Nobody but the sign-in function ───────────────────────────────────────

select t.as_user('e7000000-0000-0000-0000-000000000001');
select throws_ok($$select * from public.step_ups$$, '42501', null, 'players cannot read proofs');
select throws_ok($$insert into public.step_ups (session_id, user_id, proved_kind, expires_at)
  values (gen_random_uuid(), 'e7000000-0000-0000-0000-000000000001', 'mobile', now() + interval '1 hour')$$,
  '42501', null, 'or write one');
select throws_ok($$select public.login_step_up_grant('e7000000-0000-0000-0000-000000000001', gen_random_uuid(), 'mobile')$$,
  '42501', null, 'or grant themselves one');
select throws_ok($$select public.login_contact_change('e7000000-0000-0000-0000-000000000001',
  gen_random_uuid(), 'email', 'x@test.local')$$, '42501', null, 'or call the change directly');
select throws_ok($$select public.login_proof_contact('e7000000-0000-0000-0000-000000000003', 'mobile')$$,
  '42501', null, 'or read anyone''s proof contact');
select throws_ok($$update public.account_private set email = 'x@test.local'
  where id = 'e7000000-0000-0000-0000-000000000001'$$, '42501', null,
  'or write their contact columns directly');
select throws_ok($$select private.auth_email_refused('{}'::jsonb)$$, '42501', null,
  'or call the mail hook');
select t.as_anon();
select throws_ok($$select public.login_step_up_live('e7000000-0000-0000-0000-000000000001', gen_random_uuid(), 'email')$$,
  '42501', null, 'signed out, nothing either');
select t.reset();
select hasnt_function('public', 'login_contact_set', array['uuid', 'text', 'text'],
  'the old change-without-proof function is gone');

-- ─── Auth sign-in details are fixed for players ────────────────────────────

select throws_ok($$update auth.users set encrypted_password = 'x'
  where id = 'e7000000-0000-0000-0000-000000000001'$$, '42501', null,
  'a player''s Auth password cannot be set');
select throws_ok($$update auth.users set email = 'attacker@test.local'
  where id = 'e7000000-0000-0000-0000-000000000001'$$, '42501', null, 'nor the Auth email changed');
select throws_ok($$update auth.users set phone = '+6590000003'
  where id = 'e7000000-0000-0000-0000-000000000001'$$, '42501', null, 'nor an Auth phone added');
select throws_ok($$update auth.users set email_change = 'attacker@test.local'
  where id = 'e7000000-0000-0000-0000-000000000001'$$, '42501', null,
  'nor a pending email change stored');
select lives_ok($$update auth.users set last_sign_in_at = now(), banned_until = null
  where id = 'e7000000-0000-0000-0000-000000000001'$$, 'everything else about the row still updates');
select lives_ok($$update auth.users set encrypted_password = 'x'
  where id = 'e7000000-0000-0000-0000-000000000004'$$,
  'active staff, who log in to the admin app with a password, can change theirs');
select throws_ok($$update auth.users set encrypted_password = 'x'
  where id = 'e7000000-0000-0000-0000-000000000005'$$, '42501', null,
  'someone no longer active as staff cannot');

-- ─── Supabase Auth sends no mail of its own ────────────────────────────────

select is(private.auth_email_refused('{"user": {}, "email_data": {}}'::jsonb) -> 'error' ->> 'http_code',
  '403', 'the send-email hook refuses every send');
select ok(has_function_privilege('supabase_auth_admin', 'private.auth_email_refused(jsonb)', 'execute'),
  'Supabase Auth may call it');

select * from finish();
rollback;
