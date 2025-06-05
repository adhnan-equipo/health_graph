import 'dart:math';

import 'package:flutter/material.dart';

/// Shared chart calculation utilities to reduce code duplication
/// Contains common calculations used across all chart types
class SharedChartCalculations {
  static const double _defaultHitTestThreshold = 20.0;

  /// Calculate chart area with consistent padding across all charts
  static Rect calculateChartArea(
    Size size, {
    double leftPadding = 40.0,
    double rightPadding = 10.0,
    double topPadding = 10.0,
    double bottomPadding = 30.0,
  }) {
    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  /// Calculate Y position from value using min/max range
  static double calculateYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    if (maxValue <= minValue || value.isNaN || !value.isFinite) {
      return chartArea.center.dy;
    }

    final normalizedValue = (value - minValue) / (maxValue - minValue);
    return chartArea.bottom -
        normalizedValue.clamp(0.0, 1.0) * chartArea.height;
  }

  /// Calculate X position for data points with even distribution
  static double calculateXPosition(
    int index,
    int totalPoints,
    Rect chartArea, {
    double edgePadding = 15.0,
  }) {
    if (totalPoints <= 1) return chartArea.center.dx;

    final availableWidth = chartArea.width - (edgePadding * 2);
    final pointSpacing = availableWidth / (totalPoints - 1);

    return chartArea.left + edgePadding + (index * pointSpacing);
  }

