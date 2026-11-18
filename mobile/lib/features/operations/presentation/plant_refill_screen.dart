import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/scrollable_counter_field.dart';

class PlantRefillScreen extends ConsumerStatefulWidget {
  const PlantRefillScreen({super.key});

  @override
  ConsumerState<PlantRefillScreen> createState() => _PlantRefillScreenState();
}

class _PlantRefillScreenState extends ConsumerState<PlantRefillScreen> {
  final _vehicleController = TextEditingController();
  String _selectedCanSize = '20L Can';
  int _routeId = 1;
  int _emptyHandedOver = 0;
  int _fullLoaded = 0;
  int _damagedJars = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDriverManifest();
  }

  Future<void> _loadDriverManifest() async {
    final client = ref.read(apiClientProvider);
    final res = await client.get<Map<String, dynamic>>(
      ApiEndpoints.driverManifest,
      fromJson: (data) {
        if (data is Map && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
        return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      },
    );
    if (!mounted) return;
    if (res.isSuccess) {
      final m = res.dataOrNull ?? const <String, dynamic>{};
      final veh = m['vehicle'];
      if (veh is Map) {
        final routeId = int.tryParse((veh['id'] ?? '').toString());
        if (routeId != null && routeId > 0) {
          _routeId = routeId;
        }
        final vehicleNo = veh['vehicle_number']?.toString().trim() ?? '';
        final routeName = veh['route_name']?.toString().trim() ?? '';
        if (_vehicleController.text.trim().isEmpty) {
          if (vehicleNo.isNotEmpty) {
            _vehicleController.text = vehicleNo;
          } else if (routeName.isNotEmpty) {
            _vehicleController.text = routeName;
          }
        }
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _submitRefill() async {
    if (_emptyHandedOver <= 0 && _fullLoaded <= 0 && _damagedJars <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least 1 empty, loaded, or damaged container count.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final vehicleText = _vehicleController.text.trim().isNotEmpty
        ? _vehicleController.text.trim()
        : 'Assigned Route Van';

    final payload = {
      'route_id': _routeId,
      'vehicle_no': vehicleText,
      'can_size': _selectedCanSize,
      'empty_cans_handed_over': _emptyHandedOver,
      'cans_loaded': _fullLoaded,
      'full_cans_loaded': _fullLoaded,
      'damaged_cans': _damagedJars,
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      ApiEndpoints.plantIntakes,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plant refill manifest confirmed and stock updated!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else if (result.failureOrNull?.statusCode == 422 ||
        result.failureOrNull?.statusCode == 403 ||
        result.failureOrNull?.statusCode == 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.message ?? 'Validation error checking refill manifest.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.plantIntakes,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refill manifest saved to offline Outbox!'),
          backgroundColor: AppColors.warning,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Refill Manifest'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vehicle / Route Van', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. TN-38-AQ-4411 (Route Van)',
                      prefixIcon: Icon(Icons.local_shipping_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: WaterContainerSizeSelector(
                selectedSize: _selectedCanSize,
                onChanged: (size) => setState(() => _selectedCanSize = size),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ScrollableCounterRow(
                    title: 'Empty Cans Handed Over',
                    subtitle: '$_selectedCanSize · Scroll wheel or tap to type',
                    value: _emptyHandedOver,
                    onChanged: (val) => setState(() => _emptyHandedOver = val),
                    titleColor: textCol,
                  ),
                  const Divider(height: 24),
                  ScrollableCounterRow(
                    title: 'Full Sealed Cans Loaded',
                    subtitle: '$_selectedCanSize · Scroll wheel or tap to type',
                    value: _fullLoaded,
                    onChanged: (val) => setState(() => _fullLoaded = val),
                    titleColor: textCol,
                  ),
                  const Divider(height: 24),
                  ScrollableCounterRow(
                    title: 'Damaged / Leakage Jars',
                    subtitle: '$_selectedCanSize · Scroll wheel or tap to type',
                    value: _damagedJars,
                    onChanged: (val) => setState(() => _damagedJars = val),
                    titleColor: textCol,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRefill,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Confirm Plant Intake'),
          ),
        ],
      ),
    );
  }
}
