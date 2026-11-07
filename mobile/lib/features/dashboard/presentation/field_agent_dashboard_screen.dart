import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../operations/presentation/capture_location_dialog.dart';

class FieldAgentDashboardScreen extends ConsumerStatefulWidget {
  const FieldAgentDashboardScreen({super.key});

  @override
  ConsumerState<FieldAgentDashboardScreen> createState() => _FieldAgentDashboardScreenState();
}

class _FieldAgentDashboardScreenState extends ConsumerState<FieldAgentDashboardScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final apiClient = ref.read(apiClientProvider);
    final res = await apiClient.get(
      '/mobile/customers',
      fromJson: (data) => data as List<dynamic>,
    );

    if (mounted) {
      if (res.isSuccess) {
        final list = (res.dataOrNull ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        setState(() {
          _customers = list;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bgCol,
      body: RefreshIndicator(
        onRefresh: _loadCustomers,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/accounting/collect'),
                          icon: const Icon(Icons.payments_rounded, size: 18),
                          label: const Text('Collect Dues'),
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
                          label: const Text('Onboard Client'),
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
                  const SizedBox(height: 20),

                  // Customer Accounts Directory with WhatsApp Location Update
                  Text(
                    'Assigned Customer Accounts (${_customers.length})',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrim),
                  ),
                  const SizedBox(height: 10),

                  if (_customers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol),
                      ),
                      child: Center(
                        child: Text('No customers assigned to this agent.', style: TextStyle(color: textSec)),
                      ),
                    )
                  else
                    ..._customers.map((c) {
                      final customerId = c['id'] is int ? c['id'] as int : int.parse(c['id'].toString());
                      final name = c['name']?.toString() ?? 'Customer';
                      final phone = c['phone']?.toString() ?? '';
                      final address = c['address']?.toString() ?? '';
                      final lat = c['latitude'] != null ? double.tryParse(c['latitude'].toString()) : null;
                      final lng = c['longitude'] != null ? double.tryParse(c['longitude'].toString()) : null;
                      final hasGps = lat != null && lng != null && lat != 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
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
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrim),
                                      ),
                                      if (phone.isNotEmpty || address.isNotEmpty)
                                        Text(
                                          '$phone ${address.isNotEmpty ? "· $address" : ""}',
                                          style: TextStyle(fontSize: 12, color: textSec),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: hasGps ? AppColors.success.withOpacity(0.08) : AppColors.warning.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        hasGps ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                                        size: 12,
                                        color: hasGps ? AppColors.success : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasGps ? 'GPS Saved' : 'No GPS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: hasGps ? AppColors.success : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    CaptureLocationDialog.show(
                                      context,
                                      customerId: customerId,
                                      customerName: name,
                                      currentAddress: address,
                                      currentLat: lat,
                                      currentLng: lng,
                                      onLocationUpdated: _loadCustomers,
                                    );
                                  },
                                  icon: const Icon(Icons.share_location_rounded, size: 14, color: Color(0xFF25D366)),
                                  label: const Text('Update WhatsApp GPS', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF25D366),
                                    side: const BorderSide(color: Color(0xFF25D366)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/accounting/collect'),
                                  icon: const Icon(Icons.receipt_rounded, size: 14),
                                  label: const Text('Collect Cash', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
