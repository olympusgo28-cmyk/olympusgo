-- P4a-01: money tables and the double-entry ledger. Stripe test mode only
-- (Q46). Amounts are integer minor units. Balances are never stored.

do $$
begin
  if exists (select 1 from public.payments) then
    raise exception 'payments has rows: migrate them before changing its shape';
  end if;
end;
$$;

insert into public.app_settings (key, value, description) values
  ('meet.reservation_minutes', '10', 'How long a spot is held while payment completes (Q23)'),
  ('waitlist.offer_minutes', '30', 'How long a waitlist offer lasts (Q5)'),
  ('funds.release_after_hours', '24', 'Hours after the end that held money is released (R-HOLD-2)'),
  ('money.hold_alert_days', '75', 'Alert on money held this long (R-HOLD-7)'),
  ('money.max_advance_days', '75', 'A paid booking must end within this many days'),
  ('money.vendor_alert_days', '60', 'Alert when earnings wait this long on vendor checks'),
  ('money.debt_alert_days', '30', 'Flag organizer shortfalls this old (Q12)'),
  ('money.change_refund_hours', '48', 'Full refund window after an organizer change (R-REF-17)'),
  ('money.recon_timing_hours', '48', 'Newer differences count as timing, not mismatch'),
  ('payout.second_approver_minor', '500000', 'A run above this needs a second approver (Q9)');

insert into public.feature_flags (key, enabled, description) values
  ('payments.tournament', false, 'Paid tournament entries. Off until that flow is built.');

-- Money records outlive accounts and activities, so they keep opaque ids.
alter table public.payments
  drop constraint payments_user_id_fkey,
  drop constraint payments_activity_id_fkey,
  drop constraint payments_method_check,
  drop constraint payments_status_check,
  drop column amount_cents,
  drop column platform_fee_cents,
  drop column provider_reference,
  alter column method drop not null,
  alter column receipt_no set default 'OG-' || upper(substr(md5(gen_random_uuid()::text), 1, 12)),
  alter column status set default 'pending',
  add column purpose text not null
    check (purpose in ('meet', 'ticket', 'tournament', 'host_spot', 'organizer_fee', 'debt')),
  add column qty integer not null default 1 check (qty between 1 and 10),
  add column price_minor bigint not null check (price_minor >= 0),
  add column fee_minor bigint not null check (fee_minor >= 0),
  add column amount_minor bigint not null check (amount_minor > 0),
  add column organizer_id uuid,
  add column beneficiary_id uuid,
  add column rule_snapshot jsonb not null,
  add column idempotency_key text not null,
  add column stripe_intent_id text unique,
  add column stripe_charge_id text unique,
  add column processor_fee_minor bigint check (processor_fee_minor >= 0),
  add column failure_code text,
  add column hold_until timestamptz,
  add column captured_at timestamptz,
  add column released_at timestamptz,
  add constraint payments_total check (amount_minor = price_minor + fee_minor),
  add constraint payments_method_check check (method in ('card', 'paynow')),
  add constraint payments_status_check
    check (status in ('pending', 'succeeded', 'cancel_requested', 'cancelled', 'debt')),
  add constraint payments_key unique (user_id, idempotency_key);

create unique index payments_one_live on public.payments (activity_id, user_id, purpose)
  where status = 'pending' and purpose in ('meet', 'ticket', 'tournament', 'host_spot');
create index payments_activity_idx on public.payments (activity_id, status);
create index payments_release_idx on public.payments (captured_at)
  where status = 'succeeded' and released_at is null;

create table private.payment_transitions (
  from_status text not null,
  to_status text not null,
  primary key (from_status, to_status)
);
insert into private.payment_transitions values
  ('pending', 'succeeded'), ('pending', 'cancel_requested'), ('pending', 'cancelled'),
  ('pending', 'debt'), ('cancel_requested', 'succeeded'), ('cancel_requested', 'cancelled'),
  ('debt', 'cancelled');

create function private.payment_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'payments are never deleted';
  end if;
  if (new.user_id, new.activity_id, new.purpose, new.qty, new.price_minor, new.fee_minor,
      new.amount_minor, new.currency, new.organizer_id, new.beneficiary_id,
      new.rule_snapshot, new.idempotency_key)
     is distinct from
     (old.user_id, old.activity_id, old.purpose, old.qty, old.price_minor, old.fee_minor,
      old.amount_minor, old.currency, old.organizer_id, old.beneficiary_id,
      old.rule_snapshot, old.idempotency_key) then
    raise exception 'A payment''s amounts can''t change';
  end if;
  if new.status <> old.status and not exists (
      select 1 from private.payment_transitions t
      where t.from_status = old.status and t.to_status = new.status) then
    raise exception 'A payment can''t go from % to %', old.status, new.status;
  end if;
  return new;
