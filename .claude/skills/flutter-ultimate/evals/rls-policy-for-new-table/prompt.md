---
tags: [skill-creator]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

i need a new table for coach notes in our flutter + supabase app. a coach writes a note about a student in one of their classes, and only that student's parent (or the student if they're an adult) can read it. other coaches and other parents must not see it. tables we already have: classes(id, coach_id), enrolments(class_id, student_id), students(id, guardian_id). write the migration and whatever proves the rules hold. don't touch our live project.
