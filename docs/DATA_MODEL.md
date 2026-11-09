# Data model

The starting database design for the first phases, as SQL an agent can turn into migrations. `ARCHITECTURE.md` section 7 lists every domain's tables; this file gives the exact shape of the ones built first, the helper functions every policy uses, and the patterns to copy.

**This is a starting point, not a frozen schema.** Change it through migrations, keep this file in step, and record anything that changes a rule in `RULES.md` or an ADR.

## Conventions

- **Schemas by domain:** `identity`, `orgs`, `activities`, `matches`, `money`, `messaging`, `moderation`, `platform`. Security helpers in `private` (never exposed). Expose to the API only what clients read directly; everything else goes through RPCs.
- **Keys:** `uuid` primary keys, `default gen_random_uuid()`. Public links use opaque tokens, never ids.
- **Time:** `timestamptz` in UTC. Every table has `created_at timestamptz not null default now()`; mutable tables also `updated_at` (set by trigger).
- **Money:** `amount_minor bigint` and `currency char(3)`; never `numeric` floats in application code, never `real`.
- **Enums:** Postgres enums for closed sets that rarely change (status values); lookup tables for sets that grow (sports, permissions).
- **Soft delete:** `deleted_at timestamptz`; RLS hides soft-deleted rows; the retention job erases them later.
- **Sensitivity:** every column is registered in `platform.field_registry` with a level P0 to P4 (`ARCHITECTURE.md` section 19). Add the row in the same migration as the column.
- **Migrations:** one change per file, named `YYYYMMDDHHMMSS_<what>.sql`, each with a pgTAP test file in `supabase/tests/`.

## Names that differ from ARCHITECTURE.md

The architecture doc was written first and uses some earlier names. Use the names in this file and in `API.md`.

| ARCHITECTURE.md | Use |
| --- | --- |
| `profiles`, `user_private`, `consents`, `guardian_links`, `child_profiles`, `user_blocks` | Same names, in the `identity` schema |
| `abuse_reports`, `moderation_cases`, `moderation_decisions` | `moderation.reports`, `moderation.decisions` |
| `organizations`, `organization_members`, `org_roles`, `org_role_permissions` | `orgs.organizations`, `orgs.members`, `orgs.roles`, `orgs.role_permissions` |
| `ledger_accounts`, `ledger_entries` | Same names, in `public`, plus `ledger_transactions` (Phase 4a) |
| `meets.join(meet_id, idempotency_key)` | `activities.join_meet` |
| `payments.refund(...)` | `private.refund_issue` |
| `release_held_funds` job | `private.release_activity`, swept by `private.money_sweep` |

## Shared platform tables

```sql
create extension if not exists citext;
create schema if not exists platform;
create schema if not exists private;

-- Country rules live in data, never in code (R-AGE-2, R-FEE-2).
create table platform.country_config (
  country_code        char(2) primary key,              -- 'SG', 'MY', 'NZ'
  currency            char(3) not null,                 -- 'SGD', 'MYR', 'NZD'
  time_zone           text not null,                    -- 'Asia/Singapore'
  emergency_number    text not null,                    -- '999', '111'
  min_signup_age      int  not null,                    -- 13 in SG
  adult_age           int  not null,                    -- 18
  regulator_name      text,
  enabled             boolean not null default false
);

create table platform.fee_rules (
  id                  uuid primary key default gen_random_uuid(),
  currency            char(3) not null,
  applies_to          text not null,                    -- 'meet','tournament','ticket','court','service','academy'
  percent_bp          int  not null,                    -- basis points: 1000 = 10%
  minimum_minor       bigint not null,                  -- 200 = S$2.00
  valid_from          timestamptz not null default now(),
  valid_to            timestamptz,
  unique (currency, applies_to, valid_from)
);

create table platform.app_settings (                   -- assumed values (OPEN_QUESTIONS) live here
  key                 text primary key,                 -- e.g. 'meet.reservation_minutes'
  value               jsonb not null,
  note                text
);

create table platform.feature_flags (
  key                 text primary key,                 -- 'wallet.topup','camera.scoring','country.my.enabled'
  enabled             boolean not null default false,
  audience            jsonb not null default '{}'       -- optional targeting
);

create table platform.field_registry (
  schema_name text, table_name text, column_name text,
  sensitivity text not null check (sensitivity in ('P0','P1','P2','P3','P4')),
  primary key (schema_name, table_name, column_name)
);

create table platform.idempotency_keys (
  key                 text primary key,
  user_id             uuid not null,
  operation           text not null,
  response            jsonb,
  created_at          timestamptz not null default now()
);

-- Transactional outbox (ACR-006). Written in the same transaction as the change.
create table platform.domain_events (
  event_id            uuid primary key default gen_random_uuid(),
  type                text not null,                    -- 'attendance.recorded'
  schema_version      int  not null default 1,
  aggregate_type      text not null,
  aggregate_id        uuid not null,
  aggregate_version   bigint not null,
  payload             jsonb not null default '{}',      -- opaque ids only, no personal data
  occurred_at         timestamptz not null default now(),
  dispatched_at       timestamptz
);
create table platform.event_consumptions (             -- consumer idempotency
  event_id uuid not null references platform.domain_events, consumer text not null,
  processed_at timestamptz not null default now(),
  primary key (event_id, consumer)
);
```

