"""
Global Food Security & Nutrition Intelligence Platform
Phase 15 - Streamlit Application
"""

import streamlit as st
import gfs_queries as queries


# =============================================================================
# PAGE CONFIG
# =============================================================================

st.set_page_config(
    page_title="Global Food Security Intelligence",
    page_icon="🌍",
    layout="wide",
    initial_sidebar_state="expanded",
)


st.title("🌍 Global Food Security & Nutrition Intelligence")

st.caption(
    "Integrated FAOSTAT and World Bank indicators for food-system, "
    "nutrition, agricultural, demographic, environmental, and "
    "socioeconomic analysis."
)


# =============================================================================
# SNOWFLAKE CONNECTION
# =============================================================================

@st.cache_resource
def get_snowflake_session():
    connection = st.connection("snowflake")
    return connection.session()


try:
    session = get_snowflake_session()

except Exception as exc:
    st.error("Unable to connect to Snowflake.")
    st.exception(exc)
    st.stop()


# =============================================================================
# CACHED LOADERS
# =============================================================================

@st.cache_data(ttl=600)
def load_countries():
    return queries.get_countries(session)


@st.cache_data(ttl=600)
def load_food_security_indicators():
    return queries.get_food_security_indicators(session)


@st.cache_data(ttl=300)
def load_food_security_trend(
    country_iso3,
    indicator_code,
):
    return queries.get_food_security_trend(
        session,
        country_iso3,
        indicator_code,
    )


@st.cache_data(ttl=300)
def load_country_comparison(
    countries,
    indicator_code,
):
    return queries.get_country_comparison(
        session,
        list(countries),
        indicator_code,
    )


@st.cache_data(ttl=600)
def load_aggregate_geographies():
    return queries.get_aggregate_geographies(session)


@st.cache_data(ttl=600)
def load_aggregate_indicators():
    return queries.get_aggregate_indicators(session)


@st.cache_data(ttl=300)
def load_aggregate_trend(
    geography_name,
    indicator_code,
):
    return queries.get_aggregate_food_security_trend(
        session,
        geography_name,
        indicator_code,
    )


@st.cache_data(ttl=300)
def load_agriculture_items(
    domain_name,
    country_iso3,
):
    return queries.get_agriculture_items(
        session,
        domain_name,
        country_iso3,
    )


@st.cache_data(ttl=300)
def load_agriculture_elements(
    domain_name,
    country_iso3,
    item_code,
):
    return queries.get_agriculture_elements(
        session,
        domain_name,
        country_iso3,
        item_code,
    )


@st.cache_data(ttl=300)
def load_agriculture_trend(
    domain_name,
    country_iso3,
    item_code,
    element_code,
):
    return queries.get_agriculture_trend(
        session,
        domain_name,
        country_iso3,
        item_code,
        element_code,
    )


# =============================================================================
# HELPERS
# =============================================================================

def get_latest_non_null(
    df,
    column_name,
):
    available = (
        df[
            [
                "YEAR",
                column_name,
            ]
        ]
        .dropna(
            subset=[column_name]
        )
        .sort_values("YEAR")
    )

    if available.empty:
        return None, None

    latest = available.iloc[-1]

    return (
        latest[column_name],
        int(latest["YEAR"]),
    )


def format_metric(
    value,
    metric_type="number",
):
    if value is None:
        return "N/A"

    if metric_type == "integer":
        return f"{value:,.0f}"

    if metric_type == "currency":
        return f"${value:,.0f}"

    if metric_type == "percent":
        return f"{value:,.1f}%"

    return f"{value:,.1f}"


# =============================================================================
# COUNTRY METADATA
# =============================================================================

try:
    countries_df = load_countries()

except Exception as exc:
    st.error("Unable to load country metadata.")
    st.exception(exc)
    st.stop()


if countries_df.empty:
    st.error(
        "No countries were found in "
        "GFS_DEV.PUBLISH.V_COUNTRY_YEAR_INTELLIGENCE."
    )
    st.stop()


country_lookup = dict(
    zip(
        countries_df["COUNTRY_ISO3"],
        countries_df["GEOGRAPHY_NAME"],
    )
)

country_codes = list(
    country_lookup.keys()
)


# =============================================================================
# SIDEBAR
# =============================================================================

