library;

import 'package:flutter/foundation.dart';

double _toDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

int _toInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

@immutable
class PosPartyOption {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final double creditLimit;
  final double dueAmount;

  const PosPartyOption({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.creditLimit = 0,
    this.dueAmount = 0,
  });

  factory PosPartyOption.fromJson(Map<String, dynamic> json) {
    return PosPartyOption(
      id: _toInt(json['id']),
      name: (json['name'] ?? json['company_name'] ?? 'Option').toString(),
      phone: json['phone_number']?.toString() ?? json['phone']?.toString(),
      email: json['email']?.toString(),
      creditLimit: _toDouble(json['credit_limit']),
      dueAmount: _toDouble(json['due_amount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'credit_limit': creditLimit,
        'due_amount': dueAmount,
      };
}

@immutable
class PosCategory {
  final int id;
  final String name;
  final int? parentId;

  const PosCategory({
    required this.id,
    required this.name,
    this.parentId,
  });

  factory PosCategory.fromJson(Map<String, dynamic> json) {
    return PosCategory(
      id: _toInt(json['id']),
      name: (json['name'] ?? 'Category').toString(),
      parentId: _toNullableInt(json['parent_id']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
      };
}

@immutable
class PosProduct {
  final int id;
  final String name;
  final String code;
  final String type;
  final double price;
  final double cost;
  final int? categoryId;
  final double taxRate;
  final int taxMethod;
  final String? image;
  final bool isFeatured;
  final bool isAvailable;
  final double stockQty;
  final double alertQty;

  const PosProduct({
    required this.id,
    required this.name,
    required this.code,
    this.type = 'standard',
    required this.price,
    this.cost = 0,
    this.categoryId,
    this.taxRate = 0,
    this.taxMethod = 1,
    this.image,
    this.isFeatured = false,
    this.isAvailable = true,
    this.stockQty = 0,
    this.alertQty = 0,
  });

  factory PosProduct.fromJson(Map<String, dynamic> json) {
    final availableRaw = json['is_available'] ?? json['in_stock'] ?? json['is_active'];
    return PosProduct(
      id: _toInt(json['id']),
      name: (json['name'] ?? 'Item').toString(),
      code: (json['code'] ?? '').toString(),
      type: (json['type'] ?? 'standard').toString(),
      price: _toDouble(json['price']),
      cost: _toDouble(json['cost']),
      categoryId: _toNullableInt(json['category_id']),
      taxRate: _toDouble(json['tax_rate']),
      taxMethod: _toInt(json['tax_method'], 1),
      image: json['image']?.toString(),
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      isAvailable: availableRaw == null
          ? true
          : (availableRaw == true || availableRaw == 1 || availableRaw == '1'),
      stockQty: _toDouble(json['stock_qty'] ?? json['qty']),
      alertQty: _toDouble(json['alert_quantity'] ?? json['alert_qty']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'type': type,
        'price': price,
        'cost': cost,
        'category_id': categoryId,
        'tax_rate': taxRate,
        'tax_method': taxMethod,
        'image': image,
        'is_featured': isFeatured,
        'is_available': isAvailable,
        'stock_qty': stockQty,
        'alert_quantity': alertQty,
      };
}

@immutable
class PosTable {
  final int id;
  final String name;
  final int seats;
  final String? floorName;
  final String status; // 'available' | 'occupied'
  final int? heldSaleId;
  final String? heldReferenceNo;
  final double? heldGrandTotal;
  final String? heldCustomerName;

  const PosTable({
    required this.id,
    required this.name,
    this.seats = 4,
    this.floorName,
    this.status = 'available',
    this.heldSaleId,
    this.heldReferenceNo,
    this.heldGrandTotal,
    this.heldCustomerName,
  });

  bool get isOccupied => status == 'occupied';

  factory PosTable.fromJson(Map<String, dynamic> json) {
    return PosTable(
      id: _toInt(json['id']),
      name: (json['name'] ?? 'Table').toString(),
      seats: _toInt(json['seats'], 4),
      floorName: json['floor_name']?.toString(),
      status: (json['status'] ?? 'available').toString(),
      heldSaleId: _toNullableInt(json['held_sale_id']),
      heldReferenceNo: json['held_reference_no']?.toString(),
      heldGrandTotal: json['held_grand_total'] != null ? _toDouble(json['held_grand_total']) : null,
      heldCustomerName: json['held_customer_name']?.toString(),
    );
  }
}

@immutable
class PosShift {
  final int id;
  final int warehouseId;
  final double cashInHand;
  final double? closingBalance;
  final bool status;
  final String? openedAt;
  final String? closedAt;
  final double cashPayment;
  final double upiPayment;
  final double cardPayment;
  final double bankPayment;
  final double chequePayment;
  final double giftCardPayment;
  final double creditSaleAmount;
  final double totalSaleReturn;
  final double totalExpense;
  final double expectedCash;
  final double? variance;
  final double totalSalesAmount;
  final int ordersCount;

  const PosShift({
    required this.id,
    required this.warehouseId,
    required this.cashInHand,
    this.closingBalance,
    required this.status,
    this.openedAt,
    this.closedAt,
    this.cashPayment = 0,
    this.upiPayment = 0,
    this.cardPayment = 0,
    this.bankPayment = 0,
    this.chequePayment = 0,
    this.giftCardPayment = 0,
    this.creditSaleAmount = 0,
    this.totalSaleReturn = 0,
    this.totalExpense = 0,
    this.expectedCash = 0,
    this.variance,
    this.totalSalesAmount = 0,
    this.ordersCount = 0,
  });

  factory PosShift.fromJson(Map<String, dynamic> json) {
    return PosShift(
      id: _toInt(json['id']),
      warehouseId: _toInt(json['warehouse_id']),
      cashInHand: _toDouble(json['cash_in_hand']),
      closingBalance: json['closing_balance'] != null ? _toDouble(json['closing_balance']) : null,
      status: json['status'] == true || json['status'] == 1,
      openedAt: json['opened_at']?.toString(),
      closedAt: json['closed_at']?.toString(),
      cashPayment: _toDouble(json['cash_payment']),
      upiPayment: _toDouble(json['upi_payment']),
      cardPayment: _toDouble(json['card_payment']),
      bankPayment: _toDouble(json['bank_payment']),
      chequePayment: _toDouble(json['cheque_payment']),
      giftCardPayment: _toDouble(json['gift_card_payment']),
      creditSaleAmount: _toDouble(json['credit_sale_amount']),
      totalSaleReturn: _toDouble(json['total_sale_return']),
      totalExpense: _toDouble(json['total_expense']),
      expectedCash: _toDouble(json['expected_cash']),
      variance: json['variance'] != null ? _toDouble(json['variance']) : null,
      totalSalesAmount: _toDouble(json['total_sales_amount']),
      ordersCount: _toInt(json['orders_count']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'warehouse_id': warehouseId,
        'cash_in_hand': cashInHand,
        'closing_balance': closingBalance,
        'status': status,
        'opened_at': openedAt,
        'closed_at': closedAt,
        'cash_payment': cashPayment,
        'upi_payment': upiPayment,
        'card_payment': cardPayment,
        'bank_payment': bankPayment,
        'cheque_payment': chequePayment,
        'gift_card_payment': giftCardPayment,
        'credit_sale_amount': creditSaleAmount,
        'total_sale_return': totalSaleReturn,
        'total_expense': totalExpense,
        'expected_cash': expectedCash,
        'variance': variance,
        'total_sales_amount': totalSalesAmount,
        'orders_count': ordersCount,
      };
}

@immutable
class PosCartItem {
  final PosProduct product;
  final double qty;
  final double discount;
  final double? unitPriceOverride;
  final String? note;

  const PosCartItem({
    required this.product,
    this.qty = 1,
    this.discount = 0,
    this.unitPriceOverride,
    this.note,
  });

  double get unitPrice => unitPriceOverride ?? product.price;
  double get lineTotal => ((unitPrice * qty) - discount).clamp(0, double.infinity);

  String get qtyLabel =>
      (qty - qty.roundToDouble()).abs() < 0.001
          ? qty.round().toString()
          : qty.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');

  PosCartItem copyWith({
    double? qty,
    double? discount,
    double? unitPriceOverride,
    bool clearUnitPriceOverride = false,
    String? note,
    bool clearNote = false,
  }) {
    return PosCartItem(
      product: product,
      qty: qty ?? this.qty,
      discount: discount ?? this.discount,
      unitPriceOverride: clearUnitPriceOverride ? null : (unitPriceOverride ?? this.unitPriceOverride),
      note: clearNote ? null : (note ?? this.note),
    );
  }
}

@immutable
class PosPaymentSplit {
  final String method; // Cash | UPI | Card | Credit | Bank
  final double amount;
  final String? note;

  const PosPaymentSplit({
    required this.method,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'amount': amount,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  factory PosPaymentSplit.fromJson(Map<String, dynamic> json) {
    return PosPaymentSplit(
      method: (json['paying_method'] ?? json['method'] ?? 'Cash').toString(),
      amount: _toDouble(json['amount']),
      note: json['payment_note']?.toString() ?? json['note']?.toString(),
    );
  }
}

@immutable
class PosOrderLine {
  final int id;
  final int productId;
  final String productName;
  final String productCode;
  final double qty;
  final double netUnitPrice;
  final double discount;
  final double tax;
  final double total;
  final double returnQty;
  final double returnableQty;
  final String? note;

  const PosOrderLine({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.qty,
    required this.netUnitPrice,
    required this.discount,
    required this.tax,
    required this.total,
    this.returnQty = 0,
    this.returnableQty = 0,
    this.note,
  });

  String get qtyLabel =>
      (qty - qty.roundToDouble()).abs() < 0.001
          ? qty.round().toString()
          : qty.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');

  factory PosOrderLine.fromJson(Map<String, dynamic> json) {
    final q = _toDouble(json['qty']);
    final r = _toDouble(json['return_qty']);
    return PosOrderLine(
      id: _toInt(json['id']),
      productId: _toInt(json['product_id']),
      productName: (json['product_name'] ?? 'Item').toString(),
      productCode: (json['product_code'] ?? '').toString(),
      qty: q,
      netUnitPrice: _toDouble(json['net_unit_price'] ?? json['unit_price']),
      discount: _toDouble(json['discount']),
      tax: _toDouble(json['tax']),
      total: _toDouble(json['total']),
      returnQty: r,
      returnableQty: json['returnable_qty'] != null ? _toDouble(json['returnable_qty']) : (q - r).clamp(0, q),
      note: json['note']?.toString(),
    );
  }
}

@immutable
class PosOrderSummary {
  final int id;
  final String referenceNo;
  final int saleStatus; // 1 = completed, 3 = held draft
  final bool isHeld;
  final String orderType;
  final double grandTotal;
  final double paidAmount;
  final double dueAmount;
  final String paymentStatus;
  final int? customerId;
  final String customerName;
  final int? tableId;
  final String? tableName;
  final String? createdAt;
  final String? saleNote;
  final String kdsStatus;
  final bool isOfflineQueued;
  final List<PosOrderLine> items;
  final List<PosPaymentSplit> payments;

  const PosOrderSummary({
    required this.id,
    required this.referenceNo,
    required this.saleStatus,
    required this.isHeld,
    required this.orderType,
    required this.grandTotal,
    required this.paidAmount,
    required this.dueAmount,
    required this.paymentStatus,
    this.customerId,
    required this.customerName,
    this.tableId,
    this.tableName,
    this.createdAt,
    this.saleNote,
    this.kdsStatus = 'NEW',
    this.isOfflineQueued = false,
    this.items = const [],
    this.payments = const [],
  });

  factory PosOrderSummary.fromJson(Map<String, dynamic> json) {
    final status = _toInt(json['sale_status'], 1);
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final paymentsJson = json['payments'] as List<dynamic>? ?? [];

    return PosOrderSummary(
      id: _toInt(json['id']),
      referenceNo: (json['reference_no'] ?? 'POS').toString(),
      saleStatus: status,
      isHeld: json['is_held'] == true || status == 3,
      orderType: (json['order_type'] ?? 'takeaway').toString(),
      grandTotal: _toDouble(json['grand_total']),
      paidAmount: _toDouble(json['paid_amount']),
      dueAmount: _toDouble(json['due_amount']),
      paymentStatus: (json['payment_status'] ?? 'pending').toString(),
      customerId: _toNullableInt(json['customer_id']),
      customerName: (json['customer_name'] ?? 'Walk-in Customer').toString(),
      tableId: _toNullableInt(json['table_id']),
      tableName: json['table_name']?.toString(),
      createdAt: json['created_at']?.toString(),
      saleNote: json['sale_note']?.toString(),
      kdsStatus: (json['kds_status'] ?? 'NEW').toString(),
      items: itemsJson.map((e) => PosOrderLine.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      payments: paymentsJson
          .map((e) => PosPaymentSplit.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

@immutable
class PosBootstrapData {
  final int companyId;
  final String? companyName;
  final String? gstin;
  final String? upiVpa;
  final int? activeWarehouseId;
  final int? defaultCustomerId;
  final int? defaultBillerId;
  final bool tableEnabled;
  final List<String> orderTypes;
  final List<String> paymentMethods;
  final PosShift? shift;
  final int heldOrdersCount;
  final List<PosPartyOption> warehouses;
  final List<PosPartyOption> customers;
  final List<PosCategory> categories;
  final List<PosProduct> products;
  final List<PosTable> tables;

  const PosBootstrapData({
    required this.companyId,
    this.companyName,
    this.gstin,
    this.upiVpa,
    this.activeWarehouseId,
    this.defaultCustomerId,
    this.defaultBillerId,
    this.tableEnabled = true,
    this.orderTypes = const ['dine_in', 'takeaway', 'delivery'],
    this.paymentMethods = const ['Cash', 'UPI', 'Card', 'Credit'],
    this.shift,
    this.heldOrdersCount = 0,
    this.warehouses = const [],
    this.customers = const [],
    this.categories = const [],
    this.products = const [],
    this.tables = const [],
  });

  factory PosBootstrapData.fromJson(Map<String, dynamic> json) {
    final setting = json['pos_setting'] is Map ? Map<String, dynamic>.from(json['pos_setting'] as Map) : {};
    return PosBootstrapData(
      companyId: _toInt(json['company_id']),
      companyName: json['company_name']?.toString(),
      gstin: json['gstin']?.toString(),
      upiVpa: json['upi_vpa']?.toString(),
      activeWarehouseId: _toNullableInt(json['active_warehouse_id']),
      defaultCustomerId: _toNullableInt(json['default_customer_id']),
      defaultBillerId: _toNullableInt(json['default_biller_id']),
      tableEnabled: setting['is_table'] == true || setting['is_table'] == 1,
      orderTypes: (json['order_types'] as List<dynamic>? ?? ['dine_in', 'takeaway', 'delivery'])
          .map((e) => e.toString())
          .toList(),
      paymentMethods: (json['payment_methods'] as List<dynamic>? ?? ['Cash', 'UPI', 'Card', 'Credit'])
          .map((e) => e.toString())
          .toList(),
      shift: json['shift'] is Map ? PosShift.fromJson(Map<String, dynamic>.from(json['shift'] as Map)) : null,
      heldOrdersCount: _toInt(json['held_orders_count']),
      warehouses: (json['warehouses'] as List<dynamic>? ?? [])
          .map((e) => PosPartyOption.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      customers: (json['customers'] as List<dynamic>? ?? [])
          .map((e) => PosPartyOption.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => PosCategory.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      products: (json['products'] as List<dynamic>? ?? [])
          .map((e) => PosProduct.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      tables: (json['tables'] as List<dynamic>? ?? [])
          .map((e) => PosTable.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

@immutable
class PosOrdersPage {
  final List<PosOrderSummary> orders;
  final int completedCount;
  final int heldCount;
  final int withReturnsCount;

  const PosOrdersPage({
    this.orders = const [],
    this.completedCount = 0,
    this.heldCount = 0,
    this.withReturnsCount = 0,
  });
}

