# Premium Frontend Update — Brief Testing

No database migration is required for this update. Preserve `.env` and the existing `scripts` folder.

## PHP lint

From the XAMPP Command Prompt:

```cmd
cd /d C:\xampp\htdocs\mccollins-ship-portal
del php-lint-results.txt 2>nul
for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" >> php-lint-results.txt 2>&1
findstr /I /C:"Parse error" /C:"Fatal error" /C:"Errors parsing" php-lint-results.txt
```

No output from the final command means lint passed.

## Focused browser tests

1. Login and registration: verify the premium split layout at desktop and mobile widths.
2. Carrier overview: click **Start free trial** and confirm it opens subscriptions.
3. Subscriptions: verify Gold = TSh 35,000, Premium = TSh 55,000 and Platinum = TSh 100,500 with distinct tier colors.
4. Offers: choose TZS and USD, enter comma-formatted values, verify the automatic equivalent, complete the four price components, send and revise an offer.
5. Tracking: verify latitude accepts -90 to 90, longitude -180 to 180 and values retain decimal precision.
6. Notifications: send to one email and confirm no other Driver receives it; test intentional role/all broadcasts; Open must mark read; Close must remove it; Mark as read must retain scroll position.
7. Navigation counters: trigger an unread notification, countered/accepted offer, pending subscription/payment, verification and tracking exception; confirm the correct permitted user sees the count.
8. Statuses: verify pending, confirmed, delivered and resolved states plus timestamps are bold and easy to scan.
9. Hover/focus: dashboard and sidebar actions show a description; navigation occurs only on click or Enter.
10. Responsive: test approximately 1440, 1024, 768 and 390 px widths; verify drawer navigation, tables, forms, cards and assistant shell do not overlap.
11. Permissions: repeat direct-URL and wrong-company checks for offers, tracking, notifications, payments and documents.
