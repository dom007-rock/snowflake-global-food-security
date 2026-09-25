USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CLEAN;


CREATE OR REPLACE TABLE FAOSTAT_LC AS

WITH source AS (

    SELECT
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc

    FROM GFS_DEV.RAW.FAOSTAT_LC
)

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

WHERE NULLIF(TRIM(src:"Area Code"::STRING), '') IS NOT NULL
  AND NULLIF(TRIM(src:"Item Code"::STRING), '') IS NOT NULL
  AND NULLIF(TRIM(src:"Element Code"::STRING), '') IS NOT NULL
  AND TRY_TO_NUMBER(
        NULLIF(TRIM(src:"Year"::STRING), '')
      ) IS NOT NULL;

USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CLEAN;


CREATE OR REPLACE TABLE FAOSTAT_ESB AS

WITH source AS (

    SELECT
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc

    FROM GFS_DEV.RAW.FAOSTAT_ESB
)

SELECT
    _source_system AS source_system,
    _source_domain AS source_domain,

    NULLIF(TRIM(src:"Area Code"::STRING), '') AS area_code_fao,

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

    NULLIF(TRIM(src:"Area"::STRING), '') AS area_name,

    NULLIF(TRIM(src:"Item Code"::STRING), '') AS item_code,
    NULLIF(TRIM(src:"Item"::STRING), '') AS item_name,

    NULLIF(TRIM(src:"Element Code"::STRING), '') AS element_code,
    NULLIF(TRIM(src:"Element"::STRING), '') AS element_name,

    NULLIF(TRIM(src:"Year Code"::STRING), '') AS year_code,

    TRY_TO_NUMBER(
        NULLIF(TRIM(src:"Year"::STRING), '')
    ) AS year,

    NULLIF(TRIM(src:"Unit"::STRING), '') AS unit,

    TRY_TO_DECIMAL(
        NULLIF(TRIM(src:"Value"::STRING), ''),
        38,
        10
    ) AS value,

    NULLIF(TRIM(src:"Flag"::STRING), '') AS flag_code,
    NULLIF(TRIM(src:"Flag Description"::STRING), '') AS flag_description,
    NULLIF(TRIM(src:"Note"::STRING), '') AS note,

    _source_row_hash AS source_row_hash,
    _ingestion_run_id AS ingestion_run_id,
    _ingestion_batch_id AS ingestion_batch_id,
    _extracted_at_utc AS extracted_at_utc,

    CURRENT_TIMESTAMP() AS cleaned_at_utc

FROM source

WHERE NULLIF(TRIM(src:"Area Code"::STRING), '') IS NOT NULL
  AND NULLIF(TRIM(src:"Item Code"::STRING), '') IS NOT NULL
  AND NULLIF(TRIM(src:"Element Code"::STRING), '') IS NOT NULL
  AND TRY_TO_NUMBER(
        NULLIF(TRIM(src:"Year"::STRING), '')
      ) IS NOT NULL;

USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CLEAN;


CREATE OR REPLACE TABLE FAOSTAT_FBS AS

WITH source AS (

    SELECT
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc

    FROM GFS_DEV.RAW.FAOSTAT_FBS
)

SELECT
    _source_system AS source_system,
    _source_domain AS source_domain,

    NULLIF(TRIM(src:"Area Code"::STRING), '') AS area_code_fao,

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

    NULLIF(TRIM(src:"Area"::STRING), '') AS area_name,

    NULLIF(TRIM(src:"Item Code"::STRING), '') AS item_code,
    NULLIF(TRIM(src:"Item"::STRING), '') AS item_name,

    NULLIF(TRIM(src:"Element Code"::STRING), '') AS element_code,
    NULLIF(TRIM(src:"Element"::STRING), '') AS element_name,

    NULLIF(TRIM(src:"Year Code"::STRING), '') AS year_code,

    TRY_TO_NUMBER(
        NULLIF(TRIM(src:"Year"::STRING), '')
    ) AS year,

    NULLIF(TRIM(src:"Unit"::STRING), '') AS unit,

    TRY_TO_DECIMAL(
        NULLIF(TRIM(src:"Value"::STRING), ''),
        38,
        10
    ) AS value,

    NULLIF(TRIM(src:"Flag"::STRING), '') AS flag_code,
    NULLIF(TRIM(src:"Flag Description"::STRING), '') AS flag_description,
    NULLIF(TRIM(src:"Note"::STRING), '') AS note,

    _source_row_hash AS source_row_hash,
    _ingestion_run_id AS ingestion_run_id,
    _ingestion_batch_id AS ingestion_batch_id,
    _extracted_at_utc AS extracted_at_utc,

    CURRENT_TIMESTAMP() AS cleaned_at_utc

