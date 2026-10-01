<?php declare(strict_types=1);require_once __DIR__.'/../bootstrap/app.php';use App\Services\Auth;Auth::requireLogin();header('Location: '.Auth::dashboardPath());exit;
