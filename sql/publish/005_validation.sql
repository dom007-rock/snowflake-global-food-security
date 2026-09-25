-- =============================================================================
-- Global Food Security & Nutrition Intelligence Platform
-- Phase 15 - PUBLISH Layer Validation
--
-- File:
--   sql/publish/005_validation.sql
--
-- Purpose:
--   Validate the analytical contracts of the Phase 15 PUBLISH layer before
--   exposing the data through Streamlit.
--
-- Expected:
--   Duplicate / invalid-row checks should return 0 rows.
-- =============================================================================


USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE WAREHOUSE GFS_ANALYTICS_WH;


-- =============================================================================
-- 1. INVENTORY / BASIC SANITY
-- =============================================================================

SELECT 'V_FOOD_SECURITY_OBSERVATIONS' AS object_name, COUNT(*) AS row_count
FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_OBSERVATIONS

UNION ALL

SELECT 'V_FOOD_SECURITY_ANNUAL', COUNT(*)
FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_ANNUAL

UNION ALL

SELECT 'V_FOOD_SECURITY_HEADLINE', COUNT(*)
FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_HEADLINE

UNION ALL

SELECT 'V_WDI_OBSERVATIONS', COUNT(*)
FROM GFS_DEV.PUBLISH.V_WDI_OBSERVATIONS

UNION ALL

SELECT 'V_WDI_COUNTRY_YEAR', COUNT(*)
FROM GFS_DEV.PUBLISH.V_WDI_COUNTRY_YEAR

UNION ALL

SELECT 'V_CROPS_LIVESTOCK', COUNT(*)
FROM GFS_DEV.PUBLISH.V_CROPS_LIVESTOCK

UNION ALL

SELECT 'V_FOOD_BALANCE', COUNT(*)
FROM GFS_DEV.PUBLISH.V_FOOD_BALANCE

UNION ALL

SELECT 'V_LAND_COVER', COUNT(*)
FROM GFS_DEV.PUBLISH.V_LAND_COVER

UNION ALL

SELECT 'V_NUTRIENT_BALANCE', COUNT(*)
FROM GFS_DEV.PUBLISH.V_NUTRIENT_BALANCE

UNION ALL

SELECT 'V_EMISSIONS', COUNT(*)
FROM GFS_DEV.PUBLISH.V_EMISSIONS

UNION ALL

SELECT 'V_FOOD_SECURITY_COUNTRY_YEAR', COUNT(*)
FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_COUNTRY_YEAR

UNION ALL

SELECT 'V_COUNTRY_YEAR_INTELLIGENCE', COUNT(*)
FROM GFS_DEV.PUBLISH.V_COUNTRY_YEAR_INTELLIGENCE

UNION ALL

SELECT 'V_FOOD_SECURITY_AGGREGATE_ANNUAL', COUNT(*)
FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_AGGREGATE_ANNUAL
;


-- =============================================================================
-- 2. V1 YEAR BOUNDARY
--
-- Expected:
--   Every dataset below should report 2010-2023.
-- =============================================================================

SELECT
    'FOOD_SECURITY_ANNUAL' AS dataset,
    MIN(year) AS min_year,
    MAX(year) AS max_year
FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_ANNUAL

UNION ALL

SELECT
    'WDI',
    MIN(year),
    MAX(year)
FROM GFS_DEV.PUBLISH.V_WDI_OBSERVATIONS

UNION ALL

SELECT
    'CROPS_LIVESTOCK',
    MIN(year),
    MAX(year)
FROM GFS_DEV.PUBLISH.V_CROPS_LIVESTOCK

UNION ALL

SELECT
    'FOOD_BALANCE',
    MIN(year),
    MAX(year)
FROM GFS_DEV.PUBLISH.V_FOOD_BALANCE

UNION ALL

SELECT
    'LAND_COVER',
    MIN(year),
    MAX(year)
FROM GFS_DEV.PUBLISH.V_LAND_COVER

UNION ALL

SELECT
    'NUTRIENT_BALANCE',
    MIN(year),
    MAX(year)
FROM GFS_DEV.PUBLISH.V_NUTRIENT_BALANCE

UNION ALL

SELECT
    'EMISSIONS',
    MIN(year),
    MAX(year)
FROM GFS_DEV.PUBLISH.V_EMISSIONS

UNION ALL

SELECT
    'COUNTRY_YEAR_INTELLIGENCE',
    MIN(year),
    MAX(year)
FROM GFS_DEV.PUBLISH.V_COUNTRY_YEAR_INTELLIGENCE
;


