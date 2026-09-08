import { createClient } from "jsr:@supabase/supabase-js@2";
import { errorResponse, jsonResponse, serveWithCors } from "../_shared/cors.ts";

/**
 * Keeps the plan on the profile in step with the store.
 *
 * The client is never the authority on entitlement: it can be modified, and a
 * modified client claiming to be Pro must not unlock anything. This webhook,
 * plus RevenueCat own API, is the only thing that writes profiles.plan.
 */
serveWithCors(async (req) => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  // Shared-secret check. Without it anyone who finds the URL can grant
  // themselves a subscription.
  const expected = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  const provided = req.headers.get("Authorization");
  if (!expected || provided !== `Bearer ${expected}`) {
    return errorResponse("Unauthorised", 401);
  }

  const body = await req.json().catch(() => null);
  const event = body?.event;
  if (!event) return errorResponse("Malformed payload", 400);

  const userId: string | undefined = event.app_user_id;
  if (!userId) return errorResponse("Missing app_user_id", 400);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const grantingEvents = new Set([
    "INITIAL_PURCHASE",
    "RENEWAL",
    "UNCANCELLATION",
    "PRODUCT_CHANGE",
    "NON_RENEWING_PURCHASE",
  ]);
  const revokingEvents = new Set(["EXPIRATION", "BILLING_ISSUE"]);

  let plan: "free" | "pro" | null = null;
  if (grantingEvents.has(event.type)) plan = "pro";
  if (revokingEvents.has(event.type)) plan = "free";

  // CANCELLATION means "will not renew", not "access ends now". Access is
  // revoked on EXPIRATION, not here.
  if (plan === null) return jsonResponse({ ignored: event.type });

  await admin
    .from("profiles")
    .update({
      plan,
      capture_quota: plan === "pro" ? null : 20,
    })
    .eq("id", userId);

  await admin.from("audit_events").insert({
    user_id: userId,
    action: "subscription_changed",
    detail: { event: event.type, plan },
  });

  return jsonResponse({ ok: true });
});
