import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/location_parser.dart';
import '../../operations/presentation/capture_location_dialog.dart';

class CanDeliveryDriverDashboardScreen extends ConsumerStatefulWidget {
  const CanDeliveryDriverDashboardScreen({super.key});

  @override
  ConsumerState<CanDeliveryDriverDashboardScreen> createState() => _CanDeliveryDriverDashboardScreenState();
}

class _CanDeliveryDriverDashboardScreenState extends ConsumerState<CanDeliveryDriverDashboardScreen> {
  Map<String, dynamic>? _manifest;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiClient = ref.read(apiClientProvider);
    final res = await apiClient.get(
      '/mobile/driver/manifest',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (mounted) {
      if (res.isSuccess) {
        final raw = res.dataOrNull ?? <String, dynamic>{};
        final data = raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : (raw['data'] is Map ? Map<String, dynamic>.from(raw['data'] as Map) : raw);
        setState(() {
          _manifest = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = res.failureOrNull?.message ?? 'Failed to load driver manifest';
          _isLoading = false;
        });
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

    final vehicle = _manifest?['vehicle'] as Map<String, dynamic>? ?? {};
    final canInventory = _manifest?['can_inventory'] as Map<String, dynamic>? ?? {};
    final stops = (_manifest?['stops'] as List<dynamic>? ?? []);
    final cash = _manifest?['cash'] as Map<String, dynamic>? ?? {};

    final vehicleNo = vehicle['vehicle_number']?.toString() ?? 'TN-58-WA-101 (Tata Ace)';
    final routeName = vehicle['route_name']?.toString() ?? 'Anna Nagar & Teppakulam Route';

    final loadedCans = canInventory['loaded_cans'] ?? 60;
    final deliveredCans = canInventory['delivered_cans'] ?? 25;
    final emptyCans = canInventory['empty_cans_on_truck'] ?? 20;
    final remainingCans = canInventory['remaining_full_cans'] ?? 35;

    final cashInHand = (cash['in_hand'] as num?)?.toDouble() ?? 1450.0;

    return Scaffold(
      backgroundColor: bgCol,
      body: RefreshIndicator(
        onRefresh: _loadManifest,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.12),
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
                            onPressed: _loadManifest,
                          ),
                        ],
                      ),
                    ),
                  // Truck & Manifest Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFF059669), const Color(0xFF047857)],
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
                              child: const Icon(Icons.airport_shuttle_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicleNo,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    routeName,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ACTIVE BEAT',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Can inventory counters
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildManifestCounter('LOADED', '$loadedCans'),
                              _buildDivider(),
                              _buildManifestCounter('DELIVERED', '$deliveredCans'),
                              _buildDivider(),
                              _buildManifestCounter('EMPTY CANS', '$emptyCans'),
                              _buildDivider(),
                              _buildManifestCounter('REMAINING', '$remainingCans'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Route Beat Stops Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Route Beat Customer Stops (${stops.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrim,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final res = await context.push<bool>('/customers/new');
                              if (res == true) _loadManifest();
                            },
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                            label: const Text('+ Customer', style: TextStyle(fontSize: 12)),
                          ),
                          TextButton.icon(
                            onPressed: () => context.push('/operations/can-sales'),
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                            label: const Text('Spot Bill', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stops List
                  if (stops.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol),
                      ),
                      child: Center(
                        child: Text('No delivery stops assigned for today.', style: TextStyle(color: textSec)),
                      ),
                    )
                  else
                    ...stops.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final stop = entry.value is Map<String, dynamic>
                          ? entry.value as Map<String, dynamic>
                          : (entry.value is Map ? Map<String, dynamic>.from(entry.value as Map) : <String, dynamic>{});
                      final customerId = stop['customer_id'] is int ? stop['customer_id'] as int : 5;
                      final customerName = stop['name']?.toString() ?? 'Customer';
                      final customerAddress = stop['address']?.toString() ?? '';
                      final cans = stop['cans_delivered'] ?? 25;
                      final empty = stop['empty_cans_returned'] ?? 20;
                      final lat = stop['latitude'] != null ? double.tryParse(stop['latitude'].toString()) : null;
                      final lng = stop['longitude'] != null ? double.tryParse(stop['longitude'].toString()) : null;
                      final hasGps = lat != null && lng != null && lat != 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderCol),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primary).withOpacity(0.12),
                                  child: Text(
                                    '$idx',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName,
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrim),
                                      ),
                                      if (customerAddress.isNotEmpty)
                                        Text(
                                          customerAddress,
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
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$cans Cans · $empty Empty',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.info),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // GPS Status & Actions Bar
                            Row(
                              children: [
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
                                        size: 13,
                                        color: hasGps ? AppColors.success : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasGps ? 'GPS Verified' : 'No GPS Set',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: hasGps ? AppColors.success : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // 1-Tap Navigate Button
                                ElevatedButton.icon(
                                  onPressed: hasGps
                                      ? () => LocationParser.launchNavigation(lat, lng)
                                      : () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please capture customer GPS via WhatsApp first.'),
                                              backgroundColor: AppColors.warning,
                                            ),
                                          );
                                        },
                                  icon: const Icon(Icons.navigation_rounded, size: 14),
                                  label: const Text('Navigate', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // WhatsApp GPS Capture Button
                                OutlinedButton.icon(
                                  onPressed: () {
                                    CaptureLocationDialog.show(
                                      context,
                                      customerId: customerId,
                                      customerName: customerName,
                                      currentAddress: customerAddress,
                                      currentLat: lat,
                                      currentLng: lng,
                                      onLocationUpdated: _loadManifest,
                                    );
                                  },
                                  icon: const Icon(Icons.share_location_rounded, size: 14, color: Color(0xFF25D366)),
                                  label: const Text('WhatsApp', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF25D366),
                                    side: const BorderSide(color: Color(0xFF25D366)),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  const SizedBox(height: 16),

                  // Shift Collections & Cash Surrender Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('COLLECTED CASH IN POUCH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSec)),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${cashInHand.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    color: textPrim,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/water/driver-surrender'),
                              icon: const Icon(Icons.payments_rounded, size: 16),
                              label: const Text('Surrender Cash'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildManifestCounter(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 24, width: 1, color: Colors.white.withOpacity(0.2));
  }
}
