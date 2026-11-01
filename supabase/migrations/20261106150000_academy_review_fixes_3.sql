-- P4c last review. Tests in 45_academy_review_test.sql.

do $$
declare
  d text;
  fixed text;
begin
  -- A failed refund after a part-lost dispute comes back to staff, and the
  -- money it left behind is OlympusGO's to send, not the academy's.
  d := pg_get_functiondef('public.staff_refund_void(uuid, text)'::regprocedure);
  fixed := replace(d,
    $old$  perform private.ledger_post('refund_void', 'refund_void:' || r.id, pay.currency,$old$,
    $new$  if v_gone then
    update public.lesson_bookings set step = 'reported', owes_payer = true
    where id = pay.lesson_booking_id and step = 'refunded';
  end if;
  perform private.ledger_post('refund_void', 'refund_void:' || r.id, pay.currency,$new$);
  if fixed = d then raise exception 'staff_refund_void did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('private.refund_issue(uuid, text, text, bigint, uuid, bigint)'::regprocedure);
  fixed := replace(d,
    $old$        then private.ledger_line('held', pay.held_owner, v_price)
        else private.ledger_line('organizer', pay.organizer_id, coalesce(v_shop, v_price)) end,$old$,
    $new$        then private.ledger_line('held', pay.held_owner, v_price)
        when exists (select 1 from public.ledger_transactions t
            where t.kind = 'dispute_lost' and t.reference ->> 'payment' = pay.id::text)
        then private.ledger_line('platform_fees', null, v_price)
        else private.ledger_line('organizer', pay.organizer_id, coalesce(v_shop, v_price)) end,$new$);
  if fixed = d then raise exception 'refund_issue did not change'; end if;
  execute fixed;

  -- Settling a lost dispute while another is open would guess at the second.
  d := pg_get_functiondef('public.staff_lesson_decide(uuid, boolean, text)'::regprocedure);
  fixed := replace(d,
    $old$    if v_left <= 0 then
      raise exception 'The bank has returned money on this payment. Work it out in Payments.';
    end if;$old$,
    $new$    if v_left <= 0 then
      raise exception 'The bank has returned money on this payment. Work it out in Payments.';
    end if;
    if v_lost > 0 and exists (select 1 from public.payment_disputes d
        where d.payment_id = pay.id and d.status = 'open') then
      raise exception 'A dispute is open on this payment. Wait for it to close.';
    end if;$new$);
  if fixed = d then raise exception 'staff_lesson_decide did not change'; end if;
  execute fixed;

  -- Inviting by username makes it an ordinary invitation, emailed or not.
  d := pg_get_functiondef('public.academy_set_coach(uuid, text, boolean)'::regprocedure);
  fixed := replace(d,
    $old$    insert into public.academy_coaches (academy_id, user_id) values (p_academy, v_user)
    on conflict do nothing;$old$,
    $new$    insert into public.academy_coaches (academy_id, user_id) values (p_academy, v_user)
    on conflict (academy_id, user_id) do update set by_email = false
      where public.academy_coaches.accepted_at is null;$new$);
  if fixed = d then raise exception 'academy_set_coach did not change'; end if;
  execute fixed;
end;
$$;
