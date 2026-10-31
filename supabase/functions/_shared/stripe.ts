// Every Stripe call goes through this interface. A local stack uses the
// stand-in, which sends itself signed webhooks, so the whole money path runs
// without keys. Test mode only: the live adapter refuses anything but a test key.
import type { BalanceTxn, LedgerRow } from "./reconcile.ts";
import { isLocalStack } from "./stack.ts";

export interface MoneyEvent {
  id: string;
  type: string;
  object: Record<string, unknown>;
}

export interface Stripe {
  createIntent(input: {
    paymentId: string;
    amountMinor: number;
    currency: string;
    method: "card" | "paynow";
    customer?: string;
  }): Promise<{ intentId: string; clientSecret: string }>;
  cancelIntent(intentId: string): Promise<void>;
  createRefund(input: {
    refundId: string;
    attempt: number;
    intentId: string;
    amountMinor: number;
  }): Promise<{ id: string; status: string }>;
  chargeOffSession(input: {
    paymentId: string;
    amountMinor: number;
    currency: string;
    customer: string;
    paymentMethod: string;
  }): Promise<{ intentId: string }>;
  createCustomer(userId: string): Promise<string>;
  createSetup(input: { userId: string; customer: string }): Promise<{ clientSecret: string }>;
  /** Reuses [existing] if there is one, so a retry can't make a second account. */
  createAccount(
    ownerId: string,
    existing?: string,
  ): Promise<{ accountId: string; onboardingUrl: string | null }>;
  createTransfer(input: {
    itemId: string;
    amountMinor: number;
    currency: string;
    account: string;
  }): Promise<{ id: string }>;
  listBalanceTransactions(since: Date, ledger: LedgerRow[]): Promise<BalanceTxn[]>;
  /** Webhook secrets, one per endpoint. Empty when this project has none. */
  webhookSecrets(): string[];
  /** Fills in what Stripe sends only as ids, such as a charge's fee. */
  // deno-lint-ignore no-explicit-any
  enrich(event: any): Promise<any>;
}

/**
 * Stripe said no, so the call did nothing and it's safe to record a failure.
 * Anything else, such as a timeout or a 5xx, may have worked: the call stays
 * queued and the next tick repeats it with the same idempotency key.
 */
export class StripeError extends Error {
  constructor(readonly code: string) {
    super(code);
  }
}

const encoder = new TextEncoder();

