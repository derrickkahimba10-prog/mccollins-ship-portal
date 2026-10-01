# McCollins Phase 5A — Operations Review & Clarification

This is a merge package for the supplied working Phase 4 project. It does not replace the approved database and does not add approval/rejection, quotation, matching, assignment, dispatch, or finance behavior.

## Install on XAMPP (PHP 8.2 / MariaDB 10.4.32)
1. Stop Apache. In `C:\xampp\htdocs`, rename the current `mccollins-ship-portal` to `mccollins-ship-portal-backup-phase4`. Export `mccollins_shipping` from phpMyAdmin as a backup.
2. Extract this ZIP. Copy the **contents of the `mccollins-ship-portal` folder** into `C:\xampp\htdocs\mccollins-ship-portal`; allow folder merge and file replacement.
3. Confirm your existing `.env` stayed in the project root. This merge does not include or require new secrets. Keep the existing values; database sessions already execute `SET time_zone='+00:00'` through the existing configuration.
4. Start Apache and MySQL. Open `http://localhost/phpmyadmin`, select `mccollins_shipping`, choose **Import**, and import `database/migrations/019_phase5a_review_alignment.sql`.
5. Import `database/seeds/020_phase5a_review_permissions.sql` into the same database.
6. Open XAMPP Shell and run:
   `cd C:\xampp\htdocs\mccollins-ship-portal`
   `C:\xampp\php\php.exe scripts\create_operations_officer.php`
   Enter the local Operations Officer name, email, and a temporary password of at least 12 characters. The script is CLI-only, refuses non-local DB hosts, creates an active `MCCOLLIN_OPERATIONS` role, and writes an audit event. Internal roles remain excluded from public registration.
7. Log out any existing sessions and log in again so permissions reload.

## XAMPP validation and tests
1. Syntax lint from XAMPP Shell:
   `for /R %f in (*.php) do @C:\xampp\php\php.exe -l "%f" || exit /b 1`
2. Sign in as a Shipper. Create a draft, submit it, and note the load reference. Confirm the submitted page is read-only.
3. Sign in as the Operations Officer. Open **Operations Load Queue**. Open the submitted load and click **Start review**. Confirm status changes from `submitted` to `under_review`.
4. Enter a clarification request (10–4000 characters) and submit. Confirm status becomes `clarification_required`.
5. Sign back in as the same Shipper company. Open **My Loads**, open the load, then choose **Respond to clarification**. Change one field, enter a response note, and submit. Confirm status returns to `under_review` and the displayed version number increases.
6. In phpMyAdmin verify:
   `SELECT load_id,version_no,status,submitted_at FROM load_versions WHERE load_id=<LOAD_ID> ORDER BY version_no;`
   Expect both the original submitted version and the new under-review version.
7. Verify the relational reviews:
   `SELECT load_id,load_version_id,reviewer_user_id,review_status,clarification_requested_at,clarification_responded_at FROM load_reviews WHERE load_id=<LOAD_ID> ORDER BY load_review_id;`
8. Verify atomic workflow records:
   `SELECT previous_status,new_status,reason,occurred_at FROM status_history WHERE entity_type='load' AND entity_id_value=<LOAD_ID> ORDER BY occurred_at;`
   `SELECT audit_event_ref,metadata_json,created_at FROM audit_events WHERE metadata_json LIKE CONCAT('%\"entity_id\":',<LOAD_ID>,'%') ORDER BY created_at;`
9. Negative tests: use a different Shipper company to open `/public/loads/view.php?id=<LOAD_ID>` (expect 404); try Operations URLs as Shipper (expect 403); try clarification when status is not `clarification_required` (expect 409); confirm `/public/auth/register.php` contains no internal-role option.

## QA disclosure
The final archive is integrity-tested with `unzip -t`. PHP CLI is unavailable in the generation environment, so PHP linting/runtime execution could not be performed here; run the XAMPP lint command above before browser testing.
