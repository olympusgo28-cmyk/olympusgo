// Sign-in for the app. This function issues and checks every code, and Supabase
// Auth only creates the session at the end. Auth holds no real mobile or email,
// so nothing can be learned or bypassed by calling it directly. Unknown and
// known accounts get the same answer in the same time, and 5 wrong codes lock
// the target whether or not it is a real account.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { isLocalStack, liveDelivery, localDelivery } from "./delivery.ts";
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
const delivery = isLocalStack(url) ? localDelivery : liveDelivery((key) => Deno.env.get(key));

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

interface Account {
  user_id: string;
  mobile: string | null;
  email: string | null;
  internal_email: string;
}

async function lookup(target: Target): Promise<Account | null> {
  const value = target.kind === "mobile"
    ? target.phone
    : target.kind === "email"
    ? target.email
    : target.username;
  const { data } = await admin.rpc("login_lookup", { p_kind: target.kind, p_value: value });
  return data ?? null;
}

async function padMs(): Promise<number> {
  const { data } = await admin.from("app_settings").select("value").eq("key", "auth.login_pad_ms")
    .maybeSingle();
  return Number(data?.value ?? 900);
}

const codeHash = (targetHash: string, code: string) => sha256(`${targetHash}:${code}`, pepper);

async function issue(targetHash: string, contact: string, purpose: string): Promise<string> {
  const code = delivery.codeFor(contact);
  await admin.rpc("login_code_issue", {
    p_target_hash: targetHash,
    p_code_hash: await codeHash(targetHash, code),
    p_purpose: purpose,
  });
  return code;
}

async function allowedToSend(targetHash: string, ipHash: string): Promise<boolean> {
  const { data } = await admin.rpc("login_gate_send", {
    p_target_hash: targetHash,
    p_ip_hash: ipHash,
  });
  return data === true;
}

async function send(target: Target, targetHash: string, ipHash: string) {
  if (!await allowedToSend(targetHash, ipHash)) return json({ error: TOO_MANY }, 429);

  // Every mobile gets a code the same way, with no lookup first: a new number
  // signs up with it and one already in use simply logs in (Q247). So neither
  // the answer nor its timing says which. The old sign_up flag is ignored.
  if (target.kind === "mobile") {
    const code = await issue(targetHash, target.phone, "signup");
    await delivery.sms(target.phone, code);
    return json({ sent: true });
  }

  const account = await lookup(target);
  // Only email and username reach here; a username's code goes to its email,
  // or its mobile when it has none.
  const contact = target.kind === "email" ? account?.email : account?.email ?? account?.mobile;
  if (contact) {
    const code = await issue(targetHash, contact, "login");
    const ok = contact.startsWith("+")
      ? await delivery.sms(contact, code)
      : await delivery.email(contact, code);
    if (!ok) console.log(JSON.stringify({ event: "login_send_failed" }));
  }
  return json({ sent: true });
}

/** Makes the Supabase session for an account we have already checked. */
async function session(internalEmail: string): Promise<string | undefined> {
  const { data } = await admin.auth.admin.generateLink({ type: "magiclink", email: internalEmail });
  const tokenHash = data.properties?.hashed_token;
  if (!tokenHash) return undefined;
  const auth = createClient(url, anonKey, { auth: { persistSession: false } }).auth;
  const res = await auth.verifyOtp({ token_hash: tokenHash, type: "magiclink" });
  return res.data.session?.refresh_token;
}

/** A random address nobody can work out, so nothing can ask Supabase for it. */
function randomAuthEmail(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(20));
  const hex = Array.from(bytes).map((b) => b.toString(16).padStart(2, "0")).join("");
  return `u-${hex}@users.olympusgo.invalid`;
}

async function createAccount(mobile: string): Promise<Account | null> {
  const id = crypto.randomUUID();
  const email = randomAuthEmail();
  const { error } = await admin.auth.admin.createUser({ id, email, email_confirm: true });
  if (error) return null;
  const { data: bound } = await admin.rpc("login_account_bind", {
    p_user: id,
    p_mobile: mobile,
    p_auth_email: email,
  });
  if (bound) return { user_id: id, mobile, email: null, internal_email: email };
  // Someone else took this mobile in the same moment: that account stands.
  await admin.auth.admin.deleteUser(id);
  return null;
}

async function verify(target: Target, code: string, targetHash: string) {
  // Counted before the code is checked, so parallel tries cannot all pass.
  const { data: allowed } = await admin.rpc("login_gate_attempt", { p_target_hash: targetHash });
  if (!allowed) return json({ error: TOO_MANY }, 429);

  const { data: purpose } = /^\d{6}$/.test(code)
    ? await admin.rpc("login_code_check", {
      p_target_hash: targetHash,
      p_code_hash: await codeHash(targetHash, code),
    })
    : { data: null };
  if (!purpose) return json({ error: BAD_CODE }, 400);

  let account = await lookup(target);
  if (!account && purpose === "signup" && target.kind === "mobile") {
    account = await createAccount(target.phone) ?? await lookup(target);
  }
  const refreshToken = account ? await session(account.internal_email) : undefined;
  if (!refreshToken) return json({ error: BAD_CODE }, 400);
  await admin.rpc("login_gate_clear", { p_target_hash: targetHash });
  return json({ refresh_token: refreshToken });
}

/** The signed-in person, from their own token. */
async function caller(req: Request): Promise<string | null> {
  const token = req.headers.get("authorization")?.replace(/^Bearer /, "");
  if (!token) return null;
  const { data } = await admin.auth.getUser(token);
  return data.user?.id ?? null;
}

async function contactSend(target: Target, targetHash: string, ipHash: string) {
  if (target.kind === "username") return json({ error: BAD_INPUT }, 400);
  if (!await allowedToSend(targetHash, ipHash)) return json({ error: TOO_MANY }, 429);
  const contact = target.kind === "mobile" ? target.phone : target.email;
  const code = await issue(targetHash, contact, "contact");
  if (target.kind === "mobile") await delivery.sms(contact, code);
  else await delivery.email(contact, code);
  return json({ sent: true });
}

async function contactVerify(userId: string, target: Target, code: string, targetHash: string) {
  if (target.kind === "username") return json({ error: BAD_INPUT }, 400);
  const { data: allowed } = await admin.rpc("login_gate_attempt", { p_target_hash: targetHash });
  if (!allowed) return json({ error: TOO_MANY }, 429);
  const { data: purpose } = /^\d{6}$/.test(code)
    ? await admin.rpc("login_code_check", {
      p_target_hash: targetHash,
      p_code_hash: await codeHash(targetHash, code),
    })
    : { data: null };
  if (purpose !== "contact") return json({ error: BAD_CODE }, 400);
  const { data: saved } = await admin.rpc("login_contact_set", {
    p_user: userId,
    p_kind: target.kind,
    p_value: target.kind === "mobile" ? target.phone : target.email,
  });
  // Same wording if another account holds it, so this cannot be used to probe.
  if (!saved) return json({ error: BAD_CODE }, 400);
  await admin.rpc("login_gate_clear", { p_target_hash: targetHash });
  return json({ saved: true });
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
  const code = (body.code ?? "").trim();

  switch (body.action) {
    case "send":
      return finish(await send(target, targetHash, ipHash));
    case "verify":
      return finish(await verify(target, code, targetHash));
    case "contact_send":
    case "contact_verify": {
      const userId = await caller(req);
      if (!userId) return finish(json({ error: BAD_INPUT }, 401));
      return finish(
        body.action === "contact_send"
          ? await contactSend(target, targetHash, ipHash)
          : await contactVerify(userId, target, code, targetHash),
      );
    }
    default:
      return finish(json({ error: BAD_INPUT }, 400));
  }
});
