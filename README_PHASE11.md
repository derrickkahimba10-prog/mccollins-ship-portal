# Phase 11 — Payments & Settlement Foundation

Complete Phase 11 adds manual customer-payment records, confirmation, carrier settlements, payouts and a financial audit trail. It is a gateway-ready foundation; it does not call a live mobile-money or banking API.

## Implemented workflow

```text
Delivered + confirmed e-POD
→ Finance payment request
→ Shipper submits transaction reference
→ Finance confirms or rejects payment
→ Finance creates carrier settlement
→ Settlement approved
→ Carrier payout recorded
```

## Installation

1. Keep Apache and MySQL running.
2. Export and confirm a fresh `mccollins_shipping` backup.
3. Stop Apache.
4. Back up `C:\xampp\htdocs\mccollins-ship-portal`.
5. Extract the Phase 11 ZIP.
6. Copy everything inside its inner `mccollins-ship-portal` folder into the current project.
7. Allow replacement and preserve the existing `.env`.
8. Start Apache and MySQL.
9. Select `mccollins_shipping` in phpMyAdmin.
10. Import, in order:

```text
database/migrations/045_phase11_payments_settlement_alignment.sql
database/seeds/046_phase11_permissions.sql
```

11. Confirm both imports finish without a red error.
12. Log Finance, Operations, Shipper and Carrier accounts out and back in.

## Create the internal Finance account

Finance is intentionally excluded from public self-registration because it can confirm customer payments and record Carrier payouts. Create it locally from Command Prompt:

```bat
cd C:\xampp\htdocs\mccollins-ship-portal
C:\xampp\php\php.exe scripts\create_finance_officer.php
```

Enter the Finance Officer's full name, email and a temporary password of at least 12 characters. The script creates an active `MCCOLLIN_FINANCE` account and writes an audit event. Do not add Finance to the public registration dropdown.

## PHP lint

```bat
cd C:\xampp\htdocs\mccollins-ship-portal
for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" || exit /b 1
```

## Complete test

1. Confirm the Phase 10 shipment and load are `delivered`.
2. Log in with the `MCCOLLIN_FINANCE` role and open **Payments & Settlements**.
3. Under delivered shipments, create a TZS payment request with a due date.
4. Log in as the owning Shipper and open **Payments**.
5. Submit a method, amount and unique transaction reference.
6. Confirm status becomes `submitted`.
7. Log in as Finance. Reject once with a reason.
8. Confirm the Shipper can correct and resubmit.
9. Finance confirms the resubmitted payment and verified received amount.
10. Confirm payment status becomes `confirmed`.
11. Finance creates a carrier settlement using gross amount and deductions.
12. Verify `net_amount = gross_amount - deduction_amount`.
13. Approve the settlement.
14. Record payout method and transaction reference.
15. Confirm settlement and payout statuses become `paid`.
16. Log in as the owning Carrier and open **Settlements**.
17. Confirm the Carrier sees only its own gross, deductions, net amount, status and payout reference.
18. Verify unrelated Shippers and Carriers cannot view the records.

## Validation rules

- Only delivered shipments can receive a payment request.
- One payment record is allowed per shipment.
- Amounts must be positive and currency must be a three-letter code.
- Shippers can submit only their own company payments.
- Only submitted payments can be confirmed or rejected.
- Rejection requires a reason.
- Settlements require confirmed payments.
- Deductions cannot be negative or exceed gross amount.
- Settlement order is `draft → approved → paid`.
- Payout requires a transaction reference.
- Payment events, status history and audit events are append-only.

## Verification SQL

```sql
SELECT payment_id,payment_ref,payer_company_id,shipment_id,currency,
requested_amount,received_amount,payment_status,payment_method,
transaction_reference,due_at,submitted_at,confirmed_at
FROM payments ORDER BY payment_id;
```

```sql
SELECT payment_event_id,payment_id,event_type,previous_status,new_status,
amount,currency,transaction_reference,event_notes,occurred_at,actor_user_id
FROM payment_events ORDER BY payment_id,occurred_at,payment_event_id;
```

```sql
SELECT settlement_id,settlement_ref,payment_id,shipment_id,
carrier_company_id,carrier_user_id,currency,gross_amount,deduction_amount,
net_amount,settlement_status,due_at,approved_at,approved_by_user_id
FROM settlements ORDER BY settlement_id;
```

```sql
SELECT payout_id,payout_ref,settlement_id,beneficiary_company_id,
beneficiary_user_id,amount,currency,payout_status,payment_method,
transaction_reference,paid_at,paid_by_user_id
FROM payouts ORDER BY payout_id;
```

```sql
SELECT entity_type,entity_id_value,previous_status,new_status,
actor_user_id,reason,occurred_at
FROM status_history
WHERE entity_type='settlement'
ORDER BY occurred_at;
```

## After testing

1. Export a fresh database backup as `mccollins_shipping11.sql`.
2. ZIP the complete verified project, including Phase 10 uploaded evidence files.
3. Keep `.env` only in the private deployed copy.
4. Upload the verified ZIP and SQL backup for Phase 12.