end;
$$;
create trigger payments_guard before update or delete on public.payments
  for each row execute function private.payment_guard();

-- A refund's status follows Stripe's answer. 'manual' is staff recording a
-- bank transfer when Stripe can't return the money (Q67 default).
create table public.refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments (id) on delete restrict,
  reason text not null check (reason in ('organizer_cancelled', 'player_in_time', 'host_spot',
    'removed_from_club', 'account_deleted', 'partner_declined', 'medical',
    'event_below_minimum', 'change_by_organizer', 'late_no_spot', 'blocked', 'player_left',
    'staff')),
  price_minor bigint not null default 0 check (price_minor >= 0),
  fee_minor bigint not null default 0 check (fee_minor >= 0),
  amount_minor bigint generated always as (price_minor + fee_minor) stored,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'succeeded', 'failed', 'voided', 'manual')),
  organizer_pays_fee boolean not null default false,
  stripe_refund_id text unique,
  failure_code text,
  idempotency_key text not null unique,
  actor uuid,
  created_at timestamptz not null default now(),
  settled_at timestamptz,
  constraint refunds_some_money check (price_minor + fee_minor > 0)
);
create index refunds_payment_idx on public.refunds (payment_id);
create index refunds_work_idx on public.refunds (created_at) where status = 'pending';

create table private.refund_transitions (
  from_status text not null,
  to_status text not null,
  primary key (from_status, to_status)
);
insert into private.refund_transitions values
  ('pending', 'processing'), ('pending', 'voided'), ('processing', 'succeeded'),
  ('processing', 'failed'), ('failed', 'pending'), ('failed', 'voided'), ('failed', 'manual'),
  ('processing', 'manual'), ('pending', 'succeeded'), ('pending', 'failed');

-- The cap: lock the payment, then sum everything not voided. Failed refunds
-- still count, because the money may yet be sent. Price and fee are capped
-- separately so a refund can't turn one into the other.
create function private.refund_guard() returns trigger
language plpgsql set search_path = '' as $$
declare
  p public.payments;
  v_price bigint;
  v_fee bigint;
begin
  if tg_op = 'DELETE' then
    raise exception 'refunds are never deleted';
  end if;
  if tg_op = 'UPDATE' then
    if (new.payment_id, new.reason, new.price_minor, new.fee_minor, new.idempotency_key,
        new.organizer_pays_fee)
       is distinct from
       (old.payment_id, old.reason, old.price_minor, old.fee_minor, old.idempotency_key,
        old.organizer_pays_fee) then
      raise exception 'A refund''s amounts can''t change';
    end if;
    if new.status <> old.status and not exists (
        select 1 from private.refund_transitions t
        where t.from_status = old.status and t.to_status = new.status) then
      raise exception 'A refund can''t go from % to %', old.status, new.status;
    end if;
    return new;
  end if;
  select * into p from public.payments where id = new.payment_id for update;
  if p.status <> 'succeeded' then
    raise exception 'Only a captured payment can be refunded';
  end if;
  select coalesce(sum(price_minor), 0), coalesce(sum(fee_minor), 0) into v_price, v_fee
  from public.refunds where payment_id = new.payment_id and status <> 'voided';
  if v_price + new.price_minor > p.price_minor or v_fee + new.fee_minor > p.fee_minor then
    raise exception 'A refund can''t exceed what was captured';
  end if;
  return new;
end;
$$;
create trigger refunds_guard before insert or update or delete on public.refunds
  for each row execute function private.refund_guard();

create table public.ledger_accounts (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('clearing', 'held', 'platform_fees', 'organizer',
    'refunds_pending', 'processor_fees', 'card_fee_recovery', 'organizer_fee_debt',
    'payouts_pending', 'suspense')),
  owner_id uuid,
  currency text not null,
  created_at timestamptz not null default now(),
  unique (id, currency)
);
create unique index ledger_accounts_one on public.ledger_accounts
  (kind, coalesce(owner_id, '00000000-0000-0000-0000-000000000000'::uuid), currency);

