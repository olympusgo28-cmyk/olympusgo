// Money crosses the wire as integer minor units. Anything else is a bug.

export function assertMinor(value: unknown): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value < 0) {
    throw new Error("Amounts must be whole minor units");
  }
  return value;
}

/** "S$8.00". Prices are shown this way everywhere. */
export function formatSgd(minor: number): string {
  const cents = assertMinor(minor);
  return `S$${Math.floor(cents / 100)}.${String(cents % 100).padStart(2, "0")}`;
}
