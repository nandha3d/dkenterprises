/// Centralized API Endpoint catalog for Zolo ERP Mobile.
abstract final class ApiEndpoints {
  static const String defaultBaseUrl = 'https://dkenterprises.animazon.in/api/v1';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  // Health & Ping (Public)
  static const String ping = '/health';
  static const String bootstrap = '/mobile/bootstrap';

  // Authentication & Identity
  static const String login = '/mobile/login';
  static const String me = '/me';

  // Core Financials & Dashboards
  static const String financials = '/mobile/financials';
  static String roleDashboard(String role) => '/mobile/dashboard/$role';

  // Parties & Master Data
  static const String customers = '/mobile/customers';
  static const String customerOnboard = '/mobile/customer-onboard';
  static const String suppliers = '/suppliers';
  static const String products = '/mobile/products';

  // Sales & Invoices
  static const String sales = '/sales';
  static const String invoices = '/mobile/invoices';
  static const String quotations = '/quotations';
  static const String collectPayment = '/mobile/collect-payment';

  // Purchases
  static const String purchases = '/purchases';

  // Expenses & Income
  static const String expenses = '/expenses';
  static const String expenseCategories = '/expenses/categories';

  // HRM & Attendance
  static const String checkIn = '/hrm/attendance/check-in';
  static const String checkOut = '/hrm/attendance/check-out';
  static const String leaves = '/hrm/leaves';
  static const String leaveTypes = '/hrm/leave-types';

  // Reports
  static const String reportSales = '/reports/sales';
  static const String reportPurchases = '/reports/purchases';
  static const String reportStock = '/reports/stock';
  static String customerLedger(int id) => '/reports/customers/$id/ledger';

  // Field Operations (Packaged Water & Bulk Tankers)
  static const String waterCanRoutes = '/routes';
  static const String waterCanDeliveries = '/can-deliveries';
  static const String plantIntakes = '/plant-intakes';
  static const String spotAudit = '/mobile/spot-audit';
  static const String driverCashSurrender = '/mobile/driver-surrender';
  static const String tankerTrips = '/trip-sheets';

  // Cafe & POS
  static const String cafeMenu = '/cafe/menu';
  static const String cafeOrders = '/cafe/orders';
  static const String cafeDrawerReconcile = '/cafe/drawer-reconcile';
}

