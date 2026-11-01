# Build plan

The build split into tickets an agent can finish in one pull request. Phases follow `ARCHITECTURE.md` section 25 (from ACR-001 and ACR-018): phases 0 to 7 are fixed; from phase 8 they can reorder once their dependencies are done.

## Status now

Last updated 2 Nov 2026. **Build from `DEVELOPER_CHECKLIST.md`, not the tables below.** The checklist is newer and outranks this file (`AGENTS.md`, sources of truth). Its six phases are what's being built, split into twelve parts. Each built part has a status page in `docs/features` with what's proven, what's left out and the known gaps.

"Built" means built and tested locally. Nothing is pushed, nothing is on a hosted project, and the feature flags stay off. Payments run against a local stand-in for Stripe, and AI plans against a local stand-in for Claude.

| Phase | Part | Covers | Status | Page |
| --- | --- | --- | --- | --- |
| 0 | 0 | Set-up and first compile | Built for iOS. Android isn't built yet, and CI has never run | `phase-1-status.md` |
| 1 | 1 | Sign-up, profiles, parent linking, Play hosting | Built. No real SMS provider is connected | `phase-1-status.md` |
| 2 | 2 | Discover, Group, Inbox, moderation, admin sports | Built, except leagues (Q50). Push doesn't reach a phone yet | `phase-2-status.md` |
| 3 | 3 | Match generator, scoring, ratings, tournaments | Built | `phase-3-status.md` |
| 4 | 4a | Payments, ledger, refunds, payouts, Scan | Built | `phase-4a-status.md` |
| 4 | 4b | Shop, self-collect handover, points | Built | `phase-4b-status.md` |
| 4 | 4c | Academy verification, lessons, assessments, Services | Built | `phase-4c-status.md` |
| 4 | 4d | Campaigns, organizer rewards, vouchers, Game tab | Built | `phase-4d-status.md` |
| 5 | 5a | Fitness | Built | `phase-5a-status.md` |
| 5 | 5b | AI plans | Built | `phase-5b-status.md` |
| 5 | 5c | Video storage and consent, analysis worker and screens, A-10 | To do. Needs real tripod clips from the owner | |
| 5 | 5d | Video feed | To do. Needs moderation providers and the lawyer | |

Release gates are in `DEVELOPER_CHECKLIST.md` section 12. Gates B to F all need outside work that isn't done, such as a penetration test, the lawyer or real Stripe.

**The tables below are the earlier 13-phase plan, kept for its ticket detail.** Their numbers don't match the checklist: this file's Phase 5 is matches, and the checklist's Phase 5 is Fitness, AI and video (Q173). Their statuses weren't updated as work was done, so a ticket marked To do may already be built. Check the table above and the status pages instead.

---

**How to use a ticket.** Give the agent the ticket id. It reads the requirements and rules named, builds the deliverables, proves the acceptance criteria with tests, and sets the status here.

**Status values:** To do · In progress · In review · Done · Blocked (name the question).

**Release gates** (NFR-13). Foundation ships only when auth, RLS and enumeration tests pass. Core Sports Beta ships only after an outside penetration test, a staffed moderation runbook, a breach-response plan and a PDPA review. Public launch needs the legal sign-off on money (Q1).

---

## Phase 0: foundations (no user-facing features)

