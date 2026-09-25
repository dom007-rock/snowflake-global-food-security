-- =============================================================================
-- Global Food Security & Nutrition Intelligence Platform
-- Phase 15 - Integrated Analytical Layer
--
-- File:
--   sql/publish/004_integrated_kpi_views.sql
--
-- Purpose:
--   Create integrated country-year analytical views combining:
--
--     FAOSTAT food-security / nutrition indicators
--     World Bank socioeconomic indicators
--
-- Important:
--   These views expose indicators together for comparative analysis.
--   They do NOT imply causal relationships between socioeconomic variables
--   and food-security outcomes.
--
-- V1 analytical period:
--   2010-2023
-- =============================================================================


USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE WAREHOUSE GFS_ANALYTICS_WH;


-- =============================================================================
-- 1. FOOD-SECURITY COUNTRY-YEAR KPI VIEW
--
-- Grain:
--   country × year
--
-- Converts the curated headline food-security indicators from long format
-- into dashboard-friendly columns.
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_FOOD_SECURITY_COUNTRY_YEAR AS

SELECT
    geography_key,
    area_code_fao,
    area_code_m49,
    country_iso3,
    geography_name,
    year,

    -- -------------------------------------------------------------------------
    -- Food-system efficiency
    -- -------------------------------------------------------------------------
    MAX(
        CASE
            WHEN indicator_code = '21059'
            THEN value
        END
    ) AS caloric_loss_retail_pct,

    -- -------------------------------------------------------------------------
    -- Basic services
    -- -------------------------------------------------------------------------
    MAX(
        CASE
            WHEN indicator_code = '21047'
            THEN value
        END
    ) AS basic_drinking_water_pct,

    MAX(
        CASE
            WHEN indicator_code = '21048'
            THEN value
        END
    ) AS basic_sanitation_pct,

    -- -------------------------------------------------------------------------
    -- Nutrition outcomes
    -- -------------------------------------------------------------------------
    MAX(
        CASE
            WHEN indicator_code = '21043'
            THEN value
        END
    ) AS anemia_women_pct,

    MAX(
        CASE
            WHEN indicator_code = '21025'
            THEN value
        END
    ) AS child_stunting_pct,

    MAX(
        CASE
            WHEN indicator_code = '21042'
            THEN value
        END
    ) AS adult_obesity_pct,

    -- -------------------------------------------------------------------------
    -- Coverage indicator
    --
    -- Number of curated food-security KPIs with a non-null value for the
    -- country/year combination.
    -- -------------------------------------------------------------------------
    COUNT(
        DISTINCT CASE
            WHEN value IS NOT NULL
            THEN indicator_code
        END
    ) AS available_food_security_kpis

FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_HEADLINE

GROUP BY
    geography_key,
    area_code_fao,
    area_code_m49,
    country_iso3,
    geography_name,
    year
;


-- =============================================================================
-- 2. INTEGRATED COUNTRY-YEAR INTELLIGENCE VIEW
--
-- Grain:
--   country × year
--
-- Combines:
--   - FAOSTAT food-security / nutrition KPIs
--   - World Bank socioeconomic context
--
-- FULL OUTER JOIN is intentional.
--
-- A country-year is retained even when only one source contains observations.
-- This prevents the analytical layer from silently discarding valid records
-- because the other source has missing data.
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_COUNTRY_YEAR_INTELLIGENCE AS

SELECT
    COALESCE(w.geography_key, f.geography_key)
        AS geography_key,

    COALESCE(w.area_code_fao, f.area_code_fao)
        AS area_code_fao,

    COALESCE(w.area_code_m49, f.area_code_m49)
        AS area_code_m49,

    COALESCE(w.country_iso3, f.country_iso3)
        AS country_iso3,

    COALESCE(w.geography_name, f.geography_name)
        AS geography_name,

    w.world_bank_name,

    COALESCE(w.year, f.year)
        AS year,

    -- -------------------------------------------------------------------------
    -- World Bank socioeconomic context
    -- -------------------------------------------------------------------------
    w.population_total,
    w.gdp_current_usd,
    w.gdp_per_capita_current_usd,
    w.rural_population_pct,
    w.agriculture_value_added_pct_gdp,

    -- -------------------------------------------------------------------------
    -- FAOSTAT food-security / nutrition KPIs
    -- -------------------------------------------------------------------------
    f.caloric_loss_retail_pct,
    f.basic_drinking_water_pct,
    f.basic_sanitation_pct,
    f.anemia_women_pct,
    f.child_stunting_pct,
    f.adult_obesity_pct,

    COALESCE(
        f.available_food_security_kpis,
        0
    ) AS available_food_security_kpis,

    -- -------------------------------------------------------------------------
    -- Source availability flags
    --
    -- Useful for the dashboard and for data-quality interpretation.
    -- -------------------------------------------------------------------------
    CASE
        WHEN w.geography_key IS NOT NULL
        THEN TRUE
        ELSE FALSE
    END AS has_wdi_data,

    CASE
        WHEN f.geography_key IS NOT NULL
        THEN TRUE
        ELSE FALSE
    END AS has_food_security_data

FROM GFS_DEV.PUBLISH.V_WDI_COUNTRY_YEAR w

FULL OUTER JOIN GFS_DEV.PUBLISH.V_FOOD_SECURITY_COUNTRY_YEAR f
    ON w.geography_key = f.geography_key
   AND w.year = f.year
;


-- =============================================================================
-- 3. FAOSTAT AGGREGATE FOOD-SECURITY VIEW
--
-- Purpose:
--   Support regional / global exploration using observations already
--   published by FAOSTAT.
--
-- Important:
--   We do NOT calculate regional percentages by averaging country percentages.
--   We expose source-published aggregate observations instead.
--
-- Examples may include:
--   World
--   Africa
--   Asia
--   Eastern Africa
--   South America
--   Sub-Saharan Africa
--   etc.
--
-- Grain:
--   aggregate geography × indicator × element × year
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_FOOD_SECURITY_AGGREGATE_ANNUAL AS

SELECT
    geography_key,
    area_code_fao,
    area_code_m49,
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

    period_start_year AS year,

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

WHERE is_aggregate = TRUE
  AND period_type = 'ANNUAL'
  AND period_start_year BETWEEN 2010 AND 2023
;