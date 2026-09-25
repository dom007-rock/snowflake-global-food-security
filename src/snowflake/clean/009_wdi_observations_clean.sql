USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CLEAN;


CREATE OR REPLACE TABLE WDI_OBSERVATIONS AS

WITH source AS (

    SELECT
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc

    FROM GFS_DEV.RAW.WDI_OBSERVATIONS
)

SELECT
    _source_system AS source_system,
    _source_domain AS source_domain,

    -- World Bank's own entity identifier.
    -- This is our grain key, not countryiso3code.
    NULLIF(
        TRIM(src:"country":"id"::STRING),
        ''
    ) AS wb_entity_id,

    NULLIF(
        TRIM(src:"country":"value"::STRING),
        ''
    ) AS wb_entity_name,

    -- ISO3-style code when World Bank provides one.
    -- Valid entities may legitimately have this as NULL.
    NULLIF(
        TRIM(src:"countryiso3code"::STRING),
        ''
    ) AS wb_iso3_code,

    NULLIF(
        TRIM(src:"indicator":"id"::STRING),
        ''
    ) AS indicator_code,

    NULLIF(
        TRIM(src:"indicator":"value"::STRING),
        ''
    ) AS indicator_name,

    TRY_TO_NUMBER(
        NULLIF(TRIM(src:"date"::STRING), '')
    ) AS year,

    TRY_TO_DECIMAL(
        NULLIF(TRIM(src:"value"::STRING), ''),
        38,
        10
    ) AS value,

    NULLIF(
        TRIM(src:"unit"::STRING),
        ''
    ) AS unit,

    TRY_TO_NUMBER(
        NULLIF(TRIM(src:"decimal"::STRING), '')
    ) AS decimal_places,

    NULLIF(
        TRIM(src:"obs_status"::STRING),
        ''
    ) AS observation_status,

    _source_row_hash AS source_row_hash,
    _ingestion_run_id AS ingestion_run_id,
    _ingestion_batch_id AS ingestion_batch_id,
    _extracted_at_utc AS extracted_at_utc,

    CURRENT_TIMESTAMP() AS cleaned_at_utc

FROM source

WHERE NULLIF(
        TRIM(src:"country":"id"::STRING),
        ''
      ) IS NOT NULL

  AND NULLIF(
        TRIM(src:"indicator":"id"::STRING),
        ''
      ) IS NOT NULL

  AND TRY_TO_NUMBER(
        NULLIF(TRIM(src:"date"::STRING), '')
      ) BETWEEN 2010 AND 2023;