-- P4c-01: trials, drop-in classes and one-to-one lessons, paid in the app and
-- held until attendance, like a Meet. Monthly and term fees stay direct.

create extension if not exists btree_gist with schema extensions;

insert into public.feature_flags (key, enabled, description) values
  ('lessons.checkout', false, 'Paying for trials and lessons in the app. Needs payments.enabled too.');

insert into public.app_settings (key, value, description) values
  ('lesson.hold_minutes', '10', 'How long a lesson place is held while payment completes'),
  ('lesson.cancel_hours', '24', 'A payer can cancel for the price back up to this long before (R-REF-10)');

alter table public.academy_classes
  add column trial_price_cents int check (trial_price_cents between 1 and 1000000),
  add column dropin_price_cents int check (dropin_price_cents between 1 and 1000000);

create table public.lesson_slots (
  id uuid primary key default gen_random_uuid(),
  academy_id uuid not null references public.academies (id) on delete cascade,
  coach_id uuid not null references auth.users (id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  price_minor bigint not null check (price_minor between 1 and 1000000),
  currency text not null default 'SGD',
  venue text not null default '' check (char_length(venue) <= 80),
  status text not null default 'open' check (status in ('open', 'withdrawn')),
  created_at timestamptz not null default now(),
  check (ends_at > starts_at),
  -- A coach can only be in one place, across every academy they coach at.
  constraint lesson_slots_no_overlap exclude using gist
    (coach_id with =, tstzrange(starts_at, ends_at) with &&) where (status = 'open')
);
create index lesson_slots_academy_idx on public.lesson_slots (academy_id, starts_at);
alter table public.lesson_slots enable row level security;

-- No foreign keys: money outlives academies, classes and accounts.
create table public.lesson_bookings (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('trial', 'class', 'one_to_one')),
  academy_id uuid not null,
  academy_name text not null,
  title text not null,
  payee_id uuid not null,
  coach_id uuid,
  class_id uuid,
  slot_id uuid,
  payer_id uuid not null,
  student_id uuid not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  step text not null default 'pending' check (step in ('pending', 'paid', 'marked', 'late_cancelled',
    'reported', 'released', 'cancelled', 'expired', 'refunded')),
  attendance text check (attendance in ('present', 'absent')),
  hold_until timestamptz,
  paid_at timestamptz,
  release_at timestamptz,
  released_at timestamptz,
  cancelled_at timestamptz,
  cancelled_by text check (cancelled_by in ('payer', 'academy', 'staff')),
  cancel_reason text check (char_length(cancel_reason) <= 200),
  report_note text check (char_length(report_note) <= 500),
  idempotency_key text not null,
  created_at timestamptz not null default now(),
  unique (payer_id, idempotency_key),
  check (ends_at > starts_at),
  check ((kind = 'one_to_one') = (slot_id is not null)),
  check ((kind = 'one_to_one') = (class_id is null))
);
create unique index lesson_one_slot on public.lesson_bookings (slot_id)
  where step in ('pending', 'paid', 'marked', 'late_cancelled', 'reported', 'released');
create unique index lesson_one_seat on public.lesson_bookings (class_id, starts_at, student_id)
  where step in ('pending', 'paid', 'marked', 'late_cancelled', 'reported', 'released');
create index lesson_bookings_class_idx on public.lesson_bookings (class_id, starts_at);
create index lesson_bookings_payer_idx on public.lesson_bookings (payer_id, created_at desc);
create index lesson_bookings_student_idx on public.lesson_bookings (student_id);
create index lesson_bookings_academy_idx on public.lesson_bookings (academy_id, starts_at);
create index lesson_bookings_due_idx on public.lesson_bookings (release_at)
  where step in ('paid', 'late_cancelled');
alter table public.lesson_bookings enable row level security;

create table private.lesson_transitions (
  from_step text not null,
  to_step text not null,
  primary key (from_step, to_step)
);
insert into private.lesson_transitions values
  ('pending', 'paid'), ('pending', 'cancelled'), ('pending', 'expired'),
  ('paid', 'cancelled'), ('paid', 'late_cancelled'), ('paid', 'marked'), ('paid', 'released'),
  ('paid', 'reported'),
  ('late_cancelled', 'cancelled'), ('late_cancelled', 'released'), ('late_cancelled', 'reported'),
  ('marked', 'released'),
  ('reported', 'released'), ('reported', 'refunded'), ('reported', 'cancelled'),
  ('released', 'refunded'),
  -- A voided refund puts the money back in staff's hands.
  ('refunded', 'reported'), ('refunded', 'released'), ('cancelled', 'reported');

create function private.lesson_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then raise exception 'Lesson bookings are never deleted'; end if;
  if new.step <> old.step and not exists (select 1 from private.lesson_transitions t
      where t.from_step = old.step and t.to_step = new.step) then
    raise exception 'A lesson can''t go from % to %', old.step, new.step;
  end if;
  if (new.kind, new.academy_id, new.payee_id, new.coach_id, new.class_id, new.slot_id, new.payer_id,
      new.student_id, new.starts_at, new.ends_at, new.idempotency_key)
     is distinct from (old.kind, old.academy_id, old.payee_id, old.coach_id, old.class_id, old.slot_id,
      old.payer_id, old.student_id, old.starts_at, old.ends_at, old.idempotency_key) then
    raise exception 'A lesson''s details can''t change';
  end if;
  if old.release_at is not null and new.release_at is distinct from old.release_at then
    raise exception 'A lesson''s release time can''t change';
  end if;
  return new;
end;
$$;
create trigger lesson_bookings_guard before update or delete on public.lesson_bookings
  for each row execute function private.lesson_guard();

-- ─── Payments know about lessons ───────────────────────────────────────────

alter table public.payments add column lesson_booking_id uuid;
alter table public.payments drop column held_owner;
alter table public.payments add column held_owner uuid
  generated always as (coalesce(activity_id, order_id, lesson_booking_id)) stored;
alter table public.payments drop constraint payments_purpose_check;
alter table public.payments add constraint payments_purpose_check check (purpose in
  ('meet', 'ticket', 'tournament', 'host_spot', 'organizer_fee', 'debt', 'shop', 'lesson'));
alter table public.payments add constraint payments_one_owner
  check (num_nonnulls(activity_id, order_id, lesson_booking_id) <= 1);
create unique index payments_one_lesson on public.payments (lesson_booking_id)
  where lesson_booking_id is not null;

create or replace function private.refund_rule_text(p_purpose text) returns text
language sql immutable set search_path = '' as $$
  select case p_purpose
    when 'meet' then 'Give up your spot before the Meet starts and you get the price back, without the fee. After that, no refund. If the organizer cancels, you get everything back.'
    when 'ticket' then 'Release your tickets up to 24 hours before the start and you get the price back, without the fee. After that, no refund. If the organizer cancels, you get everything back.'
    when 'tournament' then 'Withdraw before registration closes and you get the price back, without the fee. After that, no refund. If the organizer cancels, you get everything back.'
    when 'host_spot' then 'Give up your spot before the Meet starts and you get the S$2.00 fee back.'
    when 'shop' then 'Cancel any time before you collect and you get everything back, unless a service has started. Sports equipment is final once collected.'
    when 'lesson' then 'Cancel at least 24 hours before the lesson and you get the price back, without the fee. After that, no refund. If the academy cancels, you get everything back.'
    else 'This fee isn''t refundable unless the player leaves in time.' end;
