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

export const BAD_CODE = "That code didn't work. Check it and try again.";
export const TOO_MANY = "Too many tries. Wait a while, then try again.";
export const BAD_INPUT = "Check what you entered and try again.";
