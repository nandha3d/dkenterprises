import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/main.dart';

void main() {
  testWidgets('ZOLO ERP mobile app bootstrap smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ZoloErpApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ZoloErpApp), findsOneWidget);
  });
}