with st.sidebar:

    st.header("Global Filters")

    default_country_index = (
        country_codes.index("IND")
        if "IND" in country_codes
        else 0
    )

    selected_country = st.selectbox(
        "Country",
        options=country_codes,
        index=default_country_index,
        format_func=lambda code: (
            f"{country_lookup[code]} ({code})"
        ),
    )

    st.divider()

    st.caption("Analytical period")
    st.write("2010 - 2023")

    st.caption("Primary sources")
    st.write("FAOSTAT")
    st.write("World Bank WDI")

    st.divider()

    st.caption(
        "Indicators are presented for comparative and contextual "
        "analysis. The application does not infer causal relationships."
    )


# =============================================================================
# TABS
# =============================================================================

(
    overview_tab,
    food_security_tab,
    comparison_tab,
    agriculture_tab,
    aggregates_tab,
) = st.tabs(
    [
        "📊 Overview",
        "🥗 Food Security",
        "🌐 Country Comparison",
        "🌾 Agriculture Explorer",
        "🗺️ FAOSTAT Aggregates",
    ]
)


# =============================================================================
# TAB 1 - OVERVIEW
# =============================================================================

with overview_tab:

    country_name = country_lookup[
        selected_country
    ]

    st.header(
        f"{country_name} Overview"
    )

    st.caption(
        "Socioeconomic context and selected nutrition and "
        "food-system indicators."
    )

    try:

        country_df = (
            queries.get_country_intelligence(
                session,
                selected_country,
            )
        )

        if country_df.empty:

            st.info(
                "No integrated observations are available "
                "for this country."
            )

        else:

            min_year = int(
                country_df["YEAR"].min()
            )

            max_year = int(
                country_df["YEAR"].max()
            )

            st.caption(
                f"Available coverage: {min_year} - {max_year}"
            )


            # -----------------------------------------------------------------
            # SOCIOECONOMIC METRICS
            # -----------------------------------------------------------------

            population, population_year = (
                get_latest_non_null(
                    country_df,
                    "POPULATION_TOTAL",
                )
            )

            gdp_pc, gdp_pc_year = (
                get_latest_non_null(
                    country_df,
                    "GDP_PER_CAPITA_CURRENT_USD",
                )
            )

            rural_pct, rural_year = (
                get_latest_non_null(
                    country_df,
                    "RURAL_POPULATION_PCT",
                )
            )

            agri_gdp, agri_year = (
                get_latest_non_null(
                    country_df,
                    "AGRICULTURE_VALUE_ADDED_PCT_GDP",
                )
            )


            st.subheader(
                "Socioeconomic context"
            )

            c1, c2, c3, c4 = st.columns(4)

            c1.metric(
                "Population",
                format_metric(
                    population,
                    "integer",
                ),
                help=(
                    f"Latest available year: {population_year}"
                    if population_year
                    else "No observation available"
                ),
            )

            c2.metric(
                "GDP per capita",
                format_metric(
                    gdp_pc,
                    "currency",
                ),
                help=(
                    f"Latest available year: {gdp_pc_year}"
                    if gdp_pc_year
                    else "No observation available"
                ),
            )

            c3.metric(
                "Rural population",
                format_metric(
                    rural_pct,
                    "percent",
                ),
                help=(
                    f"Latest available year: {rural_year}"
                    if rural_year
                    else "No observation available"
                ),
            )

            c4.metric(
                "Agriculture value added",
                format_metric(
                    agri_gdp,
                    "percent",
                ),
                help=(
                    f"Share of GDP | Latest available year: {agri_year}"
                    if agri_year
                    else "No observation available"
                ),
            )


            # -----------------------------------------------------------------
            # NUTRITION METRICS
            # -----------------------------------------------------------------

            drinking_water, water_year = (
                get_latest_non_null(
                    country_df,
                    "BASIC_DRINKING_WATER_PCT",
                )
            )

            sanitation, sanitation_year = (
                get_latest_non_null(
                    country_df,
                    "BASIC_SANITATION_PCT",
                )
            )

            anemia, anemia_year = (
                get_latest_non_null(
                    country_df,
                    "ANEMIA_WOMEN_PCT",
                )
            )

            stunting, stunting_year = (
                get_latest_non_null(
                    country_df,
                    "CHILD_STUNTING_PCT",
                )
            )


            st.subheader(
                "Food security & nutrition context"
            )

            c1, c2, c3, c4 = st.columns(4)

            c1.metric(
                "Basic drinking water",
                format_metric(
                    drinking_water,
                    "percent",
                ),
                help=(
                    f"Latest available year: {water_year}"
                    if water_year
                    else "No observation available"
                ),
            )

            c2.metric(
                "Basic sanitation",
                format_metric(
                    sanitation,
                    "percent",
                ),
                help=(
                    f"Latest available year: {sanitation_year}"
                    if sanitation_year
                    else "No observation available"
                ),
            )

            c3.metric(
                "Anemia among women",
                format_metric(
                    anemia,
                    "percent",
                ),
                help=(
                    f"Women aged 15-49 | Latest year: {anemia_year}"
                    if anemia_year
                    else "No observation available"
                ),
            )

            c4.metric(
                "Child stunting",
                format_metric(
                    stunting,
                    "percent",
                ),
                help=(
                    f"Children under 5 | Latest year: {stunting_year}"
                    if stunting_year
                    else "No observation available"
                ),
            )


            # -----------------------------------------------------------------
            # GDP TREND
            # -----------------------------------------------------------------

            st.subheader(
                "GDP per capita trend"
            )

            gdp_chart_df = (
                country_df[
                    [
                        "YEAR",
                        "GDP_PER_CAPITA_CURRENT_USD",
                    ]
                ]
                .dropna(
                    subset=[
                        "GDP_PER_CAPITA_CURRENT_USD"
                    ]
                )
                .sort_values("YEAR")
            )

            if gdp_chart_df.empty:
                st.info(
                    "GDP per capita data are unavailable."
                )

            else:
                st.line_chart(
                    gdp_chart_df,
                    x="YEAR",
                    y="GDP_PER_CAPITA_CURRENT_USD",
                )


            # -----------------------------------------------------------------
            # HEADLINE TREND
            # -----------------------------------------------------------------

            st.subheader(
                "Food security & nutrition trend"
            )

            overview_metrics = {
                "Caloric losses at retail":
                    "CALORIC_LOSS_RETAIL_PCT",

                "Basic drinking water":
                    "BASIC_DRINKING_WATER_PCT",

                "Basic sanitation":
                    "BASIC_SANITATION_PCT",

                "Anemia among women aged 15-49":
                    "ANEMIA_WOMEN_PCT",

                "Child stunting":
                    "CHILD_STUNTING_PCT",

                "Adult obesity":
                    "ADULT_OBESITY_PCT",
            }

            metric_name = st.selectbox(
                "Indicator",
                options=list(
                    overview_metrics.keys()
                ),
                key="overview_metric",
            )

            metric_column = (
                overview_metrics[
                    metric_name
                ]
            )

            metric_df = (
                country_df[
                    [
                        "YEAR",
                        metric_column,
                    ]
                ]
                .dropna(
                    subset=[metric_column]
                )
                .sort_values("YEAR")
            )

            if metric_df.empty:
                st.info(
                    "No observations are available for this indicator."
                )

            else:
                st.line_chart(
                    metric_df,
                    x="YEAR",
                    y=metric_column,
                )


            with st.expander(
                "View underlying country-year data"
            ):

                st.dataframe(
                    country_df,
                    use_container_width=True,
                    hide_index=True,
                )


    except Exception as exc:

        st.error(
            "Unable to retrieve integrated country data."
        )

        st.exception(exc)


