import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/models/models.dart';
import 'package:dk_track_mobile/screens/fleet_gps_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
        'tankers': [],
        'can_routes': [
          {
            'vehicle_no': 'TN-58-WA-101',
            'driver_name': 'Kumar R.',
            'driver_phone': '+91 98421 55101',
            'route_name': 'Anna Nagar & Teppakulam Route',
            'current_speed': 0,
            'daily_avg_cans': 60,
            'latitude': 11.2812,
            'longitude': 77.5994,
            'last_ping_at': null,
          },
          {
            'vehicle_no': 'TN-58-WA-102',
            'driver_name': 'Selvam P.',
            'driver_phone': '+91 98421 55102',
            'route_name': 'KK Nagar & Mattuthavani Route',
            'current_speed': 0,
            'daily_avg_cans': 60,
            'latitude': 11.2912,
            'longitude': 77.6094,
            'last_ping_at': null,
          },
        ]
      }
    };
    return ApiSuccess(fromJson(mockData));
  }
}

void main() {
  testWidgets('FleetGpsScreen renders selected vehicle telemetry and checks coordinates', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(584, 1000);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(FakeApiClient()),
        ],
        child: const MaterialApp(
          home: FleetGpsScreen(
            isTamil: false,
            initialMode: FleetViewMode.packagedWater,
            activeRole: UserRole.superAdmin,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap on second vehicle chip TN-58-WA-102
    await tester.tap(find.text('TN-58-WA-102').first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('KK Nagar & Mattuthavani Route'), findsOneWidget);
    expect(find.text('Selvam P.'), findsOneWidget);

    final textElements = find.byType(Text);
    for (final el in textElements.evaluate()) {
      final textWidget = el.widget as Text;
      final renderBox = el.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final pos = renderBox.localToGlobal(Offset.zero);
        // ignore: avoid_print
        print('POS: y=${pos.dy.toStringAsFixed(1)} x=${pos.dx.toStringAsFixed(1)} size=${renderBox.size} text="${textWidget.data}"');
      }
    }
  });
}
