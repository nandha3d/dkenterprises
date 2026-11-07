import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/ui/kpi_card.dart';

class ExecutiveDashboardScreen extends ConsumerStatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  ConsumerState<ExecutiveDashboardScreen> createState() => _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState extends ConsumerState<ExecutiveDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _financials;
  DateTime? _lastRefreshedAt;
  bool _isFromCache = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiClient = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final authState = ref.read(authNotifierProvider);
    final companyId = authState.activeCompany?.id ?? 0;
    final cacheKey = 'financials_company_$companyId';

    // 1. Check offline cache first
    try {
      final cached = await db.getCache(cacheKey).timeout(const Duration(milliseconds: 500));
      final cacheTime = await db.getCacheTimestamp(cacheKey).timeout(const Duration(milliseconds: 500));
      if (cached != null && cached is Map<String, dynamic> && mounted) {
        setState(() {
          _financials = cached;
          _lastRefreshedAt = cacheTime;
          _isFromCache = true;
          _isLoading = false; // Immediately paint cached snapshot!
        });
      }
    } catch (_) {
      // Continue to live fetch
    }

    // 2. Attempt live server fetch with safe timeout
    try {
      final result = await apiClient.get(
        ApiEndpoints.financials,
        fromJson: (data) => data as Map<String, dynamic>,
      ).timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (result.isSuccess) {
        final rawData = result.dataOrNull!;
        final liveData = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : (rawData['data'] is Map ? Map<String, dynamic>.from(rawData['data'] as Map) : rawData);
        await db.saveCache(cacheKey, liveData);
        if (mounted) {
          setState(() {
            _financials = liveData;
            _isFromCache = false;
            _lastRefreshedAt = DateTime.now();
          });
        }
      } else {
        if (_financials == null && mounted) {
          setState(() {
            _errorMessage = result.failureOrNull?.message ?? 'Failed to load live data';
          });
        }
      }
    } catch (e) {
      if (_financials == null && mounted) {
        setState(() {
          _errorMessage = 'Connection timeout. Pull down to refresh.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedCol = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final industry = authState.activeCompany?.industry ?? '';

    final cashBalance = _financials?['cash_balance'] as num? ??
        _financials?['cash_in_hand_1010'] as num? ?? 0;
    final bankBalance = _financials?['bank_balance'] as num? ??
        _financials?['bank_account_1020'] as num? ?? 0;
    final receivables = _financials?['receivables'] as num? ??
        _financials?['accounts_receivable_1030'] as num? ?? 0;
    final payables = _financials?['payables'] as num? ?? 0;
    final todayCollections = _financials?['collections_today'] as num? ??
        _financials?['today_collections'] as num? ?? 0;

    final isInitialLoading = _isLoading && _financials == null;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),

          // Error Banner if network failed and no cache
          if (_errorMessage != null && !isInitialLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadDashboardData,
                    child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          // Live Server / Cached Status Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isFromCache
                      ? (isDark ? AppColors.chipWarningBgDark : AppColors.chipWarningBgLight)
                      : (isDark ? AppColors.chipSuccessBgDark : AppColors.chipSuccessBgLight),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isFromCache ? AppColors.warning : AppColors.success,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFromCache ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                      size: 14,
                      color: _isFromCache ? AppColors.warning : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isFromCache ? 'Cached Snapshot' : 'Live Ledger Server',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isFromCache ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              if (_lastRefreshedAt != null)
                Text(
                  'Updated: ${DateFormat('hh:mm a').format(_lastRefreshedAt!)}',
                  style: AppTypography.caption.copyWith(color: mutedCol, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // User Greeting Strip
          Text(
            'Hello, ${authState.user?.name.isNotEmpty == true ? authState.user!.name : "Executive"}',
            style: AppTypography.title.copyWith(color: textCol),
          ),
          const SizedBox(height: 2),
          Text(
            'Role: ${authState.user?.role.toUpperCase() ?? "STAFF"} • ${authState.activeCompany?.name ?? ""}',
            style: AppTypography.caption.copyWith(color: mutedCol),
          ),
          const SizedBox(height: 18),

          // 2x2 Core Financial KPIs Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              KpiCard(
                title: 'Cash in Hand (1010)',
                amount: isInitialLoading ? null : cashBalance,
                customValue: isInitialLoading ? '...' : null,
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.success,
                onTap: () => context.push('/accounting/books'),
              ),
              KpiCard(
                title: 'Bank Balances (1020)',
                amount: isInitialLoading ? null : bankBalance,
                customValue: isInitialLoading ? '...' : null,
                icon: Icons.account_balance_rounded,
                iconColor: AppColors.primary,
                onTap: () => context.push('/accounting/books'),
              ),
              KpiCard(
                title: 'Receivables (1030)',
                amount: isInitialLoading ? null : receivables,
                customValue: isInitialLoading ? '...' : null,
                icon: Icons.call_received_rounded,
                iconColor: AppColors.warning,
                subtitle: 'Customer Dues',
                onTap: () => context.push('/accounting/collect'),
              ),
              KpiCard(
                title: 'Payables (2010)',
                amount: isInitialLoading ? null : payables,
                customValue: isInitialLoading ? '...' : null,
                icon: Icons.call_made_rounded,
                iconColor: AppColors.danger,
                subtitle: 'Supplier Dues',
                onTap: () => context.push('/purchases'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Today's Collections Strip
          KpiCard(
            title: "Today's Verified Collections",
            amount: isInitialLoading ? null : todayCollections,
            customValue: isInitialLoading ? '...' : null,
            icon: Icons.verified_rounded,
            iconColor: AppColors.success,
            subtitle: 'Direct journal entries posted to ledger',
            onTap: () => context.push('/accounting/collect'),
          ),
          const SizedBox(height: 20),

          // Vertical Operational Command
          Text(
            'Operational Workflows',
            style: AppTypography.section.copyWith(color: textCol),
          ),
          const SizedBox(height: 10),

          if (industry == 'packaged_water' || industry.isEmpty) ...[
            _buildWorkflowActionCard(
              context: context,
              title: '20L Can Distribution Beat',
              description: 'Ticket Machine, Spot Empty Audit & Plant Refill',
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF0284C7),
              onTap: () => context.push('/operations/can-sales'),
            ),
            const SizedBox(height: 10),
          ],

          if (industry == 'bulk_water' || industry.isEmpty) ...[
            _buildWorkflowActionCard(
              context: context,
              title: 'Bulk Tanker Fleet Operations',
              description: 'Trip sheets, motor pumping & waiting surcharges',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF0369A1),
              onTap: () => context.push('/operations/tanker-trip'),
            ),
            const SizedBox(height: 10),
          ],

          if (industry == 'cafe_bakery' || industry.isEmpty) ...[
            _buildWorkflowActionCard(
              context: context,
              title: 'Aran Cafe POS Terminal',
              description: 'Touch order billing & cash drawer closing',
              icon: Icons.restaurant_rounded,
              color: const Color(0xFFD97706),
              onTap: () => context.push('/operations/cafe-pos'),
            ),
            const SizedBox(height: 10),
          ],

          _buildWorkflowActionCard(
            context: context,
            title: 'Physical Stock Count',
            description: 'Barcode scan, godown inventory reconciliation',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF059669),
            onTap: () => context.push('/inventory/stock-count'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWorkflowActionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedCol = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label.copyWith(color: textCol),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(color: mutedCol),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: mutedCol),
          ],
        ),
      ),
    );
  }
}

