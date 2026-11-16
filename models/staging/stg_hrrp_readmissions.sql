-- Staging model: one row per hospital per condition (same grain as the raw table).
-- Job: rename columns, convert text to real types, and turn CMS text codes into NULLs.
-- No joins, no filtering, no business logic here.

with source as (

    select * from {{ source('cms_raw', 'hrrp_readmissions') }}

),

cleaned as (

    select
        -- keys
        concat(facility_id, '-', measure_name) as readmission_id,
        facility_id,
        measure_name as measure_id,

        -- descriptions
        facility_name,
        state,
        case measure_name
            when 'READM-30-AMI-HRRP' then 'Heart attack'
            when 'READM-30-HF-HRRP' then 'Heart failure'
            when 'READM-30-PN-HRRP' then 'Pneumonia'
            when 'READM-30-COPD-HRRP' then 'COPD'
            when 'READM-30-HIP-KNEE-HRRP' then 'Hip/knee replacement'
            when 'READM-30-CABG-HRRP' then 'Bypass surgery (CABG)'
        end as condition,

        -- measures: SAFE_CAST returns NULL for 'N/A' and 'Too Few to Report'
        safe_cast(excess_readmission_ratio as float64) as excess_readmission_ratio,
        safe_cast(predicted_readmission_rate as float64) as predicted_readmission_rate,
        safe_cast(expected_readmission_rate as float64) as expected_readmission_rate,
        safe_cast(number_of_discharges as int64) as discharges,
        safe_cast(number_of_readmissions as int64) as readmissions,

        -- keep the reason a value is missing, so it isn't lost when the text becomes NULL
        number_of_readmissions = 'Too Few to Report' as is_readmissions_suppressed,
        nullif(footnote, '') as footnote_code,

        -- measurement period
        parse_date('%m/%d/%Y', start_date) as period_start_date,
        parse_date('%m/%d/%Y', end_date) as period_end_date

    from source

)

select * from cleaned
