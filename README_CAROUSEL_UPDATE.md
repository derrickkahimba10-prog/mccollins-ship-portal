# McCollins Carousel & Subscription Visibility Update

## Installation

1. Back up the project and database.
2. Stop Apache.
3. Copy this package into `C:\xampp\htdocs\mccollins-ship-portal` and allow replacement.
4. Preserve `.env`; the `scripts` folder is unchanged.
5. No SQL import is required.
6. Restart Apache and MySQL.
7. Run `CAROUSEL_SUBSCRIPTION_UPDATE_TESTING.md`.

## Included

- Authenticated language control moved to the top-right corner.
- Read-only subscription plan/subscriber catalog for Operations and Finance.
- Audit search button aligned beneath its field.
- Reusable premium capability carousel on the public About page.
- Slow autoplay, pause on interaction, arrows, dots, keyboard navigation, mouse drag and touch swipe.
- Existing design tokens and operational workflows preserved.

See `SAFE_PAYMENT_DECISION.md` for why raw CVC storage and unverified automatic paid activation were not implemented.
