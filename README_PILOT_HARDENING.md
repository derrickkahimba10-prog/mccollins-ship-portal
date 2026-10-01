# McCollins Pilot Hardening Package

This is a post-Phase 12 pilot candidate, not a new phase. It preserves the completed business architecture and data.

## Install

1. Keep a fresh ZIP of the current project and export `mccollins_shipping`.
2. Stop Apache.
3. Extract this package.
4. Copy the contents of its inner `mccollins-ship-portal` folder into `C:\xampp\htdocs\mccollins-ship-portal` and allow replacement.
5. Preserve the local `.env`; this package intentionally excludes it.
6. Start Apache and MySQL.
7. In phpMyAdmin, select `mccollins_shipping` and import only:
   `database/migrations/049_pilot_integrity_constraints.sql`
8. Run the PowerShell lint command in `PILOT_TEST_PLAN.md`.
9. Execute the complete test plan and log every failure.

## Main changes

- Restricted the database diagnostic route.
- Added account lockout and session timeouts.
- Added eight proven missing foreign keys through an idempotent migration.
- Completed core admin/role dashboard shortcuts and success feedback.
- Standardized the responsive McCollins design system and mobile navigation.
- Added the full test plan and pilot-readiness audit.

Do not import older phase migrations into a database that already contains Phase 12. Do not replace your `.env`.
