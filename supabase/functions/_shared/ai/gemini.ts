import { analysisSchema } from "../schema.ts";
import { EXTRACTION_TOOL_SCHEMA } from "./anthropic.ts";
import {
  AIProvider,
  AnswerResult,
  ExtractionRequest,
  ProviderResult,
} from "./provider.ts";

const API = "https://generativelanguage.googleapis.com/v1beta/models";

/**
 * USD per million tokens, for the paid tier.
 *
 * Deliberately empty until somebody fills it in from Google's current price
 * list. On the free tier the honest recorded cost is zero, and an invented
 * number would be worse than no number: ai_usage exists to answer "what does
 * a user cost us", and a wrong answer there prices the subscription wrong.
 *
 * An unknown model records zero rather than falling back to some other
 * vendor's prices. See docs/COSTS.md before moving off the free tier.
 */
const PRICING: Record<string, { input: number; output: number }> = {};

/**
 * Google Gemini.
 *
 * Chosen as the free option because it is the only one with a genuine free
 * tier that is also multimodal: Relya's main input is a photograph of a
 * document, and a text-only model cannot read one.
 *
 * Structured output uses responseSchema rather than a tool call. The effect is
 * the same as the Anthropic adapter's tool: there is no free-text channel for
 * a hostile document to write instructions into, only fields.
 */
export class GeminiProvider implements AIProvider {
  readonly name = "gemini";

  constructor(
    private readonly apiKey: string,
    // Verified against the live models list. Both are stable, not preview,
    // and both read images - the lite one still has to cope with a photo of
    // a receipt when on-device OCR gives up.
    private readonly largeModel = Deno.env.get("AI_MODEL_LARGE") ??
      "gemini-3.5-flash",
    private readonly smallModel = Deno.env.get("AI_MODEL_SMALL") ??
      "gemini-3.5-flash-lite",
  ) {}

  private async call(model: string, body: Record<string, unknown>) {
    const response = await fetch(
      `${API}/${model}:generateContent?key=${this.apiKey}`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(body),
      },
    );
    if (!response.ok) {
      throw new Error(`Gemini ${response.status}: ${await response.text()}`);
    }
    return await response.json();
  }

  async extract(request: ExtractionRequest): Promise<ProviderResult> {
    const model = request.imageBase64 || !request.preferSmallModel
      ? this.largeModel
      : this.smallModel;

    const parts: unknown[] = [];
    if (request.imageBase64) {
      parts.push({
        inline_data: {
          mime_type: request.imageMimeType ?? "image/jpeg",
          data: request.imageBase64,
        },
      });
    }
    parts.push({ text: request.userPrompt });

    const data = await this.call(model, {
      systemInstruction: { parts: [{ text: request.systemPrompt }] },
      contents: [{ role: "user", parts }],
      generationConfig: {
        temperature: 0,
        maxOutputTokens: 2048,
        responseMimeType: "application/json",
        responseSchema: toGeminiSchema(EXTRACTION_TOOL_SCHEMA),
      },
    });

    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) throw new Error("Model returned no structured output");

    const analysis = analysisSchema.parse(JSON.parse(text));
    const usage = data.usageMetadata ?? {};
    const price = PRICING[model];
    const inputTokens = usage.promptTokenCount ?? 0;
    const outputTokens = usage.candidatesTokenCount ?? 0;

    return {
      analysis,
      model,
      inputTokens,
      outputTokens,
      // Zero on the free tier, and zero for a model nobody has priced yet.
      // The token counts are still recorded, so the bill can be reconstructed
      // the day a price is known.
      costUsd: price
        ? (inputTokens * price.input + outputTokens * price.output) / 1e6
        : 0,
    };
  }

  async answer(
    systemPrompt: string,
    userPrompt: string,
  ): Promise<AnswerResult> {
    const model = this.smallModel;
    const data = await this.call(model, {
      systemInstruction: { parts: [{ text: systemPrompt }] },
      contents: [{ role: "user", parts: [{ text: userPrompt }] }],
      generationConfig: { temperature: 0.2, maxOutputTokens: 600 },
    });
    const usage = data.usageMetadata ?? {};
    const price = PRICING[model];
    const inputTokens = usage.promptTokenCount ?? 0;
    const outputTokens = usage.candidatesTokenCount ?? 0;

    return {
      text: data.candidates?.[0]?.content?.parts?.[0]?.text ?? "",
      model,
      inputTokens,
      outputTokens,
      // Unknown price records zero rather than a guess, for the reason at the
      // top of this file.
      costUsd: price
        ? (inputTokens * price.input + outputTokens * price.output) / 1e6
        : 0,
    };
  }
}

/**
 * The same schema, in the dialect Gemini accepts.
 *
 * Gemini's responseSchema is OpenAPI-shaped rather than JSON Schema: the type
 * is an upper-case enum, and the numeric bounds and item counts that the
 * Anthropic tool definition carries are rejected outright with a bare 400
 * saying "invalid argument" and nothing about which argument.
 *
 * Translating one definition rather than keeping two copies means a field
 * added for one vendor cannot silently miss the other. The bounds that get
 * dropped here are re-applied by Zod on the way out anyway, so nothing is
 * actually unchecked.
 */
export function toGeminiSchema(node: unknown): unknown {
  if (Array.isArray(node)) return node.map(toGeminiSchema);
  if (node === null || typeof node !== "object") return node;

  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(node as Record<string, unknown>)) {
    // Rejected by the API rather than ignored.
    if (
      key === "minimum" || key === "maximum" ||
      key === "maxItems" || key === "minItems" ||
      key === "additionalProperties"
    ) {
      continue;
    }
    if (key === "type" && typeof value === "string") {
      out[key] = value.toUpperCase();
      continue;
    }
    out[key] = toGeminiSchema(value);
  }
  return out;
}
