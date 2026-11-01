# Status against DEVELOPER_CHECKLIST.md: Phase 4c (1 Nov 2026)

"Proven" means a test or a real run shows it. All money here runs against a **local stand-in for Stripe**. No real Stripe call has been made, and `lessons.checkout` stays off on top of `payments.enabled`.

| Ticket | State |
| --- | --- |
| P4c-01 Academy and coaches | Proven at the database and through the real API. Coach pages, verification with real files, coach invitations that must be accepted, students who are accounts, R-ACD-3 make-ups, and paid trials, single classes and one-to-ones. |
| P4c-02 Assessments | Proven at the database and through the real API. Custom templates, coach assessments, charts. Readable by the player, a minor's parent and the assigning coach. Writable only by that coach. |
| P4c-03 Services referral | Proven at the database and through the real API. Partner list, a leaving sheet, the partner's own link. Five columns, none about a condition. |
| A-08 Academy and services admin | Verification, Lessons and Services sections, with widget tests. |

## Not built

- Monthly and term fees in the app (Q107). They stay direct, so fee invoices stay empty and coach pay stays between the academy and the coach.
- A real check against the NROC or ACRA registers. Staff compare by hand.
- Stripe's own payment sheet, as in 4a and 4b.
- R-ACD-2's SMS after 2 hours, and filming beyond the existing consent switch.
- Vouchers and points on lessons. Lessons earn no points.

## Differences from the documents

- Step 4 of creating an academy now says what's needed, and the real upload follows on the Verification screen straight after, so a licence photo isn't held in memory through the steps.
- ACD-14 marks one-to-one booking as Later. The checklist is newer, and the owner confirmed it on 1 Nov.
- Parents with a typed name can no longer enrol. A child needs an account and a parent link first (owner, 1 Nov).
- Attendance releases money at once, as with a Meet, so a report has to come before the coach saves it (Q114).
- An invited email is held until that person next opens Academy, whether or not it has an account, so inviting can't be used to find out who's registered.
