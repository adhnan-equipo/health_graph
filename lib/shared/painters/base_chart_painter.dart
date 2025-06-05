import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../utils/chart_view_config.dart';
import '../models/base_chart_style.dart';

/// Base painter class that provides common chart painting functionality
/// All specific chart painters should extend this to reduce code duplication
abstract class BaseChartPainter<T, S extends BaseChartStyle>
    extends CustomPainter {
  final List<T> data;
  final S style;
  final ChartViewConfig config;
  final Animation<double> animation;
  final Rect chartArea;
  final double minValue;
  final double maxValue;

  BaseChartPainter({
    required this.data,
    required this.style,
    required this.config,
    required this.animation,
    required this.chartArea,
    required this.minValue,
    required this.maxValue,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      drawEmptyState(canvas, size);
      return;
    }

    paintChart(canvas, size);
  }

  /// Override this method to implement chart-specific painting logic
  void paintChart(Canvas canvas, Size size);

  /// Common empty state drawing implementation
  void drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = style.gridLineColor.withValues(alpha: 0.1 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw animated grid pattern
    const spacing = 20.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      final progress = (x / size.width * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * progress),
        paint,
      );
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      final progress = (y / size.height * animation.value).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * progress, y),
        paint,
      );
    }
  }

  /// Common Y position calculation
  double getYPosition(double value) {
    if (maxValue <= minValue) return chartArea.bottom;
    final normalizedValue = (value - minValue) / (maxValue - minValue);
    return chartArea.bottom -
        normalizedValue.clamp(0.0, 1.0) * chartArea.height;
  }

  /// Common X position calculation for data points
  double getXPosition(int index, int totalPoints, {double padding = 8.0}) {
    final availableWidth = chartArea.width - (padding * 2);
    if (totalPoints <= 1) {
      return chartArea.left + chartArea.width / 2;
    }

    final spacing = availableWidth / (totalPoints - 1);
    return chartArea.left + padding + (index * spacing);
  }

  /// Create smooth gradient for bars/areas
  ui.Gradient createVerticalGradient({
    required Color topColor,
    required Color bottomColor,
    required Rect rect,
  }) {
    return ui.Gradient.linear(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.bottom),
      [topColor, bottomColor],
    );
  }

  /// Calculate animation value for staggered animations
  double calculateStaggeredAnimation(
    int index,
    int totalItems, {
    double delayFactor = 2.0,
    double duration = 0.6,
  }) {
    final delay = index / (totalItems * delayFactor);

    if (animation.value < delay) return 0.0;
    if (animation.value > delay + duration) return 1.0;

    final t = ((animation.value - delay) / duration).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(t);
  }

  /// Draw a dashed line
  void drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 8.0,
    double dashSpace = 4.0,
  }) {
    var currentX = start.dx;
    while (currentX < end.dx) {
      final dashEnd = (currentX + dashWidth).clamp(start.dx, end.dx);
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(dashEnd, start.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  /// Animate a path for progressive drawing
  Path animatePath(Path originalPath, double animationValue) {
    final pathMetrics = originalPath.computeMetrics();
    final animatedPath = Path();

    for (final pathMetric in pathMetrics) {
      final extractedPath = pathMetric.extractPath(
        0.0,
        pathMetric.length * animationValue.clamp(0.0, 1.0),
      );
      animatedPath.addPath(extractedPath, Offset.zero);
    }

    return animatedPath;
  }

  /// Draw a text label with optional background
  void drawLabel(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle textStyle, {
    Color? backgroundColor,
    double borderRadius = 4.0,
    EdgeInsets padding = const EdgeInsets.all(4.0),
    TextAlign textAlign = TextAlign.center,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: textStyle.color?.withValues(alpha: animation.value),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );

    textPainter.layout();

    final textRect = Rect.fromLTWH(
      position.dx - textPainter.width / 2 - padding.left,
      position.dy - textPainter.height / 2 - padding.top,
      textPainter.width + padding.horizontal,
      textPainter.height + padding.vertical,
    );

    // Draw background if specified
    if (backgroundColor != null) {
      final backgroundPaint = Paint()
        ..color = backgroundColor.withValues(alpha: 0.9 * animation.value)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(textRect, Radius.circular(borderRadius)),
        backgroundPaint,
      );
    }

    // Draw text
    textPainter.paint(
      canvas,
      Offset(
        textRect.left + padding.left,
        textRect.top + padding.top,
      ),
    );
  }

  /// Common shouldRepaint implementation - override if you need additional checks
  @override
  bool shouldRepaint(covariant BaseChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        style != oldDelegate.style ||
        config != oldDelegate.config ||
        animation.value != oldDelegate.animation.value ||
        chartArea != oldDelegate.chartArea ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue;
  }
}