$$;

do $$
declare
  d text;
  fixed text;
begin
  -- A lesson's fee is a session's fee (R-FEE-1).
  d := pg_get_functiondef('public.money_quote(text, bigint, integer, text)'::regprocedure);
  fixed := replace(d, $old$when 'meet', 'ticket', 'tournament' then$old$, $new$when 'meet', 'ticket', 'tournament', 'lesson' then$new$);
  if fixed = d then raise exception 'money_quote did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('private.payment_guard()'::regprocedure);
  fixed := replace(replace(d, 'new.rule_snapshot, new.idempotency_key, new.order_id)',
      'new.rule_snapshot, new.idempotency_key, new.order_id, new.lesson_booking_id)'),
    'old.rule_snapshot, old.idempotency_key, old.order_id)',
    'old.rule_snapshot, old.idempotency_key, old.order_id, old.lesson_booking_id)');
  if fixed = d then raise exception 'payment_guard did not change'; end if;
  execute fixed;

  -- The booking is locked first, as everything else that touches it does.
  d := pg_get_functiondef('private.capture_succeeded(uuid, text, text, bigint, text, text)'::regprocedure);
  fixed := replace(replace(d,
    $old$  select * into was from public.payments where id = p_payment for update;$old$,
    $new$  if pay.lesson_booking_id is not null then
    perform 1 from public.lesson_bookings where id = pay.lesson_booking_id for update;
  end if;
  select * into was from public.payments where id = p_payment for update;$new$),
    $old$  if pay.purpose = 'organizer_fee' then
    -- The player left$old$,
    $new$  if pay.purpose = 'lesson' then
    return private.lesson_captured(pay, was);
  end if;
  if pay.purpose = 'organizer_fee' then
    -- The player left$new$);
  if position('lesson_captured' in fixed) = 0 or position('pay.lesson_booking_id' in fixed) = 0 then
    raise exception 'capture_succeeded did not change';
  end if;
  execute fixed;

  d := pg_get_functiondef('public.payment_abandon(uuid)'::regprocedure);
  fixed := replace(replace(d,
    $old$    perform 1 from public.orders where id = pay.order_id for update;
  end if;
  select * into pay from public.payments where id = p_payment for update;$old$,
    $new$    perform 1 from public.orders where id = pay.order_id for update;
  elsif pay.lesson_booking_id is not null then
    perform 1 from public.lesson_bookings where id = pay.lesson_booking_id for update;
  end if;
  select * into pay from public.payments where id = p_payment for update;$new$),
    $old$  elsif pay.activity_id is not null then
    update public.activity_participants set status = 'cancelled', hold_until = null$old$,
    $new$  elsif pay.lesson_booking_id is not null then
    update public.lesson_bookings set step = 'cancelled', hold_until = null, cancelled_at = now(),
      cancelled_by = 'payer', cancel_reason = 'Stopped paying'
    where id = pay.lesson_booking_id and step = 'pending';
  elsif pay.activity_id is not null then
    update public.activity_participants set status = 'cancelled', hold_until = null$new$);
  if position('Stopped paying' in fixed) = 0 or position('elsif pay.lesson_booking_id is not null then
    perform' in fixed) = 0 then
    raise exception 'payment_abandon did not change';
  end if;
  execute fixed;

  -- A dispute lost on a lesson that wasn't delivered ends the booking.
  d := pg_get_functiondef('public.money_svc_event(jsonb)'::regprocedure);
  fixed := replace(d,
    $old$        perform 1 from public.orders where id = v_row.order_id for update;
      end if;
      update public.payment_disputes$old$,
    $new$        perform 1 from public.orders where id = v_row.order_id for update;
      elsif v_row.lesson_booking_id is not null then
        perform 1 from public.lesson_bookings where id = v_row.lesson_booking_id for update;
      end if;
      update public.payment_disputes$new$);
  fixed := replace(fixed,
    $old$             or exists (select 1 from public.orders x where x.id = v_row.order_id and x.step <> 'collected')) then$old$,
    $new$             or exists (select 1 from public.orders x where x.id = v_row.order_id and x.step <> 'collected')
             or exists (select 1 from public.lesson_bookings x where x.id = v_row.lesson_booking_id and x.step <> 'marked')) then$new$);
  fixed := replace(fixed,
    $old$          update public.payments set released_at = now() where id = v_payment;
          if v_row.order_id is not null then$old$,
    $new$          update public.payments set released_at = now() where id = v_payment;
          update public.lesson_bookings set step = 'cancelled', cancelled_at = now(), cancelled_by = 'staff',
            cancel_reason = 'Card dispute lost'
          where id = v_row.lesson_booking_id and step in ('paid', 'late_cancelled', 'reported');
          if v_row.order_id is not null then$new$);
  if (length(fixed) - length(replace(fixed, 'lesson_booking', ''))) / 14 < 3 then
    raise exception 'money_svc_event did not change';
  end if;
  execute fixed;

  -- Refunds on a lesson go through staff_lesson_decide, which keeps the booking in step.
  d := pg_get_functiondef('public.staff_refund_issue(uuid, text)'::regprocedure);
  fixed := replace(d,
    $old$  if pay.purpose = 'shop' then raise exception 'Refund Shop orders by item, in Orders.'; end if;$old$,
    $new$  if pay.purpose = 'shop' then raise exception 'Refund Shop orders by item, in Orders.'; end if;
  if pay.purpose = 'lesson' then raise exception 'Refund lessons in Lessons.'; end if;$new$);
  if fixed = d then raise exception 'staff_refund_issue did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.staff_refund_void(uuid, text)'::regprocedure);
  fixed := replace(d,
    $old$    where id = pay.order_id and step = 'refunded';
  end if;$old$,
    $new$    where id = pay.order_id and step = 'refunded';
    update public.lesson_bookings set step = case when pay.released_at is null then 'reported' else 'released' end
    where id = pay.lesson_booking_id and step in ('refunded', 'cancelled');
  end if;$new$);
  if fixed = d then raise exception 'staff_refund_void did not change'; end if;
  execute fixed;

  -- Earnings count what was kept, not what was charged.
  d := pg_get_functiondef('private.payment_earned(public.payments)'::regprocedure);
  fixed := replace(d, $old$    else p.price_minor end;$old$,
    $new$    else p.price_minor - coalesce((select sum(r.price_minor) from public.refunds r
      where r.payment_id = p.id and r.status <> 'voided'), 0) end;$new$);
  if fixed = d then raise exception 'payment_earned did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.money_my_payments(integer)'::regprocedure);
  fixed := replace(replace(d,
    $old$(select m.name from public.orders o join public.malls m on m.id = o.mall_id where o.id = p.order_id)),$old$,
    $new$(select m.name from public.orders o join public.malls m on m.id = o.mall_id where o.id = p.order_id),
        (select b.title from public.lesson_bookings b where b.id = p.lesson_booking_id)),$new$),
    $old$'activity_id', p.activity_id, 'order_id', p.order_id,$old$,
    $new$'activity_id', p.activity_id, 'order_id', p.order_id, 'lesson_booking_id', p.lesson_booking_id,$new$);
  if fixed = d then raise exception 'money_my_payments did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.money_my_earnings()'::regprocedure);
  fixed := replace(d,
    $old$      group by a.id order by a.starts_at desc limit 50) y));$old$,
    $new$      group by a.id order by a.starts_at desc limit 50) y),
    'lessons', (select coalesce(jsonb_agg(x order by x ->> 'starts_at' desc), '[]') from (
      select jsonb_build_object('booking_id', b.id, 'title', b.title, 'academy', b.academy_name,
        'starts_at', b.starts_at, 'price_minor', private.payment_earned(p),
        'released', p.released_at is not null) as x
      from public.payments p join public.lesson_bookings b on b.id = p.lesson_booking_id
      where p.organizer_id = me and p.status = 'succeeded'
      order by b.starts_at desc limit 50) y));$new$);
  if fixed = d then raise exception 'money_my_earnings did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.staff_payment_list(integer)'::regprocedure);
  fixed := replace(d, $old$'activity_id', p.activity_id, 'created_at'$old$,
    $new$'activity_id', p.activity_id, 'order_id', p.order_id, 'lesson_booking_id', p.lesson_booking_id, 'created_at'$new$);
  if fixed = d then raise exception 'staff_payment_list did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.staff_payment_get(uuid)'::regprocedure);
  fixed := replace(d, $old$jsonb_build_object('activity_id', p.activity_id,$old$,
    $new$jsonb_build_object('activity_id', p.activity_id, 'order_id', p.order_id, 'lesson_booking_id', p.lesson_booking_id,$new$);
  if fixed = d then raise exception 'staff_payment_get did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.staff_held_list()'::regprocedure);
  fixed := replace(d,
    $old$      and private.ledger_balance('held', o.id, p.currency) <> 0) y);$old$,
    $new$      and private.ledger_balance('held', o.id, p.currency) <> 0
    union all
    select jsonb_build_object('lesson_booking_id', b.id, 'title', b.title, 'ends_at', b.release_at,
      'held_minor', -private.ledger_balance('held', b.id, p.currency),
      'oldest', p.captured_at, 'hold_id', null)
    from public.payments p join public.lesson_bookings b on b.id = p.lesson_booking_id
    where p.status = 'succeeded' and p.released_at is null
      and private.ledger_balance('held', b.id, p.currency) <> 0) y);$new$);
  if fixed = d then raise exception 'staff_held_list did not change'; end if;
  execute fixed;
