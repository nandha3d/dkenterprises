<?php
$operationsApi = true;
require __DIR__.'/operations.php';

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\SaleApiController;
use App\Http\Controllers\Api\V1\PurchaseApiController;
use App\Http\Controllers\Api\V1\ProductApiController;
use App\Http\Controllers\Api\V1\InventoryApiController;
use App\Http\Controllers\Api\V1\AccountingApiController;
use App\Http\Controllers\Api\V1\PartnerApiController;
use App\Http\Controllers\Api\V1\WaterLogisticsApiController;
use App\Http\Controllers\Api\V1\CafeApiController;
use App\Http\Controllers\Api\V1\RepairApiController;
use App\Http\Controllers\Api\V1\AddonApiController;
use App\Http\Controllers\Api\V1\MeApiController;
use App\Http\Controllers\Api\V1\ExpenseApiController;
use App\Http\Controllers\Api\V1\HrmApiController;
use App\Http\Controllers\Api\V1\ReportApiController;

/*
|--------------------------------------------------------------------------
| API Routes - zoloERP SaaS & Industry Addon Engine (API v1)
|--------------------------------------------------------------------------
|
| Versioned RESTful API endpoints for the zoloERP Enterprise Cloud Engine.
| All endpoints return standardized JSON payloads.
| Protected routes require a Bearer token via Laravel Sanctum.
|
*/

