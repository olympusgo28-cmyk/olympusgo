-- P1-12: tries every table in public as a signed-out caller, as a restricted
-- child and as an unrelated player, against rows that belong to someone else.
-- A new table is covered without changing this file.
begin;
\ir helpers/setup.psql
select plan(9);

select t.player('a0000000-0000-0000-0000-000000000001');      -- victim
select t.player('a0000000-0000-0000-0000-000000000002');      -- their friend
select t.player('a0000000-0000-0000-0000-000000000003');      -- attacker
select t.player('a0000000-0000-0000-0000-000000000004', 12);  -- restricted child
select t.player('a0000000-0000-0000-0000-000000000005', 12);  -- victim's child

-- Rows worth stealing, across the main tables.
insert into public.guardian_links (child_id, parent_id, status)
  values ('a0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'approved');
insert into public.follows (follower_id, followee_id)
  values ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002');
insert into public.player_sports (user_id, sport, level, play_min, play_max)
  values ('a0000000-0000-0000-0000-000000000001', 'badminton', 4, 3, 5);
select public.notify('a0000000-0000-0000-0000-000000000001', 'Private');
select t.as_user('a0000000-0000-0000-0000-000000000001');
select public.open_direct_conversation('a0000000-0000-0000-0000-000000000002');
select public.my_qr();
select t.reset();
insert into public.messages (conversation_id, sender_id, body)
  select id, 'a0000000-0000-0000-0000-000000000001', 'Private' from public.conversations limit 1;
insert into public.activity_participants (activity_id, user_id, status)
  values (t.meet('a0000000-0000-0000-0000-000000000001'), 'a0000000-0000-0000-0000-000000000001', 'joined');

-- Rows each table holds, so a change can be spotted.
create function t.row_counts() returns jsonb language plpgsql security definer as $$
declare
  r record;
  n bigint;
  out jsonb := '{}';
begin
  for r in select tablename from pg_tables where schemaname = 'public' order by 1 loop
    execute format('select count(*) from public.%I', r.tablename) into n;
    out := out || jsonb_build_object(r.tablename, n);
  end loop;
  return out;
end;
$$;

-- Tries to wipe every table as the current role. Refusals are expected;
-- what matters is the row counts afterwards.
create function t.try_delete_everything() returns void language plpgsql as $$
declare
  r record;
begin
  for r in select tablename from pg_tables where schemaname = 'public' loop
    begin
      execute format('delete from public.%I', r.tablename);
    exception when others then
      null;
    end;
  end loop;
end;
$$;

-- Tables that read as anything but empty to this role.
create function t.readable_tables() returns text[] language plpgsql as $$
declare
  r record;
  n bigint;
  out text[] := '{}';
begin
  for r in select tablename from pg_tables where schemaname = 'public' order by 1 loop
    begin
      execute format('select count(*) from public.%I', r.tablename) into n;
      if n > 0 then out := out || r.tablename; end if;
    exception when others then
      null;
    end;
  end loop;
  return out;
end;
$$;

grant execute on function t.row_counts(), t.try_delete_everything(), t.readable_tables() to anon, authenticated;

create temp table before on commit drop as select t.row_counts() as c;
grant select on before to anon, authenticated;

-- Reference data that is open by design.
create temp table open_data (name text) on commit drop;
insert into open_data values ('app_settings'), ('country_config'), ('feature_flags'),
  ('fee_rules'), ('sports'), ('sport_formats'), ('game_types'), ('level_scales');
grant select on open_data to anon, authenticated;

select t.as_anon();
select is(
  (select array_agg(x order by x) from unnest(t.readable_tables()) x
    where x not in (select name from open_data)),
  null::text[], 'signed out: nothing but reference data can be read');
select t.try_delete_everything();
select t.reset();
select is(t.row_counts(), (select c from before), 'signed out: nothing can be deleted');

select t.as_user('a0000000-0000-0000-0000-000000000004');
select is(
  (select array_agg(x order by x) from unnest(t.readable_tables()) x
    where x not in (select name from open_data) and x not in ('activity_participants')
      and x not in ('account_private', 'profiles', 'player_sports', 'blocks',
        'notifications', 'activities', 'venues', 'venue_courts', 'clubs', 'teams')),
  null::text[], 'restricted child: only their own and open rows can be read');
select is_empty($$select 1 from public.messages$$, 'restricted child: no messages');
select is_empty($$select 1 from public.profiles where id = 'a0000000-0000-0000-0000-000000000001'$$,
  'restricted child: no other player''s profile');
select t.try_delete_everything();
select t.reset();
select is(t.row_counts(), (select c from before), 'restricted child: nothing of anyone''s can be deleted');

select t.as_user('a0000000-0000-0000-0000-000000000003');
select is_empty($$select 1 from public.notifications$$, 'another player: no one else''s notifications');
select is_empty($$select 1 from public.messages$$, 'another player: no one else''s messages');
select t.try_delete_everything();
select t.reset();
select is(t.row_counts(), (select c from before), 'another player: nothing of anyone''s can be deleted');

select * from finish();
rollback;
