-- P4c reviews: every fix here has a test in 45_academy_review_test.sql.

insert into public.app_settings (key, value, description) values
  ('academy.invites_per_hour', '20', 'Coach and parent invitations one person can send in an hour');

-- ─── A refused coach stays refused ─────────────────────────────────────────

do $$
declare
  d text;
  fixed text;
begin
  d := pg_get_functiondef('public.staff_licence_decide(uuid, boolean, text)'::regprocedure);
  fixed := replace(d, 'verified_at = case when p_approve then coalesce(verified_at, now()) else verified_at end',
    'verified_at = case when p_approve then coalesce(verified_at, now()) end');
  if fixed = d then raise exception 'staff_licence_decide did not change'; end if;
  execute fixed;
end;
$$;

-- ─── Nobody learns who has an account, or who is a minor ───────────────────

-- Every email is held the same way, and the person answers when they next open
-- Academy. So nobody learns from this whether an address has an account.
create or replace function public.academy_create(p jsonb) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: academies have no client write path.
declare
  v_id uuid;
  v_me uuid := (select auth.uid());
  v_mine text := (select email from public.account_private where id = (select auth.uid()));
begin
  if private.is_minor(v_me) then raise exception 'Academies are run by adults.'; end if;
  if char_length(trim(coalesce(p->>'name', ''))) < 2 then
    raise exception 'Give your academy a name.';
  end if;
  if private.text_problem(concat_ws(' ', p->>'name', p->>'blurb', p->>'audience')) is not null then
    raise exception 'Please change the wording.';
  end if;
  if jsonb_array_length(coalesce(p->'coaches', '[]')) > 20 then
    raise exception 'Invite up to 20 coaches at a time.';
  end if;
  insert into public.academies (owner_id, name, sport, area, blurb, audience, venues,
    billing, makeups_per_month)
  values (v_me, trim(p->>'name'), coalesce(p->>'sport', 'badminton'),
    coalesce(p->>'area', ''), left(coalesce(p->>'blurb', ''), 300),
    left(coalesce(p->>'audience', ''), 80),
    coalesce((select array_agg(x) from jsonb_array_elements_text(p->'venues') x), '{}'),
    coalesce(p->>'billing', 'month'), coalesce((p->>'makeups')::int, 2))
  returning id into v_id;
  insert into public.academy_coaches (academy_id, user_id, role, head, accepted_at)
  values (v_id, v_me, 'Head coach', true, now());
  insert into public.academy_coach_invites (academy_id, email)
  select v_id, lower(trim(x)) from jsonb_array_elements_text(coalesce(p->'coaches', '[]')) x
  where lower(trim(x)) ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' and lower(trim(x)) is distinct from lower(v_mine)
  on conflict do nothing;
  return v_id;
end;
$$;

-- Blocks stop an invitation arriving, and the person never learns it was tried.
create or replace function public.academy_claim_invites() returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes coach rows.
declare
  v_me uuid := (select auth.uid());
  v_email text := (select email from public.account_private where id = (select auth.uid()) and email_verified_at is not null);
begin
  if v_email is null then return; end if;
  if not private.is_minor(v_me) then
    insert into public.academy_coaches (academy_id, user_id)
    select i.academy_id, v_me from public.academy_coach_invites i
    join public.academies a on a.id = i.academy_id
    where i.email = v_email and a.closed_at is null and not public.is_blocked_between(v_me, a.owner_id)
    on conflict do nothing;
  end if;
  delete from public.academy_coach_invites where email = v_email;
end;
$$;

