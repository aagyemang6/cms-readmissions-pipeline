"""Load the raw CMS CSV files into BigQuery, untouched, with every column as STRING.

Cleaning and typing happen later in dbt (the "T" in ELT).
Usage: python load_cms.py <folder containing the CSVs>
"""
import csv
import re
import sys
from pathlib import Path

import pydata_google_auth
from google.cloud import bigquery

PROJECT = "cms-readmissions"
DATASET = "cms_raw"

# CSV file name -> BigQuery table name
FILES = {
    "Hospital_General_Information_2.csv": "hospital_general_information",
    "FY_2026_Hospital_Readmissions_Reduction_Program_Hospital.csv": "hrrp_readmissions",
    "Unplanned_Hospital_Visits-Hospital.csv": "unplanned_hospital_visits",
}


def snake_case(header: str) -> str:
    """'Facility ID' -> 'facility_id' (BigQuery column names can't contain spaces)."""
    name = re.sub(r"[^0-9a-zA-Z]+", "_", header.strip()).strip("_").lower()
    return f"_{name}" if name[0].isdigit() else name


def main(data_dir: Path) -> None:
    # Opens a browser window once so you can sign in to Google and allow access.
    credentials = pydata_google_auth.get_user_credentials(
        ["https://www.googleapis.com/auth/bigquery"]
    )
    client = bigquery.Client(project=PROJECT, credentials=credentials)

    for file_name, table_name in FILES.items():
        path = data_dir / file_name
        with path.open(newline="", encoding="utf-8-sig") as f:
            headers = next(csv.reader(f))
        schema = [bigquery.SchemaField(snake_case(h), "STRING") for h in headers]

        job_config = bigquery.LoadJobConfig(
            schema=schema,
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            allow_quoted_newlines=True,
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,  # safe to re-run
        )
        table_id = f"{PROJECT}.{DATASET}.{table_name}"
        with path.open("rb") as f:
            client.load_table_from_file(f, table_id, job_config=job_config).result()
        table = client.get_table(table_id)
        print(f"{table_id}: {table.num_rows} rows, {len(table.schema)} columns")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
