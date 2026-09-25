# Phase 12 - Transformation & Orchestration

## Status

**Complete**

## Implemented design

- Snowflake Streams are placed on persistent CLEAN tables, not on S3 or RAW external data.
- `TASK_GFS_ROOT` acts as the root of the task graph and is triggered when one or more CLEAN streams contain changes.
- `TASK_REFRESH_DIMENSIONS` refreshes conformed dimensions before fact processing.
- Seven fact tasks then fan out for QCL, LC, ESB, FBS, GT, FS and WDI.
- `TASK_RUN_DQ_GATE` executes after fact processing and converges the graph through the production DQ gate.

## Data quality gate

The pipeline DQ suite contains **23 checks**. ERROR-severity failures stop the task graph.

QCL reconciliation explicitly separates reviewed historical entities from eligible analytical geography. Historical predecessor entities are classified as:

- `AREA_TYPE = HISTORICAL_ENTITY`
- `MAPPING_STATUS = NOT_APPLICABLE`
- `MAPPING_METHOD = REVIEWED_HISTORICAL_ENTITY`

Validated QCL analytical fact count: **1,131,596** rows with **0 duplicate fact grains**.

## Restartability and idempotency

- `run_id` identifies an execution attempt.
- `batch_id` identifies the deterministic logical source snapshot.
- Repeated delivery of the same logical batch is safely recognized.
- CLEAN merge procedures are batch-aware.
- Hash-gated updates prevent unchanged source rows from generating unnecessary downstream stream activity.

The QCL refresh path was tested by rerunning the same logical batch and validating that downstream state remained correct.

## Dynamic Tables decision

Dynamic Tables were evaluated but not selected as the primary orchestration mechanism because this pipeline requires explicit external-ingestion handoff, revision-aware merges, auditability, restartability and a converged DQ gate.
