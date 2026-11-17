-- P2-01. Location is optional, needs consent, and is kept only as a coarse
-- geohash. It is used to sort things near you and is never shown to anyone. It
-- is not used to find players at all: sorting people by distance would leak
-- roughly where they are.

insert into public.app_settings (key, value, description) values
  ('discover.geohash_precision', '5', 'Geohash characters kept, about 5 km'),
  ('discover.default_km', '15', 'Default search distance');

create table public.consents (
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('location')),
  granted_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  primary key (user_id, kind)
);

create table public.private_locations (
  user_id uuid primary key references auth.users (id) on delete cascade,
  geohash text not null check (geohash ~ '^[0-9b-hjkmnp-z]{1,12}$'),
  updated_at timestamptz not null default now()
);

alter table public.consents enable row level security;
alter table public.private_locations enable row level security;
revoke all on public.consents, public.private_locations from anon, authenticated;
grant select on public.consents to authenticated;
create policy "Players read their own consents" on public.consents
  for select to authenticated using (user_id = (select auth.uid()));
-- private_locations has no client access at all.

create function public.consent_set(p_kind text, p_granted boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes consents, and withdrawing removes the stored location.
begin
  insert into public.consents as c (user_id, kind, granted_at, withdrawn_at)
  values (auth.uid(), p_kind, now(), case when p_granted then null else now() end)
  on conflict (user_id, kind) do update
    set granted_at = case when p_granted then now() else c.granted_at end,
        withdrawn_at = case when p_granted then null else now() end;
  if p_kind = 'location' and not p_granted then
    delete from public.private_locations where user_id = auth.uid();
  end if;
end;
$$;

-- Whatever the phone sends, only the coarse part is kept.
create function public.location_set(p_geohash text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: private_locations has no client access.
begin
  if not exists (select 1 from public.consents c
      where c.user_id = auth.uid() and c.kind = 'location' and c.withdrawn_at is null) then
    raise exception 'Turn on location first.';
  end if;
  insert into public.private_locations as l (user_id, geohash)
  values (auth.uid(), left(lower(p_geohash), private.setting_int('discover.geohash_precision')))
  on conflict (user_id) do update set geohash = excluded.geohash, updated_at = now();
end;
$$;

-- The centre of a geohash cell.
create function private.geohash_center(p_hash text, out lat double precision, out lng double precision)
language plpgsql immutable set search_path = '' as $$
declare
  alphabet constant text := '0123456789bcdefghjkmnpqrstuvwxyz';
  lat_lo double precision := -90; lat_hi double precision := 90;
  lng_lo double precision := -180; lng_hi double precision := 180;
  even boolean := true;
  v int;
  bit int;
begin
  for i in 1..length(p_hash) loop
    v := strpos(alphabet, substr(p_hash, i, 1)) - 1;
    for b in reverse 4..0 loop
      bit := (v >> b) & 1;
      if even then
        if bit = 1 then lng_lo := (lng_lo + lng_hi) / 2; else lng_hi := (lng_lo + lng_hi) / 2; end if;
      else
        if bit = 1 then lat_lo := (lat_lo + lat_hi) / 2; else lat_hi := (lat_lo + lat_hi) / 2; end if;
      end if;
      even := not even;
    end loop;
  end loop;
  lat := (lat_lo + lat_hi) / 2;
  lng := (lng_lo + lng_hi) / 2;
end;
$$;

create function private.km_between(a_lat double precision, a_lng double precision,
  b_lat double precision, b_lng double precision) returns double precision
-- Strict: least() ignores nulls, so a missing position would otherwise come
-- out as the far side of the planet.
language sql immutable strict set search_path = '' as $$
  select 6371 * 2 * asin(least(1, sqrt(
    power(sin(radians(b_lat - a_lat) / 2), 2)
    + cos(radians(a_lat)) * cos(radians(b_lat)) * power(sin(radians(b_lng - a_lng) / 2), 2))));
$$;

-- The caller's own coarse position, or nothing.
create function private.my_center(out lat double precision, out lng double precision)
language sql stable security definer set search_path = '' as $$
  -- Definer: private_locations has no client access. Only ever the caller's.
  select c.lat, c.lng from public.private_locations l
  cross join lateral private.geohash_center(l.geohash) c
  where l.user_id = auth.uid();
$$;

revoke execute on function private.geohash_center(text) from public;
revoke execute on function private.km_between(double precision, double precision, double precision, double precision) from public;
revoke execute on function private.my_center() from public;
grant execute on function private.geohash_center(text) to authenticated, service_role;
grant execute on function private.km_between(double precision, double precision, double precision, double precision) to authenticated, service_role;
grant execute on function private.my_center() to authenticated, service_role;

-- Runs as the caller, so every rule on activities applies: hidden items, club
-- Meets and blocked hosts all drop out by themselves.
create function public.discover_sessions(
  p_sport text default null,
  p_level numeric default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_hour_from int default null,
  p_hour_to int default null,
  p_max_km double precision default null,
  p_limit int default 50
) returns jsonb
language sql stable set search_path = '' as $$
  with me as (select lat, lng from private.my_center()),
  rows as (
    select to_jsonb(c) || jsonb_build_object('km', k.km, 'latitude', v.latitude, 'longitude', v.longitude,
      'fits_me', exists (select 1 from public.player_sports ps
        where ps.user_id = auth.uid() and ps.sport = any (c.sports)
          and (c.level_min is null or ps.play_max >= c.level_min)
          and (c.level_max is null or ps.play_min <= c.level_max))) as j,
      k.km, c.starts_at
    from public.activity_cards c
    join public.venues v on v.id = c.venue_id
    left join lateral (
      select private.km_between(me.lat, me.lng, v.latitude, v.longitude) as km from me
    ) k on v.latitude is not null
    where c.status = 'published' and c.kind = 'meet'
      and c.starts_at >= coalesce(p_from, now())
      and (p_to is null or c.starts_at < p_to)
      and (p_sport is null or p_sport = any (c.sports))
      and (p_level is null or ((c.level_min is null or p_level >= c.level_min)
        and (c.level_max is null or p_level <= c.level_max)))
      and (p_hour_from is null or extract(hour from c.starts_at at time zone 'Asia/Singapore') >= p_hour_from)
      and (p_hour_to is null or extract(hour from c.starts_at at time zone 'Asia/Singapore') < p_hour_to)
      and (p_max_km is null or k.km is null or k.km <= p_max_km)
  )
  select coalesce(jsonb_agg(j order by km nulls last, starts_at), '[]'::jsonb)
  from (select * from rows order by km nulls last, starts_at limit least(p_limit, 100)) r;
$$;

-- No distance here, on purpose. See the top of this file.
create function public.discover_players(
  p_sport text default null,
  p_level numeric default null,
  p_limit int default 30
) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: ranks across player_sports. Minors, blocked players, hidden
  -- profiles and players who chose "only me" are left out.
  select coalesce(jsonb_agg(public.player_json(x.id) || jsonb_build_object('level', x.level)
    order by x.fits desc, x.level desc), '[]'::jsonb)
  from (
    select distinct on (p.id) p.id, ps.level,
      exists (select 1 from public.player_sports m where m.user_id = auth.uid()
        and m.sport = ps.sport and ps.level between m.play_min and m.play_max) as fits
    from public.player_sports ps
    join public.profiles p on p.id = ps.user_id
    where p.onboarding_completed and p.id <> auth.uid()
      and p.visibility <> 'only_me' and p.hidden_at is null
      and not private.is_minor(p.id)
      and not public.is_blocked_between(auth.uid(), p.id)
      and (p_sport is null or ps.sport = p_sport)
      and (p_level is null or ps.level = p_level)
    limit least(p_limit, 100)
  ) x;
$$;

create function public.discover_groups(
  p_sport text default null,
  p_query text default null,
  p_max_km double precision default null,
  p_limit int default 30
) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: clubs has no client policies. Only public groups the caller may
  -- see, and a child only sees groups a parent approved.
  with me as (select lat, lng from private.my_center())
  select coalesce(jsonb_agg(public.club_json(x.id) || jsonb_build_object('km', x.km)
    order by x.km nulls last, x.name), '[]'::jsonb)
  from (
    select c.id, c.name, k.km
    from public.clubs c
    left join public.venues v on v.id = c.home_venue_id
    left join lateral (
      select private.km_between(me.lat, me.lng, v.latitude, v.longitude) as km from me
    ) k on v.latitude is not null
    where c.visibility = 'public' and c.hidden_at is null
      and private.group_allowed(auth.uid(), c.id)
      and not exists (select 1 from public.club_bans b where b.club_id = c.id and b.user_id = auth.uid())
      and (p_query is null or c.name ilike '%' || p_query || '%' or c.area ilike '%' || p_query || '%')
      and (p_sport is null or c.sports::text ilike '%' || p_sport || '%')
      and (p_max_km is null or k.km is null or k.km <= p_max_km)
    order by k.km nulls last
    limit least(p_limit, 100)
  ) x;
$$;

revoke execute on function public.consent_set(text, boolean) from public, anon;
revoke execute on function public.location_set(text) from public, anon;
revoke execute on function public.discover_sessions(text, numeric, timestamptz, timestamptz, int, int, double precision, int) from public, anon;
revoke execute on function public.discover_players(text, numeric, int) from public, anon;
revoke execute on function public.discover_groups(text, text, double precision, int) from public, anon;
grant execute on function public.consent_set(text, boolean) to authenticated;
grant execute on function public.location_set(text) to authenticated;
grant execute on function public.discover_sessions(text, numeric, timestamptz, timestamptz, int, int, double precision, int) to authenticated;
grant execute on function public.discover_players(text, numeric, int) to authenticated;
grant execute on function public.discover_groups(text, text, double precision, int) to authenticated;
