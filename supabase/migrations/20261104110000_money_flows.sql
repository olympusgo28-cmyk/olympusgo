-- P4a-04 to P4a-06: paid joins, capture, hold and release, refunds, and the
-- organizer's fee on free Meets.
--
-- Lock order everywhere: activity, then payment, then ledger. The Edge
-- Functions call Stripe; nothing here does. Client functions write intent, and
-- money_svc_* functions, closed to every client role, carry out the rest.

alter table public.activity_participants
  drop constraint activity_participants_status_check,
  drop constraint activity_participants_refund_to_check,
  add constraint activity_participants_status_check
    check (status in ('joined', 'waitlist', 'requested', 'cancelled', 'reserved', 'offered')),
  add constraint activity_participants_refund_to_check check (refund_to in ('original')),
  add column hold_until timestamptz;

create index activity_participants_hold_idx on public.activity_participants (hold_until)
  where status in ('reserved', 'offered');

-- When an organizer last moved a Meet people have paid for (R-REF-17).
alter table public.activities add column money_changed_at timestamptz;

drop function public.card_fee_cents(integer);

-- Spots held for someone paying count as taken, until their hold runs out.
create or replace function public.activity_spots_taken(a uuid) returns integer
language sql stable security definer set search_path = '' as $$
  select coalesce(sum(1 + (guest_name is not null)::int), 0)::int
  from public.activity_participants
  where activity_id = a
    and (status = 'joined' or (status in ('reserved', 'offered') and hold_until > now()));
$$;

create function private.spots_joined(p_activity uuid) returns integer
language sql stable security definer set search_path = '' as $$
  select coalesce(sum(1 + (guest_name is not null)::int), 0)::int
  from public.activity_participants where activity_id = p_activity and status = 'joined';
$$;

-- Game on counts people who have actually paid, so an abandoned hold can't flap it.
do $$
declare
  d text := pg_get_functiondef('private.refresh_game_on(uuid)'::regprocedure);
  fixed text := replace(d, 'public.activity_spots_taken(p_activity) >= a.min_players',
    'private.spots_joined(p_activity) >= a.min_players');
begin
  if fixed = d then raise exception 'refresh_game_on did not change'; end if;
  execute fixed;
end;
$$;

-- A player must pay to take a spot.
create function private.activity_charges(a public.activities) returns boolean
language sql stable set search_path = '' as $$
  select private.flag('payments.enabled') and a.kind in ('meet', 'event')
    and (a.fee_cents > 0 or a.players_pay_fee);
$$;

-- The organizer covers the fee on a free Meet or ticket (R-FEE-3, R-FEE-4).
create function private.organizer_pays(a public.activities) returns boolean
language sql stable set search_path = '' as $$
  select private.flag('payments.enabled') and a.kind in ('meet', 'event')
    and a.fee_cents = 0 and not a.players_pay_fee;
$$;

