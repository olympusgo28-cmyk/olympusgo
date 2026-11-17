-- P4d: what the reviews found. Attendance, money and flags are read at the last
-- moment they can change, and a voucher's limits hold everywhere it's offered.

insert into private.rate_rules (path, max_hits, window_seconds) values ('/rpc/campaign_join', 30, 3600)
on conflict do nothing;

alter table public.organizer_games drop constraint organizer_games_reason_check;
alter table public.organizer_games add constraint organizer_games_reason_check check (reason in (
  'counted', 'before_payments', 'cancelled', 'under_six', 'unpaid', 'not_scanned',
  'organizer_minor', 'organizer_flagged'));

-- ─── Quests ─────────────────────────────────────────

-- A finished session that someone else confirmed: a scan, or the organizer's
-- list. Saying you're there yourself isn't proof (Q157).
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
         and ap.check_in_method in ('qr', 'host') and a.status <> 'cancelled' and a.ends_at <= now()
         and a.starts_at >= greatest(c.starts_at, p_from) and a.starts_at < c.ends_at
         and (q.type = 'attend_sessions' or a.kind in ('meet', 'tournament'))) end;
$$;

create or replace function private.quest_sync(p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes progress and rewards.
declare
  r record;
  v_count int;
  v_done boolean;
begin
  if not private.flag('game.campaigns') or private.is_suspended(p_user)
     or exists (select 1 from public.points_blocks b where b.user_id = p_user) then
    return;
  end if;
  perform pg_advisory_xact_lock(hashtext('quests:' || p_user));
  for r in
    select q, c, j.joined_at from public.challenges j
    join public.campaigns c on c.id = j.campaign_id and c.status = 'live'
    join public.quests q on q.campaign_id = c.id
    where j.user_id = p_user
      and not exists (select 1 from public.challenge_progress p
        where p.quest_id = q.id and p.user_id = p_user and p.completed_at is not null)
    order by q.id
  loop
    v_count := private.quest_count(r.q, r.c, p_user, r.joined_at);
    -- A switched-off voucher waits: the quest finishes when it's back on.
    v_done := v_count >= (r.q).target and not exists (select 1 from public.voucher_types t
      where t.id = (r.q).voucher_type_id and not t.active);
    insert into public.challenge_progress (quest_id, user_id, count, completed_at)
    values ((r.q).id, p_user, v_count, case when v_done then now() end)
    on conflict (quest_id, user_id) do update
      set count = excluded.count, completed_at = excluded.completed_at;
    if v_done then
      if (r.q).voucher_type_id is not null then
        perform private.voucher_issue((r.q).voucher_type_id, p_user, 'quest:' || (r.q).id || ':' || p_user);
      end if;
      if (r.q).badge_id is not null then
        perform private.badge_grant((r.q).badge_id, p_user, 'quest:' || (r.q).id || ':' || p_user);
      end if;
    end if;
  end loop;
end;
$$;

-- ─── Organizer games ─────────────────────────────────────

-- Before anyone can pay, a game still ranks its group, and earns nothing: it was
-- never checked against the rule that participants paid (Q158).
do $$
declare
  d text := pg_get_functiondef('private.game_counted(uuid)'::regprocedure);
  fixed text;
begin
  fixed := replace(d, $old$  return jsonb_build_object('reason', 'counted', 'present', v_present);$old$,
    $new$  return jsonb_build_object('reason', case when v_require then 'counted' else 'before_payments' end,
    'present', v_present);$new$);
  if fixed = d then raise exception 'game_counted did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('private.organizer_game_check(uuid, uuid)'::regprocedure);
  fixed := replace(d, $old$  perform private.quest_sync(p_host);$old$,
    $new$  -- The game stands whatever a quest does.
  begin
    perform private.quest_sync(p_host);
  exception when others then
    perform private.money_alert('quest_failed', 'quest-failed:' || p_host || ':' || now()::date,
      jsonb_build_object('activity', p_activity));
  end;$new$);
  if fixed = d then raise exception 'organizer_game_check did not change'; end if;
  execute fixed;
end;
$$;

-- A game is judged once attendance has closed for the day and its money has
-- released, whether or not the organizer pressed save.
create or replace function private.organizer_sweep() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: cron.
declare
  r record;
  v_type uuid;
begin
  for r in
    select a.id as activity_id, a.host_id from public.activities a
    where a.kind = 'meet' and a.ends_at <= now() and not private.attendance_open(a)
      and (exists (select 1 from public.campaign_game_log l where l.activity_id = a.id)
        or exists (select 1 from public.activity_participants ap
          where ap.activity_id = a.id and ap.status = 'joined' and ap.attendance = 'present'))
      and not exists (select 1 from public.organizer_games g where g.activity_id = a.id)
      and not exists (select 1 from public.payments p
        where p.activity_id = a.id and p.status = 'succeeded' and p.released_at is null
          and p.purpose in ('meet', 'host_spot', 'ticket', 'tournament'))
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

  -- A session only counts once it's over, and scans come before that. This is
  -- also the second try for a quest that failed when attendance was saved.
  if private.flag('game.campaigns') then
    for r in select distinct ap.user_id from public.activity_participants ap
      join public.activities a on a.id = ap.activity_id
      join public.challenges j on j.user_id = ap.user_id
      join public.campaigns c on c.id = j.campaign_id and c.status = 'live'
      where a.ends_at between now() - interval '1 day' and now()
        and ap.status = 'joined' and ap.attendance = 'present'
      limit 500
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

-- The window runs on when the game was played, as the old one ran on when it was
-- saved. A checked date would bring old games back in when the sweep first runs.
create or replace function public.group_activity_rank(p_limit int default 50) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: counts across the game record, and returns only group names and totals.
  select coalesce(jsonb_agg(jsonb_build_object('rank', x.rk, 'club_id', x.id, 'name', x.name,
      'area', x.area, 'games', x.games) order by x.rk), '[]'::jsonb)
  from (
    select c.id, c.name, c.area, count(*)::int as games,
      rank() over (order by count(*) desc)::int as rk
    from public.organizer_games g
    join public.activities a on a.id = g.activity_id
    join public.clubs c on c.id = a.club_id
    where (g.counted or g.reason = 'before_payments')
      and a.ends_at > now() - make_interval(days => private.setting_int('ranking.window_days'))
      and c.visibility = 'public' and c.hidden_at is null
      and private.group_allowed(auth.uid(), c.id)
    group by c.id
    order by games desc
    limit least(p_limit, 100)
  ) x;
$$;

-- ─── Reads and joining ───────────────────────────────────

create or replace function public.campaign_join(p_campaign uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the caller's own row.
declare
  c public.campaigns;
begin
  if private.is_minor(auth.uid()) then raise exception 'Campaigns are for adults for now.'; end if;
  if exists (select 1 from public.points_blocks b where b.user_id = auth.uid()) then
    raise exception 'You can''t join campaigns right now.';
  end if;
  select * into c from public.campaigns where id = p_campaign and status = 'live';
  if c.id is null or not private.flag('game.campaigns') or c.ends_at <= now() then
    raise exception 'This campaign has ended.';
  end if;
  insert into public.challenges (campaign_id, user_id) values (p_campaign, auth.uid())
  on conflict do nothing;
  if found then perform private.quest_sync(auth.uid()); end if;
end;
$$;

create or replace function public.voucher_my() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: vouchers have no client access.
  select coalesce(jsonb_agg(jsonb_build_object('id', v.id, 'name', t.name, 'code', v.code, 'kind', t.kind,
      'status', case when v.status = 'issued' and v.expires_at <= now() then 'expired' else v.status end,
      'amount_minor', t.amount_minor, 'expires_at', v.expires_at, 'used_at', v.used_at, 'issued_at', v.issued_at,
      'mall_id', t.mall_id, 'where', coalesce((select m.name from public.malls m where m.id = t.mall_id),
        (select x.name from public.venues x where x.id = t.venue_id), ''),
      'product', (select p.name from public.products p where p.id = t.product_id))
      order by v.status = 'issued' desc, v.expires_at), '[]')
  from public.vouchers v join public.voucher_types t on t.id = v.type_id
  where v.owner_id = auth.uid();
$$;

create or replace function public.organizer_rewards_my() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: the record has no client access. Only the caller's own games.
  with mine as (select count(*) filter (where g.counted)::int as n from public.organizer_games g
    where g.host_id = auth.uid())
  select jsonb_build_object('counted', mine.n, 'next', private.next_milestone(mine.n),
    'open', private.flag('game.organizer_rewards'),
    'min_present', private.setting_int('campaign.min_present'),
    'fee_minor', private.fee_per_unit(0, 'SGD', 'host_spot'),
    'waiting', (select count(*) from public.reward_grants x where x.user_id = auth.uid() and x.status = 'pending'),
    'games', (select coalesce(jsonb_agg(y.x), '[]') from (
      select jsonb_build_object('title', a.title, 'at', a.starts_at, 'counted', g.counted, 'reason', g.reason,
        'present', g.present, 'game_no', g.game_no) as x
      from public.organizer_games g join public.activities a on a.id = g.activity_id
      where g.host_id = auth.uid() order by g.checked_at desc limit 30) y))
  from mine;
$$;

-- ─── Vouchers at checkout ─────────────────────────────────

create or replace function private.voucher_usable(p_voucher uuid, p_mall uuid) returns public.voucher_types
language plpgsql stable security definer set search_path = '' as $$
-- Definer: vouchers have no client access.
declare
  v public.vouchers;
  t public.voucher_types;
begin
  select * into v from public.vouchers where id = p_voucher and owner_id = auth.uid();
  if v.id is null then raise exception 'This voucher isn''t yours.'; end if;
  if v.status = 'held' then raise exception 'This voucher opens with court booking.'; end if;
  if v.status = 'expired' or v.expires_at <= now() then raise exception 'This voucher has expired.'; end if;
  if v.status <> 'issued' then raise exception 'This voucher has been used.'; end if;
  if exists (select 1 from public.points_blocks b where b.user_id = v.owner_id) then
    raise exception 'This voucher can''t be used right now.';
  end if;
  select * into t from public.voucher_types where id = v.type_id;
  if t.mall_id is distinct from p_mall then raise exception 'This voucher is for another shop.'; end if;
  if not t.active then raise exception 'This voucher can''t be used right now.'; end if;
  return t;
end;
$$;

-- It goes on the dearest item it fits, so the buyer gets the most from it.
do $$
declare
  d text := pg_get_functiondef('private.shop_price(uuid, jsonb, bigint, uuid)'::regprocedure);
  fixed text;
begin
  fixed := replace(d, $old$  if p_voucher is not null then t := private.voucher_usable(p_voucher, p_mall); end if;$old$,
    $new$  if p_voucher is not null then
    t := private.voucher_usable(p_voucher, p_mall);
    select x.product_id, coalesce(x.variant, '') into v_for, v_for_variant
    from jsonb_to_recordset(p_lines) as x(product_id uuid, variant text, qty int)
    join public.products p on p.id = x.product_id and p.mall_id = p_mall
    where private.product_on_sale(p.id) and p.price_cents > v_floor
      and (t.product_id is null or t.product_id = p.id)
    order by p.price_cents desc, p.id, x.variant limit 1;
  end if;$new$);
  fixed := replace(fixed, $old$  v_floor bigint := private.setting_int('voucher.min_pay_minor');
begin$old$, $new$  v_floor bigint := private.setting_int('voucher.min_pay_minor');
  v_for uuid;
  v_for_variant text;
begin$new$);
  fixed := replace(fixed, $old$    if p_voucher is not null and v_off = 0 and l.price_cents > v_floor
       and (t.product_id is null or t.product_id = l.product_id) then$old$,
    $new$    if v_off = 0 and l.product_id = v_for and coalesce(l.variant, '') = v_for_variant then$new$);
  if position('v_for_variant' in fixed) = 0 or position('l.product_id = v_for' in fixed) = 0 then
    raise exception 'shop_price did not change';
  end if;
  execute fixed;

  -- A retry after a lost answer finds its order, split line or not, and only with
  -- the voucher that order holds.
  d := pg_get_functiondef('public.shop_reserve(uuid, text, bigint, bigint, jsonb, timestamptz, uuid)'::regprocedure);
  fixed := replace(d, $old$if pay.amount_minor is distinct from p_expected_minor or o.slot_at is distinct from p_slot$old$,
    $new$if pay.amount_minor is distinct from p_expected_minor or o.slot_at is distinct from p_slot
       or o.voucher_id is distinct from p_voucher$new$);
  fixed := replace(fixed, $old$except select l.product_id, l.variant, l.qty from public.order_lines l where l.order_id = o.id)$old$,
    $new$except select l.product_id, l.variant, sum(l.qty)::int from public.order_lines l where l.order_id = o.id group by 1, 2)$new$);
  fixed := replace(fixed, $old$(select l.product_id, l.variant, l.qty from public.order_lines l where l.order_id = o.id
          except$old$,
    $new$(select l.product_id, l.variant, sum(l.qty)::int from public.order_lines l where l.order_id = o.id group by 1, 2
          except$new$);
  if (length(fixed) - length(replace(fixed, 'sum(l.qty)', ''))) <> 2 * length('sum(l.qty)')
     or position('o.voucher_id is distinct from p_voucher' in fixed) = 0 then
    raise exception 'shop_reserve did not change';
  end if;
  execute fixed;

  -- Only what fits this cart is offered, at what it'll really take off.
  d := pg_get_functiondef('public.shop_quote(uuid, jsonb, bigint, uuid)'::regprocedure);
  fixed := replace(d, $old$  q jsonb := private.shop_price(p_mall, private.shop_lines_for(me, p_mall, p_only), p_points, p_voucher);$old$,
    $new$  v_lines jsonb := private.shop_lines_for(me, p_mall, p_only);
  q jsonb := private.shop_price(p_mall, v_lines, p_points, p_voucher);
  v_floor bigint := private.setting_int('voucher.min_pay_minor');$new$);
  fixed := replace(fixed, $old$'vouchers', (select coalesce(jsonb_agg(jsonb_build_object('id', v.id, 'name', t.name,
        'amount_minor', t.amount_minor, 'expires_at', v.expires_at) order by v.expires_at), '[]')
      from public.vouchers v join public.voucher_types t on t.id = v.type_id
      where v.owner_id = me and v.status = 'issued' and v.expires_at > now() and t.mall_id = p_mall));$old$,
    $new$'vouchers', (select coalesce(jsonb_agg(jsonb_build_object('id', v.id, 'name', t.name,
        'amount_minor', off.minor, 'expires_at', v.expires_at) order by v.expires_at), '[]')
      from public.vouchers v join public.voucher_types t on t.id = v.type_id
      cross join lateral (select max(least(t.amount_minor, p.price_cents - v_floor)) as minor
        from jsonb_to_recordset(v_lines) as x(product_id uuid)
        join public.products p on p.id = x.product_id and p.mall_id = p_mall
        where private.product_on_sale(p.id) and p.price_cents > v_floor
          and (t.product_id is null or t.product_id = p.id)) off
      where v.owner_id = me and v.status = 'issued' and v.expires_at > now() and t.mall_id = p_mall
        and t.active and off.minor is not null
        and not exists (select 1 from public.points_blocks b where b.user_id = me)));$new$);
  if position('off.minor' in fixed) = 0 or position('v_lines jsonb' in fixed) = 0 then
    raise exception 'shop_quote did not change';
  end if;
  execute fixed;
