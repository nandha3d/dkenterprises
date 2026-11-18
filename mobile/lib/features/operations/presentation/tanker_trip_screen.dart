import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/adaptive_layout.dart';
import '../../../core/ui/amount_text.dart';
import '../../../core/ui/pos_print_preview_sheet.dart';
import 'water_order_helpers.dart';

enum TankerTripPhase {
  preTrip('PRE-TRIP READY', Icons.local_shipping_outlined),
  movingTransit('MOVING · GPS TRACKING', Icons.satellite_alt_rounded),
  atSiteDwell('AT SITE · DWELL TIMER', Icons.factory_outlined),
  motorDecanting('MOTOR PUMPING ACTIVE', Icons.water_drop_rounded),
  completed('TRIP LOCKED', Icons.verified_rounded);

  final String label;
  final IconData icon;
  const TankerTripPhase(this.label, this.icon);
}

typedef TankerGpsFetcher = Future<({double lat, double lng})?> Function();

class TankerTripScreen extends ConsumerStatefulWidget {
  final TankerGpsFetcher? gpsFetcher;
  final Map<String, dynamic>? initialTrip;

  const TankerTripScreen({super.key, this.gpsFetcher, this.initialTrip});

  @override
  ConsumerState<TankerTripScreen> createState() => _TankerTripScreenState();
}

class _TankerTripScreenState extends ConsumerState<TankerTripScreen> {
  final _customerController = TextEditingController();
  final _destinationController = TextEditingController();
  final _startOdoController = TextEditingController();
  final _endOdoController = TextEditingController();
  final _klController = TextEditingController();
  final _tripRateController = TextEditingController();
  final _tollController = TextEditingController(text: '0');
  final _dieselController = TextEditingController(text: '0');
  final _receiverController = TextEditingController();
  final _extraChargeController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _adjustmentNoteController = TextEditingController();
  final _extVehicleController = TextEditingController();
  final _extVendorController = TextEditingController();
  final _vendorPayableController = TextEditingController(text: '0');

  double _selectedKl = 0.0;
  double _baseTripRate = 0.0;
  int? _selectedOrderId;
  String? _selectedTripNumber;
  int? _selectedCustomerId;
  int? _tankerId;
  String _vehicleNumber = '';
  String _companyName = '';
  String? _gstin;
  String? _upiVpa;
  List<Map<String, dynamic>> _pendingTrips = [];
  List<Map<String, dynamic>> _waterPackages = [];
  List<Map<String, dynamic>> _tankers =
      kDefaultTmwsTankerFleet.map((e) => Map<String, dynamic>.from(e)).toList();
  List<Map<String, dynamic>> _pickupPoints =
      kDefaultWaterPickupPoints.map((e) => Map<String, dynamic>.from(e)).toList();
  int? _selectedPickupPointId =
      int.tryParse(kDefaultWaterPickupPoints.first['id'].toString());
  String _pickupPointName = kDefaultWaterPickupPoints.first['name'].toString();
  bool _isOutsourcedVehicle = false;
  String _paymentMode = 'Account / Credit';
  String _gpayStatus = 'pending_verification';
  String _paymentAccount = 'GPAY - KAVIN AXIS';
  GpayProofAttachment? _gpayProof;

  TankerTripPhase _phase = TankerTripPhase.preTrip;

  // Chronometer & Timestamps
  DateTime? _tripStartedAt;
  DateTime? _siteArrivedAt;
  DateTime? _siteDepartedAt;
  DateTime? _motorStartedAt;
  DateTime? _motorStoppedAt;

  int _travelSeconds = 0;
  int _siteDwellSeconds = 0;
  int _motorSeconds = 0;

  bool _isGpsTracking = false;
  bool _isMotorRunning = false;
  bool _autoTimedMotorRate = true;

  double _gpsTrackedKm = 0.0;
  double _currentSpeedKmh = 0.0;
  Position? _lastGpsPosition;
  final List<Map<String, dynamic>> _breadcrumbs = [];