create function private.activity_has_money(p_activity uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: a host can't read other players' payments.
  select exists (select 1 from public.payments
    where activity_id = p_activity and status in ('pending', 'succeeded', 'cancel_requested'));
$$;

-- Once money exists the deal is fixed. Dates can only move later, and that
-- opens the refund window.
do $$
declare
  d text := pg_get_functiondef('private.activity_lock_columns()'::regprocedure);
  fixed text := replace(d, 'if private.activity_has_scores(old.id) then',
$new$if private.activity_has_money(old.id) then
      if (new.fee_cents, new.currency, new.players_pay_fee, new.allow_refunds)
          is distinct from (old.fee_cents, old.currency, old.players_pay_fee, old.allow_refunds) then
        raise exception 'People have already paid, so the price can''t change.' using errcode = 'P0001';
      end if;
      if new.starts_at < old.starts_at then
        raise exception 'People have already paid, so this can only move later.' using errcode = 'P0001';
      end if;
      if new.starts_at <> old.starts_at or new.venue_id <> old.venue_id then
        new.money_changed_at := now();
      end if;
    end if;
    if private.activity_has_scores(old.id) then$new$);
begin
  if fixed = d then raise exception 'activity_lock_columns did not change'; end if;
  execute fixed;
end;
$$;

create function private.has_saved_card(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: payment_customers has no client access.
  select exists (select 1 from public.payment_customers c
    where c.user_id = p_user and c.payment_method_id is not null);
$$;

-- A free Meet the organizer pays for needs a saved card and no unpaid fees.
-- Not a definer, so it can see who is really publishing.
create function private.activity_publish_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user = 'authenticated' and new.status = 'published' and private.organizer_pays(new)
     and (tg_op = 'INSERT' or not private.organizer_pays(old)) then
    if private.is_minor(new.host_id) then
      raise exception 'Organizers under 18 can''t cover the fee. Ask players to pay it instead.'
        using errcode = 'P0001';
    end if;
    if not private.has_saved_card(new.host_id) then
      raise exception 'card_required' using errcode = 'P0001';
    end if;
    if private.ledger_balance('organizer_fee_debt', new.host_id, new.currency) > 0 then
      raise exception 'fee_debt' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;
create trigger activities_publish_guard before insert or update of fee_cents, players_pay_fee, status
  on public.activities for each row execute function private.activity_publish_guard();

-- Money survives everything, so an activity holding money can't go.
create function private.activity_delete_guard() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: a host can't read other players' payments.
begin
  if private.ledger_balance('held', old.id, old.currency) <> 0
     or exists (select 1 from public.payments
       where activity_id = old.id and status in ('pending', 'cancel_requested')) then
    raise exception 'This activity holds money, so it can''t be deleted.';
  end if;
  return old;
end;
$$;
create trigger activities_delete_guard before delete on public.activities
  for each row execute function private.activity_delete_guard();

-- Reservations ------------------------------------------------------------

create function private.payment_json(p public.payments) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object('payment_id', p.id, 'status', p.status, 'purpose', p.purpose,
    'qty', p.qty, 'price_minor', p.price_minor, 'fee_minor', p.fee_minor,
    'amount_minor', p.amount_minor, 'currency', p.currency, 'method', p.method,
    'hold_until', p.hold_until, 'server_now', now(), 'failure_code', p.failure_code,
    'receipt_no', p.receipt_no, 'refund_rule', p.rule_snapshot ->> 'refund_rule');
$$;

-- Frees spots whose time ran out. The caller holds the activity lock.
create function private.expire_holds(p_activity uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: changes other players' rows.
declare
  v_seats int;
begin
  update public.activity_participants
  set status = 'cancelled', hold_until = null, queue_seq = null
  where activity_id = p_activity and status in ('reserved', 'offered') and hold_until <= now();
  get diagnostics v_seats = row_count;

  update public.payments
  set status = case when method is null then 'cancelled' else 'cancel_requested' end
  where activity_id = p_activity and status = 'pending' and hold_until <= now();

  if v_seats > 0 then
    perform private.promote_waitlist(p_activity);
  end if;
end;
$$;

-- Takes a spot and starts a payment. The webhook, not this, confirms it.
create function public.activity_reserve(p_activity uuid, p_key text, p_qty integer default 1,
  p_guest text default null, p_guest_level numeric default null)
returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: joins go only through a lock, so capacity can't be sidestepped.
declare
  me uuid := auth.uid();
  a public.activities;
  pay public.payments;
  ap public.activity_participants;
  v_purpose text;
  v_party int;
  v_taken int;
  v_mine int;
  v_hold timestamptz;
  v_status text;
  q jsonb;
begin
  if me is null then raise exception 'Sign in first.'; end if;
  if p_key is null or length(p_key) < 8 then raise exception 'Try that again.'; end if;
  select * into a from public.activities where id = p_activity and status = 'published' for update;
  if a.id is null then raise exception 'This activity is no longer available.'; end if;
  if private.is_restricted(me) then raise exception 'Ask a parent to link your account first.'; end if;

  select * into pay from public.payments where user_id = me and idempotency_key = p_key;
  if pay.id is not null then
    return private.payment_json(pay) || jsonb_build_object('result', 'reserved');
  end if;

  if not private.flag('payments.enabled') then
    raise exception 'Payments aren''t switched on yet.';
  end if;
  if a.kind = 'tournament' then raise exception 'Paid tournament entries aren''t open yet.'; end if;
  if a.starts_at < now() then raise exception 'This has already started.'; end if;
  if a.registration_closes_at is not null and a.registration_closes_at < now() then
    raise exception 'Registration has closed.';
  end if;
  if public.is_blocked_between(me, a.host_id) then
    raise exception 'You can''t join this activity.';
  end if;
  if a.ends_at > now() + make_interval(days => private.setting_int('money.max_advance_days')) then
    raise exception 'Paid booking opens closer to the date.';
  end if;

  perform private.expire_holds(p_activity);
  v_hold := least(now() + make_interval(mins => private.setting_int('meet.reservation_minutes')),
    a.starts_at);

  if a.kind = 'event' then
    v_purpose := 'ticket';
  elsif me = a.host_id then
    v_purpose := 'host_spot';
  else
    v_purpose := 'meet';
  end if;

  if v_purpose <> 'host_spot' and not private.activity_charges(a) then
    raise exception 'This one is free, so there''s nothing to pay.';
  end if;
  if a.approval_required and v_purpose = 'meet' then
    raise exception 'Paid Meets that need approval aren''t open yet.';
  end if;

  select * into pay from public.payments
  where activity_id = p_activity and user_id = me and status = 'pending'
    and purpose in ('meet', 'ticket', 'host_spot');
  if pay.id is not null then
    return private.payment_json(pay) || jsonb_build_object('result', 'reserved');
  end if;

  if v_purpose = 'ticket' then
    v_party := coalesce(p_qty, 1);
    select coalesce(sum(qty), 0) into v_taken from public.event_tickets
    where activity_id = p_activity and status = 'active';
    v_taken := v_taken + coalesce((select sum(qty) from public.payments
      where activity_id = p_activity and purpose = 'ticket' and status = 'pending'), 0);
    select coalesce(sum(qty), 0) into v_mine from public.event_tickets
    where activity_id = p_activity and user_id = me and status = 'active';
    if v_mine + v_party > 10 then raise exception 'You can hold up to 10 tickets.'; end if;
    if v_taken + v_party > a.capacity then
      raise exception 'Only % left.', greatest(a.capacity - v_taken, 0);
    end if;
  else
    if p_guest is not null and not a.allow_guests then
      raise exception 'The host has turned off guests.';
    end if;
    v_party := case when p_guest is null then 1 else 2 end;
    select * into ap from public.activity_participants
    where activity_id = p_activity and user_id = me;
    if ap.status in ('joined', 'waitlist', 'requested') then
      return jsonb_build_object('result', ap.status);
    end if;
    if ap.status = 'offered' and ap.hold_until > now() then
      -- The offer's seat is already counted. Keep it for the time paying takes.
      v_hold := least(greatest(ap.hold_until, v_hold), a.starts_at);
      v_party := 1 + (ap.guest_name is not null)::int;
    elsif public.activity_spots_taken(p_activity) + v_party > private.open_capacity(a) then
      if not a.waitlist_when_full then raise exception 'This one is full.'; end if;
      v_status := public.join_activity(p_activity, p_guest, p_guest_level);
      return jsonb_build_object('result', v_status);
    end if;
    insert into public.activity_participants
      (activity_id, user_id, status, guest_name, guest_level, hold_until)
    values (p_activity, me, 'reserved', p_guest, p_guest_level, v_hold)
    on conflict (activity_id, user_id) do update
      set status = 'reserved', hold_until = excluded.hold_until, queue_seq = null,
          guest_name = case when public.activity_participants.status = 'offered'
            then public.activity_participants.guest_name else excluded.guest_name end,
          guest_level = case when public.activity_participants.status = 'offered'
            then public.activity_participants.guest_level else excluded.guest_level end,
          attendance = null, checked_in_at = null, checked_in_by = null, check_in_method = null,
          refund_to = null, refund_cents = null, created_at = now();
  end if;

  q := public.money_quote(v_purpose, a.fee_cents::bigint, v_party, a.currency);
  insert into public.payments (user_id, activity_id, purpose, qty, price_minor, fee_minor,
    amount_minor, currency, organizer_id, rule_snapshot, idempotency_key, hold_until)
  values (me, p_activity, v_purpose, v_party, (q ->> 'price_minor')::bigint,
    (q ->> 'fee_minor')::bigint, (q ->> 'total_minor')::bigint, a.currency, a.host_id,
    q || jsonb_build_object('refund_rule', private.refund_rule_text(v_purpose)), p_key, v_hold)
  returning * into pay;
  return private.payment_json(pay) || jsonb_build_object('result', 'reserved');
end;
$$;

-- What the payment sheet shows before anything is reserved (R-REF-20).
create function public.activity_quote(p_activity uuid, p_qty integer default 1)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: the quote reads one activity the caller may not otherwise see in full.
declare
  a public.activities;
  v_purpose text;
begin
  select * into a from public.activities where id = p_activity;
  if a.id is null then raise exception 'This activity is no longer available.'; end if;
  v_purpose := case when a.kind = 'event' then 'ticket'
    when a.kind = 'tournament' then 'tournament'
    when a.host_id = auth.uid() then 'host_spot' else 'meet' end;
  return public.money_quote(v_purpose, a.fee_cents::bigint, p_qty, a.currency)
    || jsonb_build_object('refund_rule', private.refund_rule_text(v_purpose),
         'payments_enabled', private.flag('payments.enabled'),
         'must_pay', private.activity_charges(a) or v_purpose = 'host_spot' and private.flag('payments.enabled'));
end;
$$;

-- Called by create-payment-intent as the player, so the gate applies.
create function public.payment_begin(p_payment uuid, p_method text) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: payments can't be written by clients.
declare
  pay public.payments;
begin
  if p_method not in ('card', 'paynow') then raise exception 'Choose how to pay.'; end if;
  select * into pay from public.payments where id = p_payment and user_id = auth.uid() for update;
  if pay.id is null then raise exception 'That payment isn''t yours.'; end if;
  if pay.status <> 'pending' or pay.purpose = 'organizer_fee' then
    raise exception 'This payment has ended. Try again.';
  end if;
  if pay.hold_until <= now() then raise exception 'Your time ran out. Try again.'; end if;
  if pay.method is not null and pay.method <> p_method then
    raise exception 'This payment has started. Cancel it to pay another way.';
  end if;
  if p_method = 'paynow' and pay.currency <> 'SGD' then
    raise exception 'PayNow is for Singapore dollars.';
  end if;
  update public.payments set method = p_method where id = pay.id returning * into pay;
  return private.payment_json(pay);
end;
$$;

-- The player gives up a pending payment. A late success still refunds in full.
create function public.payment_abandon(p_payment uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: changes the spot under the same lock as joining.
declare
  pay public.payments;
begin
  select * into pay from public.payments where id = p_payment and user_id = auth.uid();
  if pay.id is null then raise exception 'That payment isn''t yours.'; end if;
  perform 1 from public.activities where id = pay.activity_id for update;
  select * into pay from public.payments where id = p_payment for update;
  if pay.status <> 'pending' then return; end if;
  update public.payments
  set status = case when method is null then 'cancelled' else 'cancel_requested' end
  where id = pay.id;
  if pay.activity_id is not null then
    update public.activity_participants set status = 'cancelled', hold_until = null
    where activity_id = pay.activity_id and user_id = pay.user_id and status = 'reserved';
    perform private.promote_waitlist(pay.activity_id);
  end if;
end;
$$;

create function public.payment_status(p_payment uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: returns only the caller's own payment, with its spot.
declare
  pay public.payments;
begin
  select * into pay from public.payments where id = p_payment and user_id = auth.uid();
  if pay.id is null then raise exception 'That payment isn''t yours.'; end if;
  return private.payment_json(pay) || jsonb_build_object('spot',
    (select status from public.activity_participants ap
     where ap.activity_id = pay.activity_id and ap.user_id = pay.user_id),
    'refunded_minor', coalesce((select sum(r.amount_minor) from public.refunds r
      where r.payment_id = pay.id and r.status <> 'voided'), 0));
end;
$$;

-- Joining ---------------------------------------------------------------

create or replace function public.join_activity(activity uuid, guest text default null,
  guest_lvl numeric default null)
returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: joins go only through here, so capacity cannot be sidestepped.
declare
  me uuid := auth.uid();
  a public.activities;
  v_party int := case when guest is null then 1 else 2 end;
  v_existing text;
  v_result text;
begin
  -- The lock is what makes the count below safe. Every path that changes who
  -- holds a spot takes the same lock.
  select * into a from public.activities
  where id = activity and status = 'published' for update;
  if a.id is null then raise exception 'This activity is no longer available.'; end if;
  if a.starts_at < now() then raise exception 'This has already started.'; end if;
  if a.registration_closes_at is not null and a.registration_closes_at < now() then
    raise exception 'Registration has closed.';
  end if;
  if private.is_restricted(me) then
    raise exception 'Ask a parent to link your account first.';
  end if;
  if public.is_blocked_between(me, a.host_id) then
    raise exception 'You can''t join this activity.';
  end if;
  -- With payments off a paid Meet shows its price and players settle with the
  -- host; other kinds stay closed.
  if a.fee_cents > 0 and a.kind <> 'meet' then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;
  if guest is not null and not a.allow_guests then
    raise exception 'The host has turned off guests.';
  end if;

  select ap.status into v_existing from public.activity_participants ap
  where ap.activity_id = activity and ap.user_id = me;
  if v_existing in ('joined', 'waitlist', 'requested') then
    return v_existing;
  end if;

  perform private.expire_holds(activity);
  if (select ap.status from public.activity_participants ap
      where ap.activity_id = activity and ap.user_id = me) in ('reserved', 'offered') then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;

  if public.activity_spots_taken(activity) + v_party > private.open_capacity(a) then
    if not a.waitlist_when_full then
      raise exception 'This one is full.';
    end if;
    v_result := 'waitlist';
  elsif private.activity_charges(a) then
    -- activity_reserve takes the spot once there's a payment behind it.
    raise exception 'payment_required' using errcode = 'P0001';
  elsif a.approval_required then
    v_result := 'requested';
  else
    v_result := 'joined';
  end if;

  insert into public.activity_participants
    (activity_id, user_id, status, guest_name, guest_level, queue_seq)
  values (activity, me, v_result, guest, guest_lvl,
    case when v_result = 'waitlist' then nextval('public.activity_queue_seq') end)
  on conflict (activity_id, user_id) do update
    set status = excluded.status, guest_name = excluded.guest_name,
        guest_level = excluded.guest_level, queue_seq = excluded.queue_seq,
        hold_until = null, created_at = now();

  if v_result = 'joined' then
    perform private.organizer_fee_queue(a, me, v_party);
  end if;
  perform private.refresh_game_on(activity);
  return v_result;
end;
$$;

-- With payments on, a spot opening on a paid Meet is an offer with an expiry.
-- Nobody is charged without acting (Q5).
create or replace function private.promote_waitlist(p_activity uuid) returns integer
language plpgsql security definer set search_path = '' as $$
-- Definer: changes other players' rows and writes their notifications.
declare
  a public.activities;
  r record;
  v_left int;
  v_party int;
  v_moved int := 0;
  v_paid boolean;
  v_until timestamptz;
begin
  select * into a from public.activities where id = p_activity;
  if a.id is null or a.status <> 'published' or a.starts_at < now() then
    return 0;
  end if;
  v_paid := private.activity_charges(a);
  v_until := least(now() + make_interval(mins => private.setting_int('waitlist.offer_minutes')), a.starts_at);
  v_left := private.open_capacity(a) - public.activity_spots_taken(p_activity);
  for r in
    select * from public.activity_participants ap
    where ap.activity_id = p_activity and ap.status = 'waitlist'
    order by ap.queue_seq
  loop
    exit when v_left <= 0;
    v_party := case when r.guest_name is null then 1 else 2 end;
    continue when v_party > v_left;
    continue when public.is_blocked_between(r.user_id, a.host_id);
    continue when private.is_restricted(r.user_id);
    if v_paid then
      update public.activity_participants
      set status = 'offered', hold_until = v_until, queue_seq = null where id = r.id;
      perform public.notify(r.user_id, 'A spot opened',
        'Pay within ' || private.setting_int('waitlist.offer_minutes') || ' minutes to take your spot at '
          || a.title || '.', '!', '/activities/' || a.id);
    else
      update public.activity_participants
      set status = case when a.approval_required then 'requested' else 'joined' end,
          queue_seq = null
      where id = r.id;
      if not a.approval_required then
        perform private.organizer_fee_queue(a, r.user_id, v_party);
      end if;
      perform public.notify(r.user_id,
        case when a.approval_required then 'Your request is with the host' else 'You''re in' end,
        'A spot opened at ' || a.title || '.', '!', '/activities/' || a.id);
    end if;
    v_left := v_left - v_party;
    v_moved := v_moved + 1;
  end loop;
  perform private.refresh_game_on(p_activity);
  return v_moved;
end;
$$;

create or replace function public.host_plays(activity uuid, playing boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: takes or frees a spot under the same lock as joining.
declare
  a public.activities;
begin
  select * into a from public.activities where id = activity and host_id = auth.uid() for update;
  if a.id is null then raise exception 'Only the organizer can do this.'; end if;
  if not playing then
    perform private.leave_money(a, a.host_id);
    update public.activity_participants set status = 'cancelled', queue_seq = null, hold_until = null
    where activity_id = activity and user_id = a.host_id;
    perform private.promote_waitlist(activity);
    return;
  end if;
  -- R-FEE-5: the organizer pays only the S$2.00 fee, through activity_reserve.
  if private.flag('payments.enabled') then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;
  if public.activity_spots_taken(activity) >= a.capacity then
    raise exception 'The Meet is full.';
  end if;
  insert into public.activity_participants (activity_id, user_id, status)
  values (activity, a.host_id, 'joined')
  on conflict (activity_id, user_id) do update set status = 'joined', queue_seq = null;
  perform private.refresh_game_on(activity);
end;
$$;

-- Tickets ----------------------------------------------------------------

create function private.ticket_issue(a public.activities, p_user uuid, p_qty integer)
returns public.event_tickets
language plpgsql security definer set search_path = '' as $$
-- Definer: tickets have no client write path.
declare
  t public.event_tickets;
begin
  insert into public.event_tickets (activity_id, user_id, qty, code)
  values (a.id, p_user, p_qty,
          'OG-' || upper(substr(translate(encode(extensions.gen_random_bytes(8), 'base64'),
                                          '+/=0O1I', ''), 1, 6)))
  on conflict (activity_id, user_id) do update
    set qty = case when public.event_tickets.status = 'active'
                   then public.event_tickets.qty + excluded.qty else excluded.qty end,
        status = 'active', scanned_at = null
  returning * into t;
  insert into public.activity_participants (activity_id, user_id, status)
  values (a.id, p_user, 'joined')
  on conflict (activity_id, user_id) do update set status = 'joined';
  return t;
end;
$$;

create or replace function public.event_ticket_buy(p_activity uuid, p_qty integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  a public.activities;
  v_me uuid := (select auth.uid());
  v_taken int;
  v_mine int;
  t public.event_tickets;
begin
  -- One booking at a time per event, so seats can't be oversold.
  select * into a from public.activities
  where id = p_activity and kind = 'event' and status = 'published' for update;
  if not found then raise exception 'This event is no longer available.'; end if;
  if a.ends_at < now() then raise exception 'This event has finished.'; end if;
  if a.fee_cents > 0 or private.activity_charges(a) then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;
  if p_qty is null or p_qty < 1 then raise exception 'Choose how many tickets.'; end if;
  if public.is_blocked_between(v_me, a.host_id) then
    raise exception 'You can''t get tickets for this event.';
  end if;
  select coalesce(sum(qty), 0) into v_taken from public.event_tickets
  where activity_id = p_activity and status = 'active';
  select coalesce(qty, 0) into v_mine from public.event_tickets
  where activity_id = p_activity and user_id = v_me and status = 'active';
  v_mine := coalesce(v_mine, 0);
  if v_mine + p_qty > 10 then raise exception 'You can hold up to 10 tickets.'; end if;
  if v_taken + p_qty > a.capacity then
    raise exception 'Only % left.', greatest(a.capacity - v_taken, 0);
  end if;
  t := private.ticket_issue(a, v_me, p_qty);
  perform private.organizer_fee_queue(a, v_me, p_qty);
  return public.event_ticket_json(t);
end;
$$;

-- Refunds ----------------------------------------------------------------

-- Writes the refund and its ledger entries. The worker sends it to Stripe.
-- The price comes back out of held money, or out of earnings once released.
create function private.refund_issue(p_payment uuid, p_reason text, p_key text default null,
  p_price_limit bigint default null, p_actor uuid default null)
returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: refunds and the ledger have no client write path.
declare
  pay public.payments;
  v_price bigint;
  v_fee bigint;
  q jsonb;
  v_id uuid;
begin
  select * into pay from public.payments where id = p_payment for update;
  if pay.status <> 'succeeded' then return 0; end if;
  if exists (select 1 from public.payment_disputes d
      where d.payment_id = pay.id and d.status = 'open') then
    perform private.money_alert('refund_blocked_by_dispute', 'dispute-refund:' || pay.id,
      jsonb_build_object('payment', pay.id));
    return 0;
  end if;
  select pay.price_minor - coalesce(sum(price_minor), 0), pay.fee_minor - coalesce(sum(fee_minor), 0)
  into v_price, v_fee
  from public.refunds where payment_id = pay.id and status <> 'voided';

  q := public.money_refund_quote(p_reason, v_price, v_fee, pay.method);
  v_price := (q ->> 'price_minor')::bigint;
  v_fee := (q ->> 'fee_minor')::bigint;
  if p_price_limit is not null then
    v_price := least(v_price, p_price_limit);
  end if;
  if v_price + v_fee = 0 then return 0; end if;

  insert into public.refunds (payment_id, reason, price_minor, fee_minor, organizer_pays_fee,
    idempotency_key, actor)
  values (pay.id, p_reason, v_price, v_fee, (q ->> 'organizer_pays_card_fee')::boolean,
    coalesce(p_key, p_reason || ':' || pay.id), p_actor)
  on conflict (idempotency_key) do nothing
  returning id into v_id;
  if v_id is null then return 0; end if;

  perform private.ledger_post('refund', 'refund:' || v_id, pay.currency,
    jsonb_build_object('refund', v_id, 'payment', pay.id),
    jsonb_build_array(
      case when pay.released_at is null
        then private.ledger_line('held', pay.activity_id, v_price)
        else private.ledger_line('organizer', pay.organizer_id, v_price) end,
      private.ledger_line(case when pay.purpose = 'debt' then 'organizer_fee_debt' else 'platform_fees' end,
        case when pay.purpose = 'debt' then pay.user_id end, v_fee),
      private.ledger_line('refunds_pending', null, -(v_price + v_fee))));
  return v_price + v_fee;
end;
$$;

-- The organizer's S$2.00 for a player: charged by the worker, off-session,
-- because join_activity can't call Stripe.
create function private.organizer_fee_queue(a public.activities, p_player uuid, p_qty integer)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: payments can't be written by clients.
declare
  q jsonb;
begin
  if not private.organizer_pays(a) or p_player = a.host_id then return; end if;
  q := public.money_quote('organizer_fee', 0, p_qty, a.currency);
  insert into public.payments (user_id, activity_id, purpose, qty, price_minor, fee_minor, amount_minor,
    currency, method, organizer_id, beneficiary_id, rule_snapshot, idempotency_key)
  values (a.host_id, a.id, 'organizer_fee', p_qty, 0, (q ->> 'fee_minor')::bigint,
    (q ->> 'total_minor')::bigint, a.currency, 'card', a.host_id, p_player,
    q || jsonb_build_object('refund_rule', private.refund_rule_text('organizer_fee')),
    'orgfee:' || gen_random_uuid());
end;
$$;

-- The fee comes back to the organizer when a player leaves in time (R-FEE-3).
create function private.organizer_fee_reverse(a public.activities, p_player uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: changes the organizer's payments.
declare
  pay public.payments;
begin
  for pay in
    select * from public.payments
    where activity_id = a.id and beneficiary_id = p_player and purpose = 'organizer_fee'
      and status in ('pending', 'debt', 'succeeded')
    for update
  loop
    if pay.status = 'pending' then
      update public.payments
      set status = case when stripe_intent_id is null then 'cancelled' else 'cancel_requested' end
      where id = pay.id;
    elsif pay.status = 'debt' then
      perform private.ledger_post('debt_reverse', 'debt_reverse:' || pay.id, pay.currency,
        jsonb_build_object('payment', pay.id),
        jsonb_build_array(private.ledger_line('platform_fees', null, pay.fee_minor),
          private.ledger_line('organizer_fee_debt', pay.user_id, -pay.fee_minor)));
      update public.payments set status = 'cancelled' where id = pay.id;
    else
      perform private.refund_issue(pay.id, 'player_left');
    end if;
  end loop;
end;
$$;

-- Everything money owes a player who gives up a spot. Returns the refund.
-- The caller holds the activity lock.
create function private.leave_money(a public.activities, p_user uuid) returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and the ledger.
declare
  pay public.payments;
  v_refund bigint := 0;
  v_changed boolean := a.money_changed_at is not null and now() < a.money_changed_at
    + make_interval(hours => private.setting_int('money.change_refund_hours'));
begin
  for pay in
    select * from public.payments
    where activity_id = a.id and user_id = p_user and purpose in ('meet', 'host_spot', 'ticket')
      and status in ('pending', 'succeeded')
    order by created_at
  loop
    if pay.status = 'pending' then
      update public.payments
      set status = case when method is null then 'cancelled' else 'cancel_requested' end
      where id = pay.id;
    elsif pay.purpose = 'host_spot' then
      if private.refund_in_time('meet', a) then
        v_refund := v_refund + private.refund_issue(pay.id, 'host_spot');
      end if;
    elsif v_changed then
      v_refund := v_refund + private.refund_issue(pay.id, 'change_by_organizer');
    elsif private.refund_in_time(pay.purpose, a) then
      v_refund := v_refund + private.refund_issue(pay.id, 'player_in_time');
    end if;
  end loop;
  if now() < a.starts_at then
    perform private.organizer_fee_reverse(a, p_user);
  end if;
  return v_refund;
end;
$$;

drop function public.leave_activity(uuid, boolean);
create function public.leave_activity(activity uuid) returns integer
language plpgsql security definer set search_path = '' as $$
-- Definer: leaving promotes other players, which the caller may not do.
declare
  me uuid := auth.uid();
  a public.activities;
  v_refund bigint;
begin
  select * into a from public.activities where id = activity for update;
  if a.id is null then raise exception 'This activity is no longer available.'; end if;
  v_refund := private.leave_money(a, me);
  update public.activity_participants
  set status = 'cancelled', queue_seq = null, hold_until = null,
      refund_to = case when v_refund > 0 then 'original' end,
      refund_cents = v_refund
  where activity_id = activity and user_id = me;
  perform private.promote_waitlist(activity);
  return v_refund;
end;
$$;

create or replace function public.event_ticket_release(p_activity uuid, p_qty integer) returns integer
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and tickets.
declare
  v_me uuid := (select auth.uid());
  a public.activities;
  t public.event_tickets;
  pay public.payments;
  v_left int;
  v_units int;
  v_unit bigint;
  v_remaining bigint;
  v_refund bigint := 0;
  v_in_time boolean;
begin
  select * into a from public.activities where id = p_activity for update;
  select * into t from public.event_tickets
  where activity_id = p_activity and user_id = v_me and status = 'active';
  if not found then raise exception 'You don''t have tickets for this event.'; end if;
  if t.scanned_at is not null then
    raise exception 'These tickets were used at the door.';
  end if;
  v_left := least(greatest(coalesce(p_qty, 1), 1), t.qty);
  if v_left >= t.qty then
    update public.event_tickets set status = 'released' where id = t.id;
    update public.activity_participants set status = 'cancelled'
    where activity_id = p_activity and user_id = v_me;
  else
    update public.event_tickets set qty = qty - v_left where id = t.id;
  end if;

  v_in_time := private.refund_in_time('ticket', a);
  if v_in_time then
    -- Newest tickets first, one unit's price at a time.
    for pay in
      select * from public.payments
      where activity_id = p_activity and user_id = v_me and purpose = 'ticket'
        and status = 'succeeded' and price_minor > 0
      order by captured_at desc
    loop
      exit when v_left = 0;
      v_unit := pay.price_minor / pay.qty;
      select pay.price_minor - coalesce(sum(r.price_minor), 0) into v_remaining
      from public.refunds r where r.payment_id = pay.id and r.status <> 'voided';
      v_units := least(v_left, (v_remaining / v_unit)::int);
      continue when v_units = 0;
      v_refund := v_refund + private.refund_issue(pay.id, 'player_in_time',
        'ticket:' || pay.id || ':' || (v_remaining / v_unit), v_units * v_unit);
      v_left := v_left - v_units;
    end loop;
  end if;
  if now() < a.starts_at and not exists (select 1 from public.event_tickets
      where id = t.id and status = 'active') then
    perform private.organizer_fee_reverse(a, v_me);
  end if;
  return v_refund;
end;
$$;

-- Release -----------------------------------------------------------------

-- Pays the organizer what's left of each payment, once. The price of absent
-- players goes too (R-HOLD-3). Attendance corrected later never moves money.
create function private.release_activity(p_activity uuid) returns integer
language plpgsql security definer set search_path = '' as $$
-- Definer: runs from a host's call and from cron.
declare
  pay public.payments;
  v_net bigint;
  v_done int := 0;
begin
  perform 1 from public.activities where id = p_activity for update;
  if exists (select 1 from public.activity_money_holds h
      where h.activity_id = p_activity and h.closed_at is null) then
    return 0;
  end if;
  for pay in
    select * from public.payments
    where activity_id = p_activity and status = 'succeeded' and released_at is null
      and purpose in ('meet', 'ticket', 'tournament', 'host_spot')
    for update
  loop
    continue when exists (select 1 from public.payment_disputes d
      where d.payment_id = pay.id and d.status = 'open');
    select pay.price_minor - coalesce(sum(r.price_minor), 0) into v_net
    from public.refunds r where r.payment_id = pay.id and r.status <> 'voided';
    perform private.ledger_post('release', 'release:' || pay.id, pay.currency,
      jsonb_build_object('payment', pay.id, 'activity', p_activity),
      jsonb_build_array(private.ledger_line('held', p_activity, v_net),
        private.ledger_line('organizer', pay.organizer_id, -v_net)));
    update public.payments set released_at = now() where id = pay.id;
    v_done := v_done + 1;
  end loop;
  return v_done;
end;
$$;

-- R-HOLD-2, and never before the start, or a host could save attendance
-- early, release, then cancel.
do $$
declare
  d text := pg_get_functiondef('public.save_attendance(uuid, jsonb)'::regprocedure);
  fixed text := replace(d, 'return v_present;',
$new$if now() >= a.starts_at then
    perform private.release_activity(activity);
  end if;
  return v_present;$new$);
begin
  if fixed = d then raise exception 'save_attendance did not change'; end if;
  execute fixed;
end;
$$;

-- Cancelling --------------------------------------------------------------

create or replace function public.cancel_activity(activity uuid, series boolean, message text)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  first public.activities;
  a public.activities;
  pay public.payments;
  ap public.activity_participants;
  v_paid boolean;
begin
  select * into first from public.activities where id = activity and host_id = auth.uid();
  if first.id is null then raise exception 'Only the organizer can cancel.'; end if;
  for a in
    select * from public.activities s
    where s.id = activity
       or (series and first.series_id is not null and s.series_id = first.series_id
           and s.host_id = first.host_id and s.starts_at >= first.starts_at and s.status = 'published')
    order by s.id
    for update
  loop
    if a.starts_at <= now() and private.activity_has_scores(a.id) then
      raise exception 'This has scores, so it can''t be cancelled. Ask the OlympusGO team.';
    end if;
    if exists (select 1 from public.payments p
        where p.activity_id = a.id and p.released_at is not null and p.price_minor > 0) then
      raise exception 'The money for this has been released. Ask the OlympusGO team.';
    end if;
    update public.activities set status = 'cancelled', cancel_message = nullif(trim(message), '')
    where id = a.id;

    for pay in
      select * from public.payments p
      where p.activity_id = a.id and p.status in ('pending', 'succeeded', 'debt')
      order by p.id for update
    loop
      if pay.purpose = 'organizer_fee' then
        perform private.organizer_fee_reverse(a, pay.beneficiary_id);
      elsif pay.status = 'pending' then
        update public.payments
        set status = case when method is null then 'cancelled' else 'cancel_requested' end
        where id = pay.id;
      elsif pay.purpose = 'host_spot' then
        perform private.refund_issue(pay.id, 'host_spot');
      else
        perform private.refund_issue(pay.id, 'organizer_cancelled');
      end if;
    end loop;

    update public.event_tickets set status = 'released'
    where activity_id = a.id and status = 'active';

    for ap in
      select * from public.activity_participants p
      where p.activity_id = a.id and p.status in ('joined', 'waitlist', 'reserved', 'offered')
        and p.user_id <> a.host_id
    loop
      v_paid := exists (select 1 from public.payments p
        where p.activity_id = a.id and p.user_id = ap.user_id and p.status = 'succeeded');
      perform public.notify(ap.user_id, a.title || ' is cancelled',
        coalesce(nullif(trim(message), ''),
          case when v_paid then 'The organizer cancelled it. You get everything you paid back.'
               else 'The organizer cancelled it.' end),
        '!', '/activities/' || a.id);
    end loop;
    update public.activity_participants set status = 'cancelled', hold_until = null, queue_seq = null
    where activity_id = a.id and status in ('reserved', 'offered');
  end loop;
end;
$$;

create or replace function public.cancel_preview(activity uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  with a as (select * from public.activities where id = activity),
  paid as (
    select pay.* from public.payments pay
    where pay.activity_id = activity and pay.status = 'succeeded' and pay.purpose <> 'organizer_fee'
  )
  select jsonb_build_object(
    'players', (select count(*) from public.activity_participants
      where activity_id = activity and status = 'joined' and user_id <> a.host_id),
    'each_cents', case when private.activity_charges(a)
      then (public.money_quote('meet', a.fee_cents::bigint, 1, a.currency) ->> 'total_minor')::bigint
      else 0 end,
    'card_payments', (select count(*) from paid where method = 'card'),
    -- Stripe's real fee (R-REF-11). Unknown fees show up once Stripe reports them.
    'card_fee_cents', coalesce((select sum(processor_fee_minor) from paid where method = 'card'), 0),
    'later_meets', case when a.series_id is null then 1 else
      (select count(*) from public.activities s where s.series_id = a.series_id
        and s.starts_at >= a.starts_at and s.status = 'published') end,
    'last_meet', (select max(s.starts_at) from public.activities s
      where s.series_id = a.series_id and s.status = 'published')
  )
  from a where public.is_host(activity);
$$;

-- R-REF-13: a removed or banned member gets upcoming paid Meets of that club
-- back in full.
create function private.club_member_refunds(p_club uuid, p_user uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and another player's place.
declare
  a public.activities;
  pay public.payments;
begin
  for a in
    select * from public.activities s
    where s.club_id = p_club and s.status = 'published' and s.starts_at > now()
      and exists (select 1 from public.activity_participants ap
        where ap.activity_id = s.id and ap.user_id = p_user
          and ap.status in ('joined', 'reserved', 'offered', 'waitlist'))
    order by s.id
    for update
  loop
    for pay in
      select * from public.payments p
      where p.activity_id = a.id and p.user_id = p_user and p.status = 'succeeded'
        and p.purpose in ('meet', 'ticket')
    loop
      perform private.refund_issue(pay.id, 'removed_from_club');
    end loop;
    perform private.organizer_fee_reverse(a, p_user);
    update public.payments
    set status = case when method is null then 'cancelled' else 'cancel_requested' end
    where activity_id = a.id and user_id = p_user and status = 'pending';
    update public.activity_participants set status = 'cancelled', hold_until = null, queue_seq = null
    where activity_id = a.id and user_id = p_user;
    perform private.promote_waitlist(a.id);
  end loop;
end;
$$;

do $$
declare
  f text;
  d text;
  fixed text;
begin
  foreach f in array array['public.club_ban(uuid, uuid, text)', 'public.club_remove_member(uuid, uuid)'] loop
    d := pg_get_functiondef(f::regprocedure);
    fixed := replace(d, E'perform public.club_log(p_club, ''members'',',
      E'perform private.club_member_refunds(p_club, p_user);\n  perform public.club_log(p_club, ''members'',');
    if fixed = d then raise exception '% did not change', f; end if;
    execute fixed;
  end loop;
end;
$$;

-- Courts stay refused until 4b, but no path may mention a Wallet.
drop function public.cancel_court_booking(uuid, boolean);
alter table public.court_bookings drop constraint court_bookings_refund_to_check;
alter table public.court_bookings add constraint court_bookings_refund_to_check
  check (refund_to in ('original'));

create function public.cancel_court_booking(booking uuid) returns integer
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
  refund := case when b.starts_at - now() < interval '24 hours' then 0 else b.court_cents end;
  update public.court_bookings
  set status = 'cancelled', refund_cents = refund,
      refund_to = case when refund > 0 then 'original' end
  where id = booking;
  return refund;
end;
$$;
revoke execute on function public.cancel_court_booking(uuid) from public, anon;
grant execute on function public.cancel_court_booking(uuid) to authenticated;

-- Reports hold money --------------------------------------------------------

-- R-HOLD-4: a participant's report before release keeps the money held until
-- staff decide. A report from anyone else doesn't, or any user could freeze an
-- organizer's money (Q default).
create function private.report_holds_money() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: reads cases and writes holds, which clients can't.
declare
  c public.moderation_cases;
  v_activity uuid;
begin
  select * into c from public.moderation_cases where id = new.case_id;
  if c.target_kind <> 'activity' then return new; end if;
  v_activity := c.target_id::uuid;
  perform 1 from public.activities where id = v_activity for update;
  if not exists (select 1 from public.activity_participants ap
      where ap.activity_id = v_activity and ap.user_id = new.reporter_id
        and ap.status = 'joined') then
    return new;
  end if;
  if not exists (select 1 from public.payments p
      where p.activity_id = v_activity and p.status = 'succeeded' and p.released_at is null
        and p.price_minor > 0) then
    return new;
  end if;
  insert into public.activity_money_holds (activity_id, case_id)
  values (v_activity, c.id)
  on conflict do nothing;
  return new;
end;
$$;
create trigger case_reports_hold_money after insert on public.case_reports
  for each row execute function private.report_holds_money();

-- Capture -------------------------------------------------------------------

-- Money that can't be placed is still recorded, and a person looks at it.
create function private.capture_suspense(p_payment uuid, p_intent text, p_amount bigint, p_currency text,
  p_why text)
returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the ledger.
begin
  perform private.ledger_post('suspense', 'suspense:' || p_intent, p_currency,
    jsonb_build_object('intent', p_intent, 'payment', p_payment, 'why', p_why),
    jsonb_build_array(private.ledger_line('clearing', null, p_amount),
      private.ledger_line('suspense', null, -p_amount)));
  perform private.money_alert('suspense', 'suspense:' || p_intent,
    jsonb_build_object('intent', p_intent, 'payment', p_payment, 'why', p_why, 'amount_minor', p_amount));
  return 'suspense';
end;
$$;

-- Ledger first, always: the money is here, so record it, then decide the spot.
create function private.capture_succeeded(p_payment uuid, p_intent text, p_charge text, p_amount bigint,
  p_currency text, p_method text)
returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: runs for the webhook.
declare
  pay public.payments;
  a public.activities;
  v_live boolean;
  v_seat boolean;
  v_reason text;
begin
  select * into pay from public.payments where id = p_payment;
  if pay.id is null or p_amount <> pay.amount_minor or p_currency <> pay.currency
     or (pay.stripe_intent_id is not null and pay.stripe_intent_id <> p_intent) then
    if pay.status = 'succeeded' and pay.stripe_intent_id = p_intent then return 'duplicate'; end if;
    return private.capture_suspense(p_payment, p_intent, p_amount, p_currency, 'unmatched');
  end if;
  if pay.activity_id is not null then
    select * into a from public.activities where id = pay.activity_id for update;
  end if;
  select * into pay from public.payments where id = p_payment for update;
  if pay.status = 'succeeded' then return 'duplicate'; end if;
  if pay.status not in ('pending', 'cancel_requested') then
    return private.capture_suspense(p_payment, p_intent, p_amount, p_currency, 'ended:' || pay.status);
  end if;

  v_live := pay.status = 'pending' and pay.hold_until > now();
  update public.payments
  set status = 'succeeded', captured_at = now(), method = coalesce(p_method, method),
      stripe_intent_id = p_intent, stripe_charge_id = p_charge, hold_until = null
  where id = pay.id
  returning * into pay;

  perform private.ledger_post('capture', 'capture:' || pay.id, pay.currency,
    jsonb_build_object('payment', pay.id, 'intent', p_intent),
    jsonb_build_array(private.ledger_line('clearing', null, pay.amount_minor),
      private.ledger_line('held', pay.activity_id, -pay.price_minor),
      private.ledger_line(case when pay.purpose = 'debt' then 'organizer_fee_debt' else 'platform_fees' end,
        case when pay.purpose = 'debt' then pay.user_id end, -pay.fee_minor)));

  if pay.purpose in ('organizer_fee', 'debt') then
    return 'captured';
  end if;

  -- Blocked and suspended players can't reach a spot, whatever they paid.
  if a.id is null or a.status <> 'published' then
    v_reason := case when a.status = 'cancelled' then 'organizer_cancelled' else 'late_no_spot' end;
  elsif public.is_blocked_between(pay.user_id, a.host_id) or private.is_restricted(pay.user_id)
     or private.is_suspended(pay.user_id) then
    v_reason := 'blocked';
  elsif v_live then
    v_seat := true;
  elsif pay.purpose = 'ticket' then
    v_seat := a.starts_at > now()
      and (select coalesce(sum(t.qty), 0) from public.event_tickets t
           where t.activity_id = a.id and t.status = 'active') + pay.qty <= a.capacity;
    v_reason := 'late_no_spot';
  else
    -- Late money takes a free seat, but never ahead of the queue.
    v_seat := a.starts_at > now()
      and public.activity_spots_taken(a.id) + pay.qty <= private.open_capacity(a)
      and not exists (select 1 from public.activity_participants ap
        where ap.activity_id = a.id and ap.status in ('waitlist', 'offered'));
    v_reason := 'late_no_spot';
  end if;

  if not coalesce(v_seat, false) then
    update public.activity_participants set status = 'cancelled', hold_until = null
    where activity_id = pay.activity_id and user_id = pay.user_id and status in ('reserved', 'offered');
    perform private.refund_issue(pay.id, v_reason);
    perform public.notify(pay.user_id, 'Your payment is coming back',
      'We couldn''t keep your spot, so everything you paid is being refunded.', '!',
      '/activities/' || pay.activity_id);
    return 'refunded';
  end if;

  if pay.purpose = 'ticket' then
    perform private.ticket_issue(a, pay.user_id, pay.qty);
  else
    insert into public.activity_participants (activity_id, user_id, status)
    values (pay.activity_id, pay.user_id, 'joined')
    on conflict (activity_id, user_id) do update
      set status = 'joined', hold_until = null, queue_seq = null;
    perform private.refresh_game_on(pay.activity_id);
  end if;
  perform public.notify(pay.user_id, 'You''re in', 'Your payment went through for ' || a.title || '.',
    '✓', '/activities/' || a.id, '#E3F7C8', '#2E5A00');
  return 'seated';
end;
$$;

-- An organizer-pays fee that won't charge becomes a debt (owner, 31 Oct). The
-- player keeps the spot.
create function private.organizer_fee_failed(p_payment uuid, p_code text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the ledger.
declare
  pay public.payments;
begin
  select * into pay from public.payments where id = p_payment for update;
  if pay.status <> 'pending' or pay.purpose <> 'organizer_fee' then return; end if;
  update public.payments set status = 'debt', failure_code = p_code where id = pay.id;
  perform private.ledger_post('organizer_debt', 'organizer_debt:' || pay.id, pay.currency,
    jsonb_build_object('payment', pay.id),
    jsonb_build_array(private.ledger_line('organizer_fee_debt', pay.user_id, pay.fee_minor),
      private.ledger_line('platform_fees', null, -pay.fee_minor)));
  perform public.notify(pay.user_id, 'We couldn''t charge your card',
    'Your player keeps their spot. Clear the fee before you publish another free Meet.', '!',
    '/earnings');
end;
$$;

-- Reserves the amount owed, then pays like any other payment.
create function public.organizer_debt_reserve(p_key text) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: reads the ledger.
declare
  me uuid := auth.uid();
  v_debt bigint := private.ledger_balance('organizer_fee_debt', me, 'SGD');
  pay public.payments;
begin
  select * into pay from public.payments where user_id = me and idempotency_key = p_key;
  if pay.id is not null then return private.payment_json(pay); end if;
  if v_debt <= 0 then raise exception 'You don''t owe anything.'; end if;
  insert into public.payments (user_id, purpose, price_minor, fee_minor, amount_minor, currency,
    rule_snapshot, idempotency_key, hold_until)
  values (me, 'debt', 0, v_debt, v_debt, 'SGD',
    jsonb_build_object('refund_rule', 'Fees you owe aren''t refundable.'), p_key,
    now() + make_interval(mins => private.setting_int('meet.reservation_minutes')))
  returning * into pay;
  return private.payment_json(pay);
end;
$$;

-- Card fees ----------------------------------------------------------------

-- R-REF-11: once a refund has gone through and Stripe's real fee is known.
create function private.card_fee_recover(p_payment uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the ledger.
declare
  pay public.payments;
begin
  select * into pay from public.payments where id = p_payment;
  if pay.processor_fee_minor is null or pay.processor_fee_minor = 0 or pay.method <> 'card' then return; end if;
  if not exists (select 1 from public.refunds r
      where r.payment_id = pay.id and r.organizer_pays_fee and r.status in ('succeeded', 'manual')) then
    return;
  end if;
  perform private.ledger_post('card_fee', 'card_fee:' || pay.id, pay.currency,
    jsonb_build_object('payment', pay.id),
    jsonb_build_array(private.ledger_line('card_fee_recovery', pay.organizer_id, pay.processor_fee_minor),
      private.ledger_line('processor_fees', null, -pay.processor_fee_minor)));
end;
$$;

create function private.refund_settled(p_refund uuid, p_status text, p_stripe_id text, p_code text)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the ledger.
declare
  r public.refunds;
  pay public.payments;
begin
  select * into r from public.refunds where id = p_refund for update;
  if r.id is null then
    perform private.money_alert('refund_unknown', 'refund-unknown:' || coalesce(p_stripe_id, p_refund::text));
    return;
  end if;
  select * into pay from public.payments where id = r.payment_id;
  if p_status = 'succeeded' and r.status in ('pending', 'processing') then
    update public.refunds
    set status = 'succeeded', settled_at = now(), stripe_refund_id = coalesce(p_stripe_id, stripe_refund_id)
    where id = r.id;
    perform private.ledger_post('refund_paid', 'refund_paid:' || r.id, pay.currency,
      jsonb_build_object('refund', r.id, 'stripe', p_stripe_id),
      jsonb_build_array(private.ledger_line('refunds_pending', null, r.amount_minor),
        private.ledger_line('clearing', null, -r.amount_minor)));
    perform private.card_fee_recover(r.payment_id);
  elsif p_status = 'failed' and r.status in ('pending', 'processing') then
    update public.refunds
    set status = 'failed', failure_code = p_code, stripe_refund_id = coalesce(p_stripe_id, stripe_refund_id)
    where id = r.id;
    perform private.money_alert('refund_failed', 'refund-failed:' || r.id || ':' || now()::date,
      jsonb_build_object('refund', r.id, 'payment', r.payment_id, 'code', p_code));
  end if;
end;
$$;

-- Webhook and worker ---------------------------------------------------------

-- Idempotent on Stripe's event id. Business outcomes never raise: only a real
-- fault does, and then Stripe retries.
create function public.money_svc_event(p_event jsonb) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only, and it writes every money table.
declare
  v_id text := p_event ->> 'id';
  v_type text := p_event ->> 'type';
  o jsonb := p_event -> 'object';
  v_payment uuid;
  v_result text := 'ignored';
  v_row public.payments;
begin
  insert into public.stripe_events (id, type, payload) values (v_id, v_type, p_event)
  on conflict (id) do nothing;
  if not found then return 'duplicate'; end if;

  v_payment := nullif(o #>> '{metadata,payment_id}', '')::uuid;
  case v_type
    when 'payment_intent.succeeded' then
      v_result := private.capture_succeeded(v_payment, o ->> 'id', o ->> 'latest_charge',
        (o ->> 'amount')::bigint, upper(o ->> 'currency'), o ->> 'payment_method_type');
    when 'payment_intent.payment_failed' then
      select * into v_row from public.payments where id = v_payment;
      if v_row.purpose = 'organizer_fee' then
        perform private.organizer_fee_failed(v_payment, o ->> 'failure_code');
      elsif v_row.status = 'pending' then
        -- Not final: the hold stays, so the player can try again.
        update public.payments set failure_code = o ->> 'failure_code' where id = v_payment;
      end if;
      v_result := 'failed';
    when 'payment_intent.canceled' then
      update public.payments set status = 'cancelled'
      where id = v_payment and status in ('pending', 'cancel_requested');
      v_result := 'cancelled';
    when 'charge.updated' then
      -- The fee may not exist at capture: Stripe reports it here.
      select * into v_row from public.payments where stripe_charge_id = o ->> 'id' for update;
      if v_row.id is not null and (o ->> 'fee_minor') is not null then
        update public.payments set processor_fee_minor = (o ->> 'fee_minor')::bigint where id = v_row.id;
        perform private.ledger_post('processor_fee', 'processor_fee:' || v_row.id, v_row.currency,
          jsonb_build_object('payment', v_row.id),
          jsonb_build_array(private.ledger_line('processor_fees', null, (o ->> 'fee_minor')::bigint),
            private.ledger_line('clearing', null, -(o ->> 'fee_minor')::bigint)));
        perform private.card_fee_recover(v_row.id);
        v_result := 'fee';
      end if;
    when 'refund.updated', 'refund.failed', 'charge.refund.updated' then
      if o ->> 'status' in ('succeeded', 'failed') then
        perform private.refund_settled(nullif(o #>> '{metadata,refund_id}', '')::uuid, o ->> 'status',
          o ->> 'id', o ->> 'failure_reason');
        v_result := o ->> 'status';
      end if;
    when 'setup_intent.succeeded' then
      insert into public.payment_customers
        (user_id, stripe_customer_id, payment_method_id, card_brand, card_last4)
      values ((o #>> '{metadata,user_id}')::uuid, o ->> 'customer', o ->> 'payment_method',
        o ->> 'card_brand', o ->> 'card_last4')
      on conflict (user_id) do update
        set stripe_customer_id = excluded.stripe_customer_id,
            payment_method_id = excluded.payment_method_id,
            card_brand = excluded.card_brand, card_last4 = excluded.card_last4, updated_at = now();
      v_result := 'card_saved';
    when 'charge.dispute.created' then
      select * into v_row from public.payments where stripe_charge_id = o ->> 'charge';
      if v_row.id is not null then
        insert into public.payment_disputes (payment_id, stripe_dispute_id, amount_minor)
        values (v_row.id, o ->> 'id', (o ->> 'amount')::bigint)
        on conflict (stripe_dispute_id) do nothing;
        perform private.ledger_post('dispute', 'dispute:' || (o ->> 'id'), v_row.currency,
          jsonb_build_object('payment', v_row.id, 'dispute', o ->> 'id'),
          jsonb_build_array(private.ledger_line('suspense', null, (o ->> 'amount')::bigint),
            private.ledger_line('clearing', null, -(o ->> 'amount')::bigint)));
        perform private.money_alert('dispute', 'dispute:' || (o ->> 'id'),
          jsonb_build_object('payment', v_row.id));
        v_result := 'dispute';
      end if;
    when 'charge.dispute.closed' then
      -- Won returns the money. Lost stays in suspense for staff (Q72).
      update public.payment_disputes
      set status = case when o ->> 'status' = 'won' then 'won' else 'lost' end, closed_at = now()
      where stripe_dispute_id = o ->> 'id' and status = 'open'
      returning payment_id into v_payment;
      if found and o ->> 'status' = 'won' then
        select * into v_row from public.payments where id = v_payment;
        perform private.ledger_post('dispute_won', 'dispute_won:' || (o ->> 'id'), v_row.currency,
          jsonb_build_object('payment', v_payment, 'dispute', o ->> 'id'),
          jsonb_build_array(private.ledger_line('clearing', null, (o ->> 'amount')::bigint),
            private.ledger_line('suspense', null, -(o ->> 'amount')::bigint)));
      end if;
      v_result := 'dispute_closed';
    when 'account.updated' then
      update public.vendors
      set status = case when (o ->> 'payouts_enabled')::boolean then 'verified' else status end,
          verified_at = case when (o ->> 'payouts_enabled')::boolean then coalesce(verified_at, now()) else verified_at end
      where stripe_account_id = o ->> 'id';
      v_result := 'vendor';
    else
      null;
  end case;

  update public.stripe_events set processed_at = now() where id = v_id;
  return v_result;
end;
$$;

-- Records the intent. A webhook that got here first has already filled it in.
create function public.money_svc_attach_intent(p_payment uuid, p_intent text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only.
begin
  update public.payments set stripe_intent_id = coalesce(stripe_intent_id, p_intent)
  where id = p_payment;
end;
$$;

create function public.money_svc_customer(p_user uuid) returns text
language sql stable security definer set search_path = '' as $$
  -- Definer: service role only.
  select stripe_customer_id from public.payment_customers where user_id = p_user;
$$;

-- The worker's to-do list.
create function public.money_svc_work() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: service role only.
  select jsonb_build_object(
    'cancel', (select coalesce(jsonb_agg(jsonb_build_object('payment_id', p.id, 'intent', p.stripe_intent_id)), '[]')
      from (select * from public.payments where status = 'cancel_requested'
            order by created_at limit 50) p),
    'refunds', (select coalesce(jsonb_agg(jsonb_build_object('refund_id', r.id, 'intent', p.stripe_intent_id,
        'amount_minor', r.amount_minor)), '[]')
      from (select * from public.refunds where status = 'pending' order by created_at limit 50) r
      join public.payments p on p.id = r.payment_id),
    'organizer_fees', (select coalesce(jsonb_agg(jsonb_build_object('payment_id', p.id,
        'amount_minor', p.amount_minor, 'currency', p.currency, 'customer', c.stripe_customer_id,
        'payment_method', c.payment_method_id)), '[]')
      from (select * from public.payments where status = 'pending' and purpose = 'organizer_fee'
              and stripe_intent_id is null
            order by created_at limit 50) p
      left join public.payment_customers c on c.user_id = p.user_id));
$$;

-- What the worker's Stripe call said.
create function public.money_svc_result(p_kind text, p_id uuid, p_ok boolean, p_ref text default null,
  p_code text default null)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only.
begin
  case p_kind
    when 'cancel' then
      -- No intent to cancel, or Stripe says it's gone: finished either way.
      if p_ok then
        update public.payments set status = 'cancelled'
        where id = p_id and status = 'cancel_requested';
      end if;
    when 'refund' then
      if p_ok then
        update public.refunds set status = 'processing', stripe_refund_id = coalesce(stripe_refund_id, p_ref)
        where id = p_id and status = 'pending';
      else
        perform private.refund_settled(p_id, 'failed', p_ref, p_code);
      end if;
    when 'organizer_fee' then
      if p_ok then
        perform public.money_svc_attach_intent(p_id, p_ref);
      else
        perform private.organizer_fee_failed(p_id, p_code);
      end if;
    else
      raise exception 'Unknown result %', p_kind;
  end case;
end;
$$;

-- Holds that ran out, money due for release, and old money.
create function private.holds_sweep() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: cron.
declare
  r record;
begin
  for r in
    select distinct activity_id from public.activity_participants
    where status in ('reserved', 'offered') and hold_until <= now()
    union
    select distinct activity_id from public.payments
    where status = 'pending' and hold_until <= now() and activity_id is not null
    order by 1
  loop
    perform 1 from public.activities where id = r.activity_id for update;
    perform private.expire_holds(r.activity_id);
  end loop;
  update public.payments set status = 'cancelled'
  where status = 'pending' and activity_id is null and hold_until <= now() and method is null;
  update public.payments set status = 'cancel_requested'
  where status = 'pending' and activity_id is null and hold_until <= now();
end;
$$;

create function private.money_sweep() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: cron.
declare
  r record;
begin
  for r in
    select distinct a.id from public.payments p
    join public.activities a on a.id = p.activity_id
    where p.status = 'succeeded' and p.released_at is null
      and (now() >= a.ends_at + make_interval(hours => private.setting_int('funds.release_after_hours'))
        or (now() >= a.starts_at and private.attendance_saved(a.id)))
    order by a.id
  loop
    perform private.release_activity(r.id);
  end loop;

  for r in
    select p.id, p.activity_id from public.payments p
    where p.status = 'succeeded' and p.released_at is null and p.price_minor > 0
      and p.captured_at < now() - make_interval(days => private.setting_int('money.hold_alert_days'))
  loop
    perform private.money_alert('hold_aging', 'hold-aging:' || r.activity_id,
      jsonb_build_object('activity', r.activity_id));
  end loop;
end;
$$;

select cron.schedule('money-holds', '* * * * *', 'select private.holds_sweep()');
select cron.schedule('money-sweep', '*/5 * * * *', 'select private.money_sweep()');

-- A player's own records ----------------------------------------------------

create function public.money_my_payments(p_limit integer default 50) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: joins refunds and activity names for the caller's own rows.
  select coalesce(jsonb_agg(x order by x ->> 'created_at' desc), '[]')
  from (
    select private.payment_json(p) || jsonb_build_object(
      'created_at', p.created_at, 'captured_at', p.captured_at,
      'title', (select a.title from public.activities a where a.id = p.activity_id),
      'activity_id', p.activity_id,
      'refunded_minor', coalesce((select sum(r.amount_minor) from public.refunds r
        where r.payment_id = p.id and r.status <> 'voided'), 0)) as x
    from public.payments p
    where p.user_id = auth.uid() and p.status in ('succeeded', 'debt')
    order by p.created_at desc limit least(coalesce(p_limit, 50), 200)
  ) y;
$$;

create function public.money_my_card() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: payment_customers has no client access.
  select jsonb_build_object('brand', card_brand, 'last4', card_last4)
  from public.payment_customers
  where user_id = auth.uid() and payment_method_id is not null;
$$;

-- Definer functions the app calls.
revoke execute on function public.activity_reserve(uuid, text, integer, text, numeric),
  public.activity_quote(uuid, integer), public.payment_begin(uuid, text),
  public.payment_abandon(uuid), public.payment_status(uuid),
  public.leave_activity(uuid), public.organizer_debt_reserve(text),
  public.money_my_payments(integer), public.money_my_card()
  from public, anon;
grant execute on function public.activity_reserve(uuid, text, integer, text, numeric),
  public.activity_quote(uuid, integer), public.payment_begin(uuid, text),
  public.payment_abandon(uuid), public.payment_status(uuid),
  public.leave_activity(uuid), public.organizer_debt_reserve(text),
  public.money_my_payments(integer), public.money_my_card()
  to authenticated;

-- Only the Edge Functions, with the service key.
revoke execute on function public.money_svc_event(jsonb), public.money_svc_attach_intent(uuid, text),
  public.money_svc_customer(uuid), public.money_svc_work(),
  public.money_svc_result(text, uuid, boolean, text, text)
  from public, anon, authenticated;
grant execute on function public.money_svc_event(jsonb), public.money_svc_attach_intent(uuid, text),
  public.money_svc_customer(uuid), public.money_svc_work(),
  public.money_svc_result(text, uuid, boolean, text, text)
  to service_role;

revoke execute on function private.capture_succeeded(uuid, text, text, bigint, text, text),
  private.capture_suspense(uuid, text, bigint, text, text), private.refund_issue(uuid, text, text, bigint, uuid),
  private.organizer_fee_queue(public.activities, uuid, integer),
  private.organizer_fee_reverse(public.activities, uuid),
  private.organizer_fee_failed(uuid, text), private.leave_money(public.activities, uuid),
  private.release_activity(uuid), private.expire_holds(uuid), private.card_fee_recover(uuid),
  private.refund_settled(uuid, text, text, text), private.holds_sweep(), private.money_sweep(),
  private.club_member_refunds(uuid, uuid), private.ticket_issue(public.activities, uuid, integer)
  from public, anon, authenticated;

insert into private.suspended_allow (path) values ('/rpc/money_my_payments');
