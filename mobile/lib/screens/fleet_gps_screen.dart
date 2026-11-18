import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../core/network/api_endpoints.dart';
import '../core/network/api_result.dart';
import '../core/providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_typography.dart';
import '../core/ui/gps_map_interactive_sheets.dart';
import '../models/models.dart';

enum FleetViewMode { tankers, packagedWater }

enum _MapCustomerFilter { all, due, overdue, paid }

/// Interactive OpenStreetMap + Leaflet-style Fleet & Customer Ledger Map.
/// Displays every customer location with inline Customer Name + Paid/Due badges,
/// geofence perimeters, live tanker/van vehicles, and quick navigation/order actions.
class FleetGpsScreen extends ConsumerStatefulWidget {
  final bool isTamil;
  final FleetViewMode initialMode;
  final UserRole? activeRole;
  final bool? lockMode;
  final List<Map<String, dynamic>>? initialCustomers;
  final List<Map<String, dynamic>>? initialVehicles;
  final bool skipInitialFetch;
  final TileProvider? tileProvider;

  const FleetGpsScreen({
    super.key,
    required this.isTamil,
    this.initialMode = FleetViewMode.tankers,
    this.activeRole,
    this.lockMode,
    this.initialCustomers,
    this.initialVehicles,
    this.skipInitialFetch = false,
    this.tileProvider,
  });

  @override
  ConsumerState<FleetGpsScreen> createState() => _FleetGpsScreenState();
}

class _FleetGpsScreenState extends ConsumerState<FleetGpsScreen> {
  static const LatLng _defaultCenter = LatLng(9.9252, 78.1198);
  static final NumberFormat _inrCompact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  late final MapController _mapController;
  late final TextEditingController _searchController;
  Timer? _livePollTimer;

  late FleetViewMode _viewMode;
  _MapCustomerFilter _filter = _MapCustomerFilter.all;
  String _searchQuery = '';
  bool _showGeofences = true;
  bool _showVehicles = true;
  bool _loading = false;
  String? _errorMessage;
  int? _selectedCustomerId;
  String? _selectedVehicleKey;
  LatLng? _myPosition;
  bool _mapReady = false;

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController();
    _viewMode = widget.initialMode;

