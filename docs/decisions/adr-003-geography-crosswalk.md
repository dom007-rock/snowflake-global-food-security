# ADR-003 - Governed FAOSTAT to World Bank Geography Crosswalk

## Status

Accepted.

## Context

FAOSTAT and World Bank use different geography identifiers and naming conventions. Name matching would introduce ambiguity, historical-name problems, and fragile enrichment logic.

## Decision

Use the governed path:

`FAOSTAT area -> M49 -> UN M49 reference -> ISO3 -> World Bank`

Store the canonical result in `CONTROL.GEOGRAPHY_CROSSWALK`.

Do not use fuzzy matching for production integration.

## Exception policy

- Valid FAOSTAT aggregates are retained and marked `NOT_APPLICABLE` for World Bank country enrichment.
- Valid ISO3 entities without selected WDI coverage may remain `NO_WDI_MATCH`.
- Ambiguous or historical special cases remain `MANUAL_REVIEW` until explicitly resolved.
- Manual decisions are protected from automatic overwrite.

## Consequences

Positive:

- reproducible integration
- auditable mappings
- explicit exceptions
- stable country joins

Tradeoff:

- some entities remain intentionally unresolved rather than being force-matched.
