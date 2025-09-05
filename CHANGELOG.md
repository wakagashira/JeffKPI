# JeffKPI Changelog

## [v5.0.1] - 2025-09-04
### Changed
- Pipeline values on KPI cards are now formatted as currency without cents (e.g., $1,200,000 instead of $1,200,000.00).

## [v5.0.2] - 2025-09-04
### Fixed
- Updated LWC templates to use `formattedPipeline` instead of `pipelineValue`, ensuring pipeline values render as currency without cents on the page.

## [v5.0.3] - 2025-09-05
### Changed
- LWC header now automatically shows the current version (`Jeff KPI v5.0.3`).
- Pipeline values now render as proper US currency with `$` and commas (e.g., `$1,200,000`).

## [v5.0.4] - 2025-09-05
### Fixed
- Header now binds to a component property and renders as **Jeff KPI v5.0.4** in the UI (no literal `{VERSION}` and no stale `3.6.8` suffix).
- Pipeline values render as **USD currency** with `$` and commas, with **no cents**; uses `<lightning-formatted-number>` where appropriate and a `formattedPipeline` getter as fallback.

## [v5.0.5] - 2025-09-05
### Fixed
- Removed invalid template attribute `{VERSION}3.6.8`; header now binds cleanly to `{headerText}` and shows `Jeff KPI v5.0.5`.
- All pipeline fields now render with `<lightning-formatted-number>` using USD currency, commas, and no cents.

## [v5.0.6] - 2025-09-05
### Fixed
- Corrected all LWC template attribute bindings to use proper syntax (e.g., title={headerText} instead of title="{headerText}").

## [v5.0.7] - 2025-09-05
### Fixed
- Replaced all `pipelineValue` template bindings with `<lightning-formatted-number>` for proper USD currency formatting (adds `$` and commas, no cents).

## [v5.0.8] - 2025-09-05
### Changed
- Extended USD currency formatting to **Bookings, Quota, and Closed Won** fields (now all monetary KPIs render with `$` and commas, no cents).

## [v5.0.9] - 2025-09-05
### Changed
- Bumped header version to show `Jeff KPI v5.0.9` dynamically in the UI.
