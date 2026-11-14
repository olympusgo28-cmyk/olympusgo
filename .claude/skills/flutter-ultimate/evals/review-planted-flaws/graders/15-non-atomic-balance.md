---
type: llm
focus: trace
weight: 1
---

The review identifies that the balance check and the deduction in send_tip are not atomic (no row lock), so concurrent calls can overspend.
