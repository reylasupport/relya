import { Extraction } from "./schema.ts";

/**
 * Post-processing the model cannot be trusted to do consistently.
 *
 * Everything here is defensive: clamping values into range, dropping dates
 * that did not resolve, and stopping obviously wrong reminders from being
 * offered. Cheap to run, and it removes a whole class of "the app scheduled
 * something absurd" bug reports.
 */
export function normalise(item: Extraction, now: Date): Extraction {
  const dates = item.dates
    .filter((date) => {
      if (!date.resolved) return true;
      const parsed = new Date(date.resolved);
      if (Number.isNaN(parsed.getTime())) return false;
      // A resolved date more than a century out is a hallucination or a parse
      // artefact, not a real deadline.
      const years = Math.abs(parsed.getFullYear() - now.getFullYear());
      return years <= 100;
    })
    // One representation downstream. The schema accepts both the Z form and
    // a local offset, because models reach for whichever the document
    // suggests and both are real instants; everything after this point sees
    // UTC. The IANA zone travels in its own field, so nothing is lost.
    .map((date) =>
      date.resolved
        ? {
          ...date,
          resolved: new Date(date.resolved).toISOString(),
          alternative: date.alternative
            ? new Date(date.alternative).toISOString()
            : date.alternative,
        }
        : date
    );

  const anchorKinds = new Set(dates.map((d) => d.kind));
  const reminders = item.suggested_reminders
    .filter((reminder) => {
      const wanted = reminder.anchor === "deadline" ? "deadline" : "start";
      // Keep a reminder only if the date it hangs off actually exists.
      if (anchorKinds.has(wanted)) return true;
      return wanted === "deadline"
        ? anchorKinds.has("expiry") || anchorKinds.has("renewal")
        : false;
    })
    .slice(0, 3);

  return {
    ...item,
    confidence: Math.min(1, Math.max(0, item.confidence)),
    currency: item.currency ? item.currency.toUpperCase() : item.currency,
    dates,
    suggested_reminders: reminders,
  };
}
