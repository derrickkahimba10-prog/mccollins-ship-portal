# McCollins Phase 7C — Operations Assignment

Phase 7C converts the accepted winning transport offer into one authoritative Operations-controlled assignment. It supports company and individual Carriers, preserves the accepted offer and match links, changes the load from `approved` to `assigned`, and keeps the selected Driver–truck pair reserved for Phase 8 dispatch.

## Included
- Accepted-offer assignment queue.
- Operations confirmation and optional assignment note.
- Company or individual Carrier ownership.
- One assignment per load and accepted offer.
- Reserved-resource enforcement.
- Load transition `approved → assigned`.
- Assignment and load status history plus audit event in one transaction.
- Operations assignment history and Carrier-scoped assignment view.

## Excluded
- Assignment cancellation/reassignment.
- Dispatch, shipment or trip creation.
- Driver readiness, tracking, documents, payments or settlement.

## Install
1. Export a fresh `mccollins_shipping` backup while Apache and MySQL run.
2. Stop Apache after download.
3. Back up `C:\xampp\htdocs\mccollins-ship-portal`.
4. Merge the ZIP's inner project contents, preserving `.env`.
5. Start Apache and MySQL.
6. Import in order:
   - `database/migrations/037_phase7c_assignment_alignment.sql`
   - `database/seeds/038_phase7c_assignment_permissions.sql`
7. Log Operations and Carrier users out and back in.

## Test
1. Use the already accepted Phase 7B offer.
2. Operations opens **Assignments**.
3. Confirm the accepted offer appears under awaiting assignment.
4. Select **Assign**, verify Carrier/truck/Driver/price, and confirm.
5. Confirm the assignment appears in history and the load is `assigned`.
6. Confirm resource, truck and Driver remain `reserved`.
7. Carrier opens **My Assignments** and sees only their assignment.
8. Confirm no shipment, trip or dispatch record was created.

## Verification SQL
```sql
SELECT assignment_id,assignment_ref,load_id,match_id,accepted_offer_id,
       carrier_company_id,carrier_user_id,truck_id,driver_id,
       assignment_status,assigned_at,assigned_by_user_id
FROM assignments ORDER BY assignment_id;
```

```sql
SELECT load_id,load_ref,current_status FROM loads WHERE load_id=<LOAD_ID>;
```

```sql
SELECT truck_id,driver_id,availability_status,reason
FROM resource_availability WHERE truck_id=<TRUCK_ID>;
```

```sql
SELECT entity_type,entity_id_value,previous_status,new_status,reason,occurred_at
FROM status_history
WHERE entity_type IN('assignment','load')
ORDER BY status_history_id DESC;
```

## Negative tests
- Non-Operations users cannot create assignments.
- Only an accepted offer can be assigned.
- Only a reserved resource pair can be assigned.
- A load or accepted offer cannot be assigned twice.
- Carrier A cannot view Carrier B assignments.
- Phase 7C creates no dispatch, shipment or trip.
