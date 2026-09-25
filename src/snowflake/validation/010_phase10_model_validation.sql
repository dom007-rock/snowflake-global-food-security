USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


SELECT
    domain,
    source_count,
    fact_count,
    source_count = fact_count AS passed
FROM (

    SELECT
        'QCL' AS domain,
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_QCL) AS source_count,
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_CROPS_LIVESTOCK) AS fact_count

    UNION ALL

    SELECT
        'LC',
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_LC),
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_LAND_COVER)

    UNION ALL

    SELECT
        'ESB',
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_ESB),
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_NUTRIENT_BALANCE)

    UNION ALL

    SELECT
        'FBS',
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_FBS),
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_FOOD_BALANCE)

    UNION ALL

    SELECT
        'GT',
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_GT),
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_EMISSIONS)

    UNION ALL

    SELECT
        'FS',
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_FS),
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_FOOD_SECURITY)

    UNION ALL

    SELECT
        'WDI_MAPPED',

        (
            SELECT COUNT(*)
            FROM CLEAN.WDI_OBSERVATIONS wdi
            JOIN CONSUMPTION.DIM_GEOGRAPHY g
                ON wdi.wb_iso3_code = g.country_iso3
               AND g.mapping_status = 'MAPPED'
        ),

        (
            SELECT COUNT(*)
            FROM CONSUMPTION.FACT_WDI
        )
)

ORDER BY domain;

USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;


SELECT
    domain,
    source_count,
    fact_count,
    source_count = fact_count AS passed
FROM (

    SELECT
        'QCL' AS domain,
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_QCL) AS source_count,
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_CROPS_LIVESTOCK) AS fact_count

    UNION ALL

    SELECT
        'LC',
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_LC),
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_LAND_COVER)

    UNION ALL

    SELECT
        'ESB',
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_ESB),
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_NUTRIENT_BALANCE)

    UNION ALL

    SELECT
        'FBS',
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_FBS),
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_FOOD_BALANCE)

    UNION ALL

    SELECT
        'GT',
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_GT),
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_EMISSIONS)

    UNION ALL

    SELECT
        'FS',
        (SELECT COUNT(*) FROM CLEAN.FAOSTAT_FS),
        (SELECT COUNT(*) FROM CONSUMPTION.FACT_FOOD_SECURITY)

    UNION ALL

    SELECT
        'WDI_MAPPED',

        (
            SELECT COUNT(*)
            FROM CLEAN.WDI_OBSERVATIONS wdi
            JOIN CONSUMPTION.DIM_GEOGRAPHY g
                ON wdi.wb_iso3_code = g.country_iso3
               AND g.mapping_status = 'MAPPED'
        ),

        (
            SELECT COUNT(*)
            FROM CONSUMPTION.FACT_WDI
        )
)

ORDER BY domain;

SELECT 'DIM_GEOGRAPHY' AS dimension_name,
       COUNT(*) - COUNT(DISTINCT geography_key) AS duplicate_keys
FROM CONSUMPTION.DIM_GEOGRAPHY

UNION ALL

SELECT 'DIM_DATE',
       COUNT(*) - COUNT(DISTINCT date_key)
FROM CONSUMPTION.DIM_DATE

UNION ALL

SELECT 'DIM_PERIOD',
       COUNT(*) - COUNT(DISTINCT period_key)
FROM CONSUMPTION.DIM_PERIOD

UNION ALL

SELECT 'DIM_ITEM',
       COUNT(*) - COUNT(DISTINCT item_key)
FROM CONSUMPTION.DIM_ITEM

UNION ALL

SELECT 'DIM_ELEMENT',
       COUNT(*) - COUNT(DISTINCT element_key)
FROM CONSUMPTION.DIM_ELEMENT

UNION ALL

SELECT 'DIM_INDICATOR',
       COUNT(*) - COUNT(DISTINCT indicator_key)
FROM CONSUMPTION.DIM_INDICATOR

UNION ALL

SELECT 'DIM_SOURCE',
       COUNT(*) - COUNT(DISTINCT source_key)
FROM CONSUMPTION.DIM_SOURCE;

SELECT
    fact_name,
    orphan_rows
