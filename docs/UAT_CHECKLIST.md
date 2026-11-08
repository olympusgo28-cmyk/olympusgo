# OlympusGO UAT checklist

A hand-run acceptance test of every feature that exists in the app today, on the iOS Simulator (or a phone) against the local Supabase stack. Tick each line as you go and write what you saw in the Notes column. It complements `docs/TESTING.md` (the automated journeys) and the deletion UAT in `docs/audits/2026-11-08/REPORT.md`.

"Expect" describes what should happen; if anything else happens, that is a finding. Rule ids point at `docs/RULES.md`; journey ids (P01, A04, N18 …) at `docs/TESTING.md`; ticket ids at `docs/BUILD_PLAN.md` and `docs/features/phase-*-status.md`.

**Scope.** Everything is local. Stripe, SMS, email, push, the Claude model, the video checks and the analysis worker are stand-ins. Nothing here proves a real payment, a real text message or a real push.

## 0. Before you start

### 0.1 Stack and app

- [ ] **0.1.1 Start the stack.** `colima start --cpu 4 --memory 6`, then `supabase start`, then `supabase db reset` so the seed is clean. Expect: `supabase status` shows a non-empty anon key and every container is up, including `supabase_edge_runtime_olympusGO` (sign-in dies silently without it).
- [ ] **0.1.2 Launch the app.** `flutter run -d <simulator udid> --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_ANON_KEY=<anon key>`. Expect: the Welcome screen. If every 6-digit code is accepted and the home screen shows demo content, the anon key was empty and the app is in demo mode: relaunch.
- [ ] **0.1.3 Face ID.** Simulator menu Features, Face ID, Enrolled. To answer a prompt: `xcrun simctl spawn <udid> notifyutil -p com.apple.BiometricKit_Sim.pearl.match` (or `.nomatch`).
- [ ] **0.1.4 Offline switch.** `docker stop supabase_kong_olympusGO` takes the API away; `docker start` brings it back. Use it for every offline case below.

### 0.2 Accounts and codes

| Who | Sign in with | Code | Notes |
| --- | --- | --- | --- |
| Aaron Ng, player, adult | +65 8000 0001 | 123456 | Seeded. Badminton |
| Hannah Goh, player, adult | +65 8000 0002 | 123456 | Seeded |
| Any new account | Any mobile number with no account | 123456 | Get started, then log in by mobile: a new number signs up. Pick the birthday for the age path you need |
| Any email | Any address | 123456 | For the optional email or an email change |
| Staff (admin web) | admin@test.local | password `local-admin-password` | Enrols MFA on first sign-in |

Fixed codes work only on a local stack, for every number and address. Nothing is sent anywhere. Codes last 3 minutes, and a new one can be sent after 3 minutes (Q248).

### 0.3 Feature flags

Every money and media feature is off by default. Turn one on with SQL before its section, and off again after:

```sql
update public.feature_flags set enabled = true where key = 'payments.enabled';
```

| Key | Needed for |
| --- | --- |
| `payments.enabled` | Paid Meets, tickets, refunds, earnings, payouts (section 10) |
| `payments.tournament` | Paid tournament entries (not built: leave off) |
| `shop.checkout` | Shop checkout (section 11) |
| `points.earning` | Earning points at checkout (section 12). Also needs `points.weekly_cap_minor` and `points.redeem_min_account_days` in `app_settings` |
| `lessons.checkout` | Paid trials, single classes and one-to-ones (section 13) |
| `game.campaigns`, `game.organizer_rewards` | Game tab campaigns and organizer rewards (section 12) |
| `fitness.enabled` | Fitness tile (section 15) |
| `fitness.ai_plans` | AI plans (section 15) |
| `video.analysis`, `video.analysis_minors` | Analysis clips (section 16) |
| `video.feed`, `feed.fake_checks` | Video feed with the stand-in checker (section 16) |
| `campaign.require_paid` | Counted games need a paid spot (leave as is) |

### 0.4 How to record a finding

For each failed line write: the line id, what you did, what you saw, what you expected, screenshot if any, and whether it blocks the flow. Severity: **High** stops the journey or breaks a rule; **Medium** wrong but a way round exists; **Low** wording or polish. Record findings in `docs/audits/<date>/REPORT.md`.

## 1. Sign-up and onboarding (N01, P1-02 to P1-06)

- [ ] **1.1 Sign up by mobile.** Welcome, Get started, enter a number with no account, such as 9123 4567. Expect: "Log in or sign up", then "Check your messages" naming the number, "It works for 3 minutes", one 6-digit code field and a 3:00 resend timer. Nothing says whether the number is known (R-ACC-4, Q247).
- [ ] **1.2 Wrong code.** Enter 000000. Expect: "That code didn't work. Check it and try again." Nothing else changes.
- [ ] **1.3 Lockout.** Enter 5 wrong codes. Expect: locked for 15 minutes with a plain message; the right code is refused too until then. Repeat with an unknown number: the same behaviour (R-ACC-4).
- [ ] **1.4 Right code.** Enter 123456. Expect: onboarding starts at Name.
- [ ] **1.5 Adult path.** Birthday making you 25. Expect: Sports, then a starting level per sport (provisional note), Username, optional email, Ready, then Home. No parent step.
- [ ] **1.6 Teen path (13 to 17).** New account, birthday making you 15. Expect: the Parent link step; the account lands in the restricted shell (section 3) until a parent approves (R-AGE-1).
- [ ] **1.7 Child path (under 13).** New account, birthday making you 11. Expect: the same shell; nothing public is reachable.
- [ ] **1.8 Edge ages.** Repeat with birthdays exactly 13 and exactly 18 today. Expect: 13 is a teen, 18 is an adult (P1-03 proved 12, 13, 17, 18).
- [ ] **1.9 Birthday is write-once.** After onboarding, look for any way to change the birthday in Settings. Expect: none; support does it.
- [ ] **1.10 Username rules.** Try a taken username (`aaron_host`), one with spaces, one with a rude word. Expect: each refused with a sentence; a free one accepted.
- [ ] **1.11 Optional email.** Add any email, code 123456. Expect: "Check your email" naming the address, no progress bar, verified; skipping the step also works.
- [ ] **1.12 Permissions.** Notifications and location asked on their own screens with a Not now. Expect: declining does not block onboarding.
- [ ] **1.13 Back.** Press Back on every onboarding screen. Expect: returns to the previous step, never to Welcome with data lost.
- [ ] **1.14 Offline.** Kill the API at the code step and submit. Expect: "Can't reach OlympusGO. Check your connection and try again." and a retry that works once the API is back.

