import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/storage/local_database.dart';
import '../domain/pos_models.dart';

/// Repository wiring mobile POS directly to the Laravel ERP POS API (`/api/v1/pos/*`)
/// with SQLite offline cache + outbox fallback for counter checkouts.
class PosRepository {
  final ApiClient _client;
  final LocalDatabase _db;
  final int? activeCompanyId;
  final Uuid _uuid = const Uuid();

  PosRepository(this._client, this._db, {this.activeCompanyId});

  String get _bootstrapCacheKey => 'pos_bootstrap_v1_company_${activeCompanyId ?? 0}';
  String get _shiftCacheKey => 'pos_active_shift_v1_company_${activeCompanyId ?? 0}';

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
  }

  bool _isNotFoundFailure(NetworkFailure f) {
    final msg = f.message.toLowerCase();
    return f.statusCode == 404 || msg.contains('could not be found');
  }

  Future<void> _saveBootstrapCache(PosBootstrapData data) async {
    await _db.saveCache(_bootstrapCacheKey, {
      'company_id': data.companyId,
      'active_warehouse_id': data.activeWarehouseId,
      'default_customer_id': data.defaultCustomerId,
      'default_biller_id': data.defaultBillerId,
      'order_types': data.orderTypes,
      'payment_methods': data.paymentMethods,
      'categories': data.categories.map((c) => c.toJson()).toList(),
      'products': data.products.map((p) => p.toJson()).toList(),
      'warehouses': data.warehouses.map((w) => w.toJson()).toList(),
      'customers': data.customers.map((c) => c.toJson()).toList(),
    });
  }

  Future<ApiResult<PosBootstrapData>> fetchBootstrap({int? warehouseId}) async {
    final res = await _client.get<PosBootstrapData>(
      ApiEndpoints.posBootstrap,
      queryParameters: warehouseId != null ? {'warehouse_id': warehouseId} : null,
      fromJson: (raw) => PosBootstrapData.fromJson(_unwrapMap(raw)),
    );

    if (res is ApiSuccess<PosBootstrapData>) {
      await _saveBootstrapCache(res.data);
      return res;
    }

    if (res case ApiFailure<PosBootstrapData>(failure: final f)) {
      if (_isNotFoundFailure(f)) {
        final legacyRes = await _fetchLegacyBootstrapFallback();
        if (legacyRes is ApiSuccess<PosBootstrapData>) {
          await _saveBootstrapCache(legacyRes.data);
          return legacyRes;
        }
      }

      if (f.isNetworkError || _isNotFoundFailure(f)) {
        final cached = await _db.getCache(_bootstrapCacheKey);
        if (cached is Map) {
          return ApiSuccess(
            PosBootstrapData.fromJson(Map<String, dynamic>.from(cached)),
            isFromCache: true,
          );
        }
      }
    }
    return res;
  }

  Future<ApiResult<PosBootstrapData>> _fetchLegacyBootstrapFallback() async {
    final productsRes = await _client.get<List<Map<String, dynamic>>>(
      ApiEndpoints.products,
      fromJson: (raw) {
        final list = raw is Map && raw['data'] is List
            ? raw['data'] as List
            : (raw is List ? raw : const []);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );

    List<Map<String, dynamic>> rawProducts = const [];
    if (productsRes is ApiSuccess<List<Map<String, dynamic>>>) {
      rawProducts = productsRes.data;
    } else {
      final menuRes = await _client.get<List<Map<String, dynamic>>>(
        ApiEndpoints.cafeMenu,
        fromJson: (raw) {
          final map = _unwrapMap(raw);
          final list = map['items'] is List
              ? map['items'] as List
              : (raw is List ? raw : const []);
          return list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        },
      );
      if (menuRes is ApiSuccess<List<Map<String, dynamic>>>) {
        rawProducts = menuRes.data;
      } else if (productsRes is ApiFailure<List<Map<String, dynamic>>>) {
        return ApiFailure(productsRes.failure);
      }
    }

    if (activeCompanyId != null) {
      final scoped = rawProducts.where((p) {
        final cid = int.tryParse((p['company_id'] ?? '').toString());
        return cid == null || cid == activeCompanyId;
      }).toList();
      if (scoped.isNotEmpty || rawProducts.any((p) => p['company_id'] != null)) {
        rawProducts = scoped;
      }
    }

    final categoriesById = <int, PosCategory>{};
    for (final p in rawProducts) {
      final catId = int.tryParse((p['category_id'] ?? '').toString());
      final catName = (p['category_name'] ?? p['category'] ?? '').toString().trim();
      if (catId != null && catId > 0) {
        categoriesById[catId] = PosCategory(
          id: catId,
          name: catName.isNotEmpty ? catName : 'Category #$catId',
        );
      }
    }

    List<PosPartyOption> customers = const [
      PosPartyOption(id: 1, name: 'Walk-in Customer'),
    ];
    final customersRes = await _client.get<List<PosPartyOption>>(
      ApiEndpoints.customers,
      fromJson: (raw) {
        final list = raw is Map && raw['data'] is List
            ? raw['data'] as List
            : (raw is List ? raw : const []);
        return list
            .whereType<Map>()
            .where((c) {
              if (activeCompanyId == null || c['company_id'] == null) {
                return true;
              }
              return int.tryParse(c['company_id'].toString()) == activeCompanyId;
            })
            .map((e) => PosPartyOption.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    if (customersRes is ApiSuccess<List<PosPartyOption>> &&
        customersRes.data.isNotEmpty) {
      customers = customersRes.data;
    }

    final products = rawProducts.map(PosProduct.fromJson).toList();
    final isCafeCompany = activeCompanyId == null || activeCompanyId == 3;

    return ApiSuccess(
      PosBootstrapData(
        companyId: activeCompanyId ?? 0,
        activeWarehouseId: 1,
        defaultCustomerId: customers.first.id,
        defaultBillerId: 1,
        tableEnabled: isCafeCompany,
        orderTypes: isCafeCompany
            ? const ['dine_in', 'takeaway', 'delivery']
            : const ['takeaway', 'delivery'],
        paymentMethods: const ['Cash', 'UPI', 'Card', 'Credit'],
        customers: customers,
        categories: categoriesById.values.toList(),
        products: products,
      ),
    );
  }

  Future<ApiResult<PosShift?>> fetchCurrentShift({int? warehouseId}) async {
    final res = await _client.get<PosShift?>(
      ApiEndpoints.posCurrentShift,
      queryParameters: warehouseId != null ? {'warehouse_id': warehouseId} : null,
      fromJson: (raw) {
        final map = _unwrapMap(raw);
        if (map['shift'] is Map) {
          return PosShift.fromJson(Map<String, dynamic>.from(map['shift'] as Map));
        }
        return null;
      },
    );

    if (res case ApiSuccess<PosShift?>(data: final shift)) {
      if (shift != null) {
        await _db.saveCache(_shiftCacheKey, shift.toJson());
      } else {
        await _db.saveCache(_shiftCacheKey, {'status': false});
      }
      return res;
    }

    if (res case ApiFailure<PosShift?>(failure: final f)
        when _isNotFoundFailure(f) || f.isNetworkError) {
      final cached = await _db.getCache(_shiftCacheKey);
      if (cached is Map && (cached['status'] == true || cached['status'] == 1)) {
        return ApiSuccess(
          PosShift.fromJson(Map<String, dynamic>.from(cached)),
          isFromCache: true,
        );
      }
      return const ApiSuccess(null, isFromCache: true);
    }

    return res;
  }

  Future<ApiResult<PosShift>> openShift({
    required double cashInHand,
    int? warehouseId,
  }) async {
    final res = await _client.post<PosShift>(
      ApiEndpoints.posOpenShift,
      data: {
        'cash_in_hand': cashInHand,
        if (warehouseId != null) 'warehouse_id': warehouseId,
      },
      fromJson: (raw) {
        final map = _unwrapMap(raw);
        final shiftMap =
            map['shift'] is Map ? Map<String, dynamic>.from(map['shift'] as Map) : map;
        return PosShift.fromJson(shiftMap);
      },
    );

    if (res case ApiSuccess<PosShift>(data: final opened)) {
      await _db.saveCache(_shiftCacheKey, opened.toJson());
      return res;
    }

    if (res case ApiFailure<PosShift>(failure: final f)
        when _isNotFoundFailure(f) || f.isNetworkError) {
      final localShift = PosShift(
        id: DateTime.now().millisecondsSinceEpoch,
        warehouseId: warehouseId ?? 1,
        cashInHand: cashInHand,
        status: true,
        openedAt: DateTime.now().toIso8601String(),
        expectedCash: cashInHand,
      );
      await _db.saveCache(_shiftCacheKey, localShift.toJson());
      return ApiSuccess(localShift, isFromCache: true);
    }

    return res;
  }

  Future<ApiResult<PosShift>> closeShift({
    required double actualCash,
    int? cashRegisterId,
    int? warehouseId,
    String? note,
  }) async {
    final res = await _client.post<PosShift>(
      ApiEndpoints.posCloseShift,
      data: {
        'actual_cash': actualCash,
        if (cashRegisterId != null) 'cash_register_id': cashRegisterId,
        if (warehouseId != null) 'warehouse_id': warehouseId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      fromJson: (raw) {
        final map = _unwrapMap(raw);
        final shiftMap =
            map['shift'] is Map ? Map<String, dynamic>.from(map['shift'] as Map) : map;
        return PosShift.fromJson(shiftMap);
      },
    );

    if (res case ApiSuccess<PosShift>()) {
      await _db.saveCache(_shiftCacheKey, {'status': false});
      return res;
    }

    if (res case ApiFailure<PosShift>(failure: final f)
        when _isNotFoundFailure(f) || f.isNetworkError) {
      final cached = await _db.getCache(_shiftCacheKey);
      final prev = (cached is Map)
          ? PosShift.fromJson(Map<String, dynamic>.from(cached))
          : null;
      final expectedCash = prev?.expectedCash ?? actualCash;
      final closedShift = PosShift(
        id: prev?.id ?? cashRegisterId ?? DateTime.now().millisecondsSinceEpoch,
        warehouseId: prev?.warehouseId ?? warehouseId ?? 1,
        cashInHand: prev?.cashInHand ?? 0,
        closingBalance: actualCash,
        status: false,
        openedAt: prev?.openedAt,
        closedAt: DateTime.now().toIso8601String(),
        cashPayment: prev?.cashPayment ?? 0,
        upiPayment: prev?.upiPayment ?? 0,
        cardPayment: prev?.cardPayment ?? 0,
        bankPayment: prev?.bankPayment ?? 0,
        chequePayment: prev?.chequePayment ?? 0,
        giftCardPayment: prev?.giftCardPayment ?? 0,
        creditSaleAmount: prev?.creditSaleAmount ?? 0,
        totalSaleReturn: prev?.totalSaleReturn ?? 0,
        totalExpense: prev?.totalExpense ?? 0,
        expectedCash: expectedCash,
        variance: actualCash - expectedCash,
        totalSalesAmount: prev?.totalSalesAmount ?? 0,
        ordersCount: prev?.ordersCount ?? 0,
      );
      await _db.saveCache(_shiftCacheKey, {'status': false});
      return ApiSuccess(closedShift, isFromCache: true);
    }

    return res;
  }

  Future<ApiResult<PosOrdersPage>> fetchOrders({
    int? saleStatus,
    String? query,
    int perPage = 30,
  }) async {
    final res = await _client.get<PosOrdersPage>(
      ApiEndpoints.posOrders,
      queryParameters: {
        if (saleStatus != null) 'sale_status': saleStatus,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'per_page': perPage,
      },
      fromJson: (raw) {
        final map = _unwrapMap(raw);
        final list = (map['orders'] as List<dynamic>? ?? [])
            .map((e) => PosOrderSummary.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        final counts = map['counts'] is Map ? Map<String, dynamic>.from(map['counts'] as Map) : {};
        return PosOrdersPage(
          orders: list,
          completedCount: int.tryParse((counts['completed'] ?? 0).toString()) ?? 0,
          heldCount: int.tryParse((counts['held'] ?? 0).toString()) ?? 0,
          withReturnsCount: int.tryParse((counts['with_returns'] ?? 0).toString()) ?? 0,
        );
      },
    );

    if (res case ApiFailure<PosOrdersPage>(failure: final f) when _isNotFoundFailure(f)) {
      return _client.get<PosOrdersPage>(
        ApiEndpoints.sales,
        queryParameters: {'per_page': perPage},
        fromJson: (raw) {
          final listRaw = raw is Map && raw['data'] is List
              ? raw['data'] as List
              : (raw is List ? raw : const []);
          final list = listRaw
              .whereType<Map>()
              .map((e) => PosOrderSummary.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          return PosOrdersPage(
            orders: list,
            completedCount: list.where((o) => !o.isHeld).length,
            heldCount: list.where((o) => o.isHeld).length,
          );
        },
      );
    }

    return res;
  }

  Future<ApiResult<PosOrderSummary>> fetchOrderDetail(int id) {
    return _client.get<PosOrderSummary>(
      ApiEndpoints.posOrderDetail(id),
      fromJson: (raw) {
        final map = _unwrapMap(raw);
        final orderMap = map['order'] is Map ? Map<String, dynamic>.from(map['order'] as Map) : map;
        return PosOrderSummary.fromJson(orderMap);
      },
    );
  }

  PosOrderSummary _parseFallbackOrderSummary(
    dynamic raw, {
    required double total,
    required double paid,
    required String orderType,
    int? customerId,
    bool isHeld = false,
  }) {
    final map = _unwrapMap(raw);
    final inner = map['order'] is Map
        ? Map<String, dynamic>.from(map['order'] as Map)
        : (map['sale'] is Map
            ? Map<String, dynamic>.from(map['sale'] as Map)
            : map);
    if (inner.containsKey('grand_total') || inner.containsKey('sale_status')) {
      return PosOrderSummary.fromJson(inner);
    }
    final grandTotal = (double.tryParse((inner['total_amount'] ?? inner['total'] ?? total).toString()) ?? total)
        .clamp(0.0, double.infinity);
    final paidAmt = (double.tryParse((inner['paid_amount'] ?? paid).toString()) ?? paid)
        .clamp(0.0, double.infinity);
    final dueAmt = (grandTotal - paidAmt).clamp(0.0, double.infinity);
    return PosOrderSummary(
      id: int.tryParse((inner['sale_id'] ?? inner['id'] ?? 0).toString()) ?? 0,
      referenceNo: (inner['reference_no'] ?? inner['order_reference'] ?? 'POS-SALE').toString(),
      saleStatus: isHeld ? 3 : 1,
      isHeld: isHeld,
      orderType: orderType,
      grandTotal: grandTotal,
      paidAmount: paidAmt,
      dueAmount: dueAmt,
      paymentStatus: dueAmt > 0.01 ? 'due' : 'paid',
      customerId: customerId,
      customerName: (inner['customer_name'] ?? 'Walk-in Customer').toString(),
    );
  }

  Future<ApiSuccess<PosOrderSummary>> _queueOfflineSale({
    required double total,
    required double totalPaid,
    required String orderType,
    required Map<String, dynamic> offlinePayload,
  }) async {
    final offlineId = _uuid.v4();
    await _db.queueMutation(
      id: offlineId,
      endpoint: ApiEndpoints.cafeOrders,
      method: 'POST',
      idempotencyKey: offlineId,
      payload: offlinePayload,
    );

    return ApiSuccess(
      PosOrderSummary(
        id: -1,
        referenceNo: 'QUEUED-${offlineId.substring(0, 6).toUpperCase()}',
        saleStatus: 1,
        isHeld: false,
        orderType: orderType,
        grandTotal: total,
        paidAmount: totalPaid,
        dueAmount: 0,
        paymentStatus: 'queued_offline',
        customerName: 'Offline Queue',
        isOfflineQueued: true,
      ),
      isFromCache: true,
    );
  }

  Future<ApiSuccess<PosOrderSummary>> _saveLocalHeldOrder({
    int? resumingOrderId,
    required String orderType,
    int? customerId,
    int? tableId,
    String? saleNote,
    required double total,
    required List<PosCartItem> items,
  }) async {
    final heldKey = 'pos_held_orders_v1_company_${activeCompanyId ?? 0}';
    final existingRaw = await _db.getCache(heldKey);
    final existing = existingRaw is List
        ? existingRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    final localId = resumingOrderId ?? -DateTime.now().millisecondsSinceEpoch;
    final refNo = 'HELD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final record = <String, dynamic>{
      'id': localId,
      'reference_no': refNo,
      'sale_status': 3,
      'is_held': true,
      'order_type': orderType,
      'grand_total': total,
      'paid_amount': 0.0,
      'due_amount': total,
      'payment_status': 'pending',
      'customer_id': customerId,
      'customer_name': 'Walk-in Customer',
      'table_id': tableId,
      'sale_note': saleNote,
      'created_at': DateTime.now().toIso8601String(),
      'items': items
          .map((i) => {
                'id': i.product.id,
                'product_id': i.product.id,
                'product_name': i.product.name,
                'product_code': i.product.code,
                'qty': i.qty,
                'net_unit_price': i.unitPrice,
                'discount': i.discount,
                'tax': 0.0,
                'total': i.lineTotal,
                if (i.note != null && i.note!.trim().isNotEmpty) 'note': i.note!.trim(),
              })
          .toList(),
    };
    existing.removeWhere((e) => e['id'] == localId);
    existing.insert(0, record);
    await _db.saveCache(heldKey, existing);

    return ApiSuccess(
      PosOrderSummary(
        id: localId,
        referenceNo: refNo,
        saleStatus: 3,
        isHeld: true,
        orderType: orderType,
        grandTotal: total,
        paidAmount: 0,
        dueAmount: total,
        paymentStatus: 'pending',
        customerId: customerId,
        customerName: 'Walk-in Customer',
        tableId: tableId,
        saleNote: saleNote,
        isOfflineQueued: true,
      ),
      isFromCache: true,
    );
  }

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
    final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amount);
    final computedTotal = (items.fold<double>(0, (sum, i) => sum + i.lineTotal) -
            orderDiscount +
            shippingCost +
            roundOffAmount)
        .clamp(0.0, double.infinity);
    final primaryMethod = payments.isNotEmpty ? payments.first.method : 'Cash';
    final lineNotes = <String, String>{
      for (final i in items)
        if (i.note != null && i.note!.trim().isNotEmpty) i.product.id.toString(): i.note!.trim(),
    };
    final payload = <String, dynamic>{
      'status': hold ? 'held' : 'completed',
      'order_type': orderType,
      'price_tier': priceTier,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (customerId != null) 'customer_id': customerId,
      if (billerId != null) 'biller_id': billerId,
      if (tableId != null) 'table_id': tableId,
      if (cashRegisterId != null) 'cash_register_id': cashRegisterId,
      if (orderDiscount > 0) 'order_discount': orderDiscount,
      if (orderTaxRate > 0) 'order_tax_rate': orderTaxRate,
      if (shippingCost > 0) 'shipping_cost': shippingCost,
      if (roundOffAmount.abs() > 0.001) 'round_off_amount': double.parse(roundOffAmount.toStringAsFixed(2)),
      if (lineNotes.isNotEmpty) 'line_notes': lineNotes,
      if (saleNote != null && saleNote.isNotEmpty) 'sale_note': saleNote,
      if (!hold) ...{
        'payment_method': primaryMethod,
        'paid_amount': totalPaid,
        'payments': payments.map((p) => p.toJson()).toList(),
      },
      'items': items
          .map((i) => {
                'product_id': i.product.id,
                'qty': i.qty,
                'unit_price': i.unitPrice,
                if (i.discount > 0) 'discount': i.discount,
                if (i.note != null && i.note!.trim().isNotEmpty) 'note': i.note!.trim(),
              })
          .toList(),
    };

    final endpoint = resumingOrderId != null
        ? ApiEndpoints.posResumeOrder(resumingOrderId)
        : ApiEndpoints.posOrders;

    final res = await _client.post<PosOrderSummary>(
      endpoint,
      data: payload,
      fromJson: (raw) {
        final map = _unwrapMap(raw);
        final orderMap = map['order'] is Map ? Map<String, dynamic>.from(map['order'] as Map) : map;
        return PosOrderSummary.fromJson(orderMap);
      },
    );

    if (res is ApiSuccess<PosOrderSummary>) {
      return res;
    }

    if (hold) {
      if (res case ApiFailure<PosOrderSummary>(failure: final f)
          when _isNotFoundFailure(f) || f.isNetworkError) {
        return _saveLocalHeldOrder(
          resumingOrderId: resumingOrderId,
          orderType: orderType,
          customerId: customerId,
          tableId: tableId,
          saleNote: saleNote,
          total: computedTotal,
          items: items,
        );
      }
      return res;
    }

    final cafePayload = <String, dynamic>{
      if (activeCompanyId != null) 'company_id': activeCompanyId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (warehouseId != null) 'branch_id': warehouseId,
      if (customerId != null) 'customer_id': customerId,
      if (billerId != null) 'biller_id': billerId,
      'order_type': orderType,
      'price_tier': priceTier,
      'total': computedTotal,
      'total_amount': computedTotal,
      'grand_total': computedTotal,
      'paid_amount': totalPaid,
      'payment_method': primaryMethod.toLowerCase(),
      if (orderDiscount > 0) 'order_discount': orderDiscount,
      if (shippingCost > 0) 'shipping_cost': shippingCost,
      if (saleNote != null && saleNote.isNotEmpty) 'sale_note': saleNote,
      'items': items
          .map((i) => {
                'product_id': i.product.id,
                'qty': i.qty,
                'price': i.unitPrice,
                'unit_price': i.unitPrice,
                if (i.discount > 0) 'discount': i.discount,
                if (i.note != null && i.note!.trim().isNotEmpty) 'note': i.note!.trim(),
              })
          .toList(),
    };

    if (res case ApiFailure<PosOrderSummary>(failure: final f) when _isNotFoundFailure(f)) {
      final legacySale = await _client.post<PosOrderSummary>(
        ApiEndpoints.cafeOrders,
        data: cafePayload,
        fromJson: (raw) => _parseFallbackOrderSummary(
          raw,
          total: computedTotal,
          paid: totalPaid,
          orderType: orderType,
          customerId: customerId,
        ),
      );
      if (legacySale is ApiSuccess<PosOrderSummary>) {
        return legacySale;
      }

      if (legacySale case ApiFailure<PosOrderSummary>(failure: final lf)) {
        if (_isNotFoundFailure(lf)) {
          final salesPayload = <String, dynamic>{
            'sale_status': 1,
            'customer_id': customerId ?? 1,
            'warehouse_id': warehouseId ?? 1,
            'biller_id': billerId ?? 1,
            if (activeCompanyId != null) 'company_id': activeCompanyId,
            'total_price': computedTotal,
            'grand_total': computedTotal,
            'paid_amount': totalPaid,
            'payment_method': primaryMethod,
            if (orderDiscount > 0) 'order_discount': orderDiscount,
            if (shippingCost > 0) 'shipping_cost': shippingCost,
            if (saleNote != null && saleNote.isNotEmpty) 'sale_note': saleNote,
            'items': items
                .map((i) => {
                      'product_id': i.product.id,
                      'qty': i.qty,
                      'unit_price': i.unitPrice,
                      'net_unit_price': i.unitPrice,
                      'price': i.unitPrice,
                      if (i.discount > 0) 'discount': i.discount,
                    })
                .toList(),
          };
          final salesRes = await _client.post<PosOrderSummary>(
            ApiEndpoints.sales,
            data: salesPayload,
            fromJson: (raw) => _parseFallbackOrderSummary(
              raw,
              total: computedTotal,
              paid: totalPaid,
              orderType: orderType,
              customerId: customerId,
            ),
          );
          if (salesRes is ApiSuccess<PosOrderSummary>) {
            return salesRes;
          }
          if (salesRes case ApiFailure<PosOrderSummary>(failure: final sf) when sf.isNetworkError) {
            return _queueOfflineSale(
              total: computedTotal,
              totalPaid: totalPaid,
              orderType: orderType,
              offlinePayload: cafePayload,
            );
          }
          return salesRes;
        }
        if (lf.isNetworkError) {
          return _queueOfflineSale(
            total: computedTotal,
            totalPaid: totalPaid,
            orderType: orderType,
            offlinePayload: cafePayload,
          );
        }
        return legacySale;
      }
    }

    if (res case ApiFailure<PosOrderSummary>(failure: final f) when f.isNetworkError) {
      return _queueOfflineSale(
        total: computedTotal,
        totalPaid: totalPaid,
        orderType: orderType,
        offlinePayload: cafePayload,
      );
    }

    return res;
  }

  Future<ApiResult<bool>> cancelHeldOrder(int id) {
    return _client.delete<bool>(
      ApiEndpoints.posCancelHeldOrder(id),
      fromJson: (_) => true,
    );
  }

  Future<ApiResult<Map<String, dynamic>>> refundOrder(
    int id, {
    required String refundMethod,
    bool restock = true,
    String? reason,
    int? cashRegisterId,
    List<Map<String, dynamic>>? items,
  }) {
    return _client.post<Map<String, dynamic>>(
      ApiEndpoints.posRefundOrder(id),
      data: {
        'refund_method': refundMethod,
        'restock': restock,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (cashRegisterId != null) 'cash_register_id': cashRegisterId,
        if (items != null && items.isNotEmpty) 'items': items,
      },
      fromJson: (raw) => _unwrapMap(raw),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> fetchKdsTickets({int? warehouseId}) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.posKds,
      queryParameters: warehouseId != null ? {'warehouse_id': warehouseId} : null,
      fromJson: (raw) => _unwrapMap(raw),
    );
    if (res case ApiFailure<Map<String, dynamic>>(failure: final f) when _isNotFoundFailure(f)) {
      return const ApiSuccess(
        {
          'tickets': <dynamic>[],
          'counts': {'queued': 0, 'preparing': 0, 'ready': 0},
        },
        isFromCache: true,
      );
    }
    return res;
  }

  Future<ApiResult<PosOrderSummary>> updateKdsStatus(int orderId, String status) {
    return _client.post<PosOrderSummary>(
      ApiEndpoints.posKdsStatus(orderId),
      data: {'status': status},
      fromJson: (raw) {
        final map = _unwrapMap(raw);
        final ticket = map['ticket'] is Map
            ? Map<String, dynamic>.from(map['ticket'] as Map)
            : map;
        return PosOrderSummary.fromJson(ticket);
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> toggleProductAvailability(
    int productId, {
    required bool isAvailable,
  }) {
    return _client.patch<Map<String, dynamic>>(
      ApiEndpoints.posProductAvailability(productId),
      data: {'is_available': isAvailable},
      fromJson: (raw) => _unwrapMap(raw),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> createProductionBatch({
    required int productId,
    required double producedQty,
    int? warehouseId,
    double? unitCost,
    String? batchRef,
    String? notes,
  }) {
    return _client.post<Map<String, dynamic>>(
      ApiEndpoints.posProductionBatches,
      data: {
        'product_id': productId,
        'produced_qty': producedQty,
        if (warehouseId != null) 'warehouse_id': warehouseId,
        if (unitCost != null) 'unit_cost': unitCost,
        if (batchRef != null && batchRef.isNotEmpty) 'batch_ref': batchRef,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      fromJson: (raw) => _unwrapMap(raw),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> createWastage({
    required int productId,
    required double wastedQty,
    required String reason,
    int? warehouseId,
    String? notes,
  }) {
    return _client.post<Map<String, dynamic>>(
      ApiEndpoints.posWastage,
      data: {
        'product_id': productId,
        'wasted_qty': wastedQty,
        'reason': reason,
        if (warehouseId != null) 'warehouse_id': warehouseId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      fromJson: (raw) => _unwrapMap(raw),
    );
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchReorderRequests() async {
    final res = await _client.get<List<Map<String, dynamic>>>(
      ApiEndpoints.posReorderRequests,
      fromJson: (raw) {
        final map = _unwrapMap(raw);
        final list = map['requests'] is List
            ? map['requests'] as List
            : (raw is List ? raw : const []);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );
    if (res case ApiFailure<List<Map<String, dynamic>>>(failure: final f) when _isNotFoundFailure(f)) {
      return const ApiSuccess(<Map<String, dynamic>>[], isFromCache: true);
    }
    return res;
  }

  Future<ApiResult<Map<String, dynamic>>> createReorderRequest({
    required List<Map<String, dynamic>> items,
    int? warehouseId,
    int? supplierId,
    String? notes,
  }) {
    return _client.post<Map<String, dynamic>>(
      ApiEndpoints.posReorderRequests,
      data: {
        'items': items,
        if (warehouseId != null) 'warehouse_id': warehouseId,
        if (supplierId != null) 'supplier_id': supplierId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      fromJson: (raw) => _unwrapMap(raw),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> printOrderJob(
    int orderId, {
    String format = '80mm',
    int copies = 1,
  }) {
    return _client.post<Map<String, dynamic>>(
      ApiEndpoints.posOrderPrintJob(orderId),
      data: {
        'format': format,
        'copies': copies,
      },
      fromJson: (raw) => _unwrapMap(raw),
    );
  }
}
