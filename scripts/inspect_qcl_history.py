import os
from collections import Counter

from deltalake import DeltaTable


bucket = os.environ["GFS_S3_BUCKET"]
region = os.environ.get("AWS_REGION", "ap-south-1")

table_uri = f"s3a://{bucket}/delta/faostat/qcl"

storage_options = {
    "AWS_REGION": region,
}


table = DeltaTable(
    table_uri,
    storage_options=storage_options,
)

current_version = table.version()

print("=" * 70)
print("QCL DELTA HISTORY INSPECTION")
print("=" * 70)

print(f"\nCurrent version: {current_version}")


print("\nCOMMIT HISTORY")
print("-" * 70)

for commit in table.history():
    print(
        f"Version: {commit.get('version')} | "
        f"Operation: {commit.get('operation')} | "
        f"Timestamp: {commit.get('timestamp')}"
    )

    operation_parameters = commit.get(
        "operationParameters"
    )

    if operation_parameters:
        print(
            f"  Parameters: {operation_parameters}"
        )


print("\nVERSION STATES")
print("-" * 70)

for version in range(current_version + 1):

    version_table = DeltaTable(
        table_uri,
        version=version,
        storage_options=storage_options,
    )

    arrow_table = (
        version_table.to_pyarrow_table(
            columns=["_request_year"]
        )
    )

    years = (
        arrow_table
        .column("_request_year")
        .to_pylist()
    )

    year_counts = Counter(years)

    print(f"\nVersion {version}")
    print(f"  Rows : {arrow_table.num_rows:,}")
    print(
        f"  Files: "
        f"{len(version_table.file_uris())}"
    )

    print("  Rows by request year:")

    for year, count in sorted(
        year_counts.items()
    ):
        print(
            f"    {year}: {count:,}"
        )