# Delta Storage Contract

## Table roots

Each logical source dataset owns one Delta table root.

```text
delta/
  faostat/
    qcl/
    lc/
    esb/
    fbs/
    gt/
    fs/
  world_bank/
    wdi_observations/
    wdi_indicator_metadata/
    wdi_entity_metadata/
  reference/
    un_m49/
```

A Delta table is **Parquet data files plus `_delta_log` transaction metadata**.

## Landing-layer contract

Common technical metadata includes, where applicable:

| Column | Purpose |
|---|---|
| `source_payload` | Canonical JSON representation of source record |
| `_source_system` | Source system identifier |
| `_source_domain` | Logical source dataset/domain |
| `_ingestion_run_id` | Unique execution identifier |
| `_ingestion_batch_id` | Logical batch/snapshot identifier |
| `_extracted_at_utc` | Extraction timestamp |
| `_source_row_hash` | SHA-256 source-row fingerprint |
| `_request_parameters` | Request/bootstrap context where relevant |

FAOSTAT additionally retains request year/page metadata for the bulk/API ingestion contract.

## Source preservation

The landing layer performs no analytical typing or business interpretation. Source field names and values remain inside `source_payload`; technical metadata is additive.

## Idempotency and revision handling

- Exact repeat snapshots are identifiable through row/snapshot hashes.
- Historical source revisions create changed hashes rather than being silently ignored.
- Initial bulk bootstrap may overwrite the active DEV Delta baseline.
- Recurring refresh logic must not assume history is append-only.

## S3 write coordination

Current `deltalake` / delta-rs uses S3 conditional write semantics. The earlier DynamoDB log-store design is retired.

## FAOSTAT bootstrap baseline

| Domain | Rows | Active files |
|---|---:|---:|
| QCL | 1,005,808 | 308 |
| LC | 119,230 | 28 |
| ESB | 194,244 | 70 |
| FBS | 4,820,497 | 350 |
| GT | 820,429 | 182 |
| FS | 187,905 | 52 |
| **Total** | **7,148,113** | **990** |

Compaction is deferred until query behavior shows a measurable need.
