# JeffKPI v3.6.7 — Test Fix

**What's fixed**
- Updated JeffKPIControllerTest to populate required field `Opportunity_Type__c` when creating test Opportunities.
- Prevents REQUIRED_FIELD_MISSING DmlException.

**What's in this package**
- Apex: JeffKPIController and JeffKPIControllerTest (fixed).
- LWC: jeffKpi (HTML/JS/CSS/Meta with filters + cards).
- Permission Set: JeffKPI (Apex class access).
- Manifest & Project files.

**Deploy**
sf org login web --alias CreteSandbox --instance-url https://test.salesforce.com
sf project deploy start --source-dir force-app --target-org CreteSandbox
sf permset assign --name JeffKPI --target-org CreteSandbox
