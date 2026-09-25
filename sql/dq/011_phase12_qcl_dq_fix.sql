-- Phase 12 QCL DQ fix v3
-- Corrected Snowflake VALUES syntax and uses $$ for the SQL procedure body.

USE ROLE ACCOUNTADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CONTROL;
USE WAREHOUSE GFS_TRANSFORM_WH;

-- A. Classify the six reviewed historical FAOSTAT entities. Re-runnable.
MERGE INTO CONTROL.GEOGRAPHY_CROSSWALK AS t
USING (
    SELECT
        v.area_code_fao,
        v.faostat_area_name
    FROM (VALUES
        ('15',  'Belgium-Luxembourg'),
        ('51',  'Czechoslovakia'),
        ('62',  'Ethiopia PDR'),
        ('186', 'Serbia and Montenegro'),
        ('228', 'USSR'),
        ('248', 'Yugoslav SFR')
    ) AS v(area_code_fao, faostat_area_name)
) AS s
ON t.area_code_fao = s.area_code_fao
WHEN MATCHED THEN UPDATE SET
    t.faostat_area_name = s.faostat_area_name,
    t.area_type = 'HISTORICAL_ENTITY',
    t.mapping_status = 'NOT_APPLICABLE',
    t.mapping_method = 'REVIEWED_HISTORICAL_ENTITY',
    t.updated_at_utc = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT (
    area_code_fao,
    area_code_m49,
    faostat_area_name,
    country_iso3,
    world_bank_name,
    area_type,
    mapping_status,
    mapping_method,
    valid_from,
    valid_to,
    created_at_utc,
    updated_at_utc
)
VALUES (
    s.area_code_fao,
    NULL,
    s.faostat_area_name,
    NULL,
    NULL,
    'HISTORICAL_ENTITY',
    'NOT_APPLICABLE',
    'REVIEWED_HISTORICAL_ENTITY',
    NULL,
    NULL,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
);

-- B. Preflight. Current expected values: 4,980 excluded and 1,131,596 eligible.
WITH historical_exclusions AS (
    SELECT DISTINCT area_code_fao
    FROM CONTROL.GEOGRAPHY_CROSSWALK
    WHERE mapping_status = 'NOT_APPLICABLE'
      AND area_type = 'HISTORICAL_ENTITY'
)
SELECT
    COUNT(*) AS qcl_total_rows,
    COUNT_IF(h.area_code_fao IS NOT NULL) AS explicitly_excluded_rows,
    COUNT_IF(h.area_code_fao IS NULL) AS fact_eligible_rows
FROM CLEAN.FAOSTAT_QCL q
LEFT JOIN historical_exclusions h
    ON q.area_code_fao = h.area_code_fao;

-- C. Preflight classification. For the current dataset this should return 0 rows.
SELECT
    q.area_code_fao,
    COUNT(*) AS row_count
FROM CLEAN.FAOSTAT_QCL q
LEFT JOIN CONTROL.GEOGRAPHY_CROSSWALK x
    ON q.area_code_fao = x.area_code_fao
WHERE x.area_code_fao IS NULL
GROUP BY q.area_code_fao
ORDER BY row_count DESC;

