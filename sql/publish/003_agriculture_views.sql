-- =============================================================================
-- Global Food Security & Nutrition Intelligence Platform
-- Phase 15 - Consumption & Streamlit
--
-- File:
--   sql/publish/003_agriculture_views.sql
--
-- Purpose:
--   Create business-readable analytical views for the main FAOSTAT
--   agricultural and food-system domains.
--
-- V1 analytical period:
--   2010-2023
--
-- Views:
--   V_CROPS_LIVESTOCK
--   V_FOOD_BALANCE
--   V_LAND_COVER
--   V_NUTRIENT_BALANCE
--   V_EMISSIONS
--
-- Design:
--   Preserve the natural fact grain and expose dimension attributes so
--   downstream consumers do not need to work directly with surrogate keys.
-- =============================================================================


USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE WAREHOUSE GFS_ANALYTICS_WH;


-- =============================================================================
-- 1. CROPS & LIVESTOCK
--
-- Grain:
--   geography × item × element × year
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_CROPS_LIVESTOCK AS

SELECT
    -- Geography
    g.geography_key,
    g.area_code_fao,
    g.area_code_m49,
    g.country_iso3,
    g.geography_name,
    g.area_type,
    g.is_aggregate,

    -- Time
    d.date_key,
    d.year,
    d.decade,

    -- Item
    i.item_key,
    i.item_code,
    i.item_name,

    -- Element
    e.element_key,
    e.element_code,
    e.element_name,

    -- Observation
    f.value,
    f.unit,
    f.flag_code,
    f.flag_description,
    f.note,

    -- Lineage
    f.source_row_hash,
    f.ingestion_run_id,
    f.ingestion_batch_id,
    f.extracted_at_utc,
    f.loaded_at_utc

FROM GFS_DEV.CONSUMPTION.FACT_CROPS_LIVESTOCK f

INNER JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
    ON f.geography_key = g.geography_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
    ON f.date_key = d.date_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_ITEM i
    ON f.item_key = i.item_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
    ON f.element_key = e.element_key

WHERE d.year BETWEEN 2010 AND 2023
;


-- =============================================================================
-- 2. FOOD BALANCE
--
-- Grain:
--   geography × item × element × year
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_FOOD_BALANCE AS

SELECT
    g.geography_key,
    g.area_code_fao,
    g.area_code_m49,
    g.country_iso3,
    g.geography_name,
    g.area_type,
    g.is_aggregate,

    d.date_key,
    d.year,
    d.decade,

    i.item_key,
    i.item_code,
    i.item_name,

    e.element_key,
    e.element_code,
    e.element_name,

    f.value,
    f.unit,
    f.flag_code,
    f.flag_description,
    f.note,

    f.source_row_hash,
    f.ingestion_run_id,
    f.ingestion_batch_id,
    f.extracted_at_utc,
    f.loaded_at_utc

FROM GFS_DEV.CONSUMPTION.FACT_FOOD_BALANCE f

INNER JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
    ON f.geography_key = g.geography_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
    ON f.date_key = d.date_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_ITEM i
    ON f.item_key = i.item_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
    ON f.element_key = e.element_key

WHERE d.year BETWEEN 2010 AND 2023
;


-- =============================================================================
-- 3. LAND COVER
--
-- Grain:
--   geography × item × element × year
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_LAND_COVER AS

SELECT
    g.geography_key,
    g.area_code_fao,
    g.area_code_m49,
    g.country_iso3,
    g.geography_name,
    g.area_type,
    g.is_aggregate,

    d.date_key,
    d.year,
    d.decade,

    i.item_key,
    i.item_code,
    i.item_name,

    e.element_key,
    e.element_code,
    e.element_name,

    f.value,
    f.unit,
    f.flag_code,
    f.flag_description,
    f.note,

    f.source_row_hash,
    f.ingestion_run_id,
    f.ingestion_batch_id,
    f.extracted_at_utc,
    f.loaded_at_utc

FROM GFS_DEV.CONSUMPTION.FACT_LAND_COVER f

INNER JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
    ON f.geography_key = g.geography_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
    ON f.date_key = d.date_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_ITEM i
    ON f.item_key = i.item_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
    ON f.element_key = e.element_key

WHERE d.year BETWEEN 2010 AND 2023
;


-- =============================================================================
-- 4. CROPLAND NUTRIENT BALANCE
--
-- Grain:
--   geography × item × element × year
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_NUTRIENT_BALANCE AS

SELECT
    g.geography_key,
    g.area_code_fao,
    g.area_code_m49,
    g.country_iso3,
    g.geography_name,
    g.area_type,
    g.is_aggregate,

    d.date_key,
    d.year,
    d.decade,

    i.item_key,
    i.item_code,
    i.item_name,

    e.element_key,
    e.element_code,
    e.element_name,

    f.value,
    f.unit,
    f.flag_code,
    f.flag_description,
    f.note,

    f.source_row_hash,
    f.ingestion_run_id,
    f.ingestion_batch_id,
    f.extracted_at_utc,
    f.loaded_at_utc

FROM GFS_DEV.CONSUMPTION.FACT_NUTRIENT_BALANCE f

INNER JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
    ON f.geography_key = g.geography_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
    ON f.date_key = d.date_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_ITEM i
    ON f.item_key = i.item_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
    ON f.element_key = e.element_key

WHERE d.year BETWEEN 2010 AND 2023
;


-- =============================================================================
-- 5. EMISSIONS
--
-- Grain:
--   geography × item × element × source × year
--
-- Unlike the other four domains, emissions contains an additional SOURCE
-- dimension and therefore must retain SOURCE_KEY / SOURCE_CODE / SOURCE_NAME.
-- =============================================================================

CREATE OR REPLACE VIEW GFS_DEV.PUBLISH.V_EMISSIONS AS

SELECT
    g.geography_key,
    g.area_code_fao,
    g.area_code_m49,
    g.country_iso3,
    g.geography_name,
    g.area_type,
    g.is_aggregate,

    d.date_key,
    d.year,
    d.decade,

    i.item_key,
    i.item_code,
    i.item_name,

    e.element_key,
    e.element_code,
    e.element_name,

    s.source_key,
    s.source_code,
    s.source_name,

    f.value,
    f.unit,
    f.flag_code,
    f.flag_description,
    f.note,

    f.source_row_hash,
    f.ingestion_run_id,
    f.ingestion_batch_id,
    f.extracted_at_utc,
    f.loaded_at_utc

FROM GFS_DEV.CONSUMPTION.FACT_EMISSIONS f

INNER JOIN GFS_DEV.CONSUMPTION.DIM_GEOGRAPHY g
    ON f.geography_key = g.geography_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_DATE d
    ON f.date_key = d.date_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_ITEM i
    ON f.item_key = i.item_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_ELEMENT e
    ON f.element_key = e.element_key

INNER JOIN GFS_DEV.CONSUMPTION.DIM_SOURCE s
    ON f.source_key = s.source_key

WHERE d.year BETWEEN 2010 AND 2023
;