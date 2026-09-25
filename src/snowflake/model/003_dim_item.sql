USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CONSUMPTION;


CREATE SEQUENCE IF NOT EXISTS GFS_DEV.CONTROL.ITEM_KEY_SEQ
    START = 1
    INCREMENT = 1;


CREATE TABLE IF NOT EXISTS DIM_ITEM (

    item_key           NUMBER       NOT NULL,

    source_domain      STRING       NOT NULL,
    item_code          STRING       NOT NULL,
    item_name          STRING       NOT NULL,

    created_at_utc     TIMESTAMP_TZ NOT NULL,
    updated_at_utc     TIMESTAMP_TZ

);