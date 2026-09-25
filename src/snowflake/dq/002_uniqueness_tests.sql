SET DQ_RUN_ID =
    'DQ_' ||
    TO_VARCHAR(
        CURRENT_TIMESTAMP(),
        'YYYYMMDD_HH24MISS'
    );

INSERT INTO GFS_DEV.CONTROL.DQ_RUNS (
    dq_run_id,
    run_status,
    started_at_utc
)
VALUES (
    $DQ_RUN_ID,
    'RUNNING',
    CURRENT_TIMESTAMP()
);

USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


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

    -- DIM_GEOGRAPHY
    SELECT
        'DIM_GEOGRAPHY_BUSINESS_KEY_UNIQUE' AS test_name,
        'CONSUMPTION.DIM_GEOGRAPHY' AS target_object,
        'area_code_fao' AS target_column,
        COUNT(*) AS failure_count
    FROM (
        SELECT area_code_fao
        FROM CONSUMPTION.DIM_GEOGRAPHY
        GROUP BY area_code_fao
        HAVING COUNT(*) > 1
    )

    UNION ALL

    -- DIM_DATE
    SELECT
        'DIM_DATE_KEY_UNIQUE',
        'CONSUMPTION.DIM_DATE',
        'date_key',
        COUNT(*)
    FROM (
        SELECT date_key
        FROM CONSUMPTION.DIM_DATE
        GROUP BY date_key
        HAVING COUNT(*) > 1
    )

    UNION ALL

    -- DIM_PERIOD
    SELECT
        'DIM_PERIOD_CODE_UNIQUE',
        'CONSUMPTION.DIM_PERIOD',
        'period_code',
        COUNT(*)
    FROM (
        SELECT period_code
        FROM CONSUMPTION.DIM_PERIOD
        GROUP BY period_code
        HAVING COUNT(*) > 1
    )

    UNION ALL

    -- DIM_ITEM
    SELECT
        'DIM_ITEM_BUSINESS_KEY_UNIQUE',
        'CONSUMPTION.DIM_ITEM',
        'source_domain + item_code',
        COUNT(*)
    FROM (
        SELECT
            source_domain,
            item_code
        FROM CONSUMPTION.DIM_ITEM
        GROUP BY
            source_domain,
            item_code
        HAVING COUNT(*) > 1
    )

    UNION ALL

    -- DIM_ELEMENT
    SELECT
        'DIM_ELEMENT_BUSINESS_KEY_UNIQUE',
        'CONSUMPTION.DIM_ELEMENT',
        'source_domain + element_code',
        COUNT(*)
    FROM (
        SELECT
            source_domain,
            element_code
        FROM CONSUMPTION.DIM_ELEMENT
        GROUP BY
            source_domain,
            element_code
        HAVING COUNT(*) > 1
    )

    UNION ALL

    -- DIM_INDICATOR
    SELECT
        'DIM_INDICATOR_BUSINESS_KEY_UNIQUE',
        'CONSUMPTION.DIM_INDICATOR',
        'source_system + source_domain + indicator_code',
        COUNT(*)
    FROM (
        SELECT
            source_system,
            source_domain,
            indicator_code
        FROM CONSUMPTION.DIM_INDICATOR
        GROUP BY
            source_system,
            source_domain,
            indicator_code
        HAVING COUNT(*) > 1
    )

    UNION ALL

    -- DIM_SOURCE
    SELECT
        'DIM_SOURCE_BUSINESS_KEY_UNIQUE',
        'CONSUMPTION.DIM_SOURCE',
        'source_domain + source_code',
        COUNT(*)
    FROM (
        SELECT
            source_domain,
            source_code
        FROM CONSUMPTION.DIM_SOURCE
        GROUP BY
            source_domain,
            source_code
        HAVING COUNT(*) > 1
    )
)

