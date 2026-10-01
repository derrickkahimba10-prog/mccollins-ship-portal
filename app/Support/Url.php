<?php
declare(strict_types=1);
namespace App\Support;
use App\Config\Env;
final class Url {
    public static function base(): string { return rtrim((string)(Env::get('APP_BASE_URL','/mccollins-ship-portal/public') ?? '/mccollins-ship-portal/public'),'/'); }
    public static function to(string $path=''): string { return self::base().'/'.ltrim($path,'/'); }
}