## 2. Log-in, saved accounts, recovery (P1-04, P1-05, P1-06)

- [ ] **2.1 Log in by mobile.** Log out, Get started, +65 8000 0001, 123456. Expect: Home as Aaron, not onboarding.
- [ ] **2.2 Log in by email and by username.** Use the email and username tabs with Aaron's values. Expect: same code screen, same success.
- [ ] **2.3 Unknown identifiers.** Log in with an unknown email and an unknown username. Expect: the code screen looks identical, takes about the same time, and a code of 123456 fails the same way a wrong code does. The username screen names the username, never the email or mobile behind it. Nothing says "no account" (R-ACC-4, Q41). An unknown mobile signs up instead (1.1).
- [ ] **2.4 Saved account tile.** Switch on Enable Face ID in Account information, then log out. Expect: Get started opens Log in, headed "Welcome", with a tile for Aaron showing "•••• 0001" or "@aaron_host", never the email (R-ACC-10). Use another profile and the Terms line sit below. With Face ID off, no tile is kept and Get started opens log in by mobile (Q249).
- [ ] **2.5 Tile with Face ID match.** Tap the tile, answer the prompt with a match. Expect: Home, no code.
- [ ] **2.6 Tile with no match.** Tap the tile, answer no-match. Expect: "Face ID didn't work. Log in with a code to continue." and the tile stays.
- [ ] **2.7 Remove a tile.** Tap the cross. Expect: the tile goes; logging in by code makes it come back on the next log-out.
- [ ] **2.8 Expired tile.** In SQL, delete Aaron's `auth.refresh_tokens`, then tap the tile. Expect: "That sign-in has expired. Log in with a code to continue." and the tile is removed.
- [ ] **2.9 Recovery.** Get started, "Trouble logging in? Get back into your account", enter an email. Expect: a "sent" screen with no hint whether the email is known; a support row appears in the database (`account_recovery_request`).
- [ ] **2.10 Two accounts on one phone.** With Face ID on, log in as Hannah, log out, log in as Aaron, log out. Expect: two tiles, each opening the right account. With more than 3 tiles the list scrolls.

## 3. Restricted shell and parent link (P1-07, P1-08, R01, R02)

Set up: a teen account from 1.6 (the child) and Aaron (the parent, 18+).

- [ ] **3.1 The shell.** As the child, try Home, Discover, Inbox, Profile, any Meet. Expect: only the parent-link screens, Settings, Legal and onboarding are reachable; everything else says a parent has to link first.
- [ ] **3.2 Ask for a code.** Child: Parent link, Get a code. Expect: a code with its expiry (`guardian.code_hours`); the code is shown once, never in the Inbox.
- [ ] **3.3 Parent enters the code.** Aaron: Settings or Profile, Children, Enter a code. Expect: a pending link; the child is still restricted.
- [ ] **3.4 Wrong code five times.** Aaron enters a wrong code 5 times. Expect: locked for the configured minutes with a message.
- [ ] **3.5 Approve.** Aaron approves. Expect: the child's app opens up on its next action; the child's profile cannot be set Public (R-AGE-3); the child appears in Aaron's Children list.
- [ ] **3.6 Child without a verified mobile.** Make an account with only a `@test.local` email. Expect: it is restricted whatever birthday it has (an account needs a verified mobile).
- [ ] **3.7 Adult cannot be a parent of an adult.** Aaron tries a code from Hannah. Expect: refused.
- [ ] **3.8 Revoke.** Aaron revokes the link. Expect: the child is back in the shell at once; the child's data is intact.
- [ ] **3.9 Second parent.** Hannah links the same child and approves; Aaron revokes. Expect: the child stays open because another approved parent remains.
- [ ] **3.10 Minors in lists.** As Hannah (not linked), look at a Meet roster, club members and search results that include the child. Expect: the child is masked or absent; no real name, no avatar.
- [ ] **3.11 Messages.** As Hannah, open the child's profile and look for Message. Expect: no private message from an adult who is not the parent (R-MSG-1).

## 4. Home, Discover and search (P04, N13, P2-01, P2-02)

