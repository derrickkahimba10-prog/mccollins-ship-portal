# McCollins Ship Portal — Pilot Readiness Report

## Executive decision

**Status: Conditionally pilot-ready.** The uploaded Phase 12 implementation contains the complete core freight chain through paid settlement, and the saved database contains one complete end-to-end transaction. Static security, route, schema, UI and responsive reviews passed after the fixes in this package. Final approval remains conditional on importing the included integrity migration and completing the XAMPP runtime regression in `PILOT_TEST_PLAN.md`.

This work is post-Phase 12 hardening. It does not introduce a Phase 13, redesign the approved architecture, delete data or change the established business rules.

## Implementation audit

| Area | Current status | Evidence from the actual project | Problems found | Recommended action |
|---|---|---|---|---|
| Authentication and sessions | Hardened | `Auth.php` verifies credentials, roles and permissions; public routes consistently invoke authentication/authorization | Failed-attempt counters did not previously lock accounts; no idle/absolute timeout | Fixed: five failures lock for 15 minutes; 30-minute idle and 12-hour absolute limits; successful login resets lock state |
| Authorization/company scope | Implemented | 77 public application routes reviewed; role/permission guards and company checks exist in controllers/services | Runtime request tampering and cross-company tests still require XAMPP | Execute the negative-access matrix before pilot |
| Load intake/review | Implemented | Load, version, review, clarification and status-history tables/routes/services exist | No static blocker identified | Run happy-path and clarification-path tests |
| Fleet/compliance | Implemented | Carrier, truck, driver, compliance, subscription and eligibility workflows are present | Expired-document behavior needs runtime validation | Run compliance-boundary tests |
| Matching/assignment | Implemented | Offer, response, assignment and history objects/routes exist | Duplicate acceptance/race behavior needs runtime validation | Test repeated submissions and competing offers |
| Dispatch/shipments/trips | Implemented | Shipment/trip/stops/milestones and role workspaces are present | Several important foreign keys were absent | Fixed non-destructively by migration `049_pilot_integrity_constraints.sql` |
| Tracking/alerts/exceptions | Implemented | Tracking events, alerts/incidents and resolution/history data exist; saved DB has 3 tracking events and 1 incident | No static blocker identified | Test update order, exception creation, resolution and audit history |
| Documents/e-POD | Implemented | Document access and e-POD review/confirmation flows exist; saved e-POD is `confirmed` | Authorization must be tested with direct document URLs | Run owner, wrong-company and wrong-role tests |
| Payments/settlements | Implemented | Payment, settlement and payout workflows exist; saved records are `confirmed`, `paid`, `paid` | Finance workflow requires runtime role tests | Test shipper, finance, carrier visibility and duplicate actions |
| Notifications/audit/access logs | Implemented | Saved DB contains 7 notifications, 95 audit events and 51 access logs | List pages use bounded result sets without pagination | Acceptable for pilot volume; paginate before scale |
| Diagnostics | Restricted | `public/db-test.php` remains available for local debugging | It previously exposed database metadata publicly | Fixed: 404 unless `APP_DEBUG=true`, then requires `ACCESS_LOG_VIEW` |
| Frontend coverage | Core freight workflows exposed | Role navigation links to loads, operations, fleet, trips, tracking, documents, finance, notifications and audit | Admin system/compliance dashboards and some role shortcuts were incomplete/stale | Fixed and connected to actual protected routes |
| Design system | Standardized | Centralized variables and reusable components in `public/assets/css/app.css` | Previous UI was inconsistent and sidebar overflowed | Rebuilt around emerald structure, cream surfaces and champagne-gold accents |
| Responsive design | Static visual QA passed | 1440×900 and 390×844 renders reviewed; drawer navigation and contained table overflow work | Real-device/browser testing remains | Verify Chrome/Edge desktop and at least one Android/iOS-sized viewport |
| Database integrity | Stronger after included migration | SQL backup has 186 tables and a complete saved business chain | Eight proven foreign-key relationships were missing | Import migration 049 after a backup; it only adds missing constraints |

