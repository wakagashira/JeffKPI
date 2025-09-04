# Jeff KPI (v4.6.7)

This DX project deploys:
- Apex: `JeffKPIController` (+ test)
- LWC: `jeffKpi`

**No FlexiPage** is included to avoid metadata parsing errors. After deployment, add the `jeffKpi` component to a Lightning App/Home page via App Builder.

## Deploy

```bash
sf project deploy start --source-dir force-app/main/default --target-org <your_alias>
```
