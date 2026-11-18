import 'dart:typed_data';
import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/core/ui/gps_map_interactive_sheets.dart';
import 'package:dk_track_mobile/models/models.dart';
import 'package:dk_track_mobile/screens/fleet_gps_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 1x1 transparent PNG bytes so headless widget tests never perform real HTTP requests.
final Uint8List _kTransparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _StubTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_kTransparentPng);
  }
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
    if (path.contains('/history')) {
      final histData = {
        'status': 'success',
        'data': {
          'customer': {
            'id': 101,
            'name': 'Meenakshi Hotel',
            'address': 'West Tower Street, Madurai',
            'total_sales': 18500.0,
            'total_paid': 12500.0,
            'due_amount': 6000.0,
            'overdue_amount': 0.0,
            'payment_status': 'due',
            'cash_paid_total': 8500.0,
            'digital_paid_total': 4000.0,
            'cans_held': 14,
            'deposit_held': 2100.0,
          },
          'purchases': [
            {
              'id': 1,
              'type': 'water_can',
              'reference_no': 'CAN-20261117-01',
              'date': '2026-11-17',
              'time': '09:15 AM',
              'item_summary': '20 × Water Can @ ₹35',
              'qty': 20,
              'unit': 'Cans',
              'unit_rate': 35.0,
              'empty_cans_returned': 18,
              'total_amount': 700.0,
              'paid_amount': 500.0,
              'due_amount': 200.0,
              'payment_mode': 'Cash',
              'payment_status': 'partial',
              'where_address': 'West Tower Street, Madurai',
              'driver_name': 'Kumar R.',
              'vehicle_number': 'TN-58-WA-101',
            },
          ],
          'payments': [
            {
              'id': 1,
              'payment_reference': 'REC-20261117-01',
              'invoice_ref': 'CAN-20261117-01',
              'amount': 500.0,
              'payment_mode': 'Cash',
              'date': '2026-11-17',
              'time': '09:16 AM',
              'note': 'Collected at shop counter',
            },
          ],
          'timeline': [
            {
              'date': '2026-11-17',
              'time': '09:16 AM',
              'type': 'payment',
              'title': 'Payment Received (Cash)',
              'subtitle': 'Against CAN-20261117-01',
              'debit': 0.0,
              'credit': 500.0,
              'running_balance': 6000.0,
            },
          ],
        },
      };
      return ApiSuccess(fromJson(histData));
    }

    if (path.contains('fleet/driver-activity')) {
      final actData = {
        'status': 'success',
        'data': {
          'today_summary': {
            'activity_date': '2026-11-17',
            'is_today': true,
            'morning_loaded_cans': 60,
            'plant_refills_count': 1,
            'plant_refilled_cans': 20,
            'total_loaded_cans': 80,
            'deliveries_completed': 6,
            'open_orders_count': 1,
            'cans_delivered': 42,
            'empty_cans_returned': 38,
            'remaining_cans': 38,
            'total_billed': 1470.0,
            'cash_collected': 1120.0,
            'cash_in_hand': 1120.0,
          },
          'today_timeline': [
            {
              'time': '07:00 AM',
              'type': 'shift_start',
              'title': 'Morning Van Dispatch & Stock Load',
              'subtitle': 'Anna Nagar & Teppakulam Route · Baseline 60 Cans loaded',
              'location': 'DK Waters RO Plant',
              'badge': '60 CANS',
            },
            {
              'time': '09:15 AM',
              'type': 'delivery',
              'title': 'Delivered 20 Cans to Meenakshi Hotel',
              'subtitle': 'Empty returned: 18 · Cash · Paid ₹500',
              'location': 'West Tower Street, Madurai',
              'badge': 'DELIVERED',
              'amount': 700.0,
            },
          ],
        },
      };
      return ApiSuccess(fromJson(actData));
    }

    final mockData = {
      'status': 'success',
      'data': {
        'customers': [
          {
            'id': 101,
            'name': 'Meenakshi Hotel',
            'address': 'West Tower Street, Madurai',
            'latitude': 9.9195,
            'longitude': 78.1193,
            'geofence_radius': 150,
            'total_sales': 18500.0,
            'total_paid': 12500.0,
            'due_amount': 6000.0,
            'overdue_amount': 0.0,
            'payment_status': 'due',
          },
          {
            'id': 102,
            'name': 'Sri Murugan Mess',
            'address': 'KK Nagar Main Road, Madurai',
            'latitude': 9.9320,
            'longitude': 78.1445,
            'geofence_radius': 180,
            'total_sales': 9000.0,
            'total_paid': 9000.0,
            'due_amount': 0.0,
            'overdue_amount': 0.0,
            'payment_status': 'paid',
          },
        ],
        'tankers': [
          {
            'id': 1,
            'vehicle_number': 'TN-58-BW-2001',
            'model_type': 'Tata LPT 2518 (20KL Dual Chamber)',
            'capacity_kl': 20,
            'capacity_liters': 20000,
            'driver_name': 'K. Murugan',
            'driver_phone': '9842100001',
            'is_active': 1,
            'latitude': 9.9245,
            'longitude': 78.1302,
            'current_speed': 34,
            'current_odometer_km': 45200,
            'last_ping_at': '2026-11-13T10:00:00Z',
          },
        ],
        'can_routes': [
          {
            'id': 1,
            'vehicle_no': 'TN-58-WA-101',
            'driver_name': 'Kumar R.',
            'driver_phone': '+91 98421 55101',
            'route_name': 'Anna Nagar & Teppakulam Route',
            'current_speed': 18,
            'daily_avg_cans': 60,
            'latitude': 9.9212,
            'longitude': 78.1284,
            'last_ping_at': '2026-11-13T10:00:00Z',
          },
          {
            'id': 2,
            'vehicle_no': 'TN-58-WA-102',
            'driver_name': 'Selvam P.',
            'driver_phone': '+91 98421 55102',
            'route_name': 'KK Nagar & Mattuthavani Route',
            'current_speed': 22,
            'daily_avg_cans': 60,
            'latitude': 9.9292,
            'longitude': 78.1394,
            'last_ping_at': '2026-11-13T10:00:00Z',
          },
        ],
      },
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

  testWidgets('FleetGpsScreen renders map customer Paid/Due badges and vehicle pins',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(584, 1000);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiClientProvider.overrideWithValue(FakeApiClient()),
        ],
        child: MaterialApp(
          home: FleetGpsScreen(
            isTamil: false,
            initialMode: FleetViewMode.packagedWater,
            activeRole: UserRole.superAdmin,
            tileProvider: _StubTileProvider(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Customer names are shortened on pins so map stays clean
    expect(find.text('Meenakshi'), findsAtLeastNWidgets(1));
    expect(find.text('Sri Murugan'), findsAtLeastNWidgets(1));
    expect(find.text('TN-58-WA-101'), findsAtLeastNWidgets(1));
    expect(find.text('TN-58-WA-102'), findsAtLeastNWidgets(1));
    expect(find.text('Collected'), findsOneWidget);
    expect(find.text('Total Due'), findsOneWidget);

    // 1st tap: clicking pin pops detailed bubble over pin
    await tester.tap(find.text('Meenakshi').first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('customer_map_callout_bubble_101')),
      findsOneWidget,
    );
    expect(find.text('Meenakshi Hotel'), findsOneWidget);
    expect(find.text('Tap Bubble for Full History & Payments'), findsOneWidget);

    // 2nd tap: clicking bubble opens full interactive Customer 360° history sheet
    await tester.tap(find.text('Tap Bubble for Full History & Payments'));
    await tester.pumpAndSettle();

    expect(find.text('Total Billed'), findsOneWidget);
    expect(find.text('Paid Amount'), findsOneWidget);
    expect(find.text('Due Amount'), findsOneWidget);
    expect(find.textContaining('Should Pay Now'), findsOneWidget);
    expect(find.textContaining('Purchases ('), findsOneWidget);
    expect(find.textContaining('Payments ('), findsOneWidget);
    expect(find.textContaining('Timeline ('), findsOneWidget);

    // Close customer sheet and tap a Delivery Boy in the quick locator strip
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kumar R.').last);
    await tester.pumpAndSettle();

    expect(find.text("Today's Work Summary"), findsOneWidget);
    expect(find.textContaining("Today's Activity Timeline"), findsOneWidget);
    expect(find.textContaining('Delivered 20 Cans to Meenakshi Hotel'), findsOneWidget);
  });

  test('shortenCustomerMapName strips generic business words and truncates cleanly', () {
    expect(shortenCustomerMapName('Meenakshi Hotel'), 'Meenakshi');
    expect(shortenCustomerMapName('Vaigai Bakeries'), 'Vaigai');
    expect(shortenCustomerMapName('Sri Murugan Mess'), 'Sri Murugan');
    expect(shortenCustomerMapName('Madurai Teppakulam Milk Depot'), 'Madurai Te…');
  });

  testWidgets('FleetGpsScreen renders tankers mode without layout errors',
      (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(553, 650);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiClientProvider.overrideWithValue(FakeApiClient()),
        ],
        child: MaterialApp(
          home: FleetGpsScreen(
            isTamil: false,
            initialMode: FleetViewMode.tankers,
            activeRole: UserRole.superAdmin,
            tileProvider: _StubTileProvider(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('TN-58-BW-2001'), findsAtLeastNWidgets(1));
    expect(find.text('Due (1)'), findsOneWidget);
    expect(find.text('Paid (1)'), findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(200, 300));
    await tester.pump();
    await gesture.moveTo(const Offset(250, 350));
    await tester.pump();
    await gesture.removePointer();
  });
}
