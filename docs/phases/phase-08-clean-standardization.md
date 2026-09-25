# Phase 8 - CLEAN / Standardization Layer

## Status

Complete.

## Objective

Convert read-only RAW Delta/Iceberg data into trusted, typed, semantically consistent Snowflake CLEAN datasets while preserving source identity and lineage.

## Standardized domains

- `CLEAN.FAOSTAT_QCL` - crops and livestock products
- `CLEAN.FAOSTAT_LC` - land cover
- `CLEAN.FAOSTAT_ESB` - cropland nutrient balance
- `CLEAN.FAOSTAT_FBS` - food balances
- `CLEAN.FAOSTAT_GT` - emissions totals
- `CLEAN.FAOSTAT_FS` - food security indicators

## Core design rules

### Common FAOSTAT grain

For QCL, LC, ESB, and FBS:

`Area x Item x Element x Year`

For GT:

`Area x Item x Element x Source x Year`

For FS:

`Area x Indicator x Element x Period`

### Identifiers

Source codes remain strings. M49 values are normalized as zero-padded strings rather than converted to numeric values.

Standard geography fields include:

- `area_code_fao`
- `area_code_m49`
- `area_name`

`country_iso3` is not fabricated in the CLEAN layer. ISO3 enrichment is handled through governed reference data and the geography crosswalk.

### Food-security periods

FAOSTAT FS contains annual and multi-year reporting periods. CLEAN preserves:

- `period_code`
- `period_label`
- `period_start_year`
- `period_end_year`
- `period_type`

`period_type` distinguishes `ANNUAL` and `MULTI_YEAR` observations.

### Food-security values

FS preserves both:

- `value_raw` for the original source representation
- `value` for numeric use where conversion is valid

This avoids discarding source meaning when a value is not a simple numeric observation.

### Emissions source

GT preserves the observation-level source attributes:

- `source_code`
- `source_name`

These attributes are part of the GT business grain.

## Lineage

CLEAN datasets retain operational lineage including:

- `source_row_hash`
- `ingestion_run_id`
- `ingestion_batch_id`
- `extracted_at_utc`
- `cleaned_at_utc`

## Reject handling

Malformed or contract-breaking source records are separated into:

`CONTROL.FAOSTAT_CLEAN_REJECTS`

The reconciliation rule is:

`RAW = CLEAN + REJECTS`

## Phase 8 validation

The completed validation covered:

- RAW-to-CLEAN reconciliation
- required fields
- duplicate business grain
- year scope of 2010-2023
- M49 formatting
- lineage completeness
- rejected-record reconciliation

All six FAOSTAT domains passed the final Phase 8 validation gate.