- [ ] **4.1 Home tiles.** As Aaron. Expect: the main tiles (Play, Clubs, Game, Shop, Academies, Services, Fitness, Venues) each open; Services and Fitness show their empty or flagged state when off.
- [ ] **4.2 Edit categories.** Home, edit the tile order. Expect: the order sticks after relaunch.
- [ ] **4.3 Discover list and map.** Discover with location declined, then allowed. Expect: a list; the map with a coarse location pin; no exact location shown for a player.
- [ ] **4.4 Sport filter.** Filter by badminton, then clear. Expect: only badminton Meets; count changes; chips show the active filter.
- [ ] **4.5 Date and level chips.** Try each chip and the calendar. Expect: results change and a Clear all exists.
- [ ] **4.6 Search.** Search "Tampines", a username, a club name, a venue. Expect: grouped results; a tap opens the right page; an empty result has an empty state with wording, not a spinner.
- [ ] **4.7 Players tab.** Search players. Expect: minors absent; blocked users absent.
- [ ] **4.8 Offline Discover.** API off, open Discover. Expect: an offline state with Retry; cached content if any; no crash.

## 5. Meets: create, publish, join, leave, waitlist (A04, A05, P01, P02, N02, P1-09)

Set up: Hannah hosts, Aaron and a third account join. For a paid Meet turn `payments.enabled` on (section 10 covers money).

- [ ] **5.1 Create a free Meet.** Hannah: Play, Create, sport, details (format, level range, capacity 2, date, time, venue, price S$0). Expect: each field validates; the date and time pickers are separate screens that return the value; the venue picker searches.
- [ ] **5.2 Draft to published.** Save, then Publish. Expect: the Meet appears in Discover for Aaron within a refresh; Hannah's Schedule, Hosting tab lists it.
- [ ] **5.3 Join.** Aaron opens the Meet, Join. Expect: "You're in" state; the players list shows Aaron; capacity count updates (`join_activity`).
- [ ] **5.4 Capacity and waitlist.** Third account joins the now-full Meet. Expect: Waitlist, with position; the host sees the waitlist.
- [ ] **5.5 Leave frees the spot.** Aaron gives up his spot. Expect: the waitlisted player is promoted (offer or seat per settings) and told in the Inbox.
- [ ] **5.6 Join twice.** Tap Join twice quickly. Expect: one participation row, no error.
- [ ] **5.7 Pair join.** Join as a pair when one seat is left. Expect: waitlist, not a split pair.
- [ ] **5.8 Guest spot.** Aaron adds a guest. Expect: the guest counts against capacity; the price shown for a guest matches the Meet price (a review fix: no doubling).
- [ ] **5.9 Request-to-join Meets.** Hannah creates a Meet that needs approval. Expect: Aaron's Join becomes Requested; Hannah approves or declines from the players list.
- [ ] **5.10 Blocked by host.** Hannah blocks the third account, who then tries to join. Expect: refused or never promoted from the waitlist.
- [ ] **5.11 Edit a published Meet.** Hannah changes the time. Expect: players are notified; the card updates.
- [ ] **5.12 Cancel a Meet.** Hannah cancels with a reason. Expect: status Cancelled, players notified, Meet gone from Discover; for paid Meets see 10.9.
- [ ] **5.13 Repeating Meets.** Create a weekly series. Expect: the next occurrences exist; cancelling one does not cancel the series.
- [ ] **5.14 Report a Meet.** Aaron reports the Meet. Expect: a reason has to be picked before Send is enabled (R-MOD-1); it shows under My reports.
- [ ] **5.15 Past Meets.** Look at a Meet whose time has passed. Expect: Join is gone; "Game is on" or the recap shows instead.
- [ ] **5.16 Schedule.** Aaron: Profile, Schedule, Joined and Hosting. Expect: joined Meets under Joined; hosted under Hosting; past ones below or in History.

## 6. Check-in, QR, attendance (P05, A06, A09, P1-10, P1-11)

- [ ] **6.1 Attendance opens on time.** Before the window (`meet.attendance_opens_minutes`), Hannah opens Attendance. Expect: a message that it opens later. Within the window: the roster with Present toggles.
- [ ] **6.2 Player QR.** Aaron: Scan tab, My code. Expect: a QR that rotates on "New code"; the old one stops working.
- [ ] **6.3 Host scans a player.** Hannah: Attendance, Scan players, scan Aaron's code (use a second simulator or a printed image; the simulator has no camera, so this may need a device). Expect: Aaron marked Present with source "qr".
- [ ] **6.4 Player self check-in.** Aaron scans the Meet's code. Expect: Present with source "self"; a parent scanning for a child gives "parent".
- [ ] **6.5 Walk-in.** Hannah adds a walk-in by name. Expect: appears in the roster; not a real account; no minor data asked.
- [ ] **6.6 Save attendance.** Hannah saves. Expect: a game log row is written once; a second save with changes writes to the audit, not a second log row.
- [ ] **6.7 Organizer attendance.** Hannah arrives at the venue (simulate location) or taps Check in. Expect: her own attendance is recorded automatically or by the fallback button (A09).
- [ ] **6.8 Meet rounds.** Hannah: Match rounds, pick a preset, generate. Expect: rounds laid out from the roster; the preset locks once the first score is in.
- [ ] **6.9 Recap.** After the Meet, open Recap. Expect: players, scores, a share card; minors masked.

## 7. Scores, ratings, Passport, leaderboards (P03, P3-03 to P3-07)

