import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class CafePosScreen extends StatefulWidget {
  final bool isTamil;

  const CafePosScreen({super.key, required this.isTamil});

  @override
  State<CafePosScreen> createState() => _CafePosScreenState();
}

class _CafePosScreenState extends State<CafePosScreen> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;

  final Map<int, int> _cart = {}; // itemId -> qty
  String _paymentMethod = 'UPI'; // 'Cash', 'UPI'
  bool _isSubmitting = false;
  String? _lastOrderRef;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final data = await _apiService.fetchProducts();
    if (mounted) {
      setState(() {
        _menuItems = data;
        _isLoading = false;
      });
    }
  }

  double _getCartTotal() {
    double total = 0.0;
    _cart.forEach((itemId, qty) {
      final item = _menuItems.firstWhere((p) => p['id'] == itemId, orElse: () => {});
      final price = (item['price'] ?? 0.0).toDouble();
      total += price * qty;
    });
    return total;
  }

  void _addToCart(int itemId) {
    setState(() {
      _cart[itemId] = (_cart[itemId] ?? 0) + 1;
    });
  }

  void _removeFromCart(int itemId) {
    setState(() {
      if ((_cart[itemId] ?? 0) > 1) {
        _cart[itemId] = _cart[itemId]! - 1;
      } else {
        _cart.remove(itemId);
      }
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  Future<void> _checkoutOrder() async {
    final total = _getCartTotal();
    if (total <= 0) return;

    setState(() => _isSubmitting = true);

    final items = _cart.entries.map((e) {
      final item = _menuItems.firstWhere((p) => p['id'] == e.key, orElse: () => {});
      return {
        'product_id': e.key,
        'product_name': item['name'] ?? 'Item',
        'quantity': e.value,
        'unit_price': (item['price'] ?? 0.0).toDouble(),
      };
    }).toList();

    final res = await _apiService.submitCafeOrder(
      totalAmount: total,
      paymentMode: _paymentMethod,
      items: items,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _lastOrderRef = res['order_reference'] ?? 'POS-${DateTime.now().millisecondsSinceEpoch}';
        _clearCart();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTamil
                ? 'ஆர்டர் [$_lastOrderRef] நிறைவடைந்தது! தொகை: ₹${total.toStringAsFixed(2)}'
                : 'Order [$_lastOrderRef] billed! Total: ₹${total.toStringAsFixed(2)}',
          ),
          backgroundColor: AppColors.brandEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final total = _getCartTotal();

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPurple))
          : Column(
              children: [
                // Top Cart Overview Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 18,
                    tintColor: AppColors.brandPurple,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t ? 'அரண் கஃபே விரைவு கவுண்டர்' : 'Aran Cafe Express Touch POS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t ? 'நேரடி தயாரிப்புகள் பட்டியல்' : 'Live Product Catalog Matrix',
                              style: TextStyle(fontSize: 10, color: AppColors.textDim(context)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.brandEmerald.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.brandEmerald,
                                ),
                              ),
                            ),
                            if (_cart.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.brandDanger),
                                onPressed: _clearCart,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Touch POS Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.35,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _menuItems.length,
                    itemBuilder: (ctx, idx) {
                      final item = _menuItems[idx];
                      final itemId = item['id'] as int;
                      final price = (item['price'] ?? 0.0).toDouble();
                      final count = _cart[itemId] ?? 0;

                      return GlassCard(
                        isInteractive: true,
                        padding: const EdgeInsets.all(12),
                        borderRadius: 16,
                        tintColor: count > 0 ? AppColors.brandPurple : null,
                        borderColor: count > 0 ? AppColors.brandPurple : null,
                        borderWidth: count > 0 ? 1.5 : 1.0,
                        onTap: () => _addToCart(itemId),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SKU: ${item['code'] ?? 'POS'}',
                                  style: TextStyle(fontSize: 9.5, color: AppColors.textDim(context), fontWeight: FontWeight.bold),
                                ),
                                if (count > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPurple,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'x$count',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              item['name'] ?? 'Product',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text(context),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandEmerald,
                                  ),
                                ),
                                if (count > 0)
                                  InkWell(
                                    onTap: () => _removeFromCart(itemId),
                                    child: const Icon(Icons.remove_circle, size: 18, color: AppColors.brandDanger),
                                  )
                                else
                                  const Icon(Icons.add_circle, size: 18, color: AppColors.brandPurple),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Checkout Dock Card
                if (total > 0)
                  GlassCard(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    child: Column(
                      children: [
                        Row(
                          children: ['UPI', 'Cash'].map((m) {
                            final isSel = _paymentMethod == m;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text(m),
                                  selected: isSel,
                                  selectedColor: AppColors.brandPurple,
                                  labelStyle: TextStyle(
                                    color: isSel ? Colors.white : AppColors.textMuted(context),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                  onSelected: (val) => setState(() => _paymentMethod = m),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _checkoutOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandEmerald,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    t ? 'பில் அச்சிடு (₹${total.toStringAsFixed(2)})' : 'Generate Bill (₹${total.toStringAsFixed(2)})',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
