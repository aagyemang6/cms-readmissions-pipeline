# Findings

**Question:** which U.S. hospitals have worse-than-expected 30-day readmissions, and what do they have in common?

**Data:** CMS Hospital Readmissions Reduction Program, FY 2026 (discharges from July 2021 to June 2024). 3,055 hospitals, 6 conditions, 11,720 published excess readmission ratios. A ratio above 1.0 means more readmissions than CMS expected for that hospital's patients.

**Method:** the SQL for every number below is in this folder (`a1` to `a5`). Hospital-level comparisons use one value per hospital, the average of its condition ratios, and include only the 2,392 hospitals measured on at least 3 conditions. Ranges are 95% confidence intervals for the group average.

## Summary

1. **Star rating is the strongest signal.** One-star hospitals average 4.8% more readmissions than expected; five-star hospitals 3.2% fewer. 32% of one-star hospitals are worse than expected on every condition they are measured on, against 2% of five-star hospitals.
2. **For-profit hospitals are worse than expected more often, on every one of the six conditions.** Their average ratio is 1.016 (1.012 to 1.021), against 0.999 for non-profits (0.997 to 1.001). The ranges do not overlap, so this is unlikely to be chance, but the gap is small: about 1.7% more readmissions than expected.
3. **Geography matters.** Massachusetts, New Jersey, Florida and Illinois have the highest averages; Utah, Oregon, Washington, Colorado and the Upper Midwest the lowest.
4. **221 hospitals (9%) are worse than expected on every condition measured.** They average 2.35 stars, against 3.26 for the rest, and 25% of them are for-profit, against 17% of the rest.

## 1. Star rating

| Star rating | Hospitals | Average ratio | 95% range | Worse on every condition |
|---|---|---|---|---|
| 1 | 139 | 1.048 | 1.040 to 1.056 | 31.7% |
| 2 | 523 | 1.024 | 1.021 to 1.028 | 16.8% |
| 3 | 756 | 1.006 | 1.003 to 1.009 | 8.1% |
| 4 | 690 | 0.986 | 0.983 to 0.989 | 3.0% |
| 5 | 261 | 0.968 | 0.963 to 0.973 | 2.3% |

Each step up in stars lowers the average ratio, with no overlap between neighbouring groups.

**Caveat:** readmissions are one of the measure groups that feed the star rating, so part of this link is built in. The useful point is how large the gap is, and that star rating is a quick, public flag for readmission risk.

## 2. Ownership

**Within each condition** (`a1`), for-profit hospitals have the highest average ratio for every one of the six conditions. Comparing within each condition rules out the explanation that for-profit hospitals simply treat a different mix of conditions.

**At hospital level** (`a2`):

| Ownership | Hospitals | Average ratio | 95% range | Worse on every condition |
|---|---|---|---|---|
| For-profit | 424 | 1.016 | 1.012 to 1.021 | 13.0% |
| Government | 296 | 1.002 | 0.997 to 1.006 | 9.1% |
| Physician-owned | 11 | 1.000 | 0.976 to 1.025 | 9.1% |
| Non-profit | 1,646 | 0.999 | 0.997 to 1.001 | 8.3% |

**Physician-owned hospitals** look best in the raw numbers, driven by hip and knee replacement (average 0.911 across 47 hospitals). Most are small surgical hospitals, so only 11 have enough conditions for the hospital-level view, and their range is too wide to rank them.

## 3. States

States with at least 15 qualifying hospitals (`a4`):

- **Highest:** Massachusetts 1.037, New Jersey 1.027, Florida 1.022, Illinois 1.018.
- **Lowest:** Utah 0.958, Oregon 0.961, Washington 0.964, Colorado 0.970, Kansas 0.973, Iowa 0.974.
- In Massachusetts and New Jersey, about 1 in 4 hospitals is worse than expected on every condition. In Washington, Oregon, Utah, Iowa, Kansas and Wisconsin, none are.

State differences may reflect things the ratio does not adjust for, such as local health systems, follow-up care after discharge, and patients' social circumstances. Ownership mix also differs by state. These results show where to look, not why.

## 4. Consistently worse hospitals

Of 2,392 hospitals measured on at least 3 conditions, **221 (9.2%) are worse than expected on every one.** Compared with the rest, they have lower star ratings (2.35 against 3.26) and are more often for-profit (25% against 17%). They are listed in the `agg_hospital_readmissions` table (`is_consistently_worse = true`) and on the dashboard.

## Limits

- **Association, not cause.** None of this shows that ownership or location causes readmissions.
- **The ratio adjusts for patients' age and health, not for everything.** Differences in income, housing or support at home are only partly reflected.
- **A ratio above 1.0 is not the same as a penalty.** CMS calculates penalties by comparing hospitals within peer groups, so this analysis does not say which hospitals were penalized.
- **Small hospitals are excluded.** CMS does not publish ratios below 25 cases, so results describe hospitals with enough volume to measure.
- **One period.** July 2021 to June 2024, which includes part of the COVID-19 pandemic.
- **The hospital-level average treats each condition equally,** whatever its volume.
- **Confidence intervals use a normal approximation** and treat hospitals as independent.

## What I would recommend

For a hospital operations or quality team, three practical uses:

1. **Prioritize** follow-up programs at hospitals worse than expected on every condition. 221 hospitals is a manageable list.
2. **Use star rating as an early-warning screen** when no readmission data is at hand, such as for a newly acquired hospital.
3. **Investigate the for-profit gap and the Northeast cluster** with data this analysis lacks: discharge planning practices, follow-up appointment rates and patients' social risk.
