import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';

class CafePosScreen extends ConsumerStatefulWidget {
  const CafePosScreen({super.key});

  @override
  ConsumerState<CafePosScreen> createState() => _CafePosScreenState();
}

class _CafePosScreenState extends ConsumerState<CafePosScreen> {
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;
  final Map<int, int> _cart = {}; // itemId -> qty
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
  }

  Future<void> _fetchMenuItems() async {
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
        _isLoading = false;
        if (res.isSuccess && (res.dataOrNull?.isNotEmpty ?? false)) {
          _menuItems = res.dataOrNull!.map((p) => {
            'id': p['id'] as int,
            'name': p['name']?.toString() ?? 'Item',
            'price': (p['price'] as num?)?.toDouble() ?? 0.0,
            'category': (p['category'] ?? p['category_name'] ?? 'Bakery & Cafe')?.toString(),
          }).toList();
        }
      });
    }
  }

  double get _totalBill {
    double total = 0;
    _cart.forEach((id, qty) {
      final item = _menuItems.firstWhere((m) => m['id'] == id);
      total += (item['price'] as double) * qty;
    });
    return total;
  }

  void _addToCart(int id) {
    setState(() {
      _cart[id] = (_cart[id] ?? 0) + 1;
    });
  }

  void _removeFromCart(int id) {
    setState(() {
      if ((_cart[id] ?? 0) > 1) {
        _cart[id] = _cart[id]! - 1;
      } else {
        _cart.remove(id);
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Tap items to add to order.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final syncWorker = ref.read(syncWorkerProvider);

    final payload = {
      'order_items': _cart.entries.map((e) => {'item_id': e.key, 'qty': e.value}).toList(),
      'grand_total': _totalBill,
      'payment_mode': 'Cash',
      'client_timestamp': DateTime.now().toIso8601String(),
    };

    final idempotencyKey = const Uuid().v4();

    final result = await client.post(
      ApiEndpoints.cafeOrders,
      data: payload,
      idempotencyKey: idempotencyKey,
      fromJson: (data) => data,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _cart.clear();
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cafe POS ticket issued and drawer updated!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      await db.queueMutation(
        id: const Uuid().v4(),
        endpoint: ApiEndpoints.cafeOrders,
        method: 'POST',
        payload: payload,
        idempotencyKey: idempotencyKey,
      );
      await syncWorker.refreshPendingCount();

      setState(() {
        _cart.clear();
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('POS order stored in offline Outbox! Will sync automatically.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aran Cafe POS Terminal'),
        actions: [
          if (_cart.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _cart.clear()),
              child: const Text('Clear', style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Items Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _menuItems.isEmpty
                    ? const Center(
                        child: Text('No menu products configured for this branch.'),
                      )
                    : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              itemCount: _menuItems.length,
              itemBuilder: (ctx, index) {
                final item = _menuItems[index];
                final id = item['id'] as int;
                final qty = _cart[id] ?? 0;

                return InkWell(
                  onTap: () => _addToCart(id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: qty > 0 ? (isDark ? AppColors.primaryDark : AppColors.primary) : borderCol,
                        width: qty > 0 ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['name'] as String,
                                style: AppTypography.label.copyWith(color: textCol, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (qty > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.primaryDark : AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'x$qty',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AmountText(
                              amount: item['price'] as double,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.primaryDark : AppColors.primary,
                              ),
                            ),
                            if (qty > 0)
                              InkWell(
                                onTap: () => _removeFromCart(id),
                                child: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: AppColors.danger),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Checkout Bar
          Container(
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
                        Text('Order Total (${_cart.values.fold<int>(0, (a, b) => a + b)} Items)', style: AppTypography.caption),
                        AmountText(
                          amount: _totalBill,
                          style: AppTypography.title.copyWith(
                            color: isDark ? AppColors.primaryDark : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting || _cart.isEmpty ? null : _submitOrder,
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Charge & Print Slip'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(180, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

