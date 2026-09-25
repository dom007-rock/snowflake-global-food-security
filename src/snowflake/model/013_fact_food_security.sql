CREATE TABLE IF NOT EXISTS GFS_DEV.CONSUMPTION.FACT_FOOD_SECURITY (

    geography_key          NUMBER       NOT NULL,
    indicator_key          NUMBER       NOT NULL,
    element_key            NUMBER       NOT NULL,
    period_key             NUMBER       NOT NULL,

    value                  NUMBER(38,10),
    value_raw              STRING,
    unit                   STRING,

    flag_code              STRING,
    note                   STRING,

    source_row_hash        STRING       NOT NULL,
    ingestion_run_id       STRING,
    ingestion_batch_id     STRING,
    extracted_at_utc       TIMESTAMP_TZ,
    loaded_at_utc          TIMESTAMP_TZ NOT NULL

);