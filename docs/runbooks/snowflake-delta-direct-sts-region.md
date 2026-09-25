# Runbook - Snowflake Delta Direct STS Region Failure

## Symptom

Snowflake `CREATE ICEBERG TABLE` using the configured external volume failed with an AWS `sts:AssumeRole` access error even though the IAM trust policy and external ID were correct.

## Environment

- S3 bucket region: `ap-south-1`
- Snowflake account region: `AWS_AP_SOUTHEAST_7`
- Snowflake AWS principal: `arn:aws:iam::192929863221:user/nat62000-s`
- Snowflake external ID: `gfs-snowflake-delta-dev-v1`
- Snowflake read role: `arn:aws:iam::915639745456:role/gfs-snowflake-delta-read-dev`

## Root cause

The Snowflake account operates from the AWS opt-in region corresponding to `ap-southeast-7`. AWS regional activation / STS availability for that region was not enabled in the target AWS account.

The result looked like an IAM trust-policy problem even though the role trust configuration was already correct.

## Resolution

Enable the required AWS opt-in region / regional STS support for the Snowflake account's operating region, then retry the external-volume / Delta Direct access.

After the region was enabled, Snowflake successfully assumed the role and the Delta Direct Iceberg tables were created.

## Operational lesson

When cross-account Snowflake-to-S3 role assumption fails despite correct:

- principal
- external ID
- trust policy
- bucket permissions

also verify the Snowflake account's AWS region and whether that region is enabled for the target AWS account.