# =============================================================================
# TAB 2 - FOOD SECURITY
# =============================================================================

with food_security_tab:

    country_name = (
        country_lookup[
            selected_country
        ]
    )

    st.header(
        "Food Security & Nutrition"
    )

    st.caption(
        f"Explore annual FAOSTAT indicators for {country_name}."
    )

    try:

        indicators_df = (
            load_food_security_indicators()
            .copy()
        )

        if indicators_df.empty:

            st.info(
                "No country-level indicators are available."
            )

        else:

            indicators_df[
                "DISPLAY_LABEL"
            ] = (
                indicators_df[
                    "INDICATOR_NAME"
                ].astype(str)
                + " ["
                + indicators_df[
                    "INDICATOR_CODE"
                ].astype(str)
                + "]"
            )

            labels = (
                indicators_df[
                    "DISPLAY_LABEL"
                ].tolist()
            )

            default_index = 0

            preferred = indicators_df[
                indicators_df[
                    "INDICATOR_CODE"
                ].astype(str)
                == "21047"
            ]

            if not preferred.empty:

                preferred_label = (
                    preferred.iloc[0][
                        "DISPLAY_LABEL"
                    ]
                )

                default_index = (
                    labels.index(
                        preferred_label
                    )
                )

            selected_label = st.selectbox(
                "Indicator",
                options=labels,
                index=default_index,
                key="food_security_indicator",
            )

            indicator_row = (
                indicators_df[
                    indicators_df[
                        "DISPLAY_LABEL"
                    ]
                    == selected_label
                ]
                .iloc[0]
            )

            indicator_code = str(
                indicator_row[
                    "INDICATOR_CODE"
                ]
            )

            indicator_name = (
                indicator_row[
                    "INDICATOR_NAME"
                ]
            )

            c1, c2, c3 = st.columns(3)

            c1.metric(
                "Countries available",
                int(
                    indicator_row[
                        "COUNTRY_COUNT"
                    ]
                ),
            )

            c2.metric(
                "First available year",
                int(
                    indicator_row[
                        "MIN_YEAR"
                    ]
                ),
            )

            c3.metric(
                "Latest available year",
                int(
                    indicator_row[
                        "MAX_YEAR"
                    ]
                ),
            )

            st.caption(
                f"Unit: {indicator_row['UNIT']}"
            )

            trend_df = (
                load_food_security_trend(
                    selected_country,
                    indicator_code,
                )
            )

            if trend_df.empty:

                st.info(
                    "No observations are available "
                    "for this country and indicator."
                )

            else:

                element_df = (
                    trend_df[
                        [
                            "ELEMENT_CODE",
                            "ELEMENT_NAME",
                        ]
                    ]
                    .drop_duplicates()
                )

                display_df = (
                    trend_df.copy()
                )

                if len(element_df) > 1:

                    element_df = (
                        element_df.copy()
                    )

                    element_df[
                        "DISPLAY_LABEL"
                    ] = (
                        element_df[
                            "ELEMENT_NAME"
                        ].astype(str)
                        + " ["
                        + element_df[
                            "ELEMENT_CODE"
                        ].astype(str)
                        + "]"
                    )

                    element_label = (
                        st.selectbox(
                            "Element",
                            options=element_df[
                                "DISPLAY_LABEL"
                            ].tolist(),
                            key="food_security_element",
                        )
                    )

                    selected_element = (
                        element_df[
                            element_df[
                                "DISPLAY_LABEL"
                            ]
                            == element_label
                        ]
                        .iloc[0]
                    )

                    element_code = (
                        selected_element[
                            "ELEMENT_CODE"
                        ]
                    )

                    display_df = (
                        trend_df[
                            trend_df[
                                "ELEMENT_CODE"
                            ]
                            == element_code
                        ]
                        .copy()
                    )

                numeric_df = (
                    display_df
                    .dropna(
                        subset=["VALUE"]
                    )
                    .sort_values("YEAR")
                )

                if numeric_df.empty:

                    st.info(
                        "Rows exist, but no numeric values are available."
                    )

                else:

                    latest = numeric_df.iloc[-1]

                    latest_unit = (
                        latest["UNIT"]
                    )

                    c1, c2, c3 = (
                        st.columns(3)
                    )

                    c1.metric(
                        "Latest observation",
                        format_metric(
                            latest["VALUE"],
                            (
                                "percent"
                                if latest_unit == "%"
                                else "number"
                            ),
                        ),
                    )

                    c2.metric(
                        "Observation year",
                        int(
                            latest["YEAR"]
                        ),
                    )

                    c3.metric(
                        "Observations",
                        len(numeric_df),
                    )

                    min_year = int(
                        numeric_df[
                            "YEAR"
                        ].min()
                    )

                    max_year = int(
                        numeric_df[
                            "YEAR"
                        ].max()
                    )

                    chart_df = (
                        numeric_df.copy()
                    )

                    if min_year < max_year:

                        year_range = (
                            st.slider(
                                "Year range",
                                min_value=min_year,
                                max_value=max_year,
                                value=(
                                    min_year,
                                    max_year,
                                ),
                                key="food_security_year_range",
                            )
                        )

                        chart_df = (
                            numeric_df[
                                (
                                    numeric_df[
                                        "YEAR"
                                    ]
                                    >= year_range[0]
                                )
                                &
                                (
                                    numeric_df[
                                        "YEAR"
                                    ]
                                    <= year_range[1]
                                )
                            ]
                        )

                    st.subheader(
                        indicator_name
                    )

                    st.line_chart(
                        chart_df,
                        x="YEAR",
                        y="VALUE",
                    )

                    with st.expander(
                        "View underlying observations"
                    ):

                        st.dataframe(
                            display_df,
                            use_container_width=True,
                            hide_index=True,
                        )

                    st.caption(
                        "Changes over time are descriptive and "
                        "do not establish causal relationships."
                    )


    except Exception as exc:

        st.error(
            "Unable to retrieve food-security data."
        )

        st.exception(exc)


