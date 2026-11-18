import 'dart:async';
import 'dart:typed_data';
import 'package:dk_track_mobile/core/gps/gps_enforcement_gate.dart';
import 'package:dk_track_mobile/core/gps/gps_service.dart';
import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/core/theme/app_theme.dart';
import 'package:dk_track_mobile/core/ui/daily_sales_chart.dart';
import 'package:dk_track_mobile/features/auth/data/auth_repository.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';
import 'package:dk_track_mobile/features/operations/presentation/driver_surrender_screen.dart';
import 'package:dk_track_mobile/models/models.dart';
import 'package:dk_track_mobile/screens/fleet_gps_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Uint8List _kTransparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _StubTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_kTransparentPng);
  }
}

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) async {
    return ApiSuccess(fromJson(<String, dynamic>{'data': <String, dynamic>{}}));
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    required T Function(dynamic data) fromJson,
  }) async {
    return ApiSuccess(fromJson(<String, dynamic>{'status': 'success'}));
  }
}

class _FakeGpsHardwareAdapter implements GpsHardwareAdapter {
  _FakeGpsHardwareAdapter({
    required this.serviceEnabled,
    required this.permission,
    required this.mocked,
  });

  bool serviceEnabled;
  LocationPermission permission;
  bool mocked;

  @override
  bool get isMobileHardware => true;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<bool> hasAlwaysPermission() async =>
      permission == LocationPermission.always;

  @override
  Future<bool> requestAlwaysPermission() async =>
      permission == LocationPermission.always;

  @override
  Future<Position?> getCurrentPosition() async => Position(
        longitude: 78.1198,
        latitude: 9.9252,
        timestamp: DateTime(2026, 11, 13, 10, 0),
        accuracy: 6.0,
        altitude: 130.0,
        altitudeAccuracy: 2.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 12.0,
        speedAccuracy: 1.0,
        isMocked: mocked,
      );

  @override
  Future<Position?> getLastKnownPosition() => getCurrentPosition();

  @override
  Stream<Position> positionStream() => const Stream<Position>.empty();

