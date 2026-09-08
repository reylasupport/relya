-- Row Level Security.
--
-- One policy shape for every table: you can see and change exactly the rows
-- that are yours. There is no admin bypass here; anything operational uses the
-- service role, which is only ever available inside Edge Functions.

alter table profiles enable row level security;
alter table user_preferences enable row level security;
alter table captures enable row level security;
alter table attachments enable row level security;
alter table capture_analyses enable row level security;
alter table entities enable row level security;
alter table entity_relationships enable row level security;
alter table life_items enable row level security;
alter table reminders enable row level security;
alter table devices enable row level security;
alter table extraction_feedback enable row level security;
alter table ai_usage enable row level security;
alter table audit_events enable row level security;

create policy "own profile" on profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "own preferences" on user_preferences
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own captures" on captures
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own attachments" on attachments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own analyses" on capture_analyses
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own entities" on entities
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own relationships" on entity_relationships
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own items" on life_items
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own reminders" on reminders
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own devices" on devices
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own feedback" on extraction_feedback
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Usage and audit rows are written by the server on the user behalf. The user
-- may read their own, but must never be able to forge or erase them.
create policy "read own usage" on ai_usage
  for select using (auth.uid() = user_id);

create policy "read own audit" on audit_events
  for select using (auth.uid() = user_id);
