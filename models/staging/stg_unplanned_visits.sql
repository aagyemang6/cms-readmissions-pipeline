-- Staging model: one row per hospital per measure (same grain as the raw table).
-- Job: rename columns, convert text to real types, and turn CMS text codes into NULLs.
-- No joins, no filtering, no business logic here.

with source as (
    select * from {{source('cms_raw','unplanned_hospital_visits') }}
),
cleaned as (
    select
        concat(facility_id, '-', measure_id) as visit_measure_id,
        facility_id,
        measure_id,
        measure_name,

        -- comparison label: 'Not Available' becomes NULL
        nullif(compared_to_national, 'Not Available') as compared_to_national,

        -- decimal measures: SAFE_CAST returns NULL for 'Not Available' and 'Not Applicable'
        safe_cast(score as float64) as score,
        safe_cast(lower_estimate as float64) as lower_estimate,
        safe_cast(higher_estimate as float64) as higher_estimate,

        -- whole-number counts
        safe_cast(denominator as int64) as denominator,
        safe_cast(number_of_patients as int64) as patients,
        safe_cast(number_of_patients_returned as int64) as patients_returned,

        -- keep the footnote code, with empty text as NULL
        nullif(footnote, '') as footnote_code,

        -- measurement period (differs by measure)
        parse_date('%m/%d/%Y', start_date) as period_start_date,
        parse_date('%m/%d/%Y', end_date) as period_end_date

    from source
)

select * from cleaned
