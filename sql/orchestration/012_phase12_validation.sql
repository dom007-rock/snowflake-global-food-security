-- Phase 12 validation checkpoints
USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;

SELECT COUNT(*) AS fact_rows
FROM CONSUMPTION.FACT_CROPS_LIVESTOCK;

SELECT COUNT(*) AS duplicate_grains
FROM (
    SELECT geography_key, item_key, element_key, date_key, COUNT(*) AS cnt
    FROM CONSUMPTION.FACT_CROPS_LIVESTOCK
    GROUP BY 1,2,3,4
    HAVING COUNT(*) > 1
);

SELECT SYSTEM$STREAM_HAS_DATA(
    'GFS_DEV.CLEAN.FAOSTAT_QCL_STREAM'
) AS qcl_stream_has_data;

SELECT
    dq_run_id,
    run_status,
    total_tests,
    passed_tests,
    warning_tests,
    failed_tests
FROM CONTROL.DQ_RUNS
ORDER BY started_at_utc DESC
LIMIT 1;
