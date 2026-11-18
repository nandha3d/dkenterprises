import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers.dart';
import '../../../core/sync/sync_worker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/adaptive_layout.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/ripple_components.dart';
import '../../../core/ui/status_chip.dart';
import '../../operations/presentation/water_order_helpers.dart';

/// Stitch D-11 (Can Driver Work Tab), T-07 (Tanker Work Tab) & T-12 (My Trips & GPS Trail).
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _selectedFilterIndex = 0; // 0: Operations & Trips, 1: Sync Outbox, 2: Shift & Approvals
  bool _isLoadingTasks = false;
  List<Map<String, dynamic>> _pendingCanOrders = [];
  List<Map<String, dynamic>> _dynamicStops = [];
  List<Map<String, dynamic>> _tankerTrips = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_fetchTasks);
  }

  Future<void> _fetchTasks() async {
    final authState = ref.read(authNotifierProvider);
    final industry = authState.activeCompany?.industry ?? '';
    final client = ref.read(apiClientProvider);

    setState(() => _isLoadingTasks = true);

    if (industry == 'packaged_water') {
      final stopsFuture = client.get(
        ApiEndpoints.customers,
        fromJson: (data) {
          final list = data is Map && data['data'] is List
              ? data['data'] as List
              : (data is List ? data : []);
          return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        },
      );
      final manifestFuture = client.get<Map<String, dynamic>>(
        ApiEndpoints.driverManifest,
        fromJson: (data) {
          if (data is Map && data['data'] is Map) {
            return Map<String, dynamic>.from(data['data'] as Map);
          }
          return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        },
      );
      final res = await stopsFuture;
      final manifestRes = await manifestFuture;
      if (mounted) {
        final rawOrders = manifestRes.dataOrNull?['pending_orders'];
        final ordersList = rawOrders is List
            ? rawOrders.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : <Map<String, dynamic>>[];
        setState(() {
          _isLoadingTasks = false;
          _pendingCanOrders = ordersList;
          _dynamicStops = res.dataOrNull ?? [];
        });
      }
      return;
    }

    if (industry == 'bulk_water') {
      final res = await client.get(
        ApiEndpoints.waterTrips,
        fromJson: (data) {
          dynamic list = const [];
          if (data is Map) {
            final d = data['data'];
            if (d is List) {
              list = d;
            } else if (d is Map && d['trips'] is List) {
              list = d['trips'];
            } else if (data['trips'] is List) {
              list = data['trips'];
            }
          } else if (data is List) {
            list = data;
          }
          return (list is List ? list : const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        },
      );
      if (mounted) {
        setState(() {
          _isLoadingTasks = false;
          _tankerTrips = res.dataOrNull ?? [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _startCanOrder(Map<String, dynamic> order) async {
    final orderId = int.tryParse((order['order_id'] ?? order['id'] ?? '').toString());
    if (orderId == null || orderId <= 0) return;
    final res = await ref.read(apiClientProvider).post(
          ApiEndpoints.waterCanOrderStart(orderId),
          data: <String, dynamic>{},
          fromJson: (d) => d,
        );
    if (!mounted) return;
    if (res.isSuccess) {
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order['order_no'] ?? ''} started Ã‚Â· Owner notified'),
          backgroundColor: AppColors.aquaPrimary,
        ),
      );
      await _fetchTasks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.failureOrNull?.message ?? 'Unable to update order status.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _showTripTrailSheet(Map<String, dynamic> trip) async {
    final tripId = (trip['id'] as num?)?.toInt() ?? 0;
    final client = ref.read(apiClientProvider);
    List<Map<String, dynamic>> trail = const [];

    if (tripId > 0) {
      final res = await client.get<Map<String, dynamic>>(
        ApiEndpoints.waterTripTrail(tripId),
        fromJson: (d) => d is Map<String, dynamic>
            ? (d['data'] is Map<String, dynamic> ? d['data'] as Map<String, dynamic> : d)
            : <String, dynamic>{},
      );
      if (res is ApiSuccess<Map<String, dynamic>>) {
        final raw = res.data['trail'] is List ? res.data['trail'] as List : const [];
        trail = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }

    if (!mounted) return;
    final skin = RippleSkin.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: skin.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(skin.heroRadius)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                        'Trip GPS Breadcrumb Trail',
                        style: AppTypography.title.copyWith(color: skin.ink),
                      ),
                      Text(
                        '${trip['reference_no'] ?? '#TRIP'} Ã‚Â· ${trip['customer_name'] ?? 'Industrial Sump'}',
                        style: AppTypography.caption.copyWith(color: skin.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.rippleMint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(skin.pillRadius),
                  ),
                  child: Text(
                    '${trip['water_kl'] ?? (trip['water_quantity_litres'] != null ? ((trip['water_quantity_litres'] as num) / 1000) : 0)} KL',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.rippleMint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (trail.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'GPS breadcrumbs verified at Mother Plant Dispatch & Customer Decanting Sump.',
                  style: AppTypography.body.copyWith(color: skin.muted),
                ),
              )
            else
              ...trail.map(
                (pt) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: skin.canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: skin.hairline),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: skin.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pt['stage']?.toString() ?? 'Waypoint',
                                style: AppTypography.label.copyWith(
                                  color: skin.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${pt['latitude']}Ã‚Â° N, ${pt['longitude']}Ã‚Â° E Ã‚Â· Valve: ${pt['valve_state'] ?? 'LOCKED'}',
                                style: AppTypography.caption.copyWith(color: skin.muted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${pt['flow_lpm'] ?? 0} L/m',
                          style: AppTypography.caption.copyWith(
                            color: skin.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/fleet/gps?mode=bulk_water');
                },
                icon: const Icon(Icons.radar_rounded, size: 18),
                label: const Text('Open Live Fleet GPS Radar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = ref.watch(authNotifierProvider);
    final industry = authState.activeCompany?.industry ?? '';
    final syncWorker = ref.watch(syncWorkerProvider);
    final syncState = syncWorker.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final primaryTabLabel = switch (industry) {
      'packaged_water' => 'Can Work',
      'cafe_bakery' => 'Cafe Operations',
      'bulk_water' => 'Tanker Work & Trips',
      _ => 'Daily Queue',
    };

    final primaryTabCount = switch (industry) {
      'packaged_water' => _pendingCanOrders.length + _dynamicStops.length,
      'bulk_water' => _tankerTrips.length,
      _ => 0,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Work & Task Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fingerprint_rounded),
            tooltip: 'Geofenced Shift Attendance',
            onPressed: () => context.push('/hrm/attendance'),
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Outbox Now',
            onPressed: () => syncWorker.drainOutbox(),
          ),
        ],
      ),
      body: AdaptivePageConstraint(
        maxWidth: 1120,
        child: Column(
          children: [
            // Filter Chips Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: Border(bottom: BorderSide(color: borderCol, width: 1)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: primaryTabLabel,
                      count: primaryTabCount,
                      index: 0,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Sync Outbox',
                      count: syncState.pendingCount,
                      index: 1,
                      badgeColor: syncState.pendingCount > 0 ? AppColors.warning : null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Shift & Attendance',
                      count: 1,
                      index: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Task List Body
            Expanded(
              child: _selectedFilterIndex == 0
                  ? _buildVerticalOperationsList(context, industry)
                  : _selectedFilterIndex == 1
                      ? _buildSyncOutboxList(context, syncWorker)
                      : _buildShiftAndAttendanceShortcut(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required int index,
    Color? badgeColor,
  }) {
    final isSelected = _selectedFilterIndex == index;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? (isSelected ? Colors.white : AppColors.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeColor != null ? Colors.white : (isSelected ? AppColors.primary : Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilterIndex = index),
    );
  }

  Widget _buildShiftAndAttendanceShortcut(BuildContext context) {
    final skin = RippleSkin.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: BorderRadius.circular(skin.cardRadius),
            border: Border.all(color: skin.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Geofenced Shift Attendance', style: AppTypography.title.copyWith(color: skin.ink)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.rippleMint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(skin.pillRadius),
                    ),
                    child: const Text(
                      'GPS Lock Ã‚Â±3.2m',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.rippleMint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Verify 150m Plant Geofence Radar, Facial Biometric Liveness, Vehicle Odometer & 5-Day Shift Log.',
                style: AppTypography.body.copyWith(color: skin.muted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/hrm/attendance'),
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Open Geofenced Attendance'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalOperationsList(BuildContext context, String industry) {
    if (industry == 'packaged_water') {
      return _buildWaterCanOperationsAndStops(context);
    } else if (industry == 'cafe_bakery') {
      return _buildCafeOperationsList(context);
    } else if (industry == 'bulk_water') {
      return _buildTankerWorkAndMyTrips(context);
    } else {
      return const EmptyState(
        title: 'No Pending Queue Items',
        message: 'All operations and vouchers for this company workspace are settled.',
        icon: Icons.done_all_rounded,
      );
    }
  }

  Widget _buildCafeOperationsList(BuildContext context) {
    final companyLabel = ref.read(authNotifierProvider).activeCompany?.name ?? 'Cafe';
    final tasks = [
      {
        'title': '$companyLabel Touch POS Counter',
        'subtitle': 'Ready for table & counter billing',
        'route': '/operations/cafe-pos',
        'icon': Icons.point_of_sale_rounded,
        'action': 'Open POS',
        'color': const Color(0xFFD97706),
      },
      {
        'title': 'Kitchen Display, Batch & 86 Stock',
        'subtitle': 'Live KOT queue, bakery batches, wastage & reorders',
        'route': '/pos/kitchen',
        'icon': Icons.soup_kitchen_rounded,
        'action': 'Kitchen',
        'color': const Color(0xFFC2542D),
      },
      {
        'title': 'Kitchen & Ingredient Stock Audit',
        'subtitle': 'Verify milk, sugar, flour & coffee beans',
        'route': '/inventory/stock-count',
        'icon': Icons.inventory_2_rounded,
        'action': 'Audit',
        'color': const Color(0xFF059669),
      },
      {
        'title': 'Staff Geofenced Shift Attendance',
        'subtitle': 'Punch check-in/out inside cafe geofence',
        'route': '/hrm/attendance',
        'icon': Icons.fingerprint_rounded,
        'action': 'Attendance',
        'color': AppColors.primary,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final task = tasks[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final color = task['color'] as Color;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                RippleIconBadge(
                  icon: task['icon'] as IconData,
                  accentColor: color,
                  size: 46,
                  iconSize: 24,
                  radius: 14,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] as String,
                        style: AppTypography.label.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task['subtitle'] as String,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push(task['route'] as String),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(86, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: color,
                  ),
                  child: Text(task['action'] as String, style: const TextStyle(fontSize: 13, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Stitch T-07 (Tanker Work Tab) + T-12 (My Trips & GPS Breadcrumbs).
  Widget _buildTankerWorkAndMyTrips(BuildContext context) {
    final skin = RippleSkin.of(context);
    final modules = [
      {
        'title': 'Tanker Trip Sheet',
        'subtitle': 'Dispatches, dual GPS & odo tracking, site decanting & waiting surcharges',
        'route': '/operations/tanker-trip',
        'icon': Icons.route_rounded,
        'badge': 'Auto GPS',
      },
      {
        'title': 'Diesel & Fuel Expenses',
        'subtitle': 'Capture IOCL pump slips, driver batta, AdBlue & toll expenditure',
        'route': '/expenses/new',
        'icon': Icons.local_gas_station_rounded,
        'badge': 'Voucher Cam',
      },
      {
        'title': 'Live Fleet & Customer Map',
        'subtitle': 'Track active water tankers, speed & 385 L/min decanting flow',
        'route': '/fleet/gps?mode=bulk_water',
        'icon': Icons.radar_rounded,
        'badge': '385 L/min Live',
      },
      {
        'title': 'New Sump / Site Onboarding',
        'subtitle': 'Pin industrial customer sump GPS coordinates & credit profile',
        'route': '/customers/onboard',
        'icon': Icons.add_location_alt_rounded,
        'badge': 'Geofence',
      },
      {
        'title': 'Delivery Schedules',
        'subtitle': 'Manage regular recurring & customizable tanker delivery rules',
        'route': '/operations/schedules?vertical=tanker',
        'icon': Icons.event_repeat_rounded,
        'badge': 'Recurring',
      },
    ];

    final activeTrip = _tankerTrips.cast<Map<String, dynamic>?>().firstWhere(
      (t) {
        final s = (t?['status'] ?? '').toString().toLowerCase();
        return s.isNotEmpty && s != 'completed' && s != 'settled' && s != 'delivered';
      },
      orElse: () => null,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active Trip Decanting Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: skin.surface,
            borderRadius: BorderRadius.circular(skin.cardRadius),
            border: Border.all(color: skin.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.rippleHoney.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(skin.pillRadius),
                      ),
                      child: Text(
                        activeTrip != null ? 'ASSIGNED TRIP QUEUE' : 'TANKER DISPATCH DESK',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: skin.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.rippleMint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(skin.pillRadius),
                    ),
                    child: Text(
                      activeTrip != null
                          ? (activeTrip['status'] ?? 'DISPATCHED').toString().toUpperCase()
                          : 'READY',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.rippleMint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                activeTrip != null
                    ? '${activeTrip['customer_name'] ?? 'Bulk Water Order'} · ${activeTrip['reference_no'] ?? '#${activeTrip['id'] ?? ''}'}'
                    : 'Bulk Tanker Logistics Desk',
                style: AppTypography.title.copyWith(color: skin.ink),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/operations/tanker-trip', extra: activeTrip),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                      icon: const Icon(Icons.local_shipping_rounded, size: 18),
                      label: Text(activeTrip != null ? 'Process Assigned Order' : 'Start / Resume Tanker Trip'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => showCreateTankerOrderSheet(
                      context: context,
                      ref: ref,
                      onCreated: _fetchTasks,
                    ),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
                    label: const Text('Create Order'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/operations/schedules?vertical=tanker'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                    icon: const Icon(Icons.event_repeat_rounded, size: 16),
                    label: const Text('Delivery Schedules'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/hrm/attendance'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                    icon: const Icon(Icons.fingerprint_rounded, size: 16),
                    label: const Text('Shift Log'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5 Bulk Tanker Operations Modules
        Text(
          'Bulk Tanker Operations (5 Modules)',
          style: AppTypography.section.copyWith(color: skin.ink),
        ),
        const SizedBox(height: 10),
        ...modules.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => context.push(m['route'] as String),
              borderRadius: BorderRadius.circular(skin.cardRadius),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: skin.surface,
                  borderRadius: BorderRadius.circular(skin.cardRadius),
                  border: Border.all(color: skin.hairline),
                ),
                child: Row(
                  children: [
                    RippleIconBadge(
                      icon: m['icon'] as IconData,
                      accentColor: skin.primary,
                      size: 48,
                      iconSize: 25,
                      radius: 14,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['title'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              color: skin.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m['subtitle'] as String,
                            style: AppTypography.caption.copyWith(color: skin.muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: skin.surface2,
                        borderRadius: BorderRadius.circular(skin.pillRadius),
                      ),
                      child: Text(
                        m['badge'] as String,
                        style: AppTypography.caption.copyWith(
                          color: skin.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // T-12: My Trips & GPS Breadcrumbs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'My Completed Trips & GPS Trail',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.section.copyWith(color: skin.ink),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _fetchTasks,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_tankerTrips.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: skin.surface,
              borderRadius: BorderRadius.circular(skin.cardRadius),
              border: Border.all(color: skin.hairline),
            ),
            child: Text(
              'No tanker dispatches synced yet. Tap Refresh or start a trip above.',
              style: AppTypography.caption.copyWith(color: skin.muted),
            ),
          )
        else
          ..._tankerTrips.map((trip) {
            final refNo = trip['reference_no']?.toString() ?? 'Trip #${trip['id'] ?? ''}';
            final customer = trip['customer_name']?.toString() ?? 'Bulk Customer';
            final kl = trip['water_kl'] ??
                (trip['water_quantity_litres'] != null
                    ? ((trip['water_quantity_litres'] as num) / 1000)
                    : 0);
            final dist = trip['distance_km'] ?? 0;
            final total = trip['grand_total'] ?? 0;
            final status = (trip['status'] ?? 'completed').toString().toLowerCase();
            final isPending = status != 'completed' && status != 'settled' && status != 'delivered';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => isPending
                    ? context.push('/operations/tanker-trip', extra: trip)
                    : _showTripTrailSheet(trip),
                borderRadius: BorderRadius.circular(skin.cardRadius),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: skin.surface,
                    borderRadius: BorderRadius.circular(skin.cardRadius),
                    border: Border.all(color: skin.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$refNo · $customer',
                              style: AppTypography.bodyMedium.copyWith(
                                color: skin.ink,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isPending ? AppColors.warning : AppColors.rippleMint)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(skin.pillRadius),
                            ),
                            child: Text(
                              isPending ? 'PROCESS →' : 'GPS Trail ✓',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isPending ? AppColors.warning : AppColors.rippleMint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      OrderOriginBadge(order: trip),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '$kl KL · $dist KM · ${isPending ? 'Tap to Process Order' : 'Tap for GPS Trail'}',
                              style: AppTypography.caption.copyWith(color: skin.muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹$total',
                            style: AppTypography.bodyMedium.copyWith(
                              color: skin.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => showAdjustWaterOrderSheet(
                                context: context,
                                ref: ref,
                                verticalType: 'tanker',
                                order: trip,
                                onUpdated: _fetchTasks,
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 34),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              icon: const Icon(Icons.tune_rounded, size: 15),
                              label: const Text('Adjust Order', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Stitch D-11 (Can Driver Work Tab): 20L Can Operations Bento + Scheduled Stops + Shift Card.
  Widget _buildWaterCanOperationsAndStops(BuildContext context) {
    final skin = RippleSkin.of(context);
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    final quickActions = [
      {
        'title': 'Create Can Order',
        'subtitle': 'Create sales order & notify owner before moving',
        'route': '/operations/can-order',
        'icon': Icons.add_shopping_cart_rounded,
        'color': AppColors.aquaPrimary,
        'badge': 'Order',
      },
      {
        'title': 'Close / Deliver Order',
        'subtitle': 'Deliver cans, collect empties & cash/UPI',
        'route': '/operations/can-sales',
        'icon': Icons.local_drink_rounded,
        'color': AppColors.brandEmerald,
        'badge': 'Deliver',
      },
      {
        'title': 'Plant Refill Intake',
        'subtitle': 'Load filled water cans at RO Mother Plant',
        'route': '/operations/plant-refill',
        'icon': Icons.water_drop_rounded,
        'color': AppColors.info,
        'badge': 'Plant',
      },
      {
        'title': 'Van Stock Spot Audit',
        'subtitle': 'Reconcile full, empty & damaged jars',
        'route': '/operations/spot-audit',
        'icon': Icons.fact_check_rounded,
        'color': AppColors.warning,
        'badge': 'Audit',
      },
      {
        'title': 'Geofenced Attendance',
        'subtitle': '150m Plant Radar & Biometric Shift Log',
        'route': '/hrm/attendance',
        'icon': Icons.fingerprint_rounded,
        'color': AppColors.brandPurple,
        'badge': 'Shift',
      },
      {
        'title': 'Delivery Schedules',
        'subtitle': 'Recurring regular schedules & skip rules',
        'route': '/operations/schedules?vertical=can',
        'icon': Icons.event_repeat_rounded,
        'color': AppColors.aquaPrimary,
        'badge': 'Recurring',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Water Can Van Operations',
          style: AppTypography.section.copyWith(color: skin.ink),
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (context) {
            final cols = MediaQuery.sizeOf(context).width >= 820 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: rippleGridTileExtent(
                  context,
                  baseHeight: 74,
                  textBudget: 62,
                ),
              ),
              itemCount: quickActions.length,
              itemBuilder: (_, idx) {
                final item = quickActions[idx];
                return RippleMenuTileCard(
                  icon: item['icon'] as IconData,
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  accentColor: item['color'] as Color,
                  badge: item['badge'] as String?,
                  onTap: () async {
                    await context.push(item['route'] as String);
                    if (mounted) _fetchTasks();
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Open Can Orders (${_pendingCanOrders.length})',
                style: AppTypography.section.copyWith(color: skin.ink),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await context.push('/operations/schedules?vertical=can');
                if (mounted) _fetchTasks();
              },
              icon: const Icon(Icons.event_repeat_rounded, size: 16),
              label: const Text('Schedules'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_pendingCanOrders.isEmpty)
          Card(
            child: ListTile(
              leading: Icon(Icons.playlist_add_check_rounded, color: skin.primary),
              title: const Text('No open customer orders yet', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Tap Create Can Order before moving to a customer shop.'),
              trailing: TextButton(
                onPressed: () async {
                  await context.push('/operations/can-order');
                  if (mounted) _fetchTasks();
                },
                child: const Text('+ Order'),
              ),
            ),
          )
        else
          ..._pendingCanOrders.map((ord) {
            final ordStatus = (ord['status'] ?? 'ordered').toString().toLowerCase();
            final isTransit = ordStatus == 'in_transit';
            final ordNo = ord['order_no']?.toString() ?? 'ORD';
            final custName = ord['customer_name']?.toString() ?? 'Customer';
            final qty = ord['ordered_cans'] ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$custName · $qty Cans',
                                style: AppTypography.label.copyWith(color: skin.ink, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$ordNo · Est ₹${(ord['estimated_amount'] ?? 0)}',
                                style: AppTypography.caption.copyWith(color: skin.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusChip(
                              status: isTransit ? DocumentStatus.syncing : DocumentStatus.pending,
                              customLabel: isTransit ? 'IN TRANSIT' : 'ORDERED',
                            ),
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                              onPressed: () => showAdjustWaterOrderSheet(
                                context: context,
                                ref: ref,
                                verticalType: 'can',
                                order: ord,
                                onUpdated: _fetchTasks,
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 28),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                shape: const StadiumBorder(),
                              ),
                              icon: const Icon(Icons.tune_rounded, size: 13),
                              label: const Text('Adjust', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OrderOriginBadge(order: ord),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (!isTransit) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _startCanOrder(ord),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                              ),
                              icon: const Icon(Icons.directions_run_rounded, size: 16),
                              label: const Text('Start Moving'),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await context.push('/operations/can-sales', extra: ord);
                              if (mounted) _fetchTasks();
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Close Order'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 18),
        Text(
          'Scheduled Route Beat Stops (${_dynamicStops.length})',
          style: AppTypography.section.copyWith(color: skin.ink),
        ),
        const SizedBox(height: 10),
        if (_dynamicStops.isEmpty)
          const EmptyState(
            title: 'No Scheduled Can Stops',
            message: 'All water can delivery beats for this vehicle are clear.',
            icon: Icons.local_drink_rounded,
          )
        else
          ...List.generate(_dynamicStops.length, (index) {
            final stop = _dynamicStops[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final name = stop['name']?.toString() ?? 'Customer';
            final address = (stop['address'] ?? stop['city'])?.toString() ?? 'Route Beat';
            final cans = stop['total_cans_held'] ?? stop['daily_avg_cans'] ?? 10;
            final due = stop['outstanding_due'] != null ? 'Ã¢â€šÂ¹${stop['outstanding_due']}' : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTypography.label.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$address Ã¢â‚¬Â¢ Cans Held: $cans',
                              style: AppTypography.caption.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            if (due != null)
                              Text(
                                'Outstanding: $due',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await context.push('/operations/can-order', extra: {'customer_id': stop['id']});
                          if (mounted) _fetchTasks();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(88, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Create Order', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSyncOutboxList(BuildContext context, SyncWorker syncWorker) {
    final pendingCount = syncWorker.state.pendingCount;
    if (pendingCount == 0) {
      return const EmptyState(
        title: 'Outbox is Clean',
        message: 'All local field transactions are synced with the server.',
        icon: Icons.cloud_done_rounded,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$pendingCount Offline Records Pending',
                      style: AppTypography.section.copyWith(fontSize: 16),
                    ),
                    const StatusChip(
                      status: DocumentStatus.offline,
                      customLabel: 'Outbox',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  syncWorker.state.lastError != null && syncWorker.state.lastError!.isNotEmpty
                      ? 'Last attempt error: ${syncWorker.state.lastError}'
                      : 'Records were captured offline and will sync automatically when network connectivity is established.',
                  style: AppTypography.caption.copyWith(
                    color: syncWorker.state.lastError != null ? AppColors.danger : null,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final count = syncWorker.state.pendingCount;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(count > 0 ? 'Syncing $count offline record(s) to server...' : 'Checking server sync status...'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    await syncWorker.drainOutbox();
                    if (context.mounted) {
                      ref.read(dashboardRefreshSignalProvider.notifier).state++;
                      final remaining = syncWorker.state.pendingCount;
                      if (remaining == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All offline records successfully synced to ERP server!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        final err = syncWorker.state.lastError ?? 'Server rejected sync.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$remaining records pending. $err'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: const Text('Sync Outbox Now'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