| Id | Ticket | Depends | Deliverables | Acceptance | Status |
| --- | --- | --- | --- | --- | --- |
| P0-01 | Scaffold the monorepo | — | Folders exactly as `ARCHITECTURE.md` section 4; Flutter apps `mobile`, `partner_web`, `admin_web`; packages `core`, `ui`, `l10n`; Next.js `site`; `supabase/` initialised; `.env.example`; `.gitignore` covering every `.env*` except the example | `flutter analyze` and `npm run lint` pass on the empty apps; `supabase start` runs | To do |
| P0-02 | CI pipeline | P0-01 | GitHub Actions running every check in `AGENTS.md` on each pull request; branch protection on `main` | A pull request with a failing test cannot merge | To do |
| P0-03 | Database test harness | P0-01 | pgTAP set-up in `supabase/tests`; a meta-test that fails if any table in an exposed schema lacks RLS; a lint that fails on `security definer` functions without `set search_path = ''` | Meta-test fails on a deliberately bad table, passes after the fix | To do |
| P0-04 | Platform tables | P0-03 | `platform.country_config`, `fee_rules`, `app_settings`, `feature_flags`, `field_registry`, `idempotency_keys` from `DATA_MODEL.md`, with the Singapore seed | Seed loads; tests read each table as anon and authenticated per policy | To do |
| P0-05 | Outbox and dispatcher | P0-04 | `platform.domain_events`, `event_consumptions`, a dispatcher moving events to pgmq queues, a dead-letter queue, replay script | Duplicate delivery is processed once; a failing consumer lands in dead-letter | To do |
| P0-06 | Money and time helpers | P0-01 | Dart `Money` value type and formatter (R-MON-1, R-MON-3), TypeScript `_shared/money.ts`, SQL `private.fee_minor(price, currency, applies_to)`; time-zone helpers using zone names (R-TIM-2) | Unit tests for every row of the fee examples in `RULES.md` in all three languages | To do |
| P0-07 | Design tokens and base components | P0-01 | `packages/ui` tokens from `DESIGN_SYSTEM.md`; `OgButton`, `OgChip`, `OgField`, `OgOptionRow`, `OgSwitchRow`, `OgSheet`, `StateView`, `MoneyText`; fonts bundled | Golden tests in light and dark; every component has 44 px targets and semantics labels | To do |
| P0-08 | Observability | P0-01 | Error tracking in apps and Edge Functions; structured logging with request ids; a log scrubber that drops emails, phones, codes | A test log line with an email is scrubbed | To do |
| P0-09 | ADR: state management | — | `docs/adr/0001-state-management.md` deciding Riverpod with or without code generation (Q3) | Owner approves | To do |
| P0-10 | Camera feasibility spike | — | Separate repo or folder; badminton score proposal from a phone video; report against ACR-011 | Report delivered; result recorded in Q24 | To do |

## Phase 1: Foundation, identity and safety

