import { analysisSchema } from "../schema.ts";
import {
  AIProvider,
  AnswerResult,
  ExtractionRequest,
  ProviderResult,
} from "./provider.ts";

const API = "https://api.anthropic.com/v1/messages";
const VERSION = "2023-06-01";

/** USD per million tokens. Kept here so cost accounting is honest without a
 *  second source of truth to drift. */
const PRICING: Record<string, { input: number; output: number }> = {
  "claude-sonnet-5": { input: 3, output: 15 },
  "claude-haiku-4-5-20251001": { input: 1, output: 5 },
};

export class AnthropicProvider implements AIProvider {
  readonly name = "anthropic";

  constructor(
    private readonly apiKey: string,
    private readonly largeModel = Deno.env.get("AI_MODEL_LARGE") ??
      "claude-sonnet-5",
    private readonly smallModel = Deno.env.get("AI_MODEL_SMALL") ??
      "claude-haiku-4-5-20251001",
  ) {}

  private async call(body: Record<string, unknown>) {
    const response = await fetch(API, {
      method: "POST",
      headers: {
        "x-api-key": this.apiKey,
        "anthropic-version": VERSION,
        "content-type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      throw new Error(`Anthropic ${response.status}: ${await response.text()}`);
    }
    return await response.json();
  }

  async extract(request: ExtractionRequest): Promise<ProviderResult> {
    // Pixels need the multimodal model; transcribed text does not, and the
    // difference is most of the bill.
    const model = request.imageBase64 || !request.preferSmallModel
      ? this.largeModel
      : this.smallModel;

    const content: unknown[] = [];
    if (request.imageBase64) {
      content.push({
        type: "image",
        source: {
          type: "base64",
          media_type: request.imageMimeType ?? "image/jpeg",
          data: request.imageBase64,
        },
      });
    }
    content.push({ type: "text", text: request.userPrompt });

    const data = await this.call({
      model,
      max_tokens: 2048,
      system: request.systemPrompt,
      messages: [{ role: "user", content }],
      tools: [
        {
          name: "record_findings",
          description: "Record everything important found in the document.",
          input_schema: EXTRACTION_TOOL_SCHEMA,
        },
      ],
      tool_choice: { type: "tool", name: "record_findings" },
    });

    const toolUse = (data.content as Array<Record<string, unknown>>)
      .find((block) => block.type === "tool_use");
    if (!toolUse) throw new Error("Model returned no structured output");

    const analysis = analysisSchema.parse(toolUse.input);
    const usage = data.usage ?? {};
    const price = PRICING[model] ?? { input: 3, output: 15 };
    const inputTokens = usage.input_tokens ?? 0;
    const outputTokens = usage.output_tokens ?? 0;

    return {
      analysis,
      model,
      inputTokens,
      outputTokens,
      costUsd: (inputTokens * price.input + outputTokens * price.output) / 1e6,
    };
  }

  async answer(
    systemPrompt: string,
    userPrompt: string,
  ): Promise<AnswerResult> {
    const model = this.smallModel;
    const data = await this.call({
      model,
      max_tokens: 600,
      system: systemPrompt,
      messages: [{ role: "user", content: userPrompt }],
    });
    const first = (data.content as Array<Record<string, unknown>>)[0];
    const usage = data.usage ?? {};
    const price = PRICING[model] ?? { input: 1, output: 5 };
    const inputTokens = usage.input_tokens ?? 0;
    const outputTokens = usage.output_tokens ?? 0;

    return {
      text: (first?.text as string) ?? "",
      model,
      inputTokens,
      outputTokens,
      costUsd: (inputTokens * price.input + outputTokens * price.output) / 1e6,
    };
  }
}

/** Tool input schema. Using a tool rather than free text is what makes the
 *  output structurally guaranteed instead of hopefully-parseable.
 *
 *  Exported because every provider needs the same shape, in its own dialect.
 *  One definition, translated per vendor, so a new field cannot reach one
 *  model and miss another. */
export const EXTRACTION_TOOL_SCHEMA = {
  type: "object",
  required: ["items"],
  properties: {
    detected_language: {
      type: "string",
      description: "BCP-47 tag of the document language.",
    },
    items: {
      type: "array",
      maxItems: 10,
      items: {
        type: "object",
        required: ["category", "title", "confidence"],
        properties: {
          category: {
            type: "string",
            enum: [
              "appointment", "bill", "subscription", "purchase", "return",
              "warranty", "travel", "document", "insurance", "vehicle", "home",
              "event", "delivery", "reservation", "education", "task", "other",
            ],
          },
          title: { type: "string" },
          summary: { type: "string" },
          source_language: { type: "string" },
          confidence: { type: "number", minimum: 0, maximum: 1 },
          action_required: { type: "boolean" },
          dates: {
            type: "array",
            items: {
              type: "object",
              required: ["raw", "kind"],
              properties: {
                raw: { type: "string" },
                kind: {
                  type: "string",
                  enum: [
                    "start", "end", "deadline", "purchase", "renewal",
                    "expiry", "other",
                  ],
                },
                resolved: {
                  type: "string",
                  format: "date-time",
                  description:
                    "RFC 3339 with an explicit offset, e.g. " +
                    "2026-09-17T15:30:00+01:00. A local time with no offset " +
                    "is not an instant and will be rejected: an appointment " +
                    "must not move when the reader is in another country.",
                },
                timezone: {
                  type: "string",
                  description: "IANA zone of the event, e.g. Europe/Lisbon.",
                },
                has_time: { type: "boolean" },
                ambiguous: { type: "boolean" },
                alternative: {
                  type: "string",
                  format: "date-time",
                  description:
                    "The other plausible reading, same format as resolved.",
                },
                confidence: { type: "number" },
              },
            },
          },
          amount: { type: "number" },
          currency: { type: "string" },
          location: { type: "string" },
          organization: { type: "string" },
          people: { type: "array", items: { type: "string" } },
          reference_numbers: { type: "array", items: { type: "string" } },
          related_entity: { type: "string" },
          recurrence: { type: "string" },
          suggested_reminders: {
            type: "array",
            items: {
              type: "object",
              required: ["label", "lead_seconds"],
              properties: {
                label: { type: "string" },
                lead_seconds: { type: "integer" },
                anchor: { type: "string", enum: ["start", "deadline"] },
                default_on: { type: "boolean" },
              },
            },
          },
          suggested_actions: {
            type: "array",
            items: {
              type: "object",
              required: ["type", "label"],
              properties: {
                type: {
                  type: "string",
                  enum: [
                    "add_to_calendar", "save_document", "track_payment",
                    "track_subscription", "track_warranty", "track_delivery",
                    "add_trip",
                  ],
                },
                label: { type: "string" },
                default_on: { type: "boolean" },
              },
            },
          },
          sensitivity: {
            type: "string",
            enum: ["normal", "personal", "sensitive"],
          },
          unresolved_note: { type: "string" },
        },
      },
    },
  },
} as const;
