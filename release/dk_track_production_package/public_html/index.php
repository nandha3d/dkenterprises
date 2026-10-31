<?php
// DK Track — Herd / Valet / Shared Hosting Universal Front Controller
$uri = urldecode(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH));

// 1. Route API requests to REST front controller
if (str_starts_with($uri, '/api/')) {
    require_once __DIR__ . '/api/v1/index.php';
    exit;
}

// 2. Direct static files for Herd PHP server
$filePath = __DIR__ . $uri;
if ($uri !== '/' && file_exists($filePath) && !is_dir($filePath)) {
    return false;
}

// 3. Deliver SPA frontend
if (file_exists(__DIR__ . '/index.html')) {
    readfile(__DIR__ . '/index.html');
} else {
    echo "DK Track Front Controller Running.";
}
exit;