- [ ] **7.1 Enter a score.** Aaron enters a score against Hannah from the Meet. Expect: the other side is asked to confirm in the Inbox.
- [ ] **7.2 Confirm.** Hannah confirms. Expect: the result is final; ratings move for both; the Passport shows a new session.
- [ ] **7.3 Dispute.** Enter another score; Hannah disputes. Expect: it goes to the organizer, who decides; the loser cannot change the outcome by flipping attendance (a review fix).
- [ ] **7.4 Expiry.** Leave a score unconfirmed. Expect: it expires after 24 hours (set `created_at` back in SQL to check).
- [ ] **7.5 Self-confirmation refused.** Aaron tries to confirm his own score. Expect: refused.
- [ ] **7.6 Duplicate score.** Enter the same score again in the same Meet. Expect: refused while one is open (known limit).
- [ ] **7.7 Passport.** Profile, Passport. Expect: rating band plus number, provisional note until enough games, history chart per sport, sessions count, badges.
- [ ] **7.8 History.** Passport, a sport's history. Expect: the chart matches the results entered.
- [ ] **7.9 Leaderboards.** Game, Leaderboards. Expect: by sport and country; the teen from section 3 is absent unless a parent opts in; the snapshot is hourly so a new result may wait.
- [ ] **7.10 Club leaderboard.** Clubs, a club, Leaderboard. Expect: members only.

## 8. Tournaments and events (P06, P07, A07, N03, P3-06)

- [ ] **8.1 Create a tournament.** Hannah: Create, Tournament, format (knockout, groups then knockout, round robin), size, dates. Expect: validation; a tournament page with tabs.
- [ ] **8.2 Register.** Aaron registers (free). Expect: an entry; for doubles a partner search and the partner's confirmation.
- [ ] **8.3 Last place.** Fill the tournament, then try one more. Expect: a waitlist or refusal, never over capacity (note: `tournament_register` was reported unlocked in Phase 1; check two registrations at once if you can).
- [ ] **8.4 Withdraw.** Aaron withdraws. Expect: the entry is withdrawn; a refund if paid (R-REF-14 to R-REF-16 are quotes only; paid entries are off).
- [ ] **8.5 Make the draw.** Hannah: Manage, Make draw. Expect: a bracket or groups matching the format; sizes 3 to 33 were tested, try 5 and 9.
- [ ] **8.6 Check-in and run.** Hannah: Check-in, then Run. Expect: entrants checked in; matches assigned to courts.
- [ ] **8.7 Score a match.** Hannah scores a match game by game. Expect: the winner advances; results tab updates; a correction and a retirement both work.
- [ ] **8.8 Message entrants.** Hannah: Message. Expect: all entrants get it in the Inbox.
- [ ] **8.9 Cancel a tournament.** Expect: entrants told; refunds if paid.
- [ ] **8.10 Create an event.** Hannah: Create, Event, sports, details, ticket count. Expect: an event page with Get ticket.
- [ ] **8.11 Get a ticket.** Aaron: Get ticket. Expect: a ticket in Scan, My tickets with a QR.
- [ ] **8.12 Door scan.** Hannah: Check tickets, scan Aaron's ticket. Expect: admitted once; a second scan says already used.
- [ ] **8.13 Release a ticket.** Aaron releases. Expect: the ticket stops working (a review fix) and the spot returns.
- [ ] **8.14 Cancel an event.** Expect: ticket holders told; refunds if paid.

## 9. Clubs and teams (A01 to A03, P10, T01, P2-03, P2-04)

- [ ] **9.1 Create a club.** Hannah: Clubs, Start, 4 steps (basics, sports, levels, invite, venue). Expect: the club page; Hannah is owner.
- [ ] **9.2 Join a private club.** Aaron requests to join; Hannah approves from Requests. Expect: Aaron is a member; a declined request says so.
- [ ] **9.3 Invite link.** Hannah shares the invite link `/join/<code>`. Expect: it opens the club and joins or requests.
- [ ] **9.4 Member roles.** Hannah makes Aaron an admin, then back to member. Expect: his permissions change; the audit log records both.
- [ ] **9.5 Custom role.** Hannah creates a role, sets permissions, assigns members, deletes the role. Expect: each step reflected; deleting moves members back to member.
- [ ] **9.6 Ban and unban.** Hannah bans the third account. Expect: they lose access and cannot rejoin; Bans lists them; unban restores.
- [ ] **9.7 Announcements and chat.** Hannah posts an announcement; Aaron replies in club chat. Expect: both appear; a member can report a message; the owner can delete one.
- [ ] **9.8 Moderation hide survives the owner.** A reported club message is hidden by staff. Expect: the owner cannot un-hide it (a review fix).
- [ ] **9.9 Leave, transfer, delete.** Aaron leaves; Hannah transfers ownership to Aaron and back; Hannah deletes a test club. Expect: each refuses or succeeds with a plain message; a club with members needs a transfer first if the rule says so.
- [ ] **9.10 Teen in a club.** The linked teen requests to join. Expect: the parent must approve group membership (P2-03).
- [ ] **9.11 Group ranking.** Clubs, Ranking. Expect: clubs ranked; counts match.
- [ ] **9.12 Create a team.** Hannah: Teams, Start, sport, members. Expect: a team page with roster, lineup and fixtures.
- [ ] **9.13 Fixture and lineup.** Add a fixture, set the lineup, mark availability as a member. Expect: each saved; the fixture page shows availability.
- [ ] **9.14 Team chat and settings.** Expect: works as club chat; settings save.
- [ ] **9.15 Leave and delete a team.** Expect: a member can leave; the owner is told to hand over first (there is no hand-over function yet: Q238); delete works for the owner.

## 10. Payments, refunds, earnings (N05, N18, P4a) — flag `payments.enabled`

Everything below uses the local Stripe stand-in: no real money moves.

