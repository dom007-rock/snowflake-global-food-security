# Phase 9 - World Bank Enrichment

## Status

Complete.

## Objective

Enrich the FAOSTAT analytical model with selected World Bank World Development Indicators while preserving source identity and using a governed geography bridge rather than fuzzy country-name matching.

## Selected WDI indicators

- `SP.POP.TOTL` - Population, total
- `NY.GDP.MKTP.CD` - GDP (current US$)
- `NY.GDP.PCAP.CD` - GDP per capita (current US$)
- `SP.RUR.TOTL.ZS` - Rural population (% of total population)
- `NV.AGR.TOTL.ZS` - Agriculture, forestry, and fishing, value added (% of GDP)

World Bank WDI Source ID 2 is used.

## Delta landing zones

- `delta/world_bank/wdi_observations/`
- `delta/world_bank/wdi_indicator_metadata/`
- `delta/world_bank/wdi_entity_metadata/`
- `delta/reference/un_m49/`

## Snowflake RAW tables

- `RAW.WDI_OBSERVATIONS`
- `RAW.WDI_INDICATOR_METADATA`
- `RAW.WDI_ENTITY_METADATA`
- `RAW.UN_M49_REFERENCE`

## Snowflake CLEAN tables

- `CLEAN.WDI_OBSERVATIONS`
- `CLEAN.WDI_INDICATOR_METADATA`
- `CLEAN.WDI_ENTITY_METADATA`
- `CLEAN.UN_M49_REFERENCE`

## WDI grain discovery

The initial assumption that `countryiso3code x indicator x year` formed the WDI observation grain was rejected after profiling.

Some valid World Bank entities have blank `countryiso3code`, which caused multiple entities to collapse into duplicate groups when ISO3 alone was treated as identity.

The CLEAN model therefore preserves the World Bank observation entity identifier independently from `wb_iso3_code`.

The project currently retains the observation-source field as `wb_entity_id` and keeps `wb_iso3_code` separately for geographic integration.

## Indicator metadata

Indicator metadata preserves:

- indicator code and name
- source ID and source name
- unit
- source note
- source organization
- topic metadata
- lineage

Blank source metadata fields are preserved rather than synthesized.

## UN M49 reference

A governed UN M49 reference dataset provides the bridge from FAOSTAT geography identifiers to ISO alpha codes.

Key fields include:

- `un_area_name`
- `m49_code`
- `iso_alpha2`
- `iso_alpha3`

## Geography integration path

The integration path is:

`FAOSTAT M49 -> UN M49 -> ISO3 -> World Bank wb_iso3_code`

No fuzzy country-name matching is used.

## Geography crosswalk

`CONTROL.GEOGRAPHY_CROSSWALK` contains:

- `area_code_fao`
- `area_code_m49`
- `faostat_area_name`
- `country_iso3`
- `world_bank_name`
- `area_type`
- `mapping_status`
- `mapping_method`
- validity and audit timestamps

Supported mapping statuses include:

- `MAPPED`
- `NO_WDI_MATCH`
- `NOT_APPLICABLE`
- `MANUAL_REVIEW`

## Aggregate handling

FAOSTAT regional and economic aggregates are retained as valid FAOSTAT analytical geography members but are not forced into country mappings. Reviewed aggregates use:

- `area_type = 'AGGREGATE'`
- `mapping_status = 'NOT_APPLICABLE'`
- `mapping_method = 'REVIEWED_FAOSTAT_AGGREGATE'`

## Manual-review exceptions

Five deliberately unresolved special cases remain for controlled review rather than forced automatic mapping:

- Channel Islands
- China
- China, Taiwan Province of
- Netherlands Antilles (former)
- Sudan (former)

## Canonicalization lesson

FAOSTAT code 148 appeared under both `Naoero` and `Nauru` while resolving to the same M49 and ISO3 identity. This demonstrated that source names are descriptive attributes, not durable identity keys.

The crosswalk was canonicalized to one row per `area_code_fao`, prioritizing consistent source/reference names while protecting manual decisions.

## Final validation gate

The final Phase 9 gate passed checks for:

- WDI RAW-to-CLEAN reconciliation
- WDI duplicate grain
- selected indicator count
- year scope
- indicator metadata coverage
- crosswalk FAO-code uniqueness
- required mapped keys
- mapped ISO3 coverage in WDI
- controlled manual-review exception count
- India integration smoke test

All final Phase 9 checks passed.
