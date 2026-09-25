-- =============================================================================
-- 2. ANNUAL COUNTRY-LEVEL FOOD-SECURITY VIEW
--
-- Annual FAOSTAT FS periods are represented by a four-digit PERIOD_CODE,
-- e.g. 2010, 2011, ..., 2023.
--
-- Multi-year periods use a different period-code structure and are therefore
-- excluded from this annual analytical view.
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_FOOD_SECURITY_ANNUAL AS

SELECT
    geography_key,
    area_code_fao,
    area_code_m49,
    country_iso3,
    geography_name,
    area_type,

    indicator_key,
    indicator_code,
    indicator_name,

    element_key,
    element_code,
    element_name,

    period_key,
    period_code,
    period_label,

    TRY_TO_NUMBER(period_code) AS year,

    value,
    value_raw,
    unit,
    flag_code,
    note,

    source_row_hash,
    ingestion_run_id,
    ingestion_batch_id,
    extracted_at_utc,
    loaded_at_utc

FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_OBSERVATIONS

WHERE COALESCE(is_aggregate, FALSE) = FALSE

  -- Annual periods are represented by exactly four numeric digits.
  AND REGEXP_LIKE(period_code, '^[0-9]{4}$')

  -- Project V1 analytical boundary.
  AND TRY_TO_NUMBER(period_code) BETWEEN 2010 AND 2023
;


-- =============================================================================
-- 3. HEADLINE FOOD-SECURITY KPI VIEW
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_FOOD_SECURITY_HEADLINE AS

SELECT
    geography_key,
    area_code_fao,
    area_code_m49,
    country_iso3,
    geography_name,
    area_type,

    indicator_key,
    indicator_code,
    indicator_name,

    element_key,
    element_code,
    element_name,

    year,

    value,
    value_raw,
    unit,
    flag_code,
    note,

    CASE indicator_code
        WHEN '210040'
            THEN 'UNDERNOURISHMENT_PREVALENCE'

        WHEN '210090'
            THEN 'MODERATE_SEVERE_FOOD_INSECURITY_PREVALENCE'

        WHEN '210400'
            THEN 'SEVERE_FOOD_INSECURITY_PREVALENCE'

        WHEN '210010'
            THEN 'UNDERNOURISHED_PEOPLE_MILLION'
    END AS kpi_code,

    CASE indicator_code
        WHEN '210040'
            THEN 'Prevalence of undernourishment'

        WHEN '210090'
            THEN 'Moderate or severe food insecurity'

        WHEN '210400'
            THEN 'Severe food insecurity'

        WHEN '210010'
            THEN 'People undernourished'
    END AS kpi_name,

    source_row_hash,
    ingestion_run_id,
    ingestion_batch_id,
    extracted_at_utc,
    loaded_at_utc

FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_ANNUAL

WHERE indicator_code IN (
    '210040',
    '210090',
    '210400',
    '210010'
);