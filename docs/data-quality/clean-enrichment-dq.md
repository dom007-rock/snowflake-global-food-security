# CLEAN and Enrichment Data Quality Framework

## Purpose

The Phase 8–9 DQ framework proves that standardization and enrichment preserve row accountability, business grain, temporal scope, lineage, and cross-source referential integrity.

## Phase 8 FAOSTAT checks

For each FAOSTAT CLEAN domain:

1. RAW count reconciles to CLEAN + rejects.
2. Required business-key fields are non-null.
3. Business grain has zero duplicate groups.
4. Temporal scope remains inside the v1 contract.
5. M49 values are either null or three-digit strings.
6. Source lineage fields are populated.

### Domain grains

| Domain | Grain |
|---|---|
| QCL | area x item x element x year |
| LC | area x item x element x year |
| ESB | area x item x element x year |
| FBS | area x item x element x year |
| GT | area x item x element x source x year |
| FS | area x indicator x element x period |

## Reject handling

Malformed records are quarantined in CONTROL rather than silently dropped. The expected accounting identity is:

```text
RAW = CLEAN + REJECTS
```

An empty reject table is a valid result when all source rows satisfy the rules.

FS is intentionally more permissive for source value text and retains `value_raw` alongside parsed `value`.

## Phase 9 WDI checks

- RAW-to-CLEAN observation reconciliation.
- Zero duplicate observation grain groups.
- Exactly five selected indicators.
- Year range 2010–2023.
- Exactly five indicator metadata records.

## Geography/cross-source checks

- one crosswalk row per `area_code_fao`;
- mapped rows have non-null ISO3 and World Bank name;
- mapped ISO3 exists in WDI observations;
- aggregates are not forced into country-level mappings;
- special manual-review exceptions remain explicit;
- India end-to-end smoke test proves a working FAOSTAT -> crosswalk -> WDI join.

## Audit persistence

DQ outcomes are persisted in CONTROL audit tables so validation evidence survives beyond an interactive worksheet session and can later be automated in Phase 12 orchestration.
