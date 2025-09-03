# JeffKPI v3.6.6 — User Filter Fix

**What's fixed**
- User filter now properly shows only the selected user's card.
- Added type coercion (String comparison) so Id values match.
- Added `loadAll()` on user change to reload metrics.

**What's in this package**
- LWC: jeffKpi (HTML/JS/CSS/Meta) with corrected user filter logic.
- Apex: JeffKPIController and JeffKPIControllerTest.
- Permission Set: JeffKPI (Apex class access).
- Manifest & Project files.

**Deploy**
sf org login web --alias CreteSandbox --instance-url https://test.salesforce.com
sf project deploy start --source-dir force-app --target-org CreteSandbox
sf permset assign --name JeffKPI --target-org CreteSandbox
