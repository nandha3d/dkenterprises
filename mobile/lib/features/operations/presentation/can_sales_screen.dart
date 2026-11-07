import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';

class CanSalesScreen extends ConsumerStatefulWidget {
  const CanSalesScreen({super.key});

  @override
  ConsumerState<CanSalesScreen> createState() => _CanSalesScreenState();
}

class _CanSalesScreenState extends ConsumerState<CanSalesScreen> {
  final _customerController = TextEditingController(text: 'Sri Murugan Mess');
  int _deliveredCans = 10;
  int _returnedEmpties = 8;
  double _pricePerCan = 35.0;
  String _paymentMode = 'Cash';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  double get _totalBill => _deliveredCans * _pricePerCan;

  Future<void> _submitTicket() async {
    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final payload = {
      'customer_name': _customerController.text.trim(),
      'delivered_cans': _deliveredCans,
      'returned_empties': _returnedEmpties,
      'price_per_can': _pricePerCan,
      'total_amount': _totalBill,
      'payment_mode': _paymentMode,
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      ApiEndpoints.waterCanDeliveries,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Can delivery ticket issued and synced with ERP!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.waterCanDeliveries,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery ticket stored offline in Outbox! Will sync automatically.'),
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
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('15s Can Sales POS'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer Picker
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Party', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_pin_circle_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Big Stepper: Delivered Cans
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivered Full Cans', style: AppTypography.section.copyWith(color: textCol)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '₹$_pricePerCan / can',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(minimumSize: const Size(54, 54)),
                        onPressed: _deliveredCans > 1 ? () => setState(() => _deliveredCans--) : null,
                        icon: const Icon(Icons.remove_rounded, size: 24),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '$_deliveredCans',
                          style: AppTypography.display.copyWith(
                            color: isDark ? AppColors.primaryDark : AppColors.primary,
                            fontSize: 38,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(minimumSize: const Size(54, 54)),
                        onPressed: () => setState(() => _deliveredCans++),
                        icon: const Icon(Icons.add_rounded, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Returned Empties Stepper
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Returned Empty Jars', style: AppTypography.body.copyWith(color: textCol)),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: _returnedEmpties > 0 ? () => setState(() => _returnedEmpties--) : null,
                        icon: const Icon(Icons.remove_rounded, size: 18),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '$_returnedEmpties',
                          style: AppTypography.title.copyWith(fontSize: 20),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => setState(() => _returnedEmpties++),
                        icon: const Icon(Icons.add_rounded, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Mode
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Collection', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPaymentButton('Cash'),
                      const SizedBox(width: 8),
                      _buildPaymentButton('UPI'),
                      const SizedBox(width: 8),
                      _buildPaymentButton('Credit'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border(top: BorderSide(color: borderCol, width: 1)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Bill', style: AppTypography.caption),
                    AmountText(
                      amount: _totalBill,
                      style: AppTypography.title.copyWith(
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTicket,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Print & Save Ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton(String mode) {
    final isSelected = _paymentMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primaryDark : AppColors.primary)
                : (isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            mode,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? (isDark ? Colors.black : Colors.white) : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

