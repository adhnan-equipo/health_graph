// lib/bmi/drawer/chart_grid_drawer.dart - MODIFIED

import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/bmi_chart_calculations.dart'; // Add this import

class ChartGridDrawer {
  void drawGrid(
    Canvas canvas,
    Rect chartArea,
    List<double> yAxisValues, // Changed from List<int> to List<double>
    double minValue,
    double maxValue,
    double animationValue,
  ) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15 * animationValue)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Use the same calculation method as the label drawer for consistency
    for (var value in yAxisValues) {
      // Use the shared calculation method from BMIChartCalculations
      final y = BMIChartCalculations.calculateYPosition(
          value, chartArea, yAxisValues.first, yAxisValues.last);

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
    // Increase edge padding for better visibility of first and last points
    const edgePadding = 15.0; // Consistent padding value
    final availableWidth = chartArea.width - (edgePadding * 2);

    // Handle single point case
    if (totalPoints <= 1) {
      return chartArea.center.dx;
    }

    final pointSpacing = availableWidth / (totalPoints - 1);
    return chartArea.left + edgePadding + (index * pointSpacing);
  }

  // This method is deprecated - use BMIChartCalculations.calculateYPosition instead
  @Deprecated(
      'Use BMIChartCalculations.calculateYPosition for consistent positioning')
  double _getYPosition(
      double value, Rect chartArea, double minValue, double maxValue) {
    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
