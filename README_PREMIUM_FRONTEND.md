# McCollins Premium Frontend Update

This package is a post-Phase 12 frontend transformation. It is not a Phase 13 and it does not redesign the database.

## Installation

1. Back up the existing project folder and database.
2. Stop Apache.
3. Extract this ZIP and copy its inner `mccollins-ship-portal` contents into `C:\xampp\htdocs\mccollins-ship-portal`.
4. Allow replacement.
5. Preserve the existing `.env`.
6. The `scripts` folder is unchanged and may be left as-is.
7. No new SQL import is required for this premium frontend update.
8. Start Apache and MySQL.
9. Run the lint and focused tests in `PREMIUM_UPDATE_TESTING.md`.

## Included changes

- Premium dark-emerald, warm-cream and champagne-gold frontend system.
- Original lightweight logistics hero artwork and redesigned login/registration.
- Tier pricing and distinct Gold, Premium sapphire and Platinum presentation.
- Carrier overview **Start free trial** shortcut linked to subscriptions.
- Dual-currency TZS/USD offer entry with automatic equivalent and comma formatting.
- Structured transport cost, company charges, insurance and taxes fields.
- Latitude/longitude browser ranges matching backend validation.
- Individual-email notifications, intentional role/all broadcasts, open-as-read, close and scroll retention.
- Dynamic navigation attention counters according to permissions and scope.
- Strong status badges, bold timestamps, descriptive hover/focus previews and assistant UI shell.
- Responsive desktop, tablet and mobile behavior.

## Important

The McCollins Assistant is a frontend placeholder only. It does not claim to provide AI responses. Existing authentication, permissions, company scope and business workflows remain authoritative.
