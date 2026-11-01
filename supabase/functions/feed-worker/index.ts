// What a worker talks to for the feed. It sends the fleet secret to claim a
// post, and gets a token for that job alone and a short link to the video. It
// sends frames back here. The providers are called from here, so the worker
// holds nothing but its secret.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { claimPost, failPost, finishPost, frameList } from "../_shared/feed.ts";
import { pickCheckers } from "../_shared/moderation.ts";
import { isLocalStack } from "../_shared/stack.ts";
import { timingSafeEqual } from "../_shared/stripe.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const secret = isLocalStack(url) ? "local-analysis-secret" : Deno.env.get("ANALYSIS_WORKER_SECRET");
// The address a worker outside the stack reaches Storage on.
const publicUrl = Deno.env.get("ANALYSIS_PUBLIC_URL");

Deno.serve(async (req) => {
  if (!secret || !timingSafeEqual(req.headers.get("x-worker-secret") ?? "", secret)) {
    return new Response("Not found", { status: 404 });
  }
  const service = createClient(url, serviceKey, { auth: { persistSession: false } });
  const body = await req.json().catch(() => ({}));

  if (body.action === "claim") {
    try {
      return Response.json({ job: await claimPost(service, url, publicUrl) });
    } catch (e) {
      console.error("feed claim failed", (e as Error).name);
      return new Response("Try again", { status: 500 });
    }
  }

  if (body.action === "check") {
    const finish = {
      job_id: body.job_id,
      token: body.token,
      worker_seconds: Math.round(Number(body.worker_seconds) || 0),
    };
    let outcome;
    if (body.ok === true) {
      const frames = frameList(body.frames);
      if (!frames) return Response.json({ error: "Bad result." }, { status: 400 });
      outcome = await finishPost(
        service,
        finish,
        frames,
        () => pickCheckers(url, Deno.env.get("FEED_CHECKER")),
      );
    } else {
      outcome = await failPost(service, finish, typeof body.code === "string" ? body.code : "internal");
    }
    if ("status" in outcome) return Response.json({ status: outcome.status });
    return Response.json({ error: outcome.code === "P0001" ? outcome.error : "Try again" }, {
      status: outcome.code === "P0001" ? 403 : 500,
    });
  }

  return new Response("Bad request", { status: 400 });
});
