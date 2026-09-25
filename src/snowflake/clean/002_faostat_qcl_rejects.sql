USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CLEAN;


CREATE OR REPLACE TABLE FAOSTAT_QCL_REJECTS AS

WITH source AS (

    SELECT
        source_payload,
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc,
        _source_row_hash

    FROM GFS_DEV.RAW.FAOSTAT_QCL
),

validated AS (

    SELECT
        *,

        NULLIF(TRIM(src:"Area Code"::STRING), '') AS area_code_fao,
        NULLIF(TRIM(src:"Item Code"::STRING), '') AS item_code,
        NULLIF(TRIM(src:"Element Code"::STRING), '') AS element_code,

        NULLIF(TRIM(src:"Year"::STRING), '') AS year_raw,
        NULLIF(TRIM(src:"Value"::STRING), '') AS value_raw,

        TRY_TO_NUMBER(
            NULLIF(TRIM(src:"Year"::STRING), '')
        ) AS parsed_year,

        TRY_TO_DECIMAL(
            NULLIF(TRIM(src:"Value"::STRING), ''),
            38,
            10
        ) AS parsed_value

    FROM source
),

rejected AS (

    SELECT
        *,

        CASE
            WHEN area_code_fao IS NULL
                THEN 'MISSING_AREA_CODE'

            WHEN item_code IS NULL
                THEN 'MISSING_ITEM_CODE'

            WHEN element_code IS NULL
                THEN 'MISSING_ELEMENT_CODE'

            WHEN year_raw IS NULL
                THEN 'MISSING_YEAR'

            WHEN parsed_year IS NULL
                THEN 'INVALID_YEAR'

            WHEN value_raw IS NOT NULL
                 AND parsed_value IS NULL
                THEN 'INVALID_VALUE'
        END AS rejection_reason

    FROM validated
)

SELECT
    source_payload,

    rejection_reason,

    _source_system       AS source_system,
    _source_domain       AS source_domain,
    _source_row_hash     AS source_row_hash,
    _ingestion_run_id    AS ingestion_run_id,
    _ingestion_batch_id  AS ingestion_batch_id,
    _extracted_at_utc    AS extracted_at_utc,

    CURRENT_TIMESTAMP()  AS rejected_at_utc

FROM rejected

WHERE rejection_reason IS NOT NULL;

CREATE OR REPLACE TABLE GFS_DEV.CLEAN.FAOSTAT_GT_REJECTS AS

WITH source AS (

    SELECT
        source_payload,
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc

    FROM GFS_DEV.RAW.FAOSTAT_GT
),

validated AS (

    SELECT
        *,

        NULLIF(TRIM(src:"Area Code"::STRING), '')
            AS area_code_fao,

        NULLIF(TRIM(src:"Item Code"::STRING), '')
            AS item_code,

        NULLIF(TRIM(src:"Element Code"::STRING), '')
            AS element_code,

        NULLIF(TRIM(src:"Source Code"::STRING), '')
            AS source_code,

        NULLIF(TRIM(src:"Year"::STRING), '')
            AS year_raw,

        NULLIF(TRIM(src:"Value"::STRING), '')
            AS value_raw,

        TRY_TO_NUMBER(
            NULLIF(TRIM(src:"Year"::STRING), '')
        ) AS parsed_year,

        TRY_TO_DECIMAL(
            NULLIF(TRIM(src:"Value"::STRING), ''),
            38,
            10
        ) AS parsed_value

    FROM source
),

rejected AS (

    SELECT
        *,

        CASE
            WHEN area_code_fao IS NULL
                THEN 'MISSING_AREA_CODE'

            WHEN item_code IS NULL
                THEN 'MISSING_ITEM_CODE'

            WHEN element_code IS NULL
                THEN 'MISSING_ELEMENT_CODE'

            WHEN source_code IS NULL
                THEN 'MISSING_SOURCE_CODE'

            WHEN year_raw IS NULL
                THEN 'MISSING_YEAR'

            WHEN parsed_year IS NULL
                THEN 'INVALID_YEAR'

            WHEN value_raw IS NOT NULL
                 AND parsed_value IS NULL
                THEN 'INVALID_VALUE'
        END AS rejection_reason

    FROM validated
)

SELECT
    source_payload,
    rejection_reason,

    _source_system AS source_system,
    _source_domain AS source_domain,
    _source_row_hash AS source_row_hash,
    _ingestion_run_id AS ingestion_run_id,
    _ingestion_batch_id AS ingestion_batch_id,
    _extracted_at_utc AS extracted_at_utc,

    CURRENT_TIMESTAMP() AS rejected_at_utc

FROM rejected

WHERE rejection_reason IS NOT NULL;

USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CLEAN;

CREATE OR REPLACE TABLE GFS_DEV.CLEAN.FAOSTAT_FS_REJECTS AS

WITH source AS (

    SELECT
        source_payload,
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc

    FROM GFS_DEV.RAW.FAOSTAT_FS
),

validated AS (

    SELECT
        *,

        NULLIF(TRIM(src:"Area Code"::STRING), '')
            AS area_code_fao,

        NULLIF(TRIM(src:"Item Code"::STRING), '')
            AS indicator_code,

        NULLIF(TRIM(src:"Element Code"::STRING), '')
            AS element_code,

        NULLIF(TRIM(src:"Year"::STRING), '')
            AS period_label

    FROM source
)

SELECT
    source_payload,

    CASE
        WHEN area_code_fao IS NULL
            THEN 'MISSING_AREA_CODE'

        WHEN indicator_code IS NULL
            THEN 'MISSING_INDICATOR_CODE'

        WHEN element_code IS NULL
            THEN 'MISSING_ELEMENT_CODE'

        WHEN period_label IS NULL
            THEN 'MISSING_PERIOD'

        WHEN NOT REGEXP_LIKE(
            period_label,
            '^[0-9]{4}$|^[0-9]{4}-[0-9]{4}$'
        )
            THEN 'INVALID_PERIOD_FORMAT'

    END AS rejection_reason,

    _source_system AS source_system,
    _source_domain AS source_domain,
    _source_row_hash AS source_row_hash,
    _ingestion_run_id AS ingestion_run_id,
    _ingestion_batch_id AS ingestion_batch_id,
    _extracted_at_utc AS extracted_at_utc,

    CURRENT_TIMESTAMP() AS rejected_at_utc

FROM validated

WHERE area_code_fao IS NULL
   OR indicator_code IS NULL
   OR element_code IS NULL
   OR period_label IS NULL
   OR NOT REGEXP_LIKE(
        period_label,
        '^[0-9]{4}$|^[0-9]{4}-[0-9]{4}$'
      );

