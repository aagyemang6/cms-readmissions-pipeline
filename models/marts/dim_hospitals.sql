-- Dimension: one row per hospital.
-- Describes each hospital (where it is, who owns it, its star rating) so facts can be grouped by these attributes.
--
-- Includes every hospital in the CMS hospital directory, plus 37 hospitals that appear in the
-- readmissions data but not in the directory (most likely closed, merged or renumbered since the
-- 2021-2024 measurement period). Those 37 get their name and state from the readmissions data and
-- NULL for everything else, so no readmission rows are lost when facts are joined to this table.

with directory_hospitals as (

    select * from {{ ref('stg_hospitals') }}

),

readmission_hospitals as (

    -- one row per hospital in the readmissions program
    select
        facility_id,
        any_value(facility_name) as facility_name,
        any_value(state) as state
    from {{ ref('stg_hrrp_readmissions') }}
    group by facility_id

),

missing_from_directory as (

    select readmission_hospitals.*
    from readmission_hospitals
    left join directory_hospitals using (facility_id)
    where directory_hospitals.facility_id is null

),

combined as (

    select
        facility_id,
        facility_name,
        city,
        county,
        state,
        zip_code,
        hospital_type,
        hospital_ownership,
        has_emergency_services,
        hospital_overall_rating,
        true as is_in_hospital_directory
    from directory_hospitals

    union all

    select
        facility_id,
        facility_name,
        null as city,
        null as county,
        state,
        null as zip_code,
        null as hospital_type,
        null as hospital_ownership,
        null as has_emergency_services,
        null as hospital_overall_rating,
        false as is_in_hospital_directory
    from missing_from_directory

),

final as (

    select
        combined.*,

        -- 10 CMS ownership types grouped into 4 that are large enough to compare
        case
            when hospital_ownership like 'Voluntary non-profit%' then 'Non-profit'
            when hospital_ownership = 'Proprietary' then 'For-profit'
            when hospital_ownership = 'Physician' then 'Physician-owned'
            when hospital_ownership like 'Government%' or hospital_ownership = 'Tribal' then 'Government'
        end as ownership_group,

        facility_id in (select facility_id from readmission_hospitals) as is_in_readmissions_program

    from combined

)

select * from final
