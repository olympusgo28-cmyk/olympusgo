---
type: llm
focus: trace
weight: 1
---

Every policy on the new table names a role with a to clause (not public by default) and compares ownership using (select auth.uid()) rather than a bare auth.uid() or a client-supplied id.
