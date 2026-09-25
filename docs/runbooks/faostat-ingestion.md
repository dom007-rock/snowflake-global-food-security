# FAOSTAT Ingestion Runbook

## Objective

Maintain a source-preserving Delta Lake landing layer for the six FAOSTAT domains used by the project.

## Domains

| Code | Dataset |
|---|---|
| QCL | Crops and livestock products |
| LC | Land Cover |
| ESB | Cropland Nutrient Balance |
| FBS | Food Balances (2010-) |
| GT | Emissions totals |
| FS | Suite of Food Security Indicators |

## Historical bootstrap

The initial historical bootstrap uses official normalized FAOSTAT bulk CSV files.

### Scope

- v1 analytical window: 2010–2023
- QCL/LC/ESB/FBS/GT: annual records in the window
- FS: annual and multi-year periods fully contained in the window

### Execution pattern

```text
bulk normalized CSV
  -> chunked pandas read
  -> temporal filter
  -> source_payload JSON
  -> technical metadata
  -> PyArrow
  -> Delta Lake on S3
```

### Bootstrap result

| Domain | Loaded rows | Runtime |
|---|---:|---:|
| QCL | 1,005,808 | 57.48 s |
| LC | 119,230 | 5.34 s |
| ESB | 194,244 | 10.68 s |
| FBS | 4,820,497 | 239.82 s |
| GT | 820,429 | 48.29 s |
| FS | 187,905 | 8.42 s |
| **Total** | **7,148,113** | **~6 min** |

All six Delta tables passed the post-bootstrap reconciliation script.

## API refresh pipeline

The API pipeline is retained for future refresh cycles.

### Behavior

- bearer-token authentication;
- HTTP timeout;
- retry with backoff for 429/5xx responses;
- paginated reads;
- bounded HTTP concurrency;
- deterministic page ordering;
- order-independent snapshot hashing;
- row-level SHA-256 hashes;
- logical batch identity;
- duplicate-snapshot skip;
- extraction and write telemetry.

### Benchmark that triggered bootstrap redesign

QCL 2023 full-year API extraction:

- rows: 202,520
- pages: 203
- page size: 1,000
- concurrent extraction benchmark: 454.47 s
- Delta write: 1.56 s

Conclusion: API pagination was the dominant cost. Historical bootstrap moved to bulk files; API remains the refresh path.

## Known source behavior

1. API envelope is an object containing `metadata` and `data`.
2. Source values, codes, and years can arrive as strings.
3. Request filter codes must not be assumed to equal returned observation codes.
4. Flags, flag descriptions, units, notes, and missing-value semantics must be preserved.
5. FS mixes annual and multi-year periods.
6. Historical observations are revision-capable.

## Failure and recovery

### API token expiry

Update the token and rerun the orchestration. Completed logical units should be skipped by idempotency/checkpoint logic.

### Partial API failure

The extraction unit is not committed until the required source set for that logical unit is available. A failed extraction is retried on rerun.

### Duplicate source arrival

Exact duplicate snapshots are skipped. Overlapping but differently scoped requests can represent different batches, so diagnostic/sampling requests must not write into production-scope Delta roots.

### Delta recovery incident

A diagnostic QCL request appended one overlapping row to the full-year table. Delta history was inspected and the active table state was restored to the known-good 202,520-row snapshot. Diagnostic writes must be isolated from production table roots.
