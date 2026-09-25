# ADR-004 - Consumption-Layer Dimensional Modeling Strategy

## Status

Accepted.

## Context

The project integrates several FAOSTAT domains plus World Bank WDI. Source schemas are similar in shape but represent different business processes and do not always share globally conformed code systems.

## Decision

Use separate fact tables per analytical process and shared dimensions only where conformance is defensible.

### Geography

Use one `DIM_GEOGRAPHY` for both country and aggregate members. This dimension is the main FAOSTAT-to-WDI conformance point.

### Item and element

Use domain-aware business keys:

- `source_domain + item_code`
- `source_domain + element_code`

Profiling found no collisions but also no evidence of cross-domain code sharing.

### Indicator

Use a source-aware business key:

`source_system + source_domain + indicator_code`

### Time

Use `DIM_DATE` for annual observations and `DIM_PERIOD` for FAOSTAT FS interval reporting.

### Surrogate keys

Use Snowflake sequences for entity dimensions and a deterministic year key for `DIM_DATE`.

### SCD

Use SCD Type 1 in v1. Historical source fidelity remains in RAW and CLEAN.

### Fact loading

Use `source_row_hash` as the source-observation identity and `MERGE` for idempotent loading.

## Consequences

Positive:

- clear fact semantics
- safe reruns
- consistent analytical geography
- preserved multi-year period meaning
- direct lineage back to source observations

Tradeoffs:

- item and element dimensions are shared physically but remain domain-aware rather than globally conformed
- WDI consumption is intentionally limited to mapped FAOSTAT analytical geographies in v1
