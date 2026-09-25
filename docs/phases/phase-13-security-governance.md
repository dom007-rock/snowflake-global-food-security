# Phase 13 - Security & Governance

## Status

**Complete**

## Role model

Human and service responsibilities are separated through dedicated roles:

- `GFS_PLATFORM_ADMIN`
- `GFS_DEVELOPER`
- `GFS_INGESTION_SVC`
- `GFS_TRANSFORM_SVC`
- `GFS_ANALYST`

`ACCOUNTADMIN` is reserved for administrative activities rather than normal pipeline execution.

## Least privilege

- Ingestion service can read RAW and call approved owner-rights CLEAN procedures.
- Ingestion service cannot directly modify CLEAN or analytical facts.
- Analyst can read CONSUMPTION and PUBLISH but cannot modify facts.
- Service roles and human roles remain distinct.

## Validation

Negative-access tests were executed to prove that unauthorized DML fails while intended SELECT/CALL operations succeed.

Future sensitive-data handling remains a documented governance consideration. The current project sources do not contain application PII.
