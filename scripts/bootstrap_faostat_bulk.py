from __future__ import annotations

import argparse
import hashlib
import json
import os
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pandas as pd
import pyarrow as pa
from deltalake import DeltaTable, write_deltalake


START_YEAR = 2010
END_YEAR = 2023
CHUNK_SIZE = 200_000


DOMAIN_FILES = {
    "QCL": "Production_Crops_Livestock_E_All_Data_(Normalized)",
    "LC": "Environment_LandCover_E_All_Data_(Normalized)",
    "ESB": "Environment_Cropland_nutrient_budget_E_All_Data_(Normalized)",
    "FBS": "FoodBalanceSheets_E_All_Data_(Normalized)",
    "GT": "Emissions_Totals_E_All_Data_(Normalized)",
    "FS": "Food_Security_Data_E_All_Data_(Normalized)",
}


def canonical_json(value: Any) -> str:
    return json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    )


def sha256(value: str) -> str:
    return hashlib.sha256(
        value.encode("utf-8")
    ).hexdigest()


def find_source_file(
    source_dir: Path,
    expected_name: str,
) -> Path:
    matches = [
        path
        for path in source_dir.rglob("*.csv")
        if expected_name.lower() in path.stem.lower()
    ]

    if not matches:
        raise FileNotFoundError(
            f"Could not find normalized FAOSTAT file "
            f"matching '{expected_name}' "
            f"under {source_dir}"
        )

    if len(matches) > 1:
        raise RuntimeError(
            f"Multiple files matched '{expected_name}': "
            f"{matches}"
        )

    return matches[0]


def parse_period(
    value: str,
) -> tuple[int, int] | None:
    value = str(value).strip()

    if not value:
        return None

    if (
        len(value) == 4
        and value.isdigit()
    ):
        year = int(value)
        return year, year

    if "-" in value:
        parts = value.split("-", 1)

        if (
            len(parts) == 2
            and parts[0].isdigit()
            and parts[1].isdigit()
        ):
            return (
                int(parts[0]),
                int(parts[1]),
            )

    return None


def in_project_period(
    year_value: str,
) -> bool:
    period = parse_period(year_value)

    if period is None:
        return False

    start_year, end_year = period

    return (
        start_year >= START_YEAR
        and end_year <= END_YEAR
    )


def filter_project_scope(
    dataframe: pd.DataFrame,
    domain: str,
) -> pd.DataFrame:
    if "Year" not in dataframe.columns:
        raise RuntimeError(
            f"{domain}: source file does not "
            "contain a Year column."
        )

    mask = dataframe["Year"].map(
        in_project_period
    )

    return dataframe.loc[mask].copy()


def build_delta_rows(
    dataframe: pd.DataFrame,
    domain: str,
    run_id: str,
    batch_id: str,
    extracted_at: str,
    source_file: str,
) -> pa.Table:
    rows: list[dict[str, str]] = []

    request_parameters = canonical_json(
        {
            "mode": "bulk_bootstrap",
            "source_file": source_file,
            "start_year": START_YEAR,
            "end_year": END_YEAR,
        }
    )

    for record in dataframe.to_dict(
        orient="records"
    ):
        # dtype=str + keep_default_na=False
        # keeps source values as strings.
        clean_record = {
            str(key): str(value)
            for key, value in record.items()
        }

        source_payload = canonical_json(
            clean_record
        )

        source_period = str(
            clean_record.get(
                "Year",
                "unknown",
            )
        )

        rows.append(
            {
                "source_payload":
                    source_payload,
                "_source_system":
                    "FAOSTAT",
                "_source_domain":
                    domain,
                "_request_year":
                    source_period,
                "_source_page":
                    "BULK",
                "_ingestion_run_id":
                    run_id,
                "_ingestion_batch_id":
                    batch_id,
                "_extracted_at_utc":
                    extracted_at,
                "_source_row_hash":
                    sha256(source_payload),
                "_request_parameters":
                    request_parameters,
            }
        )

    return pa.Table.from_pylist(rows)