## A. Backend status

Core services and route handlers for all Phases 1–12 are present. The project contains 18 service classes and 77 public application routes. Static inspection found no unprotected core route or obvious missing CSRF guard in state-changing routes. Authentication/session protections were strengthened without changing the role model.

## B. Database status

The Phase 12 backup contains 186 tables and preserves the established architecture. Saved core counts include 10 users, 2 companies, 3 loads, 1 assignment, 1 shipment, 1 trip, 3 tracking events, 1 incident, 3 documents, 1 e-POD, 1 payment, 1 settlement and 1 payout.

A complete saved chain exists: load `delivered` → active assignment → shipment `delivered` → trip `delivered` → e-POD `confirmed` → payment `confirmed` → settlement `paid` → payout `paid`.

The included idempotent migration adds eight missing foreign keys. It does not delete, rename or redesign tables.

## C. Frontend status

All major core freight functions have protected frontend routes. Role dashboards and navigation now expose the relevant workflows more clearly. C&F, farmer/marketplace buyer/seller and supplier dashboards remain placeholders because those roles belong to explicitly deferred future releases, not the completed core freight pilot.

## D. UI/UX status

The portal now uses one design system with centralized CSS variables, reusable controls, consistent spacing, forms, tables, cards, badges, alerts and focus states. Successful create/update redirects display a consistent confirmation. Navigation highlights the current route.

## E. Responsive design status

Static render checks passed at desktop and mobile widths. Mobile navigation behaves as a drawer, cards stack, action targets remain usable, and wide tables stay inside scroll containers instead of breaking the page. Real-device validation remains required.

## F. Security status

No critical static security issue remains open. The public database diagnostic was restricted; account lockout and session expiration were added; route authorization and CSRF coverage were reviewed. Runtime penetration-style checks—modified IDs, direct URLs, forged requests and session expiry—remain mandatory before real customer data is used.

## G. Permission/company-scope results

Static review found backend guards across the core public routes. Frontend hiding is not treated as authorization. Final approval requires the runtime matrix for Shipper, Operations, Carrier, Driver, Finance and a second-company user.

## H. End-to-end workflow results

The saved database proves that the full business chain can be represented through paid settlement. Source-level workflow review found the required modules and statuses. A fresh browser-driven transaction must still be completed locally because PHP and MySQL runtimes were unavailable in the inspection environment.

## I. Critical issues

**Open: none found by static inspection.** Any cross-company exposure, payment corruption or inability to complete the main workflow discovered during runtime testing must be treated as critical and block the pilot.

## J. High-priority issues

- Complete the local XAMPP runtime regression and security matrix.
- Import and verify migration 049 before pilot approval.

## K. Medium issues

- Existing sample chronology is inconsistent: the trip has planned dates in March 2027 but operational completion timestamps in September 2026. Correct test data before demonstrations; do not change production history without approval.
- Audit, access-log and notification lists have bounded results and no pagination. Add pagination before data volume grows.

## L. Low/cosmetic issues

- Deferred future-release role dashboards remain informative placeholders.
- Email/SMS and external payment-gateway delivery are not active integrations; the current core stores in-system notifications and payment records.

## M. Remaining work before pilot

1. Back up the Phase 12 database and project folder.
2. Install this package while preserving the local `.env`.
3. Import `database/migrations/049_pilot_integrity_constraints.sql`.
4. Run full PHP lint and inspect any failures.
5. Execute `PILOT_TEST_PLAN.md` using at least two companies and all core roles.
6. Record and fix every critical/high issue, then repeat the complete chain.
7. Test desktop, tablet and mobile browsers with actual data.
8. Take a fresh project ZIP and SQL export only after all tests pass.

## N. Overall pilot-readiness status

**CONDITIONAL GO.** The source, saved database chain and frontend are suitable for a controlled pilot candidate. Change to **GO** only after migration 049, PHP lint and the complete local runtime test matrix pass with no open critical or high issues.
