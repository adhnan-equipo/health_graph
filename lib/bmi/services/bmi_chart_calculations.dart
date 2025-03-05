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

    // Collect all values to consider
    final allValues = <double>[];

    // Add data points (only consider non-empty data)
    for (var point in data.where((d) => !d.isEmpty)) {
      allValues.addAll([
        point.minBMI,
        point.maxBMI,
        point.avgBMI,
      ]);
    }

    // Add BMI category reference ranges if no custom ranges
    if (referenceRanges.isEmpty) {
      allValues.addAll([15.0, 18.5, 25.0, 30.0, 35.0]);
    } else {
      // Add reference ranges
      for (var range in referenceRanges) {
        allValues.addAll([range.$1, range.$2]);
      }
    }

    // Filter out invalid values
    final validValues =
        allValues.where((v) => !v.isNaN && v.isFinite && v > 0).toList();

    if (validValues.isEmpty) {
      return _getDefaultRange();
    }

    // Find actual min/max from data
    var minValue = validValues.reduce(min);
    var maxValue = validValues.reduce(max);

    // Calculate range with padding
    final range = maxValue - minValue;
    final topPadding = range * 0.15;
    final bottomPadding = range * 0.15;

    // Always include standard BMI ranges
    minValue = min(minValue - bottomPadding, 15.0);
    maxValue = max(maxValue + topPadding, 35.0);

    // Ensure we have a reasonable range
    if (maxValue - minValue < 5) {
      maxValue = minValue + 5;
    }

    // Calculate optimal step size
    final stepSize = _calculateStepSize(minValue, maxValue);

    // Generate axis values with better distribution
    final yAxisValues = _generateAxisValues(minValue, maxValue, stepSize);

    return (yAxisValues, minValue, maxValue);
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

  static List<double> _generateAxisValues(double min, double max, double step) {
    final values = <double>[];
    var currentValue = min;

    // Round min down to nearest step
    currentValue = (min / step).floor() * step;

    while (currentValue <= max) {
      values.add(currentValue);
      currentValue += step;
    }

    return values;
  }

  static (List<double>, double, double) _getDefaultRange() {
    const defaultMin = 15.0;
    const defaultMax = 35.0;
    const step = 5.0;
    final values = _generateAxisValues(defaultMin, defaultMax, step);
    return (values, defaultMin, defaultMax);
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
