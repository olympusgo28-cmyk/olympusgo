# Status against DEVELOPER_CHECKLIST.md: Phase 4d (1 Nov 2026)

"Proven" means a test or a real run shows it. Voucher money runs against a **local stand-in for Stripe**, and `game.campaigns` and `game.organizer_rewards` stay off. Games keep being recorded with both off. What's earned once payments are open is issued when rewards open, and games before that rank their group and earn nothing (Q158).

| Ticket | State |
| --- | --- |
| P4d-01 Campaign engine | Proven at the database. Data-driven campaigns and quests, rewards in one transaction, a retry issues nothing twice, and no rating moves. |
| P4d-02 Organizer rewards | Proven at the database. The milestone function is tested for games 1 to 40, and the counted rule row by row. |
| P4d-03 Voucher wallet | Proven at the database. Wallet, expiry, one discount per item, and every use logged with who, which shop and when. The code goes only to its owner. |
| P4d-04 Game tab | Campaign list, campaign page with progress, wallet and organizer rewards, with widget tests. |
| A-09 Campaigns admin | Campaigns, voucher types, organizer games and redemptions, with widget tests. |

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
