USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CLEAN;


CREATE OR REPLACE TABLE WDI_INDICATOR_METADATA AS

WITH source AS (

    SELECT
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc

    FROM GFS_DEV.RAW.WDI_INDICATOR_METADATA
)

SELECT
    _source_system AS source_system,
    _source_domain AS source_domain,

    NULLIF(TRIM(src:"id"::STRING), '')
        AS indicator_code,

    NULLIF(TRIM(src:"name"::STRING), '')
        AS indicator_name,

    NULLIF(TRIM(src:"unit"::STRING), '')
        AS unit,

    NULLIF(TRIM(src:"source":"id"::STRING), '')
        AS source_id,

    NULLIF(TRIM(src:"source":"value"::STRING), '')
        AS source_name,

    NULLIF(TRIM(src:"sourceNote"::STRING), '')
        AS source_note,

    NULLIF(TRIM(src:"sourceOrganization"::STRING), '')
        AS source_organization,

    src:"topics"
        AS topics,

    _source_row_hash AS source_row_hash,
    _ingestion_run_id AS ingestion_run_id,
    _ingestion_batch_id AS ingestion_batch_id,
    _extracted_at_utc AS extracted_at_utc,

    CURRENT_TIMESTAMP() AS cleaned_at_utc

FROM source

WHERE NULLIF(TRIM(src:"id"::STRING), '') IS NOT NULL;