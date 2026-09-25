from __future__ import annotations

import argparse
import os
import sys

from dotenv import load_dotenv

from src.ingestion.faostat.pipeline import FAOSTATIngestionPipeline
from src.orchestration.snowflake_handoff import SnowflakeHandoff


SUPPORTED_DOMAINS = ("QCL",)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run FAOSTAT ingestion and hand the committed "
            "Delta batch to Snowflake."
        )
    )

    parser.add_argument(
        "--domain",
        required=True,
        choices=SUPPORTED_DOMAINS,
        help="FAOSTAT domain to refresh.",
    )

    parser.add_argument(
        "--year",
        required=True,
        type=int,
        help="FAOSTAT year to refresh.",
    )

    parser.add_argument(
        "--bucket",
        default=None,
        help="Optional S3 bucket override.",
    )

    parser.add_argument(
        "--region",
        default=None,
        help="Optional AWS region override.",
    )

    return parser.parse_args()


def main() -> int:
    load_dotenv(override=True)
    args = parse_args()

    bucket = (
        args.bucket
        or os.getenv("GFS_S3_BUCKET")
        or "gfs-delta-dev-kush01"
    )

    region = (
        args.region
        or os.getenv("AWS_REGION")
        or "ap-south-1"
    )

    if not 2010 <= args.year <= 2023:
        raise ValueError(
            "Project v1 analytical period is 2010-2023."
        )

    print("=" * 70)
    print("GLOBAL FOOD SECURITY - FAOSTAT REFRESH")
    print("=" * 70)
    print(f"Domain : {args.domain}")
    print(f"Year   : {args.year}")
    print(f"Bucket : {bucket}")
    print(f"Region : {region}")
    print("=" * 70)

    pipeline = FAOSTATIngestionPipeline(
        bucket=bucket,
        region=region,
    )

    result = pipeline.ingest(
        domain=args.domain,
        filters={
            "year": str(args.year),
        },
    )

    status = result["status"]

    print()
    print(f"[Ingestion] Status: {status}")

    if status == "NO_DATA":
        print(
            "[Pipeline] Source returned no data. "
            "Nothing to process."
        )
        return 0

    if status not in (
        "SUCCESS",
        "SKIPPED_ALREADY_LOADED",
    ):
        raise RuntimeError(
            f"Unexpected ingestion status: {status}"
        )

    batch_id = result["batch_id"]
    run_id = result["run_id"]
    row_count = result["row_count"]

    print(f"[Pipeline] Run ID   : {run_id}")
    print(f"[Pipeline] Batch ID : {batch_id}")
    print(f"[Pipeline] Source rows: {row_count:,}")

    if status == "SKIPPED_ALREADY_LOADED":
        print(
            "[Pipeline] Identical Delta snapshot already exists. "
            "Continuing Snowflake handoff using the existing batch."
        )

    handoff = SnowflakeHandoff()

    try:
        if args.domain == "QCL":
            handoff.wait_for_qcl_raw_batch(
                batch_id=batch_id,
                expected_rows=row_count,
            )

            merge_result = handoff.merge_qcl_clean(
                batch_id=batch_id,
            )

            print(
                f"[Pipeline] CLEAN result: "
                f"{merge_result}"
            )

    finally:
        handoff.close()

    print()
    print("=" * 70)
    print("PIPELINE COMPLETED SUCCESSFULLY")
    print("=" * 70)

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())

    except KeyboardInterrupt:
        print("\nPipeline cancelled.")
        sys.exit(130)

    except Exception as exc:
        print(
            f"\n[FAILED] {type(exc).__name__}: {exc}"
        )
        sys.exit(1)
