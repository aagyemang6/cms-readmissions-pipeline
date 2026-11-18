-- Q3. Do hospitals with lower CMS star ratings have worse readmissions?
-- Note: readmissions are one of the inputs to the star rating, so some link is expected.
select
    coalesce(cast(hospital_overall_rating as string), 'No rating') as star_rating,
    count(*) as hospitals,
    round(avg(avg_excess_readmission_ratio), 4) as mean_ratio,
    round(avg(avg_excess_readmission_ratio) - 1.96 * stddev(avg_excess_readmission_ratio) / sqrt(count(*)), 4) as ci_low,
    round(avg(avg_excess_readmission_ratio) + 1.96 * stddev(avg_excess_readmission_ratio) / sqrt(count(*)), 4) as ci_high,
    round(100 * avg(cast(is_consistently_worse as int64)), 1) as pct_consistently_worse
from {{ ref('agg_hospital_readmissions') }}
where conditions_measured >= 3
group by 1
order by 1
