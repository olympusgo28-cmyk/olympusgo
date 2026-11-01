# Status against DEVELOPER_CHECKLIST.md: Phase 5b (1 Nov 2026)

"Proven" means a test or a real run shows it. Plans come from a **local stand-in**, not the real model, and `fitness.ai_plans` stays off.

| Ticket | State |
| --- | --- |
| P5-05 AI plans | Proven at the database, through the real API and Edge Function with the stand-in, and in widget tests. The Claude adapter is tested against a fake server only. |

## Not built

- AI plans for under-18s (Q181).
- A staff screen for AI plan cost. Tokens and model are stored for A-10 in 5c.

## Differences from the documents

- No board or rule covers these screens, so they're built from the kit (Q190).
- The plan sets no weights (Q186).
- The PRD lists "AI coaching tips" as out of launch scope. The checklist is newer and asks for AI plans.

## Known gaps

- Real plan quality and real cost are unmeasured. The US$ estimates given to the owner were not measured.
- The lawyer hasn't checked the consent wording or the overseas transfer (Q188), and the provider's data terms for this account aren't checked (Q189).
- Withdrawing stops any further send at once, including a second try. It can't recall a call already under way.
- A plan in progress survives leaving the screen, and the next visit opens it. It doesn't survive closing the app, so asking again can use a second daily plan.
- A plan can be up to 2 model calls, so one player's daily limit of 3 can be up to 6 calls. A call that fails or times out records no tokens.
- The 120-second timeout is a guess until real calls are measured.
- The JSON schema hasn't met the real API. One real call is needed before the flag goes on, because a schema error would fail every request.
- The word check on plan names is a short list, not a full filter.
- The stand-in's plan is fixed and doesn't use the player's goal.

## Walkthrough

On an iPhone 17 Pro simulator against the local stack, with the stand-in writing plans:

- An adult saw the consent screen before their first plan, and agreed.
- Make my plan opened a draft with the AI note and no weights.
- Back squat took a 60 kg weight in the builder, and the workout started with it.
- Turning AI plans off in Privacy and safety was recorded in the database, and turning it on again asked again.
- The agree and make-a-plan path was repeated on the final code. Withdrawing was tested on it by API and widget tests.

The real Claude call has only met a fake server.
