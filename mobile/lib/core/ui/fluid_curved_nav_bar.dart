import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class FluidNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? tooltip;

  const FluidNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.tooltip,
  });
}

/// A high-performance fluid curved bottom navigation bar inspired by Figma's
/// Smart Animate liquid notch navigation pattern.
///
/// Features:
/// - Smooth cubic Bezier scooped notch that glides across tabs.
/// - Elevated floating circular active indicator with glowing drop shadow.
/// - Spring-animated icon scaling inside the active circle.
/// - Fully responsive geometry on phone and tablet/desktop.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-derived palette: In light theme, the bar is vibrant enterprise blue!
    final navBg = widget.backgroundColor ??
        (isDark ? AppColors.darkCard : const Color(0xFF0284C7));
    final borderCol = isDark
        ? AppColors.darkBorder
        : const Color(0xFF38BDF8).withOpacity(0.35);

    // Active circle and icon colors:
    // In light theme with a blue bar, the active circle is crisp pure white,
    // and the icon inside it is drawn in the company / brand theme color!
    final activeCircleCol = isDark
        ? (widget.activeColor ?? AppColors.primaryDark)
        : Colors.white;

    final activeIconCol = widget.activeIconColor ??
        (isDark
            ? const Color(0xFF0B0F17)
            : (widget.activeColor ?? const Color(0xFF0284C7)));

    final inactiveCol = widget.inactiveColor ??
        (isDark ? AppColors.darkTextSecondary : Colors.white.withOpacity(0.85));

    const barHeight = 64.0;
    const notchRadius = 42.0; // Half-width of notch
    const notchDepth = 26.0;  // Depth of concave dip
    const circleRadius = 25.0; // Diameter 50.0
    const cornerRadius = 24.0;
    const totalBarHeight = barHeight + 14.0 + 12.0; // 64 + 14 + 12 = 90.0

    return SizedBox(
      height: totalBarHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final itemCount = widget.items.length;
                final slotWidth = totalWidth / itemCount;

                // Calculate horizontal centers for each slot
                double getSlotCenter(int index) {
                  return (index * slotWidth) + (slotWidth / 2);
                }

                return AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final prevX = getSlotCenter(_previousIndex.clamp(0, itemCount - 1));
                    final targetX = getSlotCenter(widget.currentIndex.clamp(0, itemCount - 1));
                    // Interpolated X coordinate of active notch and circle
                    final activeX = prevX + (targetX - prevX) * _animation.value;

                    return SizedBox(
                      height: barHeight + 14.0, // extra 14px for elevated circle
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          // 1. Fluid Scoop Notch Canvas Painter
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: barHeight,
                            child: CustomPaint(
                              size: Size(totalWidth, barHeight),
                              painter: _FluidNavBarPainter(
                                activeX: activeX,
                                backgroundColor: navBg,
                                borderColor: borderCol,
                                notchRadius: notchRadius,
                                notchDepth: notchDepth,
                                cornerRadius: cornerRadius,
                                isDark: isDark,
                              ),
                            ),
                          ),

                          // 2. Inactive Tab Icons
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: barHeight,
                            child: Row(
                              children: List.generate(itemCount, (index) {
                                final item = widget.items[index];
                                final isSelected = index == widget.currentIndex;

                                return Expanded(
                                  child: Tooltip(
                                    message: item.tooltip ?? item.label,
                                    child: InkWell(
                                      onTap: () {
                                        if (index != widget.currentIndex) {
                                          HapticFeedback.lightImpact();
                                          widget.onTabSelected(index);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(cornerRadius),
                                      splashColor: isDark ? activeCircleCol.withOpacity(0.12) : Colors.white.withOpacity(0.22),
                                      highlightColor: Colors.transparent,
                                      child: Center(
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 200),
                                          opacity: isSelected ? 0.0 : 1.0,
                                          child: Semantics(
                                            button: true,
                                            label: item.label,
                                            child: Icon(
                                              item.icon,
                                              size: 23,
                                              color: inactiveCol,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          // 3. Elevated Floating Circular Active Indicator
                          Positioned(
                            left: activeX - circleRadius,
                            bottom: barHeight - circleRadius - 4.0, // Elevated ~14px above navbar
                            width: circleRadius * 2,
                            height: circleRadius * 2,
                            child: Tooltip(
                              message: widget.items[widget.currentIndex].tooltip ??
                                  widget.items[widget.currentIndex].label,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: activeCircleCol,
                                  boxShadow: isDark
                                      ? [
                                          BoxShadow(
                                            color: activeCircleCol.withOpacity(0.45),
                                            blurRadius: 14,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 4),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.16),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 4),
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFF0284C7).withOpacity(0.28),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 240),
                                    transitionBuilder: (child, anim) {
                                      return ScaleTransition(
                                        scale: CurvedAnimation(
                                          parent: anim,
                                          curve: Curves.easeOutBack,
                                        ),
                                        child: child,
                                      );
                                    },
                                    child: Icon(
                                      widget.items[widget.currentIndex].activeIcon ??
                                          widget.items[widget.currentIndex].icon,
                                      key: ValueKey<int>(widget.currentIndex),
                                      size: 24,
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

/// Custom painter that draws the curved fluid notch matching Figma Smart Animate geometry.
class _FluidNavBarPainter extends CustomPainter {
  final double activeX;
  final Color backgroundColor;
  final Color borderColor;
  final double notchRadius;
  final double notchDepth;
  final double cornerRadius;
  final bool isDark;

  _FluidNavBarPainter({
    required this.activeX,
    required this.backgroundColor,
    required this.borderColor,
    required this.notchRadius,
    required this.notchDepth,
    required this.cornerRadius,
    required this.isDark,
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
      ..strokeWidth = 1.2;

    // Notch horizontal boundaries
    final notchStart = (activeX - notchRadius).clamp(r, w - r);
    final notchEnd = (activeX + notchRadius).clamp(r, w - r);

    // Control points for smooth horizontal cubic Bezier scoop
    final cp1x = activeX - notchRadius * 0.52;
    final cp2x = activeX - notchRadius * 0.48;
    final cp3x = activeX + notchRadius * 0.48;
    final cp4x = activeX + notchRadius * 0.52;

    // 1. Fluid Outline Path
    final path = Path();
    // Top-left corner
    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);

    // Left flat edge to notch
    path.lineTo(notchStart, 0);

    // Downward scoop
    path.cubicTo(cp1x, 0, cp2x, notchDepth, activeX, notchDepth);
    // Upward scoop
    path.cubicTo(cp3x, notchDepth, cp4x, 0, notchEnd, 0);

    // Right flat edge
    path.lineTo(w - r, 0);
    // Top-right corner
    path.quadraticBezierTo(w, 0, w, r);

    // Bottom-right corner
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);

    // Bottom edge
    path.lineTo(r, h);
    // Bottom-left corner
    path.quadraticBezierTo(0, h, 0, h - r);

    path.close();

    // 2. Ambient drop shadow for floating container
    canvas.drawShadow(
      path,
      isDark
          ? Colors.black.withOpacity(0.35)
          : const Color(0xFF0284C7).withOpacity(0.35),
      12.0,
      true,
    );

    // 3. Draw Fill
    canvas.drawPath(path, fillPaint);

    // 4. Draw Border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _FluidNavBarPainter oldDelegate) {
    return oldDelegate.activeX != activeX ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor;
  }
}
