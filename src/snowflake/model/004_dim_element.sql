USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


-- =============================================================================
-- DIM_ELEMENT
--
-- Grain:
--   One row per source_domain + element_code
--
-- Reason:
--   Element codes are domain-specific in the currently profiled FAOSTAT data.
--   No code collisions were found, but no element codes were shared across
--   multiple domains either.
-- =============================================================================


CREATE SEQUENCE IF NOT EXISTS GFS_DEV.CONTROL.ELEMENT_KEY_SEQ
    START = 1
    INCREMENT = 1;


CREATE TABLE IF NOT EXISTS GFS_DEV.CONSUMPTION.DIM_ELEMENT (

    element_key        NUMBER       NOT NULL,

    source_domain      STRING       NOT NULL,
    element_code       STRING       NOT NULL,
    element_name       STRING       NOT NULL,

    created_at_utc     TIMESTAMP_TZ NOT NULL,
    updated_at_utc     TIMESTAMP_TZ

);


MERGE INTO GFS_DEV.CONSUMPTION.DIM_ELEMENT AS target

USING (

    SELECT DISTINCT
        source_domain,
        element_code,
        element_name

    FROM (

        SELECT source_domain, element_code, element_name
        FROM GFS_DEV.CLEAN.FAOSTAT_QCL

        UNION ALL

        SELECT source_domain, element_code, element_name
        FROM GFS_DEV.CLEAN.FAOSTAT_LC

        UNION ALL

        SELECT source_domain, element_code, element_name
        FROM GFS_DEV.CLEAN.FAOSTAT_ESB

        UNION ALL

        SELECT source_domain, element_code, element_name
        FROM GFS_DEV.CLEAN.FAOSTAT_FBS

        UNION ALL

        SELECT source_domain, element_code, element_name
        FROM GFS_DEV.CLEAN.FAOSTAT_GT

        UNION ALL

        SELECT source_domain, element_code, element_name
        FROM GFS_DEV.CLEAN.FAOSTAT_FS
    )

    WHERE element_code IS NOT NULL
      AND element_name IS NOT NULL

) AS source

ON  target.source_domain = source.source_domain
AND target.element_code = source.element_code


WHEN MATCHED THEN UPDATE SET

    target.element_name =
        source.element_name,

    target.updated_at_utc =
        CURRENT_TIMESTAMP()


WHEN NOT MATCHED THEN INSERT (

    element_key,
    source_domain,
    element_code,
    element_name,
    created_at_utc,
    updated_at_utc

)

VALUES (

    GFS_DEV.CONTROL.ELEMENT_KEY_SEQ.NEXTVAL,
    source.source_domain,
    source.element_code,
    source.element_name,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
);