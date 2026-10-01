# McCollins Ship Portal — Full-System Pilot Test Plan

## Test setup

Use a copied database, never the only backup. Create these accounts: Operations/Admin, Finance, Shipper Company A, Shipper Company B, Carrier company/owner, assigned Driver and an unrelated Driver. Use realistic cargo, routes, compliance dates and payment references. Keep browser sessions separate.

For every test record: test ID, account, record IDs, expected result, actual result, evidence, severity and retest result.

Severity: **Critical** security/data loss/core chain blocked; **High** major workflow or role blocked; **Medium** workaround exists; **Low** minor usability; **Cosmetic** appearance only.

## 1. Installation smoke test

1. Back up the current project and export the database.
2. Merge this package into `C:\xampp\htdocs\mccollins-ship-portal`; preserve the current `.env`.
3. Import `database/migrations/049_pilot_integrity_constraints.sql` in phpMyAdmin.
4. Start Apache and MySQL; open login and dashboard.
5. Confirm CSS/JS load, the menu opens on mobile width and no PHP warning is displayed.
6. Run PHP lint from PowerShell:

```powershell
Set-Location C:\xampp\htdocs\mccollins-ship-portal
Get-ChildItem -Recurse -Filter *.php | ForEach-Object { & C:\xampp\php\php.exe -l $_.FullName } | Tee-Object php-lint-results.txt
Select-String -Path php-lint-results.txt -Pattern 'Parse error|Fatal error|Errors parsing'
```

Expected: the final search returns no results.

## 2. Authentication and session security

- Valid login reaches only the correct dashboard.
- Five wrong passwords lock the account for approximately 15 minutes.
- Successful login resets the failed-attempt counter.
- Logout invalidates the session; Back/direct URL cannot reopen protected data.
- Idle session expires after 30 minutes; absolute session expires after 12 hours.
- Anonymous direct requests to each role route redirect/reject safely.
- Registration rejects missing fields, duplicate identity/email and invalid role input.
- Public self-registration must not permit Operations, Admin or Finance privilege assignment.

## 3. Complete happy path

1. **Shipper A:** onboard company; create/edit draft load; submit it.
2. **Operations:** review; request clarification.
3. **Shipper A:** answer clarification; confirm immutable response/version history.
4. **Operations:** approve/make load ready.
5. **Carrier:** verify carrier, truck, driver, documents and subscription/eligibility.
6. **Operations:** match eligible fleet; create/send offer.
7. **Carrier:** accept offer.
8. **Operations:** assign carrier/truck/driver; confirm assignment history.
9. **Operations:** create planned shipment/trip and stops.
10. **Assigned Driver:** mark ready.
11. **Operations:** dispatch.
12. **Driver:** update in order: dispatched → in transit → arrived → delivered.
13. Record tracking/location milestones; confirm shipper and operations see permitted progress.
14. Create a delay/breakdown exception; update and resolve it; confirm history/audit.
15. Upload permitted transport documents and delivery evidence.
16. Submit/review/confirm e-POD; confirm the prior pending-ePOD boundary and final delivery state.
17. **Shipper/Finance:** create/confirm customer payment with unique reference.
18. **Finance:** create/approve/pay carrier settlement and payout.
19. Confirm all final statuses, timestamps, notifications, audit events and company ownership.

## 4. Workflow and validation negatives

- Submit every major form with required fields blank, malformed dates, invalid numbers and oversized text.
- Attempt every status transition out of order: dispatch before driver ready, delivered before arrival, settlement before required payment/delivery state.
- Repeat offer acceptance, assignment, dispatch, delivered, e-POD confirmation, payment confirmation and payout submission.
- Open two tabs and submit the same action twice.
- Use expired insurance, inspection, roadworthiness, licence and medical documents; fleet must not be eligible.
- Use wrong truck type/capacity and unverified driver; matching/assignment must reject it.
- Confirm shippers never select or assign a truck.

## 5. Permission and company-scope matrix

For each row, test normal navigation, direct URL, changed query/path ID and modified POST body.

| Attempt | Expected result |
|---|---|
| Shipper A reads/changes Shipper B load, shipment, document or payment | Denied/not found; no data leaked |
| Carrier A reads/changes another carrier's fleet, offer, trip or settlement | Denied/not found |
| Unassigned Driver updates assigned Driver's trip | Denied |
| Shipper assigns fleet or performs Operations action | Denied |
| Carrier/Driver performs Finance action | Denied |
| Finance edits dispatch/tracking/assignment | Denied unless explicitly granted |
| Non-auditor opens audit/access logs | Denied |
| Non-owner downloads private document/e-POD | Denied |
| Any role posts without/with invalid CSRF token | Rejected; no DB change |

After every denied attempt, verify database values remain unchanged and an access/audit record is created where designed.

## 6. Tracking, alerts and exceptions

- Add valid tracking updates with location/progress information.
- Reject updates for unrelated trips and impossible transitions.
- Verify delay, breakdown, driver, route, delivery, documentation and compliance incident categories.
- Test open → acknowledged/in-progress → resolved flow and immutable history.
- Verify operational and role-appropriate alerts without cross-company leakage.

## 7. Documents and e-POD

- Accept allowed type/size; reject disallowed extension, MIME mismatch and oversize upload.
- Verify filenames/metadata are escaped and downloaded rather than executed.
- Confirm shipper/carrier/driver/operations access matches policy.
- Confirm delivery remains `delivered_pending_epod` until required e-POD confirmation, then reaches the approved final state.

## 8. Payments and settlement

- Test unique references, required amount/currency, zero/negative values and duplicate submission.
- Verify only authorized Finance users confirm/reject payments and approve/pay settlements.
- Carrier sees only its settlement; Shipper sees only its payment.
- Confirm transaction boundaries: failed action must not partially update balances/status/history.
- Verify all financial actions create audit history with actor and timestamp.

## 9. Notifications, audit and logs

- Trigger assignment, dispatch, tracking exception, delivery, e-POD, payment and settlement events.
- Confirm intended recipient, unread count, mark-read behavior and direct-link authorization.
- Confirm audit/access pages do not reveal another scope to unauthorized users.
- Compare workflow actions against database audit/status-history records.

## 10. Responsive and UX test

Test Chrome and Edge at approximately 1440, 1024, 768 and 390 px widths.

- Sidebar opens/closes and active item is clear.
- No page-wide horizontal scroll; wide tables scroll within their container.
- Forms, modals, alerts and buttons remain visible and usable.
- Keyboard Tab focus is visible; Enter/Space work on controls; Escape closes mobile navigation.
- Error text explains corrective action; successful actions show confirmation.
- Emerald remains dominant, cream is the readable surface and gold stays an accent.

## 11. Database verification

- Check foreign keys, orphan counts, duplicate active assignment/shipment/trip rows, required timestamps and company IDs.
- Compare current statuses with latest history/milestone entries.
- Confirm failed and unauthorized actions made no unintended changes.
- Export a final SQL backup only after all retests pass.

## Exit criteria

- Zero open Critical or High issues.
- Complete happy path passes from a fresh load through paid payout.
- All cross-company/direct-URL/modified-request tests pass.
- PHP lint has zero errors.
- Migration 049 imports without error and the application starts normally.
- Desktop/tablet/mobile core workflows are usable.
- Final ZIP excludes `.env`, logs and credentials; final SQL export is freshly verified.