Seed for Singapore:

```sql
insert into platform.country_config values
  ('SG','SGD','Asia/Singapore','999',13,18,'Online Safety Commission',true),
  ('MY','MYR','Asia/Kuala_Lumpur','999',13,18,'MCMC',false),   -- ages to confirm (Q7)
  ('NZ','NZD','Pacific/Auckland','111',13,18,'Netsafe',false); -- ages to confirm (Q7)
insert into platform.fee_rules (currency, applies_to, percent_bp, minimum_minor)
  select 'SGD', a, 1000, 200 from unnest(array['meet','tournament','ticket','court','academy']) a;
-- No fee rule for services yet: the PRD does not set one. Add it when the owner decides.
insert into platform.app_settings (key, value, note) values
  ('code.resend_seconds', '30', 'R-ACC-3'),
  ('code.max_attempts', '5', 'R-ACC-3'),
  ('code.lockout_minutes', '15', 'R-ACC-3, assumed'),
  ('meet.reservation_minutes', '10', 'R-MET-5, Q23'),
  ('waitlist.offer_minutes', '30', 'R-MET-6, Q5'),
  ('funds.release_after_hours', '24', 'R-HOLD-2'),
  ('account.delete_undo_days', '30', 'R-ACC-11'),
  ('account.audit_keep_years', '10', 'R-ACC-11, Q264'),
  ('account_centre.unlock_minutes', '5', 'R-ACC-8, Q19');
```

## Identity and safety (phase 1)