- [ ] **10.1 Payment sheet.** Hannah publishes a paid Meet at S$8.00. Aaron joins. Expect: a sheet with the price, the S$2.00 platform fee as the rules state (R-FEE-*), the refund rules link (R-REF-20), card or PayNow, Face ID before paying.
- [ ] **10.2 Successful payment.** Pay. Expect: "You're in", a receipt under Receipts, the host's Earnings shows the Meet as held, not available.
- [ ] **10.3 Hold timer.** Start a payment and do not finish it. Expect: the spot is held about 10 minutes, then freed.
- [ ] **10.4 Failed payment.** Use the stand-in's failing card if provided, or fail the webhook. Expect: a failed state with Try again; no spot kept.
- [ ] **10.5 Last spot race.** Two accounts pay for the last spot at once. Expect: one gets it, the other is refunded or never charged.
- [ ] **10.6 Give up a spot early.** Aaron leaves well before the start. Expect: a refund per the refund table in `docs/RULES.md` (full price, fee handling as the row says), shown on the receipt (R-REF-*).
- [ ] **10.7 Give up late.** Leave inside the no-refund window. Expect: the sheet says what comes back (possibly nothing) before confirming.
- [ ] **10.8 Leave after the start.** Expect: nothing back; the spot still releases to the organizer once attendance is saved.
- [ ] **10.9 Organizer cancels a paid Meet.** Hannah cancels. Expect: every payer refunded in full; the card fee on card payments charged to Hannah's earnings (R-REF-11); a shortfall becomes a debt netted later (R-REF-12, Q12).
- [ ] **10.10 Playing host.** Hannah joins her own paid Meet as a player. Expect: she pays the S$2.00 platform fee only (R-FEE-5).
- [ ] **10.11 Organizer pays the fee.** Create a free Meet where the organizer pays the fee. Expect: players pay nothing; Hannah needs a saved card; a player leaving returns the S$2.00 with no card fee on the organizer.
- [ ] **10.12 Release.** After the Meet, save attendance. Expect: the held money moves to Hannah's available earnings; with attendance never saved it releases 24 hours after the end (R-HOLD-2).
- [ ] **10.13 Report holds money.** Aaron reports the Meet before release. Expect: the money stays held until staff decide (R-HOLD-4).
- [ ] **10.14 Earnings screens.** Hannah: Earnings, a Meet's detail, Payout account. Expect: held and available totals, per-Meet rows (Shop sales are in the totals only), a payout account set-up that waits for Stripe test keys.
- [ ] **10.15 Payout run.** In the admin app, prepare and approve the weekly payout. Expect: one approver up to S$5,000, a second different approver above; fees owed netted first; unverified vendors skipped with an alert.
- [ ] **10.16 Receipts and payment methods.** Aaron: Receipts, Payment methods. Expect: every payment and refund listed with amounts in `S$8.00` form; saved card management waits for Stripe keys.
- [ ] **10.17 Wallet.** If the Wallet screen is reachable, check it is hidden or says it is not open (R-WAL-* are not built).
- [ ] **10.18 Refund choice.** Where the rules give a Wallet or card choice, confirm the sheet offers only what is built.

## 11. Shop (P4b, P08) — flags `shop.checkout` (and `points.earning` for 12)

- [ ] **11.1 Browse.** Shop home, a shop page, a product. Expect: price, stock, commission not shown to buyers, report a listing.
- [ ] **11.2 Cart.** Add two products from one shop, change quantity, remove one. Expect: totals update; one order per shop (Q84).
- [ ] **11.3 Checkout.** Pay for the cart. Expect: final price before paying; PayNow or card; a 10-minute hold; the order appears under Orders as Paid.
- [ ] **11.4 Changed price.** Owner changes the price while Aaron is at checkout. Expect: checkout refuses and asks to review, never charges the new price.
- [ ] **11.5 Last unit.** Two buyers on the last unit. Expect: one gets it.
- [ ] **11.6 Cancel before ready.** Aaron cancels. Expect: money, stock and points all come back.
- [ ] **11.7 Owner side.** Hannah (shop owner): Owner orders, Mark ready. Expect: Aaron is told to collect.
- [ ] **11.8 Collect.** Aaron: "Yes, I got it all". Expect: the payout releases to the shop at price less 10% commission (S$8.10 of S$9.00).
- [ ] **11.9 Report a problem.** Aaron reports instead. Expect: the money is held for staff; the admin refunds by line.
- [ ] **11.10 Timer release.** An order marked ready and not collected. Expect: released 48 hours after the collection date or the ready mark, whichever is later; an order never marked ready does not release itself.
- [ ] **11.11 Review.** After collecting, leave a review. Expect: it shows on the product; a rude word is caught.
- [ ] **11.12 Moderated listing.** Staff hide a product. Expect: it disappears from the shop.
- [ ] **11.13 Services.** Shop, Services, book one. Expect: a referral row only; a leaving sheet says you are going to the partner (section 14).

## 12. Points, vouchers and the Game tab (P4b-05, P4d) — flags `points.earning`, `game.campaigns`, `game.organizer_rewards`

- [ ] **12.1 Earn points.** Buy and collect with earning on and the two `app_settings` set. Expect: points appear after collection, half the commission per item, with a 12-month expiry.
- [ ] **12.2 Spend points.** Checkout with points as the discount. Expect: points or nothing per item (one discount per item); two carts cannot spend the same points.
- [ ] **12.3 Points refund.** Cancel a points-paid order. Expect: points come back once.
- [ ] **12.4 New account cannot redeem.** A brand-new account tries to spend points. Expect: refused until `points.redeem_min_account_days` (R-PTS-6).
- [ ] **12.5 Campaign list and page.** Game tab. Expect: published campaigns with progress; quests listed.
- [ ] **12.6 Complete a quest.** Do what the quest asks (for example a counted game). Expect: progress moves; the reward (a voucher) is issued once; a retry issues nothing twice.
- [ ] **12.7 Voucher wallet.** Game, Wallet. Expect: the voucher with its use-by date and a code shown only to its owner.
- [ ] **12.8 Use a voucher.** At Shop checkout. Expect: it comes off the price; cancelling returns it once; the redemption is logged with who, which shop and when.
- [ ] **12.9 Organizer rewards.** Hannah: Game, Organizer rewards. Expect: the milestone ladder; a counted game needs six paying players scanned, judged after attendance closes and money releases.
- [ ] **12.10 Flags off.** Turn the flags off. Expect: the Game tab hides campaigns and rewards; games are still recorded.

