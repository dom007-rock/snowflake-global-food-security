USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


-- =============================================================================
-- PHASE 11 - NUMERICAL RANGE TESTS
--
-- Rules are intentionally indicator-specific.
-- We do NOT apply value >= 0 globally across FAOSTAT facts.
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

    -- =========================================================================
    -- DIM_PERIOD
    -- Reporting periods must have a positive duration.
    -- =========================================================================

    SELECT
        'DIM_PERIOD_POSITIVE_DURATION' AS test_name,
        'CONSUMPTION.DIM_PERIOD' AS target_object,
        'duration_years' AS target_column,
        'ERROR' AS severity,

        COUNT_IF(
            duration_years <= 0
        ) AS failure_count

    FROM CONSUMPTION.DIM_PERIOD


    UNION ALL


    -- =========================================================================
    -- WORLD BANK POPULATION
    -- Population cannot logically be negative.
    -- =========================================================================

    SELECT
        'WDI_POPULATION_NON_NEGATIVE',
        'CONSUMPTION.FACT_WDI',
        'value',
        'ERROR',

        COUNT_IF(
            ind.indicator_code = 'SP.POP.TOTL'
            AND f.value < 0
        )

    FROM CONSUMPTION.FACT_WDI f

    JOIN CONSUMPTION.DIM_INDICATOR ind
        ON f.indicator_key = ind.indicator_key


    UNION ALL


    -- =========================================================================
    -- WORLD BANK GDP
    -- Current-price GDP observations are expected to be non-negative.
    -- =========================================================================

    SELECT
        'WDI_GDP_NON_NEGATIVE',
        'CONSUMPTION.FACT_WDI',
        'value',
        'ERROR',

        COUNT_IF(
            ind.indicator_code = 'NY.GDP.MKTP.CD'
            AND f.value < 0
        )

    FROM CONSUMPTION.FACT_WDI f

    JOIN CONSUMPTION.DIM_INDICATOR ind
        ON f.indicator_key = ind.indicator_key


    UNION ALL


    -- =========================================================================
    -- GDP PER CAPITA
    -- =========================================================================

    SELECT
        'WDI_GDP_PER_CAPITA_NON_NEGATIVE',
        'CONSUMPTION.FACT_WDI',
        'value',
        'ERROR',

        COUNT_IF(
            ind.indicator_code = 'NY.GDP.PCAP.CD'
            AND f.value < 0
        )

    FROM CONSUMPTION.FACT_WDI f

    JOIN CONSUMPTION.DIM_INDICATOR ind
        ON f.indicator_key = ind.indicator_key


    UNION ALL


    -- =========================================================================
    -- RURAL POPULATION %
    -- Percentage must remain between 0 and 100.
    -- =========================================================================

    SELECT
        'WDI_RURAL_POPULATION_PERCENT_RANGE',
        'CONSUMPTION.FACT_WDI',
        'value',
        'ERROR',

        COUNT_IF(
            ind.indicator_code = 'SP.RUR.TOTL.ZS'
            AND (
                f.value < 0
                OR f.value > 100
            )
        )

    FROM CONSUMPTION.FACT_WDI f

    JOIN CONSUMPTION.DIM_INDICATOR ind
        ON f.indicator_key = ind.indicator_key

)

SELECT
    $DQ_RUN_ID AS dq_run_id,

    test_name,

    'NUMERICAL_RANGE' AS test_category,

    target_object,
    target_column,

    severity,

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
        'Numeric values satisfy the defined business range.',
        'Values outside the defined business range were detected.'
    ) AS test_message,

    CURRENT_TIMESTAMP() AS executed_at_utc

FROM tests;



-- =============================================================================
-- REVIEW
-- =============================================================================

SELECT
    test_name,
    severity,
    expected_value,
    observed_value,
    test_status,
    failure_count

FROM CONTROL.DQ_RESULTS

WHERE dq_run_id = $DQ_RUN_ID
  AND test_category = 'NUMERICAL_RANGE'

ORDER BY test_name;