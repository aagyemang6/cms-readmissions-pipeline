# Hospital Readmissions Analytics Pipeline

**Status: in progress.** The raw data is loaded, and the staging layer and the fact and dimension tables are built and tested (26 tests). The analysis and the dashboard are next.

## The question

Which U.S. hospitals have worse-than-expected 30-day readmissions, and what do they have in common, such as ownership type, state, hospital type or overall star rating?

Medicare reduces payments to hospitals with excess readmissions by up to 3% under the Hospital Readmissions Reduction Program (HRRP), so the answer matters to hospital operations and finance leaders.

## Data

Three public files from the CMS Provider Data Catalog ([data.cms.gov/provider-data](https://data.cms.gov/provider-data)):

| File | Rows | One row is |
|---|---|---|
| Hospital General Information | 5,435 | one hospital |
| Hospital Readmissions Reduction Program (FY 2026) | 18,330 | one hospital for one condition |
| Unplanned Hospital Visits - Hospital | 67,018 | one hospital for one measure |

The readmissions data covers 3,055 hospitals and 6 conditions, measured from July 2021 to June 2024.

## How it works

```
CMS CSV files  ->  load_cms.py  ->  BigQuery (cms_raw)  ->  dbt staging  ->  dbt marts      ->  Tableau
                                    raw text copy           typed, tested    fact + dimension    (next)
```

1. **Load.** `load_cms.py` loads each file into BigQuery untouched, with every column as text. The script replaces the tables on each run, so it is safe to re-run.
2. **Stage.** One dbt model per raw table, at the same grain. Each renames columns, converts text to real types, and turns CMS text codes such as "N/A" and "Not Available" into NULL.
3. **Model.** Two tables in a star schema, joined on `facility_id`:
   - `fct_readmissions`: one row per hospital per condition (18,330 rows) with the readmission measures and the business rules, such as whether a hospital is worse than expected.
   - `dim_hospitals`: one row per hospital (5,472 rows) with location, ownership group and star rating.
4. **Analyze and visualize (next).** A Tableau Public dashboard.

## Data quality notes

- **About 36% of excess readmission ratios are missing (6,610 of 18,330).** This is by design: CMS publishes a ratio only when a hospital has at least 25 eligible discharges for that condition. These values are stored as NULL and excluded from averages, never treated as 0 or 1.
- **The results therefore describe hospitals with enough volume to measure,** not all U.S. hospitals.
- **37 hospitals in the readmissions file have no row in the hospital file,** most likely because they closed, merged or were renumbered after the 2021-2024 measurement period. 29 of them have published ratios, so dropping them would lose data. They are kept in `dim_hospitals` with their name and state, NULL for other attributes, and `is_in_hospital_directory = false`.
- **CMS's 10 ownership types are grouped into 4** (Non-profit, For-profit, Physician-owned, Government) so each group is large enough to compare.
- **Facility IDs and ZIP codes are kept as text,** because many start with a zero.

## Project structure

```
load_cms.py              loads the raw CSV files into BigQuery
dbt_project.yml          dbt project settings
profiles.yml             dbt connection settings (Google sign-in, no keys stored)
models/staging/          one cleaning model per raw table, plus tests
models/marts/            fact and dimension tables, plus tests
```

## Run it yourself

You need Python 3.10 to 3.14, a Google Cloud project with BigQuery, and the Google Cloud CLI signed in (`gcloud auth application-default login`).

```bash
python -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python load_cms.py cms_data        # after downloading the three CSV files into cms_data/
.venv/bin/dbt build --profiles-dir .
```

Change the project name in `load_cms.py`, `profiles.yml` and `models/staging/_sources.yml` to your own.

## Tools

BigQuery, dbt Core, Python, SQL, Tableau Public.