```sql
create schema if not exists identity;

create type identity.audience_class as enum ('adult','minor_restricted','minor_guardian_managed');
create type identity.moderation_status as enum ('active','limited','suspended');

-- Public profile. Never holds private identity (ACR-002).
create table identity.profiles (
  user_id             uuid primary key references auth.users on delete cascade,
  username            citext unique,                    -- P0 (P1 for minors)
  display_name        text not null,                    -- P0
  avatar_path         text,                             -- P0
  home_area           text,                             -- P1, declared area, never exact location
  audience_class      identity.audience_class not null default 'adult',   -- server-written
  moderation_status   identity.moderation_status not null default 'active', -- server-written
  session_visibility  text not null default 'circle' check (session_visibility in ('public','circle','private')),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

-- Private identity: no public query joins this table.
create table identity.user_private (
  user_id             uuid primary key references auth.users on delete cascade,
  date_of_birth       date,                             -- P3, write-once via RPC
  country_code        char(2) not null references platform.country_config,
  mobile_e164         text unique,                      -- P2, one account per verified mobile (R-ACC-5)
  mobile_verified_at  timestamptz,
  verification_method text
);

create table identity.consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  purpose text not null,                                -- 'location_checkin','marketing','filming'
  granted boolean not null, version text not null,
  granted_at timestamptz not null default now(), withdrawn_at timestamptz
);

create table identity.guardian_links (
  guardian_id uuid not null references auth.users,
  child_id    uuid not null references auth.users,
  scopes      text[] not null default '{}',             -- 'approve','see_sessions','spend','filming'
  status      text not null check (status in ('pending','active','ended')),
  monthly_spend_limit_minor bigint,                     -- R-AGE-5
  verified_at timestamptz, ends_at timestamptz,         -- 18th birthday (R-AGE-4)
  primary key (guardian_id, child_id)
);

create table identity.child_profiles (                  -- under 13, no login (R-AGE-1)
  id uuid primary key default gen_random_uuid(),
  guardian_id uuid not null references auth.users on delete cascade,
  display_name text not null, birth_year int not null   -- P3
);

create table identity.user_blocks (
  blocker_id uuid not null references auth.users on delete cascade,
  blocked_id uuid not null references auth.users on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table public.account_deletions (                  -- built 8 Nov 2026 (P1-14); the auth.users row is never deleted
  user_id uuid primary key references auth.users,
  requested_at timestamptz not null default now(),
  erase_after timestamptz not null,                     -- requested_at + account.delete_undo_days
  cancelled_at timestamptz,                             -- kept the account
  erased_at timestamptz,                                -- private.account_erase ran
  hidden_before boolean not null default false,         -- moderation had hidden them already
  reason text, blocked_reason text, blocked_at timestamptz  -- why the erase is waiting (open money)
);                                                      -- profiles.erased_at marks the "Former player" tombstone

create table identity.rate_limits (                      -- per IP and per device limits (R-ACC-4)
  bucket text not null,                                 -- 'code_send_ip', 'code_send_device', 'search_ip'
  key_hash text not null,                               -- hash of the IP or device id, never the raw value
  window_start timestamptz not null, count int not null default 0,
  primary key (bucket, key_hash, window_start)
);

create table identity.code_attempts (                    -- per target account limits and lockouts (R-ACC-3, R-ACC-4)
  target_hash text not null,                            -- hash of the account id or mobile, never the raw value
  channel text not null, sent_at timestamptz, failed_attempts int not null default 0,
  locked_until timestamptz,
  primary key (target_hash, channel)
);
```

Moderation (phase 1):

```sql
create schema if not exists moderation;
create table moderation.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users,               -- null for the no-account legal notice form
  target_type text not null check (target_type in ('user','message','video','live','listing','review','club','event','statistic')),
  target_id uuid not null,
  reason text not null, urgent boolean not null default false,
  status text not null default 'open' check (status in ('open','in_review','actioned','no_action','second_look')),
  created_at timestamptz not null default now(), due_at timestamptz not null  -- created_at + 24 hours (R-MOD-1)
);
create table moderation.decisions (                       -- kept 3 years (R-MOD-3), append-only
  id uuid primary key default gen_random_uuid(),
  report_id uuid references moderation.reports,
  decided_by uuid not null, second_approver_id uuid,    -- bans need a second approver (R-MOD-4)
  rule text not null, outcome text not null, told jsonb not null default '[]',
  country_code char(2), created_at timestamptz not null default now()
);
create table moderation.staff (                           -- staff accounts and roles (ADM-5)
  user_id uuid primary key references auth.users,
  role text not null check (role in ('trust_safety','payments','partnerships','viewer','admin')),
  mfa_enrolled_at timestamptz not null
);
```

## Helper functions

Every policy uses these, so they are written and tested once.

```sql
create or replace function private.is_active_user(uid uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from identity.profiles p
                 where p.user_id = uid and p.moderation_status <> 'suspended' and p.deleted_at is null);
$$;

create or replace function private.is_blocked_between(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from identity.user_blocks
                 where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a));
$$;

create or replace function private.is_minor(uid uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce((select audience_class <> 'adult' from identity.profiles where user_id = uid), true);
$$;

create or replace function private.is_staff(roles text[] default null)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from moderation.staff s
                 where s.user_id = (select auth.uid()) and (roles is null or s.role = any(roles)));
$$;

revoke all on all functions in schema private from public, anon, authenticated;
grant execute on all functions in schema private to authenticated;   -- callable from policies only
```

## Pattern: a table clients may read but not write

```sql
alter table identity.profiles enable row level security;
revoke update, insert, delete on identity.profiles from authenticated, anon;
grant select on identity.profiles to authenticated;

create policy profiles_read on identity.profiles for select to authenticated
using (
  deleted_at is null
  and private.is_active_user((select auth.uid()))
  and not private.is_blocked_between((select auth.uid()), user_id)
  and (audience_class = 'adult' or user_id = (select auth.uid())
       or exists (select 1 from identity.guardian_links g
                  where g.guardian_id = (select auth.uid()) and g.child_id = user_id and g.status = 'active'))
);

-- Updates to safe columns go through an RPC (identity.update_profile) that checks lengths and words.
-- This policy is the strict starting point. Before P1-08 ships, widen it with tested helpers so that a minor's
-- profile is also visible to their Circle, their team staff and roster (GRP-15, GRP-17) and their opponents
-- for shared results (PAS-24), and never in public Discover (R-AGE-6, R-AGE-7).
```

