# Deployment (Windows PowerShell)

# Check Salesforce CLI
& "C:\Program Files\Sf\bin\sf.cmd" --version

# Deploy to CreteSandbox
& "C:\Program Files\Sf\bin\sf.cmd" project deploy start --source-dir force-app/main/default --target-org CreteSandbox

# Run tests
& "C:\Program Files\Sf\bin\sf.cmd" apex run test --tests UserHierarchyControllerTest --wait 10 --target-org CreteSandbox

# Assign permission set
& "C:\Program Files\Sf\bin\sf.cmd" org assign permset --name "ActivitiesKPIJeff" --target-org CreteSandbox
