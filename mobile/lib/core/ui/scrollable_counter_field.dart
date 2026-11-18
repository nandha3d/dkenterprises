import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Supported water container / unit sizes (replaces hardcoded 20L assumptions).
const List<String> kWaterContainerSizes = [
  '20L Can',
  '10L Can',
  '5L Can',
  '2L Box',
  '1L Box',
  '500ml Box',
  '300ml Box',
  'Custom',
];

/// Chip bar + custom input allowing the user to pick any water can/jar/bottle size.
class WaterContainerSizeSelector extends StatefulWidget {
  final String selectedSize;
  final ValueChanged<String> onChanged;
  final String label;

  const WaterContainerSizeSelector({
    super.key,
    required this.selectedSize,
    required this.onChanged,
    this.label = 'Container / Can Size',
  });

  @override
  State<WaterContainerSizeSelector> createState() =>
      _WaterContainerSizeSelectorState();
}

class _WaterContainerSizeSelectorState
    extends State<WaterContainerSizeSelector> {
  final _customCtrl = TextEditingController();
  bool _customMode = false;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant WaterContainerSizeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSize != widget.selectedSize) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    final current = widget.selectedSize.trim();
    final isPreset =
        kWaterContainerSizes.where((s) => s != 'Custom').contains(current);
    _customMode = !isPreset && current.isNotEmpty && current != 'Custom';
    if (_customMode && _customCtrl.text != current) {
      _customCtrl.text = current;
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final selectedPreset = _customMode ? 'Custom' : widget.selectedSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_drink_rounded, size: 16, color: skin.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.label,
                style: AppTypography.label.copyWith(
                  color: skin.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: skin.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.selectedSize,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: skin.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: kWaterContainerSizes.map((size) {
            final isSelected = size == selectedPreset;
            return ChoiceChip(
              selected: isSelected,
              label: Text(
                size,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onSelected: (_) {
                if (size == 'Custom') {
                  setState(() => _customMode = true);
                  final text = _customCtrl.text.trim();
                  widget.onChanged(text.isNotEmpty ? text : 'Custom Size');
                } else {
                  setState(() => _customMode = false);
                  widget.onChanged(size);
                }
              },
            );
          }).toList(),
        ),
        if (_customMode) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _customCtrl,
            decoration: const InputDecoration(
              labelText: 'Custom Size (e.g. 15L Jar, 250ml Pack)',
              isDense: true,
              prefixIcon: Icon(Icons.edit_rounded, size: 18),
            ),
            onChanged: (v) {
              final cleaned = v.trim();
              if (cleaned.isNotEmpty) {
                widget.onChanged(cleaned);
              }
            },
          ),
        ],
      ],
    );
  }
}

/// Interactive vertical drum wheel that is both smoothly scrollable (touch/mouse)
/// and tap-to-type via an instant numeric input dialog.
class ScrollableWheelNumber extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final double width;
  final double height;
  final double itemExtent;
  final TextStyle? textStyle;
  final String unitLabel;

  const ScrollableWheelNumber({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999,
    this.width = 76,
    this.height = 56,
    this.itemExtent = 28,
    this.textStyle,
    this.unitLabel = 'Count',
  });

  @override
  State<ScrollableWheelNumber> createState() => _ScrollableWheelNumberState();
}

class _ScrollableWheelNumberState extends State<ScrollableWheelNumber> {
  late FixedExtentScrollController _wheelCtrl;
  bool _syncingController = false;

  int get _clampedValue => widget.value.clamp(widget.min, widget.max);
  int get _itemCount => (widget.max - widget.min + 1).clamp(1, 10000);

  @override
  void initState() {
    super.initState();
    _wheelCtrl = FixedExtentScrollController(
      initialItem: _clampedValue - widget.min,
    );
  }

