-- =============================================================================
-- Global Food Security & Nutrition Intelligence Platform
-- Phase 15 - Consumption & Streamlit
--
-- File:
--   sql/publish/002_world_bank_views.sql
--
-- Purpose:
--   Create business-readable World Bank WDI analytical views.
--
-- Source grain:
--   geography × indicator × year
--
-- V1 analytical period:
--   2010-2023
--
-- WDI indicators:
--
--   SP.POP.TOTL
--     Population, total
--
--   NY.GDP.MKTP.CD
--     GDP (current US$)
--
--   NY.GDP.PCAP.CD
--     GDP per capita (current US$)
--
--   SP.RUR.TOTL.ZS
--     Rural population (% of total population)
--
--   NV.AGR.TOTL.ZS
--     Agriculture, forestry, and fishing,
--     value added (% of GDP)
-- =============================================================================


USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE WAREHOUSE GFS_ANALYTICS_WH;


-- =============================================================================
-- 1. WORLD BANK WDI OBSERVATION VIEW
--
-- Grain:
--   geography × indicator × year
--
-- This view converts surrogate-key fact records into a business-readable
-- analytical dataset while retaining lineage metadata.
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_WDI_OBSERVATIONS AS

SELECT
    -- -------------------------------------------------------------------------
    -- Geography
    -- -------------------------------------------------------------------------
    g.geography_key,
    g.area_code_fao,
    g.area_code_m49,
    g.country_iso3,
    g.geography_name,
    g.world_bank_name,
    g.area_type,
    g.mapping_status,
    g.mapping_method,
    g.is_wdi_mapped,
    g.is_aggregate,

    -- -------------------------------------------------------------------------
    -- Time
    -- -------------------------------------------------------------------------
    d.date_key,
    d.year,
    d.decade,

    -- -------------------------------------------------------------------------
    -- Indicator
    -- -------------------------------------------------------------------------
    i.indicator_key,
    i.source_system,
    i.source_domain,
    i.indicator_code,
    i.indicator_name,

    -- -------------------------------------------------------------------------
    -- Observation
    -- -------------------------------------------------------------------------
    f.value,
    f.unit,
    f.decimal_places,
    f.observation_status,

    -- -------------------------------------------------------------------------
    -- World Bank source identifiers
    -- -------------------------------------------------------------------------
    f.wb_entity_id,
    f.wb_iso3_code,

    -- -------------------------------------------------------------------------
    -- Lineage / audit
    -- -------------------------------------------------------------------------
    f.source_row_hash,
    f.ingestion_run_id,
    f.ingestion_batch_id,
    f.extracted_at_utc,
    f.loaded_at_utc

FROM GFS_DEV.CONSUMPTION.FACT_WDI f

INNER JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
    ON f.geography_key = g.geography_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
    ON f.date_key = d.date_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_INDICATOR i
    ON f.indicator_key = i.indicator_key

WHERE d.year BETWEEN 2010 AND 2023
;


-- =============================================================================
-- 2. WORLD BANK COUNTRY-YEAR VIEW
--
-- Grain:
--   country × year
--
-- Purpose:
--   Pivot the five V1 socioeconomic indicators into dashboard-friendly
--   columns.
--
-- Country identity is determined by COUNTRY_ISO3.
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_WDI_COUNTRY_YEAR AS

SELECT
    geography_key,
    area_code_fao,
    area_code_m49,
    country_iso3,
    geography_name,
    world_bank_name,
    year,

    -- -------------------------------------------------------------------------
    -- Population
    -- -------------------------------------------------------------------------
    MAX(
        CASE
            WHEN indicator_code = 'SP.POP.TOTL'
            THEN value
        END
    ) AS population_total,

    -- -------------------------------------------------------------------------
    -- GDP
    -- -------------------------------------------------------------------------
    MAX(
        CASE
            WHEN indicator_code = 'NY.GDP.MKTP.CD'
            THEN value
        END
    ) AS gdp_current_usd,

    -- -------------------------------------------------------------------------
    -- GDP per capita
    -- -------------------------------------------------------------------------
    MAX(
        CASE
            WHEN indicator_code = 'NY.GDP.PCAP.CD'
            THEN value
        END
    ) AS gdp_per_capita_current_usd,

    -- -------------------------------------------------------------------------
    -- Rural population
    -- -------------------------------------------------------------------------
    MAX(
        CASE
            WHEN indicator_code = 'SP.RUR.TOTL.ZS'
            THEN value
        END
    ) AS rural_population_pct,

    -- -------------------------------------------------------------------------
    -- Agriculture contribution to GDP
    -- -------------------------------------------------------------------------
    MAX(
        CASE
            WHEN indicator_code = 'NV.AGR.TOTL.ZS'
            THEN value
        END
    ) AS agriculture_value_added_pct_gdp

FROM GFS_DEV.PUBLISH.V_WDI_OBSERVATIONS

WHERE country_iso3 IS NOT NULL

GROUP BY
    geography_key,
    area_code_fao,
    area_code_m49,
    country_iso3,
    geography_name,
    world_bank_name,
    year
;