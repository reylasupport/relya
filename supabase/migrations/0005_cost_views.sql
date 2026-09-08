-- What Relya costs to run, per day and per user.
--
-- ai_usage has recorded tokens, cost and latency since the first release, but
-- nothing read it. These views exist so "what does a free user cost us per
-- month" is a query rather than a guess, and so the answer arrives before the
-- invoice does.
--
-- All three are owner-only through the security barrier below: a signed-in
-- client can see its own consumption and nothing else. Operators read them
-- with the service role from the Supabase SQL editor.

-- One row per day: the shape of the bill over time.
create or replace view ai_cost_daily
with (security_barrier = true) as
select
  date_trunc('day', created_at)::date as day,
  provider,
  model,
  count(*)                             as calls,
  count(*) filter (where used_image)   as image_calls,
  count(*) filter (where not succeeded) as failures,
  sum(input_tokens)                    as input_tokens,
  sum(output_tokens)                   as output_tokens,
  round(sum(cost_usd), 4)              as cost_usd,
  round(avg(latency_ms))               as avg_latency_ms
from ai_usage
where user_id = auth.uid() or auth.uid() is null
group by 1, 2, 3
order by 1 desc;

-- One row per user per calendar month. The number that decides the price of
-- the subscription: if the median free user costs more than the plan brings
-- in, the plan is wrong.
create or replace view ai_cost_per_user_month
with (security_barrier = true) as
select
  user_id,
  date_trunc('month', created_at)::date as month,
  count(*)                              as calls,
  count(distinct capture_id)            as captures,
  round(sum(cost_usd), 4)               as cost_usd,
  round(sum(cost_usd) / nullif(count(distinct capture_id), 0), 4)
                                        as cost_per_capture_usd
from ai_usage
where user_id = auth.uid() or auth.uid() is null
group by 1, 2
order by 2 desc, 5 desc;

comment on view ai_cost_per_user_month is
  'Cost per user per month. Run as the service role to see every user; a '
  'signed-in client sees only its own rows.';

grant select on ai_cost_daily to authenticated;
grant select on ai_cost_per_user_month to authenticated;
