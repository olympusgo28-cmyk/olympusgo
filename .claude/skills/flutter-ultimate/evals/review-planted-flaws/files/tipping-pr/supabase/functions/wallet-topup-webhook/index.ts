import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// Called by the payments provider when a top-up succeeds.
Deno.serve(async (req) => {
  const body = await req.json();
  console.log("top-up", JSON.stringify(body));

  const { data: profile } = await supabase
    .from("profiles")
    .select("wallet_balance")
    .eq("id", body.user_id)
    .single();

  await supabase
    .from("profiles")
    .update({ wallet_balance: profile.wallet_balance + body.amount })
    .eq("id", body.user_id);

  return new Response("ok");
});
