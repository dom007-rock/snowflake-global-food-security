USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


-- =============================================================================
-- DIM_INDICATOR
--
-- Grain:
--   One row per source_system + source_domain + indicator_code
--
-- Sources:
--   FAOSTAT FS
--   World Bank WDI
--
-- Indicators are stored in one analytical dimension, but their source identity
-- remains part of the business key because FAOSTAT and WDI use independent
-- coding systems.
-- =============================================================================


CREATE SEQUENCE IF NOT EXISTS GFS_DEV.CONTROL.INDICATOR_KEY_SEQ
    START = 1
    INCREMENT = 1;


CREATE TABLE IF NOT EXISTS GFS_DEV.CONSUMPTION.DIM_INDICATOR (

    indicator_key        NUMBER       NOT NULL,

    source_system        STRING       NOT NULL,
    source_domain        STRING       NOT NULL,

    indicator_code       STRING       NOT NULL,
    indicator_name       STRING       NOT NULL,

    created_at_utc       TIMESTAMP_TZ NOT NULL,
    updated_at_utc       TIMESTAMP_TZ

);


MERGE INTO GFS_DEV.CONSUMPTION.DIM_INDICATOR AS target

USING (

    SELECT DISTINCT
        source_system,
        source_domain,
        indicator_code,
        indicator_name

    FROM GFS_DEV.CLEAN.FAOSTAT_FS

    WHERE indicator_code IS NOT NULL
      AND indicator_name IS NOT NULL


    UNION ALL


    SELECT DISTINCT
        'WORLD_BANK' AS source_system,
        'WDI' AS source_domain,
        indicator_code,
        indicator_name

    FROM GFS_DEV.CLEAN.WDI_INDICATOR_METADATA

    WHERE indicator_code IS NOT NULL
      AND indicator_name IS NOT NULL

) AS source

ON  target.source_system  = source.source_system
AND target.source_domain  = source.source_domain
AND target.indicator_code = source.indicator_code


WHEN MATCHED THEN UPDATE SET

    target.indicator_name =
        source.indicator_name,

    target.updated_at_utc =
        CURRENT_TIMESTAMP()


WHEN NOT MATCHED THEN INSERT (

    indicator_key,

    source_system,
    source_domain,

    indicator_code,
    indicator_name,

    created_at_utc,
    updated_at_utc

)

VALUES (

    GFS_DEV.CONTROL.INDICATOR_KEY_SEQ.NEXTVAL,

    source.source_system,
    source.source_domain,

    source.indicator_code,
    source.indicator_name,

    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
);