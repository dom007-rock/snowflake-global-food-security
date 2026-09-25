# Phase 14 - Monitoring & Cost Management

## Monitoring surfaces

The project exposes operational views under `GFS_DEV.CONTROL`:

- `V_MONITOR_WAREHOUSE_CREDITS`
- `V_MONITOR_QUERIES`
- `V_MONITOR_TASK_RUNS`
- `V_MONITOR_DATA_FRESHNESS`
- `V_MONITOR_DQ_RUNS`
- `V_MONITOR_DQ_FAILURES`

These cover warehouse usage, expensive queries, pipeline executions, failures, freshness, DQ status, rows processed, and processing duration.

## Cost guardrails

DEV uses:
- `GFS_INGEST_WH`: XSMALL, auto-suspend 60 seconds
- `GFS_TRANSFORM_WH`: XSMALL, auto-suspend 60 seconds
- `GFS_ANALYTICS_WH`: XSMALL, auto-suspend 60 seconds
- resource monitor: `GFS_DEV_MONTHLY_RM`
- monthly credit quota: 10 credits
- notifications at 50% and 80%
- warehouse suspension at 100%

## Operational checks

Typical checks:

```sql
SELECT *
FROM GFS_DEV.CONTROL.V_MONITOR_TASK_RUNS
ORDER BY scheduled_time DESC
LIMIT 30;

SELECT *
FROM GFS_DEV.CONTROL.V_MONITOR_DQ_RUNS
ORDER BY started_at_utc DESC
LIMIT 10;

SELECT *
FROM GFS_DEV.CONTROL.V_MONITOR_DATA_FRESHNESS
ORDER BY dataset;

SELECT *
FROM GFS_DEV.CONTROL.V_MONITOR_QUERIES
ORDER BY total_elapsed_seconds DESC
LIMIT 20;
```

Account Usage metadata is not real-time, so operational dashboards should expect metadata latency.
