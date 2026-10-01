# McCollins Phase 6B — Truck Registration & Compliance Verification

Phase 6B allows an approved individual or company Carrier to register owner-scoped trucks with insurance and combined inspection/roadworthiness references. McCollins Operations approves or rejects each truck. Approval sets truck verification to `verified` but deliberately leaves availability as `unavailable` until subscription, driver, and full eligibility checks are implemented later.

Approved body types: `FLATBED`, `BOX`, `CURTAIN_SIDE`, `TIPPER`, `TANKER`, `REFRIGERATED`, `CONTAINER_CARRIER`, `OTHER`.

Approved capacity units: `KG`, `TONNE`, `M3`.

File uploads, drivers, subscriptions, availability, eligibility assessments, matching, offers, assignment, and dispatch are excluded.

## Install on XAMPP
1. Keep Apache and MySQL running and export a backup of `mccollins_shipping` from phpMyAdmin.
2. After the export downloads, stop Apache.
3. Back up `C:\xampp\htdocs\mccollins-ship-portal`.
4. Extract the merge ZIP and copy the contents of its `mccollins-ship-portal` folder into `C:\xampp\htdocs\mccollins-ship-portal`. Allow replacement.
5. Preserve or restore the existing `.env`; no new secret is required.
6. Start Apache and confirm MySQL is running.
7. In phpMyAdmin select the `mccollins_shipping` database, not an individual table. Import in this order:
   - `database/migrations/025_phase6b_truck_compliance_alignment.sql`
   - `database/seeds/026_phase6b_truck_permissions.sql`
8. Log Carrier and Operations accounts out and back in to reload permissions.

## PHP lint
From XAMPP Shell:

```bat
cd C:\xampp\htdocs\mccollins-ship-portal
for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" || exit /b 1
```

## Company Carrier test
1. Log in as an approved company Carrier from Phase 6A.
2. Open **My Trucks** → **Register truck**.
3. Enter a unique registration and chassis number, make/model/year, approved body type, and capacity.
4. Enter insurance provider, policy number, coverage, and dates.
5. Enter the combined inspection reference, dates, `PASS`, and `ROADWORTHY`.
6. Submit. Confirm status is `pending` and availability is `unavailable`.
7. As Operations, open **Truck Verification**, review, and approve it.
8. Return to the Carrier account. Confirm verification is `verified` and availability remains `unavailable`.

## Individual Carrier ownership test
Repeat registration using an approved individual Carrier. Verify the new truck has `owner_user_id` populated and `owner_company_id` null. Confirm that Carrier can see it and another Carrier cannot.

## Rejection test
1. Register another truck using `FAIL`, `NOT_ROADWORTHY`, expired evidence, or another unacceptable record.
2. Confirm the approval button is unavailable when the compliance precheck fails.
3. Reject with a reason of 10–4000 characters.
4. Confirm the Carrier sees the rejection reason and the truck remains unavailable.

## phpMyAdmin verification
Find recent trucks:

```sql
SELECT truck_id,truck_ref,owner_company_id,owner_user_id,
       registration_number,registration_country,make_name,model_name,
       body_type_code,capacity_value,capacity_unit,
       verification_status,availability_status
FROM trucks
ORDER BY truck_id DESC;
```

Exactly one of `owner_company_id` and `owner_user_id` must be populated.

Verify compliance, replacing `<TRUCK_ID>`:

```sql
SELECT inspection_number,inspected_on,expires_on,result_code,roadworthiness_status
FROM inspections
WHERE truck_id=<TRUCK_ID>;
```

```sql
SELECT ip.policy_number,ip.provider_name,ip.valid_from,ip.valid_to,ip.coverage_type
FROM insurance_policy_links il
JOIN insurance_policies ip ON ip.insurance_policie_id=il.insurance_policy_id
WHERE il.truck_id=<TRUCK_ID> AND il.status='active';
```

Verify Operations decision:

```sql
SELECT verification_case_id,truck_id,status,findings,assigned_reviewer_user_id
FROM verification_cases
WHERE case_type='truck_verification' AND truck_id=<TRUCK_ID>;
```

Verify auditability:

```sql
SELECT previous_status,new_status,reason,actor_user_id,actor_user_role_id,occurred_at
FROM status_history
WHERE entity_type='truck' AND entity_id_value=<TRUCK_ID>
ORDER BY occurred_at;
```

```sql
SELECT audit_event_ref,metadata_json,created_at
FROM audit_events
WHERE metadata_json LIKE CONCAT('%"entity_type":"truck","entity_id":',<TRUCK_ID>,'%')
ORDER BY created_at;
```

## Required negative/boundary tests
- Shipper receives 403 on Carrier and Operations truck routes.
- Carrier A receives 404 for Carrier B's truck ID.
- Unverified/rejected Carrier cannot register a truck.
- Duplicate registration-country/number, chassis, or policy number is blocked.
- Approval is blocked if insurance or inspection is expired, inspection is not `PASS`, or roadworthiness is not `ROADWORTHY`.
- A decided verification cannot be decided again.
- Approved trucks remain `unavailable`.
- No file upload, driver, subscription, eligibility, matching, assignment, or dispatch action exists.

## QA disclosure
The archive is integrity-tested with `unzip -t`. PHP and MariaDB CLI were unavailable in the generation environment; run the XAMPP lint command and browser/database tests above.
