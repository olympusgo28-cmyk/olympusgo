import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import {
  claimJob,
  finishCourt,
  frameBytes,
  resultProblem,
  STAND_IN_FRAME,
  standInReport,
  sweepClips,
} from "./clips.ts";
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

const report = standInReport();

Deno.test("a good court result passes", () => {
  assertEquals(resultProblem("court", true, { seconds: 60, corners: [[0, 0]] }, null), null);
  assertEquals(resultProblem("court", true, { seconds: 60, corners: null }, null), null);
});

Deno.test("a good report passes", () => assertEquals(resultProblem("analyse", true, report, null), null));

const bad: [string, unknown, unknown, unknown, unknown, string][] = [
  ["an unknown kind", "other", true, report, null, "kind"],
  ["a missing outcome", "court", "yes", report, null, "ok"],
  ["no result", "analyse", true, null, null, "result"],
  ["a court with no length", "court", true, {}, null, "seconds"],
  ["corners that aren't a list", "court", true, { seconds: 1, corners: "x" }, null, "corners"],
  ["a missing number", "analyse", true, { ...report, distance_m: "12" }, null, "distance_m"],
  ["a short heatmap", "analyse", true, { ...report, heatmap: [] }, null, "heatmap"],
  ["an opponent's numbers", "analyse", true, { ...report, opponent_distance_m: 5 }, null, "extra"],
  ["an image", "analyse", true, { ...report, frame: "abc" }, null, "extra"],
  ["an unknown error code", "court", false, null, "because", "code"],
];

for (const [name, kind, ok, result, code, problem] of bad) {
  Deno.test(`refuses ${name}`, () => assertEquals(resultProblem(kind, ok, result, code), problem));
}

Deno.test("known failures pass", () => {
  for (const code of ["internal", "bad_video", "too_long", "no_court", "no_player", "doubles"]) {
    assertEquals(resultProblem("analyse", false, null, code), null);
  }
});

Deno.test("the stand-in's report has the real shape", () => {
  assertEquals(report.heatmap.length, 13);
  assertEquals(report.heatmap.every((r) => r.length === 6), true);
});

function fake(
  rpc: Record<string, unknown>,
  removed: string[][] = [],
  removeFails = false,
  uploads: string[] = [],
) {
  const called: string[] = [];
  return {
    called,
    client: {
      rpc: (name: string) => {
        called.push(name);
        return Promise.resolve({ data: rpc[name] ?? null, error: null });
      },
      storage: {
        from: () => ({
          remove: (paths: string[]) => {
            removed.push(paths);
            return Promise.resolve({ error: removeFails ? new Error("no") : null });
          },
          createSignedUrl: () => Promise.resolve({ data: { signedUrl: "http://kong:8000/s/clip?token=a" } }),
          upload: (path: string) => {
            uploads.push(path);
            return Promise.resolve({ error: null });
          },
        }),
      },
    } as unknown as SupabaseClient,
  };
}

Deno.test("a sweep removes files, then clears them", async () => {
  const removed: string[][] = [];
  const f = fake({ analysis_svc_sweep: [{ id: 1, bucket: "analysis-clips", path: "a/b.mp4" }] }, removed);
  assertEquals(await sweepClips(f.client), { removed: 1 });
  assertEquals(removed, [["a/b.mp4"]]);
  assertEquals(f.called, [
    "analysis_svc_orphans",
    "feed_svc_sweep",
    "analysis_svc_sweep",
    "analysis_svc_removed",
  ]);
});

Deno.test("a failed removal stays queued", async () => {
  const f = fake({ analysis_svc_sweep: [{ id: 1, bucket: "analysis-clips", path: "a/b.mp4" }] }, [], true);
  await assertRejects(() => sweepClips(f.client));
  assertEquals(f.called, ["analysis_svc_orphans", "feed_svc_sweep", "analysis_svc_sweep"]);
});

