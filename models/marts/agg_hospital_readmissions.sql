-- Aggregate: one row per hospital in the readmissions program (3,055 rows).
-- Rolls the six condition rows in fct_readmissions up to a single hospital-level view,
-- joined to the hospital attributes, so the dashboard can rank and compare hospitals directly.

with facts as (

    select * from {{ ref('fct_readmissions') }}

),

hospitals as (

    select * from {{ ref('dim_hospitals') }}

),

per_hospital as (

    select
        facility_id,
        count(excess_readmission_ratio) as conditions_measured,
        countif(is_worse_than_expected) as conditions_worse_than_expected,
        round(avg(excess_readmission_ratio), 4) as avg_excess_readmission_ratio,
        round(max(excess_readmission_ratio), 4) as max_excess_readmission_ratio,

        -- the condition with the highest ratio (NULL if the hospital has no ratios)
        array_agg(
            if(excess_readmission_ratio is null, null, condition)
            ignore nulls
            order by excess_readmission_ratio desc
            limit 1
        )[safe_offset(0)] as worst_condition,

        sum(discharges) as total_discharges
    from facts
    group by facility_id

),

final as (

    select
        per_hospital.facility_id,
        hospitals.facility_name,
        hospitals.city,
        hospitals.state,
        hospitals.ownership_group,
        hospitals.hospital_overall_rating,
        hospitals.has_emergency_services,
        hospitals.is_in_hospital_directory,

        per_hospital.conditions_measured,
        per_hospital.conditions_worse_than_expected,
        per_hospital.avg_excess_readmission_ratio,
        per_hospital.max_excess_readmission_ratio,
        per_hospital.worst_condition,
        per_hospital.total_discharges,

        -- a hospital with ratios for at least 3 conditions, all worse than expected
        per_hospital.conditions_measured >= 3
            and per_hospital.conditions_worse_than_expected = per_hospital.conditions_measured
            as is_consistently_worse

    from per_hospital
    inner join hospitals using (facility_id)  -- safe: the relationships test guarantees a match

)

select * from final
