import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_endpoints.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/core/storage/local_database.dart';
import 'package:dk_track_mobile/core/sync/sync_worker.dart';
import 'package:dk_track_mobile/core/theme/app_colors.dart';
import 'package:dk_track_mobile/core/theme/app_theme.dart';
import 'package:dk_track_mobile/core/ui/module_tile.dart';
import 'package:dk_track_mobile/core/ui/quick_action_sheet.dart';
import 'package:dk_track_mobile/core/ui/ripple_components.dart';
import 'package:dk_track_mobile/features/auth/data/auth_repository.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';
import 'package:dk_track_mobile/features/tasks/presentation/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UiFakeApiClient implements ApiClient {
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
              'name': 'Sri Annapoorna Restaurant',
              'address': '77 Cross Cut Road, Gandhipuram',
              'order_cans': 10,
            },
          ],
        }),
      );
    }
    if (path == ApiEndpoints.driverManifest) {
      return ApiSuccess(
        fromJson({
          'data': {
            'pending_orders': [
              {
                'id': 201,
                'order_id': 201,
                'order_no': 'ORD-201',
                'customer_id': 5,
                'customer_name': 'Sri Annapoorna Restaurant',
                'address': '77 Cross Cut Road, Gandhipuram',
                'ordered_cans': 10,
                'status': 'ordered',
              },
            ],
          },
        }),
      );
    }
    if (path == ApiEndpoints.waterTrips) {
      return ApiSuccess(fromJson({'data': <dynamic>[]}));
    }
    return ApiSuccess(fromJson({'data': <String, dynamic>{}}));
  }
}

class _UiFakeLocalDatabase extends LocalDatabase {
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
}

class _UiFakeSyncWorker extends ChangeNotifier implements SyncWorker {
  @override
  SyncState get state => const SyncState(status: SyncStatus.synced);

  @override
  Future<void> refreshPendingCount() async {}

  @override
  Future<void> drainOutbox() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UiFakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _UiFakeAuthNotifier(super.initial);

  @override
  Future<void> checkInitialAuth() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthState _buildAuthState({
  required String username,
  required String role,
  required String industry,
}) {
  return AuthState(
    isAuthenticated: true,
    token: 'test-token',
    user: UserProfile(
      id: 9,
      name: username,
      username: username,
      role: role,
    ),
    companies: const [],
    activeCompany: CompanyInfo(
      id: 3,
      name: 'DK Enterprises',
      industry: industry,
    ),
    activeBranch: null,
    activeFinancialYear: null,
  );
}

void _expectNoException(WidgetTester tester) {
  final err = tester.takeException();
  expect(err, isNull, reason: err?.toString());
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'RippleMenuTileCard & ModuleTile render compact medallion icons without overflow at desktop and 1.45x text scale',
      (tester) async {
    var tapped = 0;

    tester.view.physicalSize = const Size(1020, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [RippleSkin.forRole(RippleRole.driver, Brightness.light)],
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Builder(
                  builder: (ctx) => SizedBox(
                    height: 160,
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: rippleGridTileExtent(ctx),
                      ),
                      itemCount: 2,
                      itemBuilder: (_, idx) => RippleMenuTileCard(
                        icon: idx == 0
                            ? Icons.add_shopping_cart_rounded
                            : Icons.local_drink_rounded,
                        title: idx == 0 ? 'New Can Order' : 'Disabled Item',
                        subtitle: 'Set cans first & notify owner',
                        accentColor: AppColors.aquaPrimary,
                        badge: idx == 0 ? 'D-01' : 'D-02',
                        enabled: idx == 0,
                        onTap: () => tapped++,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModuleTile(
                  title: 'Can Route Manifest',
                  description: '60 jars on van',
                  icon: Icons.local_shipping_rounded,
                  color: AppColors.brandEmerald,
                  onTap: () => tapped++,
                ),
                const SizedBox(height: 12),
                RippleActionCard(
                  icon: Icons.payments_rounded,
                  title: 'Collect Payment',
                  subtitle: 'Invoice settlement',
                  badge: 'PAY',
                  onTap: () => tapped++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RippleMenuTileCard), findsNWidgets(2));
    expect(find.byType(RippleIconBadge), findsNWidgets(4));
    expect(find.text('D-01'), findsOneWidget);

    final tileSize = tester.getSize(find.byType(RippleMenuTileCard).first);
    expect(tileSize.height, lessThanOrEqualTo(145.0));

    await tester.tap(find.text('New Can Order'));
    await tester.tap(find.text('Disabled Item'));
    await tester.pump();
    expect(tapped, equals(1));

    // Verify accessibility scaling on narrow 360px screen with zero overflow.
    tester.view.physicalSize = const Size(360, 780);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.45)),
        child: MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [RippleSkin.forRole(RippleRole.cafe, Brightness.dark)],
          ),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: rippleGridTileExtent(
                    ctx,
                    baseHeight: 74,
                    textBudget: 62,
                  ),
                ),
                itemCount: 2,
                itemBuilder: (_, idx) => RippleMenuTileCard(
                  icon: Icons.local_cafe_rounded,
                  title: 'Close / Deliver Order',
                  subtitle: 'Deliver cans, collect empties & cash/UPI',
                  accentColor: AppColors.chaiPrimary,
                  badge: 'Deliver',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'TasksScreen Can Van Operations & Tanker Modules use compact RippleMenuTileCard and RippleIconBadge',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();

    Future<void> pumpTasksForSize(Size size, AuthState state, RippleRole role) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey('tasks_${size.width}_${state.user?.username}_${state.activeCompany?.industry}'),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apiClientProvider.overrideWithValue(_UiFakeApiClient()),
            localDatabaseProvider.overrideWithValue(_UiFakeLocalDatabase()),
            syncWorkerProvider.overrideWith((_) => _UiFakeSyncWorker()),
            authNotifierProvider.overrideWith((_) => _UiFakeAuthNotifier(state)),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [RippleSkin.forRole(role, Brightness.light)],
            ),
            home: const TasksScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final driverState = _buildAuthState(
      username: 'delivery_driver',
      role: 'deliveryDriver',
      industry: 'packaged_water',
    );

