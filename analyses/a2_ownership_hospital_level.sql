-- Q2. Hospital-level comparison by ownership, with a 95% confidence interval for each group mean.
-- One value per hospital (its average ratio), so large hospitals with six ratios don't count six times.
-- Only hospitals with at least 3 measured conditions, so each hospital's average is reasonably stable.
select
    ownership_group,
    count(*) as hospitals,
    round(avg(avg_excess_readmission_ratio), 4) as mean_ratio,
    round(avg(avg_excess_readmission_ratio) - 1.96 * stddev(avg_excess_readmission_ratio) / sqrt(count(*)), 4) as ci_low,
    round(avg(avg_excess_readmission_ratio) + 1.96 * stddev(avg_excess_readmission_ratio) / sqrt(count(*)), 4) as ci_high,
    round(100 * avg(cast(is_consistently_worse as int64)), 1) as pct_consistently_worse
from {{ ref('agg_hospital_readmissions') }}
where conditions_measured >= 3 and ownership_group is not null
group by 1
order by 3 desc
