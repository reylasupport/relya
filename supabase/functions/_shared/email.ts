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
  const digest = await crypto.subtle.digest("SHA-256", bytes);
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
