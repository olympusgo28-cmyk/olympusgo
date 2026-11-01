// A worker's side of the feed, shared by the real worker's API and the local
// stand-in. Workers send frames and hear nothing about the person. The
// verdicts go to the database, which decides what happens to the post.
import { decodeBase64 } from "jsr:@std/encoding@1/base64";
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { Checkers, FrameVerdict } from "./moderation.ts";
import { FEED_BUCKET, videoHost } from "./video_host.ts";

/** More frames than this can't be one short video. */
export const MAX_FRAMES = 300;

/** A JPEG of a sensible size, or null. */
function jpeg(base64: unknown): Uint8Array | null {
  if (typeof base64 !== "string" || base64.length < 8 || base64.length > 2_800_000) return null;
  let bytes: Uint8Array;
  try {
    bytes = decodeBase64(base64);
  } catch {
    return null;
  }
  return bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff ? bytes : null;
}

/** A worker's frames, or null if any isn't a JPEG. */
export function frameList(frames: unknown): Uint8Array[] | null {
  if (!Array.isArray(frames) || frames.length === 0 || frames.length > MAX_FRAMES) return null;
  const list = frames.map(jpeg);
  return list.every((f) => f !== null) ? list as Uint8Array[] : null;
}

export interface FeedJob {
  job_id: string;
  token: string;
  timeout_seconds: number;
  video_url: string;
  frames_per_second: number;
  max_seconds: number;
}

/** Claims the oldest post to check, or null when there's nothing to do. */
export async function claimPost(
  service: SupabaseClient,
  supabaseUrl: string,
  publicUrl?: string,
): Promise<FeedJob | null> {
  const { data: job, error } = await service.rpc("feed_svc_claim");
  if (error) throw new Error(`claim failed: ${error.code}`);
  if (!job) return null;
  return {
    job_id: job.job_id,
    token: job.token,
    timeout_seconds: job.timeout_seconds,
    video_url: await videoHost(job.host, service, supabaseUrl, publicUrl).readUrl(job.ref),
    frames_per_second: job.frames_per_second,
    max_seconds: job.max_seconds,
  };
}

interface Finish {
  job_id: string;
  token: string;
  worker_seconds: number;
}

/** The checks couldn't finish. The post waits or fails, and never goes through. */
export async function failPost(
  service: SupabaseClient,
  body: Finish,
  code: string,
): Promise<{ status: string } | { error: string; code?: string }> {
  const { data, error } = await service.rpc("feed_svc_result", {
    p_job: body.job_id,
    p_token: body.token,
    p_ok: false,
    p_hash: null,
    p_frames: null,
    p_checker: null,
    p_match_ref: null,
    p_poster: false,
    p_code: code,
    p_worker_seconds: body.worker_seconds,
  });
  if (error) return { error: error.message, code: error.code };
  return { status: data };
}

/**
 * Runs the checks and sends the verdict. The token is proved first, so a bad
 * one costs nothing. The hash match comes first, so a matched frame goes to no
 * other provider, and the poster is kept only for a post that passed.
 */
export async function finishPost(
  service: SupabaseClient,
  body: Finish,
  frames: Uint8Array[],
  pick: () => Checkers,
): Promise<{ status: string } | { error: string; code?: string }> {
  const { data: posterRef, error: jobError } = await service.rpc("feed_svc_job", {
    p_job: body.job_id,
    p_token: body.token,
  });
  if (jobError && jobError.code !== "P0001") return { error: "Try again" };
  if (typeof posterRef !== "string") return { error: "Bad token.", code: "P0001" };

  let name: string;
  let matched: boolean;
  let matchRef: string | undefined;
  let verdict: FrameVerdict = "clear";
  try {
    const checkers = pick();
    name = checkers.name;
    const hash = await checkers.hashes.match(frames);
    matched = hash.matched;
    matchRef = hash.ref;
    if (!matched) verdict = await checkers.frames.check(frames);
  } catch (e) {
    console.error("feed checks failed", (e as Error).name);
    return await failPost(service, body, "no_checker");
  }

  const files = service.storage.from(FEED_BUCKET);
  const keepPoster = !matched && verdict !== "reject";
  let poster = false;
  if (keepPoster) {
    const { error } = await files.upload(posterRef, frames[Math.floor(frames.length / 2)], {
      contentType: "image/jpeg",
      upsert: true,
    });
    poster = !error;
  }
  const { data, error } = await service.rpc("feed_svc_result", {
    p_job: body.job_id,
    p_token: body.token,
    p_ok: true,
    p_hash: matched ? "match" : "clear",
    p_frames: verdict,
    p_checker: name,
    p_match_ref: matchRef ?? null,
    p_poster: poster,
    p_code: null,
    p_worker_seconds: body.worker_seconds,
  });
  if (error) return { error: error.message, code: error.code };
  if (poster && data !== "live" && data !== "review") await files.remove([posterRef]);
  return { status: data };
}
