import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/chart_calculations.dart';

/// Shared chart grid drawer for all health metric charts
/// Provides consistent grid line drawing with animation support
class ChartGridDrawer {
  /// Draws horizontal grid lines for numeric values (double)
  void drawNumericGrid(
    Canvas canvas,
    Rect chartArea,
    List<double> yAxisValues,
    double minValue,
    double maxValue,
    double animationValue,
  ) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15 * animationValue)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (var value in yAxisValues) {
      final y = SharedChartCalculations.calculateYPosition(
          value, chartArea, minValue, maxValue);

      final start = Offset(chartArea.left, y);
      final end = Offset(
        lerpDouble(chartArea.left, chartArea.right, animationValue)!,
        y,
      );

      canvas.drawLine(start, end, paint);
    }
  }

  /// Draws horizontal grid lines for integer values
  void drawIntegerGrid(
    Canvas canvas,
    Rect chartArea,
    List<int> yAxisValues,
    double minValue,
    double maxValue,
    double animationValue,
  ) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15 * animationValue)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (var value in yAxisValues) {
      final y = SharedChartCalculations.calculateYPosition(
          value.toDouble(), chartArea, minValue, maxValue);

      final start = Offset(chartArea.left, y);
      final end = Offset(
        lerpDouble(chartArea.left, chartArea.right, animationValue)!,
        y,
      );

      canvas.drawLine(start, end, paint);
    }
  }
}
