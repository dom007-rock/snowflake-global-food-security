USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


-- =============================================================================
-- DIM_SOURCE
--
-- Grain:
--   One row per source_domain + source_code
--
-- Current use:
--   FAOSTAT GT observation-level source/method values
--
-- Example:
--   GT + 3050 -> FAO TIER 1
-- =============================================================================


CREATE SEQUENCE IF NOT EXISTS GFS_DEV.CONTROL.SOURCE_KEY_SEQ
    START = 1
    INCREMENT = 1;


CREATE TABLE IF NOT EXISTS GFS_DEV.CONSUMPTION.DIM_SOURCE (

    source_key          NUMBER       NOT NULL,

    source_domain       STRING       NOT NULL,
    source_code         STRING       NOT NULL,
    source_name         STRING       NOT NULL,

    created_at_utc      TIMESTAMP_TZ NOT NULL,
    updated_at_utc      TIMESTAMP_TZ

);


MERGE INTO GFS_DEV.CONSUMPTION.DIM_SOURCE AS target

USING (

    SELECT DISTINCT
        source_domain,
        source_code,
        source_name

    FROM GFS_DEV.CLEAN.FAOSTAT_GT

    WHERE source_code IS NOT NULL
      AND source_name IS NOT NULL

) AS source

ON  target.source_domain = source.source_domain
AND target.source_code   = source.source_code


WHEN MATCHED THEN UPDATE SET

    target.source_name =
        source.source_name,

    target.updated_at_utc =
        CURRENT_TIMESTAMP()


WHEN NOT MATCHED THEN INSERT (

    source_key,
    source_domain,
    source_code,
    source_name,
    created_at_utc,
    updated_at_utc

)

VALUES (

    GFS_DEV.CONTROL.SOURCE_KEY_SEQ.NEXTVAL,
    source.source_domain,
    source.source_code,
    source.source_name,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
);