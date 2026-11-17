// Delivers what is due in push_queue. Run on a schedule with the service key.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { fcmSender, localSender, type PushSender } from "./sender.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

function sender(): PushSender | null {
  if (["kong", "127.0.0.1", "localhost"].includes(new URL(url).hostname)) return localSender;
  const project = Deno.env.get("FCM_PROJECT_ID");
  const token = Deno.env.get("FCM_ACCESS_TOKEN");
  return project && token ? fcmSender(project, token) : null;
}

Deno.serve(async (req) => {
  if (req.headers.get("authorization") !== `Bearer ${serviceKey}`) {
    return new Response("Not found", { status: 404 });
  }
  const push = sender();
  if (!push) return Response.json({ sent: 0, reason: "no provider" });

  const { data } = await admin.rpc("push_due");
  const sent: number[] = [];
  const skipped: number[] = [];
  for (const item of data ?? []) {
    const ok = await push.send(item.tokens, item.title, item.body);
    (ok ? sent : skipped).push(item.id);
  }
  if (sent.length) await admin.rpc("push_mark", { p_ids: sent, p_sent: true });
  if (skipped.length) await admin.rpc("push_mark", { p_ids: skipped, p_sent: false });
  return Response.json({ sent: sent.length, skipped: skipped.length });
});
