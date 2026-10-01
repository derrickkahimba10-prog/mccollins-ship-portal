# Content Alignment & Subscription Update — Focused Tests

## PHP lint (XAMPP Command Prompt)

```cmd
cd /d C:\xampp\htdocs\mccollins-ship-portal
del php-lint-results.txt 2>nul
for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" >> php-lint-results.txt 2>&1
findstr /I /C:"Parse error" /C:"Fatal error" /C:"Errors parsing" php-lint-results.txt
```

No output from the final command means lint passed.

## Focused tests

1. **New subscription:** Carrier selects a plan and is immediately redirected to the bank-transfer details form.
2. **Payment details:** Submit bank, payer, reference and transfer date; Operations can see the submitted information and confirm it.
3. **Change before payment:** Carrier selects another plan while the request is pending; the same pending request changes and old transfer details are cleared.
4. **Future plan:** With an active plan, select another plan. After Operations confirms payment, verify the existing plan remains current and the new plan is shown as scheduled to start at the current plan's end.
5. **Paid future-plan control:** Carrier cannot silently replace an already paid scheduled plan; the portal directs them to Operations.
6. **Language:** Use **Kiswahili/English** on login, About and authenticated navigation; reload and confirm the preference remains.
7. **Scroll position:** Submit an action from lower on a page and confirm the successful return remains near the previous position.
8. **Wide tables:** Open Fleet Eligibility on desktop/mobile; all words remain readable and the table scrolls horizontally. Focus the table and test Left/Right arrow keys.
9. **About content:** Verify formal platform/company names, exact vision, derived mission, stakeholders and current-versus-roadmap capabilities.
10. **Contacts:** Confirm CEO and Manager details and both telephone links.
11. **Regression:** Recheck login, company scope, subscriptions, eligibility, notifications, offers and direct-URL permissions.
