USE ROLE GFS_PLATFORM_ADMIN;

USE DATABASE GFS_DEV;
USE SCHEMA RAW;


-- ============================================================================
-- FAOSTAT LC - Land Cover
-- ============================================================================

CREATE ICEBERG TABLE IF NOT EXISTS FAOSTAT_LC
    CATALOG = 'GFS_DELTA_CATALOG'
    EXTERNAL_VOLUME = 'GFS_DEV_DELTA_EXT_VOL'
    BASE_LOCATION = 'faostat/lc/'
    AUTO_REFRESH = TRUE
    COMMENT = 'Read-only RAW Delta Direct table for FAOSTAT Land Cover';


-- ============================================================================
-- FAOSTAT ESB - Cropland Nutrient Balance
-- ============================================================================

CREATE ICEBERG TABLE IF NOT EXISTS FAOSTAT_ESB
    CATALOG = 'GFS_DELTA_CATALOG'
    EXTERNAL_VOLUME = 'GFS_DEV_DELTA_EXT_VOL'
    BASE_LOCATION = 'faostat/esb/'
    AUTO_REFRESH = TRUE
    COMMENT = 'Read-only RAW Delta Direct table for FAOSTAT Cropland Nutrient Balance';


-- ============================================================================
-- FAOSTAT FBS - Food Balances
-- ============================================================================

CREATE ICEBERG TABLE IF NOT EXISTS FAOSTAT_FBS
    CATALOG = 'GFS_DELTA_CATALOG'
    EXTERNAL_VOLUME = 'GFS_DEV_DELTA_EXT_VOL'
    BASE_LOCATION = 'faostat/fbs/'
    AUTO_REFRESH = TRUE
    COMMENT = 'Read-only RAW Delta Direct table for FAOSTAT Food Balances';


-- ============================================================================
-- FAOSTAT GT - Emissions Totals
-- ============================================================================

CREATE ICEBERG TABLE IF NOT EXISTS FAOSTAT_GT
    CATALOG = 'GFS_DELTA_CATALOG'
    EXTERNAL_VOLUME = 'GFS_DEV_DELTA_EXT_VOL'
    BASE_LOCATION = 'faostat/gt/'
    AUTO_REFRESH = TRUE
    COMMENT = 'Read-only RAW Delta Direct table for FAOSTAT Emissions Totals';


-- ============================================================================
-- FAOSTAT FS - Food Security Indicators
-- ============================================================================

CREATE ICEBERG TABLE IF NOT EXISTS FAOSTAT_FS
    CATALOG = 'GFS_DELTA_CATALOG'
    EXTERNAL_VOLUME = 'GFS_DEV_DELTA_EXT_VOL'
    BASE_LOCATION = 'faostat/fs/'
    AUTO_REFRESH = TRUE
    COMMENT = 'Read-only RAW Delta Direct table for FAOSTAT Food Security Indicators';