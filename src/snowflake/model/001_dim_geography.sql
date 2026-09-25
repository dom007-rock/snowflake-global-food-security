USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


CREATE SEQUENCE IF NOT EXISTS CONTROL.GEOGRAPHY_KEY_SEQ
    START = 1
    INCREMENT = 1;

CREATE TABLE IF NOT EXISTS CONSUMPTION.DIM_GEOGRAPHY (

    geography_key              NUMBER       NOT NULL,

    -- Source / business identifiers
    area_code_fao              STRING       NOT NULL,
    area_code_m49              STRING,
    country_iso3               STRING,

    -- Canonical analytical label
    geography_name             STRING       NOT NULL,

    -- Source-specific labels
    faostat_area_name          STRING,
    world_bank_name            STRING,

    -- Classification
    area_type                  STRING,
    mapping_status             STRING,
    mapping_method             STRING,

    -- Convenience flags
    is_wdi_mapped              BOOLEAN,
    is_aggregate               BOOLEAN,

    -- Operational metadata
    created_at_utc             TIMESTAMP_TZ,
    updated_at_utc             TIMESTAMP_TZ

);

MERGE INTO CONSUMPTION.DIM_GEOGRAPHY AS target

USING (

    SELECT
        area_code_fao,
        area_code_m49,
        country_iso3,

        CASE
            WHEN mapping_status = 'MAPPED'
                 AND world_bank_name IS NOT NULL
                THEN world_bank_name

            ELSE faostat_area_name
        END AS geography_name,

        faostat_area_name,
        world_bank_name,

        area_type,
        mapping_status,
        mapping_method,

        mapping_status = 'MAPPED'
            AS is_wdi_mapped,

        area_type = 'AGGREGATE'
            AS is_aggregate

    FROM CONTROL.GEOGRAPHY_CROSSWALK

) AS source

ON target.area_code_fao = source.area_code_fao


WHEN MATCHED THEN UPDATE SET

    target.area_code_m49 =
        source.area_code_m49,

    target.country_iso3 =
        source.country_iso3,

    target.geography_name =
        source.geography_name,

    target.faostat_area_name =
        source.faostat_area_name,

    target.world_bank_name =
        source.world_bank_name,

    target.area_type =
        source.area_type,

    target.mapping_status =
        source.mapping_status,

    target.mapping_method =
        source.mapping_method,

    target.is_wdi_mapped =
        source.is_wdi_mapped,

    target.is_aggregate =
        source.is_aggregate,

    target.updated_at_utc =
        CURRENT_TIMESTAMP()


WHEN NOT MATCHED THEN INSERT (

    geography_key,

    area_code_fao,
    area_code_m49,
    country_iso3,

    geography_name,

    faostat_area_name,
    world_bank_name,

    area_type,
    mapping_status,
    mapping_method,

    is_wdi_mapped,
    is_aggregate,

    created_at_utc,
    updated_at_utc

)

VALUES (

    CONTROL.GEOGRAPHY_KEY_SEQ.NEXTVAL,

    source.area_code_fao,
    source.area_code_m49,
    source.country_iso3,

    source.geography_name,

    source.faostat_area_name,
    source.world_bank_name,

    source.area_type,
    source.mapping_status,
    source.mapping_method,

    source.is_wdi_mapped,
    source.is_aggregate,

    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()
);