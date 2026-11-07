import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/ui/amount_text.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/error_state.dart';

class AccountingBooksScreen extends ConsumerStatefulWidget {
  const AccountingBooksScreen({super.key});

  @override
  ConsumerState<AccountingBooksScreen> createState() => _AccountingBooksScreenState();
}

class _AccountingBooksScreenState extends ConsumerState<AccountingBooksScreen> {
  int _selectedBook = 0; // 0: Cash Book (1010), 1: Bank Book (1020)
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _financials;

  @override
  void initState() {
    super.initState();
    _fetchFinancials();
  }

  Future<void> _fetchFinancials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = ref.read(apiClientProvider);
    final result = await client.get(
      ApiEndpoints.financials,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final rawData = result.dataOrNull!;
      final liveData = rawData['data'] is Map<String, dynamic>
          ? rawData['data'] as Map<String, dynamic>
          : (rawData['data'] is Map ? Map<String, dynamic>.from(rawData['data'] as Map) : rawData);
      setState(() {
        _financials = liveData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.failureOrNull?.message ?? 'Failed to load ledger books';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final cashBalance = _financials?['cash_balance'] as num? ??
        _financials?['cash_in_hand_1010'] as num? ?? 0;
    final bankBalance = _financials?['bank_balance'] as num? ??
        _financials?['bank_account_1020'] as num? ?? 0;

    final allTx = (_financials?['recent_transactions'] as List<dynamic>?) ?? [];
    final currentBookType = _selectedBook == 0 ? 'cash' : 'bank';
    final filteredTx = allTx.where((t) {
      if (t is Map) {
        final type = (t['account_type'] ?? 'cash').toString().toLowerCase();
        return type == currentBookType;
      }
      return false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting & Cash Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchFinancials,
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Book Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(bottom: BorderSide(color: borderCol, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Cash Book (1010)')),
                      ButtonSegment(value: 1, label: Text('Bank Book (1020)')),
                    ],
                    selected: {_selectedBook},
                    onSelectionChanged: (selected) {
                      setState(() => _selectedBook = selected.first);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Total Balance Hero Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedBook == 0 ? 'Current Cash in Hand' : 'Current Bank Balance',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 4),
                        AmountText(
                          amount: _selectedBook == 0 ? cashBalance : bankBalance,
                          style: AppTypography.numberDisplay.copyWith(
                            color: isDark ? AppColors.primaryDark : AppColors.primary,
                            fontSize: 26,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _selectedBook == 0 ? Icons.payments_rounded : Icons.account_balance_rounded,
                      size: 36,
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recent Ledger Movements List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? ErrorState(message: _errorMessage!, onRetry: _fetchFinancials)
                    : filteredTx.isEmpty
                        ? EmptyState(
                            title: 'No Postings',
                            message: 'No ${_selectedBook == 0 ? "cash" : "bank"} transactions recorded yet for this company.',
                            icon: Icons.receipt_long_outlined,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredTx.length + 1,
                            itemBuilder: (ctx, idx) {
                              if (idx == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text('Recent Journal Postings', style: AppTypography.section.copyWith(fontSize: 16, color: textCol)),
                                );
                              }
                              final tx = filteredTx[idx - 1] as Map;
                              final title = tx['title']?.toString() ?? 'Journal Posting';
                              final amount = num.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
                              final isCredit = tx['is_credit'] == true || tx['is_credit'] == 1;
                              final dateStr = tx['date']?.toString() ?? '';
                              final formattedAmount = '${isCredit ? "+" : "-"}${AmountText.format(amount)}';

                              return _buildLedgerRow(title, formattedAmount, isCredit, dateStr);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerRow(String title, String amountStr, bool isCredit, String dateStr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isCredit ? AppColors.success : AppColors.danger).withOpacity(0.12),
          child: Icon(
            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 18,
            color: isCredit ? AppColors.success : AppColors.danger,
          ),
        ),
        title: Text(title, style: AppTypography.label.copyWith(color: textCol)),
        subtitle: Text(dateStr, style: AppTypography.caption),
        trailing: Text(
          amountStr,
          style: AppTypography.section.copyWith(
            fontSize: 15,
            color: isCredit ? AppColors.success : AppColors.danger,
          ),
        ),
      ),
    );
  }
}
