# Phase 2 Completion: Data Discovery & Source Profiling

## Status

**Phase 2 is complete.**

The phase established the source systems, structural behavior, temporal semantics, provenance behavior, and initial integration scope required to proceed into architecture and data-contract design.

## FAOSTAT Completion

| Domain | Code | Status | Key Structural Finding |
|---|---|---|---|
| Crops and livestock products | QCL | Complete | Standard annual grain; filter and returned codes may differ |
| Land Cover | LC | Complete | Multiple measurement products; estimated and missing values |
| Cropland Nutrient Balance | ESB | Complete | Standard annual grain; estimated values and multiple units |
| Food Balances (2010-) | FBS | Complete | Estimated, imputed, external-source, and blank observations |
| Emissions totals | GT | Complete | Source is part of grain; 2030/2050 projection metadata |
| Suite of Food Security Indicators | FS | Complete | Mixed annual/multi-year periods; item-family expansion; suppression semantics |

## World Bank WDI Completion

Selected database:

```text
World Development Indicators
Source ID: 2
```

Selected indicators:

```text
SP.POP.TOTL
NY.GDP.MKTP.CD
NY.GDP.PCAP.CD
SP.RUR.TOTL.ZS
NV.AGR.TOTL.ZS
```

Validated profile behavior:

- annual observations;
- 2010-2023 coverage for the initial country sample;
- candidate grain `country_code + indicator_code + year`;
- numeric values may render in scientific notation;
- observation-level `unit` may be blank;
- `obs_status` may be blank;
- `decimal` is display/scaling precision metadata, not Boolean;
- indicator metadata should be versioned separately from observations.

## Decisions Carried Forward

1. Integrated historical scope is 2010-2023.
2. RAW layers preserve source payload semantics.
3. Null values are never silently replaced with zero.
4. Source provenance flags remain available downstream.
5. Historical revisions must be supported.
6. FAOSTAT request codes and returned observation codes are stored as distinct concepts.
7. FS temporal semantics remain explicit.
8. GT projections are excluded from v1 historical facts.
9. World Bank WDI is enrichment, not a second primary domain platform.

## Phase 3 Handoff

Phase 3 will convert these findings into explicit architecture and physical data contracts, including:

- S3 landing layout;
- ingestion object naming;
- Snowflake database/schema/layer design;
- physical raw-table strategy;
- normalized clean schemas;
- curated FAOSTAT item and element allowlists;
- geography contracts;
- FS period contract;
- GT source handling;
- revision and replay strategy;
- audit metadata;
- schema-drift handling;
- data-quality assertions.

No source-discovery assumption should be silently changed during Phase 3. Any material change must be documented as a contract or ADR decision.