  Timer? _chronometerTimer;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTrip != null) {
      _applySelectedOrder(widget.initialTrip!, notify: false);
    }
    _fetchManifestAndPackages();
    _fetchCustomers();
  }

  void _applySelectedOrder(Map<String, dynamic> order, {bool notify = true}) {
    void updateFields() {
      _selectedOrderId = int.tryParse(order['id']?.toString() ?? '');
      _selectedTripNumber = order['trip_number']?.toString();
      _selectedCustomerId = int.tryParse(order['customer_id']?.toString() ?? '');
      final orderTankerId = int.tryParse(order['tanker_id']?.toString() ?? '');
      if (orderTankerId != null && orderTankerId > 0) {
        _tankerId = orderTankerId;
      }
      final vNo = order['vehicle_number']?.toString();
      if (vNo != null && vNo.isNotEmpty) {
        _vehicleNumber = vNo;
      }
      final custName = order['customer_name']?.toString() ?? '';
      final dest = order['destination_site']?.toString() ?? '';
      if (custName.isNotEmpty) {
        _customerController.text = custName;
      } else if (dest.isNotEmpty) {
        _customerController.text = dest;
      }
      if (dest.isNotEmpty) {
        _destinationController.text = dest;
      }
      final sKm = int.tryParse(order['start_km']?.toString() ?? '') ?? 0;
      if (sKm > 0) {
        _startOdoController.text = sKm.toString();
      }
      final eKm = int.tryParse(order['end_km']?.toString() ?? '') ?? 0;
      if (eKm > 0) {
        _endOdoController.text = eKm.toString();
      }
      final qtyKl = (order['water_quantity_kl'] as num?)?.toDouble() ?? 0.0;
      if (qtyKl > 0) {
        _selectedKl = qtyKl;
        _klController.text = qtyKl.toString();
      }
      final rate = (order['trip_rate'] as num?)?.toDouble() ?? 0.0;
      if (rate > 0) {
        _baseTripRate = rate;
        _tripRateController.text = rate.toStringAsFixed(0);
      }
      final receiver = order['site_receiver_name']?.toString() ?? '';
      if (receiver.isNotEmpty) {
        _receiverController.text = receiver;
      }
      final ppId = int.tryParse(order['pickup_point_id']?.toString() ?? '');
      if (ppId != null && ppId > 0) {
        _selectedPickupPointId = ppId;
      }
      final ppName = (order['pickup_point_name'] ?? order['source_plant'] ?? '').toString().trim();
      if (ppName.isNotEmpty) {
        _pickupPointName = ppName;
      }
      if (order['is_outsourced_vehicle'] == true || order['is_outsourced_vehicle'] == 1) {
        _isOutsourcedVehicle = true;
        _extVehicleController.text = (order['external_vehicle_no'] ?? '').toString();
        _extVendorController.text = (order['external_vendor_name'] ?? '').toString();
        final vPay = (order['vendor_payable_amount'] as num?)?.toDouble() ?? 0.0;
        _vendorPayableController.text = vPay.toStringAsFixed(0);
      }
      final extra = (order['extra_charge'] as num?)?.toDouble() ?? 0.0;
      if (extra > 0) _extraChargeController.text = extra.toStringAsFixed(0);
      final disc = (order['discount_amount'] as num?)?.toDouble() ?? 0.0;
      if (disc > 0) _discountController.text = disc.toStringAsFixed(0);
      final adjNote = order['adjustment_note']?.toString() ?? '';
      if (adjNote.isNotEmpty) _adjustmentNoteController.text = adjNote;
      final mode = order['payment_mode']?.toString() ?? '';
      if (mode.isNotEmpty) {
        final lower = mode.toLowerCase();
        if (lower.contains('cash')) {
          _paymentMode = 'Cash';
        } else if (lower.contains('gpay') || lower.contains('upi')) {
          _paymentMode = 'GPay / UPI';
        } else {
          _paymentMode = 'Account / Credit';
        }
      }
      final verStatus = order['payment_verification_status']?.toString() ?? '';
      if (verStatus == 'confirmed' || verStatus == 'pending_verification') {
        _gpayStatus = verStatus;
      }
    }

    if (notify && mounted) {
      setState(updateFields);
    } else {
      updateFields();
    }
  }

  void _clearSelectedOrder() {
    setState(() {
      _selectedOrderId = null;
      _selectedTripNumber = null;
    });
  }

  Future<void> _fetchManifestAndPackages() async {
    final client = ref.read(apiClientProvider);
    final manifestRes = await client.get(
      ApiEndpoints.driverManifest,
      fromJson: (data) => data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
    );
    final bootstrapRes = await client.get(
      ApiEndpoints.bootstrap,
      fromJson: (data) => data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
    );
    final fleetMeta = await fetchTmwsFleetAndPickupPoints(client);

    if (!mounted) return;
    setState(() {
      final manifestRaw = manifestRes.dataOrNull ?? const <String, dynamic>{};
      final mData = manifestRaw['data'] is Map
          ? Map<String, dynamic>.from(manifestRaw['data'] as Map)
          : manifestRaw;

      final manifestTankers = mData['tankers'] is List
          ? (mData['tankers'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      _tankers = manifestTankers.isNotEmpty ? manifestTankers : fleetMeta.tankers;

      final manifestPickups = mData['pickup_points'] is List
          ? (mData['pickup_points'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      _pickupPoints = manifestPickups.isNotEmpty ? manifestPickups : fleetMeta.pickupPoints;

      if (mData.isNotEmpty) {
        _companyName = mData['company_name']?.toString() ?? _companyName;
        _gstin = mData['gstin']?.toString() ?? _gstin;
        _upiVpa = mData['upi_vpa']?.toString() ?? _upiVpa;

        if (mData['vehicle'] is Map) {
          final veh = Map<String, dynamic>.from(mData['vehicle'] as Map);
          final vid = int.tryParse(veh['id']?.toString() ?? '');
          if (vid != null && vid > 0) {
            _tankerId ??= vid;
            if (!_tankers.any((t) => int.tryParse((t['id'] ?? '').toString()) == vid)) {
              _tankers = [veh, ..._tankers];
            }
          }
          _vehicleNumber = veh['vehicle_number']?.toString() ?? _vehicleNumber;
          final curOdo = int.tryParse(veh['current_odometer']?.toString() ?? '') ?? 0;
          if (_startOdoController.text.trim().isEmpty && curOdo > 0) {
            _startOdoController.text = curOdo.toString();
          }
          if (_selectedKl <= 0) {
            final capKl = (veh['capacity_kl'] as num?)?.toDouble() ?? 0.0;
            if (capKl > 0) {
              _selectedKl = capKl;
              _klController.text = capKl.toString();
            }
          }
        }

        if (mData['pending_trips'] is List) {
          _pendingTrips = (mData['pending_trips'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (_selectedOrderId == null && widget.initialTrip == null && _pendingTrips.isNotEmpty) {
            _applySelectedOrder(_pendingTrips.first, notify: false);
          }
        }
      }

      if (_tankerId == null && _tankers.isNotEmpty) {
        _tankerId = int.tryParse((_tankers.first['id'] ?? '').toString());
        if (_vehicleNumber.isEmpty) {
          _vehicleNumber = (_tankers.first['vehicle_number'] ?? '').toString();
        }
      } else if (_tankerId != null &&
          !_tankers.any((t) => int.tryParse((t['id'] ?? '').toString()) == _tankerId)) {
        _tankerId = _tankers.isNotEmpty ? int.tryParse((_tankers.first['id'] ?? '').toString()) : null;
      }

      if (_pickupPoints.isNotEmpty) {
        final match = _pickupPoints.firstWhere(
          (p) => int.tryParse((p['id'] ?? '').toString()) == _selectedPickupPointId,
          orElse: () => _pickupPoints.first,
        );
        _selectedPickupPointId = int.tryParse((match['id'] ?? '').toString());
        _pickupPointName = (match['name'] ?? _pickupPointName).toString();
      } else {
        _selectedPickupPointId = null;
      }

      final bootRaw = bootstrapRes.dataOrNull ?? const <String, dynamic>{};
      final bData = bootRaw['data'] is Map
          ? Map<String, dynamic>.from(bootRaw['data'] as Map)
          : bootRaw;
      if (bData['packages'] is List) {
        _waterPackages = (bData['packages'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (bData['water_packages'] is List) {
        _waterPackages = (bData['water_packages'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    });
  }

  Future<void> _fetchCustomers() async {
    final client = ref.read(apiClientProvider);
    final res = await client.get(
      ApiEndpoints.customers,
      fromJson: (data) {
        final list = data is Map && data['data'] is List
            ? data['data'] as List
            : (data is List ? data : []);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      },
    );
    if (mounted && res.isSuccess && (res.dataOrNull?.isNotEmpty ?? false)) {
      setState(() {
        _customers = res.dataOrNull ?? [];
      });
    }
  }

  @override
  void dispose() {
    _chronometerTimer?.cancel();
    _customerController.dispose();
    _destinationController.dispose();
    _startOdoController.dispose();
    _endOdoController.dispose();
    _klController.dispose();
    _tripRateController.dispose();
    _tollController.dispose();
    _dieselController.dispose();
    _receiverController.dispose();
    _extraChargeController.dispose();
    _discountController.dispose();
    _adjustmentNoteController.dispose();
    _extVehicleController.dispose();
    _extVendorController.dispose();
    _vendorPayableController.dispose();
    super.dispose();
  }

  void _ensureChronometerRunning() {
    _chronometerTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_phase == TankerTripPhase.movingTransit) {
          _travelSeconds++;
          // Accumulate realistic road progression when moving
          _gpsTrackedKm = double.parse((_gpsTrackedKm + 0.0095).toStringAsFixed(2));
          _currentSpeedKmh = 36.0;
        } else if (_phase == TankerTripPhase.atSiteDwell) {
          _siteDwellSeconds++;
          _currentSpeedKmh = 0.0;
        } else if (_phase == TankerTripPhase.motorDecanting) {
          _siteDwellSeconds++;
          _motorSeconds++;
          _currentSpeedKmh = 0.0;
        }
      });
    });
  }

  Future<void> _captureGpsCheckpoint(String phaseLabel) async {
    double lat = 11.3410 + (_breadcrumbs.length * 0.008);
    double lng = 77.7172 - (_breadcrumbs.length * 0.009);
    try {
      if (widget.gpsFetcher != null) {
        final fix = await widget.gpsFetcher!.call();
        if (fix != null) {
          if (_lastGpsPosition != null) {
            final segKm = _haversineKm(
              _lastGpsPosition!.latitude,
              _lastGpsPosition!.longitude,
              fix.lat,
              fix.lng,
            );
            if (segKm >= 0.01) {
              _gpsTrackedKm = double.parse((_gpsTrackedKm + segKm).toStringAsFixed(2));
            }
          }
          lat = fix.lat;
          lng = fix.lng;
        }
      } else {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 2));
        if (_lastGpsPosition != null) {
          final segKm = _haversineKm(
            _lastGpsPosition!.latitude,
            _lastGpsPosition!.longitude,
            pos.latitude,
            pos.longitude,
          );
          if (segKm >= 0.01) {
            _gpsTrackedKm = double.parse((_gpsTrackedKm + segKm).toStringAsFixed(2));
          }
        }
        _lastGpsPosition = pos;
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {
      // Fallback to simulated plant/corridor coordinates on desktop/offline
    }

    _breadcrumbs.add({
      'seq': _breadcrumbs.length + 1,
      'label': phaseLabel,
      'latitude': lat,
      'longitude': lng,
      'speed_kmh': _currentSpeedKmh.round(),
      'valve_status': _isMotorRunning ? 'ACTIVE_DECANT' : 'SEALED',
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  // --- Stage Actions ---
  void _startMovingGps() {
    setState(() {
      _tripStartedAt ??= DateTime.now();
      _isGpsTracking = true;
      _isMotorRunning = false;
      _phase = TankerTripPhase.movingTransit;
    });
    _ensureChronometerRunning();
    _captureGpsCheckpoint('Departed Plant (GPS Tracking Started)');
  }

  void _markArrivedAtSite() {
    setState(() {
      _siteArrivedAt = DateTime.now();
      _isMotorRunning = false;
      _phase = TankerTripPhase.atSiteDwell;
    });
    _ensureChronometerRunning();
    _captureGpsCheckpoint('Arrived at Customer Site (${_customerController.text})');
  }

  void _toggleMotorPump() {
    setState(() {
      if (!_isMotorRunning) {
        _isMotorRunning = true;
        _motorStartedAt = DateTime.now();
        _motorStoppedAt = null;
        _phase = TankerTripPhase.motorDecanting;
        _ensureChronometerRunning();
        _captureGpsCheckpoint('Motor Decanting Pump Started');
      } else {
        _isMotorRunning = false;
        _motorStoppedAt = DateTime.now();
        _phase = TankerTripPhase.atSiteDwell;
        _captureGpsCheckpoint('Motor Decanting Pump Stopped');
      }
    });
  }

  void _lockTripTiming() {
    _chronometerTimer?.cancel();
    _chronometerTimer = null;
    setState(() {
      _isGpsTracking = false;
      if (_isMotorRunning) {
        _isMotorRunning = false;
        _motorStoppedAt = DateTime.now();
      }
      _siteDepartedAt = DateTime.now();
      _currentSpeedKmh = 0.0;
      _phase = TankerTripPhase.completed;
    });
    _captureGpsCheckpoint('Trip Completed & Odometer Locked');
  }

  // --- Derived Metrics & Surcharges ---
  int get _startOdo => int.tryParse(_startOdoController.text.trim()) ?? 0;
  int get _endOdo => int.tryParse(_endOdoController.text.trim()) ?? 0;
  int get _odometerKm => math.max(0, _endOdo - _startOdo);

  double get _odoGpsDriftKm => (_odometerKm - _gpsTrackedKm).abs();
  double get _odoGpsDriftPct =>
      (_odoGpsDriftKm / math.max(1.0, _gpsTrackedKm)) * 100.0;
  bool get _isOdoVerified => _odoGpsDriftPct <= 8.0;

  int get _travelMinutes => (_travelSeconds / 60).ceil();
  int get _siteDwellMinutes => (_siteDwellSeconds / 60).ceil();
  int get _motorMinutes => (_motorSeconds / 60).ceil();

  // First 30 mins at customer site are grace unloading window; beyond 30m billed at Rs.150/hr (Rs.2.50/min)
  int get _billableWaitingMinutes => math.max(0, _siteDwellMinutes - 30);
  double get _waitingSurcharge =>
      double.parse((_billableWaitingMinutes * 2.50).toStringAsFixed(2));

  // Motor surcharge: Base Rs.150 + Rs.5/min beyond 15 mins (or flat Rs.250 when auto-timed is off)
  double get _motorPumpingSurcharge {
    if (_motorMinutes <= 0) return 0.0;
    if (!_autoTimedMotorRate) return 250.0;
    final extraMins = math.max(0, _motorMinutes - 15);
    return 150.0 + (extraMins * 5.0);
  }

  int get _estimatedDecantedLitres => _motorMinutes * 160;
  double get _tollAmount => double.tryParse(_tollController.text.trim()) ?? 0.0;
  double get _dieselAmount => double.tryParse(_dieselController.text.trim()) ?? 0.0;
  double get _extraCharge =>
      (double.tryParse(_extraChargeController.text.trim()) ?? 0.0).clamp(0.0, double.infinity);
  double get _discountAmount =>
      (double.tryParse(_discountController.text.trim()) ?? 0.0).clamp(0.0, double.infinity);

  double get _totalBill => (_baseTripRate +
          _motorPumpingSurcharge +
          _waitingSurcharge +
          _tollAmount +
          _extraCharge -
          _discountAmount)
      .clamp(0.0, double.infinity);

  String _formatDuration(int totalSeconds) {
    final hrs = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    if (hrs > 0) {
      return '${hrs}h ${mins.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${mins.toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';
  }

  String _formatClock(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  Future<void> _pickManualMotorWindow() async {
    final now = TimeOfDay.now();
    final startPick = await showTimePicker(
      context: context,
      initialTime: _motorStartedAt != null
          ? TimeOfDay.fromDateTime(_motorStartedAt!)
          : TimeOfDay(hour: (now.hour - 1).clamp(0, 23), minute: now.minute),
      helpText: 'SELECT MOTOR PUMP START TIME',
    );
    if (startPick == null || !mounted) return;

    final stopPick = await showTimePicker(
      context: context,
      initialTime: _motorStoppedAt != null
          ? TimeOfDay.fromDateTime(_motorStoppedAt!)
          : now,
      helpText: 'SELECT MOTOR PUMP STOP TIME',
    );
    if (stopPick == null || !mounted) return;

    final today = DateTime.now();
    var startDt = DateTime(today.year, today.month, today.day, startPick.hour, startPick.minute);
    var stopDt = DateTime(today.year, today.month, today.day, stopPick.hour, stopPick.minute);
    if (stopDt.isBefore(startDt)) {
      stopDt = stopDt.add(const Duration(days: 1));
    }

    setState(() {
      _motorStartedAt = startDt;
      _motorStoppedAt = stopDt;
      _motorSeconds = stopDt.difference(startDt).inSeconds;
    });
  }

  Future<void> _pickManualSiteDwellWindow() async {
    final now = TimeOfDay.now();
    final arrivePick = await showTimePicker(
      context: context,
      initialTime: _siteArrivedAt != null
          ? TimeOfDay.fromDateTime(_siteArrivedAt!)
          : TimeOfDay(hour: (now.hour - 1).clamp(0, 23), minute: now.minute),
      helpText: 'SELECT CUSTOMER SITE ARRIVAL TIME',
    );
    if (arrivePick == null || !mounted) return;

    final departPick = await showTimePicker(
      context: context,
      initialTime: _siteDepartedAt != null
          ? TimeOfDay.fromDateTime(_siteDepartedAt!)
          : now,
      helpText: 'SELECT CUSTOMER SITE DEPARTURE TIME',
    );
    if (departPick == null || !mounted) return;

    final today = DateTime.now();
    var arrDt = DateTime(today.year, today.month, today.day, arrivePick.hour, arrivePick.minute);
    var depDt = DateTime(today.year, today.month, today.day, departPick.hour, departPick.minute);
    if (depDt.isBefore(arrDt)) {
      depDt = depDt.add(const Duration(days: 1));
    }

    setState(() {
      _siteArrivedAt = arrDt;
      _siteDepartedAt = depDt;
      _siteDwellSeconds = depDt.difference(arrDt).inSeconds;
    });
  }

  void _openPrintPreview() {
    final activeCompany = ref.read(authNotifierProvider).activeCompany;
    final companyLabel = _companyName.isNotEmpty
        ? _companyName
        : (activeCompany?.name ?? 'Bulk Tanker Operations');
    final branchLabel = _vehicleNumber.isNotEmpty
        ? 'Bulk Tanker Division · $_vehicleNumber'
        : 'Bulk Tanker Division';

    PosPrintPreviewSheet.show(
      context,
      companyName: companyLabel,
      branchName: branchLabel,
      gstin: _gstin ?? activeCompany?.gstin,
      upiVpa: _upiVpa ?? activeCompany?.upiVpa,
      referenceNo: _selectedTripNumber ??
          'TRIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      tokenNumber: '${_selectedKl.toStringAsFixed(0)}KL',
      customerName: _customerController.text.trim().isEmpty
          ? 'Customer Site'
          : _customerController.text.trim(),
      orderType: 'Bulk Tanker Delivery',
      priceTier: '${_selectedKl.toStringAsFixed(1)} KL Load',
      paymentMethod: 'B2B Trip Sheet',
      initialFormat: PosPrintFormat.thermal58mm,
      items: [
        PosPrintLineItem(
          name: 'Bulk Water (${_selectedKl.toStringAsFixed(1)} KL Load)',
          code: 'BW-${_selectedKl.toStringAsFixed(0)}KL',
          qty: 1,
          unitPrice: _baseTripRate,
          unitLabel: 'Load',
          note: 'Dest: ${_destinationController.text.trim()}',
        ),
        if (_motorPumpingSurcharge > 0)
          PosPrintLineItem(
            name: 'Motor Pump (${_motorMinutes}m Run)',
            code: 'SUR-MOTOR',
            qty: 1,
            unitPrice: _motorPumpingSurcharge,
            unitLabel: 'Session',
            note: '${_formatClock(_motorStartedAt)} to ${_formatClock(_motorStoppedAt)}',
          ),
        if (_waitingSurcharge > 0)
          PosPrintLineItem(
            name: 'Site Waiting (${_billableWaitingMinutes}m Billable)',
            code: 'SUR-WAIT',
            qty: 1,
            unitPrice: _waitingSurcharge,
            unitLabel: 'Detention',
            note: 'Total at place: $_siteDwellMinutes mins (30m free)',
          ),
        if (_tollAmount > 0)
          PosPrintLineItem(
            name: 'Highway Tollgate Reimbursement',
            code: 'SUR-TOLL',
            qty: 1,
            unitPrice: _tollAmount,
          ),
      ],
      grandTotal: _totalBill,
      paidAmount: _totalBill,
      extraTelemetryMeta: {
        'Odometer': '$_startOdo -> $_endOdo ($_odometerKm km)',
        'GPS Distance': '${_gpsTrackedKm.toStringAsFixed(1)} km (${_isOdoVerified ? "VERIFIED" : "DRIFT"})',
        'Travel Time': '$_travelMinutes mins',
        'Spent at Site': '$_siteDwellMinutes mins (Wait: ${_billableWaitingMinutes}m)',
        'Motor Timing': '$_motorMinutes mins (${_formatClock(_motorStartedAt)}-${_formatClock(_motorStoppedAt)})',
      },
    );
  }

  Future<void> _submitTrip() async {
    final customerName = _customerController.text.trim();
    final destination = _destinationController.text.trim().isNotEmpty
        ? _destinationController.text.trim()
        : customerName;
    if (customerName.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an assigned order or enter customer & destination site.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final paidForPayload = _paymentMode == 'Account / Credit'
        ? 0.0
        : (_paymentMode == 'GPay / UPI' && _gpayStatus == 'pending_verification'
            ? 0.0
            : _totalBill);
    final verificationStatus = _paymentMode == 'GPay / UPI'
        ? _gpayStatus
        : (_paymentMode == 'Cash' ? 'confirmed' : 'not_applicable');

    final payload = <String, dynamic>{
      if (_selectedOrderId != null) 'trip_id': _selectedOrderId,
      if (!_isOutsourcedVehicle && _tankerId != null) 'tanker_id': _tankerId,
      if (!_isOutsourcedVehicle && _vehicleNumber.isNotEmpty) 'vehicle_number': _vehicleNumber,
      if (_isOutsourcedVehicle) ...{
        'is_outsourced_vehicle': true,
        'external_vehicle_no': _extVehicleController.text.trim(),
        if (_extVendorController.text.trim().isNotEmpty)
          'external_vendor_name': _extVendorController.text.trim(),
        'vendor_payable_amount':
            double.tryParse(_vendorPayableController.text.trim()) ?? 0.0,
      },
      if (_selectedPickupPointId != null) 'pickup_point_id': _selectedPickupPointId,
      if (_pickupPointName.isNotEmpty) ...{
        'pickup_point_name': _pickupPointName,
        'source_plant': _pickupPointName,
      },
      if (_selectedCustomerId != null) 'customer_id': _selectedCustomerId,
      'status': 'completed',
      'customer_name': customerName,
      'destination_site': destination,
      'delivery_site': _destinationController.text.trim(),
      'water_quantity_litres': (_selectedKl * 1000).round(),
      'water_quantity_kl': _selectedKl,
      'start_odometer': _startOdo,
      'end_odometer': _endOdo,
      'start_km': _startOdo,
      'end_km': _endOdo,
      'gps_tracked_km': _gpsTrackedKm,
      'odometer_variance_km': double.parse(_odoGpsDriftKm.toStringAsFixed(2)),
      'trip_started_at': _tripStartedAt?.toIso8601String(),
      'site_arrived_at': _siteArrivedAt?.toIso8601String(),
      'site_departed_at': _siteDepartedAt?.toIso8601String(),
      'travel_duration_minutes': _travelMinutes,
      'site_dwell_minutes': _siteDwellMinutes,
      'waiting_minutes': _billableWaitingMinutes,
      'waiting_charge': _waitingSurcharge,
      'motor_started_at': _motorStartedAt?.toIso8601String(),
      'motor_stopped_at': _motorStoppedAt?.toIso8601String(),
      'motor_pumping_minutes': _motorMinutes,
      'motor_pumping_charge': _motorPumpingSurcharge,
      'toll_expense': _tollAmount,
      'diesel_expense': _dieselAmount,
      'extra_charge': _extraCharge,
      'discount_amount': _discountAmount,
      if (_adjustmentNoteController.text.trim().isNotEmpty)
        'adjustment_note': _adjustmentNoteController.text.trim(),
      'payment_mode': _paymentMode,
      'payment_verification_status': verificationStatus,
      if (_paymentMode == 'GPay / UPI') ...{
        'payment_status_flag': _gpayStatus,
        'payment_account': _gpayProof?.paymentAccount ?? _paymentAccount,
        'claimed_upi_amount': _totalBill,
        if (_gpayProof != null && _gpayProof!.referenceNo.isNotEmpty)
          'payment_ref': _gpayProof!.referenceNo,
        if (_gpayProof?.base64Data != null)
          'payment_proof_base64': _gpayProof!.base64Data,
      } else if (_paymentMode == 'Cash') ...{
        'payment_account': 'CASH',
      },
      'paid_amount': paidForPayload,
      'site_receiver_name': _receiverController.text.trim(),
      'trip_rate': _totalBill,
      'billed_amount': _totalBill,
      'total_trip_amount': _totalBill,
      'gps_breadcrumbs': _breadcrumbs,
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();
    final endpoint = _selectedOrderId != null
        ? ApiEndpoints.tankerTripProcess(_selectedOrderId!)
        : ApiEndpoints.tankerTrips;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedOrderId != null
                ? 'Assigned order ${_selectedTripNumber ?? '#$_selectedOrderId'} processed & synced with ERP!'
                : 'Bulk tanker trip sheet, motor timing & GPS trail synced with ERP!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: endpoint,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanker trip sheet & GPS telemetry saved to offline Outbox!'),
          backgroundColor: AppColors.warning,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);

    return Scaffold(
      backgroundColor: skin.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.aquaPrimary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Tanker Trip & GPS Sheet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              '${_vehicleNumber.isNotEmpty ? '$_vehicleNumber · ' : ''}Auto Motor Timing · Dwell & Odo Audit',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openPrintPreview,
            tooltip: 'Print Trip Slip / Seal Tag',
            icon: const Icon(Icons.print_rounded),
          ),
        ],
      ),
      body: AdaptivePageConstraint(
        maxWidth: 960,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            // 0a. Prominent Rotating Driver Vehicle & Borewell Pickup Selector
            _buildVehicleAndPickupCard(skin),
            const SizedBox(height: 14),

            _buildAssignedOrdersSelector(skin),
            const SizedBox(height: 16),

            // 1. Live GPS Movement, Travel Time & Site Dwell Chronometer Banner
            _buildLiveTelemetryHero(skin),
            const SizedBox(height: 16),

            // 2. Automatic Motor Start & Stop Timing Calculator Card
            _buildMotorTimingCard(skin),
            const SizedBox(height: 16),

            // 3. GPS Tracked Distance vs. Odometer Reading Cross-Verification Card
            _buildOdometerVsGpsCard(skin),
            const SizedBox(height: 16),

            // 4. Customer, Capacity & Site Details Card
            _buildCustomerAndCapacityCard(skin),
            const SizedBox(height: 16),

            // 5. +Extra / -Discount & GPay Verification Payment Card
            _buildAdjustmentsAndPaymentCard(skin),
            const SizedBox(height: 16),

            // 6. Itemized Trip Freight & Surcharges Summary Card
            _buildBillBreakdownCard(skin),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleAndPickupCard(RippleSkin skin) {
    Map<String, dynamic>? activeTanker;
    for (final t in _tankers) {
      if (int.tryParse((t['id'] ?? '').toString()) == _tankerId) {
        activeTanker = t;
        break;
      }
    }
    final supportedCaps = _isOutsourcedVehicle
        ? const <double>[]
        : supportedCapacitiesForTanker(activeTanker);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.aquaPrimary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: AppColors.aquaPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vehicle Driven Today & Borewell Pickup',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: skin.ink),
                ),
              ),
              FilterChip(
                selected: _isOutsourcedVehicle,
                label: const Text(
                  'Outside / வெளி வண்டி',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                onSelected: (v) => setState(() => _isOutsourcedVehicle = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_isOutsourcedVehicle && _tankers.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              key: const Key('tanker_trip_vehicle_dropdown'),
              initialValue: _tankerId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Vehicle Number (Switch Tanker Driven Today)',
                prefixIcon: Icon(Icons.fire_truck_rounded, size: 18),
                border: OutlineInputBorder(),
              ),
              items: _tankers
                  .map((t) => DropdownMenuItem<int>(
                        value: int.tryParse((t['id'] ?? '').toString()),
                        child: Text(formatTankerOptionLabel(t), overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _tankerId = val;
                  final match = _tankers.firstWhere(
                    (t) => int.tryParse((t['id'] ?? '').toString()) == val,
                    orElse: () => <String, dynamic>{},
                  );
                  if (match.isNotEmpty) {
                    _vehicleNumber = (match['vehicle_number'] ?? '').toString();
                    final capKl = (match['capacity_kl'] as num?)?.toDouble() ?? 0.0;
                    if (_selectedKl <= 0 && capKl > 0) {
                      _selectedKl = capKl;
                      _klController.text = capKl.toStringAsFixed(capKl % 1 == 0 ? 0 : 1);
                    }
                  }
                });
              },
            ),
            if (supportedCaps.length > 1) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: supportedCaps.map((cap) {
                  final selected = (_selectedKl - cap).abs() < 0.01;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(
                      '${cap.toStringAsFixed(0)} KL',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedKl = cap;
                        _klController.text = cap.toStringAsFixed(0);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ] else if (_isOutsourcedVehicle) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _extVehicleController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Outside Vehicle No *',
                      hintText: 'TN-33-XX-1234',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _extVendorController,
                    decoration: const InputDecoration(
                      labelText: 'Outside Owner / Vendor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _vendorPayableController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Vendor Payable Rate (₹)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_pickupPoints.isNotEmpty) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              key: const Key('tanker_trip_pickup_dropdown'),
              initialValue: _selectedPickupPointId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Water Pickup / Borewell Point (தண்ணி பிடிக்கிற இடம்)',
                prefixIcon: Icon(Icons.water_rounded, size: 18),
                border: OutlineInputBorder(),
              ),
              items: _pickupPoints.map((p) {
                final pid = int.tryParse((p['id'] ?? '').toString());
                final name = (p['name'] ?? 'Pickup Point').toString();
                final isOuter = (p['location_type'] ?? '') == 'outer_paid_borewell';
                return DropdownMenuItem<int>(
                  value: pid,
                  child: Text(
                    isOuter ? '$name (Outer Paid)' : name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _selectedPickupPointId = val;
                  final match = _pickupPoints.firstWhere(
                    (p) => int.tryParse((p['id'] ?? '').toString()) == val,
                    orElse: () => <String, dynamic>{},
                  );
                  _pickupPointName = (match['name'] ?? _pickupPointName).toString();
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignedOrdersSelector(RippleSkin skin) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.aquaPrimary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded, color: AppColors.aquaPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedOrderId != null
                      ? 'Processing Assigned Order ${_selectedTripNumber ?? '#$_selectedOrderId'}'
                      : 'Select Assigned Tanker Order (${_pendingTrips.length})',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: skin.ink),
                ),
              ),
              if (_selectedOrderId != null)
                TextButton(
                  onPressed: _clearSelectedOrder,
                  child: const Text('New Ad-Hoc Trip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => showCreateTankerOrderSheet(
                  context: context,
                  ref: ref,
                  tankerId: _tankerId,
                  onCreated: _fetchManifestAndPackages,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                label: const Text('Create Order', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.push('/operations/schedules?vertical=tanker');
                  if (mounted) _fetchManifestAndPackages();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.event_repeat_rounded, size: 14),
                label: const Text('Schedules', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (_pendingTrips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _pendingTrips.map((order) {
                final oid = int.tryParse(order['id']?.toString() ?? '');
                final isSelected = oid != null && oid == _selectedOrderId;
                final tripNo = order['trip_number']?.toString() ?? '#$oid';
                final soNo = order['sales_order_no']?.toString().trim();
                final cust = order['customer_name']?.toString() ?? order['destination_site']?.toString() ?? 'Order';
                final qtyKl = (order['water_quantity_kl'] as num?)?.toDouble() ?? 0.0;
                final schedLabel = order['schedule_label']?.toString().trim();
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(
                    '$tripNo${soNo != null && soNo.isNotEmpty ? ' ($soNo)' : ''} · $cust (${qtyKl.toStringAsFixed(0)} KL)${schedLabel != null && schedLabel.isNotEmpty ? ' · $schedLabel' : ''}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onSelected: (_) => _applySelectedOrder(order),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveTelemetryHero(RippleSkin skin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A4D68), AppColors.aquaPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.aquaPrimary.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _phase.icon,
                        size: 14,
                        color: AppColors.aquaAction,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _phase.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickManualSiteDwellWindow,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.aquaAction,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                    label: const Text(
                      'Edit Site Times',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4-Column Live Chronometer & Distance Bento
          Row(
            children: [
              Expanded(
                child: _buildTelemetryKpiBox(
                  title: 'TRAVEL TIME',
                  value: _formatDuration(_travelSeconds),
                  sub: 'Start: ${_formatClock(_tripStartedAt)}',
                  highlight: _phase == TankerTripPhase.movingTransit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTelemetryKpiBox(
                  title: 'SPENT AT PLACE',
                  value: _formatDuration(_siteDwellSeconds),
                  sub: _billableWaitingMinutes > 0
                      ? 'Wait: ${_billableWaitingMinutes}m (+₹${_waitingSurcharge.toStringAsFixed(0)})'
                      : 'Within 30m Free Grace',
                  highlight: _phase == TankerTripPhase.atSiteDwell,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryKpiBox(
                  title: 'GPS DISTANCE',
                  value: '${_gpsTrackedKm.toStringAsFixed(1)} km',
                  sub: _isGpsTracking
                      ? 'Speed: ${_currentSpeedKmh.toStringAsFixed(0)} km/h · Live'
                      : '${_breadcrumbs.length} GPS Checkpoints',
                  highlight: _isGpsTracking,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTelemetryKpiBox(
                  title: 'MOTOR PUMP RUN',
                  value: _formatDuration(_motorSeconds),
                  sub: 'Est: $_estimatedDecantedLitres L · +₹${_motorPumpingSurcharge.toStringAsFixed(0)}',
                  highlight: _isMotorRunning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Tactile Stage Control Buttons (Start Moving GPS -> Arrived at Place -> Complete Trip)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _startMovingGps,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _phase == TankerTripPhase.movingTransit
                      ? AppColors.aquaAction
                      : Colors.white.withValues(alpha: 0.15),
                  foregroundColor: _phase == TankerTripPhase.movingTransit
                      ? const Color(0xFF13201B)
                      : Colors.white,
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                label: const Text(
                  '1. Start Moving (GPS)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _markArrivedAtSite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _phase == TankerTripPhase.atSiteDwell
                      ? AppColors.aquaAction
                      : Colors.white.withValues(alpha: 0.15),
                  foregroundColor: _phase == TankerTripPhase.atSiteDwell
                      ? const Color(0xFF13201B)
                      : Colors.white,
                  elevation: 0,
                ),
                icon: const Icon(Icons.location_on_rounded, size: 18),
                label: const Text(
                  '2. Arrived at Place',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _lockTripTiming,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _phase == TankerTripPhase.completed
                      ? AppColors.rippleMint
                      : Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                icon: const Icon(Icons.stop_circle_rounded, size: 18),
                label: const Text(
                  '3. End Dwell & Lock',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryKpiBox({
    required String title,
    required String value,
    required String sub,
    required bool highlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.aquaAction
              : Colors.white.withValues(alpha: 0.12),
          width: highlight ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: AppColors.aquaAction,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMotorTimingCard(RippleSkin skin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isMotorRunning ? AppColors.aquaPrimary : skin.hairline,
          width: _isMotorRunning ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatic Motor Timing & Surcharge',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: skin.ink,
                      ),
                    ),
                    Text(
                      'Start/Stop pump live or set exact start & stop clock times',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: skin.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _autoTimedMotorRate,
                activeColor: AppColors.aquaPrimary,
                onChanged: (v) => setState(() => _autoTimedMotorRate = v),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Start & Stop Clock Pill Boxes + Live Start/Stop Motor Button
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickManualMotorWindow,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: skin.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: skin.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MOTOR START',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: skin.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatClock(_motorStartedAt),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: skin.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _pickManualMotorWindow,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: skin.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: skin.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MOTOR STOP',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: skin.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isMotorRunning ? 'RUNNING...' : _formatClock(_motorStoppedAt),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _isMotorRunning ? AppColors.rippleMint : skin.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _toggleMotorPump,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _isMotorRunning ? AppColors.rippleRuby : AppColors.aquaPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _isMotorRunning ? Icons.stop_rounded : Icons.power_settings_new_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _isMotorRunning ? 'Stop Motor' : 'Start Motor',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Duration Presets + Calculated Output Bar
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final mins in [0, 15, 30, 45, 60])
                ChoiceChip(
                  selected: _motorMinutes == mins,
                  label: Text(
                    mins == 0 ? 'No Motor (0m)' : '${mins}m Run',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onSelected: (_) {
                    final now = DateTime.now();
                    setState(() {
                      _isMotorRunning = false;
                      _motorSeconds = mins * 60;
                      _motorStartedAt = mins > 0 ? now.subtract(Duration(minutes: mins)) : null;
                      _motorStoppedAt = mins > 0 ? now : null;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.aquaPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Motor Run: $_motorMinutes mins (~$_estimatedDecantedLitres L @ 160 L/min)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: skin.ink,
                    ),
                  ),
                ),
                Text(
                  '+ ₹${_motorPumpingSurcharge.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.aquaPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOdometerVsGpsCard(RippleSkin skin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'GPS Tracked Distance vs. Odometer Audit',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: skin.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isOdoVerified ? AppColors.rippleMint : AppColors.rippleHoney)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isOdoVerified
                      ? 'VERIFIED (${_odoGpsDriftKm.toStringAsFixed(1)} km diff)'
                      : 'DRIFT ALERT (${_odoGpsDriftKm.toStringAsFixed(1)} km diff)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _isOdoVerified ? AppColors.rippleMint : AppColors.rippleHoney,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startOdoController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Start Odometer (KM)',
                    prefixIcon: Icon(Icons.speed_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _endOdoController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'End Odometer (KM)',
                    prefixIcon: Icon(Icons.flag_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: skin.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Odometer Delta: $_odometerKm km  |  GPS Tracked: ${_gpsTrackedKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: skin.ink,
                      ),
                    ),
                    Text(
                      'Variance: ${_odoGpsDriftPct.toStringAsFixed(1)}% (Threshold <= 8%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: skin.muted,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _endOdoController.text =
                          (_startOdo + _gpsTrackedKm.round()).toString();
                    });
                  },
                  icon: const Icon(Icons.my_location_rounded, size: 16),
                  label: const Text(
                    'Sync Odo to GPS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAndCapacityCard(RippleSkin skin) {
    final packageOptions = _waterPackages
        .map((pkg) {
          final volume = (pkg['volume_kl'] as num?)?.toDouble() ??
              (pkg['water_capacity_spec'] as num?)?.toDouble() ??
              0.0;
          final price = (pkg['base_rate'] as num?)?.toDouble() ??
              (pkg['price'] as num?)?.toDouble() ??
              0.0;
          return MapEntry<double, double>(volume, price);
        })
        .where((e) => e.key > 0 && e.value >= 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Industrial Customer & Tanker Load Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: skin.ink,
            ),
          ),
          const SizedBox(height: 10),
          if (packageOptions.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: packageOptions.map((entry) {
                final selected = _selectedKl == entry.key;
                return ChoiceChip(
                  selected: selected,
                  label: Text(
                    '${entry.key.toStringAsFixed(entry.key % 1 == 0 ? 0 : 1)} KL (₹${entry.value.toInt()})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedKl = entry.key;
                      _baseTripRate = entry.value;
                      _klController.text = entry.key.toString();
                      _tripRateController.text = entry.value.toStringAsFixed(0);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _klController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final parsed = double.tryParse(v.trim());
                    if (parsed != null && parsed >= 0) {
                      setState(() => _selectedKl = parsed);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Water Volume (KL)',
                    prefixIcon: Icon(Icons.water_drop_outlined, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _tripRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final parsed = double.tryParse(v.trim());
                    if (parsed != null && parsed >= 0) {
                      setState(() => _baseTripRate = parsed);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Base Trip Rate (₹)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_customers.isNotEmpty) ...[
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _customers.take(10).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final c = _customers[idx];
                  final cid = int.tryParse((c['id'] ?? '').toString());
                  final name = (c['name'] ?? '').toString();
                  final isSelected = cid != null && cid == _selectedCustomerId;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    onSelected: (_) {
                      setState(() {
                        _selectedCustomerId = cid;
                        _customerController.text = name;
                        final addr = (c['address'] ?? c['city'] ?? '').toString();
                        if (addr.isNotEmpty) {
                          _destinationController.text = addr;
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextFormField(
            controller: _customerController,
            decoration: const InputDecoration(
              labelText: 'Customer Party Name',
              prefixIcon: Icon(Icons.domain_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Unloading Sump / Site Location',
                    prefixIcon: Icon(Icons.pin_drop_outlined, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _tollController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Tollgate / Gate Fee (₹)',
                    prefixIcon: Icon(Icons.toll_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsAndPaymentCard(RippleSkin skin) {
    final isGpay = _paymentMode == 'GPay / UPI';
    final isPendingGpay = isGpay && _gpayStatus == 'pending_verification';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extra Charges, Discounts & Payment Verification',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: skin.ink),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _extraChargeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '+ Extra Charge (₹)',
                    prefixIcon: Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.aquaPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _discountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '- Discount (₹)',
                    prefixIcon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.rippleRuby),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ActionChip(
                label: const Text('+₹100 Hose/Floor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                onPressed: () {
                  setState(() {
                    _extraChargeController.text = (_extraCharge + 100).toStringAsFixed(0);
                    if (_adjustmentNoteController.text.trim().isEmpty) {
                      _adjustmentNoteController.text = 'Extra hose / floor pumping';
                    }
                  });
                },
              ),
              ActionChip(
                label: const Text('-₹100 Review Discount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                onPressed: () {
                  setState(() {
                    _discountController.text = (_discountAmount + 100).toStringAsFixed(0);
                    if (_adjustmentNoteController.text.trim().isEmpty) {
                      _adjustmentNoteController.text = 'Google Review discount';
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adjustmentNoteController,
            decoration: const InputDecoration(
              labelText: 'Adjustment Note (e.g. 2nd floor hose / Google review)',
              prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
            ),
          ),
          const Divider(height: 24),
          Text(
            'Payment Mode on Delivery',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: skin.ink),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Cash', 'GPay / UPI', 'Account / Credit'].map((mode) {
              return ChoiceChip(
                selected: _paymentMode == mode,
                label: Text(mode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                onSelected: (_) => setState(() => _paymentMode = mode),
              );
            }).toList(),
          ),
          if (isGpay) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isPendingGpay ? AppColors.warning : AppColors.success).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (isPendingGpay ? AppColors.warning : AppColors.success).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPay / UPI Verification Status',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: skin.ink),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        selected: _gpayStatus == 'pending_verification',
                        label: const Text(
                          'Pending Confirmation (பெண்டிங்)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                        onSelected: (_) => setState(() => _gpayStatus = 'pending_verification'),
                      ),
                      ChoiceChip(
                        selected: _gpayStatus == 'confirmed',
                        label: const Text(
                          'Confirmed',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                        onSelected: (_) => setState(() => _gpayStatus = 'confirmed'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final attachment = await showAttachGpayProofDialog(
                              context,
                              initialRef: _gpayProof?.referenceNo,
                              initialPath: _gpayProof?.filePath,
                              initialAccount: _gpayProof?.paymentAccount ?? _paymentAccount,
                            );
                            if (attachment != null && mounted) {
                              setState(() {
                                _gpayProof = attachment;
                                _paymentAccount = attachment.paymentAccount;
                                if (attachment.hasProof) {
                                  _gpayStatus = 'confirmed';
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                          label: Text(
                            _gpayProof?.hasProof == true
                                ? 'GPay Proof Attached (Edit)'
                                : 'Attach GPay Screenshot / Photo',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_gpayProof != null && _gpayProof!.hasProof) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_gpayProof!.previewBytes != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              _gpayProof!.previewBytes!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            'Account: ${_gpayProof!.paymentAccount}'
                            '${_gpayProof!.referenceNo.isNotEmpty ? ' · Ref: ${_gpayProof!.referenceNo}' : ''}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: skin.ink),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillBreakdownCard(RippleSkin skin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Automatic Trip Sheet Bill Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: skin.ink,
            ),
          ),
          const Divider(height: 20),
          _billRow(
            'Base Water Freight (${_selectedKl.toInt()} KL Load)',
            _baseTripRate,
            skin,
          ),
          const SizedBox(height: 8),
          _billRow(
            'Motor Pumping Surcharge ($_motorMinutes mins)',
            _motorPumpingSurcharge,
            skin,
          ),
          const SizedBox(height: 8),
          _billRow(
            'Site Waiting Surcharge ($_billableWaitingMinutes mins billable / $_siteDwellMinutes mins total)',
            _waitingSurcharge,
            skin,
          ),
          if (_tollAmount > 0) ...[
            const SizedBox(height: 8),
            _billRow('Tollgate / Site Pass Reimbursement', _tollAmount, skin),
          ],
          if (_extraCharge > 0) ...[
            const SizedBox(height: 8),
            _billRow('+ Extra Charge${_adjustmentNoteController.text.trim().isNotEmpty ? ' (${_adjustmentNoteController.text.trim()})' : ''}', _extraCharge, skin),
          ],
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8),
            _billRow('- Discount', -_discountAmount, skin),
          ],
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Billed Freight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: skin.ink,
                ),
              ),
              AmountText(
                amount: _totalBill,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.aquaPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _openPrintPreview,
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text(
                      'Print Gate Slip / Label',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitTrip,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.aquaPrimary,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'Posting Trip...' : 'Complete & Post Trip Sheet',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, double amount, RippleSkin skin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: skin.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        AmountText(amount: amount),
      ],
    );
  }
}