    if (widget.initialCustomers != null) {
      _customers = widget.initialCustomers!
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (widget.initialVehicles != null) {
      _vehicles = widget.initialVehicles!
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (!widget.skipInitialFetch) {
      unawaited(_fetchLiveTelematics());
      _livePollTimer = Timer.periodic(
        const Duration(seconds: 25),
        (_) => unawaited(_fetchLiveTelematics(silent: true)),
      );
    }
  }

  @override
  void dispose() {
    _livePollTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  bool get _isModeLocked {
    if (widget.lockMode != null) return widget.lockMode!;
    if (widget.activeRole != null) {
      return widget.activeRole == UserRole.deliveryDriver ||
          widget.activeRole == UserRole.tankerDriver;
    }
    try {
      final role = ref.read(activeRippleRoleProvider);
      return role == RippleRole.driver;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchLiveTelematics({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    final industryParam = _viewMode == FleetViewMode.packagedWater
        ? 'packaged_water'
        : 'bulk_water';

    final res = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
          ApiEndpoints.fleetLive,
          queryParameters: {
            'industry': industryParam,
            'vertical': industryParam,
          },
          fromJson: (raw) {
            if (raw is Map && raw['data'] is Map) {
              return Map<String, dynamic>.from(raw['data'] as Map);
            }
            if (raw is Map) {
              return Map<String, dynamic>.from(raw);
            }
            return <String, dynamic>{};
          },
        );

    if (!mounted) return;

    if (res is ApiSuccess<Map<String, dynamic>>) {
      final data = res.data;
      final rawCustomers = data['customers'] as List<dynamic>? ?? const [];
      final rawTankers = data['tankers'] as List<dynamic>? ?? const [];
      final rawRoutes = data['can_routes'] as List<dynamic>? ?? const [];

      final parsedCustomers = rawCustomers
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .where((c) => _parseCoord(c['latitude']) != null && _parseCoord(c['longitude']) != null)
          .toList();

      final parsedVehicles = <Map<String, dynamic>>[
        ...rawTankers.whereType<Map>().map((m) {
          final map = Map<String, dynamic>.from(m);
          map['_vtype'] = 'tanker';
          return map;
        }),
        ...rawRoutes.whereType<Map>().map((m) {
          final map = Map<String, dynamic>.from(m);
          map['_vtype'] = 'route';
          return map;
        }),
      ];

      setState(() {
        _customers = parsedCustomers;
        _vehicles = parsedVehicles;
        _loading = false;
        _errorMessage = null;
      });
      if (!silent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitAllMarkers();
        });
      }
    } else if (res is ApiFailure<Map<String, dynamic>>) {
      setState(() {
        _loading = false;
        _errorMessage = res.failure.message;
      });
    }
  }

  double? _parseCoord(dynamic raw) {
    if (raw == null) return null;
    final val = double.tryParse(raw.toString());
    if (val == null || val.abs() < 0.0001) return null;
    return val;
  }

  double _num(dynamic raw) => double.tryParse(raw?.toString() ?? '0') ?? 0.0;

  String _statusOf(Map<String, dynamic> c) {
    final explicit = (c['payment_status'] ?? '').toString().toLowerCase();
    if (explicit == 'overdue' || _num(c['overdue_amount']) > 0.01) {
      return 'overdue';
    }
    if (explicit == 'due' || _num(c['due_amount']) > 0.01) {
      return 'due';
    }
    return 'paid';
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    final q = _searchQuery.trim().toLowerCase();
    return _customers.where((c) {
      final status = _statusOf(c);
      final matchesFilter = switch (_filter) {
        _MapCustomerFilter.all => true,
        _MapCustomerFilter.due => status == 'due' || status == 'overdue',
        _MapCustomerFilter.overdue => status == 'overdue',
        _MapCustomerFilter.paid => status == 'paid',
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      final hay = [
        c['name'],
        c['company_name'],
        c['address'],
        c['city'],
        c['phone_number'],
        c['phone'],
        c['tax_no'],
      ].whereType<Object>().map((e) => e.toString().toLowerCase()).join(' ');
      return hay.contains(q);
    }).toList();
  }

  void _fitAllMarkers() {
    if (!_mapReady || !mounted) return;
    final points = <LatLng>[];
    for (final c in _filteredCustomers) {
      final lat = _parseCoord(c['latitude']);
      final lng = _parseCoord(c['longitude']);
      if (lat != null && lng != null) points.add(LatLng(lat, lng));
    }
    if (_showVehicles) {
      for (final v in _vehicles) {
        final lat = _parseCoord(v['latitude']);
        final lng = _parseCoord(v['longitude']);
        if (lat != null && lng != null) points.add(LatLng(lat, lng));
      }
    }
    if (points.isEmpty) {
      _mapController.move(_defaultCenter, 12.8);
      return;
    }
    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(48, 175, 48, 110),
      ),
    );
  }

  Future<void> _centerOnMyLocation() async {
    final snap = await ref
        .read(gpsServiceProvider)
        .evaluate(requestIfDenied: true);
    if (!mounted) return;
    if (snap.latitude != null && snap.longitude != null) {
      final target = LatLng(snap.latitude!, snap.longitude!);
      setState(() => _myPosition = target);
      if (_mapReady) {
        _mapController.move(target, 15.2);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centered on active Madurai service hub.'),
        ),
      );
      _fitAllMarkers();
    }
  }

  Color _colorForStatus(String status) {
    return switch (status) {
      'overdue' => AppColors.danger,
      'due' => AppColors.warning,
      _ => AppColors.success,
    };
  }

  void _focusOnPoint(LatLng target, {double zoom = 15.2}) {
    if (!_mapReady || !mounted) return;
    _mapController.move(target, zoom);
  }

  String _vehicleKeyOf(Map<String, dynamic> v) {
    return '${v['_vtype'] ?? ''}_${v['id'] ?? v['vehicle_number'] ?? v['vehicle_no'] ?? v['route_name'] ?? ''}';
  }

  Map<String, dynamic>? get _selectedCustomerForBubble {
    if (_selectedCustomerId == null) return null;
    for (final c in _filteredCustomers) {
      final cid = int.tryParse(c['id']?.toString() ?? '') ?? -1;
      if (cid == _selectedCustomerId) return c;
    }
    return null;
  }

