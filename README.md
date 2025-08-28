# ActivitiesKPIJeff — With Filters (Salesforce DX)

Features:
- Apex with getUserActivitySummary + getUsersInMyHierarchy
- LWC groups by Partner__c
- Users sorted alphabetically by first name
- Partner dropdown filter
- User dropdown filter
- Row layout for user tiles
- Permission Set grants Apex access
- JeffTest App Page includes component

## Deploy to CreteSandbox

```bash
sf project deploy start --source-dir force-app/main/default --target-org CreteSandbox
```

## Assign Permission Set

```bash
sf org assign permset --name "ActivitiesKPIJeff" --target-org CreteSandbox
```

## Open Page

App Launcher → JeffTest
