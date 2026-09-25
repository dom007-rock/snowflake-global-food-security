# Architecture and Data Flow

## Current architecture through Phase 11

```mermaid
flowchart LR
    A[FAOSTAT bulk files\nHistorical bootstrap] --> B[Python ingestion]
    A2[FAOSTAT API\nFuture revision refresh] --> B
    W[World Bank WDI API] --> B
    U[UN M49 reference] --> B

    B --> S3[AWS S3 Delta Lake\nParquet + _delta_log]

    S3 --> EV[Snowflake External Volume]
    EV --> CI[Delta Catalog Integration]
    CI --> RAW[RAW\nRead-only Delta/Iceberg tables]

    RAW --> CLEAN[CLEAN\nTyped and standardized datasets]
    CLEAN --> CTRL[CONTROL\nCrosswalks, rejects, audits]

    CLEAN --> DIM[CONSUMPTION Dimensions]
    CTRL --> DIM
    CLEAN --> FACT[CONSUMPTION Facts]
    DIM --> FACT

    FACT --> DQ[Data Quality Framework]
    CTRL --> DQ
    DQ --> GATE[CONTROL.V_DQ_RUN_GATE]

    GATE --> PUBLISH[PUBLISH / analytical views\nFuture phase]
    PUBLISH --> ST[Streamlit\nPhase 15]
```

## Storage roots

```text
delta/
  faostat/qcl/
  faostat/lc/
  faostat/esb/
  faostat/fbs/
  faostat/gt/
  faostat/fs/
  world_bank/wdi_observations/
  world_bank/wdi_indicator_metadata/
  world_bank/wdi_entity_metadata/
  reference/un_m49/
```

## Layer responsibilities

### RAW

Read-only exposure of landed Delta data. Source fidelity is prioritized over convenience.

### CLEAN

Typed, standardized, source-aware datasets with controlled reject handling and lineage.

### CONTROL

Operational and governance objects such as geography crosswalks, rejected records, audit structures, DQ run history, detailed DQ results, and the pipeline quality gate.

### CONSUMPTION

Dimensional facts and dimensions designed for analytical joins and future dashboard/view development.

### Data Quality

A persisted validation layer checks structural integrity, analytical scope, source-target reconciliation, and selected business-semantic rules. Results are summarized into a pipeline gate for Phase 12 orchestration.

### PUBLISH

Reserved for curated analytical views and dashboard-facing datasets in later phases.
