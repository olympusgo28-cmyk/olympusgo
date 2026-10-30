// Sign-in for the app. Finds the account on the server, so the app never
// learns whether one exists: unknown and known accounts get the same answer in
// the same time. Limits are per target and per IP, and 5 wrong codes lock the
// target whether or not it is a real account.
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  BAD_CODE,
  BAD_INPUT,
  canonical,
  clientIp,
  paddingMs,
  parseIdentifier,
  sha256,
  type Target,
  TOO_MANY,
} from "./logic.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const pepper = Deno.env.get("LOGIN_HASH_PEPPER") ?? "";

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

const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
const publicAuth = () => createClient(url, anonKey, { auth: { persistSession: false } }).auth;

interface Account {
  phone: string | null;
  email: string | null;
}

/** A mobile or email is used as typed: looking it up here could be timed. */
async function resolve(target: Target): Promise<Account | null> {
  if (target.kind === "mobile") return { phone: target.phone, email: null };
  if (target.kind === "email") return { phone: null, email: target.email };
  const { data } = await admin.rpc("login_lookup", { p_username: target.username });
  return data ?? null;
}

async function padMs(): Promise<number> {
  const { data } = await admin.from("app_settings").select("value").eq("key", "auth.login_pad_ms")
    .maybeSingle();
  return Number(data?.value ?? 900);
}

async function send(target: Target, signUp: boolean, targetHash: string, ipHash: string) {
  const { data: allowed } = await admin.rpc("login_gate_send", {
    p_target_hash: targetHash,
    p_ip_hash: ipHash,
  });
  if (!allowed) return json({ error: TOO_MANY }, 429);

  const account = await resolve(target);
  if (account) {
    const options = { shouldCreateUser: signUp && target.kind === "mobile" };
    const auth = publicAuth();
    // The result is ignored on purpose: an unknown mobile fails here, and the
    // reply must not show it.
    const { error } = account.email
      ? await auth.signInWithOtp({ email: account.email, options })
      : await auth.signInWithOtp({ phone: account.phone!, options });
    if (error) console.log(JSON.stringify({ event: "login_send_failed", status: error.status }));
  }
  return json({ sent: true });
}

async function verify(target: Target, code: string, targetHash: string) {
  // Counted before the code is checked, so parallel tries cannot all pass.
  const { data: allowed } = await admin.rpc("login_gate_attempt", { p_target_hash: targetHash });
  if (!allowed) return json({ error: TOO_MANY }, 429);

  const account = /^\d{6}$/.test(code) ? await resolve(target) : null;
  let refreshToken: string | undefined;
  if (account) {
    const auth = publicAuth();
    const { data } = account.email
      ? await auth.verifyOtp({ email: account.email, token: code, type: "email" })
      : await auth.verifyOtp({ phone: account.phone!, token: code, type: "sms" });
    refreshToken = data.session?.refresh_token;
  }
  if (!refreshToken) return json({ error: BAD_CODE }, 400);
  await admin.rpc("login_gate_clear", { p_target_hash: targetHash });
  return json({ refresh_token: refreshToken });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const startedAt = Date.now();
  const pad = await padMs();
  const finish = async (res: Response) => {
    await new Promise((done) => setTimeout(done, paddingMs(startedAt, Date.now(), pad)));
    return res;
  };

  let body: { action?: string; identifier?: string; code?: string; sign_up?: boolean };
  try {
    body = await req.json();
  } catch {
    return finish(json({ error: BAD_INPUT }, 400));
  }

  const target = parseIdentifier(body.identifier ?? "");
  if (!target) return finish(json({ error: BAD_INPUT }, 400));

  const targetHash = await sha256(canonical(target), pepper);
  const ipHash = await sha256(clientIp(req.headers), pepper);

  if (body.action === "send") {
    return finish(await send(target, body.sign_up === true, targetHash, ipHash));
  }
  if (body.action === "verify") {
    return finish(await verify(target, (body.code ?? "").trim(), targetHash));
  }
  return finish(json({ error: BAD_INPUT }, 400));
});
