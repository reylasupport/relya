import { Analysis } from "../schema.ts";

export interface ExtractionRequest {
  systemPrompt: string;
  userPrompt: string;
  /** Base64 image, sent only when on-device OCR produced nothing usable. */
  imageBase64?: string;
  imageMimeType?: string;
  /** Small model for plain text, large multimodal one for pixels. */
  preferSmallModel: boolean;
}

export interface ProviderResult {
  analysis: Analysis;
  model: string;
  inputTokens: number;
  outputTokens: number;
  costUsd: number;
}

/**
 * What an assistant answer cost.
 *
 * answer() used to return a bare string, which is why every question the
 * assistant was ever asked is missing from ai_usage and from the cost views
 * built on it. Same shape as ProviderResult so both call sites account for
 * themselves the same way.
 */
export interface AnswerResult {
  text: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
  costUsd: number;
}

/**
 * One interface, several vendors (spec section 39). Swapping provider is an
 * environment variable, not a code change, which matters because model pricing
 * and quality move faster than release cycles.
 */
export interface AIProvider {
  readonly name: string;
  extract(request: ExtractionRequest): Promise<ProviderResult>;
  answer(systemPrompt: string, userPrompt: string): Promise<AnswerResult>;
}