async function hmac(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(payload));
  return [...new Uint8Array(signature)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export async function signPayload(secret: string, body: string, seconds: number): Promise<string> {
  return `t=${seconds},v1=${await hmac(secret, `${seconds}.${body}`)}`;
}

/** Stripe's scheme, for both adapters: HMAC of "timestamp.body", within 5 minutes. */
export async function verifySignature(
  secret: string,
  body: string,
  header: string | null,
  nowSeconds = Math.floor(Date.now() / 1000),
): Promise<boolean> {
  if (!header) return false;
  const parts = header.split(",").map((part) => part.split("=", 2) as [string, string]);
  const timestamp = Number(parts.find(([key]) => key === "t")?.[1]);
  if (!Number.isFinite(timestamp) || Math.abs(nowSeconds - timestamp) > 300) return false;
  const expected = await hmac(secret, `${timestamp}.${body}`);
  return parts.some(([key, value]) => key === "v1" && timingSafeEqual(value, expected));
}

export function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

// Only our own ids, whatever else metadata holds.
// deno-lint-ignore no-explicit-any
function ourMetadata(metadata: any) {
  const { payment_id, refund_id, user_id, owner_id } = metadata ?? {};
  return Object.fromEntries(
    Object.entries({ payment_id, refund_id, user_id, owner_id }).filter(([, value]) => value !== undefined),
  );
}

// Only what the database needs: no billing details reach the event log.
// deno-lint-ignore no-explicit-any
export function toMoneyEvent(event: any): MoneyEvent {
  const o = event.data?.object ?? {};
  const base = { id: o.id, metadata: ourMetadata(o.metadata) };
  const object: Record<string, unknown> = (() => {
    switch (event.type) {
      case "payment_intent.succeeded":
        return {
          ...base,
          amount: o.amount_received ?? o.amount,
          currency: o.currency,
          latest_charge: o.latest_charge,
          payment_method_type: o.payment_method_types?.[0],
        };
      case "payment_intent.payment_failed":
        return { ...base, failure_code: o.last_payment_error?.code ?? "failed" };
      case "charge.updated":
        return { id: o.id, payment_intent: o.payment_intent, fee_minor: o.balance_transaction?.fee ?? null };
      case "refund.created":
      case "refund.updated":
      case "refund.failed":
      case "charge.refund.updated":
        return { ...base, status: o.status, failure_reason: o.failure_reason };
      case "setup_intent.succeeded":
        return {
          ...base,
          customer: o.customer,
          payment_method: o.payment_method?.id ?? o.payment_method,
          card_brand: o.payment_method?.card?.brand,
          card_last4: o.payment_method?.card?.last4,
        };
      case "charge.dispute.created":
      case "charge.dispute.closed":
        return { id: o.id, charge: o.charge, amount: o.amount, status: o.status };
      case "account.updated":
        return { id: o.id, payouts_enabled: o.payouts_enabled };
      default:
        return base;
    }
  })();
  return { id: event.id, type: event.type, object };
}

// Stand-in ------------------------------------------------------------------

const LOCAL_WEBHOOK_SECRET = "whsec_local_stand_in_only";
export const LOCAL_WORKER_SECRET = "local-worker-secret";

/** A pretend fee, for the local stand-in only. Real fees always come from Stripe. */
export function standInFee(amountMinor: number, method: string): number {
  return method === "card" ? Math.round(amountMinor * 0.034 + 50) : Math.round(amountMinor * 0.013);
}

/** Sends a signed event to our own webhook, as Stripe would. */
export async function fireLocalEvent(webhookUrl: string, event: unknown): Promise<Response> {
  const body = JSON.stringify(event);
  const signature = await signPayload(LOCAL_WEBHOOK_SECRET, body, Math.floor(Date.now() / 1000));
  return fetch(webhookUrl, { method: "POST", body, headers: { "stripe-signature": signature } });
}

export function localEvent(type: string, object: unknown) {
  return { id: `evt_local_${crypto.randomUUID()}`, type, data: { object } };
}

export function localStripe(webhookUrl: string): Stripe {
  const fire = async (type: string, object: unknown) => {
    await (await fireLocalEvent(webhookUrl, localEvent(type, object))).text();
  };
  return {
    createIntent: ({ paymentId }) =>
      Promise.resolve({ intentId: `pi_local_${paymentId}`, clientSecret: `local_secret_${paymentId}` }),
    cancelIntent: () => Promise.resolve(),
    async createRefund({ refundId }) {
      const id = `re_local_${refundId}`;
      await fire("refund.updated", { id, status: "succeeded", metadata: { refund_id: refundId } });
      return { id, status: "succeeded" };
    },
    async chargeOffSession({ paymentId, amountMinor, currency, paymentMethod }) {
      if (paymentMethod === "pm_local_declined") throw new StripeError("card_declined");
      const intentId = `pi_local_${paymentId}`;
      const charge = `ch_local_${paymentId}`;
      await fire("payment_intent.succeeded", {
        id: intentId,
        amount: amountMinor,
        currency: currency.toLowerCase(),
        latest_charge: charge,
        payment_method_types: ["card"],
        metadata: { payment_id: paymentId },
      });
      await fire("charge.updated", {
        id: charge,
        balance_transaction: { fee: standInFee(amountMinor, "card") },
      });
      return { intentId };
    },
    createCustomer: (userId) => Promise.resolve(`cus_local_${userId}`),
    createSetup: ({ customer }) => Promise.resolve({ clientSecret: `local_setup_${customer}` }),
    async createAccount(ownerId, existing) {
      return await Promise.resolve({ accountId: existing ?? `acct_local_${ownerId}`, onboardingUrl: null });
    },
    createTransfer: ({ itemId }) => Promise.resolve({ id: `tr_local_${itemId}` }),
    listBalanceTransactions: (_since, ledger) =>
      Promise.resolve(
        ledger.map((row) => ({
          source: row.source,
          amount_minor: row.amount_minor,
          fee_minor: row.fee_minor ?? 0,
        })),
      ),
    webhookSecrets: () => [LOCAL_WEBHOOK_SECRET],
    enrich: (event) => Promise.resolve(event),
  };
}

// Live, in test mode. Written against Stripe's API but not yet run.
export function liveStripe(env: (key: string) => string | undefined): Stripe | null {
  const key = env("STRIPE_SECRET_KEY");
  if (!key?.startsWith("sk_test_")) return null;

  async function call(
    method: string,
    path: string,
    form?: Record<string, string>,
    idempotencyKey?: string,
    // deno-lint-ignore no-explicit-any
  ): Promise<any> {
    const response = await fetch(`https://api.stripe.com/v1/${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/x-www-form-urlencoded",
        ...(idempotencyKey ? { "Idempotency-Key": idempotencyKey } : {}),
      },
      body: form ? new URLSearchParams(form).toString() : undefined,
    });
    const data = await response.json();
    if (response.ok) return data;
    // 409 is a clash on an idempotency key and 429 is rate limiting, so the
    // first call may still land. Only a plain refusal is final.
    const refused = response.status >= 400 && response.status < 500 && ![409, 429].includes(response.status);
    if (refused) throw new StripeError(data?.error?.code ?? "stripe_refused");
    throw new Error(`Stripe answered ${response.status}`);
  }

  return {
    async createIntent({ paymentId, amountMinor, currency, method, customer }) {
      const intent = await call("POST", "payment_intents", {
        amount: String(amountMinor),
        currency: currency.toLowerCase(),
        "payment_method_types[0]": method,
        "metadata[payment_id]": paymentId,
        ...(customer ? { customer } : {}),
      }, `intent:${paymentId}`);
      return { intentId: intent.id, clientSecret: intent.client_secret };
    },
    async cancelIntent(intentId) {
      await call("POST", `payment_intents/${intentId}/cancel`, {});
    },
    async createRefund({ refundId, attempt, intentId, amountMinor }) {
      // Stripe replays a key's first answer, so a staff retry needs a new one.
      const refund = await call("POST", "refunds", {
        payment_intent: intentId,
        amount: String(amountMinor),
        "metadata[refund_id]": refundId,
      }, `refund:${refundId}:${attempt}`);
      return { id: refund.id, status: refund.status };
    },
    async chargeOffSession({ paymentId, amountMinor, currency, customer, paymentMethod }) {
      const intent = await call("POST", "payment_intents", {
        amount: String(amountMinor),
        currency: currency.toLowerCase(),
        customer,
        payment_method: paymentMethod,
        off_session: "true",
        confirm: "true",
        "metadata[payment_id]": paymentId,
      }, `orgfee:${paymentId}`);
      return { intentId: intent.id };
    },
    async createCustomer(userId) {
      return (await call("POST", "customers", { "metadata[user_id]": userId }, `customer:${userId}`)).id;
    },
    async createSetup({ userId, customer }) {
      const setup = await call("POST", "setup_intents", {
        customer,
        "payment_method_types[0]": "card",
        usage: "off_session",
        "metadata[user_id]": userId,
      });
      return { clientSecret: setup.client_secret };
    },
    async createAccount(ownerId, existing) {
      const accountId = existing ?? (await call("POST", "accounts", {
        type: "express",
        country: "SG",
        "capabilities[transfers][requested]": "true",
        "metadata[owner_id]": ownerId,
      }, `account:${ownerId}`)).id;
      const returnUrl = env("STRIPE_CONNECT_RETURN_URL") ?? "";
      const link = await call("POST", "account_links", {
        account: accountId,
        type: "account_onboarding",
        return_url: returnUrl,
        refresh_url: returnUrl,
      });
      return { accountId, onboardingUrl: link.url };
    },
    async createTransfer({ itemId, amountMinor, currency, account }) {
      const transfer = await call("POST", "transfers", {
        amount: String(amountMinor),
        currency: currency.toLowerCase(),
        destination: account,
        "metadata[item_id]": itemId,
      }, `transfer:${itemId}`);
      return { id: transfer.id };
    },
    async listBalanceTransactions(since) {
      const created = Math.floor(since.getTime() / 1000);
      const rows: BalanceTxn[] = [];
      let after: string | undefined;
      while (true) {
        const page = await call(
          "GET",
          `balance_transactions?limit=100&created[gte]=${created}${after ? `&starting_after=${after}` : ""}`,
        );
        // deno-lint-ignore no-explicit-any
        for (const t of page.data as any[]) {
          rows.push({ source: t.source, amount_minor: t.amount, fee_minor: t.fee });
        }
        if (!page.has_more) return rows;
        after = page.data[page.data.length - 1].id;
      }
    },
    // Connected-account events come to their own endpoint, with their own secret.
    webhookSecrets: () =>
      [env("STRIPE_WEBHOOK_SECRET"), env("STRIPE_CONNECT_WEBHOOK_SECRET")].filter((s): s is string => !!s),
    // Webhooks carry ids, not the objects behind them.
    async enrich(event) {
      const o = event.data?.object ?? {};
      if (event.type === "charge.updated" && typeof o.balance_transaction === "string") {
        o.balance_transaction = await call("GET", `balance_transactions/${o.balance_transaction}`);
      }
      if (event.type === "setup_intent.succeeded" && typeof o.payment_method === "string") {
        o.payment_method = await call("GET", `payment_methods/${o.payment_method}`);
      }
      return event;
    },
  };
}

/** The adapter for this stack. Hosted with no test key gives null, so callers refuse. */
export function stripeFor(supabaseUrl: string, env: (key: string) => string | undefined): Stripe | null {
  if (isLocalStack(supabaseUrl)) {
    return localStripe(`${supabaseUrl}/functions/v1/stripe-webhook`);
  }
  return liveStripe(env);
}
