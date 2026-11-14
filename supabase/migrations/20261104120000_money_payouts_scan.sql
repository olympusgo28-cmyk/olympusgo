-- P4a-07 to P4a-09, A-06: payout runs, reconciliation, Scan, and the staff
-- functions for payments.

-- Payouts ---------------------------------------------------------------------

-- What an organizer can be paid: earnings less fees they owe (R-REF-12, Q12).
create function private.organizer_net(p_owner uuid, p_currency text) returns bigint
language sql stable security definer set search_path = '' as $$
  -- Definer: no client role touches ledger tables.
  select - private.ledger_balance('organizer', p_owner, p_currency)
         - private.ledger_balance('organizer_fee_debt', p_owner, p_currency)
         - private.ledger_balance('card_fee_recovery', p_owner, p_currency);
$$;

-- Monday's draft. Nothing moves until staff approve it, so an old draft can be
-- replaced safely.
create function private.payouts_prepare(p_currency text default 'SGD', p_week date default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: cron.
declare
  v_week date := coalesce(p_week,
    date_trunc('week', now() at time zone 'Asia/Singapore')::date);
  v_run uuid;
  v_total bigint := 0;
  v_net bigint;
  v_oldest timestamptz;
  r record;
begin
  update public.payouts set status = 'superseded'
  where currency = p_currency and status = 'prepared' and week_start < v_week;

  insert into public.payouts (currency, week_start, total_minor)
  values (p_currency, v_week, 0)
  on conflict (currency, week_start) do nothing
  returning id into v_run;
  if v_run is null then return null; end if;

  for r in
    select distinct la.owner_id, v.status as vendor_status, v.schedule
    from public.ledger_accounts la
    left join public.vendors v on v.owner_id = la.owner_id
    where la.kind in ('organizer', 'organizer_fee_debt', 'card_fee_recovery')
      and la.currency = p_currency
  loop
    v_net := private.organizer_net(r.owner_id, p_currency);
    select min(e.created_at) into v_oldest
    from public.ledger_entries e join public.ledger_accounts la on la.id = e.account_id
    where la.owner_id = r.owner_id and la.currency = p_currency;

    if v_net < 0 then
      if v_oldest < now() - make_interval(days => private.setting_int('money.debt_alert_days')) then
        perform private.money_alert('organizer_shortfall', 'shortfall:' || r.owner_id || ':' || v_week,
          jsonb_build_object('owner', r.owner_id, 'net_minor', v_net));
      end if;
      continue;
    end if;
    continue when v_net = 0;
    if r.vendor_status is distinct from 'verified' then
      if v_oldest < now() - make_interval(days => private.setting_int('money.vendor_alert_days')) then
        perform private.money_alert('vendor_unverified', 'vendor:' || r.owner_id,
          jsonb_build_object('owner', r.owner_id, 'net_minor', v_net));
      end if;
      continue;
    end if;
    continue when r.schedule = 'off';
    continue when r.schedule = 'monthly' and extract(day from v_week) > 7;
    continue when private.is_suspended(r.owner_id);
    continue when exists (select 1 from public.activity_money_holds h
      join public.activities a on a.id = h.activity_id
      where h.closed_at is null and a.host_id = r.owner_id);

    insert into public.payout_items (payout_id, owner_id, amount_minor)
    values (v_run, r.owner_id, v_net);
    v_total := v_total + v_net;
  end loop;

  update public.payouts set total_minor = v_total where id = v_run;
  return v_run;
end;
$$;

select cron.schedule('payouts-prepare', '0 1 * * 1', 'select private.payouts_prepare()');

create function public.staff_payout_approve(p_run uuid, p_reason text) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: writes the ledger and the audit log.
declare
  me uuid := auth.uid();
  run public.payouts;
  it public.payout_items;
  v_vendor text;
  v_net bigint;
  v_amount bigint;
  v_debt bigint;
  v_fees bigint;
  v_total bigint := 0;
begin
  perform private.staff_require('payments');
  select * into run from public.payouts where id = p_run for update;
  if run.id is null then raise exception 'This run is closed.'; end if;
  if run.status <> 'prepared' then raise exception 'This run is closed.'; end if;

  if run.first_approver is null then
    update public.payouts set first_approver = me where id = run.id;
    if run.total_minor > private.setting_int('payout.second_approver_minor') then
      perform private.staff_audit('payout_first_approval', 'payout', run.id::text, p_reason);
      return 'needs_second';
    end if;
  elsif run.first_approver = me then
    raise exception 'A second staff member has to approve this.';
  else
    update public.payouts set second_approver = me where id = run.id;
  end if;

  for it in select * from public.payout_items where payout_id = run.id and status = 'prepared' loop
    perform pg_advisory_xact_lock(hashtext('payout:' || it.owner_id));
    select status into v_vendor from public.vendors where owner_id = it.owner_id;
    v_net := private.organizer_net(it.owner_id, run.currency);
    v_amount := least(it.amount_minor, v_net);
    if v_vendor is distinct from 'verified' or v_amount <= 0 or private.is_suspended(it.owner_id) then
      update public.payout_items set status = 'dropped' where id = it.id;
      continue;
    end if;
    -- Fees owed clear first, which also lifts the publish block.
    v_debt := greatest(private.ledger_balance('organizer_fee_debt', it.owner_id, run.currency), 0);
    v_fees := greatest(private.ledger_balance('card_fee_recovery', it.owner_id, run.currency), 0);
    perform private.ledger_post('payout', 'payout:' || it.id, run.currency,
      jsonb_build_object('payout', run.id, 'item', it.id),
      jsonb_build_array(
        private.ledger_line('organizer', it.owner_id, v_amount + v_debt + v_fees),
        private.ledger_line('organizer_fee_debt', it.owner_id, -v_debt),
        private.ledger_line('card_fee_recovery', it.owner_id, -v_fees),
        private.ledger_line('payouts_pending', null, -v_amount)));
    update public.payout_items set status = 'pending', amount_minor = v_amount where id = it.id;
    v_total := v_total + v_amount;
  end loop;

  update public.payouts set status = 'approved', approved_at = now(), total_minor = v_total
  where id = run.id;
  perform private.staff_audit('payout_approved', 'payout', run.id::text, p_reason,
    jsonb_build_object('total_minor', v_total));
  return 'approved';
end;
$$;

-- Adults only, and each owner sets up their own (R-PAY-3, R-PAY-4).
create function public.vendor_start() returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: vendors has no client write path.
declare
  me uuid := auth.uid();
  v public.vendors;
begin
  if me is null or private.is_minor(me) or private.is_restricted(me) then
    raise exception 'Payouts are for adults only.';
  end if;
  insert into public.vendors (owner_id) values (me) on conflict (owner_id) do nothing;
  select * into v from public.vendors where owner_id = me;
  return jsonb_build_object('status', v.status, 'schedule', v.schedule, 'account', v.stripe_account_id);
end;
$$;

create function public.vendor_set_schedule(p_schedule text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: vendors has no client write path.
begin
  update public.vendors set schedule = p_schedule where owner_id = auth.uid();
  if not found then raise exception 'Set up your payout account first.'; end if;
end;
$$;

create function public.money_my_earnings() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: no client role touches ledger tables.
declare
  me uuid := auth.uid();
  v_currency text := 'SGD';
begin
  return jsonb_build_object(
    'currency', v_currency,
    'available_minor', greatest(private.organizer_net(me, v_currency), 0),
    'owed_minor', greatest(-private.organizer_net(me, v_currency), 0),
    'fee_debt_minor', greatest(private.ledger_balance('organizer_fee_debt', me, v_currency), 0),
    'held_minor', coalesce((select sum(p.price_minor - coalesce((select sum(r.price_minor)
        from public.refunds r where r.payment_id = p.id and r.status <> 'voided'), 0))
      from public.payments p
      where p.organizer_id = me and p.status = 'succeeded' and p.released_at is null), 0),
    'month_minor', coalesce((select sum(p.price_minor) from public.payments p
      where p.organizer_id = me and p.status = 'succeeded'
        and p.released_at >= date_trunc('month', now())), 0),
    'year_minor', coalesce((select sum(p.price_minor) from public.payments p
      where p.organizer_id = me and p.status = 'succeeded'
        and p.released_at >= date_trunc('year', now())), 0),
    'vendor', (select jsonb_build_object('status', v.status, 'schedule', v.schedule)
      from public.vendors v where v.owner_id = me),
    'payouts', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', i.id, 'amount_minor', i.amount_minor, 'status', i.status, 'week_start', p.week_start)
        order by p.week_start desc), '[]')
      from public.payout_items i join public.payouts p on p.id = i.payout_id
      where i.owner_id = me and i.status in ('pending', 'sent', 'failed')),
    'activities', (select coalesce(jsonb_agg(x order by x ->> 'starts_at' desc), '[]') from (
      select jsonb_build_object('activity_id', a.id, 'title', a.title, 'starts_at', a.starts_at,
        'price_minor', sum(p.price_minor),
        'released', bool_and(p.released_at is not null)) as x
      from public.payments p join public.activities a on a.id = p.activity_id
      where p.organizer_id = me and p.status = 'succeeded' and p.price_minor > 0
      group by a.id order by a.starts_at desc limit 50) y));
