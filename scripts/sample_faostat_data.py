import argparse
import os
from pathlib import Path

import faostat
from dotenv import load_dotenv


OUTPUT_ROOT = Path("samples/faostat")


def configure_faostat() -> None:
    load_dotenv(override=True)

    token = os.getenv("FAOSTAT_ACCESS_TOKEN")
    if not token:
        raise RuntimeError("FAOSTAT_ACCESS_TOKEN is not configured.")

    faostat.set_requests_args(
        token=token,
        timeout=120,
    )


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download a filtered FAOSTAT sample for source profiling."
    )

    parser.add_argument("--domain", required=True)

    parser.add_argument(
        "--filter",
        action="append",
        default=[],
        metavar="DIMENSION=VALUE",
        help=(
            "FAOSTAT filter in DIMENSION=VALUE format. "
            "Can be supplied multiple times."
        ),
    )

    return parser.parse_args()


def build_filters(filter_args: list[str]) -> dict[str, str]:
    filters = {}

    for filter_arg in filter_args:
        if "=" not in filter_arg:
            raise ValueError(
                f"Invalid filter '{filter_arg}'. "
                "Expected DIMENSION=VALUE."
            )

        dimension, value = filter_arg.split("=", 1)

        dimension = dimension.strip()
        value = value.strip()

        if not dimension or not value:
            raise ValueError(
                f"Invalid filter '{filter_arg}'. "
                "Dimension and value are required."
            )

        filters[dimension] = value

    return filters


def main() -> None:
    args = parse_arguments()

    domain = args.domain.upper()
    filters = build_filters(args.filter)

    configure_faostat()

    data = faostat.get_data_df(
        domain,
        pars=filters,
        coding={"area": "ISO3"},
        show_flags=True,
        null_values=True,
        show_notes=True,
        strval=False,
    )

    output_dir = OUTPUT_ROOT / domain.lower()
    output_dir.mkdir(parents=True, exist_ok=True)

    output_path = output_dir / "sample_data.csv"
    data.to_csv(output_path, index=False)

    print(f"Domain: {domain}")
    print(f"Filters: {filters}")
    print(f"Rows: {len(data)}")
    print(f"Columns: {len(data.columns)}")
    print(f"Output: {output_path}")
    print()
    print(data.head())


if __name__ == "__main__":
    main()