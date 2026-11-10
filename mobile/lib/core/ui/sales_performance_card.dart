import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'amount_text.dart';
import 'sparkline_chart.dart';

/// Interactive, theme-colored Sales Analytics Card with period filters and graphical trend curve.
class SalesPerformanceCard extends StatelessWidget {
  final num salesAmount;
  final num todaySalesAmount;
  final int salesCount;
  final String activePeriod;
  final String activePeriodLabel;
  final List<num> trendPoints;
  final String verticalIndustry;
  final Function(String period, {DateTime? startDate, DateTime? endDate}) onPeriodSelected;

  const SalesPerformanceCard({
    super.key,
    required this.salesAmount,
    required this.todaySalesAmount,
    required this.salesCount,
    required this.activePeriod,
    required this.activePeriodLabel,
    required this.trendPoints,
    required this.verticalIndustry,
    required this.onPeriodSelected,
  });

  static const List<Map<String, String>> periodOptions = [
    {'key': 'this_month', 'label': 'This Month'},
    {'key': 'today', 'label': 'Today'},
    {'key': 'yesterday', 'label': 'Yesterday'},
    {'key': 'this_week', 'label': 'This Week'},
    {'key': 'last_week', 'label': 'Last Week'},
    {'key': 'last_month', 'label': 'Last Month'},
    {'key': 'this_quarter', 'label': 'Quarterly'},
    {'key': 'custom', 'label': 'Custom Range...'},
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
              seedColor: AppColors.brandAmber,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onPeriodSelected('custom', startDate: picked.start, endDate: picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = AppColors.brandAmber;
    final cardBg = isDark
        ? const Color(0xFF1C1917) // warm slate dark
        : const Color(0xFFFFFBEB); // soft amber tint
    final borderCol = accent.withOpacity(isDark ? 0.35 : 0.30);
    final textPrim = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF64748B);

    final verticalLabel = switch (verticalIndustry) {
      'cafe_bakery' => 'Bakery Counter & POS Sales',
      'bulk_water' => 'Tanker Freight & Water Decanting',
      'packaged_water' => '20L Can Deliveries & Bottle Sales',
      'textile' => 'Fabric & Yarn Sales',
      _ => 'Commercial Revenue',
    };

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Title + Active Period Filter Button
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12, top: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(isDark ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accent.withOpacity(0.35)),
                      ),
                      child: const Icon(Icons.insights_rounded, size: 18, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Sales & Revenue',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textPrim,
                          ),
                        ),
                        Text(
                          verticalLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Interactive Period Selector Dropdown
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'custom') {
                      _handleCustomDateRange(context);
                    } else {
                      onPeriodSelected(val);
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  itemBuilder: (context) => periodOptions.map((opt) {
                    final isSel = opt['key'] == activePeriod;
                    return PopupMenuItem<String>(
                      value: opt['key'],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            opt['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                              color: isSel ? accent : null,
                            ),
                          ),
                          if (isSel)
                            const Icon(Icons.check_rounded, size: 16, color: accent),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(isDark ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 13, color: accent),
                        const SizedBox(width: 5),
                        Text(
                          activePeriodLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, size: 16, color: accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Main Metric & Today Pulse Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL SALES ($activePeriodLabel)',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AmountText(
                      amount: salesAmount,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: textPrim,
                      ),
                    ),
                  ],
                ),

                // Today's Pulse Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.brandEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'SALES TODAY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      AmountText(
                        amount: todaySalesAmount,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Embedded Graphical Sparkline / Trend Graph
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SparklineChart(
              data: trendPoints.isNotEmpty ? trendPoints : [salesAmount * 0.9, salesAmount],
              lineColor: accent,
              height: 48,
              showEndDot: true,
              fillGradient: true,
            ),
          ),

          const SizedBox(height: 10),

          // Horizontal Quick-Filter Presets Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: periodOptions.map((opt) {
                final isSelected = opt['key'] == activePeriod;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      if (opt['key'] == 'custom') {
                        _handleCustomDateRange(context);
                      } else {
                        onPeriodSelected(opt['key']!);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent
                            : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? accent : borderCol.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        opt['label']!,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Metadata Row: Total Bills & Settlement Ratio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white.withOpacity(0.6),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(19),
                bottomRight: Radius.circular(19),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_rounded, size: 14, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      '$salesCount Transactions / Bills',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.brandEmerald),
                    SizedBox(width: 4),
                    Text(
                      'Live Backend Ledger Sync',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.brandEmerald),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
