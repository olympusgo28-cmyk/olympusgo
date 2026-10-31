-- Rules that hold for the whole schema. These fail the build on a table
-- without RLS or a definer function without a fixed search path.
begin;
\ir helpers/setup.psql
select plan(7);

select is_empty($$
  select c.relname from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind in ('r', 'p') and not c.relrowsecurity
$$, 'every table in public has row-level security on');

select is_empty($$
  select n.nspname || '.' || p.proname from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname in ('public', 'private') and p.prosecdef
    and not exists (select 1 from unnest(coalesce(p.proconfig, '{}')) c where c like 'search\_path=%')
$$, 'every security definer function fixes its search path');

select is_empty($$
  select p.proname from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prosecdef
    and p.prorettype <> 'trigger'::regtype
    and has_function_privilege('anon', p.oid, 'execute')
    and p.proname not in ('legal_notice_send', 'account_recovery_request',
      'activity_spots_taken', 'tournament_bracket', 'tournament_division_name',
      'tournament_divisions', 'tournament_doubles', 'tournament_games_won')
$$, 'signed-out callers reach no definer function outside the agreed list');

select is_empty($$
  select p.proname from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname like 'login\_gate\_%'
    and (has_function_privilege('anon', p.oid, 'execute')
      or has_function_privilege('authenticated', p.oid, 'execute'))
$$, 'sign-in limit functions are for the Edge Function only');

select is_empty($$
  select p.proname from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname like 'money\_svc\_%'
    and (has_function_privilege('anon', p.oid, 'execute')
      or has_function_privilege('authenticated', p.oid, 'execute'))
$$, 'webhook and worker functions are for the Edge Functions only');

select is_empty($$
  select table_name from information_schema.role_table_grants
  where table_schema = 'private' and grantee in ('anon', 'authenticated')
$$, 'no client role can reach a private table');

select ok(
  exists (select 1 from pg_db_role_setting s
    join pg_roles r on r.oid = s.setrole
    where r.rolname = 'authenticator'
      and 'pgrst.db_pre_request=private.gate_request' = any (s.setconfig)),
  'the API runs the gate before every request');

select * from finish();
rollback;
