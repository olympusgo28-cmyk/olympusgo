---
type: llm
focus: trace
weight: 1
---

No write path lets a user change who a row belongs to or forge its author: either updates are not permitted at all, or the update policy states both using and with check (with columns that must not change protected by column grants), or writes go through a database function that reads the caller from auth.uid() and sets search_path.
