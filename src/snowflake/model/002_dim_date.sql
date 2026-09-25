USE ROLE GFS_PLATFORM_ADMIN;
USE DATABASE GFS_DEV;
USE SCHEMA CONSUMPTION;


CREATE TABLE IF NOT EXISTS DIM_DATE (

    date_key            NUMBER       NOT NULL,
    year                NUMBER       NOT NULL,

    decade              NUMBER       NOT NULL,

    year_start_date     DATE         NOT NULL,
    year_end_date       DATE         NOT NULL,

    created_at_utc      TIMESTAMP_TZ NOT NULL

);

MERGE INTO GFS_DEV.CONSUMPTION.DIM_DATE AS target

USING (

    SELECT
        year_value AS date_key,
        year_value AS year,

        FLOOR(year_value / 10) * 10
            AS decade,

        DATE_FROM_PARTS(
            year_value,
            1,
            1
        ) AS year_start_date,

        DATE_FROM_PARTS(
            year_value,
            12,
            31
        ) AS year_end_date

    FROM (

        SELECT
            2010 + SEQ4() AS year_value

        FROM TABLE(
            GENERATOR(ROWCOUNT => 14)
        )

    )

) AS source

ON target.date_key = source.date_key


WHEN NOT MATCHED THEN INSERT (

    date_key,
    year,
    decade,
    year_start_date,
    year_end_date,
    created_at_utc

)

VALUES (

    source.date_key,
    source.year,
    source.decade,
    source.year_start_date,
    source.year_end_date,
    CURRENT_TIMESTAMP()

);