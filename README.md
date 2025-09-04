# JeffKPI v4.2 (4.1 + User & Partner filters)

This package adds **dropdown filters** for **User** and **Partner** (where `Partner__c` is a custom field on the **User** object) to the `jeffKpi` component and wires those filters into the Apex controller, **without breaking the legacy card methods**.

## What’s included
- `JeffKPIController.cls` — adds:
  - `getUserOptions()`
  - `getPartnerOptions()` (derived from distinct `User.Partner__c` values)
  - **New** filtered endpoints:
    - `getUserActivitySummaryFiltered(timeframe, selectedUserId, selectedPartner)`
    - `getOpportunityMetricsFiltered(timeframe, selectedUserId, selectedPartner)`
  - **Legacy-compatible** endpoints preserved:
    - `getUserActivitySummary(timeframe)` → calls filtered version with `null` filters
    - `getOpportunityMetrics(timeframe)` → calls filtered version with `null` filters
- LWC `jeffKpi` — adds dropdowns and refreshes the KPI cards when filters change
- Permission set `JeffKPI` — grants access to the controller class

## Quick deploy (CLI)
```bash
# From the folder that contains sfdx-project.json
sf project deploy start --source-dir force-app --target-org <YourAlias>
```

> If non-admin users see "insufficient privileges", assign the **JeffKPI** permission set to them.

## Notes
- **Partner filter** is resolved via `User.Partner__c` and filters records by **OwnerId IN users with that partner**.
- **User filter** takes precedence if both User and Partner are set (i.e., it narrows to the single selected user).
- Timeframes supported: ThisWeek, LastWeek, ThisMonth, LastMonth, Last7Days, Last30Days, ThisQuarter, LastQuarter.
