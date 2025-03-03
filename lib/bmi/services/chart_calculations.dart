import 'dart:math';

import 'package:flutter/material.dart';

import '../../blood_pressure/models/processed_blood_pressure_data.dart';

/// Utility class for chart-related calculations
class ChartCalculations {
  // Constants for hit testing and padding
  static const double hitTestThreshold = 22.0;
  static const double chartTopPadding = 10.0;
  static const double chartBottomPadding = 32.0;
  static const double chartLeftPadding = 45.0;
  static const double chartRightPadding = 10.0;
  static const double dataPointEdgePadding = 12.0;

  /// Calculate Y-axis range and values based on data and reference ranges
  static (List<int>, double, double) calculateYAxisRange(
    List<ProcessedBloodPressureData> data,
    List<(int min, int max)> referenceRanges,
  ) {
    if (data.isEmpty && referenceRanges.isEmpty) {
      return _getDefaultRange();
    }

    // Collect all values to consider
    final allValues = <int>[];

    // Add data points (only consider non-empty data)
    for (var point in data.where((d) => !d.isEmpty)) {
      allValues.addAll([
        point.minSystolic,
        point.maxSystolic,
        point.minDiastolic,
        point.maxDiastolic,
      ]);
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

    // Calculate range with appropriate padding
    final range = maxValue - minValue;
    final topPadding = range * 0.15;
    final bottomPadding = range * 0.15;

    // Round to nearest 10 with extra space
    final adjustedMin = max(0, ((minValue - bottomPadding) / 10).floor() * 10);
    var adjustedMax = ((maxValue + topPadding) / 10).ceil() * 10;

    // Ensure maximum is at least 200 for blood pressure and has enough padding
    adjustedMax = max(adjustedMax, max(200, maxValue + 20));

    // Calculate optimal step size for clean grid lines
    final effectiveRange = adjustedMax - adjustedMin;
    var stepSize = _calculateOptimalStepSize(effectiveRange);

    // Generate axis values with better distribution
    final yAxisValues = _generateAxisValues(adjustedMin, adjustedMax, stepSize);

    return (yAxisValues, adjustedMin.toDouble(), adjustedMax.toDouble());
  }

  /// Calculate optimal step size for axis labels
  static int _calculateOptimalStepSize(int range) {
    // Target 5-7 grid lines for optimal readability
    final targetSteps = 6;
    var rawStep = range / targetSteps;

    // Round to "nice" numbers that are easy to read
    if (rawStep <= 5) return 5;
    if (rawStep <= 10) return 10;
    if (rawStep <= 20) return 20;
    if (rawStep <= 25) return 25;
    if (rawStep <= 50) return 50;

    // For larger ranges, use multiples of 100
    return ((rawStep + 99) ~/ 100) * 100;
  }

  /// Generate evenly spaced axis values
  static List<int> _generateAxisValues(int start, int end, int step) {
    final values = <int>[];
    var currentValue = start;

    while (currentValue <= end) {
      values.add(currentValue);
      currentValue += step;
    }

    // Ensure we have enough values for proper spacing (at least 5 values)
    if (values.length < 5) {
      final additionalStep = step ~/ 2;
      var additionalValue = start + additionalStep;

      while (additionalValue < end) {
        if (!values.contains(additionalValue)) {
          values.add(additionalValue);
        }
        additionalValue += step;
      }
      values.sort();
    }

    return values;
  }

  /// Default Y-axis range when no data is available
  static (List<int>, double, double) _getDefaultRange() {
    const defaultMin = 0;
    const defaultMax = 200;
    const step = 20;
    final values = _generateAxisValues(defaultMin, defaultMax, step);
    return (values, defaultMin.toDouble(), defaultMax.toDouble());
  }

  /// Calculate the chart area based on available size and padding requirements
  static Rect calculateChartArea(Size size) {
    return Rect.fromLTRB(
      chartLeftPadding,
      chartTopPadding,
      size.width - chartRightPadding,
      size.height - chartBottomPadding,
    );
  }

  /// Calculate X position for a data point index
  static double calculateXPosition(
    int index,
    int totalPoints,
    Rect chartArea,
  ) {
    if (totalPoints <= 1) return chartArea.center.dx;

    final effectiveWidth = chartArea.width;
    final availableWidth = effectiveWidth - (dataPointEdgePadding * 2);
    final pointSpacing =
        availableWidth / (totalPoints - 1).clamp(1, double.infinity);

    return chartArea.left + dataPointEdgePadding + (index * pointSpacing);
  }

  /// Find the data point closest to a tap/drag position
  static ProcessedBloodPressureData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedBloodPressureData> data,
  ) {
    if (data.isEmpty || !_isWithinChartArea(position, chartArea)) {
      return null;
    }

    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < data.length; i++) {
      final x = calculateXPosition(i, data.length, chartArea);
      final distance = (position.dx - x).abs();

      if (distance < minDistance && distance <= hitTestThreshold) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    if (closestIndex >= 0 && !data[closestIndex].isEmpty) {
      return data[closestIndex];
    }

    return null;
  }

