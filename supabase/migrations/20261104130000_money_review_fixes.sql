-- P4a review: what two independent reviews found in the money path.

alter table public.ledger_accounts drop constraint ledger_accounts_kind_check;
alter table public.ledger_accounts add constraint ledger_accounts_kind_check
  check (kind in ('clearing', 'held', 'platform_fees', 'organizer', 'refunds_pending',
    'processor_fees', 'card_fee_recovery', 'organizer_fee_debt', 'payouts_pending', 'suspense',
    'disputes_open'));

alter table public.payments
  -- 'expired' money may still take a free seat. Any other cancelled payment
  -- was given up, so money that lands anyway goes straight back.
  add column cancel_reason text check (cancel_reason in ('expired')),
  -- The refund a dispute held up, to issue once it closes.
  add column refund_owed text;

-- Stripe remembers a key's first answer, so each staff retry needs a new one.
alter table public.refunds add column attempt integer not null default 1;

create unique index payments_one_debt on public.payments (user_id)
  where purpose = 'debt' and status = 'pending';

-- Money can land on a payment we'd stopped, and a PayNow refund can bounce
-- after it succeeded.
insert into private.payment_transitions values ('cancelled', 'succeeded'), ('debt', 'succeeded');
insert into private.refund_transitions values ('failed', 'succeeded'), ('succeeded', 'failed');
-- The worker may already have sent a pending refund.
delete from private.refund_transitions where from_status = 'pending' and to_status = 'voided';

-- One worker at a time.
create table private.worker_lease (
  id boolean primary key default true check (id),
  until timestamptz not null default '-infinity'
);
insert into private.worker_lease default values;

create function public.money_svc_lease(p_seconds integer) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only.
begin
  if p_seconds = 0 then
    update private.worker_lease set until = now() where id;
    return true;
  end if;
  update private.worker_lease set until = now() + make_interval(secs => p_seconds)
  where until <= now();
  return found;
end;
$$;
revoke execute on function public.money_svc_lease(integer) from public, anon, authenticated;
grant execute on function public.money_svc_lease(integer) to service_role;

-- A host can't stop the refund window, or use a date to dodge the hold limit.
do $$
declare
  d text := pg_get_functiondef('private.activity_lock_columns()'::regprocedure);
  fixed text;
begin
  fixed := replace(d, 'new.status := old.status;',
    E'new.status := old.status;\n    new.money_changed_at := old.money_changed_at;');
  fixed := replace(fixed,
$old$      if new.starts_at <> old.starts_at or new.venue_id <> old.venue_id then
        new.money_changed_at := now();
      end if;$old$,
$new$      if new.ends_at > now() + make_interval(days => private.setting_int('money.max_advance_days'))
         and new.ends_at > old.ends_at then
        raise exception 'People have already paid, so this can''t move that far ahead.' using errcode = 'P0001';
      end if;
      if (new.starts_at, new.ends_at, new.venue_id) is distinct from (old.starts_at, old.ends_at, old.venue_id) then
        new.money_changed_at := now();
      end if;$new$);
  if fixed = d or position('money_changed_at := old' in fixed) = 0
     or position('that far ahead' in fixed) = 0 then
    raise exception 'activity_lock_columns did not change';
  end if;
  execute fixed;
end;
$$;

-- The same key on another activity is a client bug, not the same payment.
do $$
declare
  d text := pg_get_functiondef('public.activity_reserve(uuid, text, integer, text, numeric)'::regprocedure);
  fixed text := replace(d,
$old$  if pay.id is not null then
    return private.payment_json(pay) || jsonb_build_object('result', 'reserved');
  end if;

  if not private.flag('payments.enabled') then$old$,
$new$  if pay.id is not null then
    if pay.activity_id is distinct from p_activity then raise exception 'Try that again.'; end if;
    return private.payment_json(pay) || jsonb_build_object('result', 'reserved');
  end if;

  if not private.flag('payments.enabled') then$new$);
begin
  if fixed = d then raise exception 'activity_reserve did not change'; end if;
  execute fixed;
end;
$$;

-- R-FEE-5 applies to a free Meet too, so a host pays through activity_reserve.
do $$
declare
  d text := pg_get_functiondef('public.join_activity(uuid, text, numeric)'::regprocedure);
  fixed text := replace(d,
$old$  if a.fee_cents > 0 and a.kind <> 'meet' then$old$,
$new$  if me = a.host_id and a.kind = 'meet' and private.flag('payments.enabled') then
    raise exception 'payment_required' using errcode = 'P0001';
  end if;
  if a.fee_cents > 0 and a.kind <> 'meet' then$new$);
