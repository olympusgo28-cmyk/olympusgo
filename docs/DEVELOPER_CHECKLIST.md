# OlympusGO developer checklist

For the walkthrough with the developer, Fri 30 October 2026, 7:30 PM. Read top to bottom: what the app is, how it is built, then each phase with its features and what each one must do. Tick a box only when the "Done when" line passes.

Companion files: `MASTER_BUILD_PLAN.md` (the full tickets, rules and open decisions), `RULES.md` (rule ids), `SPORTS_AND_FORMATS.md`, `SCREENS.md` and `SCREENS_UPDATE_30OCT.md` (the 313 designed screens), `BUILD_GUIDE.md` (security checklist). If two files disagree, the order in `MASTER_BUILD_PLAN.md` section 1 wins.

---

## 0. How to use this in the meeting

| Time | What | Where |
| --- | --- | --- |
| 10 min | What the app is, what exists today | Sections 1 and 2 |
| 15 min | How it is built, and the security rules that apply everywhere | Sections 3 and 4 |
| 40 min | Phases 0 to 5, feature by feature | Sections 5 to 10 |
| 15 min | Money, safety and legal gates | Sections 11 and 12 |
| 10 min | Decisions, estimate and questions for the developer | Sections 13 and 14 |

If time is short, cover sections 2, 4, 5, 6 and 14 first.

---

## 1. The app in one page

OlympusGO is a social sports and fitness app. People find and host sessions ("Meets"), check in by QR, play, score matches, build a rating, and earn rewards. Singapore first, then Malaysia and New Zealand. Badminton and pickleball first. iOS and Android, plus an admin web app.

- **Bottom tabs:** Main, Discover, Scan, Inbox, Profile.
- **Eight categories:** Play, Group, Academy, Venue, Services, Game, Shop, Fitness.
- **People:** adults, teens (13 to 17, parent approves), children (under 13, restricted until a parent links), parents, hosts, coaches, partner shops, staff.
- **Money:** all payments go through OlympusGO (Stripe Connect, PayNow and card). OlympusGO holds payments and releases them after attendance or collection. Platform fee 10%, minimum S$2.00, added on top for sessions.
- **Business angle:** RSL sells shuttles to OlympusGO at a discount, goods go to partner stringing shops, and hosts earn shop vouchers for running well-attended games.
- **Partner brand:** RSL.

---

## 2. Where things stand today

| Item | State |
| --- | --- |
| Flutter scaffold (`lib/`: auth, guardian, home, play, profile, core) | Written, **never compiled or run**. Expect errors on the first build. |
| Supabase | Migrations `0001` to `0007`, `seed.sql`, Edge Functions `resolve-login` and `guardian-link`. Migrations `0001` to `0007` apply cleanly on a test Postgres (with stand-ins for Supabase auth). |
| Tests | Two Flutter tests (`phone_test`, `restrictions_test`). One SQL scenario script for sports status (`supabase/tests/catalog_status_check.sql`). No pgTAP yet. |
| Sports catalogue | Badminton and pickleball live with their formats. Tennis, table tennis, squash and padel created as drafts. Each sport and format has a status: draft, live or maintenance. |
| Screens | 313 designed screens (phones and admin web) on the design canvas. Not code. |
| Admin app | Designed only. Nothing built. |
| Everything after Phase 1 | Not started. |

Dependencies already chosen (`pubspec.yaml`): Riverpod, go_router, Freezed, `supabase_flutter`, `flutter_secure_storage`, `local_auth`.

---

## 3. Architecture checklist

### 3.1 Stack

- [ ] Flutter app for iOS and Android, one codebase. Feature-first folders: `features/<name>/{data,domain,presentation}`.
- [ ] Admin: separate Flutter web app on its own domain.
- [ ] Supabase in the Singapore region: Postgres, Auth, Storage, Realtime, Edge Functions (Deno).
- [ ] Stripe Connect with delayed payouts, PayNow for SGD.
- [ ] Push through APNs and FCM. SMS and email providers behind Edge Functions.
- [ ] A GPU worker outside Supabase for video analysis (Phase 5).
- [ ] Shared Dart package for the match generator (`packages/match_engine`), used by app and validation.

### 3.2 Principles that apply to every ticket

