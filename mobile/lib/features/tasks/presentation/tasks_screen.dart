import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/sync/sync_worker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/status_chip.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int _selectedFilterIndex = 0; // 0: Route / Operations, 1: Pending Sync, 2: Approvals
  bool _isLoadingTasks = false;
  List<Map<String, dynamic>> _dynamicStops = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final authState = ref.read(authNotifierProvider);
    final industry = authState.activeCompany?.industry ?? '';
    if (industry == 'packaged_water') {
      setState(() => _isLoadingTasks = true);
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
      if (mounted) {
        setState(() {
          _isLoadingTasks = false;
          _dynamicStops = res.dataOrNull ?? [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final industry = authState.activeCompany?.industry ?? '';
    final syncWorker = ref.watch(syncWorkerProvider);
    final syncState = syncWorker.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final primaryTabLabel = switch (industry) {
      'packaged_water' => 'Beat Deliveries',
      'cafe_bakery' => 'Cafe Operations',
      'bulk_water' => 'Tanker Dispatches',
      _ => 'Daily Queue',
    };

    final primaryTabCount = industry == 'packaged_water' ? _dynamicStops.length : 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Work & Task Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Outbox Now',
            onPressed: () => syncWorker.drainOutbox(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(bottom: BorderSide(color: borderCol, width: 1)),
            ),
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
                  label: 'Approvals',
                  count: 0,
                  index: 2,
                ),
              ],
            ),
          ),

          // Task List Body
          Expanded(
            child: _selectedFilterIndex == 0
                ? _buildVerticalOperationsList(context, industry)
                : _selectedFilterIndex == 1
                    ? _buildSyncOutboxList(context, syncWorker)
                    : const EmptyState(
                        title: 'No Pending Approvals',
                        message: 'All commercial vouchers and documents are up to date.',
                        icon: Icons.check_circle_outline_rounded,
                      ),
          ),
        ],
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

  Widget _buildVerticalOperationsList(BuildContext context, String industry) {
    if (industry == 'packaged_water') {
      return _buildWaterCanStopsList(context);
    } else if (industry == 'cafe_bakery') {
      return _buildCafeOperationsList(context);
    } else if (industry == 'bulk_water') {
      return _buildTankerOperationsList(context);
    } else {
      return const EmptyState(
        title: 'No Pending Queue Items',
        message: 'All operations and vouchers for this company workspace are settled.',
        icon: Icons.done_all_rounded,
      );
    }
  }

  Widget _buildCafeOperationsList(BuildContext context) {
    final tasks = [
      {
        'title': 'Aran Cafe Touch POS Counter',
        'subtitle': 'Ready for table & counter billing',
        'route': '/operations/cafe-pos',
        'icon': Icons.point_of_sale_rounded,
        'action': 'Open POS',
        'color': const Color(0xFFD97706),
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
        'title': 'Daily Cafe Operational Expenses',
        'subtitle': 'Record dairy, gas, veggies & vendor payments',
        'route': '/expenses/new',
        'icon': Icons.receipt_long_rounded,
        'action': 'Record',
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(task['icon'] as IconData, size: 20, color: color),
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
                    minimumSize: const Size(80, 38),
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

  Widget _buildTankerOperationsList(BuildContext context) {
    final tasks = [
      {
        'title': 'Live Tanker GPS Fleet Radar',
        'subtitle': 'Track active water tankers, speed & decanting flow',
        'route': '/fleet/gps?mode=bulk_water',
        'icon': Icons.share_location_rounded,
        'action': 'Radar',
        'color': const Color(0xFF0369A1),
      },
      {
        'title': 'Tanker Trip Sheet Dispatch',
        'subtitle': 'Log start/end odometer, motor pumping & waiting surcharges',
        'route': '/operations/tanker-trip',
        'icon': Icons.local_shipping_rounded,
        'action': 'Dispatch',
        'color': const Color(0xFF0284C7),
      },
      {
        'title': 'Diesel & Vehicle Expenses',
        'subtitle': 'Capture pump slips, driver batta & maintenance bills',
        'route': '/expenses/new',
        'icon': Icons.local_gas_station_rounded,
        'action': 'Log Fuel',
        'color': AppColors.warning,
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(task['icon'] as IconData, size: 20, color: color),
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
                    minimumSize: const Size(80, 38),
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

  Widget _buildWaterCanStopsList(BuildContext context) {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dynamicStops.isEmpty) {
      return const EmptyState(
        title: 'No Scheduled Can Stops',
        message: 'All 20L can delivery beats for this vehicle are clear.',
        icon: Icons.local_drink_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _dynamicStops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final stop = _dynamicStops[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final name = stop['name']?.toString() ?? 'Customer';
        final address = (stop['address'] ?? stop['city'])?.toString() ?? 'Route Beat';
        final cans = stop['total_cans_held'] ?? stop['daily_avg_cans'] ?? 10;
        final due = stop['outstanding_due'] != null ? '₹${stop['outstanding_due']}' : null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
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
                        '$address • Order: $cans Cans',
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
                  onPressed: () => context.push('/operations/can-sales'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Deliver', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        );
      },
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
                  'Records were captured offline and will sync automatically when network connectivity is established.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => syncWorker.drainOutbox(),
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
