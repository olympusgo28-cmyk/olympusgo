import { assertEquals } from "jsr:@std/assert@1";
import { type LedgerRow, reconcile } from "./reconcile.ts";

const now = new Date("2026-11-10T00:00:00Z");
const old = "2026-11-01T00:00:00Z";
const recent = "2026-11-09T12:00:00Z";
const charge: LedgerRow = { source: "ch_1", amount_minor: 800, fee_minor: 77, at: old };

Deno.test("matching rows match", () => {
  const out = reconcile([charge], [{ source: "ch_1", amount_minor: 800, fee_minor: 77 }], now);
  assertEquals(out, { matched: 1, timing: 0, mismatches: [] });
});

Deno.test("an injected one-cent fee change raises a mismatch", () => {
  const out = reconcile([charge], [{ source: "ch_1", amount_minor: 800, fee_minor: 78 }], now);
  assertEquals(out.mismatches, [{ source: "ch_1", kind: "fee", ledger_minor: 77, stripe_minor: 78 }]);
});

Deno.test("an injected amount change raises a mismatch", () => {
  const out = reconcile([charge], [{ source: "ch_1", amount_minor: 900, fee_minor: 77 }], now);
  assertEquals(out.mismatches[0].kind, "amount");
});

Deno.test("a row Stripe doesn't have raises a mismatch once it's old", () => {
  assertEquals(reconcile([charge], [], now).mismatches, [{ source: "ch_1", kind: "missing_at_stripe" }]);
});

Deno.test("a new row Stripe doesn't have yet is timing", () => {
  assertEquals(reconcile([{ ...charge, at: recent }], [], now), { matched: 0, timing: 1, mismatches: [] });
});

Deno.test("a Stripe row the ledger doesn't know raises a mismatch", () => {
  const out = reconcile([], [{ source: "ch_2", amount_minor: 500, fee_minor: 0 }], now);
  assertEquals(out.mismatches, [{ source: "ch_2", kind: "unknown_to_ledger", stripe_minor: 500 }]);
});

Deno.test("Stripe's own payouts aren't ours to match", () => {
  const out = reconcile([], [{ source: "po_1", amount_minor: -500, fee_minor: 0 }], now);
  assertEquals(out.mismatches, []);
});

Deno.test("an unknown fee waits, then counts", () => {
  const row = { ...charge, fee_minor: null };
  const txn = [{ source: "ch_1", amount_minor: 800, fee_minor: 77 }];
  assertEquals(reconcile([{ ...row, at: recent }], txn, now).timing, 1);
  assertEquals(reconcile([row], txn, now).mismatches[0].kind, "fee");
});
