# Source-to-Target Data Flow

## 1. End-to-End Flow

```mermaid
sequenceDiagram
    participant S as Source API
    participant I as Python Ingestion
    participant D as Delta Lake on S3
    participant R as Snowflake RAW
    participant C as Snowflake CLEAN
    participant N as CONSUMPTION
    participant P as PUBLISH

    I->>S: Authenticate / request configured slice
    S-->>I: Source response pages
    I->>I: Preserve source fields + add technical lineage
    I->>I: Validate source contract and schema signature
    I->>D: Atomic Delta append for ingestion batch
    D-->>I: Delta commit version
    D->>R: Delta Direct refresh / metadata sync
    R->>C: Standardize and validate source records
    C->>C: Resolve current accepted source state
    C->>N: Apply governed analytical scope and conformance
    N->>P: Publish stable consumer-facing objects
```

## 2. Delta Table Roots

A Delta table owns its root directory. Run IDs are stored as columns, not as independent Delta roots.

Examples:

```text
s3://<bucket>/raw/faostat/qcl/
s3://<bucket>/raw/faostat/lc/
s3://<bucket>/raw/faostat/esb/
s3://<bucket>/raw/faostat/fbs/
s3://<bucket>/raw/faostat/gt/
s3://<bucket>/raw/faostat/fs/
s3://<bucket>/raw/world_bank/wdi_observations/
s3://<bucket>/raw/world_bank/wdi_indicator_metadata/
```

Annual observation tables use `year=YYYY` partitions. FS uses `reference_year=YYYY` while retaining the provider's original annual or multi-year period fields.

## 3. Ingestion Unit

The transactional ingestion unit is a source/domain/year batch where annual partitioning exists. Each batch receives:

```text
ingestion_run_id
ingestion_batch_id
source_system
source_domain
extracted_at_utc
contract_version
schema_signature
record_count
record_hash
```

A batch is appended to Delta once. If a retry occurs, the writer checks whether the same `ingestion_batch_id` is already committed before writing again.

## 4. Replay Boundary

Delta Lake on S3 is the replay boundary. Snowflake RAW can be reconstructed or refreshed from persisted Delta tables without another API call when the required source snapshot remains present.

Delta transaction history provides storage-level versioning. Run/batch metadata provides business and operational lineage across source refreshes.

## 5. Revision Flow

```mermaid
flowchart LR
    OLD[Previous snapshot] --> CMP[Compare source business key + observation attributes]
    NEW[New snapshot] --> CMP
    CMP --> I[Inserted]
    CMP --> U[Revised]
    CMP --> D[No longer returned]
    CMP --> S[Unchanged]
    I --> CUR[Current accepted CLEAN state]
    U --> CUR
    S --> CUR
    D --> AUD[Retained in RAW history / audit]
```

Cross-run identical observations are valid snapshots and are not transport duplicates.

## 6. Country Integration Flow

```mermaid
flowchart LR
    F[FAOSTAT country observation] --> ISO[Canonical ISO3]
    W[WDI country observation] --> ISO
    ISO --> X[Country crosswalk]
    X --> M[Matched country-level analytical data]
    X --> R[Review-required exceptions]
    A[Regions / aggregates / special groups] --> E[Excluded from country integration]
```

Automatic fuzzy matching on country names is prohibited.
