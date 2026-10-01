# Phase 8 — Dispatch, Shipments & Trips
Complete numbered Phase 8: Operations creates planned shipment/trip from an assignment; optional intermediate stops; assigned Driver confirms ready; Operations dispatches; Driver updates in transit, arrived and delivered with Operations fallback. Delivered remains `delivered_pending_epod` until Phase 10.

## Install
Merge ZIP preserving `.env`, then import in order:
1. `database/migrations/039_phase8_dispatch_trip_alignment.sql`
2. `database/seeds/040_phase8_permissions.sql`
Log all roles out/in.

## Test
1. Operations → Shipments & Trips → plan the Phase 7C assignment.
2. Driver → My Trips → mark Driver Ready.
3. Operations opens trip → Dispatch.
4. Driver marks In Transit, Arrived, Delivered.
5. Shipper views Shipment Progress; Carrier views Fleet Trips.
6. Verify shipment/load are `delivered_pending_epod`; no e-POD is created.

```sql
SELECT * FROM shipments ORDER BY shipment_id;
SELECT * FROM trips ORDER BY trip_id;
SELECT * FROM stops ORDER BY trip_id,sequence_no;
SELECT * FROM shipment_milestones ORDER BY occurred_at;
```
