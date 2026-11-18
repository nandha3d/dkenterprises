import 'dart:math' show max;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers.dart';
import '../data/pos_repository.dart';
import '../domain/pos_models.dart';

final posRepositoryProvider = Provider<PosRepository>((ref) {
  final activeCompanyId = ref.watch(authNotifierProvider.select((s) => s.activeCompany?.id));
  return PosRepository(
    ref.watch(apiClientProvider),
    ref.watch(localDatabaseProvider),
    activeCompanyId: activeCompanyId,
  );
});

@immutable
class PosTerminalState {
  static const Map<String, double> priceTierMultipliers = {
    'Retail MRP': 1.0,
    'Wholesale': 0.88,
    'Staff Rate': 0.60,
    'Online Aggregator': 1.15,
  };

  final bool isLoading;
  final bool isSubmitting;
  final bool isFromCache;
  final String? errorMessage;
  final PosBootstrapData? bootstrap;
  final PosShift? activeShift;
  final String orderType;
  final int? selectedWarehouseId;
  final int? selectedCustomerId;
  final int? selectedTableId;
  final int? selectedCategoryId;
  final String searchQuery;
  final double orderDiscount;
  final double packingCharge;
  final bool autoRoundOff;
  final bool kotFirstMode;
  final String priceTier;
  final int? resumingOrderId;
  final List<PosCartItem> cart;
  final PosOrderSummary? lastReceipt;

  const PosTerminalState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.isFromCache = false,
    this.errorMessage,
    this.bootstrap,
    this.activeShift,
    this.orderType = 'takeaway',
    this.selectedWarehouseId,
    this.selectedCustomerId,
    this.selectedTableId,
    this.selectedCategoryId,
    this.searchQuery = '',
    this.orderDiscount = 0,
    this.packingCharge = 0,
    this.autoRoundOff = false,
    this.kotFirstMode = false,
    this.priceTier = 'Retail MRP',
    this.resumingOrderId,
    this.cart = const [],
    this.lastReceipt,
  });

  double get tierMultiplier => priceTierMultipliers[priceTier] ?? 1.0;

  double priceForProduct(PosProduct product) {
    return double.parse((product.price * tierMultiplier).toStringAsFixed(2));
  }

  double get subtotal => cart.fold<double>(0, (sum, item) => sum + item.lineTotal);
  double get preRoundGrandTotal => (subtotal - orderDiscount + packingCharge).clamp(0, double.infinity);
  double get roundOffAmount => autoRoundOff ? (preRoundGrandTotal.roundToDouble() - preRoundGrandTotal) : 0.0;
  double get grandTotal => (preRoundGrandTotal + roundOffAmount).clamp(0, double.infinity);
  int get totalItemsCount => cart.fold<int>(0, (sum, item) => sum + (item.qty < 1 ? 1 : item.qty.round()));
  double get totalUnitsCount => cart.fold<double>(0, (sum, item) => sum + item.qty);

  PosPartyOption? get selectedCustomer {
    final list = bootstrap?.customers ?? const <PosPartyOption>[];
    final targetId = selectedCustomerId ?? bootstrap?.defaultCustomerId;
    if (targetId == null) return null;
    for (final c in list) {
      if (c.id == targetId) return c;
    }
    return null;
  }

  double customerCreditShortfall(double paidAmount) {
    final customer = selectedCustomer;
    if (customer == null || customer.creditLimit <= 0) return 0;
    final addedCredit = max(0.0, grandTotal - paidAmount);
    if (addedCredit <= 0.01) return 0;
    final projectedDue = customer.dueAmount + addedCredit;
    return projectedDue > customer.creditLimit ? (projectedDue - customer.creditLimit) : 0;
  }

  bool isCreditBlocked(double paidAmount) => customerCreditShortfall(paidAmount) > 0.01;

  List<PosProduct> get filteredProducts {
    final all = bootstrap?.products ?? const [];
    final q = searchQuery.trim().toLowerCase();
    return all.where((p) {
      if (selectedCategoryId != null && p.categoryId != selectedCategoryId) {
        return false;
      }
      if (q.isNotEmpty) {
        return p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  PosTerminalState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isFromCache,
    String? errorMessage,
    bool clearError = false,
    PosBootstrapData? bootstrap,
    PosShift? activeShift,
    bool clearShift = false,
    String? orderType,
    int? selectedWarehouseId,
    int? selectedCustomerId,
    int? selectedTableId,
    bool clearTable = false,
    int? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
    double? orderDiscount,
    double? packingCharge,
    bool? autoRoundOff,
    bool? kotFirstMode,
    String? priceTier,
    int? resumingOrderId,
    bool clearResumingOrder = false,
    List<PosCartItem>? cart,
    PosOrderSummary? lastReceipt,
    bool clearReceipt = false,
  }) {
    return PosTerminalState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFromCache: isFromCache ?? this.isFromCache,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      bootstrap: bootstrap ?? this.bootstrap,
      activeShift: clearShift ? null : (activeShift ?? this.activeShift),
      orderType: orderType ?? this.orderType,
      selectedWarehouseId: selectedWarehouseId ?? this.selectedWarehouseId,
      selectedCustomerId: selectedCustomerId ?? this.selectedCustomerId,
      selectedTableId: clearTable ? null : (selectedTableId ?? this.selectedTableId),
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      orderDiscount: orderDiscount ?? this.orderDiscount,
      packingCharge: packingCharge ?? this.packingCharge,
      autoRoundOff: autoRoundOff ?? this.autoRoundOff,
      kotFirstMode: kotFirstMode ?? this.kotFirstMode,
      priceTier: priceTier ?? this.priceTier,
      resumingOrderId: clearResumingOrder ? null : (resumingOrderId ?? this.resumingOrderId),
      cart: cart ?? this.cart,
      lastReceipt: clearReceipt ? null : (lastReceipt ?? this.lastReceipt),
    );
  }
}

