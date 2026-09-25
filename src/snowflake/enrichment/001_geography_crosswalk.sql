USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CONTROL;


CREATE TABLE IF NOT EXISTS GEOGRAPHY_CROSSWALK (
    area_code_fao       STRING,
    area_code_m49       STRING,
    faostat_area_name   STRING,

    country_iso3        STRING,
    world_bank_name     STRING,

    area_type           STRING,

    mapping_status      STRING,
    mapping_method      STRING,

    valid_from          DATE,
    valid_to            DATE,

    created_at_utc      TIMESTAMP_TZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at_utc      TIMESTAMP_TZ
);