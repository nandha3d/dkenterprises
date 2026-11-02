import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool isInteractive;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 18.0,
    this.blurSigma = 16.0,
    this.tintColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.isInteractive = false,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    // Glass frosted gradient fill
    final defaultBg = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (widget.tintColor ?? Colors.white).withOpacity(widget.tintColor != null ? 0.12 : 0.08),
              (widget.tintColor ?? Colors.white).withOpacity(widget.tintColor != null ? 0.04 : 0.02),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (widget.tintColor ?? Colors.white).withOpacity(widget.tintColor != null ? 0.15 : 0.90),
              (widget.tintColor ?? const Color(0xFFF8FAFC)).withOpacity(widget.tintColor != null ? 0.08 : 0.75),
            ],
          );

    final edgeBorder = widget.borderColor ??
        (isDark
            ? Colors.white.withOpacity(0.14)
            : const Color(0xFF0F172A).withOpacity(0.08));

    Widget content = Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: defaultBg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: edgeBorder,
          width: widget.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.35) : const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (widget.tintColor != null)
            BoxShadow(
              color: widget.tintColor!.withOpacity(isDark ? 0.15 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: widget.child,
    );

    // Apply BackdropFilter blur
    content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
        child: content,
      ),
    );

    if (widget.margin != null) {
      content = Padding(padding: widget.margin!, child: content);
    }

    if (widget.onTap != null || widget.isInteractive) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: content,
        ),
      );
    }

    return content;
  }
}