end;
$$;

create function public.money_svc_vendor_attach(p_owner uuid, p_account text) returns void
language sql security definer set search_path = '' as $$
  -- Definer: service role only.
  update public.vendors set stripe_account_id = coalesce(stripe_account_id, p_account)
  where owner_id = p_owner;
$$;

create or replace function public.money_svc_work() returns jsonb
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
      left join public.payment_customers c on c.user_id = p.user_id),
    'transfers', (select coalesce(jsonb_agg(jsonb_build_object('item_id', i.id,
        'amount_minor', i.amount_minor, 'currency', r.currency, 'account', v.stripe_account_id)), '[]')
      from (select * from public.payout_items where status = 'pending' limit 50) i
      join public.payouts r on r.id = i.payout_id
      join public.vendors v on v.owner_id = i.owner_id));
$$;

create or replace function public.money_svc_result(p_kind text, p_id uuid, p_ok boolean,
  p_ref text default null, p_code text default null)
returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only.
declare
  it public.payout_items;
  run public.payouts;
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
    when 'transfer' then
      select * into it from public.payout_items where id = p_id for update;
      if it.status <> 'pending' then return; end if;
      select * into run from public.payouts where id = it.payout_id;
      if p_ok then
        update public.payout_items set status = 'sent', stripe_transfer_id = p_ref where id = it.id;
        perform private.ledger_post('transfer', 'transfer:' || it.id, run.currency,
          jsonb_build_object('item', it.id, 'stripe', p_ref),
          jsonb_build_array(private.ledger_line('payouts_pending', null, it.amount_minor),
            private.ledger_line('clearing', null, -it.amount_minor)));
      elsif p_code = 'balance_insufficient' then
        -- Card funds can take days to arrive. Stays pending, so it retries.
        update public.payout_items set failure_code = p_code where id = it.id;
      else
        update public.payout_items set status = 'failed', failure_code = p_code where id = it.id;
        perform private.ledger_post('payout_return', 'payout_return:' || it.id, run.currency,
          jsonb_build_object('item', it.id),
          jsonb_build_array(private.ledger_line('payouts_pending', null, it.amount_minor),
            private.ledger_line('organizer', it.owner_id, -it.amount_minor)));
        perform private.money_alert('payout_failed', 'payout-failed:' || it.id,
          jsonb_build_object('item', it.id, 'code', p_code));
      end if;
    else
      raise exception 'Unknown result %', p_kind;
  end case;
