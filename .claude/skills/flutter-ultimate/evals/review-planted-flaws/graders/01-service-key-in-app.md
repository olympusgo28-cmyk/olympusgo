---
type: llm
focus: trace
weight: 1
---

The review identifies that the Supabase service-role (secret) key is used inside the app (read from a build-time define in tips_repository.dart), which exposes it to anyone with the app.
