-- The two halves of "how the app looks", which the client has been sending
-- since the appearance screen was built and the table has never had a place
-- for. Until now a save of the theme failed the whole upsert with "column
-- user_preferences.theme_skin does not exist", which took the rest of the
-- preferences down with it.
--
-- Both are plain text rather than enums on purpose: the set of designs and of
-- accents changes with the app, and a client one version ahead of the database
-- should be able to store its choice, not be refused it. The client already
-- falls back to its own default for a value it does not recognise.
alter table user_preferences
  add column if not exists theme_skin text,
  add column if not exists theme_accent text not null default 'azul';

-- Nothing is granted here: column privileges follow the table, and
-- 0004_grants.sql already grants user_preferences to authenticated. The row
-- policy in 0002_rls.sql is likewise per row, not per column.

comment on column user_preferences.theme_skin is
  'Chosen design. Null means the app has not been told, and picks its default.';
comment on column user_preferences.theme_accent is
  'Chosen accent colour. Only applies to designs that offer the choice.';