## 13. Academy and lessons (P4c, C01 to C03, R01, R02, P11-01) — flag `lessons.checkout` for paid items

- [ ] **13.1 Create an academy.** Hannah: Academies, Start, levels, policies, verify (what is needed), coaches. Expect: the academy exists as unverified; the Verification screen takes a real licence upload straight after.
- [ ] **13.2 Verify.** Staff verify in the admin app. Expect: the badge appears; the licence file is gone from storage once verified.
- [ ] **13.3 Invite a coach.** Hannah invites by email. Expect: the invitation waits until that person opens Academy; it cannot be used to tell whether an email is registered; the coach must accept.
- [ ] **13.4 Coach page.** Open the coach's page. Expect: name, sports, licences verified or not.
- [ ] **13.5 Classes.** Hannah creates a class, edits it, changes a session. Expect: students are told of a change; the SMS fallback is not built (R-ACD-2).
- [ ] **13.6 Enrol a child.** Aaron enrols the linked teen. Expect: a child needs an account and a parent link; a typed name is refused.
- [ ] **13.7 Trial and single class.** Aaron books a paid trial and a drop-in. Expect: the payment sheet; the booking under Lessons.
- [ ] **13.8 One-to-one.** Hannah adds slots; Aaron books one for the child. Expect: the slot is taken; S$50.00 held.
- [ ] **13.9 Coach today and session marking.** The coach marks Present. Expect: the held money goes to the academy owner; a report has to come before the save (Q114: a 48-hour hold after Present for single sessions).
- [ ] **13.10 Cancel a lesson.** Aaron cancels an upcoming one-to-one. Expect: refund per the lesson rules; the slot reopens.
- [ ] **13.11 Make-up credits.** Mark a student absent with notice. Expect: a make-up credit per R-ACD-3; it can be used on another session.
- [ ] **13.12 Assessments.** The coach creates a template and assesses the child. Expect: a chart on the student's Progress; readable by the player, the parent and that coach; writable only by the coach.
- [ ] **13.13 Parent home.** Aaron: Children, the child, Class, Fees, Make-up, Progress, Attendance, Filming consent. Expect: each screen loads; fees are empty (direct, Q107); the consent switch saves.
- [ ] **13.14 Parent note.** Aaron sends a note to the academy. Expect: it appears in Academy messages.
- [ ] **13.15 Close an academy.** Hannah closes a test academy. Expect: refused while classes have enrolments if the rule says so; otherwise closed; her account can then be deleted (R-ACC-15).

## 14. Services referral (P4c-03)

- [ ] **14.1 Partner list.** Home, Services. Expect: partners with what they do; nothing about a medical condition is asked.
- [ ] **14.2 Leaving sheet.** Tap a partner. Expect: a sheet saying you are leaving OlympusGO; Continue opens the partner's link; one referral row with five columns, none about a condition.

## 15. Fitness and AI plans (P5a, P5b) — flags `fitness.enabled`, `fitness.ai_plans`

- [ ] **15.1 Exercises.** Fitness, Exercises, open one. Expect: about 40 exercises, written steps, no video; the under-18 account sees a shorter list.
- [ ] **15.2 Program from a template.** Build a program, set 72.5 kg on a lift. Expect: saved; decimals accepted.
- [ ] **15.3 Train.** Start the program, log a set, rest timer. Expect: the timer counts down while the app is open; it does not sound when the app is closed (known gap).
- [ ] **15.4 Close mid-workout.** Kill the app with a set logged. Expect: the workout reopens as in progress.
- [ ] **15.5 Finish and log.** Finish. Expect: totals (72.5 kg × 5 shows 363 kg lifted), personal bests, the log entry; a log entry can be deleted.
- [ ] **15.6 Finish offline.** API off, Finish. Expect: "Not saved yet", kept; API on, retry saves once.
- [ ] **15.7 Calculators.** Expect: one-rep max and body mass index for adults; Plates only for the teen (Q175).
- [ ] **15.8 AI plan consent.** Make my plan for the first time. Expect: the consent screen first; declining makes no plan.
- [ ] **15.9 Make a plan.** Agree, make a plan. Expect: a draft with the AI note and no weights (Q186); the stand-in's fixed plan.
- [ ] **15.10 Daily limit.** Ask for plans until refused. Expect: the daily limit message (3 a day).
- [ ] **15.11 Withdraw consent.** Settings, Privacy and safety, AI plans off. Expect: recorded; turning it on asks again.
- [ ] **15.12 Teen.** The teen tries AI plans. Expect: not offered (Q181).

## 16. Video analysis and video feed (P5c, P5d) — flags `video.analysis`, `video.feed`, `feed.fake_checks`

