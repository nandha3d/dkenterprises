import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class StockCountScreen extends ConsumerStatefulWidget {
  const StockCountScreen({super.key});

  @override
  ConsumerState<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends ConsumerState<StockCountScreen> {
  final _barcodeController = TextEditingController(text: 'CAN-20L-WAT');
  final int _expectedQty = 150;
  int _countedQty = 148;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  int get _variance => _countedQty - _expectedQty;

  Future<void> _submitCount() async {
    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final payload = {
      'item_code': _barcodeController.text.trim(),
      'expected_qty': _expectedQty,
      'counted_qty': _countedQty,
      'variance': _variance,
      'notes': 'Physical warehouse stock count',
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      '/inventory/stock-count',
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock count submitted and inventory verified!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: '/inventory/stock-count',
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved offline to Outbox! Will sync when connected.'),
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
        title: const Text('Physical Stock Count'),
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
                  Text('Item Barcode / SKU', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.qr_code_scanner_rounded, size: 20),
                      hintText: 'Scan or type SKU code',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit Reconciliation',
                    style: AppTypography.section.copyWith(fontSize: 16, color: textCol),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('System Expected Stock', style: AppTypography.body.copyWith(color: textCol)),
                      Text('$_expectedQty Units', style: AppTypography.section.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Physical Counted Stock', style: AppTypography.body.copyWith(color: textCol)),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: _countedQty > 0 ? () => setState(() => _countedQty--) : null,
                            icon: const Icon(Icons.remove_rounded, size: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '$_countedQty',
                              style: AppTypography.title.copyWith(fontSize: 20),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => setState(() => _countedQty++),
                            icon: const Icon(Icons.add_rounded, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Variance (Discrepancy)',
                        style: AppTypography.section.copyWith(fontSize: 16, color: textCol),
                      ),
                      Text(
                        _variance == 0 ? '0 (Exact Match)' : '$_variance Units',
                        style: AppTypography.title.copyWith(
                          fontSize: 18,
                          color: _variance == 0
                              ? AppColors.success
                              : _variance < 0
                                  ? AppColors.danger
                                  : AppColors.warning,
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
            onPressed: _isSubmitting ? null : _submitCount,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Confirm & Submit Count'),
          ),
        ],
      ),
    );
  }
}
