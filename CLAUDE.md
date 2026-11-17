# CLAUDE.md — OlympusGO

@AGENTS.md

## Notes for Claude Code

- Start every session by reading `AGENTS.md` (imported above) and the ticket you are working on in `docs/BUILD_PLAN.md`.
- Use plan mode before changing anything in sign-in, money, minors or RLS. Put the plan in the pull request description.
- Use a separate subagent to review a finished change against `docs/RULES.md` and the security standard in `docs/ARCHITECTURE.md` section 8. The reviewer has not seen the work being produced.
- Run the checks in `AGENTS.md` with the Bash tool before saying a task is done. Report the commands you ran and their results.
- Never read, print or ask for production secrets. Local and development keys live in `.env.local`, which is git-ignored.
- When a rule is missing or marked [Open], add a row to `docs/OPEN_QUESTIONS.md` and tell the owner in your summary. Do not pick a value silently.
