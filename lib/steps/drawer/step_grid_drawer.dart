// lib/steps/drawer/step_grid_drawer.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/step_chart_calculations.dart';

class StepGridDrawer {
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

    // Draw horizontal grid lines
    for (var value in yAxisValues) {
      final y = StepChartCalculations.calculateYPosition(
          value.toDouble(), chartArea, minValue, maxValue);

      final start = Offset(chartArea.left, y);
      final end = Offset(
        lerpDouble(chartArea.left, chartArea.right, animationValue)!,
        y,
      );

      canvas.drawLine(start, end, paint);
    }
  }

  static double calculateXPosition(
    int index,
    int totalPoints,
    Rect chartArea,
  ) {
    const edgePadding = 15.0;
    final availableWidth = chartArea.width - (edgePadding * 2);

    if (totalPoints <= 1) {
      return chartArea.center.dx;
    }

    final pointSpacing = availableWidth / (totalPoints - 1);
    return chartArea.left + edgePadding + (index * pointSpacing);
  }
}
