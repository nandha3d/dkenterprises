<?php

/**
 * zoloERP Pro / DK Enterprises - Root Entry Point
 * 
 * Proxies requests to public/index.php for standard shared hosting
 * and control panel environments (LiteSpeed / Apache / Nginx / Enhance CP).
 */

$uri = urldecode(
    parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH)
);

if ($uri !== '/' && file_exists(__DIR__ . '/public' . $uri)) {
    return false;
}

require_once __DIR__ . '/public/index.php';
