CREATE OR REPLACE TASK CONTROL.TASK_QCL_TO_FACT_GRAPH
    WAREHOUSE = GFS_TRANSFORM_WH

    AFTER CONTROL.TASK_REFRESH_DIMENSIONS

    WHEN SYSTEM$STREAM_HAS_DATA(
        'GFS_DEV.CLEAN.FAOSTAT_QCL_STREAM'
    )

AS

MERGE INTO GFS_DEV.CONSUMPTION.FACT_CROPS_LIVESTOCK target

USING (

    WITH changed_rows AS (

        SELECT q.*

        FROM GFS_DEV.CLEAN.FAOSTAT_QCL_STREAM q

        WHERE q.METADATA$ACTION = 'INSERT'

        QUALIFY ROW_NUMBER() OVER (

            PARTITION BY
                q.area_code_fao,
                q.item_code,
                q.element_code,
                q.year

            ORDER BY
                q.extracted_at_utc DESC,
                q.source_row_hash DESC

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

) source

ON  target.geography_key = source.geography_key
AND target.date_key      = source.date_key
AND target.item_key      = source.item_key
AND target.element_key   = source.element_key

WHEN MATCHED THEN UPDATE SET

    target.value              = source.value,
    target.unit               = source.unit,
    target.flag_code          = source.flag_code,
    target.flag_description   = source.flag_description,
    target.note               = source.note,
    target.source_row_hash    = source.source_row_hash,
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

CREATE OR REPLACE TASK CONTROL.TASK_ESB_TO_FACT
    WAREHOUSE = GFS_TRANSFORM_WH

    AFTER CONTROL.TASK_REFRESH_DIMENSIONS

    WHEN SYSTEM$STREAM_HAS_DATA(
        'GFS_DEV.CLEAN.FAOSTAT_ESB_STREAM'
    )

AS

MERGE INTO GFS_DEV.CONSUMPTION.FACT_NUTRIENT_BALANCE target

USING (

    WITH changed_rows AS (

        SELECT x.*

        FROM GFS_DEV.CLEAN.FAOSTAT_ESB_STREAM x

        WHERE x.METADATA$ACTION = 'INSERT'

        QUALIFY ROW_NUMBER() OVER (

            PARTITION BY
                x.area_code_fao,
                x.item_code,
                x.element_code,
                x.year

            ORDER BY
                x.extracted_at_utc DESC,
                x.source_row_hash DESC

        ) = 1
    )

    SELECT
        g.geography_key,
        d.date_key,
        i.item_key,
        e.element_key,

        x.value,
        x.unit,

        x.flag_code,
        x.flag_description,
        x.note,

        x.source_row_hash,
        x.ingestion_run_id,
        x.ingestion_batch_id,
        x.extracted_at_utc

    FROM changed_rows x

    JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
        ON x.area_code_fao = g.area_code_fao

    JOIN GFS_DEV.CONSUMPTION.DIM_ITEM i
        ON x.source_domain = i.source_domain
       AND x.item_code = i.item_code

    JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
        ON x.source_domain = e.source_domain
       AND x.element_code = e.element_code

    JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
        ON x.year = d.year

) source

ON  target.geography_key = source.geography_key
AND target.date_key      = source.date_key
AND target.item_key      = source.item_key
AND target.element_key   = source.element_key

WHEN MATCHED THEN UPDATE SET

    target.value              = source.value,
    target.unit               = source.unit,
    target.flag_code          = source.flag_code,
    target.flag_description   = source.flag_description,
    target.note               = source.note,
    target.source_row_hash    = source.source_row_hash,
    target.ingestion_run_id   = source.ingestion_run_id,
    target.ingestion_batch_id = source.ingestion_batch_id,
    target.extracted_at_utc   = source.extracted_at_utc,
    target.loaded_at_utc      = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (

    geography_key, date_key, item_key, element_key,
    value, unit,
    flag_code, flag_description, note,
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

CREATE OR REPLACE TASK CONTROL.TASK_FBS_TO_FACT
    WAREHOUSE = GFS_TRANSFORM_WH

    AFTER CONTROL.TASK_REFRESH_DIMENSIONS

    WHEN SYSTEM$STREAM_HAS_DATA(
        'GFS_DEV.CLEAN.FAOSTAT_FBS_STREAM'
    )

AS

MERGE INTO GFS_DEV.CONSUMPTION.FACT_FOOD_BALANCE target

USING (

    WITH changed_rows AS (

        SELECT x.*

        FROM GFS_DEV.CLEAN.FAOSTAT_FBS_STREAM x

        WHERE x.METADATA$ACTION = 'INSERT'

        QUALIFY ROW_NUMBER() OVER (

            PARTITION BY
                x.area_code_fao,
                x.item_code,
                x.element_code,
                x.year

            ORDER BY
                x.extracted_at_utc DESC,
                x.source_row_hash DESC

        ) = 1
    )

    SELECT
        g.geography_key,
        d.date_key,
        i.item_key,
        e.element_key,

        x.value,
        x.unit,

        x.flag_code,
        x.flag_description,
        x.note,

        x.source_row_hash,
        x.ingestion_run_id,
        x.ingestion_batch_id,
        x.extracted_at_utc

    FROM changed_rows x

    JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
        ON x.area_code_fao = g.area_code_fao

    JOIN GFS_DEV.CONSUMPTION.DIM_ITEM i
        ON x.source_domain = i.source_domain
       AND x.item_code = i.item_code

    JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
        ON x.source_domain = e.source_domain
       AND x.element_code = e.element_code

    JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
        ON x.year = d.year

) source

ON  target.geography_key = source.geography_key
AND target.date_key      = source.date_key
AND target.item_key      = source.item_key
AND target.element_key   = source.element_key

WHEN MATCHED THEN UPDATE SET

    target.value              = source.value,
    target.unit               = source.unit,
    target.flag_code          = source.flag_code,
    target.flag_description   = source.flag_description,
    target.note               = source.note,
    target.source_row_hash    = source.source_row_hash,
    target.ingestion_run_id   = source.ingestion_run_id,
    target.ingestion_batch_id = source.ingestion_batch_id,
    target.extracted_at_utc   = source.extracted_at_utc,
    target.loaded_at_utc      = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (

    geography_key, date_key, item_key, element_key,
    value, unit,
    flag_code, flag_description, note,
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

CREATE OR REPLACE TASK CONTROL.TASK_GT_TO_FACT
    WAREHOUSE = GFS_TRANSFORM_WH

    AFTER CONTROL.TASK_REFRESH_DIMENSIONS

    WHEN SYSTEM$STREAM_HAS_DATA(
        'GFS_DEV.CLEAN.FAOSTAT_GT_STREAM'
    )

AS

MERGE INTO GFS_DEV.CONSUMPTION.FACT_EMISSIONS target

USING (

    WITH changed_rows AS (

        SELECT x.*

        FROM GFS_DEV.CLEAN.FAOSTAT_GT_STREAM x

        WHERE x.METADATA$ACTION = 'INSERT'

        QUALIFY ROW_NUMBER() OVER (

            PARTITION BY
                x.area_code_fao,
                x.item_code,
                x.element_code,
                x.source_code,
                x.year

            ORDER BY
                x.extracted_at_utc DESC,
                x.source_row_hash DESC

        ) = 1
    )

    SELECT
        g.geography_key,
        d.date_key,
        i.item_key,
        e.element_key,
        s.source_key,

        x.value,
        x.unit,

        x.flag_code,
        x.note,

        x.source_row_hash,
        x.ingestion_run_id,
        x.ingestion_batch_id,
        x.extracted_at_utc

    FROM changed_rows x

    JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
        ON x.area_code_fao = g.area_code_fao

    JOIN GFS_DEV.CONSUMPTION.DIM_ITEM i
        ON x.source_domain = i.source_domain
       AND x.item_code = i.item_code

    JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
        ON x.source_domain = e.source_domain
       AND x.element_code = e.element_code

    JOIN GFS_DEV.CONSUMPTION.DIM_SOURCE s
        ON x.source_domain = s.source_domain
       AND x.source_code = s.source_code

    JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
        ON x.year = d.year

) source

ON  target.geography_key = source.geography_key
AND target.date_key      = source.date_key
AND target.item_key      = source.item_key
AND target.element_key   = source.element_key
AND target.source_key    = source.source_key

WHEN MATCHED THEN UPDATE SET

    target.value              = source.value,
    target.unit               = source.unit,
    target.flag_code          = source.flag_code,
    target.note               = source.note,
    target.source_row_hash    = source.source_row_hash,
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

CREATE OR REPLACE TASK CONTROL.TASK_FS_TO_FACT
    WAREHOUSE = GFS_TRANSFORM_WH

    AFTER CONTROL.TASK_REFRESH_DIMENSIONS

    WHEN SYSTEM$STREAM_HAS_DATA(
        'GFS_DEV.CLEAN.FAOSTAT_FS_STREAM'
    )

AS

MERGE INTO GFS_DEV.CONSUMPTION.FACT_FOOD_SECURITY target

USING (

    WITH changed_rows AS (

        SELECT x.*

        FROM GFS_DEV.CLEAN.FAOSTAT_FS_STREAM x

        WHERE x.METADATA$ACTION = 'INSERT'

        QUALIFY ROW_NUMBER() OVER (

            PARTITION BY
                x.area_code_fao,
                x.indicator_code,
                x.element_code,
                x.period_code

            ORDER BY
                x.extracted_at_utc DESC,
                x.source_row_hash DESC

        ) = 1
    )

    SELECT
        g.geography_key,
        ind.indicator_key,
        e.element_key,
        p.period_key,

        x.value,
        x.value_raw,
        x.unit,

        x.flag_code,
        x.note,

        x.source_row_hash,
        x.ingestion_run_id,
        x.ingestion_batch_id,
        x.extracted_at_utc

    FROM changed_rows x

    JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
        ON x.area_code_fao = g.area_code_fao

    JOIN GFS_DEV.CONSUMPTION.DIM_INDICATOR ind
        ON x.source_system = ind.source_system
       AND x.source_domain = ind.source_domain
       AND x.indicator_code = ind.indicator_code

    JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
        ON x.source_domain = e.source_domain
       AND x.element_code = e.element_code

    JOIN GFS_DEV.CONSUMPTION.DIM_PERIOD p
        ON x.period_code = p.period_code

) source

ON  target.geography_key = source.geography_key
AND target.indicator_key = source.indicator_key
AND target.element_key   = source.element_key
AND target.period_key    = source.period_key

WHEN MATCHED THEN UPDATE SET

    target.value              = source.value,
    target.value_raw          = source.value_raw,
    target.unit               = source.unit,
    target.flag_code          = source.flag_code,
    target.note               = source.note,
    target.source_row_hash    = source.source_row_hash,
    target.ingestion_run_id   = source.ingestion_run_id,
    target.ingestion_batch_id = source.ingestion_batch_id,
    target.extracted_at_utc   = source.extracted_at_utc,
    target.loaded_at_utc      = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (

    geography_key,
    indicator_key,
    element_key,
    period_key,

    value,
    value_raw,
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
    source.indicator_key,
    source.element_key,
    source.period_key,

    source.value,
    source.value_raw,
    source.unit,

    source.flag_code,
    source.note,

    source.source_row_hash,
    source.ingestion_run_id,
    source.ingestion_batch_id,
    source.extracted_at_utc,
    CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TASK CONTROL.TASK_WDI_TO_FACT
    WAREHOUSE = GFS_TRANSFORM_WH

    AFTER CONTROL.TASK_REFRESH_DIMENSIONS

    WHEN SYSTEM$STREAM_HAS_DATA(
        'GFS_DEV.CLEAN.WDI_OBSERVATIONS_STREAM'
    )

AS

MERGE INTO GFS_DEV.CONSUMPTION.FACT_WDI target

USING (

    WITH changed_rows AS (

        SELECT x.*

        FROM GFS_DEV.CLEAN.WDI_OBSERVATIONS_STREAM x

        WHERE x.METADATA$ACTION = 'INSERT'

        QUALIFY ROW_NUMBER() OVER (

            PARTITION BY
                x.wb_entity_id,
                x.indicator_code,
                x.year

            ORDER BY
                x.extracted_at_utc DESC,
                x.source_row_hash DESC

        ) = 1
    )

    SELECT
        g.geography_key,
        ind.indicator_key,
        d.date_key,

        x.value,
        x.unit,

        x.decimal_places,
        x.observation_status,

        x.wb_entity_id,
        x.wb_iso3_code,

        x.source_row_hash,
        x.ingestion_run_id,
        x.ingestion_batch_id,
        x.extracted_at_utc

    FROM changed_rows x

    JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
        ON x.wb_iso3_code = g.country_iso3
       AND g.mapping_status = 'MAPPED'

    JOIN GFS_DEV.CONSUMPTION.DIM_INDICATOR ind
        ON ind.source_system = 'WORLD_BANK'
       AND ind.source_domain = 'WDI'
       AND x.indicator_code = ind.indicator_code

    JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
        ON x.year = d.year

) source

ON  target.geography_key = source.geography_key
AND target.indicator_key = source.indicator_key
AND target.date_key      = source.date_key

WHEN MATCHED THEN UPDATE SET

    target.value              = source.value,
    target.unit               = source.unit,
    target.decimal_places     = source.decimal_places,
    target.observation_status = source.observation_status,
    target.wb_entity_id       = source.wb_entity_id,
    target.wb_iso3_code       = source.wb_iso3_code,
    target.source_row_hash    = source.source_row_hash,
    target.ingestion_run_id   = source.ingestion_run_id,
    target.ingestion_batch_id = source.ingestion_batch_id,
    target.extracted_at_utc   = source.extracted_at_utc,
    target.loaded_at_utc      = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN INSERT (

    geography_key,
    indicator_key,
    date_key,

    value,
    unit,

    decimal_places,
    observation_status,

    wb_entity_id,
    wb_iso3_code,

    source_row_hash,
    ingestion_run_id,
    ingestion_batch_id,
    extracted_at_utc,
    loaded_at_utc

)

VALUES (

    source.geography_key,
    source.indicator_key,
    source.date_key,

    source.value,
    source.unit,

    source.decimal_places,
    source.observation_status,

    source.wb_entity_id,
    source.wb_iso3_code,

    source.source_row_hash,
    source.ingestion_run_id,
    source.ingestion_batch_id,
    source.extracted_at_utc,
    CURRENT_TIMESTAMP()
);