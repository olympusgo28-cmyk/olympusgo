// Log in by username. The app never learns the email behind a username:
// this function looks it up with the service role, asks Supabase Auth to
// email the 6-digit code, and later verifies the code and returns a session.
import { createClient } from "jsr:@supabase/supabase-js@2";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

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

async function emailFor(username: string): Promise<string | null> {
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
  const { data } = await admin
    .from("profiles")
    .select("id")
    .eq("username", username)
    .maybeSingle();
  if (!data) return null;
  const { data: user } = await admin.auth.admin.getUserById(data.id);
  return user?.user?.email ?? null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  let body: { action?: string; username?: string; code?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid request" }, 400);
  }
  const username = (body.username ?? "").trim();
  if (!/^[A-Za-z0-9_]{3,30}$/.test(username)) {
    return json({ error: "Enter a valid username." }, 400);
  }

  const email = await emailFor(username);
  const auth = createClient(url, anonKey, { auth: { persistSession: false } }).auth;

  if (body.action === "send") {
    // Same answer whether or not the username exists, so usernames can't be probed.
    if (email) {
      await auth.signInWithOtp({ email, options: { shouldCreateUser: false } });
    }
    return json({ sent: true });
  }

  if (body.action === "verify") {
    const code = (body.code ?? "").trim();
    if (!email || !/^\d{6}$/.test(code)) {
      return json({ error: "That code didn't work. Check it and try again." }, 400);
    }
    const { data, error } = await auth.verifyOtp({ email, token: code, type: "email" });
    if (error || !data.session) {
      return json({ error: "That code didn't work. Check it and try again." }, 400);
    }
    return json({ refresh_token: data.session.refresh_token });
  }

  return json({ error: "Unknown action" }, 400);
});
