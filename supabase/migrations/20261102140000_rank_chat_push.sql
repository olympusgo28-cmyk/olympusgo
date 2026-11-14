-- P2-04 group ranking, P2-05 chat, P2-06 push.

insert into public.app_settings (key, value, description) values
  ('campaign.min_present', '6', 'Players Present for a game to count'),
  ('ranking.window_days', '90', 'Days of counted games a group is ranked on'),
  ('notify.quiet_from_hour', '22', 'Quiet hours start, local (R-NOT-4)'),
  ('notify.quiet_to_hour', '7', 'Quiet hours end, local (R-NOT-4)');

-- ─── The counted-game rule, in one place ───────────────────────────────────

-- Host rewards (Phase 4) will use this too: 6 or more Present, every player
-- paid, every player checked in by a host's QR scan. Paid is skipped while
-- campaign.require_paid is off, because nobody can pay yet.
create function private.game_counts(p_players jsonb, p_present int) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads settings for any caller.
  select p_present >= private.setting_int('campaign.min_present')
    and not exists (select 1 from jsonb_array_elements(p_players) x
      where (x ->> 'present')::boolean
        and (not (x ->> 'qr')::boolean
          or (private.flag('campaign.require_paid') and not (x ->> 'paid')::boolean)));
$$;
revoke execute on function private.game_counts(jsonb, int) from public;
grant execute on function private.game_counts(jsonb, int) to authenticated, service_role;

-- Groups only. No player is named anywhere in this.
create function public.group_activity_rank(p_limit int default 50) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: counts across the game log, which hosts alone can read, and
  -- returns only group names and totals.
  select coalesce(jsonb_agg(jsonb_build_object('rank', x.rk, 'club_id', x.id, 'name', x.name,
      'area', x.area, 'games', x.games) order by x.rk), '[]'::jsonb)
  from (
    select c.id, c.name, c.area, count(*)::int as games,
      rank() over (order by count(*) desc)::int as rk
    from public.campaign_game_log l
    join public.activities a on a.id = l.activity_id
    join public.clubs c on c.id = a.club_id
    where l.saved_at > now() - make_interval(days => private.setting_int('ranking.window_days'))
      and private.game_counts(l.players, l.present_count)
      and c.visibility = 'public' and c.hidden_at is null
      and private.group_allowed(auth.uid(), c.id)
    group by c.id
    order by games desc
    limit least(p_limit, 100)
  ) x;
$$;
revoke execute on function public.group_activity_rank(int) from public, anon;
grant execute on function public.group_activity_rank(int) to authenticated;

-- ─── Chat ──────────────────────────────────────────────────────────────────

alter table public.messages
  -- Set by the phone, so a retry after a dropped connection cannot double-post.
  add column client_id uuid,
  add column deleted_at timestamptz;
create unique index messages_client_idx on public.messages (sender_id, client_id);

-- What a deleted message said, for staff if it was reported.
create table public.message_archive (
  message_id bigint primary key,
  body text not null,
  deleted_at timestamptz not null default now()
);
alter table public.message_archive enable row level security;
revoke all on public.message_archive from anon, authenticated;

create function public.message_delete(p_message bigint) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: messages have no update policy; only the sender gets this far.
declare
  m public.messages;
begin
  select * into m from public.messages where id = p_message and sender_id = auth.uid() for update;
  if m.id is null then raise exception 'You can only delete your own messages.'; end if;
  if m.deleted_at is not null then return; end if;
  insert into public.message_archive (message_id, body) values (m.id, m.body);
  update public.messages set body = 'Message deleted', deleted_at = now() where id = p_message;
end;
$$;
revoke execute on function public.message_delete(bigint) from public, anon;
grant execute on function public.message_delete(bigint) to authenticated;

alter publication supabase_realtime add table public.notifications;

-- ─── Push ──────────────────────────────────────────────────────────────────

alter table public.notifications add column kind text not null default 'general'
  check (kind in ('general', 'session', 'message', 'follower'));

create table public.device_tokens (
  token text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  updated_at timestamptz not null default now()
);
create index device_tokens_user_idx on public.device_tokens (user_id);

