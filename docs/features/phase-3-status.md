# Status against DEVELOPER_CHECKLIST.md: Phase 3 (31 Oct 2026)

"Proven" means a test or a real run shows it.

| Ticket | State |
| --- | --- |
| P3-01 Matches and presets | Proven at the database. Presets are rows staff can change. Organizers pick one on Match rounds until the first score is in |
| P3-02 Match generator | Proven by property tests in `packages/match_engine`, over 1,000 random rosters. Mixed pairs work in the engine, but the screen does not offer them: no profile field holds gender |
| P3-03 Scores | Proven at the database: the trigger checks every score from any path. 24-hour expiry, organizer decision, attendance check and retry safety are tested. The organizer's decision was walked through on the simulator |
| P3-04 Rating engine | Proven at the database and with two players confirming at once. Elo with the owner's K factor. Self-declared level only sets the starting rating |
| P3-05 Profile and history | History chart, band plus number, provisional note. R-STA-1 and R-STA-2 statistics by scoring level are not built, because nothing yet records point-by-point scoring |
| P3-06 Tournaments | Knockout and groups with knockout tested at every size from 3 to 33, round robin at 3, 4, 5, 8, 9, 16 and 33. Parallel entries on the last place tested. Corrections and retirements tested. Staff use the Scores screen in the admin app (Q53) |
| P3-07 Leaderboards | Proven at the database: hourly snapshots by sport and country, minors out unless a guardian opts in. Rules in R-LDR-1 and R-LDR-2 beyond the checklist are not built (Q54) |
| A-05 Rules | Proven at the database. The screen builds and analyses, but **the admin web app has still never been opened in a browser** |

## Differences from the plan

- `match_players` was not added. `side_a` and `side_b` on `matches`, `match_scores` and `match_results` already name the players, and a gin index covers lookups.
- `level` on `player_sports` now follows the rating. It is still the column leaderboards, seeding and groups read, so nothing else had to move.
- Tournament matches are checked game by game, not by best-of, because organizers choose how many games each stage plays.

## Fixed along the way

- The admin menu only ever listed the audit log, so Reports, Users and Sports could not be reached. This is why opening it in a browser matters.
- `discover_players` applied its limit before ranking, so the best fits could be left out.
- Editing a level scale failed, because the audit trigger could not name the row.

## Independent review, 31 Oct

An AI reviewer who had not seen the work ran attacks against the local stack and confirmed 18 of its 19 numbered findings; the other one and the low-risk ones came from reading. All are fixed in `20261103110000_review_fixes_3.sql` and the app, with tests in `22_review_fixes_3_test.sql`. The worst were an organizer confirming their own score without the other side, a host rating themselves through a tournament of their own, the same match rated twice, and `meet_rounds` showing a minor's real id.

A second review of those fixes found more, all fixed in `20261103120000_review_fixes_4.sql` with tests in `23_review_fixes_4_test.sql`. The worst were a host erasing their own loss by flipping attendance, and any player reading a minor's real id through a fake score, so clients now read scores only through `score_view`, `my_meet_results` and `meet_disputes`.

Known limits left in place:

- A rematch with an identical score in the same Meet is refused, and so is any new score between the same sides while one is open. Without scores tied to rounds, this is what stops one match being entered twice.
- Results held for attendance and two friends running their own tournament are open questions (Q58, Q60), as is one partner confirming for both (Q62).

A person still needs to review all of this. Nothing here has been reviewed by a person or an outside tester.
