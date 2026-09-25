from pathlib import Path

import pandas as pd
import requests


BASE_URL = "https://api.worldbank.org/v2"
OUTPUT_DIR = Path("samples/world_bank")

COUNTRY = "IND"
START_YEAR = 2010
END_YEAR = 2023

INDICATORS = {
    "SP.POP.TOTL": "Population, total",
    "NY.GDP.MKTP.CD": "GDP (current US$)",
    "NY.GDP.PCAP.CD": "GDP per capita (current US$)",
    "SP.RUR.TOTL.ZS": "Rural population (% of total population)",
    "NV.AGR.TOTL.ZS": (
        "Agriculture, forestry, and fishing, value added (% of GDP)"
    ),
}


def fetch_indicator(indicator_code: str) -> list[dict]:
    url = f"{BASE_URL}/country/{COUNTRY}/indicator/{indicator_code}"

    params = {
        "source": 2,
        "date": f"{START_YEAR}:{END_YEAR}",
        "format": "json",
        "per_page": 100,
    }

    response = requests.get(url, params=params, timeout=30)
    response.raise_for_status()

    payload = response.json()

    if not payload or len(payload) < 2 or payload[1] is None:
        return []

    return payload[1]


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    rows = []

    for indicator_code, indicator_name in INDICATORS.items():
        data = fetch_indicator(indicator_code)

        for record in data:
            rows.append(
                {
                    "country_code": record.get("countryiso3code"),
                    "country": record.get("country", {}).get("value"),
                    "indicator_code": indicator_code,
                    "indicator": indicator_name,
                    "year": record.get("date"),
                    "value": record.get("value"),
                    "unit": record.get("unit"),
                    "obs_status": record.get("obs_status"),
                    "decimal": record.get("decimal"),
                }
            )

    df = pd.DataFrame(rows)

    output_path = OUTPUT_DIR / "sample_data.csv"
    df.to_csv(output_path, index=False)

    print("\nWORLD BANK WDI SAMPLE")
    print("=" * 80)
    print(f"Rows: {len(df)}")
    print(f"Countries: {df['country_code'].nunique()}")
    print(f"Indicators: {df['indicator_code'].nunique()}")
    print(f"Years: {df['year'].nunique()}")
    print(f"Null values: {df['value'].isna().sum()}")

    print("\nCoverage by indicator:")
    print(
        df.groupby(["indicator_code", "indicator"])
        .agg(
            rows=("year", "count"),
            non_null_values=("value", "count"),
            min_year=("year", "min"),
            max_year=("year", "max"),
        )
        .reset_index()
        .to_string(index=False)
    )

    print(f"\nSaved to: {output_path}")


if __name__ == "__main__":
    main()