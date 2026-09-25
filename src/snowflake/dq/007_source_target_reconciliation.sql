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

WITH counts AS (

    SELECT
        'QCL' AS domain,
        'CONSUMPTION.FACT_CROPS_LIVESTOCK' AS target_object,

        (SELECT COUNT(*)
         FROM CLEAN.FAOSTAT_QCL) AS source_count,

        (SELECT COUNT(*)
         FROM CONSUMPTION.FACT_CROPS_LIVESTOCK) AS target_count


    UNION ALL


    SELECT
        'LC',
        'CONSUMPTION.FACT_LAND_COVER',

        (SELECT COUNT(*)
         FROM CLEAN.FAOSTAT_LC),

        (SELECT COUNT(*)
         FROM CONSUMPTION.FACT_LAND_COVER)


    UNION ALL


    SELECT
        'ESB',
        'CONSUMPTION.FACT_NUTRIENT_BALANCE',

        (SELECT COUNT(*)
         FROM CLEAN.FAOSTAT_ESB),

        (SELECT COUNT(*)
         FROM CONSUMPTION.FACT_NUTRIENT_BALANCE)


    UNION ALL


    SELECT
        'FBS',
        'CONSUMPTION.FACT_FOOD_BALANCE',

        (SELECT COUNT(*)
         FROM CLEAN.FAOSTAT_FBS),

        (SELECT COUNT(*)
         FROM CONSUMPTION.FACT_FOOD_BALANCE)


    UNION ALL


    SELECT
        'GT',
        'CONSUMPTION.FACT_EMISSIONS',

        (SELECT COUNT(*)
         FROM CLEAN.FAOSTAT_GT),

        (SELECT COUNT(*)
         FROM CONSUMPTION.FACT_EMISSIONS)


    UNION ALL


    SELECT
        'FS',
        'CONSUMPTION.FACT_FOOD_SECURITY',

        (SELECT COUNT(*)
         FROM CLEAN.FAOSTAT_FS),

        (SELECT COUNT(*)
         FROM CONSUMPTION.FACT_FOOD_SECURITY)


    UNION ALL


    -- WDI is intentionally scoped only to mapped analytical geographies.

    SELECT
        'WDI_MAPPED',
        'CONSUMPTION.FACT_WDI',

        (
            SELECT COUNT(*)

            FROM CLEAN.WDI_OBSERVATIONS wdi

            JOIN CONSUMPTION.DIM_GEOGRAPHY g
                ON wdi.wb_iso3_code = g.country_iso3

            WHERE g.mapping_status = 'MAPPED'
        ),

        (
            SELECT COUNT(*)
            FROM CONSUMPTION.FACT_WDI
        )

),

tests AS (

    SELECT
        'SOURCE_TARGET_' || domain || '_ROW_COUNT' AS test_name,
        target_object,

        source_count,
        target_count,

        ABS(source_count - target_count) AS failure_count

    FROM counts
)

SELECT
    $DQ_RUN_ID,

    test_name,

    'SOURCE_TARGET_RECONCILIATION',

    target_object,

    'row_count',

    'ERROR',

    source_count::STRING,

    target_count::STRING,

    IFF(
        failure_count = 0,
        'PASS',
        'FAIL'
    ),

    failure_count,

    IFF(
        failure_count = 0,
        'Source and target row counts reconcile.',
        'Source and target row counts do not reconcile.'
    ),

    CURRENT_TIMESTAMP()

FROM tests;


SELECT
    test_name,
    expected_value AS source_count,
    observed_value AS target_count,
    test_status

FROM CONTROL.DQ_RESULTS

WHERE dq_run_id = $DQ_RUN_ID
  AND test_category = 'SOURCE_TARGET_RECONCILIATION'

ORDER BY test_name;