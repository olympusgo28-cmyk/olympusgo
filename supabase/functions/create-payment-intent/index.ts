// Starts paying for a reservation. The amount comes from the database, never
// from the app, and the webhook is what confirms it.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { assertMinor } from "../_shared/money.ts";
import { type Stripe, stripeFor } from "../_shared/stripe.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const stripe: Stripe | null = stripeFor(url, (key) => Deno.env.get(key));

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!stripe) return json({ error: "Payments aren't switched on yet." }, 503);

  let body: { payment_id?: string; method?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Bad request" }, 400);
  }

  // As the player, so the gate and the ownership check both apply.
  const player = createClient(url, anonKey, {
    auth: { persistSession: false },
    global: { headers: { Authorization: req.headers.get("authorization") ?? "" } },
  });
  const { data: payment, error } = await player.rpc("payment_begin", {
    p_payment: body.payment_id,
    p_method: body.method,
  });
  if (error) return json({ error: error.code === "P0001" ? error.message : "Something went wrong." }, 400);

  try {
    const intent = await stripe.createIntent({
      paymentId: payment.payment_id,
      amountMinor: assertMinor(payment.amount_minor),
      currency: payment.currency,
      method: payment.method,
    });
    const service = createClient(url, serviceKey, { auth: { persistSession: false } });
    const { error: attachError } = await service.rpc("money_svc_attach_intent", {
      p_payment: payment.payment_id,
      p_intent: intent.intentId,
    });
    if (attachError) throw attachError;
    return json({
      payment_id: payment.payment_id,
      client_secret: intent.clientSecret,
      hold_until: payment.hold_until,
      server_now: payment.server_now,
    });
  } catch {
    return json({ error: "We couldn't start your payment. Try again." }, 502);
  }
});
