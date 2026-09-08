// GENERATED - do not edit.
//
// Built by tools/bundle-inbound-email.mjs from:
//   supabase/functions/_shared/cors.ts
//   supabase/functions/_shared/email.ts
//   supabase/functions/inbound-email/index.ts
//
// Paste this into the Supabase dashboard: Edge Functions -> Deploy a new
// function, named "inbound-email". Set INBOUND_EMAIL_SECRET in the function
// secrets first, or every call answers 500.

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

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

/**
 * Reading a forwarded email, whatever provider delivered it.
 *
 * Kept apart from the function that serves it so every rule here - which
 * address counts as the recipient, what an attachment is allowed to be, how
 * HTML becomes text - can be tested without starting a server.
 */

/** The captures bucket refuses everything else, so nothing else travels. */
export const ATTACHABLE = new Set([
  "application/pdf",
  "image/jpeg",
  "image/png",
  "image/heic",
  "image/webp",
]);

/** Below the bucket's own 25 MB, with room for base64 inflation. */
export const MAX_ATTACHMENT = 15 * 1024 * 1024;

export interface Attachment {
  name: string;
  type: string;
  bytes: Uint8Array;
}

export interface Incoming {
  to?: string;
  from?: string;
  subject?: string;
  text?: string;
  html?: string;
  attachment?: Attachment;
}

/**
 * Reads the shapes the common providers actually post.
 *
 * Postmark and CloudMailin send JSON; SendGrid's Inbound Parse and Mailgun's
 * routes send multipart form data. Supporting both is a few dozen lines and
 * saves the whole feature from depending on one vendor.
 */
export async function parseInbound(req: Request): Promise<Incoming> {
  const type = req.headers.get("content-type") ?? "";
  if (type.includes("multipart/form-data")) {
    return await parseForm(await req.formData());
  }
  return parseJson(await req.json() as Record<string, unknown>);
}

async function parseForm(form: FormData): Promise<Incoming> {
  const field = (...names: string[]) => {
    for (const name of names) {
      const value = form.get(name);
      if (typeof value === "string" && value.trim()) return value;
    }
    return undefined;
  };

  let attachment: Attachment | undefined;
  for (const [, value] of form.entries()) {
    if (!(value instanceof File)) continue;
    if (!ATTACHABLE.has(value.type)) continue;
    if (value.size > MAX_ATTACHMENT) continue;
    attachment = {
      name: value.name,
      type: value.type,
      bytes: new Uint8Array(await value.arrayBuffer()),
    };
    break;
  }

  return {
    // The envelope is the delivered-to address. The To header of a forwarded
    // message is usually whoever it was originally sent to.
    to: envelopeTo(field("envelope")) ?? field("to", "recipient", "To"),
    from: field("from", "sender", "From"),
    subject: field("subject", "Subject"),
    text: field("text", "body-plain", "plain"),
    html: field("html", "body-html"),
    attachment,
  };
}

export function parseJson(body: Record<string, unknown>): Incoming {
  return {
    to: firstString(body, [
      // Postmark's delivered-to, then the envelope forms, then the header.
      "OriginalRecipient",
      "recipient",
      "envelope_to",
      "to",
      "To",
    ]) ?? nestedString(body, "envelope", "to") ??
      nestedString(body, "headers", "to"),
    from: firstString(body, ["from", "From", "sender", "envelope_from"]) ??
      nestedString(body, "envelope", "from"),
    subject: firstString(body, ["subject", "Subject"]),
    text: firstString(body, ["text", "TextBody", "plain", "body-plain"]),
    html: firstString(body, ["html", "HtmlBody", "body-html"]),
    attachment: jsonAttachment(body),
  };
}

/** SendGrid posts the envelope as a JSON string inside a form field. */
function envelopeTo(raw: string | undefined): string | undefined {
  if (!raw) return undefined;
  try {
    const parsed = JSON.parse(raw) as { to?: unknown };
    const to = parsed.to;
    if (Array.isArray(to) && typeof to[0] === "string") return to[0];
    if (typeof to === "string") return to;
  } catch {
    // Not JSON. The caller falls back to the header.
  }
  return undefined;
}

