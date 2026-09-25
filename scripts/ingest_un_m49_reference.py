import hashlib
import io
import json
import os
import uuid
from datetime import datetime, timezone

import pandas as pd
import pyarrow as pa
import requests
from deltalake import write_deltalake


SOURCE_URL = "https://unstats.un.org/unsd/methodology/m49/overview"

TABLE_URI = (
    "s3://gfs-delta-dev-kush01/"
    "delta/reference/un_m49/"
)


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


def main():
    response = requests.get(
        SOURCE_URL,
        timeout=60,
    )
    response.raise_for_status()

    tables = pd.read_html(
        io.StringIO(response.text)
    )

    required = {
        "Country or Area",
        "M49 Code",
        "ISO-alpha2 Code",
        "ISO-alpha3 Code",
    }

    reference = None

    for table in tables:
        if required.issubset(set(table.columns)):
            reference = table[
                [
                    "Country or Area",
                    "M49 Code",
                    "ISO-alpha2 Code",
                    "ISO-alpha3 Code",
                ]
            ].copy()
            break

    if reference is None:
        raise RuntimeError(
            "Unable to locate UN M49 reference table"
        )

    run_id = str(uuid.uuid4())
    extracted_at = datetime.now(
        timezone.utc
    ).isoformat()

    records = []

    for _, row in reference.iterrows():

        m49_raw = row["M49 Code"]

        if pd.isna(m49_raw):
            continue

        m49_code = str(m49_raw).split(".")[0].zfill(3)

        iso2 = (
            None
            if pd.isna(row["ISO-alpha2 Code"])
            else str(row["ISO-alpha2 Code"]).strip()
        )

        iso3 = (
            None
            if pd.isna(row["ISO-alpha3 Code"])
            else str(row["ISO-alpha3 Code"]).strip()
        )

        payload = {
            "un_area_name": str(
                row["Country or Area"]
            ).strip(),
            "m49_code": m49_code,
            "iso_alpha2": iso2,
            "iso_alpha3": iso3,
        }

        source_payload = canonical_json(payload)

        records.append(
            {
                "source_payload": source_payload,
                "_source_system": "UNSD",
                "_source_domain": "M49",
                "_ingestion_run_id": run_id,
                "_extracted_at_utc": extracted_at,
                "_source_row_hash": sha256(
                    source_payload
                ),
                "_source_url": SOURCE_URL,
            }
        )

    snapshot_hash = sha256(
        canonical_json(
            sorted(
                row["_source_row_hash"]
                for row in records
            )
        )
    )

    for row in records:
        row["_ingestion_batch_id"] = snapshot_hash

    table = pa.Table.from_pylist(records)

    write_deltalake(
        TABLE_URI,
        table,
        mode="overwrite",
        storage_options={
            "AWS_REGION": os.environ["AWS_REGION"],
        },
    )

    print(
        f"UN M49 reference rows written: "
        f"{len(records):,}"
    )


if __name__ == "__main__":
    main()