# Status against DEVELOPER_CHECKLIST.md: Phase 5c (2 Nov 2026)

"Proven" means a test or a real run shows it. **The worker's accuracy isn't proven: no real game has been through it.** `video.analysis` and `video.analysis_minors` stay off.

| Ticket | State |
| --- | --- |
| P5-01 Private video storage, consent, purge | Proven at the database, through the real API and Storage, in a race script with a negative control, and on the simulator |
| P5-02 Analysis worker | Built. Proven as a pipeline in the real container on a made-up clip, and by unit tests and a noise simulation. Not proven on a real game |
| P5-03 Screens | Proven in widget tests and on the simulator, with the local stand-in as the worker |
| A-10 Jobs monitor | Proven in widget tests and a click-through in the built web app |

## Not built

- Rallies in the report (Q199).
- A shuttle or racket model of any kind.
- Doubles (Q203).
- Playback. Nothing with a person in it is kept beyond the clip, apart from one court still that goes with it.
- A report for the child themselves (Q205).

## Differences from the plan

- Good-Badminton's `tracking/player.py` isn't reused. The worker has its own short tracker in `metrics.py`, because the reuse brought more than it gave. Only `court/` is vendored.
- A first tracker kept several paths per person. Review and a simulated 3-minute rally showed noise splitting one player into many paths and losing nearly half the distance, so it was replaced by one that follows a single player. In the simulation it keeps nearly all sightings and reads about 10% low at low noise, and up to 7% high at high noise.
- No percentage during upload, because the Storage client doesn't give one.

## Differences from the documents

- No board or rule covers these screens, so they're built from the kit.
- "Blurred clips may train" is gone from the filming screen (Q200).
- Adults' clips follow the 90-day rule too (Q197).

## Known gaps

- **Accuracy.** The only real pose run was a photo pasted onto a drawn court. Everything in Q209 is a guess until about 10 real clips are tested.
- **A change of ends isn't noticed.** The player picks one side for the whole clip. If the players swap ends, the worker follows whoever is then on that side, so the report would hold the opponent's movement. The set-up screen says no change of ends, and that's the only guard.
- Court detection took a drawn net for the far baseline, so the player's corner check matters. Real courts are untested.
- Real iPhone files are untested in the worker: HEVC, rotation, variable frame rate.
- Speed here is CPU through Colima: 19 seconds of work for a 5-second clip. A 3-minute clip would take about 11 minutes against a 15-minute limit. A GPU host, hosted speed and real cost are unmeasured.
- The phone can't read a clip's length, so it sends the maximum and the worker's measure replaces it. A clip that's too long is refused only after it has uploaded.
- An upload needs the app open. Leaving the screen doesn't stop it, but closing the app does, and the clip is left waiting to be deleted.
- A 200 MB upload on a phone network is unmeasured.
- The corner dots can be read by a screen reader but not moved by one.
- A second linked parent can read a clip, withdraw, keep and delete it, but only the parent who added it marks the court.
- Gate F needs the lawyer (Q198, Q211) and the licence check on the model weights (Q179).
- Two human reviews are still needed before anything here ships, and nothing has been through CI.

## Walkthrough

On an iPhone 17 Pro simulator against the local stack, with `video.analysis` on for the walkthrough and off again after:

- "Analyse my game" appeared in My workouts, and a report from the real container opened from My clips.
- A clip from the library uploaded, and the stand-in's court frame came back with the corners on it.
- Dragging a corner moved it, the page didn't scroll, and the moved corner reached the database.
- Near the camera, then Analyse my game, gave a report with numbers and a heatmap.
- Delete clip asked first, and the list updated. The sweep then removed both files from Storage.
- The add, mark, report and delete path was repeated on the final code. A second parent, a child's clip and a flag closing were tested in widget tests, not on the simulator.

In the built admin web app, the jobs monitor showed the queue and a failed job with no clip, frame or name. A retry was refused while the clip couldn't run, then queued the job once it could, and the reason reached the audit log.
