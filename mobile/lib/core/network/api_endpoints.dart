/// Centralized API Endpoint catalog for DK Enterprises ERP Mobile.
abstract final class ApiEndpoints {
  static const String defaultBaseUrl = 'http://dk-track.test/api/v1';
  static const String cloudBaseUrl = 'https://dkenterprises.animazon.in/api/v1';

  static const List<String> fallbackBaseUrls = [
    'http://dk-track.test/api/v1',
    'https://dk-track.test/api/v1',
    'http://127.0.0.1:8000/api/v1',
    'http://localhost:8000/api/v1',
    'https://dkenterprises.animazon.in/api/v1',
  ];

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  // Health & Ping (Public)
  static const String ping = '/health';
  static const String bootstrap = '/mobile/bootstrap';

  // Authentication & Identity
  static const String login = '/mobile/login';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String me = '/me';
  static const String companies = '/companies';

  // Core Financials & Dashboards
  static const String workspace = '/mobile/workspace';
  static const String financials = '/mobile/financials';
  static String roleDashboard(String role) => '/mobile/dashboard/$role';

  // Parties & Master Data
  static const String customers = '/mobile/customers';
  static const String customersDirectory = '/customers';
  static const String customerOnboard = '/mobile/customer-onboard';
  static String customerLocation(int id) => '/mobile/customers/$id/location';
  static String customerCreditLimit(int id) => '/customers/$id/credit-limit';
  static const String suppliers = '/suppliers';
  static String supplierPay(int id) => '/suppliers/$id/pay';
  static const String products = '/mobile/products';
  static const String productMetadata = '/products/metadata';
  static const String productCatalog = '/products';
  static String productDetail(int id) => '/products/$id';

  // Sales, Quotations & Invoices
  static const String sales = '/sales';
  static String saleDetail(int id) => '/sales/$id';
  static String salePayment(int id) => '/sales/$id/payments';
  static const String quotations = '/quotations';
  static String quotationConvert(int id) => '/quotations/$id/convert';
  static const String invoices = '/mobile/invoices';
  static const String collectPayment = '/mobile/collect-payment';

  // Purchases
  static const String purchases = '/purchases';
  static const String purchasesQuick = '/purchases/quick';
  static const String purchasesRegularVendors = '/purchases/regular-vendors';
  static String purchaseDetail(int id) => '/purchases/$id';
  static String purchasePayment(int id) => '/purchases/$id/payments';

  // Inventory
  static const String inventoryValuation = '/inventory/valuation';
  static const String inventoryStockCount = '/inventory/stock-count';
  static const String inventoryTransfer = '/inventory/transfer';

  // Accounting & Reports
  static const String accountingTrialBalance = '/accounting/trial-balance';
  static const String accountingProfitAndLoss = '/accounting/profit-and-loss';
  static const String accountingBalanceSheet = '/accounting/balance-sheet';
  static const String accountingAgeing = '/accounting/ageing';
  static const String accountingDayBook = '/accounting/day-book';
  static const String accountingCashBook = '/accounting/cash-book';
  static const String accountingCoa = '/accounting/chart-of-accounts';
  static const String reportSales = '/reports/sales';
  static const String reportPurchases = '/reports/purchases';
  static const String reportStock = '/reports/stock';
  static String customerLedger(int id) => '/reports/customers/$id/ledger';

  // Expenses & Income
  static const String expenses = '/expenses';
  static const String expensesBatch = '/expenses/batch';
  static const String expensesAccountsSummary = '/expenses/accounts-summary';
  static const String expenseCategories = '/expenses/categories';
  static const String adminResetDemoData = '/admin/reset-demo-data';

  // HRM & Attendance
  static const String attendanceStatus = '/hrm/attendance/status';
  static const String checkIn = '/hrm/attendance/check-in';
  static const String checkOut = '/hrm/attendance/check-out';
  static const String leaves = '/hrm/leaves';
  static String leaveApprove(int id) => '/hrm/leaves/$id/approve';
  static String leaveReject(int id) => '/hrm/leaves/$id/reject';
  static const String leaveTypes = '/hrm/leave-types';