- [ ] **The database decides.** Row-level security on every table, created in the same migration. Business rules that matter (capacity, age, scoring, money) are enforced in database functions or Edge Functions, never only in the app.
- [ ] **Numbers live in configuration**, not code: `app_settings`, `country_config`, `fee_rules`, `feature_flags`, scoring rows. Examples: fee percent and minimum, voucher expiry days, auto-release hours, lockout times, age thresholds.
- [ ] **Money is integer cents plus a currency code.** The server computes every amount; the app never sends one.
- [ ] **Times stored in UTC**, shown in local time (Singapore and Malaysia UTC+8, New Zealand UTC+12/13 with daylight saving).
- [ ] **One migration per change**, named `NNNN_topic.sql`. Never edit an applied migration.
- [ ] Every `security definer` function sets `search_path` explicitly and has a comment saying why it needs that power.
- [ ] No secrets in code, tests, screenshots or logs. No service-role key in any app build (CI greps for it).
- [ ] Same generic error for "unknown" and "wrong" on sign-in, so accounts cannot be enumerated.
- [ ] Idempotency keys on every write that moves money or issues a reward, so a retry cannot do it twice.
- [ ] Append-only audit tables for admin actions, catalogue changes, the ledger and the counted-game log.

### 3.3 Definition of done (every ticket)

- [ ] `dart format --set-exit-if-changed .`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `supabase db reset` runs clean (migrations plus seed)
- [ ] `supabase test db` (pgTAP) passes, including the meta-test that fails if any exposed table lacks RLS
- [ ] `deno lint` and `deno test` in `supabase/functions`
- [ ] Each new rule has a test named after its rule id, for example `R-HOLD-2 releases after 24 hours`
- [ ] A feature note at `docs/features/<feature>.md` (what it does, who can use it, files, data, steps, rules and where the numbers live, security notes, how to change it, tests, known gaps)
- [ ] A separate reviewer checks money, sign-in, minors and RLS changes against `RULES.md` and the security checklist
- [ ] The box is ticked in `MASTER_BUILD_PLAN.md` and one line is added to the progress log

---

## 4. Security and child-safety checklist (applies everywhere)

- [ ] RLS tested for each role: signed out, adult, teen, restricted child, parent, blocked user, admin.
- [ ] Minors never appear in player discovery, public leaderboards or rankings by name.
- [ ] A restricted child (under 13, not linked) cannot see: open chat, nearby discovery, Scan, video feed, Shop. The database refuses the same reads, not just the screens.
- [ ] Parent link: 8-character code, valid 24 hours, parent must be 18 or over, parent can revoke, link ends at 18 with a notice 30 days before.
- [ ] Rate limits per identifier and per IP on sign-in, code requests, reports and any public function.
- [ ] 5 wrong codes lock the target for 15 minutes.
- [ ] QR codes hold an opaque, rotatable token, never a user id.
- [ ] Private storage buckets only. Short-lived signed URLs. Child video needs a consent row and is purged after 90 days by default.
- [ ] Location stored only as a coarse geohash, only with consent, never shown to others.
- [ ] Logging scrubs phone numbers, emails, codes, tokens and card data.
- [ ] Staff: mandatory MFA (aal2 enforced by RLS). Bans and large payout runs need a second approver. Moderators cannot see payment data.
- [ ] An RLS attack script tries every table as anon, as a child and as another user. Outside penetration test before the closed pilot.

---

## 5. Phase 0: set up and first compile (3 to 4 days)

Goal: the scaffold builds and runs, and the checks are automatic.

- [ ] **P0-01 Tooling.** Flutter, Dart, Supabase CLI, Docker, Deno, Xcode, Android Studio. Versions recorded in `docs/features/dev-setup.md`. Done when `flutter doctor` is clean.
- [ ] **P0-02 Repo and CI.** `main` protected, GitHub Actions run every check in 3.3, secret scanning on. Done when a failing pull request cannot merge.
- [ ] **P0-03 First compile.** `flutter pub get`, `dart run build_runner build`, fix every error, run on iOS simulator and Android emulator. Done when the app reaches the splash screen and the two tests pass.
- [ ] **P0-04 Local Supabase.** `supabase start`, migrations and seed run clean, test SMS and email providers configured.
- [ ] **P0-05 Test harness.** pgTAP in `supabase/tests`, the RLS meta-test, a lint for `security definer` without a fixed search path. Convert `catalog_status_check.sql` into pgTAP.
- [ ] **P0-06 Design tokens.** Orange `#E8590C`, charcoal `#1C1F23`, no lime in the light theme, no font weight above 600, light and dark golden tests. (Small text on orange uses the pressed orange `#C94A00`; link and tag orange is `#A83B00`. See `SCREENS_UPDATE_30OCT.md`.)

