# OlympusGO

Flutter app built from the **OlympusGO Screens** design canvas, using Flutter, Riverpod, go_router, freezed and Supabase. Screens match the artboards; navigation, sheets, pickers, haptics and swipe-back follow iOS conventions (see `.claude/skills/apple-design`).

## Run

```bash
cp env.example.json env.json   # add your Supabase anon or publishable key
flutter run --dart-define-from-file=env.json
```

Without a key the app runs in **demo mode**: every screen works, any 6-digit code is accepted, nothing is saved, and the people on screen are the design's sample players. Add `--dart-define=DEMO_SIGNED_IN=true` to skip sign-up, and `--dart-define=DEMO_AUDIENCE=child` to see restricted mode.

## Run against a local stack

```bash
supabase start
supabase db reset
flutter run --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_ANON_KEY=<anon key from supabase status>
```

Log in with `+65 8000 0001`, code `123456`. That is seeded as Aaron Ng; `+65 8000 0002` is Hannah Goh. See `docs/features/dev-setup.md` for the tests and every check.

## Supabase setup

1. Apply the schema: `supabase link --project-ref sfkylxlwbjculhuxoimd`, then `supabase db push` (runs every file in `supabase/migrations/`, including the `avatars` storage bucket and realtime for messages).
2. Deploy sign-in: `supabase functions deploy resolve-login`. Set secrets `LOGIN_HASH_PEPPER` (long and random), `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_MESSAGING_SERVICE_SID`, `RESEND_API_KEY` and `LOGIN_EMAIL_FROM`. In the dashboard, turn off new sign-ups and the phone provider, and leave the email provider on.
3. In the dashboard, under Authentication:
   - Email: switch on "Email OTP" and set the email template to send `{{ .Token }}` (a 6-digit code) instead of a magic link.
4. Payments: paid Meets, events and tournaments need a payment provider (for example Stripe). Until one is connected, free ones join for real and paid ones say card payments aren't switched on yet. Demo mode shows the full pay flow with a test Visa and wallet.

## Layout

```
lib/
  core/        theme tokens, shared widgets, router, providers, config
  features/    auth, onboarding, settings, social, play, home, discover, scan, inbox, profile, shell
supabase/      migrations and edge functions
```

## Build phases

1. **Done:** foundation, sign-in (email, phone, username, Face ID, recovery), 7-step onboarding, tab shell with Home, Discover, Scan, Inbox and Profile.
2. **2a done:** account centre, personal info, notifications, privacy, Passport, followers, share profile (with QR), search, saved, scan a player, direct messages, report or block, blocked players, help, log out. **2b done:** Play (Meets, tournaments, events, sport options, filters), Meet detail, pay and receipt, waitlist, bring a guest, give up a spot, check in by QR, My schedule (playing and hosting), and creating Meets, events and tournaments.
3. Clubs and teams, shop and wallet, creator.
4. Academy, venue, safety and legal.

Screens from later phases open a "Coming soon" page. Discover's "Players to follow" still shows the design's sample players until recommendations exist; everything else reads real data (or demo data in demo mode).
