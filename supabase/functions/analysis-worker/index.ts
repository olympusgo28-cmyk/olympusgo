// What a worker talks to. It sends the fleet secret to claim a job, and gets a
// token for that job alone and a short signed URL for the clip. It sends its
// frame back here, so it can never write to Storage, and it never holds the
// service-role key.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { claimJob, finishCourt, frameBytes, resultProblem } from "../_shared/clips.ts";
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
      return Response.json({ job: await claimJob(service, publicUrl) });
    } catch (e) {
      console.error("analysis claim failed", (e as Error).name);
      return new Response("Try again", { status: 500 });
    }
  }

  // Asked between stages, so a withdrawal stops the work as well as the result.
  if (body.action === "continue") {
    const { data } = await service.rpc("analysis_svc_may_continue", {
      p_job: body.job_id,
      p_token: body.token,
    });
    return Response.json({ continue: data === true });
  }

  if (body.action === "result") {
    const problem = resultProblem(body.kind, body.ok, body.result, body.code);
    if (problem) return Response.json({ error: "Bad result." }, { status: 400 });
    if (body.kind === "court" && body.ok) {
      const frame = frameBytes(body.frame);
      if (!frame) return Response.json({ error: "Bad result." }, { status: 400 });
      const outcome = await finishCourt(service, {
        job_id: body.job_id,
        token: body.token,
        result: body.result,
        worker_seconds: Math.round(Number(body.worker_seconds) || 0),
      }, frame);
      if ("status" in outcome) return Response.json({ status: outcome.status });
      return Response.json({ error: outcome.code === "P0001" ? outcome.error : "Try again" }, {
        status: outcome.code === "P0001" ? 403 : 500,
      });
    }
    const { data, error } = await service.rpc("analysis_svc_result", {
      p_job: body.job_id,
      p_token: body.token,
      p_ok: body.ok,
      p_result: body.result ?? null,
      p_code: body.code ?? null,
      p_worker_seconds: Math.round(Number(body.worker_seconds) || 0),
    });
    if (error) {
      return Response.json({ error: error.code === "P0001" ? error.message : "Try again" }, {
        status: error.code === "P0001" ? 403 : 500,
      });
    }
    return Response.json({ status: data });
  }

  return new Response("Bad request", { status: 400 });
});
