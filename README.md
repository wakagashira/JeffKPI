# ActivitiesKPIJeff LWC + Apex (Salesforce DX Project)

This project includes:
- Apex Controller (`UserHierarchyController`)
- Test Class (`UserHierarchyControllerTest`)
- LWC (`ActivitiesKPIJeff`)
- Permission Set (`ActivitiesKPIJeff Access`) to grant Apex access

## Deploy to CreteSandbox

```bash
sf project deploy start --source-dir force-app/main/default --target-org CreteSandbox
```

## Run Tests

```bash
sf apex run test --tests UserHierarchyControllerTest --wait 10 --target-org CreteSandbox
```

## Assign Permission Set

After deploying, assign the permission set to users who should access the component:

```bash
sf org assign permset --name "ActivitiesKPIJeff" --target-org CreteSandbox
```

Then, use **Lightning App Builder** to place the `ActivitiesKPIJeff` component on a page.
