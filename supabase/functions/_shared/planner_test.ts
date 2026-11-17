import { assertEquals } from "jsr:@std/assert@1";
import {
  claudePlanner,
  localPlanner,
  type Plan,
  type PlanInput,
  type Planner,
  plannerFor,
  planWithRetry,
  validatePlan,
} from "./planner.ts";

const input: PlanInput = {
  goal: "speed",
  days: 2,
  summary: { workouts_28_days: 1, exercises: [] },
  catalogue: [
    {
      slug: "push-up",
      name: "Push-up",
      group: "upper",
      equipment: "Bodyweight",
      unit: "reps",
      weighted: false,
    },
    {
      slug: "plank",
      name: "Plank",
      group: "core",
      equipment: "Bodyweight",
      unit: "seconds",
      weighted: false,
    },
    {
      slug: "back-squat",
      name: "Back squat",
      group: "legs",
      equipment: "Barbell",
      unit: "reps",
      weighted: true,
    },
  ],
};

const good = (): Plan => ({
  name: "Court plan",
  days: [1, 2].map((n) => ({
    name: `Day ${n}`,
    items: [
      { exercise: "push-up", sets: 3, reps: 10, seconds: null, rest_seconds: 60 },
      { exercise: "plank", sets: 3, reps: null, seconds: 45, rest_seconds: 60 },
    ],
  })),
});

const signal = new AbortController().signal;
const yes = () => Promise.resolve(true);

Deno.test("a good plan passes", () => assertEquals(validatePlan(good(), input), null));

const bad: [string, (p: Plan) => void, string][] = [
  ["no name", (p) => p.name = " ", "name"],
  ["a long name", (p) => p.name = "x".repeat(61), "name"],
  ["too few days", (p) => p.days.pop(), "days"],
  ["a long day name", (p) => p.days[0].name = "x".repeat(61), "day name"],
  ["a claim in the name", (p) => p.name = "Burn fat fast", "name"],
  ["calories in a day", (p) => p.days[0].name = "500 kcal circuit", "day name"],
  ["a recovery claim", (p) => p.days[0].name = "Recovery day", "day name"],
  ["a weight in a name", (p) => p.days[0].name = "Squat 100kg", "day name"],
  ["an empty day", (p) => p.days[0].items = [], "day items"],
  ["a made-up exercise", (p) => p.days[0].items[0].exercise = "made-up", "exercise"],
  ["a weight", (p) => Object.assign(p.days[0].items[0], { weight_g: 100000 }), "weight"],
  ["too many sets", (p) => p.days[0].items[0].sets = 21, "sets"],
  ["no sets", (p) => p.days[0].items[0].sets = 0, "sets"],
  ["half a set", (p) => p.days[0].items[0].sets = 1.5, "sets"],
  ["too much rest", (p) => p.days[0].items[0].rest_seconds = 901, "rest"],
  ["reps missing", (p) => p.days[0].items[0].reps = null, "amount"],
  ["too many reps", (p) => p.days[0].items[0].reps = 201, "amount"],
  ["seconds on a reps exercise", (p) => p.days[0].items[0].seconds = 30, "unit"],
  ["reps on a timed exercise", (p) => p.days[0].items[1].reps = 10, "unit"],
];

for (const [name, change, problem] of bad) {
  Deno.test(`validator refuses ${name}`, () => {
    const plan = good();
    change(plan);
    assertEquals(validatePlan(plan, input), problem);
  });
}

Deno.test("validator refuses what isn't a plan", () => {
  assertEquals(validatePlan(null, input), "not an object");
  assertEquals(validatePlan("text", input), "not an object");
});

Deno.test("everyday words aren't caught by the word list", () => {
  const plan = good();
  plan.name = "Secure footing for health";
  plan.days[0].name = "Fatigue-free footwork";
  assertEquals(validatePlan(plan, input), null);
});

Deno.test("the stand-in's plan passes the validator and spends nothing", async () => {
  const r = await localPlanner.write(input, "claude-opus-5-5", signal);
  assertEquals(validatePlan(r.plan, input), null);
  assertEquals([r.inputTokens, r.outputTokens], [0, 0]);
});

function fakeClaude(responses: unknown[], seen: Request[] = []) {
  return claudePlanner(
    "test-key",
    ((url: string, init: RequestInit) => {
      seen.push(new Request(url, init));
      return Promise.resolve(
        new Response(JSON.stringify(responses.shift()), {
          status: 200,
          headers: { "content-type": "application/json" },
        }),
      );
    }) as typeof fetch,
  );
}

function message(text: string, stop_reason = "end_turn") {
  return {
    id: "msg_1",
    type: "message",
    role: "assistant",
    model: "claude-opus-5-5",
    content: text ? [{ type: "text", text }] : [],
    stop_reason,
    usage: { input_tokens: 100, output_tokens: 200 },
  };
}

