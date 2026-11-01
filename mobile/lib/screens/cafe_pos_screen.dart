import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CafePosScreen extends StatefulWidget {
  final bool isTamil;

  const CafePosScreen({super.key, required this.isTamil});

  @override
  State<CafePosScreen> createState() => _CafePosScreenState();
}

class _CafePosScreenState extends State<CafePosScreen> {
  final ApiService _apiService = ApiService();

  final List<CafeProductItem> _menuItems = const [
    CafeProductItem(id: 1, name: 'Special Filter Coffee', category: 'Hot Brews', price: 25.0, iconEmoji: '☕'),
    CafeProductItem(id: 2, name: 'Masala Ginger Tea', category: 'Hot Brews', price: 20.0, iconEmoji: '🫖'),
    CafeProductItem(id: 3, name: 'Egg Puff (Hot & Crisp)', category: 'Bakery', price: 30.0, iconEmoji: '🥐'),
    CafeProductItem(id: 4, name: 'Veg Samosa (2 Pcs)', category: 'Savories', price: 30.0, iconEmoji: '🥟'),
    CafeProductItem(id: 5, name: 'Paneer Roll', category: 'Bakery', price: 55.0, iconEmoji: '🌯'),
    CafeProductItem(id: 6, name: 'Cold Badam Milk', category: 'Cold Drinks', price: 40.0, iconEmoji: '🥤'),
    CafeProductItem(id: 7, name: 'Rich Chocolate Pastry', category: 'Bakery', price: 70.0, iconEmoji: '🍰'),
    CafeProductItem(id: 8, name: 'Butter Biscuit (Set)', category: 'Bakery', price: 20.0, iconEmoji: '🍪'),
  ];

  final Map<int, int> _cart = {}; // itemId -> qty
  String _selectedCategory = 'All';
  String _paymentMethod = 'UPI'; // 'Cash', 'UPI', 'Split'
  bool _isSubmitting = false;
  String? _lastOrderRef;

  // Drawer Reconciliation State
  final double _openingFloat = 1500.0;
  double _cashSalesToday = 3450.0;
  double _upiSalesToday = 8920.0;

  double _getCartTotal() {
    double total = 0.0;
    _cart.forEach((itemId, qty) {
      final item = _menuItems.firstWhere((p) => p.id == itemId);
      total += item.price * qty;
    });
    return total;
  }

