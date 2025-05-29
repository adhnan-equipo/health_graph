// lib/steps/services/step_chart_calculations.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_step_data.dart';
import '../models/step_range.dart';

class StepChartCalculations {
  static const double _minPaddingPercent = 0.1; // 10% padding
  static const double _maxPaddingPercent = 0.2; // 20% padding
  static const double _hitTestThreshold = 20.0;

  /// Calculate Y-axis range with dynamic scaling
  /// If max step count is 1000, graph top will be around 1200 (20% padding)
  static (List<int>, double, double) calculateYAxisRange(
    List<ProcessedStepData> data,
    List<(int min, int max)> referenceRanges,
  ) {
    if (data.isEmpty && referenceRanges.isEmpty) {
      return _getDefaultRange();
    }

    // Extract display values (daily averages for week/month/year, totals for day)
    final actualValues = <int>[];

    for (var point in data.where((d) => !d.isEmpty)) {
      actualValues.add(point.displayValue);
    }

    // Add reference ranges if provided
    for (var range in referenceRanges) {
      actualValues.addAll([range.$1, range.$2]);
    }

    // Ensure we have meaningful reference points
    if (actualValues.isEmpty) {
      // Add basic step thresholds for context
      actualValues.addAll([
        0,
        StepRange.minimumHealthBenefit,
        StepRange.recommendedDaily,
      ]);
    }

    final validValues = actualValues.where((v) => v >= 0).toList();
    if (validValues.isEmpty) {
      return _getDefaultRange();
    }

    // Calculate dynamic min/max
    var minValue = validValues.reduce(min);
    var maxValue = validValues.reduce(max);

    // Ensure minimum value starts at 0 for step counts
    minValue = 0;

    // Dynamic scaling: Add 20% padding to max value
    // If max is 1000, it becomes 1200
    final range = maxValue - minValue;
    final topPadding = (range * _maxPaddingPercent).round();

    // Ensure minimum meaningful range
    maxValue = max(maxValue + topPadding, StepRange.recommendedDaily);

    // If range is very small, add minimum padding
    if (maxValue - minValue < 2000) {
      maxValue = minValue + 2000;
    }

    // Calculate optimal step size
    final stepSize = _calculateOptimalStepSize(minValue, maxValue);
    final yAxisValues = _generateAxisValues(minValue, maxValue, stepSize);

    return (yAxisValues, minValue.toDouble(), maxValue.toDouble());
  }

  static double calculateYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    if (value.isNaN || !value.isFinite || maxValue <= minValue) {
      return chartArea.center.dy;
    }

    final normalizedPosition = (value - minValue) / (maxValue - minValue);
    return chartArea.bottom - normalizedPosition * chartArea.height;
  }

  /// Calculate optimal step size for readable labels
  /// Adapts to the data range dynamically
  static int _calculateOptimalStepSize(int min, int max) {
    final range = max - min;
    final targetSteps = 5; // Target 5 grid lines
    final rawStep = range / targetSteps;

    // Use "nice" numbers for step sizes based on range
    if (rawStep <= 100) return 100;
    if (rawStep <= 250) return 250;
    if (rawStep <= 500) return 500;
    if (rawStep <= 1000) return 1000;
    if (rawStep <= 2500) return 2500;
    if (rawStep <= 5000) return 5000;
    if (rawStep <= 10000) return 10000;

    // For very large ranges, use multiples of 5000
    return ((rawStep + 2499) ~/ 2500) * 2500;
  }

  /// Generate evenly spaced axis values with dynamic scaling
  static List<int> _generateAxisValues(int min, int max, int step) {
    final values = <int>[];

    // Always start at 0 for step counts
    int currentValue = 0;

    while (currentValue <= max && values.length < 6) {
      if (currentValue >= min) {
        values.add(currentValue);
      }
      currentValue += step;
    }

    // Ensure we have at least the max value if it's reasonable
    if (values.length < 6 && !values.contains(max) && max > values.last) {
      values.add(max);
    }

    return values;
  }

  /// Default range for empty data
  static (List<int>, double, double) _getDefaultRange() {
    const defaultMin = 0;
    const defaultMax = 12000; // Cover typical daily range plus padding
    const step = 2000;
    final values = _generateAxisValues(defaultMin, defaultMax, step);
    return (values, defaultMin.toDouble(), defaultMax.toDouble());
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

  static Rect calculateChartArea(Size size) {
    const leftPadding = 50.0; // Space for step count labels
    const rightPadding = 15.0;
    const topPadding = 20.0;
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

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth = data.length > 1
        ? (availableWidth - (barPadding * (data.length - 1))) / data.length
        : availableWidth * 0.6;

    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < data.length; i++) {
      final x = chartArea.left +
          barPadding +
          (i * (barWidth + barPadding)) +
          (barWidth / 2);
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
      {double tolerance = 15.0}) {
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
    double x = tapPosition.dx - (tooltipSize.width / 2);
    double y = tapPosition.dy - tooltipSize.height - 10;

    // Adjust for screen edges
    x = x.clamp(
      padding.left + 8,
      screenSize.width - tooltipSize.width - padding.right - 8,
    );

    // If tooltip would go off the top, position below tap point
    if (y < padding.top + 8) {
      y = tapPosition.dy + 10;
    }

    y = y.clamp(
      padding.top + 8,
      screenSize.height - tooltipSize.height - padding.bottom - 8,
    );

    return Offset(x, y);
  }
}
