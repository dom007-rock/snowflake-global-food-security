# Runbook 001 - Snowflake Delta Direct AssumeRole failure

## Symptom
Creating or accessing Snowflake external Delta/Iceberg objects fails with an AWS STS `AssumeRole` authorization error even though the S3/IAM trust relationship appears correct.

## Context
The Snowflake account was hosted in `AWS_AP_SOUTHEAST_7` while the AWS account required regional/STS activation for the opt-in region.

## Resolution
Enable the required AWS opt-in region / regional STS capability in the AWS account, then retry the Snowflake external-volume/catalog operation.

## Prevention
When Snowflake is deployed in an AWS opt-in region, verify the corresponding AWS regional STS/region activation as part of environment bootstrap before debugging bucket policies or role trust repeatedly.
