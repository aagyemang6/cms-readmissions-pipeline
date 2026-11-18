"""Export the dashboard tables from BigQuery to CSV files for Tableau Public.

Tableau Public cannot connect to BigQuery directly, so the dashboard reads these files.
Run after `dbt build`, from the project folder:

    .venv/bin/python export_for_tableau.py

Uses the same Google sign-in as dbt (application default credentials).
"""
import csv
from pathlib import Path

import google.auth
from google.cloud import bigquery

PROJECT = "cms-readmissions"
OUT_DIR = Path(__file__).parent / "dashboard" / "data"

EXPORTS = {
    # one row per hospital in the program
    "hospitals.csv": """
        select *
        from `cms-readmissions.analytics.agg_hospital_readmissions`
        order by facility_id
    """,
    # one row per hospital per condition, with the hospital attributes attached
    "readmissions_by_condition.csv": """
        select
            f.readmission_id,
            f.facility_id,
            d.facility_name,
            d.state,
            d.ownership_group,
            d.hospital_overall_rating,
            f.condition,
            f.discharges,
            f.readmissions,
            f.predicted_readmission_rate,
            f.expected_readmission_rate,
            f.excess_readmission_ratio,
            f.has_ratio,
            f.is_worse_than_expected,
            f.pct_vs_expected
        from `cms-readmissions.analytics.fct_readmissions` f
        join `cms-readmissions.analytics.dim_hospitals` d using (facility_id)
        order by f.facility_id, f.condition
    """,
}


def main() -> None:
    credentials, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/bigquery"])
    client = bigquery.Client(project=PROJECT, credentials=credentials)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for file_name, sql in EXPORTS.items():
        rows = client.query(sql).result()
        columns = [field.name for field in rows.schema]
        path = OUT_DIR / file_name
        count = 0
        with path.open("w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(columns)
            for row in rows:
                writer.writerow(["" if row[c] is None else row[c] for c in columns])
                count += 1
        print(f"{path.relative_to(Path(__file__).parent)}: {count} rows, {len(columns)} columns")


if __name__ == "__main__":
    main()
