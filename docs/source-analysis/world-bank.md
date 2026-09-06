# World Bank World Development Indicators Source Analysis

## 1. Source Role

World Bank data is used as a socioeconomic enrichment layer around the FAOSTAT analytical story.

The project uses the **World Development Indicators (WDI)** database, identified by World Bank API **Source ID 2**.

The World Bank source is intentionally narrow. It enriches country-year FAOSTAT models rather than becoming a second large analytical project.

## 2. API Characteristics

Base API pattern:

```text
https://api.worldbank.org/v2/country/{country}/indicator/{indicator}
```

The project explicitly includes:

```text
source=2
format=json
```

No API key or authentication is required for the selected WDI endpoints.

The API supports year ranges and pagination.

## 3. Selected v1 Indicators

| Indicator Code | Indicator | Analytical Role |
|---|---|---|
| SP.POP.TOTL | Population, total | Scale / denominator context |
| NY.GDP.MKTP.CD | GDP (current US$) | Economic scale |
| NY.GDP.PCAP.CD | GDP per capita (current US$) | Economic conditions per person |
| SP.RUR.TOTL.ZS | Rural population (% of total population) | Rural-demographic context |
| NV.AGR.TOTL.ZS | Agriculture, forestry, and fishing, value added (% of GDP) | Agricultural importance in the economy |

These indicators are locked for v1.

## 4. Profiling Scope and Results

The initial profile used India for 2010-2023.

Expected rows:

```text
5 indicators x 14 years = 70 observations
```

The sample returned the expected 70 rows with complete values and no duplicate observations at the candidate grain.

Working grain:

```text
country_code + indicator_code + year
```

This grain will be validated again during multi-country ingestion.

## 5. Value Representation

Large numeric values may be displayed using scientific notation, for example:

```text
3.500906E+12
```

This is a display representation of a numeric value and must not be converted to a string in the warehouse.

The raw numeric value should retain source precision.

## 6. `unit` Field

The observation-level `unit` field was blank in the profiling sample.

This does not make the indicator unitless. The official indicator name and metadata describe the measure, for example:

- GDP (current US$)
- GDP per capita (current US$)
- Rural population (% of total population)
- Agriculture, forestry, and fishing, value added (% of GDP)

RAW ingestion will preserve the empty source `unit` field rather than manufacture a value.

Analytical display units may be derived from governed metadata later.

## 7. `obs_status` Field

The profiling sample returned blank `obs_status` values.

Blank status is treated as absence of a special observation status, not as a missing value.

The field remains part of the raw contract because special statuses may appear for other countries, years, or indicators.

## 8. `decimal` Field

The sample contained `decimal` values of `0` and `1`.

This field is not a Boolean. It represents display/scaling precision metadata used by the World Bank API.

Rules:

- Preserve `decimal` as source metadata.
- Do not round RAW values according to `decimal`.
- Do not reinterpret `0` and `1` as false/true.

## 9. Indicator Metadata

Indicator metadata is stored separately from observations.

Required metadata fields include:

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

The selected indicators all resolve to:

```text
source_id   = 2
source_name = World Development Indicators
```

Metadata source notes provide the semantic definition needed when the observation-level unit is blank.

Examples from the profile include:

- Population values based on the de facto population definition and midyear estimates.
- GDP and GDP per capita expressed in current prices and current US dollars.
- Rural population based on national statistical definitions and World Bank / UN population sources.
- Agriculture, forestry, and fishing value added expressed as a percentage of GDP.

## 10. RAW-Layer Contract

World Bank RAW ingestion will preserve:

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

It will also capture run-level ingestion metadata such as source URL, parameters, extraction timestamp, run ID, landing path, and checksum.

Indicator metadata will be landed and versioned separately from observation facts.

## 11. CLEAN-Layer Responsibilities

CLEAN processing may:

- standardize column names and data types;
- validate ISO3 country codes;
- separate true countries from World Bank aggregate entities when broader country queries are introduced;
- validate `country_code + indicator_code + year` uniqueness;
- attach governed indicator metadata;
- preserve the original numeric value while supporting presentation-scale fields downstream;
- align country-year observations with FAOSTAT country models.

## 12. Incremental and Revision Considerations

World Bank indicators may be revised historically. The ingestion strategy should therefore support controlled historical refreshes rather than assuming previously loaded years are immutable.

The same general revision-aware design principle used for FAOSTAT applies here.

## 13. Phase 2 Outcome

WDI API behavior, Source ID 2, the initial v1 indicator set, annual grain, 2010-2023 coverage, numeric behavior, blank observation metadata, decimal semantics, and indicator metadata have been profiled sufficiently to proceed to formal Phase 3 contracts.
