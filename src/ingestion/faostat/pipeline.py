from __future__ import annotations

import hashlib
import json
import os
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from typing import Any

import pyarrow as pa
import requests
from deltalake import DeltaTable, write_deltalake
from dotenv import load_dotenv
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


BASE_URL = "https://faostatservices.fao.org/api/v1/en"

DEFAULT_PAGE_SIZE = 1000
DEFAULT_MAX_WORKERS = 6

class FAOSTATAuthenticationError(RuntimeError):
    pass

def _canonical_json(value: Any) -> str:
    return json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    )


def _sha256(value: str) -> str:
    return hashlib.sha256(
        value.encode("utf-8")
    ).hexdigest()


class FAOSTATIngestionPipeline:
    def __init__(
        self,
        bucket: str,
        region: str,
        timeout: int = 60,
        page_size: int = DEFAULT_PAGE_SIZE,
        max_workers: int = DEFAULT_MAX_WORKERS,
    ) -> None:
        load_dotenv(override=True)

        token = os.getenv(
            "FAOSTAT_ACCESS_TOKEN"
        )

        if not token:
            raise RuntimeError(
                "FAOSTAT_ACCESS_TOKEN is not configured."
            )

        if max_workers < 1:
            raise ValueError(
                "max_workers must be at least 1."
            )

        self.bucket = bucket
        self.region = region
        self.timeout = timeout
        self.page_size = page_size
        self.max_workers = max_workers

        self.token = token

        # Each worker thread receives its own
        # requests.Session.
        self._thread_local = threading.local()

        # Current delta-rs uses S3 conditional writes.
        # No DynamoDB locking configuration required.
        self.storage_options = {
            "AWS_REGION": region,
        }

    def _create_session(
        self,
    ) -> requests.Session:
        session = requests.Session()

        session.headers.update(
            {
                "Authorization":
                    f"Bearer {self.token}",
                "Accept": "application/json",
            }
        )

        retry = Retry(
            total=4,
            connect=4,
            read=4,
            status=4,
            backoff_factor=1.0,
            status_forcelist=(
                429,
                500,
                502,
                503,
                504,
            ),
            allowed_methods=frozenset(
                {"GET"}
            ),
            respect_retry_after_header=True,
        )

        session.mount(
            "https://",
            HTTPAdapter(
                max_retries=retry
            ),
        )

        return session

    def _get_session(
        self,
    ) -> requests.Session:
        session = getattr(
            self._thread_local,
            "session",
            None,
        )

        if session is None:
            session = self._create_session()

            self._thread_local.session = (
                session
            )

        return session

    def _request(
        self,
        domain: str,
        params: dict[str, Any],
    ) -> dict[str, Any]:
        url = (
            f"{BASE_URL}/data/{domain}"
        )

        session = self._get_session()

        response = session.get(
            url,
            params=params,
            timeout=self.timeout,
        )
        if response.status_code == 401:
            raise FAOSTATAuthenticationError(
            "FAOSTAT authentication failed. "
            "The access token may have expired."
        )

        if not response.ok:
            raise RuntimeError(
                "FAOSTAT request failed: "
                f"{response.status_code} "
                f"{response.url}\n"
                f"{response.text[:500]}"
            )

        payload = response.json()

        if not isinstance(payload, dict):
            raise RuntimeError(
                "Unexpected FAOSTAT payload "
                f"type: "
                f"{type(payload).__name__}"
            )

        if "data" not in payload:
            raise RuntimeError(
                "FAOSTAT response does not "
                "contain a data field."
            )

        return payload

    def is_year_loaded(
        self,
        domain: str,
        year: int,
    ) -> bool:
        table_uri = (
            f"s3a://{self.bucket}"
            f"/delta/faostat/{domain.lower()}"
        )

        if not DeltaTable.is_deltatable(
            table_uri,
            storage_options=self.storage_options,
        ):
            return False

        delta_table = DeltaTable(
            table_uri,
            storage_options=self.storage_options,
        )

        expected_parameters = _canonical_json(
            {
                "year": str(year),
            }
        )

        existing = delta_table.to_pyarrow_table(
            columns=[
                "_request_year",
                "_request_parameters",
            ],
            filters=[
                (
                    "_request_year",
                    "=",
                    str(year),
                )
            ],
        )

        if existing.num_rows == 0:
            return False

        request_parameters = (
            existing
            .column("_request_parameters")
            .to_pylist()
        )

        return expected_parameters in request_parameters

    def _build_params(
        self,
        filters: dict[str, str],
        page_number: int,
    ) -> dict[str, Any]:
        return {
            **filters,
            "show_codes": "true",
            "show_unit": "true",
            "show_flags": "true",
            "show_notes": "true",
            "null_values": "true",
            "output_type": "objects",
            "datasource": "PRODUCTION",
            "page_number": page_number,
            "page_size": self.page_size,
        }

    def _fetch_page(
        self,
        domain: str,
        filters: dict[str, str],
        page_number: int,
    ) -> dict[str, Any]:
        started_at = time.perf_counter()

        payload = self._request(
            domain=domain,
            params=self._build_params(
                filters=filters,
                page_number=page_number,
            ),
        )

        elapsed_seconds = (
            time.perf_counter()
            - started_at
        )

        page_records = (
            payload.get("data") or []
        )

        if not isinstance(
            page_records,
            list,
        ):
            raise RuntimeError(
                "FAOSTAT data field is not "
                "a list."
            )

        page_hash = _sha256(
            _canonical_json(
                page_records
            )
        )

        return {
            "page_number": page_number,
            "records": page_records,
            "metadata":
                payload.get("metadata"),
            "page_hash": page_hash,
            "elapsed_seconds":
                elapsed_seconds,
        }

    def _append_page(
        self,
        page_result: dict[str, Any],
        records: list[dict[str, Any]],
        request_pages:
            list[dict[str, Any]],
    ) -> None:
        page_number = (
            page_result["page_number"]
        )

        page_records = (
            page_result["records"]
        )

        for record in page_records:
            records.append(
                {
                    "page_number":
                        page_number,
                    "record": record,
                }
            )

        request_pages.append(
            {
                "page_number":
                    page_number,
                "row_count":
                    len(page_records),
                "elapsed_seconds":
                    round(
                        page_result[
                            "elapsed_seconds"
                        ],
                        3,
                    ),
                "metadata":
                    page_result[
                        "metadata"
                    ],
            }
        )

    def extract(
        self,
        domain: str,
        filters: dict[str, str],
    ) -> tuple[
        list[dict[str, Any]],
        list[dict[str, Any]],
    ]:
        records: list[
            dict[str, Any]
        ] = []

        request_pages: list[
            dict[str, Any]
        ] = []

        print(
            f"[{domain.upper()}] "
            "Starting extraction | "
            f"workers={self.max_workers} | "
            f"page_size={self.page_size}"
        )

        # Fetch the first page separately.
        first_page = self._fetch_page(
            domain=domain,
            filters=filters,
            page_number=1,
        )

        print(
            f"[{domain.upper()}] "
            "Page 1: "
            f"{len(first_page['records']):,} "
            "rows | "
            f"{first_page['elapsed_seconds']:.2f}s"
        )

        self._append_page(
            page_result=first_page,
            records=records,
            request_pages=request_pages,
        )

        previous_page_hash = (
            first_page["page_hash"]
        )

        # A short first page means that
        # extraction is already complete.
        if (
            len(first_page["records"])
            < self.page_size
        ):
            print(
                f"[{domain.upper()}] "
                "Extraction complete: "
                f"{len(records):,} rows "
                "across 1 page."
            )

            return (
                records,
                request_pages,
            )

        next_page = 2

        with ThreadPoolExecutor(
            max_workers=self.max_workers
        ) as executor:

            while True:
                page_numbers = list(
                    range(
                        next_page,
                        next_page
                        + self.max_workers,
                    )
                )

                print(
                    f"[{domain.upper()}] "
                    "Requesting pages "
                    f"{page_numbers[0]}"
                    "-"
                    f"{page_numbers[-1]} "
                    "in parallel..."
                )

                futures = {
                    executor.submit(
                        self._fetch_page,
                        domain,
                        filters,
                        page_number,
                    ): page_number
                    for page_number
                    in page_numbers
                }

                window_results: list[
                    dict[str, Any]
                ] = []

                for future in as_completed(
                    futures
                ):
                    page_number = (
                        futures[future]
                    )

                    try:
                        result = (
                            future.result()
                        )
                    except Exception as exc:
                        raise RuntimeError(
                            f"FAOSTAT page "
                            f"{page_number} "
                            "failed during "
                            "parallel extraction."
                        ) from exc

                    window_results.append(
                        result
                    )

                    print(
                        f"[{domain.upper()}] "
                        f"Page {page_number}: "
                        f"{len(result['records']):,} "
                        "rows | "
                        f"{result['elapsed_seconds']:.2f}s"
                    )

                # Threads finish in arbitrary order.
                # Sort before adding rows so the
                # logical page order is deterministic.
                window_results.sort(
                    key=lambda item:
                        item["page_number"]
                )

                end_reached = False
                end_page: int | None = None

                for result in window_results:
                    page_number = (
                        result[
                            "page_number"
                        ]
                    )

                    page_records = (
                        result["records"]
                    )

                    # Once a short page is found,
                    # later pages should be empty.
                    if end_reached:
                        if page_records:
                            raise RuntimeError(
                                "Inconsistent FAOSTAT "
                                "pagination: "
                                f"page {end_page} "
                                "indicated the end, "
                                f"but page "
                                f"{page_number} "
                                "returned data."
                            )

                        continue

                    page_hash = (
                        result["page_hash"]
                    )

                    if (
                        page_records
                        and page_hash
                        == previous_page_hash
                    ):
                        raise RuntimeError(
                            "FAOSTAT returned "
                            "identical consecutive "
                            "pages at page "
                            f"{page_number}. "
                            "Pagination aborted."
                        )

                    previous_page_hash = (
                        page_hash
                    )

                    self._append_page(
                        page_result=result,
                        records=records,
                        request_pages=
                            request_pages,
                    )

                    if (
                        len(page_records)
                        < self.page_size
                    ):
                        end_reached = True
                        end_page = (
                            page_number
                        )

                print(
                    f"[{domain.upper()}] "
                    f"Collected "
                    f"{len(records):,} rows "
                    f"across "
                    f"{len(request_pages):,} "
                    "data pages."
                )

                if end_reached:
                    break

                next_page += (
                    self.max_workers
                )

        print(
            f"[{domain.upper()}] "
            "Extraction complete: "
            f"{len(records):,} rows "
            f"across "
            f"{len(request_pages):,} "
            "pages."
        )

        return records, request_pages

    def ingest(
        self,
        domain: str,
        filters: dict[str, str],
    ) -> dict[str, Any]:
        run_id = str(
            uuid.uuid4()
        )

        extracted_at = (
            datetime.now(
                timezone.utc
            ).isoformat()
        )

        extraction_started = (
            time.perf_counter()
        )

        records, request_pages = (
            self.extract(
                domain=domain,
                filters=filters,
            )
        )

        extraction_seconds = (
            time.perf_counter()
            - extraction_started
        )

        print(
            f"[{domain.upper()}] "
            "Extraction finished | "
            f"rows={len(records):,} | "
            f"pages="
            f"{len(request_pages):,} | "
            f"time="
            f"{extraction_seconds:.2f}s"
        )

        if not records:
            return {
                "status": "NO_DATA",
                "run_id": run_id,
                "domain":
                    domain.upper(),
                "row_count": 0,
                "page_count":
                    len(request_pages),
                "added_file_count": 0,
                "extraction_seconds":
                    round(
                        extraction_seconds,
                        3,
                    ),
            }

        print(
            f"[{domain.upper()}] "
            "Computing source "
            "snapshot fingerprint..."
        )

        source_row_hashes = sorted(
            _sha256(
                _canonical_json(
                    item["record"]
                )
            )
            for item in records
        )

        snapshot_hash = _sha256(
            _canonical_json(
                source_row_hashes
            )
        )

        batch_definition = {
            "source": "faostat",
            "domain":
                domain.upper(),
            "filters": filters,
            "snapshot_hash":
                snapshot_hash,
        }

        batch_id = _sha256(
            _canonical_json(
                batch_definition
            )
        )

        request_year = str(
            filters.get(
                "year",
                "unknown",
            )
        )

        rows: list[
            dict[str, str]
        ] = []

        print(
            f"[{domain.upper()}] "
            "Preparing Delta rows..."
        )

        for item in records:
            source_payload = (
                _canonical_json(
                    item["record"]
                )
            )

            rows.append(
                {
                    "source_payload":
                        source_payload,
                    "_source_system":
                        "FAOSTAT",
                    "_source_domain":
                        domain.upper(),
                    "_request_year":
                        request_year,
                    "_source_page":
                        str(
                            item[
                                "page_number"
                            ]
                        ),
                    "_ingestion_run_id":
                        run_id,
                    "_ingestion_batch_id":
                        batch_id,
                    "_extracted_at_utc":
                        extracted_at,
                    "_source_row_hash":
                        _sha256(
                            source_payload
                        ),
                    "_request_parameters":
                        _canonical_json(
                            filters
                        ),
                }
            )

        # The original source-record objects
        # are no longer needed.
        del records
        del source_row_hashes

        print(
            f"[{domain.upper()}] "
            "Building PyArrow table..."
        )

        table = (
            pa.Table.from_pylist(
                rows
            )
        )

        del rows

        print(
            f"[{domain.upper()}] "
            "Arrow table ready: "
            f"{table.num_rows:,} rows."
        )

        table_uri = (
            f"s3a://{self.bucket}"
            f"/delta/faostat/"
            f"{domain.lower()}"
        )

        table_exists = (
            DeltaTable.is_deltatable(
                table_uri,
                storage_options=
                    self.storage_options,
            )
        )

        before_files: set[str] = (
            set()
        )

        if table_exists:
            delta_table = DeltaTable(
                table_uri,
                storage_options=
                    self.storage_options,
            )

            before_files = set(
                delta_table.file_uris()
            )

            print(
                f"[{domain.upper()}] "
                "Checking idempotency..."
            )

            existing = (
                delta_table
                .to_pyarrow_table(
                    columns=[
                        "_ingestion_batch_id"
                    ],
                    filters=[
                        (
                            "_ingestion_batch_id",
                            "=",
                            batch_id,
                        )
                    ],
                )
            )

            if (
                existing.num_rows
                > 0
            ):
                print(
                    f"[{domain.upper()}] "
                    "Batch already exists. "
                    "Skipping Delta write."
                )

                return {
                    "status":
                        "SKIPPED_ALREADY_LOADED",
                    "run_id": run_id,
                    "batch_id":
                        batch_id,
                    "domain":
                        domain.upper(),
                    "request_year":
                        request_year,
                    "row_count":
                        table.num_rows,
                    "page_count":
                        len(
                            request_pages
                        ),
                    "added_file_count":
                        0,
                    "active_file_count":
                        len(
                            before_files
                        ),
                    "snapshot_hash":
                        snapshot_hash,
                    "delta_version":
                        delta_table.version(),
                    "extraction_seconds":
                        round(
                            extraction_seconds,
                            3,
                        ),
                    "table_uri":
                        table_uri,
                }

        print(
            f"[{domain.upper()}] "
            "Writing Delta table "
            "to S3..."
        )

        write_started = (
            time.perf_counter()
        )

        write_deltalake(
            table_uri,
            table,
            mode=(
                "append"
                if table_exists
                else "error"
            ),
            partition_by=[
                "_request_year"
            ],
            storage_options=
                self.storage_options,
        )

        write_seconds = (
            time.perf_counter()
            - write_started
        )

        print(
            f"[{domain.upper()}] "
            "Delta write completed | "
            f"time="
            f"{write_seconds:.2f}s"
        )

        delta_table = DeltaTable(
            table_uri,
            storage_options=
                self.storage_options,
        )

        after_files = set(
            delta_table.file_uris()
        )

        added_file_count = len(
            after_files
            - before_files
        )

        active_file_count = len(
            after_files
        )

        result = {
            "status": "SUCCESS",
            "run_id": run_id,
            "batch_id": batch_id,
            "domain":
                domain.upper(),
            "request_year":
                request_year,
            "row_count":
                table.num_rows,
            "page_count":
                len(request_pages),
            "added_file_count":
                added_file_count,
            "active_file_count":
                active_file_count,
            "snapshot_hash":
                snapshot_hash,
            "delta_version":
                delta_table.version(),
            "extraction_seconds":
                round(
                    extraction_seconds,
                    3,
                ),
            "write_seconds":
                round(
                    write_seconds,
                    3,
                ),
            "table_uri":
                table_uri,
        }

        print(
            f"[{domain.upper()}] "
            "SUCCESS | "
            f"rows="
            f"{table.num_rows:,} | "
            f"pages="
            f"{len(request_pages):,} | "
            f"extract="
            f"{extraction_seconds:.2f}s | "
            f"write="
            f"{write_seconds:.2f}s | "
            f"files_added="
            f"{added_file_count} | "
            f"delta_version="
            f"{delta_table.version()}"
        )

        return result