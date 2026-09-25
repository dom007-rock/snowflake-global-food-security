import os

import pyarrow as pa
from deltalake import DeltaTable, write_deltalake


bucket = os.environ["GFS_S3_BUCKET"]
region = os.environ.get("AWS_REGION", "ap-south-1")

table_uri = f"s3a://{bucket}/delta/_smoke_test"

storage_options = {
    "AWS_REGION": region,
    "AWS_S3_LOCKING_PROVIDER": "dynamodb",
    "DELTA_DYNAMO_TABLE_NAME": "delta_log",
}

data = pa.table(
    {
        "id": [1, 2, 3],
        "message": ["delta", "lake", "works"],
        "year": [2021, 2022, 2023],
    }
)

write_deltalake(
    table_uri,
    data,
    mode="overwrite",
    partition_by=["year"],
    storage_options=storage_options,
)

table = DeltaTable(
    table_uri,
    storage_options=storage_options,
)

print(f"Delta table: {table_uri}")
print(f"Delta version: {table.version()}")
print(table.to_pyarrow_table().to_pandas())