---

## 6. Phase 1: sign-up, profiles, parent linking, Play hosting (6 to 8 weeks)

Goal: someone signs up with a mobile number and logs back in with Face ID; a child links to a parent; a host runs a session with a waitlist and QR check-in. Most code exists as a scaffold, so each ticket starts with "make it run and prove it".

### Accounts and sign-in

| Feature | What it must do | Tech to check |
| --- | --- | --- |
| **Database foundation** (P1-01) | Profiles, safety and guardian links, catalogue, plays and participants, play functions, grants. | RLS tests for each role. 20 parallel joins on a 10-spot session give exactly 10 joined and 10 waitlisted in order. |
| **Mobile sign-up with SMS code** (P1-02) | Mobile number first, then username, display name, date of birth. Email optional, verified by email code. | One account per verified mobile (R-ACC-5). Same-looking message for a taken mobile. Email never shown back (R-ACC-10). |
| **Age paths** (P1-03) | 18+: own account. 13 to 17: own account, minor rules, parent approval. Under 13: restricted mode until a parent links. | Ages read from `country_config`. Test users aged 12, 13, 17 and 18. The date-of-birth screen branches to the right path. |
| **Login** (P1-04) | Mobile, email or username. `resolve-login` finds the account on the server. Code by SMS for a mobile, by email otherwise. | Unknown and wrong accounts return identical responses with padded timing. Limits per identifier and per IP. |
| **Saved-account tiles and Face ID** (P1-05) | After first login the device stores display name, avatar and a masked identifier. Refresh token in Keychain or Keystore. Tap a tile, then Face ID, fingerprint or passcode. Several accounts per device. | A fresh code is needed if biometrics change, the token expires or the device is new. Removing a tile deletes the token. |
| **Account recovery** (P1-06) | Lost mobile falls back to a verified email. Both lost: enter an email, goes to staff review. | Staff request is recorded. Admin screen arrives in Phase 2 (A-04). |
| **Profile and restricted mode** (P1-07) | Profile screen. Restricted-child shell with a banner "Ask a parent to link your account". | The `restrictions` provider plus RLS refuse the same reads. |
| **Parent link** (P1-08) | Child shows a code. Parent enters it, approves or denies, sees and deletes what the child posted, can revoke. | Approve, deny, revoke and expiry all tested. A parent under 18 is refused. |

### Play (hosting a session)

| Feature | What it must do | Tech to check |
| --- | --- | --- |
| **Create, join, leave, waitlist** (P1-09) | Create form driven by admin data: sport, format, date and time, min and max players, level range, gender mix, reserved slots, price per head, court booked, visibility. One database function joins. At the minimum the session shows "Game is on". Leaving promotes the next eligible waitlisted person. | Capacity checked with a row lock (R-MET-4). Price is shown but **no money moves** until Phase 4a. Integration test: sign up, host, second account joins, "Game is on". |
| **Sport and format status** (done, `0007`) | Draft, live, maintenance. New Meets only in live sports and formats. Each Meet keeps a copy of its scoring rules from creation. Every catalogue change is in `catalog_audit`. | Run `supabase/tests/catalog_status_check.sql`. |
| **Player QR and check-in** (P1-10) | Every player has a QR (My QR screen). The host scans players in. A parent scans for a child. | Opaque rotatable token. A scan marks the right player Present. A rotated token stops working. Under-13 cannot scan. |
| **Attendance and counted-game log** (P1-11) | Host saves attendance. Each saved session writes one append-only row to `campaign_game_log`: host, number Present, paid or not per player, QR check-in per player, times. | Log every session from day one, even before vouchers exist. Saving twice does not duplicate. Late edits go to the audit log. |

### Hardening and release

