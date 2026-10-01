# Phase 9 — Tracking, Alerts & Exceptions

Phase 9 extends the verified Phase 8 shipment/trip lifecycle without redesigning the approved database. It aligns the existing `tracking_sessions`, `tracking_events`, `trip_location_summaries`, `eta_updates`, `alerts`, `incidents` and `incident_actions` tables with the operational workflow.

## Included

- Operations monitoring dashboard
- Scoped trip tracking for Operations, assigned Drivers, Carriers and Shippers
- Manual location, coordinate and progress updates
- Tracking event and checkpoint history
- ETA updates with automatic delay alerts
- Manual operational, trip, delivery, route, documentation and compliance alerts
- Alert acknowledgement and resolution
- Driver and Operations exception reporting
- Truck breakdown, driver, delay, route, delivery and documentation exception types
- Operations exception acknowledgement, investigation and resolution
- Immutable incident action history
- Status history and audit events for important workflow actions

Phase 9 does not add e-POD, payments, settlement or notification delivery.

## Install

Merge the project while preserving `.env`, then import:

1. `database/migrations/041_phase9_tracking_alert_exception_alignment.sql`
2. `database/seeds/042_phase9_permissions.sql`

Log all roles out and in again so permission context is refreshed.

## Test workflow

1. Operations opens **Operations Monitoring** and selects a Phase 8 trip.
2. Operations or the assigned Driver records a location/progress update.
3. Record a checkpoint and verify a `shipment_milestones` row is added.
4. Set an ETA later than planned arrival and verify an open delay alert is generated.
5. The assigned Driver reports each required exception type and verify Operations can see it.
6. Operations acknowledges, investigates and resolves the exception with a resolution note.
7. Verify the linked exception alert is resolved.
8. Verify Carrier and Shipper can view only trips in their authorized scope.
9. Verify an unrelated Driver, Carrier or Shipper receives access denied.
10. Verify existing Phase 8 status transitions still work.

## Verification queries

```sql
SELECT * FROM tracking_sessions ORDER BY tracking_session_id;
SELECT * FROM tracking_events ORDER BY tracking_event_id;
SELECT * FROM trip_location_summaries ORDER BY trip_location_summarie_id;
SELECT * FROM eta_updates ORDER BY eta_update_id;
SELECT * FROM alerts ORDER BY alert_id;
SELECT * FROM incidents ORDER BY incident_id;
SELECT * FROM incident_actions ORDER BY incident_action_id;
SELECT * FROM status_history WHERE entity_type IN ('alert','incident') ORDER BY status_history_id;
```