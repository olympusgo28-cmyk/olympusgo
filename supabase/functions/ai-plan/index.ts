// Writes a draft program for an adult who has agreed. The database checks who
// may ask and saves the result. Nothing about the prompt or answer is logged.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { type PlanInput, plannerFor, planWithRetry } from "../_shared/planner.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const planner = plannerFor(url, (key) => Deno.env.get(key));

// Hosted functions stop at 150 seconds.
const DEADLINE_MS = 130_000;

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

const FAILED = "Couldn't make a plan. Try again.";
const BUSY = "Can't reach OlympusGO. Check your connection and try again.";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!planner) return json({ error: "AI plans are not open yet." }, 503);

  let body: { client_key?: string; goal?: string; days?: number };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Bad request" }, 400);
  }

  // As the player, so the gate, age, consent and limits all apply.
  const player = createClient(url, anonKey, {
    auth: { persistSession: false },
    global: { headers: { Authorization: req.headers.get("authorization") ?? "" } },
  });
  const { data: begun, error } = await player.rpc("ai_plan_begin", {
    p_client_key: body.client_key,
    p_goal: body.goal,
    p_days: body.days,
  });
  // Anything but a real refusal may be a blip, so the phone keeps its key.
  if (error) {
    // Signed out: the function is closed to anon.
    if (error.code === "42501") return json({ error: "Log in first." }, 401);
    if (error.code !== "P0001") return json({ error: BUSY }, 503);
    // From the API gate, before anything else ran. The key is still good.
    if (error.message.startsWith("Too many tries")) return json({ error: error.message }, 429);
    return json({ error: error.message }, 400);
  }
  if (begun.status === "done") return json({ program_id: begun.program_id });
  // The first try is still running. The phone keeps its key and can ask again.
  if (begun.status === "pending") return json({ error: "Your plan is still being made." }, 409);

  const service = createClient(url, serviceKey, { auth: { persistSession: false } });
  const input: PlanInput = {
    goal: begun.goal,
    days: begun.days,
    summary: begun.summary,
    catalogue: begun.catalogue,
  };
  let model: string = begun.model;
  let inputTokens = 0;
  let outputTokens = 0;
  try {
    const mayRetry = async () => {
      const { data, error } = await service.rpc("ai_plan_svc_allowed", { p_request: begun.request_id });
      return !error && data === true;
    };
    const result = await planWithRetry(
      planner,
      input,
      begun.model,
      AbortSignal.timeout(DEADLINE_MS),
      mayRetry,
    );
    model = result.model;
    inputTokens = result.inputTokens;
    outputTokens = result.outputTokens;
    if (result.plan) {
      const { data: program, error: saveError } = await service.rpc("ai_plan_svc_finish", {
        p_request: begun.request_id,
        p_plan: result.plan,
        p_model: model,
        p_input_tokens: inputTokens,
        p_output_tokens: outputTokens,
      });
      if (!saveError) return json({ program_id: program });
      console.error("ai-plan not saved", saveError.code);
      // It may have saved all the same. The request stays open, and the same
      // key finds the plan or, after 3 minutes, says it didn't work.
      if (saveError.code !== "P0001") return json({ error: BUSY }, 503);
    }
  } catch (e) {
    console.error("ai-plan failed", (e as Error).name);
  }
  await service.rpc("ai_plan_svc_fail", {
    p_request: begun.request_id,
    p_model: model,
    p_input_tokens: inputTokens,
    p_output_tokens: outputTokens,
  });
  return json({ error: FAILED }, 502);
});
