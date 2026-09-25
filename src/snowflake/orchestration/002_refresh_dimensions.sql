CREATE OR REPLACE PROCEDURE CONTROL.SP_REFRESH_DIMENSIONS()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS OWNER

AS

$$

BEGIN


-- =============================================================================
-- DIM_GEOGRAPHY
-- =============================================================================

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

        mapping_status = 'MAPPED' AS is_wdi_mapped,
        area_type = 'AGGREGATE' AS is_aggregate

    FROM CONTROL.GEOGRAPHY_CROSSWALK

) source

ON target.area_code_fao = source.area_code_fao

WHEN MATCHED THEN UPDATE SET

    target.area_code_m49     = source.area_code_m49,
    target.country_iso3      = source.country_iso3,
    target.geography_name    = source.geography_name,
    target.faostat_area_name = source.faostat_area_name,
    target.world_bank_name   = source.world_bank_name,
    target.area_type         = source.area_type,
    target.mapping_status    = source.mapping_status,
    target.mapping_method    = source.mapping_method,
    target.is_wdi_mapped     = source.is_wdi_mapped,
    target.is_aggregate      = source.is_aggregate,
    target.updated_at_utc    = CURRENT_TIMESTAMP()

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



-- =============================================================================
-- DIM_ITEM
-- =============================================================================

MERGE INTO CONSUMPTION.DIM_ITEM target

USING (

    SELECT DISTINCT
        source_domain,
        item_code,
        item_name

    FROM (

        SELECT source_domain, item_code, item_name
        FROM CLEAN.FAOSTAT_QCL

        UNION ALL

        SELECT source_domain, item_code, item_name
        FROM CLEAN.FAOSTAT_LC

        UNION ALL

        SELECT source_domain, item_code, item_name
        FROM CLEAN.FAOSTAT_ESB

        UNION ALL

        SELECT source_domain, item_code, item_name
        FROM CLEAN.FAOSTAT_FBS

        UNION ALL

        SELECT source_domain, item_code, item_name
        FROM CLEAN.FAOSTAT_GT

    )

    WHERE item_code IS NOT NULL
      AND item_name IS NOT NULL

) source

ON  target.source_domain = source.source_domain
AND target.item_code = source.item_code

WHEN MATCHED THEN UPDATE SET

    target.item_name = source.item_name,
    target.updated_at_utc = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (

    item_key,
    source_domain,
    item_code,
    item_name,
    created_at_utc,
    updated_at_utc

)

VALUES (

    CONTROL.ITEM_KEY_SEQ.NEXTVAL,
    source.source_domain,
    source.item_code,
    source.item_name,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()

);



-- =============================================================================
-- DIM_ELEMENT
-- =============================================================================

MERGE INTO CONSUMPTION.DIM_ELEMENT target

USING (

    SELECT DISTINCT
        source_domain,
        element_code,
        element_name

    FROM (

        SELECT source_domain, element_code, element_name
        FROM CLEAN.FAOSTAT_QCL

        UNION ALL

        SELECT source_domain, element_code, element_name
        FROM CLEAN.FAOSTAT_LC

        UNION ALL

        SELECT source_domain, element_code, element_name
        FROM CLEAN.FAOSTAT_ESB

        UNION ALL

        SELECT source_domain, element_code, element_name
        FROM CLEAN.FAOSTAT_FBS

        UNION ALL

        SELECT source_domain, element_code, element_name
        FROM CLEAN.FAOSTAT_GT

        UNION ALL

        SELECT source_domain, element_code, element_name
        FROM CLEAN.FAOSTAT_FS

    )

    WHERE element_code IS NOT NULL
      AND element_name IS NOT NULL

) source

ON  target.source_domain = source.source_domain
AND target.element_code = source.element_code

WHEN MATCHED THEN UPDATE SET

    target.element_name = source.element_name,
    target.updated_at_utc = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (

    element_key,
    source_domain,
    element_code,
    element_name,
    created_at_utc,
    updated_at_utc

)

VALUES (

    CONTROL.ELEMENT_KEY_SEQ.NEXTVAL,
    source.source_domain,
    source.element_code,
    source.element_name,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()

);



-- =============================================================================
-- DIM_INDICATOR
-- =============================================================================

MERGE INTO CONSUMPTION.DIM_INDICATOR target

USING (

    SELECT DISTINCT
        source_system,
        source_domain,
        indicator_code,
        indicator_name

    FROM CLEAN.FAOSTAT_FS

    WHERE indicator_code IS NOT NULL
      AND indicator_name IS NOT NULL


    UNION ALL


    SELECT DISTINCT
        'WORLD_BANK',
        'WDI',
        indicator_code,
        indicator_name

    FROM CLEAN.WDI_INDICATOR_METADATA

    WHERE indicator_code IS NOT NULL
      AND indicator_name IS NOT NULL

) source

ON  target.source_system = source.source_system
AND target.source_domain = source.source_domain
AND target.indicator_code = source.indicator_code

WHEN MATCHED THEN UPDATE SET

    target.indicator_name = source.indicator_name,
    target.updated_at_utc = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (

    indicator_key,
    source_system,
    source_domain,
    indicator_code,
    indicator_name,
    created_at_utc,
    updated_at_utc

)

VALUES (

    CONTROL.INDICATOR_KEY_SEQ.NEXTVAL,
    source.source_system,
    source.source_domain,
    source.indicator_code,
    source.indicator_name,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()

);



-- =============================================================================
-- DIM_SOURCE
-- =============================================================================

MERGE INTO CONSUMPTION.DIM_SOURCE target

USING (

    SELECT DISTINCT
        source_domain,
        source_code,
        source_name

    FROM CLEAN.FAOSTAT_GT

    WHERE source_code IS NOT NULL
      AND source_name IS NOT NULL

) source

ON  target.source_domain = source.source_domain
AND target.source_code = source.source_code

WHEN MATCHED THEN UPDATE SET

    target.source_name = source.source_name,
    target.updated_at_utc = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (

    source_key,
    source_domain,
    source_code,
    source_name,
    created_at_utc,
    updated_at_utc

)

VALUES (

    CONTROL.SOURCE_KEY_SEQ.NEXTVAL,
    source.source_domain,
    source.source_code,
    source.source_name,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()

);



-- =============================================================================
-- DIM_PERIOD
-- =============================================================================

MERGE INTO CONSUMPTION.DIM_PERIOD target

USING (

    SELECT DISTINCT

        period_code,
        period_label,
        period_start_year,
        period_end_year,
        period_type,

        period_end_year - period_start_year + 1
            AS duration_years

    FROM CLEAN.FAOSTAT_FS

    WHERE period_code IS NOT NULL
      AND period_start_year IS NOT NULL
      AND period_end_year IS NOT NULL

) source

ON target.period_code = source.period_code

WHEN MATCHED THEN UPDATE SET

    target.period_label = source.period_label,
    target.period_start_year = source.period_start_year,
    target.period_end_year = source.period_end_year,
    target.period_type = source.period_type,
    target.duration_years = source.duration_years,
    target.updated_at_utc = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (

    period_key,
    period_code,
    period_label,
    period_start_year,
    period_end_year,
    period_type,
    duration_years,
    created_at_utc,
    updated_at_utc

)

VALUES (

    CONTROL.PERIOD_KEY_SEQ.NEXTVAL,
    source.period_code,
    source.period_label,
    source.period_start_year,
    source.period_end_year,
    source.period_type,
    source.duration_years,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP()

);


RETURN 'DIMENSIONS_REFRESHED';


END;

$$;