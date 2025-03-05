import 'dart:ui';

import 'package:flutter/material.dart';

class ChartGridDrawer {
  void drawGrid(
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
      final y = _getYPosition(value.toDouble(), chartArea, minValue, maxValue);

      final start = Offset(chartArea.left, y);
      final end = Offset(
        lerpDouble(chartArea.left, chartArea.right, animationValue)!,
        y,
      );

      canvas.drawLine(start, end, paint);
    }
  }

  double _getYPosition(
      double value, Rect chartArea, double minValue, double maxValue) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
