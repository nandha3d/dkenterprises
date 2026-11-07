import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Formats and renders Indian Currency (₹) with tabular figures.
class AmountText extends StatelessWidget {
  final num amount;
  final TextStyle? style;
  final Color? color;
  final bool showSign;

  const AmountText({
    super.key,
    required this.amount,
    this.style,
    this.color,
    this.showSign = false,
  });

  static String format(num value, {bool showSign = false}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    final sign = showSign && value > 0 ? '+' : '';
    return '$sign${formatter.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Text(
      format(amount, showSign: showSign),
      style: (style ?? AppTypography.numberCard).copyWith(
        color: color ?? defaultColor,
      ),
    );
  }
}

