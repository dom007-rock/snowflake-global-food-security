# Project Status

## Global Food Security & Nutrition Intelligence Platform

### Current Status

| Phase | Status | Notes |
|---|---|---|
| 0-11 | Complete | Foundation, ingestion, Snowflake architecture, CLEAN and dimensional layers completed earlier |
| 12 | Complete | Streams, tasks, orchestration, DQ gate, restartability and QCL catch-up logic validated |
| 13 | Complete | RBAC and negative privilege tests validated |
| 14 | Complete | Monitoring, resource monitor, freshness and operational views completed |
| 15 | Complete | PUBLISH semantic layer and Streamlit application completed and functionally tested |
| 16 | Not started | CI/CD |
| 17 | Not started | Production failure drills |
| 18 | Not started | Final production review and documentation audit |

## Phase 12 Highlights

- CLEAN tables are the stream boundary.
- Root task triggers from CLEAN streams.
- Dimensions refresh before fact task fan-out.
- Seven fact tasks feed the DQ gate.
- DQ suite contains 23 checks.
- QCL reviewed historical entities are classified as `NOT_APPLICABLE` / `HISTORICAL_ENTITY`.
- QCL fact count validated at 1,131,596 rows with zero duplicate fact grains.
- Repeated deterministic refreshes are restartable and idempotent by `batch_id`.

## Phase 13 Highlights

- Human and service roles separated.
- Ingestion service can read RAW and call owner-rights CLEAN procedures but cannot directly modify CLEAN or facts.
- Analyst can read CONSUMPTION/PUBLISH but cannot modify facts.
- Negative privilege tests passed.

## Phase 14 Highlights

- 10-credit monthly DEV resource monitor.
- X-Small warehouses with 60-second auto-suspend.
- Monitoring views for warehouse credits, queries, tasks, freshness and DQ runs/failures.

## Phase 15 Highlights

- Business-readable PUBLISH semantic views created.
- Country-year WDI layer created.
- FAOSTAT + WDI integrated intelligence layer created.
- Country-level KPI coverage validated from actual source data.
- Streamlit application implemented and tested locally.
- Overview KPIs update correctly when country selection changes.
- Food Security, Country Comparison, Agriculture and Aggregate tabs are operational.

## Important Remaining Work

Before the Snowflake environment expires, prioritize any work that requires a live Snowflake account, especially Phase 17 failure drills and final DDL / evidence capture.

Phase 18 should perform the final documentation audit, including README consistency, architecture diagrams, screenshots, deployment instructions and technical-debt notes.
