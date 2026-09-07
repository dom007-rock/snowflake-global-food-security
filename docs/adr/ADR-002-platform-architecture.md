# ADR-002: Platform Architecture v1

## Status

Superseded by ADR-003.

## Context

The platform integrates revision-capable FAOSTAT and World Bank WDI APIs, requires replayable ingestion, source-level auditability, cross-source country conformance, and Snowflake-based analytical serving.

## Decision

The platform uses:

1. Python for API extraction and source-specific request handling.
2. Amazon S3 as the persistent landing and replay boundary.
3. Initial design used immutable run-specific source files and a Snowflake external stage. This storage-access decision was superseded by ADR-003 after Delta Lake was selected as the first persistent landing representation.
4. Snowflake layer separation using RAW, CLEAN, CONSUMPTION, PUBLISH, and CONTROL schemas.
5. Immutable run-specific source snapshots for historical revision handling.
6. ISO3 as the canonical country integration key, with governed manual crosswalk exceptions.
7. Consumer access through PUBLISH rather than direct RAW access.
8. Monthly expected refreshes with on-demand backfills.

## Rationale

This design separates source preservation from business transformation, supports replay without repeated API extraction, prevents historical revisions from being lost, and keeps analytical consumers isolated from provider-specific schema variation.

## Consequences

Positive consequences include strong auditability, idempotent reloads, source replay, explicit provenance, and clean security boundaries. The design introduces additional storage for immutable snapshots and requires run/file audit metadata, schema-drift monitoring, and governed current-state resolution in CLEAN.

## Deferred Decisions

Warehouse sizing, orchestration technology, final dimensional modeling, and application KPIs are intentionally deferred to their designated project phases.
