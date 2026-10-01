# Phase 2 Authentication
1. Back up the database.
2. Import `database/migrations/015_user_credentials.sql` in phpMyAdmin.
3. Copy `app/Security`, `app/Services/Auth.php`, `public/auth`, `public/dashboard.php`, and dashboard placeholders into the existing Phase 1 project, preserving folders.
4. Add session startup settings by replacing `bootstrap/app.php` with the supplied version.
5. Open `/public/auth/register.php`. Registration creates an active account but a `requested` role; it does not self-grant privileged access.
6. For testing only, activate the requested external role in phpMyAdmin: `UPDATE user_roles SET status='active' WHERE user_id=<test id>;` Do not activate internal roles through public registration.
7. Test login, wrong password, logout, pending access, direct protected URL, and role-denied URL.
