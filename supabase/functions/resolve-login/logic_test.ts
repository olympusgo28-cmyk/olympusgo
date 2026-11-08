import { assertEquals, assertNotEquals } from "jsr:@std/assert@1";
import { isLocalStack, liveDelivery, localDelivery, randomCode } from "./delivery.ts";
import { canonical, clientIp, paddingMs, parseIdentifier, sha256 } from "./logic.ts";

Deno.test("reads a mobile number and drops spaces", () => {
  assertEquals(parseIdentifier("+65 9123 4567"), { kind: "mobile", phone: "+6591234567" });
});

Deno.test("reads an email and lowers its case", () => {
  assertEquals(parseIdentifier(" Mei@Example.COM "), { kind: "email", email: "mei@example.com" });
});

Deno.test("reads a username", () => {
  assertEquals(parseIdentifier("mei_tan"), { kind: "username", username: "mei_tan" });
});

Deno.test("refuses what can be none of the three", () => {
  assertEquals(parseIdentifier("+12"), null);
  assertEquals(parseIdentifier("a b"), null);
  assertEquals(parseIdentifier(""), null);
});

Deno.test("the same person counts once however they type it", () => {
  assertEquals(canonical(parseIdentifier("MEI_TAN")!), canonical(parseIdentifier("mei_tan")!));
  assertEquals(canonical(parseIdentifier("+65 9123 4567")!), canonical(parseIdentifier("+6591234567")!));
});

Deno.test("hashes differ by pepper and never contain the input", async () => {
  const a = await sha256("mobile:+6591234567", "one");
  const b = await sha256("mobile:+6591234567", "two");
  assertNotEquals(a, b);
  assertEquals(a.includes("6591234567"), false);
});

Deno.test("padding fills the remaining time and never goes negative", () => {
  assertEquals(paddingMs(1000, 1200, 900), 700);
  assertEquals(paddingMs(1000, 3000, 900), 0);
});

Deno.test("a caller cannot choose their own address", () => {
  assertEquals(clientIp(new Headers({ "x-forwarded-for": "1.1.1.1, 9.9.9.9" })), "9.9.9.9");
  assertEquals(
    clientIp(new Headers({ "x-forwarded-for": "1.1.1.1", "cf-connecting-ip": "8.8.8.8" })),
    "8.8.8.8",
  );
  assertEquals(clientIp(new Headers()), "unknown");
});

Deno.test("the fixed code exists only on a local stack, for any contact", () => {
  assertEquals(isLocalStack("http://kong:8000"), true);
  assertEquals(isLocalStack("http://127.0.0.1:54321"), true);
  assertEquals(isLocalStack("https://abc.supabase.co"), false);
  assertEquals(localDelivery.codeFor("+6580000001"), "123456");
  assertEquals(localDelivery.codeFor("+6591234567"), "123456");
  assertEquals(localDelivery.codeFor("someone@example.com"), "123456");
  // A hosted project's codes are random, so they almost never match.
  const live = liveDelivery(() => undefined);
  const fixed = Array.from({ length: 20 }, () => live.codeFor("+6591234567"))
    .filter((c) => c === "123456");
  assertEquals(fixed.length < 2, true);
});

Deno.test("codes are six digits, padded", () => {
  for (let i = 0; i < 200; i++) assertEquals(/^\d{6}$/.test(randomCode()), true);
});

Deno.test("live delivery reports failure when its keys are missing", async () => {
  const live = liveDelivery(() => undefined);
  assertEquals(await live.sms("+6591234567", "123456"), false);
  assertEquals(await live.email("a@example.com", "123456"), false);
});
