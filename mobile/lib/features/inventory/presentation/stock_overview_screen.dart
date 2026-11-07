import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/error_state.dart';

class StockOverviewScreen extends ConsumerStatefulWidget {
  const StockOverviewScreen({super.key});

  @override
  ConsumerState<StockOverviewScreen> createState() => _StockOverviewScreenState();
}

class _StockOverviewScreenState extends ConsumerState<StockOverviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final authState = ref.read(authNotifierProvider);
    final companyId = authState.activeCompany?.id ?? 0;
    final cacheKey = 'products_company_$companyId';

    final cached = await db.getCache(cacheKey);
    if (cached != null && cached is List) {
      setState(() {
        _products = cached.cast<Map<String, dynamic>>();
      });
    }

    final result = await client.get(
      ApiEndpoints.products,
      fromJson: (data) {
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      },
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final list = result.dataOrNull!;
      await db.saveCache(cacheKey, list);
      setState(() {
        _products = list;
        _isLoading = false;
      });
    } else {
      if (_products.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = result.failureOrNull?.message ?? 'Failed to load inventory';
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedCol = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Stock Count',
            onPressed: () => context.push('/inventory/stock-count'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _products.isEmpty
              ? ErrorState(message: _errorMessage!, onRetry: _fetchProducts)
              : _products.isEmpty
                  ? const EmptyState(
                      title: 'No Inventory Items',
                      message: 'No stock or product items found in this warehouse.',
                      icon: Icons.inventory_2_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchProducts,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final item = _products[index];
                          final code = item['code']?.toString() ?? '—';
                          final name = item['name']?.toString() ?? 'Item';
                          final qty = num.tryParse(item['qty']?.toString() ?? '0') ?? 0;
                          final price = num.tryParse(item['price']?.toString() ?? '0') ?? 0;
                          final unit = item['unit']?.toString() ?? 'Pcs';

                          final isLowStock = qty <= 5;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: (isLowStock ? AppColors.danger : AppColors.primary).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_rounded,
                                      color: isLowStock ? AppColors.danger : AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: AppTypography.section.copyWith(fontSize: 15, color: textCol),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Code: $code',
                                          style: AppTypography.caption.copyWith(color: mutedCol),
                                        ),
                                        AmountText(
                                          amount: price,
                                          style: AppTypography.caption.copyWith(
                                            color: isDark ? AppColors.primaryDark : AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$qty $unit',
                                        style: AppTypography.title.copyWith(
                                          fontSize: 18,
                                          color: isLowStock ? AppColors.danger : textCol,
                                        ),
                                      ),
                                      if (isLowStock)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.danger.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Low Stock',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.danger,
                                            ),
                                          ),
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
    );
  }
}

