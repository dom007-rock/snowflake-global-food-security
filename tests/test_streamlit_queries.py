"""
Global Food Security & Nutrition Intelligence Platform
Phase 16 - CI/CD

Unit tests for the Streamlit Snowflake query layer.

These tests do not connect to Snowflake.
"""

import sys
from pathlib import Path

import pandas as pd
import pytest


# =============================================================================
# IMPORT STREAMLIT QUERY MODULE
# =============================================================================

PROJECT_ROOT = Path(__file__).resolve().parents[1]

STREAMLIT_DIR = PROJECT_ROOT / "streamlit"

sys.path.insert(
    0,
    str(STREAMLIT_DIR),
)

import gfs_queries  # noqa: E402  # type: ignore[import-not-found]


# =============================================================================
# MOCK SNOWPARK SESSION
# =============================================================================

class MockSnowparkResult:

    def __init__(self):
        self.sql_text = None

    def to_pandas(self):
        return pd.DataFrame(
            {
                "TEST_COLUMN": [1]
            }
        )


class MockSession:

    def __init__(self):
        self.last_sql = None

    def sql(self, sql_text):

        self.last_sql = sql_text

        result = MockSnowparkResult()

        result.sql_text = sql_text

        return result


# =============================================================================
# ISO3 VALIDATION
# =============================================================================

def test_validate_iso3_accepts_valid_code():

    assert (
        gfs_queries._validate_iso3("ind")
        == "IND"
    )


def test_validate_iso3_rejects_short_code():

    with pytest.raises(ValueError):

        gfs_queries._validate_iso3("IN")


def test_validate_iso3_rejects_numeric_code():

    with pytest.raises(ValueError):

        gfs_queries._validate_iso3("123")


# =============================================================================
# INDICATOR VALIDATION
# =============================================================================

def test_indicator_code_accepts_numeric_code():

    assert (
        gfs_queries._validate_indicator_code(
            "21047"
        )
        == "21047"
    )


def test_indicator_code_rejects_non_numeric_code():

    with pytest.raises(ValueError):

        gfs_queries._validate_indicator_code(
            "ABC123"
        )


# =============================================================================
# AGRICULTURE DOMAIN WHITELIST
# =============================================================================

def test_valid_agriculture_domain():

    assert (
        gfs_queries._validate_agriculture_domain(
            "Food Balance"
        )
        == "V_FOOD_BALANCE"
    )


def test_invalid_agriculture_domain():

    with pytest.raises(ValueError):

        gfs_queries._validate_agriculture_domain(
            "SOME_RANDOM_TABLE"
        )


# =============================================================================
# SQL GENERATION
# =============================================================================

def test_get_countries_queries_publish_layer():

    session = MockSession()

    result = gfs_queries.get_countries(
        session
    )

    assert isinstance(
        result,
        pd.DataFrame,
    )

    assert (
        "GFS_DEV.PUBLISH.V_COUNTRY_YEAR_INTELLIGENCE"
        in session.last_sql
    )

    assert (
        "country_iso3 IS NOT NULL"
        in session.last_sql
    )


def test_country_intelligence_filters_iso3():

    session = MockSession()

    gfs_queries.get_country_intelligence(
        session,
        "IND",
    )

    assert (
        "country_iso3 = 'IND'"
        in session.last_sql
    )


def test_food_security_trend_filters_indicator():

    session = MockSession()

    gfs_queries.get_food_security_trend(
        session,
        "IND",
        "21047",
    )

    assert (
        "country_iso3 = 'IND'"
        in session.last_sql
    )

    assert (
        "indicator_code = '21047'"
        in session.last_sql
    )


def test_country_comparison_multiple_countries():

    session = MockSession()

    gfs_queries.get_country_comparison(
        session,
        [
            "IND",
            "USA",
            "BRA",
        ],
        "21047",
    )

    assert "'IND'" in session.last_sql
    assert "'USA'" in session.last_sql
    assert "'BRA'" in session.last_sql

    assert (
        "indicator_code = '21047'"
        in session.last_sql
    )


def test_country_comparison_empty_list():

    session = MockSession()

    result = (
        gfs_queries.get_country_comparison(
            session,
            [],
            "21047",
        )
    )

    assert result.empty

    assert session.last_sql is None


# =============================================================================
# SQL LITERAL ESCAPING
# =============================================================================

def test_sql_literal_escaping():

    value = "Cote d'Ivoire"

    escaped = (
        gfs_queries._escape_sql_literal(
            value
        )
    )

    assert escaped == "Cote d''Ivoire"


# =============================================================================
# AGRICULTURE SQL SAFETY
# =============================================================================

def test_agriculture_items_uses_whitelisted_view():

    session = MockSession()

    gfs_queries.get_agriculture_items(
        session,
        "Crops & Livestock",
        "IND",
    )

    assert (
        "GFS_DEV.PUBLISH.V_CROPS_LIVESTOCK"
        in session.last_sql
    )


def test_agriculture_items_rejects_unknown_domain():

    session = MockSession()

    with pytest.raises(ValueError):

        gfs_queries.get_agriculture_items(
            session,
            "DROP TABLE SOMETHING",
            "IND",
        )