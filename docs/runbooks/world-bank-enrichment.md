# World Bank Enrichment Runbook

## Objective

Ingest five World Development Indicators, preserve World Bank metadata, standardize WDI observations in Snowflake, and integrate eligible country-level records with FAOSTAT through a governed M49/ISO3 crosswalk.

## Source datasets

### WDI observations

Target period: 2010–2023.

Selected indicators:

- `SP.POP.TOTL`
- `NY.GDP.MKTP.CD`
- `NY.GDP.PCAP.CD`
- `SP.RUR.TOTL.ZS`
- `NV.AGR.TOTL.ZS`

### WDI metadata

Indicator metadata preserves source notes, source organization, topics, and source-supplied unit values.

### WDI entity metadata

Entity metadata supports classification of countries/areas versus aggregate entities.

### UN M49

UN M49 provides M49, ISO alpha-2, and ISO alpha-3 reference attributes used to bridge FAOSTAT to World Bank.

## Ingestion

Python writes the following Delta roots:

```text
delta/world_bank/wdi_observations/
delta/world_bank/wdi_indicator_metadata/
delta/world_bank/wdi_entity_metadata/
delta/reference/un_m49/
```

The World Bank writer converts Python records to a PyArrow table before calling `write_deltalake`. This avoids passing a `list[dict]` directly to the Delta writer.

## Snowflake RAW

Create read-only Delta Direct tables over each Delta root using the existing external volume and Delta catalog integration.

## CLEAN observations

Key rules:

- preserve valid rows even when `countryiso3code` is blank;
- use the World Bank entity identifier plus indicator/year as observation grain;
- keep `wb_iso3_code` as the cross-source integration attribute;
- retain null WDI values as null, never zero;
- restrict years to 2010–2023.

## Grain incident and correction

An initial grain test used `countryiso3code x indicator x year` and produced:

- 350 rows with blank ISO3;
- 70 duplicate grain groups;
- 280 additional rows.

The pattern showed that multiple valid World Bank entities shared blank ISO3 values. The model was corrected to use the source entity identifier for observation identity while retaining ISO3 only for integration.

This incident is a canonical example of profiling grain before deduplication.

## Geography crosswalk

The crosswalk is built from:

1. distinct FAOSTAT areas;
2. UN M49 reference;
3. WDI ISO3 availability.

Automatic fuzzy-name matching is prohibited.

Crosswalk refresh uses `MERGE`. Rows marked as governed manual overrides are protected from automatic replacement.

## Canonical name collision

FAOSTAT area code `148` appeared with two labels: `Naoero` and `Nauru`. M49/ISO identity was the same. The crosswalk canonicalization rule preferred the label matching World Bank/UN reference and retained one identity row.

RAW/CLEAN records continue to preserve whichever source label FAOSTAT supplied.

## Validation

Phase 9 DQ verifies:

- RAW-to-CLEAN WDI reconciliation;
- zero duplicate WDI grain groups;
- exactly five selected WDI indicators;
- 2010–2023 year scope;
- five metadata indicators;
- unique FAOSTAT codes in the crosswalk;
- mapped rows contain required integration keys;
- every mapped ISO3 exists in the selected WDI dataset;
- reviewed manual-exception count remains explicit;
- India integration smoke test returns WDI observations.

All Phase 9 validation tests passed at the completion checkpoint.