-- People who haven't said yes stay anonymous, whatever their licence.
create or replace function public.academy_verification(p_academy uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: reads licences and the payout account of the academy's coaches.
declare
  a public.academies;
begin
  perform public.academy_require_head(p_academy);
  select * into a from public.academies where id = p_academy;
  return jsonb_build_object('verification', a.verification, 'uen', a.uen,
    'rejected_reason', a.rejected_reason,
    'payout_ready', exists (select 1 from public.vendors v where v.owner_id = a.owner_id and v.status = 'verified'),
    'is_owner', a.owner_id = auth.uid(),
    'coaches', (select coalesce(jsonb_agg(jsonb_build_object(
        'name', public.academy_user_name(k.user_id), 'head', k.head, 'accepted', true,
        'licence', case when private.licence_current(k.user_id) then 'verified'
          else coalesce((select l.status from public.coach_licences l where l.user_id = k.user_id), 'none') end)
        order by k.head desc, k.created_at), '[]')
      from public.academy_coaches k where k.academy_id = p_academy and k.accepted_at is not null));
end;
$$;

do $$
declare
  d text;
  fixed text;
begin
  -- A minor or someone blocked reads the same as a username that doesn't exist.
  d := pg_get_functiondef('public.academy_set_coach(uuid, text, boolean)'::regprocedure);
  fixed := replace(d,
    $old$    if private.is_minor(v_user) then raise exception 'Coaches must be 18 or over.'; end if;
    if public.is_blocked_between(auth.uid(), v_user) then raise exception 'No player has that username.'; end if;
$old$,
    $new$    if private.is_minor(v_user) or public.is_blocked_between(auth.uid(), v_user) then
      raise exception 'No player has that username.';
    end if;
    if not private.rate_hit('coach-invite', auth.uid()::text, private.setting_int('academy.invites_per_hour'), 3600) then
      raise exception 'That''s a lot of invitations. Try again in an hour.';
    end if;
$new$);
  if fixed = d then raise exception 'academy_set_coach did not change'; end if;
  execute fixed;

  -- Parents, never children or anyone blocked. The exact number, not its last 8 digits.
  d := pg_get_functiondef('public.academy_invite(uuid, text)'::regprocedure);
  fixed := replace(replace(replace(d,
    $old$  select id into v_user from public.account_private
  where mobile_verified_at is not null
    and right(regexp_replace(coalesce(mobile, ''), '[^0-9]', '', 'g'), 8) = right(v_digits, 8)
  limit 1;
  if v_user is not null then$old$,
    $new$  select id into v_user from public.account_private
  where mobile_verified_at is not null
    and mobile = case when char_length(v_digits) = 8 then '+65' || v_digits else '+' || v_digits end;
  if v_user is not null and not private.is_minor(v_user)
     and not public.is_blocked_between(auth.uid(), v_user) then$new$),
    $old$  if char_length(v_digits) < 8 then raise exception 'Enter a mobile number, like 9123 4567.'; end if;$old$,
    $new$  if char_length(v_digits) < 8 then raise exception 'Enter a mobile number, like 9123 4567.'; end if;
  if not private.rate_hit('parent-invite', auth.uid()::text, private.setting_int('academy.invites_per_hour'), 3600) then
    raise exception 'That''s a lot of invitations. Try again in an hour.';
  end if;$new$),
    'public.notify(v_user, ''You''''re invited to '' || c.name,',
    'public.notify(v_user, ''You''''re invited to a class'',');
  if fixed = d then raise exception 'academy_invite did not change'; end if;
  execute fixed;

  -- What a coach writes reaches children, so it passes the same words check.
  d := pg_get_functiondef('public.academy_parent_note(uuid, jsonb, text)'::regprocedure);
  fixed := replace(d, $old$  perform public.academy_require_coach(s.academy_id);
  v_week := public.academy_class_week(s.class_id);$old$,
    $new$  perform public.academy_require_coach(s.academy_id);
  if private.text_problem(p_note) is not null then raise exception 'Please change the wording.'; end if;
  v_week := public.academy_class_week(s.class_id);$new$);
  fixed := replace(fixed, $old$  perform public.notify(s.parent_id, 'A note about ' || s.name,
    left(coalesce(nullif(trim(p_note), ''), 'Skills updated'), 200), '✎',
    '/students/' || s.id, '#E3F7C8', '#2E5A00');$old$,
    $new$  perform public.notify(r, 'A note about ' || s.name,
    left(coalesce(nullif(trim(p_note), ''), 'Skills updated'), 200), '✎',
    '/students/' || s.id, '#E3F7C8', '#2E5A00')
  from private.academy_recipients(s) r;$new$);
  if position('academy_recipients' in fixed) = 0 or position('text_problem' in fixed) = 0 then
    raise exception 'academy_parent_note did not change';
  end if;
  execute fixed;

  d := pg_get_functiondef('public.academy_save_session(uuid, uuid[], jsonb, text)'::regprocedure);
  fixed := replace(d, $old$  perform public.academy_require_coach((c->>'academy_id')::uuid);
$old$,
    $new$  perform public.academy_require_coach((c->>'academy_id')::uuid);
  if private.text_problem(p_note) is not null then raise exception 'Please change the wording.'; end if;
$new$);
  if fixed = d then raise exception 'academy_save_session did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.academy_change_class(uuid, text, text, uuid)'::regprocedure);
  fixed := replace(replace(d, $old$  if coalesce(trim(p_notice), '') = '' then raise exception 'Write the notice for parents.'; end if;
$old$,
    $new$  if coalesce(trim(p_notice), '') = '' then raise exception 'Write the notice for parents.'; end if;
  if private.text_problem(p_notice) is not null then raise exception 'Please change the wording.'; end if;
$new$),
    $old$    select parent_id as x from public.academy_students where class_id = p_class
    union$old$,
    $new$    select r as x from public.academy_students s cross join lateral private.academy_recipients(s) r
    where s.class_id = p_class
    union$new$);
  if position('academy_recipients' in fixed) = 0 or position('text_problem' in fixed) = 0 then
    raise exception 'academy_change_class did not change';
  end if;
  execute fixed;

  d := pg_get_functiondef('public.academy_update(uuid, jsonb)'::regprocedure);
  fixed := replace(d, $old$  perform public.academy_require_head(p_academy);
$old$,
    $new$  perform public.academy_require_head(p_academy);
  if private.text_problem(p->>'blurb') is not null then raise exception 'Please change the wording.'; end if;
$new$);
  if fixed = d then raise exception 'academy_update did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.academy_save_class(uuid, jsonb)'::regprocedure);
  fixed := replace(d, $old$  perform public.academy_require_head(p_academy);
$old$,
    $new$  perform public.academy_require_head(p_academy);
  if private.text_problem(concat_ws(' ', p->>'name', p->>'level_name', p->>'ages', p->>'court')) is not null then
    raise exception 'Please change the wording.';
  end if;
$new$);
  if fixed = d then raise exception 'academy_save_class did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.academy_save_plan(uuid, integer, integer, jsonb, text)'::regprocedure);
  fixed := replace(d, $old$  insert into public.academy_plans$old$,
    $new$  if private.text_problem(concat_ws(' ', p_note, p_drills::text)) is not null then
    raise exception 'Please change the wording.';
  end if;
  insert into public.academy_plans$new$);
  if fixed = d then raise exception 'academy_save_plan did not change'; end if;
  execute fixed;

  d := pg_get_functiondef('public.assessment_save(jsonb)'::regprocedure);
  fixed := replace(replace(d,
    $old$    perform public.academy_require_coach(a.academy_id);
    v_template := a.template_id;$old$,
    $new$    perform public.academy_require_coach(a.academy_id);
    if public.is_blocked_between(me, a.player_id) then
      raise exception 'Only the coach who wrote this can change it.';
    end if;
    v_template := a.template_id;$new$),
    $old$    if public.is_blocked_between(me, s.player_id) then raise exception 'This student has left.'; end if;$old$,
    $new$    if public.is_blocked_between(me, s.player_id) or exists (select 1 from private.academy_recipients(s) r
        where public.is_blocked_between(me, r)) then
      raise exception 'This student has left.';
    end if;$new$);
  if fixed = d then raise exception 'assessment_save did not change'; end if;
  execute fixed;
