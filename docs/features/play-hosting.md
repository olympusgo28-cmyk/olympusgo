# Hosting a Meet

**What it does.** Create, join, leave and waitlist, QR check-in, attendance and the counted-game log.

**Files.** `supabase/migrations/20261101110000_sports_catalog.sql`, `20261101120000_play_core.sql`, `lib/features/play/`, `lib/features/scan/`.

**Joining.** `join_activity` is the one way in. It locks the activity's row, so capacity cannot be overrun, and returns `joined`, `requested` or `waitlist`. Every path that frees or takes a seat holds the same lock. `private.promote_waitlist` moves the next eligible person in, skipping anyone blocked by the host, anyone restricted, and a pair when one seat is free.

**Queue order.** `queue_seq` is taken under the lock, so ties cannot happen, and given again on rejoining.

**QR.** `player_qr_tokens` holds an opaque token with no client access. `rotate_my_qr` replaces it. The QR text is `olympusgo:player:<token>`. Only a host's scan of a live token counts as `qr` in the game log. A player or parent checking in through the Meet's code is recorded as `self` or `parent`, because nothing proves a scan happened, and vouchers depend on this.

**Attendance.** `save_attendance` writes one row to `campaign_game_log` on the first save. Later changes go to `attendance_audit`. Both are append-only, and neither links to `auth.users`, so they outlive a deleted account. Treat those ids as personal data in the retention schedule.

**Rules and numbers.** Fee in `fee_rules`. `meet.attendance_opens_minutes` in `app_settings`. `payments.enabled` and `campaign.require_paid` in `feature_flags`.

**Tests.** `supabase/tests/04_catalog_test.sql`, `05_play_test.sql`, `06_qr_test.sql`, `07_attendance_test.sql`, and the 20-parallel-joins race in `test/supabase_play_local_test.dart`.

**Known gaps.** The price is shown and the host is paid directly: no money moves until Phase 4a. `min_players` for a Meet uses the checklist's values from the format.
