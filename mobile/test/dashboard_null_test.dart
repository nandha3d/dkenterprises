import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';
import 'package:dk_track_mobile/features/auth/data/auth_repository.dart';
import 'package:dk_track_mobile/features/dashboard/presentation/role_dashboard_dispatcher.dart';
import 'package:dk_track_mobile/core/ui/app_scaffold.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpTest(WidgetTester tester, AuthState state) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authNotifierProvider.overrideWith((ref) => _MockAuthNotifier(state)),
        ],
        child: const MaterialApp(
          home: AppScaffold(
            currentIndex: 0,
            child: RoleDashboardDispatcher(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
  }

  testWidgets('Test null activeBranch or activeCompany', (WidgetTester tester) async {
    const state = AuthState(
      isAuthenticated: true,
      token: 'fake',
      user: UserProfile(id: 1, name: 'Admin', username: 'admin', role: 'admin'),
      companies: [],
      activeCompany: null,
      activeBranch: null,
      activeFinancialYear: null,
    );
    await pumpTest(tester, state);
  });

  testWidgets('Test deliveryDriver role', (WidgetTester tester) async {
    const state = AuthState(
      isAuthenticated: true,
      token: 'fake',
      user: UserProfile(id: 2, name: 'Driver', username: 'driver', role: 'deliveryDriver'),
      companies: [],
      activeCompany: CompanyInfo(id: 3, name: 'DK Waters', industry: 'packaged_water'),
      activeBranch: null,
      activeFinancialYear: null,
    );
    await pumpTest(tester, state);
  });

  testWidgets('Test tankerDriver role', (WidgetTester tester) async {
    const state = AuthState(
      isAuthenticated: true,
      token: 'fake',
      user: UserProfile(id: 3, name: 'Tanker Driver', username: 'tanker_driver', role: 'tankerDriver'),
      companies: [],
      activeCompany: CompanyInfo(id: 2, name: 'TMWS', industry: 'bulk_water'),
      activeBranch: null,
      activeFinancialYear: null,
    );
    await pumpTest(tester, state);
  });

  testWidgets('Test cashier role', (WidgetTester tester) async {
    const state = AuthState(
      isAuthenticated: true,
      token: 'fake',
      user: UserProfile(id: 4, name: 'Cashier', username: 'cashier', role: 'cashier'),
      companies: [],
      activeCompany: CompanyInfo(id: 1, name: 'Aran Cafe', industry: 'cafe_bakery'),
      activeBranch: null,
      activeFinancialYear: null,
    );
    await pumpTest(tester, state);
  });

  testWidgets('Test fieldAgent role', (WidgetTester tester) async {
    const state = AuthState(
      isAuthenticated: true,
      token: 'fake',
      user: UserProfile(id: 5, name: 'Agent', username: 'agent', role: 'fieldAgent'),
      companies: [],
      activeCompany: CompanyInfo(id: 3, name: 'DK Waters', industry: 'packaged_water'),
      activeBranch: null,
      activeFinancialYear: null,
    );
    await pumpTest(tester, state);
  });

  testWidgets('Test null user', (WidgetTester tester) async {
    const state = AuthState(
      isAuthenticated: true,
      token: 'fake',
      user: null,
      companies: [],
      activeCompany: null,
      activeBranch: null,
      activeFinancialYear: null,
    );
    await pumpTest(tester, state);
  });
}

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
