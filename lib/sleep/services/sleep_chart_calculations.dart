// lib/sleep/services/sleep_chart_calculations.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_sleep_data.dart';
import '../models/sleep_range.dart';

class SleepChartCalculations {
  static const double _hitTestThreshold = 20.0;

  /// Calculate Y-axis range for sleep data in minutes
  static (List<int>, double, double) calculateYAxisRange(
    List<ProcessedSleepData> data,
    List<(int min, int max)> referenceRanges,
  ) {
    if (data.isEmpty && referenceRanges.isEmpty) {
      return _getDefaultSleepRange();
    }

    // Extract display values from actual data
    final actualValues = <int>[];
    for (var point in data.where((d) => !d.isEmpty)) {
      actualValues.add(point.displayValue);
    }

    // Add reference ranges if provided
    for (var range in referenceRanges) {
      actualValues.addAll([range.$1, range.$2]);
    }

    final validValues = actualValues.where((v) => v >= 0).toList();
    if (validValues.isEmpty) {
      return _getDefaultSleepRange();
    }

    var minValue = 0; // Always start at 0 for sleep duration
    var maxValue = validValues.reduce(max);

    // Smart scaling for sleep data
    final adjustedRange = _applySleepScaling(minValue, maxValue);
    minValue = adjustedRange.min;
    maxValue = adjustedRange.max;

    // Calculate step size for sleep data (in minutes)
    final stepSize = _calculateSleepStepSize(minValue, maxValue);
    final yAxisValues = _generateSleepAxisValues(minValue, maxValue, stepSize);

    return (yAxisValues, minValue.toDouble(), maxValue.toDouble());
  }

  /// Apply intelligent scaling for sleep data
  static ({int min, int max}) _applySleepScaling(int minValue, int maxValue) {
    // For sleep data, we want to ensure key reference points are visible
    final recommendedMax = SleepRange.recommendedMax; // 9 hours = 540 minutes

    // Add buffer based on sleep context
    int adjustedMax;
    if (maxValue < 240) {
      // Less than 4 hours - likely short naps or poor sleep
      adjustedMax = 480; // Show up to 8 hours for context
    } else if (maxValue < 360) {
      // 4-6 hours - insufficient sleep
      adjustedMax = 600; // Show up to 10 hours
    } else if (maxValue < recommendedMax) {
      // Below recommended maximum
      adjustedMax = recommendedMax + 60; // Add 1 hour buffer
    } else {
      // Above recommended - add proportional buffer
      final buffer = (maxValue * 0.15).round();
      adjustedMax = maxValue + buffer;
    }

    // Round to nice increments
    if (adjustedMax <= 480) {
      adjustedMax = ((adjustedMax / 60).ceil() * 60); // Round to nearest hour
    } else {
      adjustedMax =
          ((adjustedMax / 120).ceil() * 120); // Round to nearest 2 hours
    }

    return (min: 0, max: adjustedMax);
  }

  /// Calculate appropriate step size for sleep data
  static int _calculateSleepStepSize(int min, int max) {
    final range = max - min;

    if (range <= 240) return 30; // 30-minute increments for short ranges
    if (range <= 480) return 60; // 1-hour increments
    if (range <= 720) return 90; // 1.5-hour increments
    if (range <= 1080) return 120; // 2-hour increments
    return 180; // 3-hour increments for very long ranges
  }

  /// Generate axis values for sleep data
  static List<int> _generateSmartAxisValues(int min, int max, int step) {
    final values = <int>[];
    int currentValue = 0; // Always start at 0

    while (currentValue <= max && values.length < 8) {
      values.add(currentValue);
      currentValue += step;
    }

    // Add key sleep reference points
    _addSleepReferencePoints(values, max);

    return values..sort();
  }

  /// Add important sleep reference points
  static void _addSleepReferencePoints(List<int> values, int maxValue) {
    // Add recommended sleep range markers if they fit
    if (!values.contains(SleepRange.recommendedMin) &&
        SleepRange.recommendedMin <= maxValue) {
      values.add(SleepRange.recommendedMin);
    }

    if (!values.contains(SleepRange.recommendedMax) &&
        SleepRange.recommendedMax <= maxValue * 1.2) {
      values.add(SleepRange.recommendedMax);
    }

    // Add minimum health benefit threshold
    if (!values.contains(SleepRange.minimumSleep) &&
        SleepRange.minimumSleep <= maxValue) {
      values.add(SleepRange.minimumSleep);
    }
  }

  /// Default range for empty sleep data
  static (List<int>, double, double) _getDefaultSleepRange() {
    const defaultMax = 480; // 8 hours
    const step = 60; // 1 hour increments
    final values = [0, 60, 120, 180, 240, 300, 360, 420, 480]; // 0-8 hours
    return (values, 0.0, defaultMax.toDouble());
  }

  /// Enhanced position calculation for sleep data
  static double calculateYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    if (value.isNaN || !value.isFinite || maxValue <= minValue) {
      return chartArea.bottom;
    }

    final normalizedPosition = (value - minValue) / (maxValue - minValue);
    final position = chartArea.bottom - normalizedPosition * chartArea.height;

    return position.clamp(chartArea.top, chartArea.bottom);
  }

  /// Find the closest sleep data point for interaction
  static ProcessedSleepData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedSleepData> data,
  ) {
    if (data.isEmpty) return null;
    if (!_isWithinChartArea(position, chartArea)) return null;

    const barPadding = 8.0;
    final availableWidth = chartArea.width - (barPadding * 2);
    final barWidth = data.length > 1
        ? (availableWidth - (barPadding * (data.length - 1))) / data.length
        : availableWidth * 0.6;

    final adaptiveThreshold = max(_hitTestThreshold, barWidth * 0.6);

    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < data.length; i++) {
      final x = chartArea.left +
          barPadding +
          (i * (barWidth + barPadding)) +
          (barWidth / 2);
      final distance = (position.dx - x).abs();

      if (distance < minDistance && distance <= adaptiveThreshold) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    if (closestIndex >= 0 && !data[closestIndex].isEmpty) {
      return data[closestIndex];
    }

    return null;
  }

  /// Calculate chart area with appropriate padding for sleep data
  static Rect calculateChartArea(Size size) {
    const leftPadding =
        70.0; // Larger for sleep duration labels (e.g., "8h 30m")
    const rightPadding = 15.0;
    const topPadding = 25.0;
    const bottomPadding = 45.0;

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  /// Calculate tooltip position (reuse existing implementation)
  static Offset calculateTooltipPosition(
    Offset tapPosition,
    Size tooltipSize,
    Size screenSize,
    EdgeInsets padding,
  ) {
    double x = tapPosition.dx - (tooltipSize.width / 2);
    double y = tapPosition.dy - tooltipSize.height - 10;

    x = x.clamp(
      padding.left + 8,
      screenSize.width - tooltipSize.width - padding.right - 8,
    );

    if (y < padding.top + 8) {
      y = tapPosition.dy + 10;
    }

    y = y.clamp(
      padding.top + 8,
      screenSize.height - tooltipSize.height - padding.bottom - 8,
    );

    return Offset(x, y);
  }

  /// Helper to check if position is within chart area
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

  /// Fix for the missing method that was used earlier
  static List<int> _generateSleepAxisValues(int min, int max, int step) {
    return _generateSmartAxisValues(min, max, step);
  }
}
