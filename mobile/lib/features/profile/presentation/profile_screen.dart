import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/sync/sync_worker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/company_switcher_sheet.dart';
import '../../../core/ui/status_chip.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final syncWorker = ref.watch(syncWorkerProvider);
    final syncState = syncWorker.state;
    final locale = ref.watch(localeProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedCol = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final user = authState.user;
    final role = (user?.role ?? '').toLowerCase();
    final username = (user?.username ?? user?.name ?? '').toLowerCase();
    final isStaffOrDriver = role == 'tankerdriver' ||
        role == 'deliverydriver' ||
        role == 'driver' ||
        role == 'cashier' ||
        role == 'fieldagent' ||
        role == 'agent' ||
        username == 'tanker_driver' ||
        username == 'driver' ||
        username == 'cashier' ||
        username == 'agent';

    final canSwitchCompany = !isStaffOrDriver && authState.companies.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Monogram Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primary).withOpacity(0.15),
                    child: Text(
                      authState.user?.name.isNotEmpty == true
                          ? authState.user!.name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.user?.name ?? 'User Profile',
                          style: AppTypography.title.copyWith(fontSize: 18, color: textCol),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${authState.user?.username ?? ""} • ${authState.user?.role.toUpperCase() ?? ""}',
                          style: AppTypography.caption.copyWith(color: mutedCol),
                        ),
                        if (authState.user?.phone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Phone: ${authState.user!.phone}',
                            style: AppTypography.caption.copyWith(color: mutedCol),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Active Entity Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Organization',
                        style: AppTypography.section.copyWith(fontSize: 15, color: textCol),
                      ),
                      if (canSwitchCompany)
                        TextButton.icon(
                          onPressed: () => CompanySwitcherSheet.show(context),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: const Text('Switch'),
                        ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildDetailRow('Company', authState.activeCompany?.name ?? '—', textCol, mutedCol),
                  _buildDetailRow('Industry', authState.activeCompany?.industry ?? 'Standard ERP', textCol, mutedCol),
                  _buildDetailRow('Branch', authState.activeBranch?.name ?? 'Main Branch', textCol, mutedCol),
                  _buildDetailRow('Financial Year', authState.activeFinancialYear?.name ?? 'FY 2026-27', textCol, mutedCol),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Offline Sync Centre Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Offline Sync Centre',
                        style: AppTypography.section.copyWith(fontSize: 15, color: textCol),
                      ),
                      StatusChip(
                        status: syncState.status == SyncStatus.synced
                            ? DocumentStatus.synced
                            : syncState.status == SyncStatus.syncing
                                ? DocumentStatus.syncing
                                : DocumentStatus.offline,
                        customLabel: syncState.status == SyncStatus.synced
                            ? 'Synced'
                            : '${syncState.pendingCount} Pending',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'All field sales, tanker trips, attendance, and expense records are safely held in local SQLite storage until server connectivity is verified.',
                    style: AppTypography.caption.copyWith(color: mutedCol),
                  ),
                  if (syncState.lastSyncedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Last Sync: ${DateFormat('dd MMM yyyy, hh:mm:ss a').format(syncState.lastSyncedAt!)}',
                      style: AppTypography.caption.copyWith(color: mutedCol, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 14),
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
          const SizedBox(height: 16),

          // App Language & Preferences
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferences',
                    style: AppTypography.section.copyWith(fontSize: 15, color: textCol),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.domain_rounded),
                    title: const Text('Company & Workspace Directory', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${authState.activeCompany?.name ?? "Select"} • All Entities',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/workspace'),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                    title: const Text('Theme Appearance', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      isDark ? 'Dark Theme' : 'Light Theme',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'light', label: Text('Light')),
                        ButtonSegment(value: 'dark', label: Text('Dark')),
                      ],
                      selected: {isDark ? 'dark' : 'light'},
                      onSelectionChanged: (selected) {
                        ref.read(themeModeProvider.notifier).setThemeMode(
                          selected.first == 'dark' ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('App Language', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      locale.languageCode == 'ta' ? 'தமிழ் (Tamil)' : 'English',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'en', label: Text('EN')),
                        ButtonSegment(value: 'ta', label: Text('தமிழ்')),
                      ],
                      selected: {locale.languageCode},
                      onSelectionChanged: (selected) {
                        final lang = selected.first;
                        ref.read(secureStorageProvider).setLanguage(lang);
                        ref.read(localeProvider.notifier).state = Locale(lang);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // System Info
          Center(
            child: Column(
              children: [
                Text(
                  'ZOLO ERP Mobile v1.0.0+1 (Build 2026.11)',
                  style: AppTypography.caption.copyWith(color: mutedCol, fontSize: 11),
                ),
                Text(
                  'API: ${ApiEndpoints.baseUrl}',
                  style: AppTypography.caption.copyWith(color: mutedCol, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Secure Sign Out Button
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Sign Out'),
                  content: const Text('Are you sure you want to end your current ERP session?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
            label: const Text(
              'Sign Out of Account',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textCol, Color mutedCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: mutedCol)),
          Text(value, style: AppTypography.label.copyWith(color: textCol, fontSize: 13)),
        ],
      ),
    );
  }
}