# =============================================================================
# TAB 3 - COUNTRY COMPARISON
# =============================================================================

with comparison_tab:

    st.header(
        "Country Comparison"
    )

    st.caption(
        "Compare selected food-security and nutrition indicators "
        "across countries."
    )

    try:

        comparison_codes = {
            "21059",
            "21047",
            "21048",
            "21043",
            "21025",
            "21042",
        }

        comparison_indicators = (
            load_food_security_indicators()
            .copy()
        )

        comparison_indicators = (
            comparison_indicators[
                comparison_indicators[
                    "INDICATOR_CODE"
                ].astype(str)
                .isin(
                    comparison_codes
                )
            ]
            .copy()
        )

        comparison_indicators[
            "DISPLAY_LABEL"
        ] = (
            comparison_indicators[
                "INDICATOR_NAME"
            ].astype(str)
            + " ["
            + comparison_indicators[
                "INDICATOR_CODE"
            ].astype(str)
            + "]"
        )

        selected_label = st.selectbox(
            "Comparison indicator",
            options=comparison_indicators[
                "DISPLAY_LABEL"
            ].tolist(),
            key="comparison_indicator",
        )

        selected_row = (
            comparison_indicators[
                comparison_indicators[
                    "DISPLAY_LABEL"
                ]
                == selected_label
            ]
            .iloc[0]
        )

        indicator_code = str(
            selected_row[
                "INDICATOR_CODE"
            ]
        )

        indicator_name = (
            selected_row[
                "INDICATOR_NAME"
            ]
        )

        defaults = [
            code
            for code in [
                "IND",
                "USA",
                "BRA",
            ]
            if code in country_codes
        ]

        if len(defaults) < 2:
            defaults = (
                country_codes[:2]
            )

        selected_countries = (
            st.multiselect(
                "Countries",
                options=country_codes,
                default=defaults,
                max_selections=5,
                format_func=lambda code: (
                    f"{country_lookup[code]} ({code})"
                ),
            )
        )

        if len(selected_countries) < 2:

            st.info(
                "Select at least two countries."
            )

        else:

            comparison_df = (
                load_country_comparison(
                    tuple(
                        selected_countries
                    ),
                    indicator_code,
                )
            )

            comparison_df = (
                comparison_df
                .dropna(
                    subset=["VALUE"]
                )
            )

            if comparison_df.empty:

                st.info(
                    "No numeric observations are available."
                )

            else:

                chart_df = (
                    comparison_df
                    .pivot(
                        index="YEAR",
                        columns="GEOGRAPHY_NAME",
                        values="VALUE",
                    )
                    .sort_index()
                )

                st.subheader(
                    indicator_name
                )

                st.line_chart(
                    chart_df
                )

                with st.expander(
                    "View comparison data"
                ):

                    st.dataframe(
                        comparison_df,
                        use_container_width=True,
                        hide_index=True,
                    )

                st.caption(
                    "Differences shown are descriptive and should not "
                    "be interpreted as causal comparisons."
                )


    except Exception as exc:

        st.error(
            "Unable to retrieve country comparison data."
        )

        st.exception(exc)


