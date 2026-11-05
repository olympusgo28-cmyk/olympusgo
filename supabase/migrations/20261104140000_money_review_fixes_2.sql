-- P4a review: the second pass over the first set of fixes.

-- What a dispute held up, in amounts, so winning pays exactly that.
alter table public.payments alter column refund_owed type jsonb using null;

alter table public.refunds drop constraint refunds_status_check;
alter table public.refunds add constraint refunds_status_check
  check (status in ('pending', 'processing', 'succeeded', 'failed', 'voided', 'manual'));

create or replace function private.refund_issue(p_payment uuid, p_reason text, p_key text default null,
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

  -- An open dispute may yet take this money back, so the refund waits for it,
  -- for exactly this amount.
  if exists (select 1 from public.payment_disputes d
      where d.payment_id = pay.id and d.status = 'open') then
    update public.payments
    set refund_owed = coalesce(refund_owed, '[]'::jsonb) || jsonb_build_array(jsonb_build_object(
      'reason', p_reason, 'price', v_price, 'fee', v_fee))
    where id = pay.id;
    perform private.money_alert('refund_blocked_by_dispute', 'dispute-refund:' || pay.id,
      jsonb_build_object('payment', pay.id));
    return 0;
  end if;

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

-- Stripe's events can arrive in any order. Each carries the attempt it belongs
-- to, so a late answer about an old attempt never changes the current one.
drop function private.refund_settled(uuid, text, text, text);
create function private.refund_settled(p_refund uuid, p_status text, p_stripe_id text, p_code text,
  p_attempt integer default null)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the ledger.
declare
  r public.refunds;
  pay public.payments;
  v_paid boolean;
begin
  select * into r from public.refunds where id = p_refund for update;
  if r.id is null then
    perform private.money_alert('refund_unknown', 'refund-unknown:' || coalesce(p_stripe_id, p_refund::text));
    return;
  end if;
  select * into pay from public.payments where id = r.payment_id;

  if p_attempt is not null and p_attempt < r.attempt then
    if p_status = 'succeeded' then
      perform private.money_alert('refund_old_attempt', 'refund-old:' || r.id || ':' || p_attempt,
        jsonb_build_object('refund', r.id, 'attempt', p_attempt, 'stripe', p_stripe_id));
    end if;
    return;
  end if;

  v_paid := exists (select 1 from public.ledger_transactions t
    where t.idempotency_key = 'refund_paid:' || r.id || ':' || r.attempt);

  if p_status = 'succeeded' then
    if r.status in ('voided', 'manual') then
      -- We wrote this one off, and Stripe sent it anyway.
      perform private.money_alert('refund_after_close', 'refund-after-close:' || r.id,
        jsonb_build_object('refund', r.id, 'payment', r.payment_id, 'stripe', p_stripe_id));
    elsif r.status in ('pending', 'processing') or (r.status = 'failed' and not v_paid) then
      update public.refunds
      set status = 'succeeded', settled_at = now(), stripe_refund_id = coalesce(p_stripe_id, stripe_refund_id)
      where id = r.id;
      perform private.ledger_post('refund_paid', 'refund_paid:' || r.id || ':' || r.attempt, pay.currency,
        jsonb_build_object('refund', r.id, 'stripe', p_stripe_id),
        jsonb_build_array(private.ledger_line('refunds_pending', null, r.amount_minor),
          private.ledger_line('clearing', null, -r.amount_minor)));
      perform private.card_fee_recover(r.payment_id);
    end if;
    -- Failed after being paid means this success is the older of the two.
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
revoke execute on function private.refund_settled(uuid, text, text, text, integer)
  from public, anon, authenticated;

do $$
declare
  d text := pg_get_functiondef('public.money_svc_event(jsonb)'::regprocedure);
  fixed text := d;
  old1 text :=
$old$      if o ->> 'status' in ('succeeded', 'failed') then
        perform private.refund_settled(nullif(o #>> '{metadata,refund_id}', '')::uuid, o ->> 'status',
          o ->> 'id', o ->> 'failure_reason');
        v_result := o ->> 'status';
      end if;$old$;
  new1 text :=
$new$      if o ->> 'status' in ('succeeded', 'failed', 'canceled') then
        perform private.refund_settled(nullif(o #>> '{metadata,refund_id}', '')::uuid,
          case when o ->> 'status' = 'canceled' then 'failed' else o ->> 'status' end,
          o ->> 'id', o ->> 'failure_reason', nullif(o #>> '{metadata,attempt}', '')::int);
        v_result := o ->> 'status';
      end if;$new$;
  old2 text :=
$old$        if v_row.refund_owed is not null then
          update public.payments set refund_owed = null where id = v_payment;
          if o ->> 'status' = 'won' then
            perform private.refund_issue(v_payment, v_row.refund_owed);
          end if;
        end if;$old$;
  new2 text :=
$new$        if v_row.refund_owed is not null then
          update public.payments set refund_owed = null where id = v_payment;
          if o ->> 'status' = 'won' then
            for v_owed, v_index in
              select x, ordinality from jsonb_array_elements(v_row.refund_owed) with ordinality t(x, ordinality)
            loop
              perform private.refund_issue(v_payment, v_owed ->> 'reason',
                'owed:' || v_payment || ':' || (o ->> 'id') || ':' || v_index, (v_owed ->> 'price')::bigint,
                null, (v_owed ->> 'fee')::bigint);
            end loop;
          end if;
        end if;
        -- The chargeback returned what a cancelled Meet still owed, so there's
        -- nothing left to hold.
        if o ->> 'status' <> 'won' and v_row.released_at is null and (select a.status = 'cancelled'
            from public.activities a where a.id = v_row.activity_id) then
          perform private.ledger_post('dispute_lost', 'dispute_lost:' || (o ->> 'id'), v_row.currency,
            jsonb_build_object('payment', v_payment, 'dispute', o ->> 'id'),
            jsonb_build_array(
              private.ledger_line('held', v_row.activity_id, v_row.price_minor),
              private.ledger_line('platform_fees', null, v_row.fee_minor),
              private.ledger_line('disputes_open', null, -v_row.amount_minor)));
          update public.payments set released_at = now() where id = v_payment;
        end if;$new$;
begin
  if position(old1 in d) = 0 or position(old2 in d) = 0 then
    raise exception 'money_svc_event did not change';
  end if;
  fixed := replace(replace(d, old1, new1), old2, new2);
  fixed := replace(fixed, E'  v_row public.payments;\nbegin', E'  v_row public.payments;\n  v_owed jsonb;\n  v_index bigint;\nbegin');
  execute fixed;
end;
$$;

-- Capture: three corners the first pass missed.
do $$
declare
  d text := pg_get_functiondef('private.capture_succeeded(uuid, text, text, bigint, text, text)'::regprocedure);
  fixed text := d;
  old1 text :=
$old$  elsif v_spot in ('joined', 'reserved') then
    -- Paid another way in the meantime.
    v_seat := false;$old$;
  new1 text :=
$new$  elsif v_spot = 'joined' or exists (select 1 from public.payments o
      where o.activity_id = pay.activity_id and o.user_id = pay.user_id
        and o.status = 'pending' and o.id <> pay.id) then
    -- Paid another way in the meantime.
    v_seat := false;$new$;
  old2 text :=
$old$          set status = 'joined', hold_until = null, queue_seq = null;$old$;
  new2 text :=
$new$          set status = 'joined', hold_until = null, queue_seq = null,
              -- A guest from an abandoned try wasn't paid for here.
              guest_name = case when pay.qty = 1 then null else public.activity_participants.guest_name end,
              guest_level = case when pay.qty = 1 then null else public.activity_participants.guest_level end;$new$;
  old3 text :=
$old$  update public.activity_participants set status = 'cancelled', hold_until = null
  where activity_id = pay.activity_id and user_id = pay.user_id and status in ('reserved', 'offered')
    and not exists (select 1 from public.payments o
      where o.activity_id = pay.activity_id and o.user_id = pay.user_id
        and o.status = 'pending' and o.id <> pay.id);
  perform private.refund_issue(pay.id, v_reason);
  perform public.notify(pay.user_id, 'Your payment is coming back',
    'We couldn''t keep your spot, so everything you paid is being refunded.', '!',
    '/activities/' || pay.activity_id);
  return 'refunded';$old$;
  new3 text :=
$new$  -- An offer stays theirs: only a hold this payment made goes with it.
  update public.activity_participants set status = 'cancelled', hold_until = null
  where activity_id = pay.activity_id and user_id = pay.user_id and status = 'reserved'
    and not exists (select 1 from public.payments o
      where o.activity_id = pay.activity_id and o.user_id = pay.user_id
        and o.status = 'pending' and o.id <> pay.id);
  if found then
    perform private.promote_waitlist(pay.activity_id);
  end if;
  perform private.refund_issue(pay.id, v_reason);
  begin
    perform public.notify(pay.user_id, 'Your payment is coming back',
      'We couldn''t keep your spot, so everything you paid is being refunded.', '!',
      '/activities/' || pay.activity_id);
  exception when others then
    null;  -- The account has gone. The refund stands.
  end;
  return 'refunded';$new$;
begin
  if position(old1 in d) = 0 or position(old2 in d) = 0 or position(old3 in d) = 0 then
    raise exception 'capture_succeeded did not change';
  end if;
  fixed := replace(replace(replace(d, old1, new1), old2, new2), old3, new3);
  execute fixed;
end;
$$;

-- Someone who has already left has nothing more to collect.
do $$
declare
  d text := pg_get_functiondef('public.leave_activity(uuid)'::regprocedure);
  fixed text := replace(d,
$old$  v_refund := private.leave_money(a, me);$old$,
$new$  if not exists (select 1 from public.activity_participants ap
        where ap.activity_id = activity and ap.user_id = me
          and ap.status in ('joined', 'reserved', 'offered', 'waitlist', 'requested'))
     and not exists (select 1 from public.payments p
        where p.activity_id = activity and p.user_id = me and p.status = 'pending') then
    return 0;
  end if;
  v_refund := private.leave_money(a, me);$new$);
begin
  if fixed = d then raise exception 'leave_activity did not change'; end if;
  execute fixed;
end;
$$;

-- A bounced attempt has already used its refund_paid key.
do $$
declare
  d text := pg_get_functiondef('public.staff_refund_manual(uuid, text, text)'::regprocedure);
  fixed text := replace(d, $old$'refund_paid:' || r.id || ':' || r.attempt$old$, $new$'refund_manual:' || r.id$new$);
begin
  if fixed = d then raise exception 'staff_refund_manual did not change'; end if;
  execute fixed;
end;
$$;

-- What staff can do when Stripe's answer never arrives: look in Stripe, then
-- record what it says. A retry needs the refund marked failed first.
create function public.staff_refund_settle(p_refund uuid, p_status text, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds, the ledger and the audit log.
begin
  perform private.staff_require('payments');
  if p_status not in ('succeeded', 'failed') then raise exception 'Choose what Stripe says.'; end if;
  if not exists (select 1 from public.refunds r where r.id = p_refund and r.status = 'processing') then
    raise exception 'Only a refund waiting on Stripe can be settled by hand.';
  end if;
  perform private.refund_settled(p_refund, p_status, null, 'staff_checked');
  perform private.staff_audit('refund_settle', 'refund', p_refund::text, p_reason,
    jsonb_build_object('status', p_status));
end;
$$;
revoke execute on function public.staff_refund_settle(uuid, text, text) from public, anon;
grant execute on function public.staff_refund_settle(uuid, text, text) to authenticated;

-- A lease belongs to whoever took it, so a slow worker can't clear the next one's.
drop function public.money_svc_lease(integer);
alter table private.worker_lease add column token uuid;
create function public.money_svc_lease(p_seconds integer, p_token uuid default null) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only.
declare
  v_token uuid := gen_random_uuid();
begin
  if p_seconds = 0 then
    update private.worker_lease set until = now(), token = null where id and token = p_token;
    return p_token;
  end if;
  update private.worker_lease
  set until = now() + make_interval(secs => p_seconds), token = v_token
  where id and until <= now();
  return case when found then v_token end;
end;
$$;
revoke execute on function public.money_svc_lease(integer, uuid) from public, anon, authenticated;
grant execute on function public.money_svc_lease(integer, uuid) to service_role;

do $$
declare
  d text := pg_get_functiondef('public.money_svc_result(text, uuid, boolean, text, text)'::regprocedure);
begin
  if position('private.refund_settled' in d) = 0 then
    raise exception 'money_svc_result lost its settle call';
  end if;
end;
$$;