def bootstrap_domain(
    domain: str,
    source_file: Path,
    bucket: str,
    region: str,
) -> dict[str, Any]:
    started_at = time.perf_counter()

    run_id = str(uuid.uuid4())

    extracted_at = datetime.now(
        timezone.utc
    ).isoformat()

    file_stat = source_file.stat()

    batch_definition = {
        "source": "faostat",
        "domain": domain,
        "mode": "bulk_bootstrap",
        "source_file": source_file.name,
        "source_file_size":
            file_stat.st_size,
        "source_file_modified_ns":
            file_stat.st_mtime_ns,
        "start_year": START_YEAR,
        "end_year": END_YEAR,
    }

    batch_id = sha256(
        canonical_json(
            batch_definition
        )
    )

    table_uri = (
        f"s3a://{bucket}"
        f"/delta/faostat/"
        f"{domain.lower()}"
    )

    storage_options = {
        "AWS_REGION": region,
    }

    print()
    print("=" * 72)
    print(
        f"{domain} BULK BOOTSTRAP"
    )
    print("=" * 72)
    print(
        f"Source : {source_file}"
    )
    print(
        f"Target : {table_uri}"
    )

    first_write = True

    source_rows = 0
    accepted_rows = 0
    chunk_number = 0

    for dataframe in pd.read_csv(
        source_file,
        dtype=str,
        keep_default_na=False,
        encoding="utf-8-sig",
        chunksize=CHUNK_SIZE,
    ):
        chunk_number += 1

        source_rows += len(dataframe)

        filtered = filter_project_scope(
            dataframe=dataframe,
            domain=domain,
        )

        if filtered.empty:
            print(
                f"[{domain}] "
                f"Chunk {chunk_number}: "
                f"source={len(dataframe):,} | "
                "accepted=0"
            )

            continue

        accepted_rows += len(filtered)

        print(
            f"[{domain}] "
            f"Chunk {chunk_number}: "
            f"source={len(dataframe):,} | "
            f"accepted={len(filtered):,} | "
            f"total accepted="
            f"{accepted_rows:,}"
        )

        table = build_delta_rows(
            dataframe=filtered,
            domain=domain,
            run_id=run_id,
            batch_id=batch_id,
            extracted_at=extracted_at,
            source_file=
                source_file.name,
        )

        write_deltalake(
            table_uri,
            table,
            mode=(
                "overwrite"
                if first_write
                else "append"
            ),
            partition_by=[
                "_request_year"
            ],
            storage_options=
                storage_options,
        )

        first_write = False

        del filtered
        del table

    if first_write:
        raise RuntimeError(
            f"{domain}: no rows matched "
            f"{START_YEAR}-{END_YEAR}."
        )

    delta_table = DeltaTable(
        table_uri,
        storage_options=
            storage_options,
    )

    elapsed_seconds = (
        time.perf_counter()
        - started_at
    )

    result = {
        "domain": domain,
        "status": "SUCCESS",
        "source_rows":
            source_rows,
        "accepted_rows":
            accepted_rows,
        "delta_version":
            delta_table.version(),
        "active_file_count":
            len(
                delta_table.file_uris()
            ),
        "elapsed_seconds":
            round(
                elapsed_seconds,
                2,
            ),
        "table_uri":
            table_uri,
    }

    print()
    print(
        f"[{domain}] SUCCESS | "
        f"source={source_rows:,} | "
        f"accepted={accepted_rows:,} | "
        f"files="
        f"{result['active_file_count']} | "
        f"time="
        f"{elapsed_seconds:.2f}s"
    )

    return result


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Bootstrap FAOSTAT bulk CSVs "
            "into Delta Lake on S3."
        )
    )

    parser.add_argument(
        "--source-dir",
        required=True,
        help=(
            "Directory containing extracted "
            "FAOSTAT bulk CSV files."
        ),
    )

    args = parser.parse_args()

    source_dir = Path(
        args.source_dir
    ).resolve()

    if not source_dir.exists():
        raise FileNotFoundError(
            f"Source directory does not exist: "
            f"{source_dir}"
        )

    bucket = os.environ[
        "GFS_S3_BUCKET"
    ]

    region = os.environ.get(
        "AWS_REGION",
        "ap-south-1",
    )

    print("=" * 72)
    print(
        "FAOSTAT BULK HISTORICAL BOOTSTRAP"
    )
    print("=" * 72)

    print(
        f"Source directory : "
        f"{source_dir}"
    )

    print(
        f"Project window   : "
        f"{START_YEAR}-{END_YEAR}"
    )

    print(
        f"Chunk size       : "
        f"{CHUNK_SIZE:,}"
    )

    print(
        "Write mode       : "
        "replace each domain Delta table"
    )

    results = []

    for domain, expected_name in (
        DOMAIN_FILES.items()
    ):
        source_file = (
            find_source_file(
                source_dir=
                    source_dir,
                expected_name=
                    expected_name,
            )
        )

        result = bootstrap_domain(
            domain=domain,
            source_file=source_file,
            bucket=bucket,
            region=region,
        )

        results.append(result)

    print()
    print("=" * 72)
    print(
        "FAOSTAT BULK BOOTSTRAP COMPLETE"
    )
    print("=" * 72)

    total_rows = 0

    for result in results:
        total_rows += (
            result["accepted_rows"]
        )

        print(
            f"{result['domain']:>3} | "
            f"rows="
            f"{result['accepted_rows']:,} | "
            f"files="
            f"{result['active_file_count']} | "
            f"time="
            f"{result['elapsed_seconds']:.2f}s"
        )

    print("-" * 72)

    print(
        f"TOTAL ROWS: "
        f"{total_rows:,}"
    )


if __name__ == "__main__":
    main()