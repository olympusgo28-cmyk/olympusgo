// Starts an organizer's payout account. Stripe runs the identity and business
// checks on its own pages, and account.updated reports the result (R-PAY-4).
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
  const { data: vendor, error } = await player.rpc("vendor_start");
  if (error) return json({ error: error.code === "P0001" ? error.message : "Something went wrong." }, 400);

  try {
    const account = await stripe.createAccount(user.user.id, vendor.account ?? undefined);
    const service = createClient(url, serviceKey, { auth: { persistSession: false } });
    const { error: attachError } = await service.rpc("money_svc_vendor_attach", {
      p_owner: user.user.id,
      p_account: account.accountId,
    });
    if (attachError) throw attachError;
    return json({ onboarding_url: account.onboardingUrl });
  } catch {
    return json({ error: "We couldn't start your payout set-up. Try again." }, 502);
  }
});