end;
$$;

-- ─── Classes offer trials and drop-ins ─────────────────────────────────────

create or replace function private.class_taken(p_class uuid, p_at timestamptz) returns int
language sql stable security definer set search_path = '' as $$
  -- Definer: reads students and bookings.
  select ((select count(*) from public.academy_students where class_id = p_class)
    + (select count(*) from public.academy_makeups where class_id = p_class and at = p_at)
    + (select count(*) from public.lesson_bookings b where b.class_id = p_class and b.starts_at = p_at
        and b.step in ('pending', 'paid', 'marked', 'late_cancelled', 'reported', 'released')))::int;
$$;

create or replace function public.academy_class_json(p_class uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', c.id, 'academy_id', c.academy_id, 'name', c.name, 'level', c.level,
    'level_name', c.level_name, 'weekdays', c.weekdays, 'hour', c.hour,
    'minute', c.minute, 'minutes', c.minutes, 'ages', c.ages,
    'fee_cents', c.fee_cents, 'capacity', c.capacity,
    'trial_price_cents', c.trial_price_cents, 'dropin_price_cents', c.dropin_price_cents,
    'enrolled', (select count(*) from public.academy_students where class_id = c.id),
    'coach', coalesce(public.academy_user_name(c.coach_id), ''),
    'coach_id', c.coach_id, 'court', c.court,
    'week', w.week, 'term_weeks', c.term_weeks,
    'lesson', coalesce(public.academy_default_plan(a.sport) -> (w.week - 1) ->> 0, ''),
    'focus_skill', coalesce(public.academy_default_plan(a.sport) -> (w.week - 1) ->> 2, ''))
  from public.academy_classes c
  join public.academies a on a.id = c.academy_id
  cross join lateral (select public.academy_class_week(c.id) as week) w
  where c.id = p_class;
$$;

do $$
declare
  d text;
  fixed text;
begin
  d := pg_get_functiondef('public.academy_save_class(uuid, jsonb)'::regprocedure);
  fixed := replace(replace(replace(replace(d,
    $old$  v_was uuid;
begin$old$,
    $new$  v_was uuid;
  v_old public.academy_classes;
begin$new$),
    $old$    select coach_id into v_was from public.academy_classes where id = v_id and academy_id = p_academy for update;
    if not found then raise exception 'This class isn''t in your academy.'; end if;$old$,
    $new$    select * into v_old from public.academy_classes where id = v_id and academy_id = p_academy for update;
    if not found then raise exception 'This class isn''t in your academy.'; end if;
    v_was := v_old.coach_id;
    -- People have paid for this time.
    if (v_old.weekdays, v_old.hour, v_old.minute, v_old.minutes)
         is distinct from (v_days, (p->>'hour')::int, coalesce((p->>'minute')::int, 0),
           coalesce((p->>'minutes')::int, v_old.minutes))
       and exists (select 1 from public.lesson_bookings b where b.class_id = v_id and b.starts_at > now()
         and b.step in ('pending', 'paid', 'late_cancelled', 'reported')) then
      raise exception 'People have booked this class. Cancel those lessons before moving it.';
    end if;$new$),
    $old$      minutes, ages, fee_cents, capacity, coach_id, court, term_weeks)$old$,
    $new$      minutes, ages, fee_cents, capacity, coach_id, court, term_weeks, trial_price_cents, dropin_price_cents)$new$),
    $old$      coalesce(p->>'court', ''), coalesce((p->>'term_weeks')::int, 10))$old$,
    $new$      coalesce(p->>'court', ''), coalesce((p->>'term_weeks')::int, 10),
      nullif(p->>'trial_price_cents', '')::int, nullif(p->>'dropin_price_cents', '')::int)$new$);
  fixed := replace(fixed,
    $old$capacity = (p->>'capacity')::int, coach_id = v_coach, court = coalesce(p->>'court', court)$old$,
    $new$capacity = (p->>'capacity')::int, coach_id = v_coach, court = coalesce(p->>'court', court),
      trial_price_cents = case when p ? 'trial_price_cents' then nullif(p->>'trial_price_cents', '')::int else trial_price_cents end,
      dropin_price_cents = case when p ? 'dropin_price_cents' then nullif(p->>'dropin_price_cents', '')::int else dropin_price_cents end$new$);
  if position('v_old.minutes' in fixed) = 0 or position('dropin_price_cents = case' in fixed) = 0 then
    raise exception 'academy_save_class did not change';
  end if;
  execute fixed;

  -- With lessons on, a trial is booked and paid like any other lesson.
  d := pg_get_functiondef('public.academy_request(uuid, uuid, text, timestamptz)'::regprocedure);
  fixed := replace(d,
    $old$  perform private.academy_check_player(c.academy_id, p_player);$old$,
    $new$  perform private.academy_check_player(c.academy_id, p_player);
  if p_trial_at is not null and private.flag('payments.enabled') and private.flag('lessons.checkout') then
    raise exception 'Trials are booked and paid in the app.';
  end if;$new$);
  if fixed = d then raise exception 'academy_request did not change'; end if;
  execute fixed;