## Pattern: append-only

```sql
create or replace function private.reject_change() returns trigger language plpgsql as $$
begin raise exception 'append-only table %', tg_table_name using errcode = '42501'; end $$;

create trigger no_update before update or delete on moderation.decisions
  for each row execute function private.reject_change();
revoke update, delete on moderation.decisions from authenticated, anon, service_role;
```

Apply the same to `money.entries`, `money.points_entries` and `platform.domain_events` below, and to `orgs.audit_events` (phase 4) and `matches.ranking_events` (phase 6) when you create them. For `domain_events`, record dispatch in a separate `platform.event_dispatch` table instead of updating `dispatched_at`.

## Organisations (phase 4)

```sql
create schema if not exists orgs;
create type orgs.org_type as enum ('club','academy','team','organiser','brand','venue_operator');  -- team: Q4
create type orgs.visibility as enum ('public','private','hidden');

create table orgs.organizations (
  id uuid primary key default gen_random_uuid(),
  org_type orgs.org_type not null,
  name text not null check (char_length(name) <= 50),   -- R-CLB-1
  description text, visibility orgs.visibility not null default 'public',
  join_by_request boolean not null default false,
  home_venue_id uuid,                                   -- required for clubs (sets the area)
  country_code char(2) not null references platform.country_config,
  status text not null default 'active', verification_state text not null default 'none',
  created_at timestamptz not null default now(), deleted_at timestamptz
);

create table orgs.roles (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references orgs.organizations on delete cascade,
  name text not null, colour text,
  level text not null check (level in ('label','member','organizer','admin','owner')),
  is_system boolean not null default false,             -- the Owner role cannot be changed (R-CLB-5)
  position int not null default 0
);
create table orgs.role_permissions (
  role_id uuid not null references orgs.roles on delete cascade,
  permission text not null,                             -- create_meets, make_meets_public, manage_checkins, run_tournaments,
                                                        -- create_events, approve_join_requests, manage_members, manage_roles,
                                                        -- edit_club_info, view_audit_log, manage_fees_payouts
  primary key (role_id, permission)
);
create table orgs.members (
  org_id uuid not null references orgs.organizations on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  role_id uuid not null references orgs.roles,
  status text not null default 'active' check (status in ('active','banned','left')),
  joined_at timestamptz not null default now(),
  primary key (org_id, user_id)
);

create or replace function private.has_org_permission(p_org uuid, p_permission text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from orgs.members m
    join orgs.roles r on r.id = m.role_id
    left join orgs.role_permissions rp on rp.role_id = r.id and rp.permission = p_permission
    where m.org_id = p_org and m.user_id = (select auth.uid()) and m.status = 'active'
      and (r.level = 'owner' or rp.permission is not null));
$$;
```

## Activities and attendance (phases 2 and 3)

