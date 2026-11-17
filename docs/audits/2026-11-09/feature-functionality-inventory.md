# OlympusGO — implemented features and file inventory

Reviewed: 9 November 2026. Repository base: `023653c`, including the existing uncommitted working-tree changes.

## What this report means

OlympusGO is already a substantial Flutter application with a Supabase backend, a separate Flutter staff console, and a Python video-analysis worker. It is beyond a screen prototype. However, a feature having screens, repositories and database functions does **not** mean it is enabled, deployed, externally integrated or ready to launch.

This is a file-level inventory and targeted static implementation review, not an exhaustive line-by-line correctness or security audit. All files in the inventory were classified; authored source was scanned for its declarations, integrations and implementation boundaries. Representative execution paths, repositories, router wiring, migrations, service adapters and tests were inspected more closely. Generated files, images and platform scaffolding were inventoried separately from product functionality. No production environment was accessed.

The inventory covers 716 existing files returned by Git's tracked/unignored-file listing, excluding local agent configuration. Ignored dependencies, build outputs and local secret/environment files are outside scope. Counts describe the snapshot taken before this report was added. Migration dates are filenames, not proof of deployment dates.

| Implementation area | Files |
| --- | ---: |
| Authored mobile Dart files | 210 |
| Generated mobile Dart files | 43 |
| Staff console Dart implementation files | 23 |
| SQL migration files | 68 |
| Numbered database test files | 55 |
| Edge Function entrypoints | 15 |
| Dart test files across app, admin and packages | 54 |
| TypeScript test files | 8 |
| Python test files | 4 |

These are file counts, not counts of independent features or passing tests.

## Status legend

- **Implemented:** screens and supporting implementation exist in the working tree. This is not a launch-readiness claim.
- **Implemented, gated:** substantial implementation exists, but flags default off or release conditions remain.
- **Partial:** important subflows are missing, placeholders, or inconsistent with newer decisions.
- **Demo only / unavailable:** a screen or interface exists, but the real repository refuses the action or returns sample/empty data.

The app explicitly switches between Supabase repositories and in-memory demo repositories in `lib/core/providers.dart`. A convincing demo can therefore show more than the configured backend supports. `lib/main.dart` starts demo mode when Supabase configuration is absent.

## Features and functionality already built

### 1. App structure and navigation — implemented

- Five main tabs: Main, Discover, Scan, Inbox and Profile.
- Eight category entry points: Play, Group, Academy, Venue, Services, Game, Shop and Fitness.
- Search, configurable home-category ordering, activity shelves and links into groups and products.
- Navigation for sign-in, onboarding, restricted accounts and closing accounts, plus app detail routes and back navigation.
- Sharing and route parsing for profiles, Meets, clubs, teams, tournaments, events and academies.
- Shared components, light/dark themes, typography, spacing, forms, sheets, lists, avatars, loading placeholders and error surfaces.
- The current working tree contains the Jost Regular/Medium typography changes and refreshed settings/profile screens. Fonts are still fetched at runtime with a fallback.

Evidence: `lib/main.dart`, `lib/core/router/`, `lib/core/share.dart`, `lib/features/shell/`, `lib/features/home/`, `packages/og_design/`.

### 2. Registration and login — implemented; delivery integration unproven

- Mobile-first code-based registration/login; email and username login alternatives.
- Custom `resolve-login` issuance and verification flow, generic replies, identifier normalization, hashing, rate limiting and failed-code lockout.
- Six-digit codes; the current code and latest migration use a three-minute validity/resend UI window, superseding older notes.
- Onboarding collects name, birthday/country, sports, starting skill levels and username; optional verified email.
- Mobile/email change flows with code verification.
- Saved-account tiles, per-account Face ID opt-in, secure session/token storage, tile removal and session restoration.
- Account recovery request submission.

Limits: SMS/email adapter code is present, but the status notes do not establish real-provider delivery. Recovery request capture is not evidence of a complete staff identity-recovery journey. Device-level biometric behavior was not re-tested in this review.

Evidence: `lib/features/auth/`, `lib/features/onboarding/`, `lib/core/config/session_storage.dart`, `supabase/functions/resolve-login/`, migrations `own_login_codes` and `three_minute_codes`.

### 3. Profiles, Passport and settings — implemented with some placeholders

- Own and other-player profiles, avatar, display name, username, biography and gender editing.
- Sports and levels, session history, ratings, provisional-rating presentation and history charts.
- Followers/following, sharing, saved players and saved activities/items.
- Searchable “Settings and activity” menu, editable profile fields and account information.
- Phone/email editing, birthday and account-region display, country selection, Face ID preference, notifications and privacy settings.
- Blocked-account management, help requests, terms/privacy/community-rules screens and logout.

Limits: Time management routes to `ComingSoonScreen`. Language choices do not establish a translated application. Detailed point-by-point sport statistics are not complete. An explicit “log out of all devices” implementation was not found.

Evidence: `lib/features/profile/`, `lib/features/settings/`, `lib/features/social/`, `lib/core/router/app_router.dart`.

### 4. Guardian links and restricted access — partially implemented

- Server-assigned age handling, restricted account screens and backend request gates.
- Generate/redeem a parent-link code, approve/refuse/revoke links, view linked children/parents.
- Guardian decisions on club/team membership requests; parent access to supported child activities/content.
- Parent-mediated child check-in, lesson booking and supported clip-consent actions.
- Minor-aware discovery, chat, profile and leaderboard checks exist.

Limits: The new strong guardian-verification interface and verification records described in `DECISIONS.md` were not found in implementation. Existing leaderboard consent code still allows a guardian opt-in for minors, whereas the newer decision excludes minors from public boards. Existing controls must not be described as complete implementation of the latest guardian policy.

Evidence: `lib/features/guardian/`, `identity_age`, `safety_gate`, `review_fixes`, `leaderboards` migrations and tests 02, 03, 08, 09 and 20.

### 5. Discover and search — implemented

- Browse/search sessions; filters for relevant sport, date, location and session attributes.
- List and map presentation; coarse geohash location sharing with consent and withdrawal.
- Player suggestions/search, public profile entry points and discovery of groups and activity categories.

Limits: Public map tiles are a development choice, not verified production infrastructure. Matching quality, scale and real-device location behavior were not measured here.

Evidence: `lib/features/discover/`, `lib/features/social/presentation/search_screens.dart`, `lib/core/geohash.dart`, migration `discover`.

### 6. Meets / Play — implemented; paid flows gated

- Browse Meets, tournaments and events; sport/skill filters and saved preferences.
- Create/edit a Meet with venue, date/time, capacity, level constraints and repeating-session information.
- Join, leave, join a waitlist, guest-at-join path, joined/hosting schedule and session details.
- Organizer roster, walk-in selection, playing/non-playing host, cancellation preview and session/series cancellation.
- Check-in, attendance marking, attendance audit records and session recap.
- Score entry and disputes; match-round generation and saved rounds.
- “Game is on”/participation presentation and related notifications.

Limits: Paid joins use the payment integration described below. Adding a guest after already holding a paid place remains a recorded gap. Attendance locking and release logic still need alignment with the newer end-of-session decision.

Evidence: `lib/features/play/data/play_repository.dart`, `lib/features/play/presentation/meet_*`, `create_*`, migrations `play_core`, `money_flows`, `matches_ratings`.

### 7. QR scanning — implemented; physical camera validation outstanding

- Personal QR display and rotation; resolution of player/group/vendor/venue codes.
- Host scans player codes; supported player/guardian check-in paths.
- Group/vendor code display and ticket-scanning screens.
- Backend checks around access, blocks and minor restrictions.

Limits: Scanning a vendor/venue does not itself make a payment. Camera behavior was not run on a device in this review; simulator evidence cannot validate a camera.

Evidence: `lib/features/scan/`, Play repository, migrations `play_core`, `money_payouts_scan`, tests 06 and 32.

### 8. Clubs and groups — implemented

- Browse/create clubs; public/private pages, membership requests, joining/leaving and invitations.
- Club overview, sports/levels, details, reviews and club leaderboard.
- Member lists, role creation/editing/reordering, permission settings and role-member assignment.
- Accept/reject requests, remove/ban/unban members, ownership transfer, closure/deletion and audit history.
- Announcements, pinned/audience-targeted notices, group chat, photos and shared Meets.
- Group ranking based on counted sessions.

Limits: The Group label is broader than delivered functionality: leagues are not implemented. Group-chat retry behavior differs from direct messaging.

Evidence: `lib/features/clubs/`, migrations `clubs`, `more_tools`, `existing_fixes`, `rank_chat_push`.

### 9. Teams — implemented in the existing team model

- Create/manage a team, roster, invitations and player additions.
- Fixtures, availability, lineup editing/publication and results.
- Team chat, team overview/settings and leaving/deleting a team.

Limits: The later decision to consolidate Club/Team under `org_type = team` is not established by the current legacy team implementation. A fixture list is not a league-management engine.

Evidence: `team_screens.dart`, Club repository implementations and club/team SQL functions.

### 10. Matches, scoring and ratings — implemented with known boundaries

- Match generator package, saved rounds, court/roster rotation logic and scoring presets.
- Score submission, opponent confirmation, dispute/organizer decision paths and retry protection.
- Elo-based rating records, rating changes, history and provisional presentation.
- Sport/country ranking snapshots and club standings.
- Admin correction tools and editable scoring/level rules.

Limits: These are implementations of the existing rules, not proof that all 7 November decisions are applied. Detailed rally/point analytics and automatic suspicious-rating detection are not complete. Mixed-pair engine support does not establish an exposed end-to-end UI flow.

Evidence: `packages/match_engine/`, Play score/round screens, Profile history, migrations `matches_ratings`, `leaderboards`, `review_fixes_3/4/5`, tests 19–24.

### 11. Tournaments — implemented; paid registration unavailable

- Create tournaments and divisions; entries, doubles partner invitations and withdrawal.
- Entry lists, check-in, groups, draws, knockout rounds, round robin and groups into knockout.
- My matches, organizer controls, match calls, umpire score entry, correction/retirement and results.
- Staff score correction tooling.

Limits: Paid tournament entry remains closed. Verified-organizer rating decisions and downstream correction requirements require comparison with the current owner decisions before release.

Evidence: `competition_repository.dart`, tournament/create-competition/score screens, migrations `tournaments` and subsequent rating fixes.

### 12. Events and tickets — implemented; payments gated

- Event creation/details, programme, reminders, live-court display and cheering.
- Ticket acquisition, ticket display, ticket release and organizer cancellation.
- Ticket scanning/checking and a My tickets view.

Limits: A live-court panel is not a live-video broadcast integration. Ticket payment uses the same unfinished real payment collection integration as Meets.

Evidence: Event repository, `event_screens.dart`, migration `events`, later money migrations.

### 13. Inbox, social connections and messaging — implemented; push incomplete

- Updates and chat sections, unread/read handling and mark-all-read.
- Realtime direct-message threads, optimistic send, retry and deletion.
- Follow/unfollow, saved players, block/unblock, player/content reporting and support requests.
- Group chat and related moderation actions.
- Backend push queue, notification preferences, quiet-hour handling and an FCM sender adapter.

Limits: No confirmed device-delivered push notification; Firebase integration and client/device setup require validation. Existing age/link-end chat restrictions need a focused review against the newer guardian requirements.

Evidence: `lib/features/inbox/`, `lib/features/social/`, group chat screens, `send-push`, migrations `phase2a_social`, `rank_chat_push`.

### 14. Safety and moderation — implemented foundation, incomplete operational readiness

- Reports, case/decision records, automatic text checks, hiding/moderation paths and blocking.
- My reports, report status, second-look requests and removal appeals.
- Public legal-notice submission and community/under-18 protection screens.
- Staff reports/cases, ban approval and audit screens; role/MFA checks in backend operations.

Limits: The moderation word list still needs language review. A dedicated support-request staff inbox is not present among the admin sections. The privacy field registry remains documented but not implemented. This report does not certify all RLS paths or logging as compliant.

Evidence: `lib/features/safety/`, `admin/lib/features/reports/`, migrations `staff`, `moderation`, `safety_gate`, `admin-action`.

### 15. Money, refunds, payouts and receipts — implemented, gated; real checkout incomplete

- Append-only double-entry ledger, integer minor-unit amounts and server-calculated quotes.
- Seat/ticket reservations, expiring holds, payment state polling and idempotent webhook handling.
- Cancellation/refund rules, disputes, held-money release, organizer fee debt and payout scheduling/approval.
- Reconciliation comparison, alerts, failed-refund staff handling and audit.
- Receipts, earnings and payout-account UI; saved-card/onboarding service adapters.

Critical boundary: `SupabasePaymentGateway.canCollect` returns `Env.localStandIn`. Real Stripe collection in the app is not complete. Stripe adapters reject live keys and have local stand-ins; test-adapter code alone is not proof of a successful real Stripe test-mode flow. Default `payments.enabled` is false.

The points/voucher screens called “wallet” are not a withdrawable cash wallet. No cash-wallet feature should be inferred from those class names.

Evidence: `payment_gateway.dart`, `lib/features/earnings/`, `packages/og_money/`, money migrations, `create-payment-intent`, `stripe-webhook`, `money-worker`, `save-card`, `vendor-onboard` and `_shared/stripe.ts`.

### 16. Partner Shop — implemented catalogue/order flow; checkout gated

- Partner shops/malls, product browsing/search, product options, deals and shop following.
- Shopping cart, quantity changes, one-shop checkout quotes, stock reservations and changed-price checks.
- Points or eligible voucher discounts, orders and refund-status views.
- Owner order management, start-work/ready/cancel, collection confirmation and buyer problem reports.
- Collected-order reviews and listing reports.
- Staff shop/product catalogue, stock and order/refund tools.

Limits: No player marketplace, delivery/logistics platform, creator affiliate commission or shoppable-video integration. Checkout requires `shop.checkout` plus payments. Latest parent approval/spending-limit, returnless refund and never-ready auto-cancellation requirements are not established as implemented. Shop earnings are not fully itemized in the activity-based earnings list.

Evidence: `lib/features/shop/`, admin Shop sections, migrations `shop_partner`, `points`, `shop_money`, `voucher_checkout`.

### 17. Points, campaigns and rewards — implemented, gated

- Points ledger/lots, expiry, spending caps, oldest-first redemption and restoration on supported refunds.
- Campaign lists/details, joining, quests, progress, completion and badge/voucher issuance.
- Organizer counted-game history, milestone rewards and voucher holdings/redemption history.
- Personal gear inventory and public sport leaderboards.
- Staff campaign/voucher-type management and redemption inspection.

Limits: `points.earning`, `game.campaigns` and `game.organizer_rewards` default off. Issuing a court voucher does not mean it can be redeemed through a court-booking flow. Camera/workout challenges, creator profiles/earnings/challenge creation are sample/placeholder flows: the real Game repository throws `_soon` for the key actions.

Evidence: `lib/features/game/`, points/earnings UI, migrations `game_engine`, `voucher_checkout` and review fixes.

### 18. Academies and coaching — substantial implementation; some sample-only screens

- Academy creation, profiles, class setup, coaches and verification checklist.
- Coach profiles, licence/business-document upload and staff review; coach invitation acceptance.
- Student account-linked enrolment, enrollment requests, roster and parent/child views.
- Class scheduling/changes, attendance, parent notes, curriculum/lesson-plan editing and make-up booking.
- Trials, drop-ins and one-to-one lesson slots, reservations, cancellations, reports and lesson lists.
- Assessment templates, coach assessments, edited records, history and score charts.
- Filming-consent setting and supported guardian/child access.

Limits: Monthly/term payment is direct to the academy; real repository invoice lists are empty and pay-invoice refuses. Academy messages return an empty list; coach-pay tracking refuses. Register checks are manual, not NROC/ACRA API integrations. Paid lesson checkout is gated. The newly approved monthly term-credit system and newer lesson payout/assessment-access rules need further work.

Evidence: `lib/features/academy/`, admin Academy sections, migrations `academy`, `academy_verification`, `lessons`, `assessments`, and review fixes.

### 19. Venues — browsing implemented; court booking unavailable

- Venue list/detail, facilities, court types, prices and availability-slot calculations.
- Booking/detail/cancellation screens and legacy booking reads are present.

Critical boundary: `SupabaseVenueRepository.book()` always throws an unavailable-payments error. The demo can simulate a booking; the real app cannot complete it. Court booking is also excluded from the current launch scope.

Evidence: `lib/features/venues/`, migration `venues`, `test/venue_test.dart`.

### 20. Services — referral functionality implemented

- Partner service listing, explicit leaving-the-app confirmation and partner booking links.
- Referral record creation and staff partner-management screen.
- Shop service-product UI is separate from the referral directory.

Limits: This is not an in-app medical consultation, clinical-record system or general service-provider scheduling marketplace.

Evidence: `lib/features/services/`, admin Services screen, migration `services`.

### 21. Fitness — implemented, gated

- Exercise catalogue/details, templates, program creation/editing/deletion and training sessions.
- Sets/repetitions/weight logging, rest timer, locally retained in-progress workout and save retry.
- Workout history/totals, personal bests and exercise history.
- Plate calculator, adult-only BMI/one-rep-max paths and age-filtered exercise selection.

Limits: `fitness.enabled` defaults off. No exercise-video library, verified camera form checks, workout sharing or catalogue-admin interface. Rest timers do not provide a full background-notification feature.

Evidence: `lib/features/fitness/`, migrations `fitness`, `fitness_catalogue`, tests for calculations, screens and local repository integration.

### 22. AI workout plans — implemented with a stand-in; real output unproven

- Adult consent/withdrawal, goal/days input, plan request and editable program draft.
- Server-side limits, retry/idempotency, exercise catalogue validation and model/token accounting.
- Anthropic adapter and a deterministic local planner.

Limits: `fitness.ai_plans` defaults off. Real model output, cost and production consent/provider terms have not been validated by this review or the cited phase notes. A fake-server adapter test is not a real AI-service test.

Evidence: `ai_plan_screen.dart`, Fitness repository/providers, `ai-plan`, `_shared/planner.ts`, migration `ai_plans`.

### 23. Uploaded sports-video analysis — pipeline implemented; accuracy unproven

- Private clip upload, consent, clip lists, status, retention/extension and deletion.
- Court-frame extraction, draggable court corners, player-side choice and analysis reports/heatmap.
- Worker job claims, scoped tokens, retries, cancellation checks and staff job monitoring.
- Python court/pose/movement pipeline with separate unit tests and model/license artifacts.

Limits: `video.analysis` and `video.analysis_minors` default off. Real-match accuracy is unproven; documented tests use synthetic material. No shuttle/racket detection, rally analysis, doubles analysis, live scoring or analysis-clip playback. This is not a completed live sports-vision product.

Evidence: `lib/features/analysis/`, `workers/analysis/`, analysis Edge Functions, migrations `video_analysis`, `clip_adder`, `deletion_buckets`.

### 24. Video feed — implemented with stand-ins; hosted integration missing

- Following/discovery feeds, upload/caption/audience, likes, own-posts list, retry and deletion.
- Moderation job pipeline, first-post staff queue, signed media URLs and video-player UI.

Limits: `video.feed` defaults off. The real video-host adapter and moderation-provider registry are missing: hosted posts fail safely. Children cannot publish; comments and shoppable video are not implemented. Location metadata stripping remains a recorded blocker.

