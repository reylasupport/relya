-- Explicit privileges for the signed-in role.
--
-- Supabase can grant these automatically when a project is created with
-- "Automatically expose new tables" on, but that is a checkbox in a form, not
-- a property of this schema. Anyone restoring these migrations into a project
-- created with it off would get "permission denied for table life_items" on
-- every request, with nothing in the repository to explain why.
--
-- Safe to grant because every one of these tables has Row Level Security
-- enabled in 0002_rls.sql with an owner-only policy: a privilege here still
-- cannot read another user's row. The dangerous combination is exposure
-- without RLS, which this schema does not contain.
--
-- Nothing is granted to `anon`. There is no part of Relya a signed-out client
-- may read.

grant usage on schema public to authenticated;

grant select, insert, update, delete on table
  public.profiles,
  public.user_preferences,
  public.captures,
  public.attachments,
  public.capture_analyses,
  public.entities,
  public.entity_relationships,
  public.life_items,
  public.reminders,
  public.devices,
  public.extraction_feedback
to authenticated;

-- Accounting and audit are written by the server, read by the owner. A client
-- that could edit its own usage rows could edit its own bill.
grant select on table public.ai_usage to authenticated;
grant select on table public.audit_events to authenticated;

grant usage, select on all sequences in schema public to authenticated;

-- assistant_context is called by ask-assistant with the caller's own JWT, so
-- the signed-in role needs execute. It is security invoker and reads
-- life_items, which means RLS still applies: passing somebody else's user id
-- returns an empty set rather than their week.
grant execute on function public.assistant_context to authenticated;

-- consume_capture_quota is deliberately NOT granted. It takes a user id and
-- decrements that user's allowance, so a client holding execute could burn
-- somebody else's quota. Only analyze-capture calls it, with the service role,
-- which bypasses grants entirely.