SELECT
    $DQ_RUN_ID,
    test_name,
    'UNIQUENESS',
    target_object,
    target_column,
    'ERROR',
    '0',
    failure_count::STRING,

    IFF(
        failure_count = 0,
        'PASS',
        'FAIL'
    ),

    failure_count,

    IFF(
        failure_count = 0,
        'Business key is unique.',
        'Duplicate business-key groups detected.'
    ),

    CURRENT_TIMESTAMP()

FROM tests;

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

    SELECT
        'FACT_CROPS_LIVESTOCK_GRAIN_UNIQUE' AS test_name,
        'CONSUMPTION.FACT_CROPS_LIVESTOCK' AS target_object,
        'geography_key,item_key,element_key,date_key' AS target_column,
        COUNT(*) AS failure_count
    FROM (
        SELECT
            geography_key,
            item_key,
            element_key,
            date_key
        FROM CONSUMPTION.FACT_CROPS_LIVESTOCK
        GROUP BY 1,2,3,4
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT
        'FACT_LAND_COVER_GRAIN_UNIQUE',
        'CONSUMPTION.FACT_LAND_COVER',
        'geography_key,item_key,element_key,date_key',
        COUNT(*)
    FROM (
        SELECT
            geography_key,
            item_key,
            element_key,
            date_key
        FROM CONSUMPTION.FACT_LAND_COVER
        GROUP BY 1,2,3,4
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT
        'FACT_NUTRIENT_BALANCE_GRAIN_UNIQUE',
        'CONSUMPTION.FACT_NUTRIENT_BALANCE',
        'geography_key,item_key,element_key,date_key',
        COUNT(*)
    FROM (
        SELECT
            geography_key,
            item_key,
            element_key,
            date_key
        FROM CONSUMPTION.FACT_NUTRIENT_BALANCE
        GROUP BY 1,2,3,4
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT
        'FACT_FOOD_BALANCE_GRAIN_UNIQUE',
        'CONSUMPTION.FACT_FOOD_BALANCE',
        'geography_key,item_key,element_key,date_key',
        COUNT(*)
    FROM (
        SELECT
            geography_key,
            item_key,
            element_key,
            date_key
        FROM CONSUMPTION.FACT_FOOD_BALANCE
        GROUP BY 1,2,3,4
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT
        'FACT_EMISSIONS_GRAIN_UNIQUE',
        'CONSUMPTION.FACT_EMISSIONS',
        'geography_key,item_key,element_key,source_key,date_key',
        COUNT(*)
    FROM (
        SELECT
            geography_key,
            item_key,
            element_key,
            source_key,
            date_key
        FROM CONSUMPTION.FACT_EMISSIONS
        GROUP BY 1,2,3,4,5
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT
        'FACT_FOOD_SECURITY_GRAIN_UNIQUE',
        'CONSUMPTION.FACT_FOOD_SECURITY',
        'geography_key,indicator_key,element_key,period_key',
        COUNT(*)
    FROM (
        SELECT
            geography_key,
            indicator_key,
            element_key,
            period_key
        FROM CONSUMPTION.FACT_FOOD_SECURITY
        GROUP BY 1,2,3,4
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT
        'FACT_WDI_GRAIN_UNIQUE',
        'CONSUMPTION.FACT_WDI',
        'geography_key,indicator_key,date_key',
        COUNT(*)
    FROM (
        SELECT
            geography_key,
            indicator_key,
            date_key
        FROM CONSUMPTION.FACT_WDI
        GROUP BY 1,2,3
        HAVING COUNT(*) > 1
    )
)

SELECT
    $DQ_RUN_ID,
    test_name,
    'UNIQUENESS',
    target_object,
    target_column,
    'ERROR',
    '0',
    failure_count::STRING,

    IFF(failure_count = 0, 'PASS', 'FAIL'),

    failure_count,

    IFF(
        failure_count = 0,
        'Declared fact grain is unique.',
        'Duplicate fact-grain groups detected.'
    ),

    CURRENT_TIMESTAMP()

FROM tests;