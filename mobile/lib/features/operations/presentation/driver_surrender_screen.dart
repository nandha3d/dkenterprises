import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';

class DriverSurrenderScreen extends ConsumerStatefulWidget {
  const DriverSurrenderScreen({super.key});

  @override
  ConsumerState<DriverSurrenderScreen> createState() => _DriverSurrenderScreenState();
}

class _DriverSurrenderScreenState extends ConsumerState<DriverSurrenderScreen> {
  final _collectedController = TextEditingController();
  final _expensesController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final client = ref.read(apiClientProvider);
    final res = await client.get(
      ApiEndpoints.financials,
      fromJson: (data) => data as Map<String, dynamic>,
    );
    if (mounted && res.isSuccess) {
      final raw = res.dataOrNull ?? <String, dynamic>{};
      final fin = raw['data'] is Map ? raw['data'] as Map : raw;
      final coll = (fin['today_collections'] as num?)?.toDouble() ?? 0.0;
      if (coll > 0) {
        setState(() {
          _collectedController.text = coll.toStringAsFixed(0);
        });
      }
    }
  }

  @override
  void dispose() {
    _collectedController.dispose();
    _expensesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _grossCollected => double.tryParse(_collectedController.text.trim()) ?? 0;
  double get _routeExpenses => double.tryParse(_expensesController.text.trim()) ?? 0;
  double get _netSurrender => _grossCollected - _routeExpenses;

  Future<void> _submitSurrender() async {
    if (_netSurrender < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expenses cannot exceed total collected cash.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final payload = {
      'driver_id': 1,
      'route_id': 1,
      'cash_surrendered': _netSurrender,
      'empty_cans_returned': 0,
      'gross_cash_collected': _grossCollected,
      'route_expenses': _routeExpenses,
      'net_cash_surrendered': _netSurrender,
      'notes': _notesController.text.trim(),
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      ApiEndpoints.driverCashSurrender,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver cash surrender completed and journal entry posted to ledger!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.driverCashSurrender,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cash surrender record queued in offline Outbox!'),
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
        title: const Text('Driver Cash Surrender'),
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
                  Text(
                    'Daily Route Cash Settlement',
                    style: AppTypography.section.copyWith(fontSize: 16, color: textCol),
                  ),
                  const Divider(height: 24),
                  Text('Gross Cash Collected Today (₹)', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _collectedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.payments_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Less: Fuel & Route Expenses (₹)', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _expensesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.local_gas_station_rounded, size: 20),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Cash Surrendered to Cashier',
                        style: AppTypography.section.copyWith(fontSize: 15, color: textCol),
                      ),
                      AmountText(
                        amount: _netSurrender,
                        style: AppTypography.title.copyWith(
                          color: AppColors.success,
                          fontSize: 22,
                        ),
                      ),
                    ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cashier Handover Notes', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Handed over ₹3,700 to Head Cashier',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitSurrender,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Confirm Cash Surrender'),
          ),
        ],
      ),
    );
  }
}

