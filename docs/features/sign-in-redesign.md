# Sign-in, onboarding and account screens redesign (owner, 8 Nov 2026)

Decisions: Q247 to Q254 in `docs/OPEN_QUESTIONS.md`. Rules changed: R-ACC-1, R-ACC-2, R-ACC-3, R-ACC-7. This touches sign-in, so this page is the plan for the pull request.

## Plan

### Server
- Migration `20261113090000_three_minute_codes.sql`: `auth.code_minutes` 10 → 3 (R-ACC-2). pgTAP checks the value and that a new code expires 3 minutes out.
- `resolve-login` local delivery: on a local stack every mobile and email gets the code `123456`. A hosted project still gets random codes; `isLocalStack` stays the only switch. Deno test updated.

### Sign-in screens
- **Welcome**: mascot, headline, lead, one **Get started** button. It opens Log in when this phone has saved tiles, otherwise log in by mobile.
- **Log in** (`/login`, new): heading "Welcome", the saved tiles (more than 3 scroll), **Use another profile** (outline pill), and the Terms and Privacy line. With no tiles it replaces itself with log in by mobile.
- **Log in account** (`/login/mobile`, `/login/email`, `/login/username`): as before, without "New here? Create an account". The recovery link reads "Trouble logging in? Get back into your account". The mobile method always asks the server for a sign-up code, so a new number gets a code and then onboarding (the router already sends a signed-in player without a profile to onboarding, and one with a profile to Home). Email and username are unchanged: nothing is sent for an unknown one, with the same answer and timing (R-ACC-4).
- Back from log in account: the screen it came from, else Log in when tiles exist, else Welcome.
- The Create your account screen and `/signup`, `/signup/code` are removed.

### Code screens (log in, onboarding email, email or mobile change)
- One outlined field labelled "6-digit code" replaces the six boxes. It keeps one-time-code autofill and submits by itself at 6 digits.
- Heading by channel: "Check your messages" (mobile), "Check your email" (email), "Check your email or messages" (username). No progress bar.
- Lead: "We sent a 6-digit code to <what was typed>. It works for 3 minutes." For a username it names the username, never the contact behind it.
- Resend timer 3:00, shown as m:ss. Verify refuses fewer than 6 digits with a message.

### Skills
- **Set your skill**: sport icon only (no circle); the summary line is empty until a level is picked, then "Level 4.0 · Low Intermediate · Plays with 3.0 to 5.0". Continue waits until every sport has a level (Q253).
- **Skill editor**: sport icon and name, no progress bar; level picker starts empty; "Play with levels", the Min and Max readouts, the slider, then each end's name with its short form, for example "Mid Beginner (MB)" (Q252); helper "We recommend Meets and partners inside this range."; **Done** saves to the draft.

### Profile and account
- **Edit profile** (rebuilt 9 Nov 2026, see `docs/features/settings-and-profile.md`): photo, Change photo, name and @username; outlined cards for Name, Username, Profile link, and About you (Bio, Sports, Level, Gender). Each edit saves on its own screen.
- **Account information** (was Personal information; rebuilt 9 Nov 2026 with `InfoRow` and `InfoCard`): a card of rows, Phone number (masked "+65 •••• 1234", or "Add"), Email (masked "n***8@gmail.com", or "Add"), Date of birth and Account region (both read only, Q254), with the region note under it; then a Sign-in card with Enable Face ID (off by default, Q249, Q258). Phone number and Email open their own screens (Mobile field or Email field, Send code, then the code screen); a verified code returns to Account information, or to its onboarding step, instead of Settings. Turning Face ID on asks for Face ID once and saves this session for a tile at once. Loading shows grey rows at full height; a failed load shows the error and Try again, without retrying on its own. Data comes from `accountInfoProvider` (`AccountInfo`, freezed).
- Settings rows renamed to Edit profile and Account information (Settings was rebuilt on 9 Nov 2026); the Account Centre hub, which had a Face ID row, was removed on 9 Nov 2026 (Q265).

### Look
- Text fields use the outlined style with a floating label (Q251).
- Font Jost everywhere, Regular and Medium only (Q250, Q257).

### Tests
- Widget tests for each changed screen, the code field, the resend timer format, the skill short forms and the Face ID default.
- pgTAP for the code lifetime; Deno test for the local code.

## Added while building

- Log in by mobile, email and username also shows the Terms and Privacy line, because a new phone has no tiles and never sees the Log in screen (Q255).
- The onboarding birthday and country fields use the outlined style too.
- Method buttons ("Log in with username") shrink their label instead of spilling over at large text sizes.
- The Bio editor opens with its field focused.

## Fixed after the independent review (9 Nov 2026)

- Face ID is switched on per account, not per phone. Another account logging in on the same phone gets no tile until that player switches it on too (Q249).
- Tiles and tokens left by the older default-on build are removed the first time the phone reads them.
- Switching Face ID on needs a face or fingerprint set up on the phone and one successful check; a passcode alone is not enough. If the session can't be stored, it stays off. A tile whose token is gone is removed when tapped.
- Account information shows the mobile with its own dialling code, so a Malaysian number on a Singapore account no longer reads "+65 60…" and Save no longer texts a wrong number. The region line says what the region sets (Q254 corrected).
- The resend timer restarts only after a new code was sent.
- The live sign-in email and the architecture and PRD notes say 3 minutes.
- The server sends every mobile a code the same way, with no account lookup, so a direct call cannot tell a known number from an unknown one by timing.
- Q256 records that the local fixed code relies on the API host name.

## Checked (9 Nov 2026)

- `supabase test db`: 55 files, 2,433 tests pass (the migration was applied with `supabase migration up`, without a reset). `50_ai_plans_test.sql` now uses an unusual mobile, because a tester signing up with the sample 9123 4567 on the same database made it fail.
- `supabase db lint`: only warnings in older functions.
- `deno fmt --line-width 110 --check`, `deno lint`, `deno test -A supabase/functions`: 115 pass.
- `dart format --set-exit-if-changed`, `flutter analyze` (app, admin, og_design): clean. `flutter test`: 288 pass, 59 skipped (local API tests without the stack variables).
- On the iPhone 17 Pro simulator against the local stack: Welcome, log in by mobile, a new number (+65 9123 4567) signing up with 123456, the code screen, every onboarding step through Set your skill, the skill editor, the email check with an address outside `@test.local`, Edit profile with the Bio editor, and Account information. After the review fixes: the terms line under log in by mobile, and logging back in with the same number going straight to Home.

## Not checked

- Saved tiles and the Face ID switch on the simulator (covered by widget and unit tests only).
- Futura's licence for Android and web (Q250).
- The admin web app with Jost.
