# Sign-in

**What it does.** Mobile-first sign-up by SMS code, and log-in by mobile, email or username, with saved-account tiles and Face ID.

**Files.** `supabase/functions/resolve-login/`, `lib/features/auth/`.

**Where contact details live.** Mobiles and emails are in `account_private`. `auth.users` holds only a random internal address, stored in `account_private.auth_email`, which players cannot select. It must never be derivable from anything public. So direct calls to Supabase Auth see an unknown account whoever they ask about, and can neither reveal one nor skip the lockout. New sign-ups and the phone provider are turned off in Supabase; the email provider stays on because it creates the session.

**Steps.** The app sends what the person typed to `resolve-login`, which finds the account on the server, issues its own code (`login_codes`, hashes only), and after a good code asks Supabase for a session. Replies are identical for known and unknown accounts and padded to `auth.login_pad_ms`. Five wrong codes lock the target for 15 minutes, counted against a hash of the identifier before the code is checked, so unknown identifiers lock too and parallel tries cannot get past.

**Saved accounts.** `BiometricVault` keeps one token per account. On iOS the token is tied to the current biometric set, so enrolling a new face or finger drops it and a code is needed. Each save deletes first, because updating a protected Keychain item would prompt for Face ID on every token refresh. The live session sits in the Keychain too (`SecureSessionStorage`), not in app preferences. Supabase's sign-out always ends the session on the server, so while a tile exists `SessionHttpClient` stops that one call and sign-out clears this device only.

**Rules and numbers.** All in `app_settings` under `auth.*`.

**Hosted set-up.** Turn off new sign-ups and the phone provider, leave email on, and set the secrets in the README. The `20261102090000` migration moves existing contact details; it has been run on empty tables only, so rehearse it on a copy.

**Security notes.** The service-role key is used only in the Edge Function. Identifiers are hashed with `LOGIN_HASH_PEPPER` before they reach the database. Logs carry status codes only.

**Tests.** `supabase/functions/resolve-login/logic_test.ts`, and the mobile journey in `test/supabase_play_local_test.dart`.

**Delivery.** `delivery.ts` sends through Twilio and Resend. A local stack sends nothing and uses fixed codes for test contacts; this is decided from `SUPABASE_URL`, so no fixed code can work on a hosted project.

**Known gaps.** The Twilio and Resend senders have not been run against the real services. Android has no tie to the biometric set, because its equivalent would prompt on every token refresh, so a new fingerprint there does not force a code. No CAPTCHA after repeated requests (R-ACC-4). Tiles have been tested on the iOS Simulator only. A Keychain setting survives uninstalling on a simulator: if tiles do not appear, check that Face ID is on in Settings.
