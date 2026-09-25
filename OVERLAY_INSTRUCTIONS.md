# Phase 12-14 repository sync overlay

This folder is an **overlay patch**, not a reconstructed copy of the entire repository.

Copy its contents into the root of your existing `snowflake-global-food-security` repository and allow matching paths to overwrite the corresponding files.

## Files intended to overwrite

- `src/orchestration/snowflake_handoff.py`
- `scripts/run_faostat_refresh.py`
- `sql/orchestration/006_sp_merge_qcl_clean.sql`
- `sql/orchestration/007_task_qcl_to_fact_graph.sql`

## Files intended to add or replace as the canonical Phase 12-14 deployment scripts

- `sql/orchestration/012_phase12_validation.sql`
- `sql/dq/011_phase12_qcl_dq_fix.sql`
- `sql/security/013_phase13_rbac.sql`
- `sql/monitoring/014_phase14_monitoring.sql`
- `docs/PROJECT_STATUS.md`
- `docs/PHASE_13_SECURITY.md`
- `docs/PHASE_14_MONITORING.md`
- `docs/adr/ADR-002-snowflake-orchestration.md`
- `docs/adr/ADR-003-batch-id-restartability.md`
- `docs/runbooks/RUNBOOK-001-aws-opt-in-region-sts.md`
- `docs/runbooks/RUNBOOK-002-qcl-reconciliation.md`

## Important

This overlay intentionally does not replace your existing top-level `README.md`, because the full current README was not available in this chat. `docs/PROJECT_STATUS.md` contains the canonical Phase 12-14 status text to merge into README before the final Git push.

The existing ingestion `pipeline.py` should remain as-is. Its deterministic `batch_id` generation and `SKIPPED_ALREADY_LOADED` behavior are already compatible with this overlay.
