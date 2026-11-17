// Where feed videos live. Storage on a local stack, and nothing yet anywhere
// else: Cloudflare Stream goes here once there are keys. A hosted post can't
// reach a viewer until then, on purpose.
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { isLocalStack } from "./stack.ts";

export const FEED_BUCKET = "feed-videos";

/** How long a link for a worker to read a post lasts. */
const WORKER_URL_SECONDS = 300;

export interface VideoHost {
  /** Where to send the file, or null if it has already landed. */
  uploadTarget(ref: string): Promise<{ path: string; token: string } | null>;
  readUrl(ref: string, seconds?: number): Promise<string>;
}

class StorageHost implements VideoHost {
  constructor(private service: SupabaseClient, private publicUrl?: string) {}

  async uploadTarget(ref: string) {
    // No overwriting: the file that passes the checks is the file people see.
    const { data, error } = await this.service.storage.from(FEED_BUCKET).createSignedUploadUrl(ref);
    // A retry after the file landed and the next step didn't.
    if ((error as { statusCode?: string } | null)?.statusCode === "409") return null;
    if (error || !data) throw new Error("upload url failed");
    return { path: data.path, token: data.token };
  }

  async readUrl(ref: string, seconds = WORKER_URL_SECONDS) {
    const { data, error } = await this.service.storage.from(FEED_BUCKET).createSignedUrl(ref, seconds);
    if (error || !data) throw new Error("read url failed");
    return this.publicUrl ? data.signedUrl.replace(/^https?:\/\/[^/]+/, this.publicUrl) : data.signedUrl;
  }
}

/** The host a post names. Throws for anything with no working host. */
export function videoHost(
  kind: string,
  service: SupabaseClient,
  supabaseUrl: string,
  publicUrl?: string,
): VideoHost {
  if (kind !== "storage" || !isLocalStack(supabaseUrl)) throw new Error("no video host");
  return new StorageHost(service, publicUrl);
}