end;
$$;

-- Reconciliation ------------------------------------------------------------

-- The ledger's view of what Stripe should show, by Stripe's own id.
create function public.money_svc_ledger_rows(p_since timestamptz) returns jsonb
language sql stable security definer set search_path = '' as $$
  -- Definer: service role only.
  select coalesce(jsonb_agg(x), '[]') from (
    select jsonb_build_object('source', p.stripe_charge_id, 'amount_minor', p.amount_minor,
      'fee_minor', p.processor_fee_minor, 'at', p.captured_at) as x
    from public.payments p
    where p.status = 'succeeded' and p.stripe_charge_id is not null and p.captured_at >= p_since
    union all
    select jsonb_build_object('source', r.stripe_refund_id, 'amount_minor', -r.amount_minor,
      'fee_minor', 0, 'at', r.settled_at)
    from public.refunds r
    where r.status = 'succeeded' and r.stripe_refund_id is not null and r.settled_at >= p_since
    union all
    select jsonb_build_object('source', i.stripe_transfer_id, 'amount_minor', -i.amount_minor,
      'fee_minor', 0, 'at', p.approved_at)
    from public.payout_items i join public.payouts p on p.id = i.payout_id
    where i.status = 'sent' and p.approved_at >= p_since
  ) y;
$$;