class PosNotifier extends StateNotifier<PosTerminalState> {
  final PosRepository _repo;
  final Ref _ref;

  PosNotifier(this._repo, this._ref) : super(const PosTerminalState());

  Future<void> loadBootstrap({int? warehouseId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final res = await _repo.fetchBootstrap(warehouseId: warehouseId ?? state.selectedWarehouseId);
    switch (res) {
      case ApiSuccess<PosBootstrapData>(data: final data, isFromCache: final cached):
        state = state.copyWith(
          isLoading: false,
          isFromCache: cached,
          bootstrap: data,
          activeShift: data.shift,
          clearShift: data.shift == null,
          selectedWarehouseId: state.selectedWarehouseId ?? data.activeWarehouseId,
          selectedCustomerId: state.selectedCustomerId ?? data.defaultCustomerId,
        );
      case ApiFailure<PosBootstrapData>(failure: final f):
        state = state.copyWith(
          isLoading: false,
          errorMessage: f.message,
        );
    }
  }

  void setCategory(int? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
    );
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setOrderType(String orderType) {
    state = state.copyWith(
      orderType: orderType,
      clearTable: orderType != 'dine_in',
    );
  }

  void setTable(int? tableId) {
    state = state.copyWith(
      selectedTableId: tableId,
      clearTable: tableId == null,
      orderType: tableId != null ? 'dine_in' : state.orderType,
    );
  }

  void setCustomer(int? customerId) {
    state = state.copyWith(selectedCustomerId: customerId);
  }

  void setOrderDiscount(double discount) {
    state = state.copyWith(orderDiscount: discount.clamp(0, state.subtotal));
  }

  void setPackingCharge(double charge) {
    state = state.copyWith(packingCharge: charge.clamp(0, 99999));
  }

  void setAutoRoundOff(bool enabled) {
    state = state.copyWith(autoRoundOff: enabled);
  }

  void setKotFirstMode(bool enabled) {
    state = state.copyWith(kotFirstMode: enabled);
  }

  void setPriceTier(String tier) {
    final multiplier = PosTerminalState.priceTierMultipliers[tier] ?? 1.0;
    final repricedCart = state.cart.map((item) {
      final tierPrice = double.parse((item.product.price * multiplier).toStringAsFixed(2));
      return tier == 'Retail MRP'
          ? item.copyWith(clearUnitPriceOverride: true)
          : item.copyWith(unitPriceOverride: tierPrice);
    }).toList();
    state = state.copyWith(
      priceTier: tier,
      cart: repricedCart,
      clearError: true,
    );
  }

  void addProduct(PosProduct product, {double qty = 1.0, String? note}) {
    final current = List<PosCartItem>.from(state.cart);
    final idx = current.indexWhere((c) => c.product.id == product.id);
    final tierPrice = state.priceForProduct(product);
    final override = (tierPrice - product.price).abs() > 0.001 ? tierPrice : null;
    if (idx >= 0) {
      final existing = current[idx];
      current[idx] = existing.copyWith(
        qty: double.parse((existing.qty + qty).toStringAsFixed(2)),
        note: (note != null && note.trim().isNotEmpty) ? note.trim() : existing.note,
      );
    } else {
      current.add(
        PosCartItem(
          product: product,
          qty: double.parse(qty.toStringAsFixed(2)),
          unitPriceOverride: override,
          note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
        ),
      );
    }
    state = state.copyWith(cart: current, clearError: true);
  }

  bool addByBarcodeOrQuery(String rawInput) {
    final q = rawInput.trim().toLowerCase();
    if (q.isEmpty) return false;
    final all = state.bootstrap?.products ?? const <PosProduct>[];
    PosProduct? match;
    for (final p in all) {
      if (p.code.toLowerCase() == q) {
        match = p;
        break;
      }
    }
    match ??= all.cast<PosProduct?>().firstWhere(
          (p) => p != null && p.name.toLowerCase() == q,
          orElse: () => null,
        );
    if (match == null) {
      final filtered = all.where((p) {
        if (state.selectedCategoryId != null && p.categoryId != state.selectedCategoryId) {
          return false;
        }
        return p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q);
      }).toList();
      if (filtered.length == 1) {
        match = filtered.first;
      }
    }
    if (match == null) return false;
    addProduct(match);
    state = state.copyWith(searchQuery: '');
    return true;
  }

