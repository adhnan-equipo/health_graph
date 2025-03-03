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
      ..color = Colors.grey.withOpacity(0.15 * animationValue)
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

// Additional changes to chart_grid_drawer.dart
  static double calculateXPosition(
    int index,
    int totalPoints,
    Rect chartArea,
  ) {
    // Add proper edge padding
    const edgePadding = 12.0;
    final availableWidth = chartArea.width - (edgePadding * 2);

    // Handle single point case
    if (totalPoints <= 1) {
      return chartArea.center.dx;
    }

    final pointSpacing = availableWidth / (totalPoints - 1);
    return chartArea.left + edgePadding + (index * pointSpacing);
  }

  double _getYPosition(
      double value, Rect chartArea, double minValue, double maxValue) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