FROM (

    SELECT
        'FACT_CROPS_LIVESTOCK' AS fact_name,
        COUNT_IF(
            g.geography_key IS NULL
            OR d.date_key IS NULL
            OR i.item_key IS NULL
            OR e.element_key IS NULL
        ) AS orphan_rows
    FROM CONSUMPTION.FACT_CROPS_LIVESTOCK f
    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key
    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key
    LEFT JOIN CONSUMPTION.DIM_ITEM i
        ON f.item_key = i.item_key
    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key


    UNION ALL


    SELECT
        'FACT_LAND_COVER',
        COUNT_IF(
            g.geography_key IS NULL
            OR d.date_key IS NULL
            OR i.item_key IS NULL
            OR e.element_key IS NULL
        )
    FROM CONSUMPTION.FACT_LAND_COVER f
    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key
    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key
    LEFT JOIN CONSUMPTION.DIM_ITEM i
        ON f.item_key = i.item_key
    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key


    UNION ALL


    SELECT
        'FACT_NUTRIENT_BALANCE',
        COUNT_IF(
            g.geography_key IS NULL
            OR d.date_key IS NULL
            OR i.item_key IS NULL
            OR e.element_key IS NULL
        )
    FROM CONSUMPTION.FACT_NUTRIENT_BALANCE f
    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key
    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key
    LEFT JOIN CONSUMPTION.DIM_ITEM i
        ON f.item_key = i.item_key
    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key


    UNION ALL


    SELECT
        'FACT_FOOD_BALANCE',
        COUNT_IF(
            g.geography_key IS NULL
            OR d.date_key IS NULL
            OR i.item_key IS NULL
            OR e.element_key IS NULL
        )
    FROM CONSUMPTION.FACT_FOOD_BALANCE f
    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key
    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key
    LEFT JOIN CONSUMPTION.DIM_ITEM i
        ON f.item_key = i.item_key
    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key


    UNION ALL


    SELECT
        'FACT_EMISSIONS',
        COUNT_IF(
            g.geography_key IS NULL
            OR d.date_key IS NULL
            OR i.item_key IS NULL
            OR e.element_key IS NULL
            OR s.source_key IS NULL
        )
    FROM CONSUMPTION.FACT_EMISSIONS f
    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key
    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key
    LEFT JOIN CONSUMPTION.DIM_ITEM i
        ON f.item_key = i.item_key
    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key
    LEFT JOIN CONSUMPTION.DIM_SOURCE s
        ON f.source_key = s.source_key


    UNION ALL


    SELECT
        'FACT_FOOD_SECURITY',
        COUNT_IF(
            g.geography_key IS NULL
            OR ind.indicator_key IS NULL
            OR e.element_key IS NULL
            OR p.period_key IS NULL
        )
    FROM CONSUMPTION.FACT_FOOD_SECURITY f
    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key
    LEFT JOIN CONSUMPTION.DIM_INDICATOR ind
        ON f.indicator_key = ind.indicator_key
    LEFT JOIN CONSUMPTION.DIM_ELEMENT e
        ON f.element_key = e.element_key
    LEFT JOIN CONSUMPTION.DIM_PERIOD p
        ON f.period_key = p.period_key


    UNION ALL


    SELECT
        'FACT_WDI',
        COUNT_IF(
            g.geography_key IS NULL
            OR ind.indicator_key IS NULL
            OR d.date_key IS NULL
        )
    FROM CONSUMPTION.FACT_WDI f
    LEFT JOIN CONSUMPTION.DIM_GEOGRAPHY g
        ON f.geography_key = g.geography_key
    LEFT JOIN CONSUMPTION.DIM_INDICATOR ind
        ON f.indicator_key = ind.indicator_key
    LEFT JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key
)

ORDER BY fact_name;

SELECT
    fact_name,
    MIN(year) AS min_year,
    MAX(year) AS max_year,
    COUNT_IF(year < 2010 OR year > 2023) AS invalid_year_rows
FROM (

    SELECT 'CROPS_LIVESTOCK' AS fact_name, d.year
    FROM CONSUMPTION.FACT_CROPS_LIVESTOCK f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    UNION ALL

    SELECT 'LAND_COVER', d.year
    FROM CONSUMPTION.FACT_LAND_COVER f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    UNION ALL

    SELECT 'NUTRIENT_BALANCE', d.year
    FROM CONSUMPTION.FACT_NUTRIENT_BALANCE f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    UNION ALL

    SELECT 'FOOD_BALANCE', d.year
    FROM CONSUMPTION.FACT_FOOD_BALANCE f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    UNION ALL

    SELECT 'EMISSIONS', d.year
    FROM CONSUMPTION.FACT_EMISSIONS f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    UNION ALL

    SELECT 'WDI', d.year
    FROM CONSUMPTION.FACT_WDI f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key
)

