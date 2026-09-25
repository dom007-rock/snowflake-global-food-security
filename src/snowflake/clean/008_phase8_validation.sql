USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


WITH counts AS (

    SELECT
        'QCL' AS domain,
        (SELECT COUNT(*) FROM RAW.FAOSTAT_QCL) AS raw_count,
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_QCL) AS clean_count

    UNION ALL
    SELECT 'LC',
        (SELECT COUNT(*) FROM RAW.FAOSTAT_LC),
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_LC)

    UNION ALL
    SELECT 'ESB',
        (SELECT COUNT(*) FROM RAW.FAOSTAT_ESB),
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_ESB)

    UNION ALL
    SELECT 'FBS',
        (SELECT COUNT(*) FROM RAW.FAOSTAT_FBS),
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_FBS)

    UNION ALL
    SELECT 'GT',
        (SELECT COUNT(*) FROM RAW.FAOSTAT_GT),
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_GT)

    UNION ALL
    SELECT 'FS',
        (SELECT COUNT(*) FROM RAW.FAOSTAT_FS),
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_FS)
),

rejects AS (

    SELECT
        domain,
        COUNT(*) AS reject_count
    FROM CONTROL.FAOSTAT_CLEAN_REJECTS
    GROUP BY domain
),

required_fields AS (

    SELECT
        'QCL' AS domain,
        COUNT_IF(
            area_code_fao IS NULL
            OR item_code IS NULL
            OR element_code IS NULL
            OR year IS NULL
        ) AS invalid_rows
    FROM CLEAN.FAOSTAT_QCL

    UNION ALL

    SELECT 'LC',
        COUNT_IF(
            area_code_fao IS NULL
            OR item_code IS NULL
            OR element_code IS NULL
            OR year IS NULL
        )
    FROM CLEAN.FAOSTAT_LC

    UNION ALL

    SELECT 'ESB',
        COUNT_IF(
            area_code_fao IS NULL
            OR item_code IS NULL
            OR element_code IS NULL
            OR year IS NULL
        )
    FROM CLEAN.FAOSTAT_ESB

    UNION ALL

    SELECT 'FBS',
        COUNT_IF(
            area_code_fao IS NULL
            OR item_code IS NULL
            OR element_code IS NULL
            OR year IS NULL
        )
    FROM CLEAN.FAOSTAT_FBS

    UNION ALL

    SELECT 'GT',
        COUNT_IF(
            area_code_fao IS NULL
            OR item_code IS NULL
            OR element_code IS NULL
            OR source_code IS NULL
            OR year IS NULL
        )
    FROM CLEAN.FAOSTAT_GT

    UNION ALL

    SELECT 'FS',
        COUNT_IF(
            area_code_fao IS NULL
            OR indicator_code IS NULL
            OR element_code IS NULL
            OR period_start_year IS NULL
            OR period_end_year IS NULL
        )
    FROM CLEAN.FAOSTAT_FS
),

