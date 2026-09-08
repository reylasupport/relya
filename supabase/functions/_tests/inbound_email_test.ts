import { assertEquals } from "jsr:@std/assert@1";
import {
  emailFrom,
  parseJson,
  stripHtml,
  tokenFrom,
} from "../_shared/email.ts";

Deno.test("the token comes out of the delivered-to address", () => {
  assertEquals(tokenFrom("u-a1b2c3d4e5f6@in.relya.app"), "a1b2c3d4e5f6");
  assertEquals(
    tokenFrom("Relya <u-a1b2c3d4e5f6@in.relya.app>"),
    "a1b2c3d4e5f6",
  );
  // Some forwarders add plus-addressing on the way through.
  assertEquals(tokenFrom("u-a1b2c3d4e5f6+spam@in.relya.app"), "a1b2c3d4e5f6");
  // And a provider's own shared address puts it after the plus instead, which
  // is what lets the whole thing be tested without owning a domain.
  assertEquals(
    tokenFrom("9f2b1c+u-a1b2c3d4e5f6@inbound.postmarkapp.com"),
    "a1b2c3d4e5f6",
  );
});

Deno.test("anything that is not one of our addresses is refused", () => {
  assertEquals(tokenFrom("someone@example.com"), null);
  assertEquals(tokenFrom("u-nothex@in.relya.app"), null);
  assertEquals(tokenFrom("u-short@in.relya.app"), null);
  assertEquals(tokenFrom(undefined), null);
  assertEquals(tokenFrom(""), null);
});

Deno.test("a sender is normalised before it is compared to the account", () => {
  assertEquals(emailFrom("Paulo <Paulo@Example.COM>"), "paulo@example.com");
  assertEquals(emailFrom("  paulo@example.com "), "paulo@example.com");
  assertEquals(emailFrom("not an address"), null);
});

Deno.test("the delivered-to address wins over the To header", () => {
  // A forwarded message still carries the address it was originally sent to.
  // Reading that instead of the envelope would look up the wrong account, or
  // none at all.
  const mail = parseJson({
    To: "paulo@example.com",
    OriginalRecipient: "u-a1b2c3d4e5f6@in.relya.app",
    From: "paulo@example.com",
    Subject: "Fatura",
    TextBody: "EDP, 48,20 EUR, vence a 12/10",
  });

  assertEquals(tokenFrom(mail.to), "a1b2c3d4e5f6");
  assertEquals(mail.subject, "Fatura");
  assertEquals(mail.text, "EDP, 48,20 EUR, vence a 12/10");
});

Deno.test("an envelope nested in the payload is read too", () => {
  const mail = parseJson({
    envelope: { to: ["u-a1b2c3d4e5f6@in.relya.app"], from: "p@example.com" },
    subject: "Reserva",
  });
  assertEquals(tokenFrom(mail.to), "a1b2c3d4e5f6");
  assertEquals(emailFrom(mail.from), "p@example.com");
});

Deno.test("an attachment is only taken when the bucket would accept it", () => {
  const pdf = parseJson({
    Attachments: [
      { Name: "a.exe", ContentType: "application/x-msdownload", Content: "AA==" },
      { Name: "fatura.pdf", ContentType: "application/pdf", Content: "JVBERi0=" },
    ],
  });
  assertEquals(pdf.attachment?.name, "fatura.pdf");
  assertEquals(pdf.attachment?.type, "application/pdf");

  const none = parseJson({
    Attachments: [{ Name: "a.zip", ContentType: "application/zip", Content: "AA==" }],
  });
  assertEquals(none.attachment, undefined);
});

Deno.test("html becomes something a model can read", () => {
  const text = stripHtml(
    "<style>p{color:red}</style><p>Total: 48,20&nbsp;&euro;</p>" +
      "<div>Vence a <b>12/10</b></div>",
  );
  assertEquals(text.includes("Total: 48,20"), true);
  assertEquals(text.includes("Vence a 12/10"), true);
  assertEquals(text.includes("<"), false);
});

Deno.test("cloudmailin's shape is read like any other", () => {
  // Its JSON nests the delivered-to address in an envelope and puts the body
  // in "plain", neither of which look like Postmark's.
  const mail = parseJson({
    envelope: {
      to: "9f2b1c+u-a1b2c3d4e5f6@cloudmailin.net",
      from: "paulo@example.com",
    },
    headers: { subject: "Fatura" },
    subject: "Fatura EDP",
    plain: "48,20 EUR",
  });

  assertEquals(tokenFrom(mail.to), "a1b2c3d4e5f6");
  assertEquals(emailFrom(mail.from), "paulo@example.com");
  assertEquals(mail.text, "48,20 EUR");
});
