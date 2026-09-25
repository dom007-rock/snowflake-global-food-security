USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


CREATE OR REPLACE PROCEDURE CONTROL.SP_RUN_PIPELINE_DQ_GATE()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS OWNER

AS

$$

DECLARE

    v_dq_run_id STRING;
    v_status    STRING;

BEGIN

    v_dq_run_id :=
        'DQ_PIPE_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDD_HH24MISSFF3'
        );


    -- =========================================================================
    -- REGISTER RUN
    -- =========================================================================

    INSERT INTO CONTROL.DQ_RUNS (
        dq_run_id,
        run_status,
        started_at_utc
    )
    VALUES (
        :v_dq_run_id,
        'RUNNING',
        CURRENT_TIMESTAMP()
    );


    -- =========================================================================
    -- 1. SOURCE -> TARGET RECONCILIATION
    -- =========================================================================

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
            (SELECT COUNT(*) FROM CLEAN.FAOSTAT_QCL) AS source_count,
            (SELECT COUNT(*) FROM CONSUMPTION.FACT_CROPS_LIVESTOCK) AS target_count

        UNION ALL

        SELECT
            'LC',
            'CONSUMPTION.FACT_LAND_COVER',
            (SELECT COUNT(*) FROM CLEAN.FAOSTAT_LC),
            (SELECT COUNT(*) FROM CONSUMPTION.FACT_LAND_COVER)

        UNION ALL

        SELECT
            'ESB',
            'CONSUMPTION.FACT_NUTRIENT_BALANCE',
            (SELECT COUNT(*) FROM CLEAN.FAOSTAT_ESB),
            (SELECT COUNT(*) FROM CONSUMPTION.FACT_NUTRIENT_BALANCE)

        UNION ALL

        SELECT
            'FBS',
            'CONSUMPTION.FACT_FOOD_BALANCE',
            (SELECT COUNT(*) FROM CLEAN.FAOSTAT_FBS),
            (SELECT COUNT(*) FROM CONSUMPTION.FACT_FOOD_BALANCE)

        UNION ALL

        SELECT
            'GT',
            'CONSUMPTION.FACT_EMISSIONS',
            (SELECT COUNT(*) FROM CLEAN.FAOSTAT_GT),
            (SELECT COUNT(*) FROM CONSUMPTION.FACT_EMISSIONS)

        UNION ALL

        SELECT
            'FS',
            'CONSUMPTION.FACT_FOOD_SECURITY',
            (SELECT COUNT(*) FROM CLEAN.FAOSTAT_FS),
            (SELECT COUNT(*) FROM CONSUMPTION.FACT_FOOD_SECURITY)

        UNION ALL

        SELECT
            'WDI_MAPPED',
            'CONSUMPTION.FACT_WDI',

            (
                SELECT COUNT(*)

                FROM CLEAN.WDI_OBSERVATIONS w

                JOIN CONSUMPTION.DIM_GEOGRAPHY g
                    ON w.wb_iso3_code = g.country_iso3
                   AND g.mapping_status = 'MAPPED'
            ),

            (
                SELECT COUNT(*)
                FROM CONSUMPTION.FACT_WDI
            )

    )

    SELECT
        :v_dq_run_id,

        'PIPELINE_' || domain || '_RECONCILIATION',

        'SOURCE_TARGET_RECONCILIATION',

        target_object,

        'row_count',

        'ERROR',

        source_count::STRING,

        target_count::STRING,

        IFF(
            source_count = target_count,
            'PASS',
            'FAIL'
        ),

        ABS(source_count - target_count),

        IFF(
            source_count = target_count,
            'Source and target counts reconcile.',
            'Source and target counts differ.'
        ),

        CURRENT_TIMESTAMP()

    FROM counts;



    -- =========================================================================
    -- 2. FACT GRAIN UNIQUENESS
    -- =========================================================================

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
            'FACT_CROPS_LIVESTOCK_GRAIN' AS test_name,
            'CONSUMPTION.FACT_CROPS_LIVESTOCK' AS target_object,
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
            'FACT_LAND_COVER_GRAIN',
            'CONSUMPTION.FACT_LAND_COVER',
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
            'FACT_NUTRIENT_BALANCE_GRAIN',
            'CONSUMPTION.FACT_NUTRIENT_BALANCE',
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
            'FACT_FOOD_BALANCE_GRAIN',
            'CONSUMPTION.FACT_FOOD_BALANCE',
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
            'FACT_EMISSIONS_GRAIN',
            'CONSUMPTION.FACT_EMISSIONS',
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
            'FACT_FOOD_SECURITY_GRAIN',
            'CONSUMPTION.FACT_FOOD_SECURITY',
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
            'FACT_WDI_GRAIN',
            'CONSUMPTION.FACT_WDI',
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
        :v_dq_run_id,

        test_name,

        'UNIQUENESS',

        target_object,

        'declared fact grain',

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
            'Fact grain is unique.',
            'Duplicate fact-grain groups detected.'
        ),

        CURRENT_TIMESTAMP()

    FROM tests;



    -- =========================================================================
    -- 3. REFERENTIAL INTEGRITY
    -- =========================================================================

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
            'FACT_CROPS_LIVESTOCK_RI' AS test_name,
            'CONSUMPTION.FACT_CROPS_LIVESTOCK' AS target_object,

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


        SELECT
            'FACT_LAND_COVER_RI',
            'CONSUMPTION.FACT_LAND_COVER',

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


        SELECT
            'FACT_NUTRIENT_BALANCE_RI',
            'CONSUMPTION.FACT_NUTRIENT_BALANCE',

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


        SELECT
            'FACT_FOOD_BALANCE_RI',
            'CONSUMPTION.FACT_FOOD_BALANCE',

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


        SELECT
            'FACT_EMISSIONS_RI',
            'CONSUMPTION.FACT_EMISSIONS',

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


        SELECT
            'FACT_FOOD_SECURITY_RI',
            'CONSUMPTION.FACT_FOOD_SECURITY',

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


        SELECT
            'FACT_WDI_RI',
            'CONSUMPTION.FACT_WDI',

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
        :v_dq_run_id,

        test_name,

        'REFERENTIAL_INTEGRITY',

        target_object,

        'dimension keys',

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
            'All foreign keys resolve.',
            'Orphan dimension references detected.'
        ),

        CURRENT_TIMESTAMP()

    FROM tests;



    -- =========================================================================
    -- 4. REJECT TRACKING
    -- =========================================================================

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

    SELECT
        :v_dq_run_id,

        'FAOSTAT_CLEAN_REJECT_COUNT',

        'REJECT_TRACKING',

        'CONTROL.FAOSTAT_CLEAN_REJECTS',

        NULL,

        'WARNING',

        '0 preferred',

        COUNT(*)::STRING,

        IFF(
            COUNT(*) = 0,
            'PASS',
            'WARN'
        ),

        COUNT(*),

        IFF(
            COUNT(*) = 0,
            'No CLEAN rejects present.',
            'CLEAN rejects exist and should be reviewed.'
        ),

        CURRENT_TIMESTAMP()

    FROM CONTROL.FAOSTAT_CLEAN_REJECTS;



    -- =========================================================================
    -- FINALIZE DQ RUN
    -- =========================================================================

    UPDATE CONTROL.DQ_RUNS run

    SET
        total_tests = summary.total_tests,

        passed_tests = summary.passed_tests,

        warning_tests = summary.warning_tests,

        failed_tests = summary.failed_tests,

        run_status =
            CASE
                WHEN summary.failed_tests > 0
                    THEN 'FAILED'

                WHEN summary.warning_tests > 0
                    THEN 'WARNING'

                ELSE 'PASSED'
            END,

        completed_at_utc =
            CURRENT_TIMESTAMP()

    FROM (

        SELECT
            dq_run_id,

            COUNT(*) AS total_tests,

            COUNT_IF(test_status = 'PASS')
                AS passed_tests,

            COUNT_IF(test_status = 'WARN')
                AS warning_tests,

            COUNT_IF(
                test_status = 'FAIL'
                AND severity = 'ERROR'
            ) AS failed_tests

        FROM CONTROL.DQ_RESULTS

        WHERE dq_run_id = :v_dq_run_id

        GROUP BY dq_run_id

    ) summary

    WHERE run.dq_run_id = summary.dq_run_id;


    SELECT run_status
    INTO :v_status

    FROM CONTROL.DQ_RUNS

    WHERE dq_run_id = :v_dq_run_id;


    RETURN v_dq_run_id || '|' || v_status;

END;

$$;