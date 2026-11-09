import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/core/utils/location_parser.dart';
import 'package:dk_track_mobile/features/customers/presentation/customer_form_screen.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Customer Location Parser & Creation Form Tests', () {
    test('extracts WhatsApp Google Maps coordinates correctly', () {
      const waText = 'Please deliver 20 cans here: https://maps.google.com/?q=11.3410,77.7172';
      final coords = LocationParser.extractCoordinates(waText);
      expect(coords, isNotNull);
      expect(coords!.latitude, 11.3410);
      expect(coords.longitude, 77.7172);
    });

    test('extracts raw latitude and longitude text', () {
      const rawText = '11.0845, 77.2941';
      final coords = LocationParser.extractCoordinates(rawText);
      expect(coords, isNotNull);
      expect(coords!.latitude, 11.0845);
      expect(coords.longitude, 77.2941);
    });

    testWidgets('CustomerFormScreen renders all sections cleanly', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: CustomerFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Onboard New Customer'), findsOneWidget);
      expect(find.text('Customer / Shop Name *'), findsOneWidget);
      expect(find.text('Phone Number *'), findsOneWidget);
      expect(find.text('Street Address & Landmark *'), findsOneWidget);
      expect(find.text('Instant WhatsApp Location Capture'), findsOneWidget);
      expect(find.text('Save & Onboard Customer'), findsOneWidget);
    });
  });
}
