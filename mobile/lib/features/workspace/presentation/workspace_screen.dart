import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/amount_text.dart';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DK Enterprises Group',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${companies.length} Operating Entities',
              style: TextStyle(fontSize: 11, color: mutedCol, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Theme Switcher Toggle (Light / Dark)
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () => themeNotifier.toggleTheme(),
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(minHeight: 2),
              ),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 10),
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

            // 1. Compact 3-Column Financial Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Group Turnover', style: TextStyle(fontSize: 11, color: mutedCol)),
                        const SizedBox(height: 2),
                        AmountText(
                          amount: groupTurnover,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 28, color: borderCol),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cash & Bank', style: TextStyle(fontSize: 11, color: mutedCol)),
                        const SizedBox(height: 2),
                        AmountText(
                          amount: groupCashBank,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 28, color: borderCol),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Receivables', style: TextStyle(fontSize: 11, color: mutedCol)),
                        const SizedBox(height: 2),
                        AmountText(
                          amount: groupReceivables,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Company Workspace',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
                Text(
                  'Tap any card to open',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: mutedCol,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. Compact Company List Cards
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
                return _buildCompactCompanyCard(
                  context: context,
                  company: company,
                  isDark: isDark,
                  cardBg: cardBg,
                  borderCol: borderCol,
                  textCol: textCol,
                  mutedCol: mutedCol,
                );
              }),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCompanyCard({
    required BuildContext context,
    required CompanyInfo company,
    required bool isDark,
    required Color cardBg,
    required Color borderCol,
    required Color textCol,
    required Color mutedCol,
  }) {
    final industry = company.industry ?? '';
    final (badgeLabel, tagline, iconData, brandColor) = switch (industry) {
      'cafe_bakery' => (
          'Bakery & POS',
          'Aran Cafe Touch Terminal & Orders',
          Icons.restaurant_rounded,
          const Color(0xFFD97706),
        ),
      'bulk_water' => (
          'Bulk Tankers',
          'Fleet Logistics & Trip Sheets',
          Icons.local_shipping_rounded,
          const Color(0xFF0284C7),
        ),
      'packaged_water' => (
          '20L Can Routes',
          'Beat Sales & Plant Refill',
          Icons.water_drop_rounded,
          const Color(0xFF059669),
        ),
      'textile' => (
          'Textile & Loom',
          'Fabric Stock & Wholesale Billing',
          Icons.inventory_2_rounded,
          const Color(0xFF7C3AED),
        ),
      _ => (
          'Enterprise',
          'Billing, Invoicing & Ledger',
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectCompany(context, company),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Vertical accent icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: brandColor.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(iconData, color: brandColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Company Title, Badge & Tagline
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
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: brandColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: brandColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tagline,
                        style: TextStyle(fontSize: 12, color: mutedCol),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text('Turnover: ', style: TextStyle(fontSize: 11, color: mutedCol)),
                          AmountText(
                            amount: turnover,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol),
                          ),
                          Text('  •  Cash: ', style: TextStyle(fontSize: 11, color: mutedCol)),
                          AmountText(
                            amount: cashBank,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Chevron Forward Action
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: brandColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