- [ ] **P1-12 Security baseline.** RLS on every table, private buckets, rate limits, no service-role key in the app (CI greps), dependency scanning, RLS attack script. Done when the script finds nothing and an outside reviewer has read the policies.
- [ ] **P1-13 Internal build.** TestFlight and Play internal testing, crash reporting, structured logging with a scrubber.
- [ ] **A-01 Admin web shell.** Email and password plus mandatory MFA, roles (super, moderator, content), actions through Edge Functions that write the audit log. A staff account without MFA gets no data.

**Gate A (internal testing):** P1-01 to P1-12 done, enumeration tests and the RLS meta-test pass.

---

## 7. Phase 2: Discover, Group, Inbox, moderation, admin sports (5 to 6 weeks)

Goal: people find sessions, players, groups and venues; groups and chat work; reporting and blocking work everywhere; the founder manages sports and formats without a code change.

| Feature | What it must do | Tech to check |
| --- | --- | --- |
| **Discover** (P2-01) | Map and list, filters (sport, level, date, time, distance), two-week date strip, skill matching. Functions: `discover_sessions`, `discover_players`, `discover_groups`. | Blocked users excluded both ways. Minors excluded from player discovery. Location only as a coarse geohash with consent. |
| **Main tab and category tiles** (P2-02) | Upcoming sessions, your groups, nearby suggestions, eight tiles. | Each tile opens its screen, even if empty. |
| **Group: clubs, teams, leagues** (P2-03) | Create, visibility (public, private, hidden), join and approve, members, custom roles. | Role permissions tested. A minor cannot see a group a parent has not approved. |
| **Group activity ranking** (P2-04) | Groups ranked by activity using the same counted-game rule as host rewards. | Flag `campaign.require_paid` off until payments go live. Only groups ranked, under-18s never named. |
| **Inbox and chat** (P2-05) | Notifications and conversations, realtime, optimistic send with retry, message deletion. | A child's chat in an unapproved group is refused by the database. |
| **Push notifications** (P2-06) | Permission flow, device tokens, `send-push` for APNs and FCM, per-kind settings, quiet hours. | Quiet hours hold everything except session changes. |
| **Moderation** (P2-07) | `moderate-text` (profanity, phone numbers, off-platform links, suggestive language; English, Malay, Mandarin and Tamil romanisation). `report-submit` on every profile, session, message and group. | Three distinct reporters auto-hide an item. Child reports carry a 24-hour deadline. Reporters get a neutral acknowledgement only. Block hides both ways. |
| **A-02 Sports and formats manager** | Admin edits sports, formats, scoring, junior variants, game types, level scales. Draft, live, maintenance, with a confirmation screen. | Database side is done (`0007`). Build the admin screens. Adding a test sport and pushing it live makes it appear in the app. |
| **A-03 Moderation queue** | Daily queue by deadline then report count. Restore, remove, warn, suspend. Bans need a second approver. | Every action writes the audit log. Moderators see no payment data. |
| **A-04 Users and parent links** | Search users, see links, review recovery requests. | A request from P1-06 can be reviewed. |

**Gate B (closed pilot, 3 to 5 organisers, free sessions only):** also needs the outside penetration test, a staffed moderation routine, the PDPA review and the app store child-safety answers.

---

## 8. Phase 3: match generator, scoring, ratings, tournaments (5 to 6 weeks)

Goal: a host presses Generate and gets rounds with courts and pairings; players enter scores; ratings move by themselves; tournaments produce brackets and a leaderboard.