```sql
create schema if not exists activities;
create type activities.kind as enum ('meet','event','tournament');
create type activities.participation_status as enum ('reserved','joined','waitlisted','offered','left','removed');

create table activities.activities (
  id uuid primary key default gen_random_uuid(),
  kind activities.kind not null,
  org_id uuid not null references orgs.organizations,   -- every Meet belongs to a club
  sport_id text not null,
  title text not null,
  starts_at timestamptz not null, ends_at timestamptz not null,
  time_zone text not null,                              -- from the venue
  venue_id uuid,
  visibility text not null default 'members' check (visibility in ('members','public','invite')),  -- R-MET-2
  status text not null default 'published' check (status in ('draft','published','cancelled','completed')),
  series_id uuid,
  attendance_saved_at timestamptz,
  funds_released_at timestamptz,
  version bigint not null default 1,
  created_by uuid not null references auth.users,
  check (ends_at > starts_at)
);

create table activities.meet_settings (
  activity_id uuid primary key references activities.activities on delete cascade,
  game_type text not null check (game_type in ('singles','doubles','social')),
  min_players int not null, max_players int not null,   -- singles >= 2, doubles >= 4, social >= 5 (R-MET-1)
  level_min numeric(3,1), level_max numeric(3,1),
  ranked boolean not null default false,
  fee_mode text not null check (fee_mode in ('paid','free_organizer_pays','free_players_pay')),  -- R-FEE-3, R-FEE-3b
  price_minor bigint not null default 0, currency char(3) not null,
  check (max_players >= min_players),
  check ((game_type = 'singles' and min_players >= 2) or (game_type = 'doubles' and min_players >= 4)
         or (game_type = 'social' and min_players >= 5))
);

create table activities.participations (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references activities.activities on delete cascade,
  user_id uuid not null references auth.users,
  status activities.participation_status not null,
  guest_of uuid references auth.users,                  -- guest spots (R-MET-9)
  waitlist_position int,
  reserved_until timestamptz, offer_expires_at timestamptz,
  order_id uuid,                                        -- money.orders, when paid
  created_at timestamptz not null default now(),
  unique nulls not distinct (activity_id, user_id, guest_of)   -- Postgres 15+
);

create table activities.attendance (
  activity_id uuid not null references activities.activities on delete cascade,
  user_id uuid not null references auth.users,
  status text not null check (status in ('present','absent')),
  method text not null check (method in ('geofence','organizer','qr','walk_in')),
  recorded_by uuid not null, recorded_at timestamptz not null default now(),
  primary key (activity_id, user_id)
);
```

## Matches and ratings (checklist phase 3)

- `scoring_presets`: named rules per sport, with staff able to change them (A-05). `activity_presets` holds an organizer's choice.
- `matches`: rounds from the generator, by round and court.
- `match_scores`: adds `client_key` (unique per person), `supersedes`, `retired_side`, and the status `superseded`. A trigger checks every score against `private.activity_rules`.
- `match_results`: append-only. Made by a trigger when a score becomes confirmed. A correction is a new row with `supersedes`. Neither this table nor `match_scores` has a client read path: they hold real ids, and a roster can show a minor by a stand-in.
- `ratings`, `rating_events`: no client write path. `rating_events` is append-only; a correction adds reversal rows.
- `player_sports.level` follows the rating once a `ratings` row exists.
- `leaderboard_rows`: snapshots from `private.leaderboards_build()`, hourly. `leaderboard_consents`: a guardian's opt-in. Both are read through RPCs that recheck `private.listable`.

## Money

**Built in Phase 4a, in `public` with helpers in `private`, and not as drawn below.** See `supabase/migrations/20261104090000_money_ledger.sql`. Tables: `payments`, `refunds`, `ledger_accounts`, `ledger_transactions`, `ledger_entries`, `stripe_events`, `money_alerts`, `payment_customers`, `activity_money_holds`, `payment_disputes`, `vendors`, `payouts`, `payout_items`, `reconciliation_runs`, `place_qr_tokens`. There is no Wallet (Q45). The sketch below is the earlier design, kept for its reasoning.