  void incrementItem(int productId) {
    final current = List<PosCartItem>.from(state.cart);
    final idx = current.indexWhere((c) => c.product.id == productId);
    if (idx >= 0) {
      current[idx] = current[idx].copyWith(qty: double.parse((current[idx].qty + 1).toStringAsFixed(2)));
      state = state.copyWith(cart: current);
    }
  }

  void decrementItem(int productId) {
    final current = List<PosCartItem>.from(state.cart);
    final idx = current.indexWhere((c) => c.product.id == productId);
    if (idx >= 0) {
      if (current[idx].qty > 1.0) {
        current[idx] = current[idx].copyWith(qty: double.parse((current[idx].qty - 1).toStringAsFixed(2)));
      } else {
        current.removeAt(idx);
      }
      state = state.copyWith(cart: current);
    }
  }

  void setItemQuantity(int productId, double qty) {
    final current = List<PosCartItem>.from(state.cart);
    final idx = current.indexWhere((c) => c.product.id == productId);
    if (idx < 0) return;
    if (qty <= 0.001) {
      current.removeAt(idx);
    } else {
      current[idx] = current[idx].copyWith(qty: double.parse(qty.toStringAsFixed(2)));
    }
    state = state.copyWith(cart: current, clearError: true);
  }

  void setItemNote(int productId, String? note) {
    final current = List<PosCartItem>.from(state.cart);
    final idx = current.indexWhere((c) => c.product.id == productId);
    if (idx < 0) return;
    final clean = note?.trim();
    current[idx] = current[idx].copyWith(
      note: (clean == null || clean.isEmpty) ? null : clean,
      clearNote: clean == null || clean.isEmpty,
    );
    state = state.copyWith(cart: current);
  }

  void setItemPriceAndModifiers(
    int productId, {
    double? qty,
    double? unitPriceOverride,
    String? note,
  }) {
    final current = List<PosCartItem>.from(state.cart);
    final idx = current.indexWhere((c) => c.product.id == productId);
    if (idx < 0) return;
    if (qty != null && qty <= 0.001) {
      current.removeAt(idx);
    } else {
      final cleanNote = note?.trim();
      current[idx] = current[idx].copyWith(
        qty: qty != null ? double.parse(qty.toStringAsFixed(2)) : null,
        unitPriceOverride: unitPriceOverride,
        note: (cleanNote == null || cleanNote.isEmpty) ? null : cleanNote,
        clearNote: note != null && (cleanNote == null || cleanNote.isEmpty),
      );
    }
    state = state.copyWith(cart: current, clearError: true);
  }

  void clearCart() {
    state = state.copyWith(
      cart: const [],
      orderDiscount: 0,
      packingCharge: 0,
      clearTable: true,
      clearResumingOrder: true,
      clearError: true,
    );
  }

