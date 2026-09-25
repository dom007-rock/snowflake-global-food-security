# ADR-003: Delta Lake Storage and Snowflake Delta Direct

- **Status:** Accepted
- **Scope:** FAOSTAT and future source landing on AWS S3

## Context

The platform requires:

- source-preserving historical storage;
- revision-aware ingestion;
- transactional writes to object storage;
- efficient Snowflake access without duplicating the full RAW dataset into native Snowflake storage;
- support for an initial historical bootstrap and later incremental refreshes.

The initial design considered raw JSON/CSV files plus Snowflake stages and `COPY INTO`. The project later selected Delta Lake as the landing table format.

## Decision

Use **Delta Lake on Amazon S3** as the physical landing layer and expose these tables to Snowflake through **Delta Direct**.

Snowflake configuration uses:

- an external volume;
- a catalog integration with `CATALOG_SOURCE = OBJECT_STORE` and `TABLE_FORMAT = DELTA`;
- `CREATE ICEBERG TABLE ... BASE_LOCATION = ... AUTO_REFRESH = TRUE` for RAW tables.

The Snowflake RAW tables are read-only representations of the externally managed Delta tables.

## Historical bootstrap decision

Use official normalized FAOSTAT bulk CSVs for the initial 2010–2023 bootstrap.

Reason: a single QCL year required 203 API pages for 202,520 observations and several minutes even with concurrent HTTP reads. Bulk bootstrap loaded all six project domains, 7,148,113 rows, in roughly six minutes.

The API ingestion code remains the refresh mechanism and retains retry, timeout, pagination, revision, hash, and idempotency logic.

## Consequences

### Positive

- One durable S3 source of truth.
- Delta transaction history and recovery capabilities.
- Snowflake RAW remains read-only and cannot accidentally duplicate data through `INSERT`/`COPY` operations.
- Historical bootstrap is fast.
- API refresh code remains available for revision-aware recurring ingestion.
- Snowflake can automatically discover Delta changes through Delta Direct refresh.

### Trade-offs

- Delta Direct is represented in Snowflake through Iceberg-table interfaces, which can be conceptually confusing.
- Externally managed RAW limits write operations from Snowflake.
- Initial bootstrap can create many relatively small Parquet files; compaction may be required later.
- Cross-region AWS/Snowflake setup requires correct STS configuration in the Snowflake deployment region.

## Superseded decision: DynamoDB locking

An earlier implementation configured delta-rs with a DynamoDB log store. Current delta-rs no longer supports this integration and uses S3 conditional writes by default. DynamoDB locking is therefore retired from the architecture.

## References

- Snowflake: Delta Direct / create Iceberg table from Delta files: https://docs.snowflake.com/en/user-guide/tables-iceberg-create
- Snowflake: object-storage catalog integration: https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-catalog-integration-object-storage
- delta-rs S3 behavior: https://github.com/delta-io/delta-rs/blob/main/python/docs/source/usage.rst
