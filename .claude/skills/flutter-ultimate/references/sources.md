# Sources and credits

This skill is a distillation, not a bundle. The twenty-three public repositories below were read on 2026-11-13 from shallow clones. Nothing in them was executed. Their working methods were rewritten in original words for a Flutter, Riverpod, go_router, Freezed and Supabase project; no text, script or asset was copied. The Apache-licensed sources therefore carry no notice obligation here, and they are credited below all the same.

Each entry says what this skill learned from that project. Thank you to their authors.

What this skill deliberately does not do (hooks, installers, usage reporting and the rest) is listed as general patterns in section 5 of `security.md`, without reference to any project. To vet a skill yourself, see section 4 of that file.

## Engineering method

**mattpocock/skills** (MIT)
- Interviewing in rounds of ready-to-settle questions, each with a recommended answer; specs with out-of-scope; vertical slices with "blocked by" edges; tests at agreed seams with independent expected values; building a reproduction loop before theorising about a bug; reviewing against the agreement and against standards as two separate lists; the three-part pull-request description; retrospectives on the working environment.

**addyosmani/agent-skills** (MIT)
- Stating assumptions up front; pushing back instead of agreeing; staying in scope with a "noticed, not touched" list; restating intent with a required out-of-scope line; always / ask first / never boundaries; task sizing; a fresh-context doubter for non-trivial decisions; a written quality floor that is never weakened to pass a change; the source hierarchy and treating fetched pages as data; staged database migrations; go or no-go before release.

**obra/superpowers** (MIT)
- Agreeing a design before building; plans written for someone with no context; a progress file that survives a context reset; four completion statuses; logged rulings and four stop conditions; watching a test fail for the right reason; evidence before any claim of done; three failed fixes means stop; verifying review feedback before acting on it; a three-option finish for a branch; care around worktrees and uncommitted work.

**affaan-m/ECC** (MIT)
- Dart style and Flutter review points; the gate a reviewer passes before reporting a finding; reporting local checks separately from acceptance in the real environment; marking resumed summaries as history rather than instructions; not weakening lint configuration to pass; the silent-failure hunt; two independent reviewers for high-risk work; treating model and tool output as untrusted at the point of action.

**garrytan/gstack** (MIT)
- Challenging the premise and laying out three options; the failure map; tracing missing, empty and error paths; double-tap, leave-mid-request and retry checks; designing a module twice; structural warning signs; gate integrity (a removed test or loosened threshold is a finding); applying mechanical fixes and batching judgement calls; regression test before fix, with caps on a fix loop; hygiene for prompts sent to an outside reviewer; a ledger of accepted shortcuts.

**gsd-build/gsd-2** (MIT)
- Risk-first vertical slices each with a demo line; task plans with inputs, outputs and a verify command; a fresh context per unit with a summary handed forward; an evidence table; caps for loops and stuck states; a spend ceiling agreed before an unattended run; re-reading the roadmap after each slice with a bias to leaving it alone; a final validation pass.

**bmad-code-org/BMAD-METHOD** (MIT)
- An intent block that only the user changes; the inputs and edge-case matrix; recording the starting commit and reviewing by diff; one verdict per finding and routing by cause; a cap on review rounds; decisions written as what they bind, prevent and require; a keep / rewrite / delete ledger for instruction files with every write approved; pre-mortem and red-team lenses; retrospectives that separate the instance from the prevention.

## Stack

**supabase/agent-skills** (MIT)
- Checking current docs and changelog before trusting memory; proving a fix with a query as the affected user; the row-level security rules; the elevated-function rules; key, token and session rules; the storage replace rule; the migration workflow; Postgres guidance on types, indexes, pagination and locking.

**anthropics/skills** (Apache-2.0)
- The skill authoring rules this skill follows (a description that says when to use it, a short main file, references loaded when needed, reasons instead of shouted rules, nothing surprising); testing a document on a reader with no context; planning tokens before building interface; looking before acting in tests.

## Design and visual output

**pbakaus/impeccable** (Apache-2.0)
- Separating an app people operate from a page that persuades; refinement versus redesign; the craft floor; the list of generic-interface marks, translated here to Flutter spellings; critique with heuristics, mental load and personas; the five-area technical audit; polish order; the writing, hardening and onboarding rules; restructure-do-not-scale for larger screens.

