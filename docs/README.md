# Project Documentation Index

## Requirements

- [`requirements/project-charter.md`](requirements/project-charter.md) - project purpose, scope, sources, users, analytical story, success criteria, and constraints.

## Source Analysis

- [`source-analysis/faostat.md`](source-analysis/faostat.md) - FAOSTAT domain profiling, source quirks, grains, provenance, temporal behavior, and raw/clean responsibilities.
- [`source-analysis/world-bank.md`](source-analysis/world-bank.md) - World Bank WDI profiling, selected indicators, grain, metadata behavior, and source contract findings.
- [`source-analysis/source-contracts.md`](source-analysis/source-contracts.md) - cross-source contract baseline handed into Phase 3.
- [`source-analysis/phase-2-completion.md`](source-analysis/phase-2-completion.md) - formal Phase 2 completion record and Phase 3 handoff.

## Architecture

- [`architecture/architecture-overview.md`](architecture/architecture-overview.md) - Architecture v1, logical/physical architecture, layer boundaries, environments, and refresh model.
- [`architecture/data-flow.md`](architecture/data-flow.md) - source-to-target, replay, revision, and country-integration flows.
- [`architecture/data-contracts.md`](architecture/data-contracts.md) - Phase 3 source, landing, RAW/CLEAN, typing, retry, idempotency, and schema-evolution contracts.

## Architecture Decision Records

- [`adr/ADR-001-data-scope.md`](adr/ADR-001-data-scope.md) - decision to use 2010-2023 as the v1 integrated historical scope and keep GT projections separate.
- [`adr/ADR-002-platform-architecture.md`](adr/ADR-002-platform-architecture.md) - Architecture v1 decision for Python, S3, Snowflake layers, immutable snapshots, and ISO3 country integration.

## Later Documentation

The following remain intentionally deferred to later phases:

```text
data-model/
transformation-rules/
runbooks/
```


## Phase 3 Architecture v1

The accepted ingestion/storage path is:

```text
FAOSTAT + World Bank -> Python -> Delta Lake on S3 -> Snowflake Delta Direct RAW -> CLEAN -> CONSUMPTION -> PUBLISH -> Streamlit
```

Key architecture documents:

- `architecture/architecture-overview.md`
- `architecture/data-flow.md`
- `architecture/data-contracts.md`
- `architecture/delta-storage-contract.md`
- `architecture/phase-3-status.md`
- `adr/ADR-003-delta-lake-storage.md`
