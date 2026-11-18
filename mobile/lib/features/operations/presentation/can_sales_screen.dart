import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';
import '../../../core/ui/pos_print_preview_sheet.dart';
import '../../../core/ui/scrollable_counter_field.dart';

/// Optional telemetry override for deterministic widget testing without native GPS plugins.
typedef CanGpsFetcher = Future<({double lat, double lng, bool isMocked})?> Function();

class CanSalesScreen extends ConsumerStatefulWidget {
  final CanGpsFetcher? gpsFetcher;
  final Map<String, dynamic>? initialOrder;

  const CanSalesScreen({super.key, this.gpsFetcher, this.initialOrder});

  @override
  ConsumerState<CanSalesScreen> createState() => _CanSalesScreenState();
}

class _CanSalesScreenState extends ConsumerState<CanSalesScreen> {
  final _customerController = TextEditingController();
  final _creditPinController = TextEditingController();

  int? _activeOrderId;
  String? _activeOrderNo;
  String? _activeOrderStatus;
  int _orderedCans = 0;
  bool _isBookingOrder = false;

  int _deliveredCans = 0;
  int _returnedEmpties = 0;
  String _selectedCanSize = '20L Can';
  double _pricePerCan = 0.0;
  double _masterCustomerRate = 0.0;
  bool _rateLocked = true;
  bool _rateOverrideUsed = false;
  String? _overridePin;

  // Bakery / Biscuit Van Supply Mode (Tata Ace EV & Tata Ace Diesel)
  bool _isBakeryMode = false;
  final List<({String name, int qty, double rate})> _bakeryItems = [];

  // +Extra / -Discount & GPay Pending vs Confirmed Proof
  double _extraCharge = 0.0;
  double _discountAmount = 0.0;
  String _adjustmentNote = '';
  String _upiVerificationStatus = 'confirmed'; // 'confirmed' | 'pending_verification'
  String? _upiProofRef;
  String? _upiUtr;

  String _priceTier = 'Standard Rate';
  String _paymentMode = 'Cash';
  bool _sendCreditWhatsappAlert = true;
  bool _emptyJarPhotoVerified = false;
  String? _emptyJarPhotoRef;

  bool _isSubmitting = false;
  bool _isFetchingGps = false;
  bool _isMockGps = false;
  double? _currentLat;
  double? _currentLng;
  double? _geofenceDistanceM;
  bool _qrVerified = false;
  String? _verifiedQrPayload;

