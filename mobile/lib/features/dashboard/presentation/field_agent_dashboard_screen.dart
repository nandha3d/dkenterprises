import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/kpi_card.dart';
import '../../../core/utils/location_parser.dart';
import '../../operations/presentation/capture_location_dialog.dart';

class FieldAgentDashboardScreen extends ConsumerStatefulWidget {
  const FieldAgentDashboardScreen({super.key});

  @override
  ConsumerState<FieldAgentDashboardScreen> createState() => _FieldAgentDashboardScreenState();
}

class _FieldAgentDashboardScreenState extends ConsumerState<FieldAgentDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

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

      if (mounted) {
        if (res.isSuccess) {
          final raw = res.dataOrNull ?? <String, dynamic>{};
          final data = raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : (raw['data'] is Map ? Map<String, dynamic>.from(raw['data'] as Map) : raw);

          final custListRaw = (data['customers'] ?? data['top_due_customers']) as List<dynamic>? ?? [];
          final custList = custListRaw
              .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
              .toList();

          setState(() {
            _dashboardData = data;
            _customers = custList;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Fallback to /mobile/customers
    }

    // Fallback if dashboard endpoint had an issue
    final custRes = await apiClient.get(
      '/mobile/customers',
      fromJson: (data) => data as List<dynamic>,
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
          _errorMessage = custRes.failureOrNull?.message ?? 'Failed to load field agent data';
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
          if (mounted) _loadAgentData();
        });
      }
    });

    ref.listen<int>(dashboardRefreshSignalProvider, (previous, next) {
      if (previous != null && next != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadAgentData();
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
    final summary = data['summary'] is Map ? Map<String, dynamic>.from(data['summary'] as Map) : <String, dynamic>{};

    final totalCustomers = (summary['assigned_customers'] as num?)?.toInt() ?? _customers.length;
    final geocodedCustomers = (summary['geocoded_customers'] as num?)?.toInt() ??
        _customers.where((c) => c['latitude'] != null && c['longitude'] != null && c['latitude'] != 0).length;
    final missingGps = totalCustomers - geocodedCustomers;
    final totalReceivables = (summary['total_receivables'] as num?)?.toDouble() ?? 2100.0;
    final todayCollected = (summary['today_collected'] as num?)?.toDouble() ?? 1450.0;
    final recoveryRate = (summary['recovery_rate_percent'] as num?)?.toDouble() ?? 85.0;
    final overdueCount = (summary['overdue_accounts_count'] as num?)?.toInt() ?? 2;

    final filteredCustomers = _customers.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (c['name'] ?? '').toString().toLowerCase();
      final company = (c['company_name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? c['phone_number'] ?? '').toString().toLowerCase();
      return name.contains(q) || company.contains(q) || phone.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: bgCol,
      body: RefreshIndicator(
        onRefresh: _loadAgentData,
        child: _isLoading && _customers.isEmpty
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
                            onPressed: _loadAgentData,
                          ),
                        ],
                      ),
                    ),

                  // Agent Header Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFF4F46E5), const Color(0xFF4338CA)],
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
                              child: const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Field Collection & KYC Desk',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Assigned Customer Receivables & GPS Onboarding',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ACTIVE BEAT',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
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
                        title: 'Assigned Accounts',
                        customValue: '$totalCustomers Accounts',
                        icon: Icons.people_alt_rounded,
                        iconColor: AppColors.primary,
                        subtitle: '$geocodedCustomers Geocoded · $missingGps Missing',
                      ),
                      KpiCard(
                        title: 'Total Receivables',
                        amount: totalReceivables,
                        icon: Icons.call_received_rounded,
                        iconColor: AppColors.warning,
                        subtitle: '$overdueCount Overdue (>30 days)',
                        onTap: () => context.push('/accounting/collect'),
                      ),
                      KpiCard(
                        title: "Today's Collected",
                        amount: todayCollected,
                        icon: Icons.verified_rounded,
                        iconColor: AppColors.success,
                        subtitle: 'Direct field collections',
                        onTap: () => context.push('/accounting/collect'),
                      ),
                      KpiCard(
                        title: 'Recovery Rate',
                        customValue: '$recoveryRate%',
                        icon: Icons.insights_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        subtitle: 'Target: 90.0%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/accounting/collect'),
                          icon: const Icon(Icons.payments_rounded, size: 18),
                          label: const Text('Collect Dues', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/customers/onboard'),
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                          label: const Text('Onboard Client', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                            side: BorderSide(color: isDark ? AppColors.primaryDark : AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderCol),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        icon: Icon(Icons.search, color: textSec, size: 20),
                        hintText: 'Search customer name, enterprise or phone...',
                        hintStyle: TextStyle(color: textSec, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Accounts Directory Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned Customers (${filteredCustomers.length})',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrim),
                      ),
                      Text(
                        '$missingGps Need GPS Pin',
                        style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (filteredCustomers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol),
                      ),
                      child: Center(
                        child: Text(
                          _searchQuery.isNotEmpty ? 'No customer matches your search.' : 'No customers assigned.',
                          style: TextStyle(color: textSec),
                        ),
                      ),
                    )
                  else
                    ...filteredCustomers.map((c) {
                      final customerId = c['id'] is int ? c['id'] as int : int.tryParse(c['id']?.toString() ?? '0') ?? 0;
                      final name = c['name']?.toString() ?? 'Customer';
                      final company = c['company_name']?.toString() ?? '';
                      final phone = (c['phone'] ?? c['phone_number'])?.toString() ?? '';
                      final address = c['address']?.toString() ?? '';
                      final city = c['city']?.toString() ?? '';
                      final lat = c['latitude'] != null ? double.tryParse(c['latitude'].toString()) : null;
                      final lng = c['longitude'] != null ? double.tryParse(c['longitude'].toString()) : null;
                      final hasGps = lat != null && lng != null && lat != 0.0;
                      final dueAmount = (c['due_amount'] as num?)?.toDouble() ?? 0.0;
                      final isOverdue = c['is_overdue'] == true || dueAmount > 1500;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderCol),
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
                                        name,
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrim),
                                      ),
                                      if (company.isNotEmpty && company != name)
                                        Text(
                                          company,
                                          style: TextStyle(fontSize: 12, color: textSec, fontWeight: FontWeight.w500),
                                        ),
                                      if (phone.isNotEmpty || address.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '$phone ${city.isNotEmpty ? "· $city" : (address.isNotEmpty ? "· $address" : "")}',
                                            style: TextStyle(fontSize: 11, color: textSec),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (dueAmount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (isOverdue ? AppColors.danger : AppColors.warning).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'DUE: ₹${dueAmount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isOverdue ? AppColors.danger : AppColors.warning,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'CLEAR',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: hasGps ? AppColors.success.withOpacity(0.08) : AppColors.warning.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            hasGps ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                                            size: 10,
                                            color: hasGps ? AppColors.success : AppColors.warning,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            hasGps ? 'Geotagged' : 'No GPS',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: hasGps ? AppColors.success : AppColors.warning,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: borderCol.withOpacity(0.6)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (phone.isNotEmpty)
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.phone_in_talk_rounded, size: 18, color: Color(0xFF0284C7)),
                                        tooltip: 'Call Customer',
                                        onPressed: () async {
                                          final uri = Uri.parse('tel:$phone');
                                          if (await canLaunchUrl(uri)) launchUrl(uri);
                                        },
                                      ),
                                    if (hasGps)
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.directions_rounded, size: 18, color: Color(0xFF059669)),
                                        tooltip: 'Navigate via Google Maps',
                                        onPressed: () => LocationParser.launchNavigation(lat, lng),
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        CaptureLocationDialog.show(
                                          context,
                                          customerId: customerId,
                                          customerName: name,
                                          currentLat: lat,
                                          currentLng: lng,
                                          onLocationUpdated: () => _loadAgentData(),
                                        );
                                      },
                                      icon: const Icon(Icons.pin_drop_outlined, size: 14),
                                      label: Text(hasGps ? 'Update GPS' : 'Tag GPS', style: const TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        side: BorderSide(color: borderCol),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => context.push('/accounting/collect'),
                                      icon: const Icon(Icons.payments_rounded, size: 14),
                                      label: const Text('Collect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF059669),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
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
