# Status against DEVELOPER_CHECKLIST.md: Phase 5d (2 Nov 2026)

"Proven" means a test or a real run shows it. **No real check has run: no frame or hash-matching provider, and no video host, is chosen.** `video.feed` stays off, and on a hosted stack a post can only fail.

| Ticket | State |
| --- | --- |
| P5-06 Video feed | Built behind stand-ins. Proven at the database, through the real API and Storage, in a race script with a negative control, and in widget tests |
| First posts queue | Proven at the database and in widget tests |

## Not built

- Children's content: results, badges and parent-reviewed clips (Q225). Q180 outranks the checklist's line.
- Comments. Reactions only, by your choice.
- Shop video, removed in 4b.
- A Cloudflare Stream adapter, or any real checker (Q214).
- Reporting a match to the authorities (Q213).

## Differences from the plan

- `52_deletion_queue_test.sql` is the sweep's own test, so the feed's is `53_feed_test.sql`.
- `post_retry` is new, so a post whose checks failed isn't stuck.
- `feed_status` joined the allow lists, so a restricted child's app can ask whether it has a feed.
- The caption column is `body`, so `private.check_text` reads it.
- Posters are signed in a batch for a list, through `post_posters`.

## Differences from the documents

- No board covers an adult feed or the post screens, and the `VideoFeedTeen` canvas is private, so they're built from the kit.
- `field_registry` from the definition of done doesn't exist in this repo, so no column is registered.

## Known gaps

- **A child in an adult's post.** After the first 3 posts, only the tick and reports catch it (Q212).
- **Nothing proves the checks work.** The fake passes everything it's told to. Detection, match accuracy and real outages are unmeasured.
- **Deleting an account mid-check** cascades the job away, so that video is never matched, though nobody could see it. The deletion job must wait for open checks (Q208).
- A link outlives a block or hide by up to 5 minutes.
- Checks read captions and sampled frames, not speech, on-screen text or what falls between samples.
- The admin web player may not play a phone's MOV or HEVC (Q220).
- The phone can't read a video's length, so it sends the maximum and the worker fails one that runs over. That happens only after upload.
- A post's stated seconds are therefore not real, so no screen shows them.
- `feed_svc_result` locks post then case, and `staff_case_decide` case then post. A deadlock aborts one side and fails safe.
- An upload needs the app open. Closing it leaves the post to be removed after a day.