begin
  if fixed = d then raise exception 'join_activity did not change'; end if;
  execute fixed;
end;
$$;

create or replace function private.expire_holds(p_activity uuid) returns void
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
  set status = case when method is null then 'cancelled' else 'cancel_requested' end,
      cancel_reason = 'expired'
  where activity_id = p_activity and status = 'pending' and hold_until <= now();

  if v_seats > 0 then
    perform private.promote_waitlist(p_activity);
  end if;
end;
$$;

create or replace function public.payment_abandon(p_payment uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: changes the spot under the same lock as joining.
declare
  pay public.payments;
begin
  select * into pay from public.payments
  where id = p_payment and user_id = auth.uid() and purpose <> 'organizer_fee';
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

-- Refunds -------------------------------------------------------------------

drop function private.refund_issue(uuid, text, text, bigint, uuid);
create function private.refund_issue(p_payment uuid, p_reason text, p_key text default null,
  p_price_limit bigint default null, p_actor uuid default null, p_fee_limit bigint default null)
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
  -- An open dispute may yet take this money back, so the refund waits for it.
  if exists (select 1 from public.payment_disputes d
      where d.payment_id = pay.id and d.status = 'open') then
    update public.payments set refund_owed = p_reason where id = pay.id;
    perform private.money_alert('refund_blocked_by_dispute', 'dispute-refund:' || pay.id,
      jsonb_build_object('payment', pay.id));
    return 0;
  end if;
  -- A lost dispute already gave the money back.
  if exists (select 1 from public.payment_disputes d
      where d.payment_id = pay.id and d.status = 'lost') then
    return 0;
  end if;
  select pay.price_minor - coalesce(sum(price_minor), 0), pay.fee_minor - coalesce(sum(fee_minor), 0)
  into v_price, v_fee
  from public.refunds where payment_id = pay.id and status <> 'voided';

  q := public.money_refund_quote(p_reason, v_price, v_fee, pay.method);
  v_price := (q ->> 'price_minor')::bigint;
  v_fee := (q ->> 'fee_minor')::bigint;
  if p_price_limit is not null then v_price := least(v_price, p_price_limit); end if;
  if p_fee_limit is not null then v_fee := least(v_fee, p_fee_limit); end if;
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
revoke execute on function private.refund_issue(uuid, text, text, bigint, uuid, bigint)
  from public, anon, authenticated;

create function private.change_window_open(a public.activities) returns boolean
language sql stable set search_path = '' as $$
  -- R-REF-17, before the start only: afterwards the player had what they paid for.
  select a.money_changed_at is not null and now() < a.starts_at
    and now() < a.money_changed_at + make_interval(hours => private.setting_int('money.change_refund_hours'));
$$;

-- Everything money owes a player who gives up a Meet spot. Tickets go through
-- private.ticket_release, so a refund always ends the ticket.
create or replace function private.leave_money(a public.activities, p_user uuid) returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and the ledger.
declare
  pay public.payments;
  v_refund bigint := 0;
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
    elsif pay.purpose = 'ticket' then
      continue;
    elsif pay.purpose = 'host_spot' then
      if private.refund_in_time('meet', a) then
        v_refund := v_refund + private.refund_issue(pay.id, 'host_spot');
      end if;
    elsif private.change_window_open(a) and pay.captured_at < a.money_changed_at then
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

-- The one way tickets end. The caller holds the activity lock.
create function private.ticket_release(a public.activities, p_user uuid, p_qty integer) returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and tickets.
declare
  t public.event_tickets;
  pay public.payments;
  v_units int;
  v_left int;
  v_take int;
  v_unit_price bigint;
  v_unit_fee bigint;
  v_remaining int;
  v_refund bigint := 0;
  v_all boolean;
  v_key text;
begin
  select * into t from public.event_tickets
  where activity_id = a.id and user_id = p_user and status = 'active';
  if not found then raise exception 'You don''t have tickets for this event.'; end if;
  if t.scanned_at is not null then
    raise exception 'These tickets were used at the door.';
  end if;
  v_units := least(greatest(coalesce(p_qty, 1), 1), t.qty);
  v_all := v_units >= t.qty;
  if v_all then
    update public.event_tickets set status = 'released' where id = t.id;
    update public.activity_participants set status = 'cancelled'
    where activity_id = a.id and user_id = p_user;
  else
    update public.event_tickets set qty = qty - v_units where id = t.id;
  end if;

  -- Newest tickets first, one unit at a time.
  v_left := v_units;
  for pay in
    select * from public.payments
    where activity_id = a.id and user_id = p_user and purpose = 'ticket' and status = 'succeeded'
    order by captured_at desc
  loop
    exit when v_left = 0;
    v_unit_price := pay.price_minor / pay.qty;
    v_unit_fee := pay.fee_minor / pay.qty;
    select case when v_unit_price > 0
        then ((pay.price_minor - coalesce(sum(r.price_minor), 0)) / v_unit_price)::int
        else ((pay.fee_minor - coalesce(sum(r.fee_minor), 0)) / nullif(v_unit_fee, 0))::int end,
      count(*)
    into v_remaining, v_take
    from public.refunds r where r.payment_id = pay.id and r.status <> 'voided';
    v_key := 'ticket:' || pay.id || ':' || (select count(*) from public.refunds r where r.payment_id = pay.id);
    v_take := least(v_left, coalesce(v_remaining, 0));
    continue when v_take = 0;
    if private.change_window_open(a) and pay.captured_at < a.money_changed_at then
      v_refund := v_refund + private.refund_issue(pay.id, 'change_by_organizer', v_key,
        v_take * v_unit_price, null, v_take * v_unit_fee);
    elsif private.refund_in_time('ticket', a) then
      v_refund := v_refund + private.refund_issue(pay.id, 'player_in_time', v_key, v_take * v_unit_price);
    end if;
    v_left := v_left - v_take;
  end loop;

  -- R-FEE-4: the organizer's fee comes back per ticket.
  if now() < a.starts_at then
    if v_all then
      perform private.organizer_fee_reverse(a, p_user);
    else
      v_left := v_units;
      for pay in
        select * from public.payments
        where activity_id = a.id and beneficiary_id = p_user and purpose = 'organizer_fee'
          and status = 'succeeded'
        order by captured_at desc
      loop
        exit when v_left = 0;
        v_unit_fee := pay.fee_minor / pay.qty;
        select ((pay.fee_minor - coalesce(sum(r.fee_minor), 0)) / v_unit_fee)::int into v_remaining
        from public.refunds r where r.payment_id = pay.id and r.status <> 'voided';
        v_take := least(v_left, v_remaining);
        continue when v_take = 0;
        perform private.refund_issue(pay.id, 'player_left',
          'orgfee:' || pay.id || ':' || (select count(*) from public.refunds r where r.payment_id = pay.id),
          null, null, v_take * v_unit_fee);
        v_left := v_left - v_take;
      end loop;
    end if;
  end if;
  return v_refund;
end;
$$;
revoke execute on function private.ticket_release(public.activities, uuid, integer)
  from public, anon, authenticated;

create or replace function public.event_ticket_release(p_activity uuid, p_qty integer) returns integer
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and tickets.
declare
  a public.activities;
begin
  select * into a from public.activities where id = p_activity for update;
  return private.ticket_release(a, (select auth.uid()), p_qty);
end;
$$;

create or replace function public.leave_activity(activity uuid) returns integer
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
  if exists (select 1 from public.event_tickets t
      where t.activity_id = activity and t.user_id = me and t.status = 'active') then
    v_refund := v_refund + private.ticket_release(a, me, 10);
  end if;
  update public.activity_participants
  set status = 'cancelled', queue_seq = null, hold_until = null,
      refund_to = case when v_refund > 0 then 'original' end,
      refund_cents = v_refund
  where activity_id = activity and user_id = me;
  perform private.promote_waitlist(activity);
  return v_refund;
end;
$$;

drop function public.host_plays(uuid, boolean);
create function public.host_plays(activity uuid, playing boolean) returns integer
language plpgsql security definer set search_path = '' as $$
-- Definer: takes or frees a spot under the same lock as joining.
declare
  a public.activities;
  v_refund bigint;
begin
  select * into a from public.activities where id = activity and host_id = auth.uid() for update;
  if a.id is null then raise exception 'Only the organizer can do this.'; end if;
  if not playing then
    v_refund := private.leave_money(a, a.host_id);
    update public.activity_participants set status = 'cancelled', queue_seq = null, hold_until = null
    where activity_id = activity and user_id = a.host_id;
    perform private.promote_waitlist(activity);
    return v_refund;
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
  return 0;
end;
$$;
revoke execute on function public.host_plays(uuid, boolean) from public, anon;
grant execute on function public.host_plays(uuid, boolean) to authenticated;

do $$
declare
  d text := pg_get_functiondef('private.club_member_refunds(uuid, uuid)'::regprocedure);
  fixed text := replace(d,
$old$    perform private.organizer_fee_reverse(a, p_user);$old$,
$new$    update public.event_tickets set status = 'released'
    where activity_id = a.id and user_id = p_user and status = 'active';
    perform private.organizer_fee_reverse(a, p_user);$new$);
begin
  if fixed = d then raise exception 'club_member_refunds did not change'; end if;
  execute fixed;
end;
$$;

-- Release ---------------------------------------------------------------------

create or replace function private.release_activity(p_activity uuid) returns integer
language plpgsql security definer set search_path = '' as $$
-- Definer: runs from a host's call and from cron.
declare
  pay public.payments;
  v_net bigint;
  v_done int := 0;
begin
  -- A cancelled activity owes its players, not its organizer.
  if (select status from public.activities where id = p_activity for update) = 'cancelled' then
    return 0;
  end if;
  if exists (select 1 from public.activity_money_holds h
      where h.activity_id = p_activity and h.closed_at is null) then
    return 0;
  end if;
  for pay in
    select * from public.payments
    where activity_id = p_activity and status = 'succeeded' and released_at is null
      and purpose in ('meet', 'ticket', 'tournament', 'host_spot') and refund_owed is null
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

-- Capture -----------------------------------------------------------------------

create or replace function private.capture_succeeded(p_payment uuid, p_intent text, p_charge text,
  p_amount bigint, p_currency text, p_method text)
returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: runs for the webhook.
declare
  pay public.payments;
  was public.payments;
  a public.activities;
  v_live boolean;
  v_expired boolean;
  v_seat boolean := false;
  v_reason text := 'late_no_spot';
  v_spot text;
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
  select * into was from public.payments where id = p_payment for update;
  if was.status = 'succeeded' then return 'duplicate'; end if;

  v_live := coalesce(was.status = 'pending' and was.hold_until > now(), false);
  v_expired := coalesce(was.cancel_reason = 'expired', false)
    or coalesce(was.status = 'pending' and was.hold_until <= now(), false);

  -- A charge we'd written off as failed turned out to work.
  if was.status = 'debt' then
    perform private.ledger_post('debt_reverse', 'debt_reverse:' || was.id, was.currency,
      jsonb_build_object('payment', was.id),
      jsonb_build_array(private.ledger_line('platform_fees', null, was.fee_minor),
        private.ledger_line('organizer_fee_debt', was.user_id, -was.fee_minor)));
  end if;

  update public.payments
  set status = 'succeeded', captured_at = now(), method = coalesce(p_method, method),
      stripe_intent_id = p_intent, stripe_charge_id = p_charge, hold_until = null
  where id = p_payment
  returning * into pay;

  perform private.ledger_post('capture', 'capture:' || pay.id, pay.currency,
    jsonb_build_object('payment', pay.id, 'intent', p_intent),
    jsonb_build_array(private.ledger_line('clearing', null, pay.amount_minor),
      private.ledger_line('held', pay.activity_id, -pay.price_minor),
      private.ledger_line(case when pay.purpose = 'debt' then 'organizer_fee_debt' else 'platform_fees' end,
        case when pay.purpose = 'debt' then pay.user_id end, -pay.fee_minor)));

  if pay.purpose = 'debt' then
    return 'captured';
  end if;
  if pay.purpose = 'organizer_fee' then
    -- The player left or the Meet ended while this was on its way.
    if was.status in ('cancel_requested', 'cancelled') then
      perform private.refund_issue(pay.id, 'player_left');
      return 'refunded';
    end if;
    return 'captured';
  end if;

  select ap.status into v_spot from public.activity_participants ap
  where ap.activity_id = pay.activity_id and ap.user_id = pay.user_id;

  -- Blocked and suspended players can't reach a spot, whatever they paid.
  if a.id is null or a.status <> 'published' then
    v_reason := case when pay.purpose = 'host_spot' then 'host_spot'
      when a.status = 'cancelled' then 'organizer_cancelled' else 'late_no_spot' end;
  elsif public.is_blocked_between(pay.user_id, a.host_id) or private.is_restricted(pay.user_id)
     or private.is_suspended(pay.user_id) then
    v_reason := 'blocked';
  elsif pay.purpose = 'ticket' and pay.qty + coalesce((select t.qty from public.event_tickets t
      where t.activity_id = a.id and t.user_id = pay.user_id and t.status = 'active'), 0) > 10 then
    v_seat := false;
  elsif v_live then
    v_seat := true;
  elsif not v_expired then
    -- Given up, so the money just goes back. Their spot, if any, stays theirs.
    v_seat := false;
  elsif pay.purpose = 'ticket' then
    v_seat := a.starts_at > now()
      and (select coalesce(sum(t.qty), 0) from public.event_tickets t
           where t.activity_id = a.id and t.status = 'active')
        + (select coalesce(sum(o.qty), 0) from public.payments o
           where o.activity_id = a.id and o.purpose = 'ticket' and o.status = 'pending' and o.id <> pay.id)
        + pay.qty <= a.capacity;
  elsif v_spot in ('joined', 'reserved') then
    -- Paid another way in the meantime.
    v_seat := false;
  else
    -- Late money takes a free seat, but never ahead of the queue.
    v_seat := a.starts_at > now()
      and public.activity_spots_taken(a.id) + pay.qty <= private.open_capacity(a)
      and not exists (select 1 from public.activity_participants ap
        where ap.activity_id = a.id and ap.status in ('waitlist', 'offered'));
  end if;

  if v_seat then
    begin
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
    exception when others then
      -- The ledger stands. A spot that can't be given mustn't cost Stripe's
      -- event, so the money goes back and a person looks.
      perform private.money_alert('seat_failed', 'seat-failed:' || pay.id,
        jsonb_build_object('payment', pay.id));
    end;
  end if;

  update public.activity_participants set status = 'cancelled', hold_until = null
  where activity_id = pay.activity_id and user_id = pay.user_id and status in ('reserved', 'offered')
    and not exists (select 1 from public.payments o
      where o.activity_id = pay.activity_id and o.user_id = pay.user_id
        and o.status = 'pending' and o.id <> pay.id);
  perform private.refund_issue(pay.id, v_reason);
  perform public.notify(pay.user_id, 'Your payment is coming back',
    'We couldn''t keep your spot, so everything you paid is being refunded.', '!',
    '/activities/' || pay.activity_id);
  return 'refunded';
end;
$$;

create or replace function private.refund_settled(p_refund uuid, p_status text, p_stripe_id text, p_code text)
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
  if p_status = 'succeeded' then
    if r.status in ('pending', 'processing', 'failed') then
      update public.refunds
      set status = 'succeeded', settled_at = now(), stripe_refund_id = coalesce(p_stripe_id, stripe_refund_id)
      where id = r.id;
      perform private.ledger_post('refund_paid', 'refund_paid:' || r.id || ':' || r.attempt, pay.currency,
        jsonb_build_object('refund', r.id, 'stripe', p_stripe_id),
        jsonb_build_array(private.ledger_line('refunds_pending', null, r.amount_minor),
          private.ledger_line('clearing', null, -r.amount_minor)));
      perform private.card_fee_recover(r.payment_id);
    elsif r.status in ('voided', 'manual') then
      -- We wrote this one off, and Stripe sent it anyway.
      perform private.money_alert('refund_after_close', 'refund-after-close:' || r.id,
        jsonb_build_object('refund', r.id, 'payment', r.payment_id, 'stripe', p_stripe_id));
    end if;
  elsif p_status = 'failed' then
    if r.status = 'succeeded' then
      -- It bounced after succeeding, as PayNow can: Stripe has the money back.
      perform private.ledger_post('refund_bounce', 'refund_bounce:' || r.id || ':' || r.attempt, pay.currency,
        jsonb_build_object('refund', r.id, 'stripe', p_stripe_id),
        jsonb_build_array(private.ledger_line('clearing', null, r.amount_minor),
          private.ledger_line('refunds_pending', null, -r.amount_minor)));
    end if;
    if r.status in ('pending', 'processing', 'succeeded') then
      update public.refunds
      set status = 'failed', failure_code = p_code, stripe_refund_id = coalesce(p_stripe_id, stripe_refund_id)
      where id = r.id;
      perform private.money_alert('refund_failed', 'refund-failed:' || r.id || ':' || r.attempt,
        jsonb_build_object('refund', r.id, 'payment', r.payment_id, 'code', p_code));
    end if;
  end if;
end;
$$;

create or replace function public.money_svc_event(p_event jsonb) returns text
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
  insert into public.stripe_events (id, type, payload)
  values (v_id, v_type, p_event #- '{object,card_last4}' #- '{object,card_brand}')
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
      if v_row.id is null and exists (select 1 from public.payments p
          where p.stripe_intent_id = o ->> 'payment_intent' and p.status <> 'succeeded') then
        -- Ahead of the capture. Failing here has Stripe send it again.
        raise exception 'charge.updated before capture';
      end if;
      if v_row.id is not null and (o ->> 'fee_minor') is not null then
        update public.payments set processor_fee_minor = (o ->> 'fee_minor')::bigint where id = v_row.id;
        perform private.ledger_post('processor_fee', 'processor_fee:' || v_row.id, v_row.currency,
          jsonb_build_object('payment', v_row.id),
          jsonb_build_array(private.ledger_line('processor_fees', null, (o ->> 'fee_minor')::bigint),
            private.ledger_line('clearing', null, -(o ->> 'fee_minor')::bigint)));
        perform private.card_fee_recover(v_row.id);
        v_result := 'fee';
      end if;
    when 'refund.created', 'refund.updated', 'refund.failed', 'charge.refund.updated' then
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
          jsonb_build_array(private.ledger_line('disputes_open', null, (o ->> 'amount')::bigint),
            private.ledger_line('clearing', null, -(o ->> 'amount')::bigint)));
        perform private.money_alert('dispute', 'dispute:' || (o ->> 'id'),
          jsonb_build_object('payment', v_row.id));
        v_result := 'dispute';
      end if;
    when 'charge.dispute.closed' then
      -- Won returns the money. Lost stays open for staff (Q72).
      update public.payment_disputes
      set status = case when o ->> 'status' = 'won' then 'won' else 'lost' end, closed_at = now()
      where stripe_dispute_id = o ->> 'id' and status = 'open'
      returning payment_id into v_payment;
      if found then
        select * into v_row from public.payments where id = v_payment for update;
        if o ->> 'status' = 'won' then
          perform private.ledger_post('dispute_won', 'dispute_won:' || (o ->> 'id'), v_row.currency,
            jsonb_build_object('payment', v_payment, 'dispute', o ->> 'id'),
            jsonb_build_array(private.ledger_line('clearing', null, (o ->> 'amount')::bigint),
              private.ledger_line('disputes_open', null, -(o ->> 'amount')::bigint)));
        end if;
        if v_row.refund_owed is not null then
          update public.payments set refund_owed = null where id = v_payment;
          if o ->> 'status' = 'won' then
            perform private.refund_issue(v_payment, v_row.refund_owed);
          end if;
        end if;
      end if;
      v_result := 'dispute_closed';
    when 'account.updated' then
      update public.vendors
      set status = case
            when (o ->> 'payouts_enabled')::boolean then 'verified'
            when status = 'verified' then 'pending'
            else status end,
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

create or replace function public.money_svc_work() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: service role only.
  select jsonb_build_object(
    'cancel', (select coalesce(jsonb_agg(jsonb_build_object('payment_id', p.id, 'intent', p.stripe_intent_id)), '[]')
      from (select * from public.payments where status = 'cancel_requested'
            order by created_at limit 50) p),
    'refunds', (select coalesce(jsonb_agg(jsonb_build_object('refund_id', r.id, 'intent', p.stripe_intent_id,
        'amount_minor', r.amount_minor, 'attempt', r.attempt)), '[]')
      from (select * from public.refunds where status = 'pending' order by created_at limit 50) r
      join public.payments p on p.id = r.payment_id),
    'organizer_fees', (select coalesce(jsonb_agg(jsonb_build_object('payment_id', p.id,
        'amount_minor', p.amount_minor, 'currency', p.currency, 'customer', c.stripe_customer_id,
        'payment_method', c.payment_method_id)), '[]')
      from (select * from public.payments where status = 'pending' and purpose = 'organizer_fee'
              and stripe_intent_id is null
            order by created_at limit 50) p
      left join public.payment_customers c on c.user_id = p.user_id),
    'transfers', (select coalesce(jsonb_agg(jsonb_build_object('item_id', i.id,
        'amount_minor', i.amount_minor, 'currency', r.currency, 'account', v.stripe_account_id)), '[]')
      from (select * from public.payout_items where status = 'pending' limit 50) i
      join public.payouts r on r.id = i.payout_id
      join public.vendors v on v.owner_id = i.owner_id));
$$;

do $$
declare
  d text := pg_get_functiondef('public.money_svc_result(text, uuid, boolean, text, text)'::regprocedure);
  fixed text := replace(d,
$old$    when 'organizer_fee' then$old$,
$new$    when 'refund_done' then
      -- A card refund can succeed at once, with no later update event.
      perform private.refund_settled(p_id, 'succeeded', p_ref, null);
    when 'organizer_fee' then$new$);
begin
  if fixed = d then raise exception 'money_svc_result did not change'; end if;
  execute fixed;
end;
$$;

-- Debts ------------------------------------------------------------------------

create or replace function public.organizer_debt_reserve(p_key text) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: reads the ledger.
declare
  me uuid := auth.uid();
  v_debt bigint := private.ledger_balance('organizer_fee_debt', me, 'SGD');
  pay public.payments;
begin
  select * into pay from public.payments
  where user_id = me and (idempotency_key = p_key or (purpose = 'debt' and status = 'pending'))
  order by status = 'pending' desc limit 1;
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

-- Sweeps ------------------------------------------------------------------------

-- One bad row mustn't stop everyone else's money.
create or replace function private.money_sweep() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: cron.
declare
  r record;
begin
  for r in
    select distinct a.id from public.payments p
    join public.activities a on a.id = p.activity_id
    where p.status = 'succeeded' and p.released_at is null and a.status <> 'cancelled'
      and p.purpose in ('meet', 'ticket', 'tournament', 'host_spot')
      and (now() >= a.ends_at + make_interval(hours => private.setting_int('funds.release_after_hours'))
        or (now() >= a.starts_at and private.attendance_saved(a.id)))
    order by a.id
  loop
    begin
      perform private.release_activity(r.id);
    exception when others then
      perform private.money_alert('release_failed', 'release-failed:' || r.id || ':' || now()::date,
        jsonb_build_object('activity', r.id));
    end;
  end loop;

  for r in
    select distinct p.activity_id from public.payments p
    where p.status = 'succeeded' and p.released_at is null and p.price_minor > 0
      and p.captured_at < now() - make_interval(days => private.setting_int('money.hold_alert_days'))
  loop
    perform private.money_alert('hold_aging', 'hold-aging:' || r.activity_id,
      jsonb_build_object('activity', r.activity_id));
  end loop;

  -- Refunds that have stopped moving, however that happened.
  for r in
    select id from public.refunds
    where status in ('pending', 'processing') and created_at < now() - interval '6 hours'
  loop
    perform private.money_alert('refund_stuck', 'refund-stuck:' || r.id, jsonb_build_object('refund', r.id));
  end loop;

  if private.flag('payments.enabled') and not exists (select 1 from public.reconciliation_runs x
      where x.ran_at > now() - interval '26 hours') then
    perform private.money_alert('reconcile_missing', 'reconcile-missing:' || now()::date);
  end if;
end;
$$;

create or replace function private.worker_tick(p_task text default 'work') returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: reads Vault.
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'money_worker_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'money_worker_secret';
  if v_url is null or v_secret is null then
    if private.flag('payments.enabled') then
      perform private.money_alert('worker_unconfigured', 'worker-unconfigured');
    end if;
    return;
  end if;
  perform net.http_post(v_url, jsonb_build_object('task', p_task), '{}'::jsonb,
    jsonb_build_object('content-type', 'application/json', 'x-worker-secret', v_secret));
end;
$$;

-- An open report holds that activity's money, which release already leaves
-- alone. It doesn't freeze the organizer's other earnings.
do $$
declare
  d text := pg_get_functiondef('private.payouts_prepare(text, date)'::regprocedure);
  fixed text := replace(d,
$old$    continue when exists (select 1 from public.activity_money_holds h
      join public.activities a on a.id = h.activity_id
      where h.closed_at is null and a.host_id = r.owner_id);
$old$, '');
begin
  if fixed = d then raise exception 'payouts_prepare did not change'; end if;
  execute fixed;
end;
$$;

-- Staff ---------------------------------------------------------------------

create or replace function public.staff_refund_retry(p_refund uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and the audit log.
begin
  perform private.staff_require('payments');
  update public.refunds set status = 'pending', failure_code = null, attempt = attempt + 1
  where id = p_refund and status = 'failed';
  if not found then raise exception 'Only a failed refund can be retried.'; end if;
  perform private.staff_audit('refund_retry', 'refund', p_refund::text, p_reason);
end;
$$;

create or replace function public.staff_refund_void(p_refund uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds, the ledger and the audit log.
declare
  r public.refunds;
  pay public.payments;
begin
  perform private.staff_require('payments');
  select * into r from public.refunds where id = p_refund for update;
  if r.id is null or r.status <> 'failed' then
    raise exception 'Only a failed refund can be voided.';
  end if;
  select * into pay from public.payments where id = r.payment_id for update;
  update public.refunds set status = 'voided', settled_at = now() where id = r.id;
  perform private.ledger_post('refund_void', 'refund_void:' || r.id, pay.currency,
    jsonb_build_object('refund', r.id, 'payment', pay.id),
    jsonb_build_array(private.ledger_line('refunds_pending', null, r.amount_minor),
      case when pay.released_at is null
        then private.ledger_line('held', pay.activity_id, -r.price_minor)
        else private.ledger_line('organizer', pay.organizer_id, -r.price_minor) end,
      private.ledger_line(case when pay.purpose = 'debt' then 'organizer_fee_debt' else 'platform_fees' end,
        case when pay.purpose = 'debt' then pay.user_id end, -r.fee_minor)));
  perform private.staff_audit('refund_void', 'refund', r.id::text, p_reason);
end;
$$;

create or replace function public.staff_refund_manual(p_refund uuid, p_reference text, p_reason text)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds, the ledger and the audit log.
declare
  r public.refunds;
  pay public.payments;
begin
  perform private.staff_require('payments');
  if coalesce(length(trim(p_reference)), 0) < 3 then raise exception 'Give the transfer reference.'; end if;
  select * into r from public.refunds where id = p_refund for update;
  if r.id is null or r.status <> 'failed' then
    raise exception 'Only a failed refund can be recorded as paid by hand.';
  end if;
  select * into pay from public.payments where id = r.payment_id;
  update public.refunds set status = 'manual', settled_at = now() where id = r.id;
  perform private.ledger_post('refund_paid', 'refund_paid:' || r.id || ':' || r.attempt, pay.currency,
    jsonb_build_object('refund', r.id, 'manual', true),
    jsonb_build_array(private.ledger_line('refunds_pending', null, r.amount_minor),
      private.ledger_line('clearing', null, -r.amount_minor)));
  perform private.card_fee_recover(r.payment_id);
  perform private.staff_audit('refund_manual', 'refund', r.id::text, p_reason,
    jsonb_build_object('reference', p_reference));
end;
$$;

-- Money that matched nothing, once staff have returned it in Stripe.
create function public.staff_suspense_clear(p_intent text, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the ledger and the audit log.
declare
  t public.ledger_transactions;
  v_amount bigint;
begin
  perform private.staff_require('payments');
  select * into t from public.ledger_transactions where idempotency_key = 'suspense:' || p_intent;
  if t.id is null then raise exception 'There''s nothing in suspense for that.'; end if;
  select sum(e.amount_minor) into v_amount from public.ledger_entries e
  where e.transaction_id = t.id and e.amount_minor > 0;
  if private.ledger_post('suspense_clear', 'suspense_clear:' || p_intent, t.currency,
      jsonb_build_object('intent', p_intent),
      jsonb_build_array(private.ledger_line('suspense', null, v_amount),
        private.ledger_line('clearing', null, -v_amount))) is null then
    raise exception 'This has already been cleared.';
  end if;
  update public.money_alerts set closed_at = now(), closed_by = auth.uid()
  where key = 'suspense:' || p_intent and closed_at is null;
  perform private.staff_audit('suspense_clear', 'stripe_intent', p_intent, p_reason,
    jsonb_build_object('amount_minor', v_amount));
end;
$$;
revoke execute on function public.staff_suspense_clear(text, text) from public, anon;
grant execute on function public.staff_suspense_clear(text, text) to authenticated;

create or replace function public.staff_venue_qr(p_venue uuid, p_rotate boolean default false) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: place_qr_tokens has no client access.
begin
  perform private.staff_require('content');
  if p_rotate then
    perform private.staff_audit('venue_code_rotated', 'venue', p_venue::text, 'Replaced the venue''s code');
  end if;
  return private.place_qr('venue', p_venue, p_rotate);
end;
$$;

do $$
declare
  d text := pg_get_functiondef('public.staff_money_overview()'::regprocedure);
  fixed text := replace(d, $old$'suspense_minor', -private.ledger_balance('suspense', null, 'SGD'),$old$,
    $new$'suspense_minor', -private.ledger_balance('suspense', null, 'SGD'),
    'disputes_minor', private.ledger_balance('disputes_open', null, 'SGD'),$new$);
begin
  if fixed = d then raise exception 'staff_money_overview did not change'; end if;
  execute fixed;
end;
$$;