| Feature | What it must do | Tech to check |
| --- | --- | --- |
| **Match tables and scoring presets** (P3-01) | `matches`, `match_players`, `match_scores`, `scoring_presets`. Badminton: games to 21, win by 2, cap 30. Pickleball: games to 11, win by 2. | Confirmed results are immutable; a correction adds a new result (R-SCO-3). |
| **Match generator** (P3-02) | Pure, seeded function. Fixed teams (circle method), Americano with skill balancing, split by gender (mixed pairs). Active-roster screen for late arrivals and early leavers; regenerates remaining rounds. | Property tests over 1,000 random rosters: nobody plays twice in a round, courts never exceeded, byes fair, partner repeats minimised, gender splits honoured. |
| **Score entry and confirmation** (P3-03) | One side enters, the other confirms. Unconfirmed after 24 hours, or disputed, goes to the organiser. Umpire entry is final. | Database validates against the preset: 30-29 valid, 22-20 valid in a game to 21, 22-21 invalid. |
| **Rating engine** (P3-04) | Elo at launch: `expected = 1 / (1 + 10^((rB - rA) / 400))`, `delta = K * (score - expected)`. Doubles use the team average. Only confirmed ranked results from attended players. | Written only by a database function. Clients cannot write `ratings`. Repeat opponents count less. Quests and academy levels never change a rating. Deltas sum to zero for equal K. |
| **Ranked profile and history** (P3-05) | History chart. Level as band plus number (for example MI 5.1). | Statistics appear only when the match was scored at the level they need. |
| **Tournaments** (P3-06) | Knockout and round-robin, byes to the next power of two against top seeds, winners propagate, bracket viewer, umpire scoring, correction within 24 hours. | Tested for 3 to 33 entrants. |
| **Leaderboards** (P3-07) | Arena leaderboard by sport and country from scheduled snapshots. | Minors left out unless a guardian opts in. |
| **A-05 Rating and game-type rules** | Edit presets and level scales in the admin without a deploy. | |

**To settle before building ratings:** K factor. The plan says 32 for the first 30 matches then 20. The admin Game types screen shows Casual 16, Ranked 32, Tournament 40. Pick one scheme.

---

## 9. Phase 4: payments, Scan, Venue, Shop, Academy, Services, Game (8 to 10 weeks)

Highest risk for money and children. Build in order 4a, 4b, 4c, 4d. **No live payments until Gate C.**

### 4a. Payments and Scan (about 3 weeks)

| Feature | What it must do | Tech to check |
| --- | --- | --- |
| **Money tables and ledger** (P4a-01) | `payments`, `refunds`, `vendors`, `payouts`, append-only double-entry `ledger_entries`. | Clients cannot write them. Entries sum to zero per transaction. A refund never exceeds the amount captured. |
| **Fee and quote functions** (P4a-02) | Pure `money.quote` and `money.refund_quote`. | Tests from the examples: S$6.00 gives fee S$2.00 and S$8.00 paid; S$30.00 gives S$3.00 and S$33.00. |
| **Stripe set-up** (P4a-03) | Connect with delayed payouts, vendor identity and business checks, webhook secrets in Edge Function secrets. | Holds no more than 90 days (R-HOLD-7). **Live use blocked until the lawyer review.** Test mode can proceed. |
| **Payment flow with PayNow** (P4a-04) | `create-payment-intent` computes the amount on the server. PayNow completes later: hold the spot 10 minutes with a countdown, show "Waiting for payment", confirm **only** on `stripe-webhook`. The sheet shows lines, fee, total, refund rule and "OlympusGO holds your payment". | Replaying `payment_intent.succeeded` twice makes one ledger entry. An expired hold frees the spot. |
| **Hold and release** (P4a-05) | Hold until the organiser saves attendance, or 24 hours after the activity ends. Absent players not refunded. A report before release keeps the money held. | R-HOLD-1 to R-HOLD-5. |
| **Refunds** (P4a-06) | Back to the original PayNow or card. Organiser, venue or shop cancels: player gets everything including the fee. Player cancels in time: price without the fee. Late or no-show: nothing. Card fees on organiser cancellations come out of their earnings. | Every row of the refund examples table in `RULES.md` is a passing test. |
| **Payout runs** (P4a-07) | Weekly, staff approval, second approver above a threshold. Bank transfer free. | Threshold open (default S$5,000 per run). |
| **Reconciliation** (P4a-08) | Daily job compares Stripe balance transactions with the ledger. | An injected mismatch raises an alert. |
| **Scan tab** (P4a-09) | Camera scanner. `resolve_qr` applies visibility rules (blocked, private, minor) and opens a player, group or venue. Pay mode scans a venue or vendor code. Under-13s see Scan disabled; a parent scans for the child. | A minor cannot call `resolve_qr`. A rotated token stops working. |
| **A-06 Payments admin** | Payments, refunds, held money with ledger drill-down, payout approval, disputes. | Only payments staff see it. |

### 4b. Venue and Shop (about 2 to 3 weeks)

