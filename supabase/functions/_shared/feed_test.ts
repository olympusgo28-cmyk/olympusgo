import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { STAND_IN_FRAME } from "./clips.ts";
import { failPost, finishPost, frameList } from "./feed.ts";
import { type Checkers, fakeCheckers, pickCheckers } from "./moderation.ts";
import { videoHost } from "./video_host.ts";

const HOSTED = "https://abc.supabase.co";
const LOCAL = "http://kong:8000";

function fake(rpc: Record<string, unknown> = {}) {
  const calls: { name: string; args: Record<string, unknown> }[] = [];
  const uploads: string[] = [];
  const removed: string[][] = [];
  return {
    calls,
    uploads,
    removed,
    last: () => calls[calls.length - 1].args,
    client: {
      rpc: (name: string, args: Record<string, unknown>) => {
        calls.push({ name, args });
        const data = name in rpc ? rpc[name] : name === "feed_svc_job" ? "a/b.poster.jpg" : "live";
        return Promise.resolve({ data, error: null });
      },
      storage: {
        from: () => ({
          upload: (path: string) => {
            uploads.push(path);
            return Promise.resolve({ error: null });
          },
          remove: (paths: string[]) => {
            removed.push(paths);
            return Promise.resolve({ error: null });
          },
        }),
      },
    } as unknown as SupabaseClient,
  };
}

const frame = new Uint8Array([0xff, 0xd8, 0xff, 1]);
const body = { job_id: "j", token: "t", worker_seconds: 2 };

Deno.test("with nothing configured, hosted has no checks at all", () => {
  assertThrows(() => pickCheckers(HOSTED, undefined), Error, "no checker");
});

Deno.test("the fake can't be named into a hosted stack", () => {
  assertThrows(() => pickCheckers(HOSTED, "local-fake"), Error, "no checker");
});

Deno.test("an unknown provider is refused everywhere", () => {
  assertThrows(() => pickCheckers(LOCAL, "something-else"), Error, "no checker");
});

Deno.test("a named provider is used", () => {
  const real: Checkers = { ...fakeCheckers(), name: "real" };
  assertEquals(pickCheckers(HOSTED, "real", { real: () => real }).name, "real");
});

Deno.test("a local stack gets the fake", () => {
  assertEquals(pickCheckers(LOCAL, undefined).name, "local-fake");
});

Deno.test("hosted has no video host yet", () => {
  assertThrows(() => videoHost("storage", fake().client, HOSTED), Error, "no video host");
});

Deno.test("an unknown host is refused", () => {
  assertThrows(() => videoHost("other", fake().client, LOCAL), Error, "no video host");
});

Deno.test("frames must all be JPEGs", () => {
  assertEquals(frameList([STAND_IN_FRAME])?.length, 1);
  assertEquals(frameList([STAND_IN_FRAME, "bm90IGEgaW1hZ2U="]), null);
  assertEquals(frameList([]), null);
  assertEquals(frameList("no"), null);
  assertEquals(frameList(Array(301).fill(STAND_IN_FRAME)), null);
});

Deno.test("a bad token costs nothing", async () => {
  const f = fake({ feed_svc_job: null });
  let asked = false;
  const outcome = await finishPost(f.client, body, [frame], () => {
    asked = true;
    return fakeCheckers();
  });
  assertEquals(outcome, { error: "Bad token.", code: "P0001" });
  assertEquals(asked, false);
  assertEquals(f.uploads, []);
});

Deno.test("no checks means the post fails, and nothing passes it", async () => {
  const f = fake({ feed_svc_result: "retry" });
  const outcome = await finishPost(f.client, body, [frame], () => {
    throw new Error("no checker");
  });
  assertEquals(outcome, { status: "retry" });
  assertEquals(f.last().p_ok, false);
  assertEquals(f.last().p_code, "no_checker");
  assertEquals(f.uploads, []);
});

Deno.test("a provider failing partway fails the post too", async () => {
  const f = fake({ feed_svc_result: "retry" });
  const broken = fakeCheckers();
  broken.frames.check = () => Promise.reject(new Error("down"));
  await finishPost(f.client, body, [frame], () => broken);
  assertEquals(f.last().p_ok, false);
});

Deno.test("a match goes to no other check and keeps no poster", async () => {
  const f = fake({ feed_svc_result: "blocked" });
  let framesChecked = false;
  const checkers = fakeCheckers("clear", true);
  checkers.frames.check = () => {
    framesChecked = true;
    return Promise.resolve("clear");
  };
  assertEquals(await finishPost(f.client, body, [frame], () => checkers), { status: "blocked" });
  assertEquals(framesChecked, false);
  assertEquals(f.last().p_hash, "match");
  assertEquals(f.last().p_match_ref, "local-fake-match");
  assertEquals(f.uploads, []);
});

Deno.test("rejected frames keep no poster", async () => {
  const f = fake({ feed_svc_result: "rejected" });
  await finishPost(f.client, body, [frame], () => fakeCheckers("reject"));
  assertEquals(f.last().p_frames, "reject");
  assertEquals(f.uploads, []);
});

Deno.test("a clean post keeps the middle frame as its poster", async () => {
  const f = fake();
  assertEquals(await finishPost(f.client, body, [frame, frame, frame], () => fakeCheckers()), {
    status: "live",
  });
  assertEquals(f.uploads, ["a/b.poster.jpg"]);
  assertEquals(f.last().p_poster, true);
  assertEquals(f.removed, []);
});

Deno.test("a post deleted meanwhile loses its poster", async () => {
  const f = fake({ feed_svc_result: "deleted" });
  await finishPost(f.client, body, [frame], () => fakeCheckers());
  assertEquals(f.removed, [["a/b.poster.jpg"]]);
});

Deno.test("a failure reports its code", async () => {
  const f = fake({ feed_svc_result: "failed" });
  assertEquals(await failPost(f.client, body, "too_long"), { status: "failed" });
  assertEquals(f.last().p_code, "too_long");
});
