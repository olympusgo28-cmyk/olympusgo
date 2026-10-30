# AGENTS.md — OlympusGO

Instructions for AI coding agents (Claude Code, Cursor, Codex and similar) and the people who supervise them. Read this file first, every session. It is short on purpose: it tells you how to work here and where the detail lives.

## What you are building

OlympusGO is a sports community app for Singapore first, then Malaysia and New Zealand. Players find and join Meets (one-day club games), tournaments and events, pay, check in, record scores, and build a Passport (rating, sessions, badges). Clubs, academies, sellers and creators run their side in the same app, and two web apps serve academy owners and Olympus staff.

This repository holds a working app. Phase 0 and most of Phase 1 of `docs/DEVELOPER_CHECKLIST.md` are done on top of an earlier build; see `docs/features/phase-1-status.md` for what is and is not finished.

## Sources of truth, in order

When two sources disagree, the higher one wins. If the disagreement matters to your task, stop and record it in `docs/OPEN_QUESTIONS.md` instead of picking one.

1. **A written decision by the owner** in `docs/OPEN_QUESTIONS.md` (marked Decided) or a later ADR in `docs/adr/`.
1b. **`docs/DEVELOPER_CHECKLIST.md`** (30 Oct), the newest document. See Q27 to Q39 for where it differs from the files below.
2. **`docs/RULES.md`**: every business rule with exact numbers. Money, refunds, ages, codes, attendance.
3. **`docs/PRD.md`** and **`docs/PRD_TOURNAMENTS_SPORT_PROFILE.md`**: requirements with IDs (ACC-1, MET-6, PAY-2, TRN-14 …), release stage and screens.
4. **`docs/ARCHITECTURE.md`**: how the system is built (Supabase, RLS, RPCs, outbox, ledger), and the approved architecture change requests (ACR-001 to ACR-018) it builds on.
5. **The design canvases** (`docs/SCREENS.md` explains them): layout, copy and behaviour of each screen.
6. **`docs/DESIGN_SYSTEM.md`**: colours, type, spacing and components. Its suggested standard (the OlympusGO Design System) takes precedence over colours and fonts drawn on older canvas screens until the owner answers Q15.

**Names.** Use the table, function and schema names in `docs/DATA_MODEL.md` and `docs/API.md`. `ARCHITECTURE.md` describes the same design but sometimes with earlier names (`meets.join`, `ledger_entries`); `DATA_MODEL.md` lists those differences.

## Stack (assumed, confirm in week 1)

| Part | Choice |
| --- | --- |
| Phone app | Flutter (Dart), iOS and Android, GoRouter, Riverpod |
| Partner web (academy, club, merchant) and admin web | Flutter web, sharing `packages/core` and `packages/ui` |
| Public site | Next.js |
| Backend | Supabase in the Singapore region: Postgres with RLS, Auth (email OTP), PostgREST RPCs, Realtime, Storage, Edge Functions (Deno, TypeScript), pgmq queues, pg_cron |
| Payments | Stripe Connect (blocked on a legal decision, see OPEN_QUESTIONS Q1) |
| Messages | Firebase Cloud Messaging, a transactional email service, Twilio SMS and WhatsApp |
| Media | Cloudflare R2 (photos, files), Cloudflare Stream (video, live) |

The app is a single Flutter project at the repository root (`lib/core`, `lib/features/<name>/{data,domain,application,presentation}`), with `supabase/` beside it. The monorepo in `docs/ARCHITECTURE.md` section 4 was not used. Migrations use the existing timestamp names, not `NNNN_topic.sql`. Tables stay in `public`; helpers that no client should call go in `private`.

## Golden rules

These are not style preferences. Breaking one is a failed task, however good the rest is.

1. **Never touch production.** You work in a local Supabase or the shared development project. You never hold the production service-role key, production database URL or live Stripe keys. If a task seems to need them, stop.
2. **The database enforces the rules.** Every table in an exposed schema has RLS on. Clients never write protected columns (status, role, audience class, moderation status, date of birth, balances). State changes go through RPCs that check an allowed-transition table. See `docs/ARCHITECTURE.md` section 8.
3. **Money is a ledger.** Never store or update a balance. Every payment, hold, fee, refund, payout and points movement is an append-only entry; balances are sums. Amounts are integer minor units (cents) plus a currency code. Never use floating point for money.
4. **Every consequential call is idempotent.** Joining, paying, refunding, paying out and confirming a score take an `idempotency_key` with a unique constraint. Webhooks are idempotent on the provider's event id.
5. **Minors are protected by default.** Age status (`audience_class`) is set by the server. Under-18 rules (no Public visibility, no private messages from adults, no paid gifting, parent consent for filming) are enforced in RLS and RPCs, never only in the app.
6. **Sign-in never reveals whether an account exists.** Same response, padded timing, rate limits per target account.
7. **Do not guess a product rule.** If a number or behaviour is not in `docs/RULES.md` or the PRD, or is marked [Open], do not invent one. Add it to `docs/OPEN_QUESTIONS.md`, read the value from config (`country_config`, `fee_rules`, `app_settings`, `feature_flags`) with the suggested default, and say so in your summary.
8. **No personal data in logs, events or analytics.** Opaque ids only. Never log codes, emails, phone numbers, card details or dates of birth.
9. **Tests come with the change.** A migration ships with pgTAP tests for its RLS and RPCs. A money rule ships with a unit test per row of its table in `docs/RULES.md`. A screen ships with a widget test and, when it completes a journey, an integration test (see `docs/TESTING.md`).
10. **Stay in scope.** Do one ticket from `docs/BUILD_PLAN.md` at a time. Do not refactor unrelated code or add features nobody asked for.

