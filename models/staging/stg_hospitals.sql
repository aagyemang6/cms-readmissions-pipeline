-- Staging model: one row per hospital (same grain as the raw table).
-- Job: pick the columns we need, rename them, and convert text to real types.
-- No joins, no filtering, no business logic here.

with source as (

    select * from {{ source('cms_raw', 'hospital_general_information') }}

),

cleaned as (

    select
        -- key: stays text, because IDs like '010001' would lose their leading zero as a number
        facility_id,

        -- descriptions
        facility_name,
        city_town as city,
        county_parish as county,
        state,
        zip_code,  -- text for the same reason as facility_id

        -- attributes we will group hospitals by
        hospital_type,
        hospital_ownership,
        emergency_services = 'Yes' as has_emergency_services,

        -- star rating: '1' to '5' become numbers, 'Not Available' becomes NULL
        safe_cast(hospital_overall_rating as int64) as hospital_overall_rating

    from source

)

select * from cleaned
