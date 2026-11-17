// The checks a post passes before anyone sees it. No provider is chosen yet
// (Q214), so the registry is empty. Hosted, that throws and the post fails, and
// a post that fails never goes live. The fake passes a post on a local stack
// only, and the database refuses it unless feed.fake_checks is on as well.
import { isLocalStack } from "./stack.ts";

export type FrameVerdict = "clear" | "flag" | "reject";

export interface HashResult {
  matched: boolean;
  ref?: string;
}

/** Checks frames against known child-abuse imagery. Always runs first. */
export interface HashMatcher {
  match(frames: Uint8Array[]): Promise<HashResult>;
}

/** Checks frames for what the rules don't allow. */
export interface FrameChecker {
  check(frames: Uint8Array[]): Promise<FrameVerdict>;
}

export interface Checkers {
  name: string;
  hashes: HashMatcher;
  frames: FrameChecker;
}

export const FAKE_CHECKER = "local-fake";

/** Real providers go here, by name. */
const PROVIDERS: Record<string, () => Checkers> = {};

export function fakeCheckers(frames: FrameVerdict = "clear", matched = false): Checkers {
  return {
    name: FAKE_CHECKER,
    hashes: { match: () => Promise.resolve({ matched, ref: matched ? "local-fake-match" : undefined }) },
    frames: { check: () => Promise.resolve(frames) },
  };
}

/** The checks to use. Throws when there's nothing real to run. */
export function pickCheckers(
  supabaseUrl: string,
  name: string | undefined,
  providers: Record<string, () => Checkers> = PROVIDERS,
): Checkers {
  if (isLocalStack(supabaseUrl) && (!name || name === FAKE_CHECKER)) return fakeCheckers();
  const provider = name ? providers[name] : undefined;
  if (!provider) throw new Error("no checker");
  return provider();
}
