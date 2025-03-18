import 'dart:math';

import 'package:flutter/material.dart';

import '../models/heart_rate_range.dart';
import '../models/processed_heart_rate_data.dart';

class HeartRateChartCalculations {
  static const double _hitTestThreshold = 30.0;
  static const double _minYPadding = 0.1; // 10% padding minimum
  static const double _maxYPadding = 0.2; // 20% padding maximum

  /// Calculate the Y-axis values, min, and max values for the chart
  static (List<int>, double, double) calculateYAxisRange(
    List<ProcessedHeartRateData> data, {
    bool adaptiveScaling = true,
  }) {
    if (data.isEmpty) {
      return _getDefaultRange();
    }

    // Collect all values to determine min/max
    final allValues = <double>[];

    // Add data points
    for (var point in data) {
      if (!point.isEmpty) {
        allValues.addAll([
          point.minValue.toDouble(),
          point.maxValue.toDouble(),
          point.avgValue,
          if (point.restingRate != null) point.restingRate!.toDouble(),
        ]);
      }
    }

    // Include zone boundaries to ensure proper display
    allValues.addAll([
      HeartRateRange.lowMin.toDouble(),
      HeartRateRange.lowMax.toDouble(),
      HeartRateRange.normalMax.toDouble(),
      HeartRateRange.elevatedMax.toDouble(),
    ]);

    if (allValues.isEmpty) {
      return _getDefaultRange();
    }

    // Find actual min/max from data
    final minValue = allValues.reduce(min);
    final maxValue = allValues.reduce(max);

    // Calculate range with padding
    final range = maxValue - minValue;
    final paddingPercent =
        adaptiveScaling ? _calculateDynamicPadding(range) : _minYPadding;

    final topPadding = range * paddingPercent;
    final bottomPadding = range * paddingPercent;

    // Round to nearest 10 with extra space
    final adjustedMin = max(0, ((minValue - bottomPadding) / 10).floor() * 10);
    var adjustedMax = ((maxValue + topPadding) / 10).ceil() * 10;

    // Ensure maximum has enough padding
    adjustedMax = max(adjustedMax, (maxValue + 20).toInt());

    // Calculate optimal step size
    final effectiveRange = adjustedMax - adjustedMin;
    var stepSize = _calculateOptimalStepSize(effectiveRange.toDouble());

    // Generate axis values
    final yAxisValues = _generateAxisValues(adjustedMin, adjustedMax, stepSize);

    return (yAxisValues, adjustedMin.toDouble(), adjustedMax.toDouble());
  }

  /// Calculate optimal step size for Y-axis
  static int _calculateOptimalStepSize(double range) {
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    if (range <= 200) return 40;
    return (range / 5).round();
  }

  /// Generate axis values with given step size
  static List<int> _generateAxisValues(int min, int max, int step) {
    final values = <int>[];
    for (var i = min; i <= max; i += step) {
      values.add(i);
    }
    return values;
  }

  /// Calculate default range when no data is available
  static (List<int>, double, double) _getDefaultRange() {
    const defaultMin = 40;
    const defaultMax = 160;
    const step = 20;
    final values = _generateAxisValues(defaultMin, defaultMax, step);
    return (values, defaultMin.toDouble(), defaultMax.toDouble());
  }

  /// Calculate dynamic padding percentage based on range
  static double _calculateDynamicPadding(double range) {
    if (range <= 0) return _maxYPadding;
    if (range > 100) return _minYPadding;

    // Linear interpolation between min and max padding
    return _maxYPadding - (range / 100) * (_maxYPadding - _minYPadding);
  }

  /// Calculate chart area within the given size
  static Rect calculateChartArea(Size size) {
    const leftPadding = 30.0; // Space for y-axis labels
    const rightPadding = 5.0; // Right margin
    const topPadding = 10.0; // Top margin
    const bottomPadding = 35.0; // Space for x-axis labels

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  /// Find data point near the given position, considering the entire vertical line
  static ProcessedHeartRateData? findNearestDataPoint(
      Offset position,
      Rect chartArea,
      List<ProcessedHeartRateData> data,
      double minValue,
      double maxValue,
      {double hitTestThreshold = _hitTestThreshold}) {
    if (data.isEmpty) return null;

    // Calculate the horizontal distance for each data point's vertical line
    double minHorizontalDistance = double.infinity;
    ProcessedHeartRateData? nearestPoint;

    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      final x = _getXPosition(i, data.length, chartArea);

      // Calculate horizontal distance only - this enables tapping anywhere along the vertical line
      final horizontalDistance = (position.dx - x).abs();

      // Check if this point's vertical line is closer than the current nearest
      if (horizontalDistance < minHorizontalDistance &&
          horizontalDistance < hitTestThreshold) {
        minHorizontalDistance = horizontalDistance;
        nearestPoint = data[i];
      }
    }

    return nearestPoint;
  }

  /// Calculate x-position for a data point
  static double _getXPosition(int index, int totalPoints, Rect chartArea) {
    if (totalPoints <= 1) return chartArea.center.dx;

    final effectiveWidth = chartArea.width;
    const edgePadding = 15.0;
    final availableWidth = effectiveWidth - (edgePadding * 2);
    final pointSpacing = availableWidth / (totalPoints - 1);

    return chartArea.left + edgePadding + (index * pointSpacing);
  }

  /// Calculate y-position for a value
  static double _getYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    if (maxValue <= minValue) return chartArea.center.dy;

    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }

  /// Calculate a linear trend line for a set of data points
  static (double, double)? calculateTrendLine(
      List<ProcessedHeartRateData> data) {
    if (data.length < 4) return null;

    final validPoints = data.where((d) => !d.isEmpty).toList();
    if (validPoints.length < 4) return null;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = validPoints.length;

    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = validPoints[i].avgValue;

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    // Calculate slope and y-intercept
    final denominator = n * sumX2 - sumX * sumX;
    if (denominator.abs() < 0.001) return null; // Avoid division by near-zero

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final yIntercept = (sumY - slope * sumX) / n;

    return (slope, yIntercept);
  }

  /// Calculate the average heart rate zone for a set of data
  static HeartRateZoneInfo calculateAverageZone(
      List<ProcessedHeartRateData> data) {
    if (data.isEmpty) {
      return HeartRateZoneInfo(
        lowPercentage: 0,
        normalPercentage: 0,
        elevatedPercentage: 0,
        highPercentage: 0,
        primaryZone: 'No Data',
      );
    }

    final validData = data.where((d) => !d.isEmpty).toList();
    if (validData.isEmpty) {
      return HeartRateZoneInfo(
        lowPercentage: 0,
        normalPercentage: 0,
        elevatedPercentage: 0,
        highPercentage: 0,
        primaryZone: 'No Data',
      );
    }

    int lowCount = 0, normalCount = 0, elevatedCount = 0, highCount = 0;

    for (var point in validData) {
      final value = point.avgValue;

      if (value < HeartRateRange.lowMax) {
        lowCount++;
      } else if (value < HeartRateRange.normalMax) {
        normalCount++;
      } else if (value < HeartRateRange.elevatedMax) {
        elevatedCount++;
      } else {
        highCount++;
      }
    }

    final total = validData.length;
    final lowPercentage = (lowCount / total) * 100;
    final normalPercentage = (normalCount / total) * 100;
    final elevatedPercentage = (elevatedCount / total) * 100;
    final highPercentage = (highCount / total) * 100;

    // Determine primary zone
    String primaryZone;
    int maxCount =
        max(max(lowCount, normalCount), max(elevatedCount, highCount));

    if (maxCount == lowCount) {
      primaryZone = 'Low';
    } else if (maxCount == normalCount) {
      primaryZone = 'Normal';
    } else if (maxCount == elevatedCount) {
      primaryZone = 'Elevated';
    } else {
      primaryZone = 'High';
    }

    return HeartRateZoneInfo(
      lowPercentage: lowPercentage,
      normalPercentage: normalPercentage,
      elevatedPercentage: elevatedPercentage,
      highPercentage: highPercentage,
      primaryZone: primaryZone,
    );
  }
}

/// Class to hold heart rate zone distribution information
class HeartRateZoneInfo {
  final double lowPercentage;
  final double normalPercentage;
  final double elevatedPercentage;
  final double highPercentage;
  final String primaryZone;

  const HeartRateZoneInfo({
    required this.lowPercentage,
    required this.normalPercentage,
    required this.elevatedPercentage,
    required this.highPercentage,
    required this.primaryZone,
  });

  // Format percentage to 1 decimal place
  String get formattedLowPercentage => lowPercentage.toStringAsFixed(1);

  String get formattedNormalPercentage => normalPercentage.toStringAsFixed(1);

  String get formattedElevatedPercentage =>
      elevatedPercentage.toStringAsFixed(1);

  String get formattedHighPercentage => highPercentage.toStringAsFixed(1);

  // Check if any data is available
  bool get hasData =>
      lowPercentage > 0 ||
      normalPercentage > 0 ||
      elevatedPercentage > 0 ||
      highPercentage > 0;
}