  /// Loads a held draft fetched from ERP `/api/v1/pos/orders/{id}` back into the cart.
  Future<bool> loadHeldOrder(int orderId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final res = await _repo.fetchOrderDetail(orderId);
    switch (res) {
      case ApiSuccess<PosOrderSummary>(data: final order):
        if (state.bootstrap == null) {
          await loadBootstrap();
        }
        final productsById = {
          for (final p in (state.bootstrap?.products ?? <PosProduct>[])) p.id: p,
        };
        final loadedCart = order.items.map((line) {
          final catalogProduct = productsById[line.productId] ??
              PosProduct(
                id: line.productId,
                name: line.productName,
                code: line.productCode,
                price: line.netUnitPrice,
              );
          return PosCartItem(
            product: catalogProduct,
            qty: line.qty > 0 ? line.qty : 1.0,
            discount: line.discount,
            unitPriceOverride: line.netUnitPrice,
            note: line.note,
          );
        }).toList();

        state = state.copyWith(
          isLoading: false,
          resumingOrderId: order.id,
          orderType: order.orderType,
          selectedCustomerId: order.customerId ?? state.selectedCustomerId,
          selectedTableId: order.tableId,
          clearTable: order.tableId == null,
          cart: loadedCart,
          orderDiscount: 0,
          packingCharge: 0,
        );
        return true;
      case ApiFailure<PosOrderSummary>(failure: final f):
        state = state.copyWith(isLoading: false, errorMessage: f.message);
        return false;
    }
  }

  Future<ApiResult<PosOrderSummary>> submitOrder({
    required bool hold,
    required List<PosPaymentSplit> payments,
    String? saleNote,
  }) async {
    if (state.cart.isEmpty) {
      return const ApiFailure(NetworkFailure(message: 'Cart is empty. Add items before submitting.'));
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    final res = await _repo.submitOrder(
      resumingOrderId: state.resumingOrderId,
      hold: hold,
      orderType: state.orderType,
      warehouseId: state.selectedWarehouseId ?? state.bootstrap?.activeWarehouseId,
      customerId: state.selectedCustomerId ?? state.bootstrap?.defaultCustomerId,
      billerId: state.bootstrap?.defaultBillerId,
      tableId: state.selectedTableId,
      cashRegisterId: state.activeShift?.id,
      orderDiscount: state.orderDiscount,
      shippingCost: state.packingCharge,
      roundOffAmount: double.parse(state.roundOffAmount.toStringAsFixed(2)),
      priceTier: state.priceTier,
      saleNote: saleNote,
      payments: payments,
      items: state.cart,
    );

    switch (res) {
      case ApiSuccess<PosOrderSummary>(data: final order):
        if (order.isOfflineQueued) {
          _ref.read(syncWorkerProvider).drainOutbox();
        }
        state = state.copyWith(
          isSubmitting: false,
          cart: const [],
          orderDiscount: 0,
          packingCharge: 0,
          clearTable: true,
          clearResumingOrder: true,
          lastReceipt: hold ? null : order,
        );
        if (!order.isOfflineQueued) {
          await loadBootstrap();
        }
      case ApiFailure<PosOrderSummary>(failure: final f):
        state = state.copyWith(isSubmitting: false, errorMessage: f.message);
    }
    return res;
  }

  Future<ApiResult<PosShift>> openShift({required double cashInHand}) async {
    final res = await _repo.openShift(
      cashInHand: cashInHand,
      warehouseId: state.selectedWarehouseId ?? state.bootstrap?.activeWarehouseId,
    );
    if (res is ApiSuccess<PosShift>) {
      state = state.copyWith(activeShift: res.data);
      await loadBootstrap();
    }
    return res;
  }

  Future<ApiResult<PosShift>> closeShift({required double actualCash, String? note}) async {
    final res = await _repo.closeShift(
      actualCash: actualCash,
      cashRegisterId: state.activeShift?.id,
      warehouseId: state.selectedWarehouseId ?? state.bootstrap?.activeWarehouseId,
      note: note,
    );
    if (res is ApiSuccess<PosShift>) {
      state = state.copyWith(clearShift: true);
      await loadBootstrap();
    }
    return res;
  }
}

final posNotifierProvider = StateNotifierProvider<PosNotifier, PosTerminalState>((ref) {
  return PosNotifier(ref.watch(posRepositoryProvider), ref);
});

