-- Phase 14: Monitoring & Cost Management

USE ROLE ACCOUNTADMIN;

GRANT DATABASE ROLE SNOWFLAKE.USAGE_VIEWER TO ROLE GFS_PLATFORM_ADMIN;
GRANT DATABASE ROLE SNOWFLAKE.GOVERNANCE_VIEWER TO ROLE GFS_PLATFORM_ADMIN;

CREATE OR REPLACE RESOURCE MONITOR GFS_DEV_MONTHLY_RM
WITH
    CREDIT_QUOTA = 10
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
TRIGGERS
    ON 50 PERCENT DO NOTIFY
    ON 80 PERCENT DO NOTIFY
    ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE GFS_INGEST_WH SET RESOURCE_MONITOR = GFS_DEV_MONTHLY_RM;
ALTER WAREHOUSE GFS_TRANSFORM_WH SET RESOURCE_MONITOR = GFS_DEV_MONTHLY_RM;
ALTER WAREHOUSE GFS_ANALYTICS_WH SET RESOURCE_MONITOR = GFS_DEV_MONTHLY_RM;

ALTER WAREHOUSE GFS_INGEST_WH SET
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

ALTER WAREHOUSE GFS_TRANSFORM_WH SET
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

ALTER WAREHOUSE GFS_ANALYTICS_WH SET
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CONTROL;

CREATE OR REPLACE VIEW CONTROL.V_MONITOR_WAREHOUSE_CREDITS AS
SELECT
    start_time,
    end_time,
    warehouse_name,
    credits_used_compute,
    credits_used_cloud_services,
    credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE warehouse_name IN (
    'GFS_INGEST_WH',
    'GFS_TRANSFORM_WH',
    'GFS_ANALYTICS_WH'
)
AND start_time >= DATEADD('DAY', -30, CURRENT_TIMESTAMP());

CREATE OR REPLACE VIEW CONTROL.V_MONITOR_QUERIES AS
SELECT
    query_id,
    start_time,
    end_time,
    user_name,
    role_name,
    warehouse_name,
    query_type,
    execution_status,
    ROUND(total_elapsed_time / 1000, 3) AS total_elapsed_seconds,
    ROUND(execution_time / 1000, 3) AS execution_seconds,
    ROUND(compilation_time / 1000, 3) AS compilation_seconds,
    bytes_scanned,
    rows_produced,
    rows_inserted,
    rows_updated,
    rows_deleted,
    error_code,
    error_message,
    query_text
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('DAY', -7, CURRENT_TIMESTAMP())
  AND warehouse_name IN (
      'GFS_INGEST_WH',
      'GFS_TRANSFORM_WH',
      'GFS_ANALYTICS_WH'
  );

CREATE OR REPLACE VIEW CONTROL.V_MONITOR_TASK_RUNS AS
SELECT
    t.graph_run_group_id,
    t.attempt_number,
    t.name AS task_name,
    t.state,
    t.scheduled_time,
    t.query_start_time,
    t.completed_time,
    ROUND(
        DATEDIFF('MILLISECOND', t.query_start_time, t.completed_time) / 1000,
        3
    ) AS duration_seconds,
    COALESCE(q.rows_inserted, 0)
      + COALESCE(q.rows_updated, 0)
      + COALESCE(q.rows_deleted, 0) AS rows_processed,
    t.error_code,
    t.error_message,
    t.query_id
FROM SNOWFLAKE.ACCOUNT_USAGE.TASK_HISTORY t
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY q
    ON t.query_id = q.query_id
WHERE t.database_name = 'GFS_DEV'
  AND t.schema_name = 'CONTROL'
  AND t.scheduled_time >= DATEADD('DAY', -7, CURRENT_TIMESTAMP());

CREATE OR REPLACE VIEW CONTROL.V_MONITOR_DATA_FRESHNESS AS
SELECT 'QCL' AS dataset, COUNT(*) AS row_count, MAX(extracted_at_utc) AS latest_source_extract
FROM CLEAN.FAOSTAT_QCL
UNION ALL
SELECT 'LC', COUNT(*), MAX(extracted_at_utc) FROM CLEAN.FAOSTAT_LC
UNION ALL
SELECT 'ESB', COUNT(*), MAX(extracted_at_utc) FROM CLEAN.FAOSTAT_ESB
UNION ALL
SELECT 'FBS', COUNT(*), MAX(extracted_at_utc) FROM CLEAN.FAOSTAT_FBS
UNION ALL
SELECT 'GT', COUNT(*), MAX(extracted_at_utc) FROM CLEAN.FAOSTAT_GT
UNION ALL
SELECT 'FS', COUNT(*), MAX(extracted_at_utc) FROM CLEAN.FAOSTAT_FS
UNION ALL
SELECT 'WDI', COUNT(*), MAX(extracted_at_utc) FROM CLEAN.WDI_OBSERVATIONS;

CREATE OR REPLACE VIEW CONTROL.V_MONITOR_DQ_RUNS AS
SELECT
    dq_run_id,
    run_status,
    started_at_utc,
    completed_at_utc,
    DATEDIFF('SECOND', started_at_utc, completed_at_utc) AS duration_seconds,
    total_tests,
    passed_tests,
    warning_tests,
    failed_tests
FROM CONTROL.DQ_RUNS;

CREATE OR REPLACE VIEW CONTROL.V_MONITOR_DQ_FAILURES AS
SELECT
    dq_run_id,
    test_name,
    test_category,
    target_object,
    target_column,
    severity,
    expected_value,
    observed_value,
    failure_count,
    test_message,
    executed_at_utc
FROM CONTROL.DQ_RESULTS
WHERE test_status IN ('FAIL', 'WARN');

-- Operational queries
SELECT * FROM CONTROL.V_MONITOR_TASK_RUNS ORDER BY scheduled_time DESC LIMIT 30;
SELECT * FROM CONTROL.V_MONITOR_TASK_RUNS WHERE state = 'FAILED' ORDER BY scheduled_time DESC;
SELECT * FROM CONTROL.V_MONITOR_DATA_FRESHNESS ORDER BY dataset;
SELECT * FROM CONTROL.V_MONITOR_DQ_RUNS ORDER BY started_at_utc DESC LIMIT 10;
SELECT * FROM CONTROL.V_MONITOR_DQ_FAILURES ORDER BY executed_at_utc DESC;
SELECT * FROM CONTROL.V_MONITOR_QUERIES ORDER BY total_elapsed_seconds DESC LIMIT 20;
SELECT warehouse_name, ROUND(SUM(credits_used), 4) AS credits_used
FROM CONTROL.V_MONITOR_WAREHOUSE_CREDITS
GROUP BY warehouse_name
ORDER BY credits_used DESC;
SHOW RESOURCE MONITORS;