| Feature | What it must do | Tech to check |
| --- | --- | --- |
| **Venues and courts** (P4b-01) | Listings, detail, photos, court booking: hold, pay, confirm. | A database exclusion constraint prevents double-booking. |
| **Shop catalogue** (P4b-02) | Products and services from partner SME shops, RSL first. Each shop sets its price and a switch for the 10%. Founder enters shops and products in the admin first. | |
| **Checkout** (P4b-03) | Cart, final price shown before paying, one discount per item (voucher **or** points), PayNow or card. **Self-collect only, no delivery.** The app states that sports equipment is final once collected. | Commission: flat 10%, by default out of the shop's price (S$100: shop S$90, OlympusGO S$10), or added on top if the shop turns the switch on. |
| **Handover** (P4b-04) | At the shop the buyer taps "Yes, I got it all" on their own phone, which releases the payout. "Report a problem" holds it. If nothing is tapped, the payout releases after the wait (default 48 hours). No refunds after the buyer leaves. | Tests for confirm, report and auto-release. A report after auto-release is refused. Before collecting, the buyer can cancel for a full refund unless a service has started. |
| **Points** (P4b-05) | 1 point = S$0.10. Earned only from playing, events, groups and tournaments (2 times the fee paid, after Present). Spend up to half of OlympusGO's commission on an item. Expire after 12 months. Shop purchases earn none. | Store value in cents, show cents divided by 10, no rounding. |
| **A-07 Shop admin** | Partner shops, catalogue, orders, handover reports, commission switch. | |

### 4c. Academy and Services (about 2 weeks)

- [ ] **P4c-01 Academy and coaches.** Coach profiles, lesson booking, verification (business licence, coach licences, payout account).
- [ ] **P4c-02 Assessments.** Custom templates, coach assessments, improvement charts. Academy level is separate from the Play rating. Readable by the player, a minor's parent and the assigning coach; writable only by the coach.
- [ ] **P4c-03 Services referral.** Partner physio list and a request button that opens the partner's own booking link. Store only that a referral was made and a partner reference code, never anything about a condition.
- [ ] **A-08 Academy and services admin.**

### 4d. Game: campaigns, quests, vouchers (about 2 weeks)

| Feature | What it must do | Tech to check |
| --- | --- | --- |
| **Campaign engine** (P4d-01) | Data-driven `campaigns`, `quests`, `challenges`, `challenge_progress`, `vouchers`, `badges`. Rewards issued in one transaction. | Idempotent: a retry cannot issue twice. Quests never change a rating. |
| **Host rewards** (P4d-02) | A game counts only if 6 or more players are Present, every player paid, and every player checked in by QR. The playing host pays only the S$2.00 fee, which counts as paid. Lifetime count, never resets. | Pure milestone function tested for games 1 to 40 (table below). |
| **Voucher wallet** (P4d-03) | Shows vouchers, expiry, status. Redeemed only in the app. Tied to one account, not transferable, expire (default 90 days). | Every redemption logged with who, which shop and when. Code shown only to its owner, never logged. |
| **Game tab** (P4d-04) | Campaign list, quest detail with progress, voucher wallet. | |
| **A-09 Campaigns admin** | Create campaigns, voucher types, expiry, funding shop or venue, see redemptions. | |

Host reward ladder (the test table):

| Counted game | Shuttle voucher (A) | Hall voucher (B) |
| --- | --- | --- |
| 1, 3, 5, 6, 7 | 0 | 0 |
| 2 (once only) | 1 | 0 |
| 4 | 1 | 0 |
| 8 | 2 | 1 |
| 12 | 2 | 0 |
| 16 | 3 | 1 |
| 20 | 3 | 0 |
| 24 | 3 | 1 |

Games between milestones (10, 14 and so on) earn nothing. A game that fails any condition counts for neither the reward nor the group ranking. The shop funds Voucher A; the venue funds Voucher B by default. No non-cash perks.

**Gate C (real money):** 4a done in Stripe test mode, a lawyer has signed off on how money is held, daily reconciliation passes. **Gate D (shop live):** Gate C plus the lawyer check on "final once collected".

---

## 10. Phase 5: AI video analysis, Fitness, AI plans, video feed (8 to 10 weeks)

