# FAOSTAT Source Analysis

## 1. Source Role

FAOSTAT is the primary domain source for agricultural resources, sustainability, production, food supply, emissions, and food-security indicators.

The project uses authenticated API access for discovery and ingestion. The third-party `faostat` Python package is used for metadata discovery and profiling, while production ingestion will retain an owned HTTP client so that raw API payloads, request metadata, retries, run IDs, checksums, and S3 landing behavior remain under project control.

## 2. Authentication

Protected FAOSTAT endpoints use bearer-token authentication:

```text
Authorization: Bearer <access_token>
```

The access token is short-lived. Local profiling may read it from `.env`, but scheduled production ingestion must authenticate at runtime and retrieve secrets from an appropriate secret store. Tokens must never be committed to source control or written to logs.

## 3. Selected Domains

| Code | Domain | Pillar | Structural Family |
|---|---|---|---|
| QCL | Crops and livestock products | Production | Standard annual |
| LC | Land Cover | Resources | Standard annual, multi-product elements |
| ESB | Cropland Nutrient Balance | Sustainability | Standard annual |
| FBS | Food Balances (2010-) | Food Supply | Standard annual |
| GT | Emissions totals | Climate | Annual + source + projections |
| FS | Suite of Food Security Indicators | Food Security & Nutrition | Mixed temporal / item-family behavior |

## 4. Common Source Semantics

Most FAOSTAT domains expose the conceptual structure:

```text
Area + Item + Element + Time
```

The meaning is:

- **Area**: country, region, special group, or other geography.
- **Item**: commodity, indicator, land-cover category, input category, or domain-specific subject.
- **Element**: measurement type, such as production, yield, area, nutrient quantity, food supply, or another measure.
- **Time**: annual year or, for FS, annual and multi-year period representations.

Country-level analytical models must avoid mixing country observations with regional or special-group aggregates.

## 5. Cross-Domain API Findings

### 5.1 Filter codes may differ from returned observation codes

FAOSTAT request/filter codes cannot be assumed to equal the codes returned in observations.

Observed examples include:

- QCL element filter `2510` returning observation element code `5510` for Production.
- FS element filter `6120` returning observation element code `6121` for Value.

Production ingestion must preserve both request context and returned observation codes. Returned codes must not be blindly reused as API filters.

### 5.2 Optional columns are not schema-stable

Some responses omit optional columns entirely when no data exists. For example, a domain sample may not return a `Note` column at all.

The raw ingestion layer must therefore tolerate additive and optional source fields without assuming a rigid CSV schema.

### 5.3 Null does not mean zero

FAOSTAT can return:

- populated values;
- null values with no flag;
- null values with an explicit missing flag;
- null values marked as suppressed;
- structurally present rows with no measurement.

These states must remain distinguishable.

### 5.4 Provenance flags are business-relevant metadata

Observed flags include:

| Flag | Meaning observed during profiling |
|---|---|
| A | Official value |
| E | Estimated value |
| I | Value imputed by a receiving agency |
| X | Value from external organization |
| O | Missing value |
| Q | Missing value; suppressed |

The raw flag and flag description must be preserved unchanged. CLEAN may derive a normalized `value_status`, but the normalized field must not replace the source flag.

## 6. Domain Findings

### 6.1 QCL - Crops and livestock products

Top-level dimensions are `area`, `element`, `item`, and `year`.

Important observations:

- Area metadata includes countries, regions, special groups, and multiple coding systems.
- Item metadata includes base items and aggregate items.
- Combining base items with aggregate items would create double-counting risk.
- A profiling slice across India, Italy, and Brazil, two crops, three elements, and 2010-2023 returned the expected complete row set with no duplicate candidate-grain observations.
- Units vary by element, for example tonnes, hectares, and kg/ha.

Working country-level grain:

```text
area + item + element + year
```

This grain must be validated again at production scale.

### 6.2 LC - Land Cover

LC uses the standard annual structure but exposes multiple land-cover measurement products through elements, including products such as MODIS, CCI_LC, CGLS, and WorldCover.

Profiling showed:

- many estimated values;
- explicit missing-value rows;
- completely blank observations;
- different source products for the same land-cover item and year.

Values from different land-cover products must not be averaged or blended without a documented reconciliation rule.

Working grain:

```text
area + item + element + year
```

The element is analytically significant because it identifies the measurement product.

### 6.3 ESB - Cropland Nutrient Balance

ESB uses the standard annual structure.

Profiling showed:

