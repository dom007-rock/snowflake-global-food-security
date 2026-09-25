USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;

CREATE OR REPLACE PROCEDURE CONTROL.SP_MERGE_QCL_CLEAN(
    P_RUN_ID STRING
)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$

BEGIN

MERGE INTO GFS_DEV.CLEAN.FAOSTAT_QCL AS target

USING (

    WITH parsed AS (

        SELECT

            _source_system AS source_system,
            _source_domain AS source_domain,

            NULLIF(
                TRIM(PARSE_JSON(source_payload):"Area Code"::STRING),
                ''
            ) AS area_code_fao,

            REGEXP_REPLACE(
                NULLIF(
                    TRIM(
                        PARSE_JSON(source_payload):"Area Code (M49)"::STRING
                    ),
                    ''
                ),
                '^''',
                ''
            ) AS area_code_m49,

            NULLIF(
                TRIM(PARSE_JSON(source_payload):"Area"::STRING),
                ''
            ) AS area_name,

            NULLIF(
                TRIM(PARSE_JSON(source_payload):"Item Code"::STRING),
                ''
            ) AS item_code,

            NULLIF(
                TRIM(PARSE_JSON(source_payload):"Item"::STRING),
                ''
            ) AS item_name,

            NULLIF(
                TRIM(PARSE_JSON(source_payload):"Element Code"::STRING),
                ''
            ) AS element_code,

            NULLIF(
                TRIM(PARSE_JSON(source_payload):"Element"::STRING),
                ''
            ) AS element_name,

            TRY_TO_NUMBER(
                PARSE_JSON(source_payload):"Year"::STRING
            ) AS year,

            NULLIF(
                TRIM(PARSE_JSON(source_payload):"Unit"::STRING),
                ''
            ) AS unit,

            TRY_TO_DECIMAL(
                PARSE_JSON(source_payload):"Value"::STRING,
                38,
                10
            ) AS value,

            NULLIF(
                TRIM(PARSE_JSON(source_payload):"Flag"::STRING),
                ''
            ) AS flag_code,

            NULLIF(
                TRIM(PARSE_JSON(source_payload):"Flag Description"::STRING),
                ''
            ) AS flag_description,

            NULLIF(
                TRIM(PARSE_JSON(source_payload):"Note"::STRING),
                ''
            ) AS note,

            _source_row_hash AS source_row_hash,
            _ingestion_run_id AS ingestion_run_id,
            _ingestion_batch_id AS ingestion_batch_id,

            TRY_TO_TIMESTAMP_TZ(
                _extracted_at_utc
            ) AS extracted_at_utc

        FROM GFS_DEV.RAW.FAOSTAT_QCL

        WHERE _ingestion_run_id = :P_RUN_ID
    ),

    latest AS (

        SELECT *

        FROM parsed

        WHERE year BETWEEN 2010 AND 2023

        QUALIFY ROW_NUMBER() OVER (

            PARTITION BY
                area_code_fao,
                item_code,
                element_code,
                year

            ORDER BY
                extracted_at_utc DESC,
                source_row_hash DESC

        ) = 1
    )

    SELECT *
    FROM latest

) AS source


ON  target.area_code_fao = source.area_code_fao
AND target.item_code     = source.item_code
AND target.element_code  = source.element_code
AND target.year          = source.year


WHEN MATCHED
AND target.source_row_hash <> source.source_row_hash

THEN UPDATE SET

    target.area_code_m49      = source.area_code_m49,
    target.area_name          = source.area_name,

    target.item_name          = source.item_name,
    target.element_name       = source.element_name,

    target.value              = source.value,
    target.unit               = source.unit,

    target.flag_code          = source.flag_code,
    target.flag_description   = source.flag_description,
    target.note               = source.note,

    target.source_row_hash    = source.source_row_hash,
    target.ingestion_run_id   = source.ingestion_run_id,
    target.ingestion_batch_id = source.ingestion_batch_id,
    target.extracted_at_utc   = source.extracted_at_utc,

    target.cleaned_at_utc     = CURRENT_TIMESTAMP()


WHEN NOT MATCHED THEN INSERT (

    source_system,
    source_domain,

    area_code_fao,
    area_code_m49,
    area_name,

    item_code,
    item_name,

    element_code,
    element_name,

    year,

    value,
    unit,

    flag_code,
    flag_description,
    note,

    source_row_hash,
    ingestion_run_id,
    ingestion_batch_id,
    extracted_at_utc,
    cleaned_at_utc

)

VALUES (

    source.source_system,
    source.source_domain,

    source.area_code_fao,
    source.area_code_m49,
    source.area_name,

    source.item_code,
    source.item_name,

    source.element_code,
    source.element_name,

    source.year,

    source.value,
    source.unit,

    source.flag_code,
    source.flag_description,
    source.note,

    source.source_row_hash,
    source.ingestion_run_id,
    source.ingestion_batch_id,
    source.extracted_at_utc,
    CURRENT_TIMESTAMP()

);

RETURN
    'QCL_CLEAN_MERGE_COMPLETED|' || P_RUN_ID;

END;

$$;