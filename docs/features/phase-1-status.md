# Status against DEVELOPER_CHECKLIST.md (30 Oct 2026)

This is the honest position, ticket by ticket. "Proven" means a test or a run shows it.

## Phase 0

| Ticket | State |
| --- | --- |
| P0-01 Tooling | Done, except Android licences (a person must accept them) |
| P0-02 Repo and CI | Workflow written, never run on GitHub. Branch protection not turned on |
| P0-03 First compile | Proven on the iOS Simulator. Android not built: its licences need accepting first |
| P0-04 Local Supabase | Proven |
| P0-05 Test harness | Proven. The old `catalog_status_check.sql` did not exist here |
| P0-06 Design tokens | Proven by test. Fonts fetched at run time, not bundled |

## Phase 1

| Ticket | State |
| --- | --- |
| P1-01 Database foundation | Proven, including 20 parallel joins on 10 spots |
| P1-02 Mobile sign-up | Proven against the local stack. A real SMS provider is not connected |
| P1-03 Age paths | Proven for 12, 13, 17 and 18 |
| P1-04 Login | Proven through the app's path: identical replies and timing, 5-code lockout under parallel tries. **Direct calls to Supabase Auth bypass it (Q41)** |
| P1-05 Saved accounts and Face ID | Proven on the iOS Simulator with a simulated Face ID match. Not tested on a real phone or on Android |
| P1-06 Recovery | Request recorded. The review screen is A-04 |
| P1-07 Restricted mode | Proven in the app and at the API |
| P1-08 Parent link | Proven at the database and API. The parent's screens have not been walked through in the app |
| P1-09 Create, join, leave, waitlist | Proven at the database and API. "Game is on" seen in the app. The create form's new fields have not been walked through |
| P1-10 QR check-in | Proven at the database. Camera scanning not tested: the simulator has no camera |
| P1-11 Attendance and log | Proven from the app through to the log row |
| P1-12 Security baseline | Partly done. See below |
| P1-13 Internal build | Not done: needs Apple and Google accounts and a crash reporting provider |
| A-01 Admin shell | Not started |

## Independent review, 30 Oct 2026

A separate reviewer read the Phase 1 work. Fixed and tested: a child approving their own parent link through an email-only account (every account now needs a verified mobile), rosters and walk-ins exposing minors, older functions naming minors, lockout races, spoofable IP limits, the session token in plain storage, and public avatars.

Still open from that review:

- **Q41: direct Supabase Auth calls bypass enumeration protection and the lockout. This blocks Gate A.**
- `tournament_register` has no row lock, so a tournament can overfill. Phase 3.
- Messages already in a conversation are not stopped when a parent link ends, beyond the child's own restriction.
- Not confirmed either way: odd URL encodings getting past the rate limit table; `pg_graphql` on the hosted project; timing if SMS or email takes longer than the 900 ms pad.
- Other older functions still return names and were not all audited: `academy_user_name`, `club_announcement_list`, `club_audit_list`, `club_ban_list`, `event_scan`, `team_fixture_get`, `shop_order_json`. Review these for minors.

## Still needed for Gate A

- Q41 above.
- An outside reviewer has to read the policies. The review above was an AI agent, not a person.
- A person has to review every money, sign-in, minors and RLS change. Nothing here has been reviewed by a person.
- Logging: the Dart app still uses `debugPrint`. There is no scrubber yet (P1-13).
- Every older `security definer` function needs its "why" comment (checklist 3.2). New ones have it.
- Raw hex colours remain in about 20 screen files for sport and logo tints.
- The hosted project needs these migrations, and existing accounts with no verified mobile will become restricted when they land.