| Feature | What it must do | Tech to check |
| --- | --- | --- |
| **Video storage and consent** (P5-01) | Private buckets, signed URLs, a consent row for every video of a child, 90-day default retention, parent can list, extend or delete. | A stranger cannot read a child's video row. |
| **Analysis worker** (P5-02) | GPU container wrapping the Good-Badminton project. Receives jobs, downloads via short-lived URL, uploads results, calls back with a scoped token. Never holds the service-role key. Per-job timeout, daily cost cap per user. | **Licence decision first:** Ultralytics YOLO is normally AGPL-3.0. Buy a licence or pick another detector. |
| **Analysis screens** (P5-03) | Record or upload a clip, guided phone placement, court detection with a four-corner fix, report: movement, speed, distance, rallies, heatmaps. Hit-point and technique stay beta or are left out. Pickleball later, behind a flag. | |
| **Fitness** (P5-04) | Built-in workouts, custom builder, logs, history. Form checks start as a spike. | No calorie or medical claims. Minors see age-suitable workouts only. |
| **AI plans** (P5-05) | An LLM call from the user's logs, output checked against a JSON schema. Labelled advisory. | |
| **Video feed** (P5-06) | Text and frame moderation before a post shows; new users checked first. Children's content: results, badges and parent-reviewed clips to parent-approved audiences, reactions only. Restricted children have no feed. | Report and block on every post. |
| **A-10 Analysis jobs monitor** | Queue, failures, storage, cost. | |

**Gate F (video of children):** parent consent flow, 90-day purge, and the licence decision.

---

## 11. Admin app (spread across the phases)

Built as separate Flutter web. Screens already designed: today, reports, case, decision log, users, sports and formats (with draft, live, maintenance), game types and levels, venues and courts, verification, shop catalogue, partner shop, orders, refunds and handover problems, payouts, campaigns, vouchers, host games, analysis jobs, word lists, audit log, login.

- [ ] Staff sign in with MFA. Roles: super, moderator, content, payments. Role separation enforced by RLS, not the UI.
- [ ] Every action writes an append-only audit row, with a short reason.
- [ ] Format changes apply to new Meets only.
- [ ] Not yet designed, suggested before launch: settings and feature switches (including a global pause), a Meets screen (search, cancel with refunds, score disputes), a payments ledger drill-down and Stripe match, staff and roles, a recovery and support queue, and a business view (new users, Meets counted, money held and paid).

---

## 12. Release gates

| Gate | Needs | Allows |
| --- | --- | --- |
| A. Internal testing | Phase 1 done. Auth, RLS and no-account-enumeration tests pass. | TestFlight and Play internal testing for the team |
| B. Closed pilot | Phases 1 and 2. Outside penetration test. Daily moderation queue staffed. PDPA review. App store child-safety answers. | 3 to 5 real organisers and their players, free sessions only |
| C. Real money | Phase 4a in Stripe test mode. **Lawyer sign-off** on holding money. Daily reconciliation passes. | Live payments |
| D. Shop live | Gate C plus the lawyer check on "final once collected". | Shop, vouchers, host rewards |
| E. Public launch | Gates B to D plus ratings and tournaments (Phase 3). | App store release |
| F. Video of children | Parent consent flow, 90-day purge, licence decision. | Analysis of child video |

**Pilot checkpoint.** Payments are in Phase 4, but organisers leave WhatsApp mainly to get paid and track attendance. After Phases 1 and 2, decide whether to pull 4a forward for the pilot (live only after the lawyer signs off).

**Pilot targets (starting measures):** 60% of new sign-ups complete their profile within 24 hours; 70% of published sessions reach "Game is on"; 35% of players join or host a second session within 14 days.

**App store checklist (before Gate E):** report, block and delete account inside the app; privacy labels (Apple) and Data safety form (Google) that match what is really collected; age rating answers (chat and under-18 accounts); a reviewer test account with a Meet to join and a payment that works in test mode; real-world services (Meets, courts, classes, gear) paid outside Apple in-app purchase.

**Legal and privacy (a lawyer in each country):** terms, privacy and refund policy; Singapore PDPA (named data protection officer, breach reporting); Malaysia PDPA; New Zealand Privacy Act; children's data; Payment Services Act position on holding money; consumer protection for the no-refund-after-collection rule; data retention schedule.

---

## 13. Open decisions (defaults the developer will use until you decide)

Numbering here is for this meeting only and does not match section 13 of `MASTER_BUILD_PLAN.md`, where the full list and config keys are kept.

