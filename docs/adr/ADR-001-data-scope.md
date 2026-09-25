# ADR-001: Integrated Historical Data Scope

- **Status:** Accepted
- **Decision Date:** 2026-09-06
- **Project:** Global Food Security & Nutrition Intelligence Platform

## Context

The selected FAOSTAT domains and World Bank indicators provide different historical ranges and update schedules.

The project needs one clear v1 analytical period for integrated country-level comparisons while avoiding unnecessary historical volume and inconsistent source coverage.

Food Balances (2010-) naturally begins in 2010. Other FAOSTAT domains may contain older observations. GT also exposes future projection metadata for 2030 and 2050. World Bank WDI contains long historical series beyond the intended project scope.

## Decision

The integrated v1 historical analytical window is:

```text
2010-2023
```

The project will not include pre-2010 observations in the primary v1 analytical model.

GT projection years 2030 and 2050 will not be mixed into historical analytical facts.

FS observations will retain their original annual or multi-year period semantics. Inclusion in the v1 model will be based on a documented period rule in the Phase 3 data contract rather than coercing every FS observation into an ordinary year.

## Rationale

1. **Common analytical window**
   2010-2023 provides a practical overlap across the selected sources and aligns directly with Food Balances (2010-).

2. **Scope discipline**
   The project is intended to demonstrate production engineering depth, not maximize historical row count.

3. **Cross-domain comparability**
   A common period reduces misleading comparisons caused by uneven historical availability.

4. **Clear historical boundary**
   Capping the integrated model at 2023 prevents later source availability from creating an inconsistent cross-domain endpoint in v1.

5. **Projection separation**
   GT 2030 and 2050 values represent projections and should not be visually or analytically blended with historical observations without explicit modeling.

## Consequences

### Positive

- Simpler cross-domain joins and validation.
- Clear project scope.
- Smaller initial ingestion volume.
- Consistent historical dashboard period.
- Easier testing and reconciliation.

### Trade-offs

- Older FAOSTAT and World Bank history remains unused in v1.
- Some domains may contain newer source years that are intentionally not integrated yet.
- FS requires a special temporal contract because its periods do not always map one-to-one to annual years.

## Future Extension

A later version may extend the historical range or add GT projections through a separate projection fact model. Such an extension should be implemented as a new decision rather than silently changing the v1 contract.
