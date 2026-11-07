import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/accounting/presentation/accounting_books_screen.dart';
import '../../features/accounting/presentation/payment_collection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/executive_dashboard_screen.dart';
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
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/purchases/presentation/purchase_bills_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/sales/presentation/new_sale_bill_screen.dart';
import '../../features/sales/presentation/sales_invoices_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../providers.dart';
import '../ui/app_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggingIn = state.uri.path == '/login';
      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }
      if (isLoggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
            builder: (context, state) => const ExecutiveDashboardScreen(),
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
    ],
  );
});

