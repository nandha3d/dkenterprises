import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../features/auth/domain/auth_models.dart';
import '../../models/models.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'gps_service.dart';

/// Continuously monitors driver GPS health & transmits live location pings
/// (including `gps_enabled=false` or `is_mocked=true` compliance alerts) to the ERP.
class GpsPinger extends ChangeNotifier {
  final ApiClient _client;
  final GpsService _gpsService;

  Timer? _heartbeatTimer;
  StreamSubscription<Position>? _posSub;
  StreamSubscription<ServiceStatus>? _serviceSub;

  GpsSnapshot _snapshot = GpsSnapshot(
    status: GpsHealthStatus.desktopBypass,
    checkedAt: DateTime.now(),
  );
  GpsSnapshot get snapshot => _snapshot;

  UserRole? _activeRole;
  bool _isAuthenticated = false;
  int? _vehicleId;
  String? _vehicleType;
  DateTime? _lastPingSentAt;
  bool _disposed = false;

  GpsPinger(this._client, this._gpsService);

  UserRole? _resolveRole(AuthState auth) {
    final candidates = <String>[
      auth.user?.role ?? '',
      auth.user?.username ?? '',
      ...auth.roles,
    ];
    for (final raw in candidates) {
      final slug = raw.trim().toLowerCase();
      if (slug == 'tanker_driver' ||
          slug == 'tankerdriver' ||
          slug == 'tanker') {
        return UserRole.tankerDriver;
      }
      if (slug == 'delivery_driver' ||
          slug == 'deliverydriver' ||
          slug == 'can_delivery' ||
          slug == 'candelivery' ||
          slug == 'can_driver' ||
          slug == 'driver') {
        return UserRole.deliveryDriver;
      }
    }
    return null;
  }

  /// Updates the active authenticated driver/staff context.
  Future<void> syncSession(AuthState auth) async {
    final nextAuth = auth.isAuthenticated && auth.user != null;
    final nextRole = _resolveRole(auth);

    if (!nextAuth) {
      await stop();
      return;
    }

    final changed = !_isAuthenticated || _activeRole != nextRole;
    _isAuthenticated = true;
    _activeRole = nextRole;

    if (nextRole == UserRole.tankerDriver) {
      _vehicleType = 'tanker';
      _vehicleId = _vehicleId ?? 1;
    } else if (nextRole == UserRole.deliveryDriver) {
      _vehicleType = 'route';
      _vehicleId = _vehicleId ?? 1;
    } else {
      _vehicleType = null;
      _vehicleId = null;
    }

    if (changed) {
      await start();
    }
  }

  /// Starts periodic evaluation + OS GPS service/position listeners for mobile sessions.
  Future<void> start() async {
    if (_disposed) return;
    await _cancelSubscriptions();

    await checkNow(requestIfDenied: _requiresMandatoryGps(_activeRole));

    if (_gpsService.isMobileHardware && _requiresMandatoryGps(_activeRole)) {
      _serviceSub = _gpsService.mobileServiceStatusStream()?.listen(
        (status) {
          unawaited(checkNow(requestIfDenied: false));
        },
        onError: (_) {},
      );
      _posSub = _gpsService.mobilePositionStream()?.listen(
        (pos) {
          _snapshot = GpsSnapshot(
            status: GpsHealthStatus.ready,
            checkedAt: DateTime.now(),
            latitude: pos.latitude,
            longitude: pos.longitude,
            speedKmh: (pos.speed * 3.6).clamp(0.0, 140.0),
            accuracyMeters: pos.accuracy,
            isMocked: pos.isMocked,
            hasBackgroundPermission: _snapshot.hasBackgroundPermission,
          );
          if (!_disposed) notifyListeners();
          _throttledSendPing();
        },
        onError: (_) {
          unawaited(checkNow(requestIfDenied: false));
        },
      );
    }

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(checkNow(requestIfDenied: false)),
    );
  }

  bool _requiresMandatoryGps(UserRole? role) =>
      role == UserRole.deliveryDriver || role == UserRole.tankerDriver;

  /// Evaluates current GPS state and reports telemetry or GPS-off security events.
  Future<GpsSnapshot> checkNow({bool requestIfDenied = false}) async {
    if (_disposed) return _snapshot;
    final next = await _gpsService.evaluate(requestIfDenied: requestIfDenied);
    _snapshot = next;
    if (!_disposed) notifyListeners();

    if (_isAuthenticated && _requiresMandatoryGps(_activeRole)) {
      await _sendTelemetryPing(next);
    }
    return next;
  }

  void _throttledSendPing() {
    final last = _lastPingSentAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 20)) {
      return;
    }
    unawaited(_sendTelemetryPing(_snapshot));
  }

  Future<void> _sendTelemetryPing(GpsSnapshot snap) async {
    final vType = _vehicleType;
    final vId = _vehicleId;
    if (vType == null || vId == null) return;
    if (!_gpsService.isMobileHardware && snap.latitude == null) return;

    _lastPingSentAt = DateTime.now();
    try {
      await _client.post<Map<String, dynamic>>(
        ApiEndpoints.fleetPing,
        data: {
          'vehicle_type': vType,
          'vehicle_id': vId,
          'latitude': snap.latitude,
          'longitude': snap.longitude,
          'speed': snap.speedKmh,
          'accuracy': snap.accuracyMeters,
          'gps_enabled': snap.isGpsReady,
          'is_mocked': snap.isMocked,
        },
        fromJson: (raw) => raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{},
      );
    } catch (_) {
      // Non-fatal: background connectivity errors handled cleanly by ApiClient
    }
  }

  Future<void> _cancelSubscriptions() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _posSub?.cancel();
    _posSub = null;
    await _serviceSub?.cancel();
    _serviceSub = null;
  }

  Future<void> stop() async {
    _isAuthenticated = false;
    _activeRole = null;
    await _cancelSubscriptions();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _heartbeatTimer?.cancel();
    _posSub?.cancel();
    _serviceSub?.cancel();
    super.dispose();
  }
}
