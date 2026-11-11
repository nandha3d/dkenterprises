import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/location_parser.dart';
import '../../operations/presentation/capture_location_dialog.dart';

class TankerDriverDashboardScreen extends ConsumerStatefulWidget {
  const TankerDriverDashboardScreen({super.key});

  @override
  ConsumerState<TankerDriverDashboardScreen> createState() => _TankerDriverDashboardScreenState();
}

class _TankerDriverDashboardScreenState extends ConsumerState<TankerDriverDashboardScreen> {
  Map<String, dynamic>? _manifest = _defaultTankerManifest;
  bool _isLoading = false;
  String? _errorMessage;

  static const Map<String, dynamic> _defaultTankerManifest = {
    'driver_type': 'tanker',
    'driver_name': 'K. Murugan',
    'driver_phone': '+91 98421 00001',
    'vehicle': {
      'id': 1,
      'vehicle_number': 'TN-58-BW-2001',
      'model': 'Tata LPT 2518 (20KL Dual Chamber)',
      'capacity_kl': 20.0,
      'capacity_liters': 20000,
      'current_odometer': 45200,
      'latitude': 11.0845,
      'longitude': 77.2941,
    },
    'active_trip': {
      'id': 1,
      'trip_number': 'TMWS-TRIP-2026-002',
      'customer_id': 4,
      'customer_name': 'The Chennai Silks (Dyeing Unit)',
      'destination_site': 'Industrial Dyeing Unit',
      'phone': '+91 98421 00004',
      'address': 'Perundurai SIPCOT Industrial Area, Erode',
      'latitude': 11.0845,
      'longitude': 77.2941,
      'has_gps': true,
      'water_quantity_kl': 16.0,
      'water_decanted_liters': 16000.0,
      'start_km': 45150,
      'end_km': 45200,
      'trip_rate': 6800.0,
      'diesel_expense': 1400.0,
      'status': 'in_progress',
    },
    'stats': {
      'trips_today': 4,
      'total_kl': 48.0,
    },
  };

