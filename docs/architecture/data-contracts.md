# Data Contracts v1

## 1. Scope

These contracts define the boundaries between source APIs, S3 landing, Snowflake RAW, CLEAN, CONSUMPTION, and PUBLISH. They are architecture contracts, not the final dimensional model.

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

2030 and 2050 projection metadata is retained in source history but excluded from v1 historical analytical facts.

### FAOSTAT FS

FS is multi-temporal. The returned item identity and period identity are mandatory. Annual rows and multi-year periods must remain distinguishable.

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

## 3. S3 File Contract

Required run-level metadata:

```text
ingestion_run_id
source_system
source_domain
source_endpoint
request_parameters
extracted_at_utc
landed_at_utc
s3_object_key
payload_checksum
http_status
record_count
contract_version
```

The source response content is immutable. New refreshes create new run paths rather than overwriting prior objects.

## 4. RAW Contract

RAW stores source fields with minimal interpretation and adds ingestion metadata. Optional provider fields may be absent. RAW must tolerate additive fields and missing optional fields without losing the source payload.

RAW does not:

- replace null with zero;
- round values;
- convert units;
- remove estimated, imputed, external, suppressed, or missing observations;
- collapse request codes into returned observation codes;
- merge source snapshots.

## 5. CLEAN Canonical Types

| Concept | Canonical Snowflake Type | Notes |
|---|---|---|
| source/domain/code fields | `VARCHAR` | Codes remain strings because alphanumeric variants exist |
| country_iso3 | `VARCHAR(3)` | Canonical cross-source geography key |
| year/reference year | `NUMBER(4,0)` | Annual reference year |
| period_start_year | `NUMBER(4,0)` | Nullable |
| period_end_year | `NUMBER(4,0)` | Nullable |
| value_numeric | `NUMBER(38,10)` | RAW source representation remains separately traceable |
| unit | `VARCHAR` | No silent unit inference in RAW |
| source flags/status | `VARCHAR` | Original provider semantics retained |
| ingestion timestamps | `TIMESTAMP_TZ` | Stored in UTC |
| run/checksum identifiers | `VARCHAR` | Stable audit identifiers |

If a source numeric value cannot safely cast to the canonical numeric type, the record is rejected from CLEAN and retained in RAW with a quality failure.

## 6. Naming Conventions

Snowflake object names use uppercase unquoted identifiers. Within layer schemas, table names identify source and subject without repeating the schema name. Examples:

```text
RAW.FAOSTAT_QCL_OBSERVATIONS
RAW.WORLD_BANK_WDI_OBSERVATIONS
RAW.WORLD_BANK_WDI_INDICATORS
CONTROL.INGESTION_RUNS
CONTROL.FILE_LOAD_AUDIT
```

Python, configuration, and local file names use `snake_case`. S3 prefixes use lowercase source names and provider domain codes where applicable.

## 7. Retry Contract

HTTP requests retry transient failures only:

- timeout / connection errors;
- HTTP 429;
- HTTP 5xx.

Default policy: up to 4 attempts with exponential backoff and jitter. Non-retryable 4xx responses fail the request. For FAOSTAT authentication expiry, the production client may refresh credentials once and replay the request.

Retries must not create duplicate landed objects inside the same run.

## 8. Duplicate and Idempotency Contract

- Every extraction has a unique `ingestion_run_id`.
- S3 paths are run-specific and immutable.
- Snowflake file-load auditing prevents the same S3 object from being loaded twice.
- Repeated observations across different runs are valid source snapshots, not duplicates.
- Within a snapshot, CLEAN validates the source-specific business grain.
- Any duplicate business key inside one snapshot is quarantined or failed according to the domain contract.

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

RAW landing continues for additive optional fields. Contract-breaking removals or type changes block downstream CLEAN publication until reviewed. All observed schema signatures are logged in CONTROL metadata.

## 10. Refresh Frequency

Expected v1 cadence:

```text
Scheduled: monthly
Backfill: on demand
Historical scope: configured 2010-2023 re-extraction supported
```

The exact scheduling technology is selected in Phase 12.

## 11. Publish Contract

PUBLISH objects are stable consumer interfaces. Breaking changes require explicit contract versioning or a migration window. Streamlit reads PUBLISH, not RAW.
