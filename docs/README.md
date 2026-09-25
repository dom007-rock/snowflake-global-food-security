# Documentation Index

## Global Food Security & Nutrition Intelligence Platform

This documentation tree captures the project through **Phase 15: Consumption & Streamlit**.

## Phase status

| Phase | Status |
|---|---|
| 0 - Project Definition | Complete |
| 1 - Local Development & Git Setup | Complete |
| 2 - Data Discovery & Source Profiling | Complete |
| 3 - Architecture & Data Contracts | Complete |
| 4 - Snowflake Platform Foundation | Complete |
| 5 - AWS Landing Zone | Complete |
| 6 - Source Ingestion | Complete |
| 7 - RAW / Landing Layer | Complete |
| 8 - CLEAN / Standardization | Complete |
| 9 - World Bank Enrichment | Complete |
| 10 - Dimensional Modeling | Complete |
| 11 - Data Quality Framework | Complete |
| 12 - Transformation & Orchestration | Complete |
| 13 - Security & Governance | Complete |
| 14 - Monitoring & Cost Management | Complete |
| 15 - Consumption & Streamlit | Complete |
| 16 - CI/CD | Not started |
| 17 - Production Failure Drills | Not started |
| 18 - Final Production Review | Not started |

## Main documentation areas

- `requirements/` - project charter and scope
- `source-analysis/` - FAOSTAT and World Bank source profiling/contracts
- `architecture/` - architecture, data flow, storage and CLEAN contracts
- `adr/` and `decisions/` - architectural and implementation decisions
- `data-model/` - dimensional model
- `data-quality/` - framework, test catalog and enrichment DQ
- `runbooks/` - ingestion, Delta Direct, enrichment, reconciliation and incident guidance
- `phases/` - phase-specific implementation records
- `phase-status/` - checkpoint summaries
- `transformation-rules/` - location for cross-domain transformation specifications

## Current architecture

```text
FAOSTAT / World Bank
        -> Python ingestion
        -> Delta Lake on Amazon S3
        -> Snowflake RAW (read-only Delta Direct)
        -> CLEAN
        -> Streams / Tasks
        -> CONSUMPTION dimensional warehouse
        -> PUBLISH semantic views
        -> gfs_queries.py
        -> Streamlit
```

See `PROJECT_STATUS.md` for the current checkpoint and `architecture/architecture-v2.md` for the latest architecture summary.