- [ ] **16.1 Add a clip.** Fitness, My workouts, Analyse my game, add a clip from the library. Expect: upload (no percentage), a court frame with four corners; dragging a corner moves it and the page does not scroll.
- [ ] **16.2 Analyse.** Pick your side, Analyse my game. Expect: a report with numbers and a heatmap from the stand-in; the set-up warns there must be no change of ends.
- [ ] **16.3 Delete a clip.** Expect: asks first; the list updates; the sweep removes the files.
- [ ] **16.4 Child's clip.** Aaron adds a clip for the linked child (`video.analysis_minors` on). Expect: consent and the parent-only marking; a second parent can read, withdraw, keep and delete, but not mark the court.
- [ ] **16.5 Post a video.** Videos, Add. Expect: the post waits for checks (stand-in); the first 3 posts queue for staff (First posts queue).
- [ ] **16.6 Approve and view.** Staff approve in the admin app. Expect: it appears in the feed; reactions work; no comments (by design).
- [ ] **16.7 Report and delete.** Report a post; delete your own. Expect: both work; a hidden post is gone within about 5 minutes.
- [ ] **16.8 Teen feed.** The teen opens Videos. Expect: the teen rules (no adult feed) or no feed at all, per Q225.

## 17. Inbox, chat, notifications (P2-05, P2-06, P8)

- [ ] **17.1 Updates.** Inbox after joining, a score request, a club approval. Expect: one update per event, in order, with a tap that opens the right page.
- [ ] **17.2 Direct message.** Aaron messages Hannah from her profile. Expect: optimistic send, retry on failure, delete own message; blocked users cannot message.
- [ ] **17.3 Rude words.** Send a message with a word from the starter list. Expect: caught or flagged (Q49: a starter list only).
- [ ] **17.4 Notification settings.** Settings, Notifications, quiet hours. Expect: saved; nothing reaches a phone locally (no Firebase), so check the push queue row in SQL instead.
- [ ] **17.5 Removal notice.** Staff hide something of Aaron's. Expect: a notice in the Inbox with the reason and how to appeal (SAF-4).

## 18. Profile, privacy, blocks and reports (P11, N04, P1-08, P1-09)

- [ ] **18.1 Edit profile.** Name, bio, avatar, sports and levels. Expect: saved; the avatar is not public to strangers beyond what visibility allows.
- [ ] **18.2 Visibility.** Set Public, Followers, Only me. Expect: another account sees what the setting allows; the teen cannot pick Public.
- [ ] **18.3 Follow.** Aaron follows Hannah; Connections lists. Expect: following and followers tabs correct.
- [ ] **18.4 Other player's profile.** Expect: Passport card, sessions per visibility, Message, Report, Block.
- [ ] **18.5 Block.** Aaron blocks the third account. Expect: each sees the other as not found; neither can join the other's Meet; Blocked list in Settings; unblock restores.
- [ ] **18.6 Report a player.** Expect: Send disabled until a reason is picked; My reports shows status; a second look is offered when the first decision is cleared.
- [ ] **18.7 Share profile.** Expect: a share card or link; a scanned username opens the profile.
- [ ] **18.8 Saved items.** Save a Meet and a product. Expect: both under Saved.
- [ ] **18.9 Findable by phone.** Turn it off. Expect: searching Aaron's number finds nothing.

## 19. Settings and Account Centre (P1-13, P1-16)

