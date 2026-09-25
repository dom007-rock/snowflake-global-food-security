# Phase 15 - Consumption Layer and Streamlit Application

## Global Food Security & Nutrition Intelligence Platform

Phase 15 builds the analytical consumption layer and the Streamlit application on top of the dimensional warehouse.

## Scope

- PUBLISH semantic views
- Food-security and nutrition analysis
- World Bank socioeconomic enrichment
- Integrated country-year intelligence
- Country comparison
- Agriculture explorer
- FAOSTAT aggregate explorer
- Streamlit application
- Analytical validation

Analytical period: **2010-2023**

Primary sources: **FAOSTAT** and **World Bank WDI**.

## PUBLISH Views

### Food Security
- `V_FOOD_SECURITY_OBSERVATIONS`
- `V_FOOD_SECURITY_ANNUAL`
- `V_FOOD_SECURITY_HEADLINE`
- `V_FOOD_SECURITY_COUNTRY_YEAR`
- `V_FOOD_SECURITY_AGGREGATE_ANNUAL`

### World Bank
- `V_WDI_OBSERVATIONS`
- `V_WDI_COUNTRY_YEAR`

### Agriculture / Food Systems
- `V_CROPS_LIVESTOCK`
- `V_FOOD_BALANCE`
- `V_LAND_COVER`
- `V_NUTRIENT_BALANCE`
- `V_EMISSIONS`

### Integrated Intelligence
- `V_COUNTRY_YEAR_INTELLIGENCE`

## Headline Country KPIs

Country-level headline food-security indicators were selected based on actual country coverage in the loaded data:

- `21059` Incidence of caloric losses at retail distribution level
- `21047` Population using at least basic drinking water services
- `21048` Population using at least basic sanitation services
- `21043` Prevalence of anemia among women aged 15-49
- `21025` Children under 5 affected by stunting
- `21042` Adult obesity prevalence

Indicator `210040` (annual prevalence of undernourishment) was found to be available only for FAOSTAT aggregate geographies in the loaded dataset and is therefore not forced into the country-level headline layer.

## World Bank Context

- `SP.POP.TOTL` Population, total
- `NY.GDP.MKTP.CD` GDP, current US$
- `NY.GDP.PCAP.CD` GDP per capita, current US$
- `SP.RUR.TOTL.ZS` Rural population (% of total population)
- `NV.AGR.TOTL.ZS` Agriculture, forestry and fishing value added (% of GDP)

## Integrated Country-Year View

`V_COUNTRY_YEAR_INTELLIGENCE` has a grain of:

`country x year`

It combines FAOSTAT and WDI using `geography_key + year` and intentionally uses a full outer join so observations from one source are not silently lost when the other source has no value for the same country-year.

The view exposes `HAS_WDI_DATA` and `HAS_FOOD_SECURITY_DATA` flags.

## Streamlit Application

Application files:

- `streamlit/app.py`
- `streamlit/gfs_queries.py`
- `streamlit/environment.yml`

The application contains five areas:

1. Overview
2. Food Security & Nutrition
3. Country Comparison
4. Agriculture Explorer
5. FAOSTAT Aggregate Explorer

The Overview uses metric-specific latest non-null observations because indicators may have different reporting years.

The Aggregate Explorer uses source-published FAOSTAT aggregate observations rather than averaging country percentages.

## Validation

`sql/publish/005_validation.sql` validates:

- year boundaries
- country-year uniqueness
- headline indicator uniqueness
- country identity completeness
- KPI pivot reconciliation
- source availability flags
- aggregate coverage
- invalid year detection

All Phase 15 validation checks passed during development.

## Local Development

Run locally with:

```powershell
streamlit run streamlit/app.py
```

Local Snowflake configuration is stored in `.streamlit/secrets.toml` and must remain ignored by Git.

## Status

**Phase 15: COMPLETE**
