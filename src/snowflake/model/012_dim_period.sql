USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


CREATE SEQUENCE IF NOT EXISTS GFS_DEV.CONTROL.PERIOD_KEY_SEQ
    START = 1
    INCREMENT = 1;


CREATE TABLE IF NOT EXISTS GFS_DEV.CONSUMPTION.DIM_PERIOD (

    period_key          NUMBER       NOT NULL,

    period_code         STRING       NOT NULL,
    period_label        STRING,

    period_start_year   NUMBER       NOT NULL,
    period_end_year     NUMBER       NOT NULL,
    period_type         STRING       NOT NULL,

    duration_years      NUMBER       NOT NULL,

    created_at_utc      TIMESTAMP_TZ NOT NULL,
    updated_at_utc      TIMESTAMP_TZ

);