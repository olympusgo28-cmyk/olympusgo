# Coding discipline: think first, change little, prove it

Read this before writing, fixing or refactoring code, and whenever the user says "be lazy", "simplest solution", "yagni", or complains about over-engineering.

It folds in two of the project's own skills: the Karpathy guidelines (four habits that prevent the usual mistakes of a coding model) and Ponytail (the lazy senior developer: the best code is the code never written). Both lean toward caution over speed. For a trivial change, use judgement.

## Contents

1. Think before coding
2. The smallest complete change
3. Surgical changes
4. Goal-driven execution
5. What is never cut
6. Levels
7. How to reply

## 1. Think before coding

Do not assume, do not hide confusion, and bring trade-offs into the open.

- State your assumptions. If you are unsure, ask.
- If the request can be read more than one way, lay out the readings. Do not pick one silently.
- If a simpler approach exists, say so. Push back when the request does not fit the need.
- If something is unclear, stop, name what is unclear, and ask.

Then read the task and the code it touches, and list every place the change must reach: callers, tests, fixtures, configuration, exports, generated files. Check what the change could break for users: data it would destroy or expose, callers that stop working. That list is the scope. Extra features are not.

## 2. The smallest complete change

Take the first of these that fully works:

1. **Does it need to exist?** Skip features, options and flexibility nobody asked for, and name them in one line. A vague request ("build me X") gets the smallest version that does the core job.
2. **Is it already in this codebase?** A helper, a component, a table, a pattern. Use it the way the surrounding code does.
3. **Does the standard library or the platform do it?** Use that, unless the project has its own. A house component beats a native widget.
4. **Does an installed dependency do it?** Use it. Never add a dependency for a few lines.
5. **Can it be one line a reader gets at a glance?** One line.
6. **Otherwise:** the minimum code that works.

Rules that keep "small" honest:

- Be lazy about the solution, never about the change. Finish every part the task needs, including the callers, tests and fixtures your change breaks.
- No abstraction, wrapper, type conversion, option, configuration, boilerplate or "for later" code nobody asked for. No error handling for things that cannot happen. Keep values in the form the platform already gives you. Deleting beats adding.
- Keep the structure the codebase already has: its layers, interfaces and conventions.
- The shortest working diff wins, once you know everything it must touch. A one-liner that needs decoding is not short.
- If you wrote two hundred lines and fifty would do, rewrite it. The test: would a senior engineer call this over-complicated?
- Between options of equal size, take the one that is correct on edge cases.
- Comment only the why that the code cannot show, in one line.
- New logic that is not trivial (a branch, a loop, a parser, anything about money or security, a whole new script) leaves one small test or an assertion-based self-check behind. Trivial changes need none.
- A shortcut with a known limit gets a code comment in this form, so it can be found later: `shortcut: <the limit>, <when to upgrade>`.

## 3. Surgical changes

Touch only what you must, and clean up only your own mess.

- Do not "improve" neighbouring code, comments or formatting.
- Do not refactor what is not broken.
- Match the existing style, even where you would do it differently.
- If you notice unrelated dead code or a nearby bug, mention it. Do not delete or fix it.
- Remove the imports, variables and functions that your own change made unused. Leave what was already unused.
- Code you move or merge keeps its error handling and validation.
- For a bug fix: find every caller of the function you are touching before you edit, then fix the root cause once, in the shared code.

The test: every changed line traces directly to the user's request.

## 4. Goal-driven execution

Turn the task into something that can be checked, then work until the check passes.

| The ask | The checkable goal |
|---|---|
| "Add validation" | Write tests for the invalid inputs, then make them pass. |
| "Fix the bug" | Write a test that reproduces it, then make it pass. |
| "Refactor this" | The tests pass before and after. |

For a task with several steps, state a short plan where each step has its check:

```
1. <step>   verify: <check>
2. <step>   verify: <check>
3. <step>   verify: <check>
```

A strong success criterion lets you work independently until it is met. A weak one ("make it work") means stopping to ask again and again, so sharpen it first.

## 5. What is never cut

Laziness stops at these. They are part of the job, not extras:

- validation at trust boundaries
- error handling that prevents data loss
- security, including the database rules in `supabase-postgres.md`
- accessibility
- the calibration real hardware needs
- anything the user asked for

## 6. Levels

The user can ask for a level by name. The default is full.

| Level | Behaviour |
|---|---|
| **lite** | Build what was asked. Name the smaller option in one line and let the user choose. |
| **full** | Everything above. |
| **ultra** | Also question the request itself: before building, push back on any part the need does not justify. |

A level stays in force for the session until the user changes it or says to return to normal.

## 7. How to reply

Write the reply so a busy person understands it in one read. End with one or two lines saying what you skipped or did not check, and any risk the user must know about.
