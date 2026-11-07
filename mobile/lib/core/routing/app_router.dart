import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/accounting/presentation/accounting_books_screen.dart';
import '../../features/accounting/presentation/payment_collection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/role_dashboard_dispatcher.dart';
import '../../features/expenses/presentation/quick_expense_screen.dart';
import '../../features/hrm/presentation/attendance_screen.dart';
import '../../features/inventory/presentation/stock_count_screen.dart';
import '../../features/inventory/presentation/stock_overview_screen.dart';
import '../../features/modules/presentation/module_launcher_screen.dart';
import '../../features/operations/presentation/cafe_pos_screen.dart';
import '../../features/operations/presentation/can_sales_screen.dart';
import '../../features/operations/presentation/driver_surrender_screen.dart';
import '../../features/operations/presentation/plant_refill_screen.dart';
import '../../features/operations/presentation/spot_audit_screen.dart';
import '../../features/operations/presentation/tanker_trip_screen.dart';
import '../../features/products/presentation/product_form_screen.dart';
import '../../features/products/presentation/products_catalog_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/purchases/presentation/purchase_bills_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/sales/presentation/new_sale_bill_screen.dart';
import '../../features/sales/presentation/sales_invoices_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/workspace/presentation/workspace_screen.dart';
import '../../screens/fleet_gps_screen.dart';
import '../providers.dart';
import '../ui/app_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: refreshNotifier,
    initialLocation: '/workspace',
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isLoggingIn = state.uri.path == '/login';
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      final user = authState.user;
      final role = (user?.role ?? '').toLowerCase();
      final username = (user?.username ?? user?.name ?? '').toLowerCase();
      final isStaffOrDriver = role == 'tankerdriver' ||
          role == 'deliverydriver' ||
          role == 'driver' ||
          role == 'cashier' ||
          role == 'fieldagent' ||
          role == 'agent' ||
          username == 'tanker_driver' ||
          username == 'driver' ||
          username == 'cashier' ||
          username == 'agent';

      if (isLoggingIn) {
        return (isStaffOrDriver || authState.companies.length <= 1) ? '/home' : '/workspace';
      }

      if (state.uri.path == '/workspace' && (isStaffOrDriver || authState.companies.length <= 1)) {
        return '/home';
      }

      // Restrict executive financial ledgers and purchase books from field staff and drivers
      final path = state.uri.path;
      if (isStaffOrDriver) {
        if (path.startsWith('/accounting/books') && role != 'cashier' && username != 'cashier') {
          return '/home';
        }
        if (path.startsWith('/reports') ||
            path.startsWith('/purchases') ||
            path.startsWith('/products')) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/workspace',
        builder: (context, state) => const WorkspaceScreen(),
      ),

      // 5-Slot Bottom Bar Shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          int index = 0;
          final location = state.uri.path;
          if (location.startsWith('/home')) {
            index = 0;
          } else if (location.startsWith('/tasks')) {
            index = 1;
          } else if (location.startsWith('/modules')) {
            index = 3;
          } else if (location.startsWith('/profile')) {
            index = 4;
          }
          return AppScaffold(
            currentIndex: index,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const RoleDashboardDispatcher(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/modules',
            builder: (context, state) => const ModuleLauncherScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Functional Sub-screens
      GoRoute(
        path: '/sales',
        builder: (context, state) => const SalesInvoicesScreen(),
      ),
      GoRoute(
        path: '/sales/new',
        builder: (context, state) => const NewSaleBillScreen(),
      ),
      GoRoute(
        path: '/purchases',
        builder: (context, state) => const PurchaseBillsScreen(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const StockOverviewScreen(),
      ),
      GoRoute(
        path: '/inventory/stock-count',
        builder: (context, state) => const StockCountScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsCatalogScreen(),
      ),
      GoRoute(
        path: '/products/new',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/accounting/books',
        builder: (context, state) => const AccountingBooksScreen(),
      ),
      GoRoute(
        path: '/accounting/collect',
        builder: (context, state) => const PaymentCollectionScreen(),
      ),
      GoRoute(
        path: '/expenses/new',
        builder: (context, state) => const QuickExpenseScreen(),
      ),
      GoRoute(
        path: '/hrm/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),

      // Operations Workflows
      GoRoute(
        path: '/operations/can-sales',
        builder: (context, state) => const CanSalesScreen(),
      ),
      GoRoute(
        path: '/operations/plant-refill',
        builder: (context, state) => const PlantRefillScreen(),
      ),
      GoRoute(
        path: '/operations/tanker-trip',
        builder: (context, state) => const TankerTripScreen(),
      ),
      GoRoute(
        path: '/operations/spot-audit',
        builder: (context, state) => const SpotAuditScreen(),
      ),
      GoRoute(
        path: '/operations/driver-surrender',
        builder: (context, state) => const DriverSurrenderScreen(),
      ),
      GoRoute(
        path: '/operations/cafe-pos',
        builder: (context, state) => const CafePosScreen(),
      ),
      GoRoute(
        path: '/fleet/gps',
        builder: (context, state) {
          final modeStr = state.uri.queryParameters['mode'];
          final initialMode = modeStr == 'packaged_water'
              ? FleetViewMode.packagedWater
              : FleetViewMode.tankers;
          final isTamil = ref.watch(localeProvider).languageCode == 'ta';
          return FleetGpsScreen(
            isTamil: isTamil,
            initialMode: initialMode,
            lockMode: true,
          );
        },
      ),
    ],
  );
});

