USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CLEAN;


CREATE OR REPLACE TABLE FAOSTAT_QCL AS

WITH source AS (

    SELECT
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc,
        _source_row_hash

    FROM GFS_DEV.RAW.FAOSTAT_QCL
),

standardized AS (

    SELECT
        _source_system AS source_system,
        _source_domain AS source_domain,

        NULLIF(TRIM(src:"Area Code"::STRING), '')
            AS area_code_fao,

        NULLIF(
            TRIM(
                REPLACE(
                    src:"Area Code (M49)"::STRING,
                    '''',
                    ''
                )
            ),
            ''
        ) AS area_code_m49,

        NULLIF(TRIM(src:"Area"::STRING), '')
            AS area_name,

        NULLIF(TRIM(src:"Item Code"::STRING), '')
            AS item_code,

        NULLIF(TRIM(src:"Item"::STRING), '')
            AS item_name,

        NULLIF(TRIM(src:"Element Code"::STRING), '')
            AS element_code,

        NULLIF(TRIM(src:"Element"::STRING), '')
            AS element_name,

        NULLIF(TRIM(src:"Year Code"::STRING), '')
            AS year_code,

        TRY_TO_NUMBER(
            NULLIF(TRIM(src:"Year"::STRING), '')
        ) AS year,

        NULLIF(TRIM(src:"Unit"::STRING), '')
            AS unit,

        TRY_TO_DECIMAL(
            NULLIF(TRIM(src:"Value"::STRING), ''),
            38,
            10
        ) AS value,

        NULLIF(TRIM(src:"Flag"::STRING), '')
            AS flag_code,

        NULLIF(TRIM(src:"Flag Description"::STRING), '')
            AS flag_description,

        NULLIF(TRIM(src:"Note"::STRING), '')
            AS note,

        _source_row_hash AS source_row_hash,
        _ingestion_run_id AS ingestion_run_id,
        _ingestion_batch_id AS ingestion_batch_id,
        _extracted_at_utc AS extracted_at_utc,
        CURRENT_TIMESTAMP() AS cleaned_at_utc

    FROM source
)

SELECT *
FROM standardized

WHERE area_code_fao IS NOT NULL
  AND item_code IS NOT NULL
  AND element_code IS NOT NULL
  AND year IS NOT NULL;