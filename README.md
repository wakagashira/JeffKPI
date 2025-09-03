# JeffKPI v3.6.8 — Full Working Bundle for Production

**What's included**
- Apex: JeffKPIController (clean dynamic SOQL; timeframe on activities + wins) and JeffKPIControllerTest (with Opportunity_Type__c).
- LWC: jeffKpi (HTML/JS/CSS/Meta) — card layout, professional styling; Partner/User/Timeframe filters; fixed user filter.
- Permission Set: JeffKPI (Apex class access).
- Manifest & Project files.

**Deploy**
sf org login web --alias Prod --instance-url https://login.salesforce.com
sf project deploy start --source-dir force-app --target-org Prod
sf permset assign --name JeffKPI --target-org Prod

**After deploy**
- In Lightning App Builder, add **Jeff KPI** to Home/App/Record Page.
- If it doesn't appear, hard refresh and clear cached Lightning resources (Cmd+Shift+R / Ctrl+F5).
