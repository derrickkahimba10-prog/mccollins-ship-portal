# McCollins Phase 6C — Driver Creation, Verification & Truck Linking

Phase 6C implements the approved sequence:

1. A verified Carrier creates and approves a Driver profile.
2. The system creates an invited Driver account and displays a one-time local password-setup link valid for 24 hours.
3. The Driver creates their own password; the Carrier never knows it.
4. McCollins Operations verifies the Driver and activates the requested `DRIVER` role.
5. The Carrier links the verified Driver to one verified owner-scoped truck.

The truck link is a fleet-resource relationship only. It is not a load, shipment, matching, or transport assignment. Driver and truck availability remain unavailable until Phase 6D eligibility checks.

Licence, identity, and medical references are captured without file uploads. Public self-registration no longer offers the Driver role.

## Install on XAMPP
1. Keep Apache and MySQL running and export a backup of `mccollins_shipping`.
2. After the export downloads, stop Apache.
3. Back up `C:\xampp\htdocs\mccollins-ship-portal`.
4. Extract the merge ZIP and merge its `mccollins-ship-portal` contents into the existing project. Allow replacement.
5. Preserve or restore the existing `.env`; no new secret is required.
6. Start Apache and confirm MySQL is running.
7. In phpMyAdmin select the `mccollins_shipping` database and import in this order:
   - `database/migrations/027_phase6c_driver_alignment.sql`
   - `database/seeds/028_phase6c_driver_permissions.sql`
8. Log Carrier and Operations accounts out and back in.

## PHP lint

```bat
cd C:\xampp\htdocs\mccollins-ship-portal
for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" || exit /b 1
```

## Complete positive test
1. Log in as a verified Carrier with at least one verified truck.
2. Open **My Drivers** → **Create Driver**.
3. Enter a unique Driver email, `NATIONAL_ID` or `PASSPORT`, licence information and comma-separated category codes such as `C,E`.
4. Enter medical certificate dates and `FIT`.
5. Submit. Copy the one-time setup link immediately.
6. Open the link in a private/incognito browser and create a password of at least 12 characters.
7. As Operations, open **Driver Verification**. Confirm password setup says Completed and the verification precheck passes.
8. Click **Verify and activate Driver**.
9. Return to the Carrier, open the Driver, and link one of the Carrier's verified trucks.
10. Log in as the Driver. Confirm the Driver Dashboard displays the Carrier and truck link, while availability remains unavailable.

## Invitation tests
- The link expires after 24 hours.
- It works only once.
- Reusing it must fail.
- Before it is used, the Carrier can generate a replacement link; the old link then fails.
- The Carrier never enters or receives the Driver password.

## Rejection test
1. Create a Driver using `UNFIT`, expired licence, or expired medical evidence.
2. Complete password setup.
3. Confirm Operations approval is blocked by the precheck.
4. Reject with a reason of 10–4000 characters.
5. Confirm the Driver role remains requested and the Carrier sees the rejection reason.

## phpMyAdmin verification
Find Drivers:

```sql
SELECT d.driver_id,d.driver_ref,d.user_id,d.identity_type,d.identity_number,
       d.licence_number,d.licence_categories,d.licence_expiry,
       d.medical_certificate_number,d.medical_expiry,d.medical_result,
       d.verification_status,d.availability_status
FROM drivers d
ORDER BY d.driver_id DESC;
```

Verify engagement and truck link, replacing `<DRIVER_ID>`:

```sql
SELECT driver_engagement_id,driver_id,carrier_company_id,carrier_user_id,
       truck_id,engagement_status,carrier_approved_by_user_id,started_at
FROM driver_engagements
WHERE driver_id=<DRIVER_ID> AND status='active';
```

Exactly one Carrier owner column must be populated. After linking, `truck_id` is populated and engagement is `active`.

Verify invitation without exposing the token:

```sql
SELECT uc.user_id,u.account_status,
       uc.setup_token_hash IS NOT NULL AS token_pending,
       uc.setup_expires_at,uc.setup_used_at
FROM user_credentials uc
JOIN drivers d ON d.user_id=uc.user_id
JOIN users u ON u.user_id=uc.user_id
WHERE d.driver_id=<DRIVER_ID>;
```

Verify role activation:

```sql
SELECT ur.user_id,r.role_code,ur.company_id,ur.status
FROM user_roles ur
JOIN roles r ON r.role_id=ur.role_id
JOIN drivers d ON d.user_id=ur.user_id
WHERE d.driver_id=<DRIVER_ID> AND r.role_code='DRIVER';
```

Expected: approved Driver = `active`; pending/rejected Driver = `requested`.

Verify status and audit:

```sql
SELECT previous_status,new_status,reason,actor_user_id,actor_user_role_id,occurred_at
FROM status_history
WHERE entity_type='driver' AND entity_id_value=<DRIVER_ID>
ORDER BY occurred_at;
```

```sql
SELECT audit_event_ref,metadata_json,created_at
FROM audit_events
WHERE metadata_json LIKE CONCAT('%"entity_type":"driver","entity_id":',<DRIVER_ID>,'%')
ORDER BY created_at;
```

## Negative/boundary tests
- Public registration contains no Driver role.
- Shipper receives 403 on Carrier/Operations Driver routes.
- Carrier A receives 404 for Carrier B's Driver.
- Operations approval is blocked before password setup.
- Operations approval is blocked for `UNFIT` or expired licence/medical evidence.
- A rejected or pending Driver cannot be linked to a truck.
- Carrier can link only one of its own verified trucks.
- A truck with an active Driver link cannot be linked to another Driver.
- Driver and truck availability remain unchanged/unavailable.
- No load matching, offer, assignment, dispatch, trip, payment, or file-upload function exists.

## QA disclosure
The archive is integrity-tested with `unzip -t`. PHP and MariaDB CLI were unavailable in the generation environment; run the XAMPP lint and browser/database tests above.