  // Repair Jobs
  static const String repairJobs = '/repair/jobs';
  static String repairJobStatus(int id) => '/repair/jobs/$id/status';

  // Field Operations (Packaged Water & Bulk Tankers)
  static const String driverManifest = '/mobile/driver/manifest';
  static const String waterCanRoutes = '/water/routes';
  static const String waterPickupPoints = '/water/pickup-points';
  static const String waterVerifyPaymentProof = '/water/payments/verify-proof';
  static const String waterCanOrders = '/water/can-orders';
  static String waterCanOrderAdjust(int id) => '/water/can-orders/$id/adjust';
  static String waterCanOrderStart(int id) => '/water/can-orders/$id/start';
  static String waterCanOrderClose(int id) => '/water/can-orders/$id/close';
  static String waterCanOrderCancel(int id) => '/water/can-orders/$id/cancel';
  static const String waterTankerOrders = '/water/tanker-orders';
  static String waterTankerOrderAdjust(int id) => '/water/tanker-orders/$id/adjust';
  static String waterTankerOrderCancel(int id) => '/water/tanker-orders/$id/cancel';
  static const String waterSchedules = '/water/schedules';
  static String waterScheduleDetail(int id) => '/water/schedules/$id';
  static String waterScheduleToggle(int id) => '/water/schedules/$id/toggle';
  static String waterScheduleSkip(int id) => '/water/schedules/$id/skip';
  static String waterScheduleGenerateNow(int id) => '/water/schedules/$id/generate-now';
  static const String waterSchedulesGenerateDue = '/water/schedules/generate-due';
  static const String waterCanDeliveries = '/water/can-deliveries';
  static const String plantIntakes = '/water/plant-intakes';
  static const String spotAudit = '/mobile/spot-audit';
  static const String driverCashSurrender = '/water/driver-surrender';
  static const String tankerTrips = '/water/trip-sheets';
  static String tankerTripProcess(int tripId) => '/water/trips/$tripId/process';
  static const String waterTrips = '/water/trips';
  static String waterTripTrail(int id) => '/water/trips/$id/trail';

  // ERP POS Module (Connected directly to CashRegister, Sale, Returns, Inventory, Accounting)
  static const String posBootstrap = '/pos/bootstrap';
  static const String posTables = '/pos/tables';
  static const String posCurrentShift = '/pos/shifts/current';
  static const String posOpenShift = '/pos/shifts/open';
  static const String posCloseShift = '/pos/shifts/close';
  static const String posOrders = '/pos/orders';
  static String posOrderDetail(int id) => '/pos/orders/$id';
  static String posResumeOrder(int id) => '/pos/orders/$id/resume';
  static String posCancelHeldOrder(int id) => '/pos/orders/$id/held';
  static String posRefundOrder(int id) => '/pos/orders/$id/refund';
  static String posOrderPrintJob(int id) => '/pos/orders/$id/print-job';
  static const String posKds = '/pos/kds';
  static String posKdsStatus(int id) => '/pos/kds/$id/status';
  static String posProductAvailability(int id) =>
      '/pos/products/$id/availability';
  static const String posProductionBatches = '/pos/production-batches';
  static const String posWastage = '/pos/wastage';
  static const String posReorderRequests = '/pos/reorder-requests';

  // Notifications & Push Devices
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const String devicePushToken = '/devices/push-token';

  // Offline Cafe Outbox Fallback (Used only when offline for rapid counter checkouts)
  static const String cafeMenu = '/cafe/menu';
  static const String cafeOrders = '/cafe/orders';
  static const String cafeDrawerReconcile = '/cafe/drawer-reconcile';

  // Fleet Telematics & GPS
  static const String fleetLive = '/mobile/fleet/live';
  static const String fleetDriverActivity = '/mobile/fleet/driver-activity';
  static const String fleetPing = '/mobile/fleet/ping';
  static String customerHistory(int id) => '/mobile/customers/$id/history';
}
