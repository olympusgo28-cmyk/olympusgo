// Every staff write comes through here. The database function checks the role
// and MFA and writes the audit row in the same transaction; this keeps the list
// of what staff can do in one place, and passes the caller's own token, so
// nothing here runs with more power than they have.
import { createClient } from "jsr:@supabase/supabase-js@2";

const url = Deno.env.get("SUPABASE_URL")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

const ACTIONS = new Set<string>([
  "staff_case_decide",
  "staff_warn",
  "staff_suspend",
  "staff_ban_request",
  "staff_ban_decide",
  "staff_sport_save",
  "staff_format_save",
  "staff_recovery_decide",
  "staff_preset_save",
  "staff_level_save",
  "staff_result_correct",
  "staff_refund_issue",
  "staff_refund_retry",
  "staff_refund_void",
  "staff_refund_manual",
  "staff_refund_settle",
  "staff_hold_decide",
  "staff_payout_approve",
  "staff_alert_close",
  "staff_suspense_clear",
  "staff_venue_qr",
  "staff_shop_save",
  "staff_shop_commission_set",
  "staff_shop_link_owner",
  "staff_product_save",
  "staff_product_stock",
  "staff_order_decide",
  "staff_points_block",
  "staff_academy_decide",
  "staff_licence_decide",
  "staff_doc_removed",
  "staff_doc_viewed",
  "staff_lesson_decide",
  "staff_service_save",
  "staff_campaign_save",
  "staff_campaign_status",
  "staff_badge_save",
  "staff_voucher_type_save",
]);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  let body: { action?: string; params?: Record<string, unknown> };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Bad request" }, 400);
  }
  if (!body.action || !ACTIONS.has(body.action)) return json({ error: "Not found." }, 404);

  const client = createClient(url, anonKey, {
    auth: { persistSession: false },
    global: { headers: { Authorization: req.headers.get("authorization") ?? "" } },
  });
  const { data, error } = await client.rpc(body.action, body.params ?? {});
  if (error) return json({ error: error.code === "P0001" ? error.message : "Something went wrong." }, 400);
  return json({ data });
});
