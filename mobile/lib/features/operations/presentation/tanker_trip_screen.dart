import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';

class TankerTripScreen extends ConsumerStatefulWidget {
  const TankerTripScreen({super.key});

  @override
  ConsumerState<TankerTripScreen> createState() => _TankerTripScreenState();
}

class _TankerTripScreenState extends ConsumerState<TankerTripScreen> {
  final _customerController = TextEditingController();
  final _startOdoController = TextEditingController();
  final _endOdoController = TextEditingController();
  final int _waterLitres = 16000;
  final double _baseTripRate = 2400.0;
  final double _motorPumpingSurcharge = 0.0;
  final double _waitingSurcharge = 0.0;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    final client = ref.read(apiClientProvider);
    final res = await client.get(
      ApiEndpoints.customers,
      fromJson: (data) {
        final list = data is Map && data['data'] is List
            ? data['data'] as List
            : (data is List ? data : []);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      },
    );
    if (mounted && res.isSuccess && (res.dataOrNull?.isNotEmpty ?? false)) {
      setState(() {
        _customers = res.dataOrNull ?? [];
        _customerController.text = _customers.first['name']?.toString() ?? '';
      });
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _startOdoController.dispose();
    _endOdoController.dispose();
    super.dispose();
  }

  double get _totalBill => _baseTripRate + _motorPumpingSurcharge + _waitingSurcharge;

  Future<void> _submitTrip() async {
    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final payload = {
      'tanker_id': 1,
      'customer_name': _customerController.text.trim(),
      'destination_site': _customerController.text.trim(),
      'delivery_site': _customerController.text.trim(),
      'water_quantity_litres': _waterLitres,
      'water_quantity_kl': _waterLitres / 1000.0,
      'start_odometer': int.tryParse(_startOdoController.text.trim()) ?? 0,
      'end_odometer': int.tryParse(_endOdoController.text.trim()) ?? 0,
      'start_km': int.tryParse(_startOdoController.text.trim()) ?? 0,
      'end_km': int.tryParse(_endOdoController.text.trim()) ?? 0,
      'motor_pumping_charge': _motorPumpingSurcharge,
      'waiting_charge': _waitingSurcharge,
      'trip_rate': _totalBill,
      'billed_amount': _totalBill,
      'total_trip_amount': _totalBill,
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      ApiEndpoints.tankerTrips,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ref.read(dashboardRefreshSignalProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bulk tanker trip sheet recorded successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.tankerTrips,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanker trip sheet saved to offline Outbox!'),
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
        title: const Text('Tanker Trip Sheet'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer & Destination
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Industrial Customer Site', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_city_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Water Decanted:', style: AppTypography.caption),
                      Text(
                        '$_waterLitres Litres',
                        style: AppTypography.label.copyWith(
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Odometer Telematics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Odometer Mileage (km)', style: AppTypography.section.copyWith(fontSize: 16, color: textCol)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startOdoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Start KM',
                            prefixIcon: Icon(Icons.speed_rounded, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _endOdoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'End KM',
                            prefixIcon: Icon(Icons.speed_rounded, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Surcharges & Bill Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trip Bill & Surcharges', style: AppTypography.section.copyWith(fontSize: 16, color: textCol)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Base Water Freight', style: AppTypography.body),
                      AmountText(amount: _baseTripRate),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Motor Pumping Surcharge', style: AppTypography.body),
                      AmountText(amount: _motorPumpingSurcharge),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Site Waiting Surcharge', style: AppTypography.body),
                      AmountText(amount: _waitingSurcharge),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Trip Amount', style: AppTypography.section.copyWith(fontSize: 16, color: textCol)),
                      AmountText(
                        amount: _totalBill,
                        style: AppTypography.title.copyWith(
                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTrip,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Complete Trip & Post Invoice'),
          ),
        ],
      ),
    );
  }
}