create function public.money_svc_reconcile_save(p_matched integer, p_timing integer, p_mismatches jsonb)
returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: service role only.
declare
  v_id uuid;
  m jsonb;
begin
  insert into public.reconciliation_runs (matched, timing, mismatches)
  values (p_matched, p_timing, p_mismatches)
  returning id into v_id;
  for m in select x from jsonb_array_elements(p_mismatches) x loop
    perform private.money_alert('reconciliation', 'recon:' || (m ->> 'source') || ':' || (m ->> 'kind'), m);
  end loop;
  return v_id;
end;
$$;

revoke execute on function public.money_svc_vendor_attach(uuid, text), public.money_svc_work(),
  public.money_svc_result(text, uuid, boolean, text, text), public.money_svc_ledger_rows(timestamptz),
  public.money_svc_reconcile_save(integer, integer, jsonb)
  from public, anon, authenticated;
grant execute on function public.money_svc_vendor_attach(uuid, text), public.money_svc_work(),
  public.money_svc_result(text, uuid, boolean, text, text), public.money_svc_ledger_rows(timestamptz),
  public.money_svc_reconcile_save(integer, integer, jsonb)
  to service_role;

-- The worker runs on a timer. Nothing happens until the URL and secret are in
-- Vault, which seed.sql does locally and an owner does on a hosted project.
create extension if not exists pg_net with schema extensions;

create function private.worker_tick(p_task text default 'work') returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: reads Vault.
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'money_worker_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'money_worker_secret';
  if v_url is null or v_secret is null then return; end if;
  perform net.http_post(v_url, jsonb_build_object('task', p_task), '{}'::jsonb,
    jsonb_build_object('content-type', 'application/json', 'x-worker-secret', v_secret));
end;
$$;
revoke execute on function private.worker_tick(text) from public, anon, authenticated, service_role;

select cron.schedule('money-worker', '* * * * *', 'select private.worker_tick()');
select cron.schedule('money-reconcile', '30 18 * * *', $$select private.worker_tick('reconcile')$$);

-- Scan ------------------------------------------------------------------------

-- Codes for places, which their owners can rotate. A rotated code stops working.
create table public.place_qr_tokens (
  kind text not null check (kind in ('group', 'venue', 'vendor')),
  subject_id uuid not null,
  token text not null unique,
  rotated_at timestamptz not null default now(),
  primary key (kind, subject_id)
);
alter table public.place_qr_tokens enable row level security;
revoke all on public.place_qr_tokens from anon, authenticated;

create function private.place_qr(p_kind text, p_subject uuid, p_rotate boolean) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: place_qr_tokens has no client access.
declare
  v_token text := private.new_qr_token();
begin
  insert into public.place_qr_tokens (kind, subject_id, token) values (p_kind, p_subject, v_token)
  on conflict (kind, subject_id) do update
    set token = case when p_rotate then excluded.token else public.place_qr_tokens.token end,
        rotated_at = case when p_rotate then now() else public.place_qr_tokens.rotated_at end
  returning token into v_token;
  return v_token;
end;
$$;
revoke execute on function private.place_qr(text, uuid, boolean) from public, anon, authenticated;

create function public.club_qr(p_club uuid, p_rotate boolean default false) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: checks the role itself.
begin
  perform public.club_require(p_club, 'members');
  return private.place_qr('group', p_club, p_rotate);
end;
$$;

-- A verified vendor's code, so a player can open their page and pay in 4b.
create function public.vendor_qr(p_rotate boolean default false) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: place_qr_tokens has no client access.
begin
  if not exists (select 1 from public.vendors v where v.owner_id = auth.uid() and v.status = 'verified') then
    raise exception 'Finish your payout set-up first.';
  end if;
  return private.place_qr('vendor', auth.uid(), p_rotate);
end;
$$;

create function public.staff_venue_qr(p_venue uuid, p_rotate boolean default false) returns text
language plpgsql security definer set search_path = '' as $$
-- Definer: place_qr_tokens has no client access.
begin
  perform private.staff_require('content');
  return private.place_qr('venue', p_venue, p_rotate);
end;
$$;

create or replace function public.resolve_qr(p_token text) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- Definer: maps a token without exposing the token tables. No under-18 can
-- look anyone up; a parent scans for a child.
declare
  me uuid := auth.uid();
  v_target uuid;
  v_username text;
  t public.place_qr_tokens;