```sql
create schema if not exists money;

create table money.accounts (                           -- ledger accounts (ARCHITECTURE 13.2)
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('customer_clearing','held','platform_fees','organizer','wallet',
                                     'card_fee_recovery','payouts_pending','processor_fees')),
  owner_type text, owner_id uuid,                       -- organizer: org or user; wallet: user; held: activity
  currency char(3) not null,
  unique (kind, owner_type, owner_id, currency)
);

create table money.transactions (                       -- one business event = one transaction
  id uuid primary key default gen_random_uuid(),
  kind text not null,                                   -- 'payment','release','refund','payout','card_fee','withdrawal'
  idempotency_key text not null unique,
  reference jsonb not null default '{}',                -- order id, activity id, stripe ids
  created_at timestamptz not null default now()
);

create table money.entries (                            -- append-only, double-entry
  id bigserial primary key,
  transaction_id uuid not null references money.transactions,
  account_id uuid not null references money.accounts,
  amount_minor bigint not null check (amount_minor <> 0), -- positive = debit, negative = credit
  currency char(3) not null,
  created_at timestamptz not null default now()
);
-- Every transaction balances to zero per currency: enforce with a deferred constraint trigger.

create table money.orders (
  id uuid primary key default gen_random_uuid(),
  payer_id uuid not null references auth.users,
  purpose text not null,                                -- 'meet','tournament','ticket','court','academy_fee','service','shop'
  activity_id uuid,
  price_minor bigint not null, fee_minor bigint not null, total_minor bigint not null,
  currency char(3) not null,
  method text not null check (method in ('card','paynow','wallet','apple_pay','google_pay')),
  status text not null check (status in ('pending','paid','failed','refunded','partly_refunded')),
  refund_rule_shown text not null,                      -- the rule text shown before paying (R-REF-20)
  stripe_payment_intent_id text unique,
  created_at timestamptz not null default now(),
  check (total_minor = price_minor + fee_minor)
);

create table money.refunds (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references money.orders,
  reason text not null check (reason in ('organizer_cancelled','player_in_time','removed_from_club','account_deleted',
                                          'partner_declined','medical','event_below_minimum','change_by_organizer','dispute')),
  destination text not null check (destination in ('wallet','original_method')),
  amount_minor bigint not null check (amount_minor > 0),
  card_fee_charged_to_organizer_minor bigint not null default 0,
  status text not null default 'pending', idempotency_key text not null unique,
  created_at timestamptz not null default now()
);

create table money.stripe_events (                      -- webhook log, idempotent on Stripe's id
  id text primary key, type text not null, payload jsonb not null,
  received_at timestamptz not null default now(), processed_at timestamptz
);

create table money.points_entries (                     -- separate ledger (see The Shop and points)
  id bigserial primary key, user_id uuid not null references auth.users,
  amount_hundredths bigint not null, reason text not null, source_order_id uuid,
  expires_at timestamptz,                               -- 12 months (R-PTS-4)
  created_at timestamptz not null default now()
);

create view money.balances with (security_invoker = true) as
  select a.id as account_id, a.kind, a.owner_type, a.owner_id, a.currency, coalesce(sum(e.amount_minor), 0) as balance_minor
  from money.accounts a left join money.entries e on e.account_id = a.id group by a.id;
```

## The Shop and points

**Built in Phase 4b, in `public` with helpers in `private`, and not as drawn above.** See `supabase/migrations/20261105090000_shop_partner.sql`, `20261105100000_points.sql` and `20261105110000_shop_money.sql`.

- `malls` are partner shops: `owner_id` (one shop per owner, nullable until linked), `active`, `commission_on_top`, `collect_address`. `addresses` and `order_returns` are gone, as are delivery columns and `products.max_points`.
- `orders` have one payment each (`payments.order_id`), with `step` moving only through `private.order_transitions`. `collect_by` and `release_at` are stamped once at capture.
- `order_lines` store unit amounts with a check that `unit_paid = unit_shop + unit_commission - unit_points`, so refunds by quantity need no rounding.
- `payments.held_owner` is `coalesce(activity_id, order_id)` and owns the `held` account. Commission is recognised at release, so a cancel has nothing to reverse.
- `points_entries` is append-only and holds cents. Each earn is a lot with its own expiry, spending takes the oldest first, and a balance is a sum over unexpired lots. `points_blocks` stops a player earning.
- `private.order_unreserve` is the only place stock and points come back, guarded by `orders.unreserved_at`.
- Lock order: the buyer's advisory lock, then the order, the payment, then products by id.

## Academy, lessons, assessments and services

**Built in Phase 4c, in `public`.** See `supabase/migrations/20261106090000_academy_verification.sql` onwards. `field_registry` doesn't exist yet (Q100), so sensitivity is noted here.

