---
tags: [skill-creator]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

add a 'saved venues' feature to the app logic (no screen yet). players can save and unsave a venue and see their saved list. stack is riverpod with code generation, freezed, go_router, supabase_flutter. the table is saved_venues(user_id uuid, venue_id uuid, created_at timestamptz) with RLS already on. give me the model, repository, providers and tests.