| Id | Ticket | Requirements | Rules | Deliverables | Acceptance | Status |
| --- | --- | --- | --- | --- | --- | --- |
| P1-01 | Identity tables and helpers | ACC-5, NFR-3 | R-AGE-1 | `identity.*` tables and `private` helpers from `DATA_MODEL.md`; field registry rows | RLS tests for all seven roles; `user_private` never readable by others | To do |
| P1-02 | Email code sign-up and log-in | ACC-1, ACC-2, ACC-7 | R-ACC-2 to R-ACC-4, R-ACC-10 | Edge `request_code`; Supabase Auth email OTP; padded timing; per-target limits | Unknown and known emails get identical responses and similar timing; after 5 wrong codes the target is locked for 15 minutes | To do |
| P1-03 | Mobile verification and duplicate mobile | ACC-3, ACC-4 | R-ACC-5, R-ACC-6 | Edge `send_mobile_code` (SMS, WhatsApp fallback), `verify_mobile_code`, `claim_mobile` | One account per verified mobile; claim emails the old account | To do |
| P1-04 | Complete sign-up with age path | ACC-1, ACC-5, ACC-12 | R-AGE-1, R-AGE-2 | `identity.complete_signup`; DOB write-once; `audience_class` set by server from `country_config` | 12, 13, 17, 18-year-old test cases each land on the right path | To do |
| P1-05 | Guardians and child profiles | ACC-5, SAF-7 | R-AGE-1, R-AGE-4, R-AGE-5 | `guardian_links`, `child_profiles`, approve and add flows | A 13 to 17 account stays inactive until approved (blocked by Q2 if the owner says no) | To do |
| P1-06 | Onboarding screens | ACC-6 | R-RAT-3, R-RAT-4 | Sports, starting level per sport (provisional), notifications and location permission | Integration test N01 steps pass | To do |
| P1-07 | App shell and navigation | NFR-11 | — | Bottom nav (Home, Discover, Scan, Inbox, Profile), GoRouter with real Back, deep links, `StateView` on every route | Back returns to the previous screen in every flow | To do |
| P1-08 | Profile and Passport card | PAS-1, PAS-10, PAS-11 | R-PRV-1 | Profile, other player's profile, follow, session visibility | Minor cannot choose Public; blocked users see not found | To do |
| P1-09 | Block and report | SAF-1, SAF-2, SAF-3 | R-PRV-4, R-MOD-1 | `block_user`, `create_report`, My reports, report detail, second look | Report send disabled until a reason is picked; blocks hide both ways | To do |
| P1-10 | Staff sign-in and admin reports queue | ADM-1, ADM-5 | R-MOD-1 to R-MOD-5 | `moderation.staff`, staff MFA, admin web app Today, Reports, Case, Decision log; second approver for bans | Staff without MFA cannot sign in; a ban without a second approver does not apply | To do |
| P1-11 | Removal notices, legal notice, community rules | SAF-4, SAF-5 | R-MOD-2 | Notices in Inbox, NZ 48-hour complaint reply, legal notice form without an account | — | To do |
| P1-12 | Under-18 protections | SAF-6 | R-AGE-3, R-MSG-1 | RLS and RPC checks for minors; teen video feed rules | Tests prove each protection holds server-side | To do |
| P1-13 | Account Centre, change email and mobile | ACC-8, ACC-9 | R-ACC-8, R-ACC-9 | Step-up check; change flows; alerts to old contact | Account Centre refuses without a fresh step-up | To do |
| P1-14 | Delete account and retention job | ACC-11 | R-ACC-11, R-ACC-12, R-REF-18 | Deletion request with undo; `retention_delete` job; "Former player" re-pointing | After 30 days, private data is gone; match results remain anonymised | To do |
| P1-15 | Consents | NFR-3 | — | `consents` table, consent screens for location and notifications | Withdrawing a consent emits `consent.withdrawn` | To do |
| P1-16 | Country, language, help, terms, log out | ACC-12, ACC-13 | — | Static and settings screens; emergency number from `country_config` | — | To do |
| P1-17 | Account recovery | ACC-10 (Beta) | R-ACC-13 | Recovery request, private evidence upload, staff review, 7-day wait | Old contacts are warned; all sessions revoked at the end | To do |

**Foundation gate:** P1-02, P1-04, P1-09, P1-10 and the RLS meta-test pass; enumeration tests pass.

## Phase 2: Foundation, discover and activities

| Id | Ticket | Requirements | Deliverables | Status |
| --- | --- | --- | --- | --- |
| P2-01 | Sports and venues (Places module, admin-curated) | VEN-1 | `sports`, `venues`, `courts`; venue page | To do |
| P2-02 | Organisations minimal (clubs exist so Meets have an owner) | GRP-2 | `orgs` tables from `DATA_MODEL.md`, owner role, seed clubs | To do |
| P2-03 | Activities and Meet settings | MET-1, MET-2 | `activities.*` tables; create Meet flow (free Meets only) | To do |
| P2-04 | Search and Discover | PLY-1, PLY-2, ACR-012 | `search_documents` fed by events; `search` RPC; Play tab, filters, activity card | To do |
| P2-05 | Meet page, join and leave (free) | MET-3, MET-11 | `join_meet` with row lock and idempotency; Meet page; players list | To do |
| P2-06 | Notifications pipeline | NOT-1 | Preferences, outbox, push and email senders, quiet hours | To do |
| P2-07 | Home and Inbox | CHT-1 | Home, Inbox (updates; chats come in phase 8) | To do |

Race test required for P2-05: 50 parallel joins for the last spot give exactly one `joined`.

## Phase 3: Core Sports Beta, attendance and records

