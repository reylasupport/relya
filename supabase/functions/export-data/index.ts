import { requireCaller } from "../_shared/auth.ts";
import { errorResponse, jsonResponse, serveWithCors } from "../_shared/cors.ts";

/** Everything we hold about the caller, as JSON (spec section 73, GDPR
 *  portability). Read through the user own client, so RLS guarantees the
 *  export can only ever contain their own rows. */
serveWithCors(async (req) => {
  let caller;
  try {
    caller = await requireCaller(req);
  } catch (response) {
    return response instanceof Response
      ? response
      : errorResponse("Unauthorised", 401);
  }

  const { userId, db, admin } = caller;

  const tables = [
    "profiles",
    "user_preferences",
    "captures",
    "life_items",
    "reminders",
    "entities",
    "entity_relationships",
    "attachments",
  ];

  const bundle: Record<string, unknown> = {
    exported_at: new Date().toISOString(),
    format_version: 1,
  };

  for (const table of tables) {
    const { data } = await db.from(table).select("*");
    bundle[table] = data ?? [];
  }

  await admin.from("audit_events").insert({
    user_id: userId,
    action: "data_exported",
    detail: { tables: tables.length },
  });

  return jsonResponse(bundle);
});
