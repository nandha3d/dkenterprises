import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_endpoints.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/core/storage/local_database.dart';
import 'package:dk_track_mobile/core/storage/secure_storage_service.dart';
import 'package:dk_track_mobile/core/theme/app_theme.dart';
import 'package:dk_track_mobile/core/ui/pos_print_preview_sheet.dart';
import 'package:dk_track_mobile/features/operations/presentation/cafe_pos_screen.dart';
import 'package:dk_track_mobile/features/operations/presentation/can_sales_screen.dart';
import 'package:dk_track_mobile/features/operations/presentation/driver_surrender_screen.dart';
import 'package:dk_track_mobile/features/operations/presentation/tanker_trip_screen.dart';
import 'package:dk_track_mobile/features/pos/data/pos_repository.dart';
import 'package:dk_track_mobile/features/pos/domain/pos_models.dart';
import 'package:dk_track_mobile/features/pos/presentation/pos_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SpecFakePosRepository extends PosRepository {
  Map<String, dynamic>? lastSubmittedOrderMeta;
  int submitCallCount = 0;

  _SpecFakePosRepository(super.client, super.db);

  @override
  Future<ApiResult<PosBootstrapData>> fetchBootstrap({int? warehouseId}) async {
    return const ApiSuccess(
      PosBootstrapData(
        companyId: 1,
        activeWarehouseId: 1,
        defaultCustomerId: 5,
        defaultBillerId: 1,
        shift: PosShift(
          id: 9,
          warehouseId: 1,
          cashInHand: 1000,
          status: true,
        ),
        categories: [PosCategory(id: 1, name: 'Beverages')],
        customers: [
          PosPartyOption(
            id: 5,
            name: 'Credit Capped Guest',
            creditLimit: 50,
            dueAmount: 30,
          ),
        ],
        products: [
          PosProduct(id: 10, name: 'Filter Coffee', code: 'CF-01', price: 35, categoryId: 1, stockQty: 40),
          PosProduct(id: 11, name: 'Masala Chai', code: 'MC-02', price: 25, categoryId: 1, stockQty: 60),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<PosOrderSummary>> submitOrder({
    int? resumingOrderId,
    required bool hold,
    required String orderType,
    int? warehouseId,
    int? customerId,
    int? billerId,
    int? tableId,
    int? cashRegisterId,
    double orderDiscount = 0,
    double orderTaxRate = 0,
    double shippingCost = 0,
    double roundOffAmount = 0,
    String priceTier = 'Retail MRP',
    String? saleNote,
    required List<PosPaymentSplit> payments,
    required List<PosCartItem> items,
  }) async {
    submitCallCount++;
    lastSubmittedOrderMeta = {
      'hold': hold,
      'orderType': orderType,
      'shippingCost': shippingCost,
      'roundOffAmount': roundOffAmount,
      'priceTier': priceTier,
      'payments': payments.map((p) => {'method': p.method, 'amount': p.amount}).toList(),
      'items': items
          .map((i) => {
                'id': i.product.id,
                'qty': i.qty,
                'unitPrice': i.unitPrice,
                'note': i.note,
              })
          .toList(),
    };

    final total = items.fold<double>(0, (sum, i) => sum + i.lineTotal) -
        orderDiscount +
        shippingCost +
        roundOffAmount;

    return ApiSuccess(
      PosOrderSummary(
        id: 501,
        referenceNo: hold ? 'HLD-501' : 'POS-501',
        saleStatus: hold ? 3 : 1,
        isHeld: hold,
        orderType: orderType,
        grandTotal: total,
        paidAmount: hold ? 0 : total,
        dueAmount: 0,
        paymentStatus: hold ? 'pending' : 'paid',
        customerName: 'Credit Capped Guest',
      ),
    );
  }
}

class _SpecFakeApiClient implements ApiClient {
  final List<({String path, Map<String, dynamic> payload})> posts = [];

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
              'name': 'Balaji Cafe',
              'latitude': 11.0182210,
              'longitude': 76.9641190,
              'geofence_radius': 150,
              'master_can_rate': 35.0,
              'shop_qr_code': 'DKW-SHOP-5',
            },
          ],
        }),
      );
    }

    if (path == ApiEndpoints.bootstrap) {
      return ApiSuccess(
        fromJson({
          'data': {
            'company_name': 'DK Water Logistics',
            'upi_vpa': 'dktest@upi',
            'packages': [
              {'id': 1, 'name': '20 KL Tanker Load', 'capacity_kl': 20, 'price': 3800},
            ],
          },
        }),
      );
    }

    if (path == ApiEndpoints.driverManifest) {
      return ApiSuccess(
        fromJson({
          'data': {
            'route_id': 1,
            'company_name': 'DK Waters Test Co',
            'gstin': '33TESTGST1234F1Z5',
            'upi_vpa': 'dktest@upi',
            'manager_override_pin': '2580',
            'jar_deposit_rate': 150.0,
            'vehicle': {
              'id': 1,
              'vehicle_number': 'TN-99-TEST-01',
              'capacity_kl': 20.0,
              'current_odometer': 1000,
              'current_odometer_km': 1000,
            },
            'can_inventory': {
              'loaded_cans': 60,
              'remaining_full_cans': 46,
            },
            'rate_slabs': [
              {'label': 'Standard', 'rate': 35},
              {'label': 'Corporate', 'rate': 30},
            ],
            'pending_trips': [
              {
                'id': 77,
                'trip_number': 'TRP-077',
                'customer_id': 5,
                'customer_name': 'Texvalley Spinning Mills',
                'destination_site': 'Perundurai SIPCOT Phase 2',
                'water_quantity_kl': 20.0,
                'trip_rate': 3800.0,
                'start_odometer': 1000,
                'status': 'dispatched',
              },
            ],
          },
        }),
      );
    }

    return ApiSuccess(fromJson({'data': <String, dynamic>{}}));
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    required T Function(dynamic data) fromJson,
  }) async {
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    posts.add((path: path, payload: map));
    return ApiSuccess(
      fromJson({
        'data': {
          'id': 901,
          'delivery_no': 'CAN-20261113-TEST01',
          'cash_surrendered': map['cash_surrendered'] ?? 1365.0,
          'audit_summary': {'cash_shortage': 0.0},
        },
      }),
    );
  }
}