begin
  if private.is_restricted(me) or private.is_minor(me) then
    raise exception 'Ask a parent to scan for you.';
  end if;
  select user_id into v_target from public.player_qr_tokens where token = p_token;
  if v_target is not null then
    if not private.can_view_profile(v_target, me) then
      raise exception 'That code isn''t valid.';
    end if;
    select username::text into v_username from public.profiles where id = v_target;
    return jsonb_build_object('kind', 'player', 'username', v_username);
  end if;

  select * into t from public.place_qr_tokens where token = p_token;
  if t.kind = 'group' then
    if exists (select 1 from public.clubs c where c.id = t.subject_id and c.hidden_at is null
        and (c.visibility = 'public' or exists (select 1 from public.club_members m
          where m.club_id = c.id and m.user_id = me))
        and not public.is_blocked_between(me, c.owner_id)) then
      return jsonb_build_object('kind', 'group', 'id', t.subject_id);
    end if;
  elsif t.kind = 'venue' then
    if exists (select 1 from public.venues v where v.id = t.subject_id) then
      return jsonb_build_object('kind', 'venue', 'id', t.subject_id);
    end if;
  elsif t.kind = 'vendor' then
    if exists (select 1 from public.vendors v where v.owner_id = t.subject_id and v.status = 'verified')
       and private.can_view_profile(t.subject_id, me) then
      select username::text into v_username from public.profiles where id = t.subject_id;
      return jsonb_build_object('kind', 'vendor', 'username', v_username);
    end if;
  end if;
  raise exception 'That code isn''t valid.';
end;
$$;

revoke execute on function public.club_qr(uuid, boolean), public.vendor_qr(boolean),
  public.staff_venue_qr(uuid, boolean), public.vendor_start(), public.vendor_set_schedule(text),
  public.money_my_earnings(), public.staff_payout_approve(uuid, text)
  from public, anon;
grant execute on function public.club_qr(uuid, boolean), public.vendor_qr(boolean),
  public.staff_venue_qr(uuid, boolean), public.vendor_start(), public.vendor_set_schedule(text),
  public.money_my_earnings(), public.staff_payout_approve(uuid, text)
  to authenticated;

-- A-06 ------------------------------------------------------------------------

create function public.staff_money_overview() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: no client role touches ledger tables.
begin
  perform private.staff_require('payments');
  return jsonb_build_object(
    'held_minor', -coalesce((select sum(e.amount_minor) from public.ledger_entries e
      join public.ledger_accounts a on a.id = e.account_id where a.kind = 'held'), 0),
    'refunds_pending_minor', -private.ledger_balance('refunds_pending', null, 'SGD'),
    'platform_fees_minor', -private.ledger_balance('platform_fees', null, 'SGD'),
    'suspense_minor', -private.ledger_balance('suspense', null, 'SGD'),
    'open_alerts', (select count(*) from public.money_alerts where closed_at is null),
    'open_holds', (select count(*) from public.activity_money_holds where closed_at is null),
    'open_disputes', (select count(*) from public.payment_disputes where status = 'open'),
    'failed_refunds', (select count(*) from public.refunds where status = 'failed'));
end;
$$;

create function public.staff_payment_list(p_limit integer default 100) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff read every payment. Opaque ids only.
begin
  perform private.staff_require('payments');
  return (select coalesce(jsonb_agg(x), '[]') from (
    select jsonb_build_object('id', p.id, 'receipt_no', p.receipt_no, 'purpose', p.purpose,
      'status', p.status, 'method', p.method, 'amount_minor', p.amount_minor,
      'price_minor', p.price_minor, 'fee_minor', p.fee_minor, 'currency', p.currency,
      'activity_id', p.activity_id, 'created_at', p.created_at, 'released_at', p.released_at,
      'refunded_minor', coalesce((select sum(r.amount_minor) from public.refunds r
        where r.payment_id = p.id and r.status <> 'voided'), 0)) as x
    from public.payments p order by p.created_at desc limit least(coalesce(p_limit, 100), 500)) y);
end;
$$;