function jsonAttachment(
  body: Record<string, unknown>,
): Attachment | undefined {
  const list = (body["Attachments"] ?? body["attachments"]) as unknown;
  if (!Array.isArray(list)) return undefined;

  for (const entry of list) {
    if (typeof entry !== "object" || entry === null) continue;
    const item = entry as Record<string, unknown>;
    const type = String(item["ContentType"] ?? item["content_type"] ?? "")
      .split(";")[0]
      .trim();
    if (!ATTACHABLE.has(type)) continue;

    const content = item["Content"] ?? item["content"] ?? item["data"];
    if (typeof content !== "string") continue;

    try {
      const bytes = decodeBase64(content);
      if (bytes.length === 0 || bytes.length > MAX_ATTACHMENT) continue;
      return {
        name: String(item["Name"] ?? item["name"] ?? "attachment"),
        type,
        bytes,
      };
    } catch {
      continue;
    }
  }
  return undefined;
}

/** Providers disagree on field names; this accepts the common spellings. */
function firstString(
  body: Record<string, unknown>,
  keys: string[],
): string | undefined {
  for (const key of keys) {
    const value = body[key];
    if (typeof value === "string" && value.trim()) return value;
  }
  return undefined;
}

function nestedString(
  body: Record<string, unknown>,
  outer: string,
  inner: string,
): string | undefined {
  const parent = body[outer];
  if (typeof parent !== "object" || parent === null) return undefined;
  const value = (parent as Record<string, unknown>)[inner];
  if (typeof value === "string" && value.trim()) return value;
  if (Array.isArray(value) && typeof value[0] === "string") return value[0];
  return undefined;
}

/**
 * Pulls `abc123` out of any of these:
 *
 *   u-abc123@in.relya.app                      the address on our own domain
 *   u-abc123+whatever@in.relya.app             a forwarder that tagged it
 *   9f2b1c+u-abc123@inbound.postmarkapp.com    a provider's shared address
 *
 * The last one is what makes this testable with no domain at all: providers
 * hand out one fixed address and let you tag it after a plus, so the token
 * can be in any segment of the local part rather than only the first.
 */
export function tokenFrom(recipient: string | undefined): string | null {
  const address = emailFrom(recipient);
  if (!address) return null;
  for (const segment of address.split("@")[0].split("+")) {
    const match = segment.match(/^u-([a-f0-9]{12,64})$/);
    if (match) return match[1];
  }
  return null;
}

export function emailFrom(value: string | undefined): string | null {
  if (!value) return null;
  const angled = value.match(/<([^>]+)>/);
  const address = (angled ? angled[1] : value).trim().toLowerCase();
  return address.includes("@") ? address : null;
}

