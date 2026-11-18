import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_endpoints.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/core/storage/local_database.dart';
import 'package:dk_track_mobile/core/storage/secure_storage_service.dart';
import 'package:dk_track_mobile/core/sync/sync_worker.dart';
import 'package:dk_track_mobile/core/theme/app_theme.dart';
import 'package:dk_track_mobile/features/auth/data/auth_repository.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';
import 'package:dk_track_mobile/features/operations/presentation/can_order_screen.dart';
import 'package:dk_track_mobile/features/operations/presentation/delivery_schedules_screen.dart';
import 'package:dk_track_mobile/features/tasks/presentation/tasks_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService(super.storage, super.prefs);

  @override
  Future<String?> getToken() async => 'test-token';

  @override
  String getServerUrl() => 'http://localhost:8000/api/v1';
}

class _FakeLocalDatabase extends LocalDatabase {
  final Map<String, dynamic> _cache = {};

  @override
  Future<void> saveCache(String key, dynamic data) async {
    _cache[key] = data;
  }

  @override
  Future<dynamic> getCache(String key) async => _cache[key];

  @override
  Future<DateTime?> getCacheTimestamp(String key) async => DateTime.now();

  @override
  Future<List<Map<String, dynamic>>> getPendingMutations() async => const [];

  @override
  Future<int> getPendingMutationsCount() async => 0;
}

class _FakeSyncWorker extends ChangeNotifier implements SyncWorker {
  @override
  SyncState get state => const SyncState(status: SyncStatus.synced);

  @override
  Future<void> refreshPendingCount() async {}

  @override
  Future<void> drainOutbox() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordedRequest {
  final String method;
  final String path;
  final Map<String, dynamic>? query;
  final dynamic data;

  const _RecordedRequest({
    required this.method,
    required this.path,
    this.query,
    this.data,
  });
}

class _ScenarioApiClient extends ApiClient {
  final List<_RecordedRequest> requests = [];

  _ScenarioApiClient(super.storage);

  List<Map<String, dynamic>> canPendingOrders = [
    {
      'id': 301,
      'order_id': 301,
      'order_no': 'ORD-301',
      'sales_order_id': 8801,
      'sales_order_no': 'SO-CAN-0088',
      'customer_id': 11,
      'customer_name': 'Hotel Supreme Residency',
      'ordered_cans': 7,
      'can_rate': 40.0,
      'status': 'ordered',
      'order_origin': 'scheduled',
      'schedule_label': 'Regular · Every 2 Days',
      'delivery_date': '2026-11-14',
      'payment_mode': 'Cash',
    },
    {
      'id': 302,
      'order_id': 302,
      'order_no': 'ORD-302',
      'sales_order_id': 8802,
      'sales_order_no': 'SO-CAN-0089',
      'customer_id': 12,
      'customer_name': 'Meenakshi Mess',
      'ordered_cans': 4,
      'can_rate': 40.0,
      'status': 'in_transit',
      'order_origin': 'on_day',
      'schedule_label': 'Created Today (On-Day)',
      'delivery_date': '2026-11-14',
      'payment_mode': 'UPI',
    },
  ];

  List<Map<String, dynamic>> tankerTrips = [
    {
      'id': 501,
      'reference_no': 'TR-501',
      'sales_order_id': 9101,
      'sales_order_no': 'SO-TNK-0091',
      'customer_id': 21,
      'customer_name': 'Titan Corporate Campus',
      'destination_site': 'Plant Utility Sump',
      'water_kl': 20.0,
      'trip_rate': 3600.0,
      'status': 'Pending',
      'order_origin': 'scheduled',
      'schedule_label': 'Regular · Weekly (Mon, Thu)',
      'trip_date': '2026-11-14',
      'payment_mode': 'Credit',
    },
  ];

  List<Map<String, dynamic>> canSchedules = [
    {
      'id': 71,
      'vertical_type': 'can',
      'customer_id': 11,
      'customer_name': 'Hotel Supreme Residency',
      'customer_phone': '9876543210',
      'ordered_qty': 7,
      'unit_rate': 40.0,
      'payment_mode': 'Cash',
      'frequency': 'every_n_days',
      'interval_days': 2,
      'frequency_label': 'Regular · Every 2 Days',
      'preferred_time_slot': '06:00 AM - 08:00 AM',
      'next_run_date': '2026-11-14',
      'is_active': true,
    },
  ];