create function public.staff_payment_get(p_payment uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: the ledger drill-down.
declare
  p public.payments;
begin
  perform private.staff_require('payments');
  select * into p from public.payments where id = p_payment;
  if p.id is null then raise exception 'Not found.' using errcode = 'P0001'; end if;
  return private.payment_json(p) || jsonb_build_object('activity_id', p.activity_id,
    'captured_at', p.captured_at, 'released_at', p.released_at,
    'refunds', (select coalesce(jsonb_agg(to_jsonb(r) order by r.created_at), '[]')
      from public.refunds r where r.payment_id = p.id),
    'ledger', (select coalesce(jsonb_agg(jsonb_build_object('kind', t.kind, 'at', t.created_at,
        'account', a.kind, 'owner', a.owner_id, 'amount_minor', e.amount_minor) order by e.id), '[]')
      from public.ledger_transactions t
      join public.ledger_entries e on e.transaction_id = t.id
      join public.ledger_accounts a on a.id = e.account_id
      where t.reference ->> 'payment' = p.id::text
         or t.reference ->> 'refund' in (select r.id::text from public.refunds r where r.payment_id = p.id)));
end;
$$;

create function public.staff_refund_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: staff read every refund.
begin
  perform private.staff_require('payments');
  return (select coalesce(jsonb_agg(x), '[]') from (
    select to_jsonb(r) as x from public.refunds r
    order by (r.status = 'failed') desc, r.created_at desc limit 200) y);
end;
$$;

create function public.staff_held_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: held money by activity, with what's keeping it.
begin
  perform private.staff_require('payments');
  return (select coalesce(jsonb_agg(x order by x ->> 'oldest'), '[]') from (
    select jsonb_build_object('activity_id', a.id, 'title', a.title, 'ends_at', a.ends_at,
      'held_minor', -private.ledger_balance('held', a.id, a.currency),
      'oldest', min(p.captured_at),
      'hold_id', (select h.id from public.activity_money_holds h
        where h.activity_id = a.id and h.closed_at is null)) as x
    from public.payments p join public.activities a on a.id = p.activity_id
    where p.status = 'succeeded' and p.released_at is null and p.price_minor > 0
    group by a.id) y);
end;
$$;

create function public.staff_payout_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: payout tables have no client access.
begin
  perform private.staff_require('payments');
  return (select coalesce(jsonb_agg(x), '[]') from (
    select to_jsonb(r) || jsonb_build_object(
      'needs_second', r.total_minor > private.setting_int('payout.second_approver_minor'),
      'items', (select coalesce(jsonb_agg(to_jsonb(i)), '[]') from public.payout_items i
        where i.payout_id = r.id)) as x
    from public.payouts r order by r.week_start desc limit 30) y);
end;
$$;

create function public.staff_dispute_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: disputes have no client access.
begin
  perform private.staff_require('payments');
  return (select coalesce(jsonb_agg(to_jsonb(d) order by d.created_at desc), '[]')
    from public.payment_disputes d);
end;
$$;

create function public.staff_alert_list() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
-- Definer: alerts have no client access.
begin
  perform private.staff_require('payments');
  return (select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at desc), '[]')
    from public.money_alerts a where a.closed_at is null);
end;
$$;

