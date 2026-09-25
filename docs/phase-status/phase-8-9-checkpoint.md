# Phase 8–9 Checkpoint

## Phase 8: CLEAN / Standardization

**Status: Complete**

### Delivered

- Six FAOSTAT CLEAN tables.
- `snake_case` standardized headers.
- Safe numeric/year conversion using `TRY_TO_*` functions.
- M49 normalization without losing leading zeros.
- Source lineage retained through CLEAN.
- Explicit business grain per domain.
- FS annual/multi-year temporal model.
- GT source dimension included in grain.
- Rejected-record quarantine design.
- Cross-domain reconciliation and DQ gate.

### Key modeling outcomes

```text
QCL / LC / ESB / FBS
  area x item x element x year

GT
  area x item x element x source x year

FS
  area x indicator x element x period
```

All final Phase 8 DQ checks passed.

## Phase 9: World Bank Enrichment

**Status: Complete**

### Delivered

- World Bank WDI observation ingestion to Delta/S3.
- World Bank indicator metadata ingestion.
- World Bank entity metadata reference.
- Snowflake RAW Delta Direct tables for World Bank datasets.
- WDI CLEAN observation and metadata tables.
- UN M49 reference ingestion and CLEAN table.
- Governed FAOSTAT -> M49 -> ISO3 -> World Bank crosswalk.
- Manual-review / not-applicable / no-WDI-match exception policy.
- Cross-source DQ gate and India smoke test.

### WDI indicators

1. `SP.POP.TOTL`
2. `NY.GDP.MKTP.CD`
3. `NY.GDP.PCAP.CD`
4. `SP.RUR.TOTL.ZS`
5. `NV.AGR.TOTL.ZS`

### Important grain correction

The first WDI uniqueness test used `countryiso3code x indicator x year`. It exposed 350 rows without ISO3, 70 duplicate groups, and 280 additional rows. Investigation showed that missing ISO3 did not mean malformed data. The model was corrected so the World Bank entity identifier defines observation identity and ISO3 is retained only as an integration attribute.

### Geography exception review

The exception review contained regions/economic groups, valid ISO3 areas without selected WDI matches, and a small number of special historical/source representations.

Reviewed aggregates were marked `NOT_APPLICABLE` for country-level WDI integration. Valid ISO3 rows without selected WDI matches remain `NO_WDI_MATCH` rather than being treated as failures.

Five explicit manual-review cases remain governed exceptions:

- Channel Islands;
- China using the reviewed FAOSTAT source representation;
- China, Taiwan Province of;
- Netherlands Antilles (former);
- Sudan (former).

### Name-variant collision

FAOSTAT code `148` appeared as both `Naoero` and `Nauru` with the same underlying geography identity. The crosswalk was canonicalized to one row by preferring a World Bank/UN reference name match. This reinforced the rule that codes define identity and names are attributes.

### Final result

All Phase 9 validation tests passed, including crosswalk uniqueness and the country-level FAOSTAT/WDI smoke test.

## Next phase

**Phase 10: Dimensional Modeling**

Primary objectives:

- define conformed dimensions;
- design fact-table grains;
- create country/geography dimension using governed mappings;
- create year/date and indicator dimensions;
- model FAOSTAT and WDI measures without implying causality;
- prepare consumption-ready analytical structures.
