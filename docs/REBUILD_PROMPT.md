# Prompt: rebuild OlympusGO

Copy everything below the line into your AI coding tool, or hand it to a developer. Attach the design canvas link when you do. Never paste passwords, API secret keys or Twilio tokens into the prompt; add those yourself in the Supabase dashboard.

---

You are building **OlympusGO**, a mobile app for racket-sport players in Southeast Asia. Players find and join games, run clubs and tournaments, learn at academies, and buy gear. Build it as a production-quality iOS and Android app. Follow every rule below exactly. When something isn't specified, choose the simplest option that fits the rules, and tell me what you chose.

## 1. Product in one paragraph

OlympusGO is a "Passport" for amateur players of badminton, pickleball, tennis, padel, table tennis, squash, basketball, football, running, swimming, cycling and HYROX. Each player has a skill level per sport (1 to 8). They join **Meets** (casual sessions), **tournaments** and **events**. They belong to **clubs** and **teams**, enrol children in **academies**, and buy from player-run **shops**. Markets: Singapore (default), Malaysia, Indonesia, Thailand. Currency SGD (S$). English only for now.

## 2. Tech stack (use these exactly)

- **Flutter** (Dart 3.13 or later), one codebase for iOS and Android. Portrait phone layouts, 402×874 reference (iPhone 17).
- **State:** Riverpod 3 with code generation (`riverpod_annotation`, `@riverpod`).
- **Navigation:** go_router 18, with every path in one `Routes` class and one router file. Deep links from `https://olympusgo.netlify.app/<path>` open the matching screen.
- **Models:** freezed + json_serializable for core models; plain immutable classes are fine for small ones.
- **Backend:** Supabase (Postgres, Auth, Storage, Realtime, Edge Functions) through `supabase_flutter`.
- **Other packages:** google_fonts, flutter_svg, local_auth (Face ID), flutter_secure_storage, image_picker, mobile_scanner (QR), qr_flutter, share_plus, url_launcher.
- **Share-link website:** a small static site in `share_site/` hosted on Netlify. It has a landing page, a page for each shareable link, and `/terms` and `/privacy`.
- **Config:** `env.json` (gitignored) holds `SUPABASE_URL` and `SUPABASE_ANON_KEY` (the publishable key). Run with `--dart-define-from-file=env.json`. **If the key is empty, the app runs in demo mode** with built-in sample data and no network. Real users must never see sample data.

## 3. Architecture rules

- Folders: `lib/core/` (theme, widgets kit, router, config, formatting, providers) and `lib/features/<feature>/{data,domain,application,presentation}`. Features: auth, onboarding, home, discover, play, clubs, academy, shop, wallet, game, venues, inbox, social, profile, safety, settings, scan, shell.
- **Every feature has a repository interface with two implementations:** `Supabase<Name>Repository` (real) and `Demo<Name>Repository` (sample data). One provider picks the implementation based on whether there is a key.
- Repositories catch database errors. Messages raised by database functions (Postgres `P0001`) pass through as a friendly `AuthFailure(message)`. Anything else becomes "Something went wrong. Try again.", and network errors become "Can't reach OlympusGO. Check your connection and try again."
- **All writes and multi-table reads go through Postgres functions (RPCs)**, not direct table access. Each function is `security definer`, `set search_path = ''`, returns `jsonb`, and checks permissions inside. Grant execute to `authenticated` only and revoke from `public` and `anon`. Internal helper functions are revoked from everyone. Every table has row-level security switched on; only add policies where the app reads or writes a table directly (addresses, gear, profiles).
- Never put raw colours or font styles in screens; always use the theme tokens and the widget kit.
- Plain, friendly English in all UI text: short sentences, no jargon, no exclamation marks. Error messages say what to do next.

## 4. Design system ("ThemeTokens")