Evidence: `lib/features/feed/`, admin first-post screen, feed Edge Functions, `_shared/moderation.ts`, `_shared/video_host.ts`, feed migrations.

### 25. Account deletion — implemented; follow-up issues remain

- In-app request, immediate profile hide/access restriction and closing-account screen.
- Undo within the configured period; relevant future activity/lesson refund initiation.
- Scheduled erase/tombstone logic, file-deletion queue, financial blockers and staff alerts.
- Preserves specified historical/financial records and avoids destructive parent-to-child cascades.

Limits: The implementation retains the `auth.users` anchor row rather than hard-deleting it. Parent-initiated child deletion is not implemented; deletion email/SMS notice and several debt/payout/coach-booking edge cases remain documented. App-store acceptance is not established.

Evidence: migration `20261112090000_account_deletion.sql`, `54_account_deletion_test.sql`, deletion race script, closing/delete screens, `docs/features/account-deletion.md`, audit dated 8 November. Older phase notes saying “support-only deletion” are stale.

### 26. Staff web console — implemented

- Staff password sign-in, MFA and role-based sections.
- Audit log, sports/catalogue/users, moderation reports/cases/bans and score/rule management.
- Money alerts, held payments, refunds, payout approvals, disputes and reconciliation views.
- Shop catalogue/orders/points tools; academy verification/lessons/services.
- Campaigns/voucher types/redemptions, analysis jobs and first-post review.
- Reads through staff RPCs; mutations through the allowlisted `admin-action` service with backend role/MFA checks.

Limits: This is a staff app, not a separate complete partner web portal. Owners/coaches use the main app for their implemented tools. Support inbox, venue-code administration and other specific admin gaps remain.

Evidence: `admin/lib/`, `admin/test/`, `admin-action`, `staff_*` SQL functions.

### 27. Public web presence — static implementation

- Landing page, app-link fallback, privacy and terms pages, shared styling and redirect/header files.
- In-app share links correspond to routes in `lib/core/share.dart`.

Limits: `share_site/` is static HTML/CSS, not the planned Next.js application. App-store links still say coming soon. No independent public player web application or separate complete partner portal was found.

## Important differences between decisions and current code

These are existing implementation/decision gaps, not new product decisions. No business behavior was changed to resolve them during this inventory. The existing Q references are retained; the source documents were not rewritten.

| Topic | Evidence in implementation | Newer documented requirement / consequence |
| --- | --- | --- |
| Guardian assurance | Parent-link paths exist; no `IdentityVerifier` / `guardian_verifications` implementation found | G1 / Q43 / Q233 require stronger guardian assurance; do not describe it as finished |
| Public minor ranking | `private.listable` still has a guardian-consent branch | G1 / Q54 exclude minors from public leaderboards |
| Meet attendance lock | `private.attendance_open` uses the activity's local day boundary | Q44 / Q157 and clarification 13 require locking at session end |
| Meet money release | Money sweep still checks saved attendance or `funds.release_after_hours` | Clarification 14 requires release only at the session-end lock |
| Lesson payout hold | `lesson_mark_attendance` invokes `private.release_lesson` immediately | Q114 calls for a configurable 48-hour hold after Present |
| Payout second approval | Migration default is `payout.second_approver_minor = 500000` (S$5,000) | Q9 decision specifies S$500; no migration updating that default was found |
| Academy invitations | Real `inviteParent` still calls the mobile-based invitation path | Q133 calls for link/QR/academy-ID invitations instead |
| Term credits | Existing make-up credits are present, but no monthly term-credit implementation found | NEW-9 is a separate feature, not completed by make-up booking |
| Shop safeguards | Existing checkout/handover code does not establish newer parent limits, returnless-refund or never-ready automation | Q88 / Q90 / NEW-10 need implementation verification/work |
| Documentation status | `BUILD_PLAN.md` and early checklist tables retain many “To do” / “not started” rows | Source and later feature notes show substantial completed code; those tables cannot measure current completion |

## Verification performed for this report

- **Passed:** `deno test --cached-only --no-check=remote -A supabase/functions` — **115 passed, 0 failed**. These exercise shared logic/adapters with fixtures and stand-ins; they do not prove hosted providers work.
- **Source analysis completed:** cached Dart SDK `dart analyze lib admin/lib packages` reported **“No issues found!”**. The process subsequently exited with a telemetry filesystem-permission error, so this was not a clean command exit.
- **Blocked before analysis:** standard `flutter analyze --no-pub` attempted to update the Flutter SDK cache outside writable workspace roots.
- **Not run:** Flutter widget/golden/integration suites, database reset/pgTAP/races, Python worker/container tests, real-device camera/biometrics, hosted services and browser walkthroughs. Historical walkthrough/test claims are identified as such in the phase notes, not represented as newly executed checks.
- Existing uncommitted source and test changes were preserved. This task adds documentation only.

## Practical assessment

The strongest existing product foundation is **accounts, profiles, discovery, clubs/teams, Meets, attendance, scoring, tournaments and staff operations**. Shop, academy, rewards and fitness also have substantial end-to-end code, with significant gates and specific gaps. Real money collection, real AI-plan quality, real video moderation/hosting and real-game sports-analysis accuracy are not complete.

A defensible next milestone is a verified development/pilot build of the core community journey, followed by decision-alignment work and provider validation. A percentage-complete estimate would be misleading until the latest requirements are reconciled with code and the complete test/device matrix is run.

## File-by-file appendix

The following index gives each inventoried file's role and the symbols or operations found in it. Symbol lists are navigation aids, not independent proof that every branch works. SQL entries describe what each migration introduces/replaces; later migrations can supersede or drop those objects. Test files describe coverage intent, not a fresh passing result. Generated serialization/provider code and static assets are explicitly labeled.


### Repository root and CI

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `.github/workflows/ci.yml` | 131 | CI definition for secrets, Flutter, database/races, Edge Functions, worker container and local integration tests; workflow results not verified. |
| `.gitignore` | 57 | Repository build/tooling metadata; not a standalone application feature. |
| `.metadata` | 33 | Repository build/tooling metadata; not a standalone application feature. |
| `AGENTS.md` | 139 | Documentation: AGENTS.md — OlympusGO. Requirements/status evidence, not executable functionality. |
| `CLAUDE.md` | 12 | Documentation: CLAUDE.md — OlympusGO. Requirements/status evidence, not executable functionality. |
| `README.md` | 48 | Documentation: OlympusGO. Requirements/status evidence, not executable functionality. |
| `analysis_options.yaml` | 36 | Dart analysis/lint configuration. |
| `env.example.json` | 4 | Example runtime configuration schema; no live configuration values included in this report. |
| `pubspec.lock` | 1623 | Resolved Dart dependency versions; no independent functionality. |
| `pubspec.yaml` | 125 | Dart/Flutter package dependencies, workspace membership and build metadata. |

### Staff console — host/build files

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `admin/.gitignore` | 48 | Repository build/tooling metadata; not a standalone application feature. |
| `admin/.metadata` | 30 | Repository build/tooling metadata; not a standalone application feature. |
| `admin/analysis_options.yaml` | 33 | Dart analysis/lint configuration. |
| `admin/pubspec.yaml` | 29 | Dart/Flutter package dependencies, workspace membership and build metadata. |
| `admin/web/favicon.png` | 917 bytes | Flutter staff-web host template, manifest or icon asset. |
| `admin/web/icons/Icon-192.png` | 5292 bytes | Flutter staff-web host template, manifest or icon asset. |
| `admin/web/icons/Icon-512.png` | 8252 bytes | Flutter staff-web host template, manifest or icon asset. |
| `admin/web/icons/Icon-maskable-192.png` | 5594 bytes | Flutter staff-web host template, manifest or icon asset. |
| `admin/web/icons/Icon-maskable-512.png` | 20998 bytes | Flutter staff-web host template, manifest or icon asset. |
| `admin/web/index.html` | 46 | Flutter staff-web host template, manifest or icon asset. |
| `admin/web/manifest.json` | 35 | Flutter staff-web host template, manifest or icon asset. |

### Staff console — implementation

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `admin/lib/core/config.dart` | 5 | Staff console implementation; shared entry/infrastructure. Declarations: Config. |
| `admin/lib/core/staff_api.dart` | 84 | Staff console implementation; shared entry/infrastructure. Declarations: StaffFailure, StaffApi. |
| `admin/lib/core/ui.dart` | 116 | Staff console implementation; shared entry/infrastructure. Declarations: StaffPage, Loaded. |
| `admin/lib/features/academy/lessons_screen.dart` | 107 | Staff console implementation; academy. Declarations: LessonsScreen. |
| `admin/lib/features/academy/services_screen.dart` | 146 | Staff console implementation; academy. Declarations: ServicesScreen. |
| `admin/lib/features/academy/verification_screen.dart` | 258 | Staff console implementation; academy. Declarations: VerificationScreen. |
| `admin/lib/features/analysis/analysis_screen.dart` | 127 | Staff console implementation; analysis. Declarations: AnalysisScreen. |
| `admin/lib/features/audit/audit_screen.dart` | 39 | Staff console implementation; audit. Declarations: AuditScreen. |
| `admin/lib/features/auth/login_screen.dart` | 76 | Staff console implementation; auth. Declarations: LoginScreen. |
| `admin/lib/features/auth/mfa_screen.dart` | 112 | Staff console implementation; auth. Declarations: MfaScreen. |
| `admin/lib/features/auth/session.dart` | 29 | Staff console implementation; auth. Declarations: StaffSession. |
| `admin/lib/features/game/campaigns_screen.dart` | 682 | Staff console implementation; game. Declarations: CampaignsScreen. |
| `admin/lib/features/money/money_screens.dart` | 599 | Staff console implementation; money. Declarations: MoneyScreen. |
| `admin/lib/features/posts/first_posts_screen.dart` | 205 | Staff console implementation; posts. Declarations: FirstPostsScreen. |
| `admin/lib/features/reports/reports_screens.dart` | 282 | Staff console implementation; reports. Declarations: ReportsScreen, CaseScreen, BansScreen. |
| `admin/lib/features/shell/admin_shell.dart` | 75 | Staff console implementation; shell. Declarations: Section, AdminShell. |
| `admin/lib/features/shop/catalogue_screen.dart` | 399 | Staff console implementation; shop. Declarations: CatalogueScreen. |
| `admin/lib/features/shop/orders_screen.dart` | 453 | Staff console implementation; shop. Declarations: OrdersScreen. |
| `admin/lib/features/sports/rules_screen.dart` | 179 | Staff console implementation; sports. Declarations: RulesScreen. |
| `admin/lib/features/sports/scores_screen.dart` | 117 | Staff console implementation; sports. Declarations: ScoresScreen. |
| `admin/lib/features/sports/sports_screen.dart` | 185 | Staff console implementation; sports. Declarations: SportsScreen. |
| `admin/lib/features/users/users_screen.dart` | 148 | Staff console implementation; users. Declarations: UsersScreen. |
| `admin/lib/main.dart` | 167 | Staff console implementation; shared entry/infrastructure. Declarations: AdminApp. |

### Staff console — tests

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `admin/test/academy_screens_test.dart` | 184 | Tests: verifying an academy deletes its file, rejecting a licence sends the reason, a role that can’t see it gets the refusal, a reported lesson can go either way, a released lesson can only be refunded (+1 more). Coverage source; only the TypeScript suite was run here. |
| `admin/test/analysis_screen_test.dart` | 102 | Tests: shows the queue, failures, storage and cost, retrying asks for a reason, a role without access sees the error. Coverage source; only the TypeScript suite was run here. |
| `admin/test/campaigns_screen_test.dart` | 179 | Tests: A-09 a draft can be published, with a reason, A-09 voucher types show their funder, A-09 each role sees only what it can do, A-09 content staff can\, A-09 organizer games say why (+2 more). Coverage source; only the TypeScript suite was run here. |
| `admin/test/first_posts_screen_test.dart` | 116 | Tests: a post shows its caption, not its person, an empty queue says so, approving needs a reason, rejecting says which, a refused video shows why. Coverage source; only the TypeScript suite was run here. |
| `admin/test/money_screen_test.dart` | 171 | Tests: A-06 shows the money at a glance, A-06 a refused role sees no money, A-06 a held report can be released, with a reason, A-06 alerts read as sentences, and empty holds stay out, A-06 a run over the limit asks for a second approval. Coverage source; only the TypeScript suite was run here. |
| `admin/test/shop_screens_test.dart` | 183 | Tests: A-07 lists shops, and stock moves by an amount, A-07 a price becomes cents, not a double, A-07 a report is decided by line, with a reason, A-07 a refused role sees nothing. Coverage source; only the TypeScript suite was run here. |
| `admin/test/widget_test.dart` | 44 | Tests: A-01 a failed read shows a sentence, not a stack trace, A-01 an empty list says so. Coverage source; only the TypeScript suite was run here. |

