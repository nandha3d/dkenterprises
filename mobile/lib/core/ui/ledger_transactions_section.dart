import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'amount_text.dart';

/// Live Accounting Ledger Postings with flexible Date Filtering across all operational verticals.
class LedgerTransactionsSection extends StatelessWidget {
  final List<dynamic> entries;
  final String activePeriod;
  final String activePeriodLabel;
  final String verticalIndustry;
  final Function(String period, {DateTime? startDate, DateTime? endDate}) onDateFilterSelected;

  const LedgerTransactionsSection({
    super.key,
    required this.entries,
    required this.activePeriod,
    required this.activePeriodLabel,
    required this.verticalIndustry,
    required this.onDateFilterSelected,
  });

  static const List<Map<String, String>> filterOptions = [
    {'key': 'today', 'label': 'Today'},
    {'key': 'yesterday', 'label': 'Yesterday'},
    {'key': 'this_week', 'label': 'This Week'},
    {'key': 'this_month', 'label': 'This Month'},
    {'key': 'custom', 'label': 'Custom...'},
  ];

  Future<void> _handleCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateFilterSelected('custom', startDate: picked.start, endDate: picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrim = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title & Subtitle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Accounting Ledger Postings',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textPrim,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time journal vouchers, receipts & expenses ($activePeriodLabel)',
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brandEmerald.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brandEmerald.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 7, color: AppColors.brandEmerald),
                  const SizedBox(width: 4),
                  Text(
                    '${entries.length} POSTED',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandEmerald,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Horizontal Date Range Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filterOptions.map((opt) {
              final isSel = opt['key'] == activePeriod;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () {
                    if (opt['key'] == 'custom') {
                      _handleCustomDateRange(context);
                    } else {
                      onDateFilterSelected(opt['key']!);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AppColors.primary : borderCol,
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (opt['key'] == 'today')
                          Icon(Icons.today_rounded, size: 12, color: isSel ? Colors.white : textMuted)
                        else if (opt['key'] == 'custom')
                          Icon(Icons.date_range_rounded, size: 12, color: isSel ? Colors.white : textMuted),
                        if (opt['key'] == 'today' || opt['key'] == 'custom')
                          const SizedBox(width: 4),
                        Text(
                          opt['label']!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? Colors.white : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Ledger List Container
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 36, color: textMuted.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Text(
                    'No ledger entries found for $activePeriodLabel',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: textPrim),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try selecting "This Month" or "This Week" to inspect posted journals.',
                    style: TextStyle(fontSize: 11, color: textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('View This Month', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => onDateFilterSelected('this_month'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderCol, width: 1.1),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: borderCol),
              itemBuilder: (context, index) {
                final entry = entries[index] is Map ? entries[index] as Map : {};
                final title = entry['title']?.toString() ?? 'Journal Posting';
                final voucher = entry['voucher_no']?.toString() ?? '';
                final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
                final isCredit = entry['is_credit'] == true || entry['is_credit'] == 1;
                final dateStr = entry['formatted_date']?.toString() ?? entry['date']?.toString() ?? '';
                final acCode = entry['account_code']?.toString() ?? '1010';
                final acName = entry['account_name']?.toString() ?? 'Cash';
                final mode = entry['payment_mode']?.toString() ?? 'Cash';
                final category = entry['category']?.toString() ?? '';

                // Relevant visual colors and icons
                final (Color badgeColor, IconData itemIcon) = switch (category) {
                  'receipt' => (AppColors.brandEmerald, Icons.arrow_downward_rounded),
                  'sale' => (AppColors.brandAmber, Icons.point_of_sale_rounded),
                  'expense' => (AppColors.brandDanger, Icons.arrow_upward_rounded),
                  'trip' => (AppColors.brandSky, Icons.fire_truck_rounded),
                  'delivery' => (const Color(0xFF8B5CF6), Icons.water_drop_rounded),
                  _ => isCredit ? (AppColors.brandEmerald, Icons.add_rounded) : (AppColors.brandDanger, Icons.remove_rounded),
                };

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // Leading Transaction Icon
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(isDark ? 0.20 : 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: badgeColor.withOpacity(0.35)),
                        ),
                        child: Icon(itemIcon, size: 16, color: badgeColor),
                      ),
                      const SizedBox(width: 12),

                      // Description, Voucher & Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrim,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (voucher.isNotEmpty) ...[
                                  Text(
                                    voucher,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: textMuted,
                                    ),
                                  ),
                                  Text(' • ', style: TextStyle(fontSize: 10, color: textMuted)),
                                ],
                                Text(
                                  dateStr,
                                  style: TextStyle(fontSize: 10, color: textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            // Account Tag Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$acName ($acCode) • $mode',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Signed Amount Pill
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AmountText(
                            amount: isCredit ? amount : -amount.abs(),
                            showSign: true,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isCredit ? AppColors.brandEmerald : AppColors.brandDanger,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCredit ? 'CREDIT' : 'DEBIT',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: isCredit ? AppColors.brandEmerald : AppColors.brandDanger,
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

        const SizedBox(height: 12),

        // Full Ledger Navigation Action
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 15),
            label: const Text('Open Full Accounting & Cash Books (1010/1020) →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: () => context.push('/accounting/books'),
          ),
        ),
      ],
    );
  }
}
