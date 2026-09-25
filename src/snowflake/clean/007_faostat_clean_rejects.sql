USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CONTROL;


CREATE OR REPLACE TABLE FAOSTAT_CLEAN_REJECTS AS

WITH raw_union AS (

    SELECT
        'QCL' AS domain,
        source_payload,
        PARSE_JSON(source_payload) AS src,
        _source_system,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc
    FROM GFS_DEV.RAW.FAOSTAT_QCL

    UNION ALL

    SELECT
        'LC',
        source_payload,
        PARSE_JSON(source_payload),
        _source_system,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc
    FROM GFS_DEV.RAW.FAOSTAT_LC

    UNION ALL

    SELECT
        'ESB',
        source_payload,
        PARSE_JSON(source_payload),
        _source_system,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc
    FROM GFS_DEV.RAW.FAOSTAT_ESB

    UNION ALL

    SELECT
        'FBS',
        source_payload,
        PARSE_JSON(source_payload),
        _source_system,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc
    FROM GFS_DEV.RAW.FAOSTAT_FBS

    UNION ALL

    SELECT
        'GT',
        source_payload,
        PARSE_JSON(source_payload),
        _source_system,
        _source_row_hash,
        _ingestion_run_id,
        _ingestion_batch_id,
        _extracted_at_utc
    FROM GFS_DEV.RAW.FAOSTAT_GT

    UNION ALL

    SELECT
        'FS',
        source_payload,
        PARSE_JSON(source_payload),
        _source_system,
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
            AS item_code,

        NULLIF(TRIM(src:"Element Code"::STRING), '')
            AS element_code,

        NULLIF(TRIM(src:"Source Code"::STRING), '')
            AS source_code,

        NULLIF(TRIM(src:"Year"::STRING), '')
            AS period_raw,

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

    FROM raw_union
),

classified AS (

    SELECT
        *,

        CASE
            WHEN area_code_fao IS NULL
                THEN 'MISSING_AREA_CODE'

            WHEN item_code IS NULL
                THEN IFF(
                    domain = 'FS',
                    'MISSING_INDICATOR_CODE',
                    'MISSING_ITEM_CODE'
                )

            WHEN element_code IS NULL
                THEN 'MISSING_ELEMENT_CODE'

            WHEN domain = 'GT'
                 AND source_code IS NULL
                THEN 'MISSING_SOURCE_CODE'

            WHEN period_raw IS NULL
                THEN 'MISSING_PERIOD'

            WHEN domain = 'FS'
                 AND NOT REGEXP_LIKE(
                     period_raw,
                     '^[0-9]{4}$|^[0-9]{4}-[0-9]{4}$'
                 )
                THEN 'INVALID_PERIOD_FORMAT'

            WHEN domain <> 'FS'
                 AND parsed_year IS NULL
                THEN 'INVALID_YEAR'

            WHEN domain <> 'FS'
                 AND value_raw IS NOT NULL
                 AND parsed_value IS NULL
                THEN 'INVALID_VALUE'

        END AS rejection_reason

    FROM validated
)

SELECT
    domain,
    rejection_reason,
    source_payload,

    _source_system AS source_system,
    _source_row_hash AS source_row_hash,
    _ingestion_run_id AS ingestion_run_id,
    _ingestion_batch_id AS ingestion_batch_id,
    _extracted_at_utc AS extracted_at_utc,

    CURRENT_TIMESTAMP() AS rejected_at_utc

FROM classified

WHERE rejection_reason IS NOT NULL;