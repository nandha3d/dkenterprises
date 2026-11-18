import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class FluidNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? tooltip;
  final bool isActionOnly;
  final VoidCallback? onActionTap;

  const FluidNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.tooltip,
    this.isActionOnly = false,
    this.onActionTap,
  });
}

/// Floating, theme-colored curved bottom navigation pill driven by the
/// Stitch "Ripple" role skin system.
///
/// Features:
/// - Floating rounded capsule with bottom/side clearance and smooth Bezier cutout notch.
/// - Responsive max-width centering on tablets/desktops so it never anchors wall-to-wall.
/// - Standardized 5-slot layout per role with integrated center (+) quick action.
/// - Theme-adaptive active circle badge, crisp labels, and reduced-motion support.
class FluidCurvedNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<FluidNavItem> items;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? activeIconColor;
  final Duration animationDuration;
  final Curve animationCurve;

  const FluidCurvedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.items,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.activeIconColor,
    this.animationDuration = const Duration(milliseconds: 340),
    this.animationCurve = Curves.easeInOutCubic,
  }) : assert(items.length >= 2, 'FluidCurvedNavBar requires at least 2 items');

  @override
  State<FluidCurvedNavBar> createState() => _FluidCurvedNavBarState();
}

class _FluidCurvedNavBarState extends State<FluidCurvedNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant FluidCurvedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final skinExt = theme.extension<RippleSkin>();
    final skin = skinExt ?? RippleSkin.forRole(RippleRole.admin, theme.brightness);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final defaultNavBg = skinExt != null
        ? (isDark
            ? Color.alphaBlend(skin.primary.withValues(alpha: 0.22), skin.navBackground)
            : skin.navBackground)
        : (isDark
            ? Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.22), colorScheme.surface)
            : colorScheme.primary);

    final navBg = widget.backgroundColor ?? defaultNavBg;
    final borderCol = isDark
        ? skin.primary.withValues(alpha: 0.34)
        : Colors.white.withValues(alpha: 0.24);
    final shadowCol = isDark
        ? Colors.black.withValues(alpha: 0.50)
        : Color.lerp(navBg, Colors.black, 0.45)!.withValues(alpha: 0.34);

    final activeCircleCol = widget.activeColor ??
        (skinExt != null
            ? skin.navActiveCircle
            : (isDark ? colorScheme.primary : Colors.white));
    final activeIconCol = widget.activeIconColor ??
        (widget.activeColor != null
            ? (ThemeData.estimateBrightnessForColor(activeCircleCol) == Brightness.dark
                ? Colors.white
                : skin.ink)
            : (skinExt != null
                ? skin.navActiveIcon
                : (isDark ? colorScheme.onPrimary : colorScheme.primary)));
    final inactiveCol = widget.inactiveColor ??
        (skinExt != null
            ? skin.navInactiveIcon
            : (isDark
                ? colorScheme.onSurface.withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.80)));
    final activeLabelCol = isDark ? skin.ink : Colors.white;

    const barHeight = 56.0;
    const topOverhang = 24.0;
    const bottomFloat = 10.0;
    const totalOuterHeight = barHeight + topOverhang + bottomFloat; // 90.0px invariant
    const innerStackHeight = barHeight + topOverhang; // 80.0px
    const notchRadius = 35.0;
    const notchDepth = 24.0;
    const circleRadius = 21.0;
    const cornerRadius = 22.0;

    final safeSelected = widget.currentIndex.clamp(0, widget.items.length - 1);

    return SizedBox(
      width: double.infinity,
      height: totalOuterHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, bottomFloat),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final itemCount = widget.items.length;
                final slotWidth = totalWidth / itemCount;

                double getSlotCenter(int index) => (index * slotWidth) + (slotWidth / 2);

                return AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final prevSafe = _previousIndex.clamp(0, itemCount - 1);
                    final animValue = reduceMotion ? 1.0 : _animation.value;
                    final prevX = getSlotCenter(prevSafe);
                    final targetX = getSlotCenter(safeSelected);
                    final activeX = prevX + (targetX - prevX) * animValue;

                    return SizedBox(
                      height: innerStackHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            key: const Key('fluid_floating_nav_pill'),
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: barHeight,
                            child: CustomPaint(
                              key: const Key('fluid_nav_custom_paint'),
                              size: Size(totalWidth, barHeight),
                              painter: _FluidNavBarPainter(
                                activeX: activeX,
                                backgroundColor: navBg,
                                borderColor: borderCol,
                                shadowColor: shadowCol,
                                notchRadius: notchRadius,
                                notchDepth: notchDepth,
                                cornerRadius: cornerRadius,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: barHeight,
                            child: Row(
                              children: List.generate(itemCount, (index) {
                                final item = widget.items[index];
                                final isSelected = !item.isActionOnly && index == safeSelected;

                                if (item.isActionOnly) {
                                  return Expanded(
                                    child: Semantics(
                                      button: true,
                                      label: item.tooltip ?? item.label,
                                      child: Tooltip(
                                        message: item.tooltip ?? item.label,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(18),
                                          onTap: () {
                                            HapticFeedback.mediumImpact();
                                            item.onActionTap?.call();
                                          },
                                          splashColor: Colors.white.withValues(alpha: 0.18),
                                          highlightColor: Colors.transparent,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                width: 31,
                                                height: 31,
                                                decoration: BoxDecoration(
                                                  color: skin.action,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: skin.action.withValues(alpha: 0.35),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  item.icon,
                                                  size: 20,
                                                  color: skin.actionInk,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 5, left: 2, right: 2),
                                                child: Text(
                                                  item.label,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    height: 1.15,
                                                    fontWeight: FontWeight.w700,
                                                    color: activeLabelCol,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return Expanded(
                                  child: Tooltip(
                                    message: item.tooltip ?? item.label,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        if (index != safeSelected) {
                                          HapticFeedback.lightImpact();
                                          widget.onTabSelected(index);
                                        }
                                      },
                                      splashColor: Colors.white.withValues(alpha: 0.18),
                                      highlightColor: Colors.transparent,
                                      child: Semantics(
                                        button: true,
                                        selected: isSelected,
                                        label: item.label,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            AnimatedOpacity(
                                              duration: reduceMotion
                                                  ? Duration.zero
                                                  : const Duration(milliseconds: 180),
                                              opacity: isSelected ? 0.0 : 1.0,
                                              child: Icon(
                                                item.icon,
                                                size: 20,
                                                color: inactiveCol,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
                                              child: Text(
                                                item.label,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  height: 1.15,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                  color: isSelected ? activeLabelCol : inactiveCol,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          Positioned(
                            left: activeX - circleRadius,
                            bottom: barHeight - circleRadius - 1.0,
                            width: circleRadius * 2,
                            height: circleRadius * 2,
                            child: IgnorePointer(
                              child: Container(
                                key: const Key('fluid_active_circle_badge'),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: activeCircleCol,
                                  border: Border.all(
                                    color: isDark
                                        ? skin.primary.withValues(alpha: 0.35)
                                        : Colors.white.withValues(alpha: 0.65),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: shadowCol,
                                      blurRadius: 10,
                                      spreadRadius: 0.5,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 220),
                                    transitionBuilder: (child, anim) => ScaleTransition(
                                      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                                      child: child,
                                    ),
                                    child: Icon(
                                      widget.items[safeSelected].activeIcon ??
                                          widget.items[safeSelected].icon,
                                      key: ValueKey<int>(safeSelected),
                                      size: 21,
                                      color: activeIconCol,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FluidNavBarPainter extends CustomPainter {
  final double activeX;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final double notchRadius;
  final double notchDepth;
  final double cornerRadius;

  _FluidNavBarPainter({
    required this.activeX,
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
    required this.notchRadius,
    required this.notchDepth,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;

    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final clampedActiveX = activeX.clamp(r + 4.0, w - r - 4.0);
    final notchStart = (clampedActiveX - notchRadius).clamp(r, clampedActiveX);
    final notchEnd = (clampedActiveX + notchRadius).clamp(clampedActiveX, w - r);
    final leftSpan = clampedActiveX - notchStart;
    final rightSpan = notchEnd - clampedActiveX;

    final cp1x = clampedActiveX - leftSpan * 0.52;
    final cp2x = clampedActiveX - leftSpan * 0.48;
    final cp3x = clampedActiveX + rightSpan * 0.48;
    final cp4x = clampedActiveX + rightSpan * 0.52;

    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(notchStart, 0)
      ..cubicTo(cp1x, 0, cp2x, notchDepth, clampedActiveX, notchDepth)
      ..cubicTo(cp3x, notchDepth, cp4x, 0, notchEnd, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..close();

    canvas.drawShadow(path, shadowColor, 14.0, true);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _FluidNavBarPainter oldDelegate) {
    return oldDelegate.activeX != activeX ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}
