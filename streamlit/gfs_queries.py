"""
Global Food Security & Nutrition Intelligence Platform
Phase 15 - Streamlit Query Layer
"""

import pandas as pd


PUBLISH_SCHEMA = "GFS_DEV.PUBLISH"


AGRICULTURE_DOMAINS = {
    "Crops & Livestock": "V_CROPS_LIVESTOCK",
    "Food Balance": "V_FOOD_BALANCE",
    "Land Cover": "V_LAND_COVER",
    "Nutrient Balance": "V_NUTRIENT_BALANCE",
    "Emissions": "V_EMISSIONS",
}


# =============================================================================
# HELPERS
# =============================================================================

def _to_pandas(session, sql: str) -> pd.DataFrame:
    return session.sql(sql).to_pandas()


def _escape_sql_literal(value: str) -> str:
    return str(value).replace("'", "''")


def _validate_iso3(country_iso3: str) -> str:

    country_iso3 = str(country_iso3).strip().upper()

    if len(country_iso3) != 3 or not country_iso3.isalpha():
        raise ValueError(
            f"Invalid ISO3 country code: {country_iso3}"
        )

    return country_iso3


def _validate_indicator_code(indicator_code: str) -> str:

    indicator_code = str(indicator_code).strip()

    if not indicator_code.isdigit():
        raise ValueError(
            f"Invalid indicator code: {indicator_code}"
        )

    return indicator_code


def _validate_agriculture_domain(domain_name: str) -> str:

    if domain_name not in AGRICULTURE_DOMAINS:
        raise ValueError(
            f"Unsupported agriculture domain: {domain_name}"
        )

    return AGRICULTURE_DOMAINS[domain_name]


# =============================================================================
# COUNTRY METADATA
# =============================================================================

def get_countries(session) -> pd.DataFrame:

    sql = f"""
        SELECT DISTINCT
            country_iso3,
            geography_name
        FROM {PUBLISH_SCHEMA}.V_COUNTRY_YEAR_INTELLIGENCE
        WHERE country_iso3 IS NOT NULL
        ORDER BY geography_name
    """

    return _to_pandas(session, sql)


# =============================================================================
# COUNTRY INTELLIGENCE
# =============================================================================

def get_country_intelligence(
    session,
    country_iso3: str,
) -> pd.DataFrame:

    country_iso3 = _validate_iso3(country_iso3)

    sql = f"""
        SELECT
            country_iso3,
            geography_name,
            year,

            population_total,
            gdp_current_usd,
            gdp_per_capita_current_usd,
            rural_population_pct,
            agriculture_value_added_pct_gdp,

            caloric_loss_retail_pct,
            basic_drinking_water_pct,
            basic_sanitation_pct,
            anemia_women_pct,
            child_stunting_pct,
            adult_obesity_pct,

            available_food_security_kpis,
            has_wdi_data,
            has_food_security_data

        FROM {PUBLISH_SCHEMA}.V_COUNTRY_YEAR_INTELLIGENCE

        WHERE country_iso3 = '{country_iso3}'

        ORDER BY year
    """

    return _to_pandas(session, sql)


# =============================================================================
# FOOD SECURITY
# =============================================================================

def get_food_security_indicators(session) -> pd.DataFrame:

    sql = f"""
        SELECT
            indicator_code,
            indicator_name,
            unit,
            COUNT(DISTINCT country_iso3) AS country_count,
            MIN(year) AS min_year,
            MAX(year) AS max_year

        FROM {PUBLISH_SCHEMA}.V_FOOD_SECURITY_ANNUAL

        GROUP BY
            indicator_code,
            indicator_name,
            unit

        ORDER BY indicator_name
    """

    return _to_pandas(session, sql)


def get_food_security_trend(
    session,
    country_iso3: str,
    indicator_code: str,
) -> pd.DataFrame:

    country_iso3 = _validate_iso3(country_iso3)
    indicator_code = _validate_indicator_code(indicator_code)

    sql = f"""
        SELECT
            country_iso3,
            geography_name,
            year,

            indicator_code,
            indicator_name,

            element_code,
            element_name,

            value,
            unit

        FROM {PUBLISH_SCHEMA}.V_FOOD_SECURITY_ANNUAL

        WHERE country_iso3 = '{country_iso3}'
          AND indicator_code = '{indicator_code}'

        ORDER BY year
    """

    return _to_pandas(session, sql)


# =============================================================================
# COUNTRY COMPARISON
# =============================================================================

