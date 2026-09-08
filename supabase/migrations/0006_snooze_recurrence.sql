-- Snooze and real recurrence.
--
-- Both were half-present before: life_item_status already had 'snoozed' and no
-- code path could produce it, and a recurrence was a string the model left in
-- metadata that never became a second occurrence.
--
-- Written to be safe to run twice, because it is also pasted by hand into the
-- SQL editor on projects with no CLI linked.

alter table public.life_items
  -- When a snoozed item comes back on its own. Kept beside the status rather
  -- than replacing the date: snoozing a bill must not move when it is due.
  add column if not exists snoozed_until timestamptz,
  -- A deliberately small subset of RFC 5545: FREQ=DAILY|WEEKLY|MONTHLY|YEARLY
  -- with an optional INTERVAL. Anything richer belongs in a calendar app.
  add column if not exists recurrence_rule text,
  add column if not exists recurrence_until timestamptz,
  -- Every occurrence of the same repeating thing shares this, so a series can
  -- be found and stopped as a whole.
  add column if not exists series_id uuid;

-- Snoozed items are read on every Home load; the partial index keeps that from
-- touching the rest of the table.
create index if not exists life_items_user_snoozed_idx
  on public.life_items (user_id, snoozed_until)
  where status = 'snoozed';

create index if not exists life_items_series_idx
  on public.life_items (series_id)
  where series_id is not null;

-- A repeating item with no date has no next occurrence to compute, so the
-- client would loop on it forever. ADD CONSTRAINT has no IF NOT EXISTS.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'life_items_recurrence_needs_a_date'
      and conrelid = 'public.life_items'::regclass
  ) then
    alter table public.life_items
      add constraint life_items_recurrence_needs_a_date
      check (
        recurrence_rule is null
        or start_at is not null
        or deadline_at is not null
      );
  end if;
end $$;

-- PostgREST keeps the schema in memory. Without this the API answers "column
-- snoozed_until does not exist" until the next restart.
notify pgrst, 'reload schema';
