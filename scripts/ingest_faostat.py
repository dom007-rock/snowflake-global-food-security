import argparse
import json
import os

from src.ingestion.faostat.pipeline import FAOSTATIngestionPipeline

def parse_filters(values: list[str]) -> dict[str, str]:
    filters = {}

    for value in values:
        if "=" not in value:
            raise ValueError(
                f"Invalid filter '{value}'. Expected KEY=VALUE."
            )

        key, filter_value = value.split("=", 1)
        filters[key.strip()] = filter_value.strip()

    return filters


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ingest FAOSTAT data into Delta Lake on S3."
    )

    parser.add_argument(
        "--domain",
        required=True,
        help="FAOSTAT domain code, for example QCL.",
    )

    parser.add_argument(
        "--filter",
        action="append",
        default=[],
        help="Repeatable FAOSTAT filter in KEY=VALUE format.",
    )

    args = parser.parse_args()

    bucket = os.environ["GFS_S3_BUCKET"]
    region = os.environ.get("AWS_REGION", "ap-south-1")

    pipeline = FAOSTATIngestionPipeline(
        bucket=bucket,
        region=region,
    )

    result = pipeline.ingest(
        domain=args.domain,
        filters=parse_filters(args.filter),
    )

    print(json.dumps(result, indent=2))
    


if __name__ == "__main__":
    main()