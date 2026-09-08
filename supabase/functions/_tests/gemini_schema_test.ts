import { assertEquals } from "jsr:@std/assert@1";
import { EXTRACTION_TOOL_SCHEMA } from "../_shared/ai/anthropic.ts";
import { toGeminiSchema } from "../_shared/ai/gemini.ts";

/**
 * One schema definition, translated per vendor.
 *
 * The risk of translating rather than duplicating is that the translation is
 * wrong in a way that only shows up as a 400 from the API in production. These
 * tests pin both halves: what must be dropped, and what must survive.
 */

function collectKeys(node: unknown, into = new Set<string>()): Set<string> {
  if (Array.isArray(node)) {
    for (const child of node) collectKeys(child, into);
    return into;
  }
  if (node === null || typeof node !== "object") return into;
  for (const [key, value] of Object.entries(node as Record<string, unknown>)) {
    into.add(key);
    collectKeys(value, into);
  }
  return into;
}

Deno.test("the keywords Gemini rejects are stripped", () => {
  const original = collectKeys(EXTRACTION_TOOL_SCHEMA);
  // Guards the test itself: if the source schema stops carrying bounds, this
  // test would pass while proving nothing.
  assertEquals(original.has("minimum"), true);
  assertEquals(original.has("maximum"), true);

  const translated = collectKeys(toGeminiSchema(EXTRACTION_TOOL_SCHEMA));
  assertEquals(translated.has("minimum"), false);
  assertEquals(translated.has("maximum"), false);
  assertEquals(translated.has("additionalProperties"), false);
});

Deno.test("everything that carries meaning survives the translation", () => {
  const translated = toGeminiSchema(EXTRACTION_TOOL_SCHEMA) as Record<
    string,
    unknown
  >;
  const keys = collectKeys(translated);
  for (const kept of ["type", "properties", "required", "items", "enum"]) {
    assertEquals(keys.has(kept), true, `${kept} was dropped`);
  }

  // The closed category list is the whole defence against a document
  // inventing its own kind of thing, so it has to reach Gemini intact.
  const items = (translated.properties as Record<string, never>)["items"] as
    Record<string, unknown>;
  const item = (items.items as Record<string, unknown>);
  const category = (item.properties as Record<string, Record<string, unknown>>)
    .category;
  assertEquals((category.enum as string[]).length, 17);
  assertEquals((category.enum as string[])[0], "appointment");
});

Deno.test("the required fields of an extracted item are preserved", () => {
  const translated = toGeminiSchema(EXTRACTION_TOOL_SCHEMA) as Record<
    string,
    unknown
  >;
  const items = (translated.properties as Record<string, never>)["items"] as
    Record<string, unknown>;
  const item = items.items as Record<string, unknown>;
  assertEquals(item.required, ["category", "title", "confidence"]);
});
