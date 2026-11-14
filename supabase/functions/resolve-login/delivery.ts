// Sends codes. A local stack sends nothing and gives every mobile and email
// the same fixed code, so a tester can use any number. A hosted project never
// uses the local delivery, so the fixed code can never work there.

export interface Delivery {
  /** The code for this contact: fixed on a local stack, random when hosted. */
  codeFor(contact: string): string;
  sms(mobile: string, code: string): Promise<boolean>;
  email(address: string, code: string): Promise<boolean>;
  /** Tells a contact something with no code in it, such as "this was changed". */
  alert(contact: string, text: string): Promise<boolean>;
}

const TEST_CODE = "123456";

export { isLocalStack } from "../_shared/stack.ts";

export function randomCode(): string {
  const value = crypto.getRandomValues(new Uint32Array(1))[0] % 1_000_000;
  return value.toString().padStart(6, "0");
}

export const localDelivery: Delivery = {
  codeFor: () => TEST_CODE,
  sms: () => Promise.resolve(true),
  email: () => Promise.resolve(true),
  alert: () => Promise.resolve(true),
};

/** Real senders. Not yet run against the real services. */
export function liveDelivery(
  env: (key: string) => string | undefined,
): Delivery {
  async function text(mobile: string, body: string): Promise<boolean> {
    const sid = env("TWILIO_ACCOUNT_SID");
    const token = env("TWILIO_AUTH_TOKEN");
    const from = env("TWILIO_MESSAGING_SERVICE_SID");
    if (!sid || !token || !from) return false;
    const res = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
      {
        method: "POST",
        headers: {
          Authorization: `Basic ${btoa(`${sid}:${token}`)}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          To: mobile,
          MessagingServiceSid: from,
          Body: body,
        }),
      },
    );
    await res.body?.cancel();
    return res.ok;
  }

  async function mail(
    address: string,
    subject: string,
    body: string,
  ): Promise<boolean> {
    const key = env("RESEND_API_KEY");
    const from = env("LOGIN_EMAIL_FROM");
    if (!key || !from) return false;
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ from, to: address, subject, text: body }),
    });
    await res.body?.cancel();
    return res.ok;
  }

  return {
    codeFor: randomCode,
    sms: (mobile, code) => text(mobile, `Your OlympusGO code is ${code}`),
    email: (address, code) =>
      mail(
        address,
        "Your OlympusGO code",
        `Your OlympusGO code is ${code}. It works for 3 minutes.`,
      ),
    alert: (contact, body) =>
      contact.startsWith("+")
        ? text(contact, body)
        : mail(contact, "Your OlympusGO sign-in details changed", body),
  };
}
