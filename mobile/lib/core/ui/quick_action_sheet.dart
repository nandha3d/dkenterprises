import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'ripple_components.dart';

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
          title: 'Create Tanker Order',
          subtitle: 'Create Sales Order & notify owner',
          icon: Icons.add_shopping_cart_rounded,
          color: AppColors.aquaPrimary,
          route: '/operations/schedules?vertical=tanker',
          badge: 'ORDER',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Tanker Trip',
          subtitle: 'Dispatch & surcharge',
          icon: Icons.local_shipping_rounded,
          color: Color(0xFF0369A1),
          route: '/operations/tanker-trip',
          badge: 'TRIP',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Delivery Schedules',
          subtitle: 'Daily, 2-day & custom tanker plans',
          icon: Icons.event_repeat_rounded,
          color: Color(0xFF0E8FB3),
          route: '/operations/schedules?vertical=tanker',
          badge: 'PLAN',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Freight Cash',
          subtitle: 'Trip settlement handover',
          icon: Icons.payments_rounded,
          color: Color(0xFF0E8FB3),
          route: '/operations/driver-surrender',
          badge: 'CASH',
          enabled: true,
        ),
        const _ActionItem(
          title: 'New Customer / Site',
          subtitle: 'Onboard destination sump',
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.brandEmerald,
          route: '/customers/new',
          badge: 'SITE',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Diesel & Expense',
          subtitle: 'Bill receipt & GPS',
          icon: Icons.local_gas_station_rounded,
          color: AppColors.warning,
          route: '/expenses/new',
          badge: 'FUEL',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Mark Attendance',
          subtitle: 'Geofenced punch',
          icon: Icons.fingerprint_rounded,
          color: AppColors.info,
          route: '/hrm/attendance',
          badge: 'PUNCH',
          enabled: true,
        ),
      ]);
    } else if (isDeliveryDriver) {
      actions.addAll([
        const _ActionItem(
          title: 'Create Can Order',
          subtitle: 'Create Sales Order & notify owner',
          icon: Icons.add_shopping_cart_rounded,
          color: AppColors.aquaPrimary,
          route: '/operations/can-order',
          badge: 'Order',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Close / Deliver Order',
          subtitle: 'Arrive & close at customer',
          icon: Icons.water_drop_rounded,
          color: Color(0xFF0284C7),
          route: '/operations/can-sales',
          badge: 'Deliver',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Delivery Schedules',
          subtitle: 'Daily, 2-day & custom can plans',
          icon: Icons.event_repeat_rounded,
          color: AppColors.info,
          route: '/operations/schedules?vertical=can',
          badge: 'PLAN',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Plant Refill',
          subtitle: 'Load filled water cans & jars',
          icon: Icons.local_drink_rounded,
          color: AppColors.brandEmerald,
          route: '/operations/plant-refill',
          badge: 'Plant',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Add Customer',
          subtitle: 'New shop on beat route',
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.brandEmerald,
          route: '/customers/new',
          badge: 'BEAT',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Driver Cash Surrender',
          subtitle: 'End-of-day settlement',
          icon: Icons.price_check_rounded,
          color: Color(0xFF0284C7),
          route: '/operations/driver-surrender',
          badge: 'EOD',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Daily Expense',
          subtitle: 'Fuel & tolls',
          icon: Icons.local_gas_station_rounded,
          color: AppColors.warning,
          route: '/expenses/new',
          badge: 'EXP',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Mark Attendance',
          subtitle: 'Geofenced punch',
          icon: Icons.fingerprint_rounded,
          color: AppColors.info,
          route: '/hrm/attendance',
          badge: 'PUNCH',
          enabled: true,
        ),
      ]);
    } else if (isCashier) {
      actions.addAll([
        const _ActionItem(
          title: 'Cafe POS',
          subtitle: 'Order billing & tables',
          icon: Icons.point_of_sale_rounded,
          color: AppColors.chaiPrimary,
          route: '/operations/cafe-pos',
          badge: 'POS',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Cash Drawer X/Z',
          subtitle: 'Shift float & handover',
          icon: Icons.savings_rounded,
          color: AppColors.rippleMint,
          route: '/erp/pos-drawer',
          badge: 'X/Z',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Kitchen Stock Audit',
          subtitle: 'Closing ingredient count',
          icon: Icons.fact_check_rounded,
          color: AppColors.rippleSky,
          route: '/inventory/stock-count',
          badge: 'AUDIT',
          enabled: true,
        ),
        const _ActionItem(
          title: 'New Customer',
          subtitle: 'Party registration',
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.brandEmerald,
          route: '/customers/new',
          badge: 'CRM',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Collect Payment',
          subtitle: 'Invoice settlement',
          icon: Icons.payments_rounded,
          color: AppColors.success,
          route: '/accounting/collect',
          badge: 'PAY',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Quick Expense',
          subtitle: 'Kitchen purchases',
          icon: Icons.receipt_rounded,
          color: AppColors.warning,
          route: '/expenses/new',
          badge: 'EXP',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Purchase Bill / Supplier',
          subtitle: 'Regular vendor & cash/GPay',
          icon: Icons.shopping_bag_rounded,
          color: AppColors.chaiPrimary,
          route: '/operations/quick-purchase',
          badge: 'BUY',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Mark Attendance',
          subtitle: 'Geofenced punch',
          icon: Icons.fingerprint_rounded,
          color: AppColors.info,
          route: '/hrm/attendance',
          badge: 'PUNCH',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Profile & Account',
          subtitle: 'Theme, shift & sync',
          icon: Icons.person_rounded,
          color: Color(0xFF475569),
          route: '/profile',
          badge: 'ME',
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
          badge: 'KYC',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Collect Payment',
          subtitle: 'Party receipt',
          icon: Icons.payments_rounded,
          color: AppColors.success,
          route: '/accounting/collect',
          badge: 'PAY',
          enabled: true,
        ),
        if (industry == 'packaged_water')
          const _ActionItem(
            title: 'Spot Can Audit',
            subtitle: 'Verify route van stock',
            icon: Icons.fact_check_rounded,
            color: AppColors.warning,
            route: '/operations/spot-audit',
            badge: 'Audit',
            enabled: true,
          ),
        if (industry == 'bulk_water')
          const _ActionItem(
            title: 'Tanker Trip',
            subtitle: 'Dispatch & surcharge',
            icon: Icons.local_shipping_rounded,
            color: Color(0xFF0369A1),
            route: '/operations/tanker-trip',
            badge: 'TRIP',
            enabled: true,
          ),
        const _ActionItem(
          title: 'Quick Expense',
          subtitle: 'Field conveyance',
          icon: Icons.receipt_rounded,
          color: AppColors.warning,
          route: '/expenses/new',
          badge: 'EXP',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Purchase Bill / Supplier',
          subtitle: 'Regular vendor & cash/GPay',
          icon: Icons.shopping_bag_rounded,
          color: AppColors.brandEmerald,
          route: '/operations/quick-purchase',
          badge: 'BUY',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Mark Attendance',
          subtitle: 'Geofenced punch',
          icon: Icons.fingerprint_rounded,
          color: AppColors.info,
          route: '/hrm/attendance',
          badge: 'PUNCH',
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
          badge: 'BILL',
          enabled: authState.hasPermission('sales-index') || authState.hasPermission('sales-add'),
        ),
        const _ActionItem(
          title: 'Collect Payment',
          subtitle: 'Invoice settlement',
          icon: Icons.payments_rounded,
          color: AppColors.success,
          route: '/accounting/collect',
          badge: 'PAY',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Quick Expense',
          subtitle: 'Bill receipt & GPS',
          icon: Icons.receipt_rounded,
          color: AppColors.warning,
          route: '/expenses/new',
          badge: 'EXP',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Purchase Bill / Supplier',
          subtitle: 'Regular vendor & cash/GPay',
          icon: Icons.shopping_bag_rounded,
          color: AppColors.primary,
          route: '/operations/quick-purchase',
          badge: 'BUY',
          enabled: true,
        ),
        const _ActionItem(
          title: 'New Customer',
          subtitle: 'Party registration',
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.brandEmerald,
          route: '/customers/new',
          badge: 'CRM',
          enabled: true,
        ),
        const _ActionItem(
          title: 'New Product',
          subtitle: 'Item configuration',
          icon: Icons.add_box_rounded,
          color: AppColors.brandPurple,
          route: '/products/new',
          badge: 'SKU',
          enabled: true,
        ),
        const _ActionItem(
          title: 'Mark Attendance',
          subtitle: 'Geofenced punch',
          icon: Icons.fingerprint_rounded,
          color: AppColors.info,
          route: '/hrm/attendance',
          badge: 'PUNCH',
          enabled: true,
        ),
        if (industry == 'packaged_water' || industry.isEmpty) ...[
          const _ActionItem(
            title: 'Create Can Order',
            subtitle: 'Create Sales Order & notify owner',
            icon: Icons.add_shopping_cart_rounded,
            color: AppColors.aquaPrimary,
            route: '/operations/can-order',
            badge: 'Order',
            enabled: true,
          ),
          const _ActionItem(
            title: 'Can Schedules',
            subtitle: 'Regular & custom can plans',
            icon: Icons.event_repeat_rounded,
            color: AppColors.info,
            route: '/operations/schedules?vertical=can',
            badge: 'PLAN',
            enabled: true,
          ),
          const _ActionItem(
            title: 'Can Driver Manifest',
            subtitle: 'Driver route & 60 cans load',
            icon: Icons.local_shipping_rounded,
            color: Color(0xFF059669),
            route: '/operations/driver-manifest',
            badge: 'BEAT',
            enabled: true,
          ),
          const _ActionItem(
            title: 'Close / Deliver Order',
            subtitle: 'Water distribution',
            icon: Icons.water_drop_rounded,
            color: Color(0xFF0284C7),
            route: '/operations/can-sales',
            badge: 'Deliver',
            enabled: true,
          ),
        ],
        if (industry == 'bulk_water' || industry.isEmpty) ...[
          const _ActionItem(
            title: 'Tanker Driver Desk',
            subtitle: 'Trip decanting & valve status',
            icon: Icons.local_shipping_rounded,
            color: Color(0xFF0284C7),
            route: '/operations/tanker-dashboard',
            badge: 'TANK',
            enabled: true,
          ),
          const _ActionItem(
            title: 'Tanker Trip',
            subtitle: 'Dispatch & surcharge',
            icon: Icons.directions_bus_filled_rounded,
            color: Color(0xFF0369A1),
            route: '/operations/tanker-trip',
            badge: 'TRIP',
            enabled: true,
          ),
        ],
        if (industry == 'cafe_bakery' || industry.isEmpty)
          const _ActionItem(
            title: 'Cafe POS',
            subtitle: 'Order billing',
            icon: Icons.restaurant_rounded,
            color: Color(0xFFD97706),
            route: '/operations/cafe-pos',
            badge: 'POS',
            enabled: true,
          ),
        const _ActionItem(
          title: 'Stock Count',
          subtitle: 'Godown audit',
          icon: Icons.inventory_2_rounded,
          color: Color(0xFF64748B),
          route: '/inventory/stock-count',
          badge: 'AUDIT',
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
            children: [
              Expanded(
                child: Text(
                  'Quick Actions (+ New)',
                  style: AppTypography.section.copyWith(color: titleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
            child: Builder(
              builder: (ctx) {
                final enabledActions = actions.where((a) => a.enabled).toList();
                final cols = MediaQuery.sizeOf(ctx).width >= 620 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: rippleGridTileExtent(
                      ctx,
                      baseHeight: 70,
                      textBudget: 58,
                    ),
                  ),
                  itemCount: enabledActions.length,
                  itemBuilder: (itemCtx, index) {
                    final item = enabledActions[index];
                    return RippleMenuTileCard(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      accentColor: item.color,
                      badge: item.badge,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(item.route);
                      },
                    );
                  },
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
  final String? badge;
  final bool enabled;

  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.badge,
    required this.enabled,
  });
}

