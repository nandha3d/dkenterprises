import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight, 60fps/120fps native Flutter sparkline chart with smooth cubic bezier curve,
/// gradient area fill, and glowing current-value pin.
class SparklineChart extends StatelessWidget {
  final List<num> data;
  final Color lineColor;
  final double height;
  final double? width;
  final bool showEndDot;
  final bool fillGradient;

  const SparklineChart({
    super.key,
    required this.data,
    required this.lineColor,
    this.height = 36,
    this.width,
    this.showEndDot = true,
    this.fillGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        width: width,
        child: Center(
          child: Container(
            height: 2,
            color: lineColor.withOpacity(0.2),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: width,
      child: CustomPaint(
        painter: _SparklinePainter(
          points: data.map((e) => e.toDouble()).toList(),
          lineColor: lineColor,
          showEndDot: showEndDot,
          fillGradient: fillGradient,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final bool showEndDot;
  final bool fillGradient;

  _SparklinePainter({
    required this.points,
    required this.lineColor,
    required this.showEndDot,
    required this.fillGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      final center = Offset(size.width / 2, size.height / 2);
      final paint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 3, paint);
      return;
    }

    double minY = points.reduce(math.min);
    double maxY = points.reduce(math.max);
    if ((maxY - minY).abs() < 0.001) {
      // Flat line when all points are identical
      minY -= 1.0;
      maxY += 1.0;
    }

    final double rangeY = maxY - minY;
    final double stepX = size.width / (points.length - 1);
    const double paddingV = 4.0;
    final double usableHeight = math.max(0.0, size.height - (paddingV * 2));

    final List<Offset> computedOffsets = [];
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (points[i] - minY) / rangeY;
      final y = (size.height - paddingV) - (normalized * usableHeight);
      computedOffsets.add(Offset(x, y));
    }

    // Build smooth cubic bezier curve
    final path = Path();
    path.moveTo(computedOffsets.first.dx, computedOffsets.first.dy);

    for (int i = 0; i < computedOffsets.length - 1; i++) {
      final p0 = computedOffsets[i];
      final p1 = computedOffsets[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 1. Fill gradient under the curve
    if (fillGradient) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withOpacity(0.28),
            lineColor.withOpacity(0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // 2. Stroke line
    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // 3. Highlight final data point with glowing pin
    if (showEndDot && computedOffsets.isNotEmpty) {
      final lastPoint = computedOffsets.last;

      final glowPaint = Paint()
        ..color = lineColor.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 6, glowPaint);

      final dotPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 3.5, dotPaint);

      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 1.5, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    if (oldDelegate.points.length != points.length ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.showEndDot != showEndDot) {
      return true;
    }
    for (int i = 0; i < points.length; i++) {
      if (oldDelegate.points[i] != points[i]) return true;
    }
    return false;
  }
}
