-- P4c second review. Tests in 45_academy_review_test.sql.

insert into public.app_settings (key, value, description) values
  ('academy.creates_per_day', '5', 'Academies one person can start in a day');

-- A lesson that wasn't taught, whose money is still owed back. Set whenever
-- a person has to finish a refund, so it can't be paid to the academy instead.
alter table public.lesson_bookings add column owes_payer boolean not null default false;

create or replace function private.lesson_cancel_full(b public.lesson_bookings, p_reason text) returns void
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
  -- The bank has part of this, so a person works out what's left to send back.
  if private.lesson_paid_back(b) then
    update public.lesson_bookings set step = 'reported', owes_payer = true, cancelled_at = now(),
      cancelled_by = 'academy', cancel_reason = left(p_reason, 200)
    where id = b.id;
    perform private.money_alert('lesson_reported', 'lesson-reported:' || b.id, jsonb_build_object('booking', b.id));
    begin
      perform public.notify(b.payer_id, b.academy_name || ' cancelled a lesson',
        'Your bank has part of this payment, so our team will sort out the rest.', '!', '/lessons/' || b.id);
    exception when others then
      null;
    end;
    return;
  end if;
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

-- Staff send back what's left, never more: what a voided refund was for, less
-- anything the bank already returned.
create or replace function public.staff_lesson_decide(p_booking uuid, p_refund boolean, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and the audit log.
declare
  b public.lesson_bookings;
  pay public.payments;
  v_lost bigint;
  v_left bigint;
  v_price bigint;
  v_fee bigint;
  v_rest bigint;
  v_dispute text;
begin
  perform private.staff_require('payments');
  b := private.lesson_lock(p_booking);
  if b.id is null then raise exception 'Not found.' using errcode = 'P0001'; end if;
  if coalesce(trim(p_reason), '') = '' then raise exception 'Give a reason.'; end if;
  select * into pay from public.payments where lesson_booking_id = b.id for update;
  if p_refund then
    if b.step not in ('reported', 'released') then raise exception 'This lesson can''t be refunded now.'; end if;
    select coalesce(sum(d.amount_minor), 0), min(d.stripe_dispute_id) into v_lost, v_dispute
    from public.payment_disputes d where d.payment_id = pay.id and d.status = 'lost';
    v_left := pay.amount_minor - v_lost - (select coalesce(sum(r.amount_minor), 0) from public.refunds r
      where r.payment_id = pay.id and r.status <> 'voided');
    if v_left <= 0 then
      raise exception 'The bank has returned money on this payment. Work it out in Payments.';
    end if;
    select r.price_minor, r.fee_minor into v_price, v_fee from public.refunds r
    where r.payment_id = pay.id and r.status = 'voided' order by r.created_at desc limit 1;
    v_price := least(coalesce(v_price, pay.price_minor), v_left);
    v_fee := least(coalesce(v_fee, pay.fee_minor), v_left - v_price);
    update public.lesson_bookings set step = 'refunded', owes_payer = false where id = b.id;
    perform private.refund_issue(pay.id, 'staff', 'lesson-staff:' || b.id || ':' || gen_random_uuid(),
      v_price, auth.uid(), v_fee);
    -- What the bank took comes out of the held price first, then the fee, so
    -- nothing sits in held for ever.
    v_rest := pay.price_minor - v_price;
    if v_lost > 0 and pay.released_at is null then
      perform private.ledger_post('dispute_lost', 'dispute_lost:' || v_dispute, pay.currency,
        jsonb_build_object('payment', pay.id, 'dispute', v_dispute),
        jsonb_build_array(private.ledger_line('held', b.id, v_rest),
          private.ledger_line('platform_fees', null, v_lost - v_rest),
          private.ledger_line('disputes_open', null, -v_lost)));
      update public.payments set released_at = now() where id = pay.id;
    end if;
  else
    if b.step <> 'reported' then raise exception 'There''s no report on this lesson.'; end if;
    if b.owes_payer then raise exception 'This lesson wasn''t taught, so the money goes back.'; end if;
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
  d text;
  fixed text;
begin
  -- A void puts the money back in staff's hands, and marks whose it is.
  d := pg_get_functiondef('public.staff_refund_void(uuid, text)'::regprocedure);
  fixed := replace(d,
    $old$update public.lesson_bookings set step = case when pay.released_at is null then 'reported' else 'released' end
    where id = pay.lesson_booking_id and step in ('refunded', 'cancelled', 'expired');$old$,
    $new$update public.lesson_bookings set step = case when pay.released_at is null then 'reported' else 'released' end,
      owes_payer = pay.released_at is null
    where id = pay.lesson_booking_id and step in ('refunded', 'cancelled', 'expired');$new$);
  if fixed = d then raise exception 'staff_refund_void did not change'; end if;
  execute fixed;

  -- A refund queued against a dispute that's only partly lost goes to staff,
  -- on a lesson: the whole amount is no longer owed.
  d := pg_get_functiondef('public.money_svc_event(jsonb)'::regprocedure);
  fixed := replace(d,
    $old$          if o ->> 'status' in ('won', 'warning_closed') or (o ->> 'amount')::bigint <> v_row.amount_minor then
            for v_owed, v_index in$old$,
    $new$          if v_row.lesson_booking_id is not null and o ->> 'status' not in ('won', 'warning_closed')
             and (o ->> 'amount')::bigint <> v_row.amount_minor then
            update public.lesson_bookings set step = 'reported', owes_payer = true
            where id = v_row.lesson_booking_id and step in ('cancelled', 'refunded');
          elsif o ->> 'status' in ('won', 'warning_closed') or (o ->> 'amount')::bigint <> v_row.amount_minor then
            for v_owed, v_index in$new$);
  if fixed = d then raise exception 'money_svc_event did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('private.lesson_json(public.lesson_bookings)'::regprocedure);
  fixed := replace(d, $old$'report_note', b.report_note, 'cancel_reason', b.cancel_reason,$old$,
    $new$'report_note', b.report_note, 'cancel_reason', b.cancel_reason, 'owes_payer', b.owes_payer,$new$);
  if fixed = d then raise exception 'lesson_json did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.academy_class_slots(uuid, text)'::regprocedure);
  fixed := replace(d, $old$  where private.academy_visible(a) and c.coach_id is not null
$old$,
    $new$  where private.academy_open_to_all(a) and private.licence_current(c.coach_id)
    and not private.is_suspended(c.coach_id) and not private.is_suspended(a.owner_id)
$new$);
  if fixed = d then raise exception 'academy_class_slots did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.academy_create(jsonb)'::regprocedure);
  fixed := replace(d, $old$  if jsonb_array_length(coalesce(p->'coaches', '[]')) > 20 then$old$,
    $new$  if not private.rate_hit('academy-create', v_me::text, private.setting_int('academy.creates_per_day'), 86400) then
    raise exception 'You''ve started a lot of academies today. Try again tomorrow.';
  end if;
  if jsonb_array_length(coalesce(p->'coaches', '[]')) > 20 then$new$);
  if fixed = d then raise exception 'academy_create did not change'; end if;
  execute fixed;