end;
$$;

-- ─── Booking ───────────────────────────────────────────────────────────────

-- What a lesson costs and when it runs. Raises anything that stops it.
create function private.lesson_offer(p_kind text, p_ref uuid, p_at timestamptz) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads classes, slots and licences.
declare
  c public.academy_classes;
  s public.lesson_slots;
  a public.academies;
  v_price bigint;
  v_start timestamptz := p_at;
  v_end timestamptz;
  v_coach uuid;
  v_title text;
begin
  if p_kind in ('trial', 'class') then
    select * into c from public.academy_classes where id = p_ref;
    if c.id is null then raise exception 'This class no longer runs.'; end if;
    select * into a from public.academies where id = c.academy_id;
    v_price := case p_kind when 'trial' then c.trial_price_cents else c.dropin_price_cents end;
    if v_price is null then raise exception 'This class doesn''t offer that.'; end if;
    if p_at is null or not private.class_meets_at(c, p_at) then
      raise exception 'This class doesn''t run then.';
    end if;
    if exists (select 1 from public.academy_cancellations x
        where x.class_id = c.id and x.held_on = (p_at at time zone 'Asia/Singapore')::date) then
      raise exception 'This class is cancelled that day.';
    end if;
    if c.coach_id is null then raise exception 'This class has no coach yet.'; end if;
    v_end := p_at + make_interval(mins => c.minutes);
    v_coach := c.coach_id;
    v_title := case p_kind when 'trial' then 'Trial · ' else '' end || c.name;
  elsif p_kind = 'one_to_one' then
    select * into s from public.lesson_slots where id = p_ref;
    if s.id is null or s.status <> 'open' then raise exception 'This lesson is no longer open.'; end if;
    select * into a from public.academies where id = s.academy_id;
    if not private.licence_current(s.coach_id) then raise exception 'This lesson is no longer open.'; end if;
    v_price := s.price_minor;
    v_start := s.starts_at;
    v_end := s.ends_at;
    v_coach := s.coach_id;
    v_title := 'One-to-one · ' || coalesce(public.academy_user_name(s.coach_id), 'Coach');
  else
    raise exception 'Try that again.';
  end if;
  if not private.academy_open_to_all(a) then raise exception 'This academy is no longer listed.'; end if;
  if v_start <= now() then raise exception 'This lesson has started.'; end if;
  if v_end > now() + make_interval(days => private.setting_int('money.max_advance_days')) then
    raise exception 'This lesson is too far ahead to pay for yet.';
  end if;
  return public.money_quote('lesson', v_price) || jsonb_build_object('kind', p_kind,
    'academy_id', a.id, 'academy_name', a.name, 'payee_id', a.owner_id, 'coach_id', v_coach,
    'title', v_title, 'starts_at', v_start, 'ends_at', v_end,
    'refund_rule', private.refund_rule_text('lesson'));
end;
$$;

create function public.lesson_quote(p_kind text, p_ref uuid, p_at timestamptz default null) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads classes and slots.
declare
  q jsonb := private.lesson_offer(p_kind, p_ref, p_at);
begin
  return (q - 'payee_id') || jsonb_build_object('enabled',
    private.flag('payments.enabled') and private.flag('lessons.checkout'));
end;
$$;

create function public.lesson_reserve(p_kind text, p_ref uuid, p_at timestamptz, p_student uuid,
  p_key text, p_expected_minor bigint)
returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: bookings and payments have no client write path.
declare
  me uuid := auth.uid();
  b public.lesson_bookings;
  pay public.payments;
  q jsonb;
  v_academy uuid;
  v_hold timestamptz;
begin
  if me is null then raise exception 'Sign in first.'; end if;
  if p_key is null or length(p_key) < 8 then raise exception 'Try that again.'; end if;
  if private.is_restricted(me) then raise exception 'A parent needs to do this for you.'; end if;

  select * into b from public.lesson_bookings where payer_id = me and idempotency_key = p_key;
  if b.id is not null then
    select * into pay from public.payments where lesson_booking_id = b.id;
    return private.payment_json(pay) || jsonb_build_object('result', 'reserved', 'booking_id', b.id);
  end if;

  if not (private.flag('payments.enabled') and private.flag('lessons.checkout')) then
    raise exception 'Paying for lessons isn''t open yet.';
  end if;

  -- Academy, then class or slot, so a close can't slip between.
  if p_kind = 'one_to_one' then
    select academy_id into v_academy from public.lesson_slots where id = p_ref;
  else
    select academy_id into v_academy from public.academy_classes where id = p_ref;
  end if;
  if v_academy is null then raise exception 'This lesson is no longer open.'; end if;
  perform 1 from public.academies where id = v_academy for share;
  if p_kind = 'one_to_one' then
    perform 1 from public.lesson_slots where id = p_ref for update;
  else
    perform 1 from public.academy_classes where id = p_ref for update;
  end if;

  q := private.lesson_offer(p_kind, p_ref, p_at);
  perform private.academy_check_player(v_academy, p_student);
  if not exists (select 1 from public.vendors v where v.owner_id = (q ->> 'payee_id')::uuid and v.status = 'verified') then
    raise exception 'This academy can''t take payments yet.';
  end if;
  if (q ->> 'coach_id')::uuid in (me, p_student) or (q ->> 'payee_id')::uuid = me then
    raise exception 'You can''t book your own lesson.';
  end if;

  -- One unpaid lesson at a time, so nobody can sit on every place.
  if exists (select 1 from public.lesson_bookings x where x.payer_id = me and x.step = 'pending') then
    raise exception 'Finish or cancel your unpaid lesson first.';
  end if;

  if p_kind = 'one_to_one' then
    if exists (select 1 from public.lesson_bookings x where x.slot_id = p_ref
        and x.step in ('pending', 'paid', 'marked', 'late_cancelled', 'reported', 'released')) then
      raise exception 'Someone has just booked this lesson.';
    end if;
  else
    if exists (select 1 from public.academy_students s where s.class_id = p_ref and s.player_id = p_student) then
      raise exception 'They''re already in this class.';
    end if;
    if exists (select 1 from public.lesson_bookings x where x.class_id = p_ref and x.starts_at = p_at
        and x.student_id = p_student
        and x.step in ('pending', 'paid', 'marked', 'late_cancelled', 'reported', 'released')) then
      raise exception 'They''re already booked for this class.';
    end if;
    if private.class_taken(p_ref, p_at) >= (select capacity from public.academy_classes where id = p_ref) then
      raise exception 'This class is full.';
    end if;
  end if;

  if (q ->> 'total_minor')::bigint is distinct from p_expected_minor then
    raise exception 'price_changed' using errcode = 'P0001';
  end if;

  v_hold := least(now() + make_interval(mins => private.setting_int('lesson.hold_minutes')),
    (q ->> 'starts_at')::timestamptz);
  insert into public.lesson_bookings (kind, academy_id, academy_name, title, payee_id, coach_id,
    class_id, slot_id, payer_id, student_id, starts_at, ends_at, hold_until, idempotency_key)
  values (p_kind, v_academy, q ->> 'academy_name', q ->> 'title', (q ->> 'payee_id')::uuid,
    (q ->> 'coach_id')::uuid, case when p_kind <> 'one_to_one' then p_ref end,
    case when p_kind = 'one_to_one' then p_ref end, me, p_student,
    (q ->> 'starts_at')::timestamptz, (q ->> 'ends_at')::timestamptz, v_hold, p_key)
  returning * into b;
  insert into public.payments (user_id, lesson_booking_id, purpose, price_minor, fee_minor, amount_minor,
    currency, organizer_id, beneficiary_id, rule_snapshot, idempotency_key, hold_until)
  values (me, b.id, 'lesson', (q ->> 'price_minor')::bigint, (q ->> 'fee_minor')::bigint,
    (q ->> 'total_minor')::bigint, q ->> 'currency', b.payee_id, p_student,
    q || jsonb_build_object('refund_rule', private.refund_rule_text('lesson')), p_key, v_hold)
  returning * into pay;
  return private.payment_json(pay) || jsonb_build_object('result', 'reserved', 'booking_id', b.id);
