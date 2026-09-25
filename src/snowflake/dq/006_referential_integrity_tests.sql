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

    -- =========================================================================
    -- FACT_CROPS_LIVESTOCK
    -- =========================================================================

    SELECT
        'FACT_CROPS_LIVESTOCK_REFERENTIAL_INTEGRITY' AS test_name,
        'CONSUMPTION.FACT_CROPS_LIVESTOCK' AS target_object,
        'geography_key,date_key,item_key,element_key' AS target_column,

        COUNT_IF(
            g.geography_key IS NULL
            OR d.date_key IS NULL
            OR i.item_key IS NULL
            OR e.element_key IS NULL
        ) AS failure_count

    FROM CONSUMPTION.FACT_CROPS_LIVESTOCK f

    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    LEFT JOIN CONSUMPTION.DIM_ITEM i
        ON f.item_key = i.item_key

    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key


    UNION ALL


    -- =========================================================================
    -- FACT_LAND_COVER
    -- =========================================================================

    SELECT
        'FACT_LAND_COVER_REFERENTIAL_INTEGRITY',
        'CONSUMPTION.FACT_LAND_COVER',
        'geography_key,date_key,item_key,element_key',

        COUNT_IF(
            g.geography_key IS NULL
            OR d.date_key IS NULL
            OR i.item_key IS NULL
            OR e.element_key IS NULL
        )

    FROM CONSUMPTION.FACT_LAND_COVER f

    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    LEFT JOIN CONSUMPTION.DIM_ITEM i
        ON f.item_key = i.item_key

    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key


    UNION ALL


    -- =========================================================================
    -- FACT_NUTRIENT_BALANCE
    -- =========================================================================

    SELECT
        'FACT_NUTRIENT_BALANCE_REFERENTIAL_INTEGRITY',
        'CONSUMPTION.FACT_NUTRIENT_BALANCE',
        'geography_key,date_key,item_key,element_key',

        COUNT_IF(
            g.geography_key IS NULL
            OR d.date_key IS NULL
            OR i.item_key IS NULL
            OR e.element_key IS NULL
        )

    FROM CONSUMPTION.FACT_NUTRIENT_BALANCE f

    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    LEFT JOIN CONSUMPTION.DIM_ITEM i
        ON f.item_key = i.item_key

    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key


    UNION ALL


    -- =========================================================================
    -- FACT_FOOD_BALANCE
    -- =========================================================================

    SELECT
        'FACT_FOOD_BALANCE_REFERENTIAL_INTEGRITY',
        'CONSUMPTION.FACT_FOOD_BALANCE',
        'geography_key,date_key,item_key,element_key',

        COUNT_IF(
            g.geography_key IS NULL
            OR d.date_key IS NULL
            OR i.item_key IS NULL
            OR e.element_key IS NULL
        )

    FROM CONSUMPTION.FACT_FOOD_BALANCE f

    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    LEFT JOIN CONSUMPTION.DIM_ITEM i
        ON f.item_key = i.item_key

    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key


    UNION ALL


    -- =========================================================================
    -- FACT_EMISSIONS
    -- =========================================================================

    SELECT
        'FACT_EMISSIONS_REFERENTIAL_INTEGRITY',
        'CONSUMPTION.FACT_EMISSIONS',
        'geography_key,date_key,item_key,element_key,source_key',

        COUNT_IF(
            g.geography_key IS NULL
            OR d.date_key IS NULL
            OR i.item_key IS NULL
            OR e.element_key IS NULL
            OR s.source_key IS NULL
        )

    FROM CONSUMPTION.FACT_EMISSIONS f

    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    LEFT JOIN CONSUMPTION.DIM_ITEM i
        ON f.item_key = i.item_key

    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key

    LEFT JOIN CONSUMPTION.DIM_SOURCE s
        ON f.source_key = s.source_key


    UNION ALL


    -- =========================================================================
    -- FACT_FOOD_SECURITY
    -- =========================================================================

    SELECT
        'FACT_FOOD_SECURITY_REFERENTIAL_INTEGRITY',
        'CONSUMPTION.FACT_FOOD_SECURITY',
        'geography_key,indicator_key,element_key,period_key',

        COUNT_IF(
            g.geography_key IS NULL
            OR ind.indicator_key IS NULL
            OR e.element_key IS NULL
            OR p.period_key IS NULL
        )

    FROM CONSUMPTION.FACT_FOOD_SECURITY f

    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key

    LEFT JOIN CONSUMPTION.DIM_INDICATOR ind
        ON f.indicator_key = ind.indicator_key

    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key

    LEFT JOIN CONSUMPTION.DIM_PERIOD p
        ON f.period_key = p.period_key


    UNION ALL


    -- =========================================================================
    -- FACT_WDI
    -- =========================================================================

    SELECT
        'FACT_WDI_REFERENTIAL_INTEGRITY',
        'CONSUMPTION.FACT_WDI',
        'geography_key,indicator_key,date_key',

        COUNT_IF(
            g.geography_key IS NULL
            OR ind.indicator_key IS NULL
            OR d.date_key IS NULL
        )

    FROM CONSUMPTION.FACT_WDI f

    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key

    LEFT JOIN CONSUMPTION.DIM_INDICATOR ind
        ON f.indicator_key = ind.indicator_key

    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

)

SELECT
    $DQ_RUN_ID,
    test_name,
    'REFERENTIAL_INTEGRITY',
    target_object,
    target_column,
    'ERROR',

    '0 orphan rows',
    failure_count::STRING,

    IFF(
        failure_count = 0,
        'PASS',
        'FAIL'
    ),

    failure_count,

    IFF(
        failure_count = 0,
        'All foreign keys resolve to valid dimension members.',
        'Orphan dimension references detected.'
    ),

    CURRENT_TIMESTAMP()

FROM tests;


SELECT
    test_name,
    test_status,
    failure_count

FROM CONTROL.DQ_RESULTS

WHERE dq_run_id = $DQ_RUN_ID
  AND test_category = 'REFERENTIAL_INTEGRITY'

ORDER BY test_name;