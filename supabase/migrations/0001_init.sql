-- Relya core schema.
--
-- Two rules hold everywhere in this file:
--   1. Every row belongs to exactly one user, via user_id.
--   2. Row Level Security is on, and the only policy is "you own it".
-- A forgotten WHERE clause in application code is then a bug that returns
-- nothing, not a bug that leaks somebody else appointments.

create extension if not exists "pgcrypto";
create extension if not exists "unaccent";

-- ---------------------------------------------------------------- enums ----

create type life_item_type as enum (
  'appointment', 'bill', 'subscription', 'purchase', 'return', 'warranty',
  'travel', 'document', 'insurance', 'vehicle', 'home', 'event', 'delivery',
  'reservation', 'education', 'task', 'other'
);

create type life_item_status as enum (
  'pending_confirmation', 'active', 'done', 'snoozed', 'archived'
);

create type capture_source as enum (
  'share_sheet', 'camera', 'photo_library', 'file_upload', 'pasted_text',
  'manual', 'demo'
);

create type capture_kind as enum ('image', 'pdf', 'text', 'url');

create type capture_status as enum (
  'queued', 'processing', 'needs_confirmation', 'completed', 'failed', 'archived'
);

create type reminder_anchor as enum ('start', 'deadline', 'absolute');

create type reminder_status as enum (
  'scheduled', 'delivered', 'dismissed', 'cancelled'
);

create type entity_type as enum (
  'person', 'vehicle', 'home', 'product', 'organization', 'subscription',
  'document', 'trip', 'health'
);

create type plan_tier as enum ('free', 'pro', 'family');

create type retention_policy as enum ('keep_original', 'extracted_only');

create type sensitivity_level as enum ('normal', 'personal', 'sensitive');

-- ------------------------------------------------------------- profiles ----

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  email text,
  -- BCP-47. Null means follow the device.
  locale text,
  -- IANA zone, refreshed by the client whenever the device reports a new one.
  timezone text default 'UTC',
  plan plan_tier not null default 'free',
  captures_this_period integer not null default 0,
  capture_quota integer default 20,
  period_resets_at timestamptz default (now() + interval '30 days'),
  onboarded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table user_preferences (
  user_id uuid primary key references auth.users on delete cascade,
  theme_mode text not null default 'system',
  locale text,
  notifications_enabled boolean not null default true,
  muted_categories text[] not null default '{}',
  quiet_hours_start text,
  quiet_hours_end text,
  default_lead_seconds integer[] not null default '{86400,7200}',
  retention retention_policy not null default 'keep_original',
  biometric_lock boolean not null default false,
  analytics_opt_in boolean not null default true,
  updated_at timestamptz not null default now()
);

-- Created the moment an account exists, so no code path ever has to cope with
-- a signed-in user who has no profile row.
create function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name')
  )
  on conflict (id) do nothing;

  insert into public.user_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ------------------------------------------------------------- captures ----

create table captures (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  source capture_source not null,
  kind capture_kind not null,
  status capture_status not null default 'queued',
  title text,
  raw_text text,
  source_url text,
  storage_path text,
  -- SHA-256 of the input. The cheapest cost control we have: the same
  -- screenshot shared twice is analysed once.
  content_hash text,
  ocr_text text,
  detected_language text,
  item_count integer not null default 0,
  error_message text,
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

create unique index captures_user_hash_idx
  on captures (user_id, content_hash)
  where content_hash is not null and status <> 'failed';

create index captures_user_status_idx on captures (user_id, status, created_at desc);

create table attachments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  capture_id uuid references captures on delete cascade,
  storage_path text not null,
  mime_type text,
  byte_size bigint,
  sensitivity sensitivity_level not null default 'normal',
  created_at timestamptz not null default now()
);

create index attachments_capture_idx on attachments (capture_id);

