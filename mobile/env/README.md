# Build-time configuration

Copy `example.json` to `dev.json`, `staging.json` and `prod.json` and fill in
the values for each environment. Those three files are gitignored.

```bash
flutter run --dart-define-from-file=env/dev.json
```

Nothing in these files is confidential. Everything in a mobile binary can be
read by anyone holding the binary, so only publishable values belong here:

* the Supabase URL and publishable (anon) key, which are gated by Row Level
  Security;
* the RevenueCat public SDK keys, which are designed to ship in a client;
* the PostHog project key and the Sentry DSN, both write-only ingest tokens.

Model provider credentials, the Supabase service-role key and the RevenueCat
webhook secret are **server-side only**. They live in Edge Function secrets and
are listed in the repository-root `.env.example`.
