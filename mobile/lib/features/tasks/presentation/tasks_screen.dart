import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  int _selectedFilterIndex = 0; // 0: Route Stops, 1: Pending Sync, 2: Approvals

  @override
  Widget build(BuildContext context) {
    final syncWorker = ref.watch(syncWorkerProvider);
    final syncState = syncWorker.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
                  label: 'Beat Stops',
                  count: 4,
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
                ? _buildRouteStopsList(context)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                color: badgeColor ?? (isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (badgeColor ?? AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilterIndex = index),
      selectedColor: isDark ? AppColors.primaryDark : AppColors.primary,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCanvas,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isSelected
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      ),
    );
  }

  Widget _buildRouteStopsList(BuildContext context) {
    final stops = [
      {'name': 'Sri Murugan Mess', 'area': 'Anna Nagar', 'cans': 10, 'due': '₹850', 'phone': '9876543210'},
      {'name': 'Kannan Departmental Store', 'area': 'Main Road', 'cans': 15, 'due': '₹0', 'phone': '9876543211'},
      {'name': 'Royal Care Clinic', 'area': 'Cross Cut Road', 'cans': 5, 'due': '₹1,200', 'phone': '9876543212'},
      {'name': 'Green Star Cafe', 'area': 'Gandhi Puram', 'cans': 8, 'due': '₹640', 'phone': '9876543213'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final stop = stops[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        stop['name'] as String,
                        style: AppTypography.label.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stop['area']} • Order: ${stop['cans']} Cans',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        'Outstanding: ${stop['due']}',
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