-- The validated model output, kept verbatim so the confirmation screen can be
-- reopened without paying for a second analysis.
create table capture_analyses (
  capture_id uuid primary key references captures on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  payload jsonb not null,
  model text,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------- entities ----

create table entities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  type entity_type not null,
  name text not null,
  subtitle text,
  -- Licence plate, serial number, policy number. What lets two captures months
  -- apart be recognised as the same car.
  identifiers jsonb not null default '{}',
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index entities_user_type_idx on entities (user_id, type);
create index entities_identifiers_idx on entities using gin (identifiers);

create table entity_relationships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  from_entity_id uuid not null references entities on delete cascade,
  to_entity_id uuid not null references entities on delete cascade,
  relation text not null,
  created_at timestamptz not null default now(),
  unique (from_entity_id, to_entity_id, relation)
);

-- ----------------------------------------------------------- life_items ----

create table life_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  capture_id uuid references captures on delete set null,
  entity_id uuid references entities on delete set null,
  type life_item_type not null default 'other',
  title text not null,
  description text,
  status life_item_status not null default 'active',
  start_at timestamptz,
  -- The zone the event happens in, which is not necessarily the zone the user
  -- is in when they read about it.
  start_tz text,
  end_at timestamptz,
  deadline_at timestamptz,
  all_day boolean not null default false,
  amount numeric(14,2),
  currency char(3),
  location text,
  organization text,
  confidence real not null default 1.0,
  source_language text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  search_vector tsvector generated always as (
    to_tsvector(
      'simple',
      coalesce(title, '') || ' ' ||
      coalesce(description, '') || ' ' ||
      coalesce(organization, '') || ' ' ||
      coalesce(location, '')
    )
  ) stored
);

create index life_items_user_start_idx
  on life_items (user_id, start_at)
  where status in ('active', 'snoozed');

create index life_items_user_deadline_idx
  on life_items (user_id, deadline_at)
  where status in ('active', 'snoozed');

create index life_items_user_status_idx on life_items (user_id, status);
create index life_items_capture_idx on life_items (capture_id);
create index life_items_entity_idx on life_items (entity_id);
create index life_items_search_idx on life_items using gin (search_vector);
create index life_items_metadata_idx on life_items using gin (metadata);

-- ------------------------------------------------------------ reminders ----

create table reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  item_id uuid not null references life_items on delete cascade,
  -- Always UTC. The zone is kept beside it so a wall-clock reminder can be
  -- recomputed when the user travels.
  fire_at timestamptz not null,
  timezone text not null default 'UTC',
  anchor reminder_anchor not null default 'start',
  lead_seconds integer,
  label text,
  status reminder_status not null default 'scheduled',
  local_notification_id integer,
  created_at timestamptz not null default now()
);

create index reminders_pending_idx
  on reminders (user_id, fire_at)
  where status = 'scheduled';

create index reminders_item_idx on reminders (item_id);

-- -------------------------------------------------------------- devices ----

create table devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  push_token text not null,
  platform text not null,
  locale text,
  timezone text,
  app_version text,
  last_seen_at timestamptz not null default now(),
  unique (user_id, push_token)
);

-- ------------------------------------------------- feedback and metrics ----

-- Every correction the user makes. The only honest measure of how good the
-- extraction actually is, and the seed corpus for improving it.
create table extraction_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  capture_id uuid references captures on delete cascade,
  item_id uuid references life_items on delete cascade,
  field text not null,
  original_value text,
  corrected_value text,
  note text,
  created_at timestamptz not null default now()
);

-- Cost per capture, per user, per model. Without this the AI bill is a
-- surprise at the end of the month instead of a number we manage.
create table ai_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  capture_id uuid references captures on delete set null,
  provider text not null,
  model text not null,
  input_tokens integer not null default 0,
  output_tokens integer not null default 0,
  cost_usd numeric(10,6) not null default 0,
  latency_ms integer,
  used_image boolean not null default false,
  succeeded boolean not null default true,
  created_at timestamptz not null default now()
);

create index ai_usage_user_month_idx on ai_usage (user_id, created_at desc);

-- Sensitive actions only: exports, deletions, document access. Not a general
-- activity log, because logging everything is its own privacy problem.
create table audit_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  action text not null,
  detail jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index audit_events_user_idx on audit_events (user_id, created_at desc);
