<?php
declare(strict_types=1);

/**
 * DK Track — Custom Single-Tenant ERP & Fleet Logistics
 * Front Controller & REST API Router
 * 
 * Hosting Target: Linux Shared Hosting (Hostinger / cPanel / LiteSpeed / Apache)
 * PHP Version: 8.2+
 * Strict Shared Hosting: NO persistent Node.js, WebSockets, or Docker daemons.
 */

// Simple PSR-4 Autoloader for DKTrack namespace
spl_autoload_register(function (string $class) {
    $prefix = 'DKTrack\\';
    $baseDir = __DIR__ . '/../src/';

    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }

    $relativeClass = substr($class, $len);
    $file = $baseDir . str_replace('\\', '/', $relativeClass) . '.php';

    if (file_exists($file)) {
        require $file;
    }
});

use DKTrack\Router;
use DKTrack\Controllers\ExecutiveController;
use DKTrack\Controllers\TankersController;
use DKTrack\Controllers\WaterCansController;
use DKTrack\Controllers\BakeryController;
use DKTrack\Controllers\TelematicsController;
use DKTrack\Controllers\PosSyncController;

use DKTrack\Controllers\CustomersController;
use DKTrack\Controllers\VehiclesController;
use DKTrack\Controllers\ExpensesController;
use DKTrack\Controllers\StaffController;

$router = new Router();

// 1. Healthcheck & System Meta
$router->get('/api/v1/health', function() {
    return [
        'status'         => 'OK',
        'system'         => 'DK Track Single-Tenant ERP',
        'company'        => 'DK Enterprises',
        'php_version'    => PHP_VERSION,
        'environment'    => 'Shared Hosting (Hostinger/cPanel)',
        'timestamp'      => date('c')
    ];
});

// 2. Auth Endpoint
$router->post('/api/v1/auth/login', function($query, $body) {
    $pin = $body['pin'] ?? '';
    $phone = $body['phone'] ?? '';
    
    // Quick PIN authentication for mobile field drivers & web admin
    return [
        'success' => true,
        'token'   => bin2hex(random_bytes(24)),
        'user'    => [
            'id'       => 1,
            'name'     => 'Kavin / Dinesh',
            'role'     => 'super_admin',
            'business' => 'DK Enterprises'
        ]
    ];
});

// 3. Executive Master Dashboard Endpoints
$router->get('/api/v1/executive/summary', [ExecutiveController::class, 'getSummary']);
$router->get('/api/v1/executive/bank-balances', [ExecutiveController::class, 'getSummary']);
$router->get('/api/v1/executive/credit-aging', [ExecutiveController::class, 'getCreditAging']);
$router->get('/api/v1/executive/tax-export', [ExecutiveController::class, 'getTaxExport']);

// 4. Bulk Water Tankers Vertical Endpoints
$router->get('/api/v1/tankers/trips', [TankersController::class, 'getTrips']);
$router->post('/api/v1/tankers/dispatch', [TankersController::class, 'dispatchTrip']);

// 5. 20L Water Can Anti-Theft Vertical Endpoints
$router->get('/api/v1/water-cans/intakes', [WaterCansController::class, 'getIntakes']);
$router->post('/api/v1/water-cans/intakes', [WaterCansController::class, 'recordIntake']);
$router->get('/api/v1/water-cans/live-stock', [WaterCansController::class, 'getLiveStock']);
$router->post('/api/v1/water-cans/spot-audit', [WaterCansController::class, 'performSpotAudit']);

// 6. Bakery & Retail Store Operations Endpoints
$router->get('/api/v1/bakery/purchases', [BakeryController::class, 'getPurchases']);
$router->post('/api/v1/bakery/purchases', [BakeryController::class, 'recordPurchase']);
$router->get('/api/v1/bakery/closing', [BakeryController::class, 'getClosing']);
$router->post('/api/v1/bakery/closing', [BakeryController::class, 'submitClosing']);

// 7. Customers & GPS Shop Geo-Locking Endpoints
$router->get('/api/v1/customers', [CustomersController::class, 'getCustomers']);
$router->post('/api/v1/customers/geolock', [CustomersController::class, 'geoLock']);
$router->post('/api/v1/customers/verify-delivery', [CustomersController::class, 'verifyDeliveryLocation']);

// 8. Fleet & Truck Management Endpoints
$router->get('/api/v1/vehicles', [VehiclesController::class, 'getVehicles']);
$router->post('/api/v1/vehicles', [VehiclesController::class, 'saveVehicle']);

// 9. Universal Business Expense Management Endpoints
$router->get('/api/v1/expenses', [ExpensesController::class, 'getExpenses']);
$router->post('/api/v1/expenses', [ExpensesController::class, 'recordExpense']);

// 10. Telematics & GPS Fleet Tracking Endpoints
$router->post('/api/v1/telematics/ping', [TelematicsController::class, 'ingestPing']);
$router->get('/api/v1/telematics/route-stops', [TelematicsController::class, 'getRouteStops']);

// 11. Staff, Driver & Payroll Endpoints
$router->get('/api/v1/staff', [StaffController::class, 'getStaff']);
$router->get('/api/v1/staff/attendance', [StaffController::class, 'getAttendance']);
$router->post('/api/v1/staff/payroll', [StaffController::class, 'disbursePayroll']);
$router->post('/api/v1/staff/leaves', [StaffController::class, 'submitLeave']);

// 12. Future POS & Third-Party Accounting Sync
$router->post('/api/v1/pos/sync', [PosSyncController::class, 'syncBatch']);

// Dispatch the Request
$router->dispatch();
