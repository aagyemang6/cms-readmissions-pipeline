-- Q4. Which states have the highest and lowest average hospital ratios?
-- States with fewer than 15 qualifying hospitals are excluded: their averages are too unstable to rank.
select
    state,
    count(*) as hospitals,
    round(avg(avg_excess_readmission_ratio), 4) as mean_ratio,
    round(100 * avg(cast(is_consistently_worse as int64)), 1) as pct_consistently_worse
from {{ ref('agg_hospital_readmissions') }}
where conditions_measured >= 3
group by 1
having count(*) >= 15
order by 3 desc
