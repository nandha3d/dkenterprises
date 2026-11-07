import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/error_state.dart';
import '../../../core/ui/status_chip.dart';

class PurchaseBillsScreen extends ConsumerStatefulWidget {
  const PurchaseBillsScreen({super.key});

  @override
  ConsumerState<PurchaseBillsScreen> createState() => _PurchaseBillsScreenState();
}

class _PurchaseBillsScreenState extends ConsumerState<PurchaseBillsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _purchases = [];

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  Future<void> _fetchPurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final authState = ref.read(authNotifierProvider);
    final companyId = authState.activeCompany?.id ?? 0;
    final cacheKey = 'purchases_company_$companyId';

    final cached = await db.getCache(cacheKey);
    if (cached != null && cached is List) {
      setState(() {
        _purchases = cached.cast<Map<String, dynamic>>();
      });
    }

    final result = await client.get(
      ApiEndpoints.purchases,
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
        _purchases = list;
        _isLoading = false;
      });
    } else {
      if (_purchases.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = result.failureOrNull?.message ?? 'Failed to load purchase bills';
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
        title: const Text('Purchase Bills & GRN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchPurchases,
          ),
        ],
      ),
      body: _isLoading && _purchases.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _purchases.isEmpty
              ? ErrorState(message: _errorMessage!, onRetry: _fetchPurchases)
              : _purchases.isEmpty
                  ? const EmptyState(
                      title: 'No Purchase Bills',
                      message: 'No inward procurement bills recorded for this company yet.',
                      icon: Icons.shopping_bag_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPurchases,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _purchases.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final p = _purchases[index];
                          final refNo = p['reference_no']?.toString() ?? '#PUR-${p['id']}';
                          final supplier = p['supplier'] is Map
                              ? (p['supplier']['name']?.toString() ?? 'Supplier')
                              : p['supplier_name']?.toString() ?? 'Supplier';
                          final grandTotal = num.tryParse(p['grand_total']?.toString() ?? '0') ?? 0;
                          final paidAmount = num.tryParse(p['paid_amount']?.toString() ?? '0') ?? 0;
                          final dateStr = p['date']?.toString() ?? '';

                          final isSettled = paidAmount >= grandTotal && grandTotal > 0;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        refNo,
                                        style: AppTypography.label.copyWith(
                                          color: isDark ? AppColors.primaryDark : AppColors.primary,
                                        ),
                                      ),
                                      StatusChip(
                                        status: isSettled ? DocumentStatus.paid : DocumentStatus.pending,
                                        customLabel: isSettled ? 'Settled' : 'Payable Due',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    supplier,
                                    style: AppTypography.section.copyWith(fontSize: 16, color: textCol),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr,
                                        style: AppTypography.caption.copyWith(color: mutedCol),
                                      ),
                                      AmountText(amount: grandTotal),
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

