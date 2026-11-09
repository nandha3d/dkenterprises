import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';

class PaymentCollectionScreen extends ConsumerStatefulWidget {
  const PaymentCollectionScreen({super.key});

  @override
  ConsumerState<PaymentCollectionScreen> createState() => _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends ConsumerState<PaymentCollectionScreen> {
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMode = 'Cash';
  bool _isSubmitting = false;
  int? _selectedCustomerId;
  double _currentDue = 0.0;
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
    if (mounted && res.isSuccess) {
      setState(() {
        _customers = res.dataOrNull ?? [];
        if (_customers.isNotEmpty) {
          final first = _customers.first;
          _selectedCustomerId = first['id'] as int?;
          _customerController.text = first['name']?.toString() ?? '';
          _currentDue = (first['outstanding_due'] as num?)?.toDouble() ?? 0.0;
        }
      });
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitCollection() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid collection amount')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final payload = {
      'customer_id': _selectedCustomerId ?? 1,
      'customer_name': _customerController.text.trim(),
      'amount': amount,
      'payment_mode': _paymentMode,
      'notes': _notesController.text.trim(),
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      ApiEndpoints.collectPayment,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment collection posted to ledger accounts!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.collectPayment,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collection saved offline to Outbox! Will sync automatically.'),
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
        title: const Text('Collect Customer Payment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Party / Customer', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_search_rounded, size: 20),
                      hintText: 'Customer name or account',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Outstanding Due:', style: AppTypography.caption),
                      AmountText(
                        amount: _currentDue,
                        color: _currentDue > 0 ? AppColors.danger : AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Amount Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Collected Amount (₹)', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.title.copyWith(fontSize: 22),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.currency_rupee_rounded, size: 22),
                      hintText: '0.00',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Payment Method', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPaymentModeOption('Cash', Icons.money_rounded),
                      const SizedBox(width: 8),
                      _buildPaymentModeOption('UPI', Icons.qr_code_rounded),
                      const SizedBox(width: 8),
                      _buildPaymentModeOption('Cheque', Icons.description_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Receipt Memo / Reference', style: AppTypography.label.copyWith(color: textCol)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. UPI Ref / Cheque No / Cash memo',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitCollection,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Post Receipt & Update Balance'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeOption(String mode, IconData icon) {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? (isDark ? Colors.black : Colors.white) : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                mode,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? (isDark ? Colors.black : Colors.white) : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