### Native platform scaffolding and assets

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `android/.gitignore` | 14 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/build.gradle.kts` | 49 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/debug/AndroidManifest.xml` | 7 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/AndroidManifest.xml` | 47 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/kotlin/com/olympusgo/olympus_go/MainActivity.kt` | 5 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/res/drawable-v21/launch_background.xml` | 12 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/res/drawable/launch_background.xml` | 12 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | 544 bytes | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | 442 bytes | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | 721 bytes | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | 1031 bytes | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | 1443 bytes | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/res/values-night/styles.xml` | 18 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/main/res/values/styles.xml` | 18 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/app/src/profile/AndroidManifest.xml` | 7 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/build.gradle.kts` | 24 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/gradle.properties` | 6 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/gradle/wrapper/gradle-wrapper.properties` | 5 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `android/settings.gradle.kts` | 26 | Android platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/.gitignore` | 34 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Flutter/AppFrameworkInfo.plist` | 24 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Flutter/Debug.xcconfig` | 1 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Flutter/Release.xcconfig` | 1 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner.xcodeproj/project.pbxproj` | 647 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | 7 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | 8 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | 8 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | 119 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner.xcworkspace/contents.xcworkspacedata` | 7 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | 8 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | 8 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/AppDelegate.swift` | 16 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | 122 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | 10932 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png` | 295 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png` | 406 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png` | 450 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png` | 282 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png` | 462 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png` | 704 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png` | 406 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png` | 586 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png` | 862 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png` | 862 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png` | 1674 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png` | 762 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png` | 1226 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png` | 1418 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json` | 23 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` | 68 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` | 68 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` | 68 bytes | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | 5 | Documentation: Launch Screen Assets. Requirements/status evidence, not executable functionality. |
| `ios/Runner/Base.lproj/LaunchScreen.storyboard` | 37 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Base.lproj/Main.storyboard` | 26 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Info.plist` | 80 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/Runner-Bridging-Header.h` | 1 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/Runner/SceneDelegate.swift` | 6 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |
| `ios/RunnerTests/RunnerTests.swift` | 12 | iOS platform build/runner configuration or app asset; supports deployment, not an independent product feature. |

### Project documentation and earlier audit evidence

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `docs/API.md` | 271 | Documentation: Server API. Requirements/status evidence, not executable functionality. |
| `docs/ARCHITECTURE.md` | 794 | Documentation: OlympusGO technical architecture. Requirements/status evidence, not executable functionality. |
| `docs/BUILD_PLAN.md` | 203 | Documentation: Build plan. Requirements/status evidence, not executable functionality. |
| `docs/DATA_MODEL.md` | 605 | Documentation: Data model. Requirements/status evidence, not executable functionality. |
| `docs/DECISIONS.md` | 293 | Documentation: OlympusGO: Owner decisions on the open questions (7 Nov 2026). Requirements/status evidence, not executable functionality. |
| `docs/DESIGN_SYSTEM.md` | 122 | Documentation: Design system. Requirements/status evidence, not executable functionality. |
| `docs/DEVELOPER_CHECKLIST.md` | 379 | Documentation: OlympusGO developer checklist. Requirements/status evidence, not executable functionality. |
| `docs/OPEN_QUESTIONS.md` | 272 | Documentation: Open questions. Requirements/status evidence, not executable functionality. |
| `docs/PRD.md` | 437 | Documentation: OlympusGO PRD. Requirements/status evidence, not executable functionality. |
| `docs/PRD_TOURNAMENTS_SPORT_PROFILE.md` | 234 | Documentation: OlympusGO PRD: Tournaments and Sport Profile. Requirements/status evidence, not executable functionality. |
| `docs/REBUILD_PROMPT.md` | 150 | Documentation: Prompt: rebuild OlympusGO. Requirements/status evidence, not executable functionality. |
| `docs/RULES.md` | 325 | Documentation: Business rules. Requirements/status evidence, not executable functionality. |
| `docs/SCREENS.md` | 638 | Documentation: Screens. Requirements/status evidence, not executable functionality. |
| `docs/TESTING.md` | 580 | Documentation: Testing. Requirements/status evidence, not executable functionality. |
| `docs/UAT_CHECKLIST.md` | 385 | Documentation: OlympusGO UAT checklist. Requirements/status evidence, not executable functionality. |
| `docs/audits/2026-11-05/REPORT.md` | 597 | Documentation: OlympusGO whole-app audit — 5 November 2026. Requirements/status evidence, not executable functionality. |
| `docs/audits/2026-11-05/audit-data.json` | 528 | Existing audit data, source excerpt or walkthrough evidence; historical, not a new test result. |
| `docs/audits/2026-11-05/evidence/accountHub-large-text.png` | 42249 bytes | Existing documentation/evidence image; metadata inventoried, image not re-reviewed. |
| `docs/audits/2026-11-05/evidence/accountHub.png` | 76189 bytes | Existing documentation/evidence image; metadata inventoried, image not re-reviewed. |
| `docs/audits/2026-11-05/evidence/activity.png` | 75029 bytes | Existing documentation/evidence image; metadata inventoried, image not re-reviewed. |
| `docs/audits/2026-11-05/evidence/audit_accessibility_tmp_test.dart.txt` | 167 | Existing audit data, source excerpt or walkthrough evidence; historical, not a new test result. |
| `docs/audits/2026-11-05/evidence/audit_new_routes_tmp_test.dart.txt` | 166 | Existing audit data, source excerpt or walkthrough evidence; historical, not a new test result. |
| `docs/audits/2026-11-05/evidence/audit_visual_tmp_test.dart.txt` | 166 | Existing audit data, source excerpt or walkthrough evidence; historical, not a new test result. |
| `docs/audits/2026-11-05/evidence/deleteAccount.png` | 84664 bytes | Existing documentation/evidence image; metadata inventoried, image not re-reviewed. |
| `docs/audits/2026-11-05/evidence/home-large-text.png` | 61817 bytes | Existing documentation/evidence image; metadata inventoried, image not re-reviewed. |
| `docs/audits/2026-11-05/evidence/home.png` | 71779 bytes | Existing documentation/evidence image; metadata inventoried, image not re-reviewed. |
| `docs/audits/2026-11-05/evidence/olympus-audit-final-routes.tsv` | 251 | Existing audit data, source excerpt or walkthrough evidence; historical, not a new test result. |
| `docs/audits/2026-11-05/evidence/olympus-audit-large-text.tsv` | 251 | Existing audit data, source excerpt or walkthrough evidence; historical, not a new test result. |
| `docs/audits/2026-11-05/evidence/olympus-audit-new-routes.tsv` | 16 | Existing audit data, source excerpt or walkthrough evidence; historical, not a new test result. |
| `docs/audits/2026-11-05/evidence/play-large-text.png` | 50572 bytes | Existing documentation/evidence image; metadata inventoried, image not re-reviewed. |
| `docs/audits/2026-11-05/evidence/profile.png` | 80498 bytes | Existing documentation/evidence image; metadata inventoried, image not re-reviewed. |
| `docs/audits/2026-11-05/evidence/scan-large-text.png` | 52411 bytes | Existing documentation/evidence image; metadata inventoried, image not re-reviewed. |
| `docs/audits/2026-11-05/evidence/shop.png` | 72798 bytes | Existing documentation/evidence image; metadata inventoried, image not re-reviewed. |
| `docs/audits/2026-11-08/REPORT.md` | 120 | Documentation: Account deletion UAT — 8 November 2026. Requirements/status evidence, not executable functionality. |
| `docs/audits/2026-11-09/type-audit.md` | 4251 | Documentation: Type audit: text styles in the mobile app (Part A, steps 1 and 2). Requirements/status evidence, not executable functionality. |
| `docs/features/account-deletion.md` | 19 | Documentation: Account deletion. Requirements/status evidence, not executable functionality. |
| `docs/features/dev-setup.md` | 44 | Documentation: Developer set-up (P0-01, P0-04). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-1-status.md` | 53 | Documentation: Status against DEVELOPER_CHECKLIST.md (30 Oct 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-2-status.md` | 29 | Documentation: Status against DEVELOPER_CHECKLIST.md: Phase 2 (31 Oct 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-3-status.md` | 42 | Documentation: Status against DEVELOPER_CHECKLIST.md: Phase 3 (31 Oct 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-4a-status.md` | 62 | Documentation: Status against DEVELOPER_CHECKLIST.md: Phase 4a (1 Nov 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-4b-status.md` | 35 | Documentation: Status against DEVELOPER_CHECKLIST.md: Phase 4b (1 Nov 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-4c-status.md` | 33 | Documentation: Status against DEVELOPER_CHECKLIST.md: Phase 4c (1 Nov 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-4d-status.md` | 42 | Documentation: Status against DEVELOPER_CHECKLIST.md: Phase 4d (1 Nov 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-5a-status.md` | 49 | Documentation: Status against DEVELOPER_CHECKLIST.md: Phase 5a (1 Nov 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-5b-status.md` | 42 | Documentation: Status against DEVELOPER_CHECKLIST.md: Phase 5b (1 Nov 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-5c-status.md` | 58 | Documentation: Status against DEVELOPER_CHECKLIST.md: Phase 5c (2 Nov 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/phase-5d-status.md` | 43 | Documentation: Status against DEVELOPER_CHECKLIST.md: Phase 5d (2 Nov 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/play-hosting.md` | 19 | Documentation: Hosting a Meet. Requirements/status evidence, not executable functionality. |
| `docs/features/restricted-mode.md` | 23 | Documentation: Age paths, restricted mode and parent links. Requirements/status evidence, not executable functionality. |
| `docs/features/sign-in-redesign.md` | 71 | Documentation: Sign-in, onboarding and account screens redesign (owner, 8 Nov 2026). Requirements/status evidence, not executable functionality. |
| `docs/features/sign-in.md` | 23 | Documentation: Sign-in. Requirements/status evidence, not executable functionality. |

### Mobile — shared infrastructure and entrypoint

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/core/config/env.dart` | 34 | Shared app infrastructure/components. Declarations: Env. |
| `lib/core/config/session_storage.dart` | 51 | Shared app infrastructure/components. Declarations: SecureSessionStorage, SessionHttpClient. |
| `lib/core/demo/demo_world.dart` | 286 | Shared app infrastructure/components. Declarations: DemoWorld. |
| `lib/core/domain/code_rules.dart` | 8 | Shared app infrastructure/components. Declarations: CodeRules. |
| `lib/core/domain/country.dart` | 68 | Shared app infrastructure/components. Declarations: Country. |
| `lib/core/format.dart` | 87 | Shared app infrastructure/components. Declarations: Fmt. |
| `lib/core/geohash.dart` | 36 | Shared app infrastructure/components. Functions: geohash. |
| `lib/core/navigation/breadcrumbs.dart` | 117 | Shared app infrastructure/components. Declarations: StackObserver, Crumb, Crumbs. |
| `lib/core/providers.dart` | 219 | Shared app infrastructure/components. Declarations: SessionProfile. |
| `lib/core/providers.g.dart` | 1157 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/core/router/app_router.dart` | 977 | Shared app infrastructure/components. Functions: verifyChangeRedirect, appRouter. |
| `lib/core/router/app_router.g.dart` | 51 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/core/router/motion_page.dart` | 89 | Shared app infrastructure/components. Declarations: MotionPage. |
| `lib/core/router/routes.dart` | 364 | Shared app infrastructure/components. Declarations: Routes. |
| `lib/core/share.dart` | 62 | Shared app infrastructure/components. Declarations: Links. |
| `lib/core/theme/og_colors.dart` | 1 | Shared app infrastructure/components. |
| `lib/core/theme/og_layout.dart` | 1 | Shared app infrastructure/components. |
| `lib/core/theme/og_text.dart` | 1 | Shared app infrastructure/components. |
| `lib/core/theme/og_theme.dart` | 1 | Shared app infrastructure/components. |
| `lib/core/theme/og_tones.dart` | 1 | Shared app infrastructure/components. |
| `lib/core/theme/og_type.dart` | 1 | Shared app infrastructure/components. |
| `lib/core/widgets/avatar.dart` | 97 | Shared app infrastructure/components. Declarations: AvatarTone, Avatar. |
| `lib/core/widgets/cupertino_sheets.dart` | 100 | Shared app infrastructure/components. |
| `lib/core/widgets/mascot.dart` | 31 | Shared app infrastructure/components. Declarations: Mascot. |
| `lib/core/widgets/og_buttons.dart` | 200 | Shared app infrastructure/components. Declarations: OgButtonStyle, OgButton, OgMethodButton, OgTextLink, OgBackButton. |
| `lib/core/widgets/og_fields.dart` | 353 | Shared app infrastructure/components. Declarations: OgTextField, OgInput, OgSelectField, OgCodeField. |
| `lib/core/widgets/og_icon.dart` | 273 | Shared app infrastructure/components. Declarations: OgIcons, OgIcon. |
| `lib/core/widgets/og_kit.dart` | 2066 | Shared app infrastructure/components. Declarations: KitLead, KitHeader, KitBack, KitBackPill, KitTrail, KitIconButton, KitScaffold, KitBottomBar, KitButtonStyle, KitButton (+30 more). |
| `lib/core/widgets/og_rows.dart` | 616 | Shared app infrastructure/components. Declarations: SectionLabel, RowGroup, NavRow, SwitchRow, OgSearchField, PillTabs, ListRow, OgChip, RadioRow, KeyValueRow (+2 more). |
| `lib/core/widgets/og_screen.dart` | 265 | Shared app infrastructure/components. Declarations: OgFlowScreen, OgHeading, StepProgress, OgErrorText, OgIconBadge. |
| `lib/core/widgets/og_toast.dart` | 111 | Shared app infrastructure/components. Functions: showOgToast. |
| `lib/core/widgets/pay_sheet.dart` | 260 | Shared app infrastructure/components. Functions: showPaySheet. |
| `lib/core/widgets/phone_field.dart` | 190 | Shared app infrastructure/components. Declarations: PhoneField. |
| `lib/core/widgets/place_code.dart` | 75 | Shared app infrastructure/components. Functions: showPlaceCode. |
| `lib/core/widgets/pressable.dart` | 74 | Shared app infrastructure/components. Declarations: Pressable. |
| `lib/core/widgets/resend_timer.dart` | 86 | Shared app infrastructure/components. Declarations: ResendTimer. |
| `lib/core/widgets/settings_list.dart` | 609 | Shared app infrastructure/components. Declarations: SettingsStyle, SettingsRow, SkeletonBlock, SettingsSection, SettingsList, SettingsSearchBar, ReadableWidth, SettingsLoadError. |
| `lib/main.dart` | 61 | App startup, Supabase/demo selection and theme/router attachment. Declarations: OlympusGoApp. |

### Mobile — Academies, coaching, lessons and assessments

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/academy/application/academy_providers.dart` | 188 | Academies, coaching, lessons and assessments — state/providers. Declarations: AcademyDraftController. |
| `lib/features/academy/application/academy_providers.g.dart` | 2307 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/academy/data/academy_repository.dart` | 1706 | Academies, coaching, lessons and assessments — data access. Contains separate Supabase and demo implementations. Declarations: AcademyRepository, SupabaseAcademyRepository, DemoAcademyRepository. Backend calls: academy_claim_invites, academy_list, academy_get, academy_my_students, academy_student, academy_lessons, academy_makeup_slots, academy_book_makeup, academy_answer_notice, academy_request (+20 more). |
| `lib/features/academy/data/assessment_repository.dart` | 265 | Academies, coaching, lessons and assessments — data access. Contains separate Supabase and demo implementations. Declarations: AssessmentRepository, SupabaseAssessmentRepository, DemoAssessmentRepository. Backend calls: assessment_template_list, assessment_template_save, assessment_template_archive, assessment_list, assessment_save. |
| `lib/features/academy/data/coach_repository.dart` | 294 | Academies, coaching, lessons and assessments — data access. Contains separate Supabase and demo implementations. Declarations: CoachRepository, SupabaseCoachRepository, DemoCoachRepository. Backend calls: coach_profile_get, coach_licence_my, coach_profile_save, coach_licence_submit, academy_submit_business, academy_verification, academy_claim_invites, academy_my_coach_invites, academy_coach_answer. |
| `lib/features/academy/data/lesson_repository.dart` | 374 | Academies, coaching, lessons and assessments — data access. Contains separate Supabase and demo implementations. Declarations: LessonRepository, SupabaseLessonRepository, DemoLessonRepository. Backend calls: lesson_quote, lesson_reserve, lesson_my, lesson_get, lesson_cancel, lesson_academy_cancel, lesson_mark_attendance, lesson_report, lesson_academy_list, lesson_slots_open (+3 more). |
| `lib/features/academy/domain/academy_models.dart` | 317 | Academies, coaching, lessons and assessments — models/domain logic. Declarations: AcademyRole, Billing, AcademyCoach, AcademyClass, Academy, SkillStatus, Skill, CoachNote, Student, LessonWeek (+7 more). |
| `lib/features/academy/domain/academy_models.freezed.dart` | 3883 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/academy/domain/academy_more.dart` | 123 | Academies, coaching, lessons and assessments — models/domain logic. Declarations: MessageThread, CoverCoach, CoachPay, Drill, CurriculumWeek, ClassProgress, AttendanceLine. |
| `lib/features/academy/domain/lesson_models.dart` | 384 | Academies, coaching, lessons and assessments — models/domain logic. Declarations: EnrolPlayer, LessonKind, LessonStep, LessonQuote, LessonBooking, LessonSlot, CoachProfile, CoachLicence, AcademyChecklist, ChecklistCoach (+4 more). |
| `lib/features/academy/presentation/academy_admin_screens.dart` | 596 | Academies, coaching, lessons and assessments — UI/screens. Declarations: AcademyClassEditScreen, AcademyCoachesScreen. |
| `lib/features/academy/presentation/academy_more_screens.dart` | 1794 | Academies, coaching, lessons and assessments — UI/screens. Declarations: AcademySettingsScreen, AcademyMessagesScreen, AcademyCloseScreen, ChangeClassScreen, CoachPayScreen, CurriculumScreen, LessonPlanEditScreen, InviteStudentsScreen, AttendanceHistoryScreen, ParentNoteScreen (+1 more). |
| `lib/features/academy/presentation/academy_screens.dart` | 1144 | Academies, coaching, lessons and assessments — UI/screens. Declarations: AcademyMark, AcademiesScreen, AcademyPageScreen, AcademyEnrolScreen, PlayerChoices, TrialClassScreen. |
| `lib/features/academy/presentation/assessment_screens.dart` | 517 | Academies, coaching, lessons and assessments — UI/screens. Declarations: AssessmentTemplatesScreen, AssessmentTemplateEditScreen, AssessStudentScreen, ScoreSparkline, AssessmentHistoryScreen. |
| `lib/features/academy/presentation/coach_screens.dart` | 866 | Academies, coaching, lessons and assessments — UI/screens. Declarations: AcademyTodayScreen, AcademyClassesScreen, ClassSessionScreen, ClassRosterScreen, EnrolRequestsScreen. |
| `lib/features/academy/presentation/create_academy_screens.dart` | 555 | Academies, coaching, lessons and assessments — UI/screens. Declarations: NewAcademyScreen, NewAcademyLevelsScreen, NewAcademyPoliciesScreen, NewAcademyVerifyScreen, NewAcademyCoachesScreen. |
| `lib/features/academy/presentation/lesson_screens.dart` | 760 | Academies, coaching, lessons and assessments — UI/screens. Declarations: OneToOneScreen, MyLessonsScreen, LessonDetailScreen, AcademyLessonsScreen, LessonSlotsScreen, LessonSlotEditScreen. |
| `lib/features/academy/presentation/parent_screens.dart` | 1037 | Academies, coaching, lessons and assessments — UI/screens. Declarations: StudentHomeScreen, StudentClassScreen, StudentFeesScreen, BookMakeupScreen, StudentProgressScreen. |
| `lib/features/academy/presentation/verification_screens.dart` | 457 | Academies, coaching, lessons and assessments — UI/screens. Declarations: AcademyVerifyScreen, CoachMeScreen, CoachInviteScreen, CoachPageScreen. |

### Mobile — Uploaded sports-video analysis

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/analysis/application/analysis_providers.dart` | 82 | Uploaded sports-video analysis — state/providers. Declarations: ClipUploads. |
| `lib/features/analysis/application/analysis_providers.g.dart` | 428 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/analysis/data/analysis_repository.dart` | 312 | Uploaded sports-video analysis — data access. Contains separate Supabase and demo implementations. Declarations: AnalysisRepository, SupabaseAnalysisRepository, DemoAnalysisRepository. Backend calls: analysis-local, analysis_status, clip_list, child_clip_list, clip_get, clip_create, clip_uploaded, clip_confirm_court, clip_delete, clip_extend (+1 more). |
| `lib/features/analysis/domain/analysis_models.dart` | 257 | Uploaded sports-video analysis — models/domain logic. Declarations: AnalysisStatus, ClipStatus, ClipReport, AnalysisClip, ClipFrame, PickedClip. |
| `lib/features/analysis/presentation/analysis_screens.dart` | 1028 | Uploaded sports-video analysis — UI/screens. Declarations: MyClipsScreen, ChildClipsScreen, AddClipScreen, ClipScreen. |

### Mobile — Authentication and saved accounts

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/auth/application/pending_code.dart` | 46 | Authentication and saved accounts — state/providers. Declarations: PendingCode, PendingCodeController. |
| `lib/features/auth/application/pending_code.freezed.dart` | 282 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/auth/application/pending_code.g.dart` | 63 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/auth/data/auth_repository.dart` | 342 | Authentication and saved accounts — data access. Contains separate Supabase and demo implementations. Declarations: AuthFailure, AuthRepository, SupabaseAuthRepository, DemoAuthRepository. Backend calls: resolve-login, account_recovery_request. |
| `lib/features/auth/data/biometric_vault.dart` | 180 | Authentication and saved accounts — data access. Declarations: BiometricVault. |
| `lib/features/auth/domain/saved_account.dart` | 19 | Authentication and saved accounts — models/domain logic. Declarations: SavedAccount. |
| `lib/features/auth/domain/saved_account.freezed.dart` | 294 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/auth/domain/saved_account.g.dart` | 23 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/auth/presentation/code_copy.dart` | 38 | Authentication and saved accounts — UI/screens. Declarations: CodeTarget. |
| `lib/features/auth/presentation/code_screen.dart` | 88 | Authentication and saved accounts — UI/screens. Declarations: CodeScreen. |
| `lib/features/auth/presentation/log_in_account_screen.dart` | 207 | Authentication and saved accounts — UI/screens. Declarations: LoginMethod, LogInAccountScreen. |
| `lib/features/auth/presentation/log_in_screen.dart` | 123 | Authentication and saved accounts — UI/screens. Declarations: LogInScreen, LegalLine. |
| `lib/features/auth/presentation/recovery_screens.dart` | 123 | Authentication and saved accounts — UI/screens. Declarations: RecoveryScreen, RecoverySentScreen. |
| `lib/features/auth/presentation/saved_accounts.dart` | 122 | Authentication and saved accounts — UI/screens. Declarations: AccountTile. |
| `lib/features/auth/presentation/saved_accounts.g.dart` | 58 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/auth/presentation/splash_screen.dart` | 130 | Authentication and saved accounts — UI/screens. Declarations: SplashScreen. |
| `lib/features/auth/presentation/validators.dart` | 27 | Authentication and saved accounts — UI/screens. Declarations: Validators. |
| `lib/features/auth/presentation/welcome_screen.dart` | 69 | Authentication and saved accounts — UI/screens. Declarations: WelcomeScreen. |

### Mobile — Clubs, teams, roles and group chat

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/clubs/application/club_providers.dart` | 157 | Clubs, teams, roles and group chat — state/providers. Declarations: ClubDraftController, TeamDraftController. |
| `lib/features/clubs/application/club_providers.g.dart` | 1694 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/clubs/data/club_repository.dart` | 173 | Clubs, teams, roles and group chat — data access. Declarations: ClubTab, ChatScope, ReportTarget, ClubRepository. |
| `lib/features/clubs/data/demo_club_repository.dart` | 1817 | Clubs, teams, roles and group chat — data access. In-memory demo implementation, not persisted backend behavior. Declarations: DemoClubRepository. |
| `lib/features/clubs/data/supabase_club_repository.dart` | 994 | Clubs, teams, roles and group chat — data access. Declarations: SupabaseClubRepository. Backend calls: club_list, team_list, club_get, club_for_code, club_join, club_cancel_request, club_leave, club_member_list, club_role_list, club_set_member_role (+38 more). |
| `lib/features/clubs/domain/club_models.dart` | 639 | Clubs, teams, roles and group chat — models/domain logic. Declarations: ClubVisibility, JoinMode, ClubStanding, ClubPermission, RoleLevel, ClubSportLevel, Club, ClubListItem, ClubRole, ClubMember (+26 more). |
| `lib/features/clubs/domain/club_models.freezed.dart` | 7439 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/clubs/domain/club_sport.dart` | 91 | Clubs, teams, roles and group chat — models/domain logic. Declarations: ClubSport, SkillBand, LevelRange. |
| `lib/features/clubs/presentation/club_admin_screens.dart` | 1528 | Clubs, teams, roles and group chat — UI/screens. Declarations: WithClub, ClubSettingsScreen, ClubMembersScreen, ClubMemberScreen, JoinRequestsScreen, AuditLogScreen, ClubBansScreen, ClubInviteScreen, ClubTransferScreen, ClubLeaveScreen (+1 more). |
| `lib/features/clubs/presentation/club_info_screens.dart` | 794 | Clubs, teams, roles and group chat — UI/screens. Declarations: ClubLoader, ClubAboutScreen, LeaderboardScreen. |
| `lib/features/clubs/presentation/club_overview_screen.dart` | 369 | Clubs, teams, roles and group chat — UI/screens. Declarations: ClubOverviewScreen. |
| `lib/features/clubs/presentation/club_page_screen.dart` | 1178 | Clubs, teams, roles and group chat — UI/screens. Declarations: ClubInviteLinkScreen, ClubScreen. |
| `lib/features/clubs/presentation/club_role_screens.dart` | 1042 | Clubs, teams, roles and group chat — UI/screens. Declarations: ManageRolesScreen, CreateRoleScreen, RoleEditScreen, RolePermissionsScreen, RoleMembersScreen, RoleDeleteScreen. |
| `lib/features/clubs/presentation/club_widgets.dart` | 270 | Clubs, teams, roles and group chat — UI/screens. Declarations: PlayerFace, ClubMark, TeamMark, LevelTag, BandTag, FilterGroup. |
| `lib/features/clubs/presentation/clubs_home_screen.dart` | 530 | Clubs, teams, roles and group chat — UI/screens. Declarations: ClubsHomeScreen. |
| `lib/features/clubs/presentation/create_group_screens.dart` | 1023 | Clubs, teams, roles and group chat — UI/screens. Declarations: CreateGroupTypeScreen, NewClubScreen, NewClubSportsScreen, NewClubLevelsScreen, NewClubInviteScreen, NewTeamScreen, NewTeamSportScreen, NewTeamMembersScreen. |
| `lib/features/clubs/presentation/group_chat_screens.dart` | 1482 | Clubs, teams, roles and group chat — UI/screens. Declarations: GroupChatScreen, ChatModerationScreen, AnnouncementsScreen, NewAnnouncementScreen, ReportContentScreen. |
| `lib/features/clubs/presentation/group_rank_screen.dart` | 67 | Clubs, teams, roles and group chat — UI/screens. Declarations: GroupRankScreen. |
| `lib/features/clubs/presentation/team_screens.dart` | 1880 | Clubs, teams, roles and group chat — UI/screens. Declarations: TeamMark, TeamPageScreen, TeamSettingsScreen, TeamOverviewScreen, TeamRosterScreen, TeamAddPlayersScreen, SkillBandCode, TeamFixtureScreen, EditLineupScreen, TeamLeaveScreen (+2 more). |

### Mobile — Discovery and map search

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/discover/application/discover_providers.dart` | 10 | Discovery and map search — state/providers. Functions: foundSessions. |
| `lib/features/discover/application/discover_providers.g.dart` | 91 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/discover/data/discover_repository.dart` | 120 | Discovery and map search — data access. Contains separate Supabase and demo implementations. Declarations: DiscoverRepository, SupabaseDiscoverRepository, DemoDiscoverRepository. Backend calls: discover_sessions, consent_set, location_set. |
| `lib/features/discover/discover_screen.dart` | 398 | Discovery and map search — UI. Declarations: DiscoverScreen. |
| `lib/features/discover/domain/discover_models.dart` | 32 | Discovery and map search — models/domain logic. Declarations: DiscoverFilter, FoundSession. |
| `lib/features/discover/domain/discover_models.freezed.dart` | 587 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/discover/presentation/coming_screens.dart` | 30 | Discovery and map search — UI/screens. Declarations: EmptyCategoryScreen. |
| `lib/features/discover/presentation/find_screen.dart` | 352 | Discovery and map search — UI/screens. Declarations: FindScreen. |

### Mobile — Earnings, receipts, points and payout setup

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/earnings/application/earnings_providers.dart` | 44 | Earnings, receipts, points and payout setup — state/providers. Functions: pointsSummary, pointsInfo, receipts, earnings, earningsDetail, payoutAccount, savedCard, refreshEarnings. |
| `lib/features/earnings/application/earnings_providers.g.dart` | 311 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/earnings/data/earnings_repository.dart` | 609 | Earnings, receipts, points and payout setup — data access. Contains separate Supabase and demo implementations. Declarations: PointsSummary, PointsUse, PointsInfo, ReceiptRecord, EarningSource, Earnings, EarningsBreakdown, PayoutAccount, EarningsRepository, SupabaseEarningsRepository (+1 more). Backend calls: points_my, money_my_payments, money_my_earnings, vendor-onboard, stripe-local, vendor_set_schedule, money_my_card, save-card. |
| `lib/features/earnings/presentation/earnings_screens.dart` | 781 | Earnings, receipts, points and payout setup — UI/screens. Declarations: MoneyRow, PointsWalletScreen, ReceiptsScreen, EarningsScreen, EarningsDetailScreen, PayoutAccountScreen, PaymentMethodsScreen. |

### Mobile — Moderated video feed

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/feed/application/feed_providers.dart` | 80 | Moderated video feed — state/providers. Declarations: PostUploads, ActivePost. |
| `lib/features/feed/application/feed_providers.g.dart` | 418 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/feed/data/feed_repository.dart` | 272 | Moderated video feed — data access. Contains separate Supabase and demo implementations. Declarations: FeedRepository, SupabaseFeedRepository, DemoFeedRepository. Backend calls: feed-media, feed-local, feed_status, feed_following, feed_discover, post_mine, post_create, post_uploaded, post_retry, post_delete (+2 more). |
| `lib/features/feed/domain/feed_models.dart` | 165 | Moderated video feed — models/domain logic. Declarations: FeedStatus, PostStatus, PostAudience, FeedPost. |
| `lib/features/feed/presentation/feed_screens.dart` | 826 | Moderated video feed — UI/screens. Declarations: FeedScreen, PostPlayer, AddPostScreen, MyPostsScreen. |

### Mobile — Workouts, programs and AI-plan flow

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/fitness/application/fitness_providers.dart` | 168 | Workouts, programs and AI-plan flow — state/providers. Declarations: AiPlanTicket, AiPlanRequest, ActiveSession. |
| `lib/features/fitness/application/fitness_providers.g.dart` | 430 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/fitness/data/fitness_repository.dart` | 431 | Workouts, programs and AI-plan flow — data access. Contains separate Supabase and demo implementations. Declarations: AiPlanRefused, FitnessRepository, SupabaseFitnessRepository, DemoFitnessRepository. Backend calls: exercise_list, program_list, program_save, program_delete, workout_save, workout_delete, workout_summary, exercise_history, ai_plan_status, consent_set (+2 more). |
| `lib/features/fitness/domain/fitness_calc.dart` | 98 | Workouts, programs and AI-plan flow — models/domain logic. Functions: kgText, liftedText, clockText, timeText, itemLine, bestText, minutesFor, bmiText. |
| `lib/features/fitness/domain/fitness_models.dart` | 501 | Workouts, programs and AI-plan flow — models/domain logic. Declarations: CatalogExercise, ProgramItem, ProgramDay, WorkoutProgram, LoggedSet, ActiveWorkout, AiStatus, WorkoutEntry, PersonalBest, WorkoutSummary (+1 more). |
| `lib/features/fitness/presentation/ai_plan_screen.dart` | 225 | Workouts, programs and AI-plan flow — UI/screens. Declarations: AiPlanScreen. |
| `lib/features/fitness/presentation/fitness_screens.dart` | 831 | Workouts, programs and AI-plan flow — UI/screens. Declarations: ExerciseTile, ExerciseRow, FitnessHomeScreen, ExerciseCatalogScreen, ExerciseDetailScreen, WorkoutLogScreen, CalculatorsScreen. |
| `lib/features/fitness/presentation/program_screens.dart` | 444 | Workouts, programs and AI-plan flow — UI/screens. Declarations: ProgramsScreen, ProgramBuilderScreen. |
| `lib/features/fitness/presentation/train_screen.dart` | 400 | Workouts, programs and AI-plan flow — UI/screens. Declarations: TrainScreen. |

### Mobile — Campaigns, rewards, gear and creator placeholders

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/game/application/game_providers.dart` | 63 | Campaigns, rewards, gear and creator placeholders — state/providers. Functions: campaigns, campaign, creator, creatorEarnings, creatorStatus, leaderboard, myGear, myVouchers (+3 more). |
| `lib/features/game/application/game_providers.g.dart` | 502 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/game/data/game_repository.dart` | 848 | Campaigns, rewards, gear and creator placeholders — data access. Contains separate Supabase and demo implementations. Declarations: GameRepository, SupabaseGameRepository, DemoGameRepository. Backend calls: campaign_list, campaign_get, campaign_join, voucher_my, badge_my, organizer_rewards_my. |
| `lib/features/game/domain/game_models.dart` | 425 | Campaigns, rewards, gear and creator placeholders — models/domain logic. Declarations: CampaignState, CampaignKind, Reward, Standing, Exercise, Campaign, AttemptResult, Creator, CreatorEarnings, CreatorStatus (+6 more). |
| `lib/features/game/presentation/creator_screens.dart` | 538 | Campaigns, rewards, gear and creator placeholders — UI/screens. Declarations: CreatorProfileScreen, CreatorEarningsScreen, CreatorChallengesScreen, NewChallengeScreen. |
| `lib/features/game/presentation/game_screens.dart` | 1170 | Campaigns, rewards, gear and creator placeholders — UI/screens. Declarations: StandingRow, CampaignCard, GameHomeScreen, CampaignScreen, CameraSetupScreen, AttemptScreen, AttemptReviewScreen, LeaderboardsScreen. |
| `lib/features/game/presentation/gear_screens.dart` | 350 | Campaigns, rewards, gear and creator placeholders — UI/screens. Declarations: MyGearScreen, GearItemScreen, GearEditScreen. |
| `lib/features/game/presentation/reward_screens.dart` | 205 | Campaigns, rewards, gear and creator placeholders — UI/screens. Declarations: WalletScreen, OrganizerRewardsScreen. |

### Mobile — Guardian links and restrictions

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/guardian/application/guardian_providers.dart` | 36 | Guardian links and restrictions — state/providers. Functions: restrictions, myChildren, myParents, childPosts, childListed, childGroupRequests. |
| `lib/features/guardian/application/guardian_providers.g.dart` | 357 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/guardian/data/guardian_repository.dart` | 324 | Guardian links and restrictions — data access. Contains separate Supabase and demo implementations. Declarations: GuardianRepository, SupabaseGuardianRepository, DemoGuardianRepository. Backend calls: set_birthday, my_restrictions, guardian_code_create, guardian_code_redeem, guardian_link_decide, guardian_link_revoke, guardian_leaderboard_set, guardian_child_posts, guardian_delete_post, guardian_group_requests (+2 more). |
| `lib/features/guardian/domain/guardian_models.dart` | 131 | Guardian links and restrictions — models/domain logic. Declarations: Restrictions, ParentCode, LinkStatus, GuardianLink, PendingLink, ChildPost, GroupRequest. |
| `lib/features/guardian/domain/guardian_models.freezed.dart` | 1666 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/guardian/presentation/parent_link_screens.dart` | 452 | Guardian links and restrictions — UI/screens. Declarations: RestrictedHomeScreen, ParentCodeScreen, EnterChildCodeScreen, MyChildrenScreen, ChildDetailScreen. |

### Mobile — Main tab and category ordering

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/home/application/home_categories.dart` | 80 | Main tab and category ordering — state/providers. Declarations: HomeCategory, HomeCategoriesController. |
| `lib/features/home/application/home_categories.g.dart` | 68 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/home/edit_categories_screen.dart` | 131 | Main tab and category ordering — UI. Declarations: EditCategoriesScreen. |
| `lib/features/home/home_rows.dart` | 775 | Main tab and category ordering — UI. Declarations: StatusScrim, HeroWithSearch, SearchPill, HomeSection, Shelf, ActivityShelf, ClubShelf, PlayerShelf, MallShelf, ProductShelf. |
| `lib/features/home/home_screen.dart` | 466 | Main tab and category ordering — UI. Declarations: HomeScreen. |

### Mobile — Updates and chat inbox

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/inbox/application/inbox_providers.dart` | 96 | Updates and chat inbox — state/providers. Functions: inboxUpdates, inboxUnread. |
| `lib/features/inbox/application/inbox_providers.g.dart` | 143 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/inbox/data/updates_repository.dart` | 158 | Updates and chat inbox — data access. Contains separate Supabase and demo implementations. Declarations: UpdatesRepository, SupabaseUpdatesRepository, DemoUpdatesRepository. |
| `lib/features/inbox/domain/inbox_models.dart` | 61 | Updates and chat inbox — models/domain logic. Declarations: InboxUpdate, InboxChat. |
| `lib/features/inbox/domain/inbox_models.freezed.dart` | 312 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/inbox/presentation/inbox_screen.dart` | 428 | Updates and chat inbox — UI/screens. Declarations: InboxScreen. |

### Mobile — Registration and sport selection

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/onboarding/application/onboarding_controller.dart` | 48 | Registration and sport selection — state/providers. Declarations: OnboardingController. |
| `lib/features/onboarding/application/onboarding_controller.g.dart` | 63 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/onboarding/domain/onboarding_models.dart` | 43 | Registration and sport selection — models/domain logic. Declarations: SportSkill, OnboardingDraft. |
| `lib/features/onboarding/domain/onboarding_models.freezed.dart` | 582 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/onboarding/domain/sport.dart` | 160 | Registration and sport selection — models/domain logic. Declarations: Sport, SkillScale. |
| `lib/features/onboarding/presentation/account_screens.dart` | 488 | Registration and sport selection — UI/screens. Declarations: UsernameScreen, AddEmailScreen, VerifyEmailScreen, ReadyScreen. |
| `lib/features/onboarding/presentation/name_birthday_screens.dart` | 314 | Registration and sport selection — UI/screens. Declarations: FullNameScreen, BirthdayScreen, ParentApprovalScreen. |
| `lib/features/onboarding/presentation/sports_screens.dart` | 456 | Registration and sport selection — UI/screens. Declarations: SportsScreen, SportIcon, SkillLevelScreen, SportSkillScreen. |

### Mobile — Meets, tournaments, events and scoring

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/play/application/competition_providers.dart` | 67 | Meets, tournaments, events and scoring — state/providers. Functions: tournamentInfo, tournamentEntries, drawGroups, drawKnockout, drawMatches, allDrawMatches, myTournamentMatches, tournamentResult (+4 more). |
| `lib/features/play/application/competition_providers.g.dart` | 859 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/play/application/play_providers.dart` | 311 | Meets, tournaments, events and scoring — state/providers. Declarations: PlaySports, HubFilters, ActivityDraftController. |
| `lib/features/play/application/play_providers.g.dart` | 1431 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/play/data/competition_repository.dart` | 1496 | Meets, tournaments, events and scoring — data access. Contains separate Supabase and demo implementations. Declarations: TournamentRepository, EventRepository, SupabaseTournamentRepository, SupabaseEventRepository, DemoTournamentRepository, DemoEventRepository. Backend calls: tournament_info, tournament_entry_list, tournament_groups, tournament_match_list, tournament_partner_picks, tournament_register, tournament_partner_answer, tournament_withdraw, tournament_check_in, tournament_message (+10 more). |
| `lib/features/play/data/payment_gateway.dart` | 333 | Meets, tournaments, events and scoring — data access. Declarations: PayMethod, PayQuote, PaymentHold, PaymentState, PaymentProgress, PaymentGateway, SupabasePaymentGateway, DemoPaymentGateway. Backend calls: activity_quote, activity_reserve, organizer_debt_reserve, create-payment-intent, payment_status, payment_abandon, stripe-local. |
| `lib/features/play/data/play_repository.dart` | 2098 | Meets, tournaments, events and scoring — data access. Contains separate Supabase and demo implementations. Declarations: PlayRepository, SupabasePlayRepository, DemoPlayRepository. Backend calls: meet_players, join_activity, join_waitlist, leave_activity, host_plays, walk_in_candidates, add_walk_in, save_attendance, cancel_preview, cancel_activity (+19 more). |
| `lib/features/play/domain/activity.dart` | 464 | Meets, tournaments, events and scoring — models/domain logic. Declarations: ActivityKind, GameType, ActivityFormat, MyStatus, Venue, SocialProof, Activity, Receipt, PlayFilters, PlaySportPref (+2 more). |
| `lib/features/play/domain/activity.freezed.dart` | 2439 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/play/domain/draw_logic.dart` | 200 | Meets, tournaments, events and scoring — models/domain logic. Functions: koRoundName, _koShort, drawStageName, drawSideName, gamesText, _when. |
| `lib/features/play/domain/event_models.dart` | 175 | Meets, tournaments, events and scoring — models/domain logic. Declarations: ProgrammeItem, LiveCourt, GearPick, EventClub, EventInfo, Ticket, ScanResult. |
| `lib/features/play/domain/hub.dart` | 178 | Meets, tournaments, events and scoring — models/domain logic. Declarations: HubTab, HubFilterGroup. |
| `lib/features/play/domain/meet_ops.dart` | 264 | Meets, tournaments, events and scoring — models/domain logic. Declarations: Attendance, MeetPlayer, CancelPreview, MeetRecap, ScoreStatus, MatchScore. |
| `lib/features/play/domain/tournament_models.dart` | 368 | Meets, tournaments, events and scoring — models/domain logic. Declarations: Division, EntryStatus, Entry, MyEntry, GroupRow, DrawGroup, KnockoutMatch, KnockoutRound, MatchState, MyMatch (+7 more). |
| `lib/features/play/presentation/create_competition_screens.dart` | 998 | Meets, tournaments, events and scoring — UI/screens. Declarations: BannerPicker, NewEventScreen, NewTournamentScreen. |
| `lib/features/play/presentation/create_meet_screens.dart` | 1158 | Meets, tournaments, events and scoring — UI/screens. Declarations: CreateStepHeader, CreateSection, CreatePickRow, CreateStepper, NewSportScreen, NewMeetDetailsScreen. |
| `lib/features/play/presentation/create_screens.dart` | 633 | Meets, tournaments, events and scoring — UI/screens. Declarations: PickDateScreen, PickTimeScreen, PickVenueScreen. |
| `lib/features/play/presentation/event_screens.dart` | 1615 | Meets, tournaments, events and scoring — UI/screens. Declarations: EventPageScreen, EventTicketScreen, EventReleaseScreen, EventManageScreen, EventCancelScreen, ScanTicketScreen, MyTicketsScreen, CheckTicketsScreen. |
| `lib/features/play/presentation/meet_action_screens.dart` | 733 | Meets, tournaments, events and scoring — UI/screens. Declarations: WithActivity, GuestScreen, WaitlistScreen, ScheduleScreen, CheckInScreen. |
| `lib/features/play/presentation/meet_detail_screen.dart` | 1599 | Meets, tournaments, events and scoring — UI/screens. Declarations: MeetDetailScreen, PlayerRow. |
| `lib/features/play/presentation/meet_host_screens.dart` | 1130 | Meets, tournaments, events and scoring — UI/screens. Declarations: MeetPlayersScreen, MeetWalkInScreen, MeetAttendanceScreen, MeetRecapScreen, MeetCancelScreen. |
| `lib/features/play/presentation/meet_rounds_screen.dart` | 285 | Meets, tournaments, events and scoring — UI/screens. Declarations: MeetRoundsScreen. |
| `lib/features/play/presentation/pay_flow.dart` | 346 | Meets, tournaments, events and scoring — UI/screens. Declarations: PayingFor, PaidSpot, PaymentWaitingScreen. |
| `lib/features/play/presentation/play_card.dart` | 440 | Meets, tournaments, events and scoring — UI/screens. Declarations: PlayCard. |
| `lib/features/play/presentation/play_screen.dart` | 1366 | Meets, tournaments, events and scoring — UI/screens. Declarations: PlayScreen, BandRangePicker, PlayAddSportScreen. |
| `lib/features/play/presentation/play_widgets.dart` | 609 | Meets, tournaments, events and scoring — UI/screens. Declarations: ActivityCard, ChipChoice, LabeledSelect, LevelRangeSelects, PickerRow, OptionRow, MonthCalendar. |
| `lib/features/play/presentation/score_screens.dart` | 1281 | Meets, tournaments, events and scoring — UI/screens. Declarations: ScoreEntryScreen, TournamentUmpireScreen, ScoreConfirmScreen. |
| `lib/features/play/presentation/tournament_host_screens.dart` | 1088 | Meets, tournaments, events and scoring — UI/screens. Declarations: TournamentManageScreen, TournamentEntriesScreen, TournamentCheckInScreen, TournamentMessageScreen, TournamentCancelScreen, TournamentRunScreen. |
| `lib/features/play/presentation/tournament_screens.dart` | 1909 | Meets, tournaments, events and scoring — UI/screens. Declarations: CompetitionBanner, TournamentPageScreen, MatchRow, TournamentRegisterScreen, SkillBandName, TournamentWithdrawScreen, TournamentResultsScreen. |

### Mobile — Profile and Passport

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/profile/data/profile_repository.dart` | 360 | Profile and Passport — data access. Contains separate Supabase and demo implementations. Declarations: ProfileRepository, SupabaseProfileRepository, DemoProfileRepository. Backend calls: player_session_count, my_rating, passport_history, username_available. |
| `lib/features/profile/domain/passport.dart` | 185 | Profile and Passport — models/domain logic. Declarations: PassportStats, StatCard, MonthPoint, UpcomingGame, GearKind, GearItem, DemoPassport. |
| `lib/features/profile/domain/passport.freezed.dart` | 1422 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/profile/domain/profile.dart` | 146 | Profile and Passport — models/domain logic. Declarations: Profile, PlayerSport, ProfileBadge, ProfileSummary, HistoryItem, RatingCard, PassportHistory. |
| `lib/features/profile/domain/profile.freezed.dart` | 1150 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/profile/domain/profile.g.dart` | 40 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/profile/presentation/passport_history_screen.dart` | 261 | Profile and Passport — UI/screens. Declarations: PassportHistoryScreen. |
| `lib/features/profile/presentation/passport_screen.dart` | 1477 | Profile and Passport — UI/screens. Declarations: PassportScreen. |
| `lib/features/profile/presentation/profile_screen.dart` | 518 | Profile and Passport — UI/screens. Declarations: ProfileScreen. |

### Mobile — Reports, appeals and legal/safety screens

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/safety/application/safety_providers.dart` | 18 | Reports, appeals and legal/safety screens — state/providers. Functions: myReports, safetyReport, removalNotice. |
| `lib/features/safety/application/safety_providers.g.dart` | 201 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/safety/data/safety_repository.dart` | 329 | Reports, appeals and legal/safety screens — data access. Contains separate Supabase and demo implementations. Declarations: SafetyRepository, SupabaseSafetyRepository, DemoSafetyRepository. Backend calls: my_reports, report_second_look, removal_ask_review, legal_notice_send. |
| `lib/features/safety/domain/safety_models.dart` | 133 | Reports, appeals and legal/safety screens — models/domain logic. Declarations: ReportState, SafetyReport, RemovalNotice, LegalNotice. |
| `lib/features/safety/presentation/legal_screens.dart` | 650 | Reports, appeals and legal/safety screens — UI/screens. Declarations: CountryRules, TermsPrivacyScreen, RefundRulesScreen, Under18ProtectionScreen, CountryScreen, LegalNoticeScreen. |
| `lib/features/safety/presentation/safety_screens.dart` | 464 | Reports, appeals and legal/safety screens — UI/screens. Declarations: CommunityRulesScreen, MyReportsScreen, ReportStatusScreen, RemovalNoticeScreen. |

### Mobile — QR scanning and check-in

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/scan/host_scan_screen.dart` | 92 | QR scanning and check-in — UI. Declarations: HostScanScreen. |
| `lib/features/scan/scan_player_screen.dart` | 143 | QR scanning and check-in — UI. Declarations: ScanPlayerScreen. |
| `lib/features/scan/scan_screen.dart` | 620 | QR scanning and check-in — UI. Declarations: ScanScreen. |

### Mobile — Partner-service referrals

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/services/application/services_providers.dart` | 16 | Partner-service referrals — state/providers. Functions: servicesRepository, servicePartners. |
| `lib/features/services/application/services_providers.g.dart` | 99 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/services/data/services_repository.dart` | 87 | Partner-service referrals — data access. Contains separate Supabase and demo implementations. Declarations: ServicePartner, ServicesRepository, SupabaseServicesRepository, DemoServicesRepository. Backend calls: service_partner_list, service_referral_make. |
| `lib/features/services/presentation/services_screen.dart` | 126 | Partner-service referrals — UI/screens. Declarations: ServicesScreen. |

### Mobile — Settings and account management

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/settings/application/avatar_upload.dart` | 39 | Settings and account management — state/providers. Functions: pickAvatar, pickAndUploadAvatar. |
| `lib/features/settings/application/settings_providers.dart` | 155 | Settings and account management — state/providers. Declarations: AccountInfoNotifier, MyProfileNotifier, NotificationSettings, PrivacySettings, FaceIdEnabled. |
| `lib/features/settings/application/settings_providers.g.dart` | 362 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/settings/data/settings_repository.dart` | 337 | Settings and account management — data access. Contains separate Supabase and demo implementations. Declarations: SettingsRepository, SupabaseSettingsRepository, DemoSettingsRepository. Backend calls: set_country, account_delete_request, account_delete_cancel. |
| `lib/features/settings/domain/account_info.dart` | 102 | Settings and account management — models/domain logic. Declarations: AccountInfo. |
| `lib/features/settings/domain/account_info.freezed.dart` | 279 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/settings/domain/my_profile.dart` | 80 | Settings and account management — models/domain logic. Declarations: MyProfile. |
| `lib/features/settings/domain/my_profile.freezed.dart` | 291 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/settings/domain/settings_models.dart` | 80 | Settings and account management — models/domain logic. Declarations: Gender, ProfileVisibility, AccountDetails, PrivateInfo, NotificationPrefs, PrivacyPrefs. |
| `lib/features/settings/domain/settings_models.freezed.dart` | 1120 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/settings/presentation/account_info_screens.dart` | 324 | Settings and account management — UI/screens. Declarations: AccountInfoScreen, ChangePhoneScreen, ChangeEmailScreen. |
| `lib/features/settings/presentation/account_screens.dart` | 779 | Settings and account management — UI/screens. Declarations: AccountHubScreen, ProfileSportsScreen, LanguageScreen, DeleteAccountScreen, AccountClosingScreen, IdentityCheckScreen. |
| `lib/features/settings/presentation/edit_profile_screens.dart` | 619 | Settings and account management — UI/screens. Declarations: EditProfileScreen, ProfileField, ProfileFieldScreen, ChangeUsernameScreen. |
| `lib/features/settings/presentation/settings_menu_screen.dart` | 284 | Settings and account management — UI/screens. Declarations: SettingsScreen, ComingSoonScreen. |
| `lib/features/settings/presentation/settings_screens.dart` | 679 | Settings and account management — UI/screens. Declarations: ImageSourceChoice, NotificationsScreen, PrivacyScreen, BlockedPlayersScreen, HelpScreen, LogOutScreen, VerifyPhoneChangeScreen. |

### Mobile — Main navigation shell

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/shell/main_shell.dart` | 266 | Main navigation shell — UI. Declarations: MainShell, MainTabBar. |
| `lib/features/shell/sample_content.dart` | 20 | Main navigation shell — UI. Declarations: SampleContent. |
| `lib/features/shell/tab_page.dart` | 94 | Main navigation shell — UI. Declarations: TabPage, TabTitle, SectionTitle. |
| `lib/features/shell/tab_widgets.dart` | 169 | Main navigation shell — UI. Declarations: MeetCard, CategoryRow, SmallPillButton. |

### Mobile — Partner shops and orders

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/shop/application/shop_providers.dart` | 61 | Partner shops and orders — state/providers. Functions: malls, popularProducts, shopProducts, shopDeals, productDetail, mallDetail, cart, myOrders (+4 more). |
| `lib/features/shop/application/shop_providers.g.dart` | 574 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/shop/data/shop_repository.dart` | 1259 | Partner shops and orders — data access. Contains separate Supabase and demo implementations. Declarations: ShopRepository, SupabaseShopRepository, DemoShopRepository. Backend calls: shop_malls, shop_products, shop_product, shop_mall, shop_follow, shop_cart, shop_cart_add, shop_cart_set, shop_quote, shop_reserve (+12 more). |
| `lib/features/shop/domain/commerce_models.dart` | 380 | Partner shops and orders — models/domain logic. Declarations: Review, OptionGroup, ProductDetail, MallDetail, CartLine, OrderStep, OrderLine, Order, QuoteLine, CheckoutVoucher (+1 more). |
| `lib/features/shop/domain/shop_models.dart` | 72 | Partner shops and orders — models/domain logic. Declarations: Mall, ProductArt, Product. |
| `lib/features/shop/domain/shop_models.freezed.dart` | 613 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/shop/presentation/order_screens.dart` | 1584 | Partner shops and orders — UI/screens. Declarations: CartScreen, CheckoutScreen, OrdersScreen, OrderCard, OrderDetailScreen, OrderProblemScreen, OrderCancelScreen, MoneyLine, RefundStatusScreen, ReportListingScreen (+1 more). |
| `lib/features/shop/presentation/owner_screens.dart` | 252 | Partner shops and orders — UI/screens. Declarations: OwnerOrdersScreen, OwnerOrderScreen. |
| `lib/features/shop/presentation/shop_screens.dart` | 1036 | Partner shops and orders — UI/screens. Declarations: CartButton, ProductArtBox, ProductTile, ProductGrid, ShopHomeScreen, MallPageScreen, ProductPageScreen, ServiceBookScreen. |

### Mobile — Connections, search and direct messaging

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/social/application/social_providers.dart` | 155 | Connections, search and direct messaging — state/providers. Declarations: MyFollowing, BlockedPlayers, SavedPlayers, SavedIds. |
| `lib/features/social/application/social_providers.g.dart` | 760 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/social/data/chat_repository.dart` | 318 | Connections, search and direct messaging — data access. Contains separate Supabase and demo implementations. Declarations: ChatRepository, SupabaseChatRepository, DemoChatRepository. Backend calls: open_direct_conversation, message_delete. |
| `lib/features/social/data/social_repository.dart` | 425 | Connections, search and direct messaging — data access. Contains separate Supabase and demo implementations. Declarations: SocialRepository, SupabaseSocialRepository, DemoSocialRepository. Backend calls: profile_social, suggested_players, my_blocked_players. |
| `lib/features/social/domain/social_models.dart` | 115 | Connections, search and direct messaging — models/domain logic. Declarations: PlayerSummary, PlayerSocial, PlayerDetail, SuggestedPlayer, ReportReason, SavedKind, Conversation, ChatMessage. |
| `lib/features/social/domain/social_models.freezed.dart` | 1748 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/social/presentation/chat_screen.dart` | 457 | Connections, search and direct messaging — UI/screens. Declarations: ChatScreen. |
| `lib/features/social/presentation/connections_screens.dart` | 325 | Connections, search and direct messaging — UI/screens. Declarations: ConnectionsScreen, ShareProfileScreen, SavedScreen. |
| `lib/features/social/presentation/other_profile_screens.dart` | 297 | Connections, search and direct messaging — UI/screens. Declarations: OtherProfileScreen, ReportBlockScreen. |
| `lib/features/social/presentation/search_screens.dart` | 387 | Connections, search and direct messaging — UI/screens. Declarations: RecentSearches, SearchScreen, SearchResultsScreen, OpenChatScreen. |

### Mobile — Venues and legacy court-booking screens

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `lib/features/venues/application/venue_providers.dart` | 59 | Venues and legacy court-booking screens — state/providers. Functions: venueList, venueDetail, courtSlots, myCourtBookings, courtBooking, venueActivities. |
| `lib/features/venues/application/venue_providers.g.dart` | 418 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/venues/data/venue_repository.dart` | 523 | Venues and legacy court-booking screens — data access. Contains separate Supabase and demo implementations. Declarations: VenueRepository, SupabaseVenueRepository, DemoVenueRepository. Backend calls: court_busy, cancel_court_booking. |
| `lib/features/venues/domain/venue_models.dart` | 123 | Venues and legacy court-booking screens — models/domain logic. Declarations: CourtType, VenueDetail, CourtSlot, BookingStatus, CourtBooking. |
| `lib/features/venues/domain/venue_models.freezed.dart` | 1183 | Generated model/serialization or Riverpod glue; supports the matching authored Dart source, not a separate feature. |
| `lib/features/venues/presentation/venue_screens.dart` | 1231 | Venues and legacy court-booking screens — UI/screens. Declarations: VenuesScreen, VenuePageScreen, BookCourtScreen, CourtBookingScreen, CancelCourtBookingScreen. |

### Shared packages

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `packages/match_engine/.gitignore` | 2 | Repository build/tooling metadata; not a standalone application feature. |
| `packages/match_engine/lib/match_engine.dart` | 6 | Shared match_engine package implementation. |
| `packages/match_engine/lib/src/generator.dart` | 235 | Shared match_engine package implementation. Declarations: RosterPlayer, Pairing, Round, Americano. |
| `packages/match_engine/lib/src/scoring.dart` | 58 | Shared match_engine package implementation. Declarations: ScoringPreset. |
| `packages/match_engine/pubspec.yaml` | 12 | Dart/Flutter package dependencies, workspace membership and build metadata. |
| `packages/match_engine/test/generator_test.dart` | 133 | Tests: P3-02 Americano holds over 1,000 random rosters, P3-02 partner repeats stay low, P3-02 mixed pairs honour the gender split over 1,000 rosters, P3-02 the same seed gives the same draw, P3-02 regenerating handles a late arrival and an early leaver (+1 more). Coverage source; only the TypeScript suite was run here. |
| `packages/match_engine/test/scoring_test.dart` | 51 | Tests: finished games, scores that cannot end a game, P3-01 pickleball games to 11, win by 2, junior badminton, 15 points cap 21, a match is decided by 2 games, with game 3 only after a split. Coverage source; only the TypeScript suite was run here. |
| `packages/og_design/lib/og_colors.dart` | 179 | Shared og_design package implementation. Declarations: OgColors. |
| `packages/og_design/lib/og_design.dart` | 9 | Shared og_design package implementation. |
| `packages/og_design/lib/og_layout.dart` | 103 | Shared og_design package implementation. Declarations: OgSpace, OgRadius, OgSize, OgMotion. |
| `packages/og_design/lib/og_text.dart` | 76 | Shared og_design package implementation. Declarations: OgText. |
| `packages/og_design/lib/og_theme.dart` | 81 | Shared og_design package implementation. Declarations: OgTheme. |
| `packages/og_design/lib/og_tones.dart` | 179 | Shared og_design package implementation. Declarations: OgTones. |
| `packages/og_design/lib/og_type.dart` | 151 | Shared og_design package implementation. Declarations: OgType. |
| `packages/og_design/pubspec.yaml` | 13 | Dart/Flutter package dependencies, workspace membership and build metadata. |
| `packages/og_money/.gitignore` | 2 | Repository build/tooling metadata; not a standalone application feature. |
| `packages/og_money/lib/og_money.dart` | 74 | Shared og_money package implementation. Declarations: Money. |
| `packages/og_money/pubspec.yaml` | 12 | Dart/Flutter package dependencies, workspace membership and build metadata. |
| `packages/og_money/test/og_money_test.dart` | 53 | Tests: prices read S\$8.00, sums stay in whole cents, currencies never mix, the list fee matches the fee table, points are tenths of a dollar, with integer maths (+1 more). Coverage source; only the TypeScript suite was run here. |

### Static public website

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `share_site/_headers` | 7 | Static-host response-header rules. |
| `share_site/_redirects` | 11 | Static-host URL redirects. |
| `share_site/icon.svg` | 1 | Public-site vector brand icon. |
| `share_site/index.html` | 43 | Static public landing page with a coming-soon app-store control. |
| `share_site/link.html` | 74 | Static fallback page for shared app links. |
| `share_site/privacy/index.html` | 89 | Static public landing page with a coming-soon app-store control. |
| `share_site/style.css` | 192 | Styles for static public pages. |
| `share_site/terms/index.html` | 88 | Static public landing page with a coming-soon app-store control. |

### Backend — configuration and development fixtures

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `supabase/config.toml` | 85 | Local Supabase service/auth/storage/function configuration. |
| `supabase/seed.sql` | 54 | Development fixtures and sample catalogue/activity/account data; not real-user feature evidence. |
| `supabase/templates/code_email.html` | 2 | Transactional sign-in code email template. |

### Backend — Edge Functions and shared tests

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `supabase/functions/_shared/clips.ts` | 167 | Edge service/shared logic. The worker's side of clip analysis, shared by the real worker's API and the local stand-in. Workers get a signed URL and a token for one job, never a service key or a way to write to Storage. The database checks every result again. |
| `supabase/functions/_shared/clips_test.ts` | 199 | Tests: a good court result passes, a good report passes, known failures pass, the stand-in, a sweep removes files, then clears them (+10 more). Coverage source; only the TypeScript suite was run here. |
| `supabase/functions/_shared/feed.ts` | 146 | Edge service/shared logic. A worker's side of the feed, shared by the real worker's API and the local stand-in. Workers send frames and hear nothing about the person. The verdicts go to the database, which decides what happens to the post. |
| `supabase/functions/_shared/feed_test.ts` | 155 | Tests: with nothing configured, hosted has no checks at all, the fake can, an unknown provider is refused everywhere, a named provider is used, a local stack gets the fake (+11 more). Coverage source; only the TypeScript suite was run here. |
| `supabase/functions/_shared/moderation.ts` | 53 | Edge service/shared logic. The checks a post passes before anyone sees it. No provider is chosen yet (Q214), so the registry is empty. Hosted, that throws and the post fails, and a post that fails never goes live. The fake passes a post on a local stack only, and the database refuses it unless feed.fake_checks is on as well. |
| `supabase/functions/_shared/money.ts` | 14 | Edge service/shared logic. Money crosses the wire as integer minor units. Anything else is a bug. |
| `supabase/functions/_shared/money_test.ts` | 15 | Tests: prices read S$8.00, only whole minor units pass. Coverage source; only the TypeScript suite was run here. |
| `supabase/functions/_shared/planner.ts` | 251 | Edge service/shared logic. Writes a draft workout plan. A local stack with no key uses a fixed stand-in. The real planner has not been run against the real service until a key is added. Prompts and answers are never logged or stored. |
| `supabase/functions/_shared/planner_test.ts` | 274 | Tests: a good plan passes, validator refuses what isn, everyday words aren, the stand-in, the request has the agreed shape and holds no extra data (+13 more). Coverage source; only the TypeScript suite was run here. |
| `supabase/functions/_shared/reconcile.ts` | 93 | Edge service/shared logic. Daily comparison of the ledger with Stripe's balance transactions (P4a-08). Pure, so a mismatch can be injected in a test. |
| `supabase/functions/_shared/reconcile_test.ts` | 47 | Tests: matching rows match, an injected one-cent fee change raises a mismatch, an injected amount change raises a mismatch, a row Stripe doesn, a new row Stripe doesn (+3 more). Coverage source; only the TypeScript suite was run here. |
| `supabase/functions/_shared/stack.ts` | 4 | Edge service/shared logic. stack |
| `supabase/functions/_shared/stripe.ts` | 386 | Edge service/shared logic. Every Stripe call goes through this interface. A local stack uses the stand-in, which sends itself signed webhooks, so the whole money path runs without keys. Test mode only: the live adapter refuses anything but a test key. |
| `supabase/functions/_shared/stripe_test.ts` | 146 | Tests: a good signature passes, a changed body fails, the wrong secret fails, an old signature fails, no signature fails (+9 more). Coverage source; only the TypeScript suite was run here. |
| `supabase/functions/_shared/video_host.ts` | 46 | Edge service/shared logic. Where feed videos live. Storage on a local stack, and nothing yet anywhere else: Cloudflare Stream goes here once there are keys. A hosted post can't reach a viewer until then, on purpose. |
| `supabase/functions/admin-action/index.ts` | 84 | Edge service/shared logic. Every staff write comes through here. The database function checks the role and MFA and writes the audit row in the same transaction; this keeps the list of what staff can do in one place, and passes the caller's own token, so nothing here runs with more power than they have. |
| `supabase/functions/ai-plan/index.ts` | 113 | Edge service/shared logic. Writes a draft program for an adult who has agreed. The database checks who may ask and saves the result. Nothing about the prompt or answer is logged. |
| `supabase/functions/analysis-local/index.ts` | 52 | Edge service/shared logic. Plays the worker on a local stack, through the same steps: claim, write the frame, send a result. Tests and the simulator use it. It doesn't exist anywhere else. |
| `supabase/functions/analysis-worker/index.ts` | 76 | Edge service/shared logic. What a worker talks to. It sends the fleet secret to claim a job, and gets a token for that job alone and a short signed URL for the clip. It sends its frame back here, so it can never write to Storage, and it never holds the service-role key. |
| `supabase/functions/create-payment-intent/index.ts` | 69 | Edge service/shared logic. Starts paying for a reservation. The amount comes from the database, never from the app, and the webhook is what confirms it. |
| `supabase/functions/feed-local/index.ts` | 43 | Edge service/shared logic. Plays the worker and its checks on a local stack, through the same steps: claim, check, send a result. Tests and the simulator use it, and can ask for a verdict. It doesn't exist anywhere else. |
| `supabase/functions/feed-media/index.ts` | 74 | Edge service/shared logic. Short links to feed videos. It runs as the person asking, so the database's gate and rules decide. Only then does it sign anything, for one video. |
| `supabase/functions/feed-worker/index.ts` | 59 | Edge service/shared logic. What a worker talks to for the feed. It sends the fleet secret to claim a post, and gets a token for that job alone and a short link to the video. It sends frames back here. The providers are called from here, so the worker holds nothing but its secret. |
| `supabase/functions/money-worker/index.ts` | 141 | Edge service/shared logic. Runs on a timer. The database writes what should happen, and this makes the Stripe calls, because nothing may call Stripe inside a transaction. |
| `supabase/functions/resolve-login/delivery.ts` | 69 | Edge service/shared logic. Sends codes. A local stack sends nothing and gives every mobile and email the same fixed code, so a tester can use any number. A hosted project never uses the local delivery, so the fixed code can never work there. |
| `supabase/functions/resolve-login/index.ts` | 248 | Edge service/shared logic. Sign-in for the app. This function issues and checks every code, and Supabase Auth only creates the session at the end. Auth holds no real mobile or email, so nothing can be learned or bypassed by calling it directly. Unknown and known accounts get the same answer in the same time, and 5 wrong codes lock the target whether or not it is a real account. |
| `supabase/functions/resolve-login/logic.ts` | 57 | Edge service/shared logic. The parts of sign-in that need no network, kept apart so they can be tested. |
| `supabase/functions/resolve-login/logic_test.ts` | 71 | Tests: reads a mobile number and drops spaces, reads an email and lowers its case, reads a username, refuses what can be none of the three, the same person counts once however they type it (+6 more). Coverage source; only the TypeScript suite was run here. |
| `supabase/functions/save-card/index.ts` | 44 | Edge service/shared logic. Starts saving a card for organizer-pays Meets. The card goes straight to Stripe, and setup_intent.succeeded records its last four digits. |
| `supabase/functions/send-push/index.ts` | 33 | Edge service/shared logic. Delivers what is due in push_queue. Run on a schedule with the service key. |
| `supabase/functions/send-push/sender.ts` | 26 | Edge service/shared logic. Sends a push. A local stack sends nothing. The real sender needs a Firebase project and has not been run against the real service. |
| `supabase/functions/send-push/sender_test.ts` | 10 | Tests: a local stack reports success and sends nothing, no devices means nothing was delivered. Coverage source; only the TypeScript suite was run here. |
| `supabase/functions/stripe-local/index.ts` | 79 | Edge service/shared logic. Plays the part of Stripe on a local stack: tests and the simulator use it to finish a payment. It doesn't exist anywhere else. |
| `supabase/functions/stripe-webhook/index.ts` | 31 | Edge service/shared logic. The only thing that confirms a payment. Idempotent on Stripe's event id, so a replay does nothing. A 5xx asks Stripe to send the event again. |
| `supabase/functions/vendor-onboard/index.ts` | 49 | Edge service/shared logic. Starts an organizer's payout account. Stripe runs the identity and business checks on its own pages, and account.updated reports the result (R-PAY-4). |

### Backend — migrations

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `supabase/migrations/20261013120000_phase1_accounts.sql` | 147 | Database migration: phase1 accounts. Tables: public.profiles, public.account_private, public.player_sports, public.account_recovery_requests. Functions: public.touch_updated_at, public.lock_birthday, public.handle_new_user, public.username_available. |
| `supabase/migrations/20261014090000_phase2a_social.sql` | 275 | Database migration: phase2a social. Tables: public.notification_settings, public.follows, public.blocks, public.player_reports, public.saved_items, public.support_requests, public.conversations, public.conversation_members (+1 more). Functions: public.sync_profile_country, public.bump_conversation, public.is_conversation_member, public.is_blocked_between, public.open_direct_conversation, public.profile_social, public.my_blocked_players. |
| `supabase/migrations/20261014120000_phase2b_play.sql` | 262 | Database migration: phase2b play. Tables: public.venues, public.activities, public.activity_participants, public.payments, public.play_preferences. Functions: public.activity_spots_taken, public.join_activity, public.join_waitlist, public.leave_activity, public.check_in. |
| `supabase/migrations/20261014160000_v2_home_inbox.sql` | 167 | Database migration: v2 home inbox. Tables: public.notifications. Functions: public.suggested_players, public.notify, public.notify_follow. |
| `supabase/migrations/20261015090000_venues.sql` | 101 | Database migration: venues. Tables: public.venue_courts, public.court_bookings. Functions: public.court_busy, public.cancel_court_booking. |
| `supabase/migrations/20261015120000_tournament_banner.sql` | 5 | Database migration: tournament banner. Tournaments must carry a banner title. NOT VALID keeps tournaments made before this rule; every new or edited tournament has to follow it. |
| `supabase/migrations/20261015150000_meet_tools.sql` | 409 | Database migration: meet tools. Tables: public.match_scores. Functions: public.leave_activity, public.is_host, public.meet_players, public.host_plays, public.walk_in_candidates, public.add_walk_in, public.save_attendance, public.platform_fee_cents, public.card_fee_cents, public.cancel_preview (+3 more). |
| `supabase/migrations/20261020090000_more_sports.sql` | 7 | Database migration: more sports. The app offers squash and Hyrox as Passport sports too. |
| `supabase/migrations/20261024090000_clubs.sql` | 1652 | Database migration: clubs. Tables: public.clubs, public.club_roles, public.club_members, public.club_member_roles, public.club_join_requests, public.club_bans, public.club_audit, public.club_announcements (+8 more). Functions: public.club_is_member, public.club_my_perms, public.club_can, public.club_require, public.club_require_member, public.club_log, public.club_notify, public.club_level_perms, public.player_json, public.club_json (+53 more). |
| `supabase/migrations/20261025090000_more_tools.sql` | 488 | Database migration: more tools. Tables: public.legal_notices, public.club_ratings, public.content_removals. Functions: public.legal_notice_send, public.team_fixture_create, public.team_fixture_result, public.club_rate, public.club_json, public.chat_photo_allowed, public.passport_history, public.my_reports, public.report_second_look, public.removal_ask_review (+1 more). |
| `supabase/migrations/20261026090000_tournaments.sql` | 1090 | Database migration: tournaments. Tables: public.tournament_entries, public.tournament_matches. Functions: public.tournament_divisions, public.tournament_doubles, public.tournament_division_name, public.tournament_level, public.tournament_players, public.tournament_entry_name, public.tournament_require_host, public.tournament_games_won, public.tournament_my_entries, public.tournament_group_table (+18 more). |
| `supabase/migrations/20261027090000_events.sql` | 233 | Database migration: events. Tables: public.event_tickets, public.event_reminders, public.event_cheers. Functions: public.event_ticket_json, public.event_ticket_get, public.event_ticket_buy, public.event_ticket_release, public.event_scan, public.event_state, public.event_remind, public.event_cheer. |
| `supabase/migrations/20261028090000_gear_leaderboards.sql` | 127 | Database migration: gear leaderboards. Tables: public.player_gear. Functions: public.leaderboard_rating, public.leaderboard_points. |
| `supabase/migrations/20261029090000_shop.sql` | 739 | Database migration: shop. Tables: public.malls, public.mall_follows, public.products, public.cart_lines, public.addresses, public.orders, public.order_lines, public.product_reviews (+1 more). Functions: public.shop_mine, public.shop_require_mine, public.shop_product_json, public.shop_mall_json, public.shop_order_json, public.shop_can_see_order, public.shop_malls, public.shop_products, public.shop_product, public.shop_mall (+21 more). |
| `supabase/migrations/20261030090000_academy.sql` | 946 | Database migration: academy. Tables: public.academies, public.academy_coaches, public.academy_coach_invites, public.academy_classes, public.academy_students, public.academy_requests, public.academy_attendance, public.academy_skills (+4 more). Functions: public.academy_is_coach, public.academy_require_coach, public.academy_require_head, public.academy_user_name, public.academy_default_plan, public.academy_skill_template, public.academy_class_week, public.academy_class_json, public.academy_json, public.academy_can_see_student (+29 more). |
| `supabase/migrations/20261031090000_uat_fixes.sql` | 38 | Database migration: uat fixes. Functions: public.shop_order_json, public.shop_mall_json. |
| `supabase/migrations/20261101090000_platform_config.sql` | 173 | Database migration: platform config. Tables: public.app_settings, public.country_config, public.fee_rules, public.feature_flags. Functions: private.setting_int, private.flag, private.fee_minor, public.platform_fee_cents, private.activity_tz. |
| `supabase/migrations/20261101100000_identity_age.sql` | 490 | Database migration: identity age. Tables: public.guardian_links, public.guardian_link_codes, public.guardian_code_attempts. Functions: private.age_years, private.audience_of, private.is_minor, private.is_guardian_of, private.is_restricted, private.masked_name, private.can_view_profile, public.set_birthday, public.set_country, public.my_restrictions (+11 more). |
| `supabase/migrations/20261101110000_sports_catalog.sql` | 203 | Database migration: sports catalog. Tables: public.sports, public.sport_formats, public.catalog_audit. Functions: private.forbid_change, private.audit_catalog, private.activity_before_insert, private.activity_lock_columns. |
| `supabase/migrations/20261101120000_play_core.sql` | 653 | Database migration: play core. Tables: public.player_qr_tokens, public.campaign_game_log, public.attendance_audit. Functions: private.open_capacity, private.refresh_game_on, private.promote_waitlist, public.join_activity, public.join_waitlist, public.leave_activity, public.host_plays, private.activity_seats_changed, public.activity_waitlist_count, public.activity_my_position (+11 more). |
| `supabase/migrations/20261101130000_safety_gate.sql` | 613 | Database migration: safety gate. Tables: private.rate_rules, private.rate_buckets, private.restricted_allow, public.login_attempts. Functions: private.rate_hit, private.request_ip, private.gate_request, public.player_json, private.profile_guard, public.suggested_players, public.leaderboard_rating, public.leaderboard_points, public.club_leaderboard, public.club_invite_candidates (+9 more). |
| `supabase/migrations/20261101140000_review_fixes.sql` | 490 | Database migration: review fixes. Functions: private.has_verified_mobile, private.is_restricted, private.code_attempt_blocked, public.guardian_code_redeem, public.guardian_link_decide, public.login_gate_attempt, public.login_gate_clear, private.request_ip, public.meet_players, public.add_walk_in (+9 more). |
| `supabase/migrations/20261102090000_own_login_codes.sql` | 168 | Database migration: own login codes. Tables: public.login_codes. Functions: private.internal_email, private.has_verified_mobile, public.login_code_issue, public.login_code_check, public.login_lookup, public.login_contact_set. |
| `supabase/migrations/20261102100000_staff.sql` | 136 | Database migration: staff. Tables: public.staff, public.admin_audit. Functions: private.has_mfa, private.is_staff, private.staff_require, private.staff_audit, public.staff_whoami, public.staff_audit_list, private.gate_request. |
| `supabase/migrations/20261102110000_moderation.sql` | 495 | Database migration: moderation. Tables: public.moderation_cases, public.case_reports, public.account_moderation, public.ban_requests, public.moderation_words. Functions: private.is_suspended, private.is_restricted, private.profile_hidden, private.can_view_profile, public.club_visible, private.case_set_hidden, private.case_owner, private.report_to_case, private.text_problem, private.check_text (+9 more). |
| `supabase/migrations/20261102120000_existing_fixes.sql` | 193 | Database migration: existing fixes. Tables: public.guardian_group_approvals. Functions: private.conversation_blocked, private.group_allowed, private.club_member_guard, public.club_visible, public.guardian_group_requests, public.guardian_group_decide, private.on_activity. |
| `supabase/migrations/20261102130000_discover.sql` | 222 | Database migration: discover. Tables: public.consents, public.private_locations. Functions: public.consent_set, public.location_set, private.geohash_center, private.km_between, private.my_center, public.discover_sessions, public.discover_players, public.discover_groups. |
| `supabase/migrations/20261102140000_rank_chat_push.sql` | 197 | Database migration: rank chat push. Tables: public.message_archive, public.device_tokens, public.push_queue. Functions: private.game_counts, public.group_activity_rank, public.message_delete, public.device_token_save, private.quiet_until, private.queue_push, public.push_due, public.push_mark. |
| `supabase/migrations/20261102150000_admin_catalog_users.sql` | 182 | Database migration: admin catalog users. Tables: public.game_types, public.level_scales. Functions: public.staff_catalog, public.staff_sport_save, public.staff_format_save, public.staff_user_search, public.staff_user_get, public.staff_recovery_list, public.staff_recovery_decide. |
| `supabase/migrations/20261102160000_review_fixes_2.sql` | 377 | Database migration: review fixes 2. Tables: public.guardian_team_approvals, private.suspended_allow. Functions: private.random_auth_email, public.login_lookup, public.login_account_bind, private.team_allowed, private.team_member_guard, public.guardian_group_requests, public.guardian_team_decide, private.activity_lock_columns, private.profile_guard, private.message_guard (+4 more). |
| `supabase/migrations/20261103090000_matches_ratings.sql` | 903 | Database migration: matches ratings. Tables: public.scoring_presets, public.matches, public.match_results, public.ratings, public.rating_events, public.activity_presets. Functions: private.level_of, private.player_sport_guard, private.rating_row, private.rating_write, private.rating_apply, private.rating_reverse, private.game_winner, private.match_winner, private.games_finished, private.activity_rules (+18 more). |
| `supabase/migrations/20261103100000_leaderboards.sql` | 190 | Database migration: leaderboards. Tables: public.leaderboard_consents, public.leaderboard_rows. Functions: private.listable, private.leaderboards_build, public.leaderboards_refresh, public.leaderboard_rating, public.leaderboard_points, public.guardian_leaderboard_set. |
| `supabase/migrations/20261103110000_review_fixes_3.sql` | 568 | Database migration: review fixes 3. Functions: private.match_winner, private.score_check, private.score_confirmed, private.result_rated, private.rating_apply, private.rating_reverse, private.level_of, private.player_sport_guard, private.attendance_rate, private.roster_real (+11 more). |
| `supabase/migrations/20261103120000_review_fixes_4.sql` | 261 | Database migration: review fixes 4. Functions: private.activity_has_scores, private.activity_lock_columns, private.activity_start_guard, private.attendance_rate, private.score_person, public.score_view, public.my_meet_results, public.meet_disputes, public.staff_scores. |
| `supabase/migrations/20261103130000_review_fixes_5.sql` | 70 | Database migration: review fixes 5. Functions: private.activity_lock_columns, public.player_json. |
| `supabase/migrations/20261104090000_money_ledger.sql` | 457 | Database migration: money ledger. Tables: private.payment_transitions, public.refunds, private.refund_transitions, public.ledger_accounts, public.ledger_transactions, public.ledger_entries, public.stripe_events, public.money_alerts (+7 more). Functions: private.payment_guard, private.refund_guard, private.ledger_balanced, private.ledger_account, private.ledger_line, private.ledger_post, private.ledger_balance, private.money_alert. |
| `supabase/migrations/20261104100000_money_quotes.sql` | 116 | Database migration: money quotes. Functions: private.fee_per_unit, public.money_quote, public.money_refund_quote, private.refund_in_time, private.refund_rule_text. |
| `supabase/migrations/20261104110000_money_flows.sql` | 1613 | Database migration: money flows. Functions: public.activity_spots_taken, private.spots_joined, private.activity_charges, private.organizer_pays, private.activity_has_money, private.has_saved_card, private.activity_publish_guard, private.activity_delete_guard, private.payment_json, private.expire_holds (+37 more). |
| `supabase/migrations/20261104120000_money_payouts_scan.sql` | 746 | Database migration: money payouts scan. Tables: public.place_qr_tokens. Functions: private.organizer_net, private.payouts_prepare, public.staff_payout_approve, public.vendor_start, public.vendor_set_schedule, public.money_my_earnings, public.money_svc_vendor_attach, public.money_svc_work, public.money_svc_result, public.money_svc_ledger_rows (+21 more). |
| `supabase/migrations/20261104130000_money_review_fixes.sql` | 1059 | Database migration: money review fixes. Tables: private.worker_lease. Functions: public.money_svc_lease, private.expire_holds, public.payment_abandon, private.refund_issue, private.change_window_open, private.leave_money, private.ticket_release, public.event_ticket_release, public.leave_activity, public.host_plays (+13 more). |
| `supabase/migrations/20261104140000_money_review_fixes_2.sql` | 342 | Database migration: money review fixes 2. Functions: private.refund_issue, private.refund_settled, public.staff_refund_settle, public.money_svc_lease. |
| `supabase/migrations/20261105090000_shop_partner.sql` | 406 | Database migration: shop partner. Tables: private.order_transitions. Functions: private.order_guard, private.shop_unit, private.product_on_sale, public.shop_mall_json, public.shop_malls, public.shop_mall, public.shop_product_json, public.shop_products, public.shop_product, public.shop_cart (+5 more). |
| `supabase/migrations/20261105100000_points.sql` | 357 | Database migration: points. Tables: public.points_entries, public.points_blocks. Functions: private.setting_int_or_null, private.points_lots, private.points_balance, private.points_spend, private.points_return, private.points_can_redeem, private.points_sync, private.points_touch, private.points_dispute, private.points_attendance (+4 more). |
| `supabase/migrations/20261105110000_shop_money.sql` | 1354 | Database migration: shop money. Tables: private.order_decisions. Functions: private.refund_rule_text, private.refund_issue, public.staff_refund_void, private.order_unreserve, private.order_refund_shop_part, private.order_due, private.release_order, private.shop_price, private.shop_lines_for, public.shop_quote (+29 more). |
| `supabase/migrations/20261106090000_academy_verification.sql` | 1102 | Database migration: academy verification. Tables: public.coach_licences, public.coach_profiles, public.academy_makeup_credits, public.academy_cancellations. Functions: public.academy_is_coach, private.licence_ok, private.licence_current, public.academy_require_coach, public.academy_require_head, public.academy_coach_answer, public.academy_my_coach_invites, public.coach_profile_save, public.coach_profile_get, public.coach_licence_my (+39 more). |
| `supabase/migrations/20261106100000_lessons.sql` | 1144 | Database migration: lessons. Tables: public.lesson_slots, public.lesson_bookings, private.lesson_transitions. Functions: private.lesson_guard, private.refund_rule_text, private.class_taken, public.academy_class_json, private.lesson_offer, public.lesson_quote, public.lesson_reserve, private.lesson_captured, private.lesson_lock, private.lesson_paid_back (+19 more). |
| `supabase/migrations/20261106110000_assessments.sql` | 269 | Database migration: assessments. Tables: public.assessment_templates, public.assessment_criteria, public.assessments, public.assessment_scores. Functions: private.assessment_can_read, public.assessment_template_list, public.assessment_template_save, public.assessment_template_archive, public.assessment_save, public.assessment_list. |
| `supabase/migrations/20261106120000_services.sql` | 111 | Database migration: services. Tables: public.service_partners, public.service_referrals. Functions: public.service_partner_list, public.service_referral_make, public.staff_service_list, public.staff_service_save. |
| `supabase/migrations/20261106130000_academy_review_fixes.sql` | 663 | Database migration: academy review fixes. Functions: public.academy_create, public.academy_claim_invites, public.academy_verification, private.academy_recipients, public.staff_doc_viewed, private.lesson_academy_off, private.lesson_coach_gone, private.lesson_cancel_full, public.lesson_academy_cancel, public.lesson_cancel (+4 more). |
| `supabase/migrations/20261106140000_academy_review_fixes_2.sql` | 240 | Database migration: academy review fixes 2. Functions: private.lesson_cancel_full, public.staff_lesson_decide, public.academy_claim_invites, private.doc_in_use. |
| `supabase/migrations/20261106150000_academy_review_fixes_3.sql` | 60 | Database migration: academy review fixes 3. P4c last review. Tests in 45_academy_review_test.sql. |
| `supabase/migrations/20261107090000_game_engine.sql` | 744 | Database migration: game engine. Tables: public.voucher_types, public.vouchers, public.voucher_redemptions, public.badges, public.campaigns, public.quests, public.challenges, public.challenge_progress (+3 more). Functions: private.voucher_issue, private.badge_grant, private.quest_count, private.quest_sync, private.quest_attendance, private.milestone_reward, private.game_counted, private.organizer_game_check, private.organizer_sweep, public.group_activity_rank (+15 more). |
| `supabase/migrations/20261107100000_voucher_checkout.sql` | 207 | Database migration: voucher checkout. Functions: private.voucher_usable, private.shop_price, public.shop_quote, private.voucher_return. |
| `supabase/migrations/20261107110000_game_review_fixes.sql` | 449 | Database migration: game review fixes. Functions: private.quest_count, private.quest_sync, private.organizer_sweep, public.group_activity_rank, public.campaign_join, public.voucher_my, public.organizer_rewards_my, private.voucher_usable, private.staff_require_game, public.staff_voucher_type_save. |
| `supabase/migrations/20261107120000_game_review_fixes_2.sql` | 152 | Database migration: game review fixes 2. Tables: private.quest_sessions_done. Functions: private.quest_count, private.organizer_sweep. |
| `supabase/migrations/20261107130000_game_review_fixes_3.sql` | 72 | Database migration: game review fixes 3. Functions: public.staff_voucher_type_save. |
| `supabase/migrations/20261108090000_fitness.sql` | 479 | Database migration: fitness. Tables: public.exercises, public.programs, public.program_days, public.program_items, public.workouts, public.workout_sets. Functions: private.fitness_gate, private.fitness_tz, private.exercise_json, private.program_json, public.exercise_list, public.program_list, public.program_save, public.program_delete, public.workout_save, public.workout_delete (+2 more). |
| `supabase/migrations/20261108100000_fitness_catalogue.sql` | 189 | Database migration: fitness catalogue. P5-04: the starter exercises and three templates. A coach reviews these before launch (Q168, Q169). Only bodyweight and band work is cleared for under-18s. |
| `supabase/migrations/20261109090000_ai_plans.sql` | 381 | Database migration: ai plans. Tables: public.ai_plan_requests. Functions: private.program_write, public.program_save, private.ai_consent, public.ai_plan_status, public.ai_plan_withdraw, private.ai_plan_summary, public.ai_plan_begin, private.ai_plan_clean, private.ai_plan_allowed, public.ai_plan_svc_allowed (+2 more). |
| `supabase/migrations/20261110090000_video_analysis.sql` | 811 | Database migration: video analysis. Tables: public.video_clips, public.video_consents, public.analysis_jobs, public.analysis_reports, public.analysis_usage, public.storage_deletions. Functions: private.clip_video_path, private.clip_frame_path, private.clip_frame_ok, private.clip_queue_files, private.clip_may_run, private.clip_upload_ok, private.clip_mine, private.clip_seconds_today, private.clip_json, private.clip_corners_ok (+20 more). |
| `supabase/migrations/20261110100000_clip_adder.sql` | 17 | Database migration: clip adder. Functions: private.clip_json. |
| `supabase/migrations/20261111090000_deletion_buckets.sql` | 79 | Database migration: deletion buckets. Functions: public.analysis_svc_sweep, public.analysis_svc_orphans. |
| `supabase/migrations/20261111100000_video_feed.sql` | 827 | Database migration: video feed. Tables: public.video_posts, public.post_likes, public.post_jobs, public.abuse_matches, private.post_transitions. Functions: private.post_guard, private.abuse_keep, private.post_poster_ref, private.post_queue_files, private.post_visible, private.post_json, private.feed_gate, public.feed_status, public.feed_following, public.feed_discover (+21 more). |
| `supabase/migrations/20261111110000_feed_review_fixes.sql` | 151 | Database migration: feed review fixes. Functions: private.post_file_ok, private.post_exists, private.case_text. |
| `supabase/migrations/20261111120000_feed_review_fixes_2.sql` | 72 | Database migration: feed review fixes 2. P5-06: fixes from the second independent review of the feed. Staff can add sports, so the catalogue decides, not a list here. |
| `supabase/migrations/20261111130000_case_with_no_reports.sql` | 14 | Database migration: case with no reports. P5-06: a hash match opens a case nobody reported, which left its reasons null and took down the staff list. |
| `supabase/migrations/20261112090000_account_deletion.sql` | 554 | Database migration: account deletion. Tables: public.account_deletions, private.closing_allow. Functions: private.is_closing, private.is_erased, private.is_minor, private.masked_name, private.profile_guard, public.lock_birthday, private.account_leave, public.account_delete_request, public.account_delete_cancel, private.gate_request (+3 more). |
| `supabase/migrations/20261113090000_three_minute_codes.sql` | 5 | Database migration: three minute codes. Q248 (owner, 8 Nov 2026): sign-in and contact codes last 3 minutes, and the app offers a new one after 3 minutes (R-ACC-2, R-ACC-3). |

### Backend — database tests and race harnesses

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `supabase/tests/00_meta_test.sql` | 60 | pgTAP checks for meta. Example assertions: the API runs the gate before every request. |
| `supabase/tests/01_config_test.sql` | 23 | pgTAP checks for config. Example assertions: R-FEE-1 S$6.00 pays the S$2.00 minimum, R-FEE-1 S$15.00 pays the S$2.00 minimum, R-FEE-1 S$30.00 pays S$3.00 (+6 more). |
| `supabase/tests/02_age_test.sql` | 57 | pgTAP checks for age. Example assertions: P1-03 age 12 is a child, P1-03 age 13 is a teen, P1-03 age 17 is a teen (+16 more). |
| `supabase/tests/03_guardian_test.sql` | 126 | pgTAP checks for guardian. Example assertions: P1-08 the code lasts 24 hours, the plain code is not stored, P1-08 a parent under 18 is refused (+18 more). |
| `supabase/tests/04_catalog_test.sql` | 42 | pgTAP checks for catalog. Example assertions: badminton is live, pickleball is live, tennis is a draft (+8 more). |
| `supabase/tests/05_play_test.sql` | 113 | pgTAP checks for play. Example assertions: P1-09 a player joins, joining twice changes nothing, not on below the minimum (+21 more). |
| `supabase/tests/06_qr_test.sql` | 83 | pgTAP checks for qr. Example assertions: the QR holds an opaque token, the token stays the same until rotated, players cannot read the token table (+10 more). |
| `supabase/tests/07_attendance_test.sql` | 62 | pgTAP checks for attendance. Example assertions: R-ATT-1 attendance waits for the window, only the host saves attendance, P1-11 the host saves attendance (+9 more). |
| `supabase/tests/08_gate_test.sql` | 79 | pgTAP checks for gate. Example assertions: a restricted child is refused the Shop, a restricted child is refused discovery, a restricted child is refused chat (+10 more). |
| `supabase/tests/09_minors_test.sql` | 106 | pgTAP checks for minors. Example assertions: a minor cannot be followed, a host cannot pull a minor onto their Meet, tournament lists show a minor by first name and initial (+7 more). |
| `supabase/tests/10_attack_test.sql` | 124 | pgTAP checks for attack. Example assertions: signed out: nothing but reference data can be read, signed out: nothing can be deleted, restricted child: only their own and open rows can be read (+1 more). |
| `supabase/tests/11_login_test.sql` | 37 | pgTAP checks for login. Example assertions: R-ACC-2 a new code cancels the old one, the newest code works, R-ACC-2 a code works once (+6 more). |
| `supabase/tests/12_staff_test.sql` | 40 | pgTAP checks for staff. Example assertions: A-01 staff without MFA are not staff, A-01 staff without MFA get no data, the app can see MFA is missing (+9 more). |
| `supabase/tests/13_moderation_test.sql` | 104 | pgTAP checks for moderation. Example assertions: two people do not hide an item, the same person counts once, P2-07 three distinct reporters hide the item (+20 more). |
| `supabase/tests/14_fixes_test.sql` | 89 | pgTAP checks for fixes. Example assertions: R-PRV-4 a blocked player cannot keep sending, P2-03 a child cannot see an unapproved group, asking goes to the parent (+10 more). |
| `supabase/tests/15_discover_test.sql` | 54 | pgTAP checks for discover. Example assertions: with no area shared, no distance is shown, no location without consent, P2-01 only a coarse geohash is kept (+11 more). |
| `supabase/tests/16_rank_chat_push_test.sql` | 69 | pgTAP checks for rank chat push. Example assertions: P2-04 a group with a counted game is ranked, with its count, P2-04 no player appears in a ranking (+7 more). |
| `supabase/tests/17_admin_catalog_test.sql` | 49 | pgTAP checks for admin catalog. Example assertions: A-02 a sport needs a live format first, a Meet can use it, so can a Passport (+8 more). |
| `supabase/tests/18_review_fixes_test.sql` | 95 | pgTAP checks for review fixes. Example assertions: R-TEM-1 a child is not added to a team without a parent, the request waits for the parent, a child cannot chat in an unapproved team (+10 more). |
| `supabase/tests/19_scores_ratings_test.sql` | 258 | pgTAP checks for scores ratings. Example assertions: P3-03 30-29 is valid, P3-03 22-20 is valid in a game to 21, P3-03 22-21 is invalid (+58 more). |
| `supabase/tests/20_leaderboards_test.sql` | 55 | pgTAP checks for leaderboards. Example assertions: P3-07 an adult is listed from the snapshot, snapshots have no client read, P3-07 a stranger cannot opt a child in (+3 more). |
| `supabase/tests/21_tournament_sizes_test.sql` | 76 | pgTAP checks for tournament sizes. |
| `supabase/tests/22_review_fixes_3_test.sql` | 237 | pgTAP checks for review fixes 3. Example assertions: t be decided early, t decide their own match, s own tournament match is not rated (+31 more). |
| `supabase/tests/23_review_fixes_4_test.sql` | 171 | pgTAP checks for review fixes 4. Example assertions: the host lost, marking themself absent changes nothing, nor marking the winner absent (+17 more). |
| `supabase/tests/24_review_fixes_5_test.sql` | 51 | pgTAP checks for review fixes 5. Example assertions: t be copied on, t be cancelled, the sport stays once scores are in (+2 more). |
| `supabase/tests/25_ledger_test.sql` | 119 | pgTAP checks for ledger. Example assertions: a balanced transaction posts, a repeated key posts nothing, a repeated key leaves one transaction (+23 more). |
| `supabase/tests/26_quotes_test.sql` | 77 | pgTAP checks for quotes. Example assertions: Paid Meet: S$6.00 gives S$2.00 and S$8.00, Tournament singles: S$15.00 gives S$17.00, Mixed doubles pair: S$30.00 gives S$3.00 and S$33.00 (+36 more). |
| `supabase/tests/27_paid_join_test.sql` | 274 | pgTAP checks for paid join. Example assertions: join alone refuses a paid Meet, reserve holds a spot, S$6.00 charges S$8.00 (+63 more). |
| `supabase/tests/28_refunds_test.sql` | 219 | pgTAP checks for refunds. Example assertions: leaving in time returns S$6.00, the spot is gone, the amount is on the place (+45 more). |
| `supabase/tests/29_release_test.sql` | 153 | pgTAP checks for release. Example assertions: two prices held, saving attendance releases the money, prices are released too (+22 more). |
| `supabase/tests/30_organizer_pays_test.sql` | 162 | pgTAP checks for organizer pays. Example assertions: no saved card, no organizer-pays Meet, Stripe confirms the saved card, the organizer sees the last four digits (+26 more). |
| `supabase/tests/31_payouts_test.sql` | 162 | pgTAP checks for payouts. Example assertions: a run is prepared, one run a week, s earnings are in it (+25 more). |
| `supabase/tests/32_scan_test.sql` | 112 | pgTAP checks for scan. Example assertions: s code opens the player, s code opens the group, without rotating, the code stays the same (+4 more). |
| `supabase/tests/33_money_staff_test.sql` | 128 | pgTAP checks for money staff. Example assertions: a player reads none of it, a minor reads none of it, a moderator reads none of it (+12 more). |
| `supabase/tests/34_money_review_test.sql` | 293 | pgTAP checks for money review. Example assertions: leaving an event refunds the price, and the ticket stops working, refunded once (+40 more). |
| `supabase/tests/35_money_review_2_test.sql` | 172 | pgTAP checks for money review 2. Example assertions: attempt 2 settles, a late failure of attempt 1 changes nothing, and the ledger is square (+13 more). |
| `supabase/tests/36_shop_catalogue_test.sql` | 117 | pgTAP checks for shop catalogue. Example assertions: on-top shows the buyer the S$110.00 they pay, nothing is advertised until points can be spent, points can take half the S$10.00 commission (+9 more). |
| `supabase/tests/37_points_test.sql` | 124 | pgTAP checks for points. Example assertions: the balance is a sum of lots, spending lowers it, taking the oldest lot first, then the next (+26 more). |
| `supabase/tests/38_shop_checkout_test.sql` | 186 | pgTAP checks for shop checkout. Example assertions: S$100.00 by default, the shop gets S$90.00, OlympusGO gets S$10.00 (+33 more). |
| `supabase/tests/39_shop_handover_test.sql` | 212 | pgTAP checks for shop handover. Example assertions: the owner marks it ready, and the buyer is told, yes, I got it all (+34 more). |
| `supabase/tests/40_shop_review_test.sql` | 464 | pgTAP checks for shop review. Example assertions: one of two refunded, the rest waits for the buyer, t paid early (+54 more). |
| `supabase/tests/41_academy_verification_test.sql` | 364 | pgTAP checks for academy verification. Example assertions: nobody grants themself a licence, t list academies, or read a coach (+79 more). |
| `supabase/tests/42_lessons_test.sql` | 492 | pgTAP checks for lessons. Example assertions: and writes none, signed out reaches nothing, not even open slots (+103 more). |
| `supabase/tests/43_assessments_test.sql` | 206 | pgTAP checks for assessments. Example assertions: only the head coach makes templates, a template needs lines, each its own (+38 more). |
| `supabase/tests/44_services_test.sql` | 82 | pgTAP checks for services. Example assertions: only live partners are listed, without their reference code, the link carries the partner code (+15 more). |
| `supabase/tests/45_academy_review_test.sql` | 372 | pgTAP checks for academy review. Example assertions: a refused coach can send a new licence, but sees no children until staff verify it, or any one child (+56 more). |
| `supabase/tests/46_game_test.sql` | 291 | pgTAP checks for game. Example assertions: game 0 earns nothing, t pay stops it, one not scanned stops it (+34 more). |
| `supabase/tests/47_vouchers_test.sql` | 261 | pgTAP checks for vouchers. Example assertions: S$100.00 less S$8.00 is S$92.00, commission is 10% of the price after the voucher, and the shop funds it, at S$82.80 (+35 more). |
| `supabase/tests/48_game_review_test.sql` | 385 | pgTAP checks for game review. Example assertions: nor is a spot you gave up, s own check-in, a scan alone finishes nothing (+30 more). |
| `supabase/tests/49_fitness_test.sql` | 424 | pgTAP checks for fitness. Example assertions: the starter list has about 40 exercises, three templates exist, signed out: no exercises (+87 more). |
| `supabase/tests/50_ai_plans_test.sql` | 403 | pgTAP checks for ai plans. Example assertions: t finish a plan, or ask if it may go on, or read requests (+82 more). |
| `supabase/tests/51_video_test.sql` | 681 | pgTAP checks for video. Example assertions: signed out: no clips, t delete one, no table access (+123 more). |
| `supabase/tests/52_deletion_queue_test.sql` | 34 | pgTAP checks for deletion queue. Example assertions: the queue only names buckets the sweep knows, one bucket gets its share of a run, and a backlog there leaves room for the other (+2 more). |
| `supabase/tests/53_feed_test.sql` | 709 | pgTAP checks for feed. Example assertions: t read posts directly, or like directly, or claim a job (+135 more). |
| `supabase/tests/54_account_deletion_test.sql` | 361 | pgTAP checks for account deletion. Example assertions: set-up: the host is owed S$6.00, set-up: the other host owes S$0.77 in fees, a fee debt is not earnings: the request goes through (+92 more). |
| `supabase/tests/helpers/academy.psql` | 65 | Database-test fixtures and helper setup for academy. |
| `supabase/tests/helpers/money.psql` | 181 | Database-test fixtures and helper setup for money. |
| `supabase/tests/helpers/setup.psql` | 100 | Database-test fixtures and helper setup for setup. |
| `supabase/tests/races/ai_plan_races.sh` | 62 | Concurrent-operation regression harness: ai plan races. Not executed during this inventory. |
| `supabase/tests/races/analysis_races.sh` | 91 | Concurrent-operation regression harness: analysis races. Not executed during this inventory. |
| `supabase/tests/races/db.sh` | 8 | Concurrent-operation regression harness: db. Not executed during this inventory. |
| `supabase/tests/races/deletion_races.sh` | 97 | Concurrent-operation regression harness: deletion races. Not executed during this inventory. |
| `supabase/tests/races/feed_races.sh` | 178 | Concurrent-operation regression harness: feed races. Not executed during this inventory. |
| `supabase/tests/races/game_races.sh` | 151 | Concurrent-operation regression harness: game races. Not executed during this inventory. |
| `supabase/tests/races/lesson_races.sh` | 226 | Concurrent-operation regression harness: lesson races. Not executed during this inventory. |
| `supabase/tests/races/refund_vs_release.sh` | 76 | Concurrent-operation regression harness: refund vs release. Not executed during this inventory. |
| `supabase/tests/races/shop_races.sh` | 124 | Concurrent-operation regression harness: shop races. Not executed during this inventory. |

### Mobile tests and visual references

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `test/academy_lessons_test.dart` | 419 | Tests: before the wait is over, cancelling gives the price back, inside 24 hours it says nothing comes back, after the start the payer can report a problem, the coach marks attendance, once it has started, a child reading their lesson has nothing to press (+17 more). Coverage source; only the TypeScript suite was run here. |
| `test/account_deletion_test.dart` | 281 | Tests: says what happens before anything is confirmed, closes the account after Face ID and says how to undo, does nothing when Face ID fails or the sheet is cancelled, shows the database\, can\ (+3 more). Coverage source; only the TypeScript suite was run here. |
| `test/account_info_test.dart` | 637 | Tests: email keeps the first and last character before the @, phone shows the dialling code and the last 4 digits, a screen reader hears the ending, not the dots, the model reads the private details, its text form carries no contact details or birthday (+25 more). Coverage source; only the TypeScript suite was run here. |
| `test/activity_test.dart` | 73 | Tests: platform fee is 10%, minimum S\$2, and money formats like the design, card lines match the design wording, dates read like the design. Coverage source; only the TypeScript suite was run here. |
| `test/analysis_screens_test.dart` | 940 | Tests: a court seen from behind is fine, swapped or crossed corners are not, every code the server sends has its own words, doubles says singles only, a report and its grid (+48 more). Coverage source; only the TypeScript suite was run here. |
| `test/audit_fixes_test.dart` | 43 | Tests: opens only with the address the change started with, a failed load still lets the app start, a slow load stops waiting at the limit, a quick load is waited for. Coverage source; only the TypeScript suite was run here. |
| `test/back_gesture_test.dart` | 49 | Tests: edge swipe pops a screen pushed over the tab shell. Coverage source; only the TypeScript suite was run here. |
| `test/band_range_picker_test.dart` | 45 | Tests: dragging moves the nearer end. Coverage source; only the TypeScript suite was run here. |
| `test/biometric_vault_test.dart` | 113 | Tests: Q249 Face ID is off on a new phone, so nothing is saved, Q249 one player switching it on does not switch it on for another, Q249 tiles from a build where Face ID was on by default go, with, P1-05 a saved account comes back with its tile details, P1-05 several accounts sit on one phone, newest first (+2 more). Coverage source; only the TypeScript suite was run here. |
| `test/create_menu_test.dart` | 75 | Tests: no hosting club asks to start a group, only the kinds the role allows are offered. Coverage source; only the TypeScript suite was run here. |
| `test/design_golden_test.dart` | 62 | Tests: P0-06 shared parts in $name. Coverage source; only the TypeScript suite was run here. |
| `test/design_tokens_test.dart` | 72 | Tests: P0-06 the brand colours are the ones in the checklist, P0-06 there is no lime in the light theme, small text on the small-text fill passes 4.5:1, white on the main orange is for large text only, text and links pass 4.5:1 in both themes (+1 more). Coverage source; only the TypeScript suite was run here. |
| `test/edit_profile_test.dart` | 402 | Tests: rows read the details, header, values on the right, Level read-only, long values end in an ellipsis, an empty bio shows Add in the link colour, the copy icon copies the link and says so (+9 more). Coverage source; only the TypeScript suite was run here. |
| `test/failures/account_info_phone_dark_isolatedDiff.png` | 10674 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_phone_dark_maskedDiff.png` | 12314 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_phone_dark_masterImage.png` | 10803 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_phone_dark_testImage.png` | 12101 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_phone_light_isolatedDiff.png` | 14877 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_phone_light_maskedDiff.png` | 16564 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_phone_light_masterImage.png` | 10794 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_phone_light_testImage.png` | 12114 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_tablet_dark_isolatedDiff.png` | 14584 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_tablet_dark_maskedDiff.png` | 17039 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_tablet_dark_masterImage.png` | 14281 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_tablet_dark_testImage.png` | 15479 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_tablet_light_isolatedDiff.png` | 19214 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_tablet_light_maskedDiff.png` | 21451 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_tablet_light_masterImage.png` | 14316 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/failures/account_info_tablet_light_testImage.png` | 15482 bytes | Existing golden-test comparison artifact; not evidence of the outcome of this review. |
| `test/feed_screens_test.dart` | 687 | Tests: an adult gets both tabs, a teen gets Following alone, and never asks for Discover, Discover shows its own list, a list ends, an empty Following says what to do (+32 more). Coverage source; only the TypeScript suite was run here. |
| `test/fitness_calc_test.dart` | 199 | Tests: weights are whole grams and read back exactly, totals read as the screens show them, one-rep max matches the board, one-rep max refuses what it can\, plates match the board (+7 more). Coverage source; only the TypeScript suite was run here. |
| `test/fitness_screens_test.dart` | 838 | Tests: with the flag off the page stays as it was, home offers a workout and the four rows, home shows a failure and can retry, with no programs home still works, the catalogue filters and searches (+35 more). Coverage source; only the TypeScript suite was run here. |
| `test/game_rewards_test.dart` | 179 | Tests: a usable voucher shows its code and date, Voucher B waits for court booking, with no code, empty, a failure offers a retry, says what the next game earns (+6 more). Coverage source; only the TypeScript suite was run here. |
| `test/geohash_test.dart` | 16 | Tests: P2-01 a known point gives the known geohash, P2-01 the default is coarse, about 5 km, nearby points share a cell. Coverage source; only the TypeScript suite was run here. |
| `test/goldens/account_info_phone_dark.png` | 12101 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/account_info_phone_light.png` | 12114 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/account_info_tablet_dark.png` | 15479 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/account_info_tablet_light.png` | 15482 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/edit_profile_phone_dark.png` | 13793 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/edit_profile_phone_light.png` | 14157 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/edit_profile_tablet_dark.png` | 17624 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/edit_profile_tablet_light.png` | 17977 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/settings_phone_dark.png` | 15523 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/settings_phone_light.png` | 15497 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/settings_tablet_dark.png` | 27823 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/settings_tablet_light.png` | 27858 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/shared_parts_dark.png` | 9281 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/goldens/shared_parts_light.png` | 9324 bytes | Reference image for visual regression tests; not a feature implementation. Image contents not re-reviewed here. |
| `test/meet_repeat_test.dart` | 42 | Tests: once is one date, weekly on Tue and Fri starts from the first date, every 2 weeks skips a week. Coverage source; only the TypeScript suite was run here. |
| `test/meet_rounds_test.dart` | 32 | Tests: P3-02 eight players on two courts: nobody plays twice in a round, P3-02 a late arrival joins the rounds that remain. Coverage source; only the TypeScript suite was run here. |
| `test/onboarding_test.dart` | 47 | Tests: toggleSport keeps the design order and can remove a sport, skill scale runs 1.0 to 8.0 in whole levels, each with a name, email, username, mobile. Coverage source; only the TypeScript suite was run here. |
| `test/pay_flow_test.dart` | 165 | Tests: counts down on the server\, says so when the hold runs out, a failed try keeps the spot, a refunded payment explains itself, an ended payment says nothing was charged (+3 more). Coverage source; only the TypeScript suite was run here. |
| `test/route_audit_routes.dart` | 259 | Dart test support or application wiring. |
| `test/route_audit_test.dart` | 165 | Tests: every screen opens without errors. Coverage source; only the TypeScript suite was run here. |
| `test/score_rules_test.dart` | 71 | Tests: finished games, scores that cannot end a game, a match is decided by 2 games, with game 3 only after a split, pickleball games end at 11 with 2 clear, junior badminton is 15 points, capped at 21 (+2 more). Coverage source; only the TypeScript suite was run here. |
| `test/settings_screens_test.dart` | 486 | Tests: subtitle and value render; it reads label, subtitle, value, a read-only row has no chevron and is not a button, the dot shows only when asked, and is announced as New, a long value ends in an ellipsis at 60 % and the label stays, an empty value shows its empty text in the link colour (+13 more). Coverage source; only the TypeScript suite was run here. |
| `test/share_links_test.dart` | 25 | Tests: share links open the matching screen, other paths are left alone. Coverage source; only the TypeScript suite was run here. |
| `test/shop_flow_test.dart` | 360 | Tests: P4b-04 the buyer confirms only after a warning, P4b-04 a collected order can\, P4b-03 checkout shows the final price and where to collect, P4d-03 a voucher takes one unit down, and shows where it went, P4d-03 a voucher that stopped working comes off the price (+9 more). Coverage source; only the TypeScript suite was run here. |
| `test/sign_in_redesign_test.dart` | 542 | Tests: the resend timer counts down from 3:00, each channel says where the code went and that it lasts 3 min, a username never shows the contact behind it, long form with the short form, the summary gives the level and the play range (+21 more). Coverage source; only the TypeScript suite was run here. |
| `test/supabase_academy_local_test.dart` | 339 | Tests: an academy from creation to a coach note, against local Supabase. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_ai_plan_local_test.dart` | 186 | Tests: no agreement, no plan, an adult gets one plan for one key, a teen is refused, and a bad goal is too, signed out gets nowhere. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_clips_local_test.dart` | 498 | Tests: a player uploads only to the clip they started, there is no way round the upload rules, signed out can\, nobody can read a video, and only the owner the frame, a stranger can\ (+4 more). Coverage source; only the TypeScript suite was run here. |
| `test/supabase_clubs_local_test.dart` | 197 | Tests: a club from creation to chat, against local Supabase. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_deletion_local_test.dart` | 97 | Tests: request, shut door, keep. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_enumeration_local_test.dart` | 144 | Tests: a registered mobile is as unknown to Supabase Auth as any other, a registered email is as unknown to Supabase Auth as any other, five wrong codes lock the target, and Supabase Auth is no way round. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_feed_local_test.dart` | 435 | Tests: reads work through the API, not only in a transaction, a post goes from the phone to a person, then to a viewer, a client never reaches a file on its own, a passed file can\, a retry finds a file that already landed (+5 more). Coverage source; only the TypeScript suite was run here. |
| `test/supabase_fitness_local_test.dart` | 161 | Tests: a player builds a program, logs a workout and sees it, a child with no parent is refused at the gate. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_lesson_local_test.dart` | 474 | Tests: a parent books a one-to-one, 20 replayed webhooks, cancels in time, a lesson can\, verification files: only your folder, and only staff read them, an assessment and a chart, and who can read them, a referral gives a link and records only that it happened. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_money_local_test.dart` | 308 | Tests: join, pay, confirm by webhook, give up, refund, 50 players race for the last spot and one gets it, parallel refunds and replayed webhooks move the money once, a free Meet: the organizer saves a card and is charged per join. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_play_local_test.dart` | 348 | Tests: R-MET-4 20 parallel joins on 10 spots give exactly 10 and 10 in order, P1-09 sign up by mobile, host, a second account joins, Game is on, the live API refuses a restricted child, and linking lifts it, P3-04 two players confirm one score at once and the rating moves once, P3-06 six parallel entries on three places give exactly three. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_safety_local_test.dart` | 89 | Tests: reports and legal notices, against local Supabase. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_shop_local_test.dart` | 464 | Tests: buy, 20 replayed webhooks, ready, collected, review, cancelling gives back the money, the stock and the points, an on-top shop charges the commission on top, a report holds the money and a shop cancel refunds it, 50 buyers race for the last one and one gets it (+1 more). Coverage source; only the TypeScript suite was run here. |
| `test/supabase_tournament_local_test.dart` | 458 | Tests: a tournament from entries to results, against local Supabase, doubles partners invite, accept and withdraw, event tickets, the door and the live court, against local Supabase, my gear and the leaderboards, against local Supabase. Coverage source; only the TypeScript suite was run here. |
| `test/supabase_voucher_local_test.dart` | 319 | Tests: a voucher through checkout, 20 replayed webhooks, cancelled and back, someone else can\, a campaign: join, attend, and the voucher arrives. Coverage source; only the TypeScript suite was run here. |
| `test/support/local_accounts.dart` | 34 | Dart test support or application wiring. Functions: signUpLocal. |
| `test/venue_test.dart` | 82 | Tests: peak is weekday evenings and all weekend, a start is taken only when every court is booked for any hour, refunds: the court price in time, none late. Coverage source; only the TypeScript suite was run here. |

### Analysis worker

| File | Lines / asset | Role and functionality |
| --- | ---: | --- |
| `workers/analysis/.dockerignore` | 6 | Worker build/support/license artifact. |
| `workers/analysis/Dockerfile` | 24 | Worker container build, test and release stages. |
| `workers/analysis/NOTICE` | 10 | Worker dependency/model licensing notice. |
| `workers/analysis/README.md` | 21 | Documentation: Analysis worker. Requirements/status evidence, not executable functionality. |
| `workers/analysis/models.sha256` | 2 | Expected model-file hashes. |
| `workers/analysis/olympus_worker/__init__.py` | 0 | Python analysis worker/support. Package initializer/support module. |
| `workers/analysis/olympus_worker/__main__.py` | 27 | Python analysis worker/support. Package initializer/support module. |
| `workers/analysis/olympus_worker/api.py` | 104 | Python analysis worker/support. Talks to the analysis-worker function. Holds only the fleet secret.. Package initializer/support module. |
| `workers/analysis/olympus_worker/metrics.py` | 175 | Python analysis worker/support. Turns foot positions on the court into a report. Pure, so it's easy to test. Court coordinates are metres: x across (0 to 6.1), y along from the far baseline (0) to the near baseline (13.4).. Functions: on_side, _inside, follow, player_path, _smooth, _smooth_stretch, heatmap, report. |
| `workers/analysis/olympus_worker/moderate.py` | 102 | Python analysis worker/support. Samples a post's frames for the feed checks. The checks themselves run in the feed-worker function, so this holds no provider key. Frames stay in memory and the video in the job's temp folder. Logs carry job ids and error names only.. Functions: _jpeg, sample_frames, run_feed_once, run_feed_forever. |
| `workers/analysis/olympus_worker/pose.py` | 33 | Python analysis worker/support. Finds where people's feet are. Faces and identity aren't looked at.. Functions: feet_from. |
| `workers/analysis/olympus_worker/run.py` | 80 | Python analysis worker/support. Claims a job, does it, reports back. The clip lives in a temp folder only for the length of the job. Logs carry job ids and error names, nothing else.. Functions: settle, run_once, run_forever. |
| `workers/analysis/olympus_worker/vendor/__init__.py` | 0 | Vendored court-analysis dependency. Package initializer/support module. |
| `workers/analysis/olympus_worker/vendor/good_badminton/LICENSE` | 201 | Vendored component license. |
| `workers/analysis/olympus_worker/vendor/good_badminton/__init__.py` | 0 | Vendored court-analysis dependency. Package initializer/support module. |
| `workers/analysis/olympus_worker/vendor/good_badminton/court/__init__.py` | 7 | Vendored court-analysis dependency. Package initializer/support module. |
| `workers/analysis/olympus_worker/vendor/good_badminton/court/detector.py` | 548 | Vendored court-analysis dependency. Functions: _line_angle, _line_intersection, _inside_image, _polygon_area, _is_convex_quad, _project_court_points, _badminton_line_alignment_score, _badminton_horizontal_pattern_score, _horizontal_segment_support, _side_segment_support (+9 more). |
| `workers/analysis/olympus_worker/vendor/good_badminton/court/mapper.py` | 344 | Vendored court-analysis dependency. Functions: compute_expanded_roi, auto_detect_preview, resolve_court_corners, annotate_court. |
| `workers/analysis/olympus_worker/vendor/good_badminton/court/reference.py` | 145 | Vendored court-analysis dependency. Package initializer/support module. |
| `workers/analysis/olympus_worker/video.py` | 108 | Python analysis worker/support. Reads a clip. Nothing here is written anywhere but the job's temp folder.. Functions: _open, corners_ok, find_court, analyse. |
| `workers/analysis/requirements.txt` | 4 | Python worker dependency versions. |
| `workers/analysis/tests/test_feed.py` | 231 | Tests: test_one_frame_a_second, test_more_frames_a_second, test_frames_are_small, test_a_video_past_the_limit_fails_rather_than_going_part_checked, test_a_file_that_isnt_a_video (+14 more). Coverage source; only the TypeScript suite was run here. |
| `workers/analysis/tests/test_licences.py` | 31 | Tests: test_ultralytics_isnt_installed, test_ultralytics_isnt_in_the_requirements, test_no_code_here_imports_it, test_torch_isnt_needed, test_the_reused_code_keeps_its_licence. Coverage source; only the TypeScript suite was run here. |
| `workers/analysis/tests/test_metrics.py` | 278 | Tests: test_a_steady_walk_measures_about_right, test_a_slow_walk_still_counts, test_quick_turns_arent_lost, test_standing_still_measures_nothing, test_jitter_isnt_counted_as_running (+22 more). Coverage source; only the TypeScript suite was run here. |
| `workers/analysis/tests/test_run.py` | 306 | Tests: test_nothing_queued, test_a_court_job_gives_length_and_a_jpeg, test_a_long_clip_is_stopped_by_its_real_length, test_a_file_that_isnt_a_video, test_an_analysis_gives_a_report (+15 more). Coverage source; only the TypeScript suite was run here. |

Inventory ends: 716 files. Generated/asset/support files are included for completeness; they must not be added together as product features.
