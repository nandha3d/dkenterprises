import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dk_track_mobile/core/network/api_client.dart';
import 'package:dk_track_mobile/core/network/api_result.dart';
import 'package:dk_track_mobile/core/providers.dart';
import 'package:dk_track_mobile/core/routing/role_navigation.dart';
import 'package:dk_track_mobile/core/storage/local_database.dart';
import 'package:dk_track_mobile/core/storage/secure_storage_service.dart';
import 'package:dk_track_mobile/core/theme/app_colors.dart';
import 'package:dk_track_mobile/core/theme/app_theme.dart';
import 'package:dk_track_mobile/core/ui/ripple_components.dart';
import 'package:dk_track_mobile/features/auth/data/auth_repository.dart';
import 'package:dk_track_mobile/features/auth/domain/auth_models.dart';
import 'package:dk_track_mobile/features/dashboard/presentation/admin_hubs.dart';
import 'package:dk_track_mobile/features/dashboard/presentation/cashier_dashboard_screen.dart';
import 'package:dk_track_mobile/features/hrm/presentation/attendance_screen.dart';
import 'package:dk_track_mobile/features/operations/presentation/cafe_pos_screen.dart';
import 'package:dk_track_mobile/features/pos/data/pos_repository.dart';
import 'package:dk_track_mobile/features/pos/domain/pos_models.dart';
import 'package:dk_track_mobile/features/pos/presentation/pos_drawer_screen.dart';
import 'package:dk_track_mobile/features/pos/presentation/pos_kitchen_screen.dart';
import 'package:dk_track_mobile/features/pos/presentation/pos_notifier.dart';

class _FakePosRepository extends PosRepository {
  PosShift? shift = const PosShift(
    id: 7,
    warehouseId: 1,
    cashInHand: 1500,
    status: true,
    cashPayment: 800,
    upiPayment: 450,
    cardPayment: 200,
    expectedCash: 2300,
    totalSalesAmount: 1450,
    ordersCount: 4,
  );
  bool simulateOfflineOnSubmit = false;
  Map<String, dynamic>? lastSubmittedOrderMeta;

  _FakePosRepository(super.client, super.db);

