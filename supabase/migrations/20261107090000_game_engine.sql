-- P4d-01, P4d-02, P4d-03: campaigns, organizer rewards and the voucher wallet.
-- Rewards are grants with a unique key, so a retry can't issue twice. Nothing
-- here touches a rating. Checkout is in the next migration.

insert into public.feature_flags (key, enabled, description) values
  ('game.campaigns', false, 'Campaigns and quests on the Game tab'),
  ('game.organizer_rewards', false, 'Issuing organizer reward vouchers. Games count either way');

insert into public.app_settings (key, value, description) values
  ('voucher.expiry_days', '90', 'Days a voucher lasts, unless its type says otherwise (decision 3)');

-- ─── Vouchers ──────────────────────────────────────────────────────────────

-- A is funded by a shop, B by a venue. One of each is the organizer reward.
create table public.voucher_types (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 60),
  kind text not null check (kind in ('A', 'B')),
  mall_id uuid references public.malls (id),
  venue_id uuid references public.venues (id),
  amount_minor bigint not null check (amount_minor between 1 and 100000),
  product_id uuid references public.products (id),
  expiry_days int check (expiry_days between 1 and 365),
  organizer_default boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  check ((kind = 'A') = (mall_id is not null)),
  check ((kind = 'B') = (venue_id is not null)),
  check (product_id is null or kind = 'A')
);
create unique index voucher_types_one_default on public.voucher_types (kind) where organizer_default;

create table public.vouchers (
  id uuid primary key default gen_random_uuid(),
  type_id uuid not null references public.voucher_types (id),
  owner_id uuid not null references auth.users (id) on delete cascade,
  -- Shown only to its owner, and never logged.
  code text not null unique,
  -- held: earned, and its redemption hasn't opened yet (Voucher B).
  status text not null default 'issued' check (status in ('issued', 'held', 'used', 'expired')),
  expires_at timestamptz,
  source text not null unique,
  issued_at timestamptz not null default now(),
  used_at timestamptz,
  check ((status = 'held') = (expires_at is null))
);
create index vouchers_owner_idx on public.vouchers (owner_id, status);
create index vouchers_expiry_idx on public.vouchers (expires_at) where status = 'issued';

-- Every use and return: who, which shop, when. Never the code.
create table public.voucher_redemptions (
  id bigint generated always as identity primary key,
  voucher_id uuid not null references public.vouchers (id),
  user_id uuid not null,
  mall_id uuid not null,
  order_id uuid not null,
  kind text not null check (kind in ('used', 'returned')),
  amount_minor bigint not null,
  at timestamptz not null default now(),
  unique (voucher_id, order_id, kind)
);
create trigger voucher_redemptions_append_only before update or delete on public.voucher_redemptions
  for each row execute function private.forbid_change();
create trigger voucher_redemptions_no_truncate before truncate on public.voucher_redemptions
  for each statement execute function private.forbid_change();

-- ─── Campaigns ─────────────────────────────────────────────────────────────

create table public.badges (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 60),
  blurb text not null default '' check (char_length(blurb) <= 200),
  created_at timestamptz not null default now()
);

create table public.campaigns (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 2 and 80),
  blurb text not null default '' check (char_length(blurb) <= 200),
  about text not null default '' check (char_length(about) <= 1000),
  color bigint not null default 4281285215,
  ink bigint not null default 4294967295,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'draft' check (status in ('draft', 'live', 'ended')),
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create table public.quests (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  type text not null check (type in ('play_sessions', 'attend_sessions', 'organize_counted')),
  target int not null check (target between 1 and 1000),
  voucher_type_id uuid references public.voucher_types (id),
  badge_id uuid references public.badges (id),
  position int not null default 1,
  check (num_nonnulls(voucher_type_id, badge_id) >= 1)
);
create index quests_campaign_idx on public.quests (campaign_id);