Deno.test("a failing bucket leaves the other bucket's removals done", async () => {
  const cleared: unknown[] = [];
  const service = {
    rpc: (name: string, args?: { p_ids: number[] }) => {
      if (name === "analysis_svc_removed") cleared.push(args?.p_ids);
      const data = name === "analysis_svc_sweep"
        ? [
          { id: 1, bucket: "analysis-clips", path: "a/b.mp4" },
          { id: 2, bucket: "feed-videos", path: "c/d.mp4" },
          { id: 3, bucket: "feed-videos", path: "e/f.mp4" },
        ]
        : null;
      return Promise.resolve({ data, error: null });
    },
    storage: {
      from: (bucket: string) => ({
        remove: () => Promise.resolve({ error: bucket === "analysis-clips" ? new Error("no") : null }),
      }),
    },
  } as unknown as SupabaseClient;
  await assertRejects(() => sweepClips(service));
  assertEquals(cleared, [[2, 3]]);
});

Deno.test("an empty sweep touches nothing", async () => {
  const removed: string[][] = [];
  assertEquals(await sweepClips(fake({ analysis_svc_sweep: [] }, removed).client), { removed: 0 });
  assertEquals(removed, []);
});

Deno.test("a claim gives a worker nothing but this job", async () => {
  const job = await claimJob(
    fake({
      analysis_svc_claim: {
        job_id: "j",
        kind: "court",
        token: "t",
        timeout_seconds: 900,
        path: "o/c.mp4",
        frame_path: "o/c.frame.jpg",
        sport: "badminton",
        side: null,
        corners: null,
        max_seconds: 180,
      },
    }).client,
    "http://host.docker.internal:54321",
  );
  assertEquals(job?.clip_url, "http://host.docker.internal:54321/s/clip?token=a");
  assertEquals("frame_upload_url" in job!, false);
  assertEquals(Object.keys(job!).includes("path"), false);
});

Deno.test("only a JPEG is taken as a frame", () => {
  assertEquals(frameBytes(STAND_IN_FRAME) !== null, true);
  assertEquals(frameBytes(btoa("not a picture")), null);
  assertEquals(frameBytes("***"), null);
  assertEquals(frameBytes(42), null);
  assertEquals(frameBytes("a".repeat(3_000_000)), null);
});

const court = { job_id: "j", token: "t", result: { seconds: 30 }, worker_seconds: 1 };
const bytes = new Uint8Array([0xff, 0xd8, 0xff]);

Deno.test("a bad token writes no frame", async () => {
  const uploads: string[] = [];
  const f = fake({ analysis_svc_frame_path: null }, [], false, uploads);
  assertEquals(await finishCourt(f.client, court, bytes), { error: "Bad token.", code: "P0001" });
  assertEquals(uploads, []);
});

Deno.test("a good result keeps its frame", async () => {
  const removed: string[][] = [];
  const f = fake({ analysis_svc_frame_path: "o/c.frame.jpg", analysis_svc_result: "done" }, removed);
  assertEquals(await finishCourt(f.client, court, bytes), { status: "done" });
  assertEquals(removed, []);
});

Deno.test("a path in the request is ignored", async () => {
  const uploads: string[] = [];
  const f = fake(
    { analysis_svc_frame_path: "o/c.frame.jpg", analysis_svc_result: "done" },
    [],
    false,
    uploads,
  );
  await finishCourt(f.client, { ...court, frame_path: "victim/video.mp4" } as typeof court, bytes);
  assertEquals(uploads, ["o/c.frame.jpg"]);
});

Deno.test("a clip withdrawn meanwhile loses its frame", async () => {
  const removed: string[][] = [];
  const f = fake({ analysis_svc_frame_path: "o/c.frame.jpg", analysis_svc_result: "cancelled" }, removed);
  assertEquals(await finishCourt(f.client, court, bytes), { status: "cancelled" });
  assertEquals(removed, [["o/c.frame.jpg"]]);
});

Deno.test("no job, no claim", async () => {
  assertEquals(await claimJob(fake({}).client), null);
});
