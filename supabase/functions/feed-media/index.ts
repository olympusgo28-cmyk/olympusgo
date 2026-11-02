// Short links to feed videos. It runs as the person asking, so the database's
// gate and rules decide. Only then does it sign anything, for one video.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { isLocalStack } from "../_shared/stack.ts";
import { FEED_BUCKET, videoHost } from "../_shared/video_host.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const publicUrl = Deno.env.get("FEED_PUBLIC_URL") ??
  (isLocalStack(url) ? "http://127.0.0.1:54321" : undefined);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const json = (body: unknown, status = 200) => Response.json(body, { status, headers: cors });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const auth = req.headers.get("authorization");
  if (!auth) return json({ error: "Log in first." }, 401);
  const user = createClient(url, anonKey, {
    auth: { persistSession: false },
    global: { headers: { Authorization: auth } },
  });
  const service = createClient(url, serviceKey, { auth: { persistSession: false } });
  const body = await req.json().catch(() => ({}));

  const refused = (error: { code?: string; message: string }) =>
    json({ error: error.code === "P0001" ? error.message : "Something went wrong. Try again." }, 400);

  const { data: seconds, error: secondsError } = await service.from("app_settings")
    .select("value").eq("key", "feed.url_seconds").single();
  if (secondsError) return json({ error: "Something went wrong. Try again." }, 500);

  try {
    if (body.action === "upload") {
      const { data, error } = await user.rpc("post_upload_target", { p_post: body.post });
      if (error) return refused(error);
      const target = await videoHost(data.host, service, url, publicUrl).uploadTarget(data.ref);
      return json(target ?? { exists: true });
    }
    if (body.action === "play" || body.action === "staff_play") {
      const rpc = body.action === "play" ? "post_play" : "staff_post_play";
      const { data, error } = await user.rpc(rpc, { p_post: body.post });
      if (error) return refused(error);
      return json({
        url: await videoHost(data.host, service, url, publicUrl).readUrl(data.ref, Number(seconds.value)),
      });
    }
    if (body.action === "posters") {
      const { data, error } = await user.rpc("post_posters", { p_posts: body.posts ?? [] });
      if (error) return refused(error);
      const urls: Record<string, string> = {};
      const refs = Object.entries(data as Record<string, string>);
      if (refs.length > 0) {
        videoHost("storage", service, url, publicUrl);
        const { data: signed, error: signError } = await service.storage.from(FEED_BUCKET)
          .createSignedUrls(refs.map(([, ref]) => ref), Number(seconds.value));
        if (signError || !signed) throw new Error("sign failed");
        refs.forEach(([id], i) => {
          const link = signed[i]?.signedUrl;
          if (link) urls[id] = publicUrl ? link.replace(/^https?:\/\/[^/]+/, publicUrl) : link;
        });
      }
      return json({ urls });
    }
  } catch (e) {
    console.error("feed media failed", (e as Error).name);
    return json({ error: "Videos are not available right now." }, 503);
  }
  return json({ error: "Bad request" }, 400);
});