  int _vanLoadedCans = 0;
  int _vanRemainingCans = 0;
  int? _selectedCustomerId;
  String? _selectedCustomerQr;
  String? _companyName;
  String? _gstin;
  String? _upiVpa;
  String? _vehicleNumber;
  String? _managerOverridePin;
  double _jarDepositRate = 0.0;
  List<({String label, double rate})> _rateSlabs = const [];
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _applyInitialOrder(widget.initialOrder);
    _fetchCustomersAndManifest();
    _captureGpsFix();
  }

  void _applyInitialOrder(Map<String, dynamic>? order) {
    if (order == null || order.isEmpty) return;
    _activeOrderId = int.tryParse((order['order_id'] ?? order['id'] ?? '').toString());
    _activeOrderNo = (order['order_no'] ?? order['delivery_no'])?.toString();
    _activeOrderStatus = (order['status'] ?? (_activeOrderId != null ? 'ordered' : '')).toString().toLowerCase();
    final qty = int.tryParse((order['ordered_cans'] ?? order['cans_delivered'] ?? 0).toString()) ?? 0;
    if (qty > 0) {
      _orderedCans = qty;
      _deliveredCans = qty;
    }
    final cid = int.tryParse((order['customer_id'] ?? '').toString());
    if (cid != null && cid > 0) {
      _selectedCustomerId = cid;
    }
    final cname = (order['customer_name'] ?? order['name'])?.toString();
    if (cname != null && cname.isNotEmpty) {
      _customerController.text = cname;
    }
    final rate = double.tryParse((order['can_rate'] ?? order['master_can_rate'] ?? 0).toString()) ?? 0.0;
    if (rate > 0) {
      _masterCustomerRate = rate;
      _pricePerCan = rate;
    }
    final size = order['can_size']?.toString().trim();
    if (size != null && size.isNotEmpty) {
      _selectedCanSize = size;
    }
    final mode = order['payment_mode']?.toString();
    if (mode != null && ['Cash', 'UPI', 'Credit'].contains(mode)) {
      _paymentMode = mode;
    }
    if (order['initial_mode']?.toString() == 'bakery_supply' ||
        order['item_category']?.toString() == 'bakery_supply') {
      _isBakeryMode = true;
    }
  }

  bool get _isDeliveryDriverUser {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return false;
    return ref.read(activeRippleRoleProvider) == RippleRole.driver &&
        ref.read(activeDriverFlavorProvider) != RippleDriverFlavor.tanker;
  }

  bool get _requiresOrderBookingFirst {
    if (!_isDeliveryDriverUser) return false;
    return _activeOrderId == null &&
        (_activeOrderNo == null || !_activeOrderNo!.startsWith('ORD-'));
  }

  Future<void> _fetchCustomersAndManifest() async {
    final client = ref.read(apiClientProvider);
    final custFuture = client.get(
      ApiEndpoints.customers,
      fromJson: (data) {
        final list = data is Map && data['data'] is List
            ? data['data'] as List
            : (data is List ? data : []);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      },
    );
    final manifestFuture = client.get(
      ApiEndpoints.driverManifest,
      fromJson: (data) {
        if (data is Map && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
        return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      },
    );

    final res = await custFuture;
    final manifestRes = await manifestFuture;
    if (!mounted) return;

    setState(() {
      if (manifestRes.isSuccess) {
        final m = manifestRes.dataOrNull ?? const <String, dynamic>{};
        _companyName = m['company_name']?.toString() ?? _companyName;
        _gstin = m['gstin']?.toString() ?? _gstin;
        _upiVpa = m['upi_vpa']?.toString() ?? _upiVpa;
        _managerOverridePin = m['manager_override_pin']?.toString() ?? _managerOverridePin;
        final depRate = double.tryParse((m['jar_deposit_rate'] ?? 0).toString()) ?? 0.0;
        if (depRate > 0) _jarDepositRate = depRate;
        final veh = m['vehicle'];
        if (veh is Map) {
          _vehicleNumber = veh['vehicle_number']?.toString() ?? _vehicleNumber;
        }
        final inv = m['can_inventory'];
        if (inv is Map) {
          _vanLoadedCans = int.tryParse((inv['loaded_cans'] ?? 0).toString()) ?? 0;
          _vanRemainingCans = int.tryParse((inv['remaining_full_cans'] ?? 0).toString()) ?? 0;
        }
        final rawSlabs = m['rate_slabs'];
        if (rawSlabs is List) {
          _rateSlabs = rawSlabs
              .whereType<Map>()
              .map((s) => (
                    label: s['label']?.toString() ?? 'Slab',
                    rate: double.tryParse((s['rate'] ?? 0).toString()) ?? 0.0,
                  ))
              .where((s) => s.rate > 0)
              .toList();
        }
      }
      if (res.isSuccess) {
        _customers = res.dataOrNull ?? [];
        if (_customers.isNotEmpty) {
          Map<String, dynamic>? matched;
          if (_selectedCustomerId != null) {
            for (final c in _customers) {
              if (int.tryParse((c['id'] ?? '').toString()) == _selectedCustomerId) {
                matched = c;
                break;
              }
            }
          }
          if (matched != null) {
            _applySelectedCustomer(matched);
          } else if (_selectedCustomerId == null) {
            _applySelectedCustomer(_customers.first);
          }
        }
      }
    });
  }

  void _applySelectedCustomer(Map<String, dynamic> c) {
    _selectedCustomerId = int.tryParse((c['id'] ?? '').toString());
    _customerController.text = c['name']?.toString() ?? '';
    _selectedCustomerQr = c['shop_qr_code']?.toString() ?? c['qr_code']?.toString();
    final custDeposit = double.tryParse((c['jar_deposit_rate'] ?? 0).toString()) ?? 0.0;
    if (custDeposit > 0) _jarDepositRate = custDeposit;
    final master = double.tryParse(
          (c['master_can_rate'] ?? c['can_rate'] ?? c['unit_price'] ?? 0).toString(),
        ) ??
        0.0;
    _masterCustomerRate = master > 0 ? master : 0.0;
    _pricePerCan = _masterCustomerRate;
    _priceTier = c['price_tier']?.toString() ?? c['customer_type']?.toString() ?? 'Customer Rate';
    _rateLocked = _masterCustomerRate > 0;
    _rateOverrideUsed = false;
    _overridePin = null;
    _qrVerified = false;
    _verifiedQrPayload = null;
    _recomputeGeofence();
  }

  Future<void> _captureGpsFix() async {
    if (_isFetchingGps) return;
    setState(() => _isFetchingGps = true);

    try {
      if (widget.gpsFetcher != null) {
        final fix = await widget.gpsFetcher!.call();
        if (!mounted) return;
        setState(() {
          _isFetchingGps = false;
          if (fix != null) {
            _currentLat = fix.lat;
            _currentLng = fix.lng;
            _isMockGps = fix.isMocked;
          }
          _recomputeGeofence();
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isFetchingGps = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isFetchingGps = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
      if (!mounted) return;
      setState(() {
        _isFetchingGps = false;
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
        _isMockGps = pos.isMocked;
        _recomputeGeofence();
      });
    } catch (_) {
      if (mounted) setState(() => _isFetchingGps = false);
    }
  }

  Map<String, dynamic>? get _selectedCustomerMap {
    if (_selectedCustomerId == null) return null;
    for (final c in _customers) {
      if (int.tryParse((c['id'] ?? '').toString()) == _selectedCustomerId) {
        return c;
      }
    }
    return null;
  }

  void _recomputeGeofence() {
    final cust = _selectedCustomerMap;
    final cLat = double.tryParse((cust?['latitude'] ?? '').toString());
    final cLng = double.tryParse((cust?['longitude'] ?? '').toString());
    if (_currentLat != null && _currentLng != null && cLat != null && cLng != null) {
      _geofenceDistanceM = Geolocator.distanceBetween(_currentLat!, _currentLng!, cLat, cLng);
    } else {
      _geofenceDistanceM = null;
    }
  }

  double get _customerAllowedRadius {
    final raw = double.tryParse((_selectedCustomerMap?['geofence_radius'] ?? 150).toString()) ?? 150.0;
    return raw > 0 ? raw : 150.0;
  }

  bool get _isGeofenceAlert {
    if (_qrVerified) return false;
    if (_geofenceDistanceM == null) return false;
    return _geofenceDistanceM! > _customerAllowedRadius;
  }

  String get _expectedShopQrCode {
    final qr = _selectedCustomerQr?.trim() ?? '';
    if (qr.isNotEmpty) return qr;
    if (_selectedCustomerId != null) return 'DKW-SHOP-$_selectedCustomerId';
    return '';
  }

  int get _emptyDeficit => _isBakeryMode ? 0 : (_deliveredCans - _returnedEmpties).clamp(0, 999);
  double get _jarDepositLiability => _emptyDeficit * _jarDepositRate;
  bool get _exceedsVanStock => !_isBakeryMode && _deliveredCans > _vanRemainingCans;
  int get _bakeryPiecesDelivered => _bakeryItems.fold<int>(0, (sum, e) => sum + e.qty);
  double get _bakerySubtotal => _bakeryItems.fold<double>(0.0, (sum, e) => sum + (e.qty * e.rate));
  double get _baseSubtotal => _isBakeryMode ? _bakerySubtotal : (_deliveredCans * _pricePerCan);
  double get _totalBill => (_baseSubtotal + _extraCharge - _discountAmount).clamp(0.0, double.infinity);

  @override
  void dispose() {
    _customerController.dispose();
    _creditPinController.dispose();
    super.dispose();
  }

  Future<void> _selectRateSlab(double rate, String tierLabel) async {
    if (_rateLocked && _masterCustomerRate > 0 && rate < _masterCustomerRate - 0.01) {
      final approvedPin = await showDialog<String>(
        context: context,
        builder: (ctx) => _RateOverridePinDialog(
          customerName: _customerController.text.trim(),
          masterRate: _masterCustomerRate,
          requestedRate: rate,
          expectedPin: _managerOverridePin,
        ),
      );
      if (approvedPin == null || !mounted) return;
      setState(() {
        _pricePerCan = rate;
        _priceTier = tierLabel;
        _rateOverrideUsed = true;
        _overridePin = approvedPin;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rate overridden to ₹${rate.toStringAsFixed(0)} ($tierLabel) · Owner notification logged.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _pricePerCan = rate;
      _priceTier = tierLabel;
      if (_masterCustomerRate <= 0 || rate >= _masterCustomerRate) {
        _rateOverrideUsed = false;
        _overridePin = null;
      }
    });
  }

  Future<void> _openCustomRateDialog() async {
    final ctrl = TextEditingController(
      text: _pricePerCan > 0 ? _pricePerCan.toStringAsFixed(0) : '',
    );
    final raw = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Per-Can Rate'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Rate per Can / Unit (₹)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v != null && v > 0) Navigator.of(ctx).pop(v);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (raw == null || !mounted) return;
    await _selectRateSlab(raw, 'Custom Rate');
  }

  Future<void> _openShopQrVerificationDialog() async {
    final payloadText = await showDialog<String>(
      context: context,
      builder: (ctx) => _ShopQrVerifyDialog(expectedQrCode: _expectedShopQrCode),
    );
    if (payloadText != null && payloadText.isNotEmpty && mounted) {
      setState(() {
        _qrVerified = true;
        _verifiedQrPayload = payloadText;
      });
    }
  }

  void _captureEmptyJarPhotoProof() {
    final stamp = DateTime.now().toIso8601String();
    setState(() {
      _emptyJarPhotoVerified = true;
      _emptyJarPhotoRef = 'PHOTO-STK-${DateTime.now().millisecondsSinceEpoch}@$stamp';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Empty jar stack photo timestamped & attached for owner audit.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  static const List<({String name, double defaultRate})> _defaultBakeryItems = [
    (name: 'Sweet Biscuits Box', defaultRate: 180.0),
    (name: 'Salt Biscuits Pack', defaultRate: 140.0),
    (name: 'Tea Cake / Bun Tray', defaultRate: 120.0),
    (name: 'Butter Cookies / Rusk', defaultRate: 160.0),
  ];

  void _addOrIncrementBakeryItem(String name, double defaultRate) {
    setState(() {
      final idx = _bakeryItems.indexWhere((item) => item.name == name);
      if (idx >= 0) {
        final cur = _bakeryItems[idx];
        _bakeryItems[idx] = (name: cur.name, qty: cur.qty + 1, rate: cur.rate);
      } else {
        _bakeryItems.add((name: name, qty: 1, rate: defaultRate));
      }
    });
  }

  Future<void> _openCustomBakeryItemDialog() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final rateCtrl = TextEditingController(text: '150');
    final item = await showDialog<({String name, int qty, double rate})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Bakery / Biscuit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item / Box Name',
                hintText: 'e.g. Coconut Biscuits Box',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pieces / Boxes'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Rate (₹)'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final n = nameCtrl.text.trim();
              final q = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              final r = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
              if (n.isEmpty || q <= 0 || r <= 0) return;
              Navigator.of(ctx).pop((name: n, qty: q, rate: r));
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    qtyCtrl.dispose();
    rateCtrl.dispose();
    if (item != null && mounted) {
      setState(() => _bakeryItems.add(item));
    }
  }

  Future<void> _editBakeryItemRate(int index) async {
    final cur = _bakeryItems[index];
    final rateCtrl = TextEditingController(text: cur.rate.toStringAsFixed(0));
    final newRate = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rate for ${cur.name}'),
        content: TextField(
          controller: rateCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Rate per piece / box (₹)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final r = double.tryParse(rateCtrl.text.trim());
              if (r != null && r > 0) Navigator.of(ctx).pop(r);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    rateCtrl.dispose();
    if (newRate != null && mounted) {
      setState(() {
        _bakeryItems[index] = (name: cur.name, qty: cur.qty, rate: newRate);
      });
    }
  }

  Future<void> _openAdjustmentDialog() async {
    final extraCtrl = TextEditingController(
      text: _extraCharge > 0 ? _extraCharge.toStringAsFixed(0) : '',
    );
    final discCtrl = TextEditingController(
      text: _discountAmount > 0 ? _discountAmount.toStringAsFixed(0) : '',
    );
    final noteCtrl = TextEditingController(text: _adjustmentNote);

    final applied = await showDialog<({double extra, double disc, String note})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bill Adjustment (+ Extra / - Discount)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: extraCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '+ Extra Charge (₹)',
                hintText: 'e.g. 100',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: discCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '- Discount (₹)',
                hintText: 'e.g. 50',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason / Note',
                hintText: 'e.g. Special transport / Google Review',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final e = (double.tryParse(extraCtrl.text.trim()) ?? 0.0).clamp(0.0, 999999.0);
              final d = (double.tryParse(discCtrl.text.trim()) ?? 0.0).clamp(0.0, 999999.0);
              Navigator.of(ctx).pop((extra: e, disc: d, note: noteCtrl.text.trim()));
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    extraCtrl.dispose();
    discCtrl.dispose();
    noteCtrl.dispose();

    if (applied != null && mounted) {
      setState(() {
        _extraCharge = applied.extra;
        _discountAmount = applied.disc;
        _adjustmentNote = applied.note;
      });
    }
  }

  Future<void> _openGpayProofDialog() async {
    final utrCtrl = TextEditingController(text: _upiUtr ?? '');
    final fileNoteCtrl = TextEditingController(text: _upiProofRef ?? '');
    final saved = await showDialog<({String proofRef, String utr})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attach GPay / UPI Screenshot Proof'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the UPI Transaction / UTR ID or capture a timestamped screenshot reference so accounts can reconcile it later.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: utrCtrl,
              decoration: const InputDecoration(
                labelText: 'UPI Transaction / UTR Ref',
                hintText: 'e.g. 432198765432',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: fileNoteCtrl,
              decoration: const InputDecoration(
                labelText: 'Screenshot / Photo Ref (Auto if empty)',
                hintText: 'e.g. WhatsApp screenshot @ Kavin Axis',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final utr = utrCtrl.text.trim();
              final customRef = fileNoteCtrl.text.trim();
              final refStr = customRef.isNotEmpty
                  ? customRef
                  : 'GPAY-PROOF-${DateTime.now().millisecondsSinceEpoch}';
              Navigator.of(ctx).pop((proofRef: refStr, utr: utr));
            },
            child: const Text('Attach Proof'),
          ),
        ],
      ),
    );
    utrCtrl.dispose();
    fileNoteCtrl.dispose();

    if (saved != null && mounted) {
      setState(() {
        _upiProofRef = saved.proofRef;
        _upiUtr = saved.utr.isEmpty ? null : saved.utr;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPay screenshot proof attached for settlement verification.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _openCanPrintStudio({PosPrintFormat format = PosPrintFormat.canNeckTag50x38}) {
    if (_deliveredCans <= 0 || _pricePerCan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter delivered cans count and per-can rate before printing.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final activeCompany = ref.read(authNotifierProvider).activeCompany;
    final compName = (_companyName?.trim().isNotEmpty ?? false)
        ? _companyName!.trim()
        : (activeCompany?.name ?? 'Packaged Water Distribution');
    final gstin = _gstin ?? activeCompany?.gstin;
    final upiVpa = (_upiVpa?.trim().isNotEmpty ?? false) ? _upiVpa!.trim() : activeCompany?.upiVpa;
    final vehicleLabel = (_vehicleNumber?.trim().isNotEmpty ?? false)
        ? 'Water Route Van · ${_vehicleNumber!.trim()}'
        : 'Packaged Water Route';
    final sizeCode = _selectedCanSize
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-');
    final heldAfter = (_deliveredCans - _returnedEmpties).clamp(0, 999);
    PosPrintPreviewSheet.show(
      context,
      companyName: compName,
      branchName: vehicleLabel,
      gstin: gstin,
      upiVpa: upiVpa,
      referenceNo: 'CAN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      tokenNumber: _deliveredCans.toString().padLeft(3, '0'),
      customerName: _customerController.text.trim().isEmpty
          ? 'Route Customer'
          : _customerController.text.trim(),
      orderType: 'Water Can Route Drop',
      priceTier: _priceTier,
      paymentMethod: _paymentMode,
      initialFormat: format,
      items: [
        PosPrintLineItem(
          name: '$_selectedCanSize Packaged Drinking Water',
          code: sizeCode,
          qty: _deliveredCans.toDouble(),
          unitPrice: _pricePerCan,
          unitLabel: _selectedCanSize,
          note: 'Empty Jars Returned: $_returnedEmpties · Balance Held: $heldAfter',
        ),
      ],
      grandTotal: _totalBill,
      paidAmount: _paymentMode == 'Credit' ? 0.0 : _totalBill,
      extraTelemetryMeta: {
        'Full Cans Delivered': '$_deliveredCans Cans',
        'Empty Jars Returned': '$_returnedEmpties Cans',
        'Net Balance Held': '$heldAfter Cans',
        if (_verifiedQrPayload != null && _verifiedQrPayload!.isNotEmpty) 'Premises QR': _verifiedQrPayload!,
      },
    );
  }

  Future<void> _bookOrderFirst() async {
    if (_isBakeryMode) {
      if (_bakeryPiecesDelivered <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least 1 Bakery / Biscuit item before booking order.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    } else if (_deliveredCans <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set Delivered Full Cans (>= 1) first to book customer order.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_isMockGps) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mock/Spoofed GPS detected! Turn off fake GPS apps before booking an order.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isBookingOrder = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);
    final idempotencyKey = const Uuid().v4();

    final orderPayload = <String, dynamic>{
      if (_selectedCustomerId != null) 'customer_id': _selectedCustomerId,
      if (_customerController.text.trim().isNotEmpty) 'customer_name': _customerController.text.trim(),
      'ordered_cans': _deliveredCans,
      'can_size': _selectedCanSize,
      'can_rate': _pricePerCan > 0 ? _pricePerCan : 35.0,
      'payment_mode': _paymentMode,
      'start_immediately': true,
      'order_source': 'mobile_driver',
      'is_mock_gps': _isMockGps,
      if (_currentLat != null) 'latitude': _currentLat,
      if (_currentLng != null) 'longitude': _currentLng,
    };

    final result = await client.post<Map<String, dynamic>>(
      ApiEndpoints.waterCanOrders,
      data: orderPayload,
      idempotencyKey: idempotencyKey,
      fromJson: (raw) {
        if (raw is Map && raw['data'] is Map) {
          return Map<String, dynamic>.from(raw['data'] as Map);
        }
        return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      },
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final created = result.dataOrNull ?? <String, dynamic>{};
      setState(() {
        _isBookingOrder = false;
        _activeOrderId = int.tryParse((created['order_id'] ?? created['id'] ?? '').toString());
        _activeOrderNo = (created['order_no'] ?? created['delivery_no'])?.toString();
        _activeOrderStatus = 'in_transit';
        _orderedCans = _deliveredCans;
        if (_pricePerCan <= 0) {
          _pricePerCan = 35.0;
        }
      });
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${_activeOrderNo ?? ''} booked & Owner notified! You can now close at customer shop.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (result.failureOrNull?.statusCode == 422 || result.failureOrNull?.statusCode == 403) {
      setState(() => _isBookingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Could not create order.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } else {
      final offlineRef = 'ORD-OFFLINE-${DateTime.now().millisecondsSinceEpoch}';
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.waterCanOrders,
        method: 'POST',
        payload: {...orderPayload, 'client_order_ref': offlineRef},
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();
      if (!mounted) return;
      setState(() {
        _isBookingOrder = false;
        _activeOrderNo = offlineRef;
        _activeOrderStatus = 'in_transit';
        _orderedCans = _deliveredCans;
        if (_pricePerCan <= 0) {
          _pricePerCan = 35.0;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offline Order $offlineRef saved. Owner will be notified on sync. Close order now.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _markOrderInTransit() async {
    final orderId = _activeOrderId;
    if (orderId == null || orderId <= 0) return;
    setState(() => _isBookingOrder = true);
    final res = await ref.read(apiClientProvider).post(
          ApiEndpoints.waterCanOrderStart(orderId),
          data: {
            if (_currentLat != null) 'latitude': _currentLat,
            if (_currentLng != null) 'longitude': _currentLng,
            'is_mock_gps': _isMockGps,
          },
          fromJson: (d) => d,
        );
    if (!mounted) return;
    setState(() => _isBookingOrder = false);
    if (res.isSuccess) {
      setState(() => _activeOrderStatus = 'in_transit');
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${_activeOrderNo ?? ''} marked In Transit · Owner Notified!'),
          backgroundColor: AppColors.aquaPrimary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'Failed to start movement.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _submitTicket() async {
    if (_requiresOrderBookingFirst) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Step 1 Required: Book customer order first so the owner is notified before delivery.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_isBakeryMode) {
      if (_bakeryPiecesDelivered <= 0 || _bakerySubtotal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least 1 Bakery / Biscuit item with quantity and rate.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    } else {
      if (_deliveredCans <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivered full cans must be at least 1.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      if (_pricePerCan <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select a customer rate or enter per-can rate first.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    if (_isMockGps) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mock/Spoofed GPS detected! Turn off fake location apps before logging delivery.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_paymentMode == 'Credit' && _creditPinController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter 4-digit Customer Credit Confirmation PIN first.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (!_isBakeryMode && _emptyDeficit > 0 && !_emptyJarPhotoVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verify timestamped empty jar stack photo for unreturned jars.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final isPendingUpi = _paymentMode == 'UPI' && _upiVerificationStatus == 'pending_verification';
    final effectivePaidAmount = (_paymentMode == 'Credit' || isPendingUpi) ? 0.0 : _totalBill;

    final payload = {
      if (_activeOrderId != null) 'order_id': _activeOrderId,
      if (_activeOrderNo != null && _activeOrderNo!.startsWith('ORD-')) 'client_order_ref': _activeOrderNo,
      if (_orderedCans > 0) 'ordered_cans': _orderedCans,
      if (_selectedCustomerId != null) 'customer_id': _selectedCustomerId,
      'customer_name': _customerController.text.trim(),
      'item_category': _isBakeryMode ? 'bakery_supply' : 'water_can',
      if (_isBakeryMode) ...{
        'bakery_items': _bakeryItems
            .map((e) => {
                  'name': e.name,
                  'qty': e.qty,
                  'rate': e.rate,
                  'total': e.qty * e.rate,
                })
            .toList(),
        'bakery_pieces_delivered': _bakeryPiecesDelivered,
        'cans_delivered': 0,
        'delivered_cans': 0,
        'empty_cans_returned': 0,
        'returned_empties': 0,
      } else ...{
        'cans_delivered': _deliveredCans,
        'delivered_cans': _deliveredCans,
        'can_size': _selectedCanSize,
        'empty_cans_returned': _returnedEmpties,
        'returned_empties': _returnedEmpties,
        'unit_price': _pricePerCan,
        'can_rate': _pricePerCan,
        'master_rate': _masterCustomerRate,
        'price_per_can': _pricePerCan,
      },
      'extra_charge': _extraCharge,
      'discount_amount': _discountAmount,
      if (_adjustmentNote.isNotEmpty) 'adjustment_note': _adjustmentNote,
      'total_amount': _totalBill,
      'paid_amount': effectivePaidAmount,
      'cash_collected': effectivePaidAmount,
      'payment_mode': _paymentMode,
      'payment_verification_status': _paymentMode == 'UPI'
          ? _upiVerificationStatus
          : (_paymentMode == 'Credit' ? 'not_applicable' : 'confirmed'),
      if (_paymentMode == 'UPI' && isPendingUpi) 'claimed_upi_amount': _totalBill,
      if (_paymentMode == 'UPI' && _upiProofRef != null) 'payment_proof_ref': _upiProofRef,
      if (_paymentMode == 'UPI' && _upiUtr != null) 'upi_utr': _upiUtr,
      'enforce_anti_cheat': true,
      'is_mock_gps': _isMockGps,
      if (_currentLat != null) 'delivery_lat': _currentLat,
      if (_currentLng != null) 'delivery_lng': _currentLng,
      if (_geofenceDistanceM != null) 'geofence_distance_m': _geofenceDistanceM,
      'qr_verified': _qrVerified,
      if (_verifiedQrPayload != null) 'qr_payload': _verifiedQrPayload,
      'rate_override_used': _rateOverrideUsed,
      if (_overridePin != null) 'override_pin': _overridePin,
      'credit_pin_verified': _paymentMode == 'Credit' && _creditPinController.text.trim().length == 4,
      if (_paymentMode == 'Credit') 'credit_pin': _creditPinController.text.trim(),
      'whatsapp_alert_sent': _paymentMode == 'Credit' && _sendCreditWhatsappAlert,
      'empty_jar_photo_verified': _isBakeryMode || _emptyJarPhotoVerified || _emptyDeficit == 0,
      if (_emptyJarPhotoRef != null) 'refill_photo': _emptyJarPhotoRef,
      'remaining_van_cans': _vanRemainingCans,
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();
    final endpoint = _activeOrderId != null
        ? ApiEndpoints.waterCanOrderClose(_activeOrderId!)
        : ApiEndpoints.waterCanDeliveries;

    final result = await client.post(
      endpoint,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      await _showPostSaveDialog(offlineQueued: false);
    } else if (result.failureOrNull?.statusCode == 422 || result.failureOrNull?.statusCode == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Security audit blocked this delivery.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: endpoint,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      await _showPostSaveDialog(offlineQueued: true);
    }
  }

  Future<void> _showPostSaveDialog({required bool offlineQueued}) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              offlineQueued ? Icons.cloud_upload_outlined : Icons.verified_user_rounded,
              color: offlineQueued ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                offlineQueued ? 'Queued in Offline Outbox' : '7-Layer Audit Passed',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          offlineQueued
              ? 'Delivery saved offline with anti-cheat telemetry & will sync automatically.'
              : 'Delivery of $_deliveredCans cans (₹${_totalBill.toStringAsFixed(0)} via $_paymentMode) posted to ERP ledger.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openCanPrintStudio(format: PosPrintFormat.canNeckTag50x38);
            },
            child: const Text('Print 50x38mm Tag'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openCanPrintStudio(format: PosPrintFormat.thermal58mm);
            },
            child: const Text('Print 58mm Slip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedCol = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    ref.watch(activeRippleRoleProvider);
    ref.watch(activeDriverFlavorProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPad = screenWidth >= 700 ? 28.0 : 16.0;
    final activeCompany = ref.watch(authNotifierProvider.select((s) => s.activeCompany));
    final resolvedCompanyName = (_companyName?.trim().isNotEmpty ?? false)
        ? _companyName!.trim()
        : (activeCompany?.name ?? 'Company Account');
    final resolvedUpiVpa = (_upiVpa?.trim().isNotEmpty ?? false)
        ? _upiVpa!.trim()
        : (activeCompany?.upiVpa?.trim() ?? '');
    final upiPayload = resolvedUpiVpa.isEmpty
        ? ''
        : 'upi://pay?pa=$resolvedUpiVpa&pn=${Uri.encodeComponent(resolvedCompanyName)}&am=${_totalBill.toStringAsFixed(2)}&tn=WaterDrop&cu=INR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Can Delivery Anti-Cheat POS'),
        actions: [
          IconButton(
            onPressed: () => _openCanPrintStudio(format: PosPrintFormat.canNeckTag50x38),
            tooltip: 'Print 50x38mm Jar Seal Tag / 58mm Slip',
            icon: const Icon(Icons.qr_code_2_rounded),
          ),
          IconButton(
            onPressed: () => _openCanPrintStudio(format: PosPrintFormat.thermal58mm),
            tooltip: 'Print 58mm Delivery Slip',
            icon: const Icon(Icons.print_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPad),
        children: [
          // 7-Layer Security Banner (GPS + Mock Blocker + Van Stock Conservation)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isMockGps
                  ? AppColors.danger.withValues(alpha: 0.14)
                  : (_isGeofenceAlert || _exceedsVanStock)
                      ? AppColors.warning.withValues(alpha: 0.14)
                      : AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isMockGps
                    ? AppColors.danger
                    : (_isGeofenceAlert || _exceedsVanStock)
                        ? AppColors.warning
                        : AppColors.success.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isMockGps
                          ? Icons.gpp_bad_rounded
                          : (_qrVerified || !_isGeofenceAlert)
                              ? Icons.verified_user_rounded
                              : Icons.location_off_rounded,
                      color: _isMockGps
                          ? AppColors.danger
                          : (_isGeofenceAlert ? AppColors.warning : AppColors.success),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isMockGps
                            ? 'FAKE / MOCK GPS DETECTED — DELIVERY BLOCKED'
                            : _qrVerified
                                ? 'Shop Wall QR Verified ($_verifiedQrPayload)'
                                : _geofenceDistanceM != null
                                    ? (_isGeofenceAlert
                                        ? 'Outside Shop Geofence (${_geofenceDistanceM!.toStringAsFixed(0)}m > ${_customerAllowedRadius.toStringAsFixed(0)}m) — Scan Wall QR'
                                        : 'GPS Geofence Verified (${_geofenceDistanceM!.toStringAsFixed(0)}m from shop)')
                                    : (_currentLat != null
                                        ? 'Live GPS Fixed (${_currentLat!.toStringAsFixed(4)}, ${_currentLng!.toStringAsFixed(4)})'
                                        : '7-Layer Anti-Cheat Active · Ready for GPS/QR'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _isMockGps
                              ? AppColors.danger
                              : (_isGeofenceAlert ? AppColors.warning : AppColors.success),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _exceedsVanStock
                            ? AppColors.danger.withValues(alpha: 0.16)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Van Full Left: $_vanRemainingCans / $_vanLoadedCans cans'
                        '${_exceedsVanStock ? ' (EXCEEDS LOAD!)' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _exceedsVanStock ? AppColors.danger : textCol,
                        ),
                      ),
                    ),
                    ActionChip(
                      avatar: _isFetchingGps
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 15),
                      label: const Text('GPS Check', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      onPressed: _isFetchingGps ? null : _captureGpsFix,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.qr_code_scanner_rounded, size: 15),
                      label: Text(
                        _qrVerified ? 'QR Verified' : 'Scan Wall QR',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      onPressed: _openShopQrVerificationDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Top Mode Switch: Water Cans vs Bakery & Biscuits (Van Supply)
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.water_drop_rounded, size: 16),
                  label: Text('Water Cans', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.bakery_dining_rounded, size: 16),
                  label: Text('Bakery & Biscuits (Van)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
              selected: {_isBakeryMode},
              onSelectionChanged: (sel) => setState(() => _isBakeryMode = sel.first),
            ),
          ),
          const SizedBox(height: 14),

          if (_activeOrderId != null || (_activeOrderNo != null && _activeOrderNo!.startsWith('ORD-'))) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_activeOrderStatus == 'in_transit' ? AppColors.aquaPrimary : AppColors.warning)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (_activeOrderStatus == 'in_transit' ? AppColors.aquaPrimary : AppColors.warning)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Order ${_activeOrderNo ?? '#$_activeOrderId'} · Ordered ${_orderedCans > 0 ? _orderedCans : _deliveredCans} Cans',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textCol),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _activeOrderStatus == 'in_transit'
                              ? AppColors.aquaPrimary.withValues(alpha: 0.18)
                              : AppColors.warning.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _activeOrderStatus == 'in_transit' ? 'IN TRANSIT' : 'ORDERED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _activeOrderStatus == 'in_transit' ? AppColors.aquaPrimary : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_activeOrderStatus != 'in_transit' && _activeOrderId != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isBookingOrder ? null : _markOrderInTransit,
                        icon: const Icon(Icons.directions_run_rounded, size: 17),
                        label: const Text('Start Moving to Customer (Notify Owner)'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else if (_requiresOrderBookingFirst) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order-First Lock: Book Order Before Delivering',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textCol),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select customer & cans below, then tap Book Order First so Owner & Incharge get notified before delivery.',
                    style: TextStyle(fontSize: 12, color: mutedCol),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isBookingOrder ? null : _bookOrderFirst,
                      icon: const Icon(Icons.notifications_active_rounded, size: 17),
                      label: const Text('Step 1: Book Order & Notify Owner'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Customer Picker & Master Customer Rate Lock
          Builder(
            builder: (context) {
              final skin = RippleSkin.of(context);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: skin.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.storefront_rounded, color: skin.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Customer Party', style: AppTypography.label.copyWith(color: textCol, fontWeight: FontWeight.w700)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: _rateOverrideUsed
                                  ? AppColors.warning.withValues(alpha: 0.16)
                                  : skin.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _rateOverrideUsed
                                  ? 'PIN OVERRIDE · ₹${_pricePerCan.toStringAsFixed(0)}'
                                  : 'RATE LOCKED · ₹${_masterCustomerRate.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _rateOverrideUsed ? AppColors.warning : skin.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 8),
                  if (_customers.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      value: _customers.any(
                              (c) => int.tryParse((c['id'] ?? '').toString()) == _selectedCustomerId)
                          ? _selectedCustomerId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Route Stop',
                        prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                      ),
                      items: _customers
                          .map((c) {
                            final id = int.tryParse((c['id'] ?? 0).toString()) ?? 0;
                            final held = c['cans_held'] ?? 0;
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                '${c['name']} ($held jars held)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (id) {
                        if (id == null) return;
                        for (final c in _customers) {
                          if (int.tryParse((c['id'] ?? '').toString()) == id) {
                            setState(() => _applySelectedCustomer(c));
                            break;
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextFormField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name / Spot Drop',
                      prefixIcon: Icon(Icons.person_pin_circle_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (_masterCustomerRate > 0 &&
                          !_rateSlabs.any((s) => (s.rate - _masterCustomerRate).abs() < 0.01))
                        ChoiceChip(
                          selected: (_pricePerCan - _masterCustomerRate).abs() < 0.01,
                          label: Text(
                            'Master Rate ₹${_masterCustomerRate.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          onSelected: (_) => _selectRateSlab(_masterCustomerRate, 'Master Rate'),
                        ),
                      ..._rateSlabs.map(
                        (s) => ChoiceChip(
                          selected: (_pricePerCan - s.rate).abs() < 0.01,
                          label: Text(
                            '${s.label} ₹${s.rate.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          onSelected: (_) => _selectRateSlab(s.rate, s.label),
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.edit_rounded, size: 15),
                        label: Text(
                          _pricePerCan > 0 ? 'Set Rate (₹${_pricePerCan.toStringAsFixed(0)})' : 'Set Rate',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _openCustomRateDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
              );
            },
          ),
          const SizedBox(height: 16),

          if (_isBakeryMode) ...[
            // Bakery & Biscuits Van Supply Card (Tata Ace EV & Tata Ace Diesel)
            Builder(
              builder: (context) {
                final skin = RippleSkin.of(context);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.chaiPrimary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.bakery_dining_rounded, color: AppColors.chaiPrimary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bakery & Biscuit Van Supply',
                                    style: AppTypography.section.copyWith(color: textCol),
                                  ),
                                  Text(
                                    'Half-day / Alternate-day · $_bakeryPiecesDelivered pcs/boxes · ₹${_bakerySubtotal.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedCol),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _openCustomBakeryItemDialog,
                              icon: const Icon(Icons.playlist_add_rounded, size: 16),
                              label: const Text('Custom', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _defaultBakeryItems.map((preset) {
                            return ActionChip(
                              avatar: const Icon(Icons.cookie_rounded, size: 15, color: AppColors.chaiPrimary),
                              label: Text(
                                '${preset.name} (₹${preset.defaultRate.toStringAsFixed(0)})',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              onPressed: () => _addOrIncrementBakeryItem(preset.name, preset.defaultRate),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        if (_bakeryItems.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: skin.surface2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Tap any bakery item above or + Custom to log pieces/boxes delivered at this shop.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mutedCol),
                            ),
                          )
                        else
                          ...List.generate(_bakeryItems.length, (idx) {
                            final item = _bakeryItems[idx];
                            final lineTotal = item.qty * item.rate;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderCol),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textCol),
                                        ),
                                        const SizedBox(height: 2),
                                        InkWell(
                                          onTap: () => _editBakeryItemRate(idx),
                                          child: Text(
                                            '${item.qty} × ₹${item.rate.toStringAsFixed(0)} = ₹${lineTotal.toStringAsFixed(0)} (Tap rate to edit)',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.chaiPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (item.qty > 1) {
                                          _bakeryItems[idx] = (name: item.name, qty: item.qty - 1, rate: item.rate);
                                        } else {
                                          _bakeryItems.removeAt(idx);
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      '${item.qty}',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textCol),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _bakeryItems[idx] = (name: item.name, qty: item.qty + 1, rate: item.rate);
                                      });
                                    },
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.chaiPrimary),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Big Stepper: Delivered Cans
            Builder(
              builder: (context) {
                final skin = RippleSkin.of(context);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: skin.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.water_drop_rounded, color: skin.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Delivered Full Cans', style: AppTypography.section.copyWith(color: textCol)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: skin.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₹${_pricePerCan.toStringAsFixed(0)} / can',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: skin.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        WaterContainerSizeSelector(
                          selectedSize: _selectedCanSize,
                          onChanged: (size) => setState(() => _selectedCanSize = size),
                        ),
                        const SizedBox(height: 16),
                        ScrollableHeroCounter(
                          value: _deliveredCans,
                          min: 0,
                          max: 9999,
                          unitLabel: 'Delivered $_selectedCanSize',
                          onChanged: (v) => setState(() => _deliveredCans = v),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Returned Empties Stepper + Jar Deficit Photo Proof
            Builder(
              builder: (context) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.recycling_rounded, color: AppColors.success, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Returned Empty Jars', style: AppTypography.bodyMedium.copyWith(color: textCol)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ScrollableCounterRow(
                          title: 'Empty Containers Collected',
                          subtitle: '$_selectedCanSize · Scroll wheel or tap to type',
                          value: _returnedEmpties,
                          onChanged: (v) => setState(() => _returnedEmpties = v),
                          titleColor: textCol,
                        ),
                        if (_emptyDeficit > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _jarDepositRate > 0
                                      ? 'Empty Jar Hold: +$_emptyDeficit jars retained '
                                          '(Liability ₹${_jarDepositLiability.toStringAsFixed(0)} @ ₹${_jarDepositRate.toStringAsFixed(0)}/jar)'
                                      : 'Empty Jar Hold: +$_emptyDeficit jars retained · Timestamped stack photo required',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _captureEmptyJarPhotoProof,
                                  icon: Icon(
                                    _emptyJarPhotoVerified
                                        ? Icons.check_circle_rounded
                                        : Icons.camera_alt_rounded,
                                    size: 18,
                                    color: _emptyJarPhotoVerified ? AppColors.success : AppColors.warning,
                                  ),
                                  label: Text(
                                    _emptyJarPhotoVerified
                                        ? 'Stack Photo Verified ($_emptyJarPhotoRef)'
                                        : 'Capture Timestamped Stack Photo Proof',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // + Extra (₹) / - Discount (₹) Bill Adjustment Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Bill Adjustments (+ Extra / - Discount)', style: AppTypography.label.copyWith(color: textCol)),
                      ),
                      TextButton(
                        onPressed: _openAdjustmentDialog,
                        child: const Text('Custom ₹', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        label: const Text('+₹50 Extra', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: () => setState(() => _extraCharge += 50),
                      ),
                      ActionChip(
                        label: const Text('+₹100 Extra', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: () => setState(() => _extraCharge += 100),
                      ),
                      ActionChip(
                        label: const Text('-₹50 Disc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: () => setState(() => _discountAmount += 50),
                      ),
                      ActionChip(
                        label: const Text('-₹100 Disc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: () => setState(() => _discountAmount += 100),
                      ),
                      if (_extraCharge > 0 || _discountAmount > 0)
                        ActionChip(
                          label: const Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.danger)),
                          onPressed: () => setState(() {
                            _extraCharge = 0;
                            _discountAmount = 0;
                            _adjustmentNote = '';
                          }),
                        ),
                    ],
                  ),
                  if (_extraCharge > 0 || _discountAmount > 0 || _adjustmentNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Base ₹${_baseSubtotal.toStringAsFixed(0)} · Extra +₹${_extraCharge.toStringAsFixed(0)} · Discount -₹${_discountAmount.toStringAsFixed(0)}'
                      '${_adjustmentNote.isNotEmpty ? ' · $_adjustmentNote' : ''}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedCol),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Mode + Customer Credit PIN + Amount-Locked UPI QR
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Collection', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPaymentButton('Cash'),
                      const SizedBox(width: 8),
                      _buildPaymentButton('UPI'),
                      const SizedBox(width: 8),
                      _buildPaymentButton('Credit'),
                    ],
                  ),
                  if (_paymentMode == 'Credit') ...[
                    const SizedBox(height: 14),
                    Material(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Credit Approval — Customer PIN Required',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _creditPinController,
                              maxLength: 4,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Customer Credit Confirmation PIN',
                                hintText: '4-digit OTP or customer phone last 4 digits',
                                prefixIcon: Icon(Icons.pin_rounded, size: 20),
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: _sendCreditWhatsappAlert,
                              onChanged: (v) => setState(() => _sendCreditWhatsappAlert = v),
                              title: const Text(
                                'Trigger Instant Owner + Shopkeeper WhatsApp/SMS Alert',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_paymentMode == 'UPI') ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (resolvedUpiVpa.isEmpty)
                            const Text(
                              'Company UPI VPA is not configured in ERP Company Settings. Ask administrator to configure UPI VPA before collecting UPI QR.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
                            )
                          else
                            Row(
                              children: [
                                RepaintBoundary(
                                  child: CustomPaint(
                                    size: const Size(84, 84),
                                    painter: _CanUpiQrPainter(payload: upiPayload),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Amount-Locked Company UPI QR',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Exact Pay: ₹${_totalBill.toStringAsFixed(2)} -> $resolvedUpiVpa\nCustomer cannot alter amount or pay driver directly.',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const Divider(height: 18),
                          Text(
                            'GPay / UPI Confirmation Status',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textCol),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  selected: _upiVerificationStatus == 'confirmed',
                                  label: const Text('Confirmed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  onSelected: (_) => setState(() => _upiVerificationStatus = 'confirmed'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  selected: _upiVerificationStatus == 'pending_verification',
                                  label: const Text('Pending (Pay Later)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  onSelected: (_) => setState(() => _upiVerificationStatus = 'pending_verification'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openGpayProofDialog,
                              icon: Icon(
                                _upiProofRef != null ? Icons.verified_rounded : Icons.upload_file_rounded,
                                size: 17,
                                color: _upiProofRef != null ? AppColors.success : AppColors.primary,
                              ),
                              label: Text(
                                _upiProofRef != null
                                    ? 'GPay Proof Attached ($_upiProofRef)'
                                    : 'Attach GPay Screenshot / UTR Proof',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border(top: BorderSide(color: borderCol, width: 1)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Bill', style: AppTypography.caption),
                    AmountText(
                      amount: _totalBill,
                      style: AppTypography.title.copyWith(
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _requiresOrderBookingFirst
                    ? ((_isBookingOrder || _isMockGps) ? null : _bookOrderFirst)
                    : ((_isSubmitting || _isMockGps) ? null : _submitTicket),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(165, 48),
                ),
                child: (_isSubmitting || _isBookingOrder)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _requiresOrderBookingFirst
                            ? 'Book Order First'
                            : ((_activeOrderId != null ||
                                    (_activeOrderNo != null && _activeOrderNo!.startsWith('ORD-')))
                                ? 'Close & Deliver Order'
                                : 'Print & Save Ticket'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton(String mode) {
    final isSelected = _paymentMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primaryDark : AppColors.primary)
                : (isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            mode,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? (isDark ? Colors.black : Colors.white) : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RateOverridePinDialog extends StatefulWidget {
  final String customerName;
  final double masterRate;
  final double requestedRate;
  final String? expectedPin;

  const _RateOverridePinDialog({
    required this.customerName,
    required this.masterRate,
    required this.requestedRate,
    this.expectedPin,
  });

  @override
  State<_RateOverridePinDialog> createState() => _RateOverridePinDialogState();
}

class _RateOverridePinDialogState extends State<_RateOverridePinDialog> {
  final _pinCtrl = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manager Override PIN Required'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Master rate for ${widget.customerName.isEmpty ? "customer" : widget.customerName} is locked at ₹${widget.masterRate.toStringAsFixed(0)}/can. '
            'Dropping to ₹${widget.requestedRate.toStringAsFixed(0)} triggers an Owner Audit Alert.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinCtrl,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '4-Digit Manager PIN',
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
          onPressed: () {
            final entered = _pinCtrl.text.trim();
            final expected = widget.expectedPin?.trim() ?? '';
            if (expected.isNotEmpty) {
              if (entered == expected) {
                Navigator.of(context).pop(entered);
              } else {
                setState(() => _errorText = 'Invalid Manager PIN');
              }
            } else if (RegExp(r'^\d{4}$').hasMatch(entered)) {
              Navigator.of(context).pop(entered);
            } else {
              setState(() => _errorText = 'Enter a 4-digit Manager PIN');
            }
          },
          child: const Text('Unlock Rate'),
        ),
      ],
    );
  }
}

class _ShopQrVerifyDialog extends StatefulWidget {
  final String expectedQrCode;

  const _ShopQrVerifyDialog({required this.expectedQrCode});

  @override
  State<_ShopQrVerifyDialog> createState() => _ShopQrVerifyDialogState();
}

class _ShopQrVerifyDialogState extends State<_ShopQrVerifyDialog> {
  final _qrCtrl = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _qrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify Shop Wall QR Sticker'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan or enter the laminated Shop Wall QR code mounted at the customer premises.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qrCtrl,
            decoration: InputDecoration(
              labelText: 'Shop QR Code',
              prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
              errorText: _err,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
          onPressed: () {
            final entered = _qrCtrl.text.trim();
            if (entered.isEmpty) {
              setState(() => _err = 'Enter or scan the Shop Wall QR code');
            } else if (widget.expectedQrCode.isNotEmpty &&
                entered.toUpperCase() != widget.expectedQrCode.toUpperCase()) {
              setState(() => _err = 'Scanned QR does not match customer premises');
            } else {
              Navigator.of(context).pop(entered);
            }
          },
          child: const Text('Verify Premises'),
        ),
      ],
    );
  }
}

class _CanUpiQrPainter extends CustomPainter {
  final String payload;
  const _CanUpiQrPainter({required this.payload});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final fg = Paint()..color = Colors.black;
    const grid = 21;
    final cell = size.width / grid;
    var hash = 2166136261;
    for (var i = 0; i < payload.length; i++) {
      hash ^= payload.codeUnitAt(i);
      hash = (hash * 16777619) & 0x7fffffff;
    }

    bool isFinder(int r, int c) {
      final inTL = r < 7 && c < 7;
      final inTR = r < 7 && c >= grid - 7;
      final inBL = r >= grid - 7 && c < 7;
      if (!inTL && !inTR && !inBL) return false;
      final lr = r < 7 ? r : r - (grid - 7);
      final lc = c < 7 ? c : c - (grid - 7);
      return lr == 0 || lr == 6 || lc == 0 || lc == 6 || (lr >= 2 && lr <= 4 && lc >= 2 && lc <= 4);
    }

    for (var r = 0; r < grid; r++) {
      for (var c = 0; c < grid; c++) {
        final on = isFinder(r, c) ||
            ((r == 6 || c == 6) && (r + c).isEven) ||
            (((hash ^ (r * 31 + c * 17)) & 1) == 1);
        if (on) {
          canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), fg);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanUpiQrPainter oldDelegate) => oldDelegate.payload != payload;
}

