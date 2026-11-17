import { assertEquals } from "jsr:@std/assert@1";
import { fcmSender, localSender } from "./sender.ts";

Deno.test("a local stack reports success and sends nothing", async () => {
  assertEquals(await localSender.send(["a"], "t", "b"), true);
});

Deno.test("no devices means nothing was delivered", async () => {
  assertEquals(await fcmSender("p", "k").send([], "t", "b"), false);
});
