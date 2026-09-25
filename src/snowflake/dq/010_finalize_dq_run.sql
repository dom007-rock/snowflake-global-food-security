USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


UPDATE CONTROL.DQ_RUNS AS run

SET

    total_tests =
        summary.total_tests,

    passed_tests =
        summary.passed_tests,

    warning_tests =
        summary.warning_tests,

    failed_tests =
        summary.failed_error_tests,

    run_status =
        CASE

            WHEN summary.failed_error_tests > 0
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

        COUNT_IF(
            test_status = 'PASS'
        ) AS passed_tests,

        COUNT_IF(
            test_status = 'WARN'
        ) AS warning_tests,

        COUNT_IF(
            test_status = 'FAIL'
            AND severity = 'ERROR'
        ) AS failed_error_tests

    FROM CONTROL.DQ_RESULTS

    WHERE dq_run_id = $DQ_RUN_ID

    GROUP BY dq_run_id

) AS summary

WHERE run.dq_run_id = summary.dq_run_id;

CREATE OR REPLACE VIEW CONTROL.V_DQ_RUN_GATE AS

SELECT
    r.dq_run_id,

    r.run_status,

    r.total_tests,
    r.passed_tests,
    r.warning_tests,
    r.failed_tests,

    IFF(
        r.run_status = 'FAILED',
        TRUE,
        FALSE
    ) AS should_stop_pipeline,

    r.started_at_utc,
    r.completed_at_utc

FROM CONTROL.DQ_RUNS r;

UPDATE CONTROL.DQ_RUNS AS run

SET

    total_tests =
        summary.total_tests,

    passed_tests =
        summary.passed_tests,

    warning_tests =
        summary.warning_tests,

    failed_tests =
        summary.failed_error_tests,

    run_status =
        CASE
            WHEN summary.failed_error_tests > 0
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
        ) AS failed_error_tests

    FROM CONTROL.DQ_RESULTS

    WHERE dq_run_id = $DQ_RUN_ID

    GROUP BY dq_run_id

) summary

WHERE run.dq_run_id = summary.dq_run_id;