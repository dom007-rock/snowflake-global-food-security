USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


-- =============================================================================
-- PHASE 11 - MANDATORY FIELD TESTS
--
-- Assumption:
--   $DQ_RUN_ID has already been created for the current DQ run.
--
-- Categories:
--   1. Dimension mandatory fields
--   2. Fact mandatory fields
--
-- Severity:
--   ERROR
--
-- Expected result:
--   failure_count = 0
-- =============================================================================



-- =============================================================================
-- 1. DIMENSION MANDATORY FIELD TESTS
-- =============================================================================

INSERT INTO CONTROL.DQ_RESULTS (

    dq_run_id,
    test_name,
    test_category,
    target_object,
    target_column,
    severity,
    expected_value,
    observed_value,
    test_status,
    failure_count,
    test_message,
    executed_at_utc

)

WITH tests AS (

    -- -------------------------------------------------------------------------
    -- DIM_GEOGRAPHY
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_GEOGRAPHY_REQUIRED_FIELDS' AS test_name,
        'CONSUMPTION.DIM_GEOGRAPHY' AS target_object,
        'geography_key,area_code_fao,geography_name' AS target_column,

        COUNT_IF(
            geography_key IS NULL
            OR area_code_fao IS NULL
            OR geography_name IS NULL
        ) AS failure_count

    FROM CONSUMPTION.DIM_GEOGRAPHY


    UNION ALL


    -- -------------------------------------------------------------------------
    -- DIM_DATE
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_DATE_REQUIRED_FIELDS',
        'CONSUMPTION.DIM_DATE',
        'date_key,year',

        COUNT_IF(
            date_key IS NULL
            OR year IS NULL
        )

    FROM CONSUMPTION.DIM_DATE


    UNION ALL


    -- -------------------------------------------------------------------------
    -- DIM_PERIOD
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_PERIOD_REQUIRED_FIELDS',
        'CONSUMPTION.DIM_PERIOD',
        'period_key,period_code,period_start_year,period_end_year,period_type',

        COUNT_IF(
            period_key IS NULL
            OR period_code IS NULL
            OR period_start_year IS NULL
            OR period_end_year IS NULL
            OR period_type IS NULL
        )

    FROM CONSUMPTION.DIM_PERIOD


    UNION ALL


    -- -------------------------------------------------------------------------
    -- DIM_ITEM
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_ITEM_REQUIRED_FIELDS',
        'CONSUMPTION.DIM_ITEM',
        'item_key,source_domain,item_code,item_name',

        COUNT_IF(
            item_key IS NULL
            OR source_domain IS NULL
            OR item_code IS NULL
            OR item_name IS NULL
        )

    FROM CONSUMPTION.DIM_ITEM


    UNION ALL


    -- -------------------------------------------------------------------------
    -- DIM_ELEMENT
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_ELEMENT_REQUIRED_FIELDS',
        'CONSUMPTION.DIM_ELEMENT',
        'element_key,source_domain,element_code,element_name',

        COUNT_IF(
            element_key IS NULL
            OR source_domain IS NULL
            OR element_code IS NULL
            OR element_name IS NULL
        )

    FROM CONSUMPTION.DIM_ELEMENT


    UNION ALL


    -- -------------------------------------------------------------------------
    -- DIM_INDICATOR
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_INDICATOR_REQUIRED_FIELDS',
        'CONSUMPTION.DIM_INDICATOR',
        'indicator_key,source_system,source_domain,indicator_code,indicator_name',

        COUNT_IF(
            indicator_key IS NULL
            OR source_system IS NULL
            OR source_domain IS NULL
            OR indicator_code IS NULL
            OR indicator_name IS NULL
        )

    FROM CONSUMPTION.DIM_INDICATOR


    UNION ALL


    -- -------------------------------------------------------------------------
    -- DIM_SOURCE
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_SOURCE_REQUIRED_FIELDS',
        'CONSUMPTION.DIM_SOURCE',
        'source_key,source_domain,source_code,source_name',

        COUNT_IF(
            source_key IS NULL
            OR source_domain IS NULL
            OR source_code IS NULL
            OR source_name IS NULL
        )

    FROM CONSUMPTION.DIM_SOURCE

)

SELECT
    $DQ_RUN_ID AS dq_run_id,

    test_name,

    'MANDATORY_FIELDS' AS test_category,

    target_object,
    target_column,

    'ERROR' AS severity,

    '0' AS expected_value,

    failure_count::STRING AS observed_value,

    IFF(
        failure_count = 0,
        'PASS',
        'FAIL'
    ) AS test_status,

    failure_count,

    IFF(
        failure_count = 0,
        'All mandatory dimension fields are populated.',
        'Rows with missing mandatory dimension fields detected.'
    ) AS test_message,

    CURRENT_TIMESTAMP() AS executed_at_utc

FROM tests;



-- =============================================================================
-- 2. FACT MANDATORY FIELD TESTS
-- =============================================================================

