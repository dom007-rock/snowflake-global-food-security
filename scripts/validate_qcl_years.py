import json
import os
from collections import Counter

from deltalake import DeltaTable


bucket = os.environ["GFS_S3_BUCKET"]
region = os.environ.get("AWS_REGION", "ap-south-1")

table_uri = f"s3a://{bucket}/delta/faostat/qcl"

table = DeltaTable(
    table_uri,
    storage_options={
        "AWS_REGION": region,
    },
)


for request_year in ("2022", "2023"):
    data = table.to_pyarrow_table(
        columns=["source_payload"],
        filters=[
            (
                "_request_year",
                "=",
                request_year,
            )
        ],
    )

    source_years = Counter()

    for payload in data.column(
        "source_payload"
    ).to_pylist():
        record = json.loads(payload)

        source_years[
            str(record.get("Year Code"))
        ] += 1

    print(
        f"\nREQUEST YEAR: {request_year}"
    )
    print(
        f"ROWS: {data.num_rows:,}"
    )
    print(
        f"SOURCE YEAR CODES: "
        f"{dict(source_years)}"
    )