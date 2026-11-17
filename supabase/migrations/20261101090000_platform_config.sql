-- Checklist 3.2: numbers live in configuration, not code. These four tables
-- hold the fee, the age limits, the lockout times and the feature switches.
-- Staff change them through the admin app (A-01); nothing in the app can.

create schema if not exists private;
grant usage on schema private to anon, authenticated, service_role;

create table public.app_settings (
  key text primary key,
  value jsonb not null,
  description text not null default '',
  updated_at timestamptz not null default now()
);

create table public.country_config (
  country_code text primary key check (country_code ~ '^[A-Z]{2}$'),
  name text not null,
  currency char(3) not null,
  -- A zone name, never an offset (R-TIM-2).
  timezone text not null,
  -- Under this age: restricted child. At adult_age and over: adult.
  child_age int check (child_age between 1 and 21),
  adult_age int check (adult_age between 1 and 25),
  signup_open boolean not null default false,
  check (not signup_open or (child_age is not null and adult_age is not null)),
  check (child_age is null or adult_age is null or child_age < adult_age)
);

create table public.fee_rules (
  id bigint generated always as identity primary key,
  currency char(3) not null,
  applies_to text not null,
  -- Basis points: 1000 is 10%.
  percent_bps int not null check (percent_bps between 0 and 10000),
  minimum_minor bigint not null check (minimum_minor >= 0),
  active boolean not null default true,
  unique (currency, applies_to)
);

create table public.feature_flags (
  key text primary key,
  enabled boolean not null default false,
  description text not null default '',
  updated_at timestamptz not null default now()
);

create trigger app_settings_touch before update on public.app_settings
  for each row execute function public.touch_updated_at();
create trigger feature_flags_touch before update on public.feature_flags
  for each row execute function public.touch_updated_at();

alter table public.app_settings enable row level security;
alter table public.country_config enable row level security;
alter table public.fee_rules enable row level security;
alter table public.feature_flags enable row level security;

-- None of these hold a secret, and the app needs them before sign-in.
create policy "Anyone reads settings" on public.app_settings
  for select to anon, authenticated using (true);
create policy "Anyone reads countries" on public.country_config
  for select to anon, authenticated using (true);
create policy "Anyone reads fee rules" on public.fee_rules
  for select to anon, authenticated using (true);
create policy "Anyone reads flags" on public.feature_flags
  for select to anon, authenticated using (true);

-- Malaysia and New Zealand stay closed until a lawyer confirms their ages
-- (open decision 12). Indonesia and Thailand were in the earlier build; they
-- stay closed for the same reason.
insert into public.country_config
  (country_code, name, currency, timezone, child_age, adult_age, signup_open)
values
  ('SG', 'Singapore', 'SGD', 'Asia/Singapore', 13, 18, true),
  ('MY', 'Malaysia', 'MYR', 'Asia/Kuala_Lumpur', null, null, false),
  ('NZ', 'New Zealand', 'NZD', 'Pacific/Auckland', null, null, false),
  ('ID', 'Indonesia', 'IDR', 'Asia/Jakarta', null, null, false),
  ('TH', 'Thailand', 'THB', 'Asia/Bangkok', null, null, false);

alter table public.profiles drop constraint if exists profiles_country_code_check;
alter table public.account_private drop constraint if exists account_private_country_code_check;
alter table public.profiles add constraint profiles_country_fk
  foreign key (country_code) references public.country_config (country_code);
alter table public.account_private add constraint account_private_country_fk
  foreign key (country_code) references public.country_config (country_code);

insert into public.fee_rules (currency, applies_to, percent_bps, minimum_minor) values
  ('SGD', 'session', 1000, 200);

insert into public.app_settings (key, value, description) values
  ('auth.code_lock_attempts', '5', 'Wrong codes before the target is locked'),
  ('auth.code_lock_minutes', '15', 'How long a locked target stays locked'),
  ('auth.send_limit_target', '5', 'Code requests per target in the send window'),
  ('auth.send_limit_ip', '20', 'Code requests per IP in the send window'),
  ('auth.send_window_minutes', '15', 'Length of the code request window'),
  ('auth.login_pad_ms', '900', 'Every sign-in reply takes at least this long'),
  ('guardian.code_hours', '24', 'How long a parent link code lasts'),
  ('guardian.end_notice_days', '30', 'Notice before a link ends at adulthood'),
  ('meet.attendance_opens_minutes', '30', 'Attendance opens this long before the start');

insert into public.feature_flags (key, enabled, description) values
  ('payments.enabled', false, 'Real payments. Off until Gate C.'),
  ('campaign.require_paid', false, 'A counted game needs every player paid. Off until payments go live.');

-- Readers for the tables above. A missing key is a bug, so it raises.
create function private.setting_int(p_key text) returns int
language plpgsql stable security definer set search_path = '' as $$
-- Definer: callers include roles that may not read app_settings directly.
declare
  v int;
begin
  select (value #>> '{}')::int into v from public.app_settings where key = p_key;
  if v is null then raise exception 'Missing setting %', p_key; end if;
  return v;
end;
$$;

create function private.flag(p_key text) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: callers include roles that may not read feature_flags directly.
  select coalesce((select enabled from public.feature_flags where key = p_key), false);
$$;

-- The one place a percentage fee is worked out (R-FEE-1, R-MON-4). Rounds
-- half up. Integer maths: a fraction of a cent never reaches a float.
create function private.fee_minor(p_price bigint, p_currency text, p_applies_to text)
returns bigint
language plpgsql stable security definer set search_path = '' as $$
-- Definer: callers include roles that may not read fee_rules directly.
declare
  r public.fee_rules;
begin
  if p_price <= 0 then return 0; end if;
  select * into r from public.fee_rules
  where currency = p_currency and applies_to = p_applies_to and active;
  if r.id is null then
    raise exception 'No fee rule for % %', p_currency, p_applies_to;
  end if;
  return greatest(r.minimum_minor, (p_price * r.percent_bps + 5000) / 10000);
end;
$$;

-- Was immutable with 10% and S$2 written in. Same signature, read from config.
create or replace function public.platform_fee_cents(amount int) returns int
language sql stable set search_path = '' as $$
  select private.fee_minor(amount, 'SGD', 'session')::int;
$$;

revoke execute on function private.setting_int(text) from public;
revoke execute on function private.flag(text) from public;
revoke execute on function private.fee_minor(bigint, text, text) from public;
grant execute on function private.setting_int(text) to anon, authenticated, service_role;
grant execute on function private.flag(text) to anon, authenticated, service_role;
grant execute on function private.fee_minor(bigint, text, text) to anon, authenticated, service_role;

-- Time zone of an activity, from its venue's country.
create function private.activity_tz(p_activity uuid) returns text
language sql stable security definer set search_path = '' as $$
  -- Definer: reads config on behalf of any caller.
  select coalesce(
    (select c.timezone from public.activities a
      join public.venues v on v.id = a.venue_id
      join public.country_config c on c.country_code = v.country_code
      where a.id = p_activity),
    'Asia/Singapore');
$$;
revoke execute on function private.activity_tz(uuid) from public;
grant execute on function private.activity_tz(uuid) to authenticated, service_role;

-- Helpers that had no reason to be callable before sign-in.
revoke execute on function public.is_blocked_between(uuid, uuid) from public, anon;
revoke execute on function public.is_conversation_member(uuid) from public, anon;
grant execute on function public.is_blocked_between(uuid, uuid) to authenticated;
grant execute on function public.is_conversation_member(uuid) to authenticated;
