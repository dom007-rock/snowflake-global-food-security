# ADR-002: Snowflake orchestration with Streams and Tasks

## Status
Accepted

## Context
The platform ingests external API data into Delta Lake on S3, exposes it through Snowflake RAW Delta Direct/Iceberg tables, and then transforms it into Snowflake-managed CLEAN and CONSUMPTION layers.

The orchestration layer must support revisions, explicit control flow, restartability, data-quality gating, and clear operational auditing.

## Decision
Use the following orchestration pattern:

```text
API refresh
  -> Delta/S3
  -> RAW Delta Direct/Iceberg
  -> revision-safe MERGE into CLEAN
  -> Streams on CLEAN
  -> triggered Snowflake Task graph
  -> dimensions
  -> parallel fact tasks
  -> converged DQ gate
```

Dynamic Tables are not the primary orchestration mechanism for this version because the pipeline needs explicit external-ingestion handoff, revision-aware MERGEs, owner-rights procedures, task dependencies, retry behavior, and a blocking DQ gate.

## Task graph

```text
TASK_GFS_ROOT
    |
    v
TASK_REFRESH_DIMENSIONS
    |
    +-- TASK_QCL_TO_FACT_GRAPH
    +-- TASK_LC_TO_FACT
    +-- TASK_ESB_TO_FACT
    +-- TASK_FBS_TO_FACT
    +-- TASK_GT_TO_FACT
    +-- TASK_FS_TO_FACT
    +-- TASK_WDI_TO_FACT
              |
              v
        TASK_RUN_DQ_GATE
```

The root wakes when any CLEAN Stream contains data. Fact branches run after dimension refresh. The DQ task waits for all fact branches, creating a convergence barrier before a run is considered healthy.

## Consequences
Benefits:
- explicit dependency graph
- CDC-driven incremental processing
- independent fact branches
- visible retries/failures
- DQ can block a graph run
- clean separation between external ingestion and Snowflake transformation

Trade-offs:
- task graph SQL must be maintained explicitly
- Stream retention/staleness must be monitored
- source-system revisions require business-grain MERGE logic
