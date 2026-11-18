import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../gps/gps_enforcement_gate.dart';
import '../providers.dart';
import '../routing/role_navigation.dart';
import '../sync/sync_worker.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'adaptive_layout.dart';
import 'fluid_curved_nav_bar.dart';
import 'quick_action_sheet.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Sign out of this shift? Pending offline records will stay saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final syncState = ref.watch(syncWorkerProvider).state;
    final unreadNotifications = ref.watch(pushNotificationServiceProvider).unreadCount;
    final rippleRole = ref.watch(activeRippleRoleProvider);
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = rippleRole == RippleRole.admin;

    final rawCompName = authState.activeCompany?.name.trim() ?? '';
    final companyName = rawCompName.isNotEmpty ? rawCompName : 'DK Enterprises';
    final rawBranchName = authState.activeBranch?.name.trim() ?? '';
    final branchName = rawBranchName.isNotEmpty ? rawBranchName : 'Main';

    final (syncColor, syncTooltip) = switch (syncState.status) {
      SyncStatus.synced => (AppColors.rippleMint, 'All records synced'),
      SyncStatus.syncing => (AppColors.rippleSky, 'Syncing offline records...'),
      SyncStatus.offline => (AppColors.rippleHoney, '${syncState.pendingCount} pending offline records'),
      SyncStatus.error => (AppColors.rippleRuby, 'Sync error: ${syncState.lastError ?? "Check connection"}'),
    };

    final roleTabs = navTabsForRole(rippleRole);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: skin.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: skin.hairline, height: 1),
        ),
        title: InkWell(
          onTap: isAdmin ? () => context.go('/workspace') : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: skin.primary.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: skin.primary.withValues(alpha: 0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      companyName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: skin.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '($branchName)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: skin.muted,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: skin.primary),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.fingerprint_rounded, size: 20, color: skin.ink),
            tooltip: 'Geofenced Shift Attendance',
            onPressed: () => context.push('/hrm/attendance'),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none_rounded, size: 22, color: skin.ink),
                if (unreadNotifications > 0)
                  Positioned(
                    right: -6,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: skin.surface, width: 1.2),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      alignment: Alignment.center,
                      child: Text(
                        unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  )
                else if (syncState.pendingCount > 0 || syncState.status == SyncStatus.error)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: syncColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications & Sync Center',
            onPressed: () {
              ref.read(pushNotificationServiceProvider).markLocalRead();
              context.push('/notifications');
            },
          ),
          if (rippleRole == RippleRole.cafe)
            IconButton(
              icon: Icon(Icons.person_outline_rounded, size: 20, color: skin.ink),
              tooltip: 'Profile & Account',
              onPressed: () => context.push('/profile'),
            ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          if (!isAdmin)
            IconButton(
              key: const Key('appbar_logout_btn'),
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.logout_rounded, size: 20, color: skin.ink),
              tooltip: 'Sign Out',
              onPressed: () => _confirmSignOut(context, ref),
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.domain_rounded, size: 20),
              tooltip: 'Group Workspace',
              onPressed: () => context.go('/workspace'),
            ),
          Tooltip(
            message: syncTooltip,
            child: InkWell(
              onTap: () => context.push('/notifications'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: syncColor, shape: BoxShape.circle),
                    ),
                    if (syncState.pendingCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        syncState.pendingCount.toString(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: syncColor),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: GpsEnforcementGate(
        child: AdaptivePageConstraint(
          maxWidth: 1600,
          child: child,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: FluidCurvedNavBar(
          currentIndex: currentIndex.clamp(0, roleTabs.length - 1),
          onTabSelected: (index) {
            final tab = roleTabs[index];
            if (!tab.isCenterAction && tab.route.isNotEmpty) {
              context.go(tab.route);
            }
          },
          items: roleTabs
              .map(
                (t) => FluidNavItem(
                  icon: t.icon,
                  activeIcon: t.activeIcon,
                  label: t.label,
                  tooltip: t.tooltip,
                  isActionOnly: t.isCenterAction,
                  onActionTap: t.isCenterAction ? () => QuickActionSheet.show(context) : null,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
