// The worker's side of clip analysis, shared by the real worker's API and the
// local stand-in. Workers get a signed URL and a token for one job, never a
// service key or a way to write to Storage. The database checks every result
// again.
import { decodeBase64 } from "jsr:@std/encoding@1/base64";
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

export const CLIPS_BUCKET = "analysis-clips";

/** How long a worker can read a clip or write its frame. */
export const SIGNED_URL_SECONDS = 900;

export interface WorkerJob {
  job_id: string;
  kind: "court" | "analyse";
  token: string;
  timeout_seconds: number;
  clip_url: string;
  sport: string;
  side: string | null;
  corners: unknown;
  max_seconds: number;
}

const CODES = new Set(["internal", "bad_video", "too_long", "no_court", "no_player", "doubles"]);

/** What's wrong with a worker's result, or null if it can go to the database. */
export function resultProblem(kind: unknown, ok: unknown, result: unknown, code: unknown): string | null {
  if (kind !== "court" && kind !== "analyse") return "kind";
  if (typeof ok !== "boolean") return "ok";
  if (!ok) return typeof code === "string" && CODES.has(code) ? null : "code";
  if (typeof result !== "object" || result === null) return "result";
  const r = result as Record<string, unknown>;
  if (kind === "court") {
    if (typeof r.seconds !== "number") return "seconds";
    if (r.corners !== null && r.corners !== undefined && !Array.isArray(r.corners)) return "corners";
    return null;
  }
  for (const field of ["distance_m", "avg_speed_ms", "top_speed_ms", "moving_seconds"]) {
    if (typeof r[field] !== "number") return field;
  }
  if (!Array.isArray(r.heatmap) || r.heatmap.length !== 13) return "heatmap";
  // Only these fields reach the database, so nothing else can be stored.
  const known = new Set(["distance_m", "avg_speed_ms", "top_speed_ms", "moving_seconds", "heatmap"]);
  return Object.keys(r).every((k) => known.has(k)) ? null : "extra";
}

/** The biggest court frame a worker can send, in base64 characters. */
export const MAX_FRAME_BASE64 = 2_800_000;

/** A JPEG, of a sensible size, or null. Nothing else reaches the bucket. */
export function frameBytes(base64: unknown): Uint8Array | null {
  if (typeof base64 !== "string" || base64.length < 8 || base64.length > MAX_FRAME_BASE64) return null;
  let bytes: Uint8Array;
  try {
    bytes = decodeBase64(base64);
  } catch {
    return null;
  }
  return bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff ? bytes : null;
}

/**
 * Stores a job's frame and sends its result. The frame goes in only once the
 * token has proved the job, and comes straight back out if the clip was
 * withdrawn meanwhile.
 */
export async function finishCourt(
  service: SupabaseClient,
  body: { job_id: string; token: string; result: unknown; worker_seconds: number },
  frame: Uint8Array,
): Promise<{ status: string } | { error: string; code?: string }> {
  // The path comes from the database, so a worker can only ever write its own
  // job's frame.
  const { data: path, error: pathError } = await service.rpc("analysis_svc_frame_path", {
    p_job: body.job_id,
    p_token: body.token,
  });
  // A database hiccup isn't a verdict on the token, so the worker tries again.
  if (pathError && pathError.code !== "P0001") return { error: "Try again" };
  if (typeof path !== "string") return { error: "Bad token.", code: "P0001" };
  const files = service.storage.from(CLIPS_BUCKET);
  const { error: uploadError } = await files.upload(path, frame, {
    contentType: "image/jpeg",
    upsert: true,
  });
  if (uploadError) return { error: "Try again" };
  const { data, error } = await service.rpc("analysis_svc_result", {
    p_job: body.job_id,
    p_token: body.token,
    p_ok: true,
    p_result: body.result,
    p_code: null,
    p_worker_seconds: body.worker_seconds,
  });
  if (error) return { error: error.message, code: error.code };
  if (data !== "done") await files.remove([path]);
  return { status: data };
}

/** Claims the oldest job, or null when there's nothing to do. */
export async function claimJob(service: SupabaseClient, publicUrl?: string): Promise<WorkerJob | null> {
  const { data: job, error } = await service.rpc("analysis_svc_claim");
  if (error) throw new Error(`claim failed: ${error.code}`);
  if (!job) return null;
  const files = service.storage.from(CLIPS_BUCKET);
  const { data: read, error: readError } = await files.createSignedUrl(job.path, SIGNED_URL_SECONDS);
  if (readError || !read) throw new Error("clip url failed");
  const outward = (u: string) => publicUrl ? u.replace(/^https?:\/\/[^/]+/, publicUrl) : u;
  return {
    job_id: job.job_id,
    kind: job.kind,
    token: job.token,
    timeout_seconds: job.timeout_seconds,
    clip_url: outward(read.signedUrl),
    sport: job.sport,
    side: job.side,
    corners: job.corners,
    max_seconds: job.max_seconds,
  };
}

/** Removes files that are due. A failed removal stays queued for the next run. */
export async function sweepClips(service: SupabaseClient): Promise<{ removed: number }> {
  // Only the safety net, so its failure can't stop a purge.
  await service.rpc("analysis_svc_orphans");
  const { data, error } = await service.rpc("analysis_svc_sweep");
  if (error) throw new Error(`sweep failed: ${error.code}`);
  const due = data as { id: number; bucket: string; path: string }[];
  if (due.length === 0) return { removed: 0 };
  // One bucket's failure leaves its own files queued, not the other's.
  const gone: number[] = [];
  let failed = false;
  for (const bucket of new Set(due.map((d) => d.bucket))) {
    const files = due.filter((d) => d.bucket === bucket);
    const { error: removeError } = await service.storage.from(bucket).remove(files.map((d) => d.path));
    if (removeError) failed = true;
    else gone.push(...files.map((d) => d.id));
  }
  if (gone.length > 0) {
    const { error: doneError } = await service.rpc("analysis_svc_removed", { p_ids: gone });
    if (doneError) throw new Error(`removed failed: ${doneError.code}`);
  }
  if (failed) throw new Error("remove failed");
  return { removed: gone.length };
}

/** A plain drawn court, for the local stand-in. It shows no person. */
export const STAND_IN_FRAME =
  "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";

/** The local stand-in's numbers, the same shape as the real worker's. */
export function standInReport() {
  return {
    distance_m: 412.5,
    avg_speed_ms: 1.6,
    top_speed_ms: 4.1,
    moving_seconds: 48,
    heatmap: Array.from(
      { length: 13 },
      (_, r) =>
        Array.from({ length: 6 }, (_, c) => Math.max(0, 12 - Math.abs(r - 9) * 2 - Math.abs(c - 2) * 2)),
    ),
  };
}
