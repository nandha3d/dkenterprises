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
import '../../../core/ui/status_chip.dart';

class SalesInvoicesScreen extends ConsumerStatefulWidget {
  const SalesInvoicesScreen({super.key});

  @override
  ConsumerState<SalesInvoicesScreen> createState() => _SalesInvoicesScreenState();
}

class _SalesInvoicesScreenState extends ConsumerState<SalesInvoicesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = ref.read(apiClientProvider);
    final db = ref.read(localDatabaseProvider);
    final authState = ref.read(authNotifierProvider);
    final companyId = authState.activeCompany?.id ?? 0;
    final cacheKey = 'invoices_company_$companyId';

    // Check offline cache
    final cached = await db.getCache(cacheKey);
    if (cached != null && cached is List) {
      setState(() {
        _invoices = cached.cast<Map<String, dynamic>>();
      });
    }

    final result = await client.get(
      ApiEndpoints.invoices,
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
        _invoices = list;
        _isLoading = false;
      });
    } else {
      if (_invoices.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = result.failureOrNull?.message ?? 'Failed to load invoices';
        });
      } else {
        setState(() {
          _isLoading = false;
        });
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
        title: const Text('Sales Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchInvoices,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sales/new'),
        backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Bill', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading && _invoices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _invoices.isEmpty
              ? ErrorState(message: _errorMessage!, onRetry: _fetchInvoices)
              : _invoices.isEmpty
                  ? const EmptyState(
                      title: 'No Sales Invoices',
                      message: 'No commercial sales invoices recorded yet for this company.',
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchInvoices,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _invoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final inv = _invoices[index];
                          final refNo = inv['reference_no']?.toString() ?? '#INV-${inv['id']}';
                          final customer = inv['customer'] is Map
                              ? (inv['customer']['name']?.toString() ?? 'Walk-in Customer')
                              : inv['customer_name']?.toString() ?? 'Customer';
                          final grandTotal = num.tryParse(inv['grand_total']?.toString() ?? '0') ?? 0;
                          final paidAmount = num.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0;
                          final dateStr = inv['date']?.toString() ?? inv['created_at']?.toString() ?? '';

                          final isPaid = paidAmount >= grandTotal && grandTotal > 0;
                          final status = isPaid ? DocumentStatus.paid : DocumentStatus.pending;

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
                                        status: status,
                                        customLabel: isPaid ? 'Paid' : 'Due',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    customer,
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
