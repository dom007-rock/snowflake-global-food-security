USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


ALTER TABLE CLEAN.FAOSTAT_QCL
    SET CHANGE_TRACKING = TRUE;


CREATE STREAM IF NOT EXISTS CLEAN.FAOSTAT_QCL_STREAM
    ON TABLE CLEAN.FAOSTAT_QCL;

SHOW STREAMS LIKE 'FAOSTAT_QCL_STREAM'
IN SCHEMA GFS_DEV.CLEAN;

SELECT SYSTEM$STREAM_HAS_DATA(
    'GFS_DEV.CLEAN.FAOSTAT_QCL_STREAM'
) AS has_changes;

CREATE OR REPLACE TASK CONTROL.TASK_QCL_TO_FACT
    WAREHOUSE = GFS_TRANSFORM_WH

    USER_TASK_TIMEOUT_MS = 900000

    SUSPEND_TASK_AFTER_NUM_FAILURES = 3

    WHEN SYSTEM$STREAM_HAS_DATA(
        'GFS_DEV.CLEAN.FAOSTAT_QCL_STREAM'
    )

AS

MERGE INTO GFS_DEV.CONSUMPTION.FACT_CROPS_LIVESTOCK AS target

USING (

    WITH changed_rows AS (

        SELECT
            q.*

        FROM GFS_DEV.CLEAN.FAOSTAT_QCL_STREAM q

        -- INSERT also represents the new version of an UPDATE.
        WHERE q.METADATA$ACTION = 'INSERT'

        -- If the same business observation changed multiple times
        -- before the task runs, retain only the latest version.
        QUALIFY ROW_NUMBER() OVER (

            PARTITION BY
                q.area_code_fao,
                q.item_code,
                q.element_code,
                q.year

            ORDER BY
                q.cleaned_at_utc DESC,
                q.extracted_at_utc DESC

        ) = 1
    )

    SELECT
        g.geography_key,
        d.date_key,
        i.item_key,
        e.element_key,

        q.value,
        q.unit,

        q.flag_code,
        q.flag_description,
        q.note,

        q.source_row_hash,
        q.ingestion_run_id,
        q.ingestion_batch_id,
        q.extracted_at_utc

    FROM changed_rows q

    JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
        ON q.area_code_fao = g.area_code_fao

    JOIN GFS_DEV.CONSUMPTION.DIM_ITEM i
        ON q.source_domain = i.source_domain
       AND q.item_code = i.item_code

    JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
        ON q.source_domain = e.source_domain
       AND q.element_code = e.element_code

    JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
        ON q.year = d.year

) AS source


ON  target.geography_key = source.geography_key
AND target.date_key      = source.date_key
AND target.item_key      = source.item_key
AND target.element_key   = source.element_key


WHEN MATCHED THEN UPDATE SET

    target.value =
        source.value,

    target.unit =
        source.unit,

    target.flag_code =
        source.flag_code,

    target.flag_description =
        source.flag_description,

    target.note =
        source.note,

    target.source_row_hash =
        source.source_row_hash,

    target.ingestion_run_id =
        source.ingestion_run_id,

    target.ingestion_batch_id =
        source.ingestion_batch_id,

    target.extracted_at_utc =
        source.extracted_at_utc,

    target.loaded_at_utc =
        CURRENT_TIMESTAMP()


WHEN NOT MATCHED THEN INSERT (

    geography_key,
    date_key,
    item_key,
    element_key,

    value,
    unit,

    flag_code,
    flag_description,
    note,

    source_row_hash,
    ingestion_run_id,
    ingestion_batch_id,
    extracted_at_utc,
    loaded_at_utc

)

VALUES (

    source.geography_key,
    source.date_key,
    source.item_key,
    source.element_key,

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