-- Fact: one row per hospital per condition (3,055 hospitals x 6 conditions).
-- Holds the readmission measurements. Hospital descriptions live in dim_hospitals; join on facility_id.
-- This is where business rules go: what counts as "worse than expected", and how far off a hospital is.

with readmissions as (

    select * from {{ ref('stg_hrrp_readmissions') }}

),

final as (

    select
        -- keys
        readmission_id,
        facility_id,
        measure_id,
        condition,

        -- volumes
        discharges,
        readmissions,

        -- rates (percent of patients readmitted within 30 days)
        predicted_readmission_rate,
        expected_readmission_rate,

        -- the key metric: predicted / expected. Above 1.0 means more readmissions than expected.
        excess_readmission_ratio,

        -- business rules
        excess_readmission_ratio is not null as has_ratio,

        case
            when excess_readmission_ratio is null then null
            else excess_readmission_ratio > 1
        end as is_worse_than_expected,

        -- how far from expected, in percent: 1.08 becomes +8.0, 0.95 becomes -5.0
        round((excess_readmission_ratio - 1) * 100, 1) as pct_vs_expected,

        -- why a value may be missing
        is_readmissions_suppressed,
        footnote_code,

        -- measurement period
        period_start_date,
        period_end_date

    from readmissions

)

select * from final
