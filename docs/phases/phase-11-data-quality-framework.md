# Phase 11 - Data Quality Framework

## Status

Complete.

## Objective

Convert one-off validation queries into a reusable, auditable data-quality framework that can be executed as part of the Snowflake processing pipeline and consumed by orchestration in Phase 12.

## Implemented control model

Phase 11 introduced three core control objects:

- `CONTROL.DQ_RUNS` - one row per data-quality execution.
- `CONTROL.DQ_RESULTS` - one row per executed test.
- `CONTROL.V_DQ_RUN_GATE` - pipeline-level gate derived from the run result.

The framework records test category, target object, target column or grain, severity, expected and observed values, failure counts, status, message, and execution timestamp.

## DQ categories implemented

The Phase 11 suite covers:

1. Uniqueness and declared fact grain.
2. Mandatory fields.
3. Accepted categorical values.
4. Supported year and period ranges.
5. Indicator-specific numerical ranges.
6. Referential integrity between facts and dimensions.
7. CLEAN-to-CONSUMPTION row-count reconciliation.
8. Rejected-record tracking.
9. Persisted execution summaries and detailed results.
10. Pipeline continuation/failure policy.

## Key design decisions

### Persist results instead of relying on interactive queries

Previous phases used validation queries as gates during development. Phase 11 persists each execution so DQ evidence is retained and can later be surfaced operationally.

### Separate test severity from test result

Tests use severity values such as `ERROR`, `WARNING`, and `INFO`, while the result is stored independently as `PASS`, `WARN`, or `FAIL`.

This allows orchestration to distinguish a broken data contract from an observable anomaly that should be reviewed without stopping the pipeline.

### Do not apply generic numerical rules to every fact

No global `value >= 0` rule is applied across FAOSTAT facts. Some business measures can legitimately be negative. Numerical contracts are therefore added only where the business meaning supports them.

Initial defensible rules include:

- reporting-period duration must be positive;
- WDI population must be non-negative;
- WDI GDP and GDP per capita must be non-negative;
- WDI rural-population percentage must be between 0 and 100.

Further numerical rules should be introduced only after profiling each measure by indicator/element and unit.

### Rejects are observable, not automatically fatal

`CONTROL.FAOSTAT_CLEAN_REJECTS` is included in the DQ framework. The presence of rejected records is treated as a warning condition unless future source-specific thresholds require stronger behavior.

## Source-to-target reconciliation

FAOSTAT consumption facts reconcile directly to their corresponding CLEAN datasets:

- QCL -> `FACT_CROPS_LIVESTOCK`
- LC -> `FACT_LAND_COVER`
- ESB -> `FACT_NUTRIENT_BALANCE`
- FBS -> `FACT_FOOD_BALANCE`
- GT -> `FACT_EMISSIONS`
- FS -> `FACT_FOOD_SECURITY`

WDI is reconciled only against the mapped analytical population because `FACT_WDI` intentionally contains WDI observations that resolve to mapped `DIM_GEOGRAPHY` members. WDI-only entities remain preserved in CLEAN.

## Pipeline gate policy

The DQ run is summarized as:

- `PASSED` when all configured tests pass;
- `WARNING` when no ERROR-level test fails but one or more warning tests return `WARN`;
- `FAILED` when an ERROR-level test returns `FAIL`.

`CONTROL.V_DQ_RUN_GATE.should_stop_pipeline` is `TRUE` only for a failed run.

Phase 12 orchestration will consume this gate rather than reimplementing quality logic in each task.

## Validation outcome

The final Phase 11 execution completed with all configured tests passing. The DQ framework is ready to be integrated into automated processing in Phase 12.

## Deliverable

Automated, persisted, severity-aware data-quality framework for the integrated Snowflake consumption model.