  List<Map<String, dynamic>> tankerSchedules = [
    {
      'id': 82,
      'vertical_type': 'tanker',
      'customer_id': 21,
      'customer_name': 'Titan Corporate Campus',
      'customer_phone': '9000011122',
      'ordered_qty': 20.0,
      'unit_rate': 3600.0,
      'payment_mode': 'Credit',
      'frequency': 'weekly',
      'interval_days': 7,
      'days_of_week': [1, 4],
      'frequency_label': 'Regular · Weekly (Mon, Thu)',
      'preferred_time_slot': '07:00 AM',
      'next_run_date': '2026-11-14',
      'is_active': true,
    },
  ];

  @override
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) async {
    requests.add(
      _RecordedRequest(method: 'GET', path: path, query: queryParameters),
    );

    if (path == ApiEndpoints.driverManifest) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {
            'driver_type': 'delivery',
            'route': {'id': 1, 'name': 'Madurai Core Loop'},
            'vehicle': {'registration_no': 'TN-58-WA-101'},
            'can_inventory': {
              'loaded_cans': 80,
              'delivered_cans': 10,
              'empty_cans_on_truck': 10,
              'remaining_full_cans': 70,
            },
            'pending_orders': canPendingOrders,
            'stops': [
              {
                'id': 11,
                'customer_id': 11,
                'name': 'Hotel Supreme Residency',
                'address': 'West Perumal Maistry St, Madurai',
                'has_gps': true,
              },
            ],
          },
        }),
      );
    }

    if (path == ApiEndpoints.customers) {
      final vertical = queryParameters?['vertical']?.toString() ?? 'can';
      final list = vertical == 'tanker'
          ? [
              {
                'id': 21,
                'name': 'Titan Corporate Campus',
                'address': 'SIPCOT Industrial Estate',
                'has_gps': true,
              },
            ]
          : [
              {
                'id': 11,
                'name': 'Hotel Supreme Residency',
                'address': 'West Perumal Maistry St, Madurai',
                'has_gps': true,
                'last_can_rate': 40.0,
              },
              {
                'id': 12,
                'name': 'Meenakshi Mess',
                'address': 'East Masi St, Madurai',
                'has_gps': true,
                'last_can_rate': 38.0,
              },
            ];
      return ApiSuccess(fromJson({'success': true, 'data': list}));
    }

    if (path == ApiEndpoints.waterTrips) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {'trips': tankerTrips},
        }),
      );
    }

    if (path.startsWith(ApiEndpoints.waterSchedules)) {
      final parsedUri = Uri.parse(path);
      final vt = (parsedUri.queryParameters['vertical_type'] ??
              queryParameters?['vertical_type'] ??
              'can')
          .toString();
      final list = vt == 'tanker' ? tankerSchedules : canSchedules;
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {
            'vertical_type': vt,
            'schedules': list,
          },
        }),
      );
    }

    if (path == ApiEndpoints.waterCanRoutes) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': [
            {'id': 1, 'route_name': 'Madurai Core Loop'},
          ],
        }),
      );
    }

    if (path.contains('fleet/live')) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {'vehicles': const []},
        }),
      );
    }

    return ApiSuccess(fromJson({'success': true, 'data': <String, dynamic>{}}));
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    required T Function(dynamic data) fromJson,
  }) async {
    requests.add(
      _RecordedRequest(
        method: 'POST',
        path: path,
        query: queryParameters,
        data: data,
      ),
    );

    if (path == ApiEndpoints.waterCanOrders) {
      final payload = data is Map<String, dynamic>
          ? data
          : <String, dynamic>{};
      final freq = payload['schedule_frequency']?.toString() ?? 'on_day';
      final nDays = payload['interval_days'] ?? 3;
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {
            'id': 399,
            'order_no': 'ORD-399',
            'sales_order_id': 8899,
            'sales_order_no': 'SO-CAN-0899',
            'ordered_cans': payload['ordered_cans'] ?? 7,
            'schedule_label': freq == 'every_n_days'
                ? 'Regular · Every $nDays Days'
                : 'Created Today (On-Day)',
          },
        }),
      );
    }

    if (path.endsWith('/adjust')) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {
            'id': 301,
            'sales_order_no': 'SO-CAN-0088',
            'ordered_cans': 10,
          },
        }),
      );
    }

    if (path.endsWith('/start')) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {'id': 301, 'status': 'in_transit'},
        }),
      );
    }

    if (path.endsWith('/skip')) {
      canSchedules = canSchedules
          .map((s) => {...s, 'next_run_date': '2026-11-16'})
          .toList();
      return ApiSuccess(fromJson({'success': true, 'data': canSchedules.first}));
    }

    if (path.endsWith('/toggle')) {
      canSchedules = canSchedules
          .map((s) => {...s, 'is_active': !(s['is_active'] == true)})
          .toList();
      return ApiSuccess(fromJson({'success': true, 'data': canSchedules.first}));
    }

    return ApiSuccess(fromJson({'success': true, 'data': <String, dynamic>{}}));
  }
}

Widget _wrapWithProviders({
  required SharedPreferences prefs,
  required _ScenarioApiClient apiClient,
  required AuthState authState,
  required RippleRole themeRole,
  required Widget child,
}) {
  final storage = _FakeSecureStorageService(
    const FlutterSecureStorage(),
    prefs,
  );
  final db = _FakeLocalDatabase();
  final syncWorker = _FakeSyncWorker();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      secureStorageProvider.overrideWithValue(storage),
      localDatabaseProvider.overrideWithValue(db),
      apiClientProvider.overrideWithValue(apiClient),
      syncWorkerProvider.overrideWith((ref) => syncWorker),
      authNotifierProvider.overrideWith((ref) => _FakeAuthNotifier(authState)),
    ],
    child: MaterialApp(
      theme: AppTheme.themeForRole(themeRole, Brightness.light),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets(
    'TasksScreen (packaged_water) renders pending Sales Orders inside ListView with zero layout error and supports Start Moving + Adjust sheet',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _FakeSecureStorageService(
        const FlutterSecureStorage(),
        prefs,
      );
      final api = _ScenarioApiClient(storage);

      const state = AuthState(
        isAuthenticated: true,
        token: 'fake',
        user: UserProfile(
          id: 2,
          name: 'S. Karthik',
          username: 'driver',
          role: 'deliveryDriver',
        ),
        companies: [
          CompanyInfo(id: 3, name: 'DK Waters', industry: 'packaged_water'),
        ],
        activeCompany: CompanyInfo(
          id: 3,
          name: 'DK Waters',
          industry: 'packaged_water',
        ),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          prefs: prefs,
          apiClient: api,
          authState: state,
          themeRole: RippleRole.driver,
          child: const TasksScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verifies _RenderInputPadding/RenderBox crash inside SliverList is completely resolved
      expect(tester.takeException(), isNull);
      expect(find.textContaining('SO-CAN-0088'), findsOneWidget);
      expect(find.text('Regular · Every 2 Days'), findsOneWidget);
      expect(find.text('Created Today (On-Day)'), findsOneWidget);
      expect(find.text('Start Moving'), findsOneWidget);
      expect(find.text('Adjust'), findsNWidgets(2));

      // Tap Start Moving on ordered stop
      await tester.tap(find.text('Start Moving'));
      await tester.pumpAndSettle();
      expect(
        api.requests.any((r) => r.method == 'POST' && r.path == '/water/can-orders/301/start'),
        isTrue,
      );

      // Tap Adjust -> opens showAdjustWaterOrderSheet and posts to /adjust
      await tester.tap(find.text('Adjust').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Adjust Can Sales Order'), findsOneWidget);
      expect(find.text('Save Adjusted Sales Order'), findsOneWidget);

      await tester.tap(find.text('Save Adjusted Sales Order'));
      await tester.pumpAndSettle();
      expect(
        api.requests.any(
          (r) => r.method == 'POST' && r.path == ApiEndpoints.waterCanOrderAdjust(301),
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'TasksScreen (bulk_water) parses data.trips Map, renders SO-TNK badge, Create Order & Delivery Schedules actions',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _FakeSecureStorageService(
        const FlutterSecureStorage(),
        prefs,
      );
      final api = _ScenarioApiClient(storage);

      const state = AuthState(
        isAuthenticated: true,
        token: 'fake',
        user: UserProfile(
          id: 3,
          name: 'K. Murugan',
          username: 'tanker_driver',
          role: 'tankerDriver',
        ),
        companies: [
          CompanyInfo(
            id: 2,
            name: 'Tiruchendur Murugan Water Supply',
            industry: 'bulk_water',
          ),
        ],
        activeCompany: CompanyInfo(
          id: 2,
          name: 'Tiruchendur Murugan Water Supply',
          industry: 'bulk_water',
        ),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          prefs: prefs,
          apiClient: api,
          authState: state,
          themeRole: RippleRole.driver,
          child: const TasksScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Create Order'), findsWidgets);
      expect(find.text('Delivery Schedules'), findsWidgets);
      expect(find.textContaining('SO-TNK-0091'), findsOneWidget);
      expect(find.text('Regular · Weekly (Mon, Thu)'), findsOneWidget);
      expect(find.text('Adjust Order'), findsOneWidget);
    },
  );

  testWidgets(
    'CanOrderScreen supports customizable Every N Days (3 days) schedule booking and shows Sales Order Created dialog',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _FakeSecureStorageService(
        const FlutterSecureStorage(),
        prefs,
      );
      final api = _ScenarioApiClient(storage);

      const state = AuthState(
        isAuthenticated: true,
        token: 'fake',
        user: UserProfile(
          id: 2,
          name: 'S. Karthik',
          username: 'driver',
          role: 'deliveryDriver',
        ),
        companies: [
          CompanyInfo(id: 3, name: 'DK Waters', industry: 'packaged_water'),
        ],
        activeCompany: CompanyInfo(
          id: 3,
          name: 'DK Waters',
          industry: 'packaged_water',
        ),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          prefs: prefs,
          apiClient: api,
          authState: state,
          themeRole: RippleRole.driver,
          child: CanOrderScreen(
            initialCustomerId: 11,
            initialOrderedCans: 7,
            gpsFetcher: () async => (lat: 9.9252, lng: 78.1198, isMocked: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Create Water Can Order'), findsOneWidget);

      await tester.ensureVisible(find.text('Every N Days'));
      await tester.tap(find.text('Every N Days'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Every 3 d'));
      await tester.pumpAndSettle();
      expect(find.text('Repeat every 3 days'), findsOneWidget);

      await tester.ensureVisible(find.text('Create Sales Order'));
      await tester.tap(find.text('Create Sales Order'));
      await tester.pumpAndSettle();

      final createReq = api.requests.lastWhere(
        (r) => r.method == 'POST' && r.path == ApiEndpoints.waterCanOrders,
      );
      final payload = createReq.data as Map<String, dynamic>;
      expect(payload['create_schedule'], isTrue);
      expect(payload['schedule_frequency'], 'every_n_days');
      expect(payload['interval_days'], 3);

      expect(find.text('Sales Order Created & Owner Notified'), findsOneWidget);
      expect(find.textContaining('SO-CAN-0899'), findsOneWidget);
    },
  );

  testWidgets(
    'DeliverySchedulesScreen enforces vertical gating (deliveryDriver hides Tanker chip, Super Admin sees both) and Skip Next / Pause actions',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _FakeSecureStorageService(
        const FlutterSecureStorage(),
        prefs,
      );
      final driverApi = _ScenarioApiClient(storage);

      const driverState = AuthState(
        isAuthenticated: true,
        token: 'fake',
        user: UserProfile(
          id: 2,
          name: 'S. Karthik',
          username: 'driver',
          role: 'deliveryDriver',
        ),
        companies: [
          CompanyInfo(id: 3, name: 'DK Waters', industry: 'packaged_water'),
        ],
        activeCompany: CompanyInfo(
          id: 3,
          name: 'DK Waters',
          industry: 'packaged_water',
        ),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          prefs: prefs,
          apiClient: driverApi,
          authState: driverState,
          themeRole: RippleRole.driver,
          child: const DeliverySchedulesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bulk Tanker Lorry'), findsNothing);
      expect(find.text('Hotel Supreme Residency'), findsOneWidget);
      expect(find.text('Skip Next'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);

      await tester.tap(find.text('Skip Next'));
      await tester.pumpAndSettle();
      expect(
        driverApi.requests.any((r) => r.method == 'POST' && r.path == '/water/schedules/71/skip'),
        isTrue,
      );

      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      expect(
        driverApi.requests.any((r) => r.method == 'POST' && r.path == '/water/schedules/71/toggle'),
        isTrue,
      );
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets(
    'DeliverySchedulesScreen lets Super Admin view and switch between 20L Water Can and Bulk Tanker Lorry schedules',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = _FakeSecureStorageService(
        const FlutterSecureStorage(),
        prefs,
      );
      final adminApi = _ScenarioApiClient(storage);
      const adminState = AuthState(
        isAuthenticated: true,
        token: 'fake',
        user: UserProfile(
          id: 1,
          name: 'DK Super Admin',
          username: 'admin',
          role: 'superAdmin',
        ),
        roles: ['super_admin'],
        companies: [
          CompanyInfo(id: 3, name: 'DK Waters', industry: 'packaged_water'),
          CompanyInfo(id: 2, name: 'Tiruchendur Murugan Water Supply', industry: 'bulk_water'),
        ],
        activeCompany: CompanyInfo(
          id: 3,
          name: 'DK Waters',
          industry: 'packaged_water',
        ),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          prefs: prefs,
          apiClient: adminApi,
          authState: adminState,
          themeRole: RippleRole.admin,
          child: const DeliverySchedulesScreen(initialVerticalType: 'can'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Water Can'), findsOneWidget);
      expect(find.text('Bulk Tanker Lorry'), findsOneWidget);

      await tester.tap(find.text('Bulk Tanker Lorry'));
      await tester.pumpAndSettle();
      expect(find.text('Titan Corporate Campus'), findsOneWidget);
    },
  );
}

