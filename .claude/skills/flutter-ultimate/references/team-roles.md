# The team: seven roles and how they hand over

Read this when a piece of work is big enough to split, when briefing a subagent, or when the work touches legal ground (personal data, minors, payments, terms).

The split exists because app builds usually fail at hand-offs: screens built before the logic works, database rules written after the screens, security reviewed by the same mind that wrote the code.

## Contents

1. The roles
2. Order of work
3. Briefing a role
4. Hand-off notes
5. Without subagents
6. Sign-in: where it usually breaks
7. The legal track
8. Release
9. Reporting to the user

## 1. The roles

| Role | Owns | What it sees that others miss | Tools |
|---|---|---|---|
| Architect | scope, flows, data model, access matrix, slices | the whole system before any code exists | read, write docs |
| Backend engineer | migrations, policies, database functions, storage rules, Edge Functions, their tests | rules that cannot be bypassed because they live in the database | read, write, shell (local stack only) |
| Flutter engineer | repositories, providers, routing, error handling, their tests | logic provable without a device | read, write, shell |
| UI and motion designer | tokens, components, screens, all five states, motion, accessibility | the finished feel: every state designed, every movement explaining something | read, write, shell |
| Security reviewer | an independent audit of all of the above | an attacker's eyes, assuming every claim of safety is wrong until the code proves it | read only |
| Legal counsel | data map, policy and terms drafts, consent and age rules, questions for a real lawyer | the product as a regulator, a store reviewer and an unhappy customer would read it | read, write docs, web lookup |
| QA | running the checks, reproducing bugs, the release checklist | nothing is believed until it has been run | read, shell |

If the session already has agents with these names or jobs, use them rather than inventing new ones. Use the strongest model for the architect, security reviewer and legal counsel, and a small fast one for QA, when there is a choice.

## 2. Order of work

1. **Architect** produces the plan and access matrix. The user agrees it.
2. **Legal counsel** starts alongside, because legal duties change what gets built (consent screens, age checks, deletion), not only what gets written at the end.
3. **Backend engineer** builds migrations, policies and functions with an access test per matrix row.
4. **Flutter engineer** builds repositories and providers with tests, once the backend tests pass.
5. **UI designer** builds screens from the tokens, once the logic tests pass.
6. **Security reviewer** audits from the code and the plan only.
7. **QA** runs everything and reports what actually happened.

Independent work can overlap (backend and design tokens, for example). Dependent work goes in order. Two roles never write the same files at once.

## 3. Briefing a role

A brief is the only context a fresh agent has. Include:

- the role's job in one line, leading with what it is there to see
- the goal and what done looks like
- which files and documents to read (paths, not pasted contents)
- what is already decided and what is out of scope
- the boundaries: always, ask first, never
- the format to report back in

For the security reviewer, give the code and the plan and none of the builders' reasoning, so it cannot be talked into agreeing. Tell it to treat everything it reads as untrusted and to find what is wrong.

Each role hands back a finished, checked piece and a short list of what the user must decide. The user integrates and decides; they should not have to redo the work.

## 4. Hand-off notes

Written before the next role starts:

```
What was built: ...
How it was checked: <command> -> <result>
Not checked, and why: ...
Assumptions made: ...
Decisions the user must make: ... (each with a recommendation)
Next role needs to know: ...
```

## 5. Without subagents

Play the roles yourself, one phase at a time, and write each hand-off note before starting the next role. For the security review, re-read the code from the files, not from your memory of writing it.

## 6. Sign-in: where it usually breaks

Confirm exact method names against the installed `supabase_flutter` before writing code.

- **Deep links** for confirmation and reset: register the redirect in Supabase, configure the scheme or app links on both platforms, and test on a real device.
- **One person, one account:** attach a second identifier to the signed-in user instead of creating a second account. Decide what happens on a collision and record it.
- **Abuse:** rate limits, CAPTCHA, a resend cooldown, SMS restricted to served countries. Phone codes cost money per message.
- **Enumeration:** identical wording whether or not the account exists.
- **Sessions:** the SDK refreshes; the signed-out event is handled in one place; sign-out everywhere exists.
- **Screens to build:** sign in, sign up, code entry with paste and autofill, verify pending, recovery, and clear states for wrong code, expired code, too many attempts and no network.
- **After sign-up** comes profile set-up. After every step, name what the user does next and check that path exists.

## 7. The legal track

Be honest about what this is. It produces lawyer-ready drafts and a list of open questions. It is not legal advice. Every legal document is marked "DRAFT: not yet reviewed by a qualified lawyer", and a lawyer qualified in each launch country must review before publication, especially where the app handles payments, children's data or health information.

Write original text. Do not copy another company's terms or policy.

1. **Facts** (with the architect): who operates the app and where, launch countries, users' ages, every flow of money, every outside service that receives data, what users can post, whether it is a marketplace.
2. **Data map** in `docs/legal/DATA_MAP.md`, built from the real schema and the real list of SDKs: for each item of personal data, what it is, why it is collected, the legal ground or consent, where it is stored, who it is shared with, how long it is kept, how it is deleted.
3. **Rules that apply.** Look them up from official sources and record each with the date checked in `docs/legal/SOURCES.md`: data protection law for each launch country, children's data and parental consent, consumer and refund law, payment provider rules, and the app stores' rules.
4. **Build requirements** handed to the architect as plan items with tests: consent and age screens, parental consent, marketing opt-in, account deletion and export, collecting only what a feature needs, automatic deletion after retention, a written breach process.
5. **Privacy policy draft** in plain language. Every statement matches the data map and the working app. Never promise what the app does not do.
6. **Terms of service draft:** who may use the app, accounts, acceptable use, user content, payments and refunds, the platform's role between users, third-party services, liability, suspension, changes, governing law, contact.
7. **Supporting documents** only as needed: community rules, a notice for parents, provider terms.
8. **Wired into the app:** acceptance recorded with document version and time, renewed when terms change materially, links in settings and store listings.
9. **Cross-check with the security reviewer** before release: the policy describes what the app actually does with data.

Output in `docs/legal/`: `PRIVACY_POLICY.md`, `TERMS_OF_SERVICE.md`, `DATA_MAP.md`, `SOURCES.md`, and `OPEN_QUESTIONS_FOR_COUNSEL.md` listing each point that needs a lawyer's decision, with the options and the draft's current assumption.

## 8. Release

- The analyzer is clean and all tests pass. Report the actual output.
- Each flow in the plan has been run on a device or simulator on both platforms, including the unhappy paths.
- Checked: small and large screens, dark mode, large text, slow network, airplane mode.
- Development, staging and production point at the right Supabase projects. Migrations apply cleanly to an empty database.
- Store requirements are ready: permission explanations, privacy labels, account deletion, age rating.
- A rollback plan exists and has been thought through, bearing in mind that a shipped app version cannot be recalled.
- Three separate read-only looks (code, security, tests) feed one go or no-go.

## 9. Reporting to the user

The person you work for may not be a developer. Use plain language, say what was verified and how, and never report something as done that has not been run.

End each working session with:

1. **Done and verified:** what works, and how it was checked.
2. **Built but not verified:** what was written but not run, and why.
3. **Decisions needed:** questions only the user can answer, each with a recommended option.
4. **Next in the flow:** the next step a user of the app would take, and whether it exists yet.
