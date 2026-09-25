# ADR-003: Deterministic batch identity for restartable ingestion

## Status
Accepted

## Context
Each API execution receives a unique `run_id`, but an identical source snapshot may already exist in Delta. A retry can therefore have a new `run_id` even though the logical payload is unchanged.

Using `run_id` as the Snowflake handoff key creates a restartability defect: if Delta committed successfully and the process failed before CLEAN completed, a retry would receive a new `run_id` that does not exist in the already-committed Delta rows.

## Decision
Use two identifiers with different responsibilities:

- `run_id`: physical execution attempt
- `batch_id`: deterministic logical payload identity

`batch_id` is derived from source, domain, request filters, and snapshot hash. An identical source snapshot therefore produces the same `batch_id`.

The Snowflake handoff, RAW visibility check, and `SP_MERGE_QCL_CLEAN` all use `batch_id`.

## Retry behavior

```text
First attempt
  API -> Delta SUCCESS -> batch_id X -> Snowflake handoff

Retry of same snapshot
  API -> Delta SKIPPED_ALREADY_LOADED -> same batch_id X
      -> Snowflake handoff still runs
      -> CLEAN MERGE is a no-op if hashes match
```

## Consequences
- retry after Delta commit is safe
- duplicate Delta writes are prevented
- exact reruns do not create CLEAN CDC
- downstream processing remains idempotent