INSERT INTO CONTROL.DQ_RESULTS (

    dq_run_id,
    test_name,
    test_category,
    target_object,
    target_column,
    severity,
    expected_value,
    observed_value,
    test_status,
    failure_count,
    test_message,
    executed_at_utc

)

WITH tests AS (

    -- -------------------------------------------------------------------------
    -- FACT_CROPS_LIVESTOCK
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_CROPS_LIVESTOCK_REQUIRED_FIELDS' AS test_name,
        'CONSUMPTION.FACT_CROPS_LIVESTOCK' AS target_object,
        'geography_key,date_key,item_key,element_key,source_row_hash' AS target_column,

        COUNT_IF(
            geography_key IS NULL
            OR date_key IS NULL
            OR item_key IS NULL
            OR element_key IS NULL
            OR source_row_hash IS NULL
        ) AS failure_count

    FROM CONSUMPTION.FACT_CROPS_LIVESTOCK


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_LAND_COVER
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_LAND_COVER_REQUIRED_FIELDS',
        'CONSUMPTION.FACT_LAND_COVER',
        'geography_key,date_key,item_key,element_key,source_row_hash',

        COUNT_IF(
            geography_key IS NULL
            OR date_key IS NULL
            OR item_key IS NULL
            OR element_key IS NULL
            OR source_row_hash IS NULL
        )

    FROM CONSUMPTION.FACT_LAND_COVER


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_NUTRIENT_BALANCE
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_NUTRIENT_BALANCE_REQUIRED_FIELDS',
        'CONSUMPTION.FACT_NUTRIENT_BALANCE',
        'geography_key,date_key,item_key,element_key,source_row_hash',

        COUNT_IF(
            geography_key IS NULL
            OR date_key IS NULL
            OR item_key IS NULL
            OR element_key IS NULL
            OR source_row_hash IS NULL
        )

    FROM CONSUMPTION.FACT_NUTRIENT_BALANCE


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_FOOD_BALANCE
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_FOOD_BALANCE_REQUIRED_FIELDS',
        'CONSUMPTION.FACT_FOOD_BALANCE',
        'geography_key,date_key,item_key,element_key,source_row_hash',

        COUNT_IF(
            geography_key IS NULL
            OR date_key IS NULL
            OR item_key IS NULL
            OR element_key IS NULL
            OR source_row_hash IS NULL
        )

    FROM CONSUMPTION.FACT_FOOD_BALANCE


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_EMISSIONS
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_EMISSIONS_REQUIRED_FIELDS',
        'CONSUMPTION.FACT_EMISSIONS',
        'geography_key,date_key,item_key,element_key,source_key,source_row_hash',

        COUNT_IF(
            geography_key IS NULL
            OR date_key IS NULL
            OR item_key IS NULL
            OR element_key IS NULL
            OR source_key IS NULL
            OR source_row_hash IS NULL
        )

    FROM CONSUMPTION.FACT_EMISSIONS


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_FOOD_SECURITY
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_FOOD_SECURITY_REQUIRED_FIELDS',
        'CONSUMPTION.FACT_FOOD_SECURITY',
        'geography_key,indicator_key,element_key,period_key,source_row_hash',

        COUNT_IF(
            geography_key IS NULL
            OR indicator_key IS NULL
            OR element_key IS NULL
            OR period_key IS NULL
            OR source_row_hash IS NULL
        )

    FROM CONSUMPTION.FACT_FOOD_SECURITY


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_WDI
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_WDI_REQUIRED_FIELDS',
        'CONSUMPTION.FACT_WDI',
        'geography_key,indicator_key,date_key,source_row_hash',

        COUNT_IF(
            geography_key IS NULL
            OR indicator_key IS NULL
            OR date_key IS NULL
            OR source_row_hash IS NULL
        )

    FROM CONSUMPTION.FACT_WDI

)

SELECT
    $DQ_RUN_ID AS dq_run_id,

    test_name,

    'MANDATORY_FIELDS' AS test_category,

    target_object,
    target_column,

    'ERROR' AS severity,

    '0' AS expected_value,

    failure_count::STRING AS observed_value,

    IFF(
        failure_count = 0,
        'PASS',
        'FAIL'
    ) AS test_status,

    failure_count,

    IFF(
        failure_count = 0,
        'All mandatory fact fields are populated.',
        'Rows with missing mandatory fact fields detected.'
    ) AS test_message,

    CURRENT_TIMESTAMP() AS executed_at_utc

FROM tests;



-- =============================================================================
-- 3. VIEW RESULTS FOR CURRENT RUN
-- =============================================================================

SELECT
    test_category,
    test_name,
    target_object,
    target_column,
    severity,
    expected_value,
    observed_value,
    test_status,
    failure_count,
    test_message

FROM CONTROL.DQ_RESULTS

WHERE dq_run_id = $DQ_RUN_ID
  AND test_category = 'MANDATORY_FIELDS'

ORDER BY
    target_object,
    test_name;