end;
$$;

-- Who hears about a student: their guardians today, not whoever enrolled them.
create function private.academy_recipients(s public.academy_students) returns setof uuid
language sql stable security definer set search_path = '' as $$
  -- Definer: reads guardian links.
  select s.parent_id where s.player_id is null
  union
  select s.player_id where s.player_id is not null and not private.is_minor(s.player_id)
  union
  select l.parent_id from public.guardian_links l
  where l.child_id = s.player_id and l.status = 'approved' and private.is_minor(s.player_id);
$$;

-- A close tells today's guardians too.
do $$
declare
  d text;
  fixed text;
begin
  d := pg_get_functiondef('public.academy_close(uuid)'::regprocedure);
  fixed := replace(replace(d,
    $old$  for v in select distinct parent_id from public.academy_students where academy_id = p_academy loop$old$,
    $new$  for v in select distinct r from public.academy_students s cross join lateral private.academy_recipients(s) r
    where s.academy_id = p_academy loop$new$),
    $old$  update public.lesson_slots set status = 'withdrawn' where academy_id = p_academy and status = 'open';
  for b in select * from public.lesson_bookings x
    where x.academy_id = p_academy and x.starts_at > now() and x.step in ('pending', 'paid', 'late_cancelled')
    order by x.id
  loop
    b := private.lesson_lock(b.id);
    perform private.lesson_cancel_full(b, 'The academy has closed');
  end loop;$old$,
    $new$  perform private.lesson_academy_off(p_academy, 'The academy has closed');$new$);
  if position('academy_recipients' in fixed) = 0 or position('lesson_academy_off' in fixed) = 0 then
    raise exception 'academy_close did not change';
  end if;
  execute fixed;
