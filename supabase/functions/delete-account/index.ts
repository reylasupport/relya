import { requireCaller } from "../_shared/auth.ts";
import { errorResponse, jsonResponse, serveWithCors } from "../_shared/cors.ts";

/**
 * Deletes everything (spec section 72).
 *
 * Runs server-side because two of the three steps are impossible from the
 * client: removing storage objects the user can only sign URLs for, and
 * deleting the auth user itself. Cascades handle the rows; this handles the
 * rest, and records that it happened before the account disappears.
 */
serveWithCors(async (req) => {
  let caller;
  try {
    caller = await requireCaller(req);
  } catch (response) {
    return response instanceof Response
      ? response
      : errorResponse("Unauthorised", 401);
  }

  const { userId, admin } = caller;

  await admin.from("audit_events").insert({
    user_id: userId,
    action: "account_deletion_requested",
  });

  const { data: files } = await admin.storage
    .from("captures")
    .list(userId, { limit: 1000 });

  if (files && files.length > 0) {
    await admin.storage
      .from("captures")
      .remove(files.map((file) => `${userId}/${file.name}`));
  }

  // Every table cascades from auth.users, so this one delete takes the rest.
  const { error } = await admin.auth.admin.deleteUser(userId);
  if (error) return errorResponse("Could not delete the account", 500);

  return jsonResponse({ deleted: true });
});
