import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Selected map coordinate pair returned by [LocationPickerScreen].
class PickedLocation {
  final double latitude;
  final double longitude;
  const PickedLocation(this.latitude, this.longitude);
}

/// Interactive OpenStreetMap tap-to-pin coordinate picker for customer onboarding
/// and shop geofence calibration. Defaults to Madurai hub if GPS fix unavailable.
class LocationPickerScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String title;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.title = 'Pin Customer GPS Location',
  });

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(9.9252, 78.1198);
  late final MapController _mapController;
  late LatLng _selected;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selected = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _defaultCenter;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _centerOnCurrentGps() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final snap = await ref
          .read(gpsServiceProvider)
          .evaluate(requestIfDenied: true);
      if (!mounted) return;
      if (snap.latitude != null && snap.longitude != null) {
        final target = LatLng(snap.latitude!, snap.longitude!);
        setState(() => _selected = target);
        _mapController.move(target, 16);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tap anywhere on the map to place the customer pin.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Center on My GPS',
            onPressed: _locating ? null : _centerOnCurrentGps,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: 15,
              onTap: (_, point) {
                setState(() => _selected = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dkenterprises.dk_track_mobile',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _selected,
                    radius: 150,
                    useRadiusInMeter: true,
                    color: skin.primary.withValues(alpha: 0.14),
                    borderColor: skin.primary,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selected,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      size: 44,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: skin.surface,
                  borderRadius: BorderRadius.circular(skin.cardRadius),
                  border: Border.all(color: skin.hairline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: skin.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.gps_fixed_rounded,
                              color: skin.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tap map to move 150m geofence center',
                                style: AppTypography.caption.copyWith(
                                  color: skin.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_selected.latitude.toStringAsFixed(6)}, '
                                '${_selected.longitude.toStringAsFixed(6)}',
                                style: AppTypography.title.copyWith(
                                  color: skin.ink,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(
                            PickedLocation(
                              _selected.latitude,
                              _selected.longitude,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Use This GPS Location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
