# Status against DEVELOPER_CHECKLIST.md: Phase 2 (31 Oct 2026)

"Proven" means a test or a real run shows it.

| Ticket | State |
| --- | --- |
| Q41 Sign-in hole | Fixed and retested with the reviewer's own attack. Twilio and Resend senders not run against the real services. Contact migration run on empty tables only |
| A-01 Admin shell | Proven through the API: password, MFA, roles, audit. **The web app has been built but never opened in a browser** |
| P2-01 Discover | Proven on the iOS Simulator, including the map and coarse location. Map tiles use OpenStreetMap's public server, which is not for production traffic |
| P2-02 Main tab | Eight tiles proven. Services and Fitness are empty pages until Phases 4 and 5 |
| P2-03 Groups | Parent approval for clubs and teams proven. **Leagues not built: nobody has said what one is (Q50)** |
| P2-04 Group ranking | Proven at the database. Screen not walked through |
| P2-05 Inbox and chat | Direct messages: optimistic send, retry, delete proven at the database; screen not walked through. Group chat keeps its older send (Q51) |
| P2-06 Push | Queue, settings and quiet hours proven at the database. **Nothing reaches a phone**: it needs a Firebase project |
| P2-07 Moderation | Proven at the database and API. Starter word list only (Q49) |
| A-02 Sports manager | Proven at the database. Screen not walked through |
| A-03 Moderation queue | Proven through the API |
| A-04 Users | Proven at the database. Screen not walked through |

## Differences from the plan

- `report-submit` and `moderate-text` are a table trigger and a database function, not Edge Functions, so no path can skip them.
- `sport_formats.key` keeps its four values, because the app's game types and `activities.game_type` use them.

## Independent review, 31 Oct

An AI reviewer found seven confirmed problems, all fixed and tested: a derivable internal sign-in address that bypassed the lockout, teams bypassing parent approval, owners un-hiding moderated content, one report re-hiding a cleared item, two functions revealing minors' names, suspended players still able to act, and text checks skipping names.

A person still needs to review all of this. Nothing here has been reviewed by a person or an outside tester.