-- A person taking part.
create table public.challenges (
  campaign_id uuid not null references public.campaigns (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (campaign_id, user_id)
);
create index challenges_user_idx on public.challenges (user_id);

create table public.challenge_progress (
  quest_id uuid not null references public.quests (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  count int not null default 0,
  completed_at timestamptz,
  primary key (quest_id, user_id)
);

create table public.player_badges (
  badge_id uuid not null references public.badges (id),
  user_id uuid not null references auth.users (id) on delete cascade,
  source text not null unique,
  granted_at timestamptz not null default now(),
  primary key (badge_id, user_id)
);

-- Everything issued, or waiting to be. The key is what stops a second issue.
create table public.reward_grants (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('A', 'B')),
  status text not null default 'pending' check (status in ('pending', 'issued')),
  created_at timestamptz not null default now(),
  issued_at timestamptz
);
create index reward_grants_pending_idx on public.reward_grants (created_at) where status = 'pending';

-- One row for each Meet looked at. Numbers run on counted games, for life.
create table public.organizer_games (
  activity_id uuid primary key,
  host_id uuid not null references auth.users (id) on delete cascade,
  counted boolean not null,
  reason text not null check (reason in ('counted', 'cancelled', 'under_six', 'unpaid', 'not_scanned',
    'organizer_minor', 'organizer_flagged')),
  present int not null,
  game_no int,
  checked_at timestamptz not null default now(),
  unique (host_id, game_no),
  check (counted = (game_no is not null))
);
create index organizer_games_host_idx on public.organizer_games (host_id, checked_at desc);

alter table public.voucher_types enable row level security;
alter table public.vouchers enable row level security;
alter table public.voucher_redemptions enable row level security;
alter table public.badges enable row level security;
alter table public.campaigns enable row level security;
alter table public.quests enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_progress enable row level security;
alter table public.player_badges enable row level security;
alter table public.reward_grants enable row level security;
alter table public.organizer_games enable row level security;
-- Everything goes through the functions below.
revoke all on public.voucher_types, public.vouchers, public.voucher_redemptions, public.badges,
  public.campaigns, public.quests, public.challenges, public.challenge_progress, public.player_badges,
  public.reward_grants, public.organizer_games from anon, authenticated;

-- ─── Issuing ───────────────────────────────────────────────────────────────

create function private.voucher_issue(p_type uuid, p_user uuid, p_source text) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: vouchers have no client write path.
declare
  t public.voucher_types;
  v_id uuid;
begin
  select * into t from public.voucher_types where id = p_type;
  insert into public.vouchers (type_id, owner_id, code, status, expires_at, source)
  values (t.id, p_user, upper(encode(extensions.gen_random_bytes(6), 'hex')),
    case when t.kind = 'A' then 'issued' else 'held' end,
    case when t.kind = 'A' then now() + make_interval(days =>
      coalesce(t.expiry_days, private.setting_int('voucher.expiry_days'))) end,
    p_source)
  on conflict (source) do nothing
  returning id into v_id;
  if v_id is null then return false; end if;
  perform public.notify(p_user, 'You earned a voucher', t.name, '★', '/game/wallet', '#16181B', '#C6FF00');
  return true;
end;
$$;

-- Issued in one go with whatever earned it, or not at all.
create function private.badge_grant(p_badge uuid, p_user uuid, p_source text) returns void
language sql security definer set search_path = '' as $$
  -- Definer: badges have no client write path.
  insert into public.player_badges (badge_id, user_id, source) values (p_badge, p_user, p_source)
  on conflict do nothing;
$$;

-- ─── Quests ────────────────────────────────────────────────────────────────

create function private.quest_count(q public.quests, c public.campaigns, p_user uuid, p_from timestamptz)
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
       where ap.user_id = p_user and ap.attendance = 'present' and a.status <> 'cancelled'
         and a.starts_at >= greatest(c.starts_at, p_from) and a.starts_at < c.ends_at
         and (q.type = 'attend_sessions' or a.kind in ('meet', 'tournament'))) end;
$$;

