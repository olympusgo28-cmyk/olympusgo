-- Phase 2a: account settings, follows, blocks, reports, saved items and direct messages.

-- Profile fields edited in the Account centre and Privacy screens.
alter table public.profiles
  add column gender text not null default 'prefer_not_to_say'
    check (gender in ('male', 'female', 'non_binary', 'prefer_not_to_say')),
  add column visibility text not null default 'followers'
    check (visibility in ('everyone', 'followers', 'only_me')),
  add column show_level boolean not null default true,
  add column findable_by_phone boolean not null default false,
  add column share_location_at_meets boolean not null default true,
  add column country_code text not null default 'SG'
    check (country_code in ('SG', 'MY', 'ID', 'TH'));

-- Keep the public country in step with the private one set at onboarding.
create function public.sync_profile_country() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.profiles set country_code = new.country_code where id = new.id;
  return new;
end;
$$;

create trigger account_private_sync_country after insert or update of country_code
  on public.account_private for each row execute function public.sync_profile_country();

create table public.notification_settings (
  user_id uuid primary key references auth.users (id) on delete cascade,
  meet_reminders boolean not null default true,
  court_calls boolean not null default true,
  messages boolean not null default true,
  new_followers boolean not null default true,
  offers_and_news boolean not null default false,
  updated_at timestamptz not null default now()
);

create trigger notification_settings_touch before update on public.notification_settings
  for each row execute function public.touch_updated_at();

create table public.follows (
  follower_id uuid not null references auth.users (id) on delete cascade,
  followee_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);
create index follows_followee_idx on public.follows (followee_id);

create table public.blocks (
  blocker_id uuid not null references auth.users (id) on delete cascade,
  blocked_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table public.player_reports (
  id bigint generated always as identity primary key,
  reporter_id uuid not null references auth.users (id) on delete cascade,
  reported_id uuid not null references auth.users (id) on delete cascade,
  reason text not null check (reason in (
    'spam', 'harassment', 'inappropriate', 'cheating', 'other'
  )),
  created_at timestamptz not null default now()
);

create table public.saved_items (
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('meet', 'player', 'club')),
  item_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (user_id, kind, item_id)
);

create table public.support_requests (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  message text not null check (char_length(message) between 1 and 2000),
  created_at timestamptz not null default now()
);

-- Direct messages.
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create table public.conversation_members (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);
create index conversation_members_user_idx on public.conversation_members (user_id);

create table public.messages (
  id bigint generated always as identity primary key,
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index messages_conversation_idx on public.messages (conversation_id, created_at);

create function public.bump_conversation() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.conversations set last_message_at = new.created_at
  where id = new.conversation_id;
  update public.conversation_members set last_read_at = new.created_at
  where conversation_id = new.conversation_id and user_id = new.sender_id;
  return new;
end;
$$;

create trigger messages_bump after insert on public.messages
  for each row execute function public.bump_conversation();

-- Helpers. Security definer so RLS policies can call them without recursion.
create function public.is_conversation_member(conv uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.conversation_members
    where conversation_id = conv and user_id = auth.uid()
  );
$$;

create function public.is_blocked_between(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
  );
$$;

-- Opens the one-to-one conversation with another player, creating it once.
create function public.open_direct_conversation(other uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  conv uuid;
begin
  if me is null or other is null or me = other then
    raise exception 'Invalid conversation';
  end if;
  if public.is_blocked_between(me, other) then
    raise exception 'You can''t message this player.' using errcode = 'insufficient_privilege';
  end if;
  select a.conversation_id into conv
  from public.conversation_members a
  join public.conversation_members b on b.conversation_id = a.conversation_id
  where a.user_id = me and b.user_id = other
    and (select count(*) from public.conversation_members c
         where c.conversation_id = a.conversation_id) = 2
  limit 1;
  if conv is null then
    insert into public.conversations default values returning id into conv;
    insert into public.conversation_members (conversation_id, user_id)
    values (conv, me), (conv, other);
  end if;
  return conv;
end;
$$;

revoke execute on function public.open_direct_conversation(uuid) from public, anon;
grant execute on function public.open_direct_conversation(uuid) to authenticated;

-- Follower and following counts plus "do I follow them" for a profile.
create function public.profile_social(target uuid) returns table (
  followers bigint, following bigint, i_follow boolean, follows_me boolean
)
language sql stable security definer set search_path = '' as $$
  select
    (select count(*) from public.follows where followee_id = target),
    (select count(*) from public.follows where follower_id = target),
    exists (select 1 from public.follows where follower_id = auth.uid() and followee_id = target),
    exists (select 1 from public.follows where follower_id = target and followee_id = auth.uid());
$$;

revoke execute on function public.profile_social(uuid) from public, anon;
grant execute on function public.profile_social(uuid) to authenticated;

-- The blocker's own block list with names (profiles of blocked players are
-- otherwise hidden from them).
create function public.my_blocked_players() returns table (
  id uuid, username text, full_name text, avatar_url text
)
language sql stable security definer set search_path = '' as $$
  select p.id, p.username::text, p.full_name, p.avatar_url
  from public.blocks b join public.profiles p on p.id = b.blocked_id
  where b.blocker_id = auth.uid()
  order by b.created_at desc;
$$;

revoke execute on function public.my_blocked_players() from public, anon;
grant execute on function public.my_blocked_players() to authenticated;

-- Row level security.
alter table public.notification_settings enable row level security;
alter table public.follows enable row level security;
alter table public.blocks enable row level security;
alter table public.player_reports enable row level security;
alter table public.saved_items enable row level security;
alter table public.support_requests enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

create policy "Own notification settings" on public.notification_settings
  for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy "Follows are visible to signed-in players" on public.follows
  for select to authenticated using (true);
create policy "Players follow as themselves" on public.follows
  for insert to authenticated with check (
    (select auth.uid()) = follower_id
    and not public.is_blocked_between(follower_id, followee_id)
  );
create policy "Players unfollow as themselves" on public.follows
  for delete to authenticated using ((select auth.uid()) = follower_id);

create policy "Own blocks" on public.blocks
  for all to authenticated
  using ((select auth.uid()) = blocker_id) with check ((select auth.uid()) = blocker_id);

create policy "Players file reports as themselves" on public.player_reports
  for insert to authenticated with check ((select auth.uid()) = reporter_id);

create policy "Own saved items" on public.saved_items
  for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy "Players contact support as themselves" on public.support_requests
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Members see their conversations" on public.conversations
  for select to authenticated using (public.is_conversation_member(id));

create policy "Members see who is in their conversations" on public.conversation_members
  for select to authenticated using (public.is_conversation_member(conversation_id));
create policy "Members mark their own conversations read" on public.conversation_members
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy "Members read messages" on public.messages
  for select to authenticated using (public.is_conversation_member(conversation_id));
create policy "Members send messages as themselves" on public.messages
  for insert to authenticated with check (
    (select auth.uid()) = sender_id and public.is_conversation_member(conversation_id)
  );

-- Blocked players disappear from each other's profile reads.
drop policy "Signed-in players can see profiles" on public.profiles;
create policy "Signed-in players can see profiles they are not blocked from"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or not public.is_blocked_between((select auth.uid()), id));

-- Live updates for chat.
alter publication supabase_realtime add table public.messages;

-- Profile photos: public read, each player writes only their own folder.
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true)
  on conflict (id) do nothing;

create policy "Players upload their own avatar" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Players replace their own avatar" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Players remove their own avatar" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
