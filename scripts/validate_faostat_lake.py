from __future__ import annotations

import json
import os
from collections import Counter
from typing import Any

import pyarrow.compute as pc
from deltalake import DeltaTable


EXPECTED_ROWS = {
    "QCL": 1_005_808,
    "LC": 119_230,
    "ESB": 194_244,
    "FBS": 4_820_497,
    "GT": 820_429,
    "FS": 187_905,
}

ANNUAL_DOMAINS = {
    "QCL",
    "LC",
    "ESB",
    "FBS",
    "GT",
}

START_YEAR = 2010
END_YEAR = 2023


def parse_period(
    value: str,
) -> tuple[int, int] | None:
    value = str(value).strip()

    if not value:
        return None

    if len(value) == 4 and value.isdigit():
        year = int(value)
        return year, year

    if "-" in value:
        left, right = value.split("-", 1)

        if left.isdigit() and right.isdigit():
            return int(left), int(right)

    return None


def validate_period(
    domain: str,
    value: str,
) -> bool:
    period = parse_period(value)

    if period is None:
        return False

    start_year, end_year = period

    if domain in ANNUAL_DOMAINS:
        return (
            start_year == end_year
            and START_YEAR <= start_year <= END_YEAR
        )

    return (
        start_year >= START_YEAR
        and end_year <= END_YEAR
    )


def validate_domain(
    domain: str,
    bucket: str,
    region: str,
) -> dict[str, Any]:
    table_uri = (
        f"s3a://{bucket}"
        f"/delta/faostat/{domain.lower()}"
    )

    delta_table = DeltaTable(
        table_uri,
        storage_options={
            "AWS_REGION": region,
        },
    )

    dataset = delta_table.to_pyarrow_dataset()

    scanner = dataset.scanner(
        columns=[
            "source_payload",
            "_source_system",
            "_source_domain",
            "_request_year",
            "_ingestion_run_id",
            "_ingestion_batch_id",
            "_source_row_hash",
        ],
        batch_size=100_000,
    )

    row_count = 0
    period_counts: Counter[str] = Counter()

    null_technical_rows = 0
    invalid_period_rows = 0
    source_mismatch_rows = 0

    sample_payloads: list[str] = []

    for batch in scanner.to_batches():
        row_count += batch.num_rows

        years = batch.column(
            batch.schema.get_field_index(
                "_request_year"
            )
        ).to_pylist()

        source_systems = batch.column(
            batch.schema.get_field_index(
                "_source_system"
            )
        ).to_pylist()

        source_domains = batch.column(
            batch.schema.get_field_index(
                "_source_domain"
            )
        ).to_pylist()

        run_ids = batch.column(
            batch.schema.get_field_index(
                "_ingestion_run_id"
            )
        ).to_pylist()

        batch_ids = batch.column(
            batch.schema.get_field_index(
                "_ingestion_batch_id"
            )
        ).to_pylist()

        row_hashes = batch.column(
            batch.schema.get_field_index(
                "_source_row_hash"
            )
        ).to_pylist()

        payloads = batch.column(
            batch.schema.get_field_index(
                "source_payload"
            )
        ).to_pylist()

        for index, period in enumerate(years):
            period = str(period)

            period_counts[period] += 1

            if not validate_period(
                domain=domain,
                value=period,
            ):
                invalid_period_rows += 1

            if (
                source_systems[index] != "FAOSTAT"
                or source_domains[index] != domain
                or not run_ids[index]
                or not batch_ids[index]
                or not row_hashes[index]
            ):
                null_technical_rows += 1

            if len(sample_payloads) < 5:
                sample_payloads.append(
                    payloads[index]
                )

    for payload in sample_payloads:
        record = json.loads(payload)

        if not isinstance(record, dict):
            source_mismatch_rows += 1
            continue

        if "Year" not in record:
            source_mismatch_rows += 1

    expected_rows = EXPECTED_ROWS[domain]

    row_count_matches = (
        row_count == expected_rows
    )

    status = (
        "PASS"
        if (
            row_count_matches
            and null_technical_rows == 0
            and invalid_period_rows == 0
            and source_mismatch_rows == 0
        )
        else "FAIL"
    )

    return {
        "domain": domain,
        "status": status,
        "rows": row_count,
        "expected_rows": expected_rows,
        "files": len(
            delta_table.file_uris()
        ),
        "delta_version":
            delta_table.version(),
        "period_count":
            len(period_counts),
        "periods":
            sorted(period_counts),
        "invalid_period_rows":
            invalid_period_rows,
        "invalid_technical_rows":
            null_technical_rows,
        "sample_payload_failures":
            source_mismatch_rows,
    }


def main() -> None:
    bucket = os.environ[
        "GFS_S3_BUCKET"
    ]

    region = os.environ.get(
        "AWS_REGION",
        "ap-south-1",
    )

    print("=" * 78)
    print(
        "FAOSTAT DELTA LAKE RECONCILIATION"
    )
    print("=" * 78)

    results = []

    for domain in EXPECTED_ROWS:
        print(
            f"\nValidating {domain}..."
        )

        result = validate_domain(
            domain=domain,
            bucket=bucket,
            region=region,
        )

        results.append(result)

        print(
            f"{domain}: "
            f"{result['status']} | "
            f"rows={result['rows']:,} | "
            f"files={result['files']} | "
            f"version={result['delta_version']}"
        )

    print()
    print("=" * 78)
    print("RECONCILIATION SUMMARY")
    print("=" * 78)

    total_rows = 0
    failures = []

    for result in results:
        total_rows += result["rows"]

        print(
            f"{result['domain']:>3} | "
            f"{result['status']:>4} | "
            f"rows={result['rows']:,} | "
            f"expected="
            f"{result['expected_rows']:,} | "
            f"files={result['files']} | "
            f"periods="
            f"{result['period_count']}"
        )

        if result["status"] != "PASS":
            failures.append(
                result["domain"]
            )

    print("-" * 78)
    print(
        f"TOTAL ROWS: {total_rows:,}"
    )

    if failures:
        raise RuntimeError(
            "Validation failed for: "
            + ", ".join(failures)
        )

    print()
    print(
        "ALL FAOSTAT DELTA TABLES PASSED."
    )


if __name__ == "__main__":
    main()