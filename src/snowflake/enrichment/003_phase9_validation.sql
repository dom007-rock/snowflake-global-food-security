USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


WITH tests AS (

    -- ---------------------------------------------------------
    -- 1. RAW -> CLEAN reconciliation
    -- ---------------------------------------------------------

    SELECT
        'WDI_RAW_CLEAN_RECONCILIATION' AS test_name,

        (
            SELECT COUNT(*)
            FROM RAW.WDI_OBSERVATIONS
        ) -
        (
            SELECT COUNT(*)
            FROM CLEAN.WDI_OBSERVATIONS
        ) AS observed_value,

        0 AS expected_value

    UNION ALL


    -- ---------------------------------------------------------
    -- 2. Observation grain
    -- ---------------------------------------------------------

    SELECT
        'WDI_DUPLICATE_GRAIN',

        COUNT(*),

        0

    FROM (

        SELECT
            wb_entity_id,
            indicator_code,
            year

        FROM CLEAN.WDI_OBSERVATIONS

        GROUP BY
            wb_entity_id,
            indicator_code,
            year

        HAVING COUNT(*) > 1
    )


    UNION ALL


    -- ---------------------------------------------------------
    -- 3. Five selected indicators only
    -- ---------------------------------------------------------

    SELECT
        'WDI_INDICATOR_COUNT',

        COUNT(DISTINCT indicator_code),

        5

    FROM CLEAN.WDI_OBSERVATIONS


    UNION ALL


    -- ---------------------------------------------------------
    -- 4. Year contract
    -- ---------------------------------------------------------

    SELECT
        'WDI_YEAR_SCOPE_VIOLATIONS',

        COUNT_IF(
            year < 2010
            OR year > 2023
        ),

        0

    FROM CLEAN.WDI_OBSERVATIONS


    UNION ALL


    -- ---------------------------------------------------------
    -- 5. Indicator metadata
    -- ---------------------------------------------------------

    SELECT
        'WDI_METADATA_INDICATOR_COUNT',

        COUNT(DISTINCT indicator_code),

        5

    FROM CLEAN.WDI_INDICATOR_METADATA


    UNION ALL


    -- ---------------------------------------------------------
    -- 6. Crosswalk uniqueness
    -- ---------------------------------------------------------

    SELECT
        'CROSSWALK_DUPLICATE_FAO_CODES',

        COUNT(*),

        0

    FROM (

        SELECT
            area_code_fao

        FROM CONTROL.GEOGRAPHY_CROSSWALK

        GROUP BY area_code_fao

        HAVING COUNT(*) > 1
    )


    UNION ALL


    -- ---------------------------------------------------------
    -- 7. Every mapped geography must have integration keys
    -- ---------------------------------------------------------

    SELECT
        'MAPPED_ROWS_MISSING_KEYS',

        COUNT(*),

        0

    FROM CONTROL.GEOGRAPHY_CROSSWALK

    WHERE mapping_status = 'MAPPED'

      AND (
          country_iso3 IS NULL
          OR world_bank_name IS NULL
      )


    UNION ALL


    -- ---------------------------------------------------------
    -- 8. Every mapped ISO3 must actually exist in WDI
    -- ---------------------------------------------------------

    SELECT
        'MAPPED_ISO3_WITHOUT_WDI',

        COUNT(*),

        0

    FROM CONTROL.GEOGRAPHY_CROSSWALK g

    WHERE g.mapping_status = 'MAPPED'

      AND NOT EXISTS (

          SELECT 1

          FROM CLEAN.WDI_OBSERVATIONS w

          WHERE w.wb_iso3_code = g.country_iso3
      )


    UNION ALL


    -- ---------------------------------------------------------
    -- 9. Known special cases
    -- ---------------------------------------------------------

    SELECT
        'MANUAL_REVIEW_EXCEPTIONS',

        COUNT(*),

        5

    FROM CONTROL.GEOGRAPHY_CROSSWALK

    WHERE mapping_status = 'MANUAL_REVIEW'


    UNION ALL


    -- ---------------------------------------------------------
    -- 10. Prove our reference enrichment works
    -- ---------------------------------------------------------

    SELECT
        'INDIA_WDI_JOIN_AVAILABLE',

        IFF(COUNT(*) > 0, 1, 0),

        1

    FROM CLEAN.WDI_OBSERVATIONS w

    WHERE w.wb_iso3_code = 'IND'

)

SELECT
    test_name,
    observed_value,
    expected_value,

    observed_value = expected_value
        AS test_passed

FROM tests

ORDER BY test_name;