end;
$$;

-- What capture does for a lesson, with the booking and payment locked.
create function private.lesson_captured(pay public.payments, was public.payments) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: runs for the webhook.
declare
  b public.lesson_bookings;
begin
  select * into b from public.lesson_bookings where id = pay.lesson_booking_id;
  if b.step = 'pending' and was.status = 'pending' and b.starts_at > now()
     and not private.is_restricted(pay.user_id) and not private.is_suspended(pay.user_id)
     and not public.is_blocked_between(pay.user_id, b.payee_id)
     and not public.is_blocked_between(b.student_id, b.payee_id)
     and not public.is_blocked_between(pay.user_id, b.coach_id)
     and not public.is_blocked_between(b.student_id, b.coach_id) then
    update public.lesson_bookings
    set step = 'paid', paid_at = now(), hold_until = null,
        release_at = b.ends_at + make_interval(hours => private.setting_int('funds.release_after_hours'))
    where id = b.id;
    begin
      perform public.notify(pay.user_id, 'You''re booked', b.title || ' at ' || b.academy_name || '.',
        '✓', '/lessons/' || b.id, '#E3F7C8', '#2E5A00');
      perform public.notify(b.coach_id, 'New lesson booked', b.title, '★',
        '/academies/' || b.academy_id || '/lessons', '#16181B', '#C6FF00');
    exception when others then
      null;  -- An account has gone. The booking stands.
    end;
    return 'seated';
  end if;

  -- Late money never takes the place: it may be someone else's now (Q85).
  if b.step = 'pending' then
    update public.lesson_bookings set step = 'cancelled', hold_until = null, cancelled_at = now(),
      cancelled_by = 'staff', cancel_reason = 'Couldn''t be paid for' where id = b.id;
  end if;
  perform private.refund_issue(pay.id, 'late_no_spot');
  begin
    perform public.notify(pay.user_id, 'Your payment is coming back',
      'We couldn''t keep your lesson, so everything you paid is being refunded.', '!', '/lessons/' || b.id);
  exception when others then
    null;
  end;
  return 'refunded';
end;
$$;

create function private.lesson_lock(p_booking uuid) returns public.lesson_bookings
language sql security definer set search_path = '' as $$
  -- Definer: bookings have no client access.
  select * from public.lesson_bookings where id = p_booking for update;
$$;

create function private.lesson_paid_back(b public.lesson_bookings) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads disputes. The bank has already taken this back.
  select exists (select 1 from public.payment_disputes d join public.payments p on p.id = d.payment_id
    where p.lesson_booking_id = b.id and d.status = 'lost');
$$;

-- Pays the academy's owner. The step changes with the money, or not at all.
create function private.release_lesson(p_booking uuid) returns boolean
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the ledger.
declare
  pay public.payments;
  v_net bigint;
begin
  select * into pay from public.payments where lesson_booking_id = p_booking for update;
  if pay.id is null or pay.status <> 'succeeded' or pay.released_at is not null then return false; end if;
  if pay.refund_owed is not null or exists (select 1 from public.payment_disputes d
      where d.payment_id = pay.id and d.status = 'open') then
    return false;
  end if;
  select pay.price_minor - coalesce(sum(r.price_minor), 0) into v_net
  from public.refunds r where r.payment_id = pay.id and r.status <> 'voided';
  perform private.ledger_post('release', 'release:' || pay.id, pay.currency,
    jsonb_build_object('payment', pay.id, 'lesson', p_booking),
    jsonb_build_array(private.ledger_line('held', p_booking, v_net),
      private.ledger_line('organizer', pay.organizer_id, -v_net)));
  update public.payments set released_at = now() where id = pay.id;
  update public.lesson_bookings set step = 'released', released_at = now() where id = p_booking;
  return true;
end;
$$;