# =============================================================================
# TAB 4 - AGRICULTURE EXPLORER
# =============================================================================

with agriculture_tab:

    st.header(
        "Agriculture Explorer"
    )

    st.caption(
        "Explore crops, livestock, food balances, land cover, "
        "nutrient balance, and emissions."
    )

    try:

        domain_name = (
            st.selectbox(
                "Dataset",
                options=list(
                    queries.AGRICULTURE_DOMAINS.keys()
                ),
                key="agriculture_domain",
            )
        )

        item_df = (
            load_agriculture_items(
                domain_name,
                selected_country,
            )
        )

        if item_df.empty:

            st.info(
                "No items are available for this selection."
            )

        else:

            item_df = item_df.copy()

            item_df[
                "DISPLAY_LABEL"
            ] = (
                item_df[
                    "ITEM_NAME"
                ].astype(str)
                + " ["
                + item_df[
                    "ITEM_CODE"
                ].astype(str)
                + "]"
            )

            item_label = st.selectbox(
                "Item",
                options=item_df[
                    "DISPLAY_LABEL"
                ].tolist(),
                key="agriculture_item",
            )

            selected_item = (
                item_df[
                    item_df[
                        "DISPLAY_LABEL"
                    ]
                    == item_label
                ]
                .iloc[0]
            )

            item_code = str(
                selected_item[
                    "ITEM_CODE"
                ]
            )

            item_name = (
                selected_item[
                    "ITEM_NAME"
                ]
            )

            element_df = (
                load_agriculture_elements(
                    domain_name,
                    selected_country,
                    item_code,
                )
            )

            if element_df.empty:

                st.info(
                    "No elements are available for this item."
                )

            else:

                element_df = (
                    element_df.copy()
                )

                element_df[
                    "DISPLAY_LABEL"
                ] = (
                    element_df[
                        "ELEMENT_NAME"
                    ].astype(str)
                    + " ["
                    + element_df[
                        "ELEMENT_CODE"
                    ].astype(str)
                    + "]"
                )

                element_label = (
                    st.selectbox(
                        "Element",
                        options=element_df[
                            "DISPLAY_LABEL"
                        ].tolist(),
                        key="agriculture_element",
                    )
                )

                selected_element = (
                    element_df[
                        element_df[
                            "DISPLAY_LABEL"
                        ]
                        == element_label
                    ]
                    .iloc[0]
                )

                element_code = str(
                    selected_element[
                        "ELEMENT_CODE"
                    ]
                )

                element_name = (
                    selected_element[
                        "ELEMENT_NAME"
                    ]
                )

                agriculture_df = (
                    load_agriculture_trend(
                        domain_name,
                        selected_country,
                        item_code,
                        element_code,
                    )
                )

                numeric_df = (
                    agriculture_df
                    .dropna(
                        subset=["VALUE"]
                    )
                    .sort_values("YEAR")
                )

                if numeric_df.empty:

                    st.info(
                        "No numeric observations are available."
                    )

                else:

                    latest = (
                        numeric_df.iloc[-1]
                    )

                    c1, c2, c3 = (
                        st.columns(3)
                    )

                    c1.metric(
                        "Latest observation",
                        format_metric(
                            latest["VALUE"]
                        ),
                    )

                    c2.metric(
                        "Observation year",
                        int(
                            latest["YEAR"]
                        ),
                    )

                    c3.metric(
                        "Unit",
                        (
                            str(
                                latest["UNIT"]
                            )
                            if latest["UNIT"]
                            else "N/A"
                        ),
                    )

                    st.subheader(
                        f"{item_name} | {element_name}"
                    )

                    duplicate_years = (
                        numeric_df
                        .groupby("YEAR")
                        .size()
                        .max()
                        > 1
                    )

                    if duplicate_years:

                        st.warning(
                            "Multiple source observations exist for "
                            "one or more years. They are not collapsed "
                            "into an artificial annual value."
                        )

                    else:

                        st.line_chart(
                            numeric_df,
                            x="YEAR",
                            y="VALUE",
                        )

                    with st.expander(
                        "View agriculture observations"
                    ):

                        st.dataframe(
                            agriculture_df,
                            use_container_width=True,
                            hide_index=True,
                        )


    except Exception as exc:

        st.error(
            "Unable to retrieve agriculture data."
        )

        st.exception(exc)


