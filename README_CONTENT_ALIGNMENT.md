# McCollins Content Alignment Update

This update preserves the approved premium frontend and existing database. It is not a new development phase.

## Install

1. Back up the current project and database.
2. Stop Apache.
3. Copy this package into `C:\xampp\htdocs\mccollins-ship-portal` and allow replacement.
4. Preserve the existing `.env`.
5. The `scripts` folder is unchanged and may be left untouched.
6. No SQL import is required.
7. Restart Apache and MySQL.
8. Run `CONTENT_ALIGNMENT_TESTING.md`.

## Added

- Changeable unpaid plan selection and future-plan scheduling using existing subscription records.
- Automatic redirect from plan selection to manual bank-transfer detail capture.
- Operations payment verification with submitted transfer information.
- English/Kiswahili interface toggle stored in the browser.
- Same-page scroll restoration and accessible horizontal table scrolling.
- Wider Fleet Eligibility tables without changing the approved design system.
- Public About, Vision, Mission, stakeholder, platform-capability and management contact content grounded in the investor deck.
- Clear separation between implemented capabilities and future integrations.

No beneficiary bank account was invented because the supplied source did not provide one. The current form records the payer's real transfer details for Operations verification. Official McCollins beneficiary details can be displayed later once supplied and approved.
