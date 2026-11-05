/** True only on a local stack. Test paths hang off this, so they can't run hosted. */
export function isLocalStack(supabaseUrl: string): boolean {
  return ["kong", "127.0.0.1", "localhost"].includes(new URL(supabaseUrl).hostname);
}
