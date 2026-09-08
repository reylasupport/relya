import { requireCaller } from "../_shared/auth.ts";
import { errorResponse, jsonResponse, serveWithCors } from "../_shared/cors.ts";
import { createProvider } from "../_shared/ai/factory.ts";
import { normalise } from "../_shared/normalise.ts";
import { buildUserPrompt, SYSTEM_PROMPT } from "../_shared/prompt.ts";

/**
 * The one endpoint the product depends on.
 *
 * Order of operations is chosen to spend as little as possible: reuse a cached
 * analysis if we have one, charge the quota before doing any work, prefer the
 * text the device already extracted over sending pixels, and account for every
 * token afterwards.
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

  const { userId, db, admin } = caller;
  const started = Date.now();

  const body = await req.json().catch(() => null);
  const captureId = body?.capture_id;
  if (typeof captureId !== "string") {
    return errorResponse("capture_id is required", 400);
  }

  // RLS means this returns nothing at all if the capture is not theirs.
  const { data: capture } = await db
    .from("captures")
    .select("*")
    .eq("id", captureId)
    .maybeSingle();

  if (!capture) return errorResponse("Capture not found", 404);

  // Already analysed: hand back what we paid for last time.
  const { data: cached } = await db
    .from("capture_analyses")
    .select("payload, model")
    .eq("capture_id", captureId)
    .maybeSingle();

  if (cached) {
    return jsonResponse({
      capture_id: captureId,
      ...cached.payload,
      model: cached.model,
      cached: true,
    });
  }

  const { data: allowed } = await admin.rpc("consume_capture_quota", {
    p_user_id: userId,
  });
  if (allowed === false) {
    return errorResponse("Monthly capture limit reached", 429);
  }

  const { data: profile } = await db
    .from("profiles")
    .select("locale, timezone")
    .eq("id", userId)
    .maybeSingle();

  const { data: entities } = await db
    .from("entities")
    .select("name")
    .limit(30);

  // Text the device already read costs a fraction of sending the image.
  const documentText: string = capture.ocr_text ?? capture.raw_text ?? "";
  let imageBase64: string | undefined;
  let imageMimeType: string | undefined;

  // A PDF is always read from the file: the device never OCRs one, and an
  // email that carries an invoice has a body that says nothing useful.
  const needsOriginal = capture.kind === "pdf" ||
    documentText.trim().length < 24;

  if (needsOriginal && capture.storage_path) {
    const { data: file } = await db.storage
      .from("captures")
      .download(capture.storage_path);
    if (file) {
      const bytes = new Uint8Array(await file.arrayBuffer());
      imageBase64 = base64Encode(bytes);
      imageMimeType = file.type || "image/jpeg";
    }
  }

  if (!documentText.trim() && !imageBase64) {
    // Charged above, and no model was called: give it back.
    await admin.rpc("refund_capture_quota", { p_user_id: userId });
    await db
      .from("captures")
      .update({ status: "failed", error_message: "Nothing to read" })
      .eq("id", captureId);
    return errorResponse("Nothing to read in this capture", 422);
  }

  const provider = createProvider();
  const now = new Date();

  try {
    const result = await provider.extract({
      systemPrompt: SYSTEM_PROMPT,
      userPrompt: buildUserPrompt(
        {
          locale: profile?.locale ?? "en",
          timezone: profile?.timezone ?? "UTC",
          now: now.toISOString(),
          knownEntities: (entities ?? []).map((e) => e.name as string),
        },
        documentText,
      ),
      imageBase64,
      imageMimeType,
      preferSmallModel: documentText.length < 1500,
    });

    const items = result.analysis.items
      .map((item) => normalise(item, now))
      .map((item, index) => ({ ...item, id: `${captureId}-${index}` }));

    const payload = {
      items,
      detected_language: result.analysis.detected_language ?? null,
      processing_ms: Date.now() - started,
    };

    await admin.from("capture_analyses").upsert({
      capture_id: captureId,
      user_id: userId,
      payload,
      model: result.model,
    });

    await db
      .from("captures")
      .update({
        status: items.length > 0 ? "needs_confirmation" : "completed",
        item_count: items.length,
        detected_language: payload.detected_language,
        processed_at: new Date().toISOString(),
      })
      .eq("id", captureId);

    // Written with the service role so the number cannot be forged from the
    // client, and so a failed insert here never blocks the user.
    await admin.from("ai_usage").insert({
      user_id: userId,
      capture_id: captureId,
      provider: provider.name,
      model: result.model,
      input_tokens: result.inputTokens,
      output_tokens: result.outputTokens,
      cost_usd: result.costUsd,
      latency_ms: Date.now() - started,
      used_image: Boolean(imageBase64),
      succeeded: true,
    });

    return jsonResponse({
      capture_id: captureId,
      ...payload,
      model: result.model,
    });
  } catch (error) {
    // The user is not paying for a capture they never got back. Refunded
    // before anything else, because the rest of this block is best effort and
    // the allowance is the part they would actually notice.
    await admin.rpc("refund_capture_quota", { p_user_id: userId });

    await db
      .from("captures")
      .update({
        status: "failed",
        error_message: String(error).slice(0, 500),
      })
      .eq("id", captureId);

    await admin.from("ai_usage").insert({
      user_id: userId,
      capture_id: captureId,
      provider: provider.name,
      model: "unknown",
      latency_ms: Date.now() - started,
      used_image: Boolean(imageBase64),
      succeeded: false,
    });

    return errorResponse("Could not analyse this capture", 502);
  }
});

/** Chunked so a large PDF does not blow the call stack the way
 *  String.fromCharCode(...bytes) does. */
function base64Encode(bytes: Uint8Array): string {
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}
