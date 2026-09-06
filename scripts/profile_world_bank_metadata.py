from pathlib import Path

import pandas as pd
import requests


BASE_URL = "https://api.worldbank.org/v2"
OUTPUT_DIR = Path("samples/world_bank")

INDICATORS = [
    "SP.POP.TOTL",
    "NY.GDP.MKTP.CD",
    "NY.GDP.PCAP.CD",
    "SP.RUR.TOTL.ZS",
    "NV.AGR.TOTL.ZS",
]


def fetch_indicator_metadata(indicator_code: str) -> dict:
    url = f"{BASE_URL}/indicator/{indicator_code}"

    params = {
        "source": 2,
        "format": "json",
    }

    response = requests.get(url, params=params, timeout=30)
    response.raise_for_status()

    payload = response.json()

    if not payload or len(payload) < 2 or not payload[1]:
        return {}

    return payload[1][0]


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    rows = []

    for indicator_code in INDICATORS:
        record = fetch_indicator_metadata(indicator_code)

        if not record:
            print(f"No metadata returned for {indicator_code}")
            continue

        topics = record.get("topics", [])

        rows.append(
            {
                "indicator_code": record.get("id"),
                "indicator_name": record.get("name"),
                "unit": record.get("unit"),
                "source_id": record.get("source", {}).get("id"),
                "source_name": record.get("source", {}).get("value"),
                "source_note": record.get("sourceNote"),
                "source_organization": record.get("sourceOrganization"),
                "topics": ", ".join(
                    topic.get("value", "")
                    for topic in topics
                    if topic.get("value")
                ),
            }
        )

    df = pd.DataFrame(rows)

    output_path = OUTPUT_DIR / "indicator_metadata.csv"
    df.to_csv(output_path, index=False)

    print("\nWORLD BANK WDI INDICATOR METADATA")
    print("=" * 80)
    print(df.to_string(index=False))

    print(f"\nSaved to: {output_path}")


if __name__ == "__main__":
    main()