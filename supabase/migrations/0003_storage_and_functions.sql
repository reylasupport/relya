-- Private storage for originals, plus the small amount of server-side logic
-- that has to live in the database.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'captures',
  'captures',
  false,
  26214400, -- 25 MB
  array['image/jpeg', 'image/png', 'image/heic', 'image/webp', 'application/pdf']
)
on conflict (id) do nothing;

-- Objects live at {user_id}/{filename}, and the first path segment is the
-- authorisation check. Nothing else can read them, and every URL handed to the
-- client is signed and short-lived.
create policy "read own captures" on storage.objects
  for select using (
    bucket_id = 'captures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "write own captures" on storage.objects
  for insert with check (
    bucket_id = 'captures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "delete own captures" on storage.objects
  for delete using (
    bucket_id = 'captures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------- quota ----

-- Atomic so two captures shared at once cannot both slip past the free limit.
create function consume_capture_quota(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_plan plan_tier;
  v_used integer;
  v_quota integer;
  v_resets timestamptz;
begin
  select plan, captures_this_period, capture_quota, period_resets_at
    into v_plan, v_used, v_quota, v_resets
    from profiles where id = p_user_id for update;

  if v_plan <> 'free' then
    return true;
  end if;

  if v_resets is null or v_resets < now() then
    update profiles
       set captures_this_period = 1,
           period_resets_at = now() + interval '30 days'
     where id = p_user_id;
    return true;
  end if;

  if v_quota is not null and v_used >= v_quota then
    return false;
  end if;

  update profiles
     set captures_this_period = captures_this_period + 1
   where id = p_user_id;
  return true;
end;
$$;

-- ------------------------------------------------------------- touch/updated_at ----

create function touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger life_items_touch
  before update on life_items
  for each row execute function touch_updated_at();

create trigger entities_touch
  before update on entities
  for each row execute function touch_updated_at();

create trigger profiles_touch
  before update on profiles
  for each row execute function touch_updated_at();

-- ------------------------------------------------- assistant retrieval ----

-- Everything the assistant is allowed to reason about, for one user, in one
-- window. The function is the boundary: the model never sees a row this does
-- not return, and it cannot widen the window by asking.
create function assistant_context(
  p_user_id uuid,
  p_from timestamptz default now() - interval '30 days',
  p_to timestamptz default now() + interval '400 days',
  p_limit integer default 60
)
returns table (
  id uuid,
  type life_item_type,
  title text,
  description text,
  start_at timestamptz,
  deadline_at timestamptz,
  amount numeric,
  currency char(3),
  organization text,
  location text
)
language sql
stable
security invoker
as $$
  select l.id, l.type, l.title, l.description, l.start_at, l.deadline_at,
         l.amount, l.currency, l.organization, l.location
    from life_items l
   where l.user_id = p_user_id
     and l.status in ('active', 'snoozed')
     and coalesce(l.start_at, l.deadline_at) between p_from and p_to
   order by coalesce(l.start_at, l.deadline_at)
   limit p_limit;
$$;
