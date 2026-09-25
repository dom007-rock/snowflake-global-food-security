from __future__ import annotations

import os
import time

import snowflake.connector
from dotenv import load_dotenv


class SnowflakeHandoff:
    def __init__(self) -> None:
        load_dotenv(override=True)

        self.connection = snowflake.connector.connect(
            account=os.environ["SNOWFLAKE_ACCOUNT"],
            user=os.environ["SNOWFLAKE_USER"],
            password=os.environ["SNOWFLAKE_PASSWORD"],
            role=os.getenv(
                "SNOWFLAKE_ROLE",
                "GFS_INGESTION_SVC",
            ),
            warehouse=os.getenv(
                "SNOWFLAKE_WAREHOUSE",
                "GFS_INGEST_WH",
            ),
            database="GFS_DEV",
        )

    def wait_for_qcl_raw_batch(
        self,
        batch_id: str,
        expected_rows: int,
        timeout_seconds: int = 180,
    ) -> None:
        """Wait until Snowflake RAW can see the Delta ingestion batch."""
        deadline = time.monotonic() + timeout_seconds

        sql = """
            SELECT COUNT(*)
            FROM GFS_DEV.RAW.FAOSTAT_QCL
            WHERE _ingestion_batch_id = %s
        """

        while time.monotonic() < deadline:
            with self.connection.cursor() as cursor:
                cursor.execute(
                    sql,
                    (batch_id,),
                )
                visible_rows = cursor.fetchone()[0]

            print(
                "[Snowflake] RAW QCL visibility: "
                f"{visible_rows:,}/{expected_rows:,}"
            )

            if visible_rows == expected_rows:
                print(
                    "[Snowflake] RAW QCL ingestion batch is visible."
                )
                return

            time.sleep(5)

        raise TimeoutError(
            "Snowflake RAW did not expose QCL batch "
            f"{batch_id} within {timeout_seconds} seconds."
        )

    def merge_qcl_clean(
        self,
        batch_id: str,
    ) -> str:
        """Execute revision-safe RAW -> CLEAN processing."""
        sql = """
            CALL GFS_DEV.CONTROL.SP_MERGE_QCL_CLEAN(%s)
        """

        with self.connection.cursor() as cursor:
            cursor.execute(
                sql,
                (batch_id,),
            )
            result = cursor.fetchone()[0]

        print(f"[Snowflake] {result}")
        return result

    def close(self) -> None:
        self.connection.close()
