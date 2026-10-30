# Sign-in

**What it does.** Mobile-first sign-up by SMS code, and log-in by mobile, email or username, with saved-account tiles and Face ID.

**Files.** `supabase/functions/resolve-login/`, `lib/features/auth/`.

**Steps.** The app sends what the person typed to `resolve-login`, which finds the account on the server. Replies are identical for known and unknown accounts and padded to `auth.login_pad_ms`. Five wrong codes lock the target for 15 minutes, counted against a hash of the identifier before the code is checked, so unknown identifiers lock too and parallel tries cannot get past.

**Saved accounts.** `BiometricVault` keeps one token per account. On iOS the token is tied to the current biometric set, so enrolling a new face or finger drops it and a code is needed. Each save deletes first, because updating a protected Keychain item would prompt for Face ID on every token refresh. The live session sits in the Keychain too (`SecureSessionStorage`), not in app preferences. Supabase's sign-out always ends the session on the server, so while a tile exists `SessionHttpClient` stops that one call and sign-out clears this device only.

**Rules and numbers.** All in `app_settings` under `auth.*`.

**Security notes.** The service-role key is used only in the Edge Function. Identifiers are hashed with `LOGIN_HASH_PEPPER` before they reach the database. Logs carry status codes only.

**Tests.** `supabase/functions/resolve-login/logic_test.ts`, and the mobile journey in `test/supabase_play_local_test.dart`.

**Known gaps.** **Direct calls to Supabase Auth bypass all of this (Q41).** Android has no tie to the biometric set, because its equivalent would prompt on every token refresh, so a new fingerprint there does not force a code. No CAPTCHA after repeated requests (R-ACC-4). Tiles have been tested on the iOS Simulator only. A Keychain setting survives uninstalling on a simulator: if tiles do not appear, check that Face ID is on in Settings.
