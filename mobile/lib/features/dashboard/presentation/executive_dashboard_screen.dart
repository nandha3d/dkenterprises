import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/daily_sales_chart.dart';
import '../../../core/ui/gps_map_interactive_sheets.dart';
import '../../../core/ui/ledger_transactions_section.dart';
import '../../../core/ui/ripple_components.dart';
import '../../../core/ui/sparkline_chart.dart';
import '../../auth/domain/auth_models.dart';
import 'can_delivery_driver_dashboard_screen.dart';
import 'cashier_dashboard_screen.dart';
import 'field_agent_dashboard_screen.dart';
import 'tanker_driver_dashboard_screen.dart';

/// 1x1 transparent PNG bytes used when running headless widget tests.
final Uint8List _kTransparentTilePng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _MemoryStubTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_kTransparentTilePng);
  }
}

TileProvider _buildSafeTileProvider() {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return _MemoryStubTileProvider();
  }
  return NetworkTileProvider();
}

class ExecutiveDashboardScreen extends ConsumerStatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  ConsumerState<ExecutiveDashboardScreen> createState() =>
      _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState
    extends ConsumerState<ExecutiveDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  static final NumberFormat _inrWhole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final NumberFormat _inrCompact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _financials;
  DateTime? _lastRefreshedAt;
  bool _isFromCache = false;

  String _salesPeriod = 'this_month';
  int _dailyChartDays = 14;
  DateTime? _salesStartDate;
  DateTime? _salesEndDate;

  String _ledgerPeriod = 'today';
  DateTime? _ledgerStartDate;
  DateTime? _ledgerEndDate;

  Map<String, dynamic>? _fleetLiveSnapshot;
  late final MapController _ownerMapController;
  bool _ownerMapReady = false;
  String _ownerMapFilter = 'all';
  int? _ownerSelectedCustomerId;
  String? _ownerSelectedVehicleKey;

  @override
  void initState() {
    super.initState();
    _ownerMapController = MapController();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _ownerMapController.dispose();
    super.dispose();
  }

  String _resolveEffectiveIndustry(CompanyInfo? company) {
    final raw = (company?.industry ?? '').trim().toLowerCase();
    if (raw == 'bulk_water' || raw == 'packaged_water' || raw == 'cafe_bakery') {
      return raw;
    }
    final code = (company?.code ?? '').trim().toLowerCase();
    final name = (company?.name ?? '').trim().toLowerCase();
    if (code == 'tmws' || name.contains('murugan') || name.contains('tanker') || name.contains('bulk')) {
      return 'bulk_water';
    }
    if (code.contains('dkw') || name.contains('dk water') || name.contains('can') || name.contains('packaged')) {
      return 'packaged_water';
    }
    if (code.contains('aran') || name.contains('cafe') || name.contains('bakery')) {
      return 'cafe_bakery';
    }
    return raw;
  }

  double? _parseCoord(dynamic raw) {
    if (raw == null) return null;
    final val = double.tryParse(raw.toString());
    if (val == null || val.abs() < 0.0001) return null;
    return val;
  }

  double _numVal(dynamic raw) => double.tryParse(raw?.toString() ?? '0') ?? 0.0;

  String _customerPaymentStatus(Map<String, dynamic> c) {
    final explicit = (c['payment_status'] ?? '').toString().toLowerCase();
    if (explicit == 'overdue' || _numVal(c['overdue_amount']) > 0.01) {
      return 'overdue';
    }
    if (explicit == 'due' || _numVal(c['due_amount']) > 0.01) {
      return 'due';
    }
    return 'paid';
  }

  Color _colorForPaymentStatus(String status) {
    return switch (status) {
      'overdue' => AppColors.danger,
      'due' => AppColors.warning,
      _ => AppColors.success,
    };
  }

  List<Map<String, dynamic>> _extractFleetVehicles(
    Map<String, dynamic>? snapshot,
    bool isBulk,
  ) {
    final raw = isBulk
        ? (snapshot?['tankers'] as List<dynamic>? ?? const [])
        : (snapshot?['can_routes'] as List<dynamic>? ?? const []);
    return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  List<Map<String, dynamic>> _extractFleetCustomers(Map<String, dynamic>? snapshot) {
    final raw = snapshot?['customers'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .where((c) => _parseCoord(c['latitude']) != null && _parseCoord(c['longitude']) != null)
        .toList();
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
    final cacheKey =
        'financials_comp_${companyId}_s_${_salesPeriod}_l_${_ledgerPeriod}_d_$_dailyChartDays';

    try {
      final cached = await db.getCache(cacheKey).timeout(const Duration(milliseconds: 500));
      final cacheTime = await db.getCacheTimestamp(cacheKey).timeout(const Duration(milliseconds: 500));
      if (cached != null && cached is Map<String, dynamic> && mounted) {
        setState(() {
          _financials = cached;
          _lastRefreshedAt = cacheTime;
          _isFromCache = true;
          _isLoading = false;
        });
      }
    } catch (_) {}

    final queryParams = <String, dynamic>{
      'sales_period': _salesPeriod,
      'ledger_period': _ledgerPeriod,
      'days': _dailyChartDays,
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

    final industry = _resolveEffectiveIndustry(authState.activeCompany);
    final Future<dynamic> wsFuture = authState.companies.length <= 1
        ? () async {
            try {
              return await apiClient
                  .get(
                    ApiEndpoints.workspace,
                    fromJson: (data) =>
                        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
                  )
                  .timeout(const Duration(seconds: 4));
            } catch (_) {
              return null;
            }
          }()
        : Future<dynamic>.value(null);

    Future<dynamic> fetchFleetFor(String ind, Duration timeout) async {
      try {
        return await apiClient
            .get(
              ApiEndpoints.fleetLive,
              queryParameters: {'vertical': ind, 'industry': ind},
              fromJson: (data) => data is Map
                  ? Map<String, dynamic>.from(data)
                  : <String, dynamic>{},
            )
            .timeout(timeout);
      } catch (_) {
        return null;
      }
    }

    final Future<dynamic> fleetFuture =
        (industry == 'bulk_water' || industry == 'packaged_water')
            ? fetchFleetFor(industry, const Duration(seconds: 4))
            : Future<dynamic>.value(null);

    try {
      final result = await apiClient
          .get(
            ApiEndpoints.financials,
            queryParameters: queryParams,
            fromJson: (data) => data as Map<String, dynamic>,
          )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (result.isSuccess) {
        final rawData = result.dataOrNull ?? <String, dynamic>{};
        final liveData = rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : (rawData['data'] is Map
                ? Map<String, dynamic>.from(rawData['data'] as Map)
                : rawData);
        await db.saveCache(cacheKey, liveData);
        if (mounted) {
          setState(() {
            _financials = liveData;
            _isFromCache = false;
            _lastRefreshedAt = DateTime.now();
          });
        }
      } else if (_financials == null && mounted) {
        setState(() {
          _errorMessage =
              result.failureOrNull?.message ?? 'Failed to load live ledger balances';
        });
      }
    } catch (_) {
      if (_financials == null && mounted) {
        setState(() {
          _errorMessage = 'Connection timeout. Pull down to refresh.';
        });
      }
    }

    final wsRes = await wsFuture;
    if (wsRes != null && wsRes.isSuccess == true && wsRes.dataOrNull != null && mounted) {
      final rawWs = wsRes.dataOrNull as Map<String, dynamic>;
      final wsData = rawWs['data'] is Map
          ? Map<String, dynamic>.from(rawWs['data'] as Map)
          : rawWs;
      final rawComps = wsData['companies'];
      if (rawComps is List && rawComps.isNotEmpty) {
        final parsedComps = rawComps
            .whereType<Map>()
            .map((c) => CompanyInfo.fromJson(Map<String, dynamic>.from(c)))
            .toList();
        if (parsedComps.isNotEmpty) {
          try {
            await ref
                .read(authNotifierProvider.notifier)
                .syncCompaniesFromWorkspace(parsedComps);
          } catch (_) {}
        }
      }
    }

    var fleetRes = await fleetFuture;
    final resolvedAfterSync = mounted
        ? _resolveEffectiveIndustry(ref.read(authNotifierProvider).activeCompany)
        : industry;
    if (fleetRes == null &&
        mounted &&
        (resolvedAfterSync == 'bulk_water' || resolvedAfterSync == 'packaged_water')) {
      fleetRes = await fetchFleetFor(resolvedAfterSync, const Duration(seconds: 3));
    }

    if (fleetRes != null &&
        fleetRes.isSuccess == true &&
        fleetRes.dataOrNull != null &&
        mounted) {
      final rawFleet = fleetRes.dataOrNull as Map<String, dynamic>;
      final fData = rawFleet['data'] is Map
          ? Map<String, dynamic>.from(rawFleet['data'] as Map)
          : rawFleet;
      setState(() {
        _fleetLiveSnapshot = fData;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_ownerMapReady) return;
        final isBulk = resolvedAfterSync == 'bulk_water';
        _fitOwnerMapBounds(
          _extractFleetCustomers(fData),
          _extractFleetVehicles(fData, isBulk),
        );
      });
    } else if (resolvedAfterSync != 'bulk_water' &&
        resolvedAfterSync != 'packaged_water' &&
        mounted) {
      setState(() {
        _fleetLiveSnapshot = null;
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.activeCompany?.id != next.activeCompany?.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _fleetLiveSnapshot = null;
            _ownerMapFilter = 'all';
            _ownerSelectedCustomerId = null;
            _ownerSelectedVehicleKey = null;
          });
          _loadDashboardData();
        });
      }
    });

    ref.listen<int>(
      syncWorkerProvider.select((w) => w.state.pendingCount),
      (previous, next) {
        if (previous != null && next < previous) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadDashboardData();
          });
        }
      },
    );

    ref.listen<int>(dashboardRefreshSignalProvider, (previous, next) {
      if (previous != null && next != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadDashboardData();
        });
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final userRole = (authState.user?.role ?? '').toLowerCase();
    final userName =
        (authState.user?.username ?? authState.user?.name ?? '').toLowerCase();
    final userEmail = (authState.user?.email ?? '').toLowerCase();
    final allRoles = authState.roles.map((r) => r.toLowerCase()).toList();

    bool hasKeyword(String kw) {
      return userRole.contains(kw) ||
          userName.contains(kw) ||
          userEmail.contains(kw) ||
          allRoles.any((r) => r.contains(kw));
    }

    if (hasKeyword('tanker')) {
      return const TankerDriverDashboardScreen();
    } else if (hasKeyword('delivery') || hasKeyword('driver')) {
      return const CanDeliveryDriverDashboardScreen();
    } else if (hasKeyword('cashier')) {
      return const CashierDashboardScreen();
    } else if (hasKeyword('agent') || hasKeyword('field')) {
      return const FieldAgentDashboardScreen();
    }

    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final industry = _resolveEffectiveIndustry(authState.activeCompany);
    final isWaterVertical =
        industry == 'bulk_water' || industry == 'packaged_water';
    final displayName =
        authState.user?.name.trim().isNotEmpty == true
            ? authState.user!.name.trim()
            : 'Executive';

    final cashBalance = _financials?['cash_balance'] as num? ??
        _financials?['cash_in_hand_1010'] as num? ??
        0;
    final bankBalance = _financials?['bank_balance'] as num? ??
        _financials?['bank_account_1020'] as num? ??
        0;
    final receivables = _financials?['receivables'] as num? ??
        _financials?['accounts_receivable_1030'] as num? ??
        0;
    final payables = _financials?['payables'] as num? ?? 0;
    final todayCollections = _financials?['collections_today'] as num? ??
        _financials?['today_collections'] as num? ??
        0;
    final cashInTransit = _financials?['cash_in_transit_drivers'] as num? ?? 0;

    final salesAmount = _financials?['sales_amount'] as num? ?? 0;
    final salesToday = _financials?['sales_today'] as num? ?? 0;
    final salesCount = (_financials?['sales_count'] as num?)?.toInt() ?? 0;
    final salesPeriodLabel =
        _financials?['sales_period_label'] as String? ?? 'This Month';

    final salesTrendRaw = _financials?['sales_trend'] as List<dynamic>? ?? [];
    final salesTrend = salesTrendRaw
        .map<({String label, double amount})>((e) {
          if (e is Map) {
            return (
              label: (e['label'] ?? e['date'] ?? '').toString(),
              amount: (e['amount'] as num? ?? 0).toDouble(),
            );
          }
          if (e is num) {
            return (label: '', amount: e.toDouble());
          }
          return (label: '', amount: 0.0);
        })
        .toList();

    final cashTrend = (_financials?['cash_trend'] as List<dynamic>?)
            ?.map<num>((e) => e as num)
            .toList() ??
        const <num>[];

    final ledgerEntries = _financials?['ledger_entries'] as List<dynamic>? ??
        _financials?['recent_transactions'] as List<dynamic>? ??
        [];
    final ledgerPeriodLabel =
        _financials?['ledger_period_label'] as String? ?? 'Today';

    final dailySalesSeries =
        (_financials?['daily_sales_series'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
    final dailyCollectedTotal =
        (_financials?['daily_collected_total'] as num? ?? 0).toDouble();
    final dailyDueTotal =
        (_financials?['daily_due_total'] as num? ?? 0).toDouble();
    final dailyGstTotal =
        (_financials?['daily_gst_total'] as num? ?? 0).toDouble();

    final isInitialLoading = _isLoading && _financials == null;

    return Container(
      color: skin.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            color: skin.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: skin.primary,
                          backgroundColor: skin.hairline,
                        ),
                      ),
                    if (_errorMessage != null && !isInitialLoading)
                      _buildErrorBanner(skin),
                  ],
                ),

                // 1. Greeting Header & Role Badge
                _buildGreetingHeader(
                  skin: skin,
                  displayName: displayName,
                  companyName: authState.activeCompany?.name.trim().isNotEmpty == true
                      ? authState.activeCompany!.name.trim()
                      : 'DK Enterprises',
                ),
                const SizedBox(height: 12),

                // 1B. Admin Company Switcher & Group Insights Strip
                _buildCompanySwitcherStrip(
                  skin: skin,
                  companies: authState.companies,
                  activeCompanyId: authState.activeCompany?.id,
                ),
                const SizedBox(height: 14),

                // 1C. Owner Live GPS Command Center (Primary View for Bulk Water & Can Delivery)
                if (isWaterVertical) ...[
                  _buildOwnerWaterGpsCommandSection(
                    skin: skin,
                    isDark: isDark,
                    industry: industry,
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Hero Cash in Hand Card (#0B5D52 + #C9F36A + Mini Sparkline)
                _buildHeroCashCard(
                  skin: skin,
                  isDark: isDark,
                  isLoading: isInitialLoading,
                  cashBalance: cashBalance,
                  todayCollections: todayCollections,
                  cashTrend: cashTrend,
                ),
                const SizedBox(height: 12),

                // 3. Horizontal Attention / Operational Pills Strip
                _buildAttentionStrip(
                  skin: skin,
                  isDark: isDark,
                  industry: industry,
                  receivables: receivables,
                  cashInTransit: cashInTransit,
                ),
                const SizedBox(height: 14),

                // 4. 2x2 Bento Metric Grid (Bank, Receivables, Payables, Journal Postings)
                _buildBentoMetricGrid(
                  skin: skin,
                  isDark: isDark,
                  isLoading: isInitialLoading,
                  bankBalance: bankBalance,
                  receivables: receivables,
                  payables: payables,
                  postingsCount: ledgerEntries.length,
                ),
                const SizedBox(height: 16),

                // 5. Sales Performance Card (Today | 7D | Month + Line Chart)
                _buildSalesPerformanceSection(
                  skin: skin,
                  isDark: isDark,
                  salesAmount: salesAmount,
                  salesToday: salesToday,
                  salesCount: salesCount,
                  salesPeriodLabel: salesPeriodLabel,
                  salesTrend: salesTrend,
                ),
                const SizedBox(height: 16),

                // 5B. Daily Sales & Collections Bar Graph (Synced ERP + GST)
                DailySalesChart(
                  series: dailySalesSeries,
                  selectedDays: _dailyChartDays,
                  onDaysChanged: (days) {
                    if (days == _dailyChartDays) return;
                    setState(() => _dailyChartDays = days);
                    _loadDashboardData();
                  },
                  collectedTotal: dailyCollectedTotal,
                  dueTotal: dailyDueTotal,
                  gstTotal: dailyGstTotal,
                  skin: skin,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // 6. Live Fleet Strip (Bulk Tanker & Can Supply verticals only)
                if (industry == 'bulk_water' || industry == 'packaged_water') ...[
                  _buildLiveFleetStrip(
                    skin: skin,
                    isDark: isDark,
                    industry: industry,
                  ),
                  const SizedBox(height: 16),
                ],

                // 7. Quick Modules 2x2 Grid (Scoped by Industry)
                _buildQuickModulesGrid(
                  skin: skin,
                  isDark: isDark,
                  industry: industry,
                ),
                const SizedBox(height: 14),

                // 8. Primary Action Pill CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/sales/new'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isDark ? skin.primary : AppColors.rippleLightInk,
                      foregroundColor:
                          isDark ? Colors.white : Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 20),
                    label: const Text(
                      'Issue New Commercial Sale Bill',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // 9. Live Accounting Ledger Postings
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(RippleSkin skin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.rippleRuby.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.rippleRuby.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.rippleRuby),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(fontSize: 12, color: AppColors.rippleRuby),
            ),
          ),
          TextButton(
            onPressed: _loadDashboardData,
            child: const Text('Retry',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader({
    required RippleSkin skin,
    required String displayName,
    required String companyName,
  }) {
    final dateStr = DateFormat('d MMM yyyy').format(DateTime.now());
    final syncLabel = _isFromCache ? 'Cached' : 'Live';
    final syncColor = _isFromCache ? AppColors.rippleHoney : AppColors.rippleMint;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greetingText()}, $displayName',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: skin.ink,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '$dateStr • $companyName',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: skin.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: syncColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _lastRefreshedAt != null
                        ? '$syncLabel · ${DateFormat('h:mm a').format(_lastRefreshedAt!)}'
                        : syncLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: syncColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: skin.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: skin.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined, size: 14, color: skin.primary),
              const SizedBox(width: 4),
              Text(
                skin.skinName.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: skin.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanySwitcherStrip({
    required RippleSkin skin,
    required List<CompanyInfo> companies,
    required int? activeCompanyId,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            avatar: Icon(Icons.corporate_fare_rounded, size: 16, color: skin.primary),
            label: const Text(
              'Group Insights',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            onPressed: () => context.go('/workspace'),
          ),
          for (final company in companies) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: Icon(
                switch (company.industry) {
                  'cafe_bakery' => Icons.restaurant_rounded,
                  'bulk_water' => Icons.fire_truck_rounded,
                  'packaged_water' => Icons.water_drop_rounded,
                  _ => Icons.business_rounded,
                },
                size: 15,
                color: company.id == activeCompanyId ? Colors.white : skin.primary,
              ),
              selected: company.id == activeCompanyId,
              label: Text(
                company.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onSelected: (selected) async {
                if (!selected || company.id == activeCompanyId) return;
                try {
                  await ref.read(authNotifierProvider.notifier).switchCompany(company);
                } catch (_) {}
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroCashCard({
    required RippleSkin skin,
    required bool isDark,
    required bool isLoading,
    required num cashBalance,
    required num todayCollections,
    required List<num> cashTrend,
  }) {
    final cardBgTop = isDark ? const Color(0xFF0A4A41) : AppColors.lagoonPrimary;
    final cardBgBottom = isDark ? const Color(0xFF052E28) : const Color(0xFF00443B);
    const lime = AppColors.lagoonAction;
    final sparkPoints =
        cashTrend.length >= 2 ? cashTrend : <num>[cashBalance, cashBalance];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardBgTop, cardBgBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(skin.heroRadius),
        boxShadow: [
          BoxShadow(
            color: cardBgBottom.withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -36,
            child: IgnorePointer(
              child: Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lime.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'CASH IN HAND',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: lime,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  todayCollections > 0
                                      ? '+${_inrCompact.format(todayCollections)} today'
                                      : 'GL 1010',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.rippleLightInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isLoading ? '₹...' : _inrWhole.format(cashBalance),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: lime,
                                letterSpacing: -0.8,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 16),
                        SparklineChart(
                          data: sparkPoints,
                          lineColor: lime,
                          height: 36,
                          width: 78,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => context.push('/accounting/books'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            size: 15, color: lime),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Main Cash Account (GL 1010)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Collected Today: ${_inrWhole.format(todayCollections)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: lime,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionStrip({
    required RippleSkin skin,
    required bool isDark,
    required String industry,
    required num receivables,
    required num cashInTransit,
  }) {
    final items = <({
      String label,
      IconData icon,
      Color accent,
      String route,
    })>[
      if (industry == 'bulk_water' || industry == 'packaged_water')
        (
          label: 'Live GPS & Due Map',
          icon: Icons.map_rounded,
          accent: AppColors.rippleSky,
          route: '/fleet/gps?mode=$industry',
        ),
      (
        label: receivables > 0
            ? 'Customer Dues (${_inrCompact.format(receivables)})'
            : 'Receivables Clear',
        icon: receivables > 0
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline_rounded,
        accent: receivables > 0 ? AppColors.rippleCoral : AppColors.rippleMint,
        route: '/accounting/collect',
      ),
      if (cashInTransit > 0)
        (
          label: 'Surrender Queue (${_inrCompact.format(cashInTransit)})',
          icon: Icons.payments_outlined,
          accent: AppColors.rippleHoney,
          route: '/operations/driver-surrender',
        ),
      if (industry == 'packaged_water')
        (
          label: 'Can Route Manifest',
          icon: Icons.local_shipping_outlined,
          accent: AppColors.aquaPrimary,
          route: '/operations/driver-manifest',
        )
      else if (industry == 'bulk_water')
        (
          label: 'Tanker Driver Desk',
          icon: Icons.local_shipping_outlined,
          accent: AppColors.aquaPrimary,
          route: '/operations/tanker-dashboard',
        )
      else if (industry == 'cafe_bakery')
        (
          label: 'Open Touch POS',
          icon: Icons.point_of_sale_rounded,
          accent: AppColors.chaiPrimary,
          route: '/operations/cafe-pos',
        ),
      (
        label: 'Stock Audit',
        icon: Icons.inventory_2_outlined,
        accent: AppColors.rippleHoney,
        route: '/inventory/stock-count',
      ),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final pill = items[index];
          return Material(
            color: pill.accent.withValues(alpha: isDark ? 0.16 : 0.11),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => context.push(pill.route),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: pill.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(pill.icon, size: 15, color: pill.accent),
                    const SizedBox(width: 6),
                    Text(
                      pill.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: pill.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBentoMetricGrid({
    required RippleSkin skin,
    required bool isDark,
    required bool isLoading,
    required num bankBalance,
    required num receivables,
    required num payables,
    required int postingsCount,
  }) {
    final cards = [
      _BentoMetricData(
        title: 'BANK BALANCES',
        value: isLoading ? '...' : _inrWhole.format(bankBalance),
        subtitle: 'Active Bank & UPI',
        badgeText: 'GL 1020',
        badgeColor: AppColors.rippleSky,
        onTap: () => context.push('/accounting/books'),
      ),
      _BentoMetricData(
        title: 'RECEIVABLES',
        value: isLoading ? '...' : _inrWhole.format(receivables),
        subtitle: 'Customer Dues',
        badgeText: receivables > 0 ? 'Due' : 'Clear',
        badgeColor:
            receivables > 0 ? AppColors.rippleCoral : AppColors.rippleMint,
        valueColor: receivables > 0 ? AppColors.rippleCoral : skin.ink,
        onTap: () => context.push('/accounting/collect'),
      ),
      _BentoMetricData(
        title: 'PAYABLES',
        value: isLoading ? '...' : _inrWhole.format(payables),
        subtitle: 'Supplier Dues',
        badgeText: 'GL 2010',
        badgeColor: AppColors.rippleHoney,
        onTap: () => context.push('/purchases'),
      ),
      _BentoMetricData(
        title: 'JOURNAL POSTINGS',
        value: isLoading
            ? '...'
            : '$postingsCount ${_ledgerPeriod == 'today' ? 'Today' : 'Entries'}',
        subtitle: 'Posted to Ledger',
        badgeText: 'Live',
        badgeColor: AppColors.rippleMint,
        onTap: () => context.push('/accounting/books'),
      ),
    ];

    return Builder(
      builder: (context) {
        final isWide = MediaQuery.sizeOf(context).width >= 720;
        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: _buildBentoCard(skin, cards[i])),
                if (i < cards.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildBentoCard(skin, cards[0])),
                const SizedBox(width: 10),
                Expanded(child: _buildBentoCard(skin, cards[1])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildBentoCard(skin, cards[2])),
                const SizedBox(width: 10),
                Expanded(child: _buildBentoCard(skin, cards[3])),
              ],
            ),
          ],
        );
      },
    );
  }

  ({IconData icon, Color color}) _metricVisual(_BentoMetricData data) {
    final t = data.title.toUpperCase();
    if (t.contains('CASH')) {
      return (icon: Icons.account_balance_wallet_rounded, color: data.badgeColor);
    }
    if (t.contains('DUE') || t.contains('RECEIVABLE') || t.contains('CREDIT')) {
      return (icon: Icons.request_quote_rounded, color: data.badgeColor);
    }
    if (t.contains('CAN') || t.contains('WATER') || t.contains('TANK')) {
      return (icon: Icons.water_drop_rounded, color: data.badgeColor);
    }
    if (t.contains('PROFIT') || t.contains('SALES') || t.contains('REV')) {
      return (icon: Icons.trending_up_rounded, color: data.badgeColor);
    }
    if (t.contains('EXPENSE')) {
      return (icon: Icons.receipt_long_rounded, color: data.badgeColor);
    }
    return (icon: Icons.analytics_rounded, color: data.badgeColor);
  }

  Widget _buildBentoCard(RippleSkin skin, _BentoMetricData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _metricVisual(data);
    final accent = visual.color;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.11 : 0.05),
              skin.surface,
            ),
            skin.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(skin.cardRadius),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : accent)
                .withValues(alpha: isDark ? 0.16 : 0.045),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(skin.cardRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: data.onTap,
            borderRadius: BorderRadius.circular(skin.cardRadius),
            child: Stack(
              children: [
                PositionedDirectional(
                  end: -8,
                  bottom: -8,
                  child: ExcludeSemantics(
                    child: Icon(
                      visual.icon,
                      size: 52,
                      color: accent.withValues(alpha: isDark ? 0.065 : 0.045),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RippleIconBadge(
                            icon: visual.icon,
                            accentColor: accent,
                            size: 28,
                            iconSize: 15,
                            radius: 9,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              data.title,
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
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: data.badgeColor.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              data.badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Color.lerp(data.badgeColor, Colors.white, 0.22)!
                                    : data.badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          data.value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: data.valueColor ?? skin.ink,
                            letterSpacing: -0.4,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: skin.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesPerformanceSection({
    required RippleSkin skin,
    required bool isDark,
    required num salesAmount,
    required num salesToday,
    required int salesCount,
    required String salesPeriodLabel,
    required List<({String label, double amount})> salesTrend,
  }) {
    final periods = [
      (key: 'today', label: 'Today'),
      (key: 'this_week', label: '7D'),
      (key: 'this_month', label: 'Month'),
    ];

    final hasTrend = salesTrend.any((p) => p.amount > 0);
    final peakPoint = salesTrend.isNotEmpty
        ? salesTrend.reduce((a, b) => a.amount >= b.amount ? a : b)
        : (label: '', amount: 0.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(skin.cardRadius),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Performance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: skin.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$salesPeriodLabel · Ledger pacing',
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
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: skin.surface2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final p in periods)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _salesPeriod = p.key;
                            _salesStartDate = null;
                            _salesEndDate = null;
                          });
                          _loadDashboardData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _salesPeriod == p.key
                                ? (isDark ? skin.primary : skin.surface)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _salesPeriod == p.key
                                  ? (isDark ? Colors.white : skin.ink)
                                  : skin.muted,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: () => _pickCustomSalesDateRange(context),
                      icon: Icon(Icons.date_range_rounded,
                          size: 16, color: skin.primary),
                      tooltip: 'Custom Date Range',
                      visualDensity: VisualDensity.compact,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Invoiced',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: skin.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _inrWhole.format(salesAmount),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: skin.ink,
                        letterSpacing: -0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Volume',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: skin.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$salesCount bills · Today ${_inrCompact.format(salesToday)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: skin.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasTrend) ...[
            if (peakPoint.amount > 0)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.rippleLightInk,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Peak${peakPoint.label.isNotEmpty ? ' (${peakPoint.label})' : ''}: ${_inrWhole.format(peakPoint.amount)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: _StitchAreaLinePainter(
                  values: salesTrend.map((e) => e.amount).toList(),
                  lineColor: skin.primary,
                  gridColor: skin.hairline,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (salesTrend.isNotEmpty)
                  Text(
                    salesTrend.first.label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: skin.muted),
                  ),
                if (salesTrend.length > 2)
                  Text(
                    salesTrend[salesTrend.length ~/ 2].label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: skin.muted),
                  ),
                if (salesTrend.isNotEmpty)
                  Text(
                    salesTrend.last.label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: skin.muted),
                  ),
              ],
            ),
          ] else
            Container(
              height: 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: skin.surface2.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'No sales invoices recorded in this window yet.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: skin.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickCustomSalesDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (range != null && mounted) {
      setState(() {
        _salesPeriod = 'custom';
        _salesStartDate = range.start;
        _salesEndDate = range.end;
      });
      _loadDashboardData();
    }
  }

  Widget _buildLiveFleetStrip({
    required RippleSkin skin,
    required bool isDark,
    required String industry,
  }) {
    final isBulk = industry == 'bulk_water';
    final rawUnits = isBulk
        ? (_fleetLiveSnapshot?['tankers'] as List<dynamic>? ?? const [])
        : (_fleetLiveSnapshot?['can_routes'] as List<dynamic>? ?? const []);

    final units = rawUnits.whereType<Map>().map((item) {
      final mapCopy = Map<String, dynamic>.from(item);
      if (isBulk) {
        final reg = (item['tanker_number'] ??
                item['vehicle_number'] ??
                item['name'] ??
                'Tanker')
            .toString();
        final cap = item['capacity_liters'] != null
            ? '${((item['capacity_liters'] as num) / 1000).toStringAsFixed(0)} KL Tanker'
            : (item['driver_name']?.toString() ?? 'Bulk Water Unit');
        final rawSpeed = item['current_speed'] ?? item['speed_kmh'];
        final speed = rawSpeed != null
            ? '$rawSpeed km/h'
            : (item['latitude'] != null ? 'GPS Active' : 'Telemetry Pending');
        final status =
            (item['status'] ?? 'ACTIVE').toString().toUpperCase();
        return (
          raw: mapCopy,
          title: reg,
          subtitle: cap,
          status: status,
          metricLabel: 'LIVE SPEED',
          metricValue: speed,
        );
      }
      final routeName = (item['route_name'] ??
              item['vehicle_no'] ??
              item['vehicle_number'] ??
              'Delivery Route')
          .toString();
      final driverName = (item['driver_name'] ??
              item['vehicle_no'] ??
              item['vehicle_number'] ??
              'Active Beat')
          .toString();
      final rawSpeed = item['current_speed'] ?? item['speed_kmh'];
      final speed = rawSpeed != null
          ? '$rawSpeed km/h'
          : (item['latitude'] != null ? 'GPS Active' : 'Route Ready');
      return (
        raw: mapCopy,
        title: routeName,
        subtitle: driverName,
        status: 'ACTIVE BEAT',
        metricLabel: 'ROUTE STATUS',
        metricValue: speed,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Live Fleet Strip',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: skin.ink,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.rippleMint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${units.length} ACTIVE',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.rippleMint,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.push('/fleet/gps?mode=$industry'),
              icon: Icon(Icons.radar_rounded, size: 16, color: skin.primary),
              label: Text(
                'Open Radar',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: skin.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (units.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: skin.surface,
              borderRadius: BorderRadius.circular(skin.cardRadius),
              border: Border.all(color: skin.hairline),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 20, color: skin.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No active fleet telemetry units reported by server for this company.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: skin.muted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: units.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final u = units[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(skin.cardRadius),
                  onTap: () => _openOwnerDriverDetails(u.raw, isBulk),
                  child: Container(
                    width: 248,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: skin.surface,
                      borderRadius: BorderRadius.circular(skin.cardRadius),
                      border: Border.all(color: skin.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                u.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: skin.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.rippleMint.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                u.status,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.rippleMint,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          u.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: skin.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u.metricLabel,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: skin.muted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    u.metricValue,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: skin.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  context.push('/fleet/gps?mode=$industry'),
                              style: FilledButton.styleFrom(
                                backgroundColor: isDark
                                    ? skin.primary
                                    : AppColors.rippleLightInk,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                minimumSize: const Size(0, 34),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Track / Nav',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
      ],
    );
  }

  Widget _buildQuickModulesGrid({
    required RippleSkin skin,
    required bool isDark,
    required String industry,
  }) {
    final thirdModule = switch (industry) {
      'cafe_bakery' => (
          title: 'Cafe POS Terminal',
          subtitle: 'Touch billing & dining tables',
          icon: Icons.point_of_sale_rounded,
          color: AppColors.chaiPrimary,
          route: '/operations/cafe-pos',
        ),
      'bulk_water' => (
          title: 'Tanker Trip Desk',
          subtitle: 'Dispatch & sump decanting',
          icon: Icons.water_drop_rounded,
          color: AppColors.aquaPrimary,
          route: '/operations/tanker-dashboard',
        ),
      'packaged_water' => (
          title: 'Water Can Beat POS',
          subtitle: 'Route sales & empty audit',
          icon: Icons.local_shipping_rounded,
          color: AppColors.aquaPrimary,
          route: '/operations/can-sales',
        ),
      _ => (
          title: 'Collect Receivables',
          subtitle: 'Post customer settlements',
          icon: Icons.payments_rounded,
          color: AppColors.rippleMint,
          route: '/accounting/collect',
        ),
    };

    final fourthModule = switch (industry) {
      'cafe_bakery' => (
          title: 'Kitchen KOT Display',
          subtitle: 'Live prep orders & queue',
          icon: Icons.soup_kitchen_rounded,
          color: AppColors.chaiAction,
          route: '/operations/pos/kitchen',
        ),
      'bulk_water' => (
          title: 'Live Tanker Radar',
          subtitle: 'GPS position & flow status',
          icon: Icons.radar_rounded,
          color: AppColors.rippleSky,
          route: '/fleet/gps?mode=bulk_water',
        ),
      'packaged_water' => (
          title: 'Driver Surrender',
          subtitle: 'Verify route cash & empties',
          icon: Icons.price_check_rounded,
          color: AppColors.rippleMint,
          route: '/operations/driver-surrender',
        ),
      _ => (
          title: 'Expense Vouchers',
          subtitle: 'Record operational spends',
          icon: Icons.money_off_rounded,
          color: AppColors.rippleCoral,
          route: '/expenses/new',
        ),
    };

    final tiles = [
      (
        title: 'Sales Billing',
        subtitle: 'Create GST / cash invoices',
        icon: Icons.receipt_long_rounded,
        color: skin.primary,
        route: '/sales/new',
      ),
      (
        title: 'Physical Stock Count',
        subtitle: 'Godown & SKU verification',
        icon: Icons.inventory_2_rounded,
        color: AppColors.rippleMint,
        route: '/inventory/stock-count',
      ),
      thirdModule,
      fourthModule,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quick Modules',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: skin.ink,
              ),
            ),
            const Spacer(),
            Text(
              'Tap to launch',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: skin.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildQuickModuleTile(skin, tiles[0])),
                const SizedBox(width: 10),
                Expanded(child: _buildQuickModuleTile(skin, tiles[1])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildQuickModuleTile(skin, tiles[2])),
                const SizedBox(width: 10),
                Expanded(child: _buildQuickModuleTile(skin, tiles[3])),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: Icon(Icons.shopping_bag_rounded, size: 16, color: skin.primary),
                    label: const Text(
                      'Purchase Bill',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => context.push('/operations/quick-purchase'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.table_chart_rounded, size: 16, color: AppColors.rippleMint),
                    label: const Text(
                      '2026 Sheet Batch',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => context.push('/expenses/new'),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.cleaning_services_rounded, size: 16, color: AppColors.danger),
                    label: const Text(
                      'Go-Live Clean Reset',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                    onPressed: _showGoLiveResetDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showGoLiveResetDialog() async {
    final confirmCtrl = TextEditingController();
    var isSubmitting = false;
    String? errorMsg;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Expanded(child: Text('Go-Live Clean Reset', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clears demo sales, deliveries, tanker trips, POS orders & test expenses while preserving companies, ARAN1/ARAN2 branches, fleet vehicles, 8 pickup points, regular suppliers, accounts & logins.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                decoration: InputDecoration(
                  labelText: 'Type RESET-FOR-LIVE to confirm',
                  hintText: 'RESET-FOR-LIVE',
                  errorText: errorMsg,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (confirmCtrl.text.trim() != 'RESET-FOR-LIVE') {
                        setDialogState(() {
                          errorMsg = 'Enter exact text RESET-FOR-LIVE';
                        });
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                        errorMsg = null;
                      });
                      final res = await ref.read(apiClientProvider).post(
                            ApiEndpoints.adminResetDemoData,
                            data: const {
                              'confirmation': 'RESET-FOR-LIVE',
                              'confirm': 'RESET-FOR-LIVE',
                              'seed_masters': true,
                            },
                            fromJson: (d) => d,
                          );
                      if (!ctx.mounted) return;
                      if (res.isSuccess) {
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Demo data wiped cleanly! System ready for live trial.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadDashboardData();
                      } else {
                        setDialogState(() {
                          isSubmitting = false;
                          errorMsg = res.failureOrNull?.message ?? 'Reset failed. Check permissions.';
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Wipe Demo Data'),
            ),
          ],
        ),
      ),
    );

    confirmCtrl.dispose();
  }

  Widget _buildQuickModuleTile(
    RippleSkin skin,
    ({
      String title,
      String subtitle,
      IconData icon,
      Color color,
      String route,
    }) tile,
  ) {
    return RippleMenuTileCard(
      icon: tile.icon,
      title: tile.title,
      subtitle: tile.subtitle,
      accentColor: tile.color,
      onTap: () => context.push(tile.route),
    );
  }

  void _fitOwnerMapBounds(
    List<Map<String, dynamic>> customers,
    List<Map<String, dynamic>> vehicles,
  ) {
    if (!_ownerMapReady || !mounted) return;
    final points = <LatLng>[];
    for (final c in customers) {
      final lat = _parseCoord(c['latitude']);
      final lng = _parseCoord(c['longitude']);
      if (lat != null && lng != null) points.add(LatLng(lat, lng));
    }
    for (final v in vehicles) {
      final lat = _parseCoord(v['latitude']);
      final lng = _parseCoord(v['longitude']);
      if (lat != null && lng != null) points.add(LatLng(lat, lng));
    }
    if (points.isEmpty) {
      _ownerMapController.move(const LatLng(9.9252, 78.1198), 12.6);
      return;
    }
    if (points.length == 1) {
      _ownerMapController.move(points.first, 14.8);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _ownerMapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(36, 44, 36, 36),
      ),
    );
  }

  void _focusOwnerMapOnPoint(LatLng target, {double zoom = 15.2}) {
    if (!_ownerMapReady || !mounted) return;
    _ownerMapController.move(target, zoom);
  }

  String _ownerVehicleKeyOf(Map<String, dynamic> v, bool isBulk) {
    return '${isBulk ? 'tanker' : 'route'}_${v['id'] ?? v['vehicle_number'] ?? v['vehicle_no'] ?? v['route_name'] ?? ''}';
  }

  Map<String, dynamic>? _findOwnerSelectedCustomer(
    List<Map<String, dynamic>> customers,
  ) {
    if (_ownerSelectedCustomerId == null) return null;
    for (final c in customers) {
      final cid = int.tryParse(c['id']?.toString() ?? '') ?? -1;
      if (cid == _ownerSelectedCustomerId) return c;
    }
    return null;
  }

  Map<String, dynamic>? _findOwnerSelectedVehicle(
    List<Map<String, dynamic>> vehicles,
    bool isBulk,
  ) {
    if (_ownerSelectedVehicleKey == null) return null;
    for (final v in vehicles) {
      if (_ownerVehicleKeyOf(v, isBulk) == _ownerSelectedVehicleKey) return v;
    }
    return null;
  }

  void _onOwnerCustomerPinTapped(Map<String, dynamic> customer) {
    final cid = int.tryParse(customer['id']?.toString() ?? '') ?? 0;
    final lat = _parseCoord(customer['latitude']);
    final lng = _parseCoord(customer['longitude']);
    setState(() {
      _ownerSelectedCustomerId = cid;
      _ownerSelectedVehicleKey = null;
    });
    if (lat != null && lng != null) {
      _focusOwnerMapOnPoint(LatLng(lat + 0.0022, lng), zoom: 15.0);
    }
  }

  void _onOwnerVehiclePinTapped(Map<String, dynamic> vehicle, bool isBulk) {
    final lat = _parseCoord(vehicle['latitude']);
    final lng = _parseCoord(vehicle['longitude']);
    setState(() {
      _ownerSelectedVehicleKey = _ownerVehicleKeyOf(vehicle, isBulk);
      _ownerSelectedCustomerId = null;
    });
    if (lat != null && lng != null) {
      _focusOwnerMapOnPoint(LatLng(lat + 0.0022, lng), zoom: 15.0);
    }
  }

  void _openOwnerDriverDetails(Map<String, dynamic> vehicle, bool isBulk) {
    final lat = _parseCoord(vehicle['latitude']);
    final lng = _parseCoord(vehicle['longitude']);
    if (lat != null && lng != null) {
      _focusOwnerMapOnPoint(LatLng(lat, lng));
    }
    showDriverFullDetailsSheet(
      context,
      ref: ref,
      vehicle: vehicle,
      isTanker: isBulk,
      onCenterOnMap: (lat != null && lng != null)
          ? () => _focusOwnerMapOnPoint(LatLng(lat, lng))
          : null,
    );
  }

  void _openOwnerCustomerDetails(
    Map<String, dynamic> customer,
    String industry,
  ) {
    showCustomerFullDetailsSheet(
      context,
      ref: ref,
      customer: customer,
      isPackagedWater: industry == 'packaged_water',
    );
  }

  Widget _buildOwnerWaterGpsCommandSection({
    required RippleSkin skin,
    required bool isDark,
    required String industry,
  }) {
    final isBulk = industry == 'bulk_water';
    final vehicles = _extractFleetVehicles(_fleetLiveSnapshot, isBulk);
    final allCustomers = _extractFleetCustomers(_fleetLiveSnapshot);

    final paidCustomers =
        allCustomers.where((c) => _customerPaymentStatus(c) == 'paid').toList();
    final dueCustomers =
        allCustomers.where((c) => _customerPaymentStatus(c) != 'paid').toList();
    final overdueCustomers = allCustomers
        .where((c) => _customerPaymentStatus(c) == 'overdue')
        .toList();

    final totalPaid =
        allCustomers.fold<double>(0, (s, c) => s + _numVal(c['total_paid']));
    final totalDue =
        allCustomers.fold<double>(0, (s, c) => s + _numVal(c['due_amount']));
    final totalOverdue = allCustomers.fold<double>(
      0,
      (s, c) => s + _numVal(c['overdue_amount']),
    );

    final visibleCustomers = switch (_ownerMapFilter) {
      'drivers' => const <Map<String, dynamic>>[],
      'paid' => paidCustomers,
      'due' => dueCustomers,
      'overdue' => overdueCustomers,
      _ => allCustomers,
    };

    final selectedOwnerCustomer = _findOwnerSelectedCustomer(visibleCustomers);
    final selectedOwnerVehicle = _findOwnerSelectedVehicle(vehicles, isBulk);

    final filters = [
      (key: 'all', label: 'All (${vehicles.length + allCustomers.length})', color: skin.primary),
      (key: 'drivers', label: 'Drivers Only (${vehicles.length})', color: AppColors.rippleSky),
      (key: 'due', label: 'Due (${dueCustomers.length})', color: AppColors.warning),
      (key: 'overdue', label: 'Overdue (${overdueCustomers.length})', color: AppColors.danger),
      (key: 'paid', label: 'Paid (${paidCustomers.length})', color: AppColors.success),
    ];

    return Container(
      key: const ValueKey('owner_water_gps_command_section'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(skin.heroRadius),
        border: Border.all(
          color: AppColors.rippleSky.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.rippleSky)
                .withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row
          Row(
            children: [
              const RippleIconBadge(
                icon: Icons.radar_rounded,
                accentColor: AppColors.rippleSky,
                size: 38,
                iconSize: 20,
                radius: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBulk
                          ? 'Owner Live GPS: Bulk Tankers & Customer Map'
                          : 'Owner Live GPS: Delivery Boys & Customer Map',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: skin.ink,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live driver locations & customer Paid / Due / Overdue status',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: skin.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => context.push('/fleet/gps?mode=$industry'),
                style: FilledButton.styleFrom(
                  backgroundColor: skin.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: const Size(0, 34),
                  shape: const StadiumBorder(),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.open_in_full_rounded, size: 14),
                label: const Text(
                  'Full Screen Map',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Owner KPI Summary Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _OwnerKpiChip(
                  label: isBulk ? 'Tankers Live' : 'Drivers Live',
                  value: '${vehicles.length}',
                  color: AppColors.rippleSky,
                  onTap: () => setState(() => _ownerMapFilter = 'drivers'),
                ),
                const SizedBox(width: 8),
                _OwnerKpiChip(
                  label: 'Paid (${paidCustomers.length})',
                  value: _inrCompact.format(totalPaid),
                  color: AppColors.success,
                  onTap: () => setState(() => _ownerMapFilter = 'paid'),
                ),
                const SizedBox(width: 8),
                _OwnerKpiChip(
                  label: 'Due (${dueCustomers.length})',
                  value: _inrCompact.format(totalDue),
                  color: AppColors.warning,
                  onTap: () => setState(() => _ownerMapFilter = 'due'),
                ),
                const SizedBox(width: 8),
                _OwnerKpiChip(
                  label: 'Overdue (${overdueCustomers.length})',
                  value: _inrCompact.format(totalOverdue),
                  color: AppColors.danger,
                  onTap: () => setState(() => _ownerMapFilter = 'overdue'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Interactive Filter Chips
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final f = filters[index];
                final selected = _ownerMapFilter == f.key;
                return GestureDetector(
                  onTap: () => setState(() => _ownerMapFilter = f.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? f.color
                          : skin.surface2.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? f.color : skin.hairline,
                      ),
                    ),
                    child: Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : skin.ink,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 4. Embedded Live Interactive FlutterMap
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _ownerMapController,
                    options: MapOptions(
                      initialCenter: const LatLng(9.9252, 78.1198),
                      initialZoom: 12.6,
                      onMapReady: () {
                        if (!mounted) return;
                        _ownerMapReady = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _fitOwnerMapBounds(visibleCustomers, vehicles);
                          }
                        });
                      },
                      onTap: (_, __) {
                        if (_ownerSelectedCustomerId != null ||
                            _ownerSelectedVehicleKey != null) {
                          setState(() {
                            _ownerSelectedCustomerId = null;
                            _ownerSelectedVehicleKey = null;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.dkenterprises.dk_track_mobile',
                        tileProvider: _buildSafeTileProvider(),
                      ),
                      if (visibleCustomers.isNotEmpty)
                        CircleLayer(
                          circles: [
                            for (final c in visibleCustomers)
                              if (_parseCoord(c['latitude']) != null &&
                                  _parseCoord(c['longitude']) != null)
                                CircleMarker(
                                  point: LatLng(
                                    _parseCoord(c['latitude'])!,
                                    _parseCoord(c['longitude'])!,
                                  ),
                                  radius: _numVal(c['geofence_radius']) > 0
                                      ? _numVal(c['geofence_radius'])
                                      : 150,
                                  useRadiusInMeter: true,
                                  color: _colorForPaymentStatus(
                                    _customerPaymentStatus(c),
                                  ).withValues(alpha: 0.12),
                                  borderColor: _colorForPaymentStatus(
                                    _customerPaymentStatus(c),
                                  ).withValues(alpha: 0.55),
                                  borderStrokeWidth: 1.5,
                                ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          for (final c in visibleCustomers)
                            if (_parseCoord(c['latitude']) != null &&
                                _parseCoord(c['longitude']) != null)
                              Marker(
                                point: LatLng(
                                  _parseCoord(c['latitude'])!,
                                  _parseCoord(c['longitude'])!,
                                ),
                                width: 146,
                                height: 54,
                                alignment: Alignment.bottomCenter,
                                child: GestureDetector(
                                  onTap: () => _onOwnerCustomerPinTapped(c),
                                  child: CompactCustomerMapPin(
                                    name: c['name']?.toString() ?? 'Customer',
                                    paidAmount: _numVal(c['total_paid']),
                                    dueAmount: _numVal(c['due_amount']),
                                    status: _customerPaymentStatus(c),
                                    isSelected: _ownerSelectedCustomerId ==
                                        (int.tryParse(c['id']?.toString() ?? '') ??
                                            -1),
                                    compactFormatter: _inrCompact,
                                  ),
                                ),
                              ),
                          for (final v in vehicles)
                            if (_parseCoord(v['latitude']) != null &&
                                _parseCoord(v['longitude']) != null)
                              Marker(
                                point: LatLng(
                                  _parseCoord(v['latitude'])!,
                                  _parseCoord(v['longitude'])!,
                                ),
                                width: 176,
                                height: 50,
                                alignment: Alignment.center,
                                child: GestureDetector(
                                  onTap: () =>
                                      _onOwnerVehiclePinTapped(v, isBulk),
                                  child: _OwnerDriverMapPin(
                                    driverName: (v['driver_name'] ??
                                            v['assigned_driver'] ??
                                            'Driver')
                                        .toString(),
                                    vehicleNo: (v['vehicle_number'] ??
                                            v['vehicle_no'] ??
                                            v['tanker_number'] ??
                                            v['route_name'] ??
                                            'Unit')
                                        .toString()
                                        .split(' ')
                                        .first,
                                    speedKmh: _numVal(
                                      v['current_speed'] ?? v['speed_kmh'],
                                    ),
                                    isTanker: isBulk,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                  if (selectedOwnerCustomer != null ||
                      selectedOwnerVehicle != null)
                    Positioned(
                      top: 8,
                      left: 10,
                      right: 54,
                      child: Center(
                        child: selectedOwnerCustomer != null
                            ? CustomerMapCalloutBubble(
                                key: ValueKey(
                                  'customer_map_callout_bubble_${selectedOwnerCustomer['id']}',
                                ),
                                customer: selectedOwnerCustomer,
                                onClose: () => setState(
                                  () => _ownerSelectedCustomerId = null,
                                ),
                                onOpenFullDetails: () {
                                  final target = selectedOwnerCustomer;
                                  setState(
                                    () => _ownerSelectedCustomerId = null,
                                  );
                                  _openOwnerCustomerDetails(target, industry);
                                },
                              )
                            : DriverMapCalloutBubble(
                                key: const ValueKey(
                                  'driver_map_callout_bubble',
                                ),
                                vehicle: selectedOwnerVehicle!,
                                isTanker: isBulk,
                                onClose: () => setState(
                                  () => _ownerSelectedVehicleKey = null,
                                ),
                                onOpenFullDetails: () {
                                  final target = selectedOwnerVehicle;
                                  setState(
                                    () => _ownerSelectedVehicleKey = null,
                                  );
                                  _openOwnerDriverDetails(target, isBulk);
                                },
                              ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      children: [
                        Material(
                          color: skin.surface.withValues(alpha: 0.94),
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () =>
                                _fitOwnerMapBounds(visibleCustomers, vehicles),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.fit_screen_rounded,
                                size: 18,
                                color: skin.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Material(
                          color: skin.surface.withValues(alpha: 0.94),
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () =>
                                context.push('/fleet/gps?mode=$industry'),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.fullscreen_rounded,
                                size: 18,
                                color: skin.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_fleetLiveSnapshot == null ||
                      (vehicles.isEmpty && visibleCustomers.isEmpty))
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: skin.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: skin.hairline),
                        ),
                        child: Text(
                          _isLoading
                              ? 'Syncing live GPS fleet & customer pins...'
                              : 'Waiting for GPS telemetry or pull to refresh',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: skin.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 5. Active Drivers / Delivery Boys Locator Strip
          if (vehicles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isBulk
                        ? 'Active Tanker Drivers (${vehicles.length})'
                        : 'Active Delivery Boys (${vehicles.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: skin.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Tap driver for today timeline',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: skin.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final v = vehicles[index];
                  final driverName =
                      (v['driver_name'] ?? v['assigned_driver'] ?? 'Driver')
                          .toString();
                  final vehicleNo = (v['vehicle_number'] ??
                          v['vehicle_no'] ??
                          v['tanker_number'] ??
                          v['route_name'] ??
                          'Unit')
                      .toString();
                  final speed =
                      _numVal(v['current_speed'] ?? v['speed_kmh']);

                  return Material(
                    color: skin.canvas,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openOwnerDriverDetails(v, isBulk),
                      onLongPress: () => _openOwnerDriverDetails(v, isBulk),
                      child: Container(
                        width: 196,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.rippleSky.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppColors.rippleSky.withValues(alpha: 0.14),
                              child: Icon(
                                isBulk
                                    ? Icons.local_shipping_rounded
                                    : Icons.fire_truck_rounded,
                                size: 16,
                                color: AppColors.rippleSky,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    driverName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: skin.ink,
                                    ),
                                  ),
                                  Text(
                                    '$vehicleNo · ${speed.toStringAsFixed(0)} km/h',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.rippleSky,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnerKpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _OwnerKpiChip({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerDriverMapPin extends StatelessWidget {
  final String driverName;
  final String vehicleNo;
  final double speedKmh;
  final bool isTanker;

  const _OwnerDriverMapPin({
    required this.driverName,
    required this.vehicleNo,
    required this.speedKmh,
    required this.isTanker,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isTanker ? const Color(0xFF0369A1) : const Color(0xFF0EA5E9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.38),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTanker ? Icons.local_shipping_rounded : Icons.fire_truck_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$vehicleNo · ${speedKmh.toStringAsFixed(0)} km/h',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoMetricData {
  final String title;
  final String value;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color? valueColor;
  final VoidCallback onTap;

  const _BentoMetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    this.valueColor,
    required this.onTap,
  });
}

class _StitchAreaLinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  _StitchAreaLinePainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    // 3 dashed horizontal grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final ratio in [0.15, 0.5, 0.85]) {
      final y = size.height * ratio;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 5, size.width), y),
          gridPaint,
        );
        x += 9;
      }
    }

    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = (maxVal - minVal) <= 0 ? 1.0 : (maxVal - minVal);
    const padV = 12.0;
    final usableH = math.max(1.0, size.height - padV * 2);

    final points = <Offset>[];
    final divisor = values.length > 1 ? values.length - 1 : 1;
    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : (i / divisor) * size.width;
      final norm = (maxVal - minVal) <= 0 ? 0.5 : (values[i] - minVal) / range;
      final y = padV + usableH * (1 - norm);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrlX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(ctrlX, p0.dy, ctrlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.24),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, strokePaint);

    final peak = points.reduce((a, b) => a.dy <= b.dy ? a : b);
    canvas.drawCircle(peak, 5, Paint()..color = lineColor);
    canvas.drawCircle(
        peak,
        2.5,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _StitchAreaLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
