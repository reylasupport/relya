import { AnthropicProvider } from "./anthropic.ts";
import { GeminiProvider } from "./gemini.ts";
import { OpenAIProvider } from "./openai.ts";
import { AIProvider } from "./provider.ts";

/**
 * Picks the provider from the environment. A new vendor is a new file plus a
 * case here; nothing else in the codebase knows which one is in use.
 *
 * Gemini is the one with a free tier that is also multimodal, which matters
 * because the main input to this product is a photograph of a document. Note
 * that Google's free tier trains on what you send it - fine while building,
 * not fine once real receipts and medical appointments are going through.
 */
export function createProvider(): AIProvider {
  const choice = (Deno.env.get("AI_PROVIDER") ?? "anthropic").toLowerCase();

  switch (choice) {
    case "gemini":
    case "google": {
      const key = requireKey("GEMINI_API_KEY");
      return new GeminiProvider(key);
    }
    case "openai": {
      const key = requireKey("OPENAI_API_KEY");
      return new OpenAIProvider(key);
    }
    case "anthropic":
    default: {
      const key = requireKey("ANTHROPIC_API_KEY");
      return new AnthropicProvider(key);
    }
  }
}

function requireKey(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(
      `${name} is not configured. Provider credentials live only in Edge Function secrets.`,
    );
  }
  return value;
}