-- D. Replace DQ gate, retaining existing USAGE grants.
CREATE OR REPLACE PROCEDURE CONTROL.SP_RUN_PIPELINE_DQ_GATE()
COPY GRANTS
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
  DECLARE      v_dq_run_id STRING;     v_status    STRING;  BEGIN      v_dq_run_id :=         'DQ_PIPE_' ||         TO_VARCHAR(             CURRENT_TIMESTAMP(),             'YYYYMMDD_HH24MISSFF3'         );        INSERT INTO CONTROL.DQ_RUNS (         dq_run_id,         run_status,         started_at_utc     )     VALUES (         :v_dq_run_id,         'RUNNING',         CURRENT_TIMESTAMP()     );        INSERT INTO CONTROL.DQ_RESULTS (          dq_run_id,         test_name,         test_category,         target_object,         target_column,         severity,         expected_value,         observed_value,         test_status,         failure_count,         test_message,         executed_at_utc      )      WITH counts AS (          SELECT             'QCL' AS domain,             'CONSUMPTION.FACT_CROPS_LIVESTOCK' AS target_object,             (
                SELECT COUNT(*)
                FROM CLEAN.FAOSTAT_QCL q
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM CONTROL.GEOGRAPHY_CROSSWALK x
                    WHERE x.area_code_fao = q.area_code_fao
                      AND x.mapping_status = 'NOT_APPLICABLE'
                      AND x.area_type = 'HISTORICAL_ENTITY'
                )
            ) AS source_count,             (SELECT COUNT(*) FROM CONSUMPTION.FACT_CROPS_LIVESTOCK) AS target_count          UNION ALL          SELECT             'LC',             'CONSUMPTION.FACT_LAND_COVER',             (SELECT COUNT(*) FROM CLEAN.FAOSTAT_LC),             (SELECT COUNT(*) FROM CONSUMPTION.FACT_LAND_COVER)          UNION ALL          SELECT             'ESB',             'CONSUMPTION.FACT_NUTRIENT_BALANCE',             (SELECT COUNT(*) FROM CLEAN.FAOSTAT_ESB),             (SELECT COUNT(*) FROM CONSUMPTION.FACT_NUTRIENT_BALANCE)          UNION ALL          SELECT             'FBS',             'CONSUMPTION.FACT_FOOD_BALANCE',             (SELECT COUNT(*) FROM CLEAN.FAOSTAT_FBS),             (SELECT COUNT(*) FROM CONSUMPTION.FACT_FOOD_BALANCE)          UNION ALL          SELECT             'GT',             'CONSUMPTION.FACT_EMISSIONS',             (SELECT COUNT(*) FROM CLEAN.FAOSTAT_GT),             (SELECT COUNT(*) FROM CONSUMPTION.FACT_EMISSIONS)          UNION ALL          SELECT             'FS',             'CONSUMPTION.FACT_FOOD_SECURITY',             (SELECT COUNT(*) FROM CLEAN.FAOSTAT_FS),             (SELECT COUNT(*) FROM CONSUMPTION.FACT_FOOD_SECURITY)          UNION ALL          SELECT             'WDI_MAPPED',             'CONSUMPTION.FACT_WDI',              (                 SELECT COUNT(*)                  FROM CLEAN.WDI_OBSERVATIONS w                  JOIN CONSUMPTION.DIM_GEOGRAPHY g                     ON w.wb_iso3_code = g.country_iso3                    AND g.mapping_status = 'MAPPED'             ),              (                 SELECT COUNT(*)                 FROM CONSUMPTION.FACT_WDI             )      )      SELECT         :v_dq_run_id,          'PIPELINE_' || domain || '_RECONCILIATION',          'SOURCE_TARGET_RECONCILIATION',          target_object,          'row_count',          'ERROR',          source_count::STRING,          target_count::STRING,          IFF(             source_count = target_count,             'PASS',             'FAIL'         ),          ABS(source_count - target_count),          IFF(             source_count = target_count,             'Source and target counts reconcile.',             'Source and target counts differ.'         ),          CURRENT_TIMESTAMP()      FROM counts;         INSERT INTO CONTROL.DQ_RESULTS (          dq_run_id,         test_name,         test_category,         target_object,         target_column,         severity,         expected_value,         observed_value,         test_status,         failure_count,         test_message,         executed_at_utc      )      WITH tests AS (          SELECT             'FACT_CROPS_LIVESTOCK_GRAIN' AS test_name,             'CONSUMPTION.FACT_CROPS_LIVESTOCK' AS target_object,             COUNT(*) AS failure_count          FROM (             SELECT                 geography_key,                 item_key,                 element_key,                 date_key             FROM CONSUMPTION.FACT_CROPS_LIVESTOCK             GROUP BY 1,2,3,4             HAVING COUNT(*) > 1         )           UNION ALL           SELECT             'FACT_LAND_COVER_GRAIN',             'CONSUMPTION.FACT_LAND_COVER',             COUNT(*)          FROM (             SELECT                 geography_key,                 item_key,                 element_key,                 date_key             FROM CONSUMPTION.FACT_LAND_COVER             GROUP BY 1,2,3,4             HAVING COUNT(*) > 1         )           UNION ALL           SELECT             'FACT_NUTRIENT_BALANCE_GRAIN',             'CONSUMPTION.FACT_NUTRIENT_BALANCE',             COUNT(*)          FROM (             SELECT                 geography_key,                 item_key,                 element_key,                 date_key             FROM CONSUMPTION.FACT_NUTRIENT_BALANCE             GROUP BY 1,2,3,4             HAVING COUNT(*) > 1         )           UNION ALL           SELECT             'FACT_FOOD_BALANCE_GRAIN',             'CONSUMPTION.FACT_FOOD_BALANCE',             COUNT(*)          FROM (             SELECT                 geography_key,                 item_key,                 element_key,                 date_key             FROM CONSUMPTION.FACT_FOOD_BALANCE             GROUP BY 1,2,3,4             HAVING COUNT(*) > 1         )           UNION ALL           SELECT             'FACT_EMISSIONS_GRAIN',             'CONSUMPTION.FACT_EMISSIONS',             COUNT(*)          FROM (             SELECT                 geography_key,                 item_key,                 element_key,                 source_key,                 date_key             FROM CONSUMPTION.FACT_EMISSIONS             GROUP BY 1,2,3,4,5             HAVING COUNT(*) > 1         )           UNION ALL           SELECT             'FACT_FOOD_SECURITY_GRAIN',             'CONSUMPTION.FACT_FOOD_SECURITY',             COUNT(*)          FROM (             SELECT                 geography_key,                 indicator_key,                 element_key,                 period_key             FROM CONSUMPTION.FACT_FOOD_SECURITY             GROUP BY 1,2,3,4             HAVING COUNT(*) > 1         )           UNION ALL           SELECT             'FACT_WDI_GRAIN',             'CONSUMPTION.FACT_WDI',             COUNT(*)          FROM (             SELECT                 geography_key,                 indicator_key,                 date_key             FROM CONSUMPTION.FACT_WDI             GROUP BY 1,2,3             HAVING COUNT(*) > 1         )      )      SELECT         :v_dq_run_id,          test_name,          'UNIQUENESS',          target_object,          'declared fact grain',          'ERROR',          '0',          failure_count::STRING,          IFF(             failure_count = 0,             'PASS',             'FAIL'         ),          failure_count,          IFF(             failure_count = 0,             'Fact grain is unique.',             'Duplicate fact-grain groups detected.'         ),          CURRENT_TIMESTAMP()      FROM tests;         INSERT INTO CONTROL.DQ_RESULTS (          dq_run_id,         test_name,         test_category,         target_object,         target_column,         severity,         expected_value,         observed_value,         test_status,         failure_count,         test_message,         executed_at_utc      )      WITH tests AS (          SELECT             'FACT_CROPS_LIVESTOCK_RI' AS test_name,             'CONSUMPTION.FACT_CROPS_LIVESTOCK' AS target_object,              COUNT_IF(                 g.geography_key IS NULL                 OR d.date_key IS NULL                 OR i.item_key IS NULL                 OR e.element_key IS NULL             ) AS failure_count          FROM CONSUMPTION.FACT_CROPS_LIVESTOCK f          LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g             ON f.geography_key = g.geography_key          LEFT JOIN CONSUMPTION.DIM_DATE d             ON f.date_key = d.date_key          LEFT JOIN CONSUMPTION.DIM_ITEM i             ON f.item_key = i.item_key          LEFT JOIN CONSUMPTION.DIM_ELEMENT e             ON f.element_key = e.element_key           UNION ALL           SELECT             'FACT_LAND_COVER_RI',             'CONSUMPTION.FACT_LAND_COVER',              COUNT_IF(                 g.geography_key IS NULL                 OR d.date_key IS NULL                 OR i.item_key IS NULL                 OR e.element_key IS NULL             )          FROM CONSUMPTION.FACT_LAND_COVER f          LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g             ON f.geography_key = g.geography_key          LEFT JOIN CONSUMPTION.DIM_DATE d             ON f.date_key = d.date_key          LEFT JOIN CONSUMPTION.DIM_ITEM i             ON f.item_key = i.item_key          LEFT JOIN CONSUMPTION.DIM_ELEMENT e             ON f.element_key = e.element_key           UNION ALL           SELECT             'FACT_NUTRIENT_BALANCE_RI',             'CONSUMPTION.FACT_NUTRIENT_BALANCE',              COUNT_IF(                 g.geography_key IS NULL                 OR d.date_key IS NULL                 OR i.item_key IS NULL                 OR e.element_key IS NULL             )          FROM CONSUMPTION.FACT_NUTRIENT_BALANCE f          LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g             ON f.geography_key = g.geography_key          LEFT JOIN CONSUMPTION.DIM_DATE d             ON f.date_key = d.date_key          LEFT JOIN CONSUMPTION.DIM_ITEM i             ON f.item_key = i.item_key          LEFT JOIN CONSUMPTION.DIM_ELEMENT e             ON f.element_key = e.element_key           UNION ALL           SELECT             'FACT_FOOD_BALANCE_RI',             'CONSUMPTION.FACT_FOOD_BALANCE',              COUNT_IF(                 g.geography_key IS NULL                 OR d.date_key IS NULL                 OR i.item_key IS NULL                 OR e.element_key IS NULL             )          FROM CONSUMPTION.FACT_FOOD_BALANCE f          LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g             ON f.geography_key = g.geography_key          LEFT JOIN CONSUMPTION.DIM_DATE d             ON f.date_key = d.date_key          LEFT JOIN CONSUMPTION.DIM_ITEM i             ON f.item_key = i.item_key          LEFT JOIN CONSUMPTION.DIM_ELEMENT e             ON f.element_key = e.element_key           UNION ALL           SELECT             'FACT_EMISSIONS_RI',             'CONSUMPTION.FACT_EMISSIONS',              COUNT_IF(                 g.geography_key IS NULL                 OR d.date_key IS NULL                 OR i.item_key IS NULL                 OR e.element_key IS NULL                 OR s.source_key IS NULL             )          FROM CONSUMPTION.FACT_EMISSIONS f          LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g             ON f.geography_key = g.geography_key          LEFT JOIN CONSUMPTION.DIM_DATE d             ON f.date_key = d.date_key          LEFT JOIN CONSUMPTION.DIM_ITEM i             ON f.item_key = i.item_key          LEFT JOIN CONSUMPTION.DIM_ELEMENT e             ON f.element_key = e.element_key          LEFT JOIN CONSUMPTION.DIM_SOURCE s             ON f.source_key = s.source_key           UNION ALL           SELECT             'FACT_FOOD_SECURITY_RI',             'CONSUMPTION.FACT_FOOD_SECURITY',              COUNT_IF(                 g.geography_key IS NULL                 OR ind.indicator_key IS NULL                 OR e.element_key IS NULL                 OR p.period_key IS NULL             )          FROM CONSUMPTION.FACT_FOOD_SECURITY f          LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g             ON f.geography_key = g.geography_key          LEFT JOIN CONSUMPTION.DIM_INDICATOR ind             ON f.indicator_key = ind.indicator_key          LEFT JOIN CONSUMPTION.DIM_ELEMENT e             ON f.element_key = e.element_key          LEFT JOIN CONSUMPTION.DIM_PERIOD p             ON f.period_key = p.period_key           UNION ALL           SELECT             'FACT_WDI_RI',             'CONSUMPTION.FACT_WDI',              COUNT_IF(                 g.geography_key IS NULL                 OR ind.indicator_key IS NULL                 OR d.date_key IS NULL             )          FROM CONSUMPTION.FACT_WDI f          LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g             ON f.geography_key = g.geography_key          LEFT JOIN CONSUMPTION.DIM_INDICATOR ind             ON f.indicator_key = ind.indicator_key          LEFT JOIN CONSUMPTION.DIM_DATE d             ON f.date_key = d.date_key      )      SELECT         :v_dq_run_id,          test_name,          'REFERENTIAL_INTEGRITY',          target_object,          'dimension keys',          'ERROR',          '0',          failure_count::STRING,          IFF(             failure_count = 0,             'PASS',             'FAIL'         ),          failure_count,          IFF(             failure_count = 0,             'All foreign keys resolve.',             'Orphan dimension references detected.'         ),          CURRENT_TIMESTAMP()      FROM tests;         

     INSERT INTO CONTROL.DQ_RESULTS (
         dq_run_id,
         test_name,
         test_category,
         target_object,
         target_column,
         severity,
         expected_value,
         observed_value,
         test_status,
         failure_count,
         test_message,
         executed_at_utc
     )
     SELECT
         :v_dq_run_id,
         'QCL_UNCLASSIFIED_GEOGRAPHY',
         'GEOGRAPHY_CLASSIFICATION',
         'CONTROL.GEOGRAPHY_CROSSWALK',
         'area_code_fao',
         'ERROR',
         '0',
         COUNT(DISTINCT q.area_code_fao)::STRING,
         IFF(COUNT(DISTINCT q.area_code_fao) = 0, 'PASS', 'FAIL'),
         COUNT(DISTINCT q.area_code_fao),
         IFF(
             COUNT(DISTINCT q.area_code_fao) = 0,
             'All QCL geographies are classified.',
             'Unclassified QCL geography codes detected.'
         ),
         CURRENT_TIMESTAMP()
     FROM CLEAN.FAOSTAT_QCL q
     LEFT JOIN CONTROL.GEOGRAPHY_CROSSWALK x
         ON q.area_code_fao = x.area_code_fao
     WHERE x.area_code_fao IS NULL;

     INSERT INTO CONTROL.DQ_RESULTS (          dq_run_id,         test_name,         test_category,         target_object,         target_column,         severity,         expected_value,         observed_value,         test_status,         failure_count,         test_message,         executed_at_utc      )      SELECT         :v_dq_run_id,          'FAOSTAT_CLEAN_REJECT_COUNT',          'REJECT_TRACKING',          'CONTROL.FAOSTAT_CLEAN_REJECTS',          NULL,          'WARNING',          '0 preferred',          COUNT(*)::STRING,          IFF(             COUNT(*) = 0,             'PASS',             'WARN'         ),          COUNT(*),          IFF(             COUNT(*) = 0,             'No CLEAN rejects present.',             'CLEAN rejects exist and should be reviewed.'         ),          CURRENT_TIMESTAMP()      FROM CONTROL.FAOSTAT_CLEAN_REJECTS;         UPDATE CONTROL.DQ_RUNS run      SET         total_tests = summary.total_tests,          passed_tests = summary.passed_tests,          warning_tests = summary.warning_tests,          failed_tests = summary.failed_tests,          run_status =             CASE                 WHEN summary.failed_tests > 0                     THEN 'FAILED'                  WHEN summary.warning_tests > 0                     THEN 'WARNING'                  ELSE 'PASSED'             END,          completed_at_utc =             CURRENT_TIMESTAMP()      FROM (          SELECT             dq_run_id,              COUNT(*) AS total_tests,              COUNT_IF(test_status = 'PASS')                 AS passed_tests,              COUNT_IF(test_status = 'WARN')                 AS warning_tests,              COUNT_IF(                 test_status = 'FAIL'                 AND severity = 'ERROR'             ) AS failed_tests          FROM CONTROL.DQ_RESULTS          WHERE dq_run_id = :v_dq_run_id          GROUP BY dq_run_id      ) summary      WHERE run.dq_run_id = summary.dq_run_id;       SELECT run_status     INTO :v_status      FROM CONTROL.DQ_RUNS      WHERE dq_run_id = :v_dq_run_id;       RETURN v_dq_run_id || '|' || v_status;  END;  
$$;

-- E. Run DQ manually.
CALL CONTROL.SP_RUN_PIPELINE_DQ_GATE();

SELECT *
FROM CONTROL.DQ_RUNS
ORDER BY started_at_utc DESC
LIMIT 1;

SELECT
    test_name,
    expected_value,
    observed_value,
    test_status,
    failure_count,
    test_message
FROM CONTROL.DQ_RESULTS
WHERE dq_run_id = (
    SELECT dq_run_id
    FROM CONTROL.DQ_RUNS
    ORDER BY started_at_utc DESC
    LIMIT 1
)
ORDER BY test_name;

-- F. Run only after the latest DQ run is PASSED:
-- SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('GFS_DEV.CONTROL.TASK_GFS_ROOT');
