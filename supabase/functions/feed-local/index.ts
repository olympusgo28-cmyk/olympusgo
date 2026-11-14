// Plays the worker and its checks on a local stack, through the same steps:
// claim, check, send a result. Tests and the simulator use it, and can ask for
// a verdict. It doesn't exist anywhere else.
import { decodeBase64 } from "jsr:@std/encoding@1/base64";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { STAND_IN_FRAME } from "../_shared/clips.ts";
import { claimPost, failPost, finishPost } from "../_shared/feed.ts";
import { fakeCheckers, type FrameVerdict } from "../_shared/moderation.ts";
import { isLocalStack } from "../_shared/stack.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (!isLocalStack(url)) return new Response("Not found", { status: 404 });
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const body = await req.json().catch(() => ({}));
  const service = createClient(url, serviceKey, { auth: { persistSession: false } });
  const verdict: FrameVerdict = body.frames === "flag" || body.frames === "reject" ? body.frames : "clear";
  let done = 0;
  for (let i = 0; i < 5; i++) {
    const job = await claimPost(service, url);
    if (!job) break;
    const finish = { job_id: job.job_id, token: job.token, worker_seconds: 1 };
    const outcome = typeof body.fail === "string"
      ? await failPost(service, finish, body.fail)
      : await finishPost(
        service,
        finish,
        [decodeBase64(STAND_IN_FRAME)],
        () => fakeCheckers(verdict, body.hash === "match"),
      );
    if (!("status" in outcome)) return new Response("Result failed", { status: 500 });
    done++;
  }
  return Response.json({ done }, { headers: cors });
});
