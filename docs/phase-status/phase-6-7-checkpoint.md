# Phase 6–7 Checkpoint

## Phase 6: Source Ingestion

**Status: Complete**

### Checklist interpretation

The project requires a rerunnable FAOSTAT-to-S3 ingestion path with pagination, HTTP error handling, retry/timeout behavior, request metadata, run IDs, timestamps, source preservation, idempotency, counts, partial-failure testing, and rerun testing.

The final implementation satisfies this through two complementary paths:

1. **Historical bootstrap** using official normalized FAOSTAT bulk files.
2. **Recurring refresh** using the authenticated FAOSTAT API pipeline.

### Evidence

- API pagination exercised and benchmarked.
- HTTP retries/timeouts implemented.
- Run and batch identifiers captured.
- Extraction timestamps captured.
- Source observations preserved in `source_payload`.
- Row and snapshot hashes implemented.
- Exact-repeat idempotency tested.
- Partial failure tested.
- Historical revision strategy documented.
- Bulk bootstrap loaded 7,148,113 rows.
- Reconciliation script passed all six domains.

## Phase 7: RAW / Landing Layer

**Status: Complete**

### Adaptation from original checklist

The original checklist assumed staged file loads into Snowflake. The implemented architecture instead uses Delta Lake on S3 and Snowflake Delta Direct.

Therefore:

- file format objects and `COPY INTO` are not used for FAOSTAT RAW;
- Snowflake reads the existing Delta tables directly;
- RAW is externally managed and read-only.

### RAW tables

| Domain | RAW rows |
|---|---:|
| QCL | 1,005,808 |
| LC | 119,230 |
| ESB | 194,244 |
| FBS | 4,820,497 |
| GT | 820,429 |
| FS | 187,905 |
| **Total** | **7,148,113** |

### Requirements satisfied

- RAW tables created for all six domains.
- Original source attributes preserved inside `source_payload`.
- Source filename retained inside request/bootstrap metadata.
- Ingestion timestamp retained.
- Run ID retained.
- Source-system and source-domain metadata retained.
- Duplicate Snowflake loads prevented by read-only Delta Direct architecture.
- Upstream ingestion idempotency controls duplicate source snapshots.
- `RAW_LOAD_AUDIT` created in CONTROL.
- Source/Delta/RAW counts reconciled successfully.

## Operational incidents captured

### 1. API performance

A single QCL year required 203 API pages. Historical bootstrap moved to bulk files to reduce project bootstrap time.

### 2. Diagnostic overlap

A one-row diagnostic request overlapped a full-year QCL extraction. Delta history was used to restore the known-good active state. Diagnostics must use isolated locations.

### 3. DynamoDB locking retirement

Current delta-rs no longer supports the historical S3 DynamoDB log store. S3 conditional writes are now used.

### 4. Snowflake STS region issue

Snowflake Delta Direct initially failed to assume the AWS role even though trust configuration was correct. Root cause: the Snowflake deployment region (`ap-southeast-7`) was an opt-in AWS region not yet enabled in the project AWS account. Enabling the region/STS resolved the issue.

## Next phase

**Phase 8: CLEAN / Standardization**

Primary work:

- parse `source_payload`;
- normalize source column names;
- standardize country and indicator identifiers;
- standardize dates/periods and units;
- define business keys;
- handle nulls, flags, duplicates, and malformed rows;
- create rejected-record handling where appropriate;
- retain source lineage back to RAW.