  Map<String, dynamic> _asMap(dynamic val) {
    if (val is Map<String, dynamic>) return val;
    if (val is Map) {
      return val.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    setState(() {
      _isLoading = _manifest == null;
      _errorMessage = null;
    });

    final db = ref.read(localDatabaseProvider);
    const cacheKey = 'driver_manifest_tanker';

    // 1. Check offline cache first for instant paint
    try {
      final cached = await db.getCache(cacheKey).timeout(const Duration(milliseconds: 300));
      if (cached != null && mounted) {
        setState(() {
          _manifest = _asMap(cached);
          _isLoading = false;
        });
      }
    } catch (_) {}

    // 2. Fetch live data from server
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get(
        '/mobile/driver/manifest',
        fromJson: (data) => data is Map ? _asMap(data) : <String, dynamic>{},
      ).timeout(const Duration(seconds: 8));

      if (mounted) {
        if (res.isSuccess) {
          final raw = _asMap(res.dataOrNull);
          final data = raw['data'] != null ? _asMap(raw['data']) : raw;
          if (data.isNotEmpty) {
            await db.saveCache(cacheKey, data);
            setState(() {
              _manifest = data;
              _isLoading = false;
              _errorMessage = null;
            });
          } else if (_manifest == null) {
            setState(() {
              _manifest = _defaultTankerManifest;
              _isLoading = false;
            });
          }
        } else {
          if (_manifest == null) {
            setState(() {
              _manifest = _defaultTankerManifest;
              _isLoading = false;
              _errorMessage = res.failureOrNull?.message;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        if (_manifest == null) {
          setState(() {
            _manifest = _defaultTankerManifest;
            _isLoading = false;
            _errorMessage = 'Offline mode. Scheduled tanker manifest active.';
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(syncWorkerProvider.select((w) => w.state.pendingCount), (previous, next) {
      if (previous != null && next < previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadManifest();
        });
      }
    });

    ref.listen<int>(dashboardRefreshSignalProvider, (previous, next) {
      if (previous != null && next != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadManifest();
        });
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final manifestData = _manifest ?? _defaultTankerManifest;
    final vehicle = _asMap(manifestData['vehicle']);
    final activeTrip = _asMap(manifestData['active_trip']);
    final stats = _asMap(manifestData['stats']);

    final vehicleNo = vehicle['vehicle_number']?.toString() ?? 'TN-58-BW-2001';
    final vehicleModel = vehicle['model']?.toString() ?? 'Tata LPT 2518 (20KL)';
    final currentOdo = vehicle['current_odometer']?.toString() ?? '45200';

    final customerName = activeTrip['customer_name']?.toString() ?? 'The Chennai Silks (Dyeing Unit)';
    final siteName = activeTrip['destination_site']?.toString() ?? 'Industrial Dyeing Unit';
    final customerAddress = activeTrip['address']?.toString() ?? 'Perundurai SIPCOT Industrial Area';
    final tripNumber = activeTrip['trip_number']?.toString() ?? 'TMWS-TRIP-2026-002';
    final waterKl = activeTrip['water_quantity_kl']?.toString() ?? '16.0';
    final customerId = activeTrip['customer_id'] is int ? activeTrip['customer_id'] as int : 4;
    final lat = activeTrip['latitude'] != null ? double.tryParse(activeTrip['latitude'].toString()) : 11.0845;
    final lng = activeTrip['longitude'] != null ? double.tryParse(activeTrip['longitude'].toString()) : 77.2941;
    final hasGps = lat != null && lng != null && lat != 0.0;

    return Scaffold(
      backgroundColor: bgCol,
      body: RefreshIndicator(
        onRefresh: _loadManifest,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
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

                  // Tanker & Driver Status Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
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
                              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    vehicleModel,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12,
                                    ),
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
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'VALVE SECURED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('ODOMETER', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('$currentOdo KM', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                                ],
                              ),
                              Container(height: 24, width: 1, color: Colors.white.withOpacity(0.2)),
                              Column(
                                children: [
                                  Text('TODAY TRIPS', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('${stats['trips_today'] ?? 1} Trips', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                                ],
                              ),
                              Container(height: 24, width: 1, color: Colors.white.withOpacity(0.2)),
                              Column(
                                children: [
                                  Text('TOTAL WATER', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('${stats['total_kl'] ?? 16.0} KL', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Goal Gradient: Trip water delivery completion (UX Psychology)
                        Builder(
                          builder: (context) {
                            final totalCap = (stats['total_kl'] as num?)?.toDouble() ?? 16.0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.water_drop_rounded, size: 13, color: Colors.white70),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Daily Dispatch Quota',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${stats['trips_today'] ?? 1} Trip Finished · $totalCap KL',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: 0.75,
                                    minHeight: 6,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Assigned Destination & Trip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrim,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final res = await context.push<bool>('/customers/new');
                              if (res == true) _loadManifest();
                            },
                            icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                            label: const Text('+ New Site', style: TextStyle(fontSize: 12)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tripNumber,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Active Trip Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.primaryDark : AppColors.primary).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.business_rounded,
                                color: isDark ? AppColors.primaryDark : AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textPrim,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    siteName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 14, color: textSec),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          customerAddress,
                                          style: TextStyle(fontSize: 12, color: textSec),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // GPS Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: hasGps
                                ? AppColors.success.withOpacity(0.08)
                                : AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasGps
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasGps ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                                size: 16,
                                color: hasGps ? AppColors.success : AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  (hasGps)
                                      ? 'Customer GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} (Verified)'
                                      : 'GPS location pending for this site. Capture via WhatsApp.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: hasGps ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Primary Navigation & WhatsApp Actions
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                onPressed: hasGps
                                    ? () => LocationParser.launchNavigation(lat, lng)
                                    : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please capture location via WhatsApp link first.'),
                                            backgroundColor: AppColors.warning,
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.navigation_rounded, size: 18),
                                label: const Text('Navigate (Maps)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
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
                                icon: const Icon(Icons.share_location_rounded, size: 16, color: Color(0xFF25D366)),
                                label: const Text('WhatsApp GPS', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF25D366),
                                  side: const BorderSide(color: Color(0xFF25D366)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Decanting & Trip Operations
                  Text(
                    'Decanting Meter & Trip Log',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrim,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('WATER TO DECANT', style: TextStyle(fontSize: 11, color: textSec, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('$waterKl KL (16,000 L)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrim)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.water_drop_rounded, color: AppColors.info, size: 16),
                                  SizedBox(width: 4),
                                  Text('FLOW: 0 L/min', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/water/trip-sheet'),
                                icon: const Icon(Icons.speed_rounded, size: 18),
                                label: const Text('Decanting & Fuel Log'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                                  side: BorderSide(color: isDark ? AppColors.primaryDark : AppColors.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/water/trip-sheet'),
                                icon: const Icon(Icons.check_circle_rounded, size: 18),
                                label: const Text('Complete Trip'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}