# =============================================================================
# TAB 5 - FAOSTAT AGGREGATES
# =============================================================================

with aggregates_tab:

    st.header(
        "FAOSTAT Aggregate Explorer"
    )

    st.caption(
        "Explore regional and global observations "
        "published directly by FAOSTAT."
    )

    st.warning(
        "These are source-published FAOSTAT aggregates. "
        "The application does not calculate regional percentages "
        "by averaging country values."
    )

    try:

        geographies_df = (
            load_aggregate_geographies()
        )

        indicators_df = (
            load_aggregate_indicators()
            .copy()
        )

        if (
            geographies_df.empty
            or indicators_df.empty
        ):

            st.info(
                "No aggregate observations are available."
            )

        else:

            geography_options = (
                geographies_df[
                    "GEOGRAPHY_NAME"
                ].tolist()
            )

            default_index = (
                geography_options.index(
                    "World"
                )
                if "World"
                in geography_options
                else 0
            )

            selected_geography = (
                st.selectbox(
                    "Aggregate geography",
                    options=geography_options,
                    index=default_index,
                    key="aggregate_geography",
                )
            )

            indicators_df[
                "DISPLAY_LABEL"
            ] = (
                indicators_df[
                    "INDICATOR_NAME"
                ].astype(str)
                + " ["
                + indicators_df[
                    "INDICATOR_CODE"
                ].astype(str)
                + "]"
            )

            indicator_label = (
                st.selectbox(
                    "Aggregate indicator",
                    options=indicators_df[
                        "DISPLAY_LABEL"
                    ].tolist(),
                    key="aggregate_indicator",
                )
            )

            indicator_row = (
                indicators_df[
                    indicators_df[
                        "DISPLAY_LABEL"
                    ]
                    == indicator_label
                ]
                .iloc[0]
            )

            indicator_code = str(
                indicator_row[
                    "INDICATOR_CODE"
                ]
            )

            indicator_name = (
                indicator_row[
                    "INDICATOR_NAME"
                ]
            )

            aggregate_df = (
                load_aggregate_trend(
                    selected_geography,
                    indicator_code,
                )
            )

            if aggregate_df.empty:

                st.info(
                    "No observations are available "
                    "for this selection."
                )

            else:

                element_df = (
                    aggregate_df[
                        [
                            "ELEMENT_CODE",
                            "ELEMENT_NAME",
                        ]
                    ]
                    .drop_duplicates()
                )

                display_df = (
                    aggregate_df.copy()
                )

                if len(element_df) > 1:

                    element_df = (
                        element_df.copy()
                    )

                    element_df[
                        "DISPLAY_LABEL"
                    ] = (
                        element_df[
                            "ELEMENT_NAME"
                        ].astype(str)
                        + " ["
                        + element_df[
                            "ELEMENT_CODE"
                        ].astype(str)
                        + "]"
                    )

                    element_label = (
                        st.selectbox(
                            "Element",
                            options=element_df[
                                "DISPLAY_LABEL"
                            ].tolist(),
                            key="aggregate_element",
                        )
                    )

                    selected_element = (
                        element_df[
                            element_df[
                                "DISPLAY_LABEL"
                            ]
                            == element_label
                        ]
                        .iloc[0]
                    )

                    element_code = (
                        selected_element[
                            "ELEMENT_CODE"
                        ]
                    )

                    display_df = (
                        aggregate_df[
                            aggregate_df[
                                "ELEMENT_CODE"
                            ]
                            == element_code
                        ]
                        .copy()
                    )

                numeric_df = (
                    display_df
                    .dropna(
                        subset=["VALUE"]
                    )
                    .sort_values("YEAR")
                )

                if numeric_df.empty:

                    st.info(
                        "Rows exist, but no numeric observations "
                        "are available."
                    )

                else:

                    latest = (
                        numeric_df.iloc[-1]
                    )

                    latest_unit = (
                        latest["UNIT"]
                    )

                    c1, c2, c3 = (
                        st.columns(3)
                    )

                    c1.metric(
                        "Latest observation",
                        format_metric(
                            latest["VALUE"],
                            (
                                "percent"
                                if latest_unit == "%"
                                else "number"
                            ),
                        ),
                    )

                    c2.metric(
                        "Observation year",
                        int(
                            latest["YEAR"]
                        ),
                    )

                    c3.metric(
                        "Observations",
                        len(numeric_df),
                    )

                    st.subheader(
                        f"{selected_geography}: "
                        f"{indicator_name}"
                    )

                    st.line_chart(
                        numeric_df,
                        x="YEAR",
                        y="VALUE",
                    )

                    with st.expander(
                        "View aggregate observations"
                    ):

                        st.dataframe(
                            display_df,
                            use_container_width=True,
                            hide_index=True,
                        )


    except Exception as exc:

        st.error(
            "Unable to retrieve FAOSTAT aggregate data."
        )

        st.exception(exc)


# =============================================================================
# FOOTER
# =============================================================================

st.divider()

st.caption(
    "Global Food Security & Nutrition Intelligence Platform | "
    "FAOSTAT + World Bank WDI | V1: 2010-2023"
)
