# CLEAN and Enrichment Contracts

## FAOSTAT CLEAN contracts

### Standard annual family: QCL, LC, ESB, FBS

Business grain:

```text
area_code_fao x item_code x element_code x year_code
```

Common standardized fields include:

```text
source_system
source_domain
area_code_fao
area_code_m49
area_name
item_code
item_name
element_code
element_name
year_code
year
unit
value
flag_code
flag_description / note where supplied
source_row_hash
ingestion_run_id
ingestion_batch_id
extracted_at_utc
cleaned_at_utc
```

M49 remains a string so leading zeros are preserved. Source values are safely typed with `TRY_TO_*` functions.

### GT: Emissions totals

GT looks similar to the standard annual family but has an additional business dimension:

```text
area_code_fao x item_code x element_code x source_code x year_code
```

`source_code` and `source_name` are retained because different emission-estimation sources can legitimately produce distinct observations.

### FS: Food security indicators

FS uses indicator semantics rather than generic item semantics:

```text
area_code_fao x indicator_code x element_code x period_code
```

Temporal standardization:

```text
period_label
period_start_year
period_end_year
period_type = ANNUAL | MULTI_YEAR
```

For example:

```text
2012-2014 -> start 2012, end 2014, MULTI_YEAR
2021      -> start 2021, end 2021, ANNUAL
```

FS retains both `value_raw` and parsed numeric `value` so semantically meaningful non-numeric source representations are not destroyed.

## World Bank WDI CLEAN contracts

### Observations

Business grain:

```text
wb_entity_id x indicator_code x year
```

Important distinction:

- `wb_entity_id` is the entity identifier emitted by the observation payload and participates in observation identity.
- `wb_iso3_code` is an integration attribute and can be null for valid World Bank entities.

A null ISO3 code is therefore not automatically a malformed row.

### Indicator metadata

One row per selected WDI indicator with:

- indicator code and name;
- source ID/name;
- source note;
- source organization;
- source-supplied unit;
- topics preserved as semi-structured metadata.

Blank World Bank `unit` fields are preserved as blank/null rather than invented from domain knowledge.

### Entity metadata

World Bank entity metadata is retained to distinguish countries/areas from aggregate entities and to carry region, income-level, lending-type, and related descriptive attributes.

## Selected WDI indicators

| Indicator | Description |
|---|---|
| `SP.POP.TOTL` | Population, total |
| `NY.GDP.MKTP.CD` | GDP (current US$) |
| `NY.GDP.PCAP.CD` | GDP per capita (current US$) |
| `SP.RUR.TOTL.ZS` | Rural population (% of total population) |
| `NV.AGR.TOTL.ZS` | Agriculture, forestry, and fishing, value added (% of GDP) |

## Geography integration contract

Country-level integration follows:

```text
FAOSTAT M49 -> UN M49 -> ISO3 -> World Bank WDI
```

The crosswalk never fuzzy-matches names automatically.

Mapping statuses:

- `MAPPED`: ISO3 resolves to the selected WDI dataset.
- `NO_WDI_MATCH`: valid ISO3 exists but selected WDI data has no matching entity.
- `NOT_APPLICABLE`: reviewed aggregate/region that should not enter country-level WDI joins.
- `MANUAL_REVIEW`: unresolved or historically/specially represented geography requiring explicit review.

Manual overrides are protected from automatic MERGE refreshes.
