# Runbook 002 - QCL source-to-fact reconciliation failure

## Symptom
DQ gate fails `PIPELINE_QCL_RECONCILIATION` while fact-grain uniqueness and referential-integrity checks pass.

Observed incident:
- CLEAN QCL: 1,136,576
- FACT_CROPS_LIVESTOCK: initially 1,117,792
- difference: 18,784

## Diagnosis
The difference had two causes:

1. 4,980 rows belonged to six historical FAOSTAT entities with no analytical geography mapping:
   - Belgium-Luxembourg
   - Czechoslovakia
   - Ethiopia PDR
   - Serbia and Montenegro
   - USSR
   - Yugoslav SFR

2. 13,804 analytically eligible 2023 rows were present in CLEAN but absent from the fact and required a controlled catch-up MERGE.

The historical entities were explicitly classified in `CONTROL.GEOGRAPHY_CROSSWALK` as:
- `AREA_TYPE = HISTORICAL_ENTITY`
- `MAPPING_STATUS = NOT_APPLICABLE`
- `MAPPING_METHOD = REVIEWED_HISTORICAL_ENTITY`

## Correct reconciliation contract
QCL reconciliation excludes only explicitly reviewed historical entities. A separate `QCL_UNCLASSIFIED_GEOGRAPHY` ERROR-level DQ test ensures genuinely new unmapped area codes cannot be silently ignored.

Final validated counts:
- eligible CLEAN QCL: 1,131,596
- FACT_CROPS_LIVESTOCK: 1,131,596
- DQ tests: 23/23 passed
