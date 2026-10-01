# McCollins Phase 6A — Carrier Onboarding & Operations Verification

Phase 6A implements individual and company carrier onboarding against the approved schema. Individual carriers use a user-linked `truck_owner_profiles` record. Company carriers use `companies`, company membership/type records, and a linked owner profile for approved carrier-specific references. McCollins Operations approves or rejects the pending verification and activates the requested `TRUCK_OWNER` role only on approval.

Phase 6A captures TIN, business licence, and insurance identifiers/details. It intentionally defers file uploads to Phase 10 and does not implement trucks, drivers, subscriptions, eligibility, matching, offers, assignment, or dispatch.

## Install on XAMPP
1. Keep Apache and MySQL running and export a backup of `mccollins_shipping` from phpMyAdmin.
2. After the backup downloads, stop Apache.
3. Back up `C:\xampp\htdocs\mccollins-ship-portal`.
4. Extract the merge ZIP and copy the contents of its `mccollins-ship-portal` folder into `C:\xampp\htdocs\mccollins-ship-portal`. Allow replacement of supplied files.
5. Preserve/restore the existing `.env`. No new secret is required.
6. Start Apache and confirm MySQL is running.
7. In phpMyAdmin select the `mccollins_shipping` database, not an individual table. Import in this order:
   - `database/migrations/023_phase6a_carrier_alignment.sql`
   - `database/seeds/024_phase6a_carrier_permissions.sql`
8. Log out and back in as Operations so the new permissions load.

## PHP lint
From XAMPP Shell:

```bat
cd C:\xampp\htdocs\mccollins-ship-portal
for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" || exit /b 1
```

## Individual carrier test
1. Publicly register a new account and choose **Truck Owner/Fleet**. Public registration creates a requested external role; it does not activate the role.
2. Log in with that account. On **Access pending**, click **Start carrier onboarding**.
3. Choose **Individual truck owner**. Enter address, TIN, business licence, and insurance references, then submit.
4. Confirm the profile displays `pending`. Truck registration must not be available.
5. As Operations, open **Carrier Verification**, review the application, and click **Approve and activate carrier**.
6. Log out of the carrier account and log back in. Confirm the Carrier Dashboard opens and verification displays `verified`/`approved`.

## Company carrier test
1. Register another Truck Owner/Fleet account.
2. Start onboarding and choose **Carrier company**.
3. Enter unique legal name, display name, registration number/country, address, TIN, licence, and insurance references.
4. Submit, approve it from the Operations queue, then log the carrier out and back in.
5. Confirm the dashboard shows the company carrier and the active role is company-scoped.

## Rejection test
1. Register and submit a third carrier application.
2. In Operations, reject it with a reason of 10–4000 characters.
3. Confirm it disappears from the pending queue, the role remains `requested`, and the applicant sees the rejection reason but cannot access the Carrier Dashboard.

## phpMyAdmin verification
Find recent cases:

```sql
SELECT verification_case_id,verification_case_ref,case_type,user_id,company_id,status,findings
FROM verification_cases
WHERE case_type IN ('carrier_onboarding_individual','carrier_onboarding_company')
ORDER BY verification_case_id DESC;
```

Verify profiles:

```sql
SELECT truck_owner_profile_id,owner_type,user_id,company_id,tin_number,
       business_license_number,business_license_expiry,
       insurance_provider,insurance_policy_number,insurance_expiry,
       verification_status
FROM truck_owner_profiles
ORDER BY truck_owner_profile_id DESC;
```

Verify role activation, replacing `<USER_ID>`:

```sql
SELECT ur.user_id,r.role_code,ur.company_id,ur.status,ur.effective_from
FROM user_roles ur
JOIN roles r ON r.role_id=ur.role_id
WHERE ur.user_id=<USER_ID> AND r.role_code='TRUCK_OWNER';
```

Expected: approved carrier = `active`; pending/rejected carrier = `requested`.

Verify auditability, replacing `<CASE_ID>`:

```sql
SELECT previous_status,new_status,reason,actor_user_id,actor_user_role_id,occurred_at
FROM status_history
WHERE entity_type='carrier_verification' AND entity_id_value=<CASE_ID>
ORDER BY occurred_at;
```

```sql
SELECT audit_event_ref,metadata_json,created_at
FROM audit_events
WHERE metadata_json LIKE CONCAT('%"entity_type":"carrier_verification","entity_id":',<CASE_ID>,'%')
ORDER BY created_at;
```

## Negative/boundary tests
- Shipper receives 403 on `/public/operations/carriers.php`.
- A requested Carrier cannot open the protected Carrier Dashboard before approval.
- Carrier A cannot view Carrier B's profile through an ID parameter; profile lookup is bound to the authenticated user.
- A decided verification cannot be approved/rejected again.
- Approval activates exactly one requested `TRUCK_OWNER` role inside the same transaction as verification/status/audit changes.
- No internal role is offered by public registration.
- No document upload, truck, driver, subscription, eligibility, matching, assignment, dispatch, or finance action exists.

## QA disclosure
The archive is integrity-tested with `unzip -t`. PHP and MariaDB CLI were unavailable in the generation environment, so run the XAMPP lint command and browser/database tests above.
