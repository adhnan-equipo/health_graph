// lib/steps/services/step_chart_calculations.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_step_data.dart';
import '../models/step_range.dart';

class StepChartCalculations {
  static const double _minPaddingPercent = 0.05;
  static const double _maxPaddingPercent = 0.15;
  static const double _hitTestThreshold = 20.0;

  static (List<int>, double, double) calculateYAxisRange(
    List<ProcessedStepData> data,
    List<(int min, int max)> referenceRanges,
  ) {
    if (data.isEmpty && referenceRanges.isEmpty) {
      return _getDefaultRange();
    }

    // Focus on actual step values from the data
    final actualValues = <int>[];

    // Extract step values from each non-empty section
    for (var point in data.where((d) => !d.isEmpty)) {
      if (point.originalMeasurements.isNotEmpty) {
        // Use latest recorded measurement for current trend
        actualValues.add(point.originalMeasurements.last.step);
      } else {
        actualValues.add(point.avgSteps.round());
      }
    }

    // Add step category reference ranges if no custom ranges provided
    if (referenceRanges.isEmpty) {
      // Key step thresholds for reference lines
      actualValues.addAll([
        StepRange.minimumHealthBenefit,
        StepRange.recommendedDaily,
        StepRange.fairlyActiveMin,
        StepRange.highlyActiveMin,
      ]);
    } else {
      // Add custom reference ranges
      for (var range in referenceRanges) {
        actualValues.addAll([range.$1, range.$2]);
      }
    }

    // Filter out invalid values
    final validValues = actualValues.where((v) => v >= 0).toList();

    if (validValues.isEmpty) {
      return _getDefaultRange();
    }

    // Calculate min/max from actual data
    var minValue = validValues.reduce(min);
    var maxValue = validValues.reduce(max);

    // Calculate range with padding
    final range = maxValue - minValue;
    final topPadding = (range * 0.2).round(); // 20% padding for better view
    final bottomPadding = (range * 0.1).round(); // 10% bottom padding

    // Ensure minimum value of 0 (never go negative)
    minValue = max(0, minValue - bottomPadding);

    // Ensure maximum covers highly active range
    maxValue = max(maxValue + topPadding, StepRange.highlyActiveMin + 2500);

    // Maintain a reasonable range for better visualization
    if (maxValue - minValue < 2000) {
      maxValue = minValue + 2000;
    }

    // Calculate optimal step size for max 6 labels
    final stepSize = _calculateOptimalStepSize(minValue, maxValue);

    // Generate axis values with better distribution
    final yAxisValues = _generateAxisValues(minValue, maxValue, stepSize);

    return (yAxisValues, minValue.toDouble(), maxValue.toDouble());
  }

  static double calculateYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    // Safety check for invalid values
    if (value.isNaN ||
        !value.isFinite ||
        minValue.isNaN ||
        !minValue.isFinite ||
        maxValue.isNaN ||
        !maxValue.isFinite ||
        maxValue <= minValue) {
      return chartArea.center.dy;
    }

    // Calculate the normalized position (0-1 range)
    final normalizedPosition = (value - minValue) / (maxValue - minValue);

    // Map to the chart area (bottom = minValue, top = maxValue)
    return chartArea.bottom - normalizedPosition * chartArea.height;
  }

  // Format Y-axis labels for step counts
  static String formatAxisLabel(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toString();
  }

  // Calculate optimal step size for readable labels
  static int _calculateOptimalStepSize(int min, int max) {
    final range = max - min;
    final targetSteps = 5; // Target 5 steps for clean labels
    final rawStep = range / targetSteps;

    // Use "nice" numbers for step sizes
    if (rawStep <= 500) return 500;
    if (rawStep <= 1000) return 1000;
    if (rawStep <= 2000) return 2000;
    if (rawStep <= 2500) return 2500;
    if (rawStep <= 5000) return 5000;
    if (rawStep <= 10000) return 10000;

    // Handle very large values
    return ((rawStep + 4999) ~/ 5000) * 5000;
  }

  // Generate evenly spaced axis values, limited to maximum of 6
  static List<int> _generateAxisValues(int min, int max, int step) {
    final values = <int>[];

    // Start at floor of min value aligned to step
    int currentValue = (min ~/ step) * step;

    // Generate values up to max, limiting to 6 total
    while (currentValue <= max && values.length < 6) {
      if (currentValue >= min) {
        values.add(currentValue);
      }
      currentValue += step;
    }

    // Ensure we include max value if we have space
    if (values.length < 6 &&
        !values.contains(max) &&
        (max - values.last) > step * 0.1) {
      values.add(max);
    }

    return values;
  }

  // Default range when no data is available
  static (List<int>, double, double) _getDefaultRange() {
    const defaultMin = 0;
    const defaultMax = 15000; // Cover typical daily range
    const step = 2500; // Clean intervals
    final values = _generateAxisValues(defaultMin, defaultMax, step);
    return (values, defaultMin.toDouble(), defaultMax.toDouble());
  }

  static Rect calculateChartArea(Size size) {
    const leftPadding = 45.0; // Space for step count labels
    const rightPadding = 15.0;
    const topPadding = 15.0;
    const bottomPadding = 45.0; // Space for date labels

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  static ProcessedStepData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedStepData> data,
  ) {
    if (data.isEmpty) return null;
    if (!_isWithinChartArea(position, chartArea)) return null;

    const edgePadding = 15.0;
    final availableWidth = chartArea.width - (edgePadding * 2);
    final xStep = data.length > 1 ? availableWidth / (data.length - 1) : 0;

    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < data.length; i++) {
      final x = chartArea.left + edgePadding + (i * xStep);
      final distance = (position.dx - x).abs();

      if (distance < minDistance && distance <= _hitTestThreshold) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    if (closestIndex >= 0 && !data[closestIndex].isEmpty) {
      return data[closestIndex];
    }

    return null;
  }

  static bool _isWithinChartArea(Offset position, Rect chartArea,
      {double tolerance = 10.0}) {
    final expandedRect = Rect.fromLTRB(
      chartArea.left - tolerance,
      chartArea.top - tolerance,
      chartArea.right + tolerance,
      chartArea.bottom + tolerance,
    );

    return expandedRect.contains(position);
  }

  static Offset calculateTooltipPosition(
    Offset tapPosition,
    Size tooltipSize,
    Size screenSize,
    EdgeInsets padding,
  ) {
    // Calculate initial position (centered above tap point)
    double x = tapPosition.dx - (tooltipSize.width / 2);
    double y = tapPosition.dy - tooltipSize.height - 10;

    // Adjust for screen edges
    x = x.clamp(
      padding.left + 8,
      screenSize.width - tooltipSize.width - padding.right - 8,
    );

    // If tooltip would go off the top of the screen, position below tap point
    if (y < padding.top + 8) {
      y = tapPosition.dy + 10;
    }

    // Final vertical bounds check
    y = y.clamp(
      padding.top + 8,
      screenSize.height - tooltipSize.height - padding.bottom - 8,
    );

    return Offset(x, y);
  }
}