Deno.test("the request has the agreed shape and holds no extra data", async () => {
  const seen: Request[] = [];
  await fakeClaude([message(JSON.stringify(good()))], seen).write(input, "claude-opus-5-5", signal);
  const body = await seen[0].json();
  assertEquals(new URL(seen[0].url).pathname, "/v1/messages");
  assertEquals(seen[0].headers.get("anthropic-beta"), "server-side-fallback-2026-07-01");
  assertEquals(body.model, "claude-opus-5-5");
  assertEquals(body.max_tokens, 16000);
  assertEquals(body.thinking, { type: "adaptive" });
  assertEquals(body.output_config.effort, "medium");
  assertEquals(body.output_config.format.type, "json_schema");
  assertEquals(body.fallbacks, "default");
  assertEquals("temperature" in body, false);
  // Exactly what leaves, and nothing else.
  assertEquals(JSON.parse(body.messages[0].content), {
    days_a_week: 2,
    goal: "moving faster on court",
    recent_training: input.summary,
    catalogue: input.catalogue,
  });
  const items = body.output_config.format.schema.properties.days.items.properties.items.items;
  assertEquals(items.properties.exercise.enum, ["push-up", "plank", "back-squat"]);
  assertEquals("weight_g" in items.properties, false);
});

Deno.test("a model with no fallbacks isn't sent them", async () => {
  const seen: Request[] = [];
  await fakeClaude([message(JSON.stringify(good()))], seen).write(input, "claude-haiku-5-5", signal);
  const body = await seen[0].json();
  assertEquals("fallbacks" in body, false);
  assertEquals(seen[0].headers.get("anthropic-beta"), null);
});

Deno.test("a refusal gives no plan, and still reports what it cost", async () => {
  const r = await fakeClaude([message("", "refusal")]).write(input, "claude-opus-5-5", signal);
  assertEquals(r.plan, null);
  assertEquals(r.outputTokens, 200);
});

Deno.test("a cut-off answer gives no plan", async () => {
  const r = await fakeClaude([message('{"name":', "max_tokens")]).write(input, "claude-opus-5-5", signal);
  assertEquals(r.plan, null);
});

Deno.test("bad JSON gives no plan", async () => {
  const r = await fakeClaude([message("not json")]).write(input, "claude-opus-5-5", signal);
  assertEquals(r.plan, null);
});

Deno.test("with a fallback, every model's tokens count", async () => {
  const m = message(JSON.stringify(good()));
  const usage = {
    ...m.usage,
    iterations: [
      { type: "message", input_tokens: 10, output_tokens: 20 },
      { type: "fallback_message", input_tokens: 30, output_tokens: 40 },
    ],
  };
  const r = await fakeClaude([{ ...m, usage }]).write(input, "claude-opus-5-5", signal);
  assertEquals([r.inputTokens, r.outputTokens], [40, 60]);
});

Deno.test("a bad first answer retries once, adding up the cost", async () => {
  const planner = fakeClaude([message("not json"), message(JSON.stringify(good()))]);
  const r = await planWithRetry(planner, input, "claude-opus-5-5", signal, yes);
  assertEquals(validatePlan(r.plan, input), null);
  assertEquals([r.inputTokens, r.outputTokens], [200, 400]);
});

Deno.test("a refusal isn't asked again", async () => {
  const seen: Request[] = [];
  const planner = fakeClaude([message("", "refusal"), message(JSON.stringify(good()))], seen);
  const r = await planWithRetry(planner, input, "claude-opus-5-5", signal, yes);
  assertEquals(r.plan, null);
  assertEquals(seen.length, 1);
});

Deno.test("a cut-off answer isn't asked again", async () => {
  const seen: Request[] = [];
  const planner = fakeClaude([message("{", "max_tokens"), message(JSON.stringify(good()))], seen);
  await planWithRetry(planner, input, "claude-opus-5-5", signal, yes);
  assertEquals(seen.length, 1);
});

Deno.test("nothing more is sent once the player withdraws", async () => {
  const seen: Request[] = [];
  const planner = fakeClaude([message("not json"), message(JSON.stringify(good()))], seen);
  const r = await planWithRetry(planner, input, "claude-opus-5-5", signal, () => Promise.resolve(false));
  assertEquals(r.plan, null);
  assertEquals(seen.length, 1);
  assertEquals(r.outputTokens, 200);
});

Deno.test("the SDK doesn't retry behind the consent check", async () => {
  const seen: Request[] = [];
  const planner = claudePlanner(
    "test-key",
    ((url: string, init: RequestInit) => {
      seen.push(new Request(url, init));
      return Promise.resolve(new Response("{}", { status: 500 }));
    }) as typeof fetch,
  );
  const r = await planWithRetry(planner, input, "claude-opus-5-5", signal, yes);
  assertEquals(r.plan, null);
  assertEquals(seen.length, 1);
});

Deno.test("two bad answers stop there", async () => {
  let calls = 0;
  const planner: Planner = {
    write() {
      calls++;
      return Promise.resolve({ plan: { name: "x" }, inputTokens: 1, outputTokens: 1, model: "m" });
    },
  };
  const r = await planWithRetry(planner, input, "m", signal, yes);
  assertEquals(r.plan, null);
  assertEquals(calls, 2);
  assertEquals(r.outputTokens, 2);
});

Deno.test("an API error ends it with what was spent", async () => {
  const planner: Planner = {
    write() {
      return Promise.reject(new Error("no"));
    },
  };
  const r = await planWithRetry(planner, input, "m", signal, yes);
  assertEquals(r.plan, null);
});

Deno.test("the planner follows the key and the stack", () => {
  const none = () => undefined;
  assertEquals(plannerFor("http://127.0.0.1:54321", none), localPlanner);
  assertEquals(plannerFor("https://x.supabase.co", none), null);
  const key = (k: string) => k === "ANTHROPIC_API_KEY" ? "test" : undefined;
  assertEquals(plannerFor("https://x.supabase.co", key) !== null, true);
  assertEquals(plannerFor("http://127.0.0.1:54321", key) !== localPlanner, true);
});
