/* ============================================================
   Global Food Security Intelligence Platform
   Phase 4 - Snowflake Platform Foundation
   ============================================================ */


/* ------------------------------------------------------------
   1. DATABASES
   ------------------------------------------------------------ */

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS GFS_DEV
    COMMENT = 'Development environment for Global Food Security platform';

CREATE DATABASE IF NOT EXISTS GFS_TEST
    COMMENT = 'Test environment for Global Food Security platform';

CREATE DATABASE IF NOT EXISTS GFS_PROD
    COMMENT = 'Production environment for Global Food Security platform';


/* ------------------------------------------------------------
   2. SCHEMAS
   ------------------------------------------------------------ */

CREATE SCHEMA IF NOT EXISTS GFS_DEV.RAW
    COMMENT = 'Source-faithful Delta Direct RAW layer';

CREATE SCHEMA IF NOT EXISTS GFS_DEV.CLEAN
    COMMENT = 'Standardized and validated source data';

CREATE SCHEMA IF NOT EXISTS GFS_DEV.CONSUMPTION
    COMMENT = 'Conformed analytical datasets';

CREATE SCHEMA IF NOT EXISTS GFS_DEV.PUBLISH
    COMMENT = 'Stable consumer-facing data products';

CREATE SCHEMA IF NOT EXISTS GFS_DEV.CONTROL
    COMMENT = 'Pipeline audit, metadata, monitoring and DQ control objects';


/* ------------------------------------------------------------
   3. WAREHOUSES
   ------------------------------------------------------------ */

CREATE WAREHOUSE IF NOT EXISTS GFS_INGEST_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Compute for ingestion and RAW integration operations';

CREATE WAREHOUSE IF NOT EXISTS GFS_TRANSFORM_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Compute for CLEAN and CONSUMPTION transformations';

CREATE WAREHOUSE IF NOT EXISTS GFS_ANALYTICS_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Compute for PUBLISH and analytical workloads';