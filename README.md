# Deployment (Windows PowerShell)
& "C:\Program Files\Sf\bin\sf.cmd" --version
& "C:\Program Files\Sf\bin\sf.cmd" project deploy start --source-dir force-app/main/default --target-org CreteSandbox
& "C:\Program Files\Sf\bin\sf.cmd" apex run test --wait 10 --target-org CreteSandbox
& "C:\Program Files\Sf\bin\sf.cmd" org assign permset --name "ActivitiesKPIJeff" --target-org CreteSandbox

## Notes
- Removed old test classes (`GetCrossSellPartnerAction_Test`, `GetOpportunityTradeAsChoiceSetActionTest`) 
  because they referenced non-existent objects/fields in this org.