  @override
  void didUpdateWidget(covariant ScrollableWheelNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = _clampedValue - widget.min;
    if (_wheelCtrl.hasClients && _wheelCtrl.selectedItem != targetIndex) {
      _syncingController = true;
      _wheelCtrl.jumpToItem(targetIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncingController = false;
      });
    }
  }

  @override
  void dispose() {
    _wheelCtrl.dispose();
    super.dispose();
  }

  Future<void> _openTypeDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => _TypeOrScrollNumberDialog(
        title: widget.unitLabel,
        initialValue: _clampedValue,
        min: widget.min,
        max: widget.max,
      ),
    );
    if (result != null && result != widget.value) {
      widget.onChanged(result.clamp(widget.min, widget.max));
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeStyle = widget.textStyle ??
        AppTypography.title.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: skin.primary,
        );

    return Tooltip(
      message: 'Drag/scroll wheel or tap to type',
      child: InkWell(
        onTap: _openTypeDialog,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : skin.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: skin.primary.withValues(alpha: 0.25)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Highlighted center slot band
              Container(
                height: widget.itemExtent,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: skin.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: ListWheelScrollView.useDelegate(
                  controller: _wheelCtrl,
                  itemExtent: widget.itemExtent,
                  perspective: 0.004,
                  diameterRatio: 1.4,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (idx) {
                    if (_syncingController) return;
                    final nextVal = widget.min + idx;
                    if (nextVal != widget.value) {
                      widget.onChanged(nextVal);
                    }
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _itemCount,
                    builder: (context, idx) {
                      final numVal = widget.min + idx;
                      final isCenter = numVal == _clampedValue;
                      return Center(
                        child: Text(
                          '$numVal',
                          style: isCenter
                              ? activeStyle
                              : activeStyle.copyWith(
                                  fontSize: (activeStyle.fontSize ?? 18) * 0.68,
                                  fontWeight: FontWeight.w600,
                                  color: skin.muted.withValues(alpha: 0.55),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 3,
                bottom: 2,
                child: Icon(
                  Icons.edit_rounded,
                  size: 10,
                  color: skin.primary.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact labeled row with `-`, a scrollable + tap-to-type drum wheel, and `+`.
class ScrollableCounterRow extends StatefulWidget {
  final String title;
  final String? subtitle;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final Color? titleColor;

  const ScrollableCounterRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999,
    this.titleColor,
  });

  @override
  State<ScrollableCounterRow> createState() => _ScrollableCounterRowState();
}

class _ScrollableCounterRowState extends State<ScrollableCounterRow> {
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant ScrollableCounterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  void _updateValue(int next) {
    final clamped = next.clamp(widget.min, widget.max);
    _currentValue = clamped;
    widget.onChanged(clamped);
  }

  void _decrement() => _updateValue(_currentValue - 1);

  void _increment() => _updateValue(_currentValue + 1);

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: AppTypography.body.copyWith(
                  color: widget.titleColor ?? skin.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle!,
                  style: AppTypography.caption.copyWith(
                    color: skin.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              onPressed: _currentValue > widget.min ? _decrement : null,
              icon: const Icon(Icons.remove_rounded, size: 18),
            ),
            const SizedBox(width: 6),
            ScrollableWheelNumber(
              value: widget.value,
              onChanged: _updateValue,
              min: widget.min,
              max: widget.max,
              width: 70,
              height: 58,
              itemExtent: 26,
              unitLabel: widget.title,
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              onPressed: _currentValue < widget.max ? _increment : null,
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

/// Hero counter control with `-`, large scrollable drum wheel, direct tap-to-type,
/// and `+` button for order/delivery screens.
class ScrollableHeroCounter extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String unitLabel;
  final List<int> quickPresets;

  const ScrollableHeroCounter({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999,
    this.unitLabel = 'Quantity',
    this.quickPresets = const [],
  });

  @override
  State<ScrollableHeroCounter> createState() => _ScrollableHeroCounterState();
}

class _ScrollableHeroCounterState extends State<ScrollableHeroCounter> {
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant ScrollableHeroCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  void _updateValue(int next) {
    final clamped = next.clamp(widget.min, widget.max);
    _currentValue = clamped;
    widget.onChanged(clamped);
  }

  void _decrement() => _updateValue(_currentValue - 1);

  void _increment() => _updateValue(_currentValue + 1);

  @override
  Widget build(BuildContext context) {
    final skin = RippleSkin.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
              onPressed: _currentValue > widget.min ? _decrement : null,
              icon: const Icon(Icons.remove_rounded, size: 24),
            ),
            const SizedBox(width: 16),
            ScrollableWheelNumber(
              value: widget.value,
              onChanged: _updateValue,
              min: widget.min,
              max: widget.max,
              width: 108,
              height: 82,
              itemExtent: 34,
              unitLabel: widget.unitLabel,
              textStyle: AppTypography.display.copyWith(
                color: activeColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 16),
            IconButton.filled(
              style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
              onPressed: _currentValue < widget.max ? _increment : null,
              icon: const Icon(Icons.add_rounded, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Scroll wheel up/down or tap number to type',
          style: TextStyle(
            fontSize: 11,
            color: skin.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.quickPresets.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: widget.quickPresets.map((n) {
              return ChoiceChip(
                selected: widget.value == n,
                label: Text('$n Cans'),
                onSelected: (_) => _updateValue(n),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _TypeOrScrollNumberDialog extends StatefulWidget {
  final String title;
  final int initialValue;
  final int min;
  final int max;

  const _TypeOrScrollNumberDialog({
    required this.title,
    required this.initialValue,
    required this.min,
    required this.max,
  });

  @override
  State<_TypeOrScrollNumberDialog> createState() =>
      _TypeOrScrollNumberDialogState();
}

class _TypeOrScrollNumberDialogState extends State<_TypeOrScrollNumberDialog> {
  late final TextEditingController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialValue.clamp(widget.min, widget.max);
    _ctrl = TextEditingController(text: '$_current');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setFromQuickAdd(int delta) {
    final next = (_current + delta).clamp(widget.min, widget.max);
    setState(() {
      _current = next;
      _ctrl.text = '$next';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Enter exact number (${widget.min}–${widget.max})',
              prefixIcon: const Icon(Icons.dialpad_rounded),
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null) {
                setState(() => _current = parsed.clamp(widget.min, widget.max));
              }
            },
            onSubmitted: (_) => Navigator.of(context).pop(_current),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final step in const [5, 10, 20, 50, 100])
                ActionChip(
                  label: Text('+$step'),
                  onPressed: () => _setFromQuickAdd(step),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: () {
            final parsed = int.tryParse(_ctrl.text.trim());
            final finalVal = (parsed ?? _current).clamp(widget.min, widget.max);
            Navigator.of(context).pop(finalVal);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

