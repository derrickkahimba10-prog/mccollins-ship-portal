# McCollins Phase 7B — Transport Offers & Carrier Responses

Operations sends candidate-specific final company prices to multiple eligible Carriers. TZS is authoritative; USD is display-only using the stored 2,600 TZS/USD snapshot. Offers expire after 24 hours. Carriers accept, decline, or counter in TZS. A counter does not reserve resources; Operations sends a revised immutable offer version. The first valid acceptance wins, reserves that Driver–truck pair, and closes competing offers.

## Included
- Operations offer creation from active Phase 7A candidates.
- Different final TZS price per candidate.
- Optional free-text price explanation visible only to Operations and the receiving Carrier.
- USD display equivalent with stored FX snapshot.
- Multiple simultaneous offers and 24-hour expiry.
- Carrier accept, decline, and counteroffer.
- Operations revised offer after a counter.
- Immutable offer versions and status history/audit.
- Atomic first-acceptance reservation and competing-offer closure.
- Reservation survives Phase 6D eligibility refresh while eligibility remains valid.
- Local CLI expiry task.

## Excluded
- Shipper/customer quotation display or approval.
- Final assignment, dispatch, shipment, trip, or settlement.
- Payment processing.
- External FX or mapping APIs.

## Installation
1. Export a backup of `mccollins_shipping` while Apache and MySQL run.
2. Stop Apache after the export downloads.
3. Back up `C:\xampp\htdocs\mccollins-ship-portal`.
4. Merge the ZIP's inner `mccollins-ship-portal` contents into the existing folder and preserve `.env`.
5. Start Apache and MySQL.
6. Import in phpMyAdmin, in order:
   - `database/migrations/035_phase7b_offer_alignment.sql`
   - `database/seeds/036_phase7b_offer_permissions_config.sql`
7. Log Operations and Carrier accounts out and back in.

## Functional test
1. Operations opens a load in **Matching Queue** with current candidates.
2. Select **Create transport offers**.
3. Select one or more candidates, enter a separate final TZS amount and optional explanation, then send.
4. Confirm each offer expires 24 hours after `sent_at` and shows TZS plus USD.
5. Carrier opens **My Transport Offers**.
6. Test decline on one offer.
7. Test counter on another; Operations opens **Transport Offers** and sends a revised amount.
8. Carrier accepts the revised offer.
9. Confirm accepted offer is `accepted`; competing offers for the load or same pair are `closed`; truck, Driver and resource availability are `reserved`.
10. Confirm there is no assignment, dispatch, or shipment record.

## Expiry task
Manual XAMPP Shell test:
```bat
cd C:\xampp\htdocs\mccollins-ship-portal
C:\xampp\php\php.exe scripts\expire_offers.php
```
Expected: `Offers expired: 0` or another non-negative count.

Task Scheduler:
- Program: `C:\xampp\php\php.exe`
- Arguments: `C:\xampp\htdocs\mccollins-ship-portal\scripts\expire_offers.php`
- Start in: `C:\xampp\htdocs\mccollins-ship-portal`
- Trigger: every 15 minutes.

## Verification SQL
```sql
SELECT offer_id,offer_thread_ref,version_no,parent_offer_id,load_id,match_id,
       offered_amount_tzs,offered_amount_usd,fx_tzs_per_usd,
       counter_amount_tzs,offer_status,sent_at,expires_at,reserved_at
FROM bids_offers ORDER BY offer_id;
```

```sql
SELECT truck_id,driver_id,availability_status,reason
FROM resource_availability ORDER BY truck_id;
```

```sql
SELECT entity_id_value,previous_status,new_status,reason,occurred_at
FROM status_history
WHERE entity_type='transport_offer'
ORDER BY status_history_id;
```

```sql
SELECT audit_event_ref,metadata_json,created_at
FROM audit_events
WHERE metadata_json LIKE '%OFFER_%'
ORDER BY audit_event_id;
```

## Security/boundary tests
- Shippers cannot access Operations or Carrier offer routes.
- Carrier A cannot view/respond to Carrier B offers.
- Expired, closed, declined, countered, revised, or accepted versions cannot be answered again.
- Duplicate acceptance for one load is blocked.
- Reserved resources cannot accept another offer.
- Matching regeneration is blocked while a load has sent, countered, or accepted offers.
- Counteroffers do not reserve resources.
- No assignment is created in Phase 7B.
