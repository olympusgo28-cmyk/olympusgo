-- P4d: what the review of the fixes found. A player's own check-in can still be
-- confirmed, quests wait for attendance to close, and no one is starved by a
-- limit on the sweep.

-- Which finished sessions the quests have seen, so each is looked at once.
create table private.quest_sessions_done (
  activity_id uuid primary key,
  done_at timestamptz not null default now()
);

-- The host scanning you, or saving you on their list, is what confirms you. A
-- check-in you made yourself doesn't stop them doing that (Q157).
do $$
declare
  d text := pg_get_functiondef('private.mark_present(uuid, uuid, uuid, text)'::regprocedure);
  fixed text;
begin
  fixed := replace(d, $old$      check_in_method = coalesce(check_in_method, p_method)$old$,
    $new$      check_in_method = case when p_method = 'qr' then 'qr' else coalesce(check_in_method, p_method) end$new$);
  if fixed = d then raise exception 'mark_present did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.save_attendance(uuid, jsonb)'::regprocedure);
  fixed := replace(d, $old$then coalesce(ap.check_in_method, 'host') else ap.check_in_method end$old$,
    $new$then case when ap.check_in_method in ('qr', 'parent') then ap.check_in_method else 'host' end
        else ap.check_in_method end$new$);
  if fixed = d then raise exception 'save_attendance did not change'; end if;
  execute fixed;
end;
$$;

-- A session counts once its attendance has closed, so a correction made that
-- evening can't leave a voucher behind.
create or replace function private.quest_count(q public.quests, c public.campaigns, p_user uuid, p_from timestamptz)
returns int
language sql stable security definer set search_path = '' as $$
  -- Definer: reads attendance. Sessions inside the campaign, after joining.
  select case when q.type = 'organize_counted' then
      (select count(*)::int from public.organizer_games g
       join public.activities a on a.id = g.activity_id
       where g.host_id = p_user and g.counted
         and a.starts_at >= greatest(c.starts_at, p_from) and a.starts_at < c.ends_at)
    else (select count(*)::int from public.activity_participants ap
       join public.activities a on a.id = ap.activity_id
       where ap.user_id = p_user and ap.status = 'joined' and ap.attendance = 'present'
         and ap.check_in_method in ('qr', 'host') and a.status <> 'cancelled'
         and a.ends_at <= now() and not private.attendance_open(a)
         and a.starts_at >= greatest(c.starts_at, p_from) and a.starts_at < c.ends_at
         and (q.type = 'attend_sessions' or a.kind in ('meet', 'tournament'))) end;
$$;

create or replace function private.organizer_sweep() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: cron.
declare
  r record;
  u record;
  v_type uuid;
begin
  for r in
    select a.id as activity_id, a.host_id from public.activities a
    where a.kind = 'meet' and a.ends_at <= now() and not private.attendance_open(a)
      and (exists (select 1 from public.campaign_game_log l where l.activity_id = a.id)
        or exists (select 1 from public.activity_participants ap
          where ap.activity_id = a.id and ap.status = 'joined' and ap.attendance = 'present'))
      and not exists (select 1 from public.organizer_games g where g.activity_id = a.id)
      -- A cancelled Meet's money is refunded, never released.
      and (a.status = 'cancelled' or not exists (select 1 from public.payments p
        where p.activity_id = a.id and p.status = 'succeeded' and p.released_at is null
          and p.purpose in ('meet', 'host_spot', 'ticket', 'tournament')))
      and not exists (select 1 from public.activity_money_holds h
        where h.activity_id = a.id and h.closed_at is null)
    order by a.ends_at, a.id limit 500
  loop
    begin
      perform private.organizer_game_check(r.activity_id, r.host_id);
    exception when others then
      perform private.money_alert('organizer_sweep_failed', 'organizer-sweep:' || r.activity_id || ':' || now()::date,
        jsonb_build_object('activity', r.activity_id));
    end;
  end loop;

  -- What was earned before the rewards opened, or before a type was set, is
  -- issued now. A flagged or suspended account's stays waiting.
  if private.flag('game.organizer_rewards') then
    for r in select g.id, g.key, g.user_id, g.kind from public.reward_grants g
      where g.status = 'pending' and not private.is_suspended(g.user_id)
        and not exists (select 1 from public.points_blocks b where b.user_id = g.user_id)
      order by g.created_at, g.id limit 500
    loop
      begin
        select t.id into v_type from public.voucher_types t where t.kind = r.kind and t.organizer_default and t.active;
        if v_type is not null then
          perform pg_advisory_xact_lock(hashtext('grant:' || r.key));
          if (select g.status from public.reward_grants g where g.id = r.id) = 'pending' then
            perform private.voucher_issue(v_type, r.user_id, r.key);
            update public.reward_grants set status = 'issued', issued_at = now() where id = r.id;
          end if;
        end if;
      exception when others then
        perform private.money_alert('organizer_sweep_failed', 'grant:' || r.id || ':' || now()::date,
          jsonb_build_object('grant', r.id));
      end;
    end loop;
  end if;

  if private.flag('game.campaigns') then
    -- Each session once, when its attendance has closed. One that fails stays
    -- unmarked, so the next run tries it again.
    for r in select a.id from public.activities a
      where a.ends_at between now() - interval '3 days' and now() and not private.attendance_open(a)
        and not exists (select 1 from private.quest_sessions_done d where d.activity_id = a.id)
      order by a.ends_at, a.id limit 200
    loop
      begin
        for u in select distinct ap.user_id from public.activity_participants ap
          join public.challenges j on j.user_id = ap.user_id
          join public.campaigns c on c.id = j.campaign_id and c.status = 'live'
          where ap.activity_id = r.id and ap.status = 'joined' and ap.attendance = 'present'
        loop
          perform private.quest_sync(u.user_id);
        end loop;
        insert into private.quest_sessions_done (activity_id) values (r.id);
      exception when others then
        perform private.money_alert('quest_failed', 'quest-failed:' || r.id || ':' || now()::date,
          jsonb_build_object('activity', r.id));
      end;
    end loop;

    -- Quests that reached their target while their voucher was switched off.
    for r in select distinct p.user_id from public.challenge_progress p
      join public.quests q on q.id = p.quest_id
      join public.campaigns c on c.id = q.campaign_id and c.status = 'live'
      join public.voucher_types t on t.id = q.voucher_type_id and t.active
      where p.completed_at is null and p.count >= q.target
      limit 200
    loop
      begin
        perform private.quest_sync(r.user_id);
      exception when others then
        perform private.money_alert('quest_failed', 'quest-failed:' || r.user_id || ':' || now()::date,
          jsonb_build_object('user', r.user_id));
      end;
    end loop;
  end if;

  update public.vouchers set status = 'expired' where status = 'issued' and expires_at <= now();
end;
$$;

revoke execute on function private.quest_count(public.quests, public.campaigns, uuid, timestamptz),
  private.organizer_sweep() from public, anon, authenticated;
