USE ROLE ACCOUNTADMIN;

CREATE EXTERNAL VOLUME IF NOT EXISTS GFS_DEV_DELTA_EXT_VOL
    STORAGE_LOCATIONS =
    (
        (
            NAME = 'gfs_dev_s3_delta'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://gfs-delta-dev-kush01/delta/'
            STORAGE_AWS_ROLE_ARN =
                'arn:aws:iam::915639745456:role/gfs-snowflake-delta-read-dev'
            STORAGE_AWS_EXTERNAL_ID =
                'gfs-snowflake-delta-dev-v1'
        )
    )
    ALLOW_WRITES = FALSE
    COMMENT = 'Read-only access to externally managed GFS Delta tables';