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
import 'package:dk_track_mobile/features/dashboard/presentation/can_delivery_driver_dashboard_screen.dart';
import 'package:dk_track_mobile/features/operations/presentation/can_order_screen.dart';
import 'package:dk_track_mobile/features/operations/presentation/can_sales_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OrderFakeApiClient implements ApiClient {
  final List<({String path, Map<String, dynamic> payload})> posts = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) async {
    if (path == ApiEndpoints.customers) {
      return ApiSuccess(
        fromJson({
          'data': [
            {
              'id': 5,
              'name': 'Balaji Cafe',
              'latitude': 11.0182210,
              'longitude': 76.9641190,
              'geofence_radius': 150,
              'master_can_rate': 35.0,
              'shop_qr_code': 'DKW-SHOP-5',
            },
          ],
        }),
      );
    }

    if (path == ApiEndpoints.driverManifest) {
      return ApiSuccess(
        fromJson({
          'data': {
            'route_id': 1,
            'driver_name': 'S. Karthik',
            'company_name': 'DK Waters',
            'gstin': '33TESTGST1234F1Z5',
            'upi_vpa': 'dkwaters@upi',
            'manager_override_pin': '2580',
            'jar_deposit_rate': 150.0,
            'vehicle': {
              'id': 1,
              'vehicle_number': 'TN-58-WA-101',
            },
            'can_inventory': {
              'loaded_cans': 60,
              'delivered_cans': 12,
              'empty_collected': 10,
              'remaining_full_cans': 48,
            },
            'cash': {
              'cash_collected_today': 420.0,
            },
            'pending_orders': [
              {
                'id': 101,
                'order_id': 101,
                'order_no': 'ORD-TEST-101',
                'customer_id': 5,
                'customer_name': 'Balaji Cafe',
                'ordered_cans': 7,
                'can_rate': 35.0,
                'master_can_rate': 35.0,
                'estimated_amount': 245.0,
                'payment_mode': 'Cash',
                'status': 'ordered',
                'latitude': 11.0182210,
                'longitude': 76.9641190,
                'order_notes': 'Morning batch',
              },
            ],
            'stops': [
              {
                'id': 5,
                'customer_id': 5,
                'name': 'Balaji Cafe',
                'cans_qty': 7,
                'latitude': 11.0182210,
                'longitude': 76.9641190,
                'status': 'pending',
              },
            ],
            'rate_slabs': [
              {'label': 'Standard Rate', 'rate': 35},
            ],
          },
        }),
      );
    }

    return ApiSuccess(fromJson({'data': {}}));
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    required T Function(dynamic data) fromJson,
  }) async {
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    posts.add((path: path, payload: map));

    if (path == ApiEndpoints.waterCanOrders) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {
            'id': 101,
            'order_id': 101,
            'order_no': 'ORD-TEST-101',
            'customer_id': map['customer_id'] ?? 5,
            'customer_name': map['customer_name'] ?? 'Balaji Cafe',
            'ordered_cans': map['ordered_cans'] ?? 7,
            'can_rate': map['can_rate'] ?? 35.0,
            'status': map['start_immediately'] == true ? 'in_transit' : 'ordered',
          },
        }),
      );
    }

    if (path == ApiEndpoints.waterCanOrderStart(101)) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {
            'id': 101,
            'order_id': 101,
            'order_no': 'ORD-TEST-101',
            'status': 'in_transit',
          },
        }),
      );
    }

    if (path == ApiEndpoints.waterCanOrderClose(101)) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {
            'id': 101,
            'order_id': 101,
            'order_no': 'ORD-TEST-101',
            'status': 'completed',
            'cans_delivered': map['cans_delivered'] ?? 7,
          },
        }),
      );
    }

    return ApiSuccess(fromJson({'success': true, 'data': {'delivery_no': 'CAN-9001'}}));
  }
}

class _OrderFakeLocalDatabase extends LocalDatabase {
  @override
  Future<dynamic> getCache(String key) async => null;

  @override
  Future<DateTime?> getCacheTimestamp(String key) async => null;

  @override
  Future<void> saveCache(String key, dynamic data) async {}

  @override
  Future<int> getPendingMutationsCount() async => 0;

  @override
  Future<List<Map<String, dynamic>>> getPendingMutations() async => const [];

  @override
  Future<void> queueMutation({
    required String id,
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
    double? gpsLat,
    double? gpsLng,
  }) async {}
}

class _OrderFakeSyncWorker extends ChangeNotifier implements SyncWorker {
  @override
  SyncState get state => const SyncState(status: SyncStatus.synced);

  @override
  Future<void> refreshPendingCount() async {}

  @override
  Future<void> drainOutbox() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OrderFakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _OrderFakeAuthNotifier(super.initial);

  @override
  Future<void> checkInitialAuth() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthState _driverAuthState() {
  const company = CompanyInfo(
    id: 3,
    name: 'DK Waters',
    code: 'DKW',
    industry: 'packaged_water',
    upiVpa: 'dkwaters@upi',
  );
  const user = UserProfile(
    id: 14,
    name: 'S. Karthik',
    username: 'delivery_driver',
    role: 'deliveryDriver',
    roleLabel: 'Delivery Driver',
  );
  return const AuthState(
    isAuthenticated: true,
    token: 'test-token',
    user: user,
    roles: ['deliveryDriver'],
    companies: [company],
    activeCompany: company,
  );
}

Future<Widget> _wrapOrderHarness({
  required Widget child,
  required _OrderFakeApiClient fakeApi,
  AuthState? authState,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final fakeDb = _OrderFakeLocalDatabase();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      secureStorageProvider.overrideWithValue(
        SecureStorageService(const FlutterSecureStorage(), prefs),
      ),
      localDatabaseProvider.overrideWithValue(fakeDb),
      apiClientProvider.overrideWithValue(fakeApi),
      syncWorkerProvider.overrideWith((_) => _OrderFakeSyncWorker()),
      if (authState != null)
        authNotifierProvider.overrideWith((_) => _OrderFakeAuthNotifier(authState)),
    ],
    child: MaterialApp(
      theme: AppTheme.themeForRole(RippleRole.driver, Brightness.light),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'Stage 1: CanOrderScreen books 7 cans first and notifies owner',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(480, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fakeApi = _OrderFakeApiClient();
      final widget = await _wrapOrderHarness(
        fakeApi: fakeApi,
        authState: _driverAuthState(),
        child: CanOrderScreen(
          gpsFetcher: () async => (lat: 11.0182210, lng: 76.9641190, isMocked: false),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('7 Cans'), findsOneWidget);
      expect(find.textContaining('Balaji Cafe'), findsWidgets);

      await tester.tap(find.text('Create Sales Order'));
      await tester.pumpAndSettle();

      final orderPost = fakeApi.posts.where((p) => p.path == ApiEndpoints.waterCanOrders).toList();
      expect(orderPost, hasLength(1));
      expect(orderPost.single.payload['ordered_cans'], 7);
      expect(orderPost.single.payload['customer_id'], 5);
      expect(orderPost.single.payload['payment_mode'], 'Cash');

      expect(find.text('Sales Order Created & Owner Notified'), findsOneWidget);
      expect(find.textContaining('ORD-TEST-101'), findsOneWidget);
    },
  );

  testWidgets(
    'Dashboard renders Open Can Orders queue and posts Start Moving transition',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(480, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fakeApi = _OrderFakeApiClient();
      final widget = await _wrapOrderHarness(
        fakeApi: fakeApi,
        authState: _driverAuthState(),
        child: const CanDeliveryDriverDashboardScreen(),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('Open Can Orders'), findsOneWidget);
      expect(find.text('ORDERED · OWNER NOTIFIED'), findsOneWidget);
      expect(find.text('Start Moving'), findsOneWidget);
      expect(find.text('Close & Deliver'), findsOneWidget);

      await tester.ensureVisible(find.text('Start Moving'));
      await tester.tap(find.text('Start Moving'));
      await tester.pumpAndSettle();

      expect(
        fakeApi.posts.any((p) => p.path == ApiEndpoints.waterCanOrderStart(101)),
        isTrue,
      );
    },
  );

  testWidgets(
    'Delivery driver CanSalesScreen requires booking order first before closing',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fakeApi = _OrderFakeApiClient();
      final widget = await _wrapOrderHarness(
        fakeApi: fakeApi,
        authState: _driverAuthState(),
        child: CanSalesScreen(
          gpsFetcher: () async => (lat: 11.0182210, lng: 76.9641190, isMocked: false),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('Order-First Lock: Book Order Before Delivering'), findsOneWidget);
      expect(find.text('Step 1: Book Order & Notify Owner'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Book Order First'), findsOneWidget);

      // Select customer name & increment 3 cans + 3 returned empties
      await tester.enterText(find.byType(TextFormField).first, 'Balaji Cafe');
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pumpAndSettle();

      final deliverPlus = find.byIcon(Icons.add_rounded).first;
      for (int i = 0; i < 3; i++) {
        await tester.tap(deliverPlus);
      }
      final emptyPlus = find.byIcon(Icons.add_rounded).last;
      for (int i = 0; i < 3; i++) {
        await tester.tap(emptyPlus);
      }
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Book Order First'));
      await tester.pumpAndSettle();

      final orderPosts = fakeApi.posts.where((p) => p.path == ApiEndpoints.waterCanOrders).toList();
      expect(orderPosts, hasLength(1));
      expect(orderPosts.single.payload['ordered_cans'], 3);
      expect(orderPosts.single.payload['start_immediately'], true);

      // Order-First Lock unlocks and Close CTA becomes active
      expect(find.text('Order-First Lock: Book Order Before Delivering'), findsNothing);
      final closeBtn = find.widgetWithText(ElevatedButton, 'Close & Deliver Order');
      expect(closeBtn, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(
        fakeApi.posts.any((p) => p.path == ApiEndpoints.waterCanOrderClose(101)),
        isTrue,
      );
    },
  );

  testWidgets(
    'CanSalesScreen with initialOrder pre-fills 7 cans and closes via order close endpoint',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fakeApi = _OrderFakeApiClient();
      final widget = await _wrapOrderHarness(
        fakeApi: fakeApi,
        authState: _driverAuthState(),
        child: CanSalesScreen(
          gpsFetcher: () async => (lat: 11.0182210, lng: 76.9641190, isMocked: false),
          initialOrder: const {
            'id': 101,
            'order_id': 101,
            'order_no': 'ORD-TEST-101',
            'status': 'in_transit',
            'ordered_cans': 7,
            'customer_id': 5,
            'customer_name': 'Balaji Cafe',
            'can_rate': 35.0,
            'payment_mode': 'Cash',
          },
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.text('Order-First Lock: Book Order Before Delivering'), findsNothing);
      expect(find.text('7'), findsWidgets);
      expect(find.widgetWithText(ElevatedButton, 'Close & Deliver Order'), findsOneWidget);

      final emptyPlus = find.byIcon(Icons.add_rounded).last;
      for (int i = 0; i < 7; i++) {
        await tester.ensureVisible(emptyPlus);
        await tester.tap(emptyPlus);
      }
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Close & Deliver Order'));
      await tester.pumpAndSettle();

      final closePosts = fakeApi.posts
          .where((p) => p.path == ApiEndpoints.waterCanOrderClose(101))
          .toList();
      expect(closePosts, hasLength(1));
      expect(closePosts.single.payload['cans_delivered'], 7);
    },
  );
}
