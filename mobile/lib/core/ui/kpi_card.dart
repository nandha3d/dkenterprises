import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'amount_text.dart';
import 'sparkline_chart.dart';

/// Compact, theme-colored executive KPI card with embedded graphical sparkline chart.
class KpiCard extends StatelessWidget {
  final String title;
  final num? amount;
  final String? customValue;
  final String? subtitle;
  final String? glCode;
  final IconData icon;
  final Color? iconColor;
  final Color? accentColor;
  final List<num>? sparklineData;
  final String? trendBadge;
  final bool isTrendPositive;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    this.amount,
    this.customValue,
    this.subtitle,
    this.glCode,
    required this.icon,
    this.iconColor,
    this.accentColor,
    this.sparklineData,
    this.trendBadge,
    this.isTrendPositive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? iconColor ?? (isDark ? AppColors.primaryDark : AppColors.primary);
    final cardBg = isDark
        ? Color.alphaBlend(color.withOpacity(0.08), const Color(0xFF111827))
        : Color.alphaBlend(color.withOpacity(0.04), Colors.white);
    final borderCol = color.withOpacity(isDark ? 0.35 : 0.25);
    final titleCol = isDark ? Colors.white70 : const Color(0xFF475569);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isDark ? 0.12 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Title + GL code tag + Icon Container
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.caption.copyWith(
                          color: titleCol,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (glCode != null && glCode!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            glCode!.startsWith('GL') ? glCode! : 'GL $glCode',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: color.withOpacity(0.85),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
              ],
            ),

            // Middle: Amount + Sparkline curve side-by-side
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (amount != null)
                        AmountText(
                          amount: amount!,
                          style: AppTypography.numberCard.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        )
                      else if (customValue != null)
                        Text(
                          customValue!,
                          style: AppTypography.numberCard.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 10,
                              color: titleCol,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (sparklineData != null && sparklineData!.isNotEmpty)
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: SparklineChart(
                        data: sparklineData!,
                        lineColor: color,
                        height: 28,
                      ),
                    ),
                  ),
              ],
            ),

            // Bottom: Trend Growth Badge (if present)
            if (trendBadge != null && trendBadge!.isNotEmpty)
              Row(
                children: [
                  Icon(
                    isTrendPositive ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
                    size: 13,
                    color: isTrendPositive ? AppColors.brandEmerald : color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trendBadge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isTrendPositive ? AppColors.brandEmerald : color,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
