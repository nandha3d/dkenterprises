import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dk_track_mobile/core/providers.dart';
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
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

  testWidgets('ExecutiveDashboardScreen shows 2nd GPS card for DK Waters (packaged_water)', (tester) async {
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

    // Must find GPS Card for packaged water
    expect(find.textContaining('20L Can Delivery Fleet Tracking'), findsOneWidget);
    expect(find.textContaining('TN-58-WA-101'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Track / Nav'), findsOneWidget);
    expect(find.textContaining('LIVE GPS'), findsOneWidget);
    expect(find.textContaining('CAN DRIVER MANIFEST'), findsOneWidget);
  });

  testWidgets('ExecutiveDashboardScreen shows 2nd GPS card for TMWS (bulk_water)', (tester) async {
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

    // Must find GPS Card for bulk water
    expect(find.textContaining('Bulk Tanker Fleet GPS Tracking'), findsOneWidget);
    expect(find.textContaining('TN-58-BW-2001'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Track / Nav'), findsOneWidget);
    expect(find.textContaining('LIVE GPS'), findsOneWidget);
    expect(find.textContaining('TANKER DRIVER DESK'), findsOneWidget);
  });
}
