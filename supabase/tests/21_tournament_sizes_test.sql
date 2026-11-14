begin;
\ir helpers/setup.psql
select no_plan();

select t.player('f1000000-0000-0000-0000-000000000000');
select t.player(('f1000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid)
from generate_series(1, 33) i;
grant select on public.tournament_entries, public.tournament_matches to authenticated;

-- Runs a whole tournament: the better seed wins every match. Returns what went
-- wrong, or null.
create function t.play(p_format text, p_n int) returns text language plpgsql as $$
declare
  v_id uuid := t.meet('f1000000-0000-0000-0000-000000000000', p_game => 'singles');
  m record;
  v_played int := 0;
  v_size int := 2;
  v_rows int;
begin
  update public.activities set kind = 'tournament', format = p_format, ranked = false where id = v_id;
  insert into public.tournament_entries (activity_id, division, user_id, rating)
  select v_id, 'main', ('f1000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid, 8 - i * 0.1
  from generate_series(1, p_n) i;
  perform t.as_user('f1000000-0000-0000-0000-000000000000');
  perform public.tournament_make_draw(v_id, 'main');
  perform t.reset();
  while p_n > v_size and p_format = 'knockout' loop v_size := v_size * 2; end loop;

  -- Byes go against the top seeds.
  if p_format = 'knockout' and exists (
      select 1 from public.tournament_matches x
      join public.tournament_entries e on e.id in (x.entry_a, x.entry_b)
      where x.activity_id = v_id and x.src_b = 'bye' and e.seed > v_size - p_n) then
    return 'a bye did not go to a top seed';
  end if;
  if p_format = 'knockout' and (select count(*) from public.tournament_matches x
      where x.activity_id = v_id and x.src_b = 'bye') <> v_size - p_n then
    return 'wrong number of byes';
  end if;

  loop
    select x.id, ea.seed as sa, eb.seed as sb into m
    from public.tournament_matches x
    join public.tournament_entries ea on ea.id = x.entry_a
    join public.tournament_entries eb on eb.id = x.entry_b
    where x.activity_id = v_id and x.state <> 'done'
    order by x.round, x.slot limit 1;
    exit when not found;
    perform t.as_user('f1000000-0000-0000-0000-000000000000');
    perform public.tournament_score(m.id,
      case when m.sa < m.sb then '[[21,10],[21,12]]'::jsonb else '[[10,21],[12,21]]'::jsonb end);
    perform t.reset();
    v_played := v_played + 1;
    if v_played > 1000 then return 'never finished'; end if;
  end loop;

  if exists (select 1 from public.tournament_matches where activity_id = v_id and state <> 'done') then
    return 'a match was left unplayed';
  end if;
  if p_format <> 'round_robin' and (select e.seed from public.tournament_matches x
      join public.tournament_entries e on e.id = x.winner
      where x.activity_id = v_id and x.stage = 'knockout' order by x.round desc limit 1) <> 1 then
    return 'the top seed did not win';
  end if;
  select count(*) into v_rows from public.match_results where activity_id = v_id;
  if v_rows <> v_played then return 'results ' || v_rows || ' for ' || v_played || ' matches'; end if;
  return null;
end;
$$;

select is(t.play('knockout', i), null, format('P3-06 knockout with %s entries', i)) from generate_series(3, 33) i;
select is(t.play('round_robin', i), null, format('P3-06 round robin with %s entries', i)) from unnest(array[3, 4, 5, 8, 9, 16, 33]) i;
select is(t.play('groups_knockout', i), null, format('P3-06 groups and knockout with %s entries', i)) from generate_series(3, 33) i;

select * from finish();
rollback;
