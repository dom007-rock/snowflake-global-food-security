import pyarrow as pa
import argparse
import hashlib
import json
import os
import uuid
from datetime import datetime, timezone

import requests
from deltalake import write_deltalake


INDICATORS = [
    "SP.POP.TOTL",
    "NY.GDP.MKTP.CD",
    "NY.GDP.PCAP.CD",
    "SP.RUR.TOTL.ZS",
    "NV.AGR.TOTL.ZS",
]

START_YEAR = 2010
END_YEAR = 2023

WORLD_BANK_SOURCE_ID = 2

OBSERVATIONS_TABLE = (
    "s3://gfs-delta-dev-kush01/"
    "delta/world_bank/wdi_observations/"
)

METADATA_TABLE = (
    "s3://gfs-delta-dev-kush01/"
    "delta/world_bank/wdi_indicator_metadata/"
)

ENTITY_METADATA_TABLE = (
    "s3://gfs-delta-dev-kush01/"
    "delta/world_bank/wdi_entity_metadata/"
)


def extract_entity_metadata():
    run_id = str(uuid.uuid4())
    extracted_at = datetime.now(timezone.utc).isoformat()

    url = "https://api.worldbank.org/v2/country"

    params = {
        "format": "json",
        "per_page": 500,
    }

    payload = get_json(url, params=params)
    rows = payload[1] or []

    records = []

    for row in rows:
        source_payload = canonical_json(row)

        records.append(
            {
                "source_payload": source_payload,
                "_source_system": "WORLD_BANK",
                "_source_domain": "WDI_ENTITY_METADATA",
                "_ingestion_run_id": run_id,
                "_ingestion_batch_id": sha256(
                    canonical_json(
                        {"dataset": "country_metadata"}
                    )
                ),
                "_extracted_at_utc": extracted_at,
                "_source_row_hash": sha256(source_payload),
                "_request_parameters": canonical_json(params),
            }
        )

    return records

def canonical_json(value):
    return json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    )


def sha256(value):
    return hashlib.sha256(
        value.encode("utf-8")
    ).hexdigest()


def get_json(url, params=None):
    response = requests.get(
        url,
        params=params,
        timeout=60,
    )
    response.raise_for_status()
    return response.json()


def extract_observations():
    run_id = str(uuid.uuid4())
    extracted_at = datetime.now(timezone.utc).isoformat()

    records = []

    for indicator in INDICATORS:

        url = (
            "https://api.worldbank.org/v2/"
            f"country/all/indicator/{indicator}"
        )

        params = {
            "format": "json",
            "date": f"{START_YEAR}:{END_YEAR}",
            "source": WORLD_BANK_SOURCE_ID,
            "per_page": 20000,
        }

        payload = get_json(url, params=params)

        observations = payload[1] or []

        for row in observations:

            # World Bank also returns regional/aggregate entities.
            # Preserve them in RAW. Geography classification happens later.

            source_payload = canonical_json(row)

            records.append(
                {
                    "source_payload": source_payload,
                    "_source_system": "WORLD_BANK",
                    "_source_domain": "WDI",
                    "_indicator_code": indicator,
                    "_ingestion_run_id": run_id,
                    "_ingestion_batch_id": sha256(
                        canonical_json(
                            {
                                "indicator": indicator,
                                "start_year": START_YEAR,
                                "end_year": END_YEAR,
                                "source_id": WORLD_BANK_SOURCE_ID,
                            }
                        )
                    ),
                    "_extracted_at_utc": extracted_at,
                    "_source_row_hash": sha256(source_payload),
                    "_request_parameters": canonical_json(params),
                }
            )

    return records


def extract_indicator_metadata():
    run_id = str(uuid.uuid4())
    extracted_at = datetime.now(timezone.utc).isoformat()

    records = []

    for indicator in INDICATORS:

        url = (
            "https://api.worldbank.org/v2/"
            f"indicator/{indicator}"
        )

        params = {
            "format": "json",
            "source": WORLD_BANK_SOURCE_ID,
        }

        payload = get_json(url, params=params)

        metadata_rows = payload[1] or []

        for row in metadata_rows:

            source_payload = canonical_json(row)

            records.append(
                {
                    "source_payload": source_payload,
                    "_source_system": "WORLD_BANK",
                    "_source_domain": "WDI_METADATA",
                    "_indicator_code": indicator,
                    "_ingestion_run_id": run_id,
                    "_ingestion_batch_id": sha256(
                        canonical_json(
                            {
                                "indicator": indicator,
                                "source_id": WORLD_BANK_SOURCE_ID,
                            }
                        )
                    ),
                    "_extracted_at_utc": extracted_at,
                    "_source_row_hash": sha256(source_payload),
                    "_request_parameters": canonical_json(params),
                }
            )

    return records


def write_delta(records, table_uri):
    if not records:
        raise ValueError(f"No records returned for {table_uri}")

    table = pa.Table.from_pylist(records)

    write_deltalake(
        table_uri,
        table,
        mode="overwrite",
        storage_options={
            "AWS_REGION": os.environ["AWS_REGION"],
        },
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dataset",
        choices=["all", "observations", "metadata"],
        default="all",
    )
    args = parser.parse_args()

    if args.dataset in ("all", "observations"):
        observations = extract_observations()

        write_delta(
            observations,
            OBSERVATIONS_TABLE,
        )

        print(
            f"WDI observations written: "
            f"{len(observations):,}"
        )

    if args.dataset in ("all", "metadata"):
        metadata = extract_indicator_metadata()

        write_delta(
            metadata,
            METADATA_TABLE,
        )

        print(
            f"WDI metadata rows written: "
            f"{len(metadata):,}"
        )


if __name__ == "__main__":
    main()
    entity_metadata = extract_entity_metadata()

    write_delta(
        entity_metadata,
        ENTITY_METADATA_TABLE,
    )

    print(
        f"WDI entity metadata rows written: "
        f"{len(entity_metadata):,}"
    )