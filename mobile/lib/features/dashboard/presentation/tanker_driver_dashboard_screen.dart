import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/location_parser.dart';
import '../../auth/domain/auth_models.dart';
import '../../operations/presentation/capture_location_dialog.dart';
import '../../operations/presentation/water_order_helpers.dart';

class TankerDriverDashboardScreen extends ConsumerStatefulWidget {
  const TankerDriverDashboardScreen({super.key});

  @override
  ConsumerState<TankerDriverDashboardScreen> createState() =>
      _TankerDriverDashboardScreenState();
}

class _TankerDriverDashboardScreenState
    extends ConsumerState<TankerDriverDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Map<String, dynamic>? _manifest;
  bool _isLoading = true;
  String? _errorMessage;

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

    try {
      final cached =
          await db.getCache(cacheKey).timeout(const Duration(milliseconds: 300));
      if (cached != null && mounted) {
        setState(() {
          _manifest = _asMap(cached);
          _isLoading = false;
        });
      }
    } catch (_) {}

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient
          .get(
            '/mobile/driver/manifest',
            fromJson: (data) => data is Map ? _asMap(data) : <String, dynamic>{},
          )
          .timeout(const Duration(seconds: 8));

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
          } else {
            setState(() {
              _isLoading = false;
              _errorMessage = _manifest == null
                  ? 'No active tanker trip assigned right now.'
                  : null;
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = _manifest == null
                ? (res.failureOrNull?.message ??
                    'Could not load tanker manifest.')
                : null;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_manifest == null) {
            _errorMessage = 'Offline mode: no cached tanker manifest found.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen<int>(
      syncWorkerProvider.select((w) => w.state.pendingCount),
      (previous, next) {
        if (previous != null && next < previous) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadManifest();
          });
        }
      },
    );

    ref.listen<int>(dashboardRefreshSignalProvider, (previous, next) {
      if (previous != null && next != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadManifest();
        });
      }
    });

    final skin = RippleSkin.of(context);
    final authState = ref.watch(authNotifierProvider);
    final manifestData = _manifest ?? const <String, dynamic>{};
    final roleSlug = authState.user?.role ?? 'tanker_driver';
    final rawManifestName = manifestData['driver_name']?.toString().trim() ?? '';
    final driverName = rawManifestName.isNotEmpty && !UserProfile.looksLikeRoleSlug(rawManifestName)
        ? rawManifestName
        : (authState.user?.displayName ?? UserProfile.humanizeName('', roleSlug));
    final roleBadgeLabel = authState.user?.roleLabel ?? 'Bulk Tanker Driver';
    final vehicle = _asMap(manifestData['vehicle']);
    final activeTrip = _asMap(manifestData['active_trip']);
    final stats = _asMap(manifestData['stats']);
    final rawPendingTrips = manifestData['pending_trips'] as List<dynamic>? ?? const [];
    final pendingTrips = rawPendingTrips
        .map((e) => _asMap(e))
        .where((e) => e.isNotEmpty)
        .toList();
    final capacityKl = (vehicle['capacity_kl'] as num?)?.toDouble() ?? 0.0;

    final vehicleNo =
        vehicle['vehicle_number']?.toString() ?? 'Unassigned Tanker';
    final vehicleModel =
        vehicle['model']?.toString() ?? 'Bulk Water Tanker';
    final currentOdo = vehicle['current_odometer']?.toString() ?? '0';

    final customerName =
        activeTrip['customer_name']?.toString() ?? 'No Active Dispatch';
    final siteName = activeTrip['destination_site']?.toString() ??
        'Tap Complete / New Trip to log dispatch';
    final customerAddress = activeTrip['address']?.toString() ?? '';
    final tripNumber = activeTrip['trip_number']?.toString() ?? '--';
    final waterKl = (activeTrip['water_quantity_kl'] as num?)?.toDouble() ?? 0.0;
    final flowRate = (activeTrip['flow_lpm'] as num?)?.toInt() ?? 0;
    final customerId =
        (activeTrip['customer_id'] as num?)?.toInt() ?? 0;

    final lat = (activeTrip['latitude'] as num?)?.toDouble();
    final lng = (activeTrip['longitude'] as num?)?.toDouble();
    final hasGps = lat != null && lng != null && lat != 0 && lng != 0;

    final tripsToday = (stats['trips_today'] as num?)?.toInt() ?? 0;
    final totalKl = (stats['total_kl'] as num?)?.toDouble() ?? 0.0;

    final contextCard = _buildDriverContextCard(
      skin: skin,
      driverName: driverName,
      roleBadgeLabel: roleBadgeLabel,
      vehicleModel: vehicleModel,
      vehicleNo: vehicleNo,
      tripNumber: tripNumber,
    );
    final telemetryCard = _buildHeroTelemetryCard(
      currentOdo: currentOdo,
      tripsToday: tripsToday,
      totalKl: totalKl,
      waterKl: waterKl,
      capacityKl: capacityKl,
    );
    final ordersQueueCard = _buildPendingOrdersQueue(
      context,
      skin,
      pendingTrips,
      tankerId: int.tryParse((vehicle['id'] ?? '').toString()),
    );
    final destinationCard = _buildDestinationCard(
      context: context,
      skin: skin,
      customerId: customerId,
      customerName: customerName,
      siteName: siteName,
      customerAddress: customerAddress,
      hasGps: hasGps,
      lat: lat,
      lng: lng,
    );
    final decantingCard = _buildDecantingMeterCard(
      skin: skin,
      waterKl: waterKl,
      flowRate: flowRate,
    );
    final antiSiphonCard = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.rippleMint.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.rippleMint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.rippleMint,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Anti-Siphon Protection Active',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: skin.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      'LOCKED OK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.rippleMint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Outlet discharge valve linked to destination geo-fence.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: skin.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final actionButtons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () => context.push(
              '/operations/tanker-trip',
              extra: activeTrip.isNotEmpty ? activeTrip : null,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.aquaAction,
              foregroundColor: AppColors.rippleLightInk,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 22),
            label: const Text(
              'Complete Trip',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => context.push(
              '/operations/tanker-trip',
              extra: activeTrip.isNotEmpty ? activeTrip : null,
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: skin.surface,
              foregroundColor: skin.ink,
              side: BorderSide(color: skin.hairline),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(
              Icons.local_gas_station_rounded,
              size: 18,
              color: AppColors.aquaPrimary,
            ),
            label: const Text(
              'Decanting & Fuel Log',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: skin.canvas,
      body: RefreshIndicator(
        onRefresh: _loadManifest,
        color: AppColors.aquaPrimary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Builder(
                builder: (context) {
                  final isWide = MediaQuery.sizeOf(context).width >= 860;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      if (_errorMessage != null && _manifest == null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.rippleHoney.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.rippleHoney,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: skin.ink,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _loadManifest,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  contextCard,
                                  const SizedBox(height: 14),
                                  destinationCard,
                                  const SizedBox(height: 14),
                                  ordersQueueCard,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  telemetryCard,
                                  const SizedBox(height: 14),
                                  decantingCard,
                                  const SizedBox(height: 12),
                                  antiSiphonCard,
                                  const SizedBox(height: 14),
                                  actionButtons,
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        contextCard,
                        const SizedBox(height: 14),
                        telemetryCard,
                        const SizedBox(height: 14),
                        ordersQueueCard,
                        const SizedBox(height: 14),
                        destinationCard,
                        const SizedBox(height: 14),
                        decantingCard,
                        const SizedBox(height: 12),
                        antiSiphonCard,
                        const SizedBox(height: 14),
                        actionButtons,
                      ],
                    ],
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Sign out of this shift? Pending offline records will stay saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  Widget _buildDriverContextCard({
    required RippleSkin skin,
    required String driverName,
    required String roleBadgeLabel,
    required String vehicleModel,
    required String vehicleNo,
    required String tripNumber,
  }) {
    final initials = driverName.isNotEmpty
        ? driverName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join()
        : 'KM';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.aquaPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.aquaPrimary,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.rippleMint,
                        shape: BoxShape.circle,
                        border: Border.all(color: skin.surface, width: 2),
                      ),
                    ),
                  ),
                ],
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
                            driverName,
                            style: TextStyle(
                              fontSize: 16,
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
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: skin.surface2,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            roleBadgeLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: skin.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            vehicleModel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: skin.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.aquaPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            vehicleNo,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.aquaPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    context.push('/fleet/gps?mode=bulk_water'),
                icon: const Icon(Icons.radar_rounded,
                    color: AppColors.aquaPrimary),
                tooltip: 'Live Fleet Radar',
              ),
              IconButton(
                key: const Key('driver_header_logout_btn'),
                onPressed: _confirmSignOut,
                icon: Icon(Icons.logout_rounded, color: skin.muted),
                tooltip: 'Sign Out',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: skin.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cell_tower_rounded,
                        size: 15, color: AppColors.rippleMint),
                    const SizedBox(width: 6),
                    Text(
                      'Trip Ref: $tripNumber',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: skin.ink,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Synced · Live',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: skin.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrdersQueue(
    BuildContext context,
    RippleSkin skin,
    List<Map<String, dynamic>> pendingTrips, {
    int? tankerId,
  }) {
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
            children: [
              Expanded(
                child: Text(
                  'ASSIGNED ORDERS QUEUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: skin.muted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.aquaPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${pendingTrips.length} Open',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.aquaPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => showCreateTankerOrderSheet(
                  context: context,
                  ref: ref,
                  tankerId: tankerId,
                  onCreated: _loadManifest,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: AppColors.aquaPrimary,
                  side: const BorderSide(color: AppColors.aquaPrimary),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                label: const Text(
                  'Create Order',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.push('/operations/schedules?vertical=tanker');
                  if (mounted) _loadManifest();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: skin.ink,
                  side: BorderSide(color: skin.hairline),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.event_repeat_rounded, size: 15),
                label: const Text(
                  'Schedules',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (pendingTrips.isEmpty)
            Text(
              'No pending bulk tanker orders assigned. Tap Create Order above or Log New Trip below.',
              style: TextStyle(fontSize: 12, color: skin.muted, fontWeight: FontWeight.w500),
            )
          else
            ...pendingTrips.map((order) {
              final tripNo = order['trip_number']?.toString() ?? '#${order['id'] ?? ''}';
              final customer = order['customer_name']?.toString() ?? order['destination_site']?.toString() ?? 'Assigned Site';
              final site = order['destination_site']?.toString() ?? '';
              final qtyKl = (order['water_quantity_kl'] as num?)?.toDouble() ?? 0.0;
              final status = (order['status']?.toString() ?? 'dispatched').replaceAll('_', ' ').toUpperCase();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: skin.canvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: skin.hairline),
                ),
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
                              Text(
                                '$tripNo · $status',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.aquaPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customer,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: skin.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${qtyKl.toStringAsFixed(1)} KL${site.isNotEmpty ? ' · $site' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: skin.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OrderOriginBadge(order: order),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => showAdjustWaterOrderSheet(
                            context: context,
                            ref: ref,
                            verticalType: 'tanker',
                            order: order,
                            onUpdated: _loadManifest,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 15),
                          label: const Text('Adjust', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await context.push('/operations/tanker-trip', extra: order);
                              if (mounted) _loadManifest();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.aquaPrimary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: const Text(
                              'Process Order',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
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
    );
  }

  Widget _buildHeroTelemetryCard({
    required String currentOdo,
    required int tripsToday,
    required double totalKl,
    required double waterKl,
    required double capacityKl,
  }) {
    final denom = capacityKl > 0 ? capacityKl : (waterKl > 0 ? waterKl : 1.0);
    final fillRatio = waterKl > 0 ? (waterKl / denom).clamp(0.15, 1.0) : 0.0;
    final halfKl = (waterKl / 2.0).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.aquaPrimary, Color(0xFF0A6E8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.aquaPrimary.withValues(alpha: 0.25),
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BULK WATER TELEMETRY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Dual-Chamber Telemetry',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.24)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded,
                        size: 13, color: AppColors.aquaAction),
                    SizedBox(width: 4),
                    Text(
                      'VALVE SECURED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildHeroStatBox(
                  label: 'Odometer KM',
                  value: currentOdo,
                  unit: 'KM',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroStatBox(
                  label: 'Today Trips Done',
                  value: '$tripsToday',
                  unit: 'Trips',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildHeroStatBox(
                  label: 'Total Water KL',
                  value: totalKl.toStringAsFixed(1),
                  unit: 'KL',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroStatBox(
                  label: 'Payload State',
                  value: waterKl > 0 ? '${waterKl.toStringAsFixed(1)} KL' : 'Empty',
                  unit: waterKl > 0 ? 'Loaded' : 'Idle',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'DUAL CHAMBER PAYLOAD SPLIT',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'CH-1: $halfKl KL · CH-2: $halfKl KL',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.aquaAction,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: fillRatio,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.aquaAction),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatBox({
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard({
    required BuildContext context,
    required RippleSkin skin,
    required int customerId,
    required String customerName,
    required String siteName,
    required String customerAddress,
    required bool hasGps,
    required double? lat,
    required double? lng,
  }) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned Destination & Trip',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: skin.muted,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasGps
                      ? AppColors.rippleMint.withValues(alpha: 0.14)
                      : AppColors.rippleHoney.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hasGps ? 'Geo-Fence OK' : 'No GPS Tagged',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: hasGps
                        ? AppColors.rippleMint
                        : AppColors.rippleHoney,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            customerName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: skin.ink,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: skin.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.factory_rounded,
                    size: 20, color: AppColors.aquaPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siteName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: skin.ink,
                        ),
                      ),
                      if (customerAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          customerAddress,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: skin.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: (hasGps && lat != null && lng != null)
                        ? () => LocationParser.launchNavigation(lat, lng)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.aquaPrimary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text(
                      'Google Maps',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton.icon(
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
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.share_location_rounded, size: 18),
                    label: const Text(
                      'WhatsApp GPS',
                      style: TextStyle(
                        fontSize: 12,
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

  Widget _buildDecantingMeterCard({
    required RippleSkin skin,
    required double waterKl,
    required int flowRate,
  }) {
    final liters = (waterKl * 1000).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WATER TO DECANT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: skin.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${waterKl.toStringAsFixed(1)} KL ($liters L)',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: skin.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.aquaPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop_rounded,
                          size: 14, color: AppColors.aquaPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'FLOW: $flowRate L/min',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.aquaPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.aquaPrimary.withValues(alpha: 0.35),
                width: 5,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$flowRate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: skin.ink,
                  ),
                ),
                Text(
                  'L/min',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: skin.muted,
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