FROM source

WHERE NULLIF(TRIM(src:"Area Code"::STRING), '') IS NOT NULL
  AND NULLIF(TRIM(src:"Item Code"::STRING), '') IS NOT NULL
  AND NULLIF(TRIM(src:"Element Code"::STRING), '') IS NOT NULL
  AND TRY_TO_NUMBER(
        NULLIF(TRIM(src:"Year"::STRING), '')
      ) IS NOT NULL;

USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CLEAN;


CREATE OR REPLACE TABLE FAOSTAT_GT AS

WITH source AS (

    SELECT
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc

    FROM GFS_DEV.RAW.FAOSTAT_GT
)

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

    NULLIF(TRIM(src:"Source Code"::STRING), '')
        AS source_code,

    NULLIF(TRIM(src:"Source"::STRING), '')
        AS source_name,

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

    NULLIF(TRIM(src:"Note"::STRING), '')
        AS note,

    _source_row_hash AS source_row_hash,
    _ingestion_run_id AS ingestion_run_id,
    _ingestion_batch_id AS ingestion_batch_id,
    _extracted_at_utc AS extracted_at_utc,

    CURRENT_TIMESTAMP() AS cleaned_at_utc

FROM source

WHERE NULLIF(TRIM(src:"Area Code"::STRING), '') IS NOT NULL

  AND NULLIF(TRIM(src:"Item Code"::STRING), '') IS NOT NULL

  AND NULLIF(TRIM(src:"Element Code"::STRING), '') IS NOT NULL

  AND NULLIF(TRIM(src:"Source Code"::STRING), '') IS NOT NULL

  AND TRY_TO_NUMBER(
        NULLIF(TRIM(src:"Year"::STRING), '')
      ) IS NOT NULL;

CREATE OR REPLACE TABLE FAOSTAT_FS AS

WITH source AS (

    SELECT
        PARSE_JSON(source_payload) AS src,

        _source_system,
        _source_domain,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc

    FROM GFS_DEV.RAW.FAOSTAT_FS
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
            AS indicator_code,

        NULLIF(TRIM(src:"Item"::STRING), '')
            AS indicator_name,

        NULLIF(TRIM(src:"Element Code"::STRING), '')
            AS element_code,

        NULLIF(TRIM(src:"Element"::STRING), '')
            AS element_name,

        NULLIF(TRIM(src:"Year Code"::STRING), '')
            AS period_code,

        NULLIF(TRIM(src:"Year"::STRING), '')
            AS period_label,

        CASE
            WHEN REGEXP_LIKE(
                NULLIF(TRIM(src:"Year"::STRING), ''),
                '^[0-9]{4}$'
            )
            THEN TRY_TO_NUMBER(src:"Year"::STRING)

            WHEN REGEXP_LIKE(
                NULLIF(TRIM(src:"Year"::STRING), ''),
                '^[0-9]{4}-[0-9]{4}$'
            )
            THEN TRY_TO_NUMBER(
                SPLIT_PART(src:"Year"::STRING, '-', 1)
            )
        END AS period_start_year,

        CASE
            WHEN REGEXP_LIKE(
                NULLIF(TRIM(src:"Year"::STRING), ''),
                '^[0-9]{4}$'
            )
            THEN TRY_TO_NUMBER(src:"Year"::STRING)

            WHEN REGEXP_LIKE(
                NULLIF(TRIM(src:"Year"::STRING), ''),
                '^[0-9]{4}-[0-9]{4}$'
            )
            THEN TRY_TO_NUMBER(
                SPLIT_PART(src:"Year"::STRING, '-', 2)
            )
        END AS period_end_year,

        CASE
            WHEN REGEXP_LIKE(
                NULLIF(TRIM(src:"Year"::STRING), ''),
                '^[0-9]{4}$'
            )
            THEN 'ANNUAL'

            WHEN REGEXP_LIKE(
                NULLIF(TRIM(src:"Year"::STRING), ''),
                '^[0-9]{4}-[0-9]{4}$'
            )
            THEN 'MULTI_YEAR'

            ELSE 'UNKNOWN'
        END AS period_type,

        NULLIF(TRIM(src:"Unit"::STRING), '')
            AS unit,

        NULLIF(TRIM(src:"Value"::STRING), '')
            AS value_raw,

        TRY_TO_DECIMAL(
            NULLIF(TRIM(src:"Value"::STRING), ''),
            38,
            10
        ) AS value,

        NULLIF(TRIM(src:"Flag"::STRING), '')
            AS flag_code,

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
  AND indicator_code IS NOT NULL
  AND element_code IS NOT NULL
  AND period_start_year IS NOT NULL
  AND period_end_year IS NOT NULL;