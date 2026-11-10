import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/amount_text.dart';
import '../../../core/ui/kpi_card.dart';

class CashierDashboardScreen extends ConsumerStatefulWidget {
  const CashierDashboardScreen({super.key});

  @override
  ConsumerState<CashierDashboardScreen> createState() => _CashierDashboardScreenState();
}

class _CashierDashboardScreenState extends ConsumerState<CashierDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCashierData();
  }

  Future<void> _loadCashierData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiClient = ref.read(apiClientProvider);
    final res = await apiClient.get(
      '/mobile/dashboard/cashier',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (mounted) {
      if (res.isSuccess) {
        final raw = res.dataOrNull ?? <String, dynamic>{};
        final data = raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : (raw['data'] is Map ? Map<String, dynamic>.from(raw['data'] as Map) : raw);
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.failureOrNull?.message ?? 'Failed to load cashier dashboard insights';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(syncWorkerProvider.select((w) => w.state.pendingCount), (previous, next) {
      if (previous != null && next < previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadCashierData();
        });
      }
    });

    ref.listen<int>(dashboardRefreshSignalProvider, (previous, next) {
      if (previous != null && next != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadCashierData();
        });
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final data = _dashboardData ?? <String, dynamic>{};
    final counterName = data['counter_name']?.toString() ?? 'Main Cafe & Kitchen POS Terminal';
    final companyName = data['company_name']?.toString() ?? 'Aran Cafe';
    final drawerStatus = data['drawer_status']?.toString() ?? 'OPEN';
    final drawerOpenedAt = data['drawer_opened_at']?.toString() ?? '07:30 AM';

    final summary = data['summary'] is Map ? Map<String, dynamic>.from(data['summary'] as Map) : <String, dynamic>{};
    final todaySales = (summary['today_sales'] as num?)?.toDouble() ?? 0.0;
    final todayOrders = (summary['today_orders'] as num?)?.toInt() ?? 0;
    final cashInDrawer = (summary['cash_in_drawer'] as num?)?.toDouble() ?? 0.0;
    final digitalCollections = (summary['digital_collections'] as num?)?.toDouble() ?? 0.0;
    final aov = (summary['average_order_value'] as num?)?.toDouble() ?? 0.0;
    final pendingKot = (summary['pending_kitchen_orders'] as num?)?.toInt() ?? 0;

    final recentOrdersRaw = data['recent_orders'] as List<dynamic>? ?? [];
    final recentOrders = recentOrdersRaw.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();

    return Scaffold(
      backgroundColor: bgCol,
      body: RefreshIndicator(
        onRefresh: _loadCashierData,
        child: _isLoading && _dashboardData == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage ?? 'An error occurred',
                              style: const TextStyle(color: AppColors.danger, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: _loadCashierData,
                          ),
                        ],
                      ),
                    ),

                  // Header Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFFD97706), const Color(0xFFB45309)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$companyName Cashier Desk',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    counterName,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: drawerStatus == 'OPEN' ? const Color(0xFF10B981) : Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'DRAWER $drawerStatus',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Shift opened: $drawerOpenedAt',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.table_restaurant_rounded, color: Colors.white70, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$pendingKot Kitchen KOT Active',
                                    style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4 Operational KPI Cards
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.45,
                    children: [
                      KpiCard(
                        title: "Today's Sales",
                        amount: todaySales,
                        icon: Icons.currency_rupee_rounded,
                        iconColor: AppColors.primary,
                        subtitle: 'Gross counter billing',
                        onTap: () => context.push('/sales'),
                      ),
                      KpiCard(
                        title: 'Orders Billed',
                        customValue: '$todayOrders Bills',
                        icon: Icons.receipt_long_rounded,
                        iconColor: const Color(0xFFD97706),
                        subtitle: 'Completed tickets',
                        onTap: () => context.push('/sales'),
                      ),
                      KpiCard(
                        title: 'Cash in Drawer',
                        amount: cashInDrawer,
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: AppColors.success,
                        subtitle: 'Physical drawer cash',
                        onTap: () => context.push('/accounting/books'),
                      ),
                      KpiCard(
                        title: 'Average Order Value',
                        amount: aov,
                        icon: Icons.trending_up_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        subtitle: 'Average per bill',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Secondary Collections Breakdown Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderCol),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DIGITAL / UPI COLLECTIONS', style: TextStyle(color: textSec, fontSize: 10, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            AmountText(amount: digitalCollections),
                          ],
                        ),
                        Container(height: 32, width: 1, color: borderCol),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CASH COLLECTIONS', style: TextStyle(color: textSec, fontSize: 10, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            AmountText(amount: cashInDrawer),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Express POS Launcher
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Express Order Billing',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrim),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Launch the high-speed touch POS terminal for dining, takeaway, and delivery orders.',
                          style: TextStyle(fontSize: 12, color: textSec),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/cafe/pos'),
                          icon: const Icon(Icons.touch_app_rounded, size: 22),
                          label: const Text('Open Touch POS Terminal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/sales/new'),
                          icon: const Icon(Icons.receipt_long_rounded, size: 18),
                          label: const Text('Standard Sale Invoice'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrim,
                            side: BorderSide(color: borderCol),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cash Drawer Reconciliation Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Cash Drawer Reconciliation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrim),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Count physical drawer cash denominations and record end-of-shift handover.',
                          style: TextStyle(fontSize: 12, color: textSec),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/accounting/books'),
                          icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                          label: const Text('Reconcile & Handover Drawer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recent Shift Orders
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Shift Bills (${recentOrders.length})',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrim),
                      ),
                      TextButton(
                        onPressed: () => context.push('/sales'),
                        child: const Text('View All Bills', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (recentOrders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol),
                      ),
                      child: Center(
                        child: Text(
                          'No bills generated yet for this shift',
                          style: TextStyle(color: textSec, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...recentOrders.map((order) {
                      final refNo = order['reference_no']?.toString() ?? '#SALE-000';
                      final grandTotal = (order['grand_total'] as num?)?.toDouble() ?? 0.0;
                      final createdAt = order['created_at']?.toString() ?? '';
                      final isPaid = (order['payment_status'] == 4 || order['payment_status'] == 'paid');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isPaid ? AppColors.success : AppColors.warning).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                                    size: 18,
                                    color: isPaid ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      refNo,
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPrim),
                                    ),
                                    Text(
                                      createdAt.length >= 16 ? createdAt.substring(11, 16) : createdAt,
                                      style: TextStyle(color: textSec, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AmountText(amount: grandTotal),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isPaid ? AppColors.success : AppColors.warning).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isPaid ? 'PAID' : 'PENDING',
                                    style: TextStyle(
                                      color: isPaid ? AppColors.success : AppColors.warning,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
