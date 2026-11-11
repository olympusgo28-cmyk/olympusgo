// The parts of sign-in that need no network, kept apart so they can be tested.

export type Target =
  | { kind: "mobile"; phone: string }
  | { kind: "email"; email: string }
  | { kind: "username"; username: string };

/** Works out what someone typed. Null if it cannot be any of the three. */
export function parseIdentifier(raw: string): Target | null {
  const value = raw.trim();
  if (value.startsWith("+")) {
    const digits = value.slice(1).replace(/[\s-]/g, "");
    return /^[1-9]\d{6,14}$/.test(digits) ? { kind: "mobile", phone: `+${digits}` } : null;
  }
  if (/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value)) {
    return { kind: "email", email: value.toLowerCase() };
  }
  if (/^[A-Za-z0-9_]{3,30}$/.test(value)) {
    return { kind: "username", username: value };
  }
  return null;
}

/** The form used for limits: never stored or logged as typed. */
export function canonical(target: Target): string {
  switch (target.kind) {
    case "mobile":
      return `mobile:${target.phone}`;
    case "email":
      return `email:${target.email}`;
    case "username":
      return `username:${target.username.toLowerCase()}`;
  }
}

export async function sha256(value: string, pepper: string): Promise<string> {
  const bytes = new TextEncoder().encode(`${pepper}:${value}`);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/** How long to wait so a reply takes padMs in total. */
export function paddingMs(startedAt: number, now: number, padMs: number): number {
  return Math.max(0, padMs - (now - startedAt));
}

/** The caller's address. The left of x-forwarded-for is whatever they sent. */
export function clientIp(headers: Headers): string {
  const hops = (headers.get("x-forwarded-for") ?? "").split(",").map((h) => h.trim()).filter(Boolean);
  return headers.get("cf-connecting-ip") ?? hops.at(-1) ?? "unknown";
}

/** The session a signed token belongs to. Only call this on a token Supabase
 * Auth has already checked: nothing here verifies the signature. */
export function sessionIdOf(token: string): string | null {
  try {
    const part = token.split(".")[1] ?? "";
    const text = atob(
      part.replace(/-/g, "+").replace(/_/g, "/").padEnd(
        Math.ceil(part.length / 4) * 4,
        "=",
      ),
    );
    const id = JSON.parse(text).session_id;
    return typeof id === "string" && /^[0-9a-f-]{36}$/.test(id) ? id : null;
  } catch {
    return null;
  }
}

/** What the limits and codes for "confirm it's you" hang on: this player in
 * this session, and the kind of contact the code went to. So one session's
 * wrong tries never lock another's, and a code sent to the mobile can only
 * ever prove the mobile. */
export function stepUpKey(userId: string, sessionId: string, kind: "mobile" | "email"): string {
  return `step_up:${userId}:${sessionId}:${kind}`;
}

/** What a contact is told when a login contact changes or one is added
 * (R-ACC-9). No code and no contact in it. */
export function alertText(changed: "mobile" | "email", first = false): string {
  const what = changed === "mobile" ? "mobile number" : "email";
  return (first
    ? `${changed === "mobile" ? "A" : "An"} ${what} was added to your OlympusGO login. `
    : `Your OlympusGO login ${what} was changed. `) +
    "If this wasn't you, open Help in the app straight away.";
}

export const BAD_CODE = "That code didn't work. Check it and try again.";
/** Not a sentence: the app shows its "Confirm it's you" step on this. */
export const STEP_UP = "step_up";
export const TOO_MANY = "Too many tries. Wait a while, then try again.";
export const BAD_INPUT = "Check what you entered and try again.";
