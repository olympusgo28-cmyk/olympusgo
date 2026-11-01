# Status against DEVELOPER_CHECKLIST.md: Phase 4d (1 Nov 2026)

"Proven" means a test or a real run shows it. Voucher money runs against a **local stand-in for Stripe**, and `game.campaigns` and `game.organizer_rewards` stay off. Games keep counting with both off, so what's earned before launch is issued when rewards open.

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
- A game is judged from live data once its money settles, not the first-save log, so a refunded fee doesn't count as paid.
