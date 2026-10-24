-- Events: tickets for several people with a code for the door, scanning,
-- programme reminders and cheering on the live court. An event that shows a
-- tournament takes its programme and live court from that tournament's draw.

create table public.event_tickets (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  qty int not null check (qty between 1 and 10),
  -- The booking code in the QR: "OG-7K2P9X".
  code text not null unique,
  status text not null default 'active' check (status in ('active', 'released')),
  scanned_at timestamptz,
  created_at timestamptz not null default now(),
  unique (activity_id, user_id)
);

create table public.event_reminders (
  activity_id uuid not null references public.activities (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  item_id text not null check (char_length(item_id) <= 64),
  primary key (activity_id, user_id, item_id)
);

create table public.event_cheers (
  activity_id uuid not null references public.activities (id) on delete cascade,
  match_id uuid not null references public.tournament_matches (id) on delete cascade,
  side text not null check (side in ('a', 'b')),
  n int not null default 0,
  primary key (activity_id, match_id, side)
);

alter table public.event_tickets enable row level security;
alter table public.event_reminders enable row level security;
alter table public.event_cheers enable row level security;
-- Everything goes through the functions below.

create function public.event_ticket_json(t public.event_tickets) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('id', t.id, 'qty', t.qty, 'code', t.code,
    'scanned_at', t.scanned_at);
$$;
revoke execute on function public.event_ticket_json(public.event_tickets)
  from public, anon, authenticated;

-- The viewer's ticket, or null.
create function public.event_ticket_get(p_activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select public.event_ticket_json(t) from public.event_tickets t
  where t.activity_id = p_activity and t.user_id = (select auth.uid())
    and t.status = 'active';
$$;

-- Takes [p_qty] more tickets (free events; paid ones need card payments).
create function public.event_ticket_buy(p_activity uuid, p_qty int) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  a public.activities;
  v_me uuid := (select auth.uid());
  v_taken int;
  v_mine int;
  t public.event_tickets;
begin
  select * into a from public.activities
  where id = p_activity and kind = 'event' and status = 'published';
  if not found then raise exception 'This event is no longer available.'; end if;
  if a.ends_at < now() then raise exception 'This event has finished.'; end if;
  if a.fee_cents > 0 then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;
  if p_qty is null or p_qty < 1 then raise exception 'Choose how many tickets.'; end if;
  if public.is_blocked_between(v_me, a.host_id) then
    raise exception 'You can''t get tickets for this event.';
  end if;
  -- One booking at a time per event, so seats can't be oversold.
  perform 1 from public.activities where id = p_activity for update;
  select coalesce(sum(qty), 0) into v_taken from public.event_tickets
  where activity_id = p_activity and status = 'active';
  select coalesce(qty, 0) into v_mine from public.event_tickets
  where activity_id = p_activity and user_id = v_me and status = 'active';
  v_mine := coalesce(v_mine, 0);
  if v_mine + p_qty > 10 then raise exception 'You can hold up to 10 tickets.'; end if;
  if v_taken + p_qty > a.capacity then
    raise exception 'Only % left.', greatest(a.capacity - v_taken, 0);
  end if;
  insert into public.event_tickets (activity_id, user_id, qty, code)
  values (p_activity, v_me, p_qty,
          'OG-' || upper(substr(translate(encode(extensions.gen_random_bytes(8), 'base64'),
                                          '+/=0O1I', ''), 1, 6)))
  on conflict (activity_id, user_id) do update
    set qty = case when public.event_tickets.status = 'active'
                   then public.event_tickets.qty + excluded.qty else excluded.qty end,
        status = 'active', scanned_at = null
  returning * into t;
  insert into public.activity_participants (activity_id, user_id, status)
  values (p_activity, v_me, 'joined')
  on conflict (activity_id, user_id) do update set status = 'joined';
  return public.event_ticket_json(t);
end;
$$;

-- Gives [p_qty] tickets back. Free tickets have nothing to refund, so it
-- returns 0 cents.
create function public.event_ticket_release(p_activity uuid, p_qty int) returns int
language plpgsql security definer set search_path = '' as $$
declare
  v_me uuid := (select auth.uid());
  t public.event_tickets;
begin
  select * into t from public.event_tickets
  where activity_id = p_activity and user_id = v_me and status = 'active';
  if not found then raise exception 'You don''t have tickets for this event.'; end if;
  if t.scanned_at is not null then
    raise exception 'These tickets were used at the door.';
  end if;
  if p_qty >= t.qty then
    update public.event_tickets set status = 'released' where id = t.id;
    update public.activity_participants set status = 'cancelled'
    where activity_id = p_activity and user_id = v_me;
  else
    update public.event_tickets set qty = qty - greatest(p_qty, 1) where id = t.id;
  end if;
  return 0;
end;
$$;

-- The organizer scans a code at the door. The first scan lets everyone on
-- the booking in; a second scan shows when it was used.
create function public.event_scan(p_activity uuid, p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  a public.activities;
  t public.event_tickets;
  v_used timestamptz;
  v_code text := upper(trim(coalesce(p_code, '')));
begin
  select * into a from public.activities where id = p_activity and kind = 'event';
  if not found then raise exception 'This event is no longer available.'; end if;
  if a.host_id <> (select auth.uid()) then
    raise exception 'Only the organizer can check tickets.';
  end if;
  if v_code !~ '^OG-' then v_code := 'OG-' || v_code; end if;
  select * into t from public.event_tickets
  where activity_id = p_activity and code = v_code and status = 'active';
  if found then
    v_used := t.scanned_at;
    if v_used is null then
      update public.event_tickets set scanned_at = now() where id = t.id;
    end if;
  end if;
  return jsonb_build_object(
    'valid', t.id is not null,
    'qty', coalesce(t.qty, 0),
    'booked_by', (select coalesce(full_name, username::text, 'Guest')
                  from public.profiles where id = t.user_id),
    'title', a.title,
    'used_at', v_used,
    'scanned', (select coalesce(sum(qty), 0) from public.event_tickets
                where activity_id = p_activity and status = 'active'
                  and scanned_at is not null),
    'capacity', a.capacity);
end;
$$;

-- What the event page needs beyond the activity: the viewer's reminders,
-- cheers on the live court, and for the organizer the count at the door.
create function public.event_state(p_activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'reminders', (select coalesce(jsonb_agg(item_id), '[]') from public.event_reminders
                  where activity_id = p_activity and user_id = (select auth.uid())),
    'cheers', (select coalesce(jsonb_object_agg(match_id || ':' || side, n), '{}')
               from public.event_cheers where activity_id = p_activity),
    'taken', (select coalesce(sum(qty), 0) from public.event_tickets
              where activity_id = p_activity and status = 'active'),
    'scanned', case when a.host_id = (select auth.uid()) then
                 (select coalesce(sum(qty), 0) from public.event_tickets
                  where activity_id = p_activity and status = 'active'
                    and scanned_at is not null) else 0 end)
  from public.activities a where a.id = p_activity;
$$;

create function public.event_remind(p_activity uuid, p_item text, p_on boolean)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_on then
    insert into public.event_reminders (activity_id, user_id, item_id)
    values (p_activity, (select auth.uid()), p_item)
    on conflict do nothing;
  else
    delete from public.event_reminders
    where activity_id = p_activity and user_id = (select auth.uid()) and item_id = p_item;
  end if;
end;
$$;

-- One cheer for a side of the match on court.
create function public.event_cheer(p_activity uuid, p_match uuid, p_side text)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_side not in ('a', 'b') then raise exception 'Pick a side to cheer.'; end if;
  if not exists (
    select 1 from public.activities e
    join public.tournament_matches m on m.activity_id = e.linked_id
    where e.id = p_activity and m.id = p_match) then
    raise exception 'This match isn''t on at this event.';
  end if;
  insert into public.event_cheers (activity_id, match_id, side, n)
  values (p_activity, p_match, p_side, 1)
  on conflict (activity_id, match_id, side) do update set n = public.event_cheers.n + 1;
end;
$$;

revoke execute on function
  public.event_ticket_get(uuid),
  public.event_ticket_buy(uuid, int),
  public.event_ticket_release(uuid, int),
  public.event_scan(uuid, text),
  public.event_state(uuid),
  public.event_remind(uuid, text, boolean),
  public.event_cheer(uuid, uuid, text)
from public, anon;
grant execute on function
  public.event_ticket_get(uuid),
  public.event_ticket_buy(uuid, int),
  public.event_ticket_release(uuid, int),
  public.event_scan(uuid, text),
  public.event_state(uuid),
  public.event_remind(uuid, text, boolean),
  public.event_cheer(uuid, uuid, text)
to authenticated;
