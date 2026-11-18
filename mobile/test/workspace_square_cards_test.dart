import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/features/auth/data/auth_repository.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';
import 'package:dk_track_mobile/features/dashboard/presentation/executive_dashboard_screen.dart';
import 'package:dk_track_mobile/features/workspace/presentation/workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) async {
    if (path.contains('fleet/live')) {
      final mockFleet = {
        'status': 'success',
        'data': {
          'customers': [
            {
              'id': 101,
              'name': 'Meenakshi Hotel',
              'address': 'West Tower Street, Madurai',
              'latitude': 9.9195,
              'longitude': 78.1193,
              'geofence_radius': 150,
              'total_sales': 18500.0,
              'total_paid': 12500.0,
              'due_amount': 6000.0,
              'overdue_amount': 0.0,
              'payment_status': 'due',
            },
            {
              'id': 102,
              'name': 'Sri Murugan Mess',
              'address': 'KK Nagar Main Road, Madurai',
              'latitude': 9.9320,
              'longitude': 78.1445,
              'geofence_radius': 180,
              'total_sales': 9000.0,
              'total_paid': 9000.0,
              'due_amount': 0.0,
              'overdue_amount': 0.0,
              'payment_status': 'paid',
            },
          ],
          'tankers': [
            {
              'id': 1,
              'vehicle_number': 'TN-58-BW-2001',
              'model_type': 'Tata LPT 2518 (20KL Dual Chamber)',
              'capacity_liters': 20000,
              'driver_name': 'K. Murugan',
              'driver_phone': '9842100001',
              'latitude': 9.9245,
              'longitude': 78.1302,
              'current_speed': 34,
            },
          ],
          'can_routes': [
            {
              'id': 1,
              'vehicle_no': 'TN-58-WA-101',
              'driver_name': 'Kumar R.',
              'driver_phone': '9842155101',
              'route_name': 'Anna Nagar & Teppakulam Route',
              'current_speed': 18,
              'latitude': 9.9212,
              'longitude': 78.1284,
            },
          ],
        },
      };
      return ApiSuccess(fromJson(mockFleet));
    }

    if (path.contains('financials')) {
      final mockFinancials = {
        'status': 'success',
        'data': {
          'cash_balance': 42000.0,
          'bank_balance': 125000.0,
          'receivables': 6000.0,
          'payables': 1800.0,
          'collections_today': 8500.0,
          'sales_amount': 54000.0,
          'sales_today': 8500.0,
          'sales_count': 12,
          'daily_sales_series': [],
          'ledger_entries': [],
        },
      };
      return ApiSuccess(fromJson(mockFinancials));
    }

    final mockData = {
      'status': 'success',
      'data': {
        'summary': {
          'total_turnover': 41430.0,
          'total_cash_and_bank': 398705.0,
          'total_receivables': 2100.0,
        },
        'companies': [
          {
            'id': 1,
            'name': 'Aran Cafe',
            'industry': 'cafe_bakery',
            'metrics': {
              'sales_turnover': 19705.0,
              'cash_and_bank': 60955.0,
              'receivables': 2100.0,
            }
          },
          {
            'id': 2,
            'name': 'Tiruchendur Murugan Water Supply',
            'industry': 'bulk_water',
            'metrics': {
              'sales_turnover': 15600.0,
              'cash_and_bank': 101550.0,
              'receivables': 0.0,
            }
          },
          {
            'id': 3,
            'name': 'DK Waters',
            'industry': 'packaged_water',
            'metrics': {
              'sales_turnover': 6125.0,
              'cash_and_bank': 51200.0,
              'receivables': 0.0,
            }
          },
        ]
      }
    };
    return ApiSuccess(fromJson(mockData));
  }
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  const company1 = CompanyInfo(id: 1, name: 'Aran Cafe', industry: 'cafe_bakery');
  const company2 = CompanyInfo(id: 2, name: 'Tiruchendur Murugan Water Supply', industry: 'bulk_water');
  const company3 = CompanyInfo(id: 3, name: 'DK Waters', industry: 'packaged_water');
  const testCompanies = [company1, company2, company3];

  const authState = AuthState(
    isAuthenticated: true,
    token: 'test_token',
    user: UserProfile(id: 1, name: 'Admin', username: 'admin', role: 'admin'),
    companies: testCompanies,
    activeCompany: company1,
    activeBranch: null,
    activeFinancialYear: null,
  );

  group('Workspace Square Cards & Responsive Navigation Tests', () {
    testWidgets('renders swipeable PageView carousel on mobile (<680px)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apiClientProvider.overrideWithValue(FakeApiClient()),
            authNotifierProvider.overrideWith((ref) => _MockAuthNotifier(authState)),
          ],
          child: const MaterialApp(
            home: WorkspaceScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Aran Cafe'), findsAtLeastNWidgets(1));
      expect(find.text('Bakery & POS'), findsOneWidget);
      expect(find.text('Open Workspace'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Swipe left or right to switch entities'), findsOneWidget);

      // Verify the new colored top card, charts, and operational carts
      expect(find.text('DK Enterprises Group'), findsAtLeastNWidgets(1));

      // Scroll down the ListView to reveal charts and carts on mobile
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Revenue Share & Multi-Vertical Insights'), findsOneWidget);
      expect(find.text('Operations & Service Carts'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Group Treasury & Capital Liquidity'), findsOneWidget);
    });

    testWidgets('renders responsive multi-column square grid on tablet/desktop (>=680px)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apiClientProvider.overrideWithValue(FakeApiClient()),
            authNotifierProvider.overrideWith((ref) => _MockAuthNotifier(authState)),
          ],
          child: const MaterialApp(
            home: WorkspaceScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Aran Cafe'), findsAtLeastNWidgets(1));
      expect(find.text('Tiruchendur Murugan Water Supply'), findsAtLeastNWidgets(1));
      expect(find.text('DK Waters'), findsAtLeastNWidgets(1));
      expect(find.text('Open Workspace'), findsNWidgets(3));

      // Verify charts and carts on tablet/desktop by scrolling down the ListView
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Revenue Share & Multi-Vertical Insights'), findsOneWidget);
      expect(find.text('Operations & Service Carts'), findsOneWidget);
      expect(find.text('Group Treasury & Capital Liquidity'), findsOneWidget);
    });

    testWidgets(
      'renders workspace company selection cards from API even when authState.companies is empty',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const emptyCompaniesAuth = AuthState(
          isAuthenticated: true,
          token: 'test_token',
          user: UserProfile(id: 1, name: 'Admin', username: 'admin', role: 'admin'),
          companies: [],
          activeCompany: null,
        );

        final blankTradeCompany = CompanyInfo.fromJson({
          'id': 2,
          'trade_name': '',
          'legal_name': 'Tiruchendur Murugan Water Supply',
          'industry': 'bulk_water',
        });
        expect(blankTradeCompany.name, 'Tiruchendur Murugan Water Supply');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              apiClientProvider.overrideWithValue(FakeApiClient()),
              authNotifierProvider
                  .overrideWith((ref) => _MockAuthNotifier(emptyCompaniesAuth)),
            ],
            child: const MaterialApp(
              home: WorkspaceScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('3 Operating Entities • Multi-Tenant Workspace'), findsOneWidget);
        expect(find.text('Aran Cafe'), findsAtLeastNWidgets(1));
        expect(find.text('Open Workspace'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'Owner view puts live delivery boy GPS & customer Paid/Due map first for packaged_water',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const waterAuth = AuthState(
          isAuthenticated: true,
          token: 'test_token',
          user: UserProfile(id: 1, name: 'Admin', username: 'admin', role: 'admin'),
          companies: testCompanies,
          activeCompany: company3,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              apiClientProvider.overrideWithValue(FakeApiClient()),
              authNotifierProvider.overrideWith((ref) => _MockAuthNotifier(waterAuth)),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ExecutiveDashboardScreen()),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Owner Live GPS: Delivery Boys & Customer Map'), findsOneWidget);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.text('Kumar R.'), findsAtLeastNWidgets(1));
        expect(find.text('Meenakshi'), findsAtLeastNWidgets(1));
        expect(find.text('Sri Murugan'), findsAtLeastNWidgets(1));
        expect(
          tester.getTopLeft(find.text('Owner Live GPS: Delivery Boys & Customer Map')).dy,
          lessThan(tester.getTopLeft(find.text('CASH IN HAND')).dy),
        );

        // Tap shortened pin -> pop-over bubble appears
        await tester.tap(find.text('Meenakshi').first);
        await tester.pumpAndSettle();
        expect(find.text('Meenakshi Hotel'), findsOneWidget);
        expect(find.text('Tap Bubble for Full History & Payments'), findsOneWidget);
      },
    );

    testWidgets(
      'Owner view puts live tanker GPS & customer Paid/Due map first for bulk_water',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(500, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const bulkAuth = AuthState(
          isAuthenticated: true,
          token: 'test_token',
          user: UserProfile(id: 1, name: 'Admin', username: 'admin', role: 'admin'),
          companies: testCompanies,
          activeCompany: company2,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              apiClientProvider.overrideWithValue(FakeApiClient()),
              authNotifierProvider.overrideWith((ref) => _MockAuthNotifier(bulkAuth)),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ExecutiveDashboardScreen()),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Owner Live GPS: Bulk Tankers & Customer Map'), findsOneWidget);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.text('K. Murugan'), findsAtLeastNWidgets(1));
        expect(
          tester.getTopLeft(find.text('Owner Live GPS: Bulk Tankers & Customer Map')).dy,
          lessThan(tester.getTopLeft(find.text('CASH IN HAND')).dy),
        );

        // Tap active tanker driver card -> today's work summary & timeline sheet opens
        await tester.tap(find.text('K. Murugan').last);
        await tester.pumpAndSettle();
        expect(find.text("Today's Work Summary"), findsOneWidget);
        expect(find.textContaining("Today's Activity Timeline"), findsOneWidget);
      },
    );
  });
}
