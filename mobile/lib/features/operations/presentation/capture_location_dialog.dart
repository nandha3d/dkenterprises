import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/location_parser.dart';

class CaptureLocationDialog extends ConsumerStatefulWidget {
  final int customerId;
  final String customerName;
  final String? currentAddress;
  final double? currentLat;
  final double? currentLng;
  final VoidCallback? onLocationUpdated;

  const CaptureLocationDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    this.currentAddress,
    this.currentLat,
    this.currentLng,
    this.onLocationUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required int customerId,
    required String customerName,
    String? currentAddress,
    double? currentLat,
    double? currentLng,
    VoidCallback? onLocationUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CaptureLocationDialog(
        customerId: customerId,
        customerName: customerName,
        currentAddress: currentAddress,
        currentLat: currentLat,
        currentLng: currentLng,
        onLocationUpdated: onLocationUpdated,
      ),
    );
  }

  @override
  ConsumerState<CaptureLocationDialog> createState() => _CaptureLocationDialogState();
}

class _CaptureLocationDialogState extends ConsumerState<CaptureLocationDialog> {
  final _inputController = TextEditingController();
  LocationCoordinates? _parsedCoordinates;
  bool _isSaving = false;
  bool _isLocatingGps = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    if (widget.currentLat != null && widget.currentLng != null && widget.currentLat != 0.0) {
      _parsedCoordinates = LocationCoordinates(
        latitude: widget.currentLat!,
        longitude: widget.currentLng!,
      );
    }
    _inputController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _statusMessage = null;
      });
      return;
    }

    final coords = LocationParser.extractCoordinates(text);
    setState(() {
      if (coords != null) {
        _parsedCoordinates = coords;
        _statusMessage = '✓ Location recognized from WhatsApp / Google Maps';
      } else {
        _statusMessage = 'Paste a WhatsApp location link (e.g. maps.google.com/?q=...)';
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _inputController.text = data.text!;
      _onTextChanged();
    }
  }

  Future<void> _captureCurrentGps() async {
    setState(() {
      _isLocatingGps = true;
      _statusMessage = 'Detecting current GPS location...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _parsedCoordinates = LocationCoordinates(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        _inputController.text = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
        _statusMessage = '✓ Live phone GPS captured successfully';
        _isLocatingGps = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'GPS capture unavailable. Please paste WhatsApp link.';
        _isLocatingGps = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_parsedCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or paste a valid WhatsApp / Google Maps location link.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final apiClient = ref.read(apiClientProvider);

    try {
      final res = await apiClient.post(
        '/mobile/customers/${widget.customerId}/location',
        data: {
          'latitude': _parsedCoordinates!.latitude,
          'longitude': _parsedCoordinates!.longitude,
          'whatsapp_text': _inputController.text.trim(),
        },
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (res.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Delivery location locked for ${widget.customerName}'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
          widget.onLocationUpdated?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.failureOrNull?.message ?? 'Failed to save location.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving location: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: borderCol),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.pin_drop_rounded,
                    color: Color(0xFF25D366),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capture Customer Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrim,
                        ),
                      ),
                      Text(
                        widget.customerName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: textSec, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Instructions Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryDark : AppColors.primary).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isDark ? AppColors.primaryDark : AppColors.primary).withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_rounded,
                    size: 20,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'If customer shares their location on WhatsApp, copy and paste the message or link below. It will be permanently stored for all future orders!',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: textSec,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Paste Input Field
            TextField(
              controller: _inputController,
              maxLines: 2,
              style: TextStyle(fontSize: 13, color: textPrim),
              decoration: InputDecoration(
                hintText: 'Paste WhatsApp message, Google Maps link, or "11.0845, 77.2941"...',
                hintStyle: TextStyle(fontSize: 12, color: textSec.withOpacity(0.6)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderCol),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderCol),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                    width: 1.5,
                  ),
                ),
                suffixIcon: IconButton(
                  tooltip: 'Paste from clipboard',
                  icon: const Icon(Icons.content_paste_rounded, size: 20),
                  onPressed: _pasteFromClipboard,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Status feedback
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _parsedCoordinates != null ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),

            // Coordinates Preview Box
            if (_parsedCoordinates != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VALID GPS COORDINATES IDENTIFIED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lat: ${_parsedCoordinates!.latitude.toStringAsFixed(6)} · Lng: ${_parsedCoordinates!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: textPrim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 20),
                      tooltip: 'Test Navigation in Google Maps',
                      onPressed: () => LocationParser.launchNavigation(
                        _parsedCoordinates!.latitude,
                        _parsedCoordinates!.longitude,
                      ),
                    ),
                  ],
                ),
              ),

            // Alternative: Capture Current Device GPS
            OutlinedButton.icon(
              onPressed: _isLocatingGps ? null : _captureCurrentGps,
              icon: _isLocatingGps
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(_isLocatingGps ? 'Reading GPS Sensor...' : 'Capture My Current GPS Location Here'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                side: BorderSide(
                  color: (isDark ? AppColors.primaryDark : AppColors.primary).withOpacity(0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            // Primary Save Button
            ElevatedButton(
              onPressed: (_isSaving || _parsedCoordinates == null) ? null : _saveLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Save & Lock Location for Re-Orders',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
