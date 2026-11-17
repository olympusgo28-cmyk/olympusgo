// Plays the part of Stripe on a local stack: tests and the simulator use it to
// finish a payment. It doesn't exist anywhere else.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { fireLocalEvent, localEvent, standInFee } from "../_shared/stripe.ts";
import { isLocalStack } from "../_shared/stack.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const webhook = `${url}/functions/v1/stripe-webhook`;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (!isLocalStack(url)) return new Response("Not found", { status: 404 });
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const body = await req.json();
  const service = createClient(url, serviceKey, { auth: { persistSession: false } });
  const fire = (type: string, object: unknown) => fireLocalEvent(webhook, localEvent(type, object));
  let response: Response | undefined;

  if (body.action === "save_card") {
    response = await fire("setup_intent.succeeded", {
      id: `seti_local_${crypto.randomUUID()}`,
      customer: body.customer,
      payment_method: {
        id: body.declined ? "pm_local_declined" : "pm_local_card",
        card: { brand: "visa", last4: body.declined ? "0002" : "4242" },
      },
      metadata: { user_id: body.user_id },
    });
  } else if (body.action === "vendor_verified") {
    await service.rpc("money_svc_vendor_attach", {
      p_owner: body.owner_id,
      p_account: `acct_local_${body.owner_id}`,
    });
    response = await fire("account.updated", { id: `acct_local_${body.owner_id}`, payouts_enabled: true });
  } else {
    const { data: payment, error } = await service.from("payments").select(
      "id, amount_minor, currency, method, stripe_intent_id",
    ).eq("id", body.payment_id).single();
    if (error) return new Response("No such payment", { status: 404, headers: cors });
    const intent = payment.stripe_intent_id ?? `pi_local_${payment.id}`;
    const metadata = { payment_id: payment.id };
    if (body.action === "fail") {
      response = await fire("payment_intent.payment_failed", {
        id: intent,
        last_payment_error: { code: "card_declined" },
        metadata,
      });
    } else {
      const charge = `ch_local_${payment.id}`;
      // The same event, as many times as asked, all at once.
      const event = localEvent("payment_intent.succeeded", {
        id: intent,
        amount: payment.amount_minor,
        currency: payment.currency.toLowerCase(),
        latest_charge: charge,
        payment_method_types: [payment.method ?? "card"],
        metadata,
      });
      const sends = await Promise.all(
        Array.from({ length: body.repeat ?? 1 }, () => fireLocalEvent(webhook, event)),
      );
      await Promise.all(sends.map((sent) => sent.text()));
      response = sends[0];
      await fire("charge.updated", {
        id: charge,
        balance_transaction: { fee: standInFee(payment.amount_minor, payment.method ?? "card") },
      });
    }
  }
  return new Response(JSON.stringify({ status: response.status }), {
    headers: { ...cors, "Content-Type": "application/json" },
  });
});
