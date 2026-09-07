# Data Contracts v1

## 1. Scope

These contracts define boundaries between source APIs, Python ingestion, Delta Lake on S3, Snowflake RAW, CLEAN, CONSUMPTION, and PUBLISH. They are architecture contracts, not the final dimensional model.

## 2. Source Contract Families

### FAOSTAT standard annual family

Domains: QCL, LC, ESB, FBS.

Candidate source grain:

```text
area + item + element + year
```

### FAOSTAT GT

Historical candidate source grain:

```text
area + item + element + year + source
```

Projection metadata is retained in source metadata but v1 analytical facts remain capped at 2023.

### FAOSTAT FS

FS is multi-temporal. Returned item identity, disaggregation suffixes, and provider period identity are mandatory. Annual rows and multi-year periods must remain distinguishable.

### World Bank WDI

Candidate source grain:

```text
country_iso3 + indicator_code + year
```

Selected v1 indicators:

```text
SP.POP.TOTL
NY.GDP.MKTP.CD
NY.GDP.PCAP.CD
SP.RUR.TOTL.ZS
NV.AGR.TOTL.ZS
```

## 3. Delta RAW Contract

Each logical source dataset is persisted as one Delta table. A table root contains Parquet data files plus `_delta_log/`.

Required technical row metadata:

```text
_ingestion_run_id
_ingestion_batch_id
_extracted_at_utc
_source_system
_source_domain
_contract_version
_record_hash
```

Required run/batch control metadata:

```text
ingestion_run_id
ingestion_batch_id
source_system
source_domain
source_endpoint
request_parameters
started_at_utc
completed_at_utc
http_status
record_count
delta_table_path
delta_commit_version
schema_signature
contract_version
run_status
error_class
error_message
```

The ingestion layer preserves provider semantics. It does not perform business unit conversion, code remapping, source-status reinterpretation, analytical filtering, or cross-run deduplication.

## 4. RAW Type Strategy

RAW uses conservative Delta-compatible types. Source identifiers and codes are stored as strings. Provider numeric observations are stored without rounding; when safe typed parsing cannot be guaranteed, the source representation is retained as a string and cast in CLEAN.

Recommended RAW categories:

| Concept | Delta Type | Notes |
|---|---|---|
| source/domain/code fields | `string` | Supports alphanumeric codes and suffixes |
| country ISO3 | `string` | Source value retained |
| year/reference year | `int` | Storage partition where applicable |
| period labels | `string` | Required for FS |
| value | `string` or compatible decimal | No rounding in ingestion |
| unit | `string` | May be blank |
| flag/status | `string` | Provider semantics retained |
| timestamps | `timestamp` | UTC technical metadata |
| run/batch/hash identifiers | `string` | Technical lineage |

## 5. CLEAN Canonical Types

| Concept | Canonical Snowflake Type | Notes |
|---|---|---|
| source/domain/code fields | `VARCHAR` | Codes remain strings |
| country_iso3 | `VARCHAR(3)` | Canonical cross-source geography key |
| year/reference year | `NUMBER(4,0)` | Annual reference year |
| period_start_year | `NUMBER(4,0)` | Nullable |
| period_end_year | `NUMBER(4,0)` | Nullable |
| value_numeric | `NUMBER(38,10)` | Wider precision can be revisited if profiling requires |
| unit | `VARCHAR` | No silent unit inference |
| source flags/status | `VARCHAR` | Original provider semantics retained |
| ingestion timestamps | `TIMESTAMP_TZ` | UTC |
| run/batch/checksum identifiers | `VARCHAR` | Stable audit identifiers |

If a value cannot safely cast to the canonical type, the record remains available in RAW and receives a CLEAN quality failure rather than being silently coerced.

## 6. Naming Conventions

### S3 / Delta

Lowercase table roots:

```text
raw/faostat/qcl/
raw/faostat/lc/
raw/faostat/esb/
raw/faostat/fbs/
raw/faostat/gt/
raw/faostat/fs/
raw/world_bank/wdi_observations/
raw/world_bank/wdi_indicator_metadata/
```

Partition names:

```text
year=YYYY
reference_year=YYYY
```

### Snowflake

Uppercase unquoted identifiers:

```text
RAW.FAOSTAT_QCL
RAW.FAOSTAT_LC
RAW.FAOSTAT_ESB
RAW.FAOSTAT_FBS
RAW.FAOSTAT_GT
RAW.FAOSTAT_FS
RAW.WORLD_BANK_WDI_OBSERVATIONS
RAW.WORLD_BANK_WDI_INDICATORS
CONTROL.INGESTION_RUNS
CONTROL.INGESTION_BATCHES
CONTROL.SCHEMA_EVENTS
CONTROL.DATA_QUALITY_RESULTS
```

Python, configuration, and repository filenames use `snake_case`.

## 7. Retry Contract

Retry only transient failures:

- timeout and connection errors;
- HTTP 429;
- HTTP 5xx.

Default policy: maximum 4 attempts with exponential backoff and jitter. Non-retryable 4xx responses fail immediately. FAOSTAT authentication expiry may trigger one credential refresh followed by one replay of the failed request.

Retries reuse the same `ingestion_batch_id`; they never create a second logical batch for the same write attempt.

## 8. Duplicate and Idempotency Contract

- Every orchestration execution has a unique `ingestion_run_id`.
- Every atomic source/domain/year write has a unique `ingestion_batch_id`.
- Before appending, the writer checks whether the batch ID already exists in the Delta target or control state.
- Repeated observations across different successful runs are valid historical snapshots.
- Within a snapshot, CLEAN validates the source-specific business grain.
- Duplicate source business keys within one batch fail or quarantine that batch according to the domain contract.
- `record_hash` supports comparison and revision analysis but is not used to erase legitimate historical snapshots.

## 9. Schema Evolution Contract

Schema changes are classified as:

```text
ADDITIVE_OPTIONAL
REMOVED_OPTIONAL
REMOVED_REQUIRED
TYPE_CHANGE
CODELIST_CHANGE
UNKNOWN
```

Additive optional source fields may be merged into the Delta schema only after the schema event is logged. Missing optional fields are represented as null. Required-field removal or incompatible type change blocks the affected batch and downstream CLEAN publication.

Delta protocol/features are not automatically upgraded by the ingestion writer.

## 10. Refresh Frequency

```text
Scheduled: monthly
Backfill: on demand
Historical scope: configured 2010-2023 re-extraction supported
```

The scheduling technology remains a Phase 12 decision.

## 11. Publish Contract

PUBLISH objects are stable consumer interfaces. Breaking changes require explicit versioning or a migration window. Streamlit reads PUBLISH, never RAW.