## How to do a task

1. Pick the ticket in `docs/BUILD_PLAN.md`. Check its dependencies are done.
2. Read the requirement IDs it names in the PRD, and every rule in `docs/RULES.md` that the ticket touches.
3. Look at the screens it names (`docs/SCREENS.md` says where). Copy the wording from the screens; it was written carefully.
4. Check `docs/OPEN_QUESTIONS.md` for anything that blocks the ticket. If a blocker is still Open, build behind a config value or a feature flag, or stop and report.
5. Plan before coding when the ticket touches auth, money, minors or RLS. Write the plan in the pull request description.
6. Write the migration, then its pgTAP tests, then the RPC or Edge Function, then the client code, then its tests.
7. Run every check (below). Fix what fails. Do not disable a test to make it pass.
8. Update docs if behaviour changed: `docs/DATA_MODEL.md`, `docs/API.md`, and the ticket's status in `docs/BUILD_PLAN.md`.
9. Write a short summary: what changed, which requirement IDs it covers, what you could not do, and any question you added.

## Checks to run before you call a task done

Commands assume the repo layout in the architecture doc. Fill in real scripts in phase 0 (ticket P0-02) and keep this list in step with them.

```bash
# database
supabase start
supabase db reset                 # applies every migration from scratch
supabase test db                  # pgTAP: RLS, grants, RPCs, races, idempotency
supabase db lint                  # plus the custom SQL lints in supabase/tests/lint

# edge functions
deno fmt --check supabase/functions && deno lint supabase/functions
deno test -A supabase/functions

# flutter: run in each app and package folder (apps/mobile, apps/partner_web, apps/admin_web, packages/*),
# or from the root with melos once P0-01 sets it up (melos run analyze, melos run test)
dart format --set-exit-if-changed .
flutter analyze
flutter test                      # unit and widget tests
flutter test integration_test     # journeys, against local Supabase (apps/mobile)

# public site (in apps/site)
npm run lint && npm test
```

## Definition of done

- [ ] The ticket's acceptance criteria in `docs/BUILD_PLAN.md` are met.
- [ ] Every table you added has RLS on and tests for each role: owner, member, outsider, blocked user, minor, suspended user, anonymous.
- [ ] Every RPC you added revokes `PUBLIC` and `anon` execute, grants only what it needs, and has a test.
- [ ] New columns are registered in `field_registry` with a sensitivity level (P0 to P4).
- [ ] No money arithmetic outside the helpers in `packages/core` (Dart) and `supabase/functions/_shared/money.ts` (TypeScript) and the SQL ledger functions.
- [ ] Screens handle loading, empty, offline and error states, have 44 px tap targets, screen-reader labels on icon buttons, and use design tokens only (no raw hex colours in widgets).
- [ ] All checks above pass locally and in CI.
- [ ] Docs updated, summary written.

## Review by change type

From ACR-017. Ask for these reviews in the pull request; an agent never approves its own change.

| Change | Reviews needed |
| --- | --- |
| Migration, RPC, RLS | Security and architecture |
| Sign-in, age, guardians, minors | Security, privacy and architecture |
| Money (payments, refunds, ledger, payouts, points) | Two human reviewers |
| New screen | UX, accessibility and privacy |

## Naming and style

- SQL: snake_case. Schemas by domain as in `docs/DATA_MODEL.md` (`identity`, `moderation`, `orgs`, `activities`, `matches`, `money`, `messaging`, `platform`, and later `academy` and `commerce`), helpers in `private`. RPCs are verbs: `activities.join_meet(...)`.
- Dart: `features/<domain>/{data,application,presentation}`. Models with freezed. Money is a `Money` value type (minor units + currency), never `double`.
- TypeScript Edge Functions: one folder per function, shared code in `supabase/functions/_shared/`.
- Time: store `timestamptz` (UTC); show in the activity's or venue's time zone.
- Copy: sentence case, plain words, second person. Product name is written OlympusGO. Prices are written `S$8.00`.
- Commit messages and PR titles start with the requirement or ticket id: `MET-6: refund choice on give up a spot`.

## The doc map

| File | Read it when |
| --- | --- |
| `docs/RULES.md` | Any task with a number, a deadline, money, age or a state change |
| `docs/PRD.md` | To know what a feature must do and when it ships |
| `docs/PRD_TOURNAMENTS_SPORT_PROFILE.md` | Tournament schedule, live match, match page, sport profile statistics |
| `docs/ARCHITECTURE.md` | Where code runs, security standard, data model by domain, events |
| `docs/DATA_MODEL.md` | Writing a migration: starting DDL, RLS patterns, helper functions |
| `docs/API.md` | Writing or calling an RPC or Edge Function: names, inputs, errors |
| `docs/SCREENS.md` | Building a screen: which canvas board shows it |
| `docs/DESIGN_SYSTEM.md` | Any UI work: tokens, type, components, accessibility |
| `docs/BUILD_PLAN.md` | Choosing the next task |
| `docs/TESTING.md` | Writing tests; the 47 end-to-end journeys |
| `docs/OPEN_QUESTIONS.md` | Before building anything a decision could change |
