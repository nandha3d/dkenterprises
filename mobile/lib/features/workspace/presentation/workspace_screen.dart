import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';
import '../../../core/ui/kpi_card.dart';
import '../../auth/domain/auth_models.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _workspaceData;

  @override
  void initState() {
    super.initState();
    _loadWorkspaceData();
  }

  Future<void> _loadWorkspaceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiClient = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    const cacheKey = 'group_workspace_insights';

    // 1. Check local cache first
    try {
      final cached = await db.getCache(cacheKey).timeout(const Duration(milliseconds: 500));
      if (cached != null && cached is Map<String, dynamic> && mounted) {
        setState(() {
          _workspaceData = cached;
          _isLoading = false;
        });
      }
    } catch (_) {}

    // 2. Fetch live multi-company insights
    try {
      final result = await apiClient.get(
        ApiEndpoints.workspace,
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
            _workspaceData = liveData;
            _errorMessage = null;
          });
        }
      } else {
        if (_workspaceData == null && mounted) {
          setState(() {
            _errorMessage = result.failureOrNull?.message ?? 'Failed to load group insights';
          });
        }
      }
    } catch (e) {
      if (_workspaceData == null && mounted) {
        setState(() {
          _errorMessage = 'Network timeout. Pull down to refresh.';
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

  Future<void> _selectCompany(BuildContext context, CompanyInfo company) async {
    await ref.read(authNotifierProvider.notifier).switchCompany(company);
    if (context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedCol = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final summary = _workspaceData?['summary'] as Map<String, dynamic>?;
    final groupTurnover = summary?['total_turnover'] as num? ?? 0;
    final groupCashBank = summary?['total_cash_and_bank'] as num? ?? 0;
    final groupReceivables = summary?['total_receivables'] as num? ?? 0;

    final companies = authState.companies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Workspace & Entities'),
        actions: [
          // Theme Switcher Toggle (Light / Dark)
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () => themeNotifier.toggleTheme(),
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWorkspaceData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),

            if (_errorMessage != null)
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
                      onPressed: _loadWorkspaceData,
                      child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Top Welcome Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderCol, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.primaryDark : AppColors.primary).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.domain_rounded,
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DK Enterprises Group',
                          style: AppTypography.title.copyWith(color: textCol, fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select an entity to enter its dedicated vertical workspace',
                          style: AppTypography.caption.copyWith(color: mutedCol),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Section 1: Consolidated Multi-Company Group Overview
            Text(
              'Consolidated Group Overview',
              style: AppTypography.section.copyWith(color: textCol),
            ),
            const SizedBox(height: 10),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                KpiCard(
                  title: 'Group Sales Turnover',
                  amount: _isLoading && _workspaceData == null ? null : groupTurnover,
                  customValue: _isLoading && _workspaceData == null ? '...' : null,
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.success,
                  subtitle: 'Combined turnover',
                ),
                KpiCard(
                  title: 'Group Cash & Bank',
                  amount: _isLoading && _workspaceData == null ? null : groupCashBank,
                  customValue: _isLoading && _workspaceData == null ? '...' : null,
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.primary,
                  subtitle: 'Liquid balances',
                ),
                KpiCard(
                  title: 'Total Receivables',
                  amount: _isLoading && _workspaceData == null ? null : groupReceivables,
                  customValue: _isLoading && _workspaceData == null ? '...' : null,
                  icon: Icons.call_received_rounded,
                  iconColor: AppColors.warning,
                  subtitle: 'Customer dues',
                ),
                KpiCard(
                  title: 'Operating Entities',
                  amount: null,
                  customValue: '${companies.length} Companies',
                  icon: Icons.storefront_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  subtitle: 'Distinct verticals',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 2: Dedicated Vertical Companies
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Company Workspace',
                  style: AppTypography.section.copyWith(color: textCol),
                ),
                Text(
                  'Strict Isolation',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (companies.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No companies assigned to your profile.',
                    style: TextStyle(color: mutedCol),
                  ),
                ),
              )
            else
              ...companies.map((company) {
                return _buildCompanyCard(
                  context: context,
                  company: company,
                  isDark: isDark,
                  cardBg: cardBg,
                  borderCol: borderCol,
                  textCol: textCol,
                  mutedCol: mutedCol,
                );
              }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCard({
    required BuildContext context,
    required CompanyInfo company,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color mutedCol,
  }) {
    // Resolve vertical presentation metadata
    final industry = company.industry ?? '';
    final (badgeLabel, tagline, iconData, brandColor) = switch (industry) {
      'cafe_bakery' => (
          'Bakery & Cafe Operations',
          'Touch POS Terminal, Daily Cash Drawer & Kitchen Orders',
          Icons.restaurant_rounded,
          const Color(0xFFD97706),
        ),
      'bulk_water' => (
          'Commercial Bulk Water Logistics',
          'Tanker Fleet, Trip Sheets & Waiting Surcharges',
          Icons.local_shipping_rounded,
          const Color(0xFF0284C7),
        ),
      'packaged_water' => (
          '20L Packaged Water Distribution',
          'Can Route Beat, Empty Jars & Driver Surrenders',
          Icons.water_drop_rounded,
          const Color(0xFF059669),
        ),
      'textile' => (
          'Textile & Garment Manufacturing',
          'Fabric Stock, Job Work Orders & Wholesale Billing',
          Icons.inventory_2_rounded,
          const Color(0xFF7C3AED),
        ),
      _ => (
          'Commercial Business Enterprise',
          'Billing, Invoicing, Inventory & General Ledger',
          Icons.business_rounded,
          AppColors.primary,
        ),
    };

    // Find company specific metrics if available in workspace data
    final compDataList = (_workspaceData?['companies'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? matchData;
    for (final item in compDataList) {
      if (item is Map<String, dynamic> && item['id'] == company.id) {
        matchData = item;
        break;
      }
    }

    final turnover = matchData?['metrics']?['sales_turnover'] as num? ?? 0;
    final cashBank = matchData?['metrics']?['cash_and_bank'] as num? ?? 0;
    final dues = matchData?['metrics']?['receivables'] as num? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Vertical Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(bottom: BorderSide(color: borderCol, width: 0.8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: brandColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              company.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: brandColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              company.code ?? 'CORP',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: brandColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tagline description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Text(
              tagline,
              style: TextStyle(fontSize: 13, color: mutedCol),
            ),
          ),

          // Mini metrics strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Turnover', style: TextStyle(fontSize: 11, color: mutedCol)),
                        const SizedBox(height: 2),
                        AmountText(
                          amount: turnover,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: borderCol),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cash & Bank', style: TextStyle(fontSize: 11, color: mutedCol)),
                        const SizedBox(height: 2),
                        AmountText(
                          amount: cashBank,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: borderCol),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Receivables', style: TextStyle(fontSize: 11, color: mutedCol)),
                        const SizedBox(height: 2),
                        AmountText(
                          amount: dues,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Button to Enter Company Workspace
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _selectCompany(context, company),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text('Open ${company.name} Workspace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
