# Delta Lake Storage Contract

## 1. Decision

The first persistent landing representation is Delta Lake on Amazon S3. Python converts source API records directly into Delta tables. Parquet is the physical data-file format and `_delta_log` is the transaction-log directory.

No intermediate JSON landing tier is required in v1.

## 2. Source Fidelity Boundary

The ingestion process may:

- deserialize API responses;
- preserve source fields and nulls;
- serialize compatible values to Delta/Parquet;
- add technical lineage fields;
- add a storage partition field where needed.

The ingestion process must not:

- rename source concepts for business convenience;
- round or aggregate values;
- replace nulls with zero;
- standardize units;
- collapse FAOSTAT request and returned codes;
- remove estimated, imputed, external, missing, or suppressed rows;
- fuzzy-match countries;
- deduplicate observations across source snapshots.

## 3. Table Roots and Partitions

| Dataset | Delta root | Partition |
|---|---|---|
| FAOSTAT QCL | `raw/faostat/qcl/` | `year` |
| FAOSTAT LC | `raw/faostat/lc/` | `year` |
| FAOSTAT ESB | `raw/faostat/esb/` | `year` |
| FAOSTAT FBS | `raw/faostat/fbs/` | `year` |
| FAOSTAT GT | `raw/faostat/gt/` | `year` |
| FAOSTAT FS | `raw/faostat/fs/` | `reference_year` |
| WDI observations | `raw/world_bank/wdi_observations/` | `year` |
| WDI indicator metadata | `raw/world_bank/wdi_indicator_metadata/` | none |

Partitioning is intentionally low-cardinality. `ingestion_run_id` and `ingestion_batch_id` are columns, not partition directories.

## 4. Delta Write Semantics

Annual observation ingestion writes one source/domain/year batch at a time. Each batch is appended atomically to the target Delta table.

The write order is:

```text
extract -> validate contract -> build batch -> idempotency check -> Delta append -> capture Delta version -> mark batch successful
```

A failed or interrupted batch is retried with the same batch ID. If the Delta append already committed, retry logic detects the committed batch and avoids a second append.

## 5. Snowflake Consumption

Snowflake accesses the Delta table using Delta Direct:

```text
Amazon S3 Delta table
    -> External Volume
    -> Catalog Integration (OBJECT_STORE, DELTA)
    -> Snowflake Iceberg table over Delta files
    -> RAW schema
```

RAW Delta Direct tables are treated as read-only source interfaces. Transformations write to Snowflake-managed CLEAN and downstream objects.

## 6. Compatibility Guardrails

The project avoids Delta features not supported by the selected Snowflake path. In v1:

- no deletion vectors;
- no row tracking;
- no Delta CDC/change-data files;
- no unsupported protocol evolution;
- decimal precision <= 38;
- no unsupported field-ID or interval representations;
- no dependency on Streams over partitioned Delta Direct RAW tables.

Compatibility is revalidated before implementation in Phases 5-7.