  /// Calculate tooltip position ensuring it stays within screen bounds
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
      padding.left + 8,
      screenSize.width - tooltipSize.width - padding.right - 8,
    );

    // If tooltip would go above screen, show it below the tap point
    if (y < padding.top + 8) {
      y = tapPosition.dy + 10;
    }

    // Ensure tooltip stays within vertical bounds
    y = y.clamp(
      padding.top + 8,
      screenSize.height - tooltipSize.height - padding.bottom - 8,
    );

    return Offset(x, y);
  }

  /// Calculate optimal Y-axis range with padding for numeric data
  static (List<double>, double, double) calculateNumericYAxisRange(
    List<double> values, {
    List<double> referenceValues = const [],
    double paddingPercent = 0.15,
    int maxLabels = 5,
  }) {
    final allValues = [...values, ...referenceValues]
        .where((v) => !v.isNaN && v.isFinite)
        .toList();

    if (allValues.isEmpty) {
      return _getDefaultNumericRange();
    }

    var minValue = allValues.reduce(min);
    var maxValue = allValues.reduce(max);

    // Add padding
    final range = maxValue - minValue;
    if (range > 0) {
      final padding = range * paddingPercent;
      minValue = max(0.0, minValue - padding);
      maxValue = maxValue + padding;
    } else {
      // Handle case where all values are the same
      minValue = max(0.0, minValue - 1);
      maxValue = maxValue + 1;
    }

    // Calculate optimal step size
    final stepSize = _calculateOptimalStepSize(minValue, maxValue, maxLabels);

    // Generate axis values
    final yAxisValues =
        _generateNumericAxisValues(minValue, maxValue, stepSize, maxLabels);

    return (yAxisValues, minValue, maxValue);
  }

  /// Calculate optimal Y-axis range with padding for integer data
  static (List<int>, double, double) calculateIntegerYAxisRange(
    List<int> values, {
    List<int> referenceValues = const [],
    double paddingPercent = 0.15,
    int maxLabels = 6,
  }) {
    final allValues = [...values, ...referenceValues];

    if (allValues.isEmpty) {
      return _getDefaultIntegerRange();
    }

    final minValue = allValues.reduce(min);
    final maxValue = allValues.reduce(max);

    // Calculate range with padding
    final range = maxValue - minValue;
    final topPadding = (range * paddingPercent).ceil();
    final bottomPadding = (range * paddingPercent).ceil();

    // Round to nice numbers
    final adjustedMin = max(0, minValue - bottomPadding);
    var adjustedMax = maxValue + topPadding;

    // Ensure minimum range
    if (adjustedMax - adjustedMin < 10) {
      adjustedMax = adjustedMin + 10;
    }

    // Calculate optimal step size
    final stepSize =
        _calculateIntegerStepSize(adjustedMin, adjustedMax, maxLabels);

    // Generate axis values
    final yAxisValues =
        _generateIntegerAxisValues(adjustedMin, adjustedMax, stepSize);

    return (yAxisValues, adjustedMin.toDouble(), adjustedMax.toDouble());
  }

  /// Format axis labels for better readability
  static String formatAxisLabel(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    } else if (value < 10) {
      return value.toStringAsFixed(1);
    }

    return value.round().toString();
  }

  /// Check if a position is within the chart area with tolerance
  static bool isWithinChartArea(
    Offset position,
    Rect chartArea, {
    double tolerance = _defaultHitTestThreshold,
  }) {
    final expandedRect = Rect.fromLTRB(
      chartArea.left - tolerance,
      chartArea.top - tolerance,
      chartArea.right + tolerance,
      chartArea.bottom + tolerance,
    );

    return expandedRect.contains(position);
  }

  /// Find the closest data point index based on X position
  static int? findClosestDataPointIndex(
    Offset position,
    Rect chartArea,
    int dataLength, {
    double hitTestThreshold = _defaultHitTestThreshold,
  }) {
    if (dataLength == 0 || !isWithinChartArea(position, chartArea)) {
      return null;
    }

    final xStep = chartArea.width / (dataLength - 1).clamp(1, double.infinity);
    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < dataLength; i++) {
      final x = chartArea.left + (i * xStep);
      final distance = (position.dx - x).abs();

      if (distance < minDistance && distance <= hitTestThreshold) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex >= 0 ? closestIndex : null;
  }

  /// Calculate optimal step size for numeric data
  static double _calculateOptimalStepSize(
      double min, double max, int maxLabels) {
    final range = max - min;
    final targetSteps = maxLabels - 1;
    final rawStep = range / targetSteps;

    // Use "nice" numbers for step sizes
    final magnitude = pow(10, (log(rawStep) / ln10).floor());
    final normalizedStep = rawStep / magnitude;

    double niceStep;
    if (normalizedStep <= 1) {
      niceStep = 1.0;
    } else if (normalizedStep <= 2) {
      niceStep = 2.0;
    } else if (normalizedStep <= 5) {
      niceStep = 5.0;
    } else {
      niceStep = 10.0;
    }

    return niceStep * magnitude;
  }

  /// Calculate optimal step size for integer data
  static int _calculateIntegerStepSize(int min, int max, int maxLabels) {
    final range = max - min;
    final targetSteps = maxLabels - 1;
    var rawStep = (range / targetSteps).ceil();

    // Round to nice numbers
    if (rawStep <= 5) return 5;
    if (rawStep <= 10) return 10;
    if (rawStep <= 20) return 20;
    if (rawStep <= 25) return 25;
    if (rawStep <= 50) return 50;
    return ((rawStep + 99) ~/ 100) * 100;
  }

  /// Generate numeric axis values
  static List<double> _generateNumericAxisValues(
    double min,
    double max,
    double step,
    int maxLabels,
  ) {
    final values = <double>[];
    double currentValue = (min / step).floor() * step;

    while (currentValue <= max && values.length < maxLabels) {
      values.add(currentValue);
      currentValue += step;
    }

    return values;
  }

  /// Generate integer axis values
  static List<int> _generateIntegerAxisValues(int min, int max, int step) {
    final values = <int>[];
    var currentValue = min;

    while (currentValue <= max) {
      values.add(currentValue);
      currentValue += step;
    }

    return values;
  }

  /// Default range for numeric data when no data is available
  static (List<double>, double, double) _getDefaultNumericRange() {
    const defaultMin = 0.0;
    const defaultMax = 100.0;
    const step = 20.0;
    final values = _generateNumericAxisValues(defaultMin, defaultMax, step, 6);
    return (values, defaultMin, defaultMax);
  }

  /// Default range for integer data when no data is available
  static (List<int>, double, double) _getDefaultIntegerRange() {
    const defaultMin = 0;
    const defaultMax = 100;
    const step = 20;
    final values = _generateIntegerAxisValues(defaultMin, defaultMax, step);
    return (values, defaultMin.toDouble(), defaultMax.toDouble());
  }
}
