# Phase 13 - Security & Governance

## Role model

```text
SYSADMIN
   ^
GFS_PLATFORM_ADMIN
   +-- inherits GFS_DEVELOPER
   |      +-- inherits GFS_ANALYST
   +-- inherits GFS_INGESTION_SVC
   +-- inherits GFS_TRANSFORM_SVC
```

## Access intent

### GFS_INGESTION_SVC
Allowed:
- use `GFS_INGEST_WH`
- use GFS_DEV / RAW / CONTROL
- read QCL RAW data required for visibility checks
- call `CONTROL.SP_MERGE_QCL_CLEAN(VARCHAR)`

Blocked:
- direct DML on CLEAN
- direct fact-table mutation

The CLEAN procedure runs `EXECUTE AS OWNER`, allowing controlled transformation without broad CLEAN privileges.

### GFS_ANALYST
Allowed:
- use `GFS_ANALYTICS_WH`
- read CONSUMPTION tables
- read PUBLISH views

Blocked:
- fact-table DML

### Administrative roles
`ACCOUNTADMIN` is used only for administrative setup that requires account-level privileges. Day-to-day project administration uses `GFS_PLATFORM_ADMIN`.

## Validation
The following negative tests were executed successfully:
- ingestion service RAW SELECT: allowed
- ingestion service CLEAN UPDATE: blocked
- ingestion service stored-procedure CALL: allowed
- analyst FACT SELECT: allowed
- analyst FACT UPDATE: blocked
