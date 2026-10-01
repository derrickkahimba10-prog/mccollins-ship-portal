<?php
// Application code should use App\Config\Database::connection().
// Credentials belong in the uncommitted root .env file.
return ['driver' => 'mysql', 'database' => getenv('DB_DATABASE') ?: 'mccollins_shipping'];
