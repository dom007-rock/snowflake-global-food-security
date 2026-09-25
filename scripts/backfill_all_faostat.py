import os
import sys
import time

from src.ingestion.faostat.pipeline import (
    FAOSTATAuthenticationError,
    FAOSTATIngestionPipeline,
)


YEARLY_DOMAINS = [
    "QCL",
    "LC",
    "ESB",
    "FBS",
    "GT",
]

START_YEAR = 2010
END_YEAR = 2023


def main() -> None:
    bucket = os.environ["GFS_S3_BUCKET"]

    region = os.environ.get(
        "AWS_REGION",
        "ap-south-1",
    )

    pipeline = FAOSTATIngestionPipeline(
        bucket=bucket,
        region=region,
        max_workers=6,
    )

    started_at = time.perf_counter()

    completed = 0
    skipped = 0

    print("=" * 70)
    print("FAOSTAT HISTORICAL BACKFILL")
    print("=" * 70)

    print(
        f"Domains : {', '.join(YEARLY_DOMAINS)}"
    )

    print(
        f"Years   : {START_YEAR}-{END_YEAR}"
    )

    print(
        "Mode    : sequential domain-years, "
        "parallel API pages"
    )

    print("=" * 70)

    for domain in YEARLY_DOMAINS:

        print()
        print("=" * 70)
        print(f"DOMAIN: {domain}")
        print("=" * 70)

        for year in range(
            START_YEAR,
            END_YEAR + 1,
        ):

            print()
            print(
                f"[{domain}] Checking {year}..."
            )

            if pipeline.is_year_loaded(
                domain=domain,
                year=year,
            ):
                print(
                    f"[{domain}] {year}: "
                    "ALREADY LOADED -> SKIP"
                )

                skipped += 1
                continue

            print(
                f"[{domain}] {year}: "
                "STARTING"
            )

            try:
                result = pipeline.ingest(
                    domain=domain,
                    filters={
                        "year": str(year),
                    },
                )

            except FAOSTATAuthenticationError:
                print()
                print("=" * 70)
                print("FAOSTAT TOKEN EXPIRED")
                print("=" * 70)

                print(
                    f"Stopped at: "
                    f"{domain} {year}"
                )

                print()
                print(
                    "Update FAOSTAT_ACCESS_TOKEN "
                    "in .env and run the SAME "
                    "command again."
                )

                print()
                print(
                    "Previously committed "
                    "domain-years will be "
                    "skipped automatically."
                )

                sys.exit(2)

            except KeyboardInterrupt:
                print()
                print(
                    "Backfill interrupted by user."
                )

                print(
                    f"Resume point: "
                    f"{domain} {year}"
                )

                print(
                    "Run the same command again "
                    "to resume."
                )

                sys.exit(130)

            except Exception as exc:
                print()
                print("=" * 70)
                print("BACKFILL FAILED")
                print("=" * 70)

                print(
                    f"Domain : {domain}"
                )

                print(
                    f"Year   : {year}"
                )

                print(
                    f"Error  : {exc}"
                )

                print()
                print(
                    "Fix the issue and run the "
                    "same command again."
                )

                print(
                    "Completed domain-years will "
                    "be skipped automatically."
                )

                raise

            completed += 1

            print(
                f"[{domain}] {year}: "
                f"{result['status']} | "
                f"rows="
                f"{result.get('row_count', 0):,} | "
                f"pages="
                f"{result.get('page_count', 0):,}"
            )

    elapsed = (
        time.perf_counter()
        - started_at
    )

    print()
    print("=" * 70)
    print("ANNUAL BACKFILL COMPLETE")
    print("=" * 70)

    print(
        f"New loads : {completed}"
    )

    print(
        f"Skipped   : {skipped}"
    )

    print(
        f"Runtime   : "
        f"{elapsed / 60:.2f} minutes"
    )

    print()
    print(
        "FS remains a special temporal-domain "
        "load and is handled separately."
    )


if __name__ == "__main__":
    main()