| # | Decision | Default used |
| --- | --- | --- |
| 1 | Lawyer sign-off on holding customer money (Gate C) | Test mode only |
| 2 | Lawyer check that "final once collected" is allowed (Gate D) | Build it, do not go live |
| 3 | Voucher expiry | 90 days |
| 4 | Game 2 voucher is the same Voucher A as game 4 | Yes |
| 5 | Wait before automatic payout release | 48 hours |
| 6 | Who funds Voucher B and how it is redeemed | Partner hall funds it; redeemed through a venue booking in the app |
| 7 | What the 10% is charged on when a voucher is used | The price the buyer pays after the voucher |
| 8 | Points earned for a S$2.00 fee | 40 points (S$4.00 of value) |
| 9 | Hosts aged 13 to 17 earning vouchers | Hosts must be 18 or over |
| 10 | Quest types and limits for children | Play N sessions, host N counted games, attend N sessions; adults only |
| 11 | Second approver threshold for payout runs | S$5,000 per run |
| 12 | Fee minimums in MYR and NZD, ages in Malaysia and New Zealand | Disabled by `country_config` |
| 13 | Ultralytics YOLO licence | Buy a licence or pick another detector |
| 14 | Final under-13 content design confirmed by a Singapore lawyer | Posts private until a parent approves |
| 15 | Cancel a shop order before collecting | Yes, until collected, unless a service has started |
| 16 | When the auto-release clock starts | Collect-by is 7 days after payment for products, or the booked slot for services; auto-release 48 hours after |
| 17 | Voucher prices in the screens (S$24 instead of S$32; S$6 off) are samples | Configuration values |
| 18 | Old "Club reward" (R-CLB-7) | Treated as replaced by host rewards; remove the screen once confirmed |
| 19 | Elo K factor scheme | Plan: 32 then 20. Admin screen shows 16, 32, 40. **Pick one.** |
| 20 | Junior badminton rule | Both seeded: 15 points cap 21, and the 11-point variant. **Pick one.** |
| 21 | Pickleball formats | Singles, Doubles, Mixed doubles, Doubles social assumed |
| 22 | Which other sports to keep as drafts | Tennis, table tennis, squash, padel |

---

## 14. Questions to ask the developer

**Estimate and team**
- [ ] Is 32 to 40 weeks for one developer plus Claude Code realistic? Where would you add time?
- [ ] Who reviews code, and who is the second pair of eyes on money and RLS?
- [ ] What would you cut or defer to reach the closed pilot sooner?

**Technical**
- [ ] Any concern with Flutter plus Supabase for realtime chat, geo search and the match generator at our scale?
- [ ] Postgres extensions needed (PostGIS or geohash only, pg_cron, pgTAP)? Any limits on the Singapore region?
- [ ] How will Edge Functions be tested and deployed? Staging environment plan?
- [ ] PayNow through Stripe: confirm async handling, fees and refund behaviour in test mode.
- [ ] Face ID and saved-account tiles: any store or platform problems with several accounts on one device?
- [ ] Offline behaviour: what must work without a connection (My QR, today's schedule)?
- [ ] Push for iOS and Android: who owns the Apple and Google accounts (the company must).

**Quality and risk**
- [ ] Who runs the outside penetration test and when?
- [ ] How are secrets, backups and a tested restore handled?
- [ ] Monitoring: crash reporting, uptime alerts, cost alerts on every provider.
- [ ] Anything in this checklist you would build differently?

**Accounts the company must own (two-step sign-in on all):** Apple Developer (needs a D-U-N-S number, can take weeks), Google Play, Supabase, Stripe, SMS provider (register the Singapore sender name), email domain with SPF, DKIM and DMARC, domains and DNS.

---

## 15. Source of truth for the details

| Topic | File |
| --- | --- |
| Tickets, rule text, config keys, open decisions | `MASTER_BUILD_PLAN.md` |
| Rule ids and fee and refund examples | `RULES.md` |
| Sports, formats, scoring, draft, live, maintenance | `SPORTS_AND_FORMATS.md` |
| Which screen is which | `SCREENS.md`, `SCREENS_UPDATE_30OCT.md` |
| Security checklist | `BUILD_GUIDE.md` section 7 |
| Database | `supabase/migrations/0001` to `0007`, `supabase/seed.sql` |
| Where to edit what | `MASTER_BUILD_PLAN.md` section 14 |