  Map<String, dynamic>? get _selectedVehicleForBubble {
    if (_selectedVehicleKey == null || !_showVehicles) return null;
    for (final v in _vehicles) {
      if (_vehicleKeyOf(v) == _selectedVehicleKey) return v;
    }
    return null;
  }

  void _onCustomerPinTapped(Map<String, dynamic> customer) {
    final cid = int.tryParse(customer['id']?.toString() ?? '') ?? 0;
    final lat = _parseCoord(customer['latitude']);
    final lng = _parseCoord(customer['longitude']);
    setState(() {
      _selectedCustomerId = cid;
      _selectedVehicleKey = null;
    });
    if (lat != null && lng != null) {
      _focusOnPoint(LatLng(lat + 0.0022, lng), zoom: 15.0);
    }
  }

  void _onVehiclePinTapped(Map<String, dynamic> vehicle) {
    final lat = _parseCoord(vehicle['latitude']);
    final lng = _parseCoord(vehicle['longitude']);
    setState(() {
      _selectedVehicleKey = _vehicleKeyOf(vehicle);
      _selectedCustomerId = null;
    });
    if (lat != null && lng != null) {
      _focusOnPoint(LatLng(lat + 0.0022, lng), zoom: 15.0);
    }
  }

  void _openDriverDetails(Map<String, dynamic> vehicle) {
    final lat = _parseCoord(vehicle['latitude']);
    final lng = _parseCoord(vehicle['longitude']);
    if (lat != null && lng != null) {
      _focusOnPoint(LatLng(lat, lng));
    }
    showDriverFullDetailsSheet(
      context,
      ref: ref,
      vehicle: vehicle,
      isTanker: vehicle['_vtype'] == 'tanker',
      onCenterOnMap: (lat != null && lng != null)
          ? () => _focusOnPoint(LatLng(lat, lng))
          : null,
    );
  }

