# ADR-004: Governed Geography Crosswalk

- **Status:** Accepted
- **Scope:** FAOSTAT to World Bank country-level integration

## Context

FAOSTAT and World Bank use different source labels and code systems. Names are not reliable join keys. Examples include source-specific names such as `Bolivia (Plurinational State of)` versus a shorter World Bank label, as well as aggregate entities such as `European Union (27)`, `World`, OECD groups, and regional rollups.

The platform needs a repeatable way to integrate country-level data without fuzzy matching or silently forcing aggregates into country joins.

## Decision

Use the UN M49 reference as the canonical bridge:

```text
FAOSTAT area_code_m49
    -> UN M49
    -> ISO alpha-3
    -> World Bank wb_iso3_code
```

Store governed mappings in `GFS_DEV.CONTROL.GEOGRAPHY_CROSSWALK`.

## Identity and canonical labels

`area_code_fao` remains the FAOSTAT geography identity key. Names are descriptive attributes.

If one FAOSTAT code appears with multiple labels, canonicalization follows this order:

1. prefer an exact World Bank name match;
2. otherwise prefer an exact UN M49 name match;
3. otherwise use a deterministic fallback.

This resolved the observed code `148` label collision (`Naoero` / `Nauru`) without changing the business identity or adding a country-specific hard-coded rule.

## Mapping outcomes

The crosswalk explicitly distinguishes:

- `MAPPED`;
- `NO_WDI_MATCH`;
- `NOT_APPLICABLE`;
- `MANUAL_REVIEW`.

A mapping rate below 100% is acceptable when the remaining records are aggregates, unsupported territories, historical entities, or deliberately unresolved special cases.

## Reviewed exception policy

The Phase 9 review identified many FAOSTAT rows that are regions/economic aggregates rather than country-level entities. These are marked `NOT_APPLICABLE` instead of being force-mapped.

Rows with valid ISO3 but no matching selected WDI entity remain `NO_WDI_MATCH`; this is not treated as a DQ failure.

Five special cases remain explicitly under manual review:

- Channel Islands;
- China using the reviewed FAOSTAT source representation;
- China, Taiwan Province of;
- Netherlands Antilles (former);
- Sudan (former).

## Consequences

### Positive
- No fuzzy country-name joins.
- Aggregates do not leak into country-level WDI analysis.
- Historical/special entities stay visible instead of being silently discarded.
- Manual decisions are governed and auditable.
- Crosswalk refresh is rerunnable through `MERGE` while protecting manual overrides.

### Trade-offs
- The crosswalk requires explicit governance.
- Some source entities intentionally remain unenriched.
- Canonical labels can differ from labels retained in RAW/CLEAN source records.
