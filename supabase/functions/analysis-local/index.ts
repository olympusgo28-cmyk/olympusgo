// Plays the worker on a local stack, through the same steps: claim, write the
// frame, send a result. Tests and the simulator use it. It doesn't exist
// anywhere else.
import { decodeBase64 } from "jsr:@std/encoding@1/base64";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { claimJob, finishCourt, STAND_IN_FRAME, standInReport } from "../_shared/clips.ts";
import { isLocalStack } from "../_shared/stack.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const CORNERS = [[0.25, 0.17], [0.75, 0.17], [0.91, 0.89], [0.09, 0.89]];

Deno.serve(async (req) => {
  if (!isLocalStack(url)) return new Response("Not found", { status: 404 });
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const body = await req.json().catch(() => ({}));
  const service = createClient(url, serviceKey, { auth: { persistSession: false } });
  let done = 0;
  for (let i = 0; i < 5; i++) {
    const job = await claimJob(service);
    if (!job) break;
    const failing = typeof body.fail === "string";
    if (job.kind === "court" && !failing) {
      const outcome = await finishCourt(service, {
        job_id: job.job_id,
        token: job.token,
        result: { seconds: 30, corners: CORNERS },
        worker_seconds: 1,
      }, decodeBase64(STAND_IN_FRAME));
      if (!("status" in outcome)) return new Response("Result failed", { status: 500 });
    } else {
      const { error } = await service.rpc("analysis_svc_result", {
        p_job: job.job_id,
        p_token: job.token,
        p_ok: !failing,
        p_result: failing ? null : standInReport(),
        p_code: failing ? body.fail : null,
        p_worker_seconds: 1,
      });
      if (error) return new Response("Result failed", { status: 500 });
    }
    done++;
  }
  return Response.json({ done }, { headers: cors });
});
