import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ProductsScreen extends StatefulWidget {
  final bool isTamil;

  const ProductsScreen({super.key, required this.isTamil});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';

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
        _products = data;
        _applyFilter(_searchQuery);
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      final q = query.toLowerCase();
      _filteredProducts = _products.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final code = (p['code'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isTamil;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandPurple, AppColors.brandNavy],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              t ? 'பொருட்கள் & விலைப்பட்டியல்' : 'Products & Price Matrix',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text(context),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.appBarBg(context),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: t ? 'புதுப்பி' : 'Refresh',
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Summary Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  borderRadius: 14,
                  blurSigma: 12,
                  child: TextField(
                    style: TextStyle(color: AppColors.text(context), fontSize: 13),
                    decoration: InputDecoration(
                      hintText: t
                          ? 'பொருள் பெயர் அல்லது குறியீடு தேடுக...'
                          : 'Search product by name or SKU...',
                      hintStyle: TextStyle(color: AppColors.textDim(context), fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.brandPurple),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _applyFilter('')),
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _applyFilter(val)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.brandEmerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t
                              ? 'மொத்தம்: ${_filteredProducts.length} பொருட்கள்'
                              : 'Catalog: ${_filteredProducts.length} SKUs Listed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple.withOpacity(isDark ? 0.25 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.brandPurple.withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        t ? 'நேரடி பட்டியல்' : 'LIVE CATALOG',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandPurple,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.brandPurple),
                  )
                : _filteredProducts.isEmpty
                    ? Center(
                        child: GlassCard(
                          padding: const EdgeInsets.all(24),
                          borderRadius: 24,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: AppColors.textDim(context),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t ? 'பொருட்கள் கிடைக்கவில்லை' : 'No products found',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t ? 'தேடலை மாற்றவும்' : 'Try searching another keyword',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textDim(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        color: AppColors.brandPurple,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (ctx, idx) {
                            final p = _filteredProducts[idx];
                            final price = (p['price'] ?? 0.0).toDouble();
                            final code = (p['code'] ?? 'SKU').toString();

                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              borderRadius: 16,
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.brandNavy, AppColors.brandPurple],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.brandPurple.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.inventory, color: Colors.white, size: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['name'] ?? 'Product',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.text(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.brandSky.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                code,
                                                style: const TextStyle(
                                                  color: AppColors.brandSky,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'GST Standard',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textDim(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.brandEmerald,
                                        ),
                                      ),
                                      Text(
                                        t ? 'அடிப்படை விலை' : 'Unit Price',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