| Id | Ticket | Requirements | Status |
| --- | --- | --- | --- |
| P3-01 | Waitlist with offers (Q5 default) | MET-4, R-MET-6, R-MET-7 | To do |
| P3-02 | Repeating Meets | MET-1, MET-13 (series management later) | To do |
| P3-03 | Attendance: geofence, organizer check-in, QR, walk-ins | MET-8, PAS-2, R-ATT-* | To do |
| P3-04 | My schedule (Joined and Hosting) | PLY-4 | To do |
| P3-05 | Sports records and metric definitions | ACR-009, ACR-010, PAS-5 | To do |
| P3-06 | Guest spots | MET-5 | To do |

## Phase 4: clubs and teams

| Id | Ticket | Requirements | Status |
| --- | --- | --- | --- |
| P4-01 | Create a club (4 steps), club page, club info | GRP-1 to GRP-5 | To do |
| P4-02 | Join requests, members, bans, audit log | GRP-6, GRP-9, GRP-10 | To do |
| P4-03 | Custom roles and permissions | GRP-7, GRP-8 | To do |
| P4-04 | Club chat and announcements (after phase 8 messaging core) | GRP-11 | To do |
| P4-05 | Leave, transfer, delete club | GRP-13 | To do |
| P4-06 | Teams: create, page, roster, lineup, fixtures, settings (Q4) | GRP-14 to GRP-18 | To do |

## Phase 5: matches

| Id | Ticket | Requirements | Status |
| --- | --- | --- | --- |
| P5-01 | Match core tables and immutable results | ACR-008, R-SCO-3 | To do |
| P5-02 | Enter and confirm a score, dispute to organizer | MET-10, R-SCO-1, R-SCO-2 | To do |
| P5-03 | Meet recap and share card | PAS-12 | To do |

**Beta gate:** penetration test, moderation runbook staffed, breach plan, PDPA review.

## Phase 6: ranked play and leaderboards

| Id | Ticket | Requirements | Status |
| --- | --- | --- | --- |
| P6-01 | Rating engine worker (Glicko-2) with anti-gaming rules | PAS-4, R-RAT-* | To do |
| P6-02 | Local, Tournament and club leaderboards (snapshots) | PAS-6 to PAS-9, R-LDR-* | To do |
| P6-03 | Sport profile: tabs, tiles, matches list, charts, privacy (PAS-22 partners comes after launch) | PAS-14 to PAS-21, PAS-23 to PAS-25, R-STA-* | To do |
| P6-04 | Sessions and rating history | PAS-5 | To do |

## Phase 7: camera v1

Only if the spike passed (Q24). Otherwise it moves after launch. Tickets are written after the spike report.

## Phase 8: messaging

| Id | Ticket | Requirements | Status |
| --- | --- | --- | --- |
| P8-01 | Direct messages, adults first | CHT-1, R-MSG-1 | To do |
| P8-02 | Club, team and class chats with organizer delete and report | CHT-2, GRP-11, GRP-17 | To do |
| P8-03 | Shop, support and parent threads | CHT-3 | To do |

## Phase 9: payments (blocked by Q1)

