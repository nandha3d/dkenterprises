import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Interactive multi-day sales, collections, and GST chart card for Admin dashboards.
class DailySalesChart extends StatefulWidget {
  final List<Map<String, dynamic>> series;
  final int selectedDays;
  final ValueChanged<int> onDaysChanged;
  final double collectedTotal;
  final double dueTotal;
  final double gstTotal;
  final RippleSkin skin;
  final bool isDark;

  const DailySalesChart({
    super.key,
    required this.series,
    required this.selectedDays,
    required this.onDaysChanged,
    required this.collectedTotal,
    required this.dueTotal,
    required this.gstTotal,
    required this.skin,
    required this.isDark,
  });

  @override
  State<DailySalesChart> createState() => _DailySalesChartState();
}

class _DailySalesChartState extends State<DailySalesChart> {
  static final NumberFormat _inrCompact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );
  static final NumberFormat _inrExact = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  int? _selectedIndex;

  double _num(dynamic raw) => double.tryParse(raw?.toString() ?? '0') ?? 0.0;

  @override
  void didUpdateWidget(covariant DailySalesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex != null && _selectedIndex! >= widget.series.length) {
      _selectedIndex = widget.series.isEmpty ? null : widget.series.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final series = widget.series;
    final activeIdx = series.isEmpty
        ? null
        : (_selectedIndex != null && _selectedIndex! < series.length
            ? _selectedIndex!
            : series.length - 1);

    double maxVal = 0.0;
    for (final row in series) {
      final total = _num(row['total']);
      if (total > maxVal) maxVal = total;
    }
    if (maxVal <= 0) maxVal = 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(skin.cardRadius),
        border: Border.all(color: skin.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.22 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: skin.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: skin.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Sales & Collections',
                      style: AppTypography.section.copyWith(color: skin.ink),
                    ),
                    Text(
                      'ERP invoices synced with GST ledger',
                      style: AppTypography.caption.copyWith(color: skin.muted),
                    ),
                  ],
                ),
              ),
              _PeriodSelector(
                selectedDays: widget.selectedDays,
                onChanged: widget.onDaysChanged,
                skin: skin,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatBadge(
                label: 'Collected',
                value: _inrExact.format(widget.collectedTotal),
                color: AppColors.success,
              ),
              _StatBadge(
                label: 'Credit Due',
                value: _inrExact.format(widget.dueTotal),
                color: AppColors.warning,
              ),
              _StatBadge(
                label: 'GST Output',
                value: _inrExact.format(widget.gstTotal),
                color: skin.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (series.isEmpty)
            Container(
              height: 132,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: skin.canvas,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: skin.hairline),
              ),
              child: Text(
                'No sales recorded in the last ${widget.selectedDays} days.',
                style: AppTypography.caption.copyWith(color: skin.muted),
              ),
            )
          else
            SizedBox(
              height: 156,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final count = series.length;
                  final minSlotWidth = count > 14 ? 32.0 : 40.0;
                  final contentWidth =
                      (count * minSlotWidth).clamp(constraints.maxWidth, 2400.0);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: contentWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (int i = 0; i < count; i++)
                            Expanded(
                              child: _DayBarColumn(
                                row: series[i],
                                maxTotal: maxVal,
                                isSelected: i == activeIdx,
                                compactFormatter: _inrCompact,
                                skin: skin,
                                onTap: () => setState(() => _selectedIndex = i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (activeIdx != null && series.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SelectedDaySummary(
              row: series[activeIdx],
              exactFormatter: _inrExact,
              skin: skin,
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onChanged;
  final RippleSkin skin;

  const _PeriodSelector({
    required this.selectedDays,
    required this.onChanged,
    required this.skin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: skin.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [7, 14, 30].map((d) {
          final active = d == selectedDays;
          return Semantics(
            button: true,
            selected: active,
            label: '$d days chart window',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onChanged(d),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? skin.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${d}D',
                  style: AppTypography.caption.copyWith(
                    color: active ? Colors.white : skin.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBarColumn extends StatelessWidget {
  final Map<String, dynamic> row;
  final double maxTotal;
  final bool isSelected;
  final NumberFormat compactFormatter;
  final RippleSkin skin;
  final VoidCallback onTap;

  const _DayBarColumn({
    required this.row,
    required this.maxTotal,
    required this.isSelected,
    required this.compactFormatter,
    required this.skin,
    required this.onTap,
  });

  double _num(dynamic raw) => double.tryParse(raw?.toString() ?? '0') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final total = _num(row['total']);
    final collected = _num(row['collected']);
    final ratio = (total / maxTotal).clamp(0.04, 1.0);
    final collectedRatio =
        total > 0 ? (collected / total).clamp(0.0, 1.0) : 1.0;
    final label = (row['short_label'] ?? row['label'] ?? '').toString();

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${row['label'] ?? label}: ${compactFormatter.format(total)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isSelected && total > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    compactFormatter.format(total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: skin.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Container(
                width: isSelected ? 18 : 13,
                height: 100 * ratio,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: skin.ink, width: 1.5)
                      : null,
                ),
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: collectedRatio,
                  widthFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? skin.primary
                          : skin.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: isSelected ? skin.primary : skin.muted,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDaySummary extends StatelessWidget {
  final Map<String, dynamic> row;
  final NumberFormat exactFormatter;
  final RippleSkin skin;

  const _SelectedDaySummary({
    required this.row,
    required this.exactFormatter,
    required this.skin,
  });

  double _num(dynamic raw) => double.tryParse(raw?.toString() ?? '0') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final total = _num(row['total']);
    final collected = _num(row['collected']);
    final due = _num(row['due']);
    final gst = _num(row['gst']);
    final ordersCount = int.tryParse(row['orders_count']?.toString() ?? '0') ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: skin.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: skin.hairline),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${row['label'] ?? row['date'] ?? ''}',
            style: AppTypography.label.copyWith(
              color: skin.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Billed ${exactFormatter.format(total)}',
            style: AppTypography.caption.copyWith(
              color: skin.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Paid ${exactFormatter.format(collected)}',
            style: AppTypography.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (due > 0.01)
            Text(
              'Due ${exactFormatter.format(due)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(
            'GST ${exactFormatter.format(gst)} ($ordersCount bills)',
            style: AppTypography.caption.copyWith(color: skin.muted),
          ),
        ],
      ),
    );
  }
}

