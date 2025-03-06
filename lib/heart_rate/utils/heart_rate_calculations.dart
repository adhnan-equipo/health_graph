import 'dart:math';

import 'package:flutter/material.dart';

import '../../utils/tooltip_position.dart';
import '../models/heart_rate_range.dart';
import '../models/processed_heart_rate_data.dart';

class HeartRateChartCalculations {
  static const double _hitTestThreshold = 30.0;
  static const double _minYPadding = 0.1; // 10% padding minimum
  static const double _maxYPadding = 0.2; // 20% padding maximum

  /// Calculate the Y-axis values, min, and max values for the chart
  static (List<int>, double, double) calculateYAxisRange(
    List<ProcessedHeartRateData> data,
  ) {
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
    final paddingPercent = _calculateDynamicPadding(range);
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
    const leftPadding = 25.0; // Space for y-axis labels
    const rightPadding = 0.0; // Right margin
    const topPadding = 15.0; // Top margin
    const bottomPadding = 35.0; // Space for x-axis labels

    return Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );
  }

  /// Find data point near the given position
  static ProcessedHeartRateData? findNearestDataPoint(
      Offset position,
      Rect chartArea,
      List<ProcessedHeartRateData> data,
      double minValue,
      double maxValue,
      {double hitTestThreshold = 30}) {
    if (data.isEmpty) return null;

    // Calculate the distance for each data point
    double minDistance = double.infinity;
    ProcessedHeartRateData? nearestPoint;

    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) continue;

      final x = _getXPosition(i, data.length, chartArea);
      final y = _getYPosition(data[i].avgValue, chartArea, minValue, maxValue);

      final distance = (position - Offset(x, y)).distance;

      if (distance < minDistance && distance < hitTestThreshold) {
        minDistance = distance;
        nearestPoint = data[i];
      }
    }

    return nearestPoint;
  }

  /// Calculate tooltip position to ensure it stays within screen bounds
  static TooltipPosition calculateTooltipPosition(
    Offset tapPosition,
    Size tooltipSize,
    Size screenSize,
    EdgeInsets padding,
  ) {
    double left = tapPosition.dx - (tooltipSize.width / 2);
    double top = tapPosition.dy - tooltipSize.height - 10;
    bool showAbove = true;

    // Ensure tooltip stays within horizontal bounds
    left = left.clamp(
      padding.left,
      screenSize.width - tooltipSize.width - padding.right,
    );

    // Check if tooltip would go off the top of the screen
    if (top < padding.top) {
      top = tapPosition.dy + 10;
      showAbove = false;
    }

    // Ensure tooltip stays within vertical bounds
    top = top.clamp(
      padding.top,
      screenSize.height - tooltipSize.height - padding.bottom,
    );

    return TooltipPosition(
      left: left,
      top: top,
      showAbove: showAbove,
    );
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
    if (maxValue == minValue) return chartArea.center.dy;

    return chartArea.bottom -
        ((value - minValue) / (maxValue - minValue)) * chartArea.height;
  }
}
