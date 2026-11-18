import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_models.dart';
import '../../pos/domain/pos_models.dart';
import '../../pos/presentation/pos_notifier.dart';

/// Stitch C-01: Chai & Crema Cafe Counter Home wired to live ERP POS shift & catalog.
class CashierDashboardScreen extends ConsumerStatefulWidget {
  const CashierDashboardScreen({super.key});

  @override
  ConsumerState<CashierDashboardScreen> createState() =>
      _CashierDashboardScreenState();
}

class _CashierDashboardScreenState
    extends ConsumerState<CashierDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(posNotifierProvider.notifier).loadBootstrap());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCompany =
        ref.watch(authNotifierProvider.select((s) => s.activeCompany));
    final posState = ref.watch(posNotifierProvider);
    final shift = posState.activeShift;
    final products = posState.bootstrap?.products ?? const <PosProduct>[];
    final heldCount = posState.bootstrap?.heldOrdersCount ?? 0;
    final lowStockCount = products.where((p) => p.stockQty <= 5).length;

    if (!posState.isLoading &&
        posState.bootstrap != null &&
        activeCompany != null &&
        posState.bootstrap!.companyId != activeCompany.id) {
      Future.microtask(
          () => ref.read(posNotifierProvider.notifier).loadBootstrap());
    }

    final grossSales = shift?.totalSalesAmount ?? 0.0;
    final ordersCount = shift?.ordersCount ?? 0;
    final expectedDrawer = shift?.expectedCash ?? 0.0;
    final floatAmount = shift?.cashInHand ?? 0.0;
    final avgOrder = ordersCount > 0 ? (grossSales / ordersCount) : 0.0;

    final cashTotal = shift?.cashPayment ?? 0.0;
    final digitalTotal = (shift?.upiPayment ?? 0.0) +
        (shift?.cardPayment ?? 0.0) +
        (shift?.bankPayment ?? 0.0);
    final settledSum = cashTotal + digitalTotal;
    final digitalRatio = settledSum > 0 ? (digitalTotal / settledSum) : 0.5;
    final digitalPct =
        settledSum > 0 ? ((digitalTotal / settledSum) * 100).round() : 0;
    final cashPct =
        settledSum > 0 ? ((cashTotal / settledSum) * 100).round() : 0;

    final sortedItems = [...products]..sort((a, b) {
        if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    final topItems = sortedItems.take(5).toList();

    return Scaffold(
      backgroundColor: skin.canvas,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(posNotifierProvider.notifier).loadBootstrap(),
        color: AppColors.chaiPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            if (posState.isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.chaiPrimary,
                  backgroundColor: skin.hairline,
                ),
              ),

            // 0. Active Branch Pill & Admin Branch Switcher (ARAN1 / ARAN2 / Main)
            _buildBranchHeaderRow(skin),
            const SizedBox(height: 10),

            // 1. Operational Shift Strip (Stitch C-01)
            _buildShiftStrip(
              skin: skin,
              shift: shift,
              floatAmount: floatAmount,
            ),
            const SizedBox(height: 12),

            // 2. Hero Card: Gross Counter Billing (#C2542D Terracotta)
            _buildHeroCounterCard(
              skin: skin,
              isDark: isDark,
              grossSales: grossSales,
              ordersCount: ordersCount,
              hasOpenShift: shift != null,
            ),
            const SizedBox(height: 12),

            // 3. 3-Column KPI Bento (ORDERS / DRAWER / AVG ORDER)
            Row(
              children: [
                Expanded(
                  child: _buildBentoTile(
                    skin: skin,
                    icon: Icons.receipt_long_rounded,
                    label: 'ORDERS',
                    subtitle: 'Completed bills',
                    value: '$ordersCount',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBentoTile(
                    skin: skin,
                    icon: Icons.point_of_sale_rounded,
                    label: 'DRAWER',
                    subtitle: 'Expected cash',
                    value: _currency.format(expectedDrawer),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBentoTile(
                    skin: skin,
                    icon: Icons.analytics_outlined,
                    label: 'AVG ORDER',
                    subtitle: 'Avg per bill',
                    value: _currency.format(avgOrder),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Settlement Breakdown Progress Card (UPI/Digital vs Cash)
            _buildSettlementBreakdownCard(
              skin: skin,
              digitalTotal: digitalTotal,
              cashTotal: cashTotal,
              digitalRatio: digitalRatio,
              digitalPct: digitalPct,
              cashPct: cashPct,
            ),
            const SizedBox(height: 14),

            // 5. Primary CTA: Open Touch POS Terminal (#F4A62A Saffron)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () => context.push('/operations/cafe-pos'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.chaiAction,
                  foregroundColor: AppColors.chaiInkLight,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.point_of_sale_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Open Touch POS Terminal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 6. 3-Button Secondary Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    skin: skin,
                    icon: Icons.receipt_outlined,
                    label: 'Standard Sale',
                    onTap: () => context.push('/sales/new'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionTile(
                    skin: skin,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Reconcile Drawer',
                    onTap: () => context.go('/pos/drawer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionTile(
                    skin: skin,
                    icon: Icons.history_rounded,
                    label: 'View All Bills',
                    onTap: () => context.go('/pos/orders'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 7. Alert Chips Row (Open KOTs / Held + Low Stock)
            Row(
              children: [
                Expanded(
                  child: _buildAlertChipCard(
                    skin: skin,
                    icon: Icons.soup_kitchen_outlined,
                    iconBg: AppColors.chaiAction.withValues(alpha: 0.16),
                    iconColor: AppColors.chaiPrimary,
                    title: 'Open KOTs / Held',
                    badgeText: '$heldCount Active',
                    badgeBg: AppColors.chaiAction.withValues(alpha: 0.2),
                    badgeColor: AppColors.chaiPrimary,
                    onTap: () => context.go('/pos/kitchen'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAlertChipCard(
                    skin: skin,
                    icon: Icons.warning_amber_rounded,
                    iconBg: AppColors.rippleRuby.withValues(alpha: 0.12),
                    iconColor: AppColors.rippleRuby,
                    title: 'Low Stock SKUs',
                    badgeText: '$lowStockCount items',
                    badgeBg: AppColors.rippleRuby.withValues(alpha: 0.12),
                    badgeColor: AppColors.rippleRuby,
                    onTap: () => context.go('/pos/kitchen'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 8. Top Counter Items (Live from POS Bootstrap Catalog)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Counter Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: skin.ink,
                    letterSpacing: -0.2,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.chaiPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${products.length} Active SKUs',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.chaiPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (topItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: skin.surface,
                  borderRadius: BorderRadius.circular(skin.cardRadius),
                  border: Border.all(color: skin.hairline),
                ),
                child: Text(
                  'No POS catalog items loaded for this company.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: skin.muted,
                  ),
                ),
              )
            else
              ...topItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: skin.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => context.push('/operations/cafe-pos'),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: skin.hairline),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.chaiAction
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_cafe_rounded,
                                color: AppColors.chaiPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: skin.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SKU ${item.code} · ${_currency.format(item.price)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: skin.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: skin.surface2,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${item.stockQty.toInt()} in stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: skin.ink,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatBranchLabel(BranchInfo? b) {
    if (b == null) return 'Main';
    final code = (b.code ?? '').trim().toUpperCase();
    final name = b.name.trim();
    if (code == 'ARAN1' || name.toUpperCase().contains('ARAN1')) return 'ARAN1 (Shop 1)';
    if (code == 'ARAN2' || name.toUpperCase().contains('ARAN2')) return 'ARAN2 (Shop 2)';
    return code.isNotEmpty ? code : name;
  }

  Widget _buildBranchHeaderRow(RippleSkin skin) {
    final authState = ref.watch(authNotifierProvider);
    final activeCompany = authState.activeCompany;
    final activeBranch = authState.activeBranch;
    final branches = activeCompany?.branches ?? const <BranchInfo>[];
    final isAdmin = ref.watch(activeRippleRoleProvider) == RippleRole.admin;
    final canSwitch = isAdmin && activeCompany != null && branches.length > 1;

    if (canSwitch) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.store_mall_directory_rounded, size: 16, color: AppColors.chaiPrimary),
            const SizedBox(width: 6),
            Text(
              'Branch:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: skin.muted),
            ),
            const SizedBox(width: 8),
            for (final branch in branches) ...[
              ChoiceChip(
                selected: activeBranch?.id == branch.id,
                visualDensity: VisualDensity.compact,
                label: Text(
                  _formatBranchLabel(branch),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                onSelected: (selected) async {
                  if (!selected || activeBranch?.id == branch.id) return;
                  await ref.read(authNotifierProvider.notifier).switchCompany(
                        activeCompany,
                        branch: branch,
                        fy: authState.activeFinancialYear,
                      );
                  await ref.read(posNotifierProvider.notifier).loadBootstrap();
                },
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.chaiPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.chaiPrimary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdmin ? Icons.store_rounded : Icons.lock_outline_rounded,
              size: 13,
              color: AppColors.chaiPrimary,
            ),
            const SizedBox(width: 5),
            Text(
              'Branch: ${_formatBranchLabel(activeBranch)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.chaiPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftStrip({
    required RippleSkin skin,
    required PosShift? shift,
    required double floatAmount,
  }) {
    final isOpen = shift != null && shift.status;
    final dotColor = isOpen ? AppColors.rippleMint : AppColors.rippleHoney;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => context.go('/pos/drawer'),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: skin.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: skin.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOpen
                      ? 'Shift open${shift.openedAt != null ? ' · ${shift.openedAt}' : ''}'
                      : 'Shift closed · Tap to open float',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: skin.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: skin.surface2,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Float ${_currency.format(floatAmount)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: skin.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCounterCard({
    required RippleSkin skin,
    required bool isDark,
    required double grossSales,
    required int ordersCount,
    required bool hasOpenShift,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.chaiPrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.chaiPrimary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: IgnorePointer(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GROSS COUNTER BILLING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFFFBF4EA).withValues(alpha: 0.85),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lagoonAction,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          size: 13,
                          color: AppColors.chaiInkLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasOpenShift ? '$ordersCount Bills' : 'Shift Closed',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.chaiInkLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _currency.format(grossSales),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFBF4EA),
                  letterSpacing: -0.8,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoTile({
    required RippleSkin skin,
    required IconData icon,
    required String label,
    required String subtitle,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.chaiPrimary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: skin.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: skin.muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: skin.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementBreakdownCard({
    required RippleSkin skin,
    required double digitalTotal,
    required double cashTotal,
    required double digitalRatio,
    required int digitalPct,
    required int cashPct,
  }) {
    final clampedRatio = digitalRatio.clamp(0.0, 1.0);
    final digitalFlex = (clampedRatio * 100).round().clamp(1, 99);
    final cashFlex = (100 - digitalFlex).clamp(1, 99);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SETTLEMENT BREAKDOWN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: skin.ink,
                ),
              ),
              Text(
                'Live sync',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: skin.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: digitalFlex,
                    child: Container(color: AppColors.chaiAction),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: cashFlex,
                    child: Container(color: AppColors.chaiPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.chaiAction,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DIGITAL / UPI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: skin.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_currency.format(digitalTotal)} ($digitalPct%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: skin.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.chaiPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'CASH IN HAND',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: skin.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_currency.format(cashTotal)} ($cashPct%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: skin.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required RippleSkin skin,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: skin.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: skin.hairline),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.chaiPrimary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: skin.ink,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertChipCard({
    required RippleSkin skin,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: skin.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: skin.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: skin.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