  void _addToCart(int itemId) {
    setState(() {
      _cart[itemId] = (_cart[itemId] ?? 0) + 1;
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
      final item = _menuItems.firstWhere((p) => p.id == e.key);
      return {
        'product_id': item.id,
        'product_name': item.name,
        'quantity': e.value,
        'unit_price': item.price,
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
        if (_paymentMethod == 'Cash') {
          _cashSalesToday += total;
        } else {
          _upiSalesToday += total;
        }
        _clearCart();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTamil
                ? 'ஆர்டர் [$_lastOrderRef] நிறைவடைந்தது! தொகை: ₹${total.toStringAsFixed(2)}'
                : 'Order [$_lastOrderRef] completed! Total: ₹${total.toStringAsFixed(2)}',
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showDrawerReconciliationDialog() {
    final cashController = TextEditingController(text: (_openingFloat + _cashSalesToday).toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final physicalCash = double.tryParse(cashController.text) ?? 0.0;
          final expectedCash = _openingFloat + _cashSalesToday;
          final variance = physicalCash - expectedCash;

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.point_of_sale, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.isTamil ? 'ஷிப்ட் கேஷ் டிராயர் தணிக்கை' : 'Shift Drawer Reconciliation',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDrawerRow(widget.isTamil ? 'தொடக்க மிதவை பணம் (Opening Float):' : 'Opening Cash Float:', '₹ ${_openingFloat.toStringAsFixed(2)}', Colors.white70),
                  const SizedBox(height: 6),
                  _buildDrawerRow(widget.isTamil ? 'இன்றைய நேரடி ரொக்க விற்பனை:' : 'Today Cash Sales:', '+ ₹ ${_cashSalesToday.toStringAsFixed(2)}', const Color(0xFF34D399)),
                  const SizedBox(height: 6),
                  _buildDrawerRow(widget.isTamil ? 'இன்றைய UPI / GPAY விற்பனை:' : 'Today UPI / QR Sales:', '₹ ${_upiSalesToday.toStringAsFixed(2)}', const Color(0xFF38BDF8)),
                  const Divider(color: Color(0xFF334155)),
                  _buildDrawerRow(widget.isTamil ? 'கணினி எதிர்பார்ப்பு ரொக்கம்:' : 'Expected Cash in Drawer:', '₹ ${expectedCash.toStringAsFixed(2)}', Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    widget.isTamil ? 'டிராயரில் எண்ணப்பட்ட நேரடி ரொக்கம் (₹):' : 'Physical Cash Counted in Drawer (₹):',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: cashController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setModalState(() {}),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: variance == 0 ? const Color(0xFF065F46) : const Color(0xFF7F1D1D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          variance == 0 ? (widget.isTamil ? 'கணக்கு சரியானது (Balanced)' : 'Perfectly Balanced') : (widget.isTamil ? 'வித்தியாசம் (Shortage/Surplus):' : 'Variance:'),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹ ${variance.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: variance >= 0 ? const Color(0xFF34D399) : const Color(0xFFF87171)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(widget.isTamil ? 'ரத்து' : 'Cancel', style: const TextStyle(color: Color(0xFF94A3B8)))),
              ElevatedButton(
                onPressed: () {
                  _apiService.reconcileCafeDrawer(
                    openingFloat: _openingFloat,
                    closingCash: physicalCash,
                    upiSettlement: _upiSalesToday,
                    cashSales: _cashSalesToday,
                  );
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                child: Text(widget.isTamil ? 'உறுதி செய்' : 'Close Shift & Balance'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Hot Brews', 'Bakery', 'Savories', 'Cold Drinks'];
    final filtered = _selectedCategory == 'All' ? _menuItems : _menuItems.where((p) => p.category == _selectedCategory).toList();
    final cartTotal = _getCartTotal();
    final cartItemCount = _cart.values.fold<int>(0, (sum, q) => sum + q);

    return Column(
      children: [
        // Top Toolbar: Shift Reconcile Button & Sales Pill
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6)),
                    child: Text('Cash: ₹${_cashSalesToday.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(6)),
                    child: Text('UPI: ₹${_upiSalesToday.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showDrawerReconciliationDialog,
                icon: const Icon(Icons.account_balance_wallet, size: 14),
                label: Text(widget.isTamil ? 'டிராயர் முடிவு' : 'Shift Drawer', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
              ),
            ],
          ),
        ),

        // Category Pills
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final isSel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFD97706) : const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSel ? const Color(0xFFD97706) : const Color(0xFF334155)),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.white : const Color(0xFF94A3B8)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Menu Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final item = filtered[i];
              final qtyInCart = _cart[item.id] ?? 0;

              return GestureDetector(
                onTap: () => _addToCart(item.id),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: qtyInCart > 0 ? const Color(0xFFD97706) : const Color(0xFF334155), width: qtyInCart > 0 ? 1.5 : 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.iconEmoji, style: const TextStyle(fontSize: 22)),
                          if (qtyInCart > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(10)),
                              child: Text('x$qtyInCart', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('₹ ${item.price.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Cart Summary & Checkout Bar
        if (cartTotal > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$cartItemCount items in cart',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _clearCart,
                          child: Text(widget.isTamil ? 'நீக்கு' : 'Clear', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
                        ),
                        Text(
                          '₹ ${cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildPaymentBtn('UPI', const Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    _buildPaymentBtn('Cash', const Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _checkoutOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                widget.isTamil ? 'விற்பனை செய்' : 'CONFIRM SALE',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentBtn(String method, Color color) {
    final isSel = _paymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? color : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSel ? color : const Color(0xFF334155)),
          ),
          alignment: Alignment.center,
          child: Text(
            method,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : const Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }
}
