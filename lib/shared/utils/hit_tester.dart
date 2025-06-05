import 'package:flutter/material.dart';

import 'chart_calculations.dart';

/// Generic hit tester for chart interactions
/// Provides reusable hit testing functionality for all chart types
class SharedHitTester {
  static const double _defaultHitThreshold = 20.0;
  static const double _pointHitThreshold = 30.0;
  static const double _lineHitThreshold = 10.0;

  /// Find the closest data point based on X position for any data type
  static T? findClosestDataPoint<T>(
    Offset position,
    Rect chartArea,
    List<T> data, {
    double hitThreshold = _defaultHitThreshold,
  }) {
    if (data.isEmpty ||
        !SharedChartCalculations.isWithinChartArea(position, chartArea)) {
      return null;
    }

    final xPosition =
        SharedChartCalculations.calculateXPosition(0, data.length, chartArea);

    final xStep = data.length > 1
        ? (chartArea.width - 30.0) / (data.length - 1) // 30.0 = edgePadding * 2
        : 0.0;

    int closestIndex = -1;
    double minDistance = double.infinity;

    for (int i = 0; i < data.length; i++) {
      final x = chartArea.left + 15.0 + (i * xStep); // 15.0 = edgePadding
      final distance = (position.dx - x).abs();

      if (distance < minDistance && distance <= hitThreshold) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex >= 0 ? data[closestIndex] : null;
  }

  /// Test if position is near a specific point
  static bool isNearPoint(
    Offset position,
    Offset point, {
    double threshold = _pointHitThreshold,
  }) {
    return (position - point).distance <= threshold;
  }

  /// Test if position is near a line between two points
  static bool isNearLine(
    Offset position,
    Offset lineStart,
    Offset lineEnd, {
    double threshold = _lineHitThreshold,
  }) {
    final a = position - lineStart;
    final b = lineEnd - lineStart;
    final bLen = b.distance;

    if (bLen == 0) return false;

    final t = (a.dx * b.dx + a.dy * b.dy) / (bLen * bLen);

    // If closest point is outside the line segment, return false
    if (t < 0 || t > 1) return false;

    final projection = lineStart + (b * t);
    final distance = (position - projection).distance;

    return distance <= threshold;
  }

  /// Find data point index by X position with hit testing
  static int? findDataIndexByPosition(
    Offset position,
    Rect chartArea,
    int dataLength, {
    double hitThreshold = _defaultHitThreshold,
  }) {
    return SharedChartCalculations.findClosestDataPointIndex(
      position,
      chartArea,
      dataLength,
      hitTestThreshold: hitThreshold,
    );
  }

  /// Calculate Y position for hit testing
  static double calculateYPosition(
    double value,
    Rect chartArea,
    double minValue,
    double maxValue,
  ) {
    return SharedChartCalculations.calculateYPosition(
        value, chartArea, minValue, maxValue);
  }

  /// Test if position hits a circular area (for data points)
  static bool hitTestCircle(
    Offset position,
    Offset center,
    double radius, {
    double extraPadding = 10.0,
  }) {
    final distance = (position - center).distance;
    return distance <= radius + extraPadding;
  }

  /// Test if position hits a rectangular area
  static bool hitTestRectangle(
    Offset position,
    Rect rectangle, {
    double padding = 5.0,
  }) {
    final expandedRect = Rect.fromLTRB(
      rectangle.left - padding,
      rectangle.top - padding,
      rectangle.right + padding,
      rectangle.bottom + padding,
    );
    return expandedRect.contains(position);
  }
}
