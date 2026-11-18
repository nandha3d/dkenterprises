import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/location_parser.dart';
import '../../operations/presentation/capture_location_dialog.dart';

class FieldAgentDashboardScreen extends ConsumerStatefulWidget {
  const FieldAgentDashboardScreen({super.key});

  @override
  ConsumerState<FieldAgentDashboardScreen> createState() =>
      _FieldAgentDashboardScreenState();
}

class _FieldAgentDashboardScreenState
    extends ConsumerState<FieldAgentDashboardScreen>
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

  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all' | 'dues' | 'no_gps' | 'geotagged'

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }

  Future<void> _loadAgentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiClient = ref.read(apiClientProvider);

    try {
      final res = await apiClient.get(
        '/mobile/dashboard/fieldAgent',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (mounted && res.isSuccess) {
        final raw = res.dataOrNull ?? <String, dynamic>{};
        final data = raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : (raw['data'] is Map
                ? Map<String, dynamic>.from(raw['data'] as Map)
                : raw);

        final custListRaw = (data['customers'] ?? data['top_due_customers'])
                as List<dynamic>? ??
            [];
        final custList = custListRaw
            .map((item) => item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{})
            .toList();

        setState(() {
          _dashboardData = data;
          _customers = custList;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    try {
      final custRes = await apiClient.get(
        '/mobile/customers',
        fromJson: (data) {
          if (data is List) return data;
          if (data is Map) {
            final inner = data['data'] ?? data['customers'];
            if (inner is List) return inner;
          }
          return const <dynamic>[];
        },
      );

      if (mounted) {
        if (custRes.isSuccess) {
          final list = (custRes.dataOrNull ?? [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          setState(() {
            _customers = list;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = custRes.failureOrNull?.message ??
                'Failed to load field agent customers';
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection timeout while loading field desk.';
          _isLoading = false;
        });
      }
    }
  }

  bool _hasGps(Map<String, dynamic> c) {
    final lat = (c['latitude'] as num?)?.toDouble();
    final lng = (c['longitude'] as num?)?.toDouble();
    return lat != null && lng != null && lat != 0 && lng != 0;
  }

  double _dueAmount(Map<String, dynamic> c) {
    final raw = c['due_amount'] ?? c['balance'] ?? c['outstanding'] ?? 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<int>(
      syncWorkerProvider.select((w) => w.state.pendingCount),
      (previous, next) {
        if (previous != null && next < previous) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadAgentData();
          });
        }
      },
    );

    ref.listen<int>(dashboardRefreshSignalProvider, (previous, next) {
      if (previous != null && next != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadAgentData();
        });
      }
    });

    final skin = RippleSkin.of(context);
    final pendingOutbox =
        ref.watch(syncWorkerProvider.select((w) => w.state.pendingCount));

    final data = _dashboardData ?? <String, dynamic>{};
    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : <String, dynamic>{};

    final totalCustomers =
        (summary['assigned_customers'] as num?)?.toInt() ?? _customers.length;
    final geocodedCustomers =
        (summary['geocoded_customers'] as num?)?.toInt() ??
            _customers.where(_hasGps).length;
    final missingGps = (totalCustomers - geocodedCustomers).clamp(0, 999999);

    final computedDues =
        _customers.fold<double>(0.0, (sum, c) => sum + _dueAmount(c));
    final totalReceivables =
        (summary['total_receivables'] as num?)?.toDouble() ?? computedDues;
    final todayCollected =
        (summary['today_collected'] as num?)?.toDouble() ?? 0.0;
    final recoveryRate =
        (summary['recovery_rate_percent'] as num?)?.toDouble() ??
            ((totalReceivables + todayCollected) > 0
                ? ((todayCollected / (totalReceivables + todayCollected)) * 100)
                : 0.0);

    final dueCustomersCount =
        _customers.where((c) => _dueAmount(c) > 0).length;

    final filteredCustomers = _customers.where((c) {
      if (_activeFilter == 'dues' && _dueAmount(c) <= 0) return false;
      if (_activeFilter == 'no_gps' && _hasGps(c)) return false;
      if (_activeFilter == 'geotagged' && !_hasGps(c)) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (c['name'] ?? '').toString().toLowerCase();
      final company = (c['company_name'] ?? '').toString().toLowerCase();
      final phone =
          (c['phone'] ?? c['phone_number'] ?? '').toString().toLowerCase();
      return name.contains(q) || company.contains(q) || phone.contains(q);
    }).toList();

    final geotagRatio = totalCustomers > 0
        ? (geocodedCustomers / totalCustomers).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: skin.canvas,
      body: RefreshIndicator(
        onRefresh: _loadAgentData,
        color: AppColors.sagePrimary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  if (_errorMessage != null && _customers.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.rippleRuby.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 18, color: AppColors.rippleRuby),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.rippleRuby,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadAgentData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),

                  // 1. Sub-header & Beat Context Bar (Stitch F-01)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.sagePrimary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me_rounded,
                                size: 14, color: AppColors.sagePrimary),
                            SizedBox(width: 4),
                            Text(
                              'ACTIVE BEAT • FIELD KYC',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.sagePrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.rippleMint.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.satellite_alt_rounded,
                                size: 13, color: AppColors.rippleMint),
                            const SizedBox(width: 4),
                            Text(
                              '$geocodedCustomers/$totalCustomers Geotagged',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.rippleMint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Field Collection & KYC Desk',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: skin.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Assigned Customer Receivables & GPS Onboarding',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: skin.muted,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Hero Card (#3F7D58 Field Sage Canvas)
                  _buildHeroSageCard(
                    totalReceivables: totalReceivables,
                    todayCollected: todayCollected,
                    totalCustomers: totalCustomers,
                    missingGps: missingGps,
                    recoveryRate: recoveryRate,
                  ),
                  const SizedBox(height: 14),

                  // 3. Primary Action Slabs (Collect Dues -> & + Onboard Client)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () =>
                                context.push('/accounting/collect'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.sageAction,
                              foregroundColor: AppColors.rippleLightInk,
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.payments_rounded, size: 20),
                            label: const Text(
                              'Collect Dues →',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/parties/customer-onboard'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: skin.surface,
                              foregroundColor: skin.ink,
                              side: BorderSide(color: skin.hairline),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 20,
                              color: AppColors.sagePrimary,
                            ),
                            label: const Text(
                              '+ Onboard Client',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4. Search Bar & Filter Pills
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: skin.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: skin.hairline),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            size: 20, color: skin.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search customer, shop or phone...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: skin.muted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: skin.muted),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip(
                          skin: skin,
                          keyName: 'all',
                          label: 'All Assigned ($totalCustomers)',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          skin: skin,
                          keyName: 'dues',
                          label: 'Outstanding Dues ($dueCustomersCount)',
                          accent: AppColors.rippleRuby,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          skin: skin,
                          keyName: 'no_gps',
                          label: 'No GPS Tag ($missingGps)',
                          accent: AppColors.rippleHoney,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          skin: skin,
                          keyName: 'geotagged',
                          label: 'Geotagged ($geocodedCustomers)',
                          accent: AppColors.rippleMint,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Priority Customer Receivables & Geotag Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ASSIGNED ROUTE PRIORITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: skin.muted,
                        ),
                      ),
                      Text(
                        '${filteredCustomers.length} Customers',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.sagePrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (filteredCustomers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: skin.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: skin.hairline),
                      ),
                      child: Text(
                        'No customers match the active filter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: skin.muted,
                        ),
                      ),
                    )
                  else
                    ...filteredCustomers.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildCustomerCard(
                          context: context,
                          skin: skin,
                          index: entry.key + 1,
                          customer: entry.value,
                        ),
                      );
                    }),

                  const SizedBox(height: 8),

                  // 6. Beat Progress Tracker & Sync Strip (Stitch F-01)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: skin.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: skin.hairline),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.route_rounded,
                                    size: 18, color: AppColors.sagePrimary),
                                const SizedBox(width: 6),
                                Text(
                                  'BEAT GEOTAG TRACKER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: skin.ink,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$geocodedCustomers / $totalCustomers Verified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: skin.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: geotagRatio,
                            minHeight: 8,
                            backgroundColor: skin.surface2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.sagePrimary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$pendingOutbox items in offline outbox',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: skin.muted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.rippleMint
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Ledger Verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.rippleMint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeroSageCard({
    required double totalReceivables,
    required double todayCollected,
    required int totalCustomers,
    required int missingGps,
    required double recoveryRate,
  }) {
    final ringVal = (recoveryRate / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sagePrimary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.sagePrimary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL RECEIVABLES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _inrWhole.format(totalReceivables),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'RECOVERY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sageAction,
                      ),
                    ),
                    Text(
                      '${recoveryRate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sageAction,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.south_west_rounded,
                    size: 16, color: AppColors.sageAction),
                const SizedBox(width: 6),
                Text(
                  _inrWhole.format(todayCollected),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.sageAction,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Collected Today',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalCustomers',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$missingGps No GPS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Field Recv.',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _inrCompact.format(todayCollected),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.sageAction,
                        ),
                      ),
                      Text(
                        'Settled Today',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 86,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: ringVal,
                            strokeWidth: 4,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.sageAction),
                          ),
                          Text(
                            '${recoveryRate.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recovery',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded,
                    size: 18, color: AppColors.sageAction),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Geofenced KYC & Instant Ledger Settlement Active (GL 1030)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  Widget _buildFilterChip({
    required RippleSkin skin,
    required String keyName,
    required String label,
    Color? accent,
  }) {
    final isSelected = _activeFilter == keyName;
    final fg = isSelected
        ? Colors.white
        : (accent ?? skin.ink);
    final bg = isSelected
        ? AppColors.rippleLightInk
        : skin.surface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => setState(() => _activeFilter = keyName),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.rippleLightInk : skin.hairline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard({
    required BuildContext context,
    required RippleSkin skin,
    required int index,
    required Map<String, dynamic> customer,
  }) {
    final customerId = (customer['id'] as num?)?.toInt() ?? 0;
    final name = (customer['name'] ?? 'Customer').toString();
    final company = (customer['company_name'] ?? '').toString();
    final address = (customer['address'] ?? customer['city'] ?? '').toString();
    final phone =
        (customer['phone_number'] ?? customer['phone'] ?? '').toString();
    final lat = (customer['latitude'] as num?)?.toDouble();
    final lng = (customer['longitude'] as num?)?.toDouble();
    final hasGps = _hasGps(customer);
    final due = _dueAmount(customer);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: skin.surface2,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '#$index',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: skin.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: skin.ink,
                      ),
                    ),
                    if (company.isNotEmpty || address.isNotEmpty)
                      Text(
                        [if (company.isNotEmpty) company, if (address.isNotEmpty) address]
                            .join(' • '),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: skin.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    due > 0 ? _inrWhole.format(due) : 'Cleared ✓',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: due > 0
                          ? AppColors.rippleRuby
                          : AppColors.rippleMint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    due > 0 ? 'OUTSTANDING' : 'NO DUES',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: due > 0
                          ? AppColors.rippleRuby
                          : AppColors.rippleMint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasGps && lat != null && lng != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.rippleMint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pin_drop_rounded,
                      size: 13, color: AppColors.rippleMint),
                  const SizedBox(width: 4),
                  Text(
                    'Geotagged (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.rippleMint,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.rippleHoney.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.rippleHoney),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No GPS Tagged — Please record live geotag at premise.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: skin.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: skin.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.contact_phone_rounded,
                      size: 15, color: skin.ink),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      phone,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: skin.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      CaptureLocationDialog.show(
                        context,
                        customerId: customerId,
                        customerName: name,
                        currentLat: lat,
                        currentLng: lng,
                        onLocationUpdated: _loadAgentData,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: hasGps
                          ? skin.surface2
                          : AppColors.sagePrimary,
                      foregroundColor: hasGps ? skin.ink : Colors.white,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                    label: Text(
                      hasGps ? 'Update GPS' : 'Tag GPS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (hasGps && lat != null && lng != null) ...[
                IconButton.filledTonal(
                  onPressed: () => LocationParser.launchNavigation(lat, lng),
                  style: IconButton.styleFrom(
                    backgroundColor: skin.surface2,
                    foregroundColor: AppColors.rippleSky,
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  tooltip: 'Navigate',
                ),
                const SizedBox(width: 8),
              ] else if (phone.isNotEmpty) ...[
                IconButton.filledTonal(
                  onPressed: () async {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) launchUrl(uri);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: skin.surface2,
                    foregroundColor: skin.ink,
                  ),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  tooltip: 'Call',
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 42,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/accounting/collect'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sageAction,
                      foregroundColor: AppColors.rippleLightInk,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.currency_rupee_rounded, size: 16),
                    label: const Text(
                      'Collect',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
