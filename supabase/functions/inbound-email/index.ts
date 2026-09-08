import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { errorResponse, jsonResponse, serveWithCors } from "../_shared/cors.ts";
import {
  type Attachment,
  emailFrom,
  parseInbound,
  safeName,
  sha256,
  sha256Bytes,
  stripHtml,
  tokenFrom,
} from "../_shared/email.ts";

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