GROUP BY fact_name
ORDER BY fact_name;

SELECT
    fact_name,
    MIN(year) AS min_year,
    MAX(year) AS max_year,
    COUNT_IF(year < 2010 OR year > 2023) AS invalid_year_rows
FROM (

    SELECT 'CROPS_LIVESTOCK' AS fact_name, d.year
    FROM CONSUMPTION.FACT_CROPS_LIVESTOCK f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    UNION ALL

    SELECT 'LAND_COVER', d.year
    FROM CONSUMPTION.FACT_LAND_COVER f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    UNION ALL

    SELECT 'NUTRIENT_BALANCE', d.year
    FROM CONSUMPTION.FACT_NUTRIENT_BALANCE f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    UNION ALL

    SELECT 'FOOD_BALANCE', d.year
    FROM CONSUMPTION.FACT_FOOD_BALANCE f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    UNION ALL

    SELECT 'EMISSIONS', d.year
    FROM CONSUMPTION.FACT_EMISSIONS f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key

    UNION ALL

    SELECT 'WDI', d.year
    FROM CONSUMPTION.FACT_WDI f
    JOIN CONSUMPTION.DIM_DATE d
        ON f.date_key = d.date_key
)

GROUP BY fact_name
ORDER BY fact_name;

SELECT
    g.geography_name,
    d.year,
    i.item_name,
    e.element_name,
    f.value,
    f.unit

FROM CONSUMPTION.FACT_CROPS_LIVESTOCK f

JOIN CONSUMPTION.DIM_GEOGRAPHY g
    ON f.geography_key = g.geography_key

JOIN CONSUMPTION.DIM_DATE d
    ON f.date_key = d.date_key

JOIN CONSUMPTION.DIM_ITEM i
    ON f.item_key = i.item_key

JOIN CONSUMPTION.DIM_ELEMENT e
    ON f.element_key = e.element_key

WHERE g.country_iso3 = 'IND'
  AND i.item_name = 'Wheat'
  AND e.element_name = 'Production'

ORDER BY d.year;

SELECT
    g.geography_name,
    d.year,
    i.indicator_name,
    f.value,
    f.unit

FROM CONSUMPTION.FACT_WDI f

JOIN CONSUMPTION.DIM_GEOGRAPHY g
    ON f.geography_key = g.geography_key

JOIN CONSUMPTION.DIM_DATE d
    ON f.date_key = d.date_key

JOIN CONSUMPTION.DIM_INDICATOR i
    ON f.indicator_key = i.indicator_key

WHERE g.country_iso3 = 'IND'
  AND i.indicator_code = 'NY.GDP.PCAP.CD'

ORDER BY d.year;

SELECT
    g.geography_name,
    i.indicator_name,

    p.period_label,
    p.period_type,

    f.value,
    f.value_raw,
    f.unit

FROM CONSUMPTION.FACT_FOOD_SECURITY f

JOIN CONSUMPTION.DIM_GEOGRAPHY g
    ON f.geography_key = g.geography_key

JOIN CONSUMPTION.DIM_INDICATOR i
    ON f.indicator_key = i.indicator_key

JOIN CONSUMPTION.DIM_PERIOD p
    ON f.period_key = p.period_key

WHERE g.country_iso3 = 'IND'

ORDER BY
    p.period_start_year,
    i.indicator_name;

SELECT
    g.geography_name,
    d.year,
    i.item_name,
    e.element_name,
    s.source_name,
    f.value,
    f.unit

FROM CONSUMPTION.FACT_EMISSIONS f

JOIN CONSUMPTION.DIM_GEOGRAPHY g
    ON f.geography_key = g.geography_key

JOIN CONSUMPTION.DIM_DATE d
    ON f.date_key = d.date_key

JOIN CONSUMPTION.DIM_ITEM i
    ON f.item_key = i.item_key

JOIN CONSUMPTION.DIM_ELEMENT e
    ON f.element_key = e.element_key

JOIN CONSUMPTION.DIM_SOURCE s
    ON f.source_key = s.source_key

WHERE g.country_iso3 = 'IND'

ORDER BY d.year DESC
LIMIT 100;

