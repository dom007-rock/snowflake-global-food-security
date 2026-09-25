USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


-- =============================================================================
-- PHASE 11 - ACCEPTED VALUE + TIME RANGE TESTS
--
-- Assumption:
--   $DQ_RUN_ID exists for the current run.
--
-- Severity:
--   ERROR
-- =============================================================================



-- =============================================================================
-- 1. ACCEPTED VALUES
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
    -- DIM_GEOGRAPHY mapping status
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_GEOGRAPHY_MAPPING_STATUS_ACCEPTED' AS test_name,
        'CONSUMPTION.DIM_GEOGRAPHY' AS target_object,
        'mapping_status' AS target_column,

        COUNT_IF(
            mapping_status IS NULL
            OR mapping_status NOT IN (
                'MAPPED',
                'NO_WDI_MATCH',
                'NOT_APPLICABLE',
                'MANUAL_REVIEW'
            )
        ) AS failure_count

    FROM CONSUMPTION.DIM_GEOGRAPHY


    UNION ALL


    -- -------------------------------------------------------------------------
    -- DIM_PERIOD period type
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_PERIOD_TYPE_ACCEPTED',
        'CONSUMPTION.DIM_PERIOD',
        'period_type',

        COUNT_IF(
            period_type IS NULL
            OR period_type NOT IN (
                'ANNUAL',
                'MULTI_YEAR'
            )
        )

    FROM CONSUMPTION.DIM_PERIOD


    UNION ALL


    -- -------------------------------------------------------------------------
    -- DIM_INDICATOR source combinations
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_INDICATOR_SOURCE_ACCEPTED',
        'CONSUMPTION.DIM_INDICATOR',
        'source_system,source_domain',

        COUNT_IF(
            NOT (
                (source_system = 'FAOSTAT'
                 AND source_domain = 'FS')

                OR

                (source_system = 'WORLD_BANK'
                 AND source_domain = 'WDI')
            )
        )

    FROM CONSUMPTION.DIM_INDICATOR

)

SELECT
    $DQ_RUN_ID AS dq_run_id,
    test_name,
    'ACCEPTED_VALUES' AS test_category,
    target_object,
    target_column,
    'ERROR' AS severity,

    '0 invalid rows' AS expected_value,
    failure_count::STRING AS observed_value,

    IFF(
        failure_count = 0,
        'PASS',
        'FAIL'
    ) AS test_status,

    failure_count,

    IFF(
        failure_count = 0,
        'All values are within the accepted domain.',
        'Unexpected categorical values detected.'
    ) AS test_message,

    CURRENT_TIMESTAMP() AS executed_at_utc

FROM tests;



-- =============================================================================
-- 2. YEAR / PERIOD RANGE TESTS
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
    -- DIM_DATE
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_DATE_YEAR_RANGE' AS test_name,
        'CONSUMPTION.DIM_DATE' AS target_object,
        'year' AS target_column,

        COUNT_IF(
            year < 2010
            OR year > 2023
        ) AS failure_count

    FROM CONSUMPTION.DIM_DATE


    UNION ALL


    -- -------------------------------------------------------------------------
    -- DIM_PERIOD
    -- -------------------------------------------------------------------------

    SELECT
        'DIM_PERIOD_YEAR_RANGE',
        'CONSUMPTION.DIM_PERIOD',
        'period_start_year,period_end_year',

        COUNT_IF(
            period_start_year < 2010
            OR period_end_year > 2023
            OR period_start_year > period_end_year
        )

    FROM CONSUMPTION.DIM_PERIOD


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_CROPS_LIVESTOCK
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_CROPS_LIVESTOCK_YEAR_RANGE',
        'CONSUMPTION.FACT_CROPS_LIVESTOCK',
        'date_key',

        COUNT_IF(
            d.year < 2010
            OR d.year > 2023
        )

    FROM CONSUMPTION.FACT_CROPS_LIVESTOCK f

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_LAND_COVER
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_LAND_COVER_YEAR_RANGE',
        'CONSUMPTION.FACT_LAND_COVER',
        'date_key',

        COUNT_IF(
            d.year < 2010
            OR d.year > 2023
        )

    FROM CONSUMPTION.FACT_LAND_COVER f

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_NUTRIENT_BALANCE
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_NUTRIENT_BALANCE_YEAR_RANGE',
        'CONSUMPTION.FACT_NUTRIENT_BALANCE',
        'date_key',

        COUNT_IF(
            d.year < 2010
            OR d.year > 2023
        )

    FROM CONSUMPTION.FACT_NUTRIENT_BALANCE f

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_FOOD_BALANCE
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_FOOD_BALANCE_YEAR_RANGE',
        'CONSUMPTION.FACT_FOOD_BALANCE',
        'date_key',

        COUNT_IF(
            d.year < 2010
            OR d.year > 2023
        )

    FROM CONSUMPTION.FACT_FOOD_BALANCE f

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_EMISSIONS
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_EMISSIONS_YEAR_RANGE',
        'CONSUMPTION.FACT_EMISSIONS',
        'date_key',

        COUNT_IF(
            d.year < 2010
            OR d.year > 2023
        )

    FROM CONSUMPTION.FACT_EMISSIONS f

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_FOOD_SECURITY
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_FOOD_SECURITY_PERIOD_RANGE',
        'CONSUMPTION.FACT_FOOD_SECURITY',
        'period_key',

        COUNT_IF(
            p.period_start_year < 2010
            OR p.period_end_year > 2023
            OR p.period_start_year > p.period_end_year
        )

    FROM CONSUMPTION.FACT_FOOD_SECURITY f

    LEFT JOIN CONSUMPTION.DIM_PERIOD p
        ON f.period_key = p.period_key


    UNION ALL


    -- -------------------------------------------------------------------------
    -- FACT_WDI
    -- -------------------------------------------------------------------------

    SELECT
        'FACT_WDI_YEAR_RANGE',
        'CONSUMPTION.FACT_WDI',
        'date_key',

        COUNT_IF(
            d.year < 2010
            OR d.year > 2023
        )

    FROM CONSUMPTION.FACT_WDI f

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

)

SELECT
    $DQ_RUN_ID,
    test_name,
    'YEAR_RANGE',
    target_object,
    target_column,
    'ERROR',

    '2010-2023',
    failure_count::STRING,

    IFF(
        failure_count = 0,
        'PASS',
        'FAIL'
    ),

    failure_count,

    IFF(
        failure_count = 0,
        'Observation is within the supported analytical period.',
        'Observations outside the supported analytical period detected.'
    ),

    CURRENT_TIMESTAMP()

FROM tests;



-- =============================================================================
-- REVIEW RESULTS
-- =============================================================================

SELECT
    test_category,
    test_name,
    target_object,
    target_column,
    test_status,
    failure_count

FROM CONTROL.DQ_RESULTS

WHERE dq_run_id = $DQ_RUN_ID
  AND test_category IN (
      'ACCEPTED_VALUES',
      'YEAR_RANGE'
  )

ORDER BY
    test_category,
    test_name;