  @override
  Stream<ServiceStatus> serviceStatusStream() =>
      const Stream<ServiceStatus>.empty();

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<bool> openAppSettings() async => true;
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('DailySalesChart widget', () {
    testWidgets('displays ERP+GST totals, toggles period and inspects tapped bar',
        (WidgetTester tester) async {
      int changedDays = 14;
      final skin = RippleSkin.forRole(RippleRole.admin, Brightness.light);
      final sampleSeries = [
        {
          'date': '2026-11-12',
          'label': '12 Nov',
          'short_label': '12',
          'total': 4200.0,
          'collected': 3200.0,
          'due': 1000.0,
          'gst': 210.0,
          'orders_count': 6,
        },
        {
          'date': '2026-11-13',
          'label': '13 Nov',
          'short_label': '13',
          'total': 8500.0,
          'collected': 6500.0,
          'due': 2000.0,
          'gst': 425.0,
          'orders_count': 11,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeForRole(RippleRole.admin, Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DailySalesChart(
                series: sampleSeries,
                selectedDays: 14,
                onDaysChanged: (d) => changedDays = d,
                collectedTotal: 9700.0,
                dueTotal: 3000.0,
                gstTotal: 635.0,
                skin: skin,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Sales & Collections'), findsOneWidget);
      expect(find.text('ERP invoices synced with GST ledger'), findsOneWidget);
      expect(find.textContaining('Collected:'), findsOneWidget);
      expect(find.textContaining('Credit Due:'), findsOneWidget);
      expect(find.textContaining('GST Output:'), findsOneWidget);

      await tester.tap(find.text('30D'));
      await tester.pump();
      expect(changedDays, 30);

      // Tap first day bar ("12") and confirm day summary switches
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(find.textContaining('12 Nov'), findsWidgets);
    });
  });

  group('Loanapp-style FleetGpsScreen Paid/Due customer map', () {
    final seedCustomers = <Map<String, dynamic>>[
      {
        'id': 1,
        'name': 'Meenakshi Hotel',
        'address': 'West Tower Street, Madurai',
        'latitude': 9.9195,
        'longitude': 78.1193,
        'geofence_radius': 150,
        'total_sales': 18000.0,
        'total_paid': 12000.0,
        'due_amount': 6000.0,
        'overdue_amount': 0.0,
        'payment_status': 'due',
      },
      {
        'id': 2,
        'name': 'Vaigai Bakeries',
        'address': 'Anna Nagar Main Rd, Madurai',
        'tax_no': '33AABCT1234Z1Z5',
        'latitude': 9.9301,
        'longitude': 78.1411,
        'geofence_radius': 180,
        'total_sales': 25000.0,
        'total_paid': 10000.0,
        'due_amount': 15000.0,
        'overdue_amount': 15000.0,
        'payment_status': 'overdue',
      },
      {
        'id': 3,
        'name': 'Temple City Mess',
        'address': 'KK Nagar, Madurai',
        'latitude': 9.9390,
        'longitude': 78.1485,
        'geofence_radius': 150,
        'total_sales': 7500.0,
        'total_paid': 7500.0,
        'due_amount': 0.0,
        'overdue_amount': 0.0,
        'payment_status': 'paid',
      },
    ];

    testWidgets('filters by Overdue status & opens customer billing sheet',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(820, 960);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apiClientProvider.overrideWithValue(_FakeApiClient()),
          ],
          child: MaterialApp(
            theme: AppTheme.themeForRole(RippleRole.admin, Brightness.light),
            home: FleetGpsScreen(
              isTamil: false,
              initialMode: FleetViewMode.packagedWater,
              activeRole: UserRole.superAdmin,
              initialCustomers: seedCustomers,
              skipInitialFetch: true,
              tileProvider: _StubTileProvider(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Due (2)'), findsOneWidget);
      expect(find.text('Overdue (1)'), findsOneWidget);
      expect(find.text('Paid (1)'), findsOneWidget);
      expect(find.text('Meenakshi'), findsWidgets);
      expect(find.text('Vaigai'), findsWidgets);
      expect(find.text('Temple City'), findsWidgets);

      // Filter strictly to Overdue customers
      await tester.tap(find.text('Overdue (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Vaigai'), findsWidgets);
      expect(find.text('Meenakshi'), findsNothing);

      // 1st tap: Overdue pin pops detailed bubble over the pin
      await tester.tap(find.text('Vaigai').first);
      await tester.pumpAndSettle();
      expect(find.text('Vaigai Bakeries'), findsOneWidget);
      expect(find.text('Tap Bubble for Full History & Payments'), findsOneWidget);

      // 2nd tap: Bubble opens full interactive Customer 360° history sheet
      await tester.tap(find.text('Tap Bubble for Full History & Payments'));
      await tester.pumpAndSettle();

      expect(find.text('Total Billed'), findsOneWidget);
      expect(find.text('Paid Amount'), findsOneWidget);
      expect(find.text('Due Amount'), findsOneWidget);
      expect(find.text('GSTIN: 33AABCT1234Z1Z5'), findsOneWidget);
      expect(find.text('Can Order'), findsOneWidget);
      expect(find.textContaining('Purchases ('), findsOneWidget);
    });
  });

  group('Always-On GpsEnforcementGate', () {
    Future<void> pumpGate(
      WidgetTester tester, {
      required String roleSlug,
      required _FakeGpsHardwareAdapter adapter,
    }) async {
      final authState = AuthState(
        isAuthenticated: true,
        token: 'test-token',
        user: UserProfile(
          id: 9,
          name: 'Test Duty Staff',
          username: 'staff',
          role: roleSlug,
        ),
        companies: const [],
        activeCompany: const CompanyInfo(
          id: 3,
          name: 'DK Waters',
          industry: 'packaged_water',
        ),
        activeBranch: null,
        activeFinancialYear: null,
      );

      final fakeGps = GpsService(adapter: adapter);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apiClientProvider.overrideWithValue(_FakeApiClient()),
            authNotifierProvider.overrideWith(
              (ref) => _FakeAuthNotifier(authState),
            ),
            gpsServiceProvider.overrideWithValue(fakeGps),
          ],
          child: MaterialApp(
            theme: AppTheme.themeForRole(RippleRole.driver, Brightness.light),
            home: const GpsEnforcementGate(
              enforceOverrideForTest: true,
              child: Scaffold(body: Text('Duty Screen Active')),
            ),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(GpsEnforcementGate)),
      );
      await container.read(gpsPingerProvider).syncSession(authState);
      await tester.pumpAndSettle();
    }

    testWidgets('blocks delivery driver when device GPS is disabled',
        (WidgetTester tester) async {
      await pumpGate(
        tester,
        roleSlug: 'delivery_driver',
        adapter: _FakeGpsHardwareAdapter(
          serviceEnabled: false,
          permission: LocationPermission.always,
          mocked: false,
        ),
      );

      expect(find.text('Turn On Device GPS'), findsOneWidget);
      expect(
        find.text('Supervisor alerted when duty GPS is disabled'),
        findsOneWidget,
      );
      expect(find.text('Duty Screen Active').hitTestable(), findsNothing);
    });

    testWidgets('blocks tanker driver when mock GPS spoofing is active',
        (WidgetTester tester) async {
      await pumpGate(
        tester,
        roleSlug: 'tanker_driver',
        adapter: _FakeGpsHardwareAdapter(
          serviceEnabled: true,
          permission: LocationPermission.always,
          mocked: true,
        ),
      );

      expect(find.text('Mock Location App Blocked'), findsOneWidget);
      expect(find.text('Duty Screen Active').hitTestable(), findsNothing);
    });

    testWidgets(
        'unblocks driver when real GPS signal is ready and never blocks admin',
        (WidgetTester tester) async {
      await pumpGate(
        tester,
        roleSlug: 'delivery_driver',
        adapter: _FakeGpsHardwareAdapter(
          serviceEnabled: true,
          permission: LocationPermission.always,
          mocked: false,
        ),
      );
      expect(find.text('Duty Screen Active'), findsOneWidget);

      await pumpGate(
        tester,
        roleSlug: 'admin',
        adapter: _FakeGpsHardwareAdapter(
          serviceEnabled: false,
          permission: LocationPermission.denied,
          mocked: true,
        ),
      );
      expect(find.text('Duty Screen Active'), findsOneWidget);
    });
  });

  testWidgets('DriverSurrenderScreen exposes clean business labels without internal codes',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiClientProvider.overrideWithValue(_FakeApiClient()),
        ],
        child: MaterialApp(
          theme: AppTheme.themeForRole(RippleRole.driver, Brightness.light),
          home: const DriverSurrenderScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blind Note Denomination Tally'), findsOneWidget);
    expect(find.textContaining('Layer '), findsNothing);
    expect(find.textContaining('(D-'), findsNothing);
  });
}
