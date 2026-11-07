/// Centralized API Endpoint catalog for Zolo ERP Mobile.
abstract final class ApiEndpoints {
  static const String defaultBaseUrl = 'https://dkenterprises.animazon.in/api/v1';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  // Authentication & Identity
  static const String login = '/mobile/login';
  static const String me = '/me';

  // Core Financials & Dashboards
  static const String financials = '/financials';
  static String roleDashboard(String role) => '/mobile/dashboard/$role';

  // Parties & Master Data
  static const String customers = '/customers';
  static const String customerOnboard = '/customer-onboard';
  static const String suppliers = '/suppliers';
  static const String products = '/products';

  // Sales & Invoices
  static const String sales = '/sales';
  static const String invoices = '/invoices';
  static const String quotations = '/quotations';
  static const String collectPayment = '/collect-payment';

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
  static const String spotAudit = '/spot-audit';
  static const String driverCashSurrender = '/driver-surrender';
  static const String tankerTrips = '/trip-sheets';

  // Cafe & POS
  static const String cafeMenu = '/cafe/menu';
  static const String cafeOrders = '/cafe/orders';
  static const String cafeDrawerReconcile = '/cafe/drawer-reconcile';
}