- **Light theme "Tangerine":** primary `#F28500` (pressed `#E67700`, text-on-white `#A85200`, on-primary `#1B1206`), soft tint `#FFE8CC`, background white, surface `#F3F2EC`, border `#E2E0D8`, control border `#D6D3C9`, text `#16181B`.
- **Dark theme "Electric lime":** accent `#C6FF00` on ink `#16181B` / night `#0F1113`.
- Lime `#C6FF00` is the highlight on dark cards (the "Next up" card, success banners). Success, warning and danger each have a fill colour and an on-fill colour.
- **Fonts:** Archivo for headings and display (weights 700–800), Figtree for body (400–700). Load both with google_fonts.
- **Widget kit** (build this first and use it everywhere): scaffold with header (title, subtitle, back link with breadcrumb trail, trailing action), cards, nav tiles (icon, title, subtitle, chevron), choice rows (radio or check), chips, segmented control, underline tabs, buttons (primary, outline, dark, danger), text inputs and text areas, tags, notes (info, warn, success), key-value rows, a "done" banner (dark hero with lime tick and a big title), dashed empty-state boxes, bottom sheets with a grabber, Cupertino pickers, toasts, a count badge, avatars with initials, and a custom SVG icon set.
- Corners 14–26 px, 20 px side padding, generous spacing, haptic feedback on key actions.
- **Skill bands** for levels 1–8: LB, MB, HB (beginner low, mid, high), LI, MI, HI (intermediate), AD (advanced), PRO. Players pick whole levels only. A "play with" range uses a slider with Min and Max labels.

## 5. Accounts, sign-in and safety