create function public.staff_alert_close(p_alert uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: alerts have no client access.
begin
  perform private.staff_require('payments');
  update public.money_alerts set closed_at = now(), closed_by = auth.uid()
  where id = p_alert and closed_at is null;
  if not found then raise exception 'This alert is closed.'; end if;
  perform private.staff_audit('alert_closed', 'money_alert', p_alert::text, p_reason);
end;
$$;

-- Everything left on a payment. After release it comes out of earnings, which
-- can go negative and net against later payouts.
create function public.staff_refund_issue(p_payment uuid, p_reason text) returns bigint
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and the audit log.
declare
  pay public.payments;
  v_refund bigint;
begin
  perform private.staff_require('payments');
  select * into pay from public.payments where id = p_payment;
  if pay.id is null then raise exception 'Not found.' using errcode = 'P0001'; end if;
  perform 1 from public.activities where id = pay.activity_id for update;
  v_refund := private.refund_issue(p_payment, 'staff', 'staff:' || gen_random_uuid(), null, auth.uid());
  if v_refund = 0 then raise exception 'There''s nothing left to refund.'; end if;
  perform private.staff_audit('refund', 'payment', p_payment::text, p_reason,
    jsonb_build_object('refund_minor', v_refund));
  return v_refund;
end;
$$;

create function public.staff_refund_retry(p_refund uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds and the audit log.
begin
  perform private.staff_require('payments');
  update public.refunds set status = 'pending', failure_code = null
  where id = p_refund and status = 'failed';
  if not found then raise exception 'Only a failed refund can be retried.'; end if;
  perform private.staff_audit('refund_retry', 'refund', p_refund::text, p_reason);
end;
$$;

-- Puts the money back where it came from. It counts against the cap no more.
create function public.staff_refund_void(p_refund uuid, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: writes refunds, the ledger and the audit log.
declare
  r public.refunds;
  pay public.payments;
begin
  perform private.staff_require('payments');
  select * into r from public.refunds where id = p_refund for update;
  if r.id is null or r.status not in ('pending', 'failed') then
    raise exception 'Only a pending or failed refund can be voided.';
  end if;
  select * into pay from public.payments where id = r.payment_id for update;
  update public.refunds set status = 'voided', settled_at = now() where id = r.id;
  perform private.ledger_post('refund_void', 'refund_void:' || r.id, pay.currency,
    jsonb_build_object('refund', r.id, 'payment', pay.id),
    jsonb_build_array(private.ledger_line('refunds_pending', null, r.amount_minor),
      case when pay.released_at is null
        then private.ledger_line('held', pay.activity_id, -r.price_minor)
        else private.ledger_line('organizer', pay.organizer_id, -r.price_minor) end,
      private.ledger_line('platform_fees', null, -r.fee_minor)));
  perform private.staff_audit('refund_void', 'refund', r.id::text, p_reason);
end;
$$;

-- Stripe can't return it (a failed PayNow refund, or past 90 days), so staff
-- paid by bank transfer outside Stripe and record that here (Q67 default).
create function public.staff_refund_manual(p_refund uuid, p_reference text, p_reason text) returns void
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
  perform private.ledger_post('refund_paid', 'refund_paid:' || r.id, pay.currency,
    jsonb_build_object('refund', r.id, 'manual', true),
    jsonb_build_array(private.ledger_line('refunds_pending', null, r.amount_minor),
      private.ledger_line('clearing', null, -r.amount_minor)));
  perform private.card_fee_recover(r.payment_id);
  perform private.staff_audit('refund_manual', 'refund', r.id::text, p_reason,
    jsonb_build_object('reference', p_reference));
end;
$$;

-- Closing a report never moves money. Only this does (R-HOLD-4).
create function public.staff_hold_decide(p_activity uuid, p_refund_all boolean, p_reason text) returns void
language plpgsql security definer set search_path = '' as $$
-- Definer: closes the hold and writes refunds.
declare
  pay public.payments;
begin
  perform private.staff_require('payments');
  perform 1 from public.activities where id = p_activity for update;
  update public.activity_money_holds
  set closed_at = now(), closed_by = auth.uid(), reason = p_reason
  where activity_id = p_activity and closed_at is null;
  if not found then raise exception 'There''s no hold on this.'; end if;
  if p_refund_all then
    for pay in
      select * from public.payments where activity_id = p_activity and status = 'succeeded'
        and released_at is null order by id
    loop
      perform private.refund_issue(pay.id, 'staff', 'hold:' || pay.id, null, auth.uid());
    end loop;
  end if;
  perform private.staff_audit('hold_decided', 'activity', p_activity::text, p_reason,
    jsonb_build_object('refund_all', p_refund_all));
end;
$$;

revoke execute on function public.staff_money_overview(), public.staff_payment_list(integer),
  public.staff_payment_get(uuid), public.staff_refund_list(), public.staff_held_list(),
  public.staff_payout_list(), public.staff_dispute_list(), public.staff_alert_list(),
  public.staff_alert_close(uuid, text), public.staff_refund_issue(uuid, text),
  public.staff_refund_retry(uuid, text), public.staff_refund_void(uuid, text),
  public.staff_refund_manual(uuid, text, text), public.staff_hold_decide(uuid, boolean, text)
  from public, anon;
grant execute on function public.staff_money_overview(), public.staff_payment_list(integer),
  public.staff_payment_get(uuid), public.staff_refund_list(), public.staff_held_list(),
  public.staff_payout_list(), public.staff_dispute_list(), public.staff_alert_list(),
  public.staff_alert_close(uuid, text), public.staff_refund_issue(uuid, text),
  public.staff_refund_retry(uuid, text), public.staff_refund_void(uuid, text),
  public.staff_refund_manual(uuid, text, text), public.staff_hold_decide(uuid, boolean, text)
  to authenticated;
