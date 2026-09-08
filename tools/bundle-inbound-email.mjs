// Builds a single-file copy of the inbound-email function.
//
// The dashboard's function editor has no notion of ../_shared, so a project
// with no CLI linked cannot deploy the real thing. This flattens the three
// files into one that can be pasted in as-is.
//
//   node tools/bundle-inbound-email.mjs
//
// The canonical source stays supabase/functions/inbound-email/index.ts plus
// _shared; this output is generated, never edited by hand.

import { readFileSync, writeFileSync } from 'node:fs';

const root = 'supabase/functions';
const out = 'tools/inbound-email.bundled.ts';

// [^;] rather than [\s\S] in both: a lazy match over any character would run
// past the end of one import statement and swallow the one above it.
const LOCAL_IMPORT = /import\s[^;]*?from\s+["']\.[^"']*["'];\n/g;
const REMOTE_IMPORT = /^import\s[^;]*?from\s+["'][^.][^"']*["'];\n/gm;

const header = `// GENERATED - do not edit.
//
// Built by tools/bundle-inbound-email.mjs from:
//   supabase/functions/_shared/cors.ts
//   supabase/functions/_shared/email.ts
//   supabase/functions/inbound-email/index.ts
//
// Paste this into the Supabase dashboard: Edge Functions -> Deploy a new
// function, named "inbound-email". Set INBOUND_EMAIL_SECRET in the function
// secrets first, or every call answers 500.

`;

const joined = [
  `${root}/_shared/cors.ts`,
  `${root}/_shared/email.ts`,
  `${root}/inbound-email/index.ts`,
]
  .map((path) => readFileSync(path, 'utf8').replace(LOCAL_IMPORT, ''))
  .join('\n');

// Legal anywhere at the top level, but an import halfway down a file reads
// like a mistake. Hoisted so the paste looks like something a person wrote.
const imports = [...new Set(joined.match(REMOTE_IMPORT) ?? [])].join('');
const body = header + imports + '\n' + joined.replace(REMOTE_IMPORT, '');

const leftover = body.match(/from\s+["']\.[^"']*["']/g);
if (leftover) {
  console.error('A relative import survived:', leftover);
  process.exit(1);
}
if (!body.includes('jsr:@supabase/supabase-js')) {
  console.error('The remote import was stripped by mistake');
  process.exit(1);
}

writeFileSync(out, body);
console.log(`wrote ${out} (${body.split('\n').length} lines)`);
