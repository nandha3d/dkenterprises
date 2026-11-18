import 'package:flutter/material.dart';

/// Material 3 window size classes (`adaptive-layout` skill).
///
/// Computed strictly from [MediaQuery.sizeOf] or [LayoutBuilder] constraints —
/// never from `Platform.is*` or `MediaQuery.of`.
enum WindowSizeClass {
  compact, // < 600 (phone portrait)
  medium, // 600 .. < 840 (tablet portrait, unfolded inner display)
  expanded, // 840 .. < 1200 (tablet landscape, small desktop)
  large; // >= 1200 (desktop, ultra-wide)

  static WindowSizeClass fromWidth(double width) => switch (width) {
        < 600 => compact,
        < 840 => medium,
        < 1200 => expanded,
        _ => large,
      };

  static WindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == compact;
  bool get isTabletOrLarger => this != compact;
  bool get isExpandedOrLarger => this == expanded || this == large;
}

/// Constrains scrollable dashboard and form content on tablet/desktop viewports
/// so cards align cleanly without stretching edge-to-edge on wide screens.
class AdaptivePageConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const AdaptivePageConstraint({
    super.key,
    required this.child,
    this.maxWidth = 1600,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

