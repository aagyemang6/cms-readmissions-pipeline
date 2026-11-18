# Dashboard plan

**Audience:** a hospital quality or operations leader.
**The one question it answers:** which hospitals have worse-than-expected readmissions, and what do they have in common?
**Tool:** Tableau Public. It cannot connect to BigQuery, so the dashboard reads the two CSV files in `data/`, made by `export_for_tableau.py`.

## Data sources

| File | Grain | Use it for |
|---|---|---|
| `data/hospitals.csv` | one row per hospital (3,055) | the KPI tiles, map, star rating chart and hospital list |
| `data/readmissions_by_condition.csv` | one row per hospital per condition (18,330) | the ownership by condition heatmap |

**Check these field types after connecting, before building anything:**

- `facility_id` must be a **String**. If Tableau reads it as a number, IDs such as 010001 lose their leading zero.
- `hospital_overall_rating` should be a **Number (whole)**, and dragged in as a **Dimension**, so it acts as five categories.
- `state` should get the **State/Province** geographic role, so Tableau can map it.
- `has_ratio`, `is_worse_than_expected`, `is_consistently_worse` should be **Boolean**.

## Layout (fixed size, 1200 x 900)

```
+-------------------------------------------------------------------+
| Title (the headline finding)                     subtitle / source |
+----------------+----------------+---------------------------------+
| KPI: hospitals | KPI: % ratios  | KPI: consistently worse          |
| measured       | worse          | hospitals                        |
+----------------+----------------+---------------------------------+
|  Map: average ratio by state      |  Bar: average ratio by stars   |
|                                   |                                |
+-----------------------------------+--------------------------------+
|  Heatmap: ownership x condition   |  Table: consistently worse     |
|                                   |  hospitals (scrolls)           |
+-----------------------------------+--------------------------------+
| Footnote: how to read the ratio, data period, limits, GitHub link  |
+-------------------------------------------------------------------+
```

## Sheets

**1. KPI tiles** (from `hospitals.csv`). Three big numbers:

- Hospitals in the program: `COUNT([facility_id])` = **3,055**
- Share of ratios worse than expected: from `readmissions_by_condition.csv`, `SUM(IF [is_worse_than_expected] THEN 1 ELSE 0 END) / SUM(IF [has_ratio] THEN 1 ELSE 0 END)` = **48.1%**
- Hospitals worse than expected on every condition measured: `SUM(IF [is_consistently_worse] THEN 1 ELSE 0 END)` = **221**

**2. Map: average ratio by state.** Filter `conditions_measured >= 3`. Color by `AVG([avg_excess_readmission_ratio])` with a **diverging** palette centered at **1.0** (blue below, orange above), so "worse than expected" reads instantly. Tooltip: state, number of hospitals, average ratio. Add a calculated field `COUNT([facility_id])` and hide states with fewer than 15 hospitals, as in the analysis.

**3. Bar: average ratio by star rating.** Filter `conditions_measured >= 3`. Rows: star rating (1 to 5, then "no rating"). Bars: `AVG([avg_excess_readmission_ratio])`. Add a **reference line at 1.0**, labelled "As expected". Start the axis near 0.9, not 0, and say so in the subtitle, because the differences are a few percent.

**4. Heatmap: ownership by condition** (from `readmissions_by_condition.csv`). Filter `has_ratio = True` and `ownership_group` not null. Columns: condition. Rows: ownership group. Color: `AVG([excess_readmission_ratio])`, same diverging palette as the map. Label each cell with the value to two decimals. The For-profit row should be orange in every column.

**5. Table: consistently worse hospitals.** Filter `is_consistently_worse = True` (221 rows). Columns: hospital, city, state, ownership, stars, conditions measured, average ratio, worst condition. Sort by average ratio, highest first.

## Interactivity

- **Click a state on the map** to filter the hospital table to that state (Dashboard > Actions > Filter).
- **Ownership filter** applied to the map, star chart and table.
- Keep it to these two. More filters make a dashboard harder to read, not easier.

## Text

- **Title:** a finding, not a topic. For example: "221 hospitals are worse than expected on every readmission measure. Low star ratings and for-profit ownership are the common threads."
- **Subtitle:** "30-day readmissions for 6 conditions, Medicare patients, July 2021 to June 2024. Source: CMS Hospital Readmissions Reduction Program."
- **Footnote:** "Excess readmission ratio = predicted / expected readmissions. Above 1.0 means more readmissions than expected for that hospital's patients. Hospitals with fewer than 25 cases for a condition have no ratio. Patterns shown are associations, not causes. Code and method: github.com/aagyemang6/cms-readmissions-pipeline"

## Check your numbers against the analysis

| Where | Expected |
|---|---|
| KPI tiles | 3,055 / 48.1% / 221 |
| Star rating bars (1 to 5) | 1.048, 1.024, 1.006, 0.986, 0.968 |
| Map, highest state | Massachusetts, 1.037 |
| Map, lowest state (15+ hospitals) | Utah, 0.958 |
| Heatmap, For-profit row | highest in every condition |
| Table | 221 rows |

If a number doesn't match, the usual cause is a missing `conditions_measured >= 3` filter, or Tableau summing where it should average.

## Publishing

1. Save the workbook as `dashboard/cms_readmissions_dashboard.twbx` in this project.
2. File > Save to Tableau Public. Sign in or create a free Tableau Public account.
3. Copy the published URL for the README and resume.
