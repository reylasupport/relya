import { analysisSchema } from "../schema.ts";
import {
  AIProvider,
  AnswerResult,
  ExtractionRequest,
  ProviderResult,
} from "./provider.ts";

const API = "https://api.openai.com/v1/chat/completions";

const PRICING: Record<string, { input: number; output: number }> = {
  "gpt-4.1": { input: 2, output: 8 },
  "gpt-4.1-mini": { input: 0.4, output: 1.6 },
};

/** Second implementation of the same interface. Exists so the product is never
 *  hostage to one vendor pricing or availability. */
export class OpenAIProvider implements AIProvider {
  readonly name = "openai";

  constructor(
    private readonly apiKey: string,
    private readonly largeModel = Deno.env.get("AI_MODEL_LARGE") ?? "gpt-4.1",
    private readonly smallModel = Deno.env.get("AI_MODEL_SMALL") ??
      "gpt-4.1-mini",
  ) {}

  private async call(body: Record<string, unknown>) {
    const response = await fetch(API, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        "content-type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      throw new Error(`OpenAI ${response.status}: ${await response.text()}`);
    }
    return await response.json();
  }

  async extract(request: ExtractionRequest): Promise<ProviderResult> {
    const model = request.imageBase64 || !request.preferSmallModel
      ? this.largeModel
      : this.smallModel;

    const content: unknown[] = [{ type: "text", text: request.userPrompt }];
    if (request.imageBase64) {
      content.push({
        type: "image_url",
        image_url: {
          url: `data:${request.imageMimeType ?? "image/jpeg"};base64,${request.imageBase64}`,
        },
      });
    }

    const data = await this.call({
      model,
      max_tokens: 2048,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content:
            `${request.systemPrompt}\n\nRespond with a single JSON object of the form {"detected_language": string, "items": [...]}.`,
        },
        { role: "user", content },
      ],
    });

    const raw = data.choices?.[0]?.message?.content;
    if (typeof raw !== "string") throw new Error("Model returned no content");

    const analysis = analysisSchema.parse(JSON.parse(raw));
    const usage = data.usage ?? {};
    const price = PRICING[model] ?? { input: 2, output: 8 };
    const inputTokens = usage.prompt_tokens ?? 0;
    const outputTokens = usage.completion_tokens ?? 0;

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
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
    });
    const usage = data.usage ?? {};
    const price = PRICING[model] ?? { input: 0.4, output: 1.6 };
    const inputTokens = usage.prompt_tokens ?? 0;
    const outputTokens = usage.completion_tokens ?? 0;

    return {
      text: data.choices?.[0]?.message?.content ?? "",
      model,
      inputTokens,
      outputTokens,
      costUsd: (inputTokens * price.input + outputTokens * price.output) / 1e6,
    };
  }
}