- **Sign-up and log-in by 6-digit email code** (Supabase email OTP, confirmations off, custom "Your OlympusGO code" email template). Players can also log in with **mobile SMS code** (Twilio Verify) or **username** (an edge function `username-login` looks up the email).
- **Onboarding steps:** name → birthday and country (birthday can't be changed later) → pick sports → "Set your skill levels" (level per sport, play-with range) → pick a username (live availability check: green border and tick when free) → mobile number (SMS verify; debug builds may skip) → "You're in" → Account Centre (photo, bio, gender, personal info, optional Face ID).
- **Under-18 protections:** parent email and approval for minors, filming consent for children, limited visibility, and an Under-18 safety page.
- **Account Centre and Settings:** personal info, change email or mobile (with code verify), identity check, country and regulators, notifications, privacy (who sees sessions), blocked players, language (shows "Coming soon"), log out, delete account.
- **Safety:** report a player, message, club, team, activity, listing, video or live. "My reports" shows status (In review, Removed, No action) with "ask for a second look". Removal notices let people ask for a review. Also a community rules page, a legal notice form (works without logging in, gives a reference like OLY-YYMM-NNNN), Terms and Privacy pages, and refund rules.

## 6. Main navigation

Five-tab shell: **Home, Discover, Scan (centre button), Inbox, Profile**.

- **Home:** greeting, a "Find your next game" hero, search (Meets, clubs, players, shops), editable category grid (Play, Group, Academy, Game, Venue, Shop), Wallet and Points cards, and "Next up". Pull to refresh.
- **Discover:** suggested players, clubs, sessions and creators.
- **Scan:** scan a player's QR (shows their Passport), check in to a session, or check event tickets at the door. It also shows "My tickets".
- **Inbox:** notifications and direct messages (one-to-one chat).
- **Profile:** Passport card (main sport, level, sessions, club rank, clubs, link to leaderboards), points, next sessions, and the account list (Edit profile, Sessions and rating, Wallet, Followers, My orders, **My shop**, Sports and levels, My clubs and teams, Account Centre, My gear, Challenges, Share profile with QR, Saved, Settings, Help).

## 7. Features to build

### 7.1 Play (Meets, tournaments, events)
- Hub with tabs All, Meet, Tournament, Event; filters per tab (when, sport, level, game type, fee; tournaments: dates, tier, entries). Sport pills come from the player's preferences. **Activities with no level range count as "all levels" and must always match the level filter.**
- **Meets:** create (sport, game type, format: open play, round robin, king of the court, ladder; date and time; venue; level range; capacity; courts; fee; guests; approval; recurring series; minimum players). Join, waitlist with position, bring a guest, leave with refund rules, host tools (players, walk-ins, attendance, cancel with notice), check-in by QR, ranked score entry (one side enters, the other confirms), and a recap.
- **Tournaments:** divisions (MS, WS, MD, WD, XD or a single "main" event), formats (groups and knockout, knockout, round robin), capacity per event, registration close date, cover banner. Detailed in 7.2.
- **Events:** festivals, clinics, socials and fundraisers, optionally linked to a tournament ("Finals Day"). Detailed in 7.3.
- Every activity is hosted under a club; creating one checks the host's club permission.

### 7.2 Tournament engine (in the database)
- **Register** for up to 2 events. Doubles invites a partner, who gets a notification and taps "Partner up" or "Not this time" on the tournament page. Full events become a waitlist, and the first waiting entry moves in automatically when someone withdraws before the draw.
- **Organizer "Run the draw":** entries are seeded by rating (pair rating = average of the two levels) and snaked into groups of about 4 (A B C D D C B A). Every group plays every other entry (circle method), and the top 2 go through. The knockout puts group winners against runners-up from another group, with standard bracket order and byes for the top seeds, plus a 3rd-place match. Matches are scheduled in 20-minute slots across the venue's courts, never booking a player on two courts at once, with each knockout round after the previous one. Everyone in the draw is told their group and first match. A draw can be remade until a real score is in.
- **Umpire score entry** (keypad, best of 3; badminton games to 21 with 2 clear, or 30; other sports just need a winner). Saving moves the winner on, fills knockout places when a group finishes, writes a confirmed ranked score, and allows corrections until the next round is played. The organizer can also call a match to court (players are notified), check players in, and message entrants (everyone, one event, or not checked in).
- **Players see:** the Draw tab (group tables with W–L and points, the bracket, "Player" or "Pair" header), My matches (next match "called to court" or "next", done matches with scores from their side), and Results (place, podium, wins and losses). Withdrawing gives walkovers to opponents.

### 7.3 Events
Free tickets, up to 10 per person, with no overselling and a booking code ("OG-XXXXXX") shown as a QR. Players can give tickets back. The organizer scans codes at the door: the first scan admits the whole booking, and a second scan shows when it was used. A linked tournament's knockout becomes the event programme, with reminders and a live court showing the match on court with cheer counts.

### 7.4 Clubs and teams
- **Clubs:** create (sports, level ranges, venue, area, visibility public/private/hidden, join by anyone or request), roles with permissions (create Meets, public Meets, attendance, tournaments, events, approve, members, roles, edit page, audit, fees), join requests, bans, an audit log, announcements, invite links (`/join/<code>`), leaderboard, star ratings with reviews (members only, not the owner), group chat with private photos (signed URLs), message moderation, transfer ownership, and delete.
- **Teams:** roster, fixtures (create, availability, lineup slots per sport, record result), team chat.

### 7.5 Academies
- **Create academy** (5 steps: details, sport and levels, billing and make-ups, verification documents, coach emails). Head coach and coaches; add a coach by username, remove one, and coaches invited by email join once they sign up.
- **Classes:** "Add a class" (name, level 1–5, level name, days, start time, length, ages, fee, capacity, coach, court) and edit a class.
- **Parents:** ask to enrol "Myself", an existing child, or "Someone else" (name and age); book a trial; the child's page (next class, week of term, coach notes, skills, attendance, progress); make-up credits (earned when a moved class is missed) and booking a make-up at the same level; filming consent; class-change notices.
- **Coaches:** today's alerts, enrolment requests (accept or decline; class capacity is enforced), roster, "take attendance" (present/absent, focus skill status, a note for the class), parent notes with skill updates, curriculum (a 10-week default plan per sport, lesson plans with drills per level and week), and invites by mobile number (people with an account get a notification).
- Skills template per sport (badminton: footwork, strokes, serve, game sense, 12 skills). Week number = classes held + 1, capped at the term length.

### 7.6 Shop (player-run shops)
- **Open a shop** from Profile → My shop (name, what you sell, ships from, about); one shop per player.
- **Products and services:** name, description, price, old price (shows "17% off"), stock, published or draft. The picture is an icon chosen from the name (rackets, paddles and bats get a racket icon; everything else a bag) until photo upload exists.
- Shop home (flash deals, For you, Services, Malls), search, product page (about, reviews with sport and level, related items), shop page (follow, products, facts), cart, addresses, checkout (Standard S$1.99, Express S$4.99, Pick up free), one order per shop.
- **Orders:** the seller marks shipped (courier and tracking) or "Ready to collect"; the buyer confirms received; cancel before shipping puts stock back. **Write a review** (stars, tags, text, show my level) once delivered. **Return an item** within 7 days of delivery (reason, refund or exchange); the seller accepts or declines, and accepted returns go back into stock.
- Chat with the shop or the buyer opens a direct message. Report a listing or order.
- New products show "New" instead of "0.0, 0 sold".

### 7.7 Wallet, points, game and gear
- **Wallet:** balance from refunds, activity, receipts, earnings for hosts and sellers. Points: 1 point = S$1.
- **Game:** campaigns, workout and creator challenges, a camera-counted attempt flow, leaderboards. Local leaderboards rank players by rating, only those with at least 1 confirmed ranked game, filtered by area (members of clubs in that area). Tournament leaderboards use points: title 100, final 70, 3rd 50, semi-final 40, quarter-final 25, earlier rounds 10.
- **My gear:** racquets, paddles, bats and shoes, with specs (string, tension and so on).
- **Venues:** venue pages, book courts, cancel bookings.

## 8. Money rules

- Platform fee: 10%, minimum S$2 per payment, on Meets, tournaments, events and academy fees. Shops pay an 8% commission and buyers pay no platform fee. Refunds go to the Wallet or the card.
- **Card payments are switched off for now.** Build the payment screens, but in real mode:
  - Shop orders say "Pay the shop on delivery or pickup" and nothing is charged.
  - Academy fees say "Pay the academy directly".
  - Paid tournament entries and paid tickets are refused with a friendly message.
  - Hide or label "coming later": points spending, wallet withdrawals and payouts, coach pay, shop vouchers, shoppable videos and live selling.
  - Never show payment, commission or "verified" claims that aren't true for that player.

## 9. Database (Supabase migrations, in this order)

1. Accounts: profiles, private account info (birthday locked, country, parent email), player sports, recovery requests.
2. Social: follows, blocks, player reports, saved items, support requests, conversations and messages.
3. Play: venues, activities, participants, payments, play preferences, an `activity_cards` view, join, waitlist, leave and check-in functions.
4. Home and inbox: notifications with a `notify()` helper, suggested players.
5. Venues and courts; tournament banner rule; Meet tools (series, cancel preview, walk-ins, attendance, ranked scores).
6. Clubs and teams (everything in 7.4) with group messages on Realtime and content reports.
7. Safety and extras: legal notices, report tracking, removal notices, fixtures, club ratings, private chat photos, passport history, identity check.
8. Tournaments; events; gear and leaderboards; shop; academy.

Test every migration on a local Supabase stack (`supabase start` in a separate working folder, with its own ports) before pushing it to the hosted project.

## 10. Testing and quality

- Unit and widget tests, plus a **route audit test** that opens every screen in demo mode at iPhone 17 size with the real fonts and fails on any error or overflow.
- Integration tests that run each real repository against a local Supabase (skipped unless the local URL is set), covering: clubs; safety; tournaments from entry to results; doubles invites; event tickets and door scans; gear and leaderboards; shop from opening to review and return; academy from creation to coach notes.
- `dart analyze` must show no issues. Format with `dart format`.
- After each feature, run the app on the iOS Simulator and check the main flow by hand.

## 11. Build order

1. Theme tokens, widget kit, icons, router, demo mode.
2. Auth and onboarding.
3. Shell, Home, Profile, Settings, Safety.
4. Play: Meets, then tournaments and events.
5. Clubs and teams.
6. Inbox and social.
7. Shop, Academy, Wallet, Game, Gear, Venues.
8. Share-link website and deep links.
9. Tests, audit, then UAT on a real device.

## 12. Out of scope

Admin web app and academy web app; real card payments (Stripe) until switched on; video upload and live streaming; languages other than English.

When you finish each step, tell me what you built, what you tested, and anything that still needs my action (for example, Supabase settings or keys I must enter myself).
