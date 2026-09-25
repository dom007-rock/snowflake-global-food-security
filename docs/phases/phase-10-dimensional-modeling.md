# Phase 10 - Dimensional Modeling

## Status

Complete.

## Objective

Create a consumption-layer dimensional model that converts standardized FAOSTAT and World Bank datasets into query-friendly analytical facts and dimensions while preserving source lineage and business grain.

## Modeling principles

- Preserve each source domain's true business grain.
- Use surrogate keys for reusable entity dimensions.
- Keep source-domain identity where codes are not proven globally conformed.
- Do not force multi-year food-security observations into an annual date grain.
- Keep World Bank enrichment inside the FAOSTAT analytical geography scope for the integrated consumption layer.
- Maintain idempotent dimension and fact loads using `MERGE`.
- Preserve `source_row_hash` in facts for source traceability and rerun safety.

## Dimensions

### `DIM_GEOGRAPHY`

Grain: one canonical FAOSTAT analytical geography per `area_code_fao`.

The dimension supports both countries and FAOSTAT aggregates. It replaces the need for separate country and geography dimensions in v1.

Important fields include:

- `geography_key`
- `area_code_fao`
- `area_code_m49`
- `country_iso3`
- `geography_name`
- `faostat_area_name`
- `world_bank_name`
- `area_type`
- `mapping_status`
- `mapping_method`
- `is_wdi_mapped`
- `is_aggregate`

SCD strategy: Type 1.

Surrogate key strategy: Snowflake sequence.

### `DIM_DATE`

Grain: one analytical year.

Scope: 2010-2023.

`date_key` is deterministic and equals the year value.

### `DIM_PERIOD`

Grain: one distinct FAOSTAT FS reporting period.

It preserves annual and multi-year reporting windows using:

- `period_code`
- `period_label`
- `period_start_year`
- `period_end_year`
- `period_type`
- `duration_years`

### `DIM_ITEM`

Grain: `source_domain + item_code`.

Profiling found no cross-domain code collisions but also no evidence that item codes are globally shared across domains. The domain therefore remains part of the business identity.

### `DIM_ELEMENT`

Grain: `source_domain + element_code`.

The same domain-aware decision used for items is applied to elements.

### `DIM_INDICATOR`

Grain: `source_system + source_domain + indicator_code`.

The dimension contains both FAOSTAT FS and World Bank WDI indicators while preserving their independent code namespaces.

### `DIM_SOURCE`

Grain: `source_domain + source_code`.

Currently populated from FAOSTAT GT observation-level source/method values.

## Facts

### `FACT_CROPS_LIVESTOCK`

Source: `CLEAN.FAOSTAT_QCL`

Grain:

`Geography x Item x Element x Year`

### `FACT_LAND_COVER`

Source: `CLEAN.FAOSTAT_LC`

Grain:

`Geography x Item x Element x Year`

### `FACT_NUTRIENT_BALANCE`

Source: `CLEAN.FAOSTAT_ESB`

Grain:

`Geography x Item x Element x Year`

### `FACT_FOOD_BALANCE`

Source: `CLEAN.FAOSTAT_FBS`

Grain:

`Geography x Item x Element x Year`

### `FACT_EMISSIONS`

Source: `CLEAN.FAOSTAT_GT`

Grain:

`Geography x Item x Element x Source x Year`

The additional `source_key` is required because GT source is part of the business grain.

### `FACT_FOOD_SECURITY`

Source: `CLEAN.FAOSTAT_FS`

Grain:

`Geography x Indicator x Element x Period`

The fact joins `DIM_PERIOD` rather than forcing multi-year observations into `DIM_DATE`.

Both `value` and `value_raw` are retained.

### `FACT_WDI`

Source: `CLEAN.WDI_OBSERVATIONS`

Grain:

`Mapped Geography x Indicator x Year`

Only WDI observations that resolve to the canonical FAOSTAT analytical geography dimension are promoted into the integrated consumption fact. WDI-only entities remain preserved in CLEAN.

The fact retains `wb_entity_id` and `wb_iso3_code` for source traceability.

## Fact idempotency

All facts use `source_row_hash` as the source observation identity in `MERGE` operations.

Rerunning a load updates the existing observation rather than duplicating it.

## SCD strategy

The v1 dimensions use SCD Type 1 behavior. Canonical descriptive attributes are updated in place while source history remains preserved in RAW/CLEAN and lineage fields.

## Final validation gate

Phase 10 was closed only after the following checks passed:

- source-to-fact reconciliation
- fact grain uniqueness
- dimension surrogate-key uniqueness
- referential integrity / orphan checks
- 2010-2023 annual scope validation
- food-security period-boundary validation
- India production smoke test
- India WDI enrichment smoke test
- food-security period smoke test
- emissions source separation smoke test

All final Phase 10 validation checks passed.

## Deliverable

Consumption-layer dimensional model ready for the Phase 11 automated data-quality framework.
