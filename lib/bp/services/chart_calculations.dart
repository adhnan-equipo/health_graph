import 'dart:math';

import 'package:flutter/material.dart';

import '../../blood_pressure/models/processed_blood_pressure_data.dart';

class ChartCalculations {
  static const double _hitTestThreshold = 20.0;
  static const double _topPaddingPercent = 0.01;
  static const double _bottomPaddingPercent = 0.12;

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

    // Calculate range with increased padding
    final range = maxValue - minValue;
    final topPadding = range * 0.15; // Increased from 0.01
    final bottomPadding = range * 0.15; // Increased from 0.12

    // Round to nearest 10 with extra space
    final adjustedMin = max(0, ((minValue - bottomPadding) / 10).floor() * 10);
    var adjustedMax = ((maxValue + topPadding) / 10).ceil() * 10;

    // Ensure maximum is at least 200 and has enough padding
    adjustedMax = max(adjustedMax, max(200, maxValue + 20));

    // Calculate optimal step size with better distribution
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
    return ((number + 99) ~/ 100) * 100; // Increased scale for larger numbers
  }

  static Rect calculateChartArea(Size size) {
    // Minimize top padding while maintaining bottom space for labels
    const leftPadding = 30.0;
    const rightPadding = 10.0;
    const topPadding = 10.0; // Reduced from 30.0
    const bottomPadding = 10.0;

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
    if (values.length < 6) {
      final additionalStep = step ~/ 2;
      var additionalValue = start + additionalStep;

      while (additionalValue < end) {
        values.add(additionalValue);
        additionalValue += step;
      }
      values.sort();
    }

    return values;
  }

  static (List<int>, double, double) _getDefaultRange() {
    const defaultMin = 0; // Adjusted for blood pressure
    const defaultMax = 200;
    const step = 20;
    final values = _generateAxisValues(defaultMin, defaultMax, step);
    return (values, defaultMin.toDouble(), defaultMax.toDouble());
  }

  // Keep existing X position calculation
  static double calculateXPosition(
    int index,
    int totalPoints,
    Rect chartArea,
  ) {
    if (totalPoints <= 1) return chartArea.center.dx;

    final effectiveWidth = chartArea.width;
    const edgePadding = 10.0;
    final availableWidth = effectiveWidth - (edgePadding * 2);
    final pointSpacing = availableWidth / (totalPoints - 1);

    return chartArea.left + edgePadding + (index * pointSpacing);
  }

  /// Cache for hit testing to improve performance
  static final Map<String, Map<int, double>> _hitTestCache = {};

  /// More efficient implementation to find the data point closest to the given position
  static ProcessedBloodPressureData? findDataPoint(
    Offset position,
    Rect chartArea,
    List<ProcessedBloodPressureData> data,
  ) {
    if (data.isEmpty || !_isWithinChartArea(position, chartArea)) {
      return null;
    }

    // Create a unique key for this chart configuration
    final cacheKey = '${chartArea.width.round()}_${data.length}';

    // Initialize the cache for this configuration if needed
    final positionCache = _hitTestCache.putIfAbsent(cacheKey, () => {});

    // Fast approximate calculation for better performance
    final dataLength = data.length;
    final relativeX = position.dx - chartArea.left;
    final effectiveWidth = chartArea.width;

    // Calculate the approximate index based on position
    final approxIndex = ((relativeX / effectiveWidth) * (dataLength - 1))
        .round()
        .clamp(0, dataLength - 1);

    // Search around the approximate index
    ProcessedBloodPressureData? closestPoint;
    double minDistance = _hitTestThreshold;

    // Define a reasonable search range (we don't need to search all points)
    final searchRadius = min(10, dataLength ~/ 4); // Adaptive search radius
    final startIndex = max(0, approxIndex - searchRadius);
    final endIndex = min(dataLength - 1, approxIndex + searchRadius);

    for (int i = startIndex; i <= endIndex; i++) {
      final point = data[i];
      if (point.isEmpty) continue;

      // Get or calculate the x position for this point
      double pointX;
      if (positionCache.containsKey(i)) {
        pointX = positionCache[i]!;
      } else {
        pointX = calculateXPosition(i, dataLength, chartArea);
        positionCache[i] = pointX; // Cache for future use
      }

      final distance = (position.dx - pointX).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = point;
      }
    }

    return closestPoint;
  }

  /// Checks if a point is within the chart area
  static bool _isWithinChartArea(Offset position, Rect chartArea) {
    return position.dx >= chartArea.left &&
        position.dx <= chartArea.right &&
        position.dy >= chartArea.top &&
        position.dy <= chartArea.bottom;
  }

  /// Finds the index of the closest data point
  static int _findClosestIndex(
    double x,
    double chartLeft,
    double xStep,
    int dataLength,
  ) {
    if (dataLength <= 1) return 0;

    final relativeX = x - chartLeft;
    final rawIndex = relativeX / xStep;
    final index = rawIndex.round();

    return index.clamp(0, dataLength - 1);
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
