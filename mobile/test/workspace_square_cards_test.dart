import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/features/auth/data/auth_repository.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';
import 'package:dk_track_mobile/features/workspace/presentation/workspace_screen.dart';
import 'package:flutter/material.dart';
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
      expect(find.text('Aran Cafe'), findsOneWidget);
      expect(find.text('Bakery & POS'), findsOneWidget);
      expect(find.text('Open Workspace'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Swipe left or right to switch entities'), findsOneWidget);
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
      expect(find.text('Aran Cafe'), findsOneWidget);
      expect(find.text('Tiruchendur Murugan Water Supply'), findsOneWidget);
      expect(find.text('DK Waters'), findsOneWidget);
      expect(find.text('Open Workspace'), findsNWidgets(3));
    });
  });
}
