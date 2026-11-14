---
type: llm
focus: trace
weight: 1
---

The review identifies that send_tip takes the payer's id as a parameter (p_from) instead of reading the caller from auth.uid(), so a caller can spend someone else's balance.
