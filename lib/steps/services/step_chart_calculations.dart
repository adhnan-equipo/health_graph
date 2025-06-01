// lib/steps/services/step_chart_calculations.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/processed_step_data.dart';
import '../models/step_range.dart';

class StepChartCalculations {
  static const double _minPaddingPercent = 0.15; // 15% padding minimum
  static const double _maxPaddingPercent = 0.25; // 25% padding maximum
  static const double _hitTestThreshold = 20.0;

  // Enhanced scaling thresholds for low values
  static const int _veryLowThreshold = 500; // < 500 steps
  static const int _lowThreshold = 2000; // < 2000 steps
  static const int _mediumThreshold = 8000; // < 8000 steps

  /// Enhanced Y-axis range calculation with intelligent scaling for low values
  static (List<int>, double, double) calculateYAxisRange(
    List<ProcessedStepData> data,
    List<(int min, int max)> referenceRanges,
  ) {
    if (data.isEmpty && referenceRanges.isEmpty) {
      return _getDefaultRange();
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
      return _getSmartDefaultRange();
    }

    var minValue = 0; // Always start at 0 for step counts
    var maxValue = validValues.reduce(max);

    // **CORE ENHANCEMENT**: Smart scaling based on data magnitude
    final scalingStrategy = _determineScalingStrategy(maxValue);
    final adjustedRange =
        _applySmartScaling(minValue, maxValue, scalingStrategy);

    minValue = adjustedRange.min;
    maxValue = adjustedRange.max;

    // Calculate optimal step size for the scaled range
    final stepSize =
        _calculateSmartStepSize(minValue, maxValue, scalingStrategy);
    final yAxisValues = _generateSmartAxisValues(minValue, maxValue, stepSize);

    return (yAxisValues, minValue.toDouble(), maxValue.toDouble());
  }

  /// Determine appropriate scaling strategy based on data magnitude
  static _ScalingStrategy _determineScalingStrategy(int maxValue) {
    if (maxValue <= _veryLowThreshold) {
      return _ScalingStrategy.veryLow;
    } else if (maxValue <= _lowThreshold) {
      return _ScalingStrategy.low;
    } else if (maxValue <= _mediumThreshold) {
      return _ScalingStrategy.medium;
    } else {
      return _ScalingStrategy.high;
    }
  }

  /// Apply intelligent scaling with appropriate buffering
  static ({int min, int max}) _applySmartScaling(
      int minValue, int maxValue, _ScalingStrategy strategy) {
    switch (strategy) {
      case _ScalingStrategy.veryLow:
        // For very low values (< 500), use generous padding and meaningful increments
        final buffer = max(maxValue * 0.4, 50); // At least 50 step buffer
        final adjustedMax =
            ((maxValue + buffer) / 50).ceil() * 50; // Round to 50s
        return (min: 0, max: max(adjustedMax, 200)); // Minimum range of 200

      case _ScalingStrategy.low:
        // For low values (500-2000), use moderate padding
        final buffer = max(maxValue * 0.3, 100); // At least 100 step buffer
        final adjustedMax =
            ((maxValue + buffer) / 100).ceil() * 100; // Round to 100s
        return (min: 0, max: max(adjustedMax, 500));

      case _ScalingStrategy.medium:
        // For medium values (2000-8000), standard padding
        final buffer = maxValue * 0.25;
        final adjustedMax =
            ((maxValue + buffer) / 500).ceil() * 500; // Round to 500s
        return (min: 0, max: adjustedMax);

      case _ScalingStrategy.high:
        // For high values (> 8000), minimal padding but ensure goal visibility
        final buffer = maxValue * 0.2;
        final adjustedMax =
            ((maxValue + buffer) / 1000).ceil() * 1000; // Round to 1000s
        final goalAwareMax =
            max(adjustedMax, StepRange.recommendedDaily + 2000);
        return (min: 0, max: goalAwareMax);
    }
  }

  /// Smart step size calculation based on scaling strategy
  static int _calculateSmartStepSize(
      int min, int max, _ScalingStrategy strategy) {
    final range = max - min;

    switch (strategy) {
      case _ScalingStrategy.veryLow:
        // For very low values, use small increments for better granularity
        if (range <= 200) return 25;
        if (range <= 500) return 50;
        return 100;

      case _ScalingStrategy.low:
        // For low values, balance granularity with readability
        if (range <= 500) return 50;
        if (range <= 1000) return 100;
        return 250;

      case _ScalingStrategy.medium:
        // Standard increments for medium values
        if (range <= 2000) return 250;
        if (range <= 5000) return 500;
        return 1000;

      case _ScalingStrategy.high:
        // Larger increments for high values
        if (range <= 10000) return 1000;
        if (range <= 25000) return 2500;
        return 5000;
    }
  }

  /// Generate axis values with smart distribution
  static List<int> _generateSmartAxisValues(int min, int max, int step) {
    final values = <int>[];
    int currentValue = 0; // Always start at 0

    // Generate primary values
    while (currentValue <= max && values.length < 8) {
      values.add(currentValue);
      currentValue += step;
    }

    // Ensure we always include key reference points for context
    _addKeyReferencePoints(values, max);

    return values..sort();
  }

  /// Add important reference points (like goal line) to axis values
  static void _addKeyReferencePoints(List<int> values, int maxValue) {
    // Always include goal line for context, even if data is much lower
    if (!values.contains(StepRange.recommendedDaily) &&
        StepRange.recommendedDaily <= maxValue * 1.5) {
      values.add(StepRange.recommendedDaily);
    }

    // Add minimum health benefit threshold if relevant
    if (!values.contains(StepRange.minimumHealthBenefit) &&
        StepRange.minimumHealthBenefit <= maxValue * 1.2) {
      values.add(StepRange.minimumHealthBenefit);
    }
  }

  /// Smart default range for very low or empty data
  static (List<int>, double, double) _getSmartDefaultRange() {
    // Default range optimized for low values
    const defaultMax = 500;
    const step = 50;
    final values = [0, 50, 100, 150, 200, 250, 300, 400, 500];
    return (values, 0.0, defaultMax.toDouble());
  }

  /// Legacy default range (kept for compatibility)
  static (List<int>, double, double) _getDefaultRange() {
    return _getSmartDefaultRange();
  }

  /// Enhanced position calculation with better precision for low values
  static double calculateYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    if (value.isNaN || !value.isFinite || maxValue <= minValue) {
      return chartArea.bottom;
    }

    // Enhanced precision for low value ranges
    final normalizedPosition = (value - minValue) / (maxValue - minValue);
    final position = chartArea.bottom - normalizedPosition * chartArea.height;

    // Ensure minimum visual separation for very close values
    return position.clamp(chartArea.top, chartArea.bottom);
  }

  // Enhanced hit testing for better interaction with low values
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

    // Enhanced hit testing with adaptive threshold
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

  // Rest of the existing methods remain unchanged...
  static String formatAxisLabel(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toString();
  }

  static Rect calculateChartArea(Size size) {
    const leftPadding = 60.0; // Increased for better label space
    const rightPadding = 15.0;
    const topPadding = 25.0; // Increased for goal line space
    const bottomPadding = 45.0;

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
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
}

/// Internal enum for scaling strategies
enum _ScalingStrategy {
  veryLow, // < 500 steps
  low, // 500-2000 steps
  medium, // 2000-8000 steps
  high, // > 8000 steps
}
