# Status against DEVELOPER_CHECKLIST.md: Phase 4b (1 Nov 2026)

"Proven" means a test or a real run shows it. Everything here runs against a **local stand-in for Stripe**. No real Stripe call has been made. `payments.enabled`, `shop.checkout` and `points.earning` all stay off by default. Courts stay out (Q25): P4b-01 is not built.

| Ticket | State |
| --- | --- |
| P4b-02 Shop catalogue | Proven. Partner shops only, each linked to one owner's account. Commission is 10% by default, taken out of the price, with a switch per shop to add it on top. The player marketplace is gone: player shops, delivery, addresses, returns, vouchers, live selling and shoppable video. Moderated listings are now hidden, and a report stores the product's id |
| P4b-03 Checkout | Proven through the real API. One order per shop, final price before paying, points or nothing as the discount, PayNow or card, a 10-minute hold, and a changed price refuses rather than charges. 50 buyers on the last unit: one gets it |
| P4b-04 Handover | Proven through the real API and a race script (cancel, collect and sweep at once, 25 rounds). "Yes, I got it all" releases the payout, "Report a problem" holds it for staff, and the timer releases a ready order 48 hours after the collection date, or 48 hours after it was marked ready if that's later. An order the shop never marked ready doesn't release itself: the buyer can still cancel or report, and staff decide. Each order's money moved once in every round |
| P4b-05 Points | Proven at the database and through the API. Append-only lots, oldest first, 12-month expiry, half the commission per item, returned once. Two carts can't spend the same points. **Earning is off** and nobody earns until the owner sets `points.weekly_cap_minor` and `points.redeem_min_account_days` (Q13) and switches `points.earning` on |
| A-07 Shop admin | Proven in a browser on 1 Nov against the local stack: shops, products, a stock change, and a handover report refunded by line, through `admin-action` to the worker. Commission switch, owner link and points block are covered by pgTAP and widget tests, not clicked in a browser |

Walked through on the iPhone simulator on 1 Nov: browse, buy with points, pay, cancel (money, stock and points all came back), collect (S$8.10 of S$9.00 to the shop), report a problem, and the owner's list and Mark ready.

## Not built

- Vouchers (4d), so "one discount per item" is only half exercised.
- Court booking (Q25).
- Stripe's own payment sheet, as in 4a: `canCollect` is false on a hosted project.
- A partner's own login to the admin app. Owners use the phone app, and staff enter the catalogue (owner, 1 Nov).
- Creator commission on the Shop.
- Shop sales as rows in the owner's Earnings. The totals include them, the list shows activities only.

## Differences from the documents

- A buyer using two shops pays twice (Q84).
- Late money after a Shop hold ends is always refunded in full, unlike Meets, because the stock or points may have gone (Q85).
- The creator profile's videos no longer open a shop video, since shoppable video is gone.
- "Report this shop" is now "Get help with this shop", because reports hang on a listing's id.

## Not proven

- Real Stripe behaviour.
- The lawyer's check on "final once collected" (Gate D).
- Two human reviewers, which `AGENTS.md` requires for money. Reviews so far are by independent agents: three reviewed the build and found about 60 issues, two more reviewed the fixes and found about 40, and a last one found 5, all fixed, tested or recorded in `OPEN_QUESTIONS.md`. `supabase/tests/40_shop_review_test.sql` holds a test for each server bug.
