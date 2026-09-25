# Phase 14 - Monitoring & Cost Management

## Status

**Complete**

## Warehouse controls

The DEV warehouses use:

- X-Small sizing
- 60-second auto-suspend
- auto-resume enabled

A monthly DEV resource monitor is configured with a **10-credit quota**, notifications at 50% and 80%, and suspension at 100%.

## Monitoring views

The CONTROL layer includes operational views for:

- warehouse credit usage
- query history
- task execution
- data freshness
- DQ runs
- DQ failures

These views support operational troubleshooting and cost review without requiring ad hoc ACCOUNT_USAGE queries for every incident.