    // Phone viewport (480x860)
    await pumpTasksForSize(const Size(480, 860), driverState, RippleRole.driver);
    expect(find.text('Water Can Van Operations'), findsOneWidget);
    expect(find.byType(RippleMenuTileCard), findsNWidgets(6));
    expect(find.byType(RippleIconBadge), findsNWidgets(6));
    expect(find.text('Order'), findsOneWidget);
    expect(find.text('Shift'), findsOneWidget);
    final phoneCardSize = tester.getSize(find.byType(RippleMenuTileCard).first);
    expect(phoneCardSize.height, lessThanOrEqualTo(145.0));
    expect(tester.takeException(), isNull);

    // Wide tablet viewport (960x900) — must stay compact (not stretch into tall blank square)
    await pumpTasksForSize(const Size(960, 900), driverState, RippleRole.driver);
    final tabletCardSize = tester.getSize(find.byType(RippleMenuTileCard).first);
    expect(tabletCardSize.height, lessThanOrEqualTo(145.0));
    expect(tester.takeException(), isNull);

    // Tanker driver T-07 modules render RippleIconBadge
    final tankerState = _buildAuthState(
      username: 'tanker_driver',
      role: 'tankerDriver',
      industry: 'bulk_water',
    );
    await pumpTasksForSize(const Size(540, 860), tankerState, RippleRole.driver);
    await tester.scrollUntilVisible(
      find.text('Bulk Tanker Operations (5 Modules)'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Bulk Tanker Operations (5 Modules)'), findsOneWidget);
    expect(find.byType(RippleIconBadge), findsNWidgets(5));
    _expectNoException(tester);
  });

  testWidgets(
      'QuickActionSheet renders compact role-filtered RippleMenuTileCard tiles in light & dark themes',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpSheet(
      Size size,
      AuthState state,
      RippleRole role,
      Brightness brightness,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey('tasks_${size.width}_${state.user?.username}_${state.activeCompany?.industry}'),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localDatabaseProvider.overrideWithValue(_UiFakeLocalDatabase()),
            authNotifierProvider.overrideWith((_) => _UiFakeAuthNotifier(state)),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness).copyWith(
              extensions: [RippleSkin.forRole(role, brightness)],
            ),
            home: const Scaffold(body: QuickActionSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpSheet(
      const Size(430, 800),
      _buildAuthState(
        username: 'delivery_driver',
        role: 'deliveryDriver',
        industry: 'packaged_water',
      ),
      RippleRole.driver,
      Brightness.light,
    );
    expect(find.text('Quick Actions (+ New)'), findsOneWidget);
    expect(find.text('Order'), findsOneWidget);
    expect(find.text('Deliver'), findsOneWidget);
    expect(find.byType(RippleMenuTileCard), findsNWidgets(8));
    expect(
      tester.getSize(find.byType(RippleMenuTileCard).first).height,
      lessThanOrEqualTo(140.0),
    );
    _expectNoException(tester);

    await pumpSheet(
      const Size(760, 820),
      _buildAuthState(
        username: 'cashier',
        role: 'cashier',
        industry: 'cafe_bakery',
      ),
      RippleRole.cafe,
      Brightness.dark,
    );
    expect(find.text('Cafe POS'), findsOneWidget);
    expect(find.text('POS'), findsOneWidget);
    expect(find.text('X/Z'), findsOneWidget);
    expect(find.text('Purchase Bill / Supplier'), findsOneWidget);
    expect(find.byType(RippleMenuTileCard), findsNWidgets(9));
    _expectNoException(tester);
  });
}
