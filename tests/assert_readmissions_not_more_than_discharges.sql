-- A hospital cannot readmit more patients than it discharged.
-- Returns the rows that break the rule; dbt fails the test if any come back.
-- It also fails if readmissions or discharges is ever not a number, as happened once when a
-- column name clashed with a CTE name and BigQuery returned the whole row instead.
select readmission_id, discharges, readmissions
from {{ ref('fct_readmissions') }}
where readmissions > discharges