end;
$$;

-- ─── Staff ──────────────────────────────────────────

-- Content staff run campaigns. A voucher takes money off a shop's proceeds, so
-- its amount is for payments staff, as commission is, who also need to see the
-- games behind what they flag.
create function private.staff_require_game() returns void
language plpgsql stable set search_path = '' as $$
begin
  if not (private.is_staff('content') or private.is_staff('payments')) then
    raise exception 'Not found.' using errcode = 'P0001';
  end if;
end;
$$;

do $$
declare
  f text;
  d text;
  fixed text;
begin
  foreach f in array array['public.staff_campaign_list()', 'public.staff_organizer_games(integer)',
    'public.staff_redemptions(integer)']
  loop
    d := pg_get_functiondef(f::regprocedure);
    fixed := replace(d, $old$perform private.staff_require('content');$old$, 'perform private.staff_require_game();');
    if fixed = d then raise exception '% did not change', f; end if;
    execute fixed;
  end loop;

  -- A live campaign can run longer. To stop it early, end it.
  d := pg_get_functiondef('public.staff_campaign_save(jsonb, text)'::regprocedure);
  fixed := replace(d, $old$    if v_status = 'ended' then raise exception 'This campaign has ended.'; end if;$old$,
    $new$    if v_status = 'ended' then raise exception 'This campaign has ended.'; end if;
    if v_status = 'live' and (p ->> 'ends_at')::timestamptz
        < (select c.ends_at from public.campaigns c where c.id = v_id) then
      raise exception 'A live campaign can''t end sooner. End it instead.';
    end if;$new$);
  if fixed = d then raise exception 'staff_campaign_save did not change'; end if;
  execute fixed;
