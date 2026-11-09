import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/empty_state.dart';
import 'product_form_screen.dart';

class ProductsCatalogScreen extends ConsumerStatefulWidget {
  const ProductsCatalogScreen({super.key});

  @override
  ConsumerState<ProductsCatalogScreen> createState() => _ProductsCatalogScreenState();
}

class _ProductsCatalogScreenState extends ConsumerState<ProductsCatalogScreen> {
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
    final client = ref.read(apiClientProvider);

    try {
      final res = await client.get(
        ApiEndpoints.products,
        fromJson: (data) {
          final list = data is Map && data['data'] is List
              ? data['data'] as List
              : (data is List ? data : []);
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        },
      );

      if (!mounted) return;

      if (res.isSuccess) {
        setState(() {
          _products = res.dataOrNull ?? [];
          _applyFilter();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    var list = List<Map<String, dynamic>>.from(_products);
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final code = (p['code'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    }
    _filteredProducts = list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardCol = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog & Config'),
        actions: [
          IconButton(
            tooltip: 'Refresh Catalog',
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
          IconButton(
            tooltip: 'Add New Product',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const ProductFormScreen(),
                ),
              );
              if (result == true) {
                _loadProducts();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardCol,
              border: Border(bottom: BorderSide(color: borderCol)),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search product by name, SKU or barcode...',
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _applyFilter();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _applyFilter();
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredProducts.length} Products Listed',
                      style: AppTypography.caption.copyWith(color: textMuted, fontWeight: FontWeight.w700),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FULL CONFIG READY',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const EmptyState(
                        title: 'No Products Found',
                        message: 'No items match your search. Tap + to configure a new product.',
                        icon: Icons.inventory_2_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final p = _filteredProducts[index];
                            final name = p['name']?.toString() ?? 'Product';
                            final code = p['code']?.toString() ?? 'SKU';
                            final price = (p['price'] as num?)?.toDouble() ?? 0.0;
                            final cost = (p['cost'] as num?)?.toDouble() ?? 0.0;
                            final type = p['type']?.toString().toUpperCase() ?? 'STANDARD';
                            final hasVariant = p['is_variant'] == 1 || p['is_variant'] == true;
                            final hasBatch = p['is_batch'] == 1 || p['is_batch'] == true;

                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  final result = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => ProductFormScreen(initialProduct: p),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadProducts();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: AppTypography.label.copyWith(fontSize: 14, color: textCol),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '₹${price.toStringAsFixed(2)}',
                                                  style: AppTypography.numberCard.copyWith(
                                                    fontSize: 15,
                                                    color: AppColors.success,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    code,
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Cost: ₹${cost.toStringAsFixed(2)}',
                                                  style: AppTypography.caption.copyWith(color: textMuted),
                                                ),
                                                const Spacer(),
                                                const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
                                                const SizedBox(width: 2),
                                                const Text(
                                                  'Configure',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    type,
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                  ),
                                                ),
                                                if (hasVariant)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.brandPurple.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'VARIANTS',
                                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.brandPurple),
                                                    ),
                                                  ),
                                                if (hasBatch)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.warning.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'BATCH EXPIRY',
                                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.warning),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const ProductFormScreen(),
            ),
          );
          if (result == true) {
            _loadProducts();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Product'),
      ),
    );
  }
}
