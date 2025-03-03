import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_blood_pressure_data.dart';

class ChartCalculations {
  static (List<int>, double, double) calculateYAxisRange(
    List<ProcessedBloodPressureData> data,
    List<(int min, int max)> referenceRanges,
  ) {
    if (data.isEmpty && referenceRanges.isEmpty) {
      return _getDefaultRange();
    }

    // Collect all values
    final allValues = <int>[];

    // Add data points
    for (var point in data) {
      if (!point.isEmpty) {
        allValues.addAll([
          point.minSystolic,
          point.maxSystolic,
          point.minDiastolic,
          point.maxDiastolic,
        ]);
      }
    }

    // Add reference ranges
    for (var range in referenceRanges) {
      allValues.addAll([range.$1, range.$2]);
    }

    if (allValues.isEmpty) {
      return _getDefaultRange();
    }

    // Find actual min/max from data
    final minValue = allValues.reduce(min);
    final maxValue = allValues.reduce(max);

    // Calculate range with padding
    final range = maxValue - minValue;
    final topPadding = range * 0.15;
    final bottomPadding = range * 0.15;

    // Round to nearest 10 with extra space
    final adjustedMin = max(0, ((minValue - bottomPadding) / 10).floor() * 10);
    var adjustedMax = ((maxValue + topPadding) / 10).ceil() * 10;

    // Ensure maximum has enough padding
    adjustedMax = max(adjustedMax, maxValue + 20);

    // Calculate optimal step size
    final effectiveRange = adjustedMax - adjustedMin;
    var stepSize = (effectiveRange / 6).ceil();
    stepSize = _roundToNiceNumber(stepSize);

    // Generate axis values with better distribution
    final yAxisValues = _generateAxisValues(adjustedMin, adjustedMax, stepSize);

    return (yAxisValues, adjustedMin.toDouble(), adjustedMax.toDouble());
  }

  // Helper method for better step size calculation
  static int _roundToNiceNumber(int number) {
    if (number <= 5) return 5;
    if (number <= 10) return 10;
    if (number <= 20) return 20;
    if (number <= 25) return 25;
    if (number <= 50) return 50;
    return ((number + 99) ~/ 100) * 100;
  }

  static Rect calculateChartArea(Size size) {
    const leftPadding = 40.0; // Increased for better y-axis label visibility
    const rightPadding = 10.0;
    const topPadding = 10.0;
    const bottomPadding = 30.0; // Increased for better x-axis label visibility

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  static List<int> _generateAxisValues(int start, int end, int step) {
    final values = <int>[];
    var currentValue = start;

    while (currentValue <= end) {
      values.add(currentValue);
      currentValue += step;
    }

    // Ensure we have enough values for proper spacing
    if (values.length < 5) {
      final additionalStep = step ~/ 2;
      if (additionalStep > 0) {
        var additionalValue = start + additionalStep;

        while (additionalValue < end) {
          if (!values.contains(additionalValue)) {
            values.add(additionalValue);
          }
          additionalValue += step;
        }
        values.sort();
      }
    }

    return values;
  }

  static (List<int>, double, double) _getDefaultRange() {
    const defaultMin = 40; // Lower minimum for blood pressure
    const defaultMax = 180; // Common maximum for normal blood pressure display
    const step = 20;
    final values = _generateAxisValues(defaultMin, defaultMax, step);
    return (values, defaultMin.toDouble(), defaultMax.toDouble());
  }

  // Calculate X position based on index in data array
  static double calculateXPosition(
    int index,
    int totalPoints,
    Rect chartArea,
  ) {
    if (totalPoints <= 1) return chartArea.center.dx;

    final effectiveWidth = chartArea.width;
    const edgePadding = 15.0; // Increased for better visibility at edges
    final availableWidth = effectiveWidth - (edgePadding * 2);
    final pointSpacing = availableWidth / (totalPoints - 1);

    return chartArea.left + edgePadding + (index * pointSpacing);
  }

  /// Calculate tooltip position to ensure it stays within screen bounds
  static Offset calculateTooltipPosition(
    Offset tapPosition,
    Size tooltipSize,
    Size screenSize,
    EdgeInsets padding,
  ) {
    double x = tapPosition.dx - (tooltipSize.width / 2);
    double y = tapPosition.dy - tooltipSize.height - 10;

    // Ensure tooltip stays within horizontal bounds
    x = x.clamp(
      padding.left,
      screenSize.width - tooltipSize.width - padding.right,
    );

    // If tooltip would go above screen, show it below the tap point
    if (y < padding.top) {
      y = tapPosition.dy + 10;
    }

    // Ensure tooltip stays within vertical bounds
    y = y.clamp(
      padding.top,
      screenSize.height - tooltipSize.height - padding.bottom,
    );

    return Offset(x, y);
  }
}