  void _openCustomerDetails(Map<String, dynamic> customer) {
    showCustomerFullDetailsSheet(
      context,
      ref: ref,
      customer: customer,
      isPackagedWater: _viewMode == FleetViewMode.packagedWater,
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final visibleCustomers = _filteredCustomers;
    final allCount = _customers.length;
    final dueCount = _customers.where((c) => _statusOf(c) != 'paid').length;
    final overdueCount = _customers.where((c) => _statusOf(c) == 'overdue').length;
    final paidCount = _customers.where((c) => _statusOf(c) == 'paid').length;

    final totalDue = _customers.fold<double>(0, (s, c) => s + _num(c['due_amount']));
    final totalOverdue = _customers.fold<double>(0, (s, c) => s + _num(c['overdue_amount']));
    final totalPaid = _customers.fold<double>(0, (s, c) => s + _num(c['total_paid']));
    final selectedCustomer = _selectedCustomerForBubble;
    final selectedVehicle = _selectedVehicleForBubble;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _viewMode == FleetViewMode.packagedWater
              ? 'Customer & Van GPS Map'
              : 'Site & Tanker GPS Map',
        ),
        actions: [
          if (!_isModeLocked)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SegmentedButton<FleetViewMode>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: FleetViewMode.packagedWater,
                    label: Text('20L Cans'),
                  ),
                  ButtonSegment(
                    value: FleetViewMode.tankers,
                    label: Text('Tankers'),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (sel) {
                  setState(() => _viewMode = sel.first);
                  unawaited(_fetchLiveTelematics());
                },
              ),
            ),
          IconButton(
            tooltip: _showGeofences ? 'Hide Geofence Circles' : 'Show Geofence Circles',
            onPressed: () => setState(() => _showGeofences = !_showGeofences),
            icon: Icon(
              _showGeofences
                  ? Icons.radar_rounded
                  : Icons.trip_origin_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Refresh Live Fleet & Balances',
            onPressed: _loading ? null : () => _fetchLiveTelematics(),
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12.8,
              onMapReady: () {
                if (!mounted) return;
                _mapReady = true;
                _fitAllMarkers();
              },
              onTap: (_, __) {
                if (_selectedCustomerId != null || _selectedVehicleKey != null) {
                  setState(() {
                    _selectedCustomerId = null;
                    _selectedVehicleKey = null;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dkenterprises.dk_track_mobile',
                tileProvider: widget.tileProvider ?? NetworkTileProvider(),
              ),
              if (_showGeofences)
                CircleLayer(
                  circles: [
                    for (final c in visibleCustomers)
                      if (_parseCoord(c['latitude']) != null &&
                          _parseCoord(c['longitude']) != null)
                        CircleMarker(
                          point: LatLng(
                            _parseCoord(c['latitude'])!,
                            _parseCoord(c['longitude'])!,
                          ),
                          radius: _num(c['geofence_radius']) > 0
                              ? _num(c['geofence_radius'])
                              : 150,
                          useRadiusInMeter: true,
                          color: _colorForStatus(_statusOf(c))
                              .withValues(alpha: 0.12),
                          borderColor: _colorForStatus(_statusOf(c))
                              .withValues(alpha: 0.55),
                          borderStrokeWidth: 1.5,
                        ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_myPosition != null)
                    Marker(
                      point: _myPosition!,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_showVehicles)
                    for (final v in _vehicles)
                      if (_parseCoord(v['latitude']) != null &&
                          _parseCoord(v['longitude']) != null)
                        Marker(
                          point: LatLng(
                            _parseCoord(v['latitude'])!,
                            _parseCoord(v['longitude'])!,
                          ),
                          width: 186,
                          height: 56,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onTap: () => _onVehiclePinTapped(v),
                            child: _VehicleMapPin(
                              label: (v['vehicle_number'] ??
                                      v['vehicle_no'] ??
                                      v['route_name'] ??
                                      'Fleet')
                                  .toString()
                                  .split(' ')
                                  .first,
                              driverName: (v['driver_name'] ??
                                      v['assigned_driver'] ??
                                      '')
                                  .toString(),
                              speedKmh: _num(
                                v['current_speed'] ?? v['speed_kmh'],
                              ),
                              isTanker: v['_vtype'] == 'tanker',
                            ),
                          ),
                        ),
                  for (final c in visibleCustomers)
                    if (_parseCoord(c['latitude']) != null &&
                        _parseCoord(c['longitude']) != null)
                      Marker(
                        point: LatLng(
                          _parseCoord(c['latitude'])!,
                          _parseCoord(c['longitude'])!,
                        ),
                        width: 146,
                        height: 54,
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () => _onCustomerPinTapped(c),
                          child: CompactCustomerMapPin(
                            name: c['name']?.toString() ?? 'Customer',
                            paidAmount: _num(c['total_paid']),
                            dueAmount: _num(c['due_amount']),
                            status: _statusOf(c),
                            isSelected: _selectedCustomerId ==
                                (int.tryParse(c['id']?.toString() ?? '') ?? -1),
                            compactFormatter: _inrCompact,
                          ),
                        ),
                      ),
                ],
              ),
            ],
          ),

          // Detailed Pop-Over Bubble over Selected Pin
          if (selectedCustomer != null || selectedVehicle != null)
            Positioned(
              top: 112,
              left: 16,
              right: 16,
              child: Center(
                child: selectedCustomer != null
                    ? CustomerMapCalloutBubble(
                        key: ValueKey(
                          'customer_map_callout_bubble_${selectedCustomer['id']}',
                        ),
                        customer: selectedCustomer,
                        onClose: () => setState(() => _selectedCustomerId = null),
                        onOpenFullDetails: () {
                          final target = selectedCustomer;
                          setState(() => _selectedCustomerId = null);
                          _openCustomerDetails(target);
                        },
                      )
                    : DriverMapCalloutBubble(
                        key: const ValueKey('driver_map_callout_bubble'),
                        vehicle: selectedVehicle!,
                        isTanker: selectedVehicle['_vtype'] == 'tanker',
                        onClose: () => setState(() => _selectedVehicleKey = null),
                        onOpenFullDetails: () {
                          final target = selectedVehicle;
                          setState(() => _selectedVehicleKey = null);
                          _openDriverDetails(target);
                        },
                      ),
              ),
            ),

          // Top Floating Search + Status Filters + Summary Strip (Loanapp layout)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(14),
                  color: skin.surface,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search customer name, address or GSTIN...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChipPill(
                        label: 'All ($allCount)',
                        selected: _filter == _MapCustomerFilter.all,
                        color: skin.primary,
                        onTap: () =>
                            setState(() => _filter = _MapCustomerFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipPill(
                        label: 'Due ($dueCount)',
                        selected: _filter == _MapCustomerFilter.due,
                        color: AppColors.warning,
                        onTap: () =>
                            setState(() => _filter = _MapCustomerFilter.due),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipPill(
                        label: 'Overdue ($overdueCount)',
                        selected: _filter == _MapCustomerFilter.overdue,
                        color: AppColors.danger,
                        onTap: () => setState(
                            () => _filter = _MapCustomerFilter.overdue),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipPill(
                        label: 'Paid ($paidCount)',
                        selected: _filter == _MapCustomerFilter.paid,
                        color: AppColors.success,
                        onTap: () =>
                            setState(() => _filter = _MapCustomerFilter.paid),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipPill(
                        label: 'Vehicles (${_vehicles.length})',
                        selected: _showVehicles,
                        color: AppColors.aquaPrimary,
                        onTap: () =>
                            setState(() => _showVehicles = !_showVehicles),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null && visibleCustomers.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: skin.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(color: skin.ink),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => _fetchLiveTelematics(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry Map Sync'),
                    ),
                  ],
                ),
              ),
            ),

          // Right-hand Floating Map Controls
          Positioned(
            right: 12,
            bottom: (_showVehicles && _vehicles.isNotEmpty) ? 142 : 92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'fleet_fit_all',
                  tooltip: 'Fit All Customer Pins',
                  onPressed: _fitAllMarkers,
                  backgroundColor: skin.surface,
                  foregroundColor: skin.primary,
                  child: const Icon(Icons.fit_screen_rounded),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fleet_my_loc',
                  tooltip: 'My GPS Location',
                  onPressed: _centerOnMyLocation,
                  backgroundColor: skin.surface,
                  foregroundColor: AppColors.success,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),

          // Live Drivers & Delivery Boys Quick Locator Strip
          if (_showVehicles && _vehicles.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 78,
              child: SafeArea(
                top: false,
                bottom: false,
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _vehicles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final v = _vehicles[index];
                      final isTanker = v['_vtype'] == 'tanker';
                      final driverName = (v['driver_name'] ??
                              v['assigned_driver'] ??
                              (isTanker ? 'Tanker Driver' : 'Delivery Boy'))
                          .toString();
                      final reg = (v['vehicle_number'] ??
                              v['vehicle_no'] ??
                              v['route_name'] ??
                              'Fleet')
                          .toString()
                          .split(' ')
                          .first;
                      final speed = _num(v['current_speed'] ?? v['speed_kmh']);

                      return Material(
                        color: skin.surface.withValues(alpha: 0.96),
                        elevation: 2,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _openDriverDetails(v),
                          onLongPress: () => _openDriverDetails(v),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.aquaPrimary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isTanker
                                      ? Icons.local_shipping_rounded
                                      : Icons.fire_truck_rounded,
                                  size: 16,
                                  color: AppColors.aquaPrimary,
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driverName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: skin.ink,
                                      ),
                                    ),
                                    Text(
                                      '$reg · ${speed.toStringAsFixed(0)} km/h',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: skin.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Bottom Compact Totals Summary Bar
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: skin.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: skin.hairline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryStat(
                      label: 'Collected',
                      value: _inrCompact.format(totalPaid),
                      color: AppColors.success,
                    ),
                    _SummaryStat(
                      label: 'Total Due',
                      value: _inrCompact.format(totalDue),
                      color: AppColors.warning,
                    ),
                    _SummaryStat(
                      label: 'Overdue',
                      value: _inrCompact.format(totalOverdue),
                      color: AppColors.danger,
                    ),
                    _SummaryStat(
                      label: 'Pins Shown',
                      value: '${visibleCustomers.length}',
                      color: skin.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleMapPin extends StatelessWidget {
  final String label;
  final String driverName;
  final double speedKmh;
  final bool isTanker;

  const _VehicleMapPin({
    required this.label,
    required this.driverName,
    required this.speedKmh,
    required this.isTanker,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isTanker ? const Color(0xFF0284C7) : const Color(0xFF0EA5E9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTanker ? Icons.local_shipping_rounded : Icons.fire_truck_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (driverName.trim().isNotEmpty)
                  Text(
                    driverName.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${speedKmh.toStringAsFixed(0)} km/h',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    return Material(
      color: selected ? color : skin.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : skin.hairline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : skin.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: skin.muted),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppTypography.title.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
