export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function errorResponse(message: string, status: number): Response {
  return jsonResponse({ error: message }, status);
}

export function preflight(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  return null;
}

/**
 * Serves a handler and guarantees CORS headers on every answer, including the
 * ones nobody planned for.
 *
 * A throw that escapes the handler becomes a platform 500 with no headers on
 * it, and a browser reports that as "blocked by CORS policy: No
 * Access-Control-Allow-Origin header". That message sends you looking for a
 * CORS misconfiguration when the real cause is usually a missing secret on the
 * server - the failure hides itself behind the wrong diagnosis.
 *
 * The message returned to the client stays generic on purpose; the detail goes
 * to the function logs, where it does not leak configuration to a caller.
 */
export function serveWithCors(
  handler: (req: Request) => Promise<Response>,
): void {
  Deno.serve(async (req) => {
    const early = preflight(req);
    if (early) return early;
    try {
      return await handler(req);
    } catch (error) {
      console.error("Unhandled failure", error);
      return errorResponse("Unexpected server error", 500);
    }
  });
}
