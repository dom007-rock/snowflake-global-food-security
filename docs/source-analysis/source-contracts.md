# Source Contract Baseline

## 1. Purpose

This document records source-level rules discovered during Phase 2. It is the handoff into Phase 3, where physical ingestion and Snowflake data contracts will be finalized.

These rules are source contracts, not final warehouse table definitions.

## 2. Contract Principles

### Source fidelity first

RAW ingestion preserves what the provider returned. Business interpretation happens downstream.

### Null is not zero

Null observations remain null unless a documented transformation explicitly creates a derived value.

### Provenance travels with the value

A numeric value without its flag, source, status, or indicator metadata may be analytically misleading. Provenance fields remain attached through curated layers.

### Request identity and observation identity are different concepts

FAOSTAT request codes can differ from returned observation codes. Both must remain traceable.

### Historical data can change

Neither FAOSTAT nor World Bank history is treated as immutable. Incremental design must support revisions.

### Historical refreshes are snapshot-based

Scheduled refreshes may re-extract previously loaded years. Each source run is retained as an immutable snapshot, while CLEAN identifies the currently accepted observation state. Cross-run repetition is therefore valid source history rather than a duplicate error.

## 3. FAOSTAT Contract Baseline

### Standard annual domains

QCL, LC, ESB, and FBS share the baseline observation shape:

```text
area + item + element + year
```

This is a candidate grain subject to production-scale validation.

### GT

GT adds source to historical observation identity:

```text
area + item + element + year + source
```

2030 and 2050 projection metadata is excluded from v1 historical analytical facts.

### FS

FS cannot be reduced to one ordinary annual grain.

The contract must preserve:

- returned item code;
- returned item label;
- annual vs multi-year period identity;
- period label and start/end years where derivable;
- source flag and flag description;
- null and suppressed states.

### FAOSTAT minimum raw fields

Where present in the response:

```text
domain_code
domain
area_code
area
element_code
element
item_code
item
time_code
time_label
source_code
source
unit
value
flag
flag_description
note
```

Physical field names will reflect the exact source payload in RAW. The normalized names above are conceptual.

## 4. World Bank Contract Baseline

Observation candidate grain:

```text
country_code + indicator_code + year
```

Minimum raw observation fields:

```text
country_code
country
indicator_code
indicator
year
value
unit
obs_status
decimal
```

Minimum indicator-metadata fields:

```text
indicator_code
indicator_name
unit
source_id
source_name
source_note
source_organization
topics
```

## 5. Normalized Value Status

CLEAN may derive a cross-source `value_status` for analytical consistency.

Potential categories include:

```text
AVAILABLE
OFFICIAL
ESTIMATED
IMPUTED
EXTERNAL_SOURCE
MISSING
MISSING_UNSPECIFIED
MISSING_SUPPRESSED
```

The derived status must always coexist with the original source flag/status.

## 6. Geography Rules

- Integrated consumption models target country-level analysis.
- `country_iso3` is the canonical cross-source geographic key.
- FAOSTAT regions and special groups must not be mixed with countries in country-level facts.
- World Bank regional, income-group, and other aggregate entities must be excluded from country-level facts.
- Country matching uses exact ISO3 first, followed only by governed manual overrides.
- Automatic fuzzy matching on country names is prohibited.
- The physical country crosswalk is implemented during Phase 9 and must retain source-specific identifiers and match status.
## 7. Time Rules

- Integrated historical scope is 2010-2023.
- Standard FAOSTAT domains use annual years.
- GT projections are not historical facts.
- FS period semantics must remain explicit.
- World Bank observations are annual for the selected indicators.

## 8. Unit Rules

- Unit is part of observation semantics.
- Values with different units must not be aggregated together without explicit conversion logic.
- Empty source units remain empty in RAW.
- Derived display units belong in governed downstream metadata, not silent RAW enrichment.

## 9. Schema Evolution

Production ingestion must tolerate:

- optional columns appearing or disappearing;
- additive source fields;
- null optional fields;
- code-list changes;
- historical revisions.

Schema drift should be detected and logged rather than silently ignored.

## 10. Production Metadata

Every landed source object should be traceable using fields such as:

```text
ingestion_run_id
source_system
source_endpoint
request_parameters
extracted_at_utc
landed_at_utc
s3_object_key
payload_checksum
http_status
record_count
```

The final physical implementation is defined in Phase 3 and Phase 6.