- [ ] **19.1 Account Centre step-up.** Open Account Centre. Expect: Face ID or a code first (R-ACC-8).
- [ ] **19.2 Change mobile.** In Account information, change the number in the merged mobile field, code 123456. Expect: "Check your messages" with a 3:00 resend timer, then verified; log in with the new number works; the old one does not. The +65 part cannot be changed, and Account region stays the same (Q254).
- [ ] **19.3 Duplicate mobile.** Change to +65 8000 0002 (Hannah's). Expect: refused without saying it is taken, or handled per R-ACC-6 (claim flow).
- [ ] **19.4 Change email.** Expect: a code to the new address; the old contact would be alerted (not sent locally).
- [ ] **19.5 Identity check.** Settings, Identity. Expect: the screen explains what is needed; upload waits for a verified flow.
- [ ] **19.6 Language and country.** Expect: language saved; country shows the emergency number from `country_config`.
- [ ] **19.7 Help, Community rules, Legal, Refund rules, Under-18.** Expect: each opens, signed in or not (Legal is open to everyone).
- [ ] **19.8 Legal notice without an account.** Get started, the Terms line at the bottom, Legal notice form. Expect: sends without signing in.
- [ ] **19.9 Log out.** Expect: with a tile, this device only; without, the session ends on the server too.
- [ ] **19.10 Edit profile.** Profile, Edit profile. Expect: the photo, Change photo under it, and one card with Name, Username, Bio and Gender. Each of the first three opens its own screen with Done; Gender opens a picker. Nothing is saved until Save, which shows "Saved" and goes back. A bad username is refused on its screen.
- [ ] **19.11 Account information.** Settings, Account information. Expect: one card with Email, Mobile (flag, +65 and the number in one field), Date of birth greyed with "can't be changed", Account region, and Enable Face ID off. Turning Face ID on asks for Face ID once.

## 20. Delete account (ACC-11, R-ACC-11, R-REF-18, R-ACC-15)

Covered in depth by `docs/audits/2026-11-08/REPORT.md`; these are the lines to re-run after any change.

- [ ] **20.1 The screen.** Settings, Delete account. Expect: what happens (refunds, Shop orders finish, points and vouchers lost, children keep accounts but lose the link, results stay as "Former player", the undo date), then Face ID.
- [ ] **20.2 Face ID no-match.** Expect: nothing happens; the screen stays.
- [ ] **20.3 Refusals.** As a club owner, a team owner, an open academy's owner, an active shop's owner, staff, or a host owed money. Expect: a plain message naming what to hand over first; nothing changes. A host with only a fee debt is not refused (Q245).
- [ ] **20.4 Request.** As Hannah with a joined paid Meet and a hosted one. Expect: signed out, "Your account is closing"; the joined Meet refunded in full with fee; the hosted Meet cancelled and its players refunded; her profile hidden from Aaron at once.
- [ ] **20.5 Closing gate.** Log in again as Hannah. Expect: only the closing screen with the date, Keep my account and Log out; every other call refused.
- [ ] **20.6 Keep.** Keep my account. Expect: Home; visible again; the refunds stand (Q244); a moderation hide is not undone.
- [ ] **20.7 Erase.** In SQL set `erase_after` to yesterday and run `select private.account_erase_due()`. Expect: "Former player", contacts and birthday gone, auth banned, points forfeited, vouchers expired, links ended; payments, results and reports kept.
- [ ] **20.8 Blocked erase.** With an open Shop order. Expect: `blocked_reason` set, nothing erased, a staff alert after 7 days.
- [ ] **20.9 Keep during the job.** Cancel after the day has passed, then run the job. Expect: the account is untouched.
- [ ] **20.10 Child of an erased parent.** Expect: the only child is restricted again; a child with a second parent carries on; enrolments and assessments stay.
- [ ] **20.11 Restricted account.** The teen in the shell tries Delete account. Expect: today refused by the gate (Q243 open); note what you see.

## 21. Scan tab

- [ ] **21.1 Scan a player.** Expect: their profile; no minor resolves.
- [ ] **21.2 Scan a group or venue code.** Expect: the club or venue page; nothing is charged.
- [ ] **21.3 Scan a vendor.** Expect: the shop page; no Pay mode.
- [ ] **21.4 Camera denied.** Deny the camera permission. Expect: an explanation and a way to Settings, not a blank view.

## 22. Admin web app (A-01 to A-10, N16)

Build and serve: `cd admin && flutter build web`, then the `admin-web` entry in `.claude/launch.json` (port 8091). Sign in as `admin@test.local`.

- [ ] **22.1 Sign-in and MFA.** Expect: MFA enrolment on first sign-in; no sign-in without MFA; roles limit sections (a payments-only account sees only Payments).
- [ ] **22.2 Reports queue and cases.** Decide a report. Expect: the decision log; a ban needs a second approver (R-MOD-*).
- [ ] **22.3 Users.** Find Aaron. Expect: opaque ids, no contact details beyond what the role allows; suspend and unsuspend.
- [ ] **22.4 Sports and rules.** Edit a preset or level scale. Expect: saved and audited.
- [ ] **22.5 Payments.** Holds, payout approval, refund retry. Expect: each goes through `admin-action` to the worker and lands in the audit log.
- [ ] **22.6 Shop admin.** Shops, products, stock, a handover report refunded by line.
- [ ] **22.7 Academy and services.** Verify a licence from a signed link; add a partner.
- [ ] **22.8 Campaigns.** Create and publish a campaign; a voucher type; see a redemption with who, where and when, and no code.
- [ ] **22.9 Jobs monitor and first posts.** A failed analysis job with no clip or name; retry; approve a first post.
- [ ] **22.10 Audit log.** Every action above appears with the actor's id, not their name or email.

## 23. Cross-cutting, on every screen you visit

- [ ] **23.1 States.** Loading, empty, offline and error states exist and say something useful (no bare spinner, no raw error JSON).
- [ ] **23.2 Back.** Hardware and in-app Back return to the previous screen in every flow.
- [ ] **23.3 Tap targets and labels.** Icon buttons are at least 44 px and have a screen-reader label (turn on VoiceOver on the simulator and swipe through a screen).
- [ ] **23.4 Dark mode.** Switch the simulator to dark. Expect: tokens only; no unreadable text; sport and logo tints are the known exception.
- [ ] **23.5 Copy.** Sentence case, second person, prices as `S$8.00`, "OlympusGO" spelled so, no placeholders like `[Venue]`.
- [ ] **23.6 Time zones.** Times show in the venue's or activity's zone; a Meet created for 7 pm shows 7 pm to a player (device zone is the known exception for vouchers and games).
- [ ] **23.7 Deep links.** Open `/activities/<id>`, `/clubs/<id>`, `/join/<code>` from a link while signed out. Expect: sign in, then the page.
- [ ] **23.8 Privacy.** No email, phone, code or birthday in any list, log line or toast; minors masked everywhere.
- [ ] **23.9 Rotation and small screens.** Rotate; try an iPhone SE size. Expect: nothing clipped.

## Not built: do not raise these as findings

Court booking and venue owner tools (Q25). Paid tournament entries (`payments.tournament`). Wallet and withdrawals. Real Stripe sheet, saved cards and Connect onboarding (need test keys). Leagues (Q50). Stripe, SMS, email and push against real services. Email or SMS notice of account deletion (Q239). A parent deleting a child's account (Q240). Comments on videos. Children's video content (Q225). Form checks, exercise videos, workout sharing. Monthly and term academy fees (Q107). Player marketplace, delivery, returns. Android build. A real check of the NROC or ACRA registers.

## Already known from the deletion UAT (8 Nov 2026)

Restricted and suspended accounts cannot delete (Q243). Saved-card rows survive the erase. Held organizer money and unsent payouts pass the request (Q246). A `manual` refund blocks the erase. Tournament entries are refunded but not withdrawn. Closing gate allows PATCH on the allowed table paths. Possible one-day date difference between screen and Inbox. See the report for the full list.