def get_country_comparison(
    session,
    country_iso3_list,
    indicator_code: str,
) -> pd.DataFrame:

    if not country_iso3_list:
        return pd.DataFrame()

    countries = [
        _validate_iso3(code)
        for code in country_iso3_list
    ]

    indicator_code = _validate_indicator_code(indicator_code)

    country_sql = ", ".join(
        f"'{code}'"
        for code in countries
    )

    sql = f"""
        SELECT
            country_iso3,
            geography_name,
            year,
            indicator_code,
            indicator_name,
            value,
            unit

        FROM {PUBLISH_SCHEMA}.V_FOOD_SECURITY_ANNUAL

        WHERE country_iso3 IN ({country_sql})
          AND indicator_code = '{indicator_code}'

        ORDER BY
            year,
            geography_name
    """

    return _to_pandas(session, sql)


# =============================================================================
# FAOSTAT AGGREGATES
# =============================================================================

def get_aggregate_geographies(session) -> pd.DataFrame:

    sql = f"""
        SELECT DISTINCT
            geography_name

        FROM {PUBLISH_SCHEMA}.V_FOOD_SECURITY_AGGREGATE_ANNUAL

        WHERE geography_name IS NOT NULL

        ORDER BY geography_name
    """

    return _to_pandas(session, sql)


def get_aggregate_indicators(session) -> pd.DataFrame:

    sql = f"""
        SELECT DISTINCT
            indicator_code,
            indicator_name,
            unit

        FROM {PUBLISH_SCHEMA}.V_FOOD_SECURITY_AGGREGATE_ANNUAL

        ORDER BY indicator_name
    """

    return _to_pandas(session, sql)


def get_aggregate_food_security_trend(
    session,
    geography_name: str,
    indicator_code: str,
) -> pd.DataFrame:

    geography_name = _escape_sql_literal(geography_name)

    indicator_code = _validate_indicator_code(
        indicator_code
    )

    sql = f"""
        SELECT
            geography_name,
            year,

            indicator_code,
            indicator_name,

            element_code,
            element_name,

            value,
            unit

        FROM {PUBLISH_SCHEMA}.V_FOOD_SECURITY_AGGREGATE_ANNUAL

        WHERE geography_name = '{geography_name}'
          AND indicator_code = '{indicator_code}'

        ORDER BY year
    """

    return _to_pandas(session, sql)


# =============================================================================
# AGRICULTURE
# =============================================================================

def get_agriculture_items(
    session,
    domain_name: str,
    country_iso3: str,
) -> pd.DataFrame:

    view_name = _validate_agriculture_domain(
        domain_name
    )

    country_iso3 = _validate_iso3(
        country_iso3
    )

    sql = f"""
        SELECT DISTINCT
            item_code,
            item_name

        FROM {PUBLISH_SCHEMA}.{view_name}

        WHERE country_iso3 = '{country_iso3}'

        ORDER BY item_name
    """

    return _to_pandas(session, sql)


def get_agriculture_elements(
    session,
    domain_name: str,
    country_iso3: str,
    item_code: str,
) -> pd.DataFrame:

    view_name = _validate_agriculture_domain(
        domain_name
    )

    country_iso3 = _validate_iso3(
        country_iso3
    )

    item_code = _escape_sql_literal(
        item_code
    )

    sql = f"""
        SELECT DISTINCT
            element_code,
            element_name,
            unit

        FROM {PUBLISH_SCHEMA}.{view_name}

        WHERE country_iso3 = '{country_iso3}'
          AND item_code = '{item_code}'

        ORDER BY element_name
    """

    return _to_pandas(session, sql)


def get_agriculture_trend(
    session,
    domain_name: str,
    country_iso3: str,
    item_code: str,
    element_code: str,
) -> pd.DataFrame:

    view_name = _validate_agriculture_domain(
        domain_name
    )

    country_iso3 = _validate_iso3(
        country_iso3
    )

    item_code = _escape_sql_literal(
        item_code
    )

    element_code = _escape_sql_literal(
        element_code
    )

    sql = f"""
        SELECT
            country_iso3,
            geography_name,
            year,

            item_code,
            item_name,

            element_code,
            element_name,

            value,
            unit

        FROM {PUBLISH_SCHEMA}.{view_name}

        WHERE country_iso3 = '{country_iso3}'
          AND item_code = '{item_code}'
          AND element_code = '{element_code}'

        ORDER BY year
    """

    return _to_pandas(session, sql)