duplicates AS (

    SELECT 'QCL' AS domain, COUNT(*) AS duplicate_groups
    FROM (
        SELECT
            area_code_fao,
            item_code,
            element_code,
            year_code
        FROM CLEAN.FAOSTAT_QCL
        GROUP BY 1,2,3,4
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT 'LC', COUNT(*)
    FROM (
        SELECT area_code_fao, item_code, element_code, year_code
        FROM CLEAN.FAOSTAT_LC
        GROUP BY 1,2,3,4
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT 'ESB', COUNT(*)
    FROM (
        SELECT area_code_fao, item_code, element_code, year_code
        FROM CLEAN.FAOSTAT_ESB
        GROUP BY 1,2,3,4
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT 'FBS', COUNT(*)
    FROM (
        SELECT area_code_fao, item_code, element_code, year_code
        FROM CLEAN.FAOSTAT_FBS
        GROUP BY 1,2,3,4
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT 'GT', COUNT(*)
    FROM (
        SELECT
            area_code_fao,
            item_code,
            element_code,
            source_code,
            year_code
        FROM CLEAN.FAOSTAT_GT
        GROUP BY 1,2,3,4,5
        HAVING COUNT(*) > 1
    )

    UNION ALL

    SELECT 'FS', COUNT(*)
    FROM (
        SELECT
            area_code_fao,
            indicator_code,
            element_code,
            period_code
        FROM CLEAN.FAOSTAT_FS
        GROUP BY 1,2,3,4
        HAVING COUNT(*) > 1
    )
),

scope_check AS (

    SELECT
        'QCL' AS domain,
        COUNT_IF(year < 2010 OR year > 2023) AS violations
    FROM CLEAN.FAOSTAT_QCL

    UNION ALL
    SELECT 'LC', COUNT_IF(year < 2010 OR year > 2023)
    FROM CLEAN.FAOSTAT_LC

    UNION ALL
    SELECT 'ESB', COUNT_IF(year < 2010 OR year > 2023)
    FROM CLEAN.FAOSTAT_ESB

    UNION ALL
    SELECT 'FBS', COUNT_IF(year < 2010 OR year > 2023)
    FROM CLEAN.FAOSTAT_FBS

    UNION ALL
    SELECT 'GT', COUNT_IF(year < 2010 OR year > 2023)
    FROM CLEAN.FAOSTAT_GT

    UNION ALL
    SELECT 'FS',
        COUNT_IF(
            period_start_year < 2010
            OR period_end_year > 2023
        )
    FROM CLEAN.FAOSTAT_FS
),

m49_check AS (

    SELECT 'QCL' AS domain,
        COUNT_IF(
            area_code_m49 IS NOT NULL
            AND NOT REGEXP_LIKE(area_code_m49, '^[0-9]{3}$')
        ) AS invalid_m49
    FROM CLEAN.FAOSTAT_QCL

    UNION ALL
    SELECT 'LC', COUNT_IF(
        area_code_m49 IS NOT NULL
        AND NOT REGEXP_LIKE(area_code_m49, '^[0-9]{3}$')
    )
    FROM CLEAN.FAOSTAT_LC

    UNION ALL
    SELECT 'ESB', COUNT_IF(
        area_code_m49 IS NOT NULL
        AND NOT REGEXP_LIKE(area_code_m49, '^[0-9]{3}$')
    )
    FROM CLEAN.FAOSTAT_ESB

    UNION ALL
    SELECT 'FBS', COUNT_IF(
        area_code_m49 IS NOT NULL
        AND NOT REGEXP_LIKE(area_code_m49, '^[0-9]{3}$')
    )
    FROM CLEAN.FAOSTAT_FBS

    UNION ALL
    SELECT 'GT', COUNT_IF(
        area_code_m49 IS NOT NULL
        AND NOT REGEXP_LIKE(area_code_m49, '^[0-9]{3}$')
    )
    FROM CLEAN.FAOSTAT_GT

    UNION ALL
    SELECT 'FS', COUNT_IF(
        area_code_m49 IS NOT NULL
        AND NOT REGEXP_LIKE(area_code_m49, '^[0-9]{3}$')
    )
    FROM CLEAN.FAOSTAT_FS
),

lineage_check AS (

    SELECT 'QCL' AS domain,
        COUNT_IF(
            source_row_hash IS NULL
            OR ingestion_run_id IS NULL
            OR ingestion_batch_id IS NULL
            OR extracted_at_utc IS NULL
            OR cleaned_at_utc IS NULL
        ) AS missing_lineage
    FROM CLEAN.FAOSTAT_QCL

    UNION ALL
    SELECT 'LC', COUNT_IF(
        source_row_hash IS NULL
        OR ingestion_run_id IS NULL
        OR ingestion_batch_id IS NULL
        OR extracted_at_utc IS NULL
        OR cleaned_at_utc IS NULL
    )
    FROM CLEAN.FAOSTAT_LC

    UNION ALL
    SELECT 'ESB', COUNT_IF(
        source_row_hash IS NULL
        OR ingestion_run_id IS NULL
        OR ingestion_batch_id IS NULL
        OR extracted_at_utc IS NULL
        OR cleaned_at_utc IS NULL
    )
    FROM CLEAN.FAOSTAT_ESB

    UNION ALL
    SELECT 'FBS', COUNT_IF(
        source_row_hash IS NULL
        OR ingestion_run_id IS NULL
        OR ingestion_batch_id IS NULL
        OR extracted_at_utc IS NULL
        OR cleaned_at_utc IS NULL
    )
    FROM CLEAN.FAOSTAT_FBS

    UNION ALL
    SELECT 'GT', COUNT_IF(
        source_row_hash IS NULL
        OR ingestion_run_id IS NULL
        OR ingestion_batch_id IS NULL
        OR extracted_at_utc IS NULL
        OR cleaned_at_utc IS NULL
    )
    FROM CLEAN.FAOSTAT_GT

    UNION ALL
    SELECT 'FS', COUNT_IF(
        source_row_hash IS NULL
        OR ingestion_run_id IS NULL
        OR ingestion_batch_id IS NULL
        OR extracted_at_utc IS NULL
        OR cleaned_at_utc IS NULL
    )
    FROM CLEAN.FAOSTAT_FS
)

SELECT
    c.domain,

    c.raw_count,
    c.clean_count,
    COALESCE(r.reject_count, 0) AS reject_count,

    c.raw_count =
        c.clean_count + COALESCE(r.reject_count, 0)
        AS reconciliation_passed,

    rf.invalid_rows AS required_field_violations,
    d.duplicate_groups,
    s.violations AS scope_violations,
    m.invalid_m49,
    l.missing_lineage,

    (
        c.raw_count =
            c.clean_count + COALESCE(r.reject_count, 0)

        AND rf.invalid_rows = 0
        AND d.duplicate_groups = 0
        AND s.violations = 0
        AND m.invalid_m49 = 0
        AND l.missing_lineage = 0
    ) AS phase8_dq_passed

FROM counts c

LEFT JOIN rejects r
    ON c.domain = r.domain

JOIN required_fields rf
    ON c.domain = rf.domain

JOIN duplicates d
    ON c.domain = d.domain

JOIN scope_check s
    ON c.domain = s.domain

JOIN m49_check m
    ON c.domain = m.domain

JOIN lineage_check l
    ON c.domain = l.domain

ORDER BY c.domain;