// Runs on a timer. The database writes what should happen, and this makes the
// Stripe calls, because nothing may call Stripe inside a transaction.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { assertMinor } from "../_shared/money.ts";
import { reconcile } from "../_shared/reconcile.ts";
import { isLocalStack } from "../_shared/stack.ts";
import { LOCAL_WORKER_SECRET, StripeError, stripeFor, timingSafeEqual } from "../_shared/stripe.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const stripe = stripeFor(url, (key) => Deno.env.get(key));
const workerSecret = isLocalStack(url) ? LOCAL_WORKER_SECRET : Deno.env.get("MONEY_WORKER_SECRET");

Deno.serve(async (req) => {
  if (!stripe || !workerSecret) return new Response("Not configured", { status: 503 });
  if (!timingSafeEqual(req.headers.get("x-worker-secret") ?? "", workerSecret)) {
    return new Response("Not found", { status: 404 });
  }

  const service = createClient(url, serviceKey, { auth: { persistSession: false } });
  const result = async (kind: string, id: string, ok: boolean, ref?: string, code?: string) => {
    const { error } = await service.rpc("money_svc_result", {
      p_kind: kind,
      p_id: id,
      p_ok: ok,
      p_ref: ref ?? null,
      p_code: code ?? null,
    });
    if (error) throw error;
  };

  const body = await req.json().catch(() => ({}));
  if (body.task === "reconcile") {
    const since = new Date(Date.now() - 7 * 86_400_000);
    const { data: rows, error } = await service.rpc("money_svc_ledger_rows", {
      p_since: since.toISOString(),
    });
    if (error) return new Response("Try again", { status: 500 });
    const outcome = reconcile(rows, await stripe.listBalanceTransactions(since, rows), new Date());
    const { error: saveError } = await service.rpc("money_svc_reconcile_save", {
      p_matched: outcome.matched,
      p_timing: outcome.timing,
      p_mismatches: outcome.mismatches,
    });
    if (saveError) return new Response("Try again", { status: 500 });
    return Response.json(outcome);
  }

  // One worker at a time: a slow batch must not overlap the next tick.
  const { data: lease } = await service.rpc("money_svc_lease", { p_seconds: 300 });
  if (!lease) return Response.json({ skipped: true });

  const { data: work, error } = await service.rpc("money_svc_work");
  if (error) return new Response("Try again", { status: 500 });

  // Stripe's answer and our record of it fail separately. If Stripe worked but
  // the record didn't, the item stays queued and repeats on its idempotency key.
  // Only a plain refusal from Stripe counts as failed. One bad item never stops
  // the rest.
  const attempt = async (
    kind: string,
    id: string,
    send: () => Promise<{ ok?: string; ref?: string } | void>,
  ) => {
    try {
      let outcome;
      try {
        outcome = await send();
      } catch (error) {
        if (!(error instanceof StripeError)) return;
        await result(kind, id, false, undefined, error.code);
        return;
      }
      await result(outcome?.ok ?? kind, id, true, outcome?.ref);
    } catch {
      // The next tick tries again.
    }
  };

  for (const item of work.cancel) {
    await attempt("cancel", item.payment_id, async () => {
      if (item.intent) await stripe.cancelIntent(item.intent);
    });
  }
  for (const item of work.refunds) {
    await attempt("refund", item.refund_id, async () => {
      const refund = await stripe.createRefund({
        refundId: item.refund_id,
        attempt: item.attempt,
        intentId: item.intent,
        amountMinor: assertMinor(item.amount_minor),
      });
      // A card refund can succeed at once, with no later update event.
      return { ok: refund.status === "succeeded" ? "refund_done" : "refund", ref: refund.id };
    });
  }
  for (const item of work.organizer_fees) {
    await attempt("organizer_fee", item.payment_id, async () => {
      if (!item.payment_method) throw new StripeError("no_card");
      const charge = await stripe.chargeOffSession({
        paymentId: item.payment_id,
        amountMinor: assertMinor(item.amount_minor),
        currency: item.currency,
        customer: item.customer,
        paymentMethod: item.payment_method,
      });
      return { ref: charge.intentId };
    });
  }
  for (const item of work.transfers) {
    await attempt("transfer", item.item_id, async () => {
      const transfer = await stripe.createTransfer({
        itemId: item.item_id,
        amountMinor: assertMinor(item.amount_minor),
        currency: item.currency,
        account: item.account,
      });
      return { ref: transfer.id };
    });
  }
  await service.rpc("money_svc_lease", { p_seconds: 0, p_token: lease });
  return Response.json({
    cancelled: work.cancel.length,
    refunds: work.refunds.length,
    organizer_fees: work.organizer_fees.length,
    transfers: work.transfers.length,
  });
});
