CREATE TABLE IF NOT EXISTS GFS_DEV.CONSUMPTION.FACT_EMISSIONS (

    geography_key          NUMBER       NOT NULL,
    date_key               NUMBER       NOT NULL,
    item_key               NUMBER       NOT NULL,
    element_key            NUMBER       NOT NULL,
    source_key             NUMBER       NOT NULL,

    value                  NUMBER(38,10),
    unit                   STRING,

    flag_code              STRING,
    note                   STRING,

    source_row_hash        STRING       NOT NULL,
    ingestion_run_id       STRING,
    ingestion_batch_id     STRING,
    extracted_at_utc       TIMESTAMP_TZ,
    loaded_at_utc          TIMESTAMP_TZ NOT NULL
);
MERGE INTO GFS_DEV.CONSUMPTION.FACT_EMISSIONS AS target

USING (

    SELECT
        g.geography_key,
        d.date_key,
        i.item_key,
        e.element_key,
        s.source_key,

        gt.value,
        gt.unit,

        gt.flag_code,
        gt.note,

        gt.source_row_hash,
        gt.ingestion_run_id,
        gt.ingestion_batch_id,
        gt.extracted_at_utc

    FROM GFS_DEV.CLEAN.FAOSTAT_GT gt

    JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
        ON gt.area_code_fao = g.area_code_fao

    JOIN GFS_DEV.CONSUMPTION.DIM_ITEM i
        ON gt.source_domain = i.source_domain
       AND gt.item_code = i.item_code

    JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
        ON gt.source_domain = e.source_domain
       AND gt.element_code = e.element_code

    JOIN GFS_DEV.CONSUMPTION.DIM_SOURCE s
        ON gt.source_domain = s.source_domain
       AND gt.source_code = s.source_code

    JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
        ON gt.year = d.year

) AS source

ON target.source_row_hash = source.source_row_hash


WHEN MATCHED THEN UPDATE SET

    target.geography_key      = source.geography_key,
    target.date_key           = source.date_key,
    target.item_key           = source.item_key,
    target.element_key        = source.element_key,
    target.source_key         = source.source_key,

    target.value              = source.value,
    target.unit               = source.unit,

    target.flag_code          = source.flag_code,
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
    source_key,

    value,
    unit,

    flag_code,
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
    source.source_key,

    source.value,
    source.unit,

    source.flag_code,
    source.note,

    source.source_row_hash,
    source.ingestion_run_id,
    source.ingestion_batch_id,
    source.extracted_at_utc,
    CURRENT_TIMESTAMP()
);