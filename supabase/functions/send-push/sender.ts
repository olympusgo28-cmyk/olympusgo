// Sends a push. A local stack sends nothing. The real sender needs a Firebase
// project and has not been run against the real service.

export interface PushSender {
  send(tokens: string[], title: string, body: string): Promise<boolean>;
}

export const localSender: PushSender = { send: () => Promise.resolve(true) };

export function fcmSender(projectId: string, accessToken: string): PushSender {
  return {
    async send(tokens, title, body) {
      let ok = tokens.length > 0;
      for (const token of tokens) {
        const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
          method: "POST",
          headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
          body: JSON.stringify({ message: { token, notification: { title, body } } }),
        });
        await res.body?.cancel();
        ok = ok && res.ok;
      }
      return ok;
    },
  };
}