  /// Find the index of the data point closest to the X position
  static int findClosestPointIndex(
    Offset position,
    Rect chartArea,
    int dataLength,
  ) {
    if (dataLength <= 0 || !_isWithinChartArea(position, chartArea)) {
      return -1;
    }

    // Calculate offset from chart left edge
    final relativeX = position.dx - chartArea.left - dataPointEdgePadding;

    // Calculate available width
    final availableWidth = chartArea.width - (dataPointEdgePadding * 2);

    // Calculate point spacing
    final pointSpacing =
        availableWidth / (dataLength - 1).clamp(1, double.infinity);

    // Estimate index
    final estimatedIndex = (relativeX / pointSpacing).round();

    // Clamp to valid range
    return estimatedIndex.clamp(0, dataLength - 1);
  }

  /// Check if a point is within the chart area with some tolerance
  static bool _isWithinChartArea(Offset position, Rect chartArea,
      {double tolerance = 0.0}) {
    final expandedRect = Rect.fromLTRB(
      chartArea.left - tolerance,
      chartArea.top - tolerance,
      chartArea.right + tolerance,
      chartArea.bottom + tolerance,
    );

    return expandedRect.contains(position);
  }

  /// Calculate tooltip position to ensure it stays within screen bounds
  static Offset calculateTooltipPosition(
    Offset tapPosition,
    Size tooltipSize,
    Size screenSize,
    EdgeInsets screenPadding,
  ) {
    // Calculate initial centered position
    double x = tapPosition.dx - (tooltipSize.width / 2);
    double y = tapPosition.dy - tooltipSize.height - 12;

    // Adjust for horizontal bounds
    x = x.clamp(
      screenPadding.left,
      screenSize.width - tooltipSize.width - screenPadding.right,
    );

    // If tooltip would appear above screen, move it below tap point
    if (y < screenPadding.top) {
      y = tapPosition.dy + 12;
    }

    // Adjust for vertical bounds
    y = y.clamp(
      screenPadding.top,
      screenSize.height - tooltipSize.height - screenPadding.bottom,
    );

    return Offset(x, y);
  }

  /// Calculate a visual scale for better display
  static (num, double) calculateVisualMinMax(
    double dataMin,
    double dataMax,
  ) {
    final range = dataMax - dataMin;
    final padding = range * 0.1; // 10% padding

    final minV = max(0, dataMin - padding);
    final maxV = dataMax + padding;

    return (minV, maxV);
  }

  /// Calculate the Y-coordinate for a value in the chart
  static double calculateYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    // Handle edge cases
    if (maxValue <= minValue) return chartArea.center.dy;

    // Normalize value to 0-1 range
    final normalizedValue = (value - minValue) / (maxValue - minValue);

    // Convert to Y coordinate (top is minValue, bottom is maxValue)
    return chartArea.bottom - (normalizedValue * chartArea.height);
  }

  /// Create animation curve that distributes delay across data points
  static Curve createProgressiveCurve(int index, int totalPoints) {
    return _ProgressiveCurve(
      itemIndex: index,
      totalItems: totalPoints,
      baseDelay: 0.3, // 30% of animation time for staggered start
      baseDuration: 0.7, // 70% of animation time for each item animation
    );
  }
}

/// Custom curve for progressive animations
class _ProgressiveCurve extends Curve {
  final int itemIndex;
  final int totalItems;
  final double baseDelay;
  final double baseDuration;

  const _ProgressiveCurve({
    required this.itemIndex,
    required this.totalItems,
    this.baseDelay = 0.3,
    this.baseDuration = 0.7,
  });

  @override
  double transform(double t) {
    // Calculate the delay for this item (0 to baseDelay)
    final itemDelay = (itemIndex / totalItems) * baseDelay;

    // Calculate adjusted time considering the delay
    final adjustedT = (t - itemDelay) / baseDuration;

    // Apply cubic ease out curve, but only after delay
    if (adjustedT <= 0) return 0;
    if (adjustedT >= 1) return 1;

    // Cubic ease out
    final t1 = adjustedT - 1.0;
    return 1.0 - t1 * t1 * t1 * t1;
  }
}
