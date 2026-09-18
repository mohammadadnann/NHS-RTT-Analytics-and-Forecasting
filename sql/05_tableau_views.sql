USE nhs_rtt_analytics;

SHOW FULL TABLES WHERE Table_type = 'VIEW';

USE nhs_rtt_analytics;
CREATE OR REPLACE VIEW vw_national_monthly_trend AS
SELECT
    f.period_date,
    SUM(f.patient_count) AS total_patients,
    SUM(CASE WHEN b.breach_flag = TRUE THEN f.patient_count ELSE 0 END) AS breaching_patients,
    ROUND(SUM(CASE WHEN b.breach_flag = TRUE THEN f.patient_count ELSE 0 END) * 100.0
          / SUM(f.patient_count), 2) AS breach_rate_pct
FROM fact_rtt_waiting_times f
JOIN dim_weeks_bands b ON f.band_id = b.band_id
GROUP BY f.period_date;

CREATE OR REPLACE VIEW vw_region_latest_month AS
SELECT
    r.region_name,
    SUM(f.patient_count) AS total_patients,
    SUM(CASE WHEN b.breach_flag = TRUE THEN f.patient_count ELSE 0 END) AS breaching_patients,
    ROUND(SUM(CASE WHEN b.breach_flag = TRUE THEN f.patient_count ELSE 0 END) * 100.0
          / SUM(f.patient_count), 2) AS breach_rate_pct
FROM fact_rtt_waiting_times f
JOIN dim_providers p ON f.provider_code = p.provider_code
JOIN dim_icb_region_map m ON p.provider_parent_code = m.icb_code
JOIN dim_regions r ON m.region_code = r.region_code
JOIN dim_weeks_bands b ON f.band_id = b.band_id
WHERE f.period_date = (SELECT MAX(period_date) FROM fact_rtt_waiting_times)
GROUP BY r.region_name;

CREATE OR REPLACE VIEW vw_specialty_latest_month AS
SELECT
    tf.treatment_function_name,
    SUM(f.patient_count) AS total_patients,
    SUM(CASE WHEN b.breach_flag = TRUE THEN f.patient_count ELSE 0 END) AS breaching_patients,
    ROUND(SUM(CASE WHEN b.breach_flag = TRUE THEN f.patient_count ELSE 0 END) * 100.0
          / SUM(f.patient_count), 2) AS breach_rate_pct
FROM fact_rtt_waiting_times f
JOIN dim_treatment_functions tf ON f.treatment_function_code = tf.treatment_function_code
JOIN dim_weeks_bands b ON f.band_id = b.band_id
WHERE f.period_date = (SELECT MAX(period_date) FROM fact_rtt_waiting_times)
GROUP BY tf.treatment_function_name;

CREATE OR REPLACE VIEW vw_provider_latest_month AS
SELECT
    p.provider_code,
    p.provider_name,
    r.region_name,
    SUM(f.patient_count) AS total_patients,
    SUM(CASE WHEN b.breach_flag = TRUE THEN f.patient_count ELSE 0 END) AS breaching_patients,
    ROUND(SUM(CASE WHEN b.breach_flag = TRUE THEN f.patient_count ELSE 0 END) * 100.0
          / SUM(f.patient_count), 2) AS breach_rate_pct
FROM fact_rtt_waiting_times f
JOIN dim_providers p ON f.provider_code = p.provider_code
LEFT JOIN dim_icb_region_map m ON p.provider_parent_code = m.icb_code
LEFT JOIN dim_regions r ON m.region_code = r.region_code
JOIN dim_weeks_bands b ON f.band_id = b.band_id
GROUP BY p.provider_code, p.provider_name, r.region_name
HAVING SUM(f.patient_count) >= 100;

CREATE OR REPLACE VIEW vw_provider_monthly_trend AS
SELECT
    p.provider_code,
    p.provider_name,
    f.period_date,
    SUM(f.patient_count) AS total_patients,
    ROUND(SUM(CASE WHEN b.breach_flag = TRUE THEN f.patient_count ELSE 0 END) * 100.0
          / SUM(f.patient_count), 2) AS breach_rate_pct
FROM fact_rtt_waiting_times f
JOIN dim_providers p ON f.provider_code = p.provider_code
JOIN dim_weeks_bands b ON f.band_id = b.band_id
GROUP BY p.provider_code, p.provider_name, f.period_date
HAVING SUM(f.patient_count) >= 100;