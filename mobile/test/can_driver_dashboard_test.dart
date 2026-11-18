import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/core/storage/local_database.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';
import 'package:dk_track_mobile/features/auth/data/auth_repository.dart';
import 'package:dk_track_mobile/features/dashboard/presentation/can_delivery_driver_dashboard_screen.dart';
import 'package:dk_track_mobile/features/dashboard/presentation/tanker_driver_dashboard_screen.dart';
import 'package:dk_track_mobile/features/dashboard/presentation/executive_dashboard_screen.dart';

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SeededLocalDatabase extends LocalDatabase {
  final Map<String, dynamic> _seed;
  _SeededLocalDatabase(this._seed);

  @override
  Future<dynamic> getCache(String key) async => _seed[key];

  @override
  Future<void> saveCache(String key, dynamic data) async {
    _seed[key] = data;
  }
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('CanDeliveryDriverDashboardScreen renders manifest and stops cleanly', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const state = AuthState(
      isAuthenticated: true,
      token: 'fake',
      user: UserProfile(id: 2, name: 'Driver', username: 'driver', role: 'deliveryDriver'),
      companies: [],
      activeCompany: CompanyInfo(id: 3, name: 'DK Waters', industry: 'packaged_water'),
      activeBranch: null,
      activeFinancialYear: null,
    );

    final seededDb = _SeededLocalDatabase({
      'driver_manifest_can_delivery': {
        'driver_type': 'delivery',
        'vehicle': {
          'vehicle_number': 'TN-58-WA-101 (Tata Ace)',
          'route_name': 'Anna Nagar & Teppakulam Route',
        },
        'can_inventory': {
          'loaded_cans': 60,
          'delivered_cans': 25,
          'empty_cans_on_truck': 20,
          'remaining_full_cans': 35,
        },
        'cash': {'in_hand': 1450.0},
        'stops': [
          {
            'id': 1,
            'customer_id': 5,
            'name': 'Hotel Saravana Bhavan',
            'address': 'Main Road, Erode',
            'latitude': 11.3410,
            'longitude': 77.7172,
            'has_gps': true,
          },
        ],
      },
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localDatabaseProvider.overrideWithValue(seededDb),
          authNotifierProvider.overrideWith((ref) => _MockAuthNotifier(state)),
        ],
        child: const MaterialApp(
          home: CanDeliveryDriverDashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    // Must find vehicle number and stops header
    expect(find.textContaining('TN-58-WA-101'), findsOneWidget);
    expect(find.textContaining('ACTIVE BEAT'), findsOneWidget);
    expect(find.textContaining('Route Beat Customer Stops'), findsOneWidget);
    expect(find.textContaining('Surrender Cash'), findsOneWidget);
  });

  testWidgets('TankerDriverDashboardScreen renders tanker and active trip cleanly', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const state = AuthState(
      isAuthenticated: true,
      token: 'fake',
      user: UserProfile(id: 3, name: 'Tanker Driver', username: 'tanker_driver', role: 'tankerDriver'),
      companies: [],
      activeCompany: CompanyInfo(id: 2, name: 'TMWS', industry: 'bulk_water'),
      activeBranch: null,
      activeFinancialYear: null,
    );

    final seededDb = _SeededLocalDatabase({
      'driver_manifest_tanker': {
        'driver_type': 'tanker',
        'vehicle': {
          'vehicle_number': 'TN-58-BW-2001',
          'model': 'Tata LPT 2518 (20KL)',
          'current_odometer': 45200,
        },
        'active_trip': {
          'trip_number': 'TMWS-TRIP-2026-002',
          'customer_id': 4,
          'customer_name': 'The Chennai Silks (Dyeing Unit)',
          'destination_site': 'Industrial Dyeing Unit',
          'address': 'Perundurai SIPCOT Industrial Area',
          'water_quantity_kl': 16.0,
          'latitude': 11.0845,
          'longitude': 77.2941,
        },
        'stats': {'trips_today': 4, 'total_kl': 48.0},
      },
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localDatabaseProvider.overrideWithValue(seededDb),
          authNotifierProvider.overrideWith((ref) => _MockAuthNotifier(state)),
        ],
        child: const MaterialApp(
          home: TankerDriverDashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    // Must find tanker vehicle number and active trip
    expect(find.textContaining('TN-58-BW-2001'), findsOneWidget);
    expect(find.textContaining('The Chennai Silks'), findsOneWidget);
    expect(find.textContaining('FLOW: 0 L/min'), findsOneWidget);
  });

  testWidgets('ExecutiveDashboardScreen renders Stitch A-01 Live Fleet Strip & Quick Modules for DK Waters (packaged_water)', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const state = AuthState(
      isAuthenticated: true,
      token: 'fake',
      user: UserProfile(id: 1, name: 'Admin', username: 'admin', role: 'admin'),
      companies: [
        CompanyInfo(id: 3, name: 'DK Waters', industry: 'packaged_water'),
      ],
      activeCompany: CompanyInfo(id: 3, name: 'DK Waters', industry: 'packaged_water'),
      activeBranch: null,
      activeFinancialYear: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authNotifierProvider.overrideWith((ref) => _MockAuthNotifier(state)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ExecutiveDashboardScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 15));

    // Must find Stitch A-01 Cash in Hand Hero, Live Fleet Strip & Packaged Water Quick Modules
    expect(find.textContaining('CASH IN HAND'), findsOneWidget);
    expect(find.textContaining('Live Fleet Strip'), findsOneWidget);
    expect(find.textContaining('Open Radar'), findsOneWidget);
    expect(find.textContaining('Water Can Beat POS'), findsOneWidget);
    expect(find.textContaining('Can Route Manifest'), findsOneWidget);
  });

  testWidgets('ExecutiveDashboardScreen renders Stitch A-01 Live Fleet Strip & Quick Modules for TMWS (bulk_water)', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const state = AuthState(
      isAuthenticated: true,
      token: 'fake',
      user: UserProfile(id: 1, name: 'Admin', username: 'admin', role: 'admin'),
      companies: [
        CompanyInfo(id: 2, name: 'TMWS', industry: 'bulk_water'),
      ],
      activeCompany: CompanyInfo(id: 2, name: 'TMWS', industry: 'bulk_water'),
      activeBranch: null,
      activeFinancialYear: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authNotifierProvider.overrideWith((ref) => _MockAuthNotifier(state)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ExecutiveDashboardScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 15));

    // Must find Stitch A-01 Cash in Hand Hero, Live Fleet Strip & Bulk Water Quick Modules
    expect(find.textContaining('CASH IN HAND'), findsOneWidget);
    expect(find.textContaining('Live Fleet Strip'), findsOneWidget);
    expect(find.textContaining('Open Radar'), findsOneWidget);
    expect(find.textContaining('Tanker Trip Desk'), findsOneWidget);
    expect(find.textContaining('Live Tanker Radar'), findsOneWidget);
  });
}