| Id | Ticket | Requirements | Rules | Status |
| --- | --- | --- | --- | --- |
| P9-01 | Ledger tables, balance check, append-only | — | R-MON-*, R-MON-5 | Blocked (Q1) |
| P9-02 | `money.quote` and `money.refund_quote` pure functions | PAY-1, PAY-2, PAY-3 | R-FEE-*, R-REF-* | Blocked (Q1) |
| P9-03 | Stripe Connect set-up, onboarding for people who get paid | PAY-10 | R-PAY-4 | Blocked (Q1) |
| P9-04 | Payment sheet (review, Face ID, receipt) and failed state | PAY-1, PAY-8 | R-REF-20, R-WAL-4 | Blocked (Q1) |
| P9-05 | Webhooks, capture, hold | PAY-1 | R-HOLD-1 | Blocked (Q1) |
| P9-06 | Release job and earnings | PAY-10 | R-HOLD-2 to R-HOLD-5 | Blocked (Q1) |
| P9-07 | Refunds with Wallet or card choice; organizer cancellations with card fees | MET-6, MET-9, PAY-2, PAY-3 | R-REF-1 to R-REF-20 | Blocked (Q1) |
| P9-08 | Wallet and withdrawals; top-up flag off | PAY-5 | R-WAL-* | Blocked (Q1) |
| P9-09 | Payment methods and receipts | PAY-6, PAY-7 | — | Blocked (Q1) |
| P9-10 | Payout runs with staff approval; admin refunds and disputes | PAY-10, ADM-2 | R-PAY-* | Blocked (Q1) |
| P9-11 | Points ledger, awarding, redemption, expiry | PAY-11 | R-PTS-* | Blocked (Q1, Q13) |
| P9-12 | Daily reconciliation job and alerts | — | — | Blocked (Q1) |
| P9-13 | Paid Meets, free Meets (organizer pays or players pay the fee), organizer playing spot | MET-7 | R-FEE-3, R-FEE-3b, R-FEE-5 | Blocked (Q1) |
| P9-14 | Club reward: count qualifying Meets, redeem | GRP-12 | R-CLB-7 | Blocked (Q1) |
| P9-15 | Identity, business and coach checks in the admin web app | ADM-3 | R-PAY-4, R-ACD-1 | Blocked (Q1) |

## Phase 10: tournaments and events

| Id | Ticket | Requirements | Status |
| --- | --- | --- | --- |
| P10-01 | Create a tournament (4 steps) | TRN-1 | To do |
| P10-02 | Register, partner search, pay, withdraw | TRN-2, TRN-5 | To do |
| P10-03 | Draw, court assignment, umpire scoring | TRN-3, TRN-4 | To do |
| P10-04 | Organizer tools and team entries | TRN-6, TRN-7 | To do |
| P10-05 | Match schedule, match page, live card (game scores) | TRN-9 to TRN-14 | To do |
| P10-06 | Match statistics, order of play, result correction | TRN-18, TRN-19, TRN-21, TRN-22 | To do |
| P10-07 | Events: create, tickets, event page, release, cancel | EVT-1 to EVT-5 | To do |

## Phase 11: academy

| Id | Ticket | Requirements | Status |
| --- | --- | --- | --- |
| P11-01 | Create and verify an academy | ACD-3, ACD-10 | Done locally, see `docs/features/phase-4c-status.md` |
| P11-02 | Find an academy, trial, enrol | ACD-1, ACD-2 | To do |
| P11-03 | Coach today, classes, session marking | ACD-4 | To do |
| P11-04 | Curriculum, lesson plans, drill library | ACD-5 | To do |
| P11-05 | Change a class with SMS fallback | ACD-6, R-ACD-2 | To do |
| P11-06 | Make-up credits | ACD-7, R-ACD-3 | To do |
| P11-07 | Parent home, progress, fees | ACD-8, ACD-9 | To do |
| P11-08 | Academy web space (partner web) | ACD-12 | To do |
| P11-09 | Coach pay, invite students, close an academy | ACD-11 | To do |

## Phase 12 and later: shop, services, creators, campaigns, venues (Q16)

| Id | Ticket | Requirements | Status |
| --- | --- | --- | --- |
| P12-01 | Shop home, shoppable video, live shopping | SHP-1, SHP-2 | To do |
| P12-02 | Product, shop page, cart, checkout with points | SHP-3 | To do |
| P12-03 | Orders, tracking, cancel, refund, return, review | SHP-4 | To do |
| P12-04 | Seller tools; merchant web space (design first) | SHP-5, SHP-6 | To do |
| P12-05 | Services booking | SHP-7 | To do |
| P12-06 | Court booking and venue owner's side (design first, Q25) | VEN-2, VEN-3 | Blocked (Q25) |
| P12-07 | Creator profile, challenges, earnings | CRT-1 to CRT-3 | To do |
| P12-08 | Campaigns (admin web app and Game tab) | GAM-1, ADM-4 | To do |