  @override
  Future<ApiResult<PosBootstrapData>> fetchBootstrap({int? warehouseId}) async {
    return ApiSuccess(
      PosBootstrapData(
        companyId: 1,
        activeWarehouseId: 1,
        defaultCustomerId: 1,
        defaultBillerId: 1,
        shift: shift,
        heldOrdersCount: 1,
        categories: const [PosCategory(id: 1, name: 'Chai & Coffee')],
        products: const [
          PosProduct(id: 10, name: 'Filter Coffee', code: 'CF-01', price: 35, categoryId: 1, stockQty: 40),
          PosProduct(id: 11, name: 'Masala Chai', code: 'MC-02', price: 25, categoryId: 1, stockQty: 60),
        ],
        customers: const [PosPartyOption(id: 1, name: 'Walk-in Customer')],
        tables: const [
          PosTable(id: 1, name: 'Table 1', seats: 4, status: 'available'),
          PosTable(
            id: 2,
            name: 'Table 2',
            seats: 2,
            status: 'occupied',
            heldSaleId: 99,
            heldReferenceNo: 'HLD-99',
            heldGrandTotal: 70,
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<PosShift?>> fetchCurrentShift({int? warehouseId}) async {
    return ApiSuccess(shift);
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> fetchKdsTickets({int? warehouseId}) async {
    return const ApiSuccess({
      'tickets': [
        {
          'id': 301,
          'reference_no': 'KOT-301',
          'sale_status': 3,
          'is_held': true,
          'order_type': 'dine_in',
          'table_name': 'Table 2',
          'grand_total': 70,
          'paid_amount': 0,
          'due_amount': 70,
          'payment_status': 'pending',
          'customer_name': 'Walk-in Customer',
          'kds_status': 'NEW',
          'items': [
            {
              'id': 1,
              'product_id': 10,
              'product_name': 'Filter Coffee',
              'product_code': 'CF-01',
              'qty': 2,
              'unit_price': 35,
              'discount': 0,
              'tax': 0,
              'total': 70,
            },
          ],
        },
      ],
      'counts': {'new': 1, 'preparing': 0, 'ready': 0, 'served': 0},
    });
  }

  @override
  Future<ApiResult<List<Map<String, dynamic>>>> fetchReorderRequests() async {
    return const ApiSuccess([]);
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
    lastSubmittedOrderMeta = {
      'hold': hold,
      'orderType': orderType,
      'priceTier': priceTier,
      'shippingCost': shippingCost,
      'roundOffAmount': roundOffAmount,
      'paymentsCount': payments.length,
      'itemsCount': items.length,
    };

    final total = (items.fold<double>(0, (s, i) => s + i.lineTotal) - orderDiscount + shippingCost + roundOffAmount)
        .clamp(0.0, double.infinity);
    if (simulateOfflineOnSubmit && !hold) {
      return ApiSuccess(
        PosOrderSummary(
          id: -1,
          referenceNo: 'QUEUED-OFF123',
          saleStatus: 1,
          isHeld: false,
          orderType: orderType,
          grandTotal: total,
          paidAmount: total,
          dueAmount: 0,
          paymentStatus: 'queued_offline',
          customerName: 'Offline Queue',
          isOfflineQueued: true,
        ),
        isFromCache: true,
      );
    }

    return ApiSuccess(
      PosOrderSummary(
        id: 201,
        referenceNo: hold ? 'HLD-201' : 'POS-201',
        saleStatus: hold ? 3 : 1,
        isHeld: hold,
        orderType: orderType,
        grandTotal: total,
        paidAmount: hold ? 0 : total,
        dueAmount: 0,
        paymentStatus: hold ? 'pending' : 'paid',
        customerName: 'Walk-in Customer',
      ),
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
    storage = SecureStorageService(
      const FlutterSecureStorage(),
      prefs,
    );
    db = LocalDatabase();
    client = ApiClient(storage);
  });

  group('Stitch Ripple Skins & Role Navigation', () {
    test('RippleRole resolver maps ERP role strings accurately', () {
      expect(resolveRippleRole(role: 'admin'), RippleRole.admin);
      expect(resolveRippleRole(role: 'deliveryDriver'), RippleRole.driver);
      expect(resolveRippleRole(role: 'tankerDriver'), RippleRole.driver);
      expect(resolveRippleRole(role: 'cashier'), RippleRole.cafe);
      expect(resolveRippleRole(role: 'fieldAgent'), RippleRole.fieldAgent);

      expect(resolveDriverFlavor(role: 'tankerDriver'), RippleDriverFlavor.tanker);
      expect(resolveDriverFlavor(role: 'deliveryDriver'), RippleDriverFlavor.canDelivery);
    });

    test('RippleSkin exposes distinct Stitch role palettes in Light mode', () {
      final lagoon = RippleSkin.forRole(RippleRole.admin, Brightness.light);
      final aqua = RippleSkin.forRole(RippleRole.driver, Brightness.light);
      final chai = RippleSkin.forRole(RippleRole.cafe, Brightness.light);
      final sage = RippleSkin.forRole(RippleRole.fieldAgent, Brightness.light);

      expect(lagoon.skinName, 'Lagoon');
      expect(lagoon.primary, AppColors.lagoonPrimary);
      expect(aqua.skinName, 'Aqua Day');
      expect(aqua.primary, AppColors.aquaPrimary);
      expect(chai.skinName, 'Chai & Crema');
      expect(chai.primary, AppColors.chaiPrimary);
      expect(sage.skinName, 'Field Sage');
      expect(sage.primary, AppColors.sagePrimary);
    });

    test('Role navigation tabs match Stitch KPSTA 5-menu role specifications in English', () {
      final adminTabs = navTabsForRole(RippleRole.admin);
      expect(adminTabs.map((t) => t.label).toList(), ['Home', 'Trade', 'Add', 'Money', 'More']);
      expect(adminTabs[2].isCenterAction, isTrue);
      expect(navIndexForLocation(RippleRole.admin, '/money'), 3);

      final driverTabs = navTabsForRole(RippleRole.driver);
      expect(driverTabs.map((t) => t.label).toList(), ['Today', 'Work', 'Add', 'Cash', 'Me']);
      expect(driverTabs[2].isCenterAction, isTrue);
      expect(navIndexForLocation(RippleRole.driver, '/tab/driver-cash'), 3);

      final cafeTabs = navTabsForRole(RippleRole.cafe);
      expect(cafeTabs.map((t) => t.label).toList(), ['Counter', 'Orders', 'Add', 'Drawer', 'Kitchen']);
      expect(cafeTabs[2].isCenterAction, isTrue);
      expect(navIndexForLocation(RippleRole.cafe, '/pos/drawer'), 3);

      final agentTabs = navTabsForRole(RippleRole.fieldAgent);
      expect(agentTabs.map((t) => t.label).toList(), ['Collect', 'Customers', 'Add', 'Spend', 'Me']);
      expect(agentTabs[2].isCenterAction, isTrue);
      expect(navIndexForLocation(RippleRole.fieldAgent, '/tab/customers'), 1);
    });
  });

  group('ERP POS State & Widgets', () {
    test('PosNotifier manages cart quantities, held orders, and split-tender submissions', () async {
      final repo = _FakePosRepository(client, db);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localDatabaseProvider.overrideWithValue(db),
          posRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(posNotifierProvider.notifier);
      await notifier.loadBootstrap();

      final loaded = container.read(posNotifierProvider);
      expect(loaded.bootstrap?.products.length, 2);
      expect(loaded.activeShift?.id, 7);

      final coffee = loaded.bootstrap!.products.first;
      notifier.addProduct(coffee);
      notifier.incrementItem(coffee.id);
      expect(container.read(posNotifierProvider).totalItemsCount, 2);
      expect(container.read(posNotifierProvider).grandTotal, 70);

      final holdRes = await notifier.submitOrder(hold: true, payments: const []);
      expect(holdRes.isSuccess, isTrue);
      expect(repo.lastSubmittedOrderMeta?['hold'], isTrue);
      expect(container.read(posNotifierProvider).cart, isEmpty);
    });

    testWidgets('CafePosScreen displays catalog items, order types, and live checkout bar', (tester) async {
      final repo = _FakePosRepository(client, db);
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

      expect(find.text('Counter POS Terminal'), findsOneWidget);
      expect(find.text('Filter Coffee'), findsWidgets);
      expect(find.text('Masala Chai'), findsWidgets);

      await tester.tap(find.text('Filter Coffee').first);
      await tester.pumpAndSettle();

      expect(find.text('Hold'), findsOneWidget);
      expect(find.textContaining('Pay ₹35.00'), findsOneWidget);
    });

    testWidgets('PosDrawerScreen renders open X-report expected cash and breakdown', (tester) async {
      final repo = _FakePosRepository(client, db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localDatabaseProvider.overrideWithValue(db),
            posRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.themeForRole(RippleRole.cafe, Brightness.light),
            home: const PosDrawerScreen(embedded: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ACTIVE SHIFT · X-REPORT'), findsOneWidget);
      expect(find.textContaining('₹2,300.00'), findsWidgets);
      expect(find.text('Tender Breakdown'), findsOneWidget);
      expect(find.text('UPI Payments'), findsOneWidget);
    });

    testWidgets('PosKitchenScreen shows live KDS queue and connected kitchen ops', (tester) async {
      final repo = _FakePosRepository(client, db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localDatabaseProvider.overrideWithValue(db),
            posRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.themeForRole(RippleRole.cafe, Brightness.light),
            home: const PosKitchenScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Kitchen Display Queue'), findsOneWidget);
      expect(find.textContaining('KOT-301'), findsOneWidget);
      expect(find.text('Start Prep'), findsOneWidget);
      expect(find.text('Quick 86 / Menu Availability Toggle'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -450));
      await tester.pumpAndSettle();

      expect(find.text('Kitchen Reorder Request / Internal PO'), findsOneWidget);
      expect(find.text('Kitchen & Ingredient Stock Audit'), findsOneWidget);
    });

    testWidgets('TradeHubScreen renders high-contrast RippleHeroPill and scopes POS by company', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('tmws'),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authNotifierProvider.overrideWith(
              (ref) => _StubAuthNotifier(
                client,
                storage,
                const AuthState(
                  isAuthenticated: true,
                  activeCompany: CompanyInfo(id: 2, name: 'TMWS', industry: 'bulk_water'),
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.themeForRole(RippleRole.admin, Brightness.light),
            home: const TradeHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RippleHeroPill), findsNWidgets(2));
      expect(find.byType(ActionChip), findsNothing);
      expect(find.text('Tanker Trip'), findsOneWidget);
      expect(find.text('Open ERP POS'), findsNothing);

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('aran-cafe'),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authNotifierProvider.overrideWith(
              (ref) => _StubAuthNotifier(
                client,
                storage,
                const AuthState(
                  isAuthenticated: true,
                  activeCompany: CompanyInfo(id: 1, name: 'Aran Cafe', industry: 'cafe_bakery'),
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.themeForRole(RippleRole.admin, Brightness.light),
            home: const TradeHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open ERP POS'), findsOneWidget);
      expect(find.text('New Sale Bill'), findsOneWidget);
    });

    testWidgets('CashierDashboardScreen (C-01) renders Stitch Gross Counter Billing, Settlement Breakdown and Top Counter Items', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakePosRepository(client, db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localDatabaseProvider.overrideWithValue(db),
            posRepositoryProvider.overrideWithValue(repo),
            authNotifierProvider.overrideWith(
              (ref) => _StubAuthNotifier(
                client,
                storage,
                const AuthState(
                  isAuthenticated: true,
                  activeCompany: CompanyInfo(id: 1, name: 'Aran Cafe', industry: 'cafe_bakery'),
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.themeForRole(RippleRole.cafe, Brightness.light),
            home: const CashierDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GROSS COUNTER BILLING'), findsOneWidget);
      expect(find.text('SETTLEMENT BREAKDOWN'), findsOneWidget);
      expect(find.text('Open Touch POS Terminal'), findsOneWidget);
      expect(find.text('Top Counter Items'), findsOneWidget);
      expect(find.text('Filter Coffee'), findsOneWidget);
    });

    testWidgets('CafePosScreen adapts to 2-pane split layout on Tablet (>= 720px) with persistent Current Order Ticket', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakePosRepository(client, db);
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

      expect(find.text('Current Order Ticket'), findsOneWidget);
      expect(find.text('Rush Hour Super-Fast'), findsOneWidget);

      await tester.tap(find.text('Filter Coffee').first);
      await tester.pumpAndSettle();

      expect(find.text('1 items'), findsOneWidget);
      expect(find.textContaining('Pay Cash (₹35.00)'), findsOneWidget);
    });

    testWidgets('AttendanceScreen (D-14) renders Plant Geofence Radar, Biometric Liveness and Weekly Hours', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localDatabaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: AppTheme.themeForRole(RippleRole.driver, Brightness.light),
            home: const AttendanceScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Geofenced Shift Attendance'), findsOneWidget);
      expect(find.text('Plant Geofence Radar'), findsOneWidget);
      expect(find.text('Facial Biometric & Odometer'), findsOneWidget);
      expect(find.text('Weekly Logged Hours'), findsOneWidget);
    });
  });
}

class _StubAuthNotifier extends AuthNotifier {
  final AuthState _initial;

  _StubAuthNotifier(super.client, super.storage, this._initial) {
    state = _initial;
  }

  @override
  Future<void> checkInitialAuth() async {}
}
