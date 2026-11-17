// The only thing that confirms a payment. Idempotent on Stripe's event id, so a
// replay does nothing. A 5xx asks Stripe to send the event again.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { stripeFor, toMoneyEvent, verifySignature } from "../_shared/stripe.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const stripe = stripeFor(url, (key) => Deno.env.get(key));

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const secrets = stripe?.webhookSecrets() ?? [];
  if (!stripe || secrets.length === 0) return new Response("Not configured", { status: 503 });

  const body = await req.text();
  const signature = req.headers.get("stripe-signature");
  const checks = await Promise.all(secrets.map((secret) => verifySignature(secret, body, signature)));
  if (!checks.includes(true)) return new Response("Bad signature", { status: 400 });

  const service = createClient(url, serviceKey, { auth: { persistSession: false } });
  try {
    const event = await stripe.enrich(JSON.parse(body));
    const { error } = await service.rpc("money_svc_event", { p_event: toMoneyEvent(event) });
    if (error) return new Response("Try again", { status: 500 });
  } catch {
    return new Response("Try again", { status: 500 });
  }
  return new Response(JSON.stringify({ received: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