/** Enough to turn a marketing email into readable text for the model. */
export function stripHtml(html: string): string {
  return html
    .replace(/<(script|style)[\s\S]*?<\/\1>/gi, " ")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/(p|div|tr|h[1-6])>/gi, "\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/[ \t]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

export function decodeBase64(value: string): Uint8Array {
  const binary = atob(value.replace(/\s/g, ""));
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

export async function sha256(value: string): Promise<string> {
  return await sha256Bytes(new TextEncoder().encode(value));
}

export async function sha256Bytes(bytes: Uint8Array): Promise<string> {
  // Re-wrapped before hashing. A bare Uint8Array now admits a view sitting on
  // a SharedArrayBuffer, which digest() refuses to take, and the TypeScript
  // that ships with Deno 2.2 started enforcing it. Everything that reaches
  // here was built with new Uint8Array over its own buffer, so the copy costs
  // one pass and restores the guarantee the type stopped carrying. Written
  // this way rather than as Uint8Array<ArrayBuffer>, which would only compile
  // on TypeScript 5.7 and later.
  const digest = await crypto.subtle.digest("SHA-256", new Uint8Array(bytes));
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

/** Storage keys are built from names a stranger chose, so they are stripped. */
export function safeName(name: string): string {
  return name
    .replace(/[^A-Za-z0-9._-]/g, "_")
    .replace(/_+/g, "_")
    .slice(0, 80) || "attachment";
}


/**
 * Turns a forwarded email into a capture.
 *
 * Called by the inbound-email provider, not by a device, so it is deployed
 * with --no-verify-jwt and authenticates on a shared secret instead. Three
 * things guard it, and all three matter:
 *
 *   1. The bearer secret, so only the provider can post here at all.
 *   2. The address token, which is unguessable and identifies the account.
 *   3. The sender, which must be the address on the account. Without this,
 *      anyone who learned a user's forwarding address could write into their
 *      life - and, because the body reaches a model, into their prompt.
 *
 * The body is data, never instructions. It is stored verbatim and handed to
 * analyze-capture, which already treats document text as untrusted.
 */

/** Anything larger is a newsletter or an attachment dump, not a receipt. */
const MAX_TEXT = 40_000;

serveWithCors(async (req) => {
  const secret = Deno.env.get("INBOUND_EMAIL_SECRET");
  if (!secret) {
    console.error("INBOUND_EMAIL_SECRET is not set");
    return errorResponse("Not configured", 500);
  }
  if (!authorised(req, secret)) {
    return errorResponse("Unauthorised", 401);
  }

  let mail;
  try {
    mail = await parseInbound(req);
  } catch (error) {
    console.error("Could not parse the inbound payload", error);
    return errorResponse("Could not read this payload", 400);
  }

  const token = tokenFrom(mail.to);
  if (!token) return errorResponse("No inbox in the recipient", 400);

  const sender = emailFrom(mail.from);
  if (!sender) return errorResponse("No sender", 400);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const { data: profile } = await admin
    .from("profiles")
    .select("id, email")
    .eq("inbox_token", token)
    .maybeSingle();

  // The same answer for an unknown token and for a sender who is not the
  // owner, so this endpoint cannot be used to find out which addresses exist.
  if (!profile) return jsonResponse({ accepted: false }, 202);

  const owner = (profile.email as string | null)?.trim().toLowerCase();
  if (!owner || owner !== sender) {
    console.warn("Rejected a forward from a sender that is not the owner");
    return jsonResponse({ accepted: false }, 202);
  }

  const subject = (mail.subject ?? "").trim();
  const content = (mail.text ?? stripHtml(mail.html ?? "")).trim();
  const document = [subject, content]
    .filter((part) => part)
    .join("\n\n")
    .slice(0, MAX_TEXT);

  const attachment = mail.attachment;
  if (document.length < 8 && !attachment) {
    return jsonResponse({ accepted: false }, 202);
  }

  // The same rule the device uses, so forwarding the same thing twice is
  // analysed once. Bytes win over the body: the invoice is the attachment.
  const hash = attachment
    ? await sha256Bytes(attachment.bytes)
    : await sha256(document);

  const { data: existing } = await admin
    .from("captures")
    .select("id")
    .eq("user_id", profile.id)
    .eq("content_hash", hash)
    .neq("status", "failed")
    .maybeSingle();

  if (existing) {
    return jsonResponse({ accepted: true, capture_id: existing.id });
  }

  const storagePath = attachment
    ? await upload(admin, profile.id as string, attachment)
    : null;

  const { data: capture, error } = await admin
    .from("captures")
    .insert({
      user_id: profile.id,
      source: "email",
      kind: attachment
        ? (attachment.type === "application/pdf" ? "pdf" : "image")
        : "text",
      status: "queued",
      title: subject.slice(0, 200) || "Email",
      raw_text: document || null,
      storage_path: storagePath,
      content_hash: hash,
    })
    .select("id")
    .single();

  if (error) {
    console.error("Could not store a forwarded email", error);
    return errorResponse("Could not store this email", 500);
  }

  return jsonResponse({ accepted: true, capture_id: capture.id });
});

/**
 * Accepts the secret in the header or in the query string.
 *
 * The header is the right way round and every provider that can send one
 * should. The query string exists because several inbound-email services let
 * you set a target URL and nothing else, and being unable to authenticate at
 * all is worse than a secret that may appear in an access log. Rotating it is
 * one dashboard field on each side.
 */
function authorised(req: Request, secret: string): boolean {
  const header = req.headers.get("Authorization");
  if (header && timingSafeEqual(header, `Bearer ${secret}`)) return true;

  const query = new URL(req.url).searchParams.get("secret");
  return query !== null && timingSafeEqual(query, secret);
}

/** Constant time in the length that matters, so the secret cannot be guessed
 *  a character at a time from how long the answer took. */
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let differences = 0;
  for (let i = 0; i < a.length; i++) {
    differences |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return differences === 0;
}

async function upload(
  admin: SupabaseClient,
  userId: string,
  attachment: Attachment,
): Promise<string | null> {
  // Same layout the device writes: the first path segment is the owner, which
  // is what the storage policies check.
  const path = `${userId}/${Date.now()}-${safeName(attachment.name)}`;

  const { error } = await admin.storage
    .from("captures")
    .upload(path, attachment.bytes, { contentType: attachment.type });

  if (error) {
    // A capture with only the body text is still worth having.
    console.error("Could not store an email attachment", error);
    return null;
  }
  return path;
}
