-- Sports and formats as data, each draft, live or maintenance. New Meets only
-- in live sports and formats, and each Meet keeps its own copy of the scoring
-- rules, so a format changed later leaves existing Meets alone.

create table public.sports (
  key text primary key check (key ~ '^[a-z_]{2,30}$'),
  name text not null,
  status text not null default 'draft' check (status in ('draft', 'live', 'maintenance')),
  position int not null default 0,
  updated_at timestamptz not null default now()
);

create table public.sport_formats (
  id uuid primary key default gen_random_uuid(),
  sport_key text not null references public.sports (key) on update cascade,
  -- Matches activities.game_type.
  key text not null check (key in ('singles', 'doubles', 'mixed', 'social')),
  name text not null,
  status text not null default 'draft' check (status in ('draft', 'live', 'maintenance')),
  min_players int not null check (min_players between 2 and 64),
  scoring jsonb not null default '{}'::jsonb,
  -- Junior rule options. Open decision 20: both badminton variants are kept
  -- until one is picked.
  variants jsonb not null default '[]'::jsonb,
  position int not null default 0,
  updated_at timestamptz not null default now(),
  unique (sport_key, key)
);

-- Every catalogue change, for good.
create table public.catalog_audit (
  id bigint generated always as identity primary key,
  table_name text not null,
  row_key text not null,
  action text not null,
  actor uuid,
  before jsonb,
  after jsonb,
  at timestamptz not null default now()
);

create function private.forbid_change() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception '% is append-only', tg_table_name;
end;
$$;

create trigger catalog_audit_append_only before update or delete on public.catalog_audit
  for each row execute function private.forbid_change();
create trigger catalog_audit_no_truncate before truncate on public.catalog_audit
  for each statement execute function private.forbid_change();

create function private.audit_catalog() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: catalog_audit is closed to every client role.
declare
  v_row jsonb := to_jsonb(coalesce(new, old));
begin
  insert into public.catalog_audit (table_name, row_key, action, actor, before, after)
  values (tg_table_name, coalesce(v_row ->> 'key', v_row ->> 'id'), lower(tg_op), auth.uid(),
    case when tg_op = 'INSERT' then null else to_jsonb(old) end,
    case when tg_op = 'DELETE' then null else to_jsonb(new) end);
  return coalesce(new, old);
end;
$$;

create trigger sports_audit after insert or update or delete on public.sports
  for each row execute function private.audit_catalog();
create trigger sport_formats_audit after insert or update or delete on public.sport_formats
  for each row execute function private.audit_catalog();
create trigger sports_touch before update on public.sports
  for each row execute function public.touch_updated_at();
create trigger sport_formats_touch before update on public.sport_formats
  for each row execute function public.touch_updated_at();

alter table public.sports enable row level security;
alter table public.sport_formats enable row level security;
alter table public.catalog_audit enable row level security;

-- Drafts stay out of sight. Maintenance rows stay visible so existing Meets
-- can still name their sport.
create policy "Live and maintenance sports are visible" on public.sports
  for select to anon, authenticated using (status <> 'draft');
create policy "Live and maintenance formats are visible" on public.sport_formats
  for select to anon, authenticated using (status <> 'draft');

-- Badminton, R-SCO-1. Pickleball, checklist P3-01.
insert into public.sports (key, name, status, position) values
  ('badminton', 'Badminton', 'live', 1),
  ('pickleball', 'Pickleball', 'live', 2),
  ('tennis', 'Tennis', 'draft', 3),
  ('table_tennis', 'Table tennis', 'draft', 4),
  ('squash', 'Squash', 'draft', 5),
  ('padel', 'Padel', 'draft', 6),
  -- On Passports from the earlier build, not on the launch list.
  ('basketball', 'Basketball', 'draft', 20),
  ('football', 'Football', 'draft', 21),
  ('running', 'Running', 'draft', 22),
  ('swimming', 'Swimming', 'draft', 23),
  ('cycling', 'Cycling', 'draft', 24),
  ('hyrox', 'Hyrox', 'draft', 25);

insert into public.sport_formats (sport_key, key, name, status, min_players, scoring, variants, position)
select s.sport, f.key, f.name, 'live', f.min_players, s.scoring, s.variants, f.position
from (values
  ('badminton',
   '{"points_to_win": 21, "win_by": 2, "cap": 30, "best_of": 3}'::jsonb,
   '[{"key": "junior_15", "points_to_win": 15, "win_by": 2, "cap": 21},
     {"key": "junior_11", "points_to_win": 11, "win_by": 2, "cap": 15}]'::jsonb),
  ('pickleball',
   '{"points_to_win": 11, "win_by": 2, "best_of": 3}'::jsonb,
   '[]'::jsonb)
) s(sport, scoring, variants)
cross join (values
  ('singles', 'Singles', 2, 1),
  ('doubles', 'Doubles', 4, 2),
  ('mixed', 'Mixed doubles', 4, 3),
  ('social', 'Doubles social', 5, 4)
) f(key, name, min_players, position);

-- ─── Meets follow the catalogue ────────────────────────────────────────────

alter table public.activities
  add column gender_mix text not null default 'any'
    check (gender_mix in ('any', 'men', 'women', 'mixed')),
  -- Spots kept for the host's own invites.
  add column reserved_slots int not null default 0 check (reserved_slots >= 0),
  add column court_booked boolean not null default false,
  add column scoring_snapshot jsonb,
  -- When the minimum was first reached, so "Game is on" is announced once.
  add column game_on_at timestamptz,
  add constraint activities_reserved_fits check (reserved_slots < capacity);

create function private.activity_before_insert() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: reads the catalogue, including rows a client cannot see, and sets
-- columns a client may not choose.
declare
  v_sport text;
  v_format public.sport_formats;
begin
  if private.is_restricted(new.host_id) then
    raise exception 'Ask a parent to link your account first.';
  end if;
  -- R-AGE-3: under 18, Public is never offered.
  if private.is_minor(new.host_id) then
    new.public_listing := false;
  end if;
  new.game_on_at := null;
  new.status := 'published';

  if new.kind <> 'meet' then
    new.scoring_snapshot := null;
    return new;
  end if;

  foreach v_sport in array new.sports loop
    if not exists (select 1 from public.sports s where s.key = v_sport and s.status = 'live') then
      raise exception 'That sport isn''t open for new Meets.';
    end if;
  end loop;

  if new.game_type is null then
    new.scoring_snapshot := null;
    return new;
  end if;
  select * into v_format from public.sport_formats f
  where f.sport_key = new.sports[1] and f.key = new.game_type;
  if v_format.id is null or v_format.status <> 'live' then
    raise exception 'That format isn''t open for new Meets.';
  end if;
  new.scoring_snapshot := v_format.scoring
    || jsonb_build_object('format_id', v_format.id, 'copied_at', now());
  new.min_players := coalesce(new.min_players, v_format.min_players);
  return new;
end;
$$;

create trigger activities_before_insert before insert on public.activities
  for each row execute function private.activity_before_insert();

-- Hosts edit their own Meet, but not the columns the server owns. Functions
-- run as their owner, so this only stops direct client writes.
create function private.activity_lock_columns() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user = 'authenticated' then
    new.status := old.status;
    new.host_id := old.host_id;
    new.kind := old.kind;
    new.scoring_snapshot := old.scoring_snapshot;
    new.game_on_at := old.game_on_at;
    if private.is_minor(old.host_id) then
      new.public_listing := false;
    end if;
  end if;
  return new;
end;
$$;

create trigger activities_lock_columns before update on public.activities
  for each row execute function private.activity_lock_columns();
