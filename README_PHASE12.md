# Phase 12 — Notifications, Audit & Pilot Hardening

Complete Phase 12 adds in-app notifications, audit visibility, authenticated access logging and security hardening to the verified freight platform.

## Included

- Personal notification inbox and unread count
- Assignment, dispatch, trip-status, delivery, e-POD, payment and settlement notifications
- Operations pilot broadcasts by role or all active users
- Per-user delivery/read records
- Searchable read-only audit viewer
- Authenticated request/access logs
- Audit backfill from existing JSON metadata
- Secure session-cookie behavior on HTTPS
- Clickjacking, MIME-sniffing, referrer and browser-permission headers
- Responsive notification and long-navigation layouts

Notifications are in-app. Email, SMS and mobile-money gateway delivery require external integrations and are not enabled in this core release.

## Installation

1. Start Apache and MySQL and export a fresh `mccollins_shipping` backup.
2. Stop Apache and back up `C:\xampp\htdocs\mccollins-ship-portal`.
3. Extract the Phase 12 ZIP.
4. Copy everything inside its inner `mccollins-ship-portal` folder into the current project.
5. Allow replacement and preserve `.env`.
6. Start Apache and MySQL.
7. Select `mccollins_shipping` in phpMyAdmin.
8. Import, in order:

```text
database/migrations/047_phase12_notifications_audit_hardening.sql
database/seeds/048_phase12_permissions.sql
```

9. Confirm both imports finish without a red error.
10. Log every test role out and back in.
11. Hard-refresh the browser with `Ctrl + F5`.

## PHP lint

```bat
cd C:\xampp\htdocs\mccollins-ship-portal
for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" || exit /b 1
```

## Core test

1. Log in as Operations and confirm **Notifications**, **Audit Events** and **Access Logs** are visible.
2. Open Notifications and send a pilot notification to Finance.
3. Log in as Finance; confirm the unread count, open the notification and mark it read.
4. Repeat with Shipper, Carrier and Driver audiences.
5. Trigger a new payment request or status action and confirm the affected role receives an automatic notification.
6. For a new transport workflow, verify assignment, dispatch, in-transit, arrival and delivery notifications.
7. Submit/review an e-POD and verify Operations and involved parties receive the correct updates.
8. Submit/review a payment and approve/pay a settlement; verify Shipper, Finance and Carrier notifications.
9. Open Audit Events, search `PAYMENT`, `SETTLEMENT`, `EPOD`, `TRIP` and `ASSIGNMENT`.
10. Open Access Logs and confirm the current user, method, path, IP and browser are recorded.
11. Confirm Shippers, Carriers and Drivers cannot access Audit Events or Access Logs directly.
12. Confirm one user cannot mark another user's notification as read.

## Verification SQL

```sql
SELECT notification_id,recipient_user_id,category,priority,title,
entity_type,entity_id_value,action_url,emitted_at,read_at
FROM notifications ORDER BY notification_id;
```

```sql
SELECT notification_id,recipient_user_id,channel,delivery_status,
delivered_at,read_at
FROM notification_deliveries ORDER BY notification_deliverie_id;
```

```sql
SELECT audit_event_id,action_code,entity_type,entity_id_value,
actor_user_id,source_channel,created_at,metadata_json
FROM audit_events ORDER BY audit_event_id DESC;
```

```sql
SELECT access_log_id,user_id,request_method,request_path,
ip_address,user_agent,occurred_at
FROM access_logs ORDER BY access_log_id DESC;
```

## Pilot acceptance checklist

- Role and company isolation passes
- Invalid transitions remain blocked
- CSRF checks remain active
- Uploaded documents remain protected
- Payment and payout duplicates remain blocked
- Notification ownership passes
- Audit and access pages are read-only
- No `.env` or database dump is exposed under `public`
- PHP lint and all Phase 1–12 regression workflows pass

After acceptance, export `mccollins_shipping12.sql` and archive the complete verified pilot project.