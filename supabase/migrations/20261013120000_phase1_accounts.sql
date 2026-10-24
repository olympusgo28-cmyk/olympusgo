-- Phase 1: accounts, onboarding and the player Passport.

create extension if not exists citext with schema extensions;

-- Public profile: what other players see.
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username extensions.citext unique
    check (username ~ '^[A-Za-z0-9_]{3,30}$'),
  full_name text check (char_length(full_name) between 1 and 80),
  bio text check (char_length(bio) <= 300),
  avatar_url text,
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Private account details: only the owner can read them.
create table public.account_private (
  id uuid primary key references auth.users (id) on delete cascade,
  birthday date check (birthday > date '1900-01-01' and birthday <= current_date),
  country_code text not null default 'SG'
    check (country_code in ('SG', 'MY', 'ID', 'TH')),
  parent_email text check (parent_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  parent_approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- One row per sport on a player's Passport.
create table public.player_sports (
  user_id uuid not null references auth.users (id) on delete cascade,
  sport text not null check (sport in (
    'badminton', 'pickleball', 'tennis', 'padel', 'table_tennis',
    'basketball', 'football', 'running', 'swimming', 'cycling'
  )),
  level numeric(2, 1) not null check (level between 1 and 8 and level * 2 = floor(level * 2)),
  play_min numeric(2, 1) not null check (play_min between 1 and 8 and play_min * 2 = floor(play_min * 2)),
  play_max numeric(2, 1) not null check (play_max between 1 and 8 and play_max * 2 = floor(play_max * 2)),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, sport),
  check (play_min <= play_max)
);

-- "Get back your account" requests, reviewed by support. Write-only from the app.
create table public.account_recovery_requests (
  id bigint generated always as identity primary key,
  contact_email text not null check (contact_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  created_at timestamptz not null default now()
);

-- updated_at bookkeeping.
create function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();
create trigger account_private_touch before update on public.account_private
  for each row execute function public.touch_updated_at();
create trigger player_sports_touch before update on public.player_sports
  for each row execute function public.touch_updated_at();

-- The design promises a birthday "can't be changed later".
create function public.lock_birthday() returns trigger
language plpgsql set search_path = '' as $$
begin
  if old.birthday is not null and new.birthday is distinct from old.birthday then
    raise exception 'Your birthday can''t be changed once it is set.'
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger account_private_lock_birthday before update on public.account_private
  for each row execute function public.lock_birthday();

-- Every new sign-in user gets empty profile rows to fill during onboarding.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id) values (new.id);
  insert into public.account_private (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Username availability without exposing the profiles table to guests.
create function public.username_available(name text) returns boolean
language sql stable security definer set search_path = '' as $$
  select name ~ '^[A-Za-z0-9_]{3,30}$'
    and not exists (
      select 1 from public.profiles p
      where p.username = name::extensions.citext
        and p.id is distinct from auth.uid()
    );
$$;

revoke execute on function public.username_available(text) from public, anon;
grant execute on function public.username_available(text) to authenticated;

-- Row level security.
alter table public.profiles enable row level security;
alter table public.account_private enable row level security;
alter table public.player_sports enable row level security;
alter table public.account_recovery_requests enable row level security;

create policy "Signed-in players can see profiles"
  on public.profiles for select to authenticated using (true);
create policy "Players update their own profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "Players read their own private details"
  on public.account_private for select to authenticated
  using ((select auth.uid()) = id);
create policy "Players update their own private details"
  on public.account_private for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "Signed-in players can see Passports"
  on public.player_sports for select to authenticated using (true);
create policy "Players add their own sports"
  on public.player_sports for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Players change their own sports"
  on public.player_sports for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Players remove their own sports"
  on public.player_sports for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "Anyone can ask for account recovery"
  on public.account_recovery_requests for insert to anon, authenticated
  with check (true);

-- Parent approval is set by the server, never by the player.
revoke update (parent_approved_at) on public.account_private from authenticated;