create table public.ledger_transactions (
  id uuid primary key default gen_random_uuid(),
  kind text not null,
  idempotency_key text not null unique,
  currency text not null,
  reference jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table public.ledger_entries (
  id bigint generated always as identity primary key,
  transaction_id uuid not null references public.ledger_transactions (id),
  account_id uuid not null,
  currency text not null,
  amount_minor bigint not null check (amount_minor <> 0),  -- positive debit, negative credit
  created_at timestamptz not null default now(),
  foreign key (account_id, currency) references public.ledger_accounts (id, currency)
);
create index ledger_entries_account_idx on public.ledger_entries (account_id);
create index ledger_entries_tx_idx on public.ledger_entries (transaction_id);

create trigger ledger_entries_no_change before update or delete on public.ledger_entries
  for each row execute function private.forbid_change();
create trigger ledger_entries_no_truncate before truncate on public.ledger_entries
  for each statement execute function private.forbid_change();
create trigger ledger_transactions_no_change before update or delete on public.ledger_transactions
  for each row execute function private.forbid_change();
create trigger ledger_transactions_no_truncate before truncate on public.ledger_transactions
  for each statement execute function private.forbid_change();

-- Every transaction balances, checked at commit so all its lines are in.
create function private.ledger_balanced() returns trigger
language plpgsql security definer set search_path = '' as $$
-- Definer: it fires at commit, after the definer that posted has returned, so
-- it runs as the player, who can't read the ledger.
declare
  v_tx uuid;
  v_lines int;
  v_off int;
begin
  if tg_table_name = 'ledger_entries' then
    v_tx := new.transaction_id;
  else
    v_tx := new.id;
  end if;
  select count(*) into v_lines from public.ledger_entries where transaction_id = v_tx;
  select count(*) into v_off from (
    select currency from public.ledger_entries where transaction_id = v_tx
    group by currency having sum(amount_minor) <> 0) x;
  if v_lines < 2 or v_off > 0 then
    raise exception 'Ledger transaction % does not balance', v_tx;
  end if;
  return null;
end;
$$;
create constraint trigger ledger_entries_balanced after insert on public.ledger_entries
  deferrable initially deferred for each row execute function private.ledger_balanced();
create constraint trigger ledger_transactions_balanced after insert on public.ledger_transactions
  deferrable initially deferred for each row execute function private.ledger_balanced();

create function private.ledger_account(p_kind text, p_owner uuid, p_currency text) returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: no client role touches ledger tables.
declare
  v_id uuid;
begin
  select id into v_id from public.ledger_accounts
  where kind = p_kind and owner_id is not distinct from p_owner and currency = p_currency;
  if v_id is null then
    insert into public.ledger_accounts (kind, owner_id, currency)
    values (p_kind, p_owner, p_currency)
    on conflict do nothing
    returning id into v_id;
  end if;
  if v_id is null then
    select id into v_id from public.ledger_accounts
    where kind = p_kind and owner_id is not distinct from p_owner and currency = p_currency;
  end if;
  return v_id;
end;
$$;

create function private.ledger_line(p_kind text, p_owner uuid, p_minor bigint) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object('kind', p_kind, 'owner', p_owner, 'minor', p_minor);
$$;

-- The only writer of the ledger. A repeated key does nothing and returns null.
create function private.ledger_post(p_kind text, p_key text, p_currency text, p_ref jsonb, p_lines jsonb)
returns uuid
language plpgsql security definer set search_path = '' as $$
-- Definer: no client role touches ledger tables.
declare
  v_id uuid;
  l jsonb;
begin
  if (select coalesce(sum((x ->> 'minor')::bigint), 0) from jsonb_array_elements(p_lines) x) <> 0 then
    raise exception 'Ledger lines for % do not balance', p_key;
  end if;
  if not exists (select 1 from jsonb_array_elements(p_lines) x where (x ->> 'minor')::bigint <> 0) then
    return null;
  end if;
  insert into public.ledger_transactions (kind, idempotency_key, currency, reference)
  values (p_kind, p_key, p_currency, p_ref)
  on conflict (idempotency_key) do nothing
  returning id into v_id;
  if v_id is null then return null; end if;
  for l in select x from jsonb_array_elements(p_lines) x where (x ->> 'minor')::bigint <> 0 loop
    insert into public.ledger_entries (transaction_id, account_id, currency, amount_minor)
    values (v_id,
      private.ledger_account(l ->> 'kind', nullif(l ->> 'owner', '')::uuid, p_currency),
      p_currency, (l ->> 'minor')::bigint);
  end loop;
  return v_id;
end;
$$;

create function private.ledger_balance(p_kind text, p_owner uuid, p_currency text) returns bigint
language sql stable security definer set search_path = '' as $$
  -- Definer: no client role touches ledger tables.
  select coalesce(sum(e.amount_minor), 0)::bigint
  from public.ledger_entries e
  join public.ledger_accounts a on a.id = e.account_id
  where a.kind = p_kind and a.owner_id is not distinct from p_owner and a.currency = p_currency;
$$;

create table public.stripe_events (
  id text primary key,
  type text not null,
  payload jsonb not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);

create table public.money_alerts (
  id uuid primary key default gen_random_uuid(),
  kind text not null,
  key text not null unique,
  detail jsonb not null default '{}',
  created_at timestamptz not null default now(),
  closed_at timestamptz,
  closed_by uuid
);
create index money_alerts_open_idx on public.money_alerts (created_at) where closed_at is null;

create function private.money_alert(p_kind text, p_key text, p_detail jsonb default '{}') returns void
language sql security definer set search_path = '' as $$
  -- Definer: money_alerts has no client access.
  insert into public.money_alerts (kind, key, detail) values (p_kind, p_key, p_detail)
  on conflict (key) do nothing;
$$;

-- A saved card for organizer-pays Meets. Last four digits only (R-PAY-6).
create table public.payment_customers (
  user_id uuid primary key,
  stripe_customer_id text not null unique,
  payment_method_id text,
  card_brand text,
  card_last4 text check (card_last4 ~ '^[0-9]{4}$'),
  updated_at timestamptz not null default now()
);

create table public.activity_money_holds (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null,
  case_id uuid,
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  closed_by uuid,
  reason text
);
create unique index activity_money_holds_open on public.activity_money_holds (activity_id)
  where closed_at is null;

create table public.payment_disputes (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments (id) on delete restrict,
  stripe_dispute_id text not null unique,
  amount_minor bigint not null check (amount_minor > 0),
  status text not null default 'open' check (status in ('open', 'won', 'lost')),
  created_at timestamptz not null default now(),
  closed_at timestamptz
);

create table public.vendors (
  owner_id uuid primary key,
  stripe_account_id text unique,
  status text not null default 'pending' check (status in ('pending', 'verified', 'rejected')),
  schedule text not null default 'weekly' check (schedule in ('weekly', 'monthly', 'off')),
  currency text not null default 'SGD',
  created_at timestamptz not null default now(),
  verified_at timestamptz
);

create table public.payouts (
  id uuid primary key default gen_random_uuid(),
  currency text not null,
  week_start date not null,
  status text not null default 'prepared'
    check (status in ('prepared', 'approved', 'superseded')),
  total_minor bigint not null check (total_minor >= 0),
  first_approver uuid,
  second_approver uuid,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  unique (currency, week_start),
  constraint payouts_two_people check (second_approver is null or second_approver <> first_approver)
);

create table public.payout_items (
  id uuid primary key default gen_random_uuid(),
  payout_id uuid not null references public.payouts (id) on delete restrict,
  owner_id uuid not null,
  amount_minor bigint not null check (amount_minor >= 0),
  status text not null default 'prepared'
    check (status in ('prepared', 'pending', 'sent', 'failed', 'dropped')),
  stripe_transfer_id text unique,
  failure_code text,
  unique (payout_id, owner_id)
);

create table public.reconciliation_runs (
  id uuid primary key default gen_random_uuid(),
  ran_at timestamptz not null default now(),
  matched integer not null,
  timing integer not null,
  mismatches jsonb not null default '[]'
);

alter table public.refunds enable row level security;
alter table public.ledger_accounts enable row level security;
alter table public.ledger_transactions enable row level security;
alter table public.ledger_entries enable row level security;
alter table public.stripe_events enable row level security;
alter table public.money_alerts enable row level security;
alter table public.payment_customers enable row level security;
alter table public.activity_money_holds enable row level security;
alter table public.payment_disputes enable row level security;
alter table public.vendors enable row level security;
alter table public.payouts enable row level security;
alter table public.payout_items enable row level security;
alter table public.reconciliation_runs enable row level security;

revoke all on public.ledger_accounts, public.ledger_transactions, public.ledger_entries,
  public.stripe_events, public.money_alerts, public.payment_customers,
  public.activity_money_holds, public.payment_disputes, public.payouts, public.payout_items,
  public.reconciliation_runs
  from anon, authenticated;
revoke all on public.payments, public.refunds, public.vendors from anon;
revoke insert, update, delete, truncate on public.payments, public.refunds, public.vendors
  from authenticated;

create policy "Players see their own refunds" on public.refunds for select to authenticated
  using (exists (select 1 from public.payments p
    where p.id = payment_id and p.user_id = (select auth.uid())));
create policy "Owners see their payout account" on public.vendors for select to authenticated
  using (owner_id = (select auth.uid()));

-- Only the database functions write these.
revoke execute on function private.ledger_post(text, text, text, jsonb, jsonb),
  private.ledger_account(text, uuid, text), private.money_alert(text, text, jsonb)
  from public, anon, authenticated, service_role;
