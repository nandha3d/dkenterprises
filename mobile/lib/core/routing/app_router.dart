import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/accounting/presentation/accounting_books_screen.dart';
import '../../features/accounting/presentation/payment_collection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/customers/presentation/customer_form_screen.dart';
import '../../features/dashboard/presentation/admin_hubs.dart';
import '../../features/dashboard/presentation/can_delivery_driver_dashboard_screen.dart';
import '../../features/dashboard/presentation/role_dashboard_dispatcher.dart';
import '../../features/dashboard/presentation/tanker_driver_dashboard_screen.dart';
import '../../features/expenses/presentation/quick_expense_screen.dart';
import '../../features/hrm/presentation/attendance_screen.dart';
import '../../features/inventory/presentation/stock_count_screen.dart';
import '../../features/inventory/presentation/stock_overview_screen.dart';
import '../../features/modules/presentation/module_launcher_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/operations/presentation/cafe_pos_screen.dart';
import '../../features/operations/presentation/can_order_screen.dart';
import '../../features/operations/presentation/can_sales_screen.dart';
import '../../features/operations/presentation/delivery_schedules_screen.dart';
import '../../features/operations/presentation/driver_surrender_screen.dart';
import '../../features/operations/presentation/plant_refill_screen.dart';
import '../../features/operations/presentation/quick_purchase_screen.dart';
import '../../features/operations/presentation/spot_audit_screen.dart';
import '../../features/operations/presentation/tanker_trip_screen.dart';
import '../../features/pos/presentation/pos_drawer_screen.dart';
import '../../features/pos/presentation/pos_kitchen_screen.dart';
import '../../features/pos/presentation/pos_orders_screen.dart';
import '../../features/products/presentation/product_form_screen.dart';
import '../../features/products/presentation/products_catalog_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/purchases/presentation/purchase_bills_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/sales/presentation/new_sale_bill_screen.dart';
import '../../features/sales/presentation/sales_invoices_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/workspace/presentation/workspace_screen.dart';
import '../../screens/customers_screen.dart';
import '../../screens/fleet_gps_screen.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import '../ui/app_scaffold.dart';
import 'role_navigation.dart';

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

      final rippleRole = resolveRippleRole(
        role: authState.user?.role,
        username: authState.user?.username,
        email: authState.user?.email,
        roles: authState.roles,
      );
      final isStaffOrDriver = rippleRole != RippleRole.admin;

      if (isLoggingIn) {
        return isStaffOrDriver ? '/home' : '/workspace';
      }

      if (state.uri.path == '/workspace' && isStaffOrDriver) {
        return '/home';
      }

      final path = state.uri.path;
      if (isStaffOrDriver) {
        if (path.startsWith('/accounting/books') && rippleRole != RippleRole.cafe) {
          return '/home';
        }
        if (path.startsWith('/reports') ||
            path.startsWith('/purchases') ||
            path.startsWith('/products') ||
            path.startsWith('/trade') ||
            path.startsWith('/money') ||
            path.startsWith('/modules')) {
          return '/home';
        }

        final driverFlavor = resolveDriverFlavor(
          role: authState.user?.role,
          username: authState.user?.username,
          email: authState.user?.email,
          roles: authState.roles,
        );
        final activeIndustry = (authState.activeCompany?.industry ?? '').toLowerCase();

        if (rippleRole == RippleRole.driver) {
          if (path.startsWith('/pos') ||
              path.startsWith('/operations/cafe-pos') ||
              path.startsWith('/erp/pos-drawer') ||
              path.startsWith('/tab/customers') ||
              path.startsWith('/tab/spend')) {
            return '/home';
          }
          if (driverFlavor == RippleDriverFlavor.tanker) {
            if (path.startsWith('/operations/can-order') ||
                path.startsWith('/operations/can-sales') ||
                path.startsWith('/operations/plant-refill') ||
                path.startsWith('/operations/driver-manifest') ||
                (path.startsWith('/fleet/gps') &&
                    state.uri.queryParameters['mode'] == 'packaged_water')) {
              return '/home';
            }
          } else {
            if (path.startsWith('/operations/tanker-trip') ||
                path.startsWith('/operations/tanker-dashboard') ||
                (path.startsWith('/fleet/gps') &&
                    state.uri.queryParameters['mode'] == 'bulk_water')) {
              return '/home';
            }
          }
        } else if (rippleRole == RippleRole.cafe) {
          if (path.startsWith('/operations/can-order') ||
              path.startsWith('/operations/can-sales') ||
              path.startsWith('/operations/schedules') ||
              path.startsWith('/operations/plant-refill') ||
              path.startsWith('/operations/tanker-trip') ||
              path.startsWith('/operations/tanker-dashboard') ||
              path.startsWith('/operations/driver-surrender') ||
              path.startsWith('/operations/driver-manifest') ||
              path.startsWith('/water/') ||
              path.startsWith('/tab/driver-cash') ||
              path.startsWith('/tab/customers') ||
              path.startsWith('/tab/spend') ||
              path.startsWith('/fleet/gps')) {
            return '/home';
          }
        } else if (rippleRole == RippleRole.fieldAgent) {
          if (activeIndustry != 'cafe_bakery' &&
              (path.startsWith('/pos') ||
                  path.startsWith('/operations/cafe-pos') ||
                  path.startsWith('/erp/pos-drawer'))) {
            return '/home';
          }
          if (activeIndustry == 'bulk_water' &&
              (path.startsWith('/operations/can-order') ||
                  path.startsWith('/operations/can-sales') ||
                  path.startsWith('/operations/plant-refill'))) {
            return '/home';
          }
          if (activeIndustry == 'packaged_water' &&
              (path.startsWith('/operations/tanker-trip') ||
                  path.startsWith('/operations/tanker-dashboard'))) {
            return '/home';
          }
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

      // Role-Adaptive Fluid Curved Navigation Shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          final rippleRole = ref.watch(activeRippleRoleProvider);
          final index = navIndexForLocation(rippleRole, state.uri.path);
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
          // Admin role tabs
          GoRoute(
            path: '/trade',
            builder: (context, state) => const TradeHubScreen(),
          ),
          GoRoute(
            path: '/money',
            builder: (context, state) => const MoneyHubScreen(),
          ),
          GoRoute(
            path: '/modules',
            builder: (context, state) => const ModuleLauncherScreen(),
          ),
          // Driver role tabs
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/tab/driver-cash',
            builder: (context, state) => const DriverSurrenderScreen(embedded: true),
          ),
          // Cafe / Cashier role tabs
          GoRoute(
            path: '/pos/orders',
            builder: (context, state) => const PosOrdersScreen(),
          ),
          GoRoute(
            path: '/pos/drawer',
            builder: (context, state) => const PosDrawerScreen(),
          ),
          GoRoute(
            path: '/pos/kitchen',
            builder: (context, state) => const PosKitchenScreen(),
          ),
          // Field Agent role tabs
          GoRoute(
            path: '/tab/customers',
            builder: (context, state) => const CustomersScreen(isTamil: false, embedded: true),
          ),
          GoRoute(
            path: '/tab/spend',
            builder: (context, state) => const QuickExpenseScreen(embedded: true),
          ),
          // Shared Me / Profile tab
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Shared Notifications Center
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Functional Sub-screens
      GoRoute(
        path: '/account/profile',
        builder: (context, state) => const ProfileScreen(embedded: false),
      ),
      GoRoute(
        path: '/erp/pos-drawer',
        builder: (context, state) => const PosDrawerScreen(embedded: false),
      ),
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
        path: '/customers',
        builder: (context, state) => const CustomersScreen(isTamil: false),
      ),
      GoRoute(
        path: '/customers/new',
        builder: (context, state) => const CustomerFormScreen(),
      ),
      GoRoute(
        path: '/customers/onboard',
        builder: (context, state) => const CustomerFormScreen(),
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
        path: '/operations/can-order',
        builder: (context, state) {
          final extraMap = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : (state.extra is Map ? Map<String, dynamic>.from(state.extra as Map) : null);
          return CanOrderScreen(
            initialCustomerId: int.tryParse((extraMap?['customer_id'] ?? '').toString()),
            initialOrderedCans: int.tryParse((extraMap?['ordered_cans'] ?? '').toString()),
          );
        },
      ),
      GoRoute(
        path: '/operations/schedules',
        builder: (context, state) {
          final v = state.uri.queryParameters['vertical'];
          return DeliverySchedulesScreen(initialVerticalType: v);
        },
      ),
      GoRoute(
        path: '/operations/can-sales',
        builder: (context, state) => CanSalesScreen(
          initialOrder: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : (state.extra is Map ? Map<String, dynamic>.from(state.extra as Map) : null),
        ),
      ),
      GoRoute(
        path: '/operations/plant-refill',
        builder: (context, state) => const PlantRefillScreen(),
      ),
      GoRoute(
        path: '/operations/tanker-trip',
        builder: (context, state) => TankerTripScreen(
          initialTrip: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : (state.extra is Map ? Map<String, dynamic>.from(state.extra as Map) : null),
        ),
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
        path: '/water/driver-surrender',
        builder: (context, state) => const DriverSurrenderScreen(),
      ),
      GoRoute(
        path: '/operations/driver-manifest',
        builder: (context, state) => const CanDeliveryDriverDashboardScreen(),
      ),
      GoRoute(
        path: '/operations/tanker-dashboard',
        builder: (context, state) => const TankerDriverDashboardScreen(),
      ),
      GoRoute(
        path: '/operations/cafe-pos',
        builder: (context, state) => const CafePosScreen(),
      ),
      GoRoute(
        path: '/operations/quick-purchase',
        builder: (context, state) => const QuickPurchaseScreen(),
      ),
      GoRoute(
        path: '/fleet/gps',
        builder: (context, state) {
          final modeStr = state.uri.queryParameters['mode'];
          final initialMode = modeStr == 'packaged_water'
              ? FleetViewMode.packagedWater
              : FleetViewMode.tankers;
          return FleetGpsScreen(
            isTamil: false,
            initialMode: initialMode,
            lockMode: true,
          );
        },
      ),
    ],
  );
});