create table public.push_queue (
  id bigint generated always as identity primary key,
  notification_id uuid not null,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  body text not null,
  not_before timestamptz not null,
  sent_at timestamptz,
  skipped boolean not null default false
);
create index push_queue_due_idx on public.push_queue (not_before) where sent_at is null and not skipped;

alter table public.device_tokens enable row level security;
alter table public.push_queue enable row level security;
revoke all on public.device_tokens, public.push_queue from anon, authenticated;

create function public.device_token_save(p_token text, p_platform text) returns void
language sql security definer set search_path = '' as $$
  -- Definer: device_tokens has no client access. A phone moves to whoever
  -- signed in on it last.
  insert into public.device_tokens (token, user_id, platform) values (p_token, auth.uid(), p_platform)
  on conflict (token) do update set user_id = excluded.user_id, updated_at = now();
$$;
revoke execute on function public.device_token_save(text, text) from public, anon;
grant execute on function public.device_token_save(text, text) to authenticated;

-- When quiet hours end for this player, or now if they are not in them.
create function private.quiet_until(p_user uuid) returns timestamptz
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads private settings and the player's country.
declare
  v_tz text := coalesce((select c.timezone from public.account_private a
    join public.country_config c on c.country_code = a.country_code where a.id = p_user), 'Asia/Singapore');
  v_local timestamp := now() at time zone v_tz;
  v_hour int := extract(hour from v_local);
  v_from int := private.setting_int('notify.quiet_from_hour');
  v_to int := private.setting_int('notify.quiet_to_hour');
begin
  if v_hour >= v_from then
    return (date_trunc('day', v_local) + interval '1 day' + make_interval(hours => v_to)) at time zone v_tz;
  elsif v_hour < v_to then
    return (date_trunc('day', v_local) + make_interval(hours => v_to)) at time zone v_tz;
  end if;
  return now();
end;
$$;
revoke execute on function private.quiet_until(uuid) from public;

-- Every notification may become a push. Session changes ignore quiet hours;
-- everything else waits (R-NOT-4). Per-kind settings are honoured here.
create function private.queue_push() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: writes push_queue and reads the player's settings.
declare
  s public.notification_settings;
  v_kind text := case
    when new.kind <> 'general' then new.kind
    when new.link like '/activities/%' then 'session'
    else 'general' end;
begin
  select * into s from public.notification_settings where user_id = new.user_id;
  if (v_kind = 'message' and s.messages is false)
    or (v_kind = 'follower' and s.new_followers is false)
    or (v_kind = 'general' and s.offers_and_news is false) then
    return new;
  end if;
  insert into public.push_queue (notification_id, user_id, title, body, not_before)
  values (new.id, new.user_id, new.title, coalesce(new.body, ''),
    case when v_kind = 'session' then now() else private.quiet_until(new.user_id) end);
  return new;
end;
$$;

create trigger notifications_queue_push after insert on public.notifications
  for each row execute function private.queue_push();

-- For the send-push function only.
create function public.push_due(p_limit int default 100) returns jsonb
language sql security definer set search_path = '' as $$
  -- Definer: push_queue has no client access.
  select coalesce(jsonb_agg(jsonb_build_object('id', q.id, 'title', q.title, 'body', q.body,
    'tokens', (select coalesce(jsonb_agg(d.token), '[]'::jsonb) from public.device_tokens d
      where d.user_id = q.user_id))), '[]'::jsonb)
  from (select * from public.push_queue where sent_at is null and not skipped
    and not_before <= now() order by id limit p_limit) q;
$$;

create function public.push_mark(p_ids bigint[], p_sent boolean) returns void
language sql security definer set search_path = '' as $$
  -- Definer: push_queue has no client access.
  update public.push_queue
  set sent_at = case when p_sent then now() end, skipped = not p_sent
  where id = any (p_ids);
$$;

revoke execute on function public.push_due(int) from public, anon, authenticated;
revoke execute on function public.push_mark(bigint[], boolean) from public, anon, authenticated;
grant execute on function public.push_due(int) to service_role;
grant execute on function public.push_mark(bigint[], boolean) to service_role;