void main() {
  late SharedPreferences prefs;
  late SecureStorageService storage;
  late LocalDatabase db;
  late ApiClient client;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SecureStorageService(const FlutterSecureStorage(), prefs);
    db = LocalDatabase();
    client = ApiClient(storage);
  });

  group('Low-Level Spec Sections 3 to 6 Automated Verification', () {
    testWidgets(
      'Section 3: CafePosScreen SensiblePOS rate slabs, barcode Enter-to-add, fractional modifier sheet, packing & credit limit guard',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = _SpecFakePosRepository(client, db);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              localDatabaseProvider.overrideWithValue(db),
              posRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              theme: AppTheme.themeForRole(RippleRole.cafe, Brightness.light),
              home: const CafePosScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Switch Price Tier to Wholesale and verify repriced label
        await tester.tap(find.text('Wholesale'));
        await tester.pumpAndSettle();
        expect(find.text('Subtotal (Wholesale)'), findsOneWidget);

        // 2. Scan/enter exact PLU code MC-02 + submit via Enter -> adds Masala Chai
        final searchField = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == 'Search menu items or scan barcode + Enter...',
        );
        expect(searchField, findsOneWidget);
        await tester.enterText(searchField, 'MC-02');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text('1 items'), findsOneWidget);

        // 3. Switch back to Retail MRP (₹25.00), open line modifier sheet, set fractional qty 0.50 + Less Sugar
        await tester.tap(find.text('Retail MRP'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Masala Chai').last);
        await tester.pumpAndSettle();
        expect(find.textContaining('Line Modifiers'), findsOneWidget);

        await tester.tap(find.text('0.50x'));
        await tester.tap(find.text('Less Sugar'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply Line Changes'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Less Sugar'), findsOneWidget);

        // 4. Add packing charge (₹15) and verify Credit tender triggers client-side Credit Limit block
        final packingField = find.descendant(
          of: find.ancestor(of: find.text('Packing / Parcel (₹)'), matching: find.byType(Row)).first,
          matching: find.byType(TextField),
        );
        await tester.enterText(packingField, '15');
        await tester.pumpAndSettle();

        // Filter Coffee click increases total above ₹20 headroom cleanly
        await tester.tap(find.text('Filter Coffee').first);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ChoiceChip, 'Credit'));
        await tester.pumpAndSettle();
        expect(find.text('LIMIT EXCEEDED'), findsOneWidget);

        await tester.tap(find.textContaining('Pay Credit'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Credit Limit Exceeded'), findsOneWidget);
        expect(repo.submitCallCount, 0);

        ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
        await tester.pumpAndSettle();

        // 5. Complete payment on Cash and verify payload metadata sent to repository
        await tester.tap(find.widgetWithText(ChoiceChip, 'Cash'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Pay Cash'));
        await tester.pumpAndSettle();

        expect(repo.submitCallCount, 1);
        expect(repo.lastSubmittedOrderMeta?['shippingCost'], 15.0);
        expect(repo.lastSubmittedOrderMeta?['priceTier'], 'Retail MRP');
        final items = repo.lastSubmittedOrderMeta?['items'] as List<dynamic>;
        final chaiLine = items.cast<Map<String, dynamic>>().firstWhere((e) => e['id'] == 11);
        expect(chaiLine['qty'], 0.5);
        expect(chaiLine['note'], 'Less Sugar');
      },
    );

    testWidgets(
      'Section 4: PosPrintPreviewSheet supports all 5 thermal/KOT/TSPL2 label templates',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1100);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: MaterialApp(
              theme: AppTheme.themeForRole(RippleRole.cafe, Brightness.light),
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        PosPrintPreviewSheet.show(
                          context,
                          companyName: 'Aran Cafe',
                          branchName: 'Main Branch',
                          referenceNo: 'POS-2026-0042',
                          tokenNumber: '0042',
                          customerName: 'Walk-in Guest',
                          items: const [
                            PosPrintLineItem(
                              name: 'Filter Coffee',
                              code: 'CF-01',
                              qty: 2,
                              unitPrice: 35.0,
                              note: 'Extra Strong, Less Sugar',
                            ),
                          ],
                          grandTotal: 70.0,
                          paidAmount: 70.0,
                        );
                      },
                      child: const Text('Open Print Studio'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Print Studio'));
        await tester.pumpAndSettle();

        expect(find.text('80mm Receipt + Token'), findsOneWidget);
        expect(find.text('58mm Pocket Slip'), findsOneWidget);
        expect(find.text('KOT Kitchen Slip'), findsOneWidget);
        expect(find.text('50x25mm Barcode Label'), findsOneWidget);
        expect(find.text('50x38mm Seal / Jar Tag'), findsOneWidget);

        Future<void> tapFormatPill(String label) async {
          final finder = find.text(label);
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }

        await tapFormatPill('58mm Pocket Slip');
        expect(find.textContaining('POS-2026-0042'), findsWidgets);

        await tapFormatPill('KOT Kitchen Slip');
        expect(find.textContaining('EXTRA STRONG, LESS SUGAR'), findsWidgets);

        await tapFormatPill('50x25mm Barcode Label');
        expect(find.text('50×25mm LABEL'), findsOneWidget);
        expect(find.textContaining('SIZE 50 mm, 25 mm'), findsOneWidget);

        await tapFormatPill('50x38mm Seal / Jar Tag');
        expect(find.text('50×38mm SEAL'), findsOneWidget);
        expect(find.textContaining('SIZE 50 mm, 38 mm'), findsOneWidget);
      },
    );

    testWidgets(
      'Section 5: TankerTripScreen tracks Moving -> At Site -> Motor Start/Stop -> End Dwell & odometer audit',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeClient = _SpecFakeApiClient();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              localDatabaseProvider.overrideWithValue(db),
              apiClientProvider.overrideWithValue(fakeClient),
            ],
            child: MaterialApp(
              theme: AppTheme.themeForRole(RippleRole.driver, Brightness.light),
              home: TankerTripScreen(
                gpsFetcher: () async => (lat: 11.3450, lng: 77.7110),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 0. Assigned order TRP-077 is pre-loaded from driverManifest pending_trips
        expect(find.textContaining('TRP-077'), findsWidgets);

        // 1. Start Moving (GPS)
        await tester.tap(find.text('1. Start Moving (GPS)'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('MOVING · GPS TRACKING'), findsOneWidget);

        // 2. Arrived at Place
        await tester.tap(find.text('2. Arrived at Place'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('AT SITE · DWELL TIMER'), findsOneWidget);

        // 3. Start Motor -> Stop Motor
        await tester.tap(find.text('Start Motor'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('MOTOR PUMPING ACTIVE'), findsOneWidget);
        expect(find.text('Stop Motor'), findsOneWidget);

        await tester.tap(find.text('Stop Motor'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('AT SITE · DWELL TIMER'), findsOneWidget);

        // 4. End Dwell & Lock cancels chronometer timer cleanly
        await tester.tap(find.text('3. End Dwell & Lock'));
        await tester.pumpAndSettle();
        expect(find.text('TRIP LOCKED'), findsOneWidget);
        expect(find.text('Automatic Motor Timing & Surcharge'), findsOneWidget);

        // 5. Enter End Odometer (1000 -> 1038) and verify delta
        final endOdoField = find.widgetWithText(TextFormField, 'End Odometer (KM)');
        await tester.ensureVisible(endOdoField);
        await tester.enterText(endOdoField, '1038');
        await tester.pumpAndSettle();

        expect(find.textContaining('Odometer Delta: 38 km'), findsOneWidget);

        // 6. Submit assigned tanker order to /water/trips/77/process
        final submitTripBtn = find.text('Complete & Post Trip Sheet');
        await tester.ensureVisible(submitTripBtn);
        await tester.tap(submitTripBtn);
        await tester.pumpAndSettle();

        expect(fakeClient.posts, isNotEmpty);
        expect(fakeClient.posts.last.path, ApiEndpoints.tankerTripProcess(77));
        expect(fakeClient.posts.last.payload['status'], 'completed');
      },
    );

    testWidgets(
      'Section 6a: CanSalesScreen blocks submission on Hardware Mock GPS',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeClient = _SpecFakeApiClient();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              localDatabaseProvider.overrideWithValue(db),
              apiClientProvider.overrideWithValue(fakeClient),
            ],
            child: MaterialApp(
              theme: AppTheme.themeForRole(RippleRole.driver, Brightness.light),
              home: CanSalesScreen(
                gpsFetcher: () async => (lat: 11.0182, lng: 76.9641, isMocked: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('FAKE / MOCK GPS DETECTED — DELIVERY BLOCKED'), findsOneWidget);
        final submitBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Print & Save Ticket'),
        );
        expect(submitBtn.onPressed, isNull);
      },
    );

    testWidgets(
      'Section 6b: CanSalesScreen 7-Layer Shield (Wall QR, Override PIN, Jar Deficit Photo, UPI QR, Credit PIN) & DriverSurrenderScreen Blind Tally',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeClient = _SpecFakeApiClient();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              localDatabaseProvider.overrideWithValue(db),
              apiClientProvider.overrideWithValue(fakeClient),
            ],
            child: MaterialApp(
              theme: AppTheme.themeForRole(RippleRole.driver, Brightness.light),
              home: CanSalesScreen(
                gpsFetcher: () async => (lat: 11.0282, lng: 76.9641, isMocked: false),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Layer 4: Outside 150m Geofence -> Enter & Verify Shop Wall QR
        expect(find.textContaining('Outside Shop Geofence'), findsOneWidget);
        await tester.tap(find.text('Scan Wall QR'));
        await tester.pumpAndSettle();
        expect(find.text('Verify Shop Wall QR Sticker'), findsOneWidget);
        await tester.enterText(find.widgetWithText(TextField, 'Shop QR Code'), 'DKW-SHOP-5');
        await tester.tap(find.text('Verify Premises'));
        await tester.pumpAndSettle();
        expect(find.text('Shop Wall QR Verified (DKW-SHOP-5)'), findsOneWidget);

        // Layer 2: Master Rate Lock -> Unlock with Manager PIN 2580
        await tester.tap(find.text('Corporate ₹30'));
        await tester.pumpAndSettle();
        expect(find.text('Manager Override PIN Required'), findsOneWidget);
        await tester.enterText(find.byType(TextField).last, '2580');
        await tester.tap(find.text('Unlock Rate'));
        await tester.pumpAndSettle();
        expect(find.text('PIN OVERRIDE · ₹30'), findsOneWidget);

        // Layer 3: Increment Delivered Full Cans (0 -> 2) & Returned Empties (0 -> 1) -> +1 deficit
        final plusBtns = find.byIcon(Icons.add_rounded);
        await tester.ensureVisible(plusBtns.first);
        await tester.tap(plusBtns.first);
        await tester.tap(plusBtns.first);
        await tester.ensureVisible(plusBtns.last);
        await tester.tap(plusBtns.last);
        await tester.pumpAndSettle();
        expect(find.textContaining('Empty Jar Hold: +1 jars retained'), findsOneWidget);

        final photoBtn = find.text('Capture Timestamped Stack Photo Proof');
        await tester.ensureVisible(photoBtn);
        await tester.tap(photoBtn);
        await tester.pumpAndSettle();
        expect(find.textContaining('Stack Photo Verified'), findsOneWidget);

        // Switch to UPI to verify Amount-Locked QR (2 * 30 = ₹60.00)
        final upiBtn = find.text('UPI');
        await tester.ensureVisible(upiBtn);
        await tester.tap(upiBtn);
        await tester.pumpAndSettle();
        expect(find.text('Amount-Locked Company UPI QR'), findsOneWidget);
        expect(find.textContaining('₹60.00'), findsWidgets);

        // Switch to Credit -> enter 4-digit customer confirmation PIN & submit
        await tester.tap(find.text('Credit'));
        await tester.pumpAndSettle();
        expect(find.text('Credit Approval — Customer PIN Required'), findsOneWidget);
        final creditPinField = find.widgetWithText(TextFormField, 'Customer Credit Confirmation PIN');
        await tester.ensureVisible(creditPinField);
        await tester.enterText(creditPinField, '4829');
        await tester.pumpAndSettle();

        final submitBtn = find.widgetWithText(ElevatedButton, 'Print & Save Ticket');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(fakeClient.posts, isNotEmpty);
        final post = fakeClient.posts.last;
        expect(post.path, ApiEndpoints.waterCanDeliveries);
        expect(post.payload['qr_verified'], isTrue);
        expect(post.payload['rate_override_used'], isTrue);
        expect(post.payload['override_pin'], '2580');
        expect(post.payload['credit_pin'], '4829');
        expect(post.payload['empty_jar_photo_verified'], isTrue);
        expect(post.payload['is_mock_gps'], isFalse);

        // Blind Note Denomination Tally on DriverSurrenderScreen
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              localDatabaseProvider.overrideWithValue(db),
              apiClientProvider.overrideWithValue(fakeClient),
            ],
            child: MaterialApp(
              theme: AppTheme.themeForRole(RippleRole.driver, Brightness.light),
              home: const DriverSurrenderScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Blind Note Denomination Tally'), findsOneWidget);
        await tester.enterText(find.widgetWithText(TextFormField, '₹500 Notes'), '2');
        await tester.enterText(find.widgetWithText(TextFormField, '₹100 Notes'), '3');
        await tester.enterText(find.widgetWithText(TextFormField, '₹50 Notes'), '1');
        await tester.enterText(find.widgetWithText(TextFormField, 'Loose Coins (₹)'), '15');
        await tester.pumpAndSettle();

        expect(find.text('Notes: ₹1365'), findsOneWidget);
        expect(find.text('= ₹1000'), findsOneWidget);
        expect(find.text('= ₹300'), findsOneWidget);
      },
    );
  });
}
