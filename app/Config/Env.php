<?php
declare(strict_types=1);

namespace App\Config;

final class Env
{
    private static bool $loaded = false;

    public static function load(string $file): void
    {
        if (self::$loaded) return;
        if (!is_readable($file)) {
            throw new \RuntimeException('Environment file not found. Copy .env.example to .env.');
        }
        foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
            [$key, $value] = array_map('trim', explode('=', $line, 2));
            if ($key === '' || getenv($key) !== false) continue;
            if (strlen($value) >= 2 && (($value[0] === '"' && $value[-1] === '"') || ($value[0] === "'" && $value[-1] === "'"))) {
                $value = substr($value, 1, -1);
            }
            putenv("{$key}={$value}");
            $_ENV[$key] = $value;
        }
        self::$loaded = true;
    }

    public static function get(string $key, ?string $default = null): ?string
    {
        $value = getenv($key);
        return $value === false ? $default : $value;
    }
}
