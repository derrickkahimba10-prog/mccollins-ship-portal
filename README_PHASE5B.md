# McCollins Phase 5B — Operations Approval & Rejection

Phase 5B completes Operations review decisions using the approved final statuses `approved` and `rejected`. It preserves Phase 5A clarification/version history. It does not implement fleet, compliance, matching, offers, assignment, dispatch, shipment, documents, or finance.

## Install on XAMPP
1. Keep Apache and MySQL running. In phpMyAdmin export a backup of `mccollins_shipping` first.
2. Stop Apache after the backup completes. Keep your existing `.env` outside the ZIP replacement process.
3. Back up `C:\xampp\htdocs\mccollins-ship-portal`, then merge the contents of this ZIP's `mccollins-ship-portal` folder into it and allow replacement of supplied files.
4. Restore/retain the existing `.env`. No new secrets are required.
5. Start Apache and confirm MySQL is running.
6. In phpMyAdmin select the `mccollins_shipping` database (not an individual table), then import in this order:
   - `database/migrations/021_phase5b_review_decisions.sql`
   - `database/seeds/022_phase5b_review_decision_permissions.sql`
7. Log out and back in so the Operations session reloads permissions.

## PHP lint
From XAMPP Shell:

`cd C:\xampp\htdocs\mccollins-ship-portal`

`for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" || exit /b 1`

## Approval test
1. As Shipper, create and submit a fresh load.
2. As Operations, start review.
3. Choose **Approve load**. The note is optional.
4. Confirm the load status is `approved`, disappears from the open queue, and the Shipper sees Approved.
5. Verify in phpMyAdmin, replacing `<LOAD_ID>`:

`SELECT current_status FROM loads WHERE load_id=<LOAD_ID>;`

`SELECT status FROM load_versions WHERE load_id=<LOAD_ID> ORDER BY version_no DESC LIMIT 1;`

`SELECT review_status,decision_code,decision_reason,decided_by_user_id,decided_at FROM load_reviews WHERE load_id=<LOAD_ID> ORDER BY load_review_id DESC LIMIT 1;`

Expected status/decision: `approved`.

## Rejection test
1. Create and submit another fresh load, then start review.
2. Choose **Reject load** and enter a reason of at least 10 characters.
3. Confirm status is `rejected`, it disappears from the open queue, and the Shipper sees Rejected.
4. Run the same SQL checks; expect `rejected`.

## Audit and negative tests
Run:

`SELECT previous_status,new_status,reason,actor_user_id,occurred_at FROM status_history WHERE entity_type='load' AND entity_id_value=<LOAD_ID> ORDER BY occurred_at;`

`SELECT audit_event_ref,metadata_json,created_at FROM audit_events WHERE metadata_json LIKE CONCAT('%\"entity_id\":',<LOAD_ID>,'%') ORDER BY created_at;`

Confirm `under_review → approved` or `under_review → rejected` appears in both workflow records. Also verify:
- Shipper receives 403 on Operations routes.
- A different Shipper company receives 404 for the load.
- Approval/rejection cannot run before `under_review` or after a decision.
- An Operations Officer who does not own the active review cannot decide it.
- Rejection without a 10-character reason is blocked.
- No matching, carrier selection, truck assignment, dispatch, or finance action exists.

## QA disclosure
The archive is integrity-tested with `unzip -t`. PHP CLI was unavailable in the generation environment, so run the XAMPP lint command and browser/database tests above.
