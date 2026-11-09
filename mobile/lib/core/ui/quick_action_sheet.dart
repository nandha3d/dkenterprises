import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class QuickActionSheet extends ConsumerWidget {
  const QuickActionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QuickActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final industry = authState.activeCompany?.industry ?? '';

    final user = authState.user;
    final role = (user?.role ?? '').toLowerCase();
    final username = (user?.username ?? user?.name ?? '').toLowerCase();

    final isTankerDriver = role == 'tankerdriver' || username == 'tanker_driver' || username == 'tanker';
    final isDeliveryDriver = role == 'deliverydriver' || role == 'driver' || username == 'driver';
    final isCashier = role == 'cashier' || username == 'cashier';
    final isFieldAgent = role == 'fieldagent' || role == 'agent' || username == 'agent';

    final actions = <_ActionItem>[];

    if (isTankerDriver) {
      actions.addAll([
        const _ActionItem(
          title: 'Tanker Trip',
          subtitle: 'Dispatch & surcharge',
          icon: Icons.local_shipping_rounded,
          color: Color(0xFF0369A1),
          route: '/operations/tanker-trip',
          enabled: true,
        ),
        const _ActionItem(
          title: 'New Customer / Site',
          subtitle: 'Onboard destination sump',
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.brandEmerald,
          route: '/customers/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Diesel & Expense',
          subtitle: 'Bill receipt & GPS',
          icon: Icons.attach_money_rounded,
          color: AppColors.warning,
          route: '/expenses/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Mark Attendance',
          subtitle: 'Geofenced punch',
          icon: Icons.fingerprint_rounded,
          color: AppColors.info,
          route: '/hrm/attendance',
          enabled: true,
        ),
      ]);
    } else if (isDeliveryDriver) {
      actions.addAll([
        const _ActionItem(
          title: 'Can Sales POS',
          subtitle: 'Water distribution',
          icon: Icons.water_drop_rounded,
          color: Color(0xFF0284C7),
          route: '/operations/can-sales',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Add Customer',
          subtitle: 'New shop on beat route',
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.brandEmerald,
          route: '/customers/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Driver Cash Surrender',
          subtitle: 'End-of-day settlement',
          icon: Icons.price_check_rounded,
          color: Color(0xFF0284C7),
          route: '/operations/driver-surrender',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Spot Can Audit',
          subtitle: 'Truck inventory check',
          icon: Icons.fact_check_rounded,
          color: AppColors.warning,
          route: '/operations/spot-audit',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Daily Expense',
          subtitle: 'Fuel & tolls',
          icon: Icons.attach_money_rounded,
          color: AppColors.warning,
          route: '/expenses/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Mark Attendance',
          subtitle: 'Geofenced punch',
          icon: Icons.fingerprint_rounded,
          color: AppColors.info,
          route: '/hrm/attendance',
          enabled: true,
        ),
      ]);
    } else if (isCashier) {
      actions.addAll([
        const _ActionItem(
          title: 'Cafe POS',
          subtitle: 'Order billing',
          icon: Icons.restaurant_rounded,
          color: Color(0xFFD97706),
          route: '/operations/cafe-pos',
          enabled: true,
        ),
        const _ActionItem(
          title: 'New Customer',
          subtitle: 'Party registration',
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.brandEmerald,
          route: '/customers/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Collect Payment',
          subtitle: 'Invoice settlement',
          icon: Icons.payments_rounded,
          color: AppColors.success,
          route: '/accounting/collect',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Quick Expense',
          subtitle: 'Kitchen purchases',
          icon: Icons.attach_money_rounded,
          color: AppColors.warning,
          route: '/expenses/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Mark Attendance',
          subtitle: 'Geofenced punch',
          icon: Icons.fingerprint_rounded,
          color: AppColors.info,
          route: '/hrm/attendance',
          enabled: true,
        ),
      ]);
    } else if (isFieldAgent) {
      actions.addAll([
        const _ActionItem(
          title: 'Onboard Customer',
          subtitle: 'KYC & GPS geotagging',
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.brandEmerald,
          route: '/customers/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Collect Payment',
          subtitle: 'Party receipt',
          icon: Icons.payments_rounded,
          color: AppColors.success,
          route: '/accounting/collect',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Quick Expense',
          subtitle: 'Field conveyance',
          icon: Icons.attach_money_rounded,
          color: AppColors.warning,
          route: '/expenses/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Mark Attendance',
          subtitle: 'Geofenced punch',
          icon: Icons.fingerprint_rounded,
          color: AppColors.info,
          route: '/hrm/attendance',
          enabled: true,
        ),
      ]);
    } else {
      actions.addAll([
        _ActionItem(
          title: 'New Sale Bill',
          subtitle: 'B2B/B2C invoice',
          icon: Icons.receipt_long_rounded,
          color: AppColors.primary,
          route: '/sales/new',
          enabled: authState.hasPermission('sales-index') || authState.hasPermission('sales-add'),
        ),
        const _ActionItem(
          title: 'Collect Payment',
          subtitle: 'Invoice settlement',
          icon: Icons.payments_rounded,
          color: AppColors.success,
          route: '/accounting/collect',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Quick Expense',
          subtitle: 'Bill receipt & GPS',
          icon: Icons.attach_money_rounded,
          color: AppColors.warning,
          route: '/expenses/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'New Customer',
          subtitle: 'Party registration',
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.brandEmerald,
          route: '/customers/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'New Product',
          subtitle: 'Item configuration',
          icon: Icons.add_box_rounded,
          color: AppColors.brandPurple,
          route: '/products/new',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Mark Attendance',
          subtitle: 'Geofenced punch',
          icon: Icons.fingerprint_rounded,
          color: AppColors.info,
          route: '/hrm/attendance',
          enabled: true,
        ),
        if (industry == 'packaged_water' || industry.isEmpty)
          const _ActionItem(
            title: 'Can Sales POS',
            subtitle: 'Water distribution',
            icon: Icons.water_drop_rounded,
            color: Color(0xFF0284C7),
            route: '/operations/can-sales',
            enabled: true,
          ),
        if (industry == 'bulk_water' || industry.isEmpty)
          const _ActionItem(
            title: 'Tanker Trip',
            subtitle: 'Dispatch & surcharge',
            icon: Icons.local_shipping_rounded,
            color: Color(0xFF0369A1),
            route: '/operations/tanker-trip',
            enabled: true,
          ),
        if (industry == 'cafe_bakery' || industry.isEmpty)
          const _ActionItem(
            title: 'Cafe POS',
            subtitle: 'Order billing',
            icon: Icons.restaurant_rounded,
            color: Color(0xFFD97706),
            route: '/operations/cafe-pos',
            enabled: true,
          ),
        const _ActionItem(
          title: 'Stock Count',
          subtitle: 'Godown audit',
          icon: Icons.inventory_2_rounded,
          color: Color(0xFF64748B),
          route: '/inventory/stock-count',
          enabled: true,
        ),
      ]);
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions (+ New)',
                style: AppTypography.section.copyWith(color: titleColor),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: actions.where((a) => a.enabled).length,
              itemBuilder: (ctx, index) {
                final item = actions.where((a) => a.enabled).toList()[index];

                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(item.route);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.icon, size: 20, color: item.color),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTypography.label.copyWith(
                                color: titleColor,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.subtitle,
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final bool enabled;

  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.enabled,
  });
}

