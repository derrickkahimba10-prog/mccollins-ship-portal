# McCollins Phase 6D — Subscription, Eligibility & Automatic Availability

Phase 6D completes the Fleet foundation. Individual and company Carriers request a plan. McCollins Operations records the received offline payment reference, and the subscription activates immediately in the same transaction. There is no separate subscription-verification wait. Operations cannot reject a request in this phase; an unpaid request remains pending.

Approved limits:
- GOLD: 2 verified trucks and 2 verified Drivers.
- PREMIUM: 10 verified trucks and 10 verified Drivers.
- PLATINUM: unlimited.

All of the following are required for an eligible/available Driver–truck pair:
- Carrier verification is `verified`.
- Carrier business licence expiry is present and current.
- Carrier insurance expiry is present and current.
- Subscription is active and inside its term.
- Pair is inside plan limits.
- Truck is verified.
- Truck insurance is current.
- Inspection is current, `PASS`, and `ROADWORTHY`.
- A Driver is actively linked to the truck.
- Driver is verified.
- Driver licence is current.
- Driver medical result is `FIT` and current.

Eligible pairs are automatically marked available. Failure of any rule automatically makes the truck and linked Driver unavailable. No manual override is provided. Matching, offers, load assignment, dispatch, trips, payments, or file uploads remain excluded.

## Install on XAMPP
1. Keep Apache and MySQL running and export a backup of `mccollins_shipping`.
2. After the export downloads, stop Apache.
3. Back up `C:\xampp\htdocs\mccollins-ship-portal`.
4. Extract the merge ZIP and merge its `mccollins-ship-portal` contents into the project. Allow replacement.
5. Preserve/restore the existing `.env`.
6. Start Apache and ensure MySQL is running.
7. In phpMyAdmin select the `mccollins_shipping` database and import in order:
   - `database/migrations/029_phase6d_subscription_eligibility_alignment.sql`
   - `database/seeds/030_phase6d_plans_permissions.sql`
   - `database/migrations/031_phase6d_payment_confirmation_activation.sql`
8. Log Carrier and Operations accounts out and back in.

If `029` and `030` were already imported, import only `031` for this adjustment.

## PHP lint

```bat
cd C:\xampp\htdocs\mccollins-ship-portal
for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" || exit /b 1
```

## Subscription test
1. Log in as a verified Carrier.
2. Open **Subscription**, choose GOLD, PREMIUM, or PLATINUM, and submit.
3. Confirm state is `requested`.
4. As Operations open **Subscription Payments** and open it.
5. Enter the received offline payment reference and an end date/time later than now.
6. Click **Confirm payment & activate now**.
7. Confirm state becomes `active` immediately, `start_at` is set to the current UTC time, and eligibility is calculated in the same transaction.

## Eligibility test
Use a Carrier with valid Carrier-level licence/insurance dates, a verified truck with current insurance/inspection, and a verified FIT Driver actively linked to that truck.

1. Activate the subscription.
2. Open **Fleet Eligibility**.
3. Confirm assessment is `eligible` with no reason codes.
4. Confirm truck and Driver availability are `available`.
5. Change one expiry date to the past in a controlled test or wait for a test expiry, then run the CLI reassessment.
6. Confirm assessment becomes `ineligible` and both become `unavailable`.

Missing Carrier expiry dates intentionally produce `CARRIER_BUSINESS_LICENSE_INVALID` or `CARRIER_INSURANCE_INVALID`.

## Plan-limit tests
- GOLD: only the first 2 verified resources by record order may become eligible; additional verified resources show `PLAN_TRUCK_LIMIT` and/or `PLAN_DRIVER_LIMIT`.
- PREMIUM: limit is 10/10.
- PLATINUM: no numeric fleet limit.
- Pending/rejected trucks and Drivers do not consume the approved verified-resource limits.

## Windows Task Scheduler
Run the eligibility command daily so expiry changes are enforced without a page visit.

Manual test from XAMPP Shell:

```bat
cd C:\xampp\htdocs\mccollins-ship-portal
C:\xampp\php\php.exe scripts\recompute_eligibility.php
```

Expected output resembles:

```text
Eligibility processed: 2; failed: 0
```

Create a Windows scheduled task:
1. Open **Task Scheduler** → **Create Task**.
2. Name: `McCollins Eligibility Reassessment`.
3. Trigger: Daily, for example 00:05.
4. Action → Start a program.
5. Program/script:
   `C:\xampp\php\php.exe`
6. Add arguments:
   `C:\xampp\htdocs\mccollins-ship-portal\scripts\recompute_eligibility.php`
7. Start in:
   `C:\xampp\htdocs\mccollins-ship-portal`
8. Save and use **Run** once. Confirm the task reports success and the command output/logs show no failure.

The CLI refuses non-local database hosts.

## phpMyAdmin verification
Approved plan limits:

```sql
SELECT plan_code,plan_name,max_trucks,max_drivers
FROM subscription_plan_versions
WHERE status='active'
ORDER BY plan_code;
```

Subscription, replacing `<SUBSCRIPTION_ID>`:

```sql
SELECT subscription_id,company_id,owner_user_id,subscription_state,
       start_at,end_at,payment_reference,payment_confirmed_at,
       requested_by_user_id,reviewed_by_user_id,payment_confirmed_by_user_id
FROM subscriptions
WHERE subscription_id=<SUBSCRIPTION_ID>;
```

Subscription history:

```sql
SELECT previous_state,new_state,actor_user_id,reason,occurred_at
FROM subscription_status_history
WHERE subscription_id=<SUBSCRIPTION_ID>
ORDER BY occurred_at;
```

Latest truck assessment, replacing `<TRUCK_ID>`:

```sql
SELECT eligibility_assessment_id,carrier_company_id,carrier_user_id,
       subscription_id,truck_id,driver_id,assessment_result,
       reason_codes_json,assessed_at
FROM eligibility_assessments
WHERE truck_id=<TRUCK_ID>
ORDER BY eligibility_assessment_id DESC
LIMIT 1;
```

Current availability:

```sql
SELECT truck_id,driver_id,eligibility_assessment_id,
       availability_status,available_from,unavailable_at,reason
FROM resource_availability
WHERE truck_id=<TRUCK_ID>;
```

Authoritative resource states:

```sql
SELECT truck_id,verification_status,availability_status
FROM trucks
WHERE truck_id=<TRUCK_ID>;
```

```sql
SELECT driver_id,verification_status,availability_status
FROM drivers
WHERE driver_id=<DRIVER_ID>;
```

Audit/history:

```sql
SELECT previous_status,new_status,reason,occurred_at
FROM status_history
WHERE entity_type IN ('subscription','truck_availability')
ORDER BY occurred_at DESC;
```

```sql
SELECT audit_event_ref,metadata_json,created_at
FROM audit_events
WHERE metadata_json LIKE '%ELIGIBILITY_%'
   OR metadata_json LIKE '%SUBSCRIPTION_%'
ORDER BY created_at DESC;
```

## Negative/boundary tests
- Shipper receives 403 on subscription and eligibility routes.
- Carrier A cannot view Carrier B's subscription or eligibility records.
- A Carrier cannot have another requested/active subscription.
- Operations cannot activate an already active request.
- Payment reference is required, unique, and 3–96 supported characters.
- Payment confirmation sets the start immediately; end must be later than now.
- Missing/expired Carrier licence or insurance forces unavailable.
- Expired truck or Driver evidence forces unavailable.
- Unlinked Driver, unverified resources, and plan-limit overflow force unavailable.
- Availability cannot be manually overridden.
- No matching, offer, assignment, dispatch, trip, finance, or document-upload action exists.

## QA disclosure
The archive is integrity-tested with `unzip -t`. PHP and MariaDB CLI were unavailable in the generation environment; run the XAMPP lint, CLI, browser, and database tests above.
