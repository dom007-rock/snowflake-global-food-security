from pathlib import Path

import pandas as pd


DOMAINS = ["LC", "ESB", "FBS"]
SAMPLE_ROOT = Path("samples/faostat")

GRAIN_COLUMNS = [
    "Area Code (ISO3)",
    "Item Code",
    "Element Code",
    "Year Code",
]


def count_unique(df: pd.DataFrame, column: str) -> int:
    if column not in df.columns:
        return 0

    return df[column].nunique(dropna=True)


def count_nulls(df: pd.DataFrame, column: str) -> int:
    if column not in df.columns:
        return 0

    return int(df[column].isna().sum())


def count_non_null(df: pd.DataFrame, column: str) -> int:
    if column not in df.columns:
        return 0

    return int(df[column].notna().sum())


def summarize_domain(domain: str) -> dict:
    path = SAMPLE_ROOT / domain.lower() / "sample_data.csv"
    df = pd.read_csv(path)

    duplicate_rows = None

    if all(column in df.columns for column in GRAIN_COLUMNS):
        duplicate_rows = int(
            df.duplicated(
                subset=GRAIN_COLUMNS,
                keep=False,
            ).sum()
        )

    null_values = count_nulls(df, "Value")

    return {
        "domain": domain,
        "rows": len(df),
        "items": count_unique(df, "Item Code"),
        "elements": count_unique(df, "Element Code"),
        "years": count_unique(df, "Year Code"),
        "units": count_unique(df, "Unit"),
        "null_values": null_values,
        "null_value_pct": (
            round(null_values / len(df) * 100, 2)
            if len(df)
            else 0
        ),
        "flags": count_unique(df, "Flag"),
        "non_null_notes": count_non_null(df, "Note"),
        "duplicate_grain_rows": duplicate_rows,
    }


def print_domain_details(domain: str, df: pd.DataFrame) -> None:
    print(f"\n{'=' * 80}")
    print(domain)
    print("=" * 80)

    print("\nColumns:")
    print(", ".join(df.columns))

    if {"Element Code", "Element"}.issubset(df.columns):
        print("\nElements:")
        print(
            df[["Element Code", "Element"]]
            .drop_duplicates()
            .sort_values("Element Code")
            .to_string(index=False)
        )

    if "Unit" in df.columns:
        print("\nUnits:")
        print(
            df["Unit"]
            .value_counts(dropna=False)
            .to_string()
        )

    if {"Flag", "Flag Description"}.issubset(df.columns):
        print("\nFlags:")
        print(
            df[["Flag", "Flag Description"]]
            .drop_duplicates()
            .to_string(index=False)
        )

    if "Note" not in df.columns:
        print("\nNote:")
        print("Column not returned by source.")


def main():
    summaries = []

    for domain in DOMAINS:
        path = SAMPLE_ROOT / domain.lower() / "sample_data.csv"

        if not path.exists():
            print(f"Skipping {domain}: {path} not found")
            continue

        summaries.append(summarize_domain(domain))

    summary_df = pd.DataFrame(summaries)

    print("\nFAOSTAT SAMPLE SUMMARY")
    print("=" * 80)

    if not summary_df.empty:
        print(summary_df.to_string(index=False))

    for domain in DOMAINS:
        path = SAMPLE_ROOT / domain.lower() / "sample_data.csv"

        if not path.exists():
            continue

        df = pd.read_csv(path)
        print_domain_details(domain, df)


if __name__ == "__main__":
    main()