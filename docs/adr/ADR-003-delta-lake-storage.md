# ADR-003: Delta Lake Landing and Snowflake Delta Direct

## Status

Accepted.

## Context

The original Architecture v1 assumed immutable source-response files in S3 followed by a Snowflake external stage and RAW load. During Phase 3 review, the project selected Delta Lake as the first persistent landing representation to provide transactional writes, Parquet storage, schema metadata, table version history, and stronger interoperability.

The source systems remain revision-capable and the project still requires source fidelity, replayability, idempotent retries, and historical lineage.

## Decision

1. Python extracts FAOSTAT and World Bank API data and writes directly to Delta Lake tables on Amazon S3.
2. Parquet is the physical data-file format and Delta `_delta_log` metadata defines the table state.
3. One Delta table root is used per logical source dataset.
4. Annual datasets are partitioned by four-digit `year`; FS uses `reference_year`; metadata tables remain unpartitioned unless profiling later justifies otherwise.
5. Run and batch IDs are stored as columns rather than creating a separate Delta table root per ingestion execution.
6. Python performs source-preserving serialization plus technical lineage only. Business transformations begin in CLEAN.
7. Snowflake accesses Delta tables through an External Volume and a catalog integration configured for object storage with Delta table format, then exposes them through Delta Direct in the RAW schema.
8. RAW Delta Direct tables are read-only in Snowflake. CLEAN and downstream layers are Snowflake-managed.
9. The project uses a conservative Delta feature set compatible with Snowflake Delta Direct.
10. Historical source snapshots are preserved through run/batch lineage; CLEAN resolves the accepted current source state.

## Rationale

This approach removes an unnecessary intermediate serialization layer, gives the S3 landing zone transactional table semantics, retains efficient columnar Parquet storage, and keeps Snowflake focused on standardization and analytics rather than raw JSON parsing.

## Consequences

### Positive

- transactional ingestion commits;
- efficient compressed columnar storage;
- explicit table schema and version history;
- stronger retry/idempotency design;
- direct Snowflake interoperability through Delta Direct;
- simpler replay from S3.

### Trade-offs

- the literal HTTP wire payload is not retained as the v1 system of record;
- ingestion must enforce source-fidelity rules carefully;
- Delta compatibility with Snowflake becomes an explicit operational constraint;
- RAW Delta Direct tables are read-only in Snowflake;
- partitioned Delta Direct RAW tables cannot be the basis for a Streams-dependent orchestration design.

## Supersedes

This ADR supersedes the storage-access portions of ADR-002 that specified immutable run-specific source files plus Snowflake external-stage loading. The broader layered architecture in ADR-002 remains valid.
