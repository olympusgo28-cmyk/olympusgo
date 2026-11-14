---
type: llm
focus: trace
weight: 1
---

Only the repository implementation imports supabase_flutter; providers call the repository and do not call the Supabase client directly.
