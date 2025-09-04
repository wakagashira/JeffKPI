# JeffKPI v4.1.2 — Conditional Formatting Reliability Fix

**What's new in v4.1.2**
- Overdue and Win Rate formatting fixed:
  - Added null-safe defaults for values from Apex.
  - Guaranteed base class `metric-value` for consistent styling.
  - CSS ensures default black text, with overrides for red/green.
- Retains all features from v4.1.1.

**Deploy**
sf org login web --alias Prod --instance-url https://login.salesforce.com
sf project deploy start --source-dir force-app --target-org Prod
sf permset assign --name JeffKPI --target-org Prod
