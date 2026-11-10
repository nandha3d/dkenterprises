import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
    _loadWorkspaceData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        final rawData = result.dataOrNull ?? <String, dynamic>{};
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
            Text(
              'DK Enterprises Group',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${companies.length} Operating Entities • Multi-Tenant Workspace',
              style: GoogleFonts.inter(fontSize: 11, color: mutedCol, fontWeight: FontWeight.normal),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _loadWorkspaceData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
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
                            _errorMessage ?? 'An error occurred',
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

                // 1. Group Consolidated Financial Summary Ribbon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group Turnover',
                              style: GoogleFonts.inter(fontSize: 11, color: mutedCol, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            AmountText(
                              amount: groupTurnover,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: textCol),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: borderCol),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash & Bank',
                              style: GoogleFonts.inter(fontSize: 11, color: mutedCol, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            AmountText(
                              amount: groupCashBank,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: borderCol),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receivables',
                              style: GoogleFonts.inter(fontSize: 11, color: mutedCol, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 3),
                            AmountText(
                              amount: groupReceivables,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.warning),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Section Header with Navigation Hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.dashboard_customize_rounded, size: 16, color: Color(0xFF6366F1)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Company Workspaces',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: textCol,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Square Cards & Insights',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: mutedCol,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Responsive Layout: Swipeable Carousel on Mobile, Multi-Column Square Grid on Tablet/Desktop
                if (companies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No companies assigned to your profile.',
                        style: TextStyle(color: mutedCol),
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isTabletOrDesktop = constraints.maxWidth >= 680;

                      if (isTabletOrDesktop) {
                        // Tablet/Desktop: 3-column square cards grid
                        final crossAxisCount = constraints.maxWidth >= 950 ? 3 : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.80,
                          ),
                          itemCount: companies.length,
                          itemBuilder: (context, index) {
                            return _buildSquareCompanyCard(
                              context: context,
                              company: companies[index],
                              isDark: isDark,
                              textCol: textCol,
                              mutedCol: mutedCol,
                            );
                          },
                        );
                      } else {
                        // Mobile: Modern Swipeable PageView Carousel with Indicator Dots & Arrows
                        return Column(
                          children: [
                            SizedBox(
                              height: 410,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: companies.length,
                                onPageChanged: (index) {
                                  setState(() => _currentPage = index);
                                },
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: _buildSquareCompanyCard(
                                      context: context,
                                      company: companies[index],
                                      isDark: isDark,
                                      textCol: textCol,
                                      mutedCol: mutedCol,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Modern Navigation Bar with Dot Indicators & Swipe Arrows
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                                  onPressed: _currentPage > 0
                                      ? () {
                                          _pageController.previousPage(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      : null,
                                  color: textCol,
                                  tooltip: 'Previous Company',
                                ),
                                const SizedBox(width: 8),
                                ...List.generate(companies.length, (index) {
                                  final isActive = index == _currentPage;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    height: 8,
                                    width: isActive ? 24 : 8,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFF6366F1)
                                          : (isDark ? Colors.white24 : Colors.black12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                  onPressed: _currentPage < companies.length - 1
                                      ? () {
                                          _pageController.nextPage(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        }
                                      : null,
                                  color: textCol,
                                  tooltip: 'Next Company',
                                ),
                              ],
                            ),
                            Text(
                              'Swipe left or right to switch entities (${_currentPage + 1} of ${companies.length})',
                              style: GoogleFonts.inter(fontSize: 11, color: mutedCol, fontWeight: FontWeight.w500),
                            ),
                          ],
                        );
                      }
                    },
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSquareCompanyCard({
    required BuildContext context,
    required CompanyInfo company,
    required bool isDark,
    required Color textCol,
    required Color mutedCol,
  }) {
    final industry = company.industry ?? '';

    // Color Theme, Icons, and Operational Profile
    final (
      badgeLabel,
      iconData,
      primaryColor,
      gradientColors,
      cartInsightTitle,
      cartInsightValue,
      opFeature1,
      opFeature2,
    ) = switch (industry) {
      'cafe_bakery' => (
          'Bakery & POS',
          Icons.restaurant_rounded,
          const Color(0xFFD97706),
          isDark
              ? [const Color(0xFF78350F).withOpacity(0.4), const Color(0xFF1E1610)]
              : [const Color(0xFFFEF3C7), Colors.white],
          'POS Carts & Counter Bills',
          'Touch Billing Active',
          'Kitchen Display & Dining Orders',
          'Instant KOT & Table Checkout',
        ),
      'bulk_water' => (
          'Bulk Tankers (16-40 KL)',
          Icons.fire_truck_rounded,
          const Color(0xFF2563EB),
          isDark
              ? [const Color(0xFF1E3A8A).withOpacity(0.4), const Color(0xFF0F172A)]
              : [const Color(0xFFDBEAFE), Colors.white],
          'Fleet Logistics & Decanting',
          'Anti-Siphon Gate Active',
          'Heavy Borewell Tanker Trips',
          'Live Decanting Flow Telemetry',
        ),
      'packaged_water' => (
          'Packaged Water (20L Cans)',
          Icons.water_drop_rounded,
          const Color(0xFF0284C7),
          isDark
              ? [const Color(0xFF075985).withOpacity(0.4), const Color(0xFF082F49).withOpacity(0.6)]
              : [const Color(0xFFE0F2FE), Colors.white],
          'Tata Ace Beat Routes',
          'Daily Can Custody & Deposits',
          '60-84 Can Van Distribution',
          'Empty Jar Balance & Surrender',
        ),
      'textile' => (
          'Textile & Fabric Loom',
          Icons.inventory_2_rounded,
          const Color(0xFF7C3AED),
          isDark
              ? [const Color(0xFF5B21B6).withOpacity(0.4), const Color(0xFF1E1B4B)]
              : [const Color(0xFFEDE9FE), Colors.white],
          'Bale & Yard Inventory',
          'Wholesale DC & Loom Rolls',
          'Fabric Quality & Shade Grading',
          'GST E-Way Bill & Challan',
        ),
      _ => (
          'Enterprise Workspace',
          Icons.business_rounded,
          const Color(0xFF6366F1),
          isDark
              ? [const Color(0xFF3730A3).withOpacity(0.4), const Color(0xFF0F172A)]
              : [const Color(0xFFEEF2FF), Colors.white],
          'General Operations',
          'Multi-Branch Consolidated',
          'Standard Sales & Expenses',
          'Double-Entry Audit Ledger',
        ),
    };

    // Find company specific metrics if available in workspace data
    final compDataList = (_workspaceData?['companies'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? matchData;
    for (final item in compDataList) {
      if (item is Map && (item['id'] == company.id || item['id']?.toString() == company.id.toString())) {
        matchData = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item);
        break;
      }
    }

    final metrics = matchData?['metrics'] is Map
        ? matchData!['metrics'] as Map
        : <String, dynamic>{};
    final turnover = metrics['sales_turnover'] as num? ?? 0;
    final cashBank = metrics['cash_and_bank'] as num? ?? 0;
    final receivables = metrics['receivables'] as num? ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(isDark ? 0.4 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectCompany(context, company),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Icon + Badge + Company Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryColor.withOpacity(0.4)),
                      ),
                      child: Icon(iconData, color: primaryColor, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textCol,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. Financial Metrics HUD (Turnover, Cash & Bank, Receivables)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A).withOpacity(0.7) : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Turnover', style: TextStyle(fontSize: 10, color: mutedCol)),
                            const SizedBox(height: 2),
                            AmountText(
                              amount: turnover,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 24, color: mutedCol.withOpacity(0.3)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cash & Bank', style: TextStyle(fontSize: 10, color: mutedCol)),
                            const SizedBox(height: 2),
                            AmountText(
                              amount: cashBank,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 24, color: mutedCol.withOpacity(0.3)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Receivables', style: TextStyle(fontSize: 10, color: mutedCol)),
                            const SizedBox(height: 2),
                            AmountText(
                              amount: receivables,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Operational Carts & Vertical Insights Block
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(isDark ? 0.08 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.18)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insights_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cartInsightTitle,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cartInsightValue,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.success),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              opFeature1,
                              style: GoogleFonts.inter(fontSize: 11, color: textCol),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.success),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              opFeature2,
                              style: GoogleFonts.inter(fontSize: 11, color: textCol),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 4. Action Button: "Enter Workspace"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectCompany(context, company),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Open Workspace',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
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
