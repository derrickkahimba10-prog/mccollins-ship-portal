<?php
declare(strict_types=1);
namespace App\Support;
final class Reference {
    public static function make(string $prefix): string { return strtoupper($prefix).'-'.strtoupper(bin2hex(random_bytes(6))); }
}
