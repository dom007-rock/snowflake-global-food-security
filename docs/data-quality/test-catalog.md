# Data Quality Test Catalog

## Uniqueness

### Dimensions

- `DIM_GEOGRAPHY`: `area_code_fao`
- `DIM_DATE`: `date_key`
- `DIM_PERIOD`: `period_code`
- `DIM_ITEM`: `source_domain + item_code`
- `DIM_ELEMENT`: `source_domain + element_code`
- `DIM_INDICATOR`: `source_system + source_domain + indicator_code`
- `DIM_SOURCE`: `source_domain + source_code`

### Facts

- `FACT_CROPS_LIVESTOCK`: geography + item + element + date
- `FACT_LAND_COVER`: geography + item + element + date
- `FACT_NUTRIENT_BALANCE`: geography + item + element + date
- `FACT_FOOD_BALANCE`: geography + item + element + date
- `FACT_EMISSIONS`: geography + item + element + source + date
- `FACT_FOOD_SECURITY`: geography + indicator + element + period
- `FACT_WDI`: geography + indicator + date

## Mandatory fields

Dimension surrogate/business keys and fact foreign keys are required. `source_row_hash` is mandatory on facts for traceability and idempotent loading.

## Accepted values

Current categorical contracts include:

- geography mapping status: `MAPPED`, `NO_WDI_MATCH`, `NOT_APPLICABLE`, `MANUAL_REVIEW`;
- period type: `ANNUAL`, `MULTI_YEAR`;
- indicator-source combinations: FAOSTAT/FS and WORLD_BANK/WDI.

## Time ranges

The analytical scope is 2010 through 2023.

Annual facts resolve through `DIM_DATE`. Food-security observations resolve through `DIM_PERIOD`, with both period boundaries required to remain inside the supported scope.

## Numerical ranges

Initial business-supported rules:

- `DIM_PERIOD.duration_years > 0`;
- WDI `SP.POP.TOTL >= 0`;
- WDI `NY.GDP.MKTP.CD >= 0`;
- WDI `NY.GDP.PCAP.CD >= 0`;
- WDI `SP.RUR.TOTL.ZS` between 0 and 100.

No universal non-negative rule is applied to FAOSTAT facts.

## Referential integrity

Every fact foreign key must resolve to its corresponding dimension. The configured tests cover all seven fact tables.

## Source-target reconciliation

FAOSTAT fact counts must equal their CLEAN source counts. WDI fact counts must equal the subset of CLEAN WDI observations that resolve to mapped analytical geographies.

## Reject tracking

`CONTROL.FAOSTAT_CLEAN_REJECTS` is tracked as an operational quality signal. Current policy treats non-zero rejects as a warning rather than an automatic ERROR-level failure.
