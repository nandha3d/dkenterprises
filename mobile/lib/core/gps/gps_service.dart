import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

/// Current GPS hardware & permission snapshot for a device session.
enum GpsHealthStatus {
  /// Non-mobile platform (Windows desktop / web) or test environment without hardware lock.
  desktopBypass,

  /// GPS location service enabled and location permission granted.
  ready,

  /// Device location / GPS toggle is switched off.
  serviceDisabled,

  /// Foreground location permission was denied.
  permissionDenied,

  /// Location permission was permanently denied in OS settings.
  permissionDeniedForever,
}

class GpsSnapshot {
  final GpsHealthStatus status;
  final double? latitude;
  final double? longitude;
  final double speedKmh;
  final double accuracyMeters;
  final bool isMocked;
  final bool hasBackgroundPermission;
  final DateTime checkedAt;

  const GpsSnapshot({
    required this.status,
    required this.checkedAt,
    this.latitude,
    this.longitude,
    this.speedKmh = 0.0,
    this.accuracyMeters = 0.0,
    this.isMocked = false,
    this.hasBackgroundPermission = false,
  });

  bool get isGpsReady =>
      status == GpsHealthStatus.ready || status == GpsHealthStatus.desktopBypass;

  bool get requiresUserAction =>
      status == GpsHealthStatus.serviceDisabled ||
      status == GpsHealthStatus.permissionDenied ||
      status == GpsHealthStatus.permissionDeniedForever;
}

/// Abstract platform adapter so tests can override OS location hardware deterministically.
abstract class GpsHardwareAdapter {
  bool get isMobileHardware;
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<bool> hasAlwaysPermission();
  Future<bool> requestAlwaysPermission();
  Future<Position?> getCurrentPosition();
  Future<Position?> getLastKnownPosition();
  Stream<Position> positionStream();
  Stream<ServiceStatus> serviceStatusStream();
  Future<bool> openLocationSettings();
  Future<bool> openAppSettings();
}

class DeviceGpsHardwareAdapter implements GpsHardwareAdapter {
  const DeviceGpsHardwareAdapter();

  @override
  bool get isMobileHardware => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 4), onTimeout: () => LocationPermission.denied);
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  @override
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  @override
  Future<bool> hasAlwaysPermission() async {
    if (!isMobileHardware) return true;
    try {
      return await Permission.locationAlways.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestAlwaysPermission() async {
    if (!isMobileHardware) return true;
    try {
      final status = await Permission.locationAlways.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    );
  }

  @override
  Stream<ServiceStatus> serviceStatusStream() {
    return Geolocator.getServiceStatusStream();
  }

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

/// Centralized GPS health checker & fix resolver shared across driver enforcement and maps.
class GpsService {
  final GpsHardwareAdapter _adapter;

  GpsService({GpsHardwareAdapter? adapter})
      : _adapter = adapter ?? const DeviceGpsHardwareAdapter();

  bool get isMobileHardware => _adapter.isMobileHardware;

  Future<GpsSnapshot> evaluate({bool requestIfDenied = false}) async {
    final now = DateTime.now();
    if (!_adapter.isMobileHardware) {
      return GpsSnapshot(
        status: GpsHealthStatus.desktopBypass,
        checkedAt: now,
        hasBackgroundPermission: true,
      );
    }

    final enabled = await _adapter.isLocationServiceEnabled();
    if (!enabled) {
      return GpsSnapshot(status: GpsHealthStatus.serviceDisabled, checkedAt: now);
    }

    var perm = await _adapter.checkPermission();
    if (perm == LocationPermission.denied && requestIfDenied) {
      perm = await _adapter.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      return GpsSnapshot(
        status: GpsHealthStatus.permissionDeniedForever,
        checkedAt: now,
      );
    }
    if (perm == LocationPermission.denied) {
      return GpsSnapshot(status: GpsHealthStatus.permissionDenied, checkedAt: now);
    }

    var hasAlways = await _adapter.hasAlwaysPermission();
    if (!hasAlways && requestIfDenied) {
      hasAlways = await _adapter.requestAlwaysPermission();
    }

    final pos = await _adapter.getCurrentPosition() ??
        await _adapter.getLastKnownPosition();

    return GpsSnapshot(
      status: GpsHealthStatus.ready,
      checkedAt: now,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      speedKmh: pos != null ? (pos.speed * 3.6).clamp(0.0, 140.0) : 0.0,
      accuracyMeters: pos?.accuracy ?? 0.0,
      isMocked: pos?.isMocked ?? false,
      hasBackgroundPermission: hasAlways,
    );
  }

  Stream<Position>? mobilePositionStream() {
    if (!_adapter.isMobileHardware) return null;
    return _adapter.positionStream();
  }

  Stream<ServiceStatus>? mobileServiceStatusStream() {
    if (!_adapter.isMobileHardware) return null;
    return _adapter.serviceStatusStream();
  }

  Future<bool> openLocationSettings() => _adapter.openLocationSettings();
  Future<bool> openAppSettings() => _adapter.openAppSettings();
}
