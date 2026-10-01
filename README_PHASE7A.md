# McCollins Phase 7A — Operations Matching Intake & Candidate Screening

Phase 7A starts the approved matching workflow without implementing offers or assignments. McCollins Operations can open approved loads, refresh current Phase 6D eligibility, and generate auditable candidate records from eligible/available Driver–truck pairs.

## Boundary

Included:
- Operations-only approved-load matching queue.
- Matching against the latest immutable approved load version.
- Fresh eligibility recalculation before every generation.
- Candidate records in `matches` and relational factors in `match_factors`.
- Capacity normalization for KG/TONNE and M3 when dimensions are comparable.
- Preserved superseded matching generations.
- Status history and audit event in the same transaction.
- A correction for DATETIME(6) subscription boundary comparisons.

Excluded:
- Carrier offers or responses.
- Candidate selection or final assignment.
- Truck/Driver reservation.
- Load status changes beyond `approved`.
- Dispatch, shipments, trips, tracking, documents, or finance.

Because the approved load version does not currently capture a required truck body type and Phase 7A does not capture live truck location, eligible candidates remain `review_required` unless screened out for insufficient comparable capacity. The system does not invent these requirements or claim a final match.

## XAMPP installation

1. Keep Apache and MySQL running and export a fresh backup of `mccollins_shipping`.
2. After the export downloads, stop Apache.
3. Back up `C:\xampp\htdocs\mccollins-ship-portal`.
4. Extract the merge ZIP and copy the contents of its inner `mccollins-ship-portal` folder into the existing project folder.
5. Allow replacement, but preserve the existing `.env`.
6. Start Apache and ensure MySQL is running.
7. In phpMyAdmin select `mccollins_shipping` and import in this exact order:
   - `database/migrations/033_phase7a_matching_alignment.sql`
   - `database/seeds/034_phase7a_matching_permissions.sql`
8. Log Operations accounts out and back in.

## PHP lint

From XAMPP Shell or Command Prompt:

```bat
cd C:\xampp\htdocs\mccollins-ship-portal
for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" || exit /b 1
```

## Functional test

1. Confirm at least one load has `current_status='approved'`.
2. Confirm at least one Driver–truck pair shows `eligible` and `available` under **Fleet Eligibility**.
3. Log in as McCollins Operations.
4. Open **Matching Queue**.
5. Open an approved load.
6. Click **Generate / refresh candidates**.
7. Confirm the success message contains a generation reference and counts.
8. Confirm each current candidate shows:
   - Carrier, truck, and Driver.
   - Eligibility and availability `pass`.
   - Capacity `pass`, `fail`, or `not evaluated`.
   - Body type and live location as `not evaluated` where the approved requirement is absent.
9. Generate again and confirm only the latest generation is shown; earlier rows remain in the database with `status='superseded'`.
10. Confirm there is no offer, assignment, reservation, or dispatch button.

If no candidates appear, open **Fleet Eligibility**. An expired/out-of-term subscription, expired compliance, unavailable truck/Driver, or missing active Driver–truck link must prevent matching.

## phpMyAdmin verification

Latest active candidates for a load, replacing `<LOAD_ID>`:

```sql
SELECT match_id,match_ref,load_id,load_version_id,truck_id,driver_id,
       eligibility_assessment_id,generated_run_ref,suitability_status,
       overall_reason,generated_by_user_id,generated_at,status
FROM matches
WHERE load_id=<LOAD_ID> AND status='active'
ORDER BY match_id;
```

Factors:

```sql
SELECT mf.match_id,mf.factor_code,mf.factor_result,
       mf.required_value,mf.actual_value,mf.unit_code,mf.reason
FROM match_factors mf
JOIN matches m ON m.match_id=mf.match_id
WHERE m.load_id=<LOAD_ID> AND m.status='active'
ORDER BY mf.match_id,mf.match_factor_id;
```

Preserved generations:

```sql
SELECT generated_run_ref,status,COUNT(*) AS candidate_count,
       MIN(generated_at) AS generated_at
FROM matches
WHERE load_id=<LOAD_ID>
GROUP BY generated_run_ref,status
ORDER BY generated_at DESC;
```

History and audit:

```sql
SELECT previous_status,new_status,reason,occurred_at
FROM status_history
WHERE entity_type='load_matching' AND entity_id_value=<LOAD_ID>
ORDER BY status_history_id DESC;
```

```sql
SELECT audit_event_ref,metadata_json,created_at
FROM audit_events
WHERE metadata_json LIKE '%MATCH_CANDIDATES_GENERATED%'
ORDER BY audit_event_id DESC;
```

## Security tests

- A Shipper or Carrier receives 403 on `/operations/matching.php` and `/operations/matching-view.php`.
- Only an active `MCCOLLIN_OPERATIONS` user with matching permissions can generate candidates.
- Submitted, under-review, clarification-required, and rejected loads cannot enter matching.
- Only currently eligible and available Driver–truck pairs are considered.
- Regeneration does not delete prior match generations.
- No Carrier or Shipper can select or assign a truck in Phase 7A.

## QA disclosure

The returned archive is integrity-tested with `unzip -t` and excludes `.env`. PHP and MariaDB CLI availability is disclosed in the delivery response; run the XAMPP lint, import, browser, and SQL tests above locally.
