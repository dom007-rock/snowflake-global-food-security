USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CONSUMPTION;


CREATE TABLE IF NOT EXISTS FACT_FOOD_BALANCE (

    geography_key          NUMBER       NOT NULL,
    date_key               NUMBER       NOT NULL,
    item_key               NUMBER       NOT NULL,
    element_key            NUMBER       NOT NULL,

    value                  NUMBER(38,10),
    unit                   STRING,

    flag_code              STRING,
    flag_description       STRING,
    note                   STRING,

    source_row_hash        STRING       NOT NULL,
    ingestion_run_id       STRING,
    ingestion_batch_id     STRING,
    extracted_at_utc       TIMESTAMP_TZ,
    loaded_at_utc          TIMESTAMP_TZ NOT NULL
);


MERGE INTO FACT_FOOD_BALANCE AS target

USING (

    SELECT
        g.geography_key,
        d.date_key,
        i.item_key,
        e.element_key,

        fbs.value,
        fbs.unit,

        fbs.flag_code,
        fbs.flag_description,
        fbs.note,

        fbs.source_row_hash,
        fbs.ingestion_run_id,
        fbs.ingestion_batch_id,
        fbs.extracted_at_utc

    FROM GFS_DEV.CLEAN.FAOSTAT_FBS fbs

    JOIN DIM_GEOGRAPHY g
        ON fbs.area_code_fao = g.area_code_fao

    JOIN DIM_ITEM i
        ON fbs.source_domain = i.source_domain
       AND fbs.item_code = i.item_code

    JOIN DIM_ELEMENT e
        ON fbs.source_domain = e.source_domain
       AND fbs.element_code = e.element_code

    JOIN DIM_DATE d
        ON fbs.year = d.year

) AS source

ON target.source_row_hash = source.source_row_hash

WHEN MATCHED THEN UPDATE SET

    target.geography_key      = source.geography_key,
    target.date_key           = source.date_key,
    target.item_key           = source.item_key,
    target.element_key        = source.element_key,

    target.value              = source.value,
    target.unit               = source.unit,

    target.flag_code          = source.flag_code,
    target.flag_description   = source.flag_description,
    target.note               = source.note,

    target.ingestion_run_id   = source.ingestion_run_id,
    target.ingestion_batch_id = source.ingestion_batch_id,
    target.extracted_at_utc   = source.extracted_at_utc,
    target.loaded_at_utc      = CURRENT_TIMESTAMP()

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