-- The academy, or anything that stops it teaching: everything goes back. The
-- caller holds the booking lock.
create function private.lesson_cancel_full(b public.lesson_bookings, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds.
declare
  pay public.payments;
begin
  select * into pay from public.payments where lesson_booking_id = b.id for update;
  if b.step = 'pending' then
    update public.payments set status = case when method is null then 'cancelled' else 'cancel_requested' end
    where id = pay.id and status = 'pending';
    update public.lesson_bookings set step = 'cancelled', hold_until = null, cancelled_at = now(),
      cancelled_by = 'academy', cancel_reason = left(p_reason, 200) where id = b.id;
    return;
  end if;
  if b.step not in ('paid', 'late_cancelled') then return; end if;
  update public.lesson_bookings set step = 'cancelled', cancelled_at = now(), cancelled_by = 'academy',
    cancel_reason = left(p_reason, 200) where id = b.id;
  perform private.refund_issue(pay.id, 'organizer_cancelled', 'lesson:' || b.id);
  begin
    perform public.notify(b.payer_id, b.academy_name || ' cancelled a lesson',
      'Everything you paid is coming back.', '!', '/lessons/' || b.id);
  exception when others then
    null;  -- An account has gone. The refund stands.
  end;
end;
$$;

-- Upcoming one-to-ones with a coach who can no longer teach them.
create function private.lesson_coach_gone(p_academy uuid, p_coach uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes slots and refunds.
declare
  r record;
  b public.lesson_bookings;
begin
  for r in select id from public.lesson_bookings x
    where x.coach_id = p_coach and x.kind = 'one_to_one' and x.starts_at > now()
      and (p_academy is null or x.academy_id = p_academy)
      and x.step in ('pending', 'paid', 'late_cancelled') order by id
  loop
    b := private.lesson_lock(r.id);
    perform private.lesson_cancel_full(b, p_reason);
  end loop;
  update public.lesson_slots set status = 'withdrawn'
  where coach_id = p_coach and status = 'open' and starts_at > now()
    and (p_academy is null or academy_id = p_academy);
end;
$$;

create function public.lesson_cancel(p_booking uuid, p_reason text default null) returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds.
declare
  b public.lesson_bookings := private.lesson_lock(p_booking);
  pay public.payments;
  v_refund bigint := 0;
begin
  if b.payer_id is distinct from auth.uid() then raise exception 'This lesson isn''t yours.'; end if;
  select * into pay from public.payments where lesson_booking_id = b.id;
  if b.step = 'pending' then
    perform public.payment_abandon(pay.id);
    return 0;
  end if;
  if b.step <> 'paid' then raise exception 'This lesson can''t be cancelled now.'; end if;
  if now() >= b.starts_at then raise exception 'This lesson has started.'; end if;
  if private.lesson_paid_back(b) then
    raise exception 'Your bank has this payment. Contact us about this lesson.';
  end if;
  if now() <= b.starts_at - make_interval(hours => private.setting_int('lesson.cancel_hours')) then
    update public.lesson_bookings set step = 'cancelled', cancelled_at = now(), cancelled_by = 'payer',
      cancel_reason = left(coalesce(p_reason, ''), 200) where id = b.id;
    v_refund := private.refund_issue(pay.id, 'player_in_time', 'lesson:' || b.id);
  else
    update public.lesson_bookings set step = 'late_cancelled', cancelled_at = now(), cancelled_by = 'payer',
      cancel_reason = left(coalesce(p_reason, ''), 200) where id = b.id;
  end if;
  begin
    perform public.notify(b.coach_id, 'Lesson cancelled', b.title, '!', '/academies/' || b.academy_id || '/lessons');
  exception when others then
    null;
  end;
  return v_refund;
end;
$$;

create function private.lesson_is_teacher(b public.lesson_bookings) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads coach rows.
  select public.academy_is_coach(b.academy_id) and (b.coach_id = auth.uid()
    or exists (select 1 from public.academy_coaches k
      where k.academy_id = b.academy_id and k.user_id = auth.uid() and k.head));
$$;

create function public.lesson_academy_cancel(p_booking uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds.
declare
  b public.lesson_bookings := private.lesson_lock(p_booking);
begin
  if b.id is null or not private.lesson_is_teacher(b) then raise exception 'This lesson isn''t yours.'; end if;
  if coalesce(trim(p_reason), '') = '' then raise exception 'Say why, for the parent.'; end if;
  if b.step not in ('pending', 'paid', 'late_cancelled') then
    raise exception 'This lesson can''t be cancelled now.';
  end if;
  perform private.lesson_cancel_full(b, p_reason);
end;
$$;

-- After the start, the coach says who came. Either way the money releases,
-- as with a Meet (R-HOLD-3).
create function public.lesson_mark_attendance(p_booking uuid, p_present boolean) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the ledger.
declare
  b public.lesson_bookings := private.lesson_lock(p_booking);
begin
  if b.id is null or not private.lesson_is_teacher(b) then raise exception 'This lesson isn''t yours.'; end if;
  if b.step <> 'paid' then raise exception 'This lesson has been settled.'; end if;
  if now() < b.starts_at then raise exception 'Mark attendance once the lesson starts.'; end if;
  update public.lesson_bookings set step = 'marked',
    attendance = case when p_present then 'present' else 'absent' end
  where id = b.id;
  perform private.release_lesson(b.id);
end;
$$;

-- Before release, a report keeps the money held for staff (R-HOLD-5).
create function public.lesson_report(p_booking uuid, p_note text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the booking.
declare
  b public.lesson_bookings := private.lesson_lock(p_booking);
begin
  if b.payer_id is distinct from auth.uid() then raise exception 'This lesson isn''t yours.'; end if;
  if b.step not in ('paid', 'late_cancelled') then
    raise exception 'This lesson has been settled, so contact us about it.';
  end if;
  if now() < b.starts_at then raise exception 'You can report a problem once the lesson starts.'; end if;
  if coalesce(trim(p_note), '') = '' then raise exception 'Tell us what went wrong.'; end if;
  update public.lesson_bookings set step = 'reported', report_note = left(trim(p_note), 500) where id = b.id;
  perform private.money_alert('lesson_reported', 'lesson-reported:' || b.id, jsonb_build_object('booking', b.id));
end;
$$;

create function private.lesson_json(b public.lesson_bookings) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: joins the payment and names.
  select jsonb_build_object('id', b.id, 'kind', b.kind, 'title', b.title, 'academy_id', b.academy_id,
    'academy', b.academy_name, 'coach', coalesce(public.academy_user_name(b.coach_id), ''),
    'student_id', b.student_id, 'student', coalesce(public.academy_user_name(b.student_id), ''),
    'starts_at', b.starts_at, 'ends_at', b.ends_at, 'step', b.step, 'attendance', b.attendance,
    'report_note', b.report_note, 'cancel_reason', b.cancel_reason,
    'hold_until', b.hold_until, 'payment_id', p.id, 'status', p.status,
    'price_minor', p.price_minor, 'fee_minor', p.fee_minor, 'amount_minor', p.amount_minor,
    'currency', p.currency,
    'refunded_minor', coalesce((select sum(r.amount_minor) from public.refunds r
      where r.payment_id = p.id and r.status <> 'voided'), 0),
    'free_cancel_until', b.starts_at - make_interval(hours => private.setting_int('lesson.cancel_hours')))
  from public.payments p where p.lesson_booking_id = b.id;
$$;

create function public.lesson_my() returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: bookings have no client access. The payer, the student and their parents.
  select coalesce(jsonb_agg(private.lesson_json(b) order by b.starts_at desc), '[]')
  from public.lesson_bookings b
  where b.step <> 'expired'
    and (b.payer_id = auth.uid() or b.student_id = auth.uid() or private.is_guardian_of(auth.uid(), b.student_id));
$$;

create function public.lesson_get(p_booking uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: bookings have no client access.
declare
  b public.lesson_bookings;
begin
  select * into b from public.lesson_bookings where id = p_booking;
  if b.id is null or not (b.payer_id = auth.uid() or b.student_id = auth.uid()
      or private.is_guardian_of(auth.uid(), b.student_id) or private.lesson_is_teacher(b)) then
    raise exception 'This lesson isn''t yours.';
  end if;
  return private.lesson_json(b) || jsonb_build_object('can_pay', b.payer_id = auth.uid(),
    'can_teach', private.lesson_is_teacher(b));
end;
$$;

-- A coach's lessons, or everyone's for the head coach.
create function public.lesson_academy_list(p_academy uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: bookings have no client access.
begin
  perform public.academy_require_coach(p_academy);
  return (select coalesce(jsonb_agg(private.lesson_json(b) order by b.starts_at), '[]')
    from public.lesson_bookings b
    where b.academy_id = p_academy and b.step in ('paid', 'marked', 'late_cancelled', 'reported', 'released')
      and b.starts_at > now() - interval '14 days' and private.lesson_is_teacher(b));
end;
$$;

-- ─── Slots ─────────────────────────────────────────────────────────────────

create function public.lesson_slot_add(p_academy uuid, p_starts timestamptz, p_minutes int,
  p_price_minor bigint, p_venue text)
returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: slots have no client write path.
declare
  a public.academies;
  v_id uuid;
begin
  select * into a from public.academies where id = p_academy;
  if a.id is null or not public.academy_is_coach(p_academy) then
    raise exception 'Only the academy''s coaches can do this.';
  end if;
  if not private.academy_open_to_all(a) then raise exception 'Your academy needs to be verified first.'; end if;
  if not private.licence_current(auth.uid()) then raise exception 'We need to verify your coaching licence first.'; end if;
  if p_starts is null or p_starts <= now() then raise exception 'Pick a time in the future.'; end if;
  if p_minutes is null or p_minutes not between 15 and 300 then raise exception 'Lessons run 15 minutes to 5 hours.'; end if;
  if p_price_minor is null or p_price_minor not between 1 and 1000000 then raise exception 'Set a price.'; end if;
  if p_starts + make_interval(mins => p_minutes) > now() + make_interval(days => private.setting_int('money.max_advance_days')) then
    raise exception 'That''s too far ahead.';
  end if;
  -- Two overlapping inserts at once would deadlock on the constraint.
  perform pg_advisory_xact_lock(hashtext('coach-slots:' || auth.uid()));
  begin
    insert into public.lesson_slots (academy_id, coach_id, starts_at, ends_at, price_minor, venue)
    values (p_academy, auth.uid(), p_starts, p_starts + make_interval(mins => p_minutes), p_price_minor,
      left(coalesce(trim(p_venue), ''), 80))
    returning id into v_id;
  exception when exclusion_violation then
    raise exception 'You already have a lesson then.';
  end;
  return v_id;
end;
$$;

create function public.lesson_slot_withdraw(p_slot uuid) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: slots have no client write path.
declare
  s public.lesson_slots;
begin
  select * into s from public.lesson_slots where id = p_slot for update;
  if s.id is null or not public.academy_is_coach(s.academy_id) or (s.coach_id <> auth.uid()
      and not exists (select 1 from public.academy_coaches k
        where k.academy_id = s.academy_id and k.user_id = auth.uid() and k.head)) then
    raise exception 'This lesson isn''t yours.';
  end if;
  if exists (select 1 from public.lesson_bookings b where b.slot_id = p_slot
      and b.step in ('pending', 'paid', 'late_cancelled', 'reported', 'marked')) then
    raise exception 'Someone has booked this. Cancel the lesson first.';
  end if;
  update public.lesson_slots set status = 'withdrawn' where id = p_slot;
end;
$$;

-- Open one-to-ones at an academy. Blocked coaches don't appear.
create function public.lesson_slots_open(p_academy uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: slots have no client access.
  select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'coach_id', s.coach_id,
      'coach', coalesce(public.academy_user_name(s.coach_id), ''), 'starts_at', s.starts_at, 'ends_at', s.ends_at,
      'price_minor', s.price_minor, 'currency', s.currency, 'venue', s.venue,
      'total_minor', (public.money_quote('lesson', s.price_minor) ->> 'total_minor')::bigint) order by s.starts_at), '[]')
  from public.lesson_slots s join public.academies a on a.id = s.academy_id
  where s.academy_id = p_academy and s.status = 'open' and s.starts_at > now()
    and private.academy_open_to_all(a) and private.licence_current(s.coach_id)
    and not public.is_blocked_between(auth.uid(), s.coach_id)
    and not exists (select 1 from public.lesson_bookings b where b.slot_id = s.id
      and b.step in ('pending', 'paid', 'marked', 'late_cancelled', 'reported', 'released'));
$$;

create function public.lesson_slots_mine(p_academy uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: slots have no client access.
begin
  if not public.academy_is_coach(p_academy) then raise exception 'Only the academy''s coaches can do this.'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'starts_at', s.starts_at, 'ends_at', s.ends_at,
      'price_minor', s.price_minor, 'currency', s.currency, 'venue', s.venue,
      'booked', exists (select 1 from public.lesson_bookings b where b.slot_id = s.id
        and b.step in ('pending', 'paid', 'marked', 'late_cancelled', 'reported', 'released'))) order by s.starts_at), '[]')
    from public.lesson_slots s
    where s.academy_id = p_academy and s.coach_id = auth.uid() and s.status = 'open' and s.ends_at > now());
end;
$$;

-- ─── The sweep ─────────────────────────────────────────────────────────────

create function private.lessons_sweep() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: cron.
declare
  r record;
  b public.lesson_bookings;
begin
  for r in select id from public.lesson_bookings where step = 'pending' and hold_until <= now() order by id loop
    begin
      b := private.lesson_lock(r.id);
      if b.step = 'pending' and b.hold_until <= now() then
        update public.lesson_bookings set step = 'expired', hold_until = null where id = b.id;
        update public.payments
        set status = case when method is null then 'cancelled' else 'cancel_requested' end,
            cancel_reason = 'expired'
        where lesson_booking_id = b.id and status = 'pending';
      end if;
    exception when others then
      perform private.money_alert('lesson_sweep_failed', 'lesson-sweep:' || r.id || ':' || now()::date,
        jsonb_build_object('booking', r.id));
    end;
  end loop;

  -- Never marked, or cancelled too late: 24 hours after the end (R-HOLD-2).
  -- Marked while a dispute was open: pay out now it's over.
  for r in select x.id from public.lesson_bookings x
    where (x.step in ('paid', 'late_cancelled') and x.release_at <= now()) or x.step = 'marked'
    order by x.id
  loop
    begin
      b := private.lesson_lock(r.id);
      if b.step = 'marked' or (b.step in ('paid', 'late_cancelled') and b.release_at <= now()) then
        perform private.release_lesson(b.id);
      end if;
    exception when others then
      perform private.money_alert('lesson_sweep_failed', 'lesson-sweep:' || r.id || ':' || now()::date,
        jsonb_build_object('booking', r.id));
    end;
  end loop;
end;
$$;

select cron.schedule('lessons-sweep', '* * * * *', 'select private.lessons_sweep()');

-- ─── Things that end lessons ───────────────────────────────────────────────

do $$
declare
  d text;
  fixed text;
begin
  d := pg_get_functiondef('public.academy_set_coach(uuid, text, boolean)'::regprocedure);
  fixed := replace(d,
    $old$    delete from public.academy_coaches where academy_id = p_academy and user_id = v_user and not head;
$old$,
    $new$    delete from public.academy_coaches where academy_id = p_academy and user_id = v_user and not head;
    if found then
      perform private.lesson_coach_gone(p_academy, v_user, 'Your coach has left the academy');
    end if;
$new$);
  if fixed = d then raise exception 'academy_set_coach did not change'; end if;
  execute fixed;

  -- Everything still to come goes back. What's been taught is still paid.
  d := pg_get_functiondef('public.academy_close(uuid)'::regprocedure);
  fixed := replace(replace(d,
    $old$  update public.academies set closed_at = now() where id = p_academy and closed_at is null
  returning name into v_name;$old$,
    $new$  update public.academies set closed_at = now() where id = p_academy and closed_at is null
  returning name into v_name;
  update public.lesson_slots set status = 'withdrawn' where academy_id = p_academy and status = 'open';
  for b in select * from public.lesson_bookings x
    where x.academy_id = p_academy and x.starts_at > now() and x.step in ('pending', 'paid', 'late_cancelled')
    order by x.id
  loop
    b := private.lesson_lock(b.id);
    perform private.lesson_cancel_full(b, 'The academy has closed');
  end loop;$new$),
    $old$  v_name text;
begin$old$,
    $new$  v_name text;
  b public.lesson_bookings;
begin$new$);
  if position('lesson_cancel_full' in fixed) = 0 or position('b public.lesson_bookings' in fixed) = 0 then
    raise exception 'academy_close did not change';
  end if;
  execute fixed;

  -- A class called off takes that day's paid lessons with it. Anyone who paid
  -- for the class also hears about a change.
  d := pg_get_functiondef('public.academy_change_class(uuid, text, text, uuid)'::regprocedure);
  fixed := replace(replace(replace(d,
    $old$  v_on date;
begin$old$,
    $new$  v_on date;
  b public.lesson_bookings;
begin$new$),
    $old$      from public.academy_students s where s.class_id = p_class;
    end if;
  end if;$old$,
    $new$      from public.academy_students s where s.class_id = p_class;
    end if;
    for b in select * from public.lesson_bookings x where x.class_id = p_class
        and (x.starts_at at time zone 'Asia/Singapore')::date = v_on
        and x.step in ('pending', 'paid', 'late_cancelled') order by x.id
    loop
      b := private.lesson_lock(b.id);
      perform private.lesson_cancel_full(b, left(trim(p_notice), 200));
    end loop;
  end if;$new$),
    $old$  select array_agg(distinct parent_id) into v_parents from public.academy_students where class_id = p_class;$old$,
    $new$  select array_agg(distinct x) into v_parents from (
    select parent_id as x from public.academy_students where class_id = p_class
    union
    select payer_id from public.lesson_bookings where class_id = p_class and starts_at > now() and step = 'paid') y;$new$);
  if position('lesson_cancel_full' in fixed) = 0 or position('union' in fixed) = 0 then
    raise exception 'academy_change_class did not change';
  end if;
  execute fixed;

  -- A licence refused ends that coach's upcoming one-to-ones, everywhere.
  d := pg_get_functiondef('public.staff_licence_decide(uuid, boolean, text)'::regprocedure);
  fixed := replace(d,
    $old$  perform public.notify(p_user,
    case when p_approve then 'Your coaching licence is verified'$old$,
    $new$  if not p_approve then
    perform private.lesson_coach_gone(null, p_user, 'Your coach can''t teach this lesson');
  end if;
  perform public.notify(p_user,
    case when p_approve then 'Your coaching licence is verified'$new$);
  if fixed = d then raise exception 'staff_licence_decide did not change'; end if;
  execute fixed;
end;
$$;

-- ─── Staff ─────────────────────────────────────────────────────────────────

create function public.staff_lesson_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff read every lesson. Reports first, then what's held.
begin
  perform private.staff_require('payments');
  return (select coalesce(jsonb_agg(x), '[]') from (
    select private.lesson_json(b) as x from public.lesson_bookings b
    where b.step in ('reported', 'paid', 'marked', 'late_cancelled', 'released', 'refunded')
    order by b.step <> 'reported', b.starts_at desc limit 200) y);
end;
$$;

-- Reported lessons, and released ones where a person decides they weren't
-- delivered (Q93). The only way to refund a lesson, so step and money stay together.
create function public.staff_lesson_decide(p_booking uuid, p_refund boolean, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and the audit log.
declare
  b public.lesson_bookings;
  pay public.payments;
begin
  perform private.staff_require('payments');
  b := private.lesson_lock(p_booking);
  if b.id is null then raise exception 'Not found.' using errcode = 'P0001'; end if;
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  select * into pay from public.payments where lesson_booking_id = b.id for update;
  if p_refund then
    if b.step not in ('reported', 'released') then raise exception 'This lesson can''t be refunded now.'; end if;
    update public.lesson_bookings set step = 'refunded' where id = b.id;
    perform private.refund_issue(pay.id, 'staff', 'lesson-staff:' || b.id || ':' || gen_random_uuid(), null, auth.uid());
  else
    if b.step <> 'reported' then raise exception 'There''s no report on this lesson.'; end if;
    if not private.release_lesson(b.id) then
      raise exception 'A dispute is open on this payment, so it can''t be released yet.';
    end if;
  end if;
  begin
    perform public.notify(b.payer_id, 'We''ve looked at your lesson',
      case when p_refund then 'Your money is coming back.' else 'The payment has gone to the academy.' end,
      '!', '/lessons/' || b.id);
  exception when others then
    null;
  end;
  perform private.staff_audit('lesson_decided', 'lesson', b.id::text, p_reason,
    jsonb_build_object('refund', p_refund));
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'lesson_quote(text, uuid, timestamptz)',
    'lesson_reserve(text, uuid, timestamptz, uuid, text, bigint)',
    'lesson_cancel(uuid, text)', 'lesson_academy_cancel(uuid, text)',
    'lesson_mark_attendance(uuid, boolean)', 'lesson_report(uuid, text)',
    'lesson_my()', 'lesson_get(uuid)', 'lesson_academy_list(uuid)',
    'lesson_slot_add(uuid, timestamptz, integer, bigint, text)', 'lesson_slot_withdraw(uuid)',
    'lesson_slots_open(uuid)', 'lesson_slots_mine(uuid)',
    'staff_lesson_list()', 'staff_lesson_decide(uuid, boolean, text)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;
