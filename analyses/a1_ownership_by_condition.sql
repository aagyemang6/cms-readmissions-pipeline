-- Q1. Does ownership still matter when we compare like with like (within each condition)?
-- A raw average mixes conditions; comparing within each condition removes differences in case mix.
select
    f.condition,
    d.ownership_group,
    count(f.excess_readmission_ratio) as hospitals_with_ratio,
    round(avg(f.excess_readmission_ratio), 3) as avg_ratio,
    round(100 * avg(cast(f.is_worse_than_expected as int64)), 1) as pct_worse_than_expected
from {{ ref('fct_readmissions') }} f
join {{ ref('dim_hospitals') }} d using (facility_id)
where f.has_ratio and d.ownership_group is not null
group by 1, 2
order by 1, 4 desc
