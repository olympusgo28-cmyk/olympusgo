-- Venues: bookable courts, prices and court bookings.

alter table public.venues
  add column bookable boolean not null default false,
  add column opens_hour int not null default 7 check (opens_hour between 0 and 23),
  add column closes_hour int not null default 23 check (closes_hour between 1 and 24),
  add column amenities text[] not null default '{}',
  add column verified boolean not null default false,
  add column rating numeric(2, 1) check (rating between 1 and 5),
  add column rating_count int not null default 0,
  add column auto_check_in boolean not null default false,
  add column color text check (color ~ '^#[0-9A-Fa-f]{6}$'),
  add column ink text check (ink ~ '^#[0-9A-Fa-f]{6}$'),
  add check (opens_hour < closes_hour);

-- Courts of one sport at a venue. Peak is weekdays 6 to 10 PM and weekends.
create table public.venue_courts (
  venue_id uuid not null references public.venues (id) on delete cascade,
  sport text not null,
  count int not null check (count between 1 and 100),
  off_peak_cents int not null check (off_peak_cents >= 0),
  peak_cents int not null check (peak_cents >= 0),
  note text not null default '',
  primary key (venue_id, sport)
);

create table public.court_bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  venue_id uuid not null references public.venues (id),
  sport text not null,
  court text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  court_cents int not null check (court_cents >= 0),
  fee_cents int not null check (fee_cents >= 0),
  door_code text not null,
  code text not null unique,
  status text not null default 'confirmed' check (status in ('confirmed', 'cancelled')),
  refund_cents int not null default 0,
  refund_to text check (refund_to in ('wallet', 'card')),
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
create index court_bookings_slot_idx on public.court_bookings (venue_id, sport, starts_at)
  where status = 'confirmed';
create index court_bookings_user_idx on public.court_bookings (user_id, starts_at);

alter table public.venue_courts enable row level security;
alter table public.court_bookings enable row level security;

create policy "Courts are public" on public.venue_courts
  for select to authenticated using (true);
-- Bookings are written by the server once payment clears.
create policy "Own court bookings" on public.court_bookings
  for select to authenticated using ((select auth.uid()) = user_id);

-- Busy times for the booking grid, without who booked.
create function public.court_busy(venue uuid, sport text, from_at timestamptz, to_at timestamptz)
returns table (starts_at timestamptz, ends_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select b.starts_at, b.ends_at from public.court_bookings b
  where b.venue_id = venue and b.sport = court_busy.sport and b.status = 'confirmed'
    and b.starts_at < to_at and b.ends_at > from_at;
$$;
revoke execute on function public.court_busy(uuid, text, timestamptz, timestamptz) from public, anon;
grant execute on function public.court_busy(uuid, text, timestamptz, timestamptz) to authenticated;

-- Cancels my booking. More than 24 hours before: all of it to the Wallet, or
-- the court price to a card. Inside 24 hours: no refund. Returns the refund.
create function public.cancel_court_booking(booking uuid, to_wallet boolean)
returns int
language plpgsql security definer set search_path = '' as $$
declare
  b public.court_bookings;
  refund int;
begin
  select * into b from public.court_bookings
  where id = booking and user_id = auth.uid() for update;
  if b.id is null then raise exception 'This booking no longer exists.'; end if;
  if b.status = 'cancelled' then raise exception 'This booking is already cancelled.'; end if;
  if b.starts_at < now() then raise exception 'This booking has already started.'; end if;
  refund := case
    when b.starts_at - now() < interval '24 hours' then 0
    when to_wallet then b.court_cents + b.fee_cents
    else b.court_cents
  end;
  update public.court_bookings
  set status = 'cancelled', refund_cents = refund,
      refund_to = case when refund > 0 then (case when to_wallet then 'wallet' else 'card' end) end
  where id = booking;
  return refund;
end;
$$;
revoke execute on function public.cancel_court_booking(uuid, boolean) from public, anon;
grant execute on function public.cancel_court_booking(uuid, boolean) to authenticated;

-- The seeded venues take bookings.
update public.venues set bookable = true, verified = true, amenities = '{Showers,Lockers,Water point}';
insert into public.venue_courts (venue_id, sport, count, off_peak_cents, peak_cents)
select id, 'badminton', 8, 1200, 1800 from public.venues;