end;
$$;

create or replace function public.staff_voucher_type_save(p jsonb, p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: voucher types have no client write path.
declare
  v_id uuid := nullif(p ->> 'id', '')::uuid;
  v_default boolean := coalesce((p ->> 'organizer_default')::boolean, false);
  v_kind text := p ->> 'kind';
  v_mall uuid := nullif(p ->> 'mall_id', '')::uuid;
  v_product uuid := nullif(p ->> 'product_id', '')::uuid;
begin
  perform private.staff_require('payments');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  if v_id is not null then
    select kind into v_kind from public.voucher_types where id = v_id;
    if v_kind is null then raise exception 'Not found.' using errcode = 'P0001'; end if;
  elsif v_product is not null and not exists (select 1 from public.products x
      where x.id = v_product and x.mall_id = v_mall) then
    raise exception 'That product isn''t from this shop.';
  end if;
  -- One default of each kind at a time.
  if v_default then
    update public.voucher_types set organizer_default = false
    where kind = v_kind and organizer_default and id is distinct from v_id;
  end if;
  if v_id is null then
    insert into public.voucher_types (name, kind, mall_id, venue_id, amount_minor, product_id, expiry_days, organizer_default)
    values (trim(p ->> 'name'), v_kind, v_mall, nullif(p ->> 'venue_id', '')::uuid,
      (p ->> 'amount_minor')::bigint, v_product, nullif(p ->> 'expiry_days', '')::int, v_default)
    returning id into v_id;
  else
    -- What's already issued keeps the terms it was issued on: only new ones change.
    update public.voucher_types set name = trim(p ->> 'name'),
      organizer_default = v_default, active = coalesce((p ->> 'active')::boolean, active)
    where id = v_id;
  end if;
  perform private.staff_audit('voucher_type_saved', 'voucher_type', v_id::text, p_reason, p);
  return v_id;
end;
$$;

-- ─── Nobody calls these but the code above ────────────────────────

revoke execute on function private.voucher_issue(uuid, uuid, text), private.badge_grant(uuid, uuid, text),
  private.quest_count(public.quests, public.campaigns, uuid, timestamptz), private.quest_sync(uuid),
  private.quest_attendance(), private.milestone_reward(int), private.game_counted(uuid),
  private.organizer_game_check(uuid, uuid), private.organizer_sweep(), private.campaign_json(public.campaigns),
  private.next_milestone(int), private.voucher_usable(uuid, uuid), private.voucher_return(uuid),
  private.shop_price(uuid, jsonb, bigint, uuid), private.staff_require_game()
from public, anon, authenticated;
