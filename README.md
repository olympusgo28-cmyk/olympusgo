# OlympusGO

Flutter app built from the **OlympusGO Screens** design canvas, using Flutter, Riverpod, go_router, freezed and Supabase. Screens match the artboards; navigation, sheets, pickers, haptics and swipe-back follow iOS conventions (see `.claude/skills/apple-design`).

## Run

```bash
cp env.example.json env.json   # add your Supabase anon or publishable key
flutter run --dart-define-from-file=env.json
```

Without a key the app runs in **demo mode**: every screen works, any 6-digit code is accepted, nothing is saved, and the people on screen are the design's sample players. Add `--dart-define=DEMO_SIGNED_IN=true` to skip sign-up and start as Alex Lim.

## Supabase setup

1. Apply the schema: `supabase link --project-ref sfkylxlwbjculhuxoimd`, then `supabase db push` (runs every file in `supabase/migrations/`, including the `avatars` storage bucket and realtime for messages).
2. Deploy username log-in: `supabase functions deploy username-login`.
3. In the dashboard, under Authentication:
   - Email: switch on "Email OTP" and set the email template to send `{{ .Token }}` (a 6-digit code) instead of a magic link.
   - Phone: connect an SMS provider (Twilio, MessageBird or Vonage) for phone log-in and the mobile-number step.
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
