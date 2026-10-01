# McCollins Implementation Phase 3
## Portal Foundation, Authorization Context & Shipper Company Onboarding

This package merges into the existing `C:\xampp\htdocs\mccollins-ship-portal` project after Phase 2.

## What this package does
- Adds an idempotent approved permission reference-data seed.
- Replaces hard-coded route-only authorization with active roles + permissions + company context.
- Adds the shared responsive portal shell.
- Adds Shipper company onboarding and profile pages.
- Keeps every other role dashboard as a permission-protected placeholder.
- Creates no new table or column.

## Install
1. Back up the project and database.
2. Extract this ZIP.
3. Copy the contents inside `mccollins-phase3` into `C:\xampp\htdocs\mccollins-ship-portal` and merge folders.
4. Allow replacement of the supplied Phase 2 PHP and CSS files.
5. In phpMyAdmin select `mccollins_shipping`, then import only `database/seeds/016_phase3_permissions.sql`.
6. Log out and log in again so the session reloads permissions.

## Shipper test
1. Login with the active Shipper test account.
2. The account should redirect to `/public/company/onboarding.php` because it has no company membership.
3. Create a test company profile. Use a two-letter country code such as `TZ`.
4. Confirm the Company Profile page shows verification `pending`.
5. Confirm the Shipper Dashboard loads.

## Expected database writes during company onboarding
One company profile creates rows in existing approved tables only:
- `companies`
- `company_type_links`
- `company_members`
- `addresses`
- `address_links`
- `verification_cases`
- `status_history`
- `audit_events`

The active Shipper `user_roles.company_id` is linked to the new company in the same transaction.

## Negative tests
- While logged in as Shipper, open `/public/dashboards/carrier/dashboard.php`; expect 403.
- Log out and directly open the Shipper dashboard; expect login redirect.
- Re-open company onboarding after creation; expect redirect to the company profile.
- Confirm no internal role or business approval permission was granted.

## Boundaries
No loads, trucks, shipments, tracking, documents, payments, subscriptions, agriculture, procurement, or coaster records are created. No prices, providers, thresholds, or commercial rules are embedded.

## QA note
The package ZIP and source structure were checked in the generation environment. PHP CLI was unavailable there, so run-time testing remains required on XAMPP/PHP 8.2.
