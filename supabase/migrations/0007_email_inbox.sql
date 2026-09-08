-- Forwarding an email into Relya.
--
-- Most of what this app is for arrives in an inbox, not on a screen. Giving
-- each account an address it can forward to closes the gap between "you never
-- have to remember anything" and "you have to remember to open the app".
--
-- Deliberately not inbox access: no OAuth, no scanning, nothing to revoke.
-- The user pushes one message at a time, which is also the version that needs
-- no approval from Google or Microsoft to ship.
--
-- Written to be safe to run twice.

-- ALTER TYPE ... ADD VALUE cannot be used in the same transaction that adds
-- it, so nothing below writes an 'email' capture.
alter type capture_source add value if not exists 'email';

-- 18 hex characters. Long enough that the address cannot be guessed, short
-- enough to read out loud once.
alter table public.profiles
  add column if not exists inbox_token text
  default encode(gen_random_bytes(9), 'hex');

update public.profiles
  set inbox_token = encode(gen_random_bytes(9), 'hex')
  where inbox_token is null;

alter table public.profiles
  alter column inbox_token set not null;

create unique index if not exists profiles_inbox_token_idx
  on public.profiles (inbox_token);

notify pgrst, 'reload schema';
