<?php
declare(strict_types=1);

namespace App\Config;

use PDO;
use PDOException;
use RuntimeException;

final class Database
{
    private static ?PDO $connection = null;

    private function __construct() {}

    public static function connection(): PDO
    {
        if (self::$connection instanceof PDO) return self::$connection;

        $host = Env::get('DB_HOST', '127.0.0.1');
        $port = Env::get('DB_PORT', '3306');
        $database = Env::get('DB_DATABASE', 'mccollins_shipping');
        $username = Env::get('DB_USERNAME', 'root');
        $password = Env::get('DB_PASSWORD', '');
        $charset = Env::get('DB_CHARSET', 'utf8mb4');
        $timezone = Env::get('DB_TIMEZONE', '+00:00');

        if (!preg_match('/^[A-Za-z0-9_]+$/', (string)$database)) {
            throw new RuntimeException('Invalid database name in environment configuration.');
        }
        if (!in_array($charset, ['utf8mb4'], true)) {
            throw new RuntimeException('Unsupported database character set.');
        }

        $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=%s', $host, $port, $database, $charset);

        try {
            self::$connection = new PDO($dsn, (string)$username, (string)$password, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::ATTR_STRINGIFY_FETCHES => false,
                PDO::ATTR_PERSISTENT => false,
            ]);
            $statement = self::$connection->prepare('SET time_zone = :timezone');
            $statement->execute(['timezone' => $timezone]);
            return self::$connection;
        } catch (PDOException $exception) {
            self::$connection = null;
            throw new RuntimeException('Database connection failed.', 0, $exception);
        }
    }
}
