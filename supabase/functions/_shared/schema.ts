import { z } from "npm:zod@3.23.8";

/**
 * The contract with the model (spec section 19).
 *
 * Nothing reaches the database until it has been through this. Free-form text
 * from a language model is never trusted for anything structural: a field that
 * does not parse is dropped, and a response that does not parse is a failure,
 * not a silent partial save.
 */

export const extractedDateSchema = z.object({
  raw: z.string().max(200),
  kind: z.enum([
    "start",
    "end",
    "deadline",
    "purchase",
    "renewal",
    "expiry",
    "other",
  ]),
  // offset: true accepts 2026-09-17T15:30:00+01:00 as well as the Z form.
  // Models reach for the local offset when the document is local, and both
  // are unambiguous instants; what must never be accepted is a bare local
  // time, which is why this is not simply a string. normalise() converts to
  // UTC, so everything downstream still sees one representation.
  resolved: z.string().datetime({ offset: true }).nullable().optional(),
  timezone: z.string().max(64).nullable().optional(),
  has_time: z.boolean().default(false),
  /** True when the written form has two readings and the locale did not
   *  settle it. The app asks rather than guessing. */
  ambiguous: z.boolean().default(false),
  alternative: z.string().datetime({ offset: true }).nullable().optional(),
  confidence: z.number().min(0).max(1).default(1),
});

export const suggestedReminderSchema = z.object({
  label: z.string().max(80),
  lead_seconds: z.number().int().min(0).max(60 * 60 * 24 * 400),
  anchor: z.enum(["start", "deadline"]).default("start"),
  default_on: z.boolean().default(true),
});

/** Closed set. A document cannot invent an action, and nothing in this list
 *  spends money, sends anything, or deletes anything (spec section 52). */
export const suggestedActionSchema = z.object({
  type: z.enum([
    "add_to_calendar",
    "save_document",
    "track_payment",
    "track_subscription",
    "track_warranty",
    "track_delivery",
    "add_trip",
  ]),
  label: z.string().max(80),
  default_on: z.boolean().default(true),
});

export const CATEGORIES = [
  "appointment",
  "bill",
  "subscription",
  "purchase",
  "return",
  "warranty",
  "travel",
  "document",
  "insurance",
  "vehicle",
  "home",
  "event",
  "delivery",
  "reservation",
  "education",
  "task",
  "other",
] as const;

export const extractionSchema = z.object({
  category: z.enum(CATEGORIES),
  title: z.string().min(1).max(120),
  summary: z.string().max(400).nullable().optional(),
  source_language: z.string().max(16).nullable().optional(),
  confidence: z.number().min(0).max(1),
  action_required: z.boolean().default(false),
  dates: z.array(extractedDateSchema).max(8).default([]),
  amount: z.number().nullable().optional(),
  currency: z.string().length(3).nullable().optional(),
  location: z.string().max(200).nullable().optional(),
  organization: z.string().max(160).nullable().optional(),
  people: z.array(z.string().max(120)).max(10).default([]),
  reference_numbers: z.array(z.string().max(80)).max(10).default([]),
  related_entity: z.string().max(120).nullable().optional(),
  recurrence: z.string().max(120).nullable().optional(),
  suggested_reminders: z.array(suggestedReminderSchema).max(6).default([]),
  suggested_actions: z.array(suggestedActionSchema).max(6).default([]),
  sensitivity: z.enum(["normal", "personal", "sensitive"]).default("normal"),
  /** What the model could not confirm. Surfaced to the user verbatim instead
   *  of being smoothed over (spec section 5). */
  unresolved_note: z.string().max(300).nullable().optional(),
});

export const analysisSchema = z.object({
  detected_language: z.string().max(16).nullable().optional(),
  items: z.array(extractionSchema).max(10).default([]),
});

export type Extraction = z.infer<typeof extractionSchema>;
export type Analysis = z.infer<typeof analysisSchema>;

/** JSON Schema handed to the provider so the model is constrained at
 *  generation time, not just checked afterwards. */
export const responseJsonSchema = {
  type: "object",
  additionalProperties: false,
  required: ["items"],
  properties: {
    detected_language: { type: "string" },
    items: {
      type: "array",
      maxItems: 10,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["category", "title", "confidence"],
        properties: {
          category: { type: "string", enum: CATEGORIES },
          title: { type: "string" },
          summary: { type: "string" },
          source_language: { type: "string" },
          confidence: { type: "number" },
          action_required: { type: "boolean" },
          dates: { type: "array" },
          amount: { type: "number" },
          currency: { type: "string" },
          location: { type: "string" },
          organization: { type: "string" },
          people: { type: "array", items: { type: "string" } },
          reference_numbers: { type: "array", items: { type: "string" } },
          related_entity: { type: "string" },
          recurrence: { type: "string" },
          suggested_reminders: { type: "array" },
          suggested_actions: { type: "array" },
          sensitivity: { type: "string" },
          unresolved_note: { type: "string" },
        },
      },
    },
  },
} as const;
