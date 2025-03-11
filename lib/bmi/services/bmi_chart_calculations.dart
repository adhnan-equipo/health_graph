// lib/bmi/services/bmi_chart_calculations.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_bmi_data.dart';

class BMIChartCalculations {
  static const double _minPaddingPercent = 0.05;
  static const double _maxPaddingPercent = 0.15;
  static const double _hitTestThreshold = 20.0;

  static (List<double>, double, double) calculateYAxisRange(
    List<ProcessedBMIData> data,
    List<(double min, double max)> referenceRanges,
  ) {
    if (data.isEmpty && referenceRanges.isEmpty) {
      return _getDefaultRange();
    }

    // Focus on last recorded values from each section
    final lastValues = <double>[];

    // Extract last recorded value from each non-empty section
    for (var point in data.where((d) => !d.isEmpty)) {
      if (point.originalMeasurements.isNotEmpty) {
        // Use last recorded measurement for more accurate representation
        lastValues.add(point.originalMeasurements.last.bmi);
      } else {
        lastValues.add(point.avgBMI); // Fallback to average
      }
    }

    // Add BMI category reference ranges if no custom ranges provided
    if (referenceRanges.isEmpty) {
      // Critical BMI thresholds for reference lines
      lastValues.addAll([18.5, 25.0, 30.0]);
    } else {
      // Add custom reference ranges
      for (var range in referenceRanges) {
        lastValues.addAll([range.$1, range.$2]);
      }
    }

    // Filter out invalid values
    final validValues =
        lastValues.where((v) => !v.isNaN && v.isFinite && v > 0).toList();

    if (validValues.isEmpty) {
      return _getDefaultRange();
    }

    // Calculate min/max from actual data
    var minValue = validValues.reduce(min);
    var maxValue = validValues.reduce(max);

    // Calculate range with padding
    final range = maxValue - minValue;
    final topPadding = range * 0.15;
    final bottomPadding = range * 0.15;

    // Enforce minimum value of 0 (never go negative)
    minValue = max(0.0, minValue - bottomPadding);

    // Ensure maximum covers obese BMI range
    maxValue = max(maxValue + topPadding, 35.0);

    // Maintain a reasonable range for better visualization
    if (maxValue - minValue < 5) {
      maxValue = minValue + 5;
    }

    // Calculate optimal step size for max 5 labels
    final stepSize = _calculateOptimalStepSize(minValue, maxValue);

    // Generate axis values with better distribution (limited to 5 max)
    final yAxisValues = _generateAxisValues(minValue, maxValue, stepSize);

    return (yAxisValues, minValue, maxValue);
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

  // NEW METHOD: Format Y-axis labels for better readability
  static String formatAxisLabel(double value) {
    // Handle large values with K/M suffix
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }

    // Avoid unnecessary decimal places
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    } else if (value < 10) {
      return value.toStringAsFixed(1); // One decimal for small values
    }

    // Round to nearest integer for most BMI values
    return value.round().toString();
  }

// Calculate optimal step size for readable labels
  static double _calculateOptimalStepSize(double min, double max) {
    final range = max - min;
    final targetSteps = 4; // Target 4 steps to ensure 5 or fewer labels
    final rawStep = range / targetSteps;

    // Use "nice" numbers for step sizes (powers of 2, 5, 10)
    if (rawStep <= 1) return 1.0;
    if (rawStep <= 2) return 2.0;
    if (rawStep <= 5) return 5.0;
    if (rawStep <= 10) return 10.0;
    if (rawStep <= 20) return 20.0;
    if (rawStep <= 50) return 50.0;
    if (rawStep <= 100) return 100.0;

    // Handle very large values
    return (rawStep / 100).ceil() * 100;
  }

// Generate evenly spaced axis values, limited to maximum of 5
  static List<double> _generateAxisValues(double min, double max, double step) {
    final values = <double>[];

    // Start at floor of min value aligned to step
    double currentValue = (min / step).floor() * step;

    // Generate values up to max, limiting to 5 total
    while (currentValue <= max && values.length < 5) {
      values.add(currentValue);
      currentValue += step;
    }

    // Ensure we include max value if we have space
    if (values.length < 5 &&
        !values.contains(max) &&
        (max - values.last) > step * 0.1) {
      values.add(max);
    }

    // If we have too few values, add intermediate steps
    if (values.length < 3 && values.length > 1) {
      final intermediateValues = <double>[];
      for (int i = 0; i < values.length - 1; i++) {
        intermediateValues.add((values[i] + values[i + 1]) / 2);
      }

      values.addAll(intermediateValues);
      values.sort();
    }

    // Enforce maximum of 5 values
    if (values.length > 5) {
      final result = <double>[values.first]; // Keep min

      // Keep evenly distributed middle values
      final step = (values.length - 2) / 3.0;
      for (int i = 1; i <= 3; i++) {
        final index = (i * step).round();
        if (index > 0 && index < values.length - 1) {
          result.add(values[index]);
        }
      }

      result.add(values.last); // Keep max
      return result;
    }

    return values;
  }

// Default range when no data is available
  static (List<double>, double, double) _getDefaultRange() {
    const defaultMin = 0.0; // Start at 0
    const defaultMax = 35.0; // Cover full BMI range
    const step = 7.0; // 5 labels (0, 7, 14, 21, 28, 35)
    final values = _generateAxisValues(defaultMin, defaultMax, step);
    return (values, defaultMin, defaultMax);
  }

  static double _calculateStepSize(double min, double max) {
    final range = max - min;
    final targetSteps = 6; // Aim for 6 steps
    final rawStep = range / targetSteps;

    if (rawStep <= 1) return 1.0;
    if (rawStep <= 2) return 2.0;
    if (rawStep <= 5) return 5.0;
    return 10.0;
  }

  static Rect calculateChartArea(Size size) {
    const leftPadding = 35.0;
    const rightPadding = 10.0; // Increased from 10.0
    const topPadding = 10.0;
    const bottomPadding = 40.0; // Increased from 30.0 for better label space

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  static ProcessedBMIData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedBMIData> data,
  ) {
    if (data.isEmpty) return null;
    if (!_isWithinChartArea(position, chartArea)) return null;

    final xStep = chartArea.width / (data.length - 1).clamp(1, double.infinity);
    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < data.length; i++) {
      final x = chartArea.left + (i * xStep);
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

  static double getYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    if (maxValue == minValue) return chartArea.center.dy;
    final valueRange = maxValue - minValue;
    final normalizedValue = (value - minValue) / valueRange;
    return chartArea.bottom - (normalizedValue * chartArea.height);
  }
}
