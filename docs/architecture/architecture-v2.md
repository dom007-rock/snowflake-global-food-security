# Architecture V2

## Global Food Security & Nutrition Intelligence Platform

```text
FAOSTAT Bulk Bootstrap / API Refresh         World Bank WDI API
                 |                                  |
                 v                                  v
          Python ingestion / normalization / lineage
                         |
                         v
                  Delta Lake on S3
                         |
                         v
          Snowflake External Volume + Catalog
                         |
                         v
                    RAW (read-only)
                         |
                         v
                       CLEAN
                         |
                  Streams / Tasks
                         |
                         v
                   CONSUMPTION
             Dimensional warehouse
                         |
                         v
                      PUBLISH
              Business-readable views
                         |
                         v
                gfs_queries.py
                         |
                         v
                     Streamlit
```

## Source Domains

### FAOSTAT
- LC Land Cover
- ESB Cropland Nutrient Balance
- QCL Crops and livestock products
- FBS Food Balances (2010-)
- GT Emissions totals
- FS Suite of Food Security Indicators

### World Bank WDI
- Population
- GDP
- GDP per capita
- Rural population share
- Agriculture value-added share of GDP

## Warehouse Model

### Dimensions
- `DIM_GEOGRAPHY`
- `DIM_DATE`
- `DIM_PERIOD`
- `DIM_ITEM`
- `DIM_ELEMENT`
- `DIM_INDICATOR`
- `DIM_SOURCE`

### Facts
- `FACT_CROPS_LIVESTOCK`
- `FACT_LAND_COVER`
- `FACT_NUTRIENT_BALANCE`
- `FACT_FOOD_BALANCE`
- `FACT_EMISSIONS`
- `FACT_FOOD_SECURITY`
- `FACT_WDI`

## Orchestration

CLEAN tables are the stream boundary. S3 changes do not directly trigger Snowflake streams.

Task flow:

```text
CLEAN streams
    |
    v
TASK_GFS_ROOT
    |
    v
TASK_REFRESH_DIMENSIONS
    |
    +--> QCL fact task
    +--> LC fact task
    +--> ESB fact task
    +--> FBS fact task
    +--> GT fact task
    +--> FS fact task
    +--> WDI fact task
                 |
                 v
        TASK_RUN_DQ_GATE
```

## Consumption / Application Layer

PUBLISH views isolate consumers from dimensional surrogate keys and provide readable geography, item, element, indicator and time attributes.

The main integrated application view is `V_COUNTRY_YEAR_INTELLIGENCE`.

Streamlit reads from PUBLISH through `streamlit/gfs_queries.py`; it does not read RAW or CLEAN directly.
