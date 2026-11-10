import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/kpi_card.dart';
import '../../../core/ui/sales_performance_card.dart';
import '../../../core/ui/ledger_transactions_section.dart';
import '../../auth/domain/auth_models.dart';
import 'tanker_driver_dashboard_screen.dart';
import 'can_delivery_driver_dashboard_screen.dart';
import 'cashier_dashboard_screen.dart';
import 'field_agent_dashboard_screen.dart';

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

  // Active filter states for dynamic Sales & Ledger queries
  String _salesPeriod = 'this_month'; // Default: Monthly Sales
  DateTime? _salesStartDate;
  DateTime? _salesEndDate;

  String _ledgerPeriod = 'today'; // Default: Today
  DateTime? _ledgerStartDate;
  DateTime? _ledgerEndDate;

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
    final cacheKey = 'financials_comp_${companyId}_s_${_salesPeriod}_l_$_ledgerPeriod';

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

    // 2. Prepare query parameters for dynamic backend computation
    final queryParams = <String, dynamic>{
      'sales_period': _salesPeriod,
      'ledger_period': _ledgerPeriod,
    };
    if (_salesStartDate != null) {
      queryParams['sales_start_date'] = DateFormat('yyyy-MM-dd').format(_salesStartDate!);
    }
    if (_salesEndDate != null) {
      queryParams['sales_end_date'] = DateFormat('yyyy-MM-dd').format(_salesEndDate!);
    }
    if (_ledgerStartDate != null) {
      queryParams['ledger_start_date'] = DateFormat('yyyy-MM-dd').format(_ledgerStartDate!);
    }
    if (_ledgerEndDate != null) {
      queryParams['ledger_end_date'] = DateFormat('yyyy-MM-dd').format(_ledgerEndDate!);
    }

    // 3. Attempt live server fetch with safe timeout
    try {
      final result = await apiClient.get(
        ApiEndpoints.financials,
        queryParameters: queryParams,
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
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.activeCompany?.id != next.activeCompany?.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadDashboardData();
          }
        });
      }
    });

    // Auto-refresh when offline outbox mutations are drained to the server
    ref.listen<int>(syncWorkerProvider.select((w) => w.state.pendingCount), (previous, next) {
      if (previous != null && next < previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadDashboardData();
          }
        });
      }
    });

    // Auto-refresh when an operational action signals new transactions
    ref.listen<int>(dashboardRefreshSignalProvider, (previous, next) {
      if (previous != null && next != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadDashboardData();
          }
        });
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final userRole = (authState.user?.role ?? '').toLowerCase();
    final userName = (authState.user?.username ?? authState.user?.name ?? '').toLowerCase();
    final userEmail = (authState.user?.email ?? '').toLowerCase();
    final allRoles = authState.roles.map((r) => r.toLowerCase()).toList();

    bool hasKeyword(String kw) {
      return userRole.contains(kw) ||
             userName.contains(kw) ||
             userEmail.contains(kw) ||
             allRoles.any((r) => r.contains(kw));
    }

    // Role-based executive redirect guard: Never show balance sheets to field crew
    if (hasKeyword('tanker')) {
      return const TankerDriverDashboardScreen();
    } else if (hasKeyword('delivery') || hasKeyword('driver')) {
      return const CanDeliveryDriverDashboardScreen();
    } else if (hasKeyword('cashier')) {
      return const CashierDashboardScreen();
    } else if (hasKeyword('agent') || hasKeyword('field')) {
      return const FieldAgentDashboardScreen();
    }
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

    // Dynamic Sales Performance
    final salesAmount = _financials?['sales_amount'] as num? ?? 0;
    final salesToday = _financials?['sales_today'] as num? ?? 0;
    final salesCount = (_financials?['sales_count'] as num?)?.toInt() ?? 0;
    final salesPeriodLabel = _financials?['sales_period_label'] as String? ?? 'This Month (Default)';

    final salesTrendRaw = _financials?['sales_trend'] as List<dynamic>? ?? [];
    final salesTrend = salesTrendRaw.map<num>((e) {
      if (e is Map) return (e['amount'] as num? ?? 0);
      if (e is num) return e;
      return 0;
    }).toList();

    // Core Financial Sparkline Trajectories
    final cashTrend = (_financials?['cash_trend'] as List<dynamic>?)
            ?.map<num>((e) => e as num)
            .toList() ??
        [];
    final bankTrend = (_financials?['bank_trend'] as List<dynamic>?)
            ?.map<num>((e) => e as num)
            .toList() ??
        [];
    final receivablesTrend = (_financials?['receivables_trend'] as List<dynamic>?)
            ?.map<num>((e) => e as num)
            .toList() ??
        [];
    final payablesTrend = (_financials?['payables_trend'] as List<dynamic>?)
            ?.map<num>((e) => e as num)
            .toList() ??
        [];

    // Live Accounting Ledger Postings
    final ledgerEntries = _financials?['ledger_entries'] as List<dynamic>? ??
        _financials?['recent_transactions'] as List<dynamic>? ??
        [];
    final ledgerPeriodLabel =
        _financials?['ledger_period_label'] as String? ?? 'Today (Default)';

    final isInitialLoading = _isLoading && _financials == null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: RefreshIndicator(
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
                      _errorMessage ?? 'An error occurred',
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
            'Hello, ${authState.user?.name.isNotEmpty == true ? (authState.user?.name ?? "Executive") : "Executive"}',
            style: AppTypography.title.copyWith(color: textCol),
          ),
          const SizedBox(height: 2),
          Text(
            'Role: ${authState.user?.role.toUpperCase() ?? "STAFF"} • ${authState.activeCompany?.name ?? ""}',
            style: AppTypography.caption.copyWith(color: mutedCol),
          ),
          const SizedBox(height: 18),

          // High-Impact Sales Performance Card with Default Monthly Sales & Instant Range Filters
          SalesPerformanceCard(
            salesAmount: salesAmount,
            todaySalesAmount: salesToday,
            salesCount: salesCount,
            activePeriod: _salesPeriod,
            activePeriodLabel: salesPeriodLabel,
            trendPoints: salesTrend,
            verticalIndustry: industry,
            onPeriodSelected: (period, {startDate, endDate}) {
              setState(() {
                _salesPeriod = period;
                _salesStartDate = startDate;
                _salesEndDate = endDate;
              });
              _loadDashboardData();
            },
          ),
          const SizedBox(height: 16),

          // Responsive Core Financial KPIs Grid (Compact with Graphical Sparklines & Separate GL Codes)
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 720;
              return GridView.count(
                crossAxisCount: isTablet ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isTablet ? 1.35 : 1.25,
                children: [
                  KpiCard(
                    title: 'Cash in Hand',
                    glCode: '1010',
                    amount: isInitialLoading ? null : cashBalance,
                    customValue: isInitialLoading ? '...' : null,
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppColors.brandEmerald,
                    sparklineData: cashTrend,
                    subtitle: 'Liquid Main Cash',
                    onTap: () => context.push('/accounting/books'),
                  ),
                  KpiCard(
                    title: 'Bank Balances',
                    glCode: '1020',
                    amount: isInitialLoading ? null : bankBalance,
                    customValue: isInitialLoading ? '...' : null,
                    icon: Icons.account_balance_rounded,
                    accentColor: AppColors.brandSky,
                    sparklineData: bankTrend,
                    subtitle: 'Active Bank & UPI',
                    onTap: () => context.push('/accounting/books'),
                  ),
                  KpiCard(
                    title: 'Customer Receivables',
                    glCode: '1030',
                    amount: isInitialLoading ? null : receivables,
                    customValue: isInitialLoading ? '...' : null,
                    icon: Icons.call_received_rounded,
                    accentColor: const Color(0xFF7C3AED),
                    sparklineData: receivablesTrend,
                    subtitle: 'Customer Dues',
                    onTap: () => context.push('/accounting/collect'),
                  ),
                  KpiCard(
                    title: 'Supplier Payables',
                    glCode: '2010',
                    amount: isInitialLoading ? null : payables,
                    customValue: isInitialLoading ? '...' : null,
                    icon: Icons.outbox_rounded,
                    accentColor: AppColors.brandDanger,
                    sparklineData: payablesTrend,
                    subtitle: 'Supplier Dues',
                    onTap: () => context.push('/purchases'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Today's Verified Collections Strip
          KpiCard(
            title: "Today's Verified Collections",
            glCode: 'GL 1010 / 1020',
            amount: isInitialLoading ? null : todayCollections,
            customValue: isInitialLoading ? '...' : null,
            icon: Icons.verified_user_rounded,
            accentColor: const Color(0xFF0D9488),
            subtitle: 'Direct journal entries posted to ledger',
            onTap: () => context.push('/accounting/collect'),
          ),
          const SizedBox(height: 20),

          // Strict Vertical Operational Command
          Text(
            switch (industry) {
              'cafe_bakery' => 'Bakery & Cafe Operations',
              'bulk_water' => 'Bulk Tanker Fleet Logistics',
              'packaged_water' => '20L Can Route Distribution',
              'textile' => 'Textile & Loom Manufacturing',
              _ => 'Commercial Operations',
            },
            style: AppTypography.section.copyWith(color: textCol),
          ),
          const SizedBox(height: 10),

          // 1. Cafe & Bakery Vertical (Aran Cafe)
          if (industry == 'cafe_bakery') ...[
            _buildWorkflowActionCard(
              context: context,
              title: 'Aran Cafe POS Terminal',
              description: 'Touch order billing, table & counter dispatch',
              icon: Icons.restaurant_rounded,
              color: const Color(0xFFD97706),
              onTap: () => context.push('/operations/cafe-pos'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Kitchen & Recipe Inventory',
              description: 'Bakery ingredient stocks, flour & dairy audit',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF059669),
              onTap: () => context.push('/inventory/stock-count'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Cafe Expenses & Kitchen Purchases',
              description: 'Vegetable, milk, gas & daily operational bills',
              icon: Icons.receipt_long_rounded,
              color: AppColors.primary,
              onTap: () => context.push('/expenses/new'),
            ),
          ]
          // 2. Bulk Water Tankers Vertical (TMWS)
          else if (industry == 'bulk_water') ...[
            _buildWorkflowActionCard(
              context: context,
              title: 'Live Tanker GPS Fleet Telematics',
              description: 'Radar tracking, decanting flow rate, dwell time & fuel',
              icon: Icons.share_location_rounded,
              color: const Color(0xFF0284C7),
              onTap: () => context.push('/fleet/gps?mode=bulk_water'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Bulk Tanker Fleet Operations',
              description: 'Trip sheets, motor pumping & waiting surcharges',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF0369A1),
              onTap: () => context.push('/operations/tanker-trip'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Trip Payment Collection',
              description: 'Collect driver cash & corporate commercial dues',
              icon: Icons.payments_rounded,
              color: AppColors.success,
              onTap: () => context.push('/accounting/collect'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Diesel & Vehicle Maintenance',
              description: 'Fuel slips, tanker repair & toll expenditure',
              icon: Icons.local_gas_station_rounded,
              color: AppColors.warning,
              onTap: () => context.push('/expenses/new'),
            ),
          ]
          // 3. 20L Can Route Distribution Vertical (DK Waters)
          else if (industry == 'packaged_water') ...[
            _buildWorkflowActionCard(
              context: context,
              title: 'Live Tata Ace Beat GPS Radar',
              description: 'Route beat perimeter, delivery stops & van jar balance',
              icon: Icons.share_location_rounded,
              color: const Color(0xFF0284C7),
              onTap: () => context.push('/fleet/gps?mode=packaged_water'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: '20L Can Distribution Beat',
              description: 'Ticket Machine, Spot Empty Audit & Plant Refill',
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF059669),
              onTap: () => context.push('/operations/can-sales'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Spot Empty Can Audit',
              description: 'Inspect Tata Ace vehicle cans vs route manifest',
              icon: Icons.fact_check_rounded,
              color: AppColors.warning,
              onTap: () => context.push('/operations/spot-audit'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Driver Cash & Jar Surrender',
              description: 'End-of-day route settlement with admin cashier',
              icon: Icons.price_check_rounded,
              color: const Color(0xFF0284C7),
              onTap: () => context.push('/operations/driver-surrender'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'RO Plant Refill Manifest',
              description: 'Reverse Osmosis factory intake batch logs',
              icon: Icons.factory_rounded,
              color: AppColors.primary,
              onTap: () => context.push('/operations/plant-refill'),
            ),
          ]
          // 4. Textile & Garment Manufacturing Vertical (zoloERP Textiles)
          else if (industry == 'textile') ...[
            _buildWorkflowActionCard(
              context: context,
              title: 'Wholesale Tax Invoicing',
              description: 'Fabric & garment commercial invoice generation',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF7C3AED),
              onTap: () => context.push('/sales/new'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Fabric Roll & Yarn Stock Audit',
              description: 'Physical meter roll and yarn weight audits',
              icon: Icons.inventory_2_rounded,
              color: AppColors.primary,
              onTap: () => context.push('/inventory/stock-count'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Commercial Debtor Collection',
              description: 'Collect trade receivables against B2B invoices',
              icon: Icons.payments_rounded,
              color: AppColors.success,
              onTap: () => context.push('/accounting/collect'),
            ),
          ]
          // 5. Default General Enterprise Fallback
          else ...[
            _buildWorkflowActionCard(
              context: context,
              title: 'Sales Billing',
              description: 'New invoice and customer receipt creation',
              icon: Icons.receipt_long_rounded,
              color: AppColors.primary,
              onTap: () => context.push('/sales/new'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Physical Stock Count',
              description: 'Barcode scan, godown inventory reconciliation',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF059669),
              onTap: () => context.push('/inventory/stock-count'),
            ),
          ],
          const SizedBox(height: 24),

          // Live Accounting Ledger Postings with Date Filtering across all verticals
          LedgerTransactionsSection(
            entries: ledgerEntries,
            activePeriod: _ledgerPeriod,
            activePeriodLabel: ledgerPeriodLabel,
            verticalIndustry: industry,
            onDateFilterSelected: (period, {startDate, endDate}) {
              setState(() {
                _ledgerPeriod = period;
                _ledgerStartDate = startDate;
                _ledgerEndDate = endDate;
              });
              _loadDashboardData();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
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