end;
$$;

-- ─── Verification files: one per purpose, so none can be left behind ───────

drop policy "Owners upload their own verification files" on storage.objects;
create policy "Owners upload their own verification files" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and storage.filename(name) ~ '^(licence|business-[0-9a-f-]{36})\.(jpg|pdf)$'
    and not private.is_restricted((select auth.uid()))
    and not private.is_suspended((select auth.uid()))
    and not private.is_minor((select auth.uid())));
-- Replacing a file needs both of these.
create policy "Owners replace their own verification files" on storage.objects
  for update to authenticated
  using (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = (select auth.uid())::text
    and storage.filename(name) ~ '^(licence|business-[0-9a-f-]{36})\.(jpg|pdf)$');
create policy "Owners read their own verification files" on storage.objects
  for select to authenticated
  using (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = (select auth.uid())::text);

create function public.staff_doc_viewed(p_kind text, p_id uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the audit log.
begin
  perform private.staff_require('content');
  perform private.staff_audit('verification_file_viewed', p_kind, p_id::text, p_reason);
end;
$$;
revoke execute on function public.staff_doc_viewed(text, uuid, text) from public, anon;
grant execute on function public.staff_doc_viewed(text, uuid, text) to authenticated;

-- ─── Lessons ───────────────────────────────────────────────────────────────

-- Reported lessons are after the start, so nobody can be booking that place.
-- Leaving them out lets a voided refund come back for a decision.
drop index public.lesson_one_slot;
drop index public.lesson_one_seat;
create unique index lesson_one_slot on public.lesson_bookings (slot_id)
  where step in ('pending', 'paid', 'marked', 'late_cancelled', 'released');
create unique index lesson_one_seat on public.lesson_bookings (class_id, starts_at, student_id)
  where step in ('pending', 'paid', 'marked', 'late_cancelled', 'released');
insert into private.lesson_transitions values ('expired', 'reported');

-- Everything still to come at an academy that has stopped.
create function private.lesson_academy_off(p_academy uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes slots and refunds. The caller holds the academy lock.
declare
  r record;
  b public.lesson_bookings;
begin
  update public.lesson_slots set status = 'withdrawn' where academy_id = p_academy and status = 'open';
  for r in select x.id from public.lesson_bookings x
    where x.academy_id = p_academy and x.starts_at > now() and x.step in ('pending', 'paid', 'late_cancelled')
    order by x.id
  loop
    b := private.lesson_lock(r.id);
    perform private.lesson_cancel_full(b, p_reason);
  end loop;
end;
$$;

create or replace function private.lesson_coach_gone(p_academy uuid, p_coach uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes slots and refunds. Slots first, so a reservation in flight
-- is seen once it commits. A refused licence ends every lesson, an academy
-- removing a coach only their one-to-ones, since a class can get another coach.
declare
  r record;
  b public.lesson_bookings;
begin
  update public.lesson_slots set status = 'withdrawn'
  where coach_id = p_coach and status = 'open' and starts_at > now()
    and (p_academy is null or academy_id = p_academy);
  for r in select id from public.lesson_bookings x
    where x.coach_id = p_coach and x.starts_at > now()
      and (p_academy is null or (x.academy_id = p_academy and x.kind = 'one_to_one'))
      and x.step in ('pending', 'paid', 'late_cancelled') order by id
  loop
    b := private.lesson_lock(r.id);
    perform private.lesson_cancel_full(b, p_reason);
  end loop;
end;
$$;

-- The bank having part of this payment means a person works out what's owed.
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
  if private.lesson_paid_back(b) then
    update public.lesson_bookings set step = 'reported', report_note = left('Academy cancelled: ' || p_reason, 500)
    where id = b.id;
    perform private.money_alert('lesson_reported', 'lesson-reported:' || b.id, jsonb_build_object('booking', b.id));
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

-- The academy cancelling a one-to-one also takes the time off sale.
create or replace function public.lesson_academy_cancel(p_booking uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds.
declare
  b public.lesson_bookings;
begin
  select * into b from public.lesson_bookings where id = p_booking;
  if b.id is null or not private.lesson_is_teacher(b) then raise exception 'This lesson isn''t yours.'; end if;
  if coalesce(trim(p_reason), '') = '' then raise exception 'Say why, for the parent.'; end if;
  if private.text_problem(p_reason) is not null then raise exception 'Please change the wording.'; end if;
  update public.lesson_slots set status = 'withdrawn' where id = b.slot_id and status = 'open';
  b := private.lesson_lock(p_booking);
  if b.step not in ('pending', 'paid', 'late_cancelled') then
    raise exception 'This lesson can''t be cancelled now.';
  end if;
  perform private.lesson_cancel_full(b, p_reason);
end;
$$;

-- What the screen promised is what happens, or nothing does.
drop function public.lesson_cancel(uuid, text);
create function public.lesson_cancel(p_booking uuid, p_reason text default null, p_expected_minor bigint default null)
returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds.
declare
  b public.lesson_bookings := private.lesson_lock(p_booking);
  pay public.payments;
  v_in_time boolean;
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
  v_in_time := now() <= b.starts_at - make_interval(hours => private.setting_int('lesson.cancel_hours'));
  if p_expected_minor is not null
     and p_expected_minor is distinct from (case when v_in_time then pay.price_minor else 0 end) then
    raise exception 'The time to cancel for a refund has passed. Check and try again.';
  end if;
  update public.lesson_bookings
  set step = case when v_in_time then 'cancelled' else 'late_cancelled' end,
      cancelled_at = now(), cancelled_by = 'payer', cancel_reason = left(coalesce(p_reason, ''), 200)
  where id = b.id;
  if v_in_time then
    v_refund := private.refund_issue(pay.id, 'player_in_time', 'lesson:' || b.id);
  end if;
  begin
    perform public.notify(b.coach_id, 'Lesson cancelled', b.title, '!', '/academies/' || b.academy_id || '/lessons');
  exception when others then
    null;
  end;
  return v_refund;
end;
$$;
revoke execute on function public.lesson_cancel(uuid, text, bigint) from public, anon;
grant execute on function public.lesson_cancel(uuid, text, bigint) to authenticated;

create or replace function private.lesson_is_teacher(b public.lesson_bookings) returns boolean
language sql stable security definer set search_path = '' as $$
  -- Definer: reads coach rows.
  select public.academy_is_coach(b.academy_id) and private.licence_ok(auth.uid()) and (b.coach_id = auth.uid()
    or exists (select 1 from public.academy_coaches k
      where k.academy_id = b.academy_id and k.user_id = auth.uid() and k.head));
$$;

-- Staff can't refund what the bank already has. A person works that one out.
create or replace function public.staff_lesson_decide(p_booking uuid, p_refund boolean, p_reason text) returns void
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
    if private.lesson_paid_back(b) then
      raise exception 'The bank has returned money on this payment. Work it out in Payments.';
    end if;
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

create or replace function private.lesson_json(b public.lesson_bookings) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: joins the payment and names.
  select jsonb_build_object('id', b.id, 'kind', b.kind, 'title', b.title, 'academy_id', b.academy_id,
    'academy', b.academy_name, 'coach', coalesce(public.academy_user_name(b.coach_id), ''),
    'student_id', b.student_id, 'student', coalesce(public.academy_user_name(b.student_id), ''),
    'starts_at', b.starts_at, 'ends_at', b.ends_at, 'step', b.step, 'attendance', b.attendance,
    'report_note', b.report_note, 'cancel_reason', b.cancel_reason,
    'hold_until', b.hold_until, 'server_now', now(), 'payment_id', p.id, 'status', p.status, 'method', p.method,
    'price_minor', p.price_minor, 'fee_minor', p.fee_minor, 'amount_minor', p.amount_minor,
    'currency', p.currency,
    'refunded_minor', coalesce((select sum(r.amount_minor) from public.refunds r
      where r.payment_id = p.id and r.status <> 'voided'), 0),
    'free_cancel_until', b.starts_at - make_interval(hours => private.setting_int('lesson.cancel_hours')))
  from public.payments p where p.lesson_booking_id = b.id;
$$;

-- Bookable classes, worked out in Singapore time rather than the phone's.
create function public.academy_class_slots(p_academy uuid, p_kind text) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: reads classes and places. Once lessons are paid, a class with no
  -- price isn't offered, and a single class never is without one.
  with open as (select private.flag('payments.enabled') and private.flag('lessons.checkout') as paid)
  select coalesce(jsonb_agg(jsonb_build_object('class_id', c.id, 'class_name', c.name, 'at', x.at,
      'coach', coalesce(public.academy_user_name(c.coach_id), ''),
      'lesson', public.academy_class_json(c.id) ->> 'lesson',
      'spots', c.capacity - private.class_taken(c.id, x.at),
      'trial_price_cents', c.trial_price_cents, 'dropin_price_cents', c.dropin_price_cents)
      order by x.at), '[]')
  from open
  join public.academy_classes c on c.academy_id = p_academy
  join public.academies a on a.id = c.academy_id
  cross join generate_series(0, 14) n
  cross join lateral (select (now() at time zone 'Asia/Singapore')::date + n as d) y
  cross join lateral (select (d + make_time(c.hour, c.minute, 0)) at time zone 'Asia/Singapore' as at) x
  where private.academy_visible(a) and c.coach_id is not null
    and extract(isodow from d)::int = any (c.weekdays) and x.at > now()
    and private.class_taken(c.id, x.at) < c.capacity
    and not exists (select 1 from public.academy_cancellations k where k.class_id = c.id and k.held_on = d)
    and case p_kind when 'class' then c.dropin_price_cents is not null
      else c.trial_price_cents is not null or not open.paid end;
$$;
revoke execute on function public.academy_class_slots(uuid, text) from public, anon;
grant execute on function public.academy_class_slots(uuid, text) to authenticated;

-- People still deciding, for the head coach who invited them.
do $$
declare
  d text;
  fixed text;
begin
  d := pg_get_functiondef('public.academy_json(uuid)'::regprocedure);
  fixed := replace(d, $old$    'classes', (select coalesce(jsonb_agg(public.academy_class_json(c.id)$old$,
    $new$    'pending_coaches', case when exists (select 1 from public.academy_coaches where academy_id = a.id
                       and user_id = (select auth.uid()) and head and accepted_at is not null)
      then (select coalesce(jsonb_agg(jsonb_build_object('id', k.user_id,
          'username', (select r.username from public.profiles r where r.id = k.user_id))
          order by k.created_at), '[]')
        from public.academy_coaches k where k.academy_id = a.id and k.accepted_at is null)
      else '[]'::jsonb end,
    'classes', (select coalesce(jsonb_agg(public.academy_class_json(c.id)$new$);
  if fixed = d then raise exception 'academy_json did not change'; end if;
  execute fixed;

  -- An unlicensed or suspended teacher doesn't sell lessons.
  d := pg_get_functiondef('private.lesson_offer(text, uuid, timestamptz)'::regprocedure);
  fixed := replace(replace(d,
    $old$    if c.coach_id is null then raise exception 'This class has no coach yet.'; end if;$old$,
    $new$    if c.coach_id is null or not private.licence_current(c.coach_id) then
      raise exception 'This class has no coach yet.';
    end if;$new$),
    $old$  if not private.academy_open_to_all(a) then raise exception 'This academy is no longer listed.'; end if;
  if v_start <= now()$old$,
    $new$  if not private.academy_open_to_all(a) then raise exception 'This academy is no longer listed.'; end if;
  if private.is_suspended(a.owner_id) or private.is_suspended(v_coach) then
    raise exception 'This lesson isn''t available.';
  end if;
  if v_start <= now()$new$);
  if position('is_suspended' in fixed) = 0 or position('or not private.licence_current(c.coach_id)' in fixed) = 0 then
    raise exception 'lesson_offer did not change';
  end if;
  execute fixed;

  d := pg_get_functiondef('public.lesson_slots_open(uuid)'::regprocedure);
  fixed := replace(d, $old$    and not public.is_blocked_between(auth.uid(), s.coach_id)$old$,
    $new$    and not private.is_suspended(s.coach_id) and not private.is_suspended(a.owner_id)
    and not public.is_blocked_between(auth.uid(), s.coach_id)$new$);
  if fixed = d then raise exception 'lesson_slots_open did not change'; end if;
  execute fixed;

  -- An academy that stopped takes late money back rather than the booking.
  d := pg_get_functiondef('private.lesson_captured(public.payments, public.payments)'::regprocedure);
  fixed := replace(d, $old$  if b.step = 'pending' and was.status = 'pending' and b.starts_at > now()
$old$,
    $new$  if b.step = 'pending' and was.status = 'pending' and b.starts_at > now()
     and exists (select 1 from public.academies a where a.id = b.academy_id and private.academy_open_to_all(a))
$new$);
  if fixed = d then raise exception 'lesson_captured did not change'; end if;
  execute fixed;

  -- Rejecting a verified academy ends what it had still to teach.
  d := pg_get_functiondef('public.staff_academy_decide(uuid, boolean, text)'::regprocedure);
  fixed := replace(d, $old$  perform public.notify(a.owner_id,
    case when p_approve then a.name || ' is verified'$old$,
    $new$  if not p_approve then
    perform private.lesson_academy_off(a.id, 'The academy is no longer verified');
  end if;
  perform public.notify(a.owner_id,
    case when p_approve then a.name || ' is verified'$new$);
  if fixed = d then raise exception 'staff_academy_decide did not change'; end if;
  execute fixed;

  -- A staff refund queued against a dispute that's then lost: whoever was paid
  -- owes it back, on any kind of payment, not only a shop's.
  d := pg_get_functiondef('public.money_svc_event(jsonb)'::regprocedure);
  fixed := replace(d, $old$select coalesce(sum((x ->> 'shop')::bigint), 0) into v_also$old$,
    $new$select coalesce(sum(coalesce((x ->> 'shop')::bigint, (x ->> 'price')::bigint)), 0) into v_also$new$);
  if fixed = d then raise exception 'money_svc_event did not change'; end if;
  execute fixed;

  -- Booking before payment, as everywhere else. An expired booking whose late
  -- refund failed comes back to staff too.
  d := pg_get_functiondef('public.staff_refund_void(uuid, text)'::regprocedure);
  fixed := replace(replace(d,
    $old$  select * into r from public.refunds where id = p_refund for update;$old$,
    $new$  perform 1 from public.lesson_bookings b
  where b.id = (select p.lesson_booking_id from public.payments p
    join public.refunds x on x.payment_id = p.id where x.id = p_refund) for update;
  select * into r from public.refunds where id = p_refund for update;$new$),
    $old$where id = pay.lesson_booking_id and step in ('refunded', 'cancelled');$old$,
    $new$where id = pay.lesson_booking_id and step in ('refunded', 'cancelled', 'expired');$new$);
  if fixed = d then raise exception 'staff_refund_void did not change'; end if;
  execute fixed;

  -- Nothing was earned on money the bank took back.
  d := pg_get_functiondef('private.payment_earned(public.payments)'::regprocedure);
  fixed := replace(d, $old$    else p.price_minor - coalesce((select sum(r.price_minor)$old$,
    $new$    when exists (select 1 from public.ledger_transactions t
        where t.kind in ('dispute_lost', 'dispute_owed') and t.reference ->> 'payment' = p.id::text) then 0
    else p.price_minor - coalesce((select sum(r.price_minor)$new$);
  if fixed = d then raise exception 'payment_earned did not change'; end if;
  execute fixed;

  -- Lessons that came to nothing don't sit in the owner's list.
  d := pg_get_functiondef('public.money_my_earnings()'::regprocedure);
  fixed := replace(d, $old$      where p.organizer_id = me and p.status = 'succeeded'
      order by b.starts_at desc limit 50) y));$old$,
    $new$      where p.organizer_id = me and p.status = 'succeeded'
        and b.step not in ('cancelled', 'expired', 'refunded')
      order by b.starts_at desc limit 50) y));$new$);
  if fixed = d then raise exception 'money_my_earnings did not change'; end if;
  execute fixed;
end;
$$;
