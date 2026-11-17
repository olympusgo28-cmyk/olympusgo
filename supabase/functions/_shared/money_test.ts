import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { assertMinor, formatSgd } from "./money.ts";

Deno.test("prices read S$8.00", () => {
  assertEquals(formatSgd(800), "S$8.00");
  assertEquals(formatSgd(4840), "S$48.40");
  assertEquals(formatSgd(5), "S$0.05");
});

Deno.test("only whole minor units pass", () => {
  assertEquals(assertMinor(800), 800);
  assertThrows(() => assertMinor(8.5));
  assertThrows(() => assertMinor(-1));
  assertThrows(() => assertMinor("800"));
});
