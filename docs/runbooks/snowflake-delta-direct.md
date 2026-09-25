# Snowflake Delta Direct Runbook

## Purpose

Expose Delta Lake tables stored in Amazon S3 as read-only Snowflake RAW tables without copying source rows into native Snowflake storage.

## Snowflake objects

- External volume: `GFS_DEV_DELTA_EXT_VOL`
- Catalog integration: `GFS_DELTA_CATALOG`
- Database: `GFS_DEV`
- RAW schema: `GFS_DEV.RAW`

The catalog integration is configured for object storage and `TABLE_FORMAT = DELTA`.

## RAW tables

| Snowflake table | S3-relative Delta location | Expected rows |
|---|---|---:|
| `FAOSTAT_QCL` | `faostat/qcl/` | 1,005,808 |
| `FAOSTAT_LC` | `faostat/lc/` | 119,230 |
| `FAOSTAT_ESB` | `faostat/esb/` | 194,244 |
| `FAOSTAT_FBS` | `faostat/fbs/` | 4,820,497 |
| `FAOSTAT_GT` | `faostat/gt/` | 820,429 |
| `FAOSTAT_FS` | `faostat/fs/` | 187,905 |

Example pattern:

```sql
CREATE ICEBERG TABLE IF NOT EXISTS GFS_DEV.RAW.FAOSTAT_QCL
    CATALOG = 'GFS_DELTA_CATALOG'
    EXTERNAL_VOLUME = 'GFS_DEV_DELTA_EXT_VOL'
    BASE_LOCATION = 'faostat/qcl/'
    AUTO_REFRESH = TRUE;
```

## Why the base location omits `delta/`

The external volume already points at:

```text
s3://gfs-delta-dev-kush01/delta/
```

`BASE_LOCATION` is relative to that external-volume root.

## Read-only IAM model

Snowflake receives S3 read/list permissions only. The external volume is intentionally read-only.

Required S3 actions include:

- `s3:GetBucketLocation`
- `s3:ListBucket`
- `s3:GetObject`
- `s3:GetObjectVersion`

No Snowflake-side `PutObject` or delete permissions are required for the RAW Delta Direct path.

## Cross-account trust

The AWS role `gfs-snowflake-delta-read-dev` trusts the Snowflake-managed IAM principal returned by `DESC EXTERNAL VOLUME` and requires the matching external ID.

Observed DEV values during setup:

```text
STORAGE_AWS_ROLE_ARN:
arn:aws:iam::915639745456:role/gfs-snowflake-delta-read-dev

STORAGE_AWS_IAM_USER_ARN:
arn:aws:iam::192929863221:user/nat62000-s

STORAGE_AWS_EXTERNAL_ID:
gfs-snowflake-delta-dev-v1
```

## Incident: STS not enabled in Snowflake deployment region

### Symptom

```text
Error assuming AWS_ROLE:
User ... is not authorized to perform sts:AssumeRole
```

IAM role ARN, Snowflake principal, external ID, and trust policy were all correct.

### Root cause

The Snowflake account was deployed in `AWS_AP_SOUTHEAST_7` (AWS `ap-southeast-7`, Thailand), an opt-in AWS region. The project AWS account had not enabled that region / STS endpoint.

### Resolution

Enable the Snowflake deployment region in the AWS account and ensure AWS STS is active there. After propagation, the same Delta Direct table creation succeeded.

### Lesson

The S3 bucket region and Snowflake deployment region are independent. Cross-account STS must be available in the **Snowflake deployment region**, even when the bucket is stored elsewhere.

## Validation

### Row reconciliation

```sql
SELECT COUNT(*) FROM GFS_DEV.RAW.FAOSTAT_QCL;
```

QCL validated at `1,005,808` rows, matching the Delta/bootstrap reconciliation.

### Metadata preservation

RAW exposes the same landing technical columns, including run ID, batch ID, extraction timestamp, request parameters, row hash, source system, and source domain.

### Audit

`GFS_DEV.CONTROL.RAW_LOAD_AUDIT` records source/expected counts, RAW counts, match flags, timestamp, and validating user.

## References

- Snowflake Delta Direct: https://docs.snowflake.com/en/user-guide/tables-iceberg-create
- External volume for S3: https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume-s3
- External volume verification: https://docs.snowflake.com/en/sql-reference/functions/system_verify_external_volume
