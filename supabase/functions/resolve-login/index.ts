// Sign-in for the app. This function issues and checks every code, and Supabase
// Auth only creates the session at the end. Auth holds no real mobile or email,
// so nothing can be learned or bypassed by calling it directly. Unknown and
// known accounts get the same answer in the same time, and 5 wrong codes lock
// the target whether or not it is a real account.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { isLocalStack, liveDelivery, localDelivery } from "./delivery.ts";
import {
  alertText,
  BAD_CODE,
  BAD_INPUT,
  canonical,
  clientIp,
  paddingMs,
  parseIdentifier,
  sessionIdOf,
  sha256,
  STEP_UP,
  stepUpKey,
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
async function session(
  internalEmail: string,
): Promise<{ refreshToken: string; sessionId: string | null } | undefined> {
  const { data } = await admin.auth.admin.generateLink({
    type: "magiclink",
    email: internalEmail,
  });
  const tokenHash = data.properties?.hashed_token;
  if (!tokenHash) return undefined;
  const auth = createClient(url, anonKey, { auth: { persistSession: false } }).auth;
  const res = await auth.verifyOtp({
    token_hash: tokenHash,
    type: "magiclink",
  });
  const made = res.data.session;
  if (!made?.refresh_token) return undefined;
  return {
    refreshToken: made.refresh_token,
    sessionId: sessionIdOf(made.access_token),
  };
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
  const made = account ? await session(account.internal_email) : undefined;
  if (!account || !made) return json({ error: BAD_CODE }, 400);
  // A code just proved it is them, so this session may change a login contact
  // for a few minutes without proving it again (R-ACC-9, Q268).
  if (made.sessionId) {
    await admin.rpc("login_step_up_grant", {
      p_user: account.user_id,
      p_session: made.sessionId,
      // The kind of contact the code went to: a username's goes to its email,
      // or its mobile when it has none.
      p_kind: target.kind === "mobile" || (target.kind === "username" && !account.email) ? "mobile" : "email",
    });
  }
  await admin.rpc("login_gate_clear", { p_target_hash: targetHash });
  return json({ refresh_token: made.refreshToken });
}

interface Caller {
  userId: string;
  sessionId: string;
}

/** The signed-in person and their session, from their own token. */
async function caller(req: Request): Promise<Caller | null> {
  const token = req.headers.get("authorization")?.replace(/^Bearer /, "");
  if (!token) return null;
  // Supabase Auth checks the token; only then is its session id read.
  const { data } = await admin.auth.getUser(token);
  const sessionId = sessionIdOf(token);
  return data.user?.id && sessionId ? { userId: data.user.id, sessionId } : null;
}

/** Whether this session has just proved itself with the contact that
 * changing [changing] needs. */
async function steppedUp(me: Caller, changing: string): Promise<boolean> {
  const { data } = await admin.rpc("login_step_up_live", {
    p_user: me.userId,
    p_session: me.sessionId,
    p_changing: changing,
  });
  return data === true;
}

/** The contact on file that must prove a change of [changing]. */
async function proofContact(
  me: Caller,
  changing: string,
): Promise<{ kind: "mobile" | "email"; value: string } | null> {
  if (changing !== "mobile" && changing !== "email") return null;
  const { data } = await admin.rpc("login_proof_contact", { p_user: me.userId, p_changing: changing });
  return typeof data?.value === "string" && (data.kind === "mobile" || data.kind === "email") ? data : null;
}

/** "Confirm it's you": a code to the contact they already have (R-ACC-9). */
async function stepUpSend(me: Caller, changing: string, ipHash: string) {
  const proof = await proofContact(me, changing);
  if (!proof) return json({ error: BAD_INPUT }, 400);
  const key = await sha256(stepUpKey(me.userId, me.sessionId, proof.kind), pepper);
  if (!await allowedToSend(key, ipHash)) return json({ error: TOO_MANY }, 429);
  const code = await issue(key, proof.value, "step_up");
  const ok = proof.kind === "mobile"
    ? await delivery.sms(proof.value, code)
    : await delivery.email(proof.value, code);
  if (!ok) console.log(JSON.stringify({ event: "step_up_send_failed" }));
  // Which kind, never the contact itself (R-ACC-10).
  return json({ sent: true, via: proof.kind });
}

async function stepUpVerify(me: Caller, changing: string, code: string) {
  const proof = await proofContact(me, changing);
  if (!proof) return json({ error: BAD_INPUT }, 400);
  // The key names the kind of contact, so a code that went to the mobile can
  // never be entered as proof from the email.
  const key = await sha256(stepUpKey(me.userId, me.sessionId, proof.kind), pepper);
  // Counted before the code is checked, so parallel tries cannot all pass.
  const { data: allowed } = await admin.rpc("login_gate_attempt", { p_target_hash: key });
  if (!allowed) return json({ error: TOO_MANY }, 429);
  const { data: purpose } = /^\d{6}$/.test(code)
    ? await admin.rpc("login_code_check", {
      p_target_hash: key,
      p_code_hash: await codeHash(key, code),
    })
    : { data: null };
  if (purpose !== "step_up") return json({ error: BAD_CODE }, 400);
  await admin.rpc("login_step_up_grant", { p_user: me.userId, p_session: me.sessionId, p_kind: proof.kind });
  await admin.rpc("login_gate_clear", { p_target_hash: key });
  return json({ confirmed: true });
}

async function contactSend(
  me: Caller,
  target: Target,
  targetHash: string,
  ipHash: string,
) {
  if (target.kind === "username") return json({ error: BAD_INPUT }, 400);
  if (!await steppedUp(me, target.kind)) return json({ error: STEP_UP }, 403);
  if (!await allowedToSend(targetHash, ipHash)) {
    return json({ error: TOO_MANY }, 429);
  }
  const contact = target.kind === "mobile" ? target.phone : target.email;
  const code = await issue(targetHash, contact, "contact");
  if (target.kind === "mobile") await delivery.sms(contact, code);
  else await delivery.email(contact, code);
  return json({ sent: true });
}

async function contactVerify(
  me: Caller,
  target: Target,
  code: string,
  targetHash: string,
) {
  if (target.kind === "username") return json({ error: BAD_INPUT }, 400);
  // Before the code is looked at, so a session with no proof learns nothing
  // and uses nothing up.
  if (!await steppedUp(me, target.kind)) return json({ error: STEP_UP }, 403);
  const { data: allowed } = await admin.rpc("login_gate_attempt", {
    p_target_hash: targetHash,
  });
  if (!allowed) return json({ error: TOO_MANY }, 429);
  const { data: purpose } = /^\d{6}$/.test(code)
    ? await admin.rpc("login_code_check", {
      p_target_hash: targetHash,
      p_code_hash: await codeHash(targetHash, code),
    })
    : { data: null };
  if (purpose !== "contact") return json({ error: BAD_CODE }, 400);
  const { data: change } = await admin.rpc("login_contact_change", {
    p_user: me.userId,
    p_session: me.sessionId,
    p_kind: target.kind,
    p_value: target.kind === "mobile" ? target.phone : target.email,
  });
  // The proof ran out between the two checks.
  if (change?.status === "step_up") return json({ error: STEP_UP }, 403);
  // Same wording if another account holds it, so this cannot be used to probe.
  if (change?.status !== "ok") return json({ error: BAD_CODE }, 400);
  await admin.rpc("login_gate_clear", { p_target_hash: targetHash });
  // The old contact hears about it (or, for a first one, the other contact),
  // so a change they didn't make is never silent.
  if (typeof change.alert === "string") {
    const told = await delivery.alert(change.alert, alertText(target.kind, change.first === true));
    if (!told) console.log(JSON.stringify({ event: "contact_alert_failed" }));
  }
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

  let body: {
    action?: string;
    identifier?: string;
    code?: string;
    sign_up?: boolean;
    changing?: string;
  };
  try {
    body = await req.json();
  } catch {
    return finish(json({ error: BAD_INPUT }, 400));
  }

  // "Confirm it's you" names no contact: the server picks the one on file.
  if (body.action === "step_up_send" || body.action === "step_up_verify") {
    const me = await caller(req);
    if (!me) return finish(json({ error: BAD_INPUT }, 401));
    return finish(
      body.action === "step_up_send"
        ? await stepUpSend(
          me,
          body.changing ?? "",
          await sha256(clientIp(req.headers), pepper),
        )
        : await stepUpVerify(me, body.changing ?? "", (body.code ?? "").trim()),
    );
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
      const me = await caller(req);
      if (!me) return finish(json({ error: BAD_INPUT }, 401));
      return finish(
        body.action === "contact_send"
          ? await contactSend(me, target, targetHash, ipHash)
          : await contactVerify(me, target, code, targetHash),
      );
    }
    default:
      return finish(json({ error: BAD_INPUT }, 400));
  }
});
