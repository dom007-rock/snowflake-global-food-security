import argparse
import json
import os
from pathlib import Path

from src.ingestion.faostat.pipeline import FAOSTATIngestionPipeline


CONFIG_PATH = Path("config/faostat_ingestion.json")


def load_config() -> dict:
    with CONFIG_PATH.open("r", encoding="utf-8") as file:
        return json.load(file)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Backfill annual FAOSTAT domains into Delta Lake."
    )

    parser.add_argument(
        "--domain",
        help="Run one domain only, for example QCL.",
    )

    parser.add_argument(
        "--start-year",
        type=int,
    )

    parser.add_argument(
        "--end-year",
        type=int,
    )

    args = parser.parse_args()

    config = load_config()

    start_year = args.start_year or config["start_year"]
    end_year = args.end_year or config["end_year"]

    domains = config["yearly_domains"]

    if args.domain:
        domain = args.domain.upper()

        if domain not in domains:
            raise ValueError(
                f"{domain} is not configured as an annual domain."
            )

        domains = [domain]

    pipeline = FAOSTATIngestionPipeline(
        bucket=os.environ["GFS_S3_BUCKET"],
        region=os.environ.get("AWS_REGION", "ap-south-1"),
    )

    summary = []

    for domain in domains:
        for year in range(start_year, end_year + 1):
            print(f"\n[{domain}] Starting {year}")

            result = pipeline.ingest(
                domain=domain,
                filters={
                    "year": str(year),
                },
            )

            summary.append(result)

            print(
                f"[{domain}] {year}: "
                f"{result['status']} | "
                f"rows={result.get('row_count', 0)} | "
                f"files={result.get('added_file_count', 0)}"
            )

    print("\nBACKFILL SUMMARY")

    for result in summary:
        print(
            f"{result['domain']} "
            f"{result.get('request_year', '')}: "
            f"{result['status']} "
            f"({result.get('row_count', 0)} rows)"
        )


if __name__ == "__main__":
    main()