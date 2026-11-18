import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'gps_service.dart';

/// Wraps operational driver routes so Delivery Boys & Tanker Drivers must keep
/// device GPS location services active at all times on mobile devices.
///
/// Desktop & web sessions bypass OS location locking while still allowing
/// GPS coordinates to be pinned on interactive maps.
class GpsEnforcementGate extends ConsumerStatefulWidget {
  final Widget child;
  final bool enforceOverrideForTest;

  const GpsEnforcementGate({
    super.key,
    required this.child,
    this.enforceOverrideForTest = false,
  });

  @override
  ConsumerState<GpsEnforcementGate> createState() => _GpsEnforcementGateState();
}

class _GpsEnforcementGateState extends ConsumerState<GpsEnforcementGate>
    with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(gpsPingerProvider).checkNow(requestIfDenied: false));
    }
  }

  Future<void> _retryCheck({required bool openSettingsFirst}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final gpsService = ref.read(gpsServiceProvider);
      if (openSettingsFirst) {
        final status = ref.read(gpsPingerProvider).snapshot.status;
        if (status == GpsHealthStatus.permissionDeniedForever) {
          await gpsService.openAppSettings();
        } else {
          await gpsService.openLocationSettings();
        }
      }
      await ref.read(gpsPingerProvider).checkNow(requestIfDenied: true);
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  bool _isDriverRoleSlug(String? rawRole) {
    final slug = (rawRole ?? '').trim().toLowerCase();
    return slug == 'delivery_driver' ||
        slug == 'deliverydriver' ||
        slug == 'can_delivery' ||
        slug == 'candelivery' ||
        slug == 'can_driver' ||
        slug == 'driver' ||
        slug == 'tanker_driver' ||
        slug == 'tankerdriver' ||
        slug == 'tanker';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final pinger = ref.watch(gpsPingerProvider);
    final gpsService = ref.watch(gpsServiceProvider);
    final rippleRole = ref.watch(activeRippleRoleProvider);

    final isDriver =
        rippleRole == RippleRole.driver || _isDriverRoleSlug(auth.user?.role);
    final snap = pinger.snapshot;
    final mustBlock = auth.isAuthenticated &&
        isDriver &&
        (gpsService.isMobileHardware || widget.enforceOverrideForTest) &&
        (!snap.isGpsReady || snap.isMocked);

    if (!mustBlock) {
      return widget.child;
    }

    final skin = RippleSkin.of(context);
    final isMock = snap.isMocked;
    final isPermanent = snap.status == GpsHealthStatus.permissionDeniedForever;
    final isOff = snap.status == GpsHealthStatus.serviceDisabled;

    final title = isMock
        ? 'Mock Location App Blocked'
        : isOff
            ? 'Turn On Device GPS'
            : 'Location Permission Required';

    final description = isMock
        ? 'Simulated GPS coordinates were detected. Disable all mock location apps to resume deliveries and billing.'
        : isOff
            ? 'Active duty requires continuous GPS location tracking for geofenced deliveries, trip mileage, and live supervisor safety alerts.'
            : 'Grant "Allow all the time" location access so deliveries and route tracking remain verified even when switching apps.';

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: true,
          child: ExcludeSemantics(child: widget.child),
        ),
        Positioned.fill(
          child: Material(
            color: skin.canvas.withValues(alpha: 0.96),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: skin.surface,
                        borderRadius: BorderRadius.circular(skin.cardRadius),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isMock
                                  ? Icons.gpp_bad_rounded
                                  : Icons.location_off_rounded,
                              color: AppColors.danger,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTypography.title
                                .copyWith(color: skin.ink),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: AppTypography.body
                                .copyWith(color: skin.muted, height: 1.45),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(skin.pillRadius),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.notifications_active_rounded,
                                    size: 16, color: AppColors.warning),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Supervisor alerted when duty GPS is disabled',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (!isMock) ...[
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _checking
                                    ? null
                                    : () => _retryCheck(
                                        openSettingsFirst:
                                            isOff || isPermanent),
                                icon: Icon(isPermanent
                                    ? Icons.settings_rounded
                                    : Icons.gps_fixed_rounded),
                                label: Text(
                                  isOff
                                      ? 'Enable GPS in Settings'
                                      : isPermanent
                                          ? 'Open App Location Settings'
                                          : 'Grant Continuous GPS Access',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _checking
                                  ? null
                                  : () => _retryCheck(openSettingsFirst: false),
                              icon: _checking
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh_rounded),
                              label: Text(_checking
                                  ? 'Checking GPS...'
                                  : 'Verify GPS Signal Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
