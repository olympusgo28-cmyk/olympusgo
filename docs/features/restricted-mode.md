# Age paths, restricted mode and parent links

**What it does.** Works out each player's age group and keeps under-18s without a parent inside a small shell until a parent links their account.

**Who can use it.** Everyone gets an age group. Only people 18 or over can be a parent.

**Files.** `supabase/migrations/20261101100000_identity_age.sql`, `20261101130000_safety_gate.sql`, `lib/features/guardian/`.

**Data.** `guardian_links`, `guardian_link_codes` (hashes only), `guardian_code_attempts`. Age is never stored: `private.audience_of` works it out from the birthday and `country_config` on every read. An unknown age counts as restricted.

**Steps.** Child asks for a code. Parent types it (`guardian_code_redeem`), which makes a pending link and changes nothing for the child. Parent approves (`guardian_link_decide`). Parent can revoke at any time. The link ends at 18; a daily job gives 30 days' notice.

**How the database enforces it.** Most reads go through security definer functions, which skip RLS, so a policy alone would not stop a child. `private.gate_request` runs before every API call (set with `pgrst.db_pre_request`) and refuses a restricted player any path not in `private.restricted_allow`. A new function therefore starts out refused. Restrictive policies refuse the same tables for Realtime and Storage, which do not pass through the gate. Functions that return people mask or drop minors; `player_json` does this for every club, team and academy list.

**Rules and where the numbers live.** Age limits in `country_config`. Code lifetime and notice in `app_settings` (`guardian.code_hours`, `guardian.end_notice_days`). Lockout in `auth.code_lock_attempts` and `auth.code_lock_minutes`.

**How to change it.** To let restricted players reach something new, add its path to `private.restricted_allow` in a new migration.

**Tests.** `supabase/tests/02_age_test.sql`, `03_guardian_test.sql`, `08_gate_test.sql`, `09_minors_test.sql`, and the live API test in `test/supabase_play_local_test.dart`.

**Accounts need a mobile.** An account with no verified mobile is restricted, however old it says it is. This is what stops a child making an email-only adult account to approve their own link. It lives in the database so it holds whatever the sign-up settings are.

**Known gaps.** A person can still lie about their birthday, and a child with a second phone can pose as a parent (Q43). Several older functions that return names have not been audited; see `phase-1-status.md`.