- extensive estimated values;
- values expressed in multiple units, including tonnes and kg/ha;
- element-level distinctions between total nutrient quantities and per-unit-area measures.

Working grain:

```text
area + item + element + year
```

No source-side precision should be discarded. Numeric scale and rounding will be defined in Snowflake after final data-volume and precision profiling.

### 6.4 FBS - Food Balances (2010-)

FBS aligns naturally with the project start year because the selected domain begins in 2010.

Profiling showed a rich mix of value provenance:

- external-organization values;
- estimated values;
- values imputed by a receiving agency;
- blank observations.

The domain includes elements such as production, imports, exports, domestic supply, food, losses, feed, seed, food-supply quantity, calories, protein, and fat.

Working grain:

```text
area + item + element + year
```

Aggregate items such as `Grand Total` must not be combined with detailed items without explicit analytical intent.

### 6.5 GT - Emissions totals

GT differs from the standard domains because it introduces a source dimension and projection metadata.

Profiling identified at least two observation sources in the same slice:

- FAO TIER 1
- UNFCCC

Multiple source records can exist for the same area, item, element, and year. Therefore source is part of the observation identity.

Working historical grain:

```text
area + item + element + year + source
```

Profiling also showed:

- estimated values;
- null observations;
- significant source-dependent coverage differences.

GT metadata contains `yearproj` values for:

```text
2030
2050
```

These are future projection years, not historical observation years. They are excluded from v1 analytical facts but documented and retained if present in raw payloads.

### 6.6 FS - Suite of Food Security Indicators

FS is the most structurally complex selected FAOSTAT domain.

Key findings:

1. FS uses `year3` metadata rather than a conventional annual-only year dimension.
2. Returned observations can include both annual rows and multi-year periods such as `2019-2021`.
3. One request item code may expand into multiple returned item variants.
4. Returned item suffixes encode analytical distinctions such as total, rural, urban, male, female, and town/semi-dense populations.
5. Annual and 3-year-average variants can coexist in the same indicator family.
6. Null observations may be blank, missing, or explicitly suppressed.
7. External-source values occur.

Example temporal semantics:

```text
2018        -> annual observation
2017-2019   -> multi-year period
```

Potential CLEAN fields include:

```text
period_type
period_start_year
period_end_year
period_label
```

Returned item suffixes must never be stripped merely to create a common base code. Doing so would collapse distinct population segments and temporal variants.

The final FS analytical grain must preserve returned item identity and period identity.

## 7. RAW-Layer Contract

FAOSTAT RAW ingestion will:

- preserve original payloads and source field names;
- preserve returned codes and labels;
- preserve value precision;
- preserve nulls;
- preserve unit, flag, flag description, and note when supplied;
- preserve request/filter context separately from returned observation codes;
- add ingestion metadata such as run ID, request timestamp, landing path, checksum, and source endpoint;
- avoid business filtering, rounding, coercion, and deduplication except for transport-level replay protection.

## 8. CLEAN-Layer Responsibilities

CLEAN processing may:

- standardize column names;
- normalize data types;
- classify geography type;
- classify base vs aggregate items where metadata supports it;
- derive normalized value-status categories from flags;
- parse FS temporal periods without losing original labels;
- validate candidate grains;
- detect duplicate source observations;
- apply documented country and analytical-item allowlists;
- exclude GT projections from the v1 historical consumption model.

CLEAN must not overwrite the original source semantics.

## 9. Revision Behavior and Historical Refresh

FAOSTAT is treated as a revision-capable statistical source rather than an append-only feed. Previously published observations may change as source statistics, estimates, classifications, or methodologies are revised.

The ingestion design must therefore not rely exclusively on:

```text
year > max_loaded_year
```

For the v1 analytical scope, scheduled refreshes re-extract the configured 2010-2023 range for the governed domain and indicator allowlist. Each extraction is retained as an immutable source snapshot identified by ingestion run metadata.

Revision detection compares source business keys together with observation attributes such as value, unit, flag, flag description, and note. A comparison between snapshots may identify:

- new observations;
- revised values or provenance metadata;
- observations no longer returned by the source;
- unchanged observations.

RAW retains historical snapshots for auditability and replay. CLEAN represents the currently accepted source state while preserving lineage to the originating ingestion run.

The exact production refresh schedule is defined in Phase 3.
## 10. Phase 2 Outcome

Source discovery and structural profiling are complete for the six selected domains.

The exact production allowlist of FAOSTAT items and elements will be frozen during the Phase 3 data-contract design. This does not reopen source discovery; it converts the profiled source space into explicit ingestion contracts.
