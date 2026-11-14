// Daily comparison of the ledger with Stripe's balance transactions (P4a-08).
// Pure, so a mismatch can be injected in a test.

export interface LedgerRow {
  source: string;
  amount_minor: number;
  fee_minor: number | null;
  at: string;
}

export interface BalanceTxn {
  source: string;
  amount_minor: number;
  fee_minor: number;
}

export type MismatchKind = "missing_at_stripe" | "unknown_to_ledger" | "amount" | "fee";

export interface Mismatch {
  source: string;
  kind: MismatchKind;
  ledger_minor?: number | null;
  stripe_minor?: number | null;
}

export interface ReconcileResult {
  matched: number;
  timing: number;
  mismatches: Mismatch[];
}

/** Charges, refunds and transfers: everything the ledger records by Stripe id. */
const OURS = /^(ch|py|re|pyr|tr)_/;

/** Newer differences are usually Stripe catching up, so they wait a run. */
export function reconcile(
  ledger: LedgerRow[],
  txns: BalanceTxn[],
  now: Date,
  timingHours = 48,
): ReconcileResult {
  const cutoff = now.getTime() - timingHours * 3_600_000;
  const stripe = new Map(txns.map((t) => [t.source, t]));
  const known = new Set(ledger.map((l) => l.source));
  const result: ReconcileResult = { matched: 0, timing: 0, mismatches: [] };

  for (const row of ledger) {
    const recent = new Date(row.at).getTime() > cutoff;
    const txn = stripe.get(row.source);
    if (!txn) {
      if (recent) result.timing++;
      else result.mismatches.push({ source: row.source, kind: "missing_at_stripe" });
      continue;
    }
    if (txn.amount_minor !== row.amount_minor) {
      result.mismatches.push({
        source: row.source,
        kind: "amount",
        ledger_minor: row.amount_minor,
        stripe_minor: txn.amount_minor,
      });
      continue;
    }
    if (row.fee_minor === null) {
      if (recent) {
        result.timing++;
        continue;
      }
    }
    if ((row.fee_minor ?? 0) !== txn.fee_minor) {
      result.mismatches.push({
        source: row.source,
        kind: "fee",
        ledger_minor: row.fee_minor,
        stripe_minor: txn.fee_minor,
      });
      continue;
    }
    result.matched++;
  }

  for (const txn of txns) {
    // Stripe's own payouts and fees aren't ours to match, only money we moved.
    if (OURS.test(txn.source) && !known.has(txn.source)) {
      result.mismatches.push({
        source: txn.source,
        kind: "unknown_to_ledger",
        stripe_minor: txn.amount_minor,
      });
    }
  }
  return result;
}
