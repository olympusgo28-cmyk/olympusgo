# Status against DEVELOPER_CHECKLIST.md: Phase 4d (1 Nov 2026)

"Proven" means a test or a real run shows it. Voucher money runs against a **local stand-in for Stripe**, and `game.campaigns` and `game.organizer_rewards` stay off. Games keep being recorded with both off. What's earned once payments are open is issued when rewards open, and games before that rank their group and earn nothing (Q158).

| Ticket | State |
| --- | --- |
| P4d-01 Campaign engine | Proven at the database and on a simulator. Data-driven campaigns and quests, rewards in one transaction, a retry issues nothing twice, and no rating moves. |
| P4d-02 Organizer rewards | Proven at the database. The milestone function is tested for games 1 to 40, and the counted rule row by row. |
| P4d-03 Voucher wallet | Proven at the database, through the real API and on a simulator. Wallet, expiry, one discount per item, and every use logged with who, which shop and when. The code goes only to its owner. |
| P4d-04 Game tab | Campaign list, campaign page with progress, wallet and organizer rewards, with widget tests. |
| A-09 Campaigns admin | Campaigns, voucher types, organizer games and redemptions, with widget tests and a run in the built web app. |

## Not built

- Voucher B redemption, since courts aren't booked in the app (Q25, Q153). It's issued and held.
- Workout, creator and camera challenges, which stay Later and hidden on a real build.
- Partner agreements. No shop or hall has agreed to fund a voucher yet.

## Differences from the documents

- The organizer earns the rewards, and needn't pay or play unless they want to count towards the 6 (Q154).
- The ladder carries on after game 24 (Q155).
- Club reward is removed (Q156).
- A game is judged from live data once attendance has closed for the day and its money has released, not the first-save log, so a refunded fee doesn't count as paid and a Meet nobody pressed save on is still judged.
- Voucher types are set by payments staff, not content staff as planned, because the amount comes out of a shop's money (Q164).
- Games before payments open rank their group and earn nothing (Q158).

## Known gaps

- With commission on top, a voucher makes the Items line drop a little, because commission follows the price after the voucher. The total is right.
- "Use by" and game dates show in the device's time zone, like the rest of the app, not the venue's.
- `field_registry` from the Definition of done doesn't exist in this repository, so no new column is registered.
- The admin creates one quest per campaign. The database and the app take several.
- A game that counted stays counted if a payment is undone later (Q160).

## Walkthrough, 1 Nov

On iPhone 17 Pro against the local stack and the Stripe stand-in: a seed player joined a campaign, a scanned past session finished the quest, and the sweep issued the voucher. It showed in My vouchers with its use-by date and code, came off a S$100.00 racket at checkout to S$92.00, and the test payment went through. Cancelling refunded S$92.00, put the stock back and returned the voucher once. The ledger summed to zero.

In the built admin, as seed staff with MFA: added a voucher type as the organizer reward, created a campaign, published it, and saw a redemption with who, which shop and when, and no code. An end date of 30 Nov saved as 23:59:59 Singapore time.

Not walked through: a real organizer scanning six paying players on phones. The counted-game rule is proven in pgTAP and the race script, with payments set up by SQL.
