# ADR-005: Data Quality Failure Policy

## Status

Accepted.

## Context

The project requires automated quality checks that can later participate in Snowflake orchestration. Treating every anomaly identically would either make pipelines fragile or allow serious contract violations to pass unnoticed.

## Decision

Use a severity-aware DQ model with persisted run and test results.

### ERROR

Used for violations that invalidate the modeled dataset, including duplicate declared grain, mandatory-key failures, referential-integrity failures, unsupported analytical periods, and source-target reconciliation failures.

An ERROR-level failed test causes the DQ run to be `FAILED` and sets `should_stop_pipeline = TRUE`.

### WARNING

Used for conditions requiring review but not necessarily invalidating the dataset. Rejected CLEAN rows are initially handled at this level.

Warnings produce a `WARNING` run status but do not stop processing.

### INFO

Reserved for operational observations that should be retained without affecting pipeline progression.

## Consequences

### Positive

- Orchestration receives one explicit pipeline gate.
- DQ evidence is retained historically.
- Serious contract failures are separated from reviewable anomalies.
- New tests can be added without rewriting orchestration logic.

### Trade-offs

- Severity assignments must be governed carefully.
- Warning thresholds may need tuning as source behavior becomes better understood.
- A test that is too broad can still create false failures, so numerical rules remain business-specific.

## Follow-up

Phase 12 will integrate the DQ gate into the selected Snowflake transformation/orchestration design.