-- =============================================================================
-- 3. WDI COUNTRY-YEAR GRAIN
--
-- Expected:
--   0 rows
-- =============================================================================

SELECT
    country_iso3,
    year,
    COUNT(*) AS row_count
FROM GFS_DEV.PUBLISH.V_WDI_COUNTRY_YEAR
GROUP BY
    country_iso3,
    year
HAVING COUNT(*) > 1
;


-- =============================================================================
-- 4. FOOD-SECURITY COUNTRY-YEAR GRAIN
--
-- Expected:
--   0 rows
-- =============================================================================

SELECT
    country_iso3,
    year,
    COUNT(*) AS row_count
FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_COUNTRY_YEAR
GROUP BY
    country_iso3,
    year
HAVING COUNT(*) > 1
;


-- =============================================================================
-- 5. INTEGRATED COUNTRY-YEAR GRAIN
--
-- Expected:
--   0 rows
-- =============================================================================

SELECT
    country_iso3,
    year,
    COUNT(*) AS row_count
FROM GFS_DEV.PUBLISH.V_COUNTRY_YEAR_INTELLIGENCE
GROUP BY
    country_iso3,
    year
HAVING COUNT(*) > 1
;


-- =============================================================================
-- 6. HEADLINE FOOD-SECURITY GRAIN
--
-- Expected:
--   0 rows
--
-- This is particularly important because V_FOOD_SECURITY_COUNTRY_YEAR uses
-- conditional MAX() to pivot these records.
-- =============================================================================

SELECT
    country_iso3,
    year,
    indicator_code,
    COUNT(*) AS row_count
FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_HEADLINE
GROUP BY
    country_iso3,
    year,
    indicator_code
HAVING COUNT(*) > 1
;


-- =============================================================================
-- 7. COUNTRY IDENTITY VALIDATION
--
-- Expected:
--   0 rows
-- =============================================================================

SELECT *
FROM GFS_DEV.PUBLISH.V_COUNTRY_YEAR_INTELLIGENCE
WHERE country_iso3 IS NULL
;


-- =============================================================================
-- 8. HEADLINE KPI COVERAGE
--
-- Confirms which curated indicators are available and their country/year
-- coverage.
-- =============================================================================

SELECT
    indicator_code,
    kpi_code,
    kpi_name,
    COUNT(*) AS observations,
    COUNT(DISTINCT country_iso3) AS countries,
    MIN(year) AS min_year,
    MAX(year) AS max_year,
    COUNT_IF(value IS NULL) AS null_values
FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_HEADLINE
GROUP BY
    indicator_code,
    kpi_code,
    kpi_name
ORDER BY
    indicator_code
;


-- =============================================================================
-- 9. KPI PIVOT RECONCILIATION
--
-- Because headline grain has already been proven unique, the number of
-- non-null values in the wide country-year view should equal the number of
-- non-null observations in the corresponding headline indicator.
-- =============================================================================

WITH source_counts AS (

    SELECT
        indicator_code,
        COUNT_IF(value IS NOT NULL) AS source_non_null_rows
    FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_HEADLINE
    GROUP BY indicator_code

),

pivot_counts AS (

    SELECT
        '21059' AS indicator_code,
        COUNT_IF(caloric_loss_retail_pct IS NOT NULL) AS pivot_non_null_rows
    FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_COUNTRY_YEAR

    UNION ALL

    SELECT
        '21047',
        COUNT_IF(basic_drinking_water_pct IS NOT NULL)
    FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_COUNTRY_YEAR

    UNION ALL

    SELECT
        '21048',
        COUNT_IF(basic_sanitation_pct IS NOT NULL)
    FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_COUNTRY_YEAR

    UNION ALL

    SELECT
        '21043',
        COUNT_IF(anemia_women_pct IS NOT NULL)
    FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_COUNTRY_YEAR

    UNION ALL

    SELECT
        '21025',
        COUNT_IF(child_stunting_pct IS NOT NULL)
    FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_COUNTRY_YEAR

    UNION ALL

    SELECT
        '21042',
        COUNT_IF(adult_obesity_pct IS NOT NULL)
    FROM GFS_DEV.PUBLISH.V_FOOD_SECURITY_COUNTRY_YEAR

)

SELECT
    s.indicator_code,
    s.source_non_null_rows,
    p.pivot_non_null_rows,
    s.source_non_null_rows - p.pivot_non_null_rows AS difference
FROM source_counts s

INNER JOIN pivot_counts p
    ON s.indicator_code = p.indicator_code

ORDER BY s.indicator_code
;