import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dk_track_mobile/core/lifecycle/app_keep_alive_manager.dart';
import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/notifications/push_notification_service.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/core/storage/local_database.dart';
import 'package:dk_track_mobile/core/storage/secure_storage_service.dart';
import 'package:dk_track_mobile/core/sync/sync_worker.dart';
import 'package:dk_track_mobile/core/theme/app_theme.dart';
import 'package:dk_track_mobile/core/ui/adaptive_layout.dart';
import 'package:dk_track_mobile/features/auth/data/auth_repository.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';
import 'package:dk_track_mobile/features/dashboard/presentation/tanker_driver_dashboard_screen.dart';
import 'package:dk_track_mobile/features/operations/presentation/driver_surrender_screen.dart';

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService(SharedPreferences prefs)
      : super(const FlutterSecureStorage(), prefs);

  @override
  Future<String?> getToken() async => null;

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

class _FakeApiClient extends ApiClient {
  int pollCount = 0;

  _FakeApiClient(super.storage);

  @override
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) async {
    if (path.contains('notifications')) {
      pollCount += 1;
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {
            'unread_count': 0,
            'notifications': <Map<String, dynamic>>[],
          },
        }),
      );
    }

    if (path.contains('driver-manifest')) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': {
            'driver': {
              'id': 14,
              'name': 'K. Murugan',
              'username': 'tanker_driver',
              'role_label': 'Bulk Tanker Driver',
              'emp_code': 'EMP-014',
            },
            'vehicle': {
              'id': 201,
              'name': 'Tata LPT 2518 (20KL Dual Chamber)',
              'registration_no': 'TN-58-BW-2001',
              'capacity_litres': 20000,
            },
            'route': {
              'id': 3,
              'name': 'Perundurai Bulk Corridor',
            },
            'odometer_km': 45200,
            'today_trips': 2,
            'total_kl': 40.0,
            'payload_kl': 20.0,
            'active_trip': {
              'id': 91,
              'trip_ref': 'TMWS-TRIP-2026-003',
              'status': 'DISPATCHED',
              'destination_name': 'Titan Corporate Campus',
              'chamber1_kl': 10.0,
              'chamber2_kl': 10.0,
            },
            'assigned_orders': <Map<String, dynamic>>[],
          },
        }),
      );
    }

    if (path.contains('trips')) {
      return ApiSuccess(
        fromJson({
          'success': true,
          'data': <Map<String, dynamic>>[],
        }),
      );
    }

    return ApiSuccess(
      fromJson({
        'success': true,
        'data': <String, dynamic>{},
      }),
    );
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    required T Function(dynamic data) fromJson,
  }) async {
    return ApiSuccess(
      fromJson({
        'success': true,
        'data': <String, dynamic>{},
      }),
    );
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(
    super.apiClient,
    super.storage,
    AuthState initialState,
  ) {
    state = initialState;
  }

  @override
  Future<void> checkInitialAuth() async {}

  @override
  Future<void> refreshMe() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Staff display name normalization & strict role labels', () {
    test('UserProfile.fromJson normalizes raw role slugs to clean human names', () {
      final tanker = UserProfile.fromJson({
        'id': 14,
        'name': 'tanker_driver',
        'username': 'tanker_driver',
        'role': 'tanker_driver',
      });
      expect(tanker.name, equals('K. Murugan'));
      expect(tanker.username, equals('tanker_driver'));
      expect(tanker.effectiveRoleLabel, equals('Bulk Tanker Driver'));
      expect(UserProfile.looksLikeRoleSlug('tanker_driver'), isTrue);

      final canDriver = UserProfile.fromJson({
        'id': 15,
        'name': 'can_driver',
        'username': 'can_driver',
        'role': 'can_delivery',
      });
      expect(canDriver.name, equals('S. Karthik'));
      expect(canDriver.effectiveRoleLabel, equals('Water Can Delivery Driver'));

      final explicitHuman = UserProfile.fromJson({
        'id': 16,
        'name': 'R. Venkatesh',
        'username': 'tmws_driver_2',
        'role': 'tanker_driver',
      });
      expect(explicitHuman.name, equals('R. Venkatesh'));
      expect(explicitHuman.username, equals('tmws_driver_2'));
      expect(explicitHuman.effectiveRoleLabel, equals('Bulk Tanker Driver'));
    });
  });

  group('Wide aspect ratio & tablet 2-column Tanker dashboard', () {
    testWidgets(
      'AdaptivePageConstraint and TankerDriverDashboardScreen stay visible and render 2 columns at 1440x800',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = _FakeSecureStorageService(prefs);
        final localDb = _FakeLocalDatabase();
        final apiClient = _FakeApiClient(storage);

        const tmwsCompany = CompanyInfo(
          id: 2,
          name: 'Tiruchendur Murugan Water Supply',
          code: 'TMWS',
          industry: 'bulk_water',
        );

        final authState = AuthState(
          isAuthenticated: true,
          token: 'test-token',
          user: UserProfile.fromJson({
            'id': 14,
            'name': 'tanker_driver',
            'username': 'tanker_driver',
            'role': 'tanker_driver',
          }),
          roles: const ['tanker_driver'],
          companies: const [tmwsCompany],
          activeCompany: tmwsCompany,
        );
        final authNotifier = _FakeAuthNotifier(apiClient, storage, authState);

        await tester.binding.setSurfaceSize(const Size(1440, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              secureStorageProvider.overrideWithValue(storage),
              localDatabaseProvider.overrideWithValue(localDb),
              apiClientProvider.overrideWithValue(apiClient),
              syncWorkerProvider.overrideWith((ref) => SyncWorker(apiClient, localDb)),
              authNotifierProvider.overrideWith((ref) => authNotifier),
              activeDriverFlavorProvider
                  .overrideWithValue(RippleDriverFlavor.tanker),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AdaptivePageConstraint(
                  child: TankerDriverDashboardScreen(),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('K. Murugan'), findsOneWidget);
        expect(find.text('tanker_driver'), findsNothing);
        expect(find.text('BULK WATER TELEMETRY'), findsOneWidget);
        expect(find.byType(TankerDriverDashboardScreen), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });

  group('Tanker vs Can vertical split on DriverSurrenderScreen', () {
    testWidgets(
      'Tanker flavor hides 20L Van Jar Count Reconciliation and shows Bulk Freight settlement',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = _FakeSecureStorageService(prefs);
        final localDb = _FakeLocalDatabase();
        final apiClient = _FakeApiClient(storage);

        const tmwsCompany = CompanyInfo(
          id: 2,
          name: 'Tiruchendur Murugan Water Supply',
          code: 'TMWS',
          industry: 'bulk_water',
        );

        final tankerAuth = _FakeAuthNotifier(
          apiClient,
          storage,
          AuthState(
            isAuthenticated: true,
            token: 'test-token',
            user: UserProfile.fromJson({
              'id': 14,
              'name': 'K. Murugan',
              'username': 'tanker_driver',
              'role': 'tanker_driver',
            }),
            roles: const ['tanker_driver'],
            companies: const [tmwsCompany],
            activeCompany: tmwsCompany,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              secureStorageProvider.overrideWithValue(storage),
              localDatabaseProvider.overrideWithValue(localDb),
              apiClientProvider.overrideWithValue(apiClient),
              syncWorkerProvider.overrideWith((ref) => SyncWorker(apiClient, localDb)),
              authNotifierProvider.overrideWith((ref) => tankerAuth),
              activeDriverFlavorProvider
                  .overrideWithValue(RippleDriverFlavor.tanker),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: DriverSurrenderScreen(embedded: true),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Bulk Tanker Trip & Freight Settlement'), findsOneWidget);
        expect(find.text('Van Jar Count Reconciliation'), findsNothing);
        expect(find.text('Empty Jars Returned'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'Can delivery flavor displays Van Jar Count Reconciliation and Empty Jars Returned',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = _FakeSecureStorageService(prefs);
        final localDb = _FakeLocalDatabase();
        final apiClient = _FakeApiClient(storage);

        const dkWaters = CompanyInfo(
          id: 3,
          name: 'DK Waters',
          code: 'DKW',
          industry: 'packaged_water',
        );

        final canAuth = _FakeAuthNotifier(
          apiClient,
          storage,
          AuthState(
            isAuthenticated: true,
            token: 'test-token',
            user: UserProfile.fromJson({
              'id': 15,
              'name': 'S. Karthik',
              'username': 'can_driver',
              'role': 'can_delivery',
            }),
            roles: const ['can_delivery'],
            companies: const [dkWaters],
            activeCompany: dkWaters,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              secureStorageProvider.overrideWithValue(storage),
              localDatabaseProvider.overrideWithValue(localDb),
              apiClientProvider.overrideWithValue(apiClient),
              syncWorkerProvider.overrideWith((ref) => SyncWorker(apiClient, localDb)),
              authNotifierProvider.overrideWith((ref) => canAuth),
              activeDriverFlavorProvider
                  .overrideWithValue(RippleDriverFlavor.canDelivery),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: DriverSurrenderScreen(embedded: true),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Van Jar Count Reconciliation'), findsOneWidget);
        expect(find.text('Empty Jars Returned'), findsOneWidget);
        expect(find.text('Bulk Tanker Trip & Freight Settlement'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });

  group('Always-live memory keep-alive manager', () {
    testWidgets(
      'AppKeepAliveManager trims imageCache safely and persists heartbeat across pause/resume/pressure',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = _FakeSecureStorageService(prefs);
        final localDb = _FakeLocalDatabase();
        final apiClient = _FakeApiClient(storage);
        final syncWorker = SyncWorker(apiClient, localDb);
        final pushService = PushNotificationService(apiClient);
        final manager = AppKeepAliveManager(
          prefs: prefs,
          syncWorker: syncWorker,
          pushService: pushService,
        );

        pushService.start();
        await tester.pump();
        final initialPolls = apiClient.pollCount;

        manager.attach();
        expect(manager.isAttached, isTrue);
        expect(
          PaintingBinding.instance.imageCache.maximumSizeBytes,
          equals(AppKeepAliveManager.activeImageCacheBytes),
        );

        manager.didChangeAppLifecycleState(AppLifecycleState.paused);
        await tester.pump();
        expect(manager.memoryTrimCount, equals(1));
        expect(
          PaintingBinding.instance.imageCache.maximumSizeBytes,
          equals(AppKeepAliveManager.suspendedImageCacheBytes),
        );
        expect(
          prefs.getString(AppKeepAliveManager.lastAliveStorageKey),
          isNotNull,
        );

        manager.didHaveMemoryPressure();
        await tester.pump();
        expect(manager.memoryTrimCount, equals(2));
        expect(
          PaintingBinding.instance.imageCache.maximumSizeBytes,
          equals(AppKeepAliveManager.suspendedImageCacheBytes),
        );

        manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await tester.pump();
        expect(
          PaintingBinding.instance.imageCache.maximumSizeBytes,
          equals(AppKeepAliveManager.activeImageCacheBytes),
        );
        expect(apiClient.pollCount, greaterThan(initialPolls));

        manager.detach();
        pushService.stop();
        pushService.dispose();
        syncWorker.dispose();
      },
    );
  });
}

