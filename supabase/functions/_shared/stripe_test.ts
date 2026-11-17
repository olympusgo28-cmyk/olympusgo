import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import {
  liveStripe,
  localStripe,
  signPayload,
  StripeError,
  stripeFor,
  toMoneyEvent,
  verifySignature,
} from "./stripe.ts";

const secret = "whsec_test";
const now = 1_800_000_000;

Deno.test("a good signature passes", async () => {
  const header = await signPayload(secret, "{}", now);
  assertEquals(await verifySignature(secret, "{}", header, now), true);
});

Deno.test("a changed body fails", async () => {
  const header = await signPayload(secret, "{}", now);
  assertEquals(await verifySignature(secret, '{"amount":1}', header, now), false);
});

Deno.test("the wrong secret fails", async () => {
  const header = await signPayload("whsec_other", "{}", now);
  assertEquals(await verifySignature(secret, "{}", header, now), false);
});

Deno.test("an old signature fails", async () => {
  const header = await signPayload(secret, "{}", now - 301);
  assertEquals(await verifySignature(secret, "{}", header, now), false);
});

Deno.test("no signature fails", async () => {
  assertEquals(await verifySignature(secret, "{}", null, now), false);
});

const noKeys = () => undefined;

Deno.test("a local stack gets the stand-in", () => {
  assertEquals(stripeFor("http://127.0.0.1:54321", noKeys) !== null, true);
  assertEquals(stripeFor("http://kong:8000", noKeys) !== null, true);
});

Deno.test("hosted with no key gets nothing, so callers refuse", () => {
  assertEquals(stripeFor("https://abc.supabase.co", noKeys), null);
});

Deno.test("hosted never gets the stand-in's webhook secret", () => {
  const stripe = stripeFor(
    "https://abc.supabase.co",
    (key) => key === "STRIPE_SECRET_KEY" ? "sk_test_x" : undefined,
  );
  assertEquals(stripe?.webhookSecrets(), []);
});

Deno.test("a live key is refused", () => {
  assertEquals(liveStripe((key) => key === "STRIPE_SECRET_KEY" ? "sk_live_x" : undefined), null);
  assertEquals(liveStripe((key) => key === "STRIPE_SECRET_KEY" ? "rk_live_x" : undefined), null);
});

Deno.test("a test key is accepted", () => {
  assertEquals(liveStripe((key) => key === "STRIPE_SECRET_KEY" ? "sk_test_x" : undefined) !== null, true);
});

Deno.test("events keep no billing details", () => {
  const event = toMoneyEvent({
    id: "evt_1",
    type: "payment_intent.succeeded",
    data: {
      object: {
        id: "pi_1",
        amount: 800,
        amount_received: 800,
        currency: "sgd",
        latest_charge: "ch_1",
        payment_method_types: ["paynow"],
        metadata: { payment_id: "p" },
        receipt_email: "someone@example.com",
        shipping: { name: "A name", phone: "+6580000000" },
      },
    },
  });
  assertEquals(event.object, {
    id: "pi_1",
    metadata: { payment_id: "p" },
    amount: 800,
    currency: "sgd",
    latest_charge: "ch_1",
    payment_method_type: "paynow",
  });
});

Deno.test("a saved card keeps only its brand and last four", () => {
  const event = toMoneyEvent({
    id: "evt_2",
    type: "setup_intent.succeeded",
    data: {
      object: {
        id: "seti_1",
        customer: "cus_1",
        metadata: { user_id: "u" },
        payment_method: {
          id: "pm_1",
          card: { brand: "visa", last4: "4242", fingerprint: "abc", exp_year: 2030 },
          billing_details: { name: "A name" },
        },
      },
    },
  });
  assertEquals(event.object.card_last4, "4242");
  assertEquals(JSON.stringify(event).includes("A name"), false);
  assertEquals(JSON.stringify(event).includes("fingerprint"), false);
});

Deno.test("metadata keeps only our own ids", () => {
  const event = toMoneyEvent({
    id: "evt_3",
    type: "payment_intent.payment_failed",
    data: {
      object: {
        id: "pi_1",
        metadata: { payment_id: "p", email: "someone@example.com" },
        last_payment_error: { code: "card_declined" },
      },
    },
  });
  assertEquals(event.object.metadata, { payment_id: "p" });
});

Deno.test("a declined saved card raises its code", async () => {
  const stripe = localStripe("http://127.0.0.1:1/none");
  await assertRejects(
    () =>
      stripe.chargeOffSession({
        paymentId: "p",
        amountMinor: 200,
        currency: "SGD",
        customer: "c",
        paymentMethod: "pm_local_declined",
      }),
    StripeError,
    "card_declined",
  );
});