end;
$$;

-- ─── An emailed invitation shows nothing until it's answered ───────────────

alter table public.academy_coaches add column by_email boolean not null default false;

-- The invitation stays listed as an email until they say yes, whoever they are,
-- so looking at the list never shows who has an account.
create or replace function public.academy_claim_invites() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes coach rows.
declare
  v_me uuid := (select auth.uid());
  v_email text := (select email from public.account_private where id = (select auth.uid()) and email_verified_at is not null);
begin
  if v_email is null or private.is_minor(v_me) then return; end if;
  insert into public.academy_coaches (academy_id, user_id, by_email)
  select i.academy_id, v_me, true from public.academy_coach_invites i
  join public.academies a on a.id = i.academy_id
  where i.email = v_email and a.closed_at is null and not public.is_blocked_between(v_me, a.owner_id)
  on conflict do nothing;
end;
$$;

do $$
declare
  d text;
  fixed text;
begin
  d := pg_get_functiondef('public.academy_coach_answer(uuid, boolean)'::regprocedure);
  fixed := replace(d, $old$  if not found then raise exception 'This invitation has ended.'; end if;
$old$,
    $new$  if not found then raise exception 'This invitation has ended.'; end if;
  delete from public.academy_coach_invites where academy_id = p_academy
    and email = (select a.email from public.account_private a where a.id = me);
$new$);
  if fixed = d then raise exception 'academy_coach_answer did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.academy_json(uuid)'::regprocedure);
  fixed := replace(d, $old$from public.academy_coaches k where k.academy_id = a.id and k.accepted_at is null)$old$,
    $new$from public.academy_coaches k where k.academy_id = a.id and k.accepted_at is null and not k.by_email)$new$);
  if fixed = d then raise exception 'academy_json did not change'; end if;
  execute fixed;
end;
$$;

-- ─── Files under review can't be swapped ───────────────────────────────────

create function private.doc_in_use(p_path text) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: called from a storage policy on tables the caller can't read.
  select exists (select 1 from public.coach_licences l
      where l.file_path = p_path and l.status in ('submitted', 'verified'))
    or exists (select 1 from public.academies a
      where a.licence_path = p_path and a.verification in ('submitted', 'verified'));
$$;

drop policy "Owners replace their own verification files" on storage.objects;
create policy "Owners replace their own verification files" on storage.objects
  for update to authenticated
  using (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = (select auth.uid())::text
    and not private.doc_in_use(name))
  with check (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = (select auth.uid())::text
    and storage.filename(name) ~ '^(licence|business-[0-9a-f-]{36})\.(jpg|pdf)$'
    and not private.doc_in_use(name)
    and not private.is_restricted((select auth.uid()))
    and not private.is_suspended((select auth.uid()))
    and not private.is_minor((select auth.uid())));
