import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class PlantRefillScreen extends ConsumerStatefulWidget {
  const PlantRefillScreen({super.key});

  @override
  ConsumerState<PlantRefillScreen> createState() => _PlantRefillScreenState();
}

class _PlantRefillScreenState extends ConsumerState<PlantRefillScreen> {
  final _vehicleController = TextEditingController();
  int _emptyHandedOver = 0;
  int _fullLoaded = 0;
  int _damagedJars = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _submitRefill() async {
    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final payload = {
      'vehicle_no': _vehicleController.text.trim(),
      'empty_cans_handed_over': _emptyHandedOver,
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

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plant refill manifest confirmed and stock updated!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.plantIntakes,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

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
              child: Column(
                children: [
                  _buildStepperRow('Empty Cans Handed Over', _emptyHandedOver, (val) => setState(() => _emptyHandedOver = val), textCol),
                  const Divider(height: 24),
                  _buildStepperRow('Full Sealed Cans Loaded', _fullLoaded, (val) => setState(() => _fullLoaded = val), textCol),
                  const Divider(height: 24),
                  _buildStepperRow('Damaged / Leakage Jars', _damagedJars, (val) => setState(() => _damagedJars = val), textCol),
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

  Widget _buildStepperRow(String title, int value, ValueChanged<int> onChanged, Color textCol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.body.copyWith(color: textCol)),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_rounded, size: 18),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '$value',
                style: AppTypography.title.copyWith(fontSize: 20),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

