# Phase 4 — Shipper Load Management
1. Back up database and project.
2. Copy the contents inside `mccollins-phase4` into the project root and replace supplied files.
3. In phpMyAdmin select `mccollins_shipping` and import `database/migrations/017_phase4_load_alignment.sql` exactly once.
4. Import `database/seeds/018_phase4_load_permissions.sql`.
5. Log out and back in to reload permissions.
6. Test Post a Load → save draft → edit → submit.

The migration aligns existing load tables with the frozen approved schema. It creates no new business entity. Phase 4 does not implement review, quotation, matching, assignment, shipment, tracking, or finance.

PHP CLI was unavailable during generation; runtime testing must be completed on XAMPP.
