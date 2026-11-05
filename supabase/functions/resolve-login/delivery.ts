// Sends codes. A local stack sends nothing and uses fixed codes for test
// contacts, so no test code can ever work on a hosted project.

export interface Delivery {
  /** The code for this contact: fixed on a local stack, otherwise random. */
  codeFor(contact: string): string;
  sms(mobile: string, code: string): Promise<boolean>;
  email(address: string, code: string): Promise<boolean>;
}

const TEST_CODE = "123456";

export { isLocalStack } from "../_shared/stack.ts";

export function randomCode(): string {
  const value = crypto.getRandomValues(new Uint32Array(1))[0] % 1_000_000;
  return value.toString().padStart(6, "0");
}

export function isTestContact(contact: string): boolean {
  return /^\+6580000\d{3}$/.test(contact) || contact.endsWith("@test.local");
}

export const localDelivery: Delivery = {
  codeFor: (contact) => (isTestContact(contact) ? TEST_CODE : randomCode()),
  sms: () => Promise.resolve(true),
  email: () => Promise.resolve(true),
};

/** Real senders. Not yet run against the real services. */
export function liveDelivery(env: (key: string) => string | undefined): Delivery {
  return {
    codeFor: randomCode,
    async sms(mobile, code) {
      const sid = env("TWILIO_ACCOUNT_SID");
      const token = env("TWILIO_AUTH_TOKEN");
      const from = env("TWILIO_MESSAGING_SERVICE_SID");
      if (!sid || !token || !from) return false;
      const res = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`, {
        method: "POST",
        headers: {
          Authorization: `Basic ${btoa(`${sid}:${token}`)}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          To: mobile,
          MessagingServiceSid: from,
          Body: `Your OlympusGO code is ${code}`,
        }),
      });
      await res.body?.cancel();
      return res.ok;
    },
    async email(address, code) {
      const key = env("RESEND_API_KEY");
      const from = env("LOGIN_EMAIL_FROM");
      if (!key || !from) return false;
      const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          from,
          to: address,
          subject: "Your OlympusGO code",
          text: `Your OlympusGO code is ${code}. It works for 10 minutes.`,
        }),
      });
      await res.body?.cancel();
      return res.ok;
    },
  };
}
