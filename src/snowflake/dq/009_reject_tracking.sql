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

WITH test_result AS (

    SELECT
        COUNT(*) AS reject_count

    FROM CONTROL.FAOSTAT_CLEAN_REJECTS

)

SELECT
    $DQ_RUN_ID,

    'FAOSTAT_CLEAN_REJECT_COUNT',

    'REJECT_TRACKING',

    'CONTROL.FAOSTAT_CLEAN_REJECTS',

    NULL,

    'WARNING',

    '0 preferred',

    reject_count::STRING,

    IFF(
        reject_count = 0,
        'PASS',
        'WARN'
    ),

    reject_count,

    IFF(
        reject_count = 0,
        'No rejected CLEAN records are currently present.',
        'Rejected CLEAN records exist and should be reviewed.'
    ),

    CURRENT_TIMESTAMP()

FROM test_result;