Route::prefix('v1')->group(function () {

    // Public Health & Ping Endpoints
    Route::get('health', function () {
        return response()->json([
            'status' => 'OK',
            'system' => 'DK Enterprises ERP API v1',
            'timestamp' => now()->toIso8601String(),
        ]);
    })->name('api.v1.health');

    Route::get('ping', function () {
        return response()->json([
            'status' => 'OK',
            'system' => 'DK Enterprises ERP API v1',
            'timestamp' => now()->toIso8601String(),
        ]);
    })->name('api.v1.ping');

    // Public Authentication Endpoints
    Route::prefix('auth')->group(function () {
        Route::post('login', [AuthController::class, 'login'])->middleware('throttle:api-login')->name('api.v1.auth.login');
    });

    // Public Mobile Authentication & Bootstrap
    Route::prefix('mobile')->group(function () {
        Route::post('login', [WaterLogisticsApiController::class, 'mobileLogin'])->middleware('throttle:api-login')->name('api.v1.mobile.login');
        Route::get('bootstrap', [WaterLogisticsApiController::class, 'mobileBootstrap'])->name('api.v1.mobile.bootstrap');
    });

    // Public Tenant Addons Status
    Route::get('addons/status', [AddonApiController::class, 'status'])->name('api.v1.addons.status');

    // Protected ERP Endpoints (Sanctum Token Required)
    Route::middleware('auth:sanctum')->group(function () {

        // Global Me & Identity Endpoint
        Route::get('me', [MeApiController::class, 'me'])->name('api.v1.me');

        // Setup deliberately does not require an existing branch or financial year.
        Route::get('company-context/financial-years', [\App\Http\Controllers\CompanyFinancialYearController::class, 'index'])->name('api.v1.company.financial-years.setup');
        Route::post('company-context/financial-years', [\App\Http\Controllers\CompanyFinancialYearController::class, 'store'])->name('api.v1.company.financial-years.store');

        // User & Session
        Route::prefix('auth')->group(function () {
            Route::get('me', [MeApiController::class, 'me'])->name('api.v1.auth.me');
            Route::post('logout', [AuthController::class, 'logout'])->name('api.v1.auth.logout');
        });

        // Protected Mobile API Endpoints (Sanctum Required)
        Route::prefix('mobile')->group(function () {
            Route::get('dashboard/{role}', [WaterLogisticsApiController::class, 'roleDashboard'])->name('api.v1.mobile.dashboard');
            Route::get('workspace', [WaterLogisticsApiController::class, 'groupWorkspaceInsights'])->name('api.v1.mobile.workspace');
            Route::get('customers', [WaterLogisticsApiController::class, 'customersList'])->name('api.v1.mobile.customers');
            Route::post('customers', [WaterLogisticsApiController::class, 'customerOnboard'])->name('api.v1.mobile.customers.create');
            Route::get('products', [WaterLogisticsApiController::class, 'productsList'])->name('api.v1.mobile.products');
            Route::get('invoices', [WaterLogisticsApiController::class, 'invoicesList'])->name('api.v1.mobile.invoices');
            Route::get('financials', [WaterLogisticsApiController::class, 'financials'])->name('api.v1.mobile.financials');
            Route::post('customer-onboard', [WaterLogisticsApiController::class, 'customerOnboard'])->name('api.v1.mobile.customer-onboard');
            Route::post('collect-payment', [WaterLogisticsApiController::class, 'collectPayment'])->name('api.v1.mobile.collect-payment');
            Route::post('spot-audit', [WaterLogisticsApiController::class, 'spotAudit'])->name('api.v1.mobile.spot-audit');
            Route::post('driver-surrender', [WaterLogisticsApiController::class, 'driverCashSurrender'])->name('api.v1.mobile.driver-surrender');
            Route::get('fleet/live', [WaterLogisticsApiController::class, 'fleetLive'])->name('api.v1.mobile.fleet.live');
            Route::get('fleet/driver-activity', [WaterLogisticsApiController::class, 'driverActivityTimeline'])->name('api.v1.mobile.fleet.driver-activity');
            Route::post('fleet/ping', [WaterLogisticsApiController::class, 'fleetPing'])->name('api.v1.mobile.fleet.ping');
            Route::get('customers/{id}/history', [WaterLogisticsApiController::class, 'customerFullHistory'])->name('api.v1.mobile.customers.history');
            Route::post('customers/{id}/location', [WaterLogisticsApiController::class, 'updateCustomerLocation'])->name('api.v1.mobile.customers.location');
            Route::get('driver/manifest', [WaterLogisticsApiController::class, 'driverManifest'])->name('api.v1.mobile.driver.manifest');
        });

        // Direct Mobile Convenience Aliases
        Route::get('customers', [WaterLogisticsApiController::class, 'customersList'])->name('api.v1.customers.alias');
        Route::post('customers', [WaterLogisticsApiController::class, 'customerOnboard'])->name('api.v1.customers.create.alias');
        Route::post('customer-onboard', [WaterLogisticsApiController::class, 'customerOnboard'])->name('api.v1.customer-onboard.alias');
        Route::get('financials', [WaterLogisticsApiController::class, 'financials'])->name('api.v1.financials.alias');
        Route::get('invoices', [WaterLogisticsApiController::class, 'invoicesList'])->name('api.v1.invoices.alias');
        Route::post('collect-payment', [WaterLogisticsApiController::class, 'collectPayment'])->name('api.v1.collect-payment.alias');
        Route::post('can-deliveries', [WaterLogisticsApiController::class, 'storeCanDelivery'])->name('api.v1.can-deliveries.alias');
        Route::post('trip-sheets', [WaterLogisticsApiController::class, 'storeTripSheet'])->name('api.v1.trip-sheets.alias');
        Route::post('plant-intakes', [WaterLogisticsApiController::class, 'storePlantIntake'])->name('api.v1.plant-intakes.alias');
        Route::get('routes', [WaterLogisticsApiController::class, 'routes'])->name('api.v1.routes.alias');
        Route::post('driver-surrender', [WaterLogisticsApiController::class, 'driverCashSurrender'])->name('api.v1.driver-surrender.alias');
        Route::post('spot-audit', [WaterLogisticsApiController::class, 'spotAudit'])->name('api.v1.spot-audit.alias');
        Route::get('fleet/driver-activity', [WaterLogisticsApiController::class, 'driverActivityTimeline'])->name('api.v1.fleet.driver-activity.alias');
        Route::get('customers/{id}/history', [WaterLogisticsApiController::class, 'customerFullHistory'])->name('api.v1.customers.history.alias');
        Route::post('operations/cafe-pos', [CafeApiController::class, 'storeOrder'])->name('api.v1.cafe-pos.alias');
        Route::post('mobile/operations/cafe-pos', [CafeApiController::class, 'storeOrder'])->name('api.v1.mobile.cafe-pos.alias');
        Route::post('cafe-orders', [CafeApiController::class, 'storeOrder'])->name('api.v1.cafe-orders.alias');
        Route::post('stock-count', [InventoryApiController::class, 'stockCount'])->middleware('company.context')->name('api.v1.stock-count.alias');
        Route::post('admin/reset-demo-data', [WaterLogisticsApiController::class, 'resetDemoDataForGolive'])->name('api.v1.admin.reset-demo-data');

        // Sales & Invoicing
        Route::prefix('sales')->group(function () {
            Route::get('/', [SaleApiController::class, 'index'])->middleware('company.context')->name('api.v1.sales.index');
            Route::post('/', [SaleApiController::class, 'store'])->middleware('company.context')->name('api.v1.sales.store');
            Route::get('{id}', [SaleApiController::class, 'show'])->middleware('company.context')->name('api.v1.sales.show');
            Route::post('{id}/payments', [SaleApiController::class, 'addPayment'])->middleware('company.context')->name('api.v1.sales.add-payment');
        });

        // Quotations & Proforma Estimates (A-14)
        Route::prefix('quotations')->middleware('company.context')->group(function () {
            Route::get('/', [SaleApiController::class, 'quotations'])->name('api.v1.quotations.index');
            Route::post('/', [SaleApiController::class, 'storeQuotation'])->name('api.v1.quotations.store');
            Route::post('{id}/convert', [SaleApiController::class, 'convertQuotation'])->name('api.v1.quotations.convert');
        });

        // Purchases & Procurement
        Route::prefix('purchases')->group(function () {
            Route::get('regular-vendors', [PurchaseApiController::class, 'regularVendors'])->middleware('company.context')->name('api.v1.purchases.regular-vendors');
            Route::post('quick', [PurchaseApiController::class, 'quickStore'])->middleware('company.context')->name('api.v1.purchases.quick');
            Route::get('/', [PurchaseApiController::class, 'index'])->middleware('company.context')->name('api.v1.purchases.index');
            Route::post('/', [PurchaseApiController::class, 'store'])->middleware('company.context')->name('api.v1.purchases.store');
            Route::get('{id}', [PurchaseApiController::class, 'show'])->middleware('company.context')->name('api.v1.purchases.show');
            Route::post('{id}/payments', [PurchaseApiController::class, 'addPayment'])->middleware('company.context')->name('api.v1.purchases.add-payment');
        });

        // Products & Catalog
        Route::prefix('products')->group(function () {
            Route::get('metadata', [ProductApiController::class, 'metadata'])->middleware('company.context')->name('api.v1.products.metadata');
            Route::get('/', [ProductApiController::class, 'index'])->middleware('company.context')->name('api.v1.products.index');
            Route::post('/', [ProductApiController::class, 'store'])->middleware('company.context')->name('api.v1.products.store');
            Route::get('search/{term}', [ProductApiController::class, 'search'])->middleware('company.context')->name('api.v1.products.search');
            Route::get('{id}', [ProductApiController::class, 'show'])->middleware('company.context')->name('api.v1.products.show');
            Route::put('{id}', [ProductApiController::class, 'update'])->middleware('company.context')->name('api.v1.products.update');
        });

        // Inventory & Warehouse Logistics
        Route::prefix('inventory')->group(function () {
            Route::get('valuation', [InventoryApiController::class, 'valuation'])->middleware('company.context')->name('api.v1.inventory.valuation');
            Route::post('transfer', [InventoryApiController::class, 'transfer'])->middleware('company.context')->name('api.v1.inventory.transfer');
            Route::post('stock-count', [InventoryApiController::class, 'stockCount'])->middleware('company.context')->name('api.v1.inventory.stock-count.direct');
        });

        // Double-Entry Accounting & Financial Ledger
        Route::prefix('accounting')->group(function () {
            Route::get('chart-of-accounts', [AccountingApiController::class, 'chartOfAccounts'])->middleware('company.context')->name('api.v1.accounting.coa');
            Route::get('trial-balance', [AccountingApiController::class, 'trialBalance'])->middleware('company.context')->name('api.v1.accounting.trial-balance');
            Route::get('profit-and-loss', [AccountingApiController::class, 'profitAndLoss'])->middleware('company.context')->name('api.v1.accounting.pnl');
            Route::get('balance-sheet', [AccountingApiController::class, 'balanceSheet'])->middleware('company.context')->name('api.v1.accounting.balance-sheet');
            Route::get('general-ledger/{id}', [AccountingApiController::class, 'generalLedger'])->middleware('company.context')->name('api.v1.accounting.gl');
            Route::post('journal-entries', [AccountingApiController::class, 'storeJournalEntry'])->middleware('company.context')->name('api.v1.accounting.journal-entry.store');
            Route::middleware('company.context')->controller(\App\Http\Controllers\Accounting\VoucherController::class)->group(function () {
                Route::post('vouchers', 'store')->name('api.v1.accounting.vouchers.store');
                Route::post('journal-entries/{id}/reverse', 'reverse')->name('api.v1.accounting.journal.reverse');
                Route::get('open-items', 'openItems')->name('api.v1.accounting.open-items');
                Route::post('allocations', 'allocate')->name('api.v1.accounting.allocations.store');
                Route::post('allocations/{id}/reverse', 'reverseAllocation')->name('api.v1.accounting.allocations.reverse');
                Route::post('period', 'period')->name('api.v1.accounting.period');
                Route::get('day-book', 'book')->defaults('type', 'day')->name('api.v1.accounting.day-book');
                Route::get('cash-book', 'book')->defaults('type', 'cash')->name('api.v1.accounting.cash-book');
                Route::get('ageing', 'ageing')->name('api.v1.accounting.ageing');
                Route::get('monthly-ledger/{id}', 'monthly')->name('api.v1.accounting.monthly-ledger');
            });
            Route::middleware('company.context')->controller(\App\Http\Controllers\Accounting\CollectionController::class)->group(function () {
                Route::get('collections', 'index')->name('api.v1.accounting.collections');
                Route::post('collections', 'store')->name('api.v1.accounting.collections.store');
                Route::put('collections/{id}', 'update')->name('api.v1.accounting.collections.update');
                Route::post('collection-preview', 'preview')->name('api.v1.accounting.collections.preview');
            });
        });

        // Partners (Customers & Suppliers)
        Route::get('customers', [PartnerApiController::class, 'customers'])->middleware('company.context')->name('api.v1.customers.index');
        Route::post('customers/{id}/credit-limit', [PartnerApiController::class, 'updateCreditLimit'])->middleware('company.context')->name('api.v1.customers.credit-limit');
        Route::get('suppliers', [PartnerApiController::class, 'suppliers'])->middleware('company.context')->name('api.v1.suppliers.index');
        Route::post('suppliers/{id}/pay', [PartnerApiController::class, 'paySupplier'])->middleware('company.context')->name('api.v1.suppliers.pay');

        // Unified Notifications & Push Tokens (G-04)
        Route::get('notifications', [WaterLogisticsApiController::class, 'notifications'])->name('api.v1.notifications.index');
        Route::post('notifications/{id}/read', [WaterLogisticsApiController::class, 'markNotificationRead'])->name('api.v1.notifications.read');
        Route::post('devices/push-token', [WaterLogisticsApiController::class, 'registerPushToken'])->name('api.v1.devices.push-token');

        // INDUSTRY ADDON: Water Logistics
        Route::prefix('water')->group(function () {
            Route::get('routes', [WaterLogisticsApiController::class, 'routes'])->name('api.v1.water.routes');
            Route::get('pickup-points', [WaterLogisticsApiController::class, 'pickupPointsIndex'])->name('api.v1.water.pickup-points.index');
            Route::post('pickup-points', [WaterLogisticsApiController::class, 'storePickupPoint'])->name('api.v1.water.pickup-points.store');
            Route::post('payments/verify-proof', [WaterLogisticsApiController::class, 'verifyWaterPaymentProof'])->name('api.v1.water.payments.verify-proof');
            Route::get('trips', [WaterLogisticsApiController::class, 'trips'])->name('api.v1.water.trips.index');
            Route::get('trips/{id}/trail', [WaterLogisticsApiController::class, 'tripTrail'])->name('api.v1.water.trips.trail');
            Route::post('trips/{id}/process', [WaterLogisticsApiController::class, 'processTripOrder'])->name('api.v1.water.trips.process');
            Route::post('trip-sheets', [WaterLogisticsApiController::class, 'storeTripSheet'])->name('api.v1.water.trip-sheets');
            Route::get('can-orders', [WaterLogisticsApiController::class, 'canOrders'])->name('api.v1.water.can-orders.index');
            Route::post('can-orders', [WaterLogisticsApiController::class, 'storeCanOrder'])->name('api.v1.water.can-orders.store');
            Route::match(['put', 'patch'], 'can-orders/{id}', [WaterLogisticsApiController::class, 'updateCanOrder'])->name('api.v1.water.can-orders.update');
            Route::post('can-orders/{id}/adjust', [WaterLogisticsApiController::class, 'updateCanOrder'])->name('api.v1.water.can-orders.adjust');
            Route::post('can-orders/{id}/start', [WaterLogisticsApiController::class, 'startCanOrder'])->name('api.v1.water.can-orders.start');
            Route::post('can-orders/{id}/close', [WaterLogisticsApiController::class, 'closeCanOrder'])->name('api.v1.water.can-orders.close');
            Route::post('can-orders/{id}/cancel', [WaterLogisticsApiController::class, 'cancelCanOrder'])->name('api.v1.water.can-orders.cancel');
            Route::get('tanker-orders', [WaterLogisticsApiController::class, 'tankerOrders'])->name('api.v1.water.tanker-orders.index');
            Route::post('tanker-orders', [WaterLogisticsApiController::class, 'storeTankerOrder'])->name('api.v1.water.tanker-orders.store');
            Route::match(['put', 'patch'], 'tanker-orders/{id}', [WaterLogisticsApiController::class, 'updateTankerOrder'])->name('api.v1.water.tanker-orders.update');
            Route::post('tanker-orders/{id}/adjust', [WaterLogisticsApiController::class, 'updateTankerOrder'])->name('api.v1.water.tanker-orders.adjust');
            Route::post('tanker-orders/{id}/cancel', [WaterLogisticsApiController::class, 'cancelTankerOrder'])->name('api.v1.water.tanker-orders.cancel');
            Route::get('schedules', [WaterLogisticsApiController::class, 'schedulesIndex'])->name('api.v1.water.schedules.index');
            Route::post('schedules', [WaterLogisticsApiController::class, 'storeSchedule'])->name('api.v1.water.schedules.store');
            Route::match(['put', 'patch'], 'schedules/{id}', [WaterLogisticsApiController::class, 'updateSchedule'])->name('api.v1.water.schedules.update');
            Route::post('schedules/{id}/toggle', [WaterLogisticsApiController::class, 'toggleSchedule'])->name('api.v1.water.schedules.toggle');
            Route::post('schedules/{id}/skip', [WaterLogisticsApiController::class, 'skipSchedule'])->name('api.v1.water.schedules.skip');
            Route::post('schedules/{id}/generate-now', [WaterLogisticsApiController::class, 'generateScheduleNow'])->name('api.v1.water.schedules.generate-now');
            Route::post('schedules/generate-due', [WaterLogisticsApiController::class, 'generateDueSchedules'])->name('api.v1.water.schedules.generate-due');
            Route::post('can-deliveries', [WaterLogisticsApiController::class, 'storeCanDelivery'])->name('api.v1.water.can-deliveries');
            Route::post('plant-intakes', [WaterLogisticsApiController::class, 'storePlantIntake'])->name('api.v1.water.plant-intakes');
            Route::post('driver-surrender', [WaterLogisticsApiController::class, 'driverCashSurrender'])->name('api.v1.water.driver-surrender');
        });

        // INDUSTRY ADDON: Bakery & Cafe POS
        Route::prefix('cafe')->group(function () {
            Route::get('menu', [CafeApiController::class, 'menu'])->name('api.v1.cafe.menu');
            Route::post('orders', [CafeApiController::class, 'storeOrder'])->name('api.v1.cafe.orders');
            Route::post('cafe-orders', [CafeApiController::class, 'storeOrder'])->name('api.v1.cafe.cafe-orders');
            Route::post('drawer-reconcile', [CafeApiController::class, 'reconcileDrawer'])->name('api.v1.cafe.drawer-reconcile');
        });

        // ERP POINT OF SALE (Shifts X/Z, Tables, Held Drafts, Split Payments, Returns, KDS, Kitchen Ops, Thermal Print)
        Route::prefix('pos')->middleware('company.context')->group(function () {
            Route::get('bootstrap', [\App\Http\Controllers\Api\V1\PosApiController::class, 'bootstrap'])->name('api.v1.pos.bootstrap');
            Route::get('tables', [\App\Http\Controllers\Api\V1\PosApiController::class, 'tables'])->name('api.v1.pos.tables');
            Route::get('shifts/current', [\App\Http\Controllers\Api\V1\PosApiController::class, 'currentShift'])->name('api.v1.pos.shifts.current');
            Route::post('shifts/open', [\App\Http\Controllers\Api\V1\PosApiController::class, 'openShift'])->name('api.v1.pos.shifts.open');
            Route::post('shifts/close', [\App\Http\Controllers\Api\V1\PosApiController::class, 'closeShift'])->name('api.v1.pos.shifts.close');
            Route::get('orders', [\App\Http\Controllers\Api\V1\PosApiController::class, 'orders'])->name('api.v1.pos.orders.index');
            Route::post('orders', [\App\Http\Controllers\Api\V1\PosApiController::class, 'storeOrder'])->name('api.v1.pos.orders.store');
            Route::get('orders/{id}', [\App\Http\Controllers\Api\V1\PosApiController::class, 'showOrder'])->name('api.v1.pos.orders.show');
            Route::post('orders/{id}/resume', [\App\Http\Controllers\Api\V1\PosApiController::class, 'resumeHeldOrder'])->name('api.v1.pos.orders.resume');
            Route::delete('orders/{id}/held', [\App\Http\Controllers\Api\V1\PosApiController::class, 'cancelHeldOrder'])->name('api.v1.pos.orders.cancel-held');
            Route::post('orders/{id}/refund', [\App\Http\Controllers\Api\V1\PosApiController::class, 'refundOrder'])->name('api.v1.pos.orders.refund');
            Route::post('orders/{id}/print-job', [\App\Http\Controllers\Api\V1\PosApiController::class, 'printOrderJob'])->name('api.v1.pos.orders.print-job');
            Route::get('kds', [\App\Http\Controllers\Api\V1\PosApiController::class, 'kds'])->name('api.v1.pos.kds.index');
            Route::post('kds/{id}/status', [\App\Http\Controllers\Api\V1\PosApiController::class, 'updateKdsStatus'])->name('api.v1.pos.kds.status');
            Route::patch('products/{id}/availability', [\App\Http\Controllers\Api\V1\PosApiController::class, 'toggleProductAvailability'])->name('api.v1.pos.products.availability');
            Route::post('production-batches', [\App\Http\Controllers\Api\V1\PosApiController::class, 'storeProductionBatch'])->name('api.v1.pos.production-batches.store');
            Route::post('wastage', [\App\Http\Controllers\Api\V1\PosApiController::class, 'storeWastage'])->name('api.v1.pos.wastage.store');
            Route::get('reorder-requests', [\App\Http\Controllers\Api\V1\PosApiController::class, 'reorderRequests'])->name('api.v1.pos.reorder-requests.index');
            Route::post('reorder-requests', [\App\Http\Controllers\Api\V1\PosApiController::class, 'storeReorderRequest'])->name('api.v1.pos.reorder-requests.store');
        });

        // INDUSTRY ADDON: Repair & RMA Service Center
        Route::prefix('repair')->group(function () {
            Route::get('jobs', [RepairApiController::class, 'jobs'])->name('api.v1.repair.jobs');
            Route::post('jobs', [RepairApiController::class, 'storeJob'])->name('api.v1.repair.store-job');
            Route::put('jobs/{id}/status', [RepairApiController::class, 'updateStatus'])->name('api.v1.repair.update-status');
        });

        // Expenses & Operational Outflows
        Route::prefix('expenses')->group(function () {
            Route::get('/', [ExpenseApiController::class, 'index'])->name('api.v1.expenses.index');
            Route::post('/', [ExpenseApiController::class, 'store'])->name('api.v1.expenses.store');
            Route::post('batch', [ExpenseApiController::class, 'storeBatch'])->name('api.v1.expenses.batch');
            Route::get('accounts-summary', [ExpenseApiController::class, 'accountsSummary'])->name('api.v1.expenses.accounts-summary');
            Route::get('categories', [ExpenseApiController::class, 'categories'])->name('api.v1.expenses.categories');
        });

        // Organization & HRM (Attendance & Leaves)
        Route::prefix('hrm')->group(function () {
            Route::get('attendance/status', [HrmApiController::class, 'status'])->name('api.v1.hrm.attendance.status');
            Route::post('attendance/check-in', [HrmApiController::class, 'checkIn'])->name('api.v1.hrm.check-in');
            Route::post('attendance/check-out', [HrmApiController::class, 'checkOut'])->name('api.v1.hrm.check-out');
            Route::get('leaves', [HrmApiController::class, 'leaves'])->name('api.v1.hrm.leaves');
            Route::post('leaves', [HrmApiController::class, 'applyLeave'])->name('api.v1.hrm.apply-leave');
            Route::post('leaves/{id}/approve', [HrmApiController::class, 'approveLeave'])->name('api.v1.hrm.leaves.approve');
            Route::post('leaves/{id}/reject', [HrmApiController::class, 'rejectLeave'])->name('api.v1.hrm.leaves.reject');
            Route::get('leave-types', [HrmApiController::class, 'leaveTypes'])->name('api.v1.hrm.leave-types');
        });

        // Mobile Analytics & Reporting
        Route::prefix('reports')->group(function () {
            Route::get('sales', [ReportApiController::class, 'sales'])->name('api.v1.reports.sales');
            Route::get('purchases', [ReportApiController::class, 'purchases'])->name('api.v1.reports.purchases');
            Route::get('stock', [ReportApiController::class, 'stock'])->name('api.v1.reports.stock');
            Route::get('customers/{id}/ledger', [ReportApiController::class, 'customerLedger'])->name('api.v1.reports.customer-ledger');
        });
    });
});

require __DIR__.'/compliance_api.php';