-- Works progress out afresh, so a corrected attendance corrects it too. Once a
-- quest is done it stays done, and its reward goes with the same transaction.
create function private.quest_sync(p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes progress and rewards.
declare
  r record;
  v_count int;
  v_done boolean;
begin
  if not private.flag('game.campaigns') or exists (select 1 from public.points_blocks b where b.user_id = p_user) then
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
    v_done := v_count >= (r.q).target;
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

-- A quest never stops attendance being saved.
create function private.quest_attendance() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: fired by the organizer, for another player.
begin
  if new.attendance is distinct from old.attendance then
    begin
      perform private.quest_sync(new.user_id);
    exception when others then
      perform private.money_alert('quest_failed', 'quest-failed:' || new.user_id || ':' || now()::date,
        jsonb_build_object('activity', new.activity_id));
    end;
  end if;
  return new;
end;
$$;
create trigger activity_participants_quests after update of attendance on public.activity_participants
  for each row execute function private.quest_attendance();

-- ─── Organizer rewards (P4d-02) ────────────────────────────────────────────

-- Vouchers A and B for a counted game. Pure, and tested for games 1 to 40.
-- The checklist's table ends at 24, and the owner carried the pattern on.
create function private.milestone_reward(n int, out voucher_a int, out voucher_b int)
language sql immutable set search_path = '' as $$
  select case when n = 2 or n = 4 then 1 when n % 4 <> 0 or n <= 0 then 0
              when n in (8, 12) then 2 else 3 end,
         case when n > 0 and n % 8 = 0 then 1 else 0 end;
$$;

-- Whether a Meet counts, from what's true now rather than the first save: 6
-- Present, every participant paid the platform fee themselves and was scanned
-- in. The organizer needn't play or pay. If they took a paid spot they count
-- towards the 6, and they can't scan their own code. Paid is skipped only
-- while nobody can pay.
create function private.game_counted(p_activity uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads participants and payments.
declare
  a public.activities;
  v_require boolean := private.flag('campaign.require_paid') or private.flag('payments.enabled');
  v_present int := 0;
  r record;
  v_paid boolean;
begin
  select * into a from public.activities where id = p_activity;
  if a.status = 'cancelled' then
    return jsonb_build_object('reason', 'cancelled', 'present', 0);
  end if;
  for r in select ap.user_id, ap.check_in_method from public.activity_participants ap
    where ap.activity_id = p_activity and ap.status = 'joined' and ap.attendance = 'present'
  loop
    v_paid := exists (select 1 from public.payments p
      where p.activity_id = p_activity and p.user_id = r.user_id and p.status = 'succeeded'
        and p.purpose in ('meet', 'host_spot')
        and p.fee_minor > coalesce((select sum(x.fee_minor) from public.refunds x
          where x.payment_id = p.id and x.status <> 'voided'), 0)
        and not exists (select 1 from public.payment_disputes d
          where d.payment_id = p.id and d.status = 'lost'));
    if r.user_id = a.host_id then
      if v_paid or not v_require then v_present := v_present + 1; end if;
      continue;
    end if;
    if v_require and not v_paid then
      return jsonb_build_object('reason', 'unpaid', 'present', v_present);
    end if;
    if r.check_in_method is distinct from 'qr' then
      return jsonb_build_object('reason', 'not_scanned', 'present', v_present);
    end if;
    v_present := v_present + 1;
  end loop;
  if v_present < private.setting_int('campaign.min_present') then
    return jsonb_build_object('reason', 'under_six', 'present', v_present);
  end if;
  if private.is_minor(a.host_id) then
    return jsonb_build_object('reason', 'organizer_minor', 'present', v_present);
  end if;
  if exists (select 1 from public.points_blocks b where b.user_id = a.host_id) then
    return jsonb_build_object('reason', 'organizer_flagged', 'present', v_present);
  end if;
  return jsonb_build_object('reason', 'counted', 'present', v_present);
end;
$$;

-- Looks at each Meet once its money has settled. A game's number is fixed then.
create function private.organizer_game_check(p_activity uuid, p_host uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the game record and grants.
declare
  v jsonb;
  v_no int;
  m record;
begin
  perform pg_advisory_xact_lock(hashtext('organizer:' || p_host));
  if exists (select 1 from public.organizer_games g where g.activity_id = p_activity) then return; end if;
  v := private.game_counted(p_activity);
  if v ->> 'reason' = 'counted' then
    select coalesce(max(g.game_no), 0) + 1 into v_no from public.organizer_games g where g.host_id = p_host;
  end if;
  insert into public.organizer_games (activity_id, host_id, counted, reason, present, game_no)
  values (p_activity, p_host, v_no is not null, v ->> 'reason', (v ->> 'present')::int, v_no);
  if v_no is null then return; end if;
  m := private.milestone_reward(v_no);
  for i in 1 .. m.voucher_a loop
    insert into public.reward_grants (key, user_id, kind)
    values ('organizer:' || p_host || ':' || v_no || ':A:' || i, p_host, 'A') on conflict do nothing;
  end loop;
  for i in 1 .. m.voucher_b loop
    insert into public.reward_grants (key, user_id, kind)
    values ('organizer:' || p_host || ':' || v_no || ':B:' || i, p_host, 'B') on conflict do nothing;
  end loop;
  perform private.quest_sync(p_host);
end;
$$;

create function private.organizer_sweep() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: cron.
declare
  r record;
  v_type uuid;
begin
  for r in
    select l.activity_id, l.host_id from public.campaign_game_log l
    join public.activities a on a.id = l.activity_id
    where a.kind = 'meet' and a.ends_at <= now()
      and not exists (select 1 from public.organizer_games g where g.activity_id = l.activity_id)
      and not exists (select 1 from public.payments p
        where p.activity_id = l.activity_id and p.status = 'succeeded' and p.released_at is null
          and p.purpose in ('meet', 'host_spot', 'ticket', 'tournament'))
      and not exists (select 1 from public.activity_money_holds h
        where h.activity_id = l.activity_id and h.closed_at is null)
    order by l.ends_at, l.activity_id limit 500
  loop
    begin
      perform private.organizer_game_check(r.activity_id, r.host_id);
    exception when others then
      perform private.money_alert('organizer_sweep_failed', 'organizer-sweep:' || r.activity_id || ':' || now()::date,
        jsonb_build_object('activity', r.activity_id));
    end;
  end loop;

  -- What was earned before the rewards opened, or before a type was set, is
  -- issued now. A flagged account's stays waiting.
  if private.flag('game.organizer_rewards') then
    for r in select g.id, g.key, g.user_id, g.kind from public.reward_grants g
      where g.status = 'pending'
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

  update public.vouchers set status = 'expired' where status = 'issued' and expires_at <= now();
end;
$$;
select cron.schedule('organizer-sweep', '*/5 * * * *', 'select private.organizer_sweep()');

-- One rule decides rewards and rankings. No player is named anywhere in this.
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
    where g.counted and g.checked_at > now() - make_interval(days => private.setting_int('ranking.window_days'))
      and c.visibility = 'public' and c.hidden_at is null
      and private.group_allowed(auth.uid(), c.id)
    group by c.id
    order by games desc
    limit least(p_limit, 100)
  ) x;
$$;
drop function private.game_counts(jsonb, int);

-- ─── Reads and joining ─────────────────────────────────────────────────────

create function private.campaign_json(c public.campaigns) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: joins quests and the caller's own progress.
  select jsonb_build_object('id', c.id, 'title', c.title, 'blurb', c.blurb, 'about', c.about,
    'color', c.color, 'ink', c.ink, 'starts_at', c.starts_at, 'ends_at', c.ends_at,
    'state', case when c.status = 'ended' or c.ends_at <= now() then 'ended'
                  when c.starts_at > now() then 'upcoming' else 'live' end,
    'joined', exists (select 1 from public.challenges j where j.campaign_id = c.id and j.user_id = auth.uid()),
    'players', (select count(*) from public.challenges j where j.campaign_id = c.id),
    'quests', (select coalesce(jsonb_agg(jsonb_build_object('id', q.id, 'type', q.type, 'target', q.target,
        'count', coalesce(p.count, 0), 'done', p.completed_at is not null,
        'voucher', (select t.name from public.voucher_types t where t.id = q.voucher_type_id),
        'badge', (select b.name from public.badges b where b.id = q.badge_id)) order by q.position, q.id), '[]')
      from public.quests q
      left join public.challenge_progress p on p.quest_id = q.id and p.user_id = auth.uid()
      where q.campaign_id = c.id));
$$;

create function public.campaign_list() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: campaigns have no client access.
  select coalesce(jsonb_agg(private.campaign_json(c) order by c.ends_at desc), '[]')
  from public.campaigns c where c.status <> 'draft' and private.flag('game.campaigns');
$$;

create function public.campaign_get(p_campaign uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: campaigns have no client access.
declare
  c public.campaigns;
begin
  select * into c from public.campaigns where id = p_campaign and status <> 'draft';
  if c.id is null or not private.flag('game.campaigns') then raise exception 'This campaign has ended.'; end if;
  return private.campaign_json(c);
end;
$$;

create function public.campaign_join(p_campaign uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the caller's own row.
declare
  c public.campaigns;
begin
  if private.is_minor(auth.uid()) then raise exception 'Campaigns are for adults for now.'; end if;
  select * into c from public.campaigns where id = p_campaign and status = 'live';
  if c.id is null or not private.flag('game.campaigns') or c.ends_at <= now() then
    raise exception 'This campaign has ended.';
  end if;
  insert into public.challenges (campaign_id, user_id) values (p_campaign, auth.uid())
  on conflict do nothing;
  perform private.quest_sync(auth.uid());
end;
$$;

-- The code goes to its owner and nowhere else.
create function public.voucher_my() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: vouchers have no client access.
  select coalesce(jsonb_agg(jsonb_build_object('id', v.id, 'name', t.name, 'code', v.code, 'kind', t.kind,
      'status', case when v.status = 'issued' and v.expires_at <= now() then 'expired' else v.status end,
      'amount_minor', t.amount_minor, 'expires_at', v.expires_at, 'used_at', v.used_at, 'issued_at', v.issued_at,
      'mall_id', t.mall_id, 'where', coalesce((select m.name from public.malls m where m.id = t.mall_id),
        (select x.name from public.venues x where x.id = t.venue_id), ''))
      order by v.status = 'issued' desc, v.expires_at), '[]')
  from public.vouchers v join public.voucher_types t on t.id = v.type_id
  where v.owner_id = auth.uid();
$$;

create function public.badge_my() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: badges have no client access. A flagged account shows none (R-PTS-6).
  select coalesce(jsonb_agg(jsonb_build_object('name', b.name, 'blurb', b.blurb, 'at', p.granted_at)
      order by p.granted_at desc), '[]')
  from public.player_badges p join public.badges b on b.id = p.badge_id
  where p.user_id = auth.uid()
    and not exists (select 1 from public.points_blocks x where x.user_id = auth.uid());
$$;

-- The next reward after n counted games.
create function private.next_milestone(n int) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object('game', g, 'voucher_a', (private.milestone_reward(g)).voucher_a,
    'voucher_b', (private.milestone_reward(g)).voucher_b)
  from generate_series(n + 1, n + 8) g
  where (private.milestone_reward(g)).voucher_a > 0 order by g limit 1;
$$;

create function public.organizer_rewards_my() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: the record has no client access. Only the caller's own games.
  with mine as (select count(*) filter (where g.counted)::int as n from public.organizer_games g
    where g.host_id = auth.uid())
  select jsonb_build_object('counted', mine.n, 'next', private.next_milestone(mine.n),
    'open', private.flag('game.organizer_rewards'),
    'waiting', (select count(*) from public.reward_grants x where x.user_id = auth.uid() and x.status = 'pending'),
    'games', (select coalesce(jsonb_agg(y.x), '[]') from (
      select jsonb_build_object('title', a.title, 'at', a.starts_at, 'counted', g.counted, 'reason', g.reason,
        'present', g.present, 'game_no', g.game_no) as x
      from public.organizer_games g join public.activities a on a.id = g.activity_id
      where g.host_id = auth.uid() order by g.checked_at desc limit 30) y))
  from mine;
$$;

-- ─── Staff ─────────────────────────────────────────────────────────────────

create function public.staff_campaign_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff read every campaign.
begin
  perform private.staff_require('content');
  return jsonb_build_object(
    'campaigns', (select coalesce(jsonb_agg(jsonb_build_object('id', c.id, 'title', c.title, 'blurb', c.blurb,
        'about', c.about, 'starts_at', c.starts_at, 'ends_at', c.ends_at, 'status', c.status,
        'players', (select count(*) from public.challenges j where j.campaign_id = c.id),
        'quests', (select coalesce(jsonb_agg(jsonb_build_object('id', q.id, 'type', q.type, 'target', q.target,
            'voucher_type_id', q.voucher_type_id, 'badge_id', q.badge_id) order by q.position), '[]')
          from public.quests q where q.campaign_id = c.id)) order by c.created_at desc), '[]')
      from public.campaigns c),
    'voucher_types', (select coalesce(jsonb_agg(jsonb_build_object('id', t.id, 'name', t.name, 'kind', t.kind,
        'mall_id', t.mall_id, 'venue_id', t.venue_id, 'amount_minor', t.amount_minor, 'product_id', t.product_id,
        'expiry_days', t.expiry_days, 'organizer_default', t.organizer_default, 'active', t.active,
        'funder', coalesce((select m.name from public.malls m where m.id = t.mall_id),
          (select v.name from public.venues v where v.id = t.venue_id)),
        'issued', (select count(*) from public.vouchers v where v.type_id = t.id)) order by t.created_at desc), '[]')
      from public.voucher_types t),
    'badges', (select coalesce(jsonb_agg(jsonb_build_object('id', b.id, 'name', b.name) order by b.name), '[]')
      from public.badges b),
    'shops', (select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'name', m.name) order by m.name), '[]')
      from public.malls m where m.active),
    'venues', (select coalesce(jsonb_agg(jsonb_build_object('id', v.id, 'name', v.name) order by v.name), '[]')
      from public.venues v));
end;
$$;

create function public.staff_campaign_save(p jsonb, p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: campaigns have no client write path.
declare
  v_id uuid := nullif(p ->> 'id', '')::uuid;
  v_status text;
  x jsonb;
begin
  perform private.staff_require('content');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  if (p ->> 'ends_at')::timestamptz <= (p ->> 'starts_at')::timestamptz then
    raise exception 'A campaign must end after it starts.';
  end if;
  if jsonb_array_length(coalesce(p -> 'quests', '[]')) = 0 then raise exception 'Add at least one quest.'; end if;
  if v_id is null then
    insert into public.campaigns (title, blurb, about, starts_at, ends_at)
    values (trim(p ->> 'title'), coalesce(p ->> 'blurb', ''), coalesce(p ->> 'about', ''),
      (p ->> 'starts_at')::timestamptz, (p ->> 'ends_at')::timestamptz)
    returning id into v_id;
    v_status := 'draft';
  else
    select status into v_status from public.campaigns where id = v_id for update;
    if v_status is null then raise exception 'Not found.' using errcode = 'P0001'; end if;
    if v_status = 'ended' then raise exception 'This campaign has ended.'; end if;
    update public.campaigns set title = trim(p ->> 'title'), blurb = coalesce(p ->> 'blurb', ''),
      about = coalesce(p ->> 'about', ''), ends_at = (p ->> 'ends_at')::timestamptz,
      starts_at = case when v_status = 'draft' then (p ->> 'starts_at')::timestamptz else starts_at end
    where id = v_id;
  end if;
  -- A live campaign's targets are what people signed up to.
  if v_status = 'draft' then
    delete from public.quests where campaign_id = v_id;
    for x in select value from jsonb_array_elements(p -> 'quests') loop
      insert into public.quests (campaign_id, type, target, voucher_type_id, badge_id)
      values (v_id, x ->> 'type', (x ->> 'target')::int, nullif(x ->> 'voucher_type_id', '')::uuid,
        nullif(x ->> 'badge_id', '')::uuid);
    end loop;
  end if;
  perform private.staff_audit('campaign_saved', 'campaign', v_id::text, p_reason, p);
  return v_id;
end;
$$;

create function public.staff_campaign_status(p_campaign uuid, p_status text, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: campaigns have no client write path.
declare
  v_was text;
begin
  perform private.staff_require('content');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  select status into v_was from public.campaigns where id = p_campaign for update;
  if v_was is null then raise exception 'Not found.' using errcode = 'P0001'; end if;
  if (v_was, p_status) not in (('draft', 'live'), ('live', 'ended')) then
    raise exception 'A campaign can''t go from % to %.', v_was, p_status;
  end if;
  update public.campaigns set status = p_status where id = p_campaign;
  perform private.staff_audit('campaign_status', 'campaign', p_campaign::text, p_reason,
    jsonb_build_object('status', p_status));
end;
$$;

create function public.staff_badge_save(p_name text, p_blurb text, p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: badges have no client write path.
declare
  v_id uuid;
begin
  perform private.staff_require('content');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  insert into public.badges (name, blurb) values (trim(p_name), coalesce(p_blurb, '')) returning id into v_id;
  perform private.staff_audit('badge_saved', 'badge', v_id::text, p_reason);
  return v_id;
end;
$$;

create function public.staff_voucher_type_save(p jsonb, p_reason text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: voucher types have no client write path.
declare
  v_id uuid := nullif(p ->> 'id', '')::uuid;
  v_default boolean := coalesce((p ->> 'organizer_default')::boolean, false);
  v_kind text := p ->> 'kind';
begin
  perform private.staff_require('content');
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  -- One default of each kind at a time.
  if v_default then
    update public.voucher_types set organizer_default = false
    where kind = v_kind and organizer_default and id is distinct from v_id;
  end if;
  if v_id is null then
    insert into public.voucher_types (name, kind, mall_id, venue_id, amount_minor, product_id, expiry_days, organizer_default)
    values (trim(p ->> 'name'), v_kind, nullif(p ->> 'mall_id', '')::uuid, nullif(p ->> 'venue_id', '')::uuid,
      (p ->> 'amount_minor')::bigint, nullif(p ->> 'product_id', '')::uuid, nullif(p ->> 'expiry_days', '')::int, v_default)
    returning id into v_id;
  else
    -- What's already issued keeps the terms it was issued on: only new ones change.
    update public.voucher_types set name = trim(p ->> 'name'),
      organizer_default = v_default, active = coalesce((p ->> 'active')::boolean, active)
    where id = v_id;
    if not found then raise exception 'Not found.' using errcode = 'P0001'; end if;
  end if;
  perform private.staff_audit('voucher_type_saved', 'voucher_type', v_id::text, p_reason, p);
  return v_id;
end;
$$;

-- Counted or not, and why. Opaque ids and totals only.
create function public.staff_organizer_games(p_limit int default 100) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff read the game record.
begin
  perform private.staff_require('content');
  return (select coalesce(jsonb_agg(y.x), '[]') from (
    select jsonb_build_object('activity_id', g.activity_id, 'title', a.title, 'at', a.starts_at,
      'organizer', coalesce(private.public_name(g.host_id), ''), 'counted', g.counted, 'reason', g.reason,
      'present', g.present, 'game_no', g.game_no) as x
    from public.organizer_games g join public.activities a on a.id = g.activity_id
    order by g.checked_at desc limit least(coalesce(p_limit, 100), 500)) y);
end;
$$;

-- Who, which shop, when. Never the code.
create function public.staff_redemptions(p_limit int default 100) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff read the redemption log.
begin
  perform private.staff_require('content');
  return (select coalesce(jsonb_agg(y.x), '[]') from (
    select jsonb_build_object('id', r.id, 'voucher', t.name, 'user', coalesce(private.public_name(r.user_id), ''),
      'mall', m.name, 'order_id', r.order_id, 'kind', r.kind, 'amount_minor', r.amount_minor, 'at', r.at) as x
    from public.voucher_redemptions r
    join public.vouchers v on v.id = r.voucher_id
    join public.voucher_types t on t.id = v.type_id
    join public.malls m on m.id = r.mall_id
    order by r.at desc limit least(coalesce(p_limit, 100), 500)) y);
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'campaign_list()', 'campaign_get(uuid)', 'campaign_join(uuid)', 'voucher_my()', 'badge_my()',
    'organizer_rewards_my()', 'staff_campaign_list()', 'staff_campaign_save(jsonb, text)',
    'staff_campaign_status(uuid, text, text)', 'staff_badge_save(text, text, text)',
    'staff_voucher_type_save(jsonb, text)', 'staff_organizer_games(integer)', 'staff_redemptions(integer)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;
