import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';

class NewSaleBillScreen extends ConsumerStatefulWidget {
  const NewSaleBillScreen({super.key});

  @override
  ConsumerState<NewSaleBillScreen> createState() => _NewSaleBillScreenState();
}

class _NewSaleBillScreenState extends ConsumerState<NewSaleBillScreen> {
  final _customerController = TextEditingController(text: 'Walk-in Retail Customer');
  String _paymentMode = 'Cash'; // Cash, UPI, Credit
  int _qty = 1;
  double _unitPrice = 35.0;
  String _selectedProductName = 'Standard Commercial Item';
  int? _selectedProductId;
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final client = ref.read(apiClientProvider);
    final res = await client.get(
      ApiEndpoints.products,
      fromJson: (data) {
        final list = data is Map && data['data'] is List
            ? data['data'] as List
            : (data is List ? data : []);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      },
    );
    if (mounted) {
      setState(() {
        _isLoadingProducts = false;
        if (res.isSuccess && (res.dataOrNull?.isNotEmpty ?? false)) {
          _products = res.dataOrNull!;
          final first = _products.first;
          _selectedProductId = first['id'] as int?;
          _selectedProductName = first['name']?.toString() ?? 'Standard Product';
          _unitPrice = (first['price'] as num?)?.toDouble() ?? 35.0;
        }
      });
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  double get _totalAmount => _qty * _unitPrice;

  Future<void> _submitSale() async {
    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final payload = {
      'customer_name': _customerController.text.trim(),
      'item_name': _selectedProductName,
      'product_id': _selectedProductId,
      'qty': _qty,
      'unit_price': _unitPrice,
      'grand_total': _totalAmount,
      'paid_amount': _paymentMode == 'Credit' ? 0 : _totalAmount,
      'payment_mode': _paymentMode,
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    // Attempt online post
    final result = await client.post(
      ApiEndpoints.sales,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale bill created and posted to general ledger!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      // Offline fallback: queue in SQLite outbox
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.sales,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved offline to Outbox! Will sync automatically.'),
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
        title: const Text('Create Sale Bill'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer Picker Box
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Name / Account',
                    style: AppTypography.label.copyWith(color: textCol),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_search_rounded, size: 20),
                      hintText: 'Search or enter customer name',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Line Item Entry Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Item Details',
                        style: AppTypography.section.copyWith(fontSize: 16, color: textCol),
                      ),
                      if (_isLoadingProducts)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_products.length > 1)
                        DropdownButton<int>(
                          value: _selectedProductId,
                          underline: const SizedBox.shrink(),
                          items: _products.map((p) {
                            return DropdownMenuItem<int>(
                              value: p['id'] as int?,
                              child: Text(
                                p['name']?.toString() ?? '',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              final p = _products.firstWhere((item) => item['id'] == id);
                              setState(() {
                                _selectedProductId = id;
                                _selectedProductName = p['name']?.toString() ?? '';
                                _unitPrice = (p['price'] as num?)?.toDouble() ?? _unitPrice;
                              });
                            }
                          },
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedProductName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantity (Cans)', style: AppTypography.body.copyWith(color: textCol)),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                            icon: const Icon(Icons.remove_rounded, size: 18),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '$_qty',
                              style: AppTypography.title.copyWith(fontSize: 20),
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => setState(() => _qty++),
                            icon: const Icon(Icons.add_rounded, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Unit Price', style: AppTypography.body.copyWith(color: textCol)),
                      AmountText(amount: _unitPrice),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: AppTypography.section.copyWith(fontSize: 16, color: textCol),
                      ),
                      AmountText(
                        amount: _totalAmount,
                        style: AppTypography.title.copyWith(color: isDark ? AppColors.primaryDark : AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Mode Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Mode',
                    style: AppTypography.label.copyWith(color: textCol),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPaymentModeOption('Cash', Icons.money_rounded),
                      const SizedBox(width: 8),
                      _buildPaymentModeOption('UPI', Icons.qr_code_rounded),
                      const SizedBox(width: 8),
                      _buildPaymentModeOption('Credit', Icons.credit_score_rounded),
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
                    Text('Total Payable', style: AppTypography.caption),
                    AmountText(
                      amount: _totalAmount,
                      style: AppTypography.title.copyWith(
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitSale,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save & Issue Bill'),
              ),
            ],
          ),
        ),
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

