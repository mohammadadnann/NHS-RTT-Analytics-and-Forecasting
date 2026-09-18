# NHS RTT Breach Risk and Forecasting

An end to end data pipeline and machine learning project on NHS England Referral to Treatment (RTT) waiting times data, built to identify which NHS trusts are likely to breach the 18 week treatment standard before that shows up in the next month's published national statistics.

## Business question

Which trusts and specialties are at highest risk of breaching the 18 week and 52 week RTT standards, and what is driving it?

Public NHS reporting tells what already happened. This project goes a step further, it flags risk ahead of time using only data a real analyst would actually have at the time, and it quantifies exactly where the pressure is concentrated, by region, by specialty, and by provider.

## Dashboard

<img width="1102" height="652" alt="Power bi" src="https://github.com/user-attachments/assets/472142e8-20f6-4b76-a995-f387902df1e0" />


The dashboard covers the national trend, breach rate by specialty and by NHS region, a provider level drill down table, and the national rate measured against the real NHS constitutional standard.

## Key findings

- The national breach rate rose from 39.34% in November 2025 to a peak of 39.76% in January 2026, then fell for three consecutive months to 36.79% by April 2026, a genuine sustained trend, not month to month noise.
- A 7.5 percentage point gap exists between the best and worst performing NHS region, the east of England at 40.91% versus North East and Yorkshire at 33.36%.
- Specialty matters far more than region. Oral Surgery breaches at close to 48%, against Elderly Medicine at around 17%, close to a 3x difference.
- Provider size only weakly correlates with breach rate (r = 0.35), so patient volume alone is not a strong predictor of performance.
- A time split logistic regression classifier, trained on data strictly before the month it predicts, achieves 94.9% accuracy, 93.9% precision, and 97.0% recall identifying which providers will underperform the national average, tested on a fully held out future month.

## Data

NHS England, Referral to Treatment (RTT) Waiting Times statistics, Incomplete Pathways, full extract files:
https://www.england.nhs.uk/statistics/statistical-work-areas/rtt-waiting-times/

Six consecutive months, November 2025 through April 2026, roughly 6.6 million fact rows across 538 providers.

Region data comes from the ONS ICB to NHS England Region lookup (April 2026, post ICB merger structure):
https://geoportal.statistics.gov.uk

## Architecture

Raw monthly CSVs are uploaded to Azure Blob Storage. A config driven Python ETL pipeline reads them directly from Blob Storage, cleans and reshapes them, and loads them into a star schema hosted on Azure Database for MySQL. Power BI connects to that data for the dashboard. All database credentials and cloud connection details are read from a gitignored .env file, and non secret settings live in config.yaml, so the pipeline runs on any machine without editing code.


## Star schema

One fact table, fact_rtt_waiting_times, at the grain of provider, commissioner, specialty, RTT part type, wait band, and month. Six dimension tables: providers, commissioners, treatment functions, week bands, regions, and an ICB to region mapping.

## Data quality

I checked every load thoroughly against known issues. Full details in reports/data_quality_notes.md, including a real double counting bug found in the raw NHS files (C_999 rollup rows), a second double counting issue found once multiple months were loaded together, and a slowly changing dimension issue found during the Azure migration where a provider's parent ICB code was only ever captured once and never updated, even after NHS England's April 2026 ICB mergers changed the real structure.

## Machine learning

A monthly panel of provider level breach rates is engineered into a small set of features, using only data from strictly prior months, so the model never sees information it would not actually have at prediction time. Trained on December 2025 through March 2026, tested on April 2026 as a genuinely unseen holdout month.

I choase Logistic regression deliberately over a tree based model, as the task needed a real, calibrated risk probability rather than a bare label, the strongest feature has a smooth, monotonic relationship with the outcome that a linear decision boundary in log odds captures directly, and the coefficients convert into odds ratios that are directly explainable to a non technical stakeholder, without needing a separate explainability layer on top.
