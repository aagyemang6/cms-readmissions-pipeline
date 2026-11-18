-- Q5. Which hospitals are worse than expected on every condition they are measured on (at least 3)?
-- And how do they differ from everyone else?
select
    count(*) as hospitals_with_3plus_conditions,
    countif(is_consistently_worse) as consistently_worse,
    round(100 * avg(cast(is_consistently_worse as int64)), 1) as pct_consistently_worse,
    round(avg(if(is_consistently_worse, hospital_overall_rating, null)), 2) as avg_stars_consistently_worse,
    round(avg(if(not is_consistently_worse, hospital_overall_rating, null)), 2) as avg_stars_others,
    round(100 * avg(if(is_consistently_worse, cast(ownership_group = 'For-profit' as int64), null)), 1) as pct_for_profit_consistently_worse,
    round(100 * avg(if(not is_consistently_worse, cast(ownership_group = 'For-profit' as int64), null)), 1) as pct_for_profit_others
from {{ ref('agg_hospital_readmissions') }}
where conditions_measured >= 3
