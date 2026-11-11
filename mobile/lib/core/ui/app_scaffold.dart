import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../sync/sync_worker.dart';
import '../theme/app_colors.dart';
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

    final industry = authState.activeCompany?.industry ?? '';
    final activeThemeColor = switch (industry) {
      'cafe_bakery' => isDark ? AppColors.brandAmber : const Color(0xFFD97706),
      'packaged_water' => isDark ? AppColors.brandEmerald : const Color(0xFF059669),
      'bulk_water' => isDark ? AppColors.primaryDark : AppColors.primary,
      _ => isDark ? AppColors.primaryDark : AppColors.primary,
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
          // Quick Action (+) Button for 1-Tap ERP Actions
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(5),
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
                    color: const Color(0xFF0284C7).withOpacity(isDark ? 0.4 : 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            ),
            tooltip: 'Quick Actions',
            onPressed: () => QuickActionSheet.show(context),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(34, 32),
            ),
          ),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: FluidCurvedNavBar(
          currentIndex: currentIndex.clamp(0, 3),
          activeColor: activeThemeColor,
          onTabSelected: (index) {
            switch (index) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/tasks');
                break;
              case 2:
                context.go('/modules');
                break;
              case 3:
                context.go('/profile');
                break;
            }
          },
          items: const [
            FluidNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
              tooltip: 'Home Dashboard',
            ),
            FluidNavItem(
              icon: Icons.access_time_rounded,
              activeIcon: Icons.access_time_filled_rounded,
              label: 'Tasks',
              tooltip: 'Operational Tasks',
            ),
            FluidNavItem(
              icon: Icons.pie_chart_outline_rounded,
              activeIcon: Icons.pie_chart_rounded,
              label: 'Modules',
              tooltip: 'All Menus & Modules',
            ),
            FluidNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
              tooltip: 'Profile & Settings',
            ),
          ],
        ),
      ),
    );
  }
}
