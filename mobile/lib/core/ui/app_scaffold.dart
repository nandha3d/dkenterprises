import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../sync/sync_worker.dart';
import '../theme/app_colors.dart';
import 'quick_action_sheet.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final syncState = ref.watch(syncWorkerProvider).state;
    final locale = ref.watch(localeProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
    final isAdmin = !isStaffOrDriver;

    final companyName = authState.activeCompany?.name ?? 'ZOLO ERP';
    final branchName = authState.activeBranch?.name ?? 'Main';

    // Sync indicator color
    final (syncColor, syncTooltip) = switch (syncState.status) {
      SyncStatus.synced => (AppColors.success, 'All records synced with server'),
      SyncStatus.syncing => (AppColors.info, 'Syncing offline records...'),
      SyncStatus.offline => (AppColors.warning, '${syncState.pendingCount} pending offline records'),
      SyncStatus.error => (AppColors.danger, 'Sync error: ${syncState.lastError ?? "Check connection"}'),
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: headerBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderCol, height: 1),
        ),
        title: InkWell(
          onTap: (isAdmin && authState.companies.length > 1) ? () => context.push('/workspace') : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.primaryDark : AppColors.primary).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (isDark ? AppColors.primaryDark : AppColors.primary).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        companyName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($branchName)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      if (isAdmin && authState.companies.length > 1) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Theme Switcher Toggle (Light / Dark)
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(34, 32),
            ),
          ),
          // Group Workspace / Switch Company (Admin Only)
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.domain_rounded, size: 20),
              tooltip: 'All Companies & Group Workspace',
              onPressed: () => context.push('/workspace'),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(34, 32),
              ),
            ),
          // Language Switcher Pill (EN / TA)
          TextButton(
            onPressed: () {
              final newLang = locale.languageCode == 'en' ? 'ta' : 'en';
              ref.read(secureStorageProvider).setLanguage(newLang);
              ref.read(localeProvider.notifier).state = Locale(newLang);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(36, 32),
            ),
            child: Text(
              locale.languageCode.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          // Sync Status Indicator Dot
          Tooltip(
            message: syncTooltip,
            child: InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: syncColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (syncState.pendingCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        syncState.pendingCount.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: syncColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: headerBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155).withOpacity(0.6) : borderCol,
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.45) : const Color(0xFF64748B).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  icon: Icons.assignment_rounded,
                  label: 'Tasks',
                  isSelected: currentIndex == 1,
                  onTap: () => context.go('/tasks'),
                ),
                // Center Floating Quick Action Button
                Semantics(
                  button: true,
                  label: 'Create New Action',
                  child: InkWell(
                    onTap: () => QuickActionSheet.show(context),
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF38BDF8), Color(0xFF0284C7)]
                              : const [Color(0xFF0284C7), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withOpacity(isDark ? 0.45 : 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  icon: Icons.apps_rounded,
                  label: 'Modules',
                  isSelected: currentIndex == 3,
                  onTap: () => context.go('/modules'),
                ),
                _buildNavItem(
                  context: context,
                  index: 4,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: currentIndex == 4,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCol = isDark ? AppColors.primaryDark : AppColors.primary;
    final inactiveCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeCol.withOpacity(isDark ? 0.18 : 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: activeCol.withOpacity(isDark ? 0.35 : 0.22),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? activeCol : inactiveCol,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeCol : inactiveCol,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 2),
              width: isSelected ? 4 : 0,
              height: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: activeCol,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
