-- Local development only. Sign in with +65 8000 0001 and code 123456, which
-- resolve-login accepts on a local stack only. Everything else comes from
-- migrations.
-- Supabase Auth cannot read NULL in its token columns, so they are blank.
insert into auth.users (id, instance_id, aud, role, email, email_confirmed_at,
  created_at, updated_at, confirmation_token, recovery_token, email_change,
  email_change_token_new, email_change_token_current, phone_change,
  phone_change_token, reauthentication_token)
select id::uuid, '00000000-0000-0000-0000-000000000000', 'authenticated',
  'authenticated', private.random_auth_email(), now(), now(), now(),
  '', '', '', '', '', '', '', ''
from (values
  ('00000000-0000-4000-a000-000000000001'),
  ('00000000-0000-4000-a000-000000000002')
) v(id);

update public.account_private set birthday = date '1990-05-20',
  mobile = '+6580000001', mobile_verified_at = now()
  where id = '00000000-0000-4000-a000-000000000001';
update public.account_private set birthday = date '1988-03-02',
  mobile = '+6580000002', mobile_verified_at = now()
  where id = '00000000-0000-4000-a000-000000000002';

update public.profiles set username = 'aaron_host', full_name = 'Aaron Ng',
  onboarding_completed = true where id = '00000000-0000-4000-a000-000000000001';
update public.profiles set username = 'hannah_plays', full_name = 'Hannah Goh',
  onboarding_completed = true where id = '00000000-0000-4000-a000-000000000002';

update public.account_private ap set auth_email = u.email
from auth.users u where u.id = ap.id and u.email like '%@users.olympusgo.invalid';

insert into public.player_sports (user_id, sport, level, play_min, play_max) values
  ('00000000-0000-4000-a000-000000000001', 'badminton', 4, 3, 5),
  ('00000000-0000-4000-a000-000000000002', 'badminton', 4, 3, 5);

-- A local staff member for the admin app: admin@test.local, password
-- local-admin-password. They enrol their own MFA on first sign-in.
insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at, confirmation_token, recovery_token,
  email_change, email_change_token_new, email_change_token_current, phone_change,
  phone_change_token, reauthentication_token)
values ('00000000-0000-4000-a000-0000000000a1', '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'admin@test.local',
  extensions.crypt('local-admin-password', extensions.gen_salt('bf')),
  now(), now(), now(), '', '', '', '', '', '', '', '');
insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
values ('00000000-0000-4000-a000-0000000000a1', '00000000-0000-4000-a000-0000000000a1',
  '{"sub": "00000000-0000-4000-a000-0000000000a1", "email": "admin@test.local"}', 'email', now(), now(), now());
insert into public.staff (user_id, role) values ('00000000-0000-4000-a000-0000000000a1', 'super');

-- The money worker's timer. The secret matches the local stand-in, and hosted
-- projects hold their own in Vault.
select vault.create_secret('http://supabase_kong_olympusGO:8000/functions/v1/money-worker', 'money_worker_url');
select vault.create_secret('local-worker-secret', 'money_worker_secret');
