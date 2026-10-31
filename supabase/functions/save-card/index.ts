// Starts saving a card for organizer-pays Meets. The card goes straight to
// Stripe, and setup_intent.succeeded records its last four digits.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { stripeFor } from "../_shared/stripe.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const stripe = stripeFor(url, (key) => Deno.env.get(key));

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

  const player = createClient(url, anonKey, {
    auth: { persistSession: false },
    global: { headers: { Authorization: req.headers.get("authorization") ?? "" } },
  });
  const { data: user } = await player.auth.getUser();
  if (!user.user) return json({ error: "Sign in first." }, 401);

  try {
    const service = createClient(url, serviceKey, { auth: { persistSession: false } });
    const { data: existing } = await service.rpc("money_svc_customer", { p_user: user.user.id });
    const customer = existing ?? await stripe.createCustomer(user.user.id);
    const setup = await stripe.createSetup({ userId: user.user.id, customer });
    return json({ client_secret: setup.clientSecret, customer });
  } catch {
    return json({ error: "We couldn't start saving your card. Try again." }, 502);
  }
});