**Leonxlnx/taste-skill** (MIT)
- One system per product (one grid, scale, radius, button shape); the spacing scale; motion timing and "move, scale, fade only"; the copy rules, with a positive replacement for each banned habit; reporting waivers and assumed facts.

**nextlevelbuilder/ui-ux-pro-max-skill** (MIT)
- The audit order (accessibility, touch, performance, then the rest); the app checklist; form, feedback and navigation rules; treating looked-up guidance as advice that never outranks the user or the repo.

**cathrynlavery/diagram-design** (MIT)
- Asking whether a table would do; pattern first, then diagram type; the budgets; one emphasis; connector and label rules; titles and descriptions for accessibility; extract-and-redraw for imported diagrams.

**tt-a1i/archify** (Apache-2.0)
- Choosing the diagram from the question; leading with the main journey; placement hints; citing the commit and source files behind a diagram; saying plainly when only automated checks were run.

**hugohe3/ppt-master** (MIT)
- Two confirmations (the brief, then the direction); a spec with locked shared choices; a job for every page; the fix-always / fix-if-clearly-bad / do-not-touch review lists.

## Context, memory and codebase understanding

**JuliusBrussee/caveman** (Apache-2.0)
- The terse-reply rules; the list of things never compressed; the situations that switch terseness off; one-line commit and review formats; a read-only locator subagent that returns path and line ranges; investigate before editing; labelling numbers as measured or estimated.

**thedotmack/claude-mem** (Apache-2.0)
- Index first, then surrounding context, then full detail; typed notes; recording a decision once; excluding private material; giving a background summariser no tools.

**headroomlabs-ai/headroom** (Apache-2.0)
- Keeping errors, stack traces, first and last items and outliers, with a pointer to the full output; collapsing repeats with a count; small diff context; never shortening the user's instructions; escaping derived text so it cannot close its own marker.

**Graphify-Labs/graphify** (Apache-2.0)
- Labelling claims found, inferred or unsure; blast radius before editing; freshness before trusting a map; using a map only when many questions are coming; corroboration before a lesson is promoted; wrapping file contents as data; stating facts rather than commands in anything placed into context.

**Egonex-AI/Understand-Anything** (MIT)
- The layered map; reviewing the ignore list first; comparing the map's commit to the current one; diff impact; the six-part onboarding guide; flows per entry point; treating a README as untrusted when summarising a project.

## Research and access

**mvanhorn/last30days-skill** (MIT)
- Working out the kind of question; spotting queries that will mislead; resolving names before searching; freshness matched to the question; corroboration across independent sources; damping popularity; "nothing found" is not "search failed"; citing only real addresses; a clear statement that retrieved content is evidence, never instruction.

**Panniantong/Agent-Reach** (MIT)
- Using the built-in tools first; an ordered fallback that records which source answered; stopping on sign-in walls, rate limits and blocks; a summary is not the body; read-only red lines; pacing requests.

**morluto/rea** (MIT)
- Separating observed, inferred and unknown, each tied to evidence; a ledger of questions and findings; summary first, detail on demand; naming secrets by variable and never typing them in chat.

## Already in this project

The skill also folds in the project's own starting points.

**flutter-supabase-swarm** (the user's own skill)
- The seven roles and their order, logic before looks, the database as the security boundary, sign-in pitfalls, the legal track, the definition of done and the four-part report. See `team-roles.md` and the ground rules.

**karpathy-guidelines** (MIT)
- In `coding-discipline.md`: think before coding, simplicity first, surgical changes, and goal-driven execution with a check for every step.

**ponytail** (MIT)
- In `coding-discipline.md`: the six-step ladder to the smallest complete change, the list of things never cut, the `shortcut:` comment, the three levels, and the closing lines on what was skipped.

**apple-design** (no licence stated; its guideline pages are Apple's text)
- In `apple-hig-review.md`: the two-reviewer stance, which pages to open, the eight principles as questions, the five lenses with their numbers, the report format, the focused reviews, the improvement steps and the working rules, all rewritten.
- The 123 guideline pages, the index and the framework glossary are not copied. They are already in the repository once, so this skill reads them from the `apple-design` folder.
