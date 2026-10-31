# Status against DEVELOPER_CHECKLIST.md: Phase 4a (1 Nov 2026)

"Proven" means a test or a real run shows it. Everything here runs against a **local stand-in for Stripe**. No real Stripe call has been made, so Gate C's "4a done in Stripe test mode" is not met. `payments.enabled` stays off by default.

| Ticket | State |
| --- | --- |
| P4a-01 Money tables and ledger | Proven at the database. Append-only double-entry ledger, balanced at commit, with a refund cap on price and fee separately. Clients read only their own payments and refunds |
| P4a-02 Quotes | Proven: one test per row of the fee and refund tables, including court and shop rows |
| P4a-03 Stripe | Interface, signature check and stand-in proven. The live adapter is written, refuses anything but a test key, and has never run. Connect onboarding, SetupIntents and the app's Stripe sheet wait for test keys |
| P4a-04 Payment flow | Proven through the real API and Edge Functions with the stand-in. The webhook is the only thing that confirms a payment. 50 players on the last spot: one gets it. The same event sent 20 times at once: one ledger entry. Meets and tickets only. **Paid tournament entries stay closed**, behind `payments.tournament` |
| P4a-05 Hold and release | Proven at the database, including a real race between a refund and a release (25 rounds) |
| P4a-06 Refunds | Proven at the database, and parallel refunds through the API. Failed refunds go to staff to retry, void or record as a bank transfer |
| P4a-07 Payouts | Proven at the database. Weekly run, one approver up to S$5,000, a second different approver above, fees owed netted first |
| P4a-08 Reconciliation | The comparison and alert are proven, including an injected mismatch. Against real Stripe data it has never run |
| P4a-09 Scan | Proven at the database: player, group, venue and vendor codes, rotation, blocks, no minor can resolve. Group managers and verified vendors can show their code in the app. Venue codes exist only as a staff function, with no admin screen. There's no separate Pay mode: scanning a vendor or venue opens their page and charges nothing |
| A-06 Payments admin | Widget tests with a fake API only. **The admin web app has still never been opened in a browser** |

## Not built

- Paid tournament entries, so R-REF-14 to R-REF-16 exist as quotes with no flow.
- R-REF-18, refunds on account deletion: nothing deletes an account yet, so there's no hook.
- Court booking and Shop payments (4b).
- Points. Screens that promised them are hidden on a real backend until 4b. The demo mode still shows them.
- Stripe's own payment sheet in the app. `canCollect` is false on a hosted project, so even with the flag on the app says paying isn't open, rather than holding a spot it can't take money for.
- Adding a guest to a paid spot you already hold (Q80).

## Differences from the documents

- Tables are in `public` with helpers in `private`, as `AGENTS.md` says, not in a `money` schema as `DATA_MODEL.md` drew them.
- `vendors`, `payouts` and `payout_items` come from the checklist. `DATA_MODEL.md` had none.
- A host who paid only the fee, and a player leaving an organizer-pays Meet, both return the S$2.00 with no card fee on the organizer.
- Payouts are weekly only. The on-demand "Pay out now" and instant PayNow screens are gone until someone decides they should exist, since R-PAY-2 needs staff approval.

## Stripe facts checked against its docs, 1 Nov

- PayNow QR codes last 1 hour, so a 10-minute hold leaves a window for late money (Q64).
- PayNow can't be charged off-session, so organizer-pays needs a saved card.
- PayNow refunds must be sent within 90 days, and a failed one has to be repaid another way (Q67).
- PayNow has no chargebacks.
- Stripe lists PayNow as unsupported for in-app payments (Q79), so the real flow may be a hosted page.

## Independent reviews, 1 Nov

Two reviewers who hadn't seen the work reported about 50 issues between them, with some overlap. Each is fixed in `20261104130000_money_review_fixes.sql`, the Edge Functions or the app, or is listed under "Not built" or in Q80 to Q83. Each fix has a test in `34_money_review_test.sql`. The worst:

- A failed status report, a timeout or a Stripe 5xx counted as a failed Stripe call, so a transfer or refund could be sent twice. Only Stripe's plain refusal now counts as failed. Anything unclear stays queued on the same idempotency key, and one worker runs at a time.
- Leaving an event refunded the ticket and left it working.
- Money landing on a given-up payment could seat the player, or charge them twice.
- A dispute during a cancellation could end with the organizer paid and the player not.
- A guest was shown at S$8.00 and charged S$16.00.
- Webhooks carry ids, not objects, so real card fees would never have been recorded. The stand-in had hidden this.

## Fixed along the way

- The balance check ran as the player at commit and refused every refund. Only a real API call showed it.
- The saved-card check on publishing never fired, because it ran under the wrong role.
- Releasing the worker's lease failed on `pg-safeupdate`, which only shows through the real API.
- The app charged a playing host 10% of a paid Meet's price. R-FEE-5 says S$2.00.
- `join_activity` could overwrite an open offer with a waitlist place.