- `academies` gains `uen` (P2), `licence_path` (P3, cleared after the check), `rejected_reason` and `closed_at`. Closing is soft, so records outlive the academy.
- `coach_licences` holds one row per person: `nroc_number` (P2), `expires_on`, `status`, `file_path` (P3, cleared after the check). `verified_at` is set once, so a renewal under review keeps the classes a coach has.
- `coach_profiles` is public text a coach writes about themself (P1).
- `academy_coaches.accepted_at` is null until the coach says yes.
- `academy_students.player_id` links to the account (P2, a child's). Old rows without one can't be booked or assessed.
- `academy_makeup_credits` gives each credit its own expiry, and `source` is unique so each cause gives one.
- `lesson_slots` has an exclusion constraint on coach and time. `lesson_slot_add` takes a per-coach lock first, because two overlapping inserts would otherwise deadlock.
- `lesson_bookings` has no foreign keys, as money outlives everything, and carries name snapshots. `private.lesson_transitions` lists the allowed steps. Partial unique indexes stop a slot or seat being sold twice.
- `payments.lesson_booking_id` is a third owner beside `activity_id` and `order_id`, and `held_owner` is the coalesce of the three.
- `assessments` and `assessment_scores` hold a child's record (P3) with their own name snapshots and no foreign key to the academy. Writes are revoked from clients, and reads go through RLS.
- `service_referrals` has five columns only, by design (P3, it implies a health interest).



## Game

**Built in Phase 4d, in `public`.** See `supabase/migrations/20261107090000_game_engine.sql`.

- `organizer_games` has one row per Meet looked at, once its money has settled, with `reason` and a lifetime `game_no` on counted games. The group ranking reads it, so one rule decides both. `campaign_game_log` stays as the first-save record.
- `reward_grants.key` is unique, which is what stops a retry issuing twice. A grant waits as `pending` until the reward opens and a default type exists.
- `vouchers.source` is unique for the same reason. `code` (P3) goes only to the owner. `expires_at` is null while `held`.
- `voucher_redemptions` is append-only: who, which shop, which order, when, and no code.
- `order_lines.unit_voucher` holds what the voucher took off one unit. `orders.voucher_id` is what `private.order_unreserve` hands back.

## Fitness

All in `public`, with no client access. Every read and write goes through the functions in `API.md`.

| Table | Holds |
| --- | --- |
| `exercises` | The catalogue, with `minors_ok`, `unit` (reps or seconds) and `weighted` |
| `programs` | A player's programs. A template has no owner |
| `program_days`, `program_items` | Days, and the exercises on them. A day's name is optional |
| `workouts` | The log. `client_key` is unique per player. `program_id` clears if the program is deleted |
| `workout_sets` | Each finished set. Weight is `weight_g`, in whole grams |
| `ai_plan_requests` | One row per AI plan: status, tokens and model. Never the prompt or the answer |

`programs.source` is `player` or `ai`. `consents.kind` also allows `ai_plans`.

## Video analysis

All in `public`, with no client access. Files are in the private `analysis-clips` bucket, as `<owner>/<clip>.mp4` and `<owner>/<clip>.frame.jpg`.

| Table | Holds |
| --- | --- |
| `video_clips` | One clip: owner, the person in it, status, side, corners, `purge_at`, `file_gone_at` |
| `video_consents` | One row per clip of a child: parent, wording version, when it was given and withdrawn |
| `analysis_jobs` | `court` and `analyse` jobs. Only a hash of the token is kept |
| `analysis_reports` | Distance, speeds, moving time and a 13 by 6 heatmap grid. No image, and nothing about an opponent |
| `storage_deletions` | Paths still to remove. Filled when a clip's row goes or its time is up |

## Video feed

All in `public`, with no client access. Files are in the private `feed-videos` bucket, as `<author>/<post>.mp4` and `.poster.jpg`, which no client can read or write: uploads and reads use short signed URLs from `feed-media`. `storage_deletions` has a `bucket` column, and one sweep clears both buckets.

| Table | Holds |
| --- | --- |
| `video_posts` | One post: author, caption (`body`), sport, country, audience, status, `video_host`, `video_ref`, `file_version`, `hash_cleared_at`, `approved_at`, `hidden_at` |
| `post_likes` | One like per person per post |
| `post_jobs` | One check per post, with a hashed token |
| `abuse_matches` | Append-only, with no foreign keys, so a match outlives the post and the account |

`private.post_transitions` holds the allowed status changes. A check constraint keeps anything out of `review` and `live` without `hash_cleared_at`. `private.post_visible(post, viewer)` decides every read, like and play.

## Tests every migration in this file needs

- RLS on for every table (CI meta-test).
- For each table, a read test as: the owner, another member, an outsider, a blocked user, a minor, a suspended user, anonymous.
- Clients cannot insert, update or delete protected tables directly.
- Append-only tables reject update and delete, even for `service_role`.
- `money.transactions` always balance per currency.
- `activities.meet_settings` rejects game types below their minimum players.
