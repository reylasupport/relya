-- Two holes in how the product meters itself.
--
-- 1. consume_capture_quota charged before the model was called and nothing
--    ever gave the capture back. A provider outage therefore billed the user
--    for work they never received, and a run of failures emptied the month.
-- 2. ask-assistant had no meter at all: no plan check, no rate limit, and no
--    row in ai_usage. Free accounts could ask an expensive model an unbounded
--    number of questions, and none of that spend appeared in the cost views,
--    so the first place it showed up was the invoice.
--
-- Written to be safe to run twice, like 0006 and 0007, because it is also
-- pasted by hand into the SQL editor on projects with no CLI linked.

-- --------------------------------------------------------------- refund ----

-- The mirror of consume_capture_quota. Called only from the failure path of
-- analyze-capture, so a capture the user never got back does not count.
--
-- Floors at zero rather than trusting the caller: a double refund from a retry
-- storm must not hand out free capture allowance.
create or replace function public.refund_capture_quota(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update profiles
     set captures_this_period = greatest(captures_this_period - 1, 0)
   where id = p_user_id
     and plan = 'free'
     and captures_this_period > 0;
end;
$$;

comment on function public.refund_capture_quota is
  'Gives back one capture after a failed analysis. Service role only.';

-- ------------------------------------------------------ assistant meter ----

-- A per-day counter rather than a per-period one. The assistant is asked in
-- bursts - a person checks three things at once and then not again for a week
-- - so a daily ceiling stops a runaway loop on the day it happens instead of
-- after it has spent the month.
alter table public.profiles
  add column if not exists assistant_questions_today integer not null default 0,
  add column if not exists assistant_day date;

-- Returns false when the free-plan daily ceiling is already reached.
--
-- Paid plans are waved through here and metered by ai_usage instead: the point
-- of the limit is cost control on accounts that bring in nothing, not a cap on
-- customers who pay.
create or replace function public.consume_assistant_quota(
  p_user_id uuid,
  p_daily_limit integer default 10
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_plan plan_tier;
  v_day  date;
  v_used integer;
begin
  select plan, assistant_day, assistant_questions_today
    into v_plan, v_day, v_used
    from profiles where id = p_user_id for update;

  if not found then
    return false;
  end if;

  if v_plan <> 'free' then
    return true;
  end if;

  -- First question of a new day: reset and count this one.
  if v_day is null or v_day <> current_date then
    update profiles
       set assistant_day = current_date,
           assistant_questions_today = 1
     where id = p_user_id;
    return true;
  end if;

  if v_used >= p_daily_limit then
    return false;
  end if;

  update profiles
     set assistant_questions_today = assistant_questions_today + 1
   where id = p_user_id;
  return true;
end;
$$;

comment on function public.consume_assistant_quota is
  'Free-plan daily ceiling for assistant questions. Service role only.';

-- Neither function is granted to `authenticated`, for the same reason
-- consume_capture_quota is not: both take a user id, so a client holding
-- execute could refund itself or burn somebody else's allowance. The edge
-- functions call them with the service role, which bypasses grants.
revoke all on function public.refund_capture_quota(uuid) from public, authenticated;
revoke all on function public.consume_assistant_quota(uuid, integer) from public, authenticated;

-- ---------------------------------------------------------- cost view -----

-- ai_usage now carries assistant rows, which have no capture_id. The old
-- per-user view divided total spend by the number of distinct captures, so
-- every assistant question quietly inflated "cost per capture". Split, so
-- both numbers mean what they say.
--
-- Dropped and recreated rather than replaced: create or replace view can only
-- append columns, and these belong in the middle.
drop view if exists public.ai_cost_per_user_month;

create view public.ai_cost_per_user_month
with (security_barrier = true) as
select
  user_id,
  date_trunc('month', created_at)::date         as month,
  count(*)                                      as calls,
  count(distinct capture_id)                    as captures,
  round(sum(cost_usd), 4)                       as cost_usd,
  round(sum(cost_usd) filter (where capture_id is not null), 4)
                                                as capture_cost_usd,
  round(sum(cost_usd) filter (where capture_id is null), 4)
                                                as assistant_cost_usd,
  round(
    sum(cost_usd) filter (where capture_id is not null)
      / nullif(count(distinct capture_id), 0),
    4
  )                                             as cost_per_capture_usd
from ai_usage
where user_id = auth.uid() or auth.uid() is null
group by 1, 2
order by 2 desc, 5 desc;

comment on view public.ai_cost_per_user_month is
  'Cost per user per month, extraction and assistant separated. Run as the '
  'service role to see every user; a signed-in client sees only its own rows.';

grant select on public.ai_cost_per_user_month to authenticated;
