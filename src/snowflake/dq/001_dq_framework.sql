USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


CREATE TABLE IF NOT EXISTS CONTROL.DQ_RUNS (

    dq_run_id          STRING       NOT NULL,

    run_status         STRING       NOT NULL,

    started_at_utc     TIMESTAMP_TZ NOT NULL,
    completed_at_utc   TIMESTAMP_TZ,

    total_tests        NUMBER,
    passed_tests       NUMBER,
    warning_tests      NUMBER,
    failed_tests       NUMBER

);

CREATE TABLE IF NOT EXISTS CONTROL.DQ_RESULTS (

    dq_run_id          STRING       NOT NULL,

    test_name          STRING       NOT NULL,
    test_category      STRING       NOT NULL,

    target_object      STRING       NOT NULL,
    target_column      STRING,

    severity           STRING       NOT NULL,

    expected_value     STRING,
    observed_value     STRING,

    test_status        STRING       NOT NULL,

    failure_count      NUMBER,

    test_message       STRING,

    executed_at_utc    TIMESTAMP_TZ NOT NULL

);