import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/kpi_card.dart';
import '../../../core/ui/sales_performance_card.dart';
import '../../../core/ui/ledger_transactions_section.dart';
import '../../../core/utils/location_parser.dart';
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

  // Active Vehicle index for Live Fleet GPS Tracking Card (Water Supply & Can Supply)
  int _selectedFleetVehicleIndex = 0;
  Map<String, dynamic>? _fleetLiveSnapshot;

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
    }

    // 4. Live Fleet Telematics for Water Supply and Water Can Supply
    final industry = authState.activeCompany?.industry ?? '';
    if (industry == 'bulk_water' || industry == 'packaged_water') {
      try {
        final fleetRes = await apiClient.get(
          ApiEndpoints.fleetLive,
          queryParameters: {'vertical': industry},
          fromJson: (data) => data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
        ).timeout(const Duration(seconds: 4));
        if (fleetRes.isSuccess && fleetRes.dataOrNull != null) {
          final rawFleet = fleetRes.dataOrNull!;
          final fData = rawFleet['data'] is Map ? Map<String, dynamic>.from(rawFleet['data'] as Map) : rawFleet;
          if (mounted) {
            setState(() {
              _fleetLiveSnapshot = fData;
            });
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
          const SizedBox(height: 14),

          // Operational View Switcher / Driver Dashboard Direct Access Banner
          _buildDriverDashboardShortcutBanner(context, isDark, industry),
          const SizedBox(height: 16),

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

          // 2nd Main Card: Live Fleet GPS & Telematics Tracking View (For Water Supply & Can Supply)
          if (industry == 'bulk_water' || industry == 'packaged_water') ...[
            _buildFleetGpsTrackingCard(context, isDark, industry),
            const SizedBox(height: 16),
          ],

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
              title: 'Tanker Driver Active Trip Dashboard',
              description: 'Live decanting flow sensor, destination sump navigation & anti-siphon lock',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF0284C7),
              onTap: () => context.push('/operations/tanker-dashboard'),
            ),
            const SizedBox(height: 10),
            _buildWorkflowActionCard(
              context: context,
              title: 'Live Tanker GPS Fleet Telematics',
              description: 'Radar tracking, decanting flow rate, dwell time & fuel',
              icon: Icons.share_location_rounded,
              color: const Color(0xFF0369A1),
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
              title: 'Can Delivery Driver Manifest & Stops',
              description: 'Live Tata Ace beat route, 60-jar load, customer stops & cash dues',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF059669),
              onTap: () => context.push('/operations/driver-manifest'),
            ),
            const SizedBox(height: 10),
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

  Widget _buildFleetGpsTrackingCard(BuildContext context, bool isDark, String industry) {
    final isBulk = industry == 'bulk_water';
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrim = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final List<Map<String, dynamic>> defaultVehicles = isBulk
        ? [
            {
              'number': 'TN-58-BW-2001',
              'model': 'Tata LPT 2518 (20KL)',
              'driver': 'K. Murugan',
              'phone': '+91 98421 00001',
              'status': 'IN TRANSIT',
              'statusColor': const Color(0xFF0284C7),
              'destination': 'The Chennai Silks (Dyeing Unit)',
              'site': 'Perundurai SIPCOT Industrial Area',
              'lat': 11.0845,
              'lng': 77.2941,
              'speed': '38 km/h',
              'flowRate': '160 L/min',
              'cargo': '16.0 / 20.0 KL',
              'valve': 'ANTI-SIPHON SECURED',
              'eta': '12 mins',
            },
            {
              'number': 'TN-58-BW-4001',
              'model': 'BharatBenz 3528 (40KL)',
              'driver': 'P. Selvam',
              'phone': '+91 98421 00002',
              'status': 'DISPATCHED',
              'statusColor': const Color(0xFF059669),
              'destination': 'Texvalley Commercial Complex',
              'site': 'NH-544 Gangapuram, Erode',
              'lat': 11.3142,
              'lng': 77.6820,
              'speed': '42 km/h',
              'flowRate': 'Idle (In Transit)',
              'cargo': '40.0 KL (Full Tank)',
              'valve': 'VALVE SECURED',
              'eta': '25 mins',
            },
            {
              'number': 'TN-58-BW-1001',
              'model': 'Eicher Pro 9KL',
              'driver': 'M. Velu',
              'phone': '+91 98421 00003',
              'status': 'BOREWELL REFILL',
              'statusColor': const Color(0xFFD97706),
              'destination': 'TMWS Borewell Hub #1',
              'site': 'Perundurai Borewell Hub',
              'lat': 11.2780,
              'lng': 77.5920,
              'speed': '0 km/h',
              'flowRate': 'Refilling Tank',
              'cargo': '8.5 / 9.0 KL',
              'valve': 'VALVE SECURED',
              'eta': 'At Station',
            },
          ]
        : [
            {
              'number': 'TN-58-WA-101',
              'model': 'Tata Ace (60 Cans)',
              'driver': 'R. Muthu',
              'phone': '+91 98421 00010',
              'status': 'ON ACTIVE BEAT',
              'statusColor': const Color(0xFF059669),
              'destination': 'Anna Nagar & Teppakulam Route',
              'site': 'Next: Hotel Saravana Bhavan (10 Cans)',
              'lat': 11.3410,
              'lng': 77.7172,
              'speed': '28 km/h',
              'flowRate': '25 Delivered (41%)',
              'cargo': '20 Empties · 35 Cans Left',
              'valve': '12.8V ECU BATTERY',
              'eta': '5 mins',
            },
            {
              'number': 'TN-58-WA-102',
              'model': 'Tata Ace (60 Cans)',
              'driver': 'Manikandan V.',
              'phone': '+91 98421 55102',
              'status': 'ON ACTIVE BEAT',
              'statusColor': const Color(0xFF0284C7),
              'destination': 'Erode Tech Park & Ring Road Beat #2',
              'site': 'Next: Texvalley Tech Campus (20 Cans)',
              'lat': 11.3520,
              'lng': 77.7280,
              'speed': '34 km/h',
              'flowRate': '40 Delivered (66%)',
              'cargo': '35 Empties · 20 Cans Left',
              'valve': '13.1V ECU BATTERY',
              'eta': '8 mins',
            },
          ];

    final vehicles = defaultVehicles;
    // Overlay live server fleet telemetry if available
    if (_fleetLiveSnapshot != null) {
      final liveList = isBulk
          ? (_fleetLiveSnapshot!['tankers'] as List<dynamic>?)
          : (_fleetLiveSnapshot!['routes'] as List<dynamic>?);
      if (liveList != null && liveList.isNotEmpty) {
        for (var i = 0; i < liveList.length && i < vehicles.length; i++) {
          final liveItem = liveList[i];
          if (liveItem is Map) {
            if (liveItem['speed_kmh'] != null) {
              vehicles[i]['speed'] = '${liveItem['speed_kmh']} km/h';
            }
            if (liveItem['latitude'] != null && liveItem['longitude'] != null) {
              vehicles[i]['lat'] = (liveItem['latitude'] as num).toDouble();
              vehicles[i]['lng'] = (liveItem['longitude'] as num).toDouble();
            }
          }
        }
      }
    }
    if (_selectedFleetVehicleIndex >= vehicles.length) {
      _selectedFleetVehicleIndex = 0;
    }
    final selected = vehicles[_selectedFleetVehicleIndex];
    final lat = (selected['lat'] as num?)?.toDouble() ?? 11.0845;
    final lng = (selected['lng'] as num?)?.toDouble() ?? 77.2941;
    final phone = selected['phone']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? borderCol : const Color(0xFFBAE6FD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0284C7)).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669)).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isBulk ? Icons.local_shipping_rounded : Icons.water_drop_rounded,
                    size: 20,
                    color: isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isBulk ? 'Bulk Tanker Fleet GPS Tracking' : '20L Can Delivery Fleet Tracking',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: textPrim,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 6, color: Color(0xFF059669)),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE GPS',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Where is the truck · Real-time satellite telemetrics',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
                // Full Radar Map Button
                InkWell(
                  onTap: () => context.push('/fleet/gps?mode=$industry'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669)).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          size: 14,
                          color: isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Radar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vehicle Switcher Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(vehicles.length, (idx) {
                final v = vehicles[idx];
                final isSel = idx == _selectedFleetVehicleIndex;
                final col = v['statusColor'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFleetVehicleIndex = idx),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel
                            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE))
                            : (isDark ? const Color(0xFF1E293B).withOpacity(0.4) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel
                              ? (isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669))
                              : borderCol,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBulk ? Icons.local_shipping_rounded : Icons.airport_shuttle_rounded,
                            size: 15,
                            color: isSel
                                ? (isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669))
                                : textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            v['number'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? textPrim : textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Active Vehicle Details Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Destination & Lat/Lng Banner
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669)).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected['destination']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrim,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selected['site']?.toString() ?? '',
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'GPS: ${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ETA: ${selected['eta']}',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textPrim),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3-Metric HUD Ribbon
                  Row(
                    children: [
                      Expanded(
                        child: _buildFleetMiniHud(
                          icon: Icons.speed_rounded,
                          label: 'LIVE SPEED',
                          value: selected['speed'],
                          color: const Color(0xFF0284C7),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFleetMiniHud(
                          icon: isBulk ? Icons.water_drop_rounded : Icons.inventory_2_rounded,
                          label: isBulk ? 'FLOW RATE' : 'DISPATCH',
                          value: selected['flowRate'],
                          color: const Color(0xFF059669),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFleetMiniHud(
                          icon: Icons.shield_rounded,
                          label: 'STATUS',
                          value: selected['status'],
                          color: selected['statusColor'] as Color,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Driver Details & Quick Actions Bar
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: (isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669)).withOpacity(0.12),
                        child: Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected['driver']?.toString() ?? 'Driver',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrim),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              phone,
                              style: TextStyle(fontSize: 10, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      // Turn-by-Turn Navigate Button (Google Maps)
                      ElevatedButton.icon(
                        onPressed: () => LocationParser.launchNavigation(lat, lng),
                        icon: const Icon(Icons.navigation_rounded, size: 14),
                        label: const Text('Track / Nav', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () async {
                            final uri = Uri.parse('tel:$phone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669),
                            side: BorderSide(color: (isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669)).withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Icon(Icons.call_rounded, size: 14),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Footer Dispatch Link
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBulk ? 'Cargo: ${selected['cargo']} · ${selected['valve']}' : 'Manifest: ${selected['cargo']}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
                ),
                InkWell(
                  onTap: () => context.push(isBulk ? '/operations/tanker-dashboard' : '/operations/driver-manifest'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Driver Dispatch View',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: isBulk ? const Color(0xFF0284C7) : const Color(0xFF059669),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetMiniHud({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDashboardShortcutBanner(BuildContext context, bool isDark, String industry) {
    final (title, subtitle, badge, badgeColor, icon, route) = switch (industry) {
      'packaged_water' => (
        'DK Waters 20L Can Driver Dashboard',
        'Live Tata Ace beat route · 60 cans loaded · 25/60 customer stops completed',
        'CAN DRIVER MANIFEST',
        const Color(0xFF059669),
        Icons.local_shipping_rounded,
        '/operations/driver-manifest',
      ),
      'bulk_water' => (
        'TMWS Tanker Driver Dashboard',
        'TN-58-BW-2001 (12 KL) · Active Texvalley Sump · 160 L/min Decanting',
        'TANKER DRIVER DESK',
        const Color(0xFF0284C7),
        Icons.local_shipping_rounded,
        '/operations/tanker-dashboard',
      ),
      'cafe_bakery' => (
        'Aran Cafe Express Touch POS',
        'Table dining orders, kitchen KOT dispatch & counter cash checkout',
        'TOUCH POS BILLING',
        const Color(0xFFD97706),
        Icons.restaurant_rounded,
        '/operations/cafe-pos',
      ),
      _ => (
        'Operations Field Dispatch Desk',
        'Field deliveries, customer collections & trip execution',
        'FIELD DESK',
        AppColors.primary,
        Icons.engineering_rounded,
        '/modules',
      ),
    };

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrim = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badgeColor.withOpacity(isDark ? 0.4 : 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: badgeColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '1-Tap Direct View',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textSec,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrim,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: textSec